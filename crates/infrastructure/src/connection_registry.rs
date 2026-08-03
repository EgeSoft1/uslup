use bytes::Bytes;
use uuid::Uuid;

pub struct LocalConnectionRegistry;

impl LocalConnectionRegistry {
    pub async fn send_to_device(&self, _device_id: &Uuid, _payload: Bytes) -> bool {
        false
    }
    
    pub fn connection_count(&self) -> u64 {
        0
    }
}
