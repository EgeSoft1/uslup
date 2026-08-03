// =============================================================================
// TurkiyeMesajlasma — DragonflyDB Presence Repository
// Dosya: crates/infrastructure/src/presence.rs
//
// Presence sistemi DragonflyDB (Redis uyumlu) üzerinde çalışır.
// Her kullanıcının online durumu TTL ile otomatik expire olur.
// =============================================================================

use std::sync::Arc;
use std::time::Duration;

use async_trait::async_trait;
use fred::prelude::*;
use tracing::{debug, error};
use uuid::Uuid;

use domain::ports::{PresenceInfo, PresenceRepository, PresenceStatus};
use domain::errors::{PlatformError, PlatformResult};

const PRESENCE_TTL: u64 = 30;       // 30 saniye
const WS_NODE_TTL: u64 = 60;        // 60 saniye
const TYPING_TTL: u64 = 5;          // 5 saniye
const LAST_SEEN_KEY_PREFIX: &str = "lastseen:";
const PRESENCE_KEY_PREFIX: &str = "presence:user:";
const WS_NODE_KEY_PREFIX: &str = "ws:node:";
const TYPING_KEY_PREFIX: &str = "typing:";

pub struct DragonflyPresenceRepository {
    client: Arc<RedisClient>,
}

impl DragonflyPresenceRepository {
    pub fn new(client: Arc<RedisClient>) -> Self {
        Self { client }
    }

    fn presence_key(user_id: Uuid) -> String {
        format!("{}{}", PRESENCE_KEY_PREFIX, user_id.as_simple())
    }

    fn ws_node_key(device_id: Uuid) -> String {
        format!("{}{}", WS_NODE_KEY_PREFIX, device_id.as_simple())
    }

    fn last_seen_key(user_id: Uuid) -> String {
        format!("{}{}", LAST_SEEN_KEY_PREFIX, user_id.as_simple())
    }

    fn typing_key(user_id: Uuid, conversation_id: Uuid) -> String {
        format!(
            "{}{}:{}",
            TYPING_KEY_PREFIX,
            conversation_id.as_simple(),
            user_id.as_simple()
        )
    }
}

#[async_trait]
impl PresenceRepository for DragonflyPresenceRepository {
    /// Kullanıcıyı online olarak işaretle
    /// Hem presence kaydı hem de ws:node kaydı güncellenir
    async fn set_online(
        &self,
        user_id: Uuid,
        device_id: Uuid,
        node_id: &str,
    ) -> PlatformResult<()> {
        let now = chrono::Utc::now().timestamp_millis();

        // Presence kaydı: JSON olarak sakla
        let presence = PresenceInfo {
            user_id,
            status: PresenceStatus::Online,
            node_id: node_id.to_string(),
            updated_at: now,
        };

        let presence_json = serde_json::to_string(&presence)
            .map_err(|e| PlatformError::InternalError {
                message: format!("Presence JSON hatası: {}", e),
            })?;

        let pkey = Self::presence_key(user_id);
        let nkey = Self::ws_node_key(device_id);
        let lkey = Self::last_seen_key(user_id);

        // Pipeline: Birden fazla komutu tek round-trip'te gönder
        // DragonflyDB pipelining desteği: latency ~50μs → ~10μs
        let pipeline = self.client.pipeline();

        // SET presence:user:{uid} <json> EX 30
        pipeline.set::<(), _, _>(
            pkey.as_str(),
            presence_json.as_str(),
            Some(Expiration::EX(PRESENCE_TTL as i64)),
            None,
            false,
        ).await.map_err(|e| PlatformError::CacheError {
            source: anyhow::anyhow!("Pipeline SET hatası: {}", e),
        })?;

        // SET ws:node:{device_id} {node_id} EX 60
        pipeline.set::<(), _, _>(
            nkey.as_str(),
            node_id,
            Some(Expiration::EX(WS_NODE_TTL as i64)),
            None,
            false,
        ).await.map_err(|e| PlatformError::CacheError {
            source: anyhow::anyhow!("Pipeline SET hatası: {}", e),
        })?;

        // SET lastseen:{uid} {timestamp}
        pipeline.set::<(), _, _>(
            lkey.as_str(),
            now.to_string().as_str(),
            None,
            None,
            false,
        ).await.map_err(|e| PlatformError::CacheError {
            source: anyhow::anyhow!("Pipeline SET hatası: {}", e),
        })?;

        // Pipeline'ı çalıştır
        pipeline.last::<()>().await.map_err(|e| PlatformError::CacheError {
            source: anyhow::anyhow!("Pipeline execute hatası: {}", e),
        })?;

        debug!(
            user_id = %user_id,
            device_id = %device_id,
            node_id = node_id,
            "Presence: Online"
        );

        Ok(())
    }

