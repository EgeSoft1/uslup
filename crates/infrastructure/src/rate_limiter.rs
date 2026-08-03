// =============================================================================
// TurkiyeMesajlasma — Dağıtık Hız Sınırlayıcı (Distributed Rate Limiter)
// Dosya: crates/infrastructure/src/rate_limiter.rs
//
// Amaç: Kötü niyetli kullanıcıların (Spam/DDoS) saniyede yüzlerce mesaj atıp
// sistemi veya karşı tarafın cihazını dondurmasını engellemek.
// Kullanılan Algoritma: Sliding Window (veya bellek dostu Fixed Window)
// Veri Deposu: DragonflyDB (In-Memory)
// =============================================================================

use std::sync::Arc;
use async_trait::async_trait;
use fred::prelude::*;
use tracing::warn;
use uuid::Uuid;

use domain::errors::{PlatformError, PlatformResult};

pub struct DragonflyRateLimiter {
    client: Arc<RedisClient>,
    max_messages_per_minute: u32,
}

impl DragonflyRateLimiter {
    pub fn new(client: Arc<RedisClient>, max_messages: u32) -> Self {
        Self {
            client,
            max_messages_per_minute: max_messages,
        }
    }
}

#[async_trait]
pub trait RateLimiter: Send + Sync {
    /// Kullanıcının mesaj gönderme hızını kontrol eder.
    /// Eğer sınırı aştıysa hata döner (PlatformError::RateLimitExceeded).
    async fn check_message_rate(&self, user_id: Uuid) -> PlatformResult<()>;
}

#[async_trait]
impl RateLimiter for DragonflyRateLimiter {
    async fn check_message_rate(&self, user_id: Uuid) -> PlatformResult<()> {
        // Hız Sınırı Anahtarı (Her dakika yeni bir anahtar oluşur - Fixed Window)
        // Gerçekte Sliding Window (ZADD/ZREMRANGEBYSCORE) daha kesindir ancak 
        // 150M CCU için Fixed Window bellek (RAM) açısından çok daha ucuzdur.
        
        let current_minute = chrono::Utc::now().timestamp() / 60;
        let key = format!("rl:msg:{}:{}", user_id.as_simple(), current_minute);

        // Redis (Dragonfly) INCR komutu atomiktir.
        // Pipeline kullanarak INCR ve EXPIRE işlemlerini tek seferde yolluyoruz (Latency düşer).
        let pipeline = self.client.pipeline();

        // Sayacı 1 artır
        pipeline.incr::<(), _>(key.as_str()).await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("Rate limit INCR hatası: {}", e),
            })?;
        
        // Eğer key yeni oluştuysa 60 saniye TTL ver (Bellek şişmemesi için)
        // (Eski bir key'e EXPIRE atmak zararsızdır, sadece süresini yeniler)
        pipeline.expire::<(), _>(key.as_str(), 60).await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("Rate limit EXPIRE hatası: {}", e),
            })?;

        // Pipeline çalıştır ve sonuçları al
        let results: Vec<i64> = pipeline.all().await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("Pipeline execute hatası: {}", e),
            })?;

        // İlk sonuç INCR komutunun dönüşüdür
        let count = results.first().unwrap_or(&0);

        if *count > self.max_messages_per_minute as i64 {
            warn!("Rate limit aşıldı! User: {}, Limit: {}/dk", user_id, self.max_messages_per_minute);
            metrics::counter!("rate_limit.message.exceeded", 1);
            
            return Err(PlatformError::RateLimitExceeded {
                retry_after_ms: 60000, // İstemciye ne kadar beklemesi gerektiğini söyle (ms)
            });
        }

        Ok(())
    }
}
