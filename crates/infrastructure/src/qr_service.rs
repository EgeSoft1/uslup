// =============================================================================
// TurkiyeMesajlasma — QR Kod Servisi (In-Memory / DragonflyDB)
// Dosya: crates/infrastructure/src/qr_service.rs
//
// Özellikler:
// - Cihazlar için 60 saniye süreli tek kullanımlık QR kodu oluşturur.
// - QR okutulduğunda kullanıcıları birbirine bağlamak için olay fırlatır.
// =============================================================================

use std::sync::Arc;
use tokio::sync::RwLock;
use std::collections::HashMap;
use uuid::Uuid;
use std::time::{Instant, Duration};

#[derive(Clone)]
pub struct QrCodeEntry {
    pub user_id: Uuid,
    pub device_id: Uuid,
    pub created_at: Instant,
    pub expires_at: Instant,
}

#[derive(Clone)]
pub struct QrService {
    // Prototip için in-memory kullanıyoruz. Gerçekte bu DragonflyDB üzerinde saklanır.
    // Key: QR Kod string'i, Value: Kod bilgileri
    store: Arc<RwLock<HashMap<String, QrCodeEntry>>>,
}

impl QrService {
    pub fn new() -> Self {
        Self {
            store: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Yeni bir QR kodu oluşturur ve 60 saniye geçerlilik süresi (TTL) verir.
    pub async fn generate_qr(&self, user_id: Uuid, device_id: Uuid) -> String {
        let code = format!("TKM-{}", uuid::Uuid::new_v4().to_string().chars().take(8).collect::<String>().to_uppercase());
        
        let entry = QrCodeEntry {
            user_id,
            device_id,
            created_at: Instant::now(),
            expires_at: Instant::now() + Duration::from_secs(60),
        };

        let mut store = self.store.write().await;
        store.insert(code.clone(), entry);

        code
    }

    /// Tarayıcı tarafından okutulan QR kodunu doğrular
    pub async fn consume_qr(&self, code: &str, scanner_user_id: Uuid) -> Result<Uuid, String> {
        let mut store = self.store.write().await;
        
        if let Some(entry) = store.get(code) {
            if Instant::now() > entry.expires_at {
                store.remove(code); // Süresi dolmuş, temizle
                return Err("Bu QR kodun süresi (1 dakika) dolmuş.".to_string());
            }

            if entry.user_id == scanner_user_id {
                return Err("Kendi QR kodunuzu tarayamazsınız.".to_string());
            }

            let target_user = entry.user_id;
            
            // Tek kullanımlık olduğu için sil
            store.remove(code);

            Ok(target_user)
        } else {
            Err("Geçersiz veya süresi dolmuş QR kod.".to_string())
        }
    }
    
    // Arkaplanda süresi dolanları temizleyen task
    pub async fn cleanup_loop(&self) {
        loop {
            tokio::time::sleep(Duration::from_secs(10)).await;
            let mut store = self.store.write().await;
            store.retain(|_, entry| Instant::now() <= entry.expires_at);
        }
    }
}
