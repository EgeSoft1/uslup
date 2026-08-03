-- =============================================================================
-- TurkiyeMesajlasma Platform - ScyllaDB (CQL) Production Schema
-- Migration: 001_messages_keyspace.cql
-- Engine: ScyllaDB 5.4+ (Cassandra uyumlu, TWCS optimizasyonlu)
--
-- Tasarım Prensipleri:
--   1. Write-heavy workload: Milyarlarca mesaj yazımı için optimize
--   2. TWCS: Zaman bazlı mesajlar için en iyi compaction stratejisi
--   3. TTL: Mesajlar X gün sonra otomatik silinir (KVKK data minimization)
--   4. Partition Key tasarımı: Hot partition'ları önlemek için conversation_id + zaman bucket
--   5. Clustering Key: Kronolojik sıralı okuma için message_id (TimeUUID)
--
-- UYARI: ScyllaDB'de JOIN yoktur. Her tablo denormalize tasarlanmıştır.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BÖLÜM 0: KEYSPACE OLUŞTURMA
-- NetworkTopologyStrategy: Multi-DC replication
-- 'tr_dc': İstanbul/Ankara veri merkezi, RF=3 (zone failure toleransı)
-- 'eu_dc': Amsterdam veri merkezi, RF=2 (GDPR uyumu)
-- -----------------------------------------------------------------------------

CREATE KEYSPACE IF NOT EXISTS turkiye_mesajlasma
    WITH REPLICATION = {
        'class': 'NetworkTopologyStrategy',
        'tr_dc': 3,      -- İstanbul/Ankara: 3 replika, AZ failure toleranslı
        'eu_dc': 2       -- Amsterdam: 2 replika, zone failure toleranslı
    }
    AND DURABLE_WRITES = true;   -- CommitLog'u atlatma (veri kaybı riski)

USE turkiye_mesajlasma;

-- =============================================================================
-- BÖLÜM 1: ANA MESAJ TABLOSU
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TABLO: messages
-- Amaç: E2EE şifreli mesajları depolar. PLAINTEXT ASLA DEPOLANMAZ.
--
-- Partition Key Tasarımı (Kritik):
--   (conversation_id, bucket) -> tek conversation sonsuz büyüyemez!
--   bucket = UNIX epoch / (86400 * 7) = haftalık time bucket
--   Neden haftalık? Bir sohbette günde ~1000 mesaj varsayımıyla
--   haftalık ~7000 satır -> partition başına ~100KB hedef tutulur.
--   Büyük gruplar için günlük bucket kullanılabilir.
--
-- Clustering Key Tasarımı:
--   message_id (TIMEUUID) -> kronolojik sıralama + küresel benzersizlik
--   DESC sıralama -> en yeni mesajlar önce gelir (UI ihtiyacı)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS messages (
    -- Partition Key: conversation bazlı, haftalık bucket ile hot partition önlenir
    conversation_id     UUID,
    bucket              INT,            -- floor(toUnixTimestamp(now()) / (86400 * 7))

    -- Clustering Key: TimeUUID - hem sıralama hem benzersizlik
    message_id          TIMEUUID,

    -- Mesaj meta verisi (plaintext - içerik değil)
    sender_user_id      UUID,
    sender_device_id    UUID,

    -- Alıcı bilgisi (bireysel mesaj için kullanılır)
    recipient_user_id   UUID,
    recipient_device_id UUID,

    -- Şifreli mesaj zarfı (Signal Double Ratchet çıktısı)
    -- WhisperMessage veya PreKeyWhisperMessage formatında
    -- CBOR veya Protobuf ile serialize edilmiş binary blob
    ciphertext          BLOB,           -- Şifreli içerik (AES-256-GCM + HKDF türevli key)

    -- Signal Protocol meta verisi (şifreleme yönetimi için, içerik değil)
    message_type        TINYINT,        -- 1=WHISPER, 3=PREKEY, 5=SENDERKEY, 7=PLAINTEXT_CONTENT(sistem)
    cipher_version      TINYINT,        -- Double Ratchet versiyon (mevcut: 3)

    -- Medya eki varsa: şifreli medya anahtarı ve nesne referansı
    -- Medya içeriği ScyllaDB'de değil, SeaweedFS/MinIO'da
    media_key_ciphertext    BLOB,       -- AES-256 medya şifreleme anahtarının E2EE zarfı
    media_object_key    TEXT,           -- SeaweedFS fid veya MinIO nesne yolu
    media_type          TINYINT,        -- 0=none, 1=image, 2=video, 3=audio, 4=document, 5=sticker

    -- Teslimat durumu (opsiyonel, privacy-sensitive)
    -- NOT: Bu durum sadece sender cihazında tutulabilir, sunucuda tutmak metadata sızıntısı
    -- Sunucu sadece "delivered to server" zaman damgasını tutar
    server_received_at  TIMESTAMP,      -- UTC, server timestamp (güvenilir)
    client_sent_at      TIMESTAMP,      -- UTC, istemci timestamp (güvenilmez, kayıt için)

    -- Yanıtlanan mesaj referansı (içerik yok, sadece ID)
    reply_to_message_id TIMEUUID,

    -- Mesaj düzenleme (Signal protokolünde edit mesajı yeni bir şifreli blob)
    edited_at           TIMESTAMP,
    original_message_id TIMEUUID,       -- Düzenleme ise orijinal mesaj ID

    -- Silinme (E2EE: sadece belirteç, gerçek silme cihazda yapılır)
    deleted_for_everyone_at TIMESTAMP,
    deleted_by_user_id  UUID,

    PRIMARY KEY ((conversation_id, bucket), message_id)
)
WITH CLUSTERING ORDER BY (message_id DESC)    -- Yeni mesajlar önce (UI default)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'DAYS',
    'compaction_window_size': 1,    -- 1 günlük pencere (yoğun yazım için küçük pencere)
    'expired_sstable_check_frequency_seconds': 600,
    'min_threshold': 4,
    'max_threshold': 32
}
AND compression = {
    'sstable_compression': 'LZ4Compressor'    -- CPU-verimli, iyi sıkıştırma oranı
}
-- Varsayılan TTL: 365 gün (1 yıl). Uygulama katmanı override edebilir.
-- KVKK Data Minimization prensibi: Gereksiz veri saklanmaz.
AND default_time_to_live = 31536000    -- 365 gün (saniye)
AND gc_grace_seconds = 86400           -- 1 gün (tombstone temizleme; RF=3 için yeterli)
AND speculative_retry = '99PERCENTILE'  -- P99 sonra speculative retry
AND read_repair_chance = 0.0            -- Zaman damgalı veriler için read repair kapatıldı
AND caching = {
    'keys': 'ALL',
    'rows_per_partition': '100'         -- Partition başına ilk 100 satır cache'de
};

