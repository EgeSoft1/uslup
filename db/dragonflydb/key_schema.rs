// =============================================================================
// TurkiyeMesajlasma Platform - DragonflyDB Key Schema & Pub/Sub Tasarımı
// Dosya: db/dragonflydb/key_schema.rs
//
// DragonflyDB: Redis uyumlu, çok çekirdekli, yüksek performanslı bellek içi DB
// Kullanım Alanları:
//   1. Presence sistemi (online/offline durumu)
//   2. Son görülme (last seen)
//   3. "Yazıyor..." göstergesi (typing indicator)
//   4. Node-to-Node mesaj yönlendirme haritası
//   5. OTP ve geçici token yönetimi
//   6. Rate limiting (DDoS koruması)
//   7. WebSocket bağlantı indeksi
// =============================================================================

/// DragonflyDB'deki tüm key prefix'lerini ve TTL'lerini tanımlayan sabitler
/// Bu modül tüm servisler tarafından import edilir (tek kaynak hakikati)
pub mod dragonfly_keys {

    // =========================================================================
    // PRESENCE SİSTEMİ
    // =========================================================================

    /// Kullanıcının online durumu
    /// Format: presence:user:<user_id>
    /// Value:  JSON { "status": "online|away|busy", "node_id": "ws-node-07", "updated_at": "<unix_ms>" }
    /// TTL:    30 saniye (heartbeat her 25 saniyede bir refresh eder)
    ///         TTL dolunca kullanıcı otomatik offline sayılır
    pub const PRESENCE_KEY: &str = "presence:user:{}";
    pub const PRESENCE_TTL_SECONDS: u64 = 30;

    /// Kullanıcının aktif WebSocket bağlantısının olduğu sunucu node
    /// Format: ws:node:<user_id>:<device_id>
    /// Value:  node_id (örn: "ws-gateway-istanbul-03")
    /// TTL:    60 saniye (bağlantı kesilince otomatik temizlenir)
    pub const WS_NODE_KEY: &str = "ws:node:{}:{}";
    pub const WS_NODE_TTL_SECONDS: u64 = 60;

    // =========================================================================
    // SON GÖRÜLME (LAST SEEN)
    // =========================================================================

    /// Son görülme zaman damgası
    /// Format: lastseen:<user_id>
    /// Value:  Unix millisecond timestamp (i64 string)
    /// TTL:    yok (kalıcı - kullanıcı her bağlandığında güncellenir)
    pub const LAST_SEEN_KEY: &str = "lastseen:{}";

    // =========================================================================
    // YAZIYOR... GÖSTERGESİ (TYPING INDICATOR)
    // =========================================================================

    /// Bir kullanıcının belirli bir sohbette yazma durumu
    /// Format: typing:<conversation_id>:<user_id>
    /// Value:  "1" (aktif yazıyor)
    /// TTL:    5 saniye (kullanıcı yazmayı durdurursa otomatik kapanır)
    pub const TYPING_KEY: &str = "typing:{}:{}";
    pub const TYPING_TTL_SECONDS: u64 = 5;

    // =========================================================================
    // MESAJ YÖNLENDİRME (NODE-TO-NODE ROUTING)
    // =========================================================================

    /// Pub/Sub channel: Bir kullanıcıya gelen mesajların yayınlandığı kanal
    /// Format: msg:channel:<user_id>
    /// Kullanım: Publisher (gönderici servisi) bu kanala yayınlar,
    ///           Subscriber (alıcının bağlı olduğu WS gateway) dinler
    pub const MSG_CHANNEL: &str = "msg:channel:{}";

    /// Pending mesaj kuyruku (kullanıcı çevrimdışı, ama bellek içi geçici kuyruk)
    /// Format: msg:queue:<device_id>
    /// Type:   Redis List (LPUSH/RPOP)
    /// TTL:    300 saniye (5 dakika - kalıcı depolama ScyllaDB'de)
    pub const MSG_QUEUE_KEY: &str = "msg:queue:{}";
    pub const MSG_QUEUE_TTL_SECONDS: u64 = 300;
    pub const MSG_QUEUE_MAX_LEN: u64 = 1000; // LTRIM ile sınırla

