// =============================================================================
// TurkiyeMesajlasma — Gateway Ana Giriş Noktası (Entrypoint)
// Dosya: crates/gateway-ws/src/main.rs
//
// MİMARİ OPTİMİZASYONLAR:
// 1. Mimalloc: Yüz binlerce küçük tahsisat (WebSocket frame) için standart 
//    malloc'tan çok daha az fragmentation yapan ve çok daha hızlı olan allocator.
// 2. SO_REUSEPORT (Socket Sharding): Aynı porta birden fazla thread'in bind
//    olmasını sağlar. Kernel, gelen TCP bağlantılarını Epoll kilitlenmesi
//    yaşatmadan thread'lere dağıtır.
// 3. Graceful Shutdown: SIGINT/SIGTERM geldiğinde yeni bağlantı reddedilir 
//    ama mevcutlar işini bitirmeden kapanmaz.
// =============================================================================

use std::net::SocketAddr;
use std::sync::Arc;
use tokio::signal;
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

// Standart bellek yöneticisi yerine mimalloc kullan (Performans x2)
#[global_allocator]
static GLOBAL: mimalloc::MiMalloc = mimalloc::MiMalloc;

// İç modüller
mod config;
mod connection;
mod middleware;
mod router;

// AppState vb. (gerçekte crates/domain içinde veya ayrı dosyada tanımlanır)
pub use crate::config::GatewayConfig;

// Tokio multi-thread runtime (İşletim sistemi thread sayısı kadar çalışır)
#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    // ── 1. Loglama (Tracing) Başlatılması ─────────────────────────────────────
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .finish();
    tracing::subscriber::set_global_default(subscriber)
        .expect("Tracing başlatılamadı");

    // ── 2. Konfigürasyon ve Bağımlılıkların Yüklenmesi ────────────────────────
    let config = GatewayConfig::from_env()?;
    info!("Gateway başlatılıyor... Bölge: {}", config.region);

    // Uygulama durumu (Bağımlılık enjeksiyonu)
    let state = AppState::new(config.clone()).await?;
    let app = router::build_router(state);

    let listen_addr: SocketAddr = config.listen_addr.parse()?;

    // ── 3. SO_REUSEPORT (Socket Sharding) ile Soket Oluşturma ─────────────────
    // Neden axum::Server::bind kullanmıyoruz? Çünkü tek bir listener thread 
    // saniyede 10.000+ yeni TCP bağlantısında darboğaz (bottleneck) oluşturur.
    
    let socket = socket2::Socket::new(
        socket2::Domain::IPV4,
        socket2::Type::STREAM,
        Some(socket2::Protocol::TCP),
    )?;

    // Nagle algoritmasını kapat (Zero-lag için kritik)
    socket.set_nodelay(true)?;

    // Linux/Unix'te SO_REUSEPORT aç (Birden fazla process/thread aynı portu dinlesin)
    #[cfg(unix)]
    {
        socket.set_reuse_port(true)?;
    }

    // Soketi adrese bağla ve dinlemeye başla
    socket.bind(&listen_addr.into())?;
    socket.listen(65535)?; // Backlog queue boyutu (Aşırı yığılmalar için yüksek)

    // socket2::Socket'i std::net::TcpListener'a çevir, oradan Tokio'ya aktar
    let std_listener: std::net::TcpListener = socket.into();
    std_listener.set_nonblocking(true)?;
    let listener = tokio::net::TcpListener::from_std(std_listener)?;

    info!("WebSocket Gateway {} adresinde dinliyor (SO_REUSEPORT aktif)", listen_addr);

    // ── 4. Sunucuyu Başlat ve Kapanma (Shutdown) Sinyalini Bekle ─────────────
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown_signal())
    .await?;

    info!("Gateway güvenli bir şekilde kapatıldı.");
    Ok(())
}

/// SIGTERM (Kubernetes Pod terminating) veya SIGINT (Ctrl+C) sinyallerini yakalar.
async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("Ctrl+C sinyali dinlenemedi");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("SIGTERM dinlenemedi")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => { info!("Ctrl+C alındı, kapanıyor..."); },
        _ = terminate => { info!("SIGTERM alındı, kapanıyor..."); },
    }
}

