use async_trait::async_trait;
use presence_service::PresenceDomainService;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

// --- Domain Models ---

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct E2EEMessage {
    pub message_id: String,
    pub sender_id: String,
    pub receiver_id: String,
    pub encrypted_payload: String, // Uçtan uca şifreli mesaj içeriği
    pub timestamp: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MessageMetadata {
    pub message_id: String,
    pub sender_id: String,
    pub receiver_id: String,
    pub timestamp: u64,
}

// --- Interfaces (Ports) ---

#[async_trait]
pub trait OfflineQueueRepository: Send + Sync {
    async fn save_offline_message(&self, message: &E2EEMessage) -> Result<(), String>;
}

#[async_trait]
pub trait LawfulInterceptLogger: Send + Sync {
    async fn log_metadata(&self, metadata: &MessageMetadata) -> Result<(), String>;
}

#[async_trait]
pub trait MessageDeliveryService: Send + Sync {
    async fn deliver_to_online_user(&self, message: &E2EEMessage) -> Result<(), String>;
}

// --- Message Router Core Logic ---

pub struct MessageRouter {
    presence_service: Arc<dyn PresenceDomainService>,
    offline_queue: Arc<dyn OfflineQueueRepository>,
    intercept_logger: Arc<dyn LawfulInterceptLogger>,
    delivery_service: Arc<dyn MessageDeliveryService>,
}

impl MessageRouter {
    pub fn new(
        presence_service: Arc<dyn PresenceDomainService>,
        offline_queue: Arc<dyn OfflineQueueRepository>,
        intercept_logger: Arc<dyn LawfulInterceptLogger>,
        delivery_service: Arc<dyn MessageDeliveryService>,
    ) -> Self {
        Self {
            presence_service,
            offline_queue,
            intercept_logger,
            delivery_service,
        }
    }

    /// Gelen E2EE mesajı yönlendirir
    pub async fn route_message(&self, message: E2EEMessage) -> Result<(), String> {
        // Yasal dinleme (metadata logging) için ClickHouse'a asenkron olay tetiklenir
        let metadata = MessageMetadata {
            message_id: message.message_id.clone(),
            sender_id: message.sender_id.clone(),
            receiver_id: message.receiver_id.clone(),
            timestamp: message.timestamp,
        };
        
        let logger = self.intercept_logger.clone();
        tokio::spawn(async move {
            let _ = logger.log_metadata(&metadata).await;
        });

        // Alıcının çevrimiçi/çevrimdışı durumunu kontrol et
        let is_online = self.presence_service.is_online(&message.receiver_id).await.unwrap_or(false);

        if is_online {
            // Kullanıcı çevrimiçi ise gateway/websocket üzerinden ilet
            self.delivery_service.deliver_to_online_user(&message).await?;
        } else {
            // Kullanıcı çevrimdışı ise ScyllaDB tabanlı offline kuyruğuna kaydet
            self.offline_queue.save_offline_message(&message).await?;
        }

        Ok(())
    }
}
