use bytes::Bytes;
use uuid::Uuid;

pub struct OfflineQueueRepository;

impl OfflineQueueRepository {
    pub async fn enqueue(&self, _device_id: Uuid, _payload: &Bytes) -> Result<(), anyhow::Error> {
        Ok(())
    }
}