// ─── Prototip Mock Servisler ────────────────────────────────────────────────
#[derive(Clone)]
pub struct AuthMock;
impl AuthMock {
    pub async fn verify_jwt(&self, token: &str) -> Result<crate::connection::AuthenticatedPeer, anyhow::Error> {
        // Mock token doğrulama
        Ok(crate::connection::AuthenticatedPeer {
            user_id: uuid::Uuid::new_v4(),
            device_id: uuid::Uuid::new_v4(),
            region_code: "TR".to_string(),
            platform: "Windows".to_string(),
            connected_at: std::time::Instant::now(),
            ip_hash: Arc::from("mock_ip_hash"),
        })
    }
}

#[derive(Clone)]
pub struct PresenceMock;
impl PresenceMock {
    pub async fn set_online(&self, _u: uuid::Uuid, _d: uuid::Uuid, _n: &str) -> Result<(), anyhow::Error> { Ok(()) }
    pub async fn set_offline(&self, _u: uuid::Uuid, _d: uuid::Uuid) -> Result<(), anyhow::Error> { Ok(()) }
    pub async fn set_typing(&self, _u: uuid::Uuid, _c: uuid::Uuid, _t: bool) -> Result<(), anyhow::Error> { Ok(()) }
}

#[derive(Clone)]
pub struct LawfulInterceptMock;
impl LawfulInterceptMock {
    pub async fn log_connection_open(&self, _p: &crate::connection::AuthenticatedPeer) {}
    pub async fn log_connection_close(&self, _p: &crate::connection::AuthenticatedPeer, _d: u64) {}
}

#[derive(Clone)]
pub struct RateLimiterMock;
impl RateLimiterMock {
    pub async fn check_message_rate(&self, _u: uuid::Uuid) -> Result<(), anyhow::Error> { Ok(()) }
}

#[derive(Clone)]
pub struct MessageRouterMock;
impl MessageRouterMock {
    pub async fn route_to_device(&self, _d: uuid::Uuid, _m: Vec<u8>) -> Result<(), anyhow::Error> { Ok(()) }
}

#[derive(Clone)]
pub struct MessageStoreMock;
impl MessageStoreMock {
    pub async fn persist_envelope(&self, _p: &crate::connection::AuthenticatedPeer, _e: proto::EncryptedEnvelope) -> Result<(), anyhow::Error> { Ok(()) }
    pub async fn mark_read(&self, _u: uuid::Uuid, _d: uuid::Uuid, _r: proto::ReadReceipt) -> Result<(), anyhow::Error> { Ok(()) }
}

#[derive(Clone)]
pub struct MockServices {
    pub auth: AuthMock,
    pub connections: std::sync::Arc<crate::connection::ConnectionRegistry>,
    pub presence: PresenceMock,
    pub lawful_intercept: LawfulInterceptMock,
    pub rate_limiter: RateLimiterMock,
    pub message_router: MessageRouterMock,
    pub message_store: MessageStoreMock,
    pub qr_service: std::sync::Arc<infrastructure::qr_service::QrService>,
}
impl MockServices {
    pub async fn dragonfly_ping(&self) -> Result<(), anyhow::Error> { Ok(()) }
    pub async fn cockroach_ping(&self) -> Result<(), anyhow::Error> { Ok(()) }
}

#[derive(Clone)]
pub struct AppState {
    pub config: GatewayConfig,
    pub node_id: Arc<str>,
    pub services: MockServices,
}
impl AppState {
    pub async fn new(config: GatewayConfig) -> Result<Self, anyhow::Error> {
        Ok(Self { 
            config, 
            node_id: Arc::from("gateway-01"),
            services: MockServices {
                auth: AuthMock,
                connections: std::sync::Arc::new(crate::connection::ConnectionRegistry::new()),
                presence: PresenceMock,
                lawful_intercept: LawfulInterceptMock,
                rate_limiter: RateLimiterMock,
                message_router: MessageRouterMock,
                message_store: MessageStoreMock,
                qr_service: std::sync::Arc::new(infrastructure::qr_service::QrService::new()),
            }
        })
    }
}
