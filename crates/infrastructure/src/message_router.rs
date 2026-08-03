// =============================================================================
// TurkiyeMesajlasma — DragonflyDB Pub/Sub Tabanlı Mesaj Yönlendirme
// Dosya: crates/infrastructure/src/message_router.rs
//
// Mimari Akış:
//   Gönderici Node (gateway-01)
//     └── PUBLISH msg:channel:{recipient_device_id} <envelope_bytes>
//           └── DragonflyDB Cluster
//                 └── SUBSCRIBE alan Node (gateway-07)
//                       └── ConnectionRegistry.send_to_device(device_id, envelope)
//                             └── WebSocket Frame → İstemci
//
// Eğer alıcı çevrimdışıysa:
//   └── ScyllaDB offline_message_queue'ya yaz
//   └── Push notification gönder (FCM / APNS)
//
// Node-to-node latency hedefi: < 1ms (aynı VPC içi)
// =============================================================================

use std::sync::Arc;
use std::time::Duration;

use async_trait::async_trait;
use bytes::Bytes;
use fred::prelude::*;
use tracing::{debug, error, info, warn};
use uuid::Uuid;

use domain::ports::{MessageRouter, RoutingResult};
use domain::errors::{PlatformError, PlatformResult};

use super::presence::DragonflyPresenceRepository;
use crate::db::scylla::offline_queue::OfflineQueueRepository;
use crate::push::PushNotificationService;
use crate::connection_registry::LocalConnectionRegistry;

/// DragonflyDB tabanlı dağıtık mesaj yönlendirici
pub struct DragonflyMessageRouter {
    /// Fred Redis client (DragonflyDB uyumlu)
    /// ClusterClient: Otomatik shard routing
    dragonfly: Arc<ClusterClient>,

    /// Bu node'daki yerel WebSocket bağlantıları
    local_connections: Arc<LocalConnectionRegistry>,

    /// Çevrimdışı kuyruk (ScyllaDB)
    offline_queue: Arc<OfflineQueueRepository>,

    /// Push notification servisi (FCM / APNS)
    push_service: Arc<PushNotificationService>,

    /// Bu node'un kimliği
    node_id: Arc<str>,
}

impl DragonflyMessageRouter {
    pub fn new(
        dragonfly: Arc<ClusterClient>,
        local_connections: Arc<LocalConnectionRegistry>,
        offline_queue: Arc<OfflineQueueRepository>,
        push_service: Arc<PushNotificationService>,
        node_id: Arc<str>,
    ) -> Self {
        Self {
            dragonfly,
            local_connections,
            offline_queue,
            push_service,
            node_id,
        }
    }

    /// DragonflyDB Pub/Sub: Mesajı hedef cihazın kanalına yayınla
    /// Performans: PUBLISH komutu O(N) — N = o kanala abone olan subscriber sayısı
    /// Beklenen N = 1 (her cihaz sadece bir node'a bağlı)
    async fn publish_to_channel(
        &self,
        device_id: Uuid,
        data: &[u8],
    ) -> PlatformResult<u64> {
        let channel = format!("msg:channel:{}", device_id.as_simple());

        // Fred: PUBLISH komutu
        // Dönüş değeri: bu mesajı alan subscriber sayısı
        let subscriber_count: u64 = self.dragonfly
            .publish(channel.as_str(), data)
            .await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("DragonflyDB PUBLISH hatası: {}", e),
            })?;

        Ok(subscriber_count)
    }

    /// Hedef cihazın hangi node'da olduğunu kontrol et
    async fn get_device_node(&self, device_id: Uuid) -> PlatformResult<Option<String>> {
        let key = format!("ws:node:{}:{}", device_id.as_simple(), "*");

        // KEYS komutu yerine SET ile saklanan node bilgisini al
        // (KEYS production'da kullanılmaz; SET + GET tercih edilir)
        let node_key = format!("ws:node:{}", device_id.as_simple());
        let node_id: Option<String> = self.dragonfly
            .get(node_key.as_str())
            .await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("DragonflyDB GET hatası: {}", e),
            })?;

        Ok(node_id)
    }
}

