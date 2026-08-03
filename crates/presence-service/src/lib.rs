use async_trait::async_trait;
// `fred` Redis istemcisi kullanılarak DragonflyDB ile iletişim sağlanır.
use fred::prelude::*;

// --- Çevrimiçi/Çevrimdışı Durumu için Domain Servisi ---

#[async_trait]
pub trait PresenceDomainService: Send + Sync {
    async fn set_online(&self, user_id: &str) -> Result<(), String>;
    async fn set_offline(&self, user_id: &str) -> Result<(), String>;
    async fn is_online(&self, user_id: &str) -> Result<bool, String>;
}

// DragonflyDB (Redis uyumlu) implementasyonu
pub struct DragonflyPresenceService {
    client: RedisClient,
}

impl DragonflyPresenceService {
    pub fn new(client: RedisClient) -> Self {
        Self { client }
    }
}

#[async_trait]
impl PresenceDomainService for DragonflyPresenceService {
    async fn set_online(&self, user_id: &str) -> Result<(), String> {
        let key = format!("presence:{}", user_id);
        // DragonflyDB üzerinde SET komutu çalıştırılır, expire süresi ile (örn: 60 saniye)
        // Eğer kullanıcı bağlantıyı keserse expire olarak offline düşer.
        self.client
            .set::<(), _, _>(key, "online", Some(Expiration::EX(60)), None, false)
            .await
            .map_err(|e| format!("Redis set error: {}", e))?;
        Ok(())
    }

    async fn set_offline(&self, user_id: &str) -> Result<(), String> {
        let key = format!("presence:{}", user_id);
        // DEL komutu ile kullanıcının durumu offline yapılır.
        self.client
            .del::<(), _>(key)
            .await
            .map_err(|e| format!("Redis del error: {}", e))?;
        Ok(())
    }

    async fn is_online(&self, user_id: &str) -> Result<bool, String> {
        let key = format!("presence:{}", user_id);
        // GET komutu ile kullanıcının durumu sorgulanır.
        let status: Option<String> = self.client
            .get(key)
            .await
            .map_err(|e| format!("Redis get error: {}", e))?;
        
        Ok(status.as_deref() == Some("online"))
    }
}
