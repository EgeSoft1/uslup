// =============================================================================
// TurkiyeMesajlasma — ClickHouse Yasal Dinleme (Lawful Intercept) Logları
// Dosya: crates/infrastructure/src/db/clickhouse/lawful_intercept.rs
//
// Özellikler:
// - Crate: clickhouse (HTTP tabanlı resmi olmayan ultra-hızlı driver)
// - Batch Insert (Yığınsal Yazma): ClickHouse saniyede 1 log yazmayı sevmez.
//   Milyonlarca satırı blok (batch) halinde yazmak için tokio::sync::mpsc
//   kanalında logları biriktirip saniyede bir defa yığın olarak basıyoruz.
// - Metadata KVKK uyumlu (sadece Hash IP).
// =============================================================================

use std::sync::Arc;
use std::time::Duration;

use async_trait::async_trait;
use clickhouse::{Client, Row};
use serde::{Deserialize, Serialize};
use tokio::sync::mpsc;
use tracing::{debug, error, info};
use uuid::Uuid;

use domain::ports::LawfulInterceptRepository;
use crate::connection::AuthenticatedPeer;

/// ClickHouse'a yazılacak olan Satır (Row) struct'ı
/// Serde Serialize şarttır, ClickHouse driver veriyi HTTP üzerinden gönderirken
/// Native format'ta serialize eder.
#[derive(Row, Serialize, Deserialize, Debug, Clone)]
pub struct ConnectionLog {
    pub session_id: String,     // UUID
    pub user_id: String,        // UUID
    pub device_id: String,      // UUID
    pub node_id: String,        
    pub ip_hash: String,        // Sadece SHA-256 hash
    pub platform: String,
    pub event_type: u8,         // 1 = Bağlandı, 2 = Koptu
    pub connected_at: u32,      // Unix Timestamp (saniye)
    pub duration_ms: u32,       // Kopuşlarda bağlantı süresi
}

pub struct ClickHouseLawfulIntercept {
    /// Logları arkada biriktiren kanala veri gönderen transmitter
    log_tx: mpsc::Sender<ConnectionLog>,
    node_id: Arc<str>,
}

impl ClickHouseLawfulIntercept {
    /// Yeni ClickHouse servisi başlatır.
    /// Arka planda 10.000 log biriktiğinde veya 1 saniye geçtiğinde 
    /// yığınsal (batch) yazma işlemi yapan bir Tokio Task'ı çalıştırır.
    pub async fn new(url: &str, user: &str, password: &str, node_id: Arc<str>) -> Self {
        let client = Client::default()
            .with_url(url)
            .with_user(user)
            .with_password(password)
            .with_database("lawful_intercept");

        // 100.000 kapasiteli MPSC kanalı (Aşırı yoğunlukta buffer)
        let (tx, rx) = mpsc::channel(100_000);

        // Arka plan (Background) Batching Task'ı
        Self::start_batch_worker(client, rx);

        Self {
            log_tx: tx,
            node_id,
        }
    }

    /// Background Worker: Logları biriktirip tek seferde ClickHouse'a gönderir
    fn start_batch_worker(client: Client, mut rx: mpsc::Receiver<ConnectionLog>) {
        tokio::spawn(async move {
            let mut batch = Vec::with_capacity(10_000);
            let flush_interval = Duration::from_secs(1);
            let mut interval = tokio::time::interval(flush_interval);

            loop {
                tokio::select! {
                    // Kanalda yeni veri var mı?
                    msg = rx.recv() => {
                        match msg {
                            Some(log) => {
                                batch.push(log);
                                // Kapasite dolduysa beklemeden yaz
                                if batch.len() >= 10_000 {
                                    Self::flush_to_db(&client, &mut batch).await;
                                }
                            }
                            None => {
                                // Kanal kapandı, son kalanları yazıp çık
                                if !batch.is_empty() {
                                    Self::flush_to_db(&client, &mut batch).await;
                                }
                                break;
                            }
                        }
                    }
                    
                    // Zaman doldu mu? (Her 1 saniyede bir)
                    _ = interval.tick() => {
                        if !batch.is_empty() {
                            Self::flush_to_db(&client, &mut batch).await;
                        }
                    }
                }
            }
        });
    }

    /// ClickHouse Insert İşlemi
    async fn flush_to_db(client: &Client, batch: &mut Vec<ConnectionLog>) {
        let count = batch.len();
        
        let mut insert = client.insert("connection_logs").unwrap();
        for log in batch.drain(..) {
            if let Err(e) = insert.write(&log).await {
                error!("ClickHouse Row yazma hatası: {}", e);
            }
        }
        
        match insert.end().await {
            Ok(_) => {
                debug!("ClickHouse: {} adet log batch olarak yazıldı.", count);
                metrics::counter!("db.clickhouse.batch_inserted", count as u64);
            }
            Err(e) => {
                error!("ClickHouse Batch Commit hatası: {}", e);
                // Production: Başarısız batch'ler MQ'ya (Kafka/RabbitMQ) geri itilebilir
                metrics::counter!("db.clickhouse.insert_failed", count as u64);
            }
        }
    }
}

#[async_trait]
impl LawfulInterceptRepository for ClickHouseLawfulIntercept {
    
    /// Cihaz ağa bağlandığında (Event 1)
    async fn log_connection_open(&self, peer: &AuthenticatedPeer) {
        let log = ConnectionLog {
            session_id: Uuid::new_v4().to_string(), // Temsili (gerçekte JWT JTI olabilir)
            user_id: peer.user_id.to_string(),
            device_id: peer.device_id.to_string(),
            node_id: self.node_id.to_string(),
            ip_hash: peer.ip_hash.to_string(),
            platform: peer.platform.clone(),
            event_type: 1, // 1 = Bağlandı
            connected_at: chrono::Utc::now().timestamp() as u32,
            duration_ms: 0,
        };

        // try_send: Kanal doluysa Gateway thread'ini (işlemi) blocklamaz.
        // Log kaybetmek (nadir de olsa) Gateway'in çökmesinden iyidir.
        if let Err(e) = self.log_tx.try_send(log) {
            error!("Lawful Intercept log kanalı dolu, log kaybedildi: {}", e);
            metrics::counter!("db.clickhouse.dropped", 1);
        }
    }

    /// Cihaz ağdan koptuğunda (Event 2)
    async fn log_connection_close(&self, peer: &AuthenticatedPeer, duration_ms: u64) {
        let log = ConnectionLog {
            session_id: Uuid::new_v4().to_string(),
            user_id: peer.user_id.to_string(),
            device_id: peer.device_id.to_string(),
            node_id: self.node_id.to_string(),
            ip_hash: peer.ip_hash.to_string(),
            platform: peer.platform.clone(),
            event_type: 2, // 2 = Koptu
            connected_at: peer.connected_at.elapsed().as_secs() as u32,
            duration_ms: duration_ms as u32,
        };

        let _ = self.log_tx.try_send(log);
    }
}
