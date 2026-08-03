// =============================================================================
// TurkiyeMesajlasma — CockroachDB Key Bundle Deposu
// Dosya: crates/infrastructure/src/db/cockroach/key_bundle_repo.rs
//
// Özellikler:
// - Crate: sqlx (PostgreSQL uyumlu, asenkron ve compile-time query kontrolü)
// - Transaction Management: X3DH One-Time PreKey (OPK) alımlarında Race Condition
//   önlemek için "FOR UPDATE SKIP LOCKED" kullanımı.
// - Geo-Partitioning: Anahtarlar kullanıcının bulunduğu coğrafi bölgeye göre tutulur.
// =============================================================================

use sqlx::{PgPool, postgres::PgPoolOptions};
use tracing::{debug, error};
use uuid::Uuid;

use domain::ports::KeyBundleRepository;
use domain::errors::{PlatformError, PlatformResult};
use proto::KeyBundle;

pub struct CockroachKeyRepo {
    pool: PgPool,
}

impl CockroachKeyRepo {
    pub async fn new(database_url: &str, min_connections: u32, max_connections: u32) -> PlatformResult<Self> {
        let pool = PgPoolOptions::new()
            .min_connections(min_connections)
            .max_connections(max_connections)
            // CockroachDB'de bağlantı kopmalarına karşı retry mantığı sqlx ile idare edilir
            .acquire_timeout(std::time::Duration::from_secs(5))
            .connect(database_url)
            .await
            .map_err(|e| PlatformError::DatabaseError {
                source: anyhow::anyhow!("CockroachDB bağlantı hatası: {}", e),
            })?;

        Ok(Self { pool })
    }
}

#[async_trait::async_trait]
impl KeyBundleRepository for CockroachKeyRepo {
    
    /// Bir cihaz için Signal Protocol Identity Key, Signed PreKey ve 
    /// bir adet One-Time PreKey (OPK) getirir.
    async fn fetch_key_bundle(&self, device_id: Uuid) -> PlatformResult<KeyBundle> {
        // CockroachDB Transaction başlat (Race condition önleme)
        let mut tx = self.pool.begin().await
            .map_err(|e| PlatformError::DatabaseError { source: anyhow::anyhow!(e) })?;

        // 1. Identity Key ve Signed PreKey'i getir
        let base_keys = sqlx::query!(
            r#"
            SELECT identity_key, signed_prekey, signed_prekey_signature 
            FROM device_keys 
            WHERE device_id = $1
            "#,
            device_id
        )
        .fetch_optional(&mut *tx)
        .await
        .map_err(|e| PlatformError::DatabaseError { source: anyhow::anyhow!(e) })?;

        let base_keys = base_keys.ok_or_else(|| PlatformError::NotFoundError {
            entity: "DeviceKeys".into(),
        })?;

        // 2. Bir adet One-Time PreKey (OPK) al ve listeden DÜŞ (Kullanılmış olarak işaretle veya sil)
        // Yüksek concurrency'de aynı OPK'nin iki kişiye verilmesini "SKIP LOCKED" ile engelleriz.
        // CockroachDB 'SKIP LOCKED' destekler (v22+).
        let opk_result = sqlx::query!(
            r#"
            DELETE FROM one_time_prekeys
            WHERE id = (
                SELECT id FROM one_time_prekeys 
                WHERE device_id = $1 
                LIMIT 1 
                FOR UPDATE SKIP LOCKED
            )
            RETURNING key_id, public_key
            "#,
            device_id
        )
        .fetch_optional(&mut *tx)
        .await
        .map_err(|e| PlatformError::DatabaseError { source: anyhow::anyhow!(e) })?;

        // Transaction onayla (Commit)
        tx.commit().await
            .map_err(|e| PlatformError::DatabaseError { source: anyhow::anyhow!(e) })?;

        // 3. Proto objesini oluştur
        let mut bundle = KeyBundle {
            device_id: device_id.into_bytes().to_vec(),
            identity_key: base_keys.identity_key,
            signed_pre_key: base_keys.signed_prekey,
            signed_pre_key_signature: base_keys.signed_prekey_signature,
            one_time_pre_key: None,
            one_time_pre_key_id: None,
        };

        if let Some(opk) = opk_result {
            bundle.one_time_pre_key = Some(opk.public_key);
            bundle.one_time_pre_key_id = Some(opk.key_id as u32);
        } else {
            // Eğer OPK tükendiyse, X3DH algoritması Signed PreKey üzerinden 
            // fallback (ikincil) mekanizma ile şifrelemeye devam edebilir.
            debug!("Cihaz {} için One-Time PreKey havuzu tükendi!", device_id);
            metrics::counter!("db.cockroach.opk_exhausted", 1);
        }

        metrics::counter!("db.cockroach.fetch_bundle", 1);
        Ok(bundle)
    }

    /// Cihazdan gelen yeni 100 adet One-Time PreKey'i (OPK) havuzuna ekler.
    async fn upload_pre_keys(
        &self,
        device_id: Uuid,
        keys: Vec<proto::PreKey>,
    ) -> PlatformResult<()> {
        if keys.is_empty() {
            return Ok(());
        }

        // Toplu INSERT işlemi (Batch / UNNEST kullanarak)
        // 100 anahtarı tek seferde eklemek performansı katlar.
        
        let key_ids: Vec<i32> = keys.iter().map(|k| k.id as i32).collect();
        let public_keys: Vec<Vec<u8>> = keys.into_iter().map(|k| k.public_key).collect();
        
        sqlx::query!(
            r#"
            INSERT INTO one_time_prekeys (device_id, key_id, public_key)
            SELECT $1, * FROM UNNEST($2::int[], $3::bytea[])
            "#,
            device_id,
            &key_ids,
            &public_keys
        )
        .execute(&self.pool)
        .await
        .map_err(|e| {
            error!("PreKey bulk insert hatası: {}", e);
            PlatformError::DatabaseError {
                source: anyhow::anyhow!("PreKeys yüklenemedi"),
            }
        })?;

        metrics::counter!("db.cockroach.upload_prekeys", public_keys.len() as u64);
        Ok(())
    }
}
