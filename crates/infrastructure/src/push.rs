use uuid::Uuid;

pub struct PushNotificationService;

impl PushNotificationService {
    pub async fn send_new_message_notification(&self, _device_id: Uuid) -> Result<(), anyhow::Error> {
        Ok(())
    }
}
