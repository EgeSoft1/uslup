// =============================================================================
// TurkiyeMesajlasma — JWT Auth Middleware ve Rate Limiter
// Dosya: crates/gateway-ws/src/middleware.rs
//
// Güvenlik katmanları:
//   1. IP bazlı bağlantı hız sınırlayıcı (DDoS koruması)
//   2. JWT doğrulama (Ed25519 imzalı)
//   3. IP hash'leme (KVKK: ham IP loglanmaz)
// =============================================================================

use std::net::IpAddr;

use axum::{
    extract::{ConnectInfo, Request, State},
    http::StatusCode,
    middleware::Next,
    response::Response,
};
use sha2::{Digest, Sha256};
use tracing::warn;

use crate::AppState;

// ─── IP Hash (KVKK Uyumu) ─────────────────────────────────────────────────────

/// IP adresini güvenli hash'e çevir (Lawful Intercept'te saklanacak olan)
/// SHA-256(IP + günlük_salt): KVKK - ham IP adresleri plaintext saklanamaz
pub fn hash_ip(ip: &str) -> String {
    // Günlük tuz: her gün farklı hash üretir (kısa vadeli tracking önler)
    // Production'da: HSM'den günlük tuz alınır
    let today = chrono::Utc::now().format("%Y-%m-%d").to_string();
    let salt = std::env::var("IP_HASH_SALT").unwrap_or_else(|_| "default-salt".to_string());

    let mut hasher = Sha256::new();
    hasher.update(ip.as_bytes());
    hasher.update(today.as_bytes());
    hasher.update(salt.as_bytes());

    format!("{:x}", hasher.finalize())
}

// ─── Bağlantı Hız Sınırlayıcı ────────────────────────────────────────────────

/// IP başına bağlantı hız sınırı (DDoS koruması)
/// DragonflyDB'de sliding window counter kullanır
pub async fn connection_rate_limit(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<std::net::SocketAddr>,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    // WebSocket endpoint için kontrol et
    if request.uri().path() != "/ws" {
        return Ok(next.run(request).await);
    }

    let ip = addr.ip().to_string();
    let ip_hash = hash_ip(&ip);
    let key = format!("rl:conn:{}", ip_hash);

    // DragonflyDB'de rate limit sayacını artır ve kontrol et
    let count: u32 = match state.services.dragonfly_incr_with_expiry(&key, 10).await {
        Ok(c) => c,
        Err(e) => {
            warn!("Rate limit kontrolü başarısız (izin ver): {}", e);
            return Ok(next.run(request).await); // Hata durumunda geçir
        }
    };

    if count > state.config.rate_limit_connections_per_ip_per_10s {
        warn!(
            ip_hash = %ip_hash,
            count = count,
            "Bağlantı hız sınırı aşıldı"
        );
        metrics::counter!("rate_limit.connection.exceeded", 1);
        return Err(StatusCode::TOO_MANY_REQUESTS);
    }

    Ok(next.run(request).await)
}

// ─── JWT Claims ───────────────────────────────────────────────────────────────

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct JwtClaims {
    /// Subject: user_id (UUID)
    pub sub: String,
    /// JWT ID: session_id (benzersizlik)
    pub jti: String,
    /// Issued At (Unix timestamp)
    pub iat: i64,
    /// Expiry (Unix timestamp)
    pub exp: i64,
    /// İssuer
    pub iss: String,

    // Platform custom claims
    pub user_id: uuid::Uuid,
    pub device_id: uuid::Uuid,
    pub region_code: String,
    pub platform: String,
    pub phone_hash: String, // Telefon numarası hash'i (doğrulama için)
}

// ─── JWT Doğrulama Servisi ─────────────────────────────────────────────────────

pub struct JwtAuthService {
    decoding_key: jsonwebtoken::DecodingKey,
    validation: jsonwebtoken::Validation,
}

impl JwtAuthService {
    pub fn new(public_key_base64: &str, issuer: &str) -> Result<Self, anyhow::Error> {
        // Base64'ten Ed25519 public key decode et
        let key_bytes = base64::engine::general_purpose::STANDARD
            .decode(public_key_base64)
            .map_err(|e| anyhow::anyhow!("Public key decode hatası: {}", e))?;

        let decoding_key = jsonwebtoken::DecodingKey::from_ed_der(&key_bytes)
            .map_err(|e| anyhow::anyhow!("DecodingKey oluşturulamadı: {}", e))?;

        let mut validation = jsonwebtoken::Validation::new(
            jsonwebtoken::Algorithm::EdDSA // Ed25519
        );
        validation.set_issuer(&[issuer]);
        validation.validate_exp = true;
        validation.validate_nbf = true;
        validation.leeway = 30; // 30 saniye saat sapması toleransı

        Ok(Self {
            decoding_key,
            validation,
        })
    }

    /// JWT doğrula ve claims döndür
    pub async fn verify_jwt(&self, token: &str) -> Result<JwtClaims, anyhow::Error> {
        let token_data = jsonwebtoken::decode::<JwtClaims>(
            token,
            &self.decoding_key,
            &self.validation,
        )
        .map_err(|e| anyhow::anyhow!("JWT doğrulama hatası: {}", e))?;

        Ok(token_data.claims)
    }
}

// base64 import
use base64::Engine;
