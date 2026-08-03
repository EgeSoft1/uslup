// =============================================================================
// TurkiyeMesajlasma — WebSocket Bağlantı Yöneticisi (Connection Manager)
// Dosya: crates/gateway-ws/src/connection.rs
//
// Mimari:
//   Her WebSocket bağlantısı için:
//   - ConnectedPeer: Bağlantı durumunu tutan struct
//   - rx_loop: Sunucudan istemciye mesaj gönderme task'ı
//   - tx_loop: İstemciden mesaj alma ve işleme task'ı
//   - HeartbeatTask: 25 saniyede bir ping/pong (presence yenileme)
//
// Zero-allocation tasarımı:
//   - bytes::Bytes ile zero-copy mesaj transferi
//   - SmallVec ile küçük listeler için stack allocation
//   - Arc<str> ile string interning
// =============================================================================

use std::sync::Arc;
use std::time::{Duration, Instant};

use axum::extract::ws::{Message, WebSocket};
use bytes::Bytes;
use dashmap::DashMap;
use futures::{SinkExt, StreamExt};
use tokio::sync::mpsc;
use tokio::time::timeout;
use tracing::{debug, error, info, warn};
use uuid::Uuid;

use crate::AppState;

// ─── Sabitler ─────────────────────────────────────────────────────────────────
/// Heartbeat aralığı: Presence TTL (30s) altında olmalı
const HEARTBEAT_INTERVAL: Duration = Duration::from_secs(25);
/// Pong bekleme süresi: Yanıt gelmezse bağlantıyı kes
const PONG_TIMEOUT: Duration = Duration::from_secs(10);
/// Maksimum mesaj boyutu: 64 KB (şifreli mesaj + overhead)
const MAX_MESSAGE_SIZE: usize = 65536;
/// Outgoing kanal kapasitesi (backpressure için)
const OUTGOING_CHANNEL_CAPACITY: usize = 256;

// ─── Bağlantı Kayıt Defteri ───────────────────────────────────────────────────

/// Thread-safe, lock-free bağlantı haritası
/// DashMap: RwLock<HashMap> yerine shard'lı concurrent map
/// 150M bağlantı bu map'e sığmaz — her node yalnızca kendi bağlantılarını tutar
pub struct ConnectionRegistry {
    /// device_id → outgoing sender
    connections: DashMap<Uuid, mpsc::Sender<OutgoingMessage>>,
    /// Toplam bağlantı sayacı (atomic)
    count: std::sync::atomic::AtomicU64,
}

impl ConnectionRegistry {
    pub fn new() -> Self {
        Self {
            connections: DashMap::with_capacity(1_000_000), // 1M bağlantı için ön-tahsis
            count: std::sync::atomic::AtomicU64::new(0),
        }
    }

    /// Yeni bağlantı kaydet
    pub fn register(&self, device_id: Uuid, sender: mpsc::Sender<OutgoingMessage>) {
        self.connections.insert(device_id, sender);
        self.count.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        metrics::gauge!("ws.connections.active", self.connection_count() as f64);
    }

    /// Bağlantıyı kaldır (kopma veya logout)
    pub fn unregister(&self, device_id: &Uuid) {
        if self.connections.remove(device_id).is_some() {
            self.count.fetch_sub(1, std::sync::atomic::Ordering::Relaxed);
            metrics::gauge!("ws.connections.active", self.connection_count() as f64);
        }
    }

    /// Cihaza mesaj gönder (async kanal üzerinden)
    /// Returns: true=gönderildi, false=cihaz bu node'da değil
    pub async fn send_to_device(&self, device_id: &Uuid, msg: OutgoingMessage) -> bool {
        if let Some(sender) = self.connections.get(device_id) {
            // try_send ile backpressure: Kanal doluysa mesajı düşür (non-blocking)
            match sender.try_send(msg) {
                Ok(_) => return true,
                Err(mpsc::error::TrySendError::Full(_)) => {
                    warn!("Çıkış kanalı dolu: device_id={}", device_id);
                    metrics::counter!("ws.messages.dropped", 1);
                    return true; // Cihaz bu node'da AMA kanal dolu
                }
                Err(mpsc::error::TrySendError::Closed(_)) => {
                    // Kanal kapanmış, bağlantı zaten yok
                    self.connections.remove(device_id);
                }
            }
        }
        false // Bu node'da yok
    }

