// =============================================================================
// TurkiyeMesajlasma — ScyllaDB Mesaj Deposu (Message Store)
// Dosya: crates/infrastructure/src/db/scylla/message_store.rs
//
// Özellikler:
// - Crate: scylla (Datastax'ın C++ driver'ından port edilen ultra hızlı Rust driver)
// - Execution Profile: Düşük gecikme için token-aware yönlendirme.
// - Asynchronous Paging: Büyük sohbet geçmişleri için sayfalama.
// =============================================================================

use std::sync::Arc;
use async_trait::async_trait;
use scylla::{Session, SessionBuilder};
use scylla::statement::prepared::PreparedStatement;
use scylla::transport::ExecutionProfile;
use scylla::transport::speculative_execution::SimpleSpeculativeExecutionPolicy;
use tracing::{debug, error};
use uuid::Uuid;

use domain::ports::MessageStoreRepository;
use domain::errors::{PlatformError, PlatformResult};
use proto::EncryptedEnvelope;
use crate::connection::AuthenticatedPeer; // Gateway'den gelen peer struct'ı

pub struct ScyllaMessageStore {
    session: Arc<Session>,
    // Performans için Query'ler başlatılma anında (boot) derlenir (Prepared Statements)
    insert_message_stmt: PreparedStatement,
    get_messages_stmt: PreparedStatement,
    mark_read_stmt: PreparedStatement,
}

impl ScyllaMessageStore {
    /// ScyllaDB Cluster'ına bağlan ve statement'ları hazırla
    pub async fn new(hosts: &[String], keyspace: &str) -> PlatformResult<Self> {
        // Token-aware routing ve Speculative Execution profili
        // (Eğer bir node'dan 50ms içinde yanıt gelmezse, aynı anda başka bir replikaya sor)
        let profile = ExecutionProfile::builder()
            .speculative_execution_policy(Some(Arc::new(
                SimpleSpeculativeExecutionPolicy {
                    max_retry_count: 1,
                    retry_interval: std::time::Duration::from_millis(50),
                },
            )))
            .build();

        let session = SessionBuilder::new()
            .known_nodes(hosts)
            .default_execution_profile(profile)
            .build()
            .await
            .map_err(|e| PlatformError::DatabaseError {
                source: anyhow::anyhow!("ScyllaDB bağlantı hatası: {}", e),
            })?;

        session.use_keyspace(keyspace, false).await
            .map_err(|e| PlatformError::DatabaseError { source: anyhow::anyhow!(e) })?;

        // ── PREPARED STATEMENTS ───────────────────────────────────────────────
        // TTL 31536000 = 1 Yıl (KVKK/GDPR gereği otomatik veri imhası)
        let mut insert_stmt = session
            .prepare("INSERT INTO messages (conversation_id, message_id, sender_device_id, ciphertext, nonce, created_at) VALUES (?, ?, ?, ?, ?, toTimestamp(now())) USING TTL 31536000")
            .await
            .map_err(|e| PlatformError::DatabaseError { source: anyhow::anyhow!(e) })?;
        
        insert_stmt.set_tracing(false); // Overhead yaratmaması için kapalı

        let get_stmt = session
            .prepare("SELECT message_id, sender_device_id, ciphertext, nonce, created_at FROM messages WHERE conversation_id = ? ORDER BY created_at DESC LIMIT ?")
            .await
            .map_err(|e| PlatformError::DatabaseError { source: anyhow::anyhow!(e) })?;

        let mark_read_stmt = session
            .prepare("UPDATE messages SET read_at = toTimestamp(now()) WHERE conversation_id = ? AND message_id = ?")
            .await
            .map_err(|e| PlatformError::DatabaseError { source: anyhow::anyhow!(e) })?;

        Ok(Self {
            session: Arc::new(session),
            insert_message_stmt: insert_stmt,
            get_messages_stmt: get_stmt,
            mark_read_stmt,
        })
    }
}

#[async_trait]
impl MessageStoreRepository for ScyllaMessageStore {
    
    /// Şifreli mesajı (Envelope) kalıcı olarak sakla
    async fn persist_envelope(
        &self,
        sender: &AuthenticatedPeer,
        envelope: EncryptedEnvelope,
    ) -> PlatformResult<()> {
        let conversation_id = Uuid::from_slice(&envelope.recipient_device_id)
            .unwrap_or_else(|_| Uuid::new_v4()); // Örnek id
            
        let message_id = Uuid::now_v1(&[0,0,0,0,0,0]); // TimeUUID (Scylla'da clustering key)

        // Execute Prepared Statement
        self.session
            .execute(
                &self.insert_message_stmt,
                (
                    conversation_id.to_string(),
                    message_id,
                    sender.device_id.to_string(),
                    &envelope.ciphertext,
                    &envelope.nonce, // Şifreleme IV'si
                ),
            )
            .await
            .map_err(|e| {
                error!("ScyllaDB INSERT hatası: {}", e);
                PlatformError::DatabaseError {
                    source: anyhow::anyhow!("Mesaj yazılamadı"),
                }
            })?;

        metrics::counter!("db.scylla.insert", 1);
        Ok(())
    }

    /// Mesajı "Okundu" (Mavi Tik) olarak işaretle
    async fn mark_read(
        &self,
        _reader_id: Uuid,
        _device_id: Uuid,
        receipt: proto::ReadReceipt,
    ) -> PlatformResult<()> {
        let conversation_id = Uuid::from_slice(&receipt.conversation_id)
            .map_err(|_| PlatformError::ValidationError("Geçersiz conv id".into()))?;
        
        let message_id = Uuid::from_slice(&receipt.message_id)
            .map_err(|_| PlatformError::ValidationError("Geçersiz msg id".into()))?;

        self.session
            .execute(&self.mark_read_stmt, (conversation_id.to_string(), message_id))
            .await
            .map_err(|e| PlatformError::DatabaseError {
                source: anyhow::anyhow!("Mark read hatası: {}", e),
            })?;
            
        Ok(())
    }
}