#[async_trait]
impl MessageRouter for DragonflyMessageRouter {
    async fn route_to_device(
        &self,
        recipient_device_id: Uuid,
        envelope: Vec<u8>,
    ) -> PlatformResult<RoutingResult> {
        let envelope_bytes = Bytes::from(envelope);

        // ── 1. Yerel bağlantı kontrolü (en hızlı yol) ────────────────────────
        // Alıcı bu node'da mı? Varsa direkt memory-to-memory transfer
        if self.local_connections
            .send_to_device(&recipient_device_id, envelope_bytes.clone())
            .await
        {
            debug!(
                device_id = %recipient_device_id,
                "Mesaj yerel WebSocket üzerinden teslim edildi"
            );
            metrics::counter!("routing.local_delivery", 1);
            return Ok(RoutingResult::DeliveredOnline);
        }

        // ── 2. Pub/Sub: Başka node'da mı? ─────────────────────────────────────
        // DragonflyDB'ye yayınla; hedef node'un subscriber'ı varsa teslim alır
        let subscriber_count = self.publish_to_channel(
            recipient_device_id,
            &envelope_bytes,
        ).await?;

        if subscriber_count > 0 {
            debug!(
                device_id = %recipient_device_id,
                subscribers = subscriber_count,
                "Mesaj Pub/Sub üzerinden başka node'a yönlendirildi"
            );
            metrics::counter!("routing.pubsub_delivery", 1);

            // Hangi node'a yönlendirildi?
            let node_id = self.get_device_node(recipient_device_id)
                .await
                .unwrap_or(None)
                .unwrap_or_else(|| "unknown".to_string());

            return Ok(RoutingResult::ForwardedToNode { node_id });
        }

        // ── 3. Çevrimdışı: ScyllaDB offline kuyruğuna ekle ───────────────────
        warn!(
            device_id = %recipient_device_id,
            "Alıcı çevrimdışı, offline kuyruğuna ekleniyor"
        );

        // ScyllaDB'ye yaz
        self.offline_queue
            .enqueue(recipient_device_id, &envelope_bytes)
            .await
            .map_err(|e| PlatformError::DatabaseError {
                source: anyhow::anyhow!("Offline kuyruk yazma hatası: {}", e),
            })?;

        // Push notification gönder (arka planda)
        let push_svc = self.push_service.clone();
        let device_id = recipient_device_id;
        tokio::spawn(async move {
            if let Err(e) = push_svc.send_new_message_notification(device_id).await {
                error!("Push notification gönderilemedi: {}", e);
                metrics::counter!("push.failed", 1);
            } else {
                metrics::counter!("push.sent", 1);
            }
        });

        metrics::counter!("routing.offline_queue", 1);
        Ok(RoutingResult::QueuedOffline)
    }

    async fn route_to_devices(
        &self,
        recipient_device_ids: &[Uuid],
        envelope: Vec<u8>,
    ) -> PlatformResult<Vec<(Uuid, RoutingResult)>> {
        let envelope_bytes = Bytes::from(envelope);

        // Grup mesajı: Her cihaz için paralel yönlendirme
        // tokio::join_all ile tüm yönlendirmeler paralel yapılır
        let futures: Vec<_> = recipient_device_ids
            .iter()
            .map(|&device_id| {
                let env = envelope_bytes.to_vec();
                let router = self as *const _ as usize; // unsafe ptr - sadece bu scope'ta geçerli
                async move {
                    // Her cihaz için bağımsız yönlendirme
                    (device_id, Ok(RoutingResult::DeliveredOnline)) // placeholder
                }
            })
            .collect();

        // Gerçek implementasyon: futures::future::join_all kullanır
        // Basitlik için placeholder döndürüyoruz
        Ok(recipient_device_ids
            .iter()
            .map(|&id| (id, RoutingResult::DeliveredOnline))
            .collect())
    }
}

// =============================================================================
// DragonflyDB Subscriber: Pub/Sub kanalını dinleyen servis
// Her gateway node, başlatıldığında kendi bağlı cihazları için kanal dinler
// =============================================================================

pub struct PubSubSubscriber {
    dragonfly_subscriber: Arc<SubscriberClient>,
    local_connections: Arc<LocalConnectionRegistry>,
    node_id: Arc<str>,
}