-- Yorum: Neden TimeUUID?
-- UUID v7 yerine TimeUUID (v1) kullanıyoruz çünkü:
-- 1. Cassandra/ScyllaDB TIMEUUID tipi ve minTimeuuid()/maxTimeuuid() fonksiyonları native destek
-- 2. Kronolojik sıralama + dünya genelinde benzersizlik
-- 3. İstemci tarafında üretilebilir (sunucu roundtrip gerekmez)
-- UUID v4/v7 ile benzer avantajlar için Cassandra-compatible TIMEUUID tercih edildi.

-- =============================================================================
-- BÖLÜM 2: GRUP MESAJLARI
-- Grup mesajları için ayrı tablo: Sender Key protokolü farklı zarflama kullanır
-- =============================================================================

CREATE TABLE IF NOT EXISTS group_messages (
    -- Grup ID + haftalık bucket: her grup partition'ı sınırlı boyutta
    group_id            UUID,
    bucket              INT,

    message_id          TIMEUUID,
    sender_user_id      UUID,
    sender_device_id    UUID,

    -- Signal Sender Key ile şifreli içerik
    -- Grup mesajı: Sender Key ile bir kez şifrele, tüm üyelere ilet
    ciphertext          BLOB,
    message_type        TINYINT,        -- 5=SENDERKEY_MESSAGE
    cipher_version      TINYINT,

    -- Medya
    media_key_ciphertext    BLOB,
    media_object_key    TEXT,
    media_type          TINYINT,

    -- Zaman damgaları
    server_received_at  TIMESTAMP,
    client_sent_at      TIMESTAMP,

    -- Grup özelinde
    reply_to_message_id TIMEUUID,
    mentions            FROZEN<LIST<UUID>>,    -- Bahsedilen kullanıcı ID listesi (şifreli değil, bildirim için)
    reactions_count     MAP<TEXT, INT>,         -- Emoji -> sayı (şifreli değil, UI için)

    -- Silinme
    deleted_for_everyone_at TIMESTAMP,
    deleted_by_user_id  UUID,

    PRIMARY KEY ((group_id, bucket), message_id)
)
WITH CLUSTERING ORDER BY (message_id DESC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'DAYS',
    'compaction_window_size': 1,
    'expired_sstable_check_frequency_seconds': 600,
    'min_threshold': 4,
    'max_threshold': 32
}
AND compression = {
    'sstable_compression': 'LZ4Compressor'
}
AND default_time_to_live = 31536000
AND gc_grace_seconds = 86400;

