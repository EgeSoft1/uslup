// =============================================================================
// TurkiyeMesajlasma — Domain Hata Tipleri
// Crate: domain
// Dosya: crates/domain/src/errors.rs
// =============================================================================

use thiserror::Error;
use uuid::Uuid;

/// Platform genelinde kullanılan birleşik hata tipi
#[derive(Debug, Error)]
pub enum PlatformError {
    // ── Kimlik Doğrulama Hataları ─────────────────────────────────────────
    #[error("Geçersiz kimlik bilgileri")]
    InvalidCredentials,

    #[error("JWT token geçersiz veya süresi dolmuş")]
    InvalidToken,

    #[error("Oturum bulunamadı: {session_id}")]
    SessionNotFound { session_id: Uuid },

    #[error("Hesap kilitli: {until} tarihine kadar")]
    AccountLocked { until: chrono::DateTime<chrono::Utc> },

    #[error("Yetersiz yetki: {required_role} rolü gerekli")]
    InsufficientPermissions { required_role: String },

    // ── Şifreleme Hataları ────────────────────────────────────────────────
    #[error("Pre-key bulunamadı: cihaz {device_id}")]
    PreKeyExhausted { device_id: Uuid },

    #[error("Signal Protocol hatası: {reason}")]
    SignalProtocolError { reason: String },

    #[error("Geçersiz şifreli mesaj zarfı")]
    InvalidCiphertext,

    #[error("HMAC doğrulama başarısız")]
    HmacVerificationFailed,

    // ── Mesajlaşma Hataları ───────────────────────────────────────────────
    #[error("Kullanıcı bulunamadı: {user_id}")]
    UserNotFound { user_id: Uuid },

    #[error("Cihaz bulunamadı: {device_id}")]
    DeviceNotFound { device_id: Uuid },

    #[error("Sohbet bulunamadı: {conversation_id}")]
    ConversationNotFound { conversation_id: Uuid },

    #[error("Grup bulunamadı: {group_id}")]
    GroupNotFound { group_id: Uuid },

    #[error("Mesaj boyutu aşıldı: {size} byte (max: {max_size})")]
    MessageTooLarge { size: usize, max_size: usize },

    // ── Hız Sınırı Hataları ───────────────────────────────────────────────
    #[error("Hız sınırı aşıldı: {retry_after_ms} ms sonra tekrar dene")]
    RateLimitExceeded { retry_after_ms: u64 },

    #[error("Çok fazla bağlantı: IP başına maksimum {max_connections}")]
    ConnectionLimitExceeded { max_connections: u32 },

    // ── Altyapı Hataları ──────────────────────────────────────────────────
    #[error("Veritabanı hatası: {source}")]
    DatabaseError {
        #[source]
        source: anyhow::Error,
    },

    #[error("Önbellek hatası: {source}")]
    CacheError {
        #[source]
        source: anyhow::Error,
    },

    #[error("Dahili sistem hatası: {message}")]
    InternalError { message: String },

    #[error("Servis geçici olarak kullanılamıyor")]
    ServiceUnavailable,
}

impl PlatformError {
    /// HTTP durum kodu eşlemesi (Axum'da kullanılır)
    pub fn http_status_code(&self) -> u16 {
        match self {
            Self::InvalidCredentials
            | Self::InvalidToken
            | Self::HmacVerificationFailed
            | Self::InvalidCiphertext => 401,

            Self::InsufficientPermissions { .. } => 403,

            Self::UserNotFound { .. }
            | Self::DeviceNotFound { .. }
            | Self::ConversationNotFound { .. }
            | Self::GroupNotFound { .. }
            | Self::SessionNotFound { .. } => 404,

            Self::MessageTooLarge { .. } => 413,

            Self::RateLimitExceeded { .. }
            | Self::ConnectionLimitExceeded { .. } => 429,

            Self::AccountLocked { .. } => 423,

            Self::PreKeyExhausted { .. }
            | Self::SignalProtocolError { .. } => 422,

            Self::DatabaseError { .. }
            | Self::CacheError { .. }
            | Self::InternalError { .. } => 500,

            Self::ServiceUnavailable => 503,
        }
    }

    /// Hatanın istemciye güvenle gönderilebilir hata kodu
    pub fn error_code(&self) -> &'static str {
        match self {
            Self::InvalidCredentials => "AUTH_INVALID_CREDENTIALS",
            Self::InvalidToken => "AUTH_INVALID_TOKEN",
            Self::SessionNotFound { .. } => "AUTH_SESSION_NOT_FOUND",
            Self::AccountLocked { .. } => "AUTH_ACCOUNT_LOCKED",
            Self::InsufficientPermissions { .. } => "AUTH_FORBIDDEN",
            Self::PreKeyExhausted { .. } => "CRYPTO_PRE_KEY_EXHAUSTED",
            Self::SignalProtocolError { .. } => "CRYPTO_SIGNAL_ERROR",
            Self::InvalidCiphertext => "CRYPTO_INVALID_CIPHERTEXT",
            Self::HmacVerificationFailed => "CRYPTO_HMAC_FAILED",
            Self::UserNotFound { .. } => "MSG_USER_NOT_FOUND",
            Self::DeviceNotFound { .. } => "MSG_DEVICE_NOT_FOUND",
            Self::ConversationNotFound { .. } => "MSG_CONVERSATION_NOT_FOUND",
            Self::GroupNotFound { .. } => "MSG_GROUP_NOT_FOUND",
            Self::MessageTooLarge { .. } => "MSG_TOO_LARGE",
            Self::RateLimitExceeded { .. } => "RATE_LIMIT_EXCEEDED",
            Self::ConnectionLimitExceeded { .. } => "CONN_LIMIT_EXCEEDED",
            Self::DatabaseError { .. }
            | Self::CacheError { .. }
            | Self::InternalError { .. } => "INTERNAL_ERROR",
            Self::ServiceUnavailable => "SERVICE_UNAVAILABLE",
        }
    }
}

pub type PlatformResult<T> = Result<T, PlatformError>;