impl PubSubSubscriber {
    pub async fn new(
        config: &fred::types::RedisConfig,
        local_connections: Arc<LocalConnectionRegistry>,
        node_id: Arc<str>,
    ) -> PlatformResult<Self> {
        // Subscriber için ayrı bir DragonflyDB bağlantısı
        // (Redis/Dragonfly: SUBSCRIBE modundaki bağlantı sadece pub/sub komutları kabul eder)
        let subscriber_client = Builder::from_config(config.clone())
            .build_subscriber_client()
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("Subscriber client oluşturulamadı: {}", e),
            })?;

        subscriber_client.connect();
        subscriber_client
            .wait_for_connect()
            .await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("Subscriber bağlantısı kurulamadı: {}", e),
            })?;

        Ok(Self {
            dragonfly_subscriber: Arc::new(subscriber_client),
            local_connections,
            node_id,
        })
    }

    /// Pattern subscription: Bu node'daki tüm cihazların mesajlarını dinle
    /// Pattern: msg:channel:* (tüm cihaz kanalları)
    ///
    /// Alternatif: Her cihaz bağlandığında SUBSCRIBE msg:channel:{device_id}
    /// Pattern subscription daha dinamik ama biraz daha yavaş
    pub async fn start_listening(self: Arc<Self>) {
        let pattern = "msg:channel:*";

        info!(
            node_id = %self.node_id,
            pattern = pattern,
            "Pub/Sub subscription başlatılıyor"
        );

        // Pattern subscribe
        if let Err(e) = self.dragonfly_subscriber
            .psubscribe(pattern)
            .await
        {
            error!("PSUBSCRIBE başarısız: {}", e);
            return;
        }

        // Mesaj akışını dinle
        let mut message_rx = self.dragonfly_subscriber.message_rx();

        loop {
            match message_rx.recv().await {
                Ok(pubsub_msg) => {
                    // Channel adından device_id'yi çıkar
                    // "msg:channel:550e8400e29b41d4a716446655440000" → Uuid
                    let channel = pubsub_msg.channel.to_string();
                    let device_id_str = channel
                        .strip_prefix("msg:channel:")
                        .unwrap_or("");

                    let device_id = match Uuid::parse_str(device_id_str) {
                        Ok(id) => id,
                        Err(_) => {
                            warn!("Geçersiz kanal formatı: {}", channel);
                            continue;
                        }
                    };

                    // Mesaj payload'ını bytes olarak al
                    let payload = match pubsub_msg.value {
                        RedisValue::Bytes(b) => Bytes::from(b),
                        RedisValue::String(s) => Bytes::from(s.into_bytes()),
                        _ => {
                            warn!("Beklenmeyen payload tipi: {:?}", pubsub_msg.value);
                            continue;
                        }
                    };

                    // Yerel WebSocket bağlantısına teslim et
                    let connections = self.local_connections.clone();
                    tokio::spawn(async move {
                        let delivered = connections
                            .send_to_device(&device_id, payload)
                            .await;

                        if delivered {
                            debug!(
                                device_id = %device_id,
                                "Pub/Sub mesajı yerel bağlantıya teslim edildi"
                            );
                            metrics::counter!("pubsub.received.delivered", 1);
                        } else {
                            // Race condition: Cihaz bu mesaj gelene kadar bağlantısını kesti
                            debug!(
                                device_id = %device_id,
                                "Pub/Sub mesajı: Yerel bağlantı bulunamadı (race condition)"
                            );
                            metrics::counter!("pubsub.received.missed", 1);
                        }
                    });
                }

                Err(e) => {
                    error!("Pub/Sub mesaj alma hatası: {}", e);
                    // Yeniden bağlanmayı dene
                    tokio::time::sleep(Duration::from_secs(1)).await;
                    // Fred otomatik reconnect yapar
                }
            }
        }
    }
}

// =============================================================================
// Tonic gRPC: MessageGatewayService implementasyonu
// (Proto tanımındaki MessageGatewayService için Rust server kodu)
// =============================================================================

use proto::turkiye_mesajlasma::v1::{
    message_gateway_service_server::MessageGatewayService,
    ForwardBatchRequest, ForwardBatchResponse,
    ForwardEnvelopeRequest, ForwardEnvelopeResponse,
    DrainQueueRequest, NodeHealthStatus,
};
use tonic::{Request, Response, Status};

pub struct GrpcMessageGatewayService {
    router: Arc<DragonflyMessageRouter>,
    local_connections: Arc<LocalConnectionRegistry>,
    node_id: Arc<str>,
}

#[tonic::async_trait]
impl MessageGatewayService for GrpcMessageGatewayService {
    /// Tek bir zarfı bu node üzerinden teslim et
    async fn forward_envelope(
        &self,
        request: Request<ForwardEnvelopeRequest>,
    ) -> Result<Response<ForwardEnvelopeResponse>, Status> {
        let req = request.into_inner();

        let recipient_device_id = Uuid::from_slice(&req.recipient_device_id)
            .map_err(|_| Status::invalid_argument("Geçersiz recipient_device_id"))?;

        let envelope = req.envelope
            .ok_or_else(|| Status::invalid_argument("Envelope boş olamaz"))?;

        use prost::Message as ProstMessage;
        let mut envelope_bytes = Vec::with_capacity(envelope.encoded_len());
        envelope.encode(&mut envelope_bytes)
            .map_err(|e| Status::internal(format!("Encode hatası: {}", e)))?;

        let start = std::time::Instant::now();
        let result = self.router
            .route_to_device(recipient_device_id, envelope_bytes)
            .await;

        let latency_us = start.elapsed().as_micros() as u64;

        match result {
            Ok(RoutingResult::DeliveredOnline) => {
                Ok(Response::new(ForwardEnvelopeResponse {
                    status: forward_envelope_response::Status::DeliveredOnline as i32,
                    node_id: self.node_id.to_string(),
                    latency_us,
                }))
            }
            Ok(RoutingResult::QueuedOffline) => {
                Ok(Response::new(ForwardEnvelopeResponse {
                    status: forward_envelope_response::Status::QueuedOffline as i32,
                    node_id: self.node_id.to_string(),
                    latency_us,
                }))
            }
            Ok(RoutingResult::ForwardedToNode { node_id }) => {
                Ok(Response::new(ForwardEnvelopeResponse {
                    status: forward_envelope_response::Status::ForwardedToNode as i32,
                    node_id,
                    latency_us,
                }))
            }
            Err(e) => Err(Status::internal(e.to_string())),
        }
    }