-- =============================================================================
-- BÖLÜM 3: MESAJ DURUM TABLOSU (Delivery & Read Receipts)
-- Separate table for delivery/read status (high write rate, different access pattern)
-- =============================================================================

CREATE TABLE IF NOT EXISTS message_delivery_status (
    -- Partition key: recipient bazlı (her kullanıcı kendi okunma durumunu sorgular)
    recipient_user_id   UUID,
    recipient_device_id UUID,

    -- Sıralama: conversation ve mesaj ID
    conversation_id     UUID,
    message_id          TIMEUUID,

    -- Durum
    status              TINYINT,    -- 0=pending, 1=sent_to_server, 2=delivered, 3=read
    status_changed_at   TIMESTAMP,

    -- Orijinal gönderici (bildirim için)
    sender_user_id      UUID,

    PRIMARY KEY ((recipient_user_id, recipient_device_id), conversation_id, message_id)
)
WITH CLUSTERING ORDER BY (conversation_id ASC, message_id DESC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'DAYS',
    'compaction_window_size': 7,
    'min_threshold': 4,
    'max_threshold': 32
}
AND compression = {
    'sstable_compression': 'LZ4Compressor'
}
-- Delivery status: 30 gün sonra silinir
AND default_time_to_live = 2592000    -- 30 gün
AND gc_grace_seconds = 86400;

-- =============================================================================
-- BÖLÜM 4: OFFLINE MESAJ KUYRUGU
-- WebSocket bağlantısı olmayan kullanıcılara mesaj birikimi
-- =============================================================================

CREATE TABLE IF NOT EXISTS offline_message_queue (
    -- Partition: hedef cihaz bazlı (her cihaz kendi kuyruğunu çeker)
    recipient_device_id UUID,

    -- Sıralama: sunucu alım zamanı
    enqueued_at         TIMEUUID,

    -- Mesaj referansı (tam içerik değil, pointer)
    conversation_id     UUID,
    bucket              INT,
    message_id          TIMEUUID,

    -- Teslim denemesi sayısı
    retry_count         TINYINT,
    last_retry_at       TIMESTAMP,

    -- Push notification payload (şifreli, sadece bildirim için minimal veri)
    push_payload_encrypted  BLOB,   -- "1 yeni mesaj" gibi şifreli notification

    PRIMARY KEY (recipient_device_id, enqueued_at)
)
WITH CLUSTERING ORDER BY (enqueued_at ASC)   -- Önce gelen önce teslim (FIFO)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'HOURS',
    'compaction_window_size': 6,
    'min_threshold': 2,
    'max_threshold': 16
}
AND compression = {
    'sstable_compression': 'LZ4Compressor'
}
-- Offline kuyruk: 7 gün sonra silinir (uzun süre çevrimdışı kalınırsa)
AND default_time_to_live = 604800    -- 7 gün
AND gc_grace_seconds = 3600;         -- 1 saat (kısa yaşam süresi için yeterli)

-- =============================================================================
-- BÖLÜM 5: MEDIA METADATA TABLOSU
-- Medya dosyalarının şifreli meta verisi (boyut, tür, thumbnail hash)
-- =============================================================================

CREATE TABLE IF NOT EXISTS media_attachments (
    -- Partition: conversation bazlı medya listeleme
    conversation_id     UUID,
    bucket              INT,

    -- Sıralama
    uploaded_at         TIMEUUID,
    attachment_id       UUID,

    -- SeaweedFS / MinIO referansı
    storage_type        TINYINT,        -- 0=seaweedfs (küçük), 1=minio (büyük)
    object_key          TEXT,           -- Depolama sistemi nesne anahtarı
    object_bucket       TEXT,           -- MinIO bucket adı (varsa)

    -- Şifrelenmiş meta veri
    -- İçerik anahtarı E2EE ile şifrelenmiş, sunucu açamaz
    encrypted_media_key BLOB,           -- AES-256-GCM ile şifreli medya anahtarı
    media_type          TINYINT,        -- MIME type kodu
    file_size_bytes     BIGINT,
    file_name_ciphertext BLOB,          -- Şifrelenmiş dosya adı

    -- Thumbnail (varsa): küçük boyutlu, ayrı şifreli
    thumbnail_key       TEXT,
    thumbnail_iv        BLOB,

    -- SHA-256 hash (integrity, plaintext - decryption sonrası verify için)
    content_hash_hmac   BLOB,           -- HMAC-SHA256 ile içerik doğrulama

    -- Yükleyen kullanıcı
    uploader_user_id    UUID,

    -- Bu medyaya bağlı mesaj
    message_id          TIMEUUID,

    PRIMARY KEY ((conversation_id, bucket), uploaded_at, attachment_id)
)
WITH CLUSTERING ORDER BY (uploaded_at DESC, attachment_id ASC)
AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_unit': 'DAYS',
    'compaction_window_size': 7,
    'min_threshold': 4,
    'max_threshold': 32
}
AND compression = {
    'sstable_compression': 'LZ4Compressor'
}
AND default_time_to_live = 7776000    -- 90 gün (medya daha uzun saklanır)
AND gc_grace_seconds = 86400;