    // =========================================================================
    // OTP ve GEÇİCİ TOKEN YÖNETİMİ
    // =========================================================================

    /// SMS OTP doğrulama kodu
    /// Format: otp:sms:<phone_number_hash>
    /// Value:  JSON { "code_hash": "<argon2 hash>", "attempts": 0 }
    /// TTL:    180 saniye (3 dakika)
    pub const OTP_SMS_KEY: &str = "otp:sms:{}";
    pub const OTP_SMS_TTL_SECONDS: u64 = 180;

    /// OTP deneme sayacı (brute force koruması)
    /// Format: otp:attempts:<phone_number_hash>
    /// Value:  deneme sayısı (integer)
    /// TTL:    3600 saniye (1 saat)
    pub const OTP_ATTEMPTS_KEY: &str = "otp:attempts:{}";
    pub const OTP_ATTEMPTS_TTL_SECONDS: u64 = 3600;
    pub const OTP_MAX_ATTEMPTS: u32 = 5;

    /// JWT refresh token (geçici, DB'ye yazılmadan önce validation için)
    /// Format: session:refresh:<token_hash>
    /// Value:  JSON { "user_id": "...", "device_id": "...", "issued_at": "..." }
    /// TTL:    604800 saniye (7 gün)
    pub const SESSION_REFRESH_KEY: &str = "session:refresh:{}";
    pub const SESSION_REFRESH_TTL_SECONDS: u64 = 604800;

    // =========================================================================
    // RATE LİMİTİNG
    // =========================================================================

    /// Mesaj gönderme hız sınırı (spam koruması)
    /// Format: rl:msg:<user_id>
    /// Value:  INCR ile sayaç
    /// TTL:    60 saniye
    /// Limit:  60 saniyede 100 mesaj
    pub const RATE_LIMIT_MSG_KEY: &str = "rl:msg:{}";
    pub const RATE_LIMIT_MSG_TTL_SECONDS: u64 = 60;
    pub const RATE_LIMIT_MSG_MAX: u32 = 100;

    /// WS bağlantı kurma hız sınırı (DDoS koruması)
    /// Format: rl:conn:<ip_hash>
    /// Value:  INCR ile sayaç
    /// TTL:    10 saniye
    /// Limit:  10 saniyede 10 bağlantı
    pub const RATE_LIMIT_CONN_KEY: &str = "rl:conn:{}";
    pub const RATE_LIMIT_CONN_TTL_SECONDS: u64 = 10;
    pub const RATE_LIMIT_CONN_MAX: u32 = 10;

    // =========================================================================
    // WEBSOCKET BAĞLANTI İNDEKSİ
    // =========================================================================

    /// Belirli bir node üzerindeki aktif WS bağlantıları (Set)
    /// Format: ws:connections:<node_id>
    /// Type:   Redis Set (SADD/SREM)
    /// Value:  Set<user_id:device_id>
    /// TTL:    yok (node restart olunca sıfırlanır)
    pub const WS_CONNECTIONS_SET: &str = "ws:connections:{}";

    /// Toplam aktif bağlantı sayısı (monitoring için)
    /// Format: ws:total:connections
    /// Type:   Integer
    pub const WS_TOTAL_CONNECTIONS: &str = "ws:total:connections";

    // =========================================================================
    // OPK ALARMLAR
    // =========================================================================

    /// Bir cihazın OPK sayısının kritik eşiğin altına düştüğü uyarısı
    /// Format: opk:low:<device_id>
    /// Value:  kalan OPK sayısı
    /// TTL:    86400 saniye (1 gün - bir kez uyarı gönder)
    pub const OPK_LOW_KEY: &str = "opk:low:{}";
    pub const OPK_LOW_TTL_SECONDS: u64 = 86400;
    pub const OPK_CRITICAL_THRESHOLD: u32 = 10; // 10'un altında kritik