    pub fn connection_count(&self) -> u64 {
        self.count.load(std::sync::atomic::Ordering::Relaxed)
    }
}

// ─── Giden Mesaj Tipi ─────────────────────────────────────────────────────────

#[derive(Debug)]
pub enum OutgoingMessage {
    /// E2EE şifreli mesaj zarfı (binary WebSocket frame)
    Envelope(Bytes),
    /// Presence güncellemesi (JSON veya binary)
    PresenceUpdate(Bytes),
    /// "Yazıyor..." göstergesi
    TypingIndicator(Bytes),
    /// Sistem mesajı (binary)
    SystemMessage(Bytes),
    /// Bağlantıyı kapat
    Close,
}

// ─── Kimlik Doğrulanmış Kullanıcı ────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct AuthenticatedPeer {
    pub user_id: Uuid,
    pub device_id: Uuid,
    pub region_code: String,
    pub platform: String,
    pub connected_at: Instant,
    pub ip_hash: Arc<str>,
}

// ─── Ana WebSocket Handler ────────────────────────────────────────────────────

/// Bir WebSocket bağlantısının tüm yaşam döngüsünü yönetir
/// Bu fonksiyon her bağlantı için ayrı bir Tokio task'ında çalışır
pub async fn handle_websocket(
    socket: WebSocket,
    peer: AuthenticatedPeer,
    state: AppState,
) {
    let device_id = peer.device_id;
    let user_id = peer.user_id;

    metrics::counter!("ws.connections.total", 1);
    info!(
        user_id = %user_id,
        device_id = %device_id,
        "WebSocket bağlantısı kuruldu"
    );

    // Outgoing kanal: Dışarıdan (pub/sub) gelen mesajlar bu kanal üzerinden ws'e gönderilir
    let (outgoing_tx, outgoing_rx) = mpsc::channel::<OutgoingMessage>(OUTGOING_CHANNEL_CAPACITY);

    // Bağlantıyı registry'e kaydet
    state.services.connections.register(device_id, outgoing_tx.clone());

    // Presence: Online olduğunu bildir
    if let Err(e) = state.services.presence
        .set_online(user_id, device_id, &state.node_id)
        .await
    {
        error!("Presence güncellenemedi: {}", e);
    }

    // Lawful Intercept: Bağlantı metaverisi logla (ClickHouse'a async)
    let li_state = state.clone();
    let li_peer = peer.clone();
    tokio::spawn(async move {
        li_state.services.lawful_intercept
            .log_connection_open(&li_peer)
            .await;
    });

    // WebSocket stream'i sink ve stream olarak böl
    let (mut ws_sink, mut ws_stream) = socket.split();

    // ── Giden Mesaj Task'ı (Sunucu → İstemci) ────────────────────────────────
    // Kanaldan gelen mesajları WebSocket frame olarak gönder
    let tx_peer = peer.clone();
    let tx_task = tokio::spawn(async move {
        let mut outgoing_rx = outgoing_rx;

        while let Some(msg) = outgoing_rx.recv().await {
            let ws_msg = match msg {
                OutgoingMessage::Envelope(data) => Message::Binary(data.to_vec()),
                OutgoingMessage::PresenceUpdate(data) => Message::Binary(data.to_vec()),
                OutgoingMessage::TypingIndicator(data) => Message::Binary(data.to_vec()),
                OutgoingMessage::SystemMessage(data) => Message::Binary(data.to_vec()),
                OutgoingMessage::Close => {
                    let _ = ws_sink.send(Message::Close(None)).await;
                    break;
                }
            };

            match ws_sink.send(ws_msg).await {
                Ok(_) => {
                    metrics::counter!("ws.messages.sent", 1);
                }
                Err(e) => {
                    debug!("WS gönderme hatası (bağlantı koptu): {}", e);
                    break;
                }
            }
        }

        debug!(
            device_id = %tx_peer.device_id,
            "Giden mesaj task'ı tamamlandı"
        );
    });

    // ── Gelen Mesaj Task'ı (İstemci → Sunucu) ────────────────────────────────
    let rx_state = state.clone();
    let rx_peer = peer.clone();
    let outgoing_tx_clone = outgoing_tx.clone();

    let rx_task = tokio::spawn(async move {
        let mut last_pong = Instant::now();

        loop {
            // Heartbeat zaman aşımıyla birlikte mesaj bekle
            let msg = timeout(HEARTBEAT_INTERVAL, ws_stream.next()).await;

            match msg {
                // ── Mesaj alındı ─────────────────────────────────────────────
                Ok(Some(Ok(frame))) => {
                    match frame {
                        Message::Binary(data) => {
                            if data.len() > MAX_MESSAGE_SIZE {
                                warn!(
                                    device_id = %rx_peer.device_id,
                                    size = data.len(),
                                    "Mesaj boyutu aşıldı, bağlantı kesiliyor"
                                );
                                metrics::counter!("ws.messages.oversized", 1);
                                break;
                            }

                            metrics::counter!("ws.messages.received", 1);

                            // Mesajı işle (rate limit kontrolü + yönlendirme)
                            if let Err(e) = process_incoming_message(
                                &rx_state,
                                &rx_peer,
                                Bytes::from(data),
                            ).await {
                                warn!(
                                    device_id = %rx_peer.device_id,
                                    error = %e,
                                    "Mesaj işleme hatası"
                                );
                                // Hatalı mesaj → bağlantıyı kesmiyoruz, sadece logluyoruz
                            }
                        }

                        Message::Text(text) => {
                            // Prototip JSON desteği
                            metrics::counter!("ws.messages.received.json", 1);
                            
                            if let Err(e) = process_incoming_json(
                                &rx_state,
                                &rx_peer,
                                &text,
                            ).await {
                                warn!(
                                    device_id = %rx_peer.device_id,
                                    error = %e,
                                    "JSON işleme hatası"
                                );
                            }
                        }

                        Message::Ping(payload) => {
                            // Otomatik pong (Axum bunu zaten yapıyor ama explicit olalım)
                            let _ = outgoing_tx_clone
                                .try_send(OutgoingMessage::SystemMessage(
                                    Bytes::from(payload)
                                ));
                        }

                        Message::Pong(_) => {
                            // Pong alındı: bağlantı canlı
                            last_pong = Instant::now();
                            debug!(device_id = %rx_peer.device_id, "Pong alındı");
                        }

                        Message::Close(frame) => {
                            info!(
                                device_id = %rx_peer.device_id,
                                reason = ?frame,
                                "İstemci bağlantıyı kapattı"
                            );
                            break;
                        }
                    }
                }

                // ── Heartbeat timeout: Ping gönder ───────────────────────────
                Err(_timeout) => {
                    // HEARTBEAT_INTERVAL geçti, pong gelip gelmediğini kontrol et
                    if last_pong.elapsed() > HEARTBEAT_INTERVAL + PONG_TIMEOUT {
                        warn!(
                            device_id = %rx_peer.device_id,
                            "Heartbeat timeout, bağlantı kesiliyor"
                        );
                        metrics::counter!("ws.connections.timeout", 1);
                        break;
                    }

                    // Ping gönder
                    let ping_payload = rx_peer.device_id.as_bytes().to_vec();
                    let _ = outgoing_tx_clone
                        .try_send(OutgoingMessage::SystemMessage(
                            Bytes::from(ping_payload)
                        ));

                    // Presence yenile (TTL refresh)
                    let presence_state = rx_state.clone();
                    let uid = rx_peer.user_id;
                    let did = rx_peer.device_id;
                    let nid = rx_state.node_id.clone();
                    tokio::spawn(async move {
                        if let Err(e) = presence_state.services.presence
                            .set_online(uid, did, &nid)
                            .await
                        {
                            debug!("Presence yenileme hatası: {}", e);
                        }
                    });
                }

                // ── Bağlantı hatası ──────────────────────────────────────────
                Ok(Some(Err(e))) => {
                    debug!("WS frame hatası: {}", e);
                    break;
                }

                // ── Stream kapandı ───────────────────────────────────────────
                Ok(None) => {
                    debug!(device_id = %rx_peer.device_id, "WS stream tüketildi");
                    break;
                }
            }
        }
    });

    // İki task'tan herhangi biri bitince diğerini iptal et (biri ölürse ikisi de ölür)
    tokio::select! {
        _ = tx_task => { debug!("TX task bitti"); }
        _ = rx_task => { debug!("RX task bitti"); }
    }

    // ── Temizlik ──────────────────────────────────────────────────────────────
    state.services.connections.unregister(&device_id);

    if let Err(e) = state.services.presence
        .set_offline(user_id, device_id)
        .await
    {
        error!("Offline presence güncellenemedi: {}", e);
    }

    // Lawful Intercept: Bağlantı kapanış logu
    let duration_ms = peer.connected_at.elapsed().as_millis() as u64;
    let li_state = state.clone();
    tokio::spawn(async move {
        li_state.services.lawful_intercept
            .log_connection_close(&peer, duration_ms)
            .await;
    });

    metrics::counter!("ws.connections.closed", 1);
    info!(
        user_id = %user_id,
        device_id = %device_id,
        duration_ms = peer.connected_at.elapsed().as_millis(),
        "WebSocket bağlantısı kapatıldı"
    );
}