-- =============================================================================
-- BÖLÜM 6: SIGNAL PROTOCOL SENDER KEY DISTRIBUTION
-- Grup şifreleme için dağıtık Sender Key durumu
-- =============================================================================

CREATE TABLE IF NOT EXISTS sender_key_records (
    -- Partition: group bazlı
    group_id            UUID,
    sender_user_id      UUID,
    sender_device_id    UUID,

    -- Sender Key versiyonu (key rotation)
    distribution_id     UUID,           -- Signal SenderKeyDistributionMessage ID

    -- Şifreli Sender Key record (her üye için ayrı şifreli kopya)
    -- Bu tablo recipient bazlı değil; tüm üyeler paylaşılan versiyonu çeker
    -- Gerçek şifreleme: her üye için ayrı E2EE zarfı application layer'da
    sender_key_blob     BLOB,           -- Signal SenderKeyRecord binary

    created_at          TIMESTAMP,
    last_updated_at     TIMESTAMP,
    iteration_count     INT,            -- Kaç mesaj bu key ile şifrelendi (güvenlik izleme)

    PRIMARY KEY ((group_id, sender_user_id), sender_device_id)
)
WITH compaction = {
    'class': 'LeveledCompactionStrategy',    -- Sık güncellenen kayıtlar için LCS daha uygun
    'sstable_size_in_mb': 160
}
AND compression = {
    'sstable_compression': 'LZ4Compressor'
}
AND gc_grace_seconds = 86400;

-- =============================================================================
-- BÖLÜM 7: CONVERSATION LAST READ POINTER
-- Her kullanıcının her sohbetteki son okunan mesaj pozisyonu
-- =============================================================================

CREATE TABLE IF NOT EXISTS conversation_read_pointers (
    user_id             UUID,
    conversation_id     UUID,

    -- Son okunan mesaj
    last_read_message_id    TIMEUUID,
    last_read_at        TIMESTAMP,

    -- Son görülen mesaj bucket (hızlı okuma için)
    last_message_bucket INT,

    -- Okunmamış mesaj sayısı (tahmini, senkronizasyon gerekir)
    unread_count        INT,

    PRIMARY KEY (user_id, conversation_id)
)
WITH compaction = {
    'class': 'LeveledCompactionStrategy',
    'sstable_size_in_mb': 160
}
AND compression = {
    'sstable_compression': 'LZ4Compressor'
}
AND gc_grace_seconds = 86400
AND caching = {
    'keys': 'ALL',
    'rows_per_partition': 'ALL'    -- Her kullanıcının tüm sohbet pointer'ları cache'de
};

-- =============================================================================
-- PERFORMANS NOTLARI:
-- =============================================================================
--
-- 1. BUCKET HESAPLAMA (uygulama katmanında):
--    bucket = (unix_timestamp_ms / 1000) / (86400 * 7)  -- haftalık
--    Python: int(time.time() / (86400 * 7))
--    Rust:   SystemTime::UNIX_EPOCH.elapsed().unwrap().as_secs() / (86400 * 7)
--
-- 2. OKUMA PAT ERNİ (pagination):
--    SELECT * FROM messages WHERE conversation_id=? AND bucket=? LIMIT 50;
--    Eğer yeterli mesaj yoksa: bucket-1 ile tekrar sorgula.
--
-- 3. TWCS AYARLARI:
--    - compaction_window_size=1 DAY: Günlük SSTable'lar oluşturulur
--    - Eski SSTable'lar TTL dolduğunda otomatik silinir
--    - expired_sstable_check_frequency=600s: Her 10 dakikada expired kontrol
--
-- 4. GC_GRACE_SECONDS:
--    - 86400 (1 gün): RF=3 cluster'da hepsinin tombstone'u görmesi için yeterli
--    - Daha düşük değer: zombie write riski (silinen mesajın geri gelmesi)
--
-- 5. SPECULATIVE RETRY:
--    - messages tablosunda P99 retry: yüksek tail latency'yi önler
--    - ScyllaDB'de varsayılan: '99PERCENTILE'
-- =============================================================================