    /// Toplu zarf teslimi (grup mesajı)
    async fn forward_batch_envelope(
        &self,
        request: Request<ForwardBatchRequest>,
    ) -> Result<Response<ForwardBatchResponse>, Status> {
        let req = request.into_inner();
        let batch = req.batch.ok_or_else(|| Status::invalid_argument("Batch boş"))?;

        let mut delivered = 0u32;
        let mut queued = 0u32;
        let mut failed = 0u32;
        let mut results = std::collections::HashMap::new();

        for envelope in batch.envelopes {
            let device_id_bytes = envelope.recipient_device_id.clone();
            let device_id = match Uuid::from_slice(&device_id_bytes) {
                Ok(id) => id,
                Err(_) => {
                    failed += 1;
                    continue;
                }
            };

            use prost::Message as ProstMessage;
            let mut bytes = Vec::with_capacity(envelope.encoded_len());
            if envelope.encode(&mut bytes).is_err() {
                failed += 1;
                continue;
            }

            match self.router.route_to_device(device_id, bytes).await {
                Ok(RoutingResult::DeliveredOnline) => {
                    delivered += 1;
                    results.insert(device_id.to_string(), "DELIVERED".to_string());
                }
                Ok(RoutingResult::QueuedOffline) => {
                    queued += 1;
                    results.insert(device_id.to_string(), "QUEUED".to_string());
                }
                Ok(RoutingResult::ForwardedToNode { .. }) => {
                    delivered += 1;
                    results.insert(device_id.to_string(), "FORWARDED".to_string());
                }
                Err(e) => {
                    failed += 1;
                    results.insert(device_id.to_string(), format!("ERROR: {}", e));
                }
            }
        }

        Ok(Response::new(ForwardBatchResponse {
            results,
            delivered_count: delivered,
            queued_count: queued,
            failed_count: failed,
        }))
    }

    /// Offline kuyruktan mesajları çek (stream olarak döner)
    type DrainOfflineQueueStream = tokio_stream::wrappers::ReceiverStream<
        Result<proto::turkiye_mesajlasma::v1::EncryptedEnvelope, Status>
    >;

    async fn drain_offline_queue(
        &self,
        request: Request<DrainQueueRequest>,
    ) -> Result<Response<Self::DrainOfflineQueueStream>, Status> {
        let req = request.into_inner();
        let device_id = Uuid::from_slice(&req.device_id)
            .map_err(|_| Status::invalid_argument("Geçersiz device_id"))?;

        let (tx, rx) = tokio::sync::mpsc::channel(128);

        // Offline kuyruktan mesajları stream olarak gönder
        // (Detay implementasyonu ScyllaDB driver katmanında)
        tokio::spawn(async move {
            // ScyllaDB'den offline mesajları çek ve tx'e gönder
            // Her sayfa 50 mesaj
            let _ = tx; // placeholder
        });

        Ok(Response::new(tokio_stream::wrappers::ReceiverStream::new(rx)))
    }

    /// Node sağlık durumu
    async fn health_check(
        &self,
        _request: Request<prost_types::Empty>,
    ) -> Result<Response<NodeHealthStatus>, Status> {
        let conn_count = self.local_connections.connection_count();

        Ok(Response::new(NodeHealthStatus {
            node_id: self.node_id.to_string(),
            active_connections: conn_count,
            cpu_usage_percent: get_cpu_usage(),
            memory_usage_percent: get_memory_usage(),
            messages_per_second: metrics::get_message_rate(),
            is_healthy: true,
            region: std::env::var("REGION").unwrap_or_else(|_| "tr".to_string()),
        }))
    }
}

// Sistem metrik yardımcıları (gerçek implementasyonda sysinfo crate kullanılır)
fn get_cpu_usage() -> f32 { 0.0 }
fn get_memory_usage() -> f32 { 0.0 }

// proto imports için gerekli
use proto::turkiye_mesajlasma::v1::forward_envelope_response;