// ─── Gelen Mesaj İşleyici ─────────────────────────────────────────────────────

/// İstemciden gelen binary frame'i parse edip yönlendirir
/// Tüm mesajlar Protobuf ile serialize edilmiş
async fn process_incoming_message(
    state: &AppState,
    peer: &AuthenticatedPeer,
    data: Bytes,
) -> Result<(), anyhow::Error> {
    use prost::Message as ProstMessage;

    // Rate limit kontrolü (DragonflyDB'den sliding window)
    state.services.rate_limiter
        .check_message_rate(peer.user_id)
        .await
        .map_err(|e| anyhow::anyhow!("Rate limit: {}", e))?;

    // Protobuf deserialize: ClientMessage
    // (proto tanımında: ClientMessage = { oneof payload { SendMessage, TypingIndicator, ... } })
    let client_msg = proto::ClientMessage::decode(data.as_ref())
        .map_err(|e| anyhow::anyhow!("Protobuf parse hatası: {}", e))?;

    match client_msg.payload {
        Some(proto::client_message::Payload::SendEnvelope(envelope)) => {
            // E2EE mesaj gönderme
            handle_send_envelope(state, peer, envelope).await?;
        }
        Some(proto::client_message::Payload::TypingIndicator(typing)) => {
            // "Yazıyor..." göstergesi yayınla
            handle_typing_indicator(state, peer, typing).await?;
        }
        Some(proto::client_message::Payload::ReadReceipt(receipt)) => {
            // Okundu bilgisi
            handle_read_receipt(state, peer, receipt).await?;
        }
        None => {
            warn!(device_id = %peer.device_id, "Boş mesaj payload'ı");
        }
        _ => {
            warn!(device_id = %peer.device_id, "Bilinmeyen mesaj tipi");
        }
    }

    Ok(())
}

