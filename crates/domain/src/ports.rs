// =============================================================================
// TurkiyeMesajlasma — Domain Port (Arayüz) Tanımları
// Crate: domain
// Dosya: crates/domain/src/ports.rs
//
// Hexagonal Architecture: Port'lar dışa bağımlılığı soyutlar.
// Infrastructure katmanı bu trait'leri implement eder.
// =============================================================================

use async_trait::async_trait;
use uuid::Uuid;
use crate::errors::PlatformResult;

// ─── Mesaj Yönlendirme Port'u ─────────────────────────────────────────────────

/// Mesajı hedef kullanıcıya iletmek için kullanılan soyut arayüz
/// İmplementasyon: DragonflyDB Pub/Sub üzerinden node-to-node yönlendirme
#[async_trait]
pub trait MessageRouter: Send + Sync + 'static {
    /// Şifreli mesaj zarfını hedef cihaza yönlendir
    async fn route_to_device(
        &self,
        recipient_device_id: Uuid,
        envelope: Vec<u8>,  // Protobuf serialize edilmiş MessageEnvelope
    ) -> PlatformResult<RoutingResult>;

    /// Birden fazla cihaza yönlendir (grup mesajı)
    async fn route_to_devices(
        &self,
        recipient_device_ids: &[Uuid],
        envelope: Vec<u8>,
    ) -> PlatformResult<Vec<(Uuid, RoutingResult)>>;
}

#[derive(Debug)]
pub enum RoutingResult {
    /// Mesaj aktif WebSocket üzerinden teslim edildi
    DeliveredOnline,
    /// Kullanıcı çevrimdışı, mesaj offline kuyruğa alındı (ScyllaDB + push)
    QueuedOffline,
    /// Farklı node'a yönlendirildi (node-to-node gRPC)
    ForwardedToNode { node_id: String },
}

// ─── Presence Port'u ──────────────────────────────────────────────────────────

#[async_trait]
pub trait PresenceRepository: Send + Sync + 'static {
    /// Kullanıcıyı online olarak işaretle (heartbeat ile yenile)
    async fn set_online(&self, user_id: Uuid, device_id: Uuid, node_id: &str) -> PlatformResult<()>;

    /// Kullanıcıyı offline olarak işaretle
    async fn set_offline(&self, user_id: Uuid, device_id: Uuid) -> PlatformResult<()>;

    /// Kullanıcının online olup olmadığını ve hangi node'da olduğunu sorgula
    async fn get_presence(&self, user_id: Uuid) -> PlatformResult<Option<PresenceInfo>>;

    /// Son görülme zamanını güncelle
    async fn update_last_seen(&self, user_id: Uuid) -> PlatformResult<()>;

    /// Birden fazla kullanıcının presence durumunu toplu sorgula
    async fn batch_get_presence(&self, user_ids: &[Uuid]) -> PlatformResult<Vec<PresenceInfo>>;
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct PresenceInfo {
    pub user_id: Uuid,
    pub status: PresenceStatus,
    pub node_id: String,
    pub updated_at: i64, // Unix milliseconds
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum PresenceStatus {
    Online,
    Away,
    Busy,
    Offline,
}

// ─── WebSocket Bağlantı Yöneticisi Port'u ────────────────────────────────────

#[async_trait]
pub trait ConnectionRegistry: Send + Sync + 'static {
    /// Yeni WebSocket bağlantısını kaydet
    async fn register(&self, conn: ConnectionInfo) -> PlatformResult<()>;

    /// Bağlantıyı kaldır
    async fn unregister(&self, device_id: Uuid) -> PlatformResult<()>;

    /// Bir device'ın aktif bağlantısını bul
    async fn get_connection(&self, device_id: Uuid) -> Option<ConnectionHandle>;

    /// Bu node'daki toplam bağlantı sayısı
    fn connection_count(&self) -> usize;
}

#[derive(Debug, Clone)]
pub struct ConnectionInfo {
    pub device_id: Uuid,
    pub user_id: Uuid,
    pub node_id: String,
    pub connected_at: chrono::DateTime<chrono::Utc>,
    pub ip_hash: String,
}

/// WebSocket bağlantısına mesaj göndermek için handle
/// Clone'lanabilir, Send + Sync (Tokio mpsc sender)
pub type ConnectionHandle = tokio::sync::mpsc::UnboundedSender<Vec<u8>>;
