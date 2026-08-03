// =============================================================================
// TurkiyeMesajlasma — Gateway Konfigürasyonu
// Dosya: crates/gateway-ws/src/config.rs
// =============================================================================

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GatewayConfig {
    // ── Ağ ────────────────────────────────────────────────────────────────────
    /// WebSocket bağlantılarını dinleyeceği adres
    pub listen_addr: String,

    /// gRPC inter-node iletişim portu
    pub grpc_listen_addr: String,

    /// Prometheus metrik sunucu adresi (dahili)
    pub metrics_addr: String,

    // ── Kapasite ──────────────────────────────────────────────────────────────
    /// Bu node'un kaldırabileceği maksimum eşzamanlı bağlantı
    /// Recommendation: CPU core sayısı × 50.000
    pub max_connections: u64,

    /// Tokio worker thread sayısı (varsayılan: CPU core sayısı)
    pub worker_threads: Option<usize>,

    // ── DragonflyDB ───────────────────────────────────────────────────────────
    pub dragonfly_cluster_urls: Vec<String>,
    pub dragonfly_password: Option<String>,
    pub dragonfly_tls: bool,
    pub dragonfly_pool_size: u32,

    // ── CockroachDB ───────────────────────────────────────────────────────────
    pub cockroachdb_url: String,
    pub cockroachdb_pool_min: u32,
    pub cockroachdb_pool_max: u32,

    // ── ScyllaDB ──────────────────────────────────────────────────────────────
    pub scylladb_hosts: Vec<String>,
    pub scylladb_keyspace: String,
    pub scylladb_port: u16,

    // ── JWT ───────────────────────────────────────────────────────────────────
    /// Ed25519 public key (Base64) — JWT doğrulama için
    /// Private key yalnızca auth-service'te bulunur
    pub jwt_public_key_base64: String,
    pub jwt_issuer: String,

    // ── Rate Limiting ─────────────────────────────────────────────────────────
    pub rate_limit_messages_per_minute: u32,
    pub rate_limit_connections_per_ip_per_10s: u32,

    // ── Observability ─────────────────────────────────────────────────────────
    pub otel_endpoint: Option<String>,
    pub log_level: String,

    // ── Node Bilgisi ──────────────────────────────────────────────────────────
    pub region: String,
    pub datacenter: String,
    pub availability_zone: String,
}

impl GatewayConfig {
    /// Ortam değişkenlerinden konfigürasyonu yükle
    pub fn from_env() -> Result<Self> {
        dotenvy::dotenv().ok(); // .env dosyasını yükle (production'da yok)

        Ok(Self {
            listen_addr: std::env::var("LISTEN_ADDR")
                .unwrap_or_else(|_| "0.0.0.0:8080".to_string()),

            grpc_listen_addr: std::env::var("GRPC_LISTEN_ADDR")
                .unwrap_or_else(|_| "0.0.0.0:9090".to_string()),

            metrics_addr: std::env::var("METRICS_ADDR")
                .unwrap_or_else(|_| "0.0.0.0:9091".to_string()),

            max_connections: std::env::var("MAX_CONNECTIONS")
                .unwrap_or_else(|_| "500000".to_string())
                .parse()
                .context("MAX_CONNECTIONS geçersiz sayı")?,

            worker_threads: std::env::var("WORKER_THREADS")
                .ok()
                .and_then(|v| v.parse().ok()),

            dragonfly_cluster_urls: std::env::var("DRAGONFLY_CLUSTER_URLS")
                .unwrap_or_else(|_| "redis://localhost:6379".to_string())
                .split(',')
                .map(String::from)
                .collect(),

            dragonfly_password: std::env::var("DRAGONFLY_PASSWORD").ok(),

            dragonfly_tls: std::env::var("DRAGONFLY_TLS")
                .map(|v| v == "true")
                .unwrap_or(false),

            dragonfly_pool_size: std::env::var("DRAGONFLY_POOL_SIZE")
                .unwrap_or_else(|_| "256".to_string())
                .parse()
                .context("DRAGONFLY_POOL_SIZE geçersiz")?,

            cockroachdb_url: std::env::var("COCKROACHDB_URL")
                .unwrap_or_else(|_| {
                    "postgresql://root@localhost:26257/turkiye_mesajlasma?sslmode=disable"
                        .to_string()
                }),

            cockroachdb_pool_min: 5,
            cockroachdb_pool_max: 50,

            scylladb_hosts: std::env::var("SCYLLADB_HOSTS")
                .unwrap_or_else(|_| "127.0.0.1".to_string())
                .split(',')
                .map(String::from)
                .collect(),

            scylladb_keyspace: "turkiye_mesajlasma".to_string(),
            scylladb_port: 9042,

            jwt_public_key_base64: std::env::var("JWT_PUBLIC_KEY")
                .context("JWT_PUBLIC_KEY env var zorunlu")?,

            jwt_issuer: std::env::var("JWT_ISSUER")
                .unwrap_or_else(|_| "turkiye-mesajlasma.com".to_string()),

            rate_limit_messages_per_minute: std::env::var("RATE_LIMIT_MESSAGES_PER_MIN")
                .unwrap_or_else(|_| "100".to_string())
                .parse()
                .unwrap_or(100),

            rate_limit_connections_per_ip_per_10s: std::env::var("RATE_LIMIT_CONN_PER_10S")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .unwrap_or(10),

            otel_endpoint: std::env::var("OTEL_EXPORTER_OTLP_ENDPOINT").ok(),

            log_level: std::env::var("LOG_LEVEL")
                .unwrap_or_else(|_| "info".to_string()),

            region: std::env::var("REGION")
                .unwrap_or_else(|_| "tr-istanbul".to_string()),

            datacenter: std::env::var("DATACENTER")
                .unwrap_or_else(|_| "tr-dc".to_string()),

            availability_zone: std::env::var("AVAILABILITY_ZONE")
                .unwrap_or_else(|_| "az1".to_string()),
        })
    }
}