/// E2EE mesaj zarfını alıcıya yönlendir
async fn handle_send_envelope(
    state: &AppState,
    sender: &AuthenticatedPeer,
    envelope: proto::EncryptedEnvelope,
) -> Result<(), anyhow::Error> {
    use domain::ports::MessageRouter;

    // Alıcı device ID'yi parse et
    let recipient_device_id = Uuid::from_slice(&envelope.recipient_device_id)
        .map_err(|e| anyhow::anyhow!("Geçersiz recipient_device_id: {}", e))?;

    // Zarf boyutunu kontrol et
    if envelope.ciphertext.len() > MAX_MESSAGE_SIZE {
        return Err(anyhow::anyhow!("Ciphertext çok büyük"));
    }

    // Zarfı serialize et
    let envelope_bytes = {
        use prost::Message as ProstMessage;
        let mut buf = Vec::with_capacity(envelope.encoded_len());
        envelope.encode(&mut buf)?;
        buf
    };

    // Yönlendir: DragonflyDB Pub/Sub üzerinden
    let result = state.services.message_router
        .route_to_device(recipient_device_id, envelope_bytes)
        .await?;

    metrics::counter!("ws.messages.routed", 1);

    debug!(
        sender = %sender.device_id,
        recipient = %recipient_device_id,
        result = ?result,
        "Mesaj yönlendirildi"
    );

    // ScyllaDB'ye async olarak kaydet (fire-and-forget pattern ile düşük latency)
    let store_state = state.clone();
    let store_sender = sender.clone();
    let raw_envelope = envelope.clone();
    tokio::spawn(async move {
        if let Err(e) = store_state.services.message_store
            .persist_envelope(&store_sender, raw_envelope)
            .await
        {
            error!("Mesaj kalıcı depolanamadı: {}", e);
            metrics::counter!("ws.messages.persist_failed", 1);
        }
    });

    Ok(())
}