    /// Kullanıcıyı offline olarak işaretle
    async fn set_offline(&self, user_id: Uuid, device_id: Uuid) -> PlatformResult<()> {
        let pkey = Self::presence_key(user_id);
        let nkey = Self::ws_node_key(device_id);
        let lkey = Self::last_seen_key(user_id);

        let now = chrono::Utc::now().timestamp_millis();

        let pipeline = self.client.pipeline();

        // Presence kaydını sil (TTL'ye bırakmak yerine explicit sil)
        pipeline.del::<(), _>(pkey.as_str()).await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("DEL hatası: {}", e),
            })?;

        // WS node kaydını sil
        pipeline.del::<(), _>(nkey.as_str()).await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("DEL hatası: {}", e),
            })?;

        // Son görülme'yi güncelle (kalıcı)
        pipeline.set::<(), _, _>(
            lkey.as_str(),
            now.to_string().as_str(),
            None,
            None,
            false,
        ).await.map_err(|e| PlatformError::CacheError {
            source: anyhow::anyhow!("SET lastseen hatası: {}", e),
        })?;

        pipeline.last::<()>().await.map_err(|e| PlatformError::CacheError {
            source: anyhow::anyhow!("Pipeline execute hatası: {}", e),
        })?;

        debug!(user_id = %user_id, device_id = %device_id, "Presence: Offline");
        Ok(())
    }

    /// Kullanıcının presence bilgisini sorgula
    async fn get_presence(&self, user_id: Uuid) -> PlatformResult<Option<PresenceInfo>> {
        let key = Self::presence_key(user_id);

        let value: Option<String> = self.client
            .get(key.as_str())
            .await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("GET hatası: {}", e),
            })?;

        match value {
            Some(json) => {
                let presence: PresenceInfo = serde_json::from_str(&json)
                    .map_err(|e| PlatformError::InternalError {
                        message: format!("Presence JSON parse hatası: {}", e),
                    })?;
                Ok(Some(presence))
            }
            None => {
                // Presence kaydı yok = offline
                // last_seen değerini al
                let lkey = Self::last_seen_key(user_id);
                let last_seen: Option<String> = self.client
                    .get(lkey.as_str())
                    .await
                    .unwrap_or(None);

                let updated_at = last_seen
                    .and_then(|s| s.parse::<i64>().ok())
                    .unwrap_or(0);

                Ok(Some(PresenceInfo {
                    user_id,
                    status: PresenceStatus::Offline,
                    node_id: String::new(),
                    updated_at,
                }))
            }
        }
    }

    /// Son görülme güncelle
    async fn update_last_seen(&self, user_id: Uuid) -> PlatformResult<()> {
        let key = Self::last_seen_key(user_id);
        let now = chrono::Utc::now().timestamp_millis();

        self.client
            .set::<(), _, _>(
                key.as_str(),
                now.to_string().as_str(),
                None,
                None,
                false,
            )
            .await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("Last seen güncelleme hatası: {}", e),
            })?;

        Ok(())
    }

    /// Toplu presence sorgusu (mget ile tek round-trip)
    async fn batch_get_presence(&self, user_ids: &[Uuid]) -> PlatformResult<Vec<PresenceInfo>> {
        if user_ids.is_empty() {
            return Ok(vec![]);
        }

        // MGET: Tüm key'leri tek seferde sorgula
        let keys: Vec<String> = user_ids
            .iter()
            .map(|id| Self::presence_key(*id))
            .collect();

        let key_refs: Vec<&str> = keys.iter().map(|s| s.as_str()).collect();

        let values: Vec<Option<String>> = self.client
            .mget(key_refs.as_slice())
            .await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("MGET hatası: {}", e),
            })?;

        let mut results = Vec::with_capacity(user_ids.len());

        for (user_id, value) in user_ids.iter().zip(values.iter()) {
            let info = match value {
                Some(json) => serde_json::from_str(json).unwrap_or(PresenceInfo {
                    user_id: *user_id,
                    status: PresenceStatus::Offline,
                    node_id: String::new(),
                    updated_at: 0,
                }),
                None => PresenceInfo {
                    user_id: *user_id,
                    status: PresenceStatus::Offline,
                    node_id: String::new(),
                    updated_at: 0,
                },
            };
            results.push(info);
        }

        Ok(results)
    }
}

impl DragonflyPresenceRepository {
    /// "Yazıyor..." durumunu ayarla
    pub async fn set_typing(
        &self,
        user_id: Uuid,
        conversation_id: Uuid,
        is_typing: bool,
    ) -> PlatformResult<()> {
        let key = Self::typing_key(user_id, conversation_id);

        if is_typing {
            // SET typing:{conv}:{user} 1 EX 5
            self.client
                .set::<(), _, _>(
                    key.as_str(),
                    "1",
                    Some(Expiration::EX(TYPING_TTL as i64)),
                    None,
                    false,
                )
                .await
                .map_err(|e| PlatformError::CacheError {
                    source: anyhow::anyhow!("Typing SET hatası: {}", e),
                })?;
        } else {
            // Yazmayı durdurdu: Explicit sil (TTL beklemeden)
            self.client
                .del::<(), _>(key.as_str())
                .await
                .map_err(|e| PlatformError::CacheError {
                    source: anyhow::anyhow!("Typing DEL hatası: {}", e),
                })?;
        }

        Ok(())
    }

    /// Bir sohbette kaç kullanıcı yazıyor?
    /// SCAN komutu ile typing:{conv_id}:* pattern araması
    pub async fn get_typing_users(
        &self,
        conversation_id: Uuid,
    ) -> PlatformResult<Vec<Uuid>> {
        let pattern = format!("{}{}:*", TYPING_KEY_PREFIX, conversation_id.as_simple());

        // SCAN: O(N) ama küçük sonuç seti bekleniyor (max 256 kişilik grup)
        let scan_result: Vec<String> = self.client
            .scan(pattern.as_str(), Some(50), None)
            .try_collect()
            .await
            .map_err(|e| PlatformError::CacheError {
                source: anyhow::anyhow!("SCAN hatası: {}", e),
            })?;

        let prefix = format!("{}{}:", TYPING_KEY_PREFIX, conversation_id.as_simple());
        let user_ids: Vec<Uuid> = scan_result
            .iter()
            .filter_map(|key| {
                key.strip_prefix(&prefix)
                    .and_then(|uid_str| Uuid::parse_str(uid_str).ok())
            })
            .collect();

        Ok(user_ids)
    }
}