    // =========================================================================
    // GRUP PRESENCE
    // =========================================================================

    /// Bir gruptaki online üye sayısı ve listesi (Sorted Set)
    /// Format: group:online:<group_id>
    /// Type:   Sorted Set (ZADD score=unix_timestamp member=user_id)
    /// TTL:    yok (presence expire olunca ZREMRANGEBYSCORE ile temizle)
    pub const GROUP_ONLINE_KEY: &str = "group:online:{}";
}

// =============================================================================
// ÖRNEK KULLANIM: Presence Servisi
// =============================================================================

use std::collections::HashMap;

/// Presence kaydı (DragonflyDB'de JSON olarak saklanır)
#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct PresenceRecord {
    pub status: PresenceStatus,
    pub node_id: String,
    pub updated_at: i64,    // Unix milliseconds
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PresenceStatus {
    Online,
    Away,
    Busy,
    Offline,
}

// Not: Gerçek implementasyonda fred veya redis-rs kullanılır.
// Bu yapılar Redis protokol uyumlu DragonflyDB ile çalışır.

/// DragonflyDB bağlantı havuzu yapılandırması
pub struct DragonflyConfig {
    /// Primary endpoint (yazma için)
    pub primary_url: String,
    /// Replica endpoint'leri (okuma için - yük dağılımı)
    pub replica_urls: Vec<String>,
    /// Bağlantı havuzu boyutu
    pub pool_size: u32,
    /// Bağlantı zaman aşımı
    pub connect_timeout_ms: u64,
    /// Komut zaman aşımı
    pub command_timeout_ms: u64,
    /// TLS aktif mi
    pub tls_enabled: bool,
}

impl DragonflyConfig {
    pub fn production() -> Self {
        Self {
            primary_url: std::env::var("DRAGONFLY_PRIMARY_URL")
                .unwrap_or_else(|_| "rediss://dragonfly-primary:6379".to_string()),
            replica_urls: std::env::var("DRAGONFLY_REPLICA_URLS")
                .unwrap_or_default()
                .split(',')
                .filter(|s| !s.is_empty())
                .map(String::from)
                .collect(),
            pool_size: 256,             // Yüksek CCU için büyük havuz
            connect_timeout_ms: 1000,   // 1 saniye
            command_timeout_ms: 100,    // 100ms (bellek içi, çok hızlı olmalı)
            tls_enabled: true,
        }
    }

    pub fn development() -> Self {
        Self {
            primary_url: "redis://localhost:6380".to_string(),
            replica_urls: vec![],
            pool_size: 16,
            connect_timeout_ms: 5000,
            command_timeout_ms: 1000,
            tls_enabled: false,
        }
    }
}

// =============================================================================
// DRAGONFLY CLUSTER YAPILANDIRMASI NOTU:
// =============================================================================
// DragonflyDB, Redis Cluster protokolünü destekler.
// 150M CCU için önerilen kurulum:
//   - 3 Primary node (sharding): her biri farklı hash slot aralığı
//   - 3 Replica node (her primary için 1 replica)
//   - Toplam: 6 node, her biri 256GB RAM
//
// Slot dağılımı:
//   Primary 1: Slots 0-5460    (İstanbul AZ1)
//   Primary 2: Slots 5461-10922 (İstanbul AZ2)
//   Primary 3: Slots 10923-16383 (Ankara)
//
// Hash tag kullanımı:
//   Aynı kullanıcının tüm key'lerini aynı slot'ta tutmak için:
//   "presence:{user_id}" -> {user_id} hash tag ile aynı slot'a yönlendirilir
//   Bu sayede kullanıcı bazlı pipeline/MULTI-EXEC işlemleri mümkün
// =============================================================================