/// Yazıyor göstergesini sohbet katılımcılarına yayınla
async fn handle_typing_indicator(
    state: &AppState,
    sender: &AuthenticatedPeer,
    typing: proto::TypingIndicatorRequest,
) -> Result<(), anyhow::Error> {
    let conversation_id = Uuid::from_slice(&typing.conversation_id)
        .map_err(|e| anyhow::anyhow!("Geçersiz conversation_id: {}", e))?;

    // DragonflyDB'ye "yazıyor" durumunu set et (5 sn TTL)
    state.services.presence
        .set_typing(sender.user_id, conversation_id, typing.is_typing)
        .await?;

    Ok(())
}

async fn handle_read_receipt(
    state: &AppState,
    reader: &AuthenticatedPeer,
    receipt: proto::ReadReceipt,
) -> Result<(), anyhow::Error> {
    // ScyllaDB'deki teslimat durumunu güncelle (async)
    let store_state = state.clone();
    let reader_id = reader.user_id;
    let device_id = reader.device_id;
    tokio::spawn(async move {
        if let Err(e) = store_state.services.message_store
            .mark_read(reader_id, device_id, receipt)
            .await
        {
            error!("Okundu bilgisi güncellenemedi: {}", e);
        }
    });

    Ok(())
}

// ─── Prototip JSON İşleyici (QR Kod ve Test için) ───────────────────────────
async fn process_incoming_json(
    state: &AppState,
    peer: &AuthenticatedPeer,
    text: &str,
) -> Result<(), anyhow::Error> {
    let json: serde_json::Value = serde_json::from_str(text)?;
    
    let msg_type = json.get("type").and_then(|v| v.as_str()).unwrap_or("");
    
    match msg_type {
        "auth" => {
            debug!("Auth JSON message received (already handled in upgrade)");
        },
        "create_qr" => {
            // QR oluşturma (1 dakikalık)
            let qr_code = state.services.qr_service.generate_qr(peer.user_id, peer.device_id).await;
            debug!("Generated QR Code for user {}: {}", peer.user_id, qr_code);
            
            // İstemciye geri gönder
            let response = serde_json::json!({
                "type": "qr_generated",
                "code": qr_code,
                "expires_in": 60
            });
            // Burada doğrudan socket üzerinden veya connection_registry üzerinden gönderilebilir.
            // Prototip olduğu için şimdilik logla yetiniyoruz veya ileride pub/sub ile gönderilebilir.
        },
        "scan_qr" => {
            // QR okuma
            let scanned_code = json.get("code").and_then(|v| v.as_str()).unwrap_or("");
            
            match state.services.qr_service.consume_qr(scanned_code, peer.user_id).await {
                Ok(target_user) => {
                    info!("QR Scanned successfully! Link {} with {}", peer.user_id, target_user);
                },
                Err(err_msg) => {
                    warn!("QR Scan Failed: {}", err_msg);
                }
            }
        },
        "chat_message" => {
            info!("Chat JSON message from {}: {}", peer.user_id, text);
            // Prototype Broadcast: Gelen mesajı kendisi hariç tüm aktif cihazlara gönder
            let msg_bytes = bytes::Bytes::from(text.to_string());
            for item in state.services.connections.connections.iter() {
                if *item.key() != peer.device_id {
                    let _ = item.value().try_send(OutgoingMessage::SystemMessage(msg_bytes.clone()));
                }
            }
        }
        _ => {
            warn!("Unknown JSON message type: {}", msg_type);
        }
    }
    
    Ok(())
}
