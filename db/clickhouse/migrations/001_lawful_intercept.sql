-- =============================================================================
-- TurkiyeMesajlasma Platform - ClickHouse Production Schema
-- Migration: 001_lawful_intercept.sql
-- Engine: ClickHouse 24.x
--
-- AMAÇ: Yasal Dinleme (Lawful Intercept) ve Adli Loglama
--
-- KRİTİK GÜVENLIK NOTU:
--   Bu tabloda MESAJ İÇERİĞİ (plaintext veya ciphertext) ASLA SAKLANMAZ.
--   Yalnızca bağlantı meta verisi (kim, ne zaman, hangi süre) depolanır.
--   Bu tasarım:
--     - 5651 sayılı Kanun (İnternet Ortamında Yapılan Yayınların Düzenlenmesi)
--     - 6698 sayılı KVKK Madde 12 (Veri güvenliği tedbirleri)
--     - ETSI TS 101 671 (Lawful Interception) standardı
--   gerekliliklerini karşılar.
--
-- Mesaj içeriği mahkeme kararı ile SADECE E2EE anahtarlarına erişim talep
-- edilebilir, ki bu anahtarlar yalnızca kullanıcı cihazında bulunur.
-- Sunucu bu anahtarlara erişemez (Zero-Knowledge mimarisi).
-- =============================================================================

-- Ayrı bir veritabanı (log verisi operasyonel veriyle karışmasın)
CREATE DATABASE IF NOT EXISTS lawful_intercept
    COMMENT 'Adli soruşturma ve yasal uyum log veritabanı';

-- =============================================================================
-- BÖLÜM 1: ANA METADATA LOG TABLOSU
-- Bağlantı meta verisi: kim ne zaman bağlandı, ne kadar süre, hangi IP
-- İçerik YOK.
-- =============================================================================

CREATE TABLE IF NOT EXISTS lawful_intercept.connection_metadata_logs
(
    -- ClickHouse'da birincil anahtar sütun sıralaması ile örtüşmeli
    -- (Sık filtre: zaman + kullanıcı)
    event_timestamp     DateTime64(3, 'UTC'),    -- Milisaniye hassasiyetli UTC zaman
    event_date          Date DEFAULT toDate(event_timestamp),   -- Partition için

    -- Olay türü
    event_type          LowCardinality(String),  -- 'conn_open','conn_close','msg_sent','call_init' vs.

    -- Bağlantı tarafları (anonymized)
    -- KVKK: IP adresleri hash'lenerek saklanır, plaintext saklanmaz
    source_ip_hash      FixedString(64),         -- SHA-256(IP + daily_salt)
    source_country_code LowCardinality(String),  -- TR, DE, US...
    source_asn          UInt32,                  -- Otonom Sistem Numarası (ISP tespiti)
    source_port         UInt16,

    dest_ip_hash        FixedString(64),         -- Sunucu IP hash'i (hangi node)
    dest_port           UInt16,
    dest_datacenter     LowCardinality(String),  -- 'tr-ist-az1', 'tr-ank-az2', 'eu-ams-az1'

    -- Cihaz kimliği (anonymized device fingerprint, UUID formatında)
    source_device_id    UUID,                    -- users tablosundaki device_id
    dest_device_id      UUID,                    -- Alıcı cihaz ID (varsa)

    -- Bağlantı özellikleri
    connection_type     LowCardinality(String),  -- 'websocket', 'grpc', 'http', 'push'
    protocol_version    LowCardinality(String),  -- 'ws/1.0', 'h2', 'h3/quic'
    tls_version         LowCardinality(String),  -- 'TLS1.3', 'TLS1.2'
    cipher_suite        LowCardinality(String),  -- TLS cipher (ECDHE-AES256-GCM-SHA384)

    -- Süre ve boyut (içerik değil, trafik analizi için)
    session_duration_ms UInt32,                  -- Bağlantı süresi (milisaniye)
    bytes_sent          UInt64,                  -- Sunucudan istemciye gönderilen byte
    bytes_received      UInt64,                  -- İstemciden alınan byte
    message_count       UInt32,                  -- Bu oturumda gönderilen mesaj sayısı (içerik yok)

    -- Oturum tanımlayıcısı (bağlantı korelasyonu için)
    session_id          UUID,                    -- WebSocket oturum UUID'si
    trace_id            String,                  -- Distributed tracing (OpenTelemetry)

    -- Meta veri bütünlük hash'i
    -- Log kaydının manipüle edilmediğini kanıtlamak için HMAC
    -- HMAC-SHA256(tüm alanlar + log_signing_key)
    -- log_signing_key: HSM'de saklanan, rotasyonlu imzalama anahtarı
    metadata_hash       FixedString(64),

    -- Yasal kayıt bilgisi
    legal_hold          UInt8 DEFAULT 0,         -- 1=mahkeme kararıyla uzatılmış saklama
    data_controller     LowCardinality(String) DEFAULT 'TurkiyeMesajlasma_AS',
    processing_purpose  LowCardinality(String) DEFAULT 'lawful_intercept',

    -- ClickHouse sharding için
    shard_key           UInt8 MATERIALIZED cityHash64(source_device_id) % 16,

    -- İndeks hızlandırma (Bloom filter ve skip index)
    INDEX idx_device_id source_device_id TYPE bloom_filter(0.01) GRANULARITY 4,
    INDEX idx_event_type event_type TYPE set(50) GRANULARITY 1,
    INDEX idx_source_asn source_asn TYPE minmax GRANULARITY 8,
    INDEX idx_session_id session_id TYPE bloom_filter(0.01) GRANULARITY 4
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/lawful_intercept/connection_metadata_logs',
    '{replica}'
)
-- Partition: Günlük (aylık log hacmi TB seviyesinde olabileceğinden)
PARTITION BY toYYYYMMDD(event_date)
-- Sıralama anahtarı: En sık sorgu paterni: zaman + cihaz
ORDER BY (event_timestamp, source_device_id, dest_device_id, session_id)
-- Birincil anahtar (ORDER BY'dan küçük olabilir)
PRIMARY KEY (event_timestamp, source_device_id)
-- Veri saklama: 730 gün = 2 yıl (5651 sayılı Kanun: ISS için 2 yıl)
TTL event_date + INTERVAL 730 DAY DELETE
SETTINGS
    index_granularity = 8192,
    -- ZSTD sıkıştırma: metadata için yüksek sıkıştırma oranı (5-10x)
    compress_by_default = true,
    merge_with_ttl_timeout = 3600,
    -- ReplicatedMergeTree için replication factor
    min_replicas_for_select = 1,
    -- Büyük partition'lar için optimize
    max_bytes_to_merge_at_max_space_in_pool = 161061273600; -- 150 GB

-- Yorum: Bu tabloyu neden PARTITION BY date kullanıyoruz?
-- Yasal talepler genellikle "şu tarihten bu tarihe kadar" şeklinde gelir.
-- Günlük partition ile sadece ilgili partition'lar okunur, full table scan olmaz.
-- Örnek: SELECT * WHERE event_date BETWEEN '2025-01-01' AND '2025-01-31'
--   -> Sadece 31 partition okunur (tüm yıllık log değil)

-- =============================================================================
-- BÖLÜM 2: KULLANICI BAĞLANTI OYTELEMİ
-- Bir kullanıcının tüm oturumlarının özeti (aggregated view)
-- Gerçek zamanlı yasal talep sorgularında hız için materialized view
-- =============================================================================

CREATE TABLE IF NOT EXISTS lawful_intercept.user_session_summaries
(
    summary_date        Date,
    device_id           UUID,

    -- Günlük agregasyon (kullanıcı aktivitesi özeti)
    total_sessions      UInt32,
    total_duration_sec  UInt64,
    total_messages_sent UInt32,
    total_bytes_sent    UInt64,
    total_bytes_received UInt64,

    -- Bağlandığı IP country'lerin özeti
    countries_set       Array(LowCardinality(String)),
    asn_set             Array(UInt32),

    -- İlk ve son bağlantı zamanı
    first_seen_at       DateTime64(3, 'UTC'),
    last_seen_at        DateTime64(3, 'UTC'),

    -- Platform bilgisi (mobil mi, web mi)
    platform_types      Array(LowCardinality(String)),

    INDEX idx_device_id device_id TYPE bloom_filter(0.01) GRANULARITY 4
)
ENGINE = ReplicatedSummingMergeTree(
    '/clickhouse/tables/{shard}/lawful_intercept/user_session_summaries',
    '{replica}'
)
PARTITION BY toYYYYMM(summary_date)    -- Aylık partition (daha az partition sayısı)
ORDER BY (summary_date, device_id)
TTL summary_date + INTERVAL 730 DAY DELETE
SETTINGS index_granularity = 8192;

-- =============================================================================
-- BÖLÜM 3: HALİLER İÇİN ERİŞİM LOGu (Who Accessed What)
-- Kimin hangi yasal logu ne zaman sorguladığını izle
-- Yasal log'a erişen yetkili/sistem de loglanır (audit of the audit)
-- =============================================================================

CREATE TABLE IF NOT EXISTS lawful_intercept.access_audit_log
(
    access_timestamp    DateTime64(3, 'UTC'),
    access_date         Date DEFAULT toDate(access_timestamp),

    -- Erişen taraf
    accessor_type       LowCardinality(String),  -- 'internal_admin', 'legal_request', 'court_order'
    accessor_id         String,                  -- Sistem kullanıcısı veya mahkeme kararı no
    accessor_ip_hash    FixedString(64),

    -- Erişilen veri
    queried_device_id   UUID,
    query_date_from     Date,
    query_date_to       Date,
    query_type          LowCardinality(String),  -- 'session_list', 'connection_detail', 'export'

    -- Sonuç
    records_returned    UInt32,
    export_format       LowCardinality(String),  -- 'json', 'csv', 'pdf_report'
    export_hash         FixedString(64),         -- Dışa aktarılan datanın SHA-256 hash'i

    -- Hukuki dayanak
    court_order_number  Nullable(String),        -- Mahkeme kararı numarası
    legal_authority     Nullable(String),        -- Savcılık/BTK/Mahkeme adı

    -- Sistem kaydı (değiştirilemez)
    server_node_id      String,
    request_trace_id    String
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/lawful_intercept/access_audit_log',
    '{replica}'
)
PARTITION BY toYYYYMM(access_date)
ORDER BY (access_timestamp, accessor_id, queried_device_id)
-- Erişim logları 5 yıl saklanır (hukuki ispat için)
TTL access_date + INTERVAL 1825 DAY DELETE
SETTINGS index_granularity = 8192;

-- =============================================================================
-- BÖLÜM 4: GERÇEK ZAMANLI UYARI TABLOSU
-- Anormal trafik pattern'leri için (DDoS, spam, bot tespiti)
-- Bu tablo yasal loglama değil, güvenlik operasyonu için
-- =============================================================================

CREATE TABLE IF NOT EXISTS lawful_intercept.anomaly_detection_events
(
    detected_at         DateTime64(3, 'UTC'),
    detection_date      Date DEFAULT toDate(detected_at),

    anomaly_type        LowCardinality(String),  -- 'high_message_rate', 'geo_anomaly', 'bot_pattern'
    severity            LowCardinality(String),  -- 'low', 'medium', 'high', 'critical'

    device_id           UUID,
    source_ip_hash      FixedString(64),
    source_asn          UInt32,

    -- Tespit edilen metrik
    metric_name         LowCardinality(String),  -- 'messages_per_second', 'connection_count'
    metric_value        Float64,
    metric_threshold    Float64,

    -- Alınan aksiyon
    action_taken        LowCardinality(String),  -- 'alert_only', 'rate_limit', 'block', 'report'

    raw_context         String    -- JSON: anomali için ek bağlam (içerik değil, sayısal metrik)
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/lawful_intercept/anomaly_detection_events',
    '{replica}'
)
PARTITION BY toYYYYMMDD(detection_date)
ORDER BY (detected_at, anomaly_type, device_id)
TTL detection_date + INTERVAL 90 DAY DELETE
SETTINGS index_granularity = 8192;

-- =============================================================================
-- BÖLÜM 5: MATERIALIZED VIEW - GERÇEK ZAMANLI LOG YAZIMI
-- Ana tablo → günlük özet otomatik güncelleme
-- =============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS lawful_intercept.mv_daily_session_aggregator
TO lawful_intercept.user_session_summaries
AS
SELECT
    toDate(event_timestamp)             AS summary_date,
    source_device_id                    AS device_id,
    count()                             AS total_sessions,
    sum(session_duration_ms) / 1000     AS total_duration_sec,
    sum(message_count)                  AS total_messages_sent,
    sum(bytes_sent)                     AS total_bytes_sent,
    sum(bytes_received)                 AS total_bytes_received,
    groupUniqArray(source_country_code) AS countries_set,
    groupUniqArray(source_asn)          AS asn_set,
    min(event_timestamp)                AS first_seen_at,
    max(event_timestamp)                AS last_seen_at,
    groupUniqArray(connection_type)     AS platform_types
FROM lawful_intercept.connection_metadata_logs
WHERE event_type = 'conn_close'    -- Oturum kapanışında özetle
GROUP BY summary_date, source_device_id;

-- =============================================================================
-- BÖLÜM 6: YASAL TALEP SORGU ŞABLONları (Production Queries)
-- Hukuk birimi ve BTK entegrasyon sistemi için hazır sorgular
-- =============================================================================

-- Şablon 1: Belirli bir cihazın belirli tarih aralığındaki oturumları
-- (Mahkeme kararı ile savcılık talebi)
/*
SELECT
    event_timestamp,
    event_type,
    source_ip_hash,             -- Hash: ham IP verilmez, hash verilir
    source_country_code,
    source_asn,
    connection_type,
    session_duration_ms,
    message_count,
    bytes_sent + bytes_received AS total_traffic_bytes,
    legal_hold
FROM lawful_intercept.connection_metadata_logs
WHERE source_device_id = '<uuid>'
  AND event_date BETWEEN '<from_date>' AND '<to_date>'
ORDER BY event_timestamp ASC
LIMIT 10000;
*/

-- Şablon 2: IP aralığından bağlanan cihazlar (DDoS/Bot soruşturması)
/*
SELECT
    source_device_id,
    source_ip_hash,
    count() AS connection_count,
    sum(message_count) AS total_messages,
    min(event_timestamp) AS first_seen,
    max(event_timestamp) AS last_seen
FROM lawful_intercept.connection_metadata_logs
WHERE source_asn = 9121  -- Türk Telekom ASN
  AND event_date = today()
  AND event_type = 'conn_open'
GROUP BY source_device_id, source_ip_hash
HAVING connection_count > 100    -- Anormal: 100'den fazla bağlantı
ORDER BY connection_count DESC
LIMIT 100;
*/

-- Şablon 3: Günlük trafik özeti (Telco raporlama)
/*
SELECT
    summary_date,
    count(DISTINCT device_id) AS unique_devices,
    sum(total_sessions) AS total_sessions,
    sum(total_messages_sent) AS total_messages,
    sum(total_bytes_sent + total_bytes_received) / 1e9 AS total_gb
FROM lawful_intercept.user_session_summaries
WHERE summary_date >= today() - 30
GROUP BY summary_date
ORDER BY summary_date DESC;
*/

-- =============================================================================
-- BÖLÜM 7: MergeTree Replication Yapılandırması
-- ZooKeeper/ClickHouse Keeper cluster konfigürasyonu (config.xml'e eklenir)
-- =============================================================================

/*
<!-- ClickHouse config.xml eklentisi (ZooKeeper cluster) -->
<zookeeper>
    <node index="1">
        <host>zk-1.internal.turkiyemesajlasma.com</host>
        <port>2181</port>
    </node>
    <node index="2">
        <host>zk-2.internal.turkiyemesajlasma.com</host>
        <port>2181</port>
    </node>
    <node index="3">
        <host>zk-3.internal.turkiyemesajlasma.com</host>
        <port>2181</port>
    </node>
</zookeeper>

<remote_servers>
    <lawful_intercept_cluster>
        <shard>
            <weight>1</weight>
            <internal_replication>true</internal_replication>
            <replica>
                <host>ch-1.internal.turkiyemesajlasma.com</host>
                <port>9000</port>
                <user>clickhouse_replication_user</user>
            </replica>
            <replica>
                <host>ch-2.internal.turkiyemesajlasma.com</host>
                <port>9000</port>
                <user>clickhouse_replication_user</user>
            </replica>
        </shard>
        <shard>
            <weight>1</weight>
            <internal_replication>true</internal_replication>
            <replica>
                <host>ch-3.internal.turkiyemesajlasma.com</host>
                <port>9000</port>
                <user>clickhouse_replication_user</user>
            </replica>
            <replica>
                <host>ch-4.internal.turkiyemesajlasma.com</host>
                <port>9000</port>
                <user>clickhouse_replication_user</user>
            </replica>
        </shard>
    </lawful_intercept_cluster>
</remote_servers>

<macros>
    <!-- Her node'a özgü, deployment sırasında set edilir -->
    <shard>01</shard>
    <replica>ch-1.internal.turkiyemesajlasma.com</replica>
</macros>
*/

-- =============================================================================
-- BÖLÜM 8: DAĞITILMIŞ TABLOLAR (Distributed Engine)
-- Tüm shard'ları tek tablo olarak sorgulama
-- =============================================================================

CREATE TABLE IF NOT EXISTS lawful_intercept.connection_metadata_logs_distributed
AS lawful_intercept.connection_metadata_logs
ENGINE = Distributed(
    'lawful_intercept_cluster',          -- Cluster adı (config.xml'de tanımlı)
    'lawful_intercept',                  -- Veritabanı
    'connection_metadata_logs',          -- Yerel tablo
    cityHash64(source_device_id)         -- Sharding: cihaz hash'i ile dağıt
);

-- Kullanım: Production sorgular distributed tablo üzerinden yapılır
-- CH otomatik olarak ilgili shard'ları sorgular ve sonuçları birleştirir.

-- =============================================================================
-- BÖLÜM 9: ROW-LEVEL SECURITY (Erişim Kontrolü)
-- Yasal log verilerine erişim sadece yetkili roller
-- =============================================================================

-- Rol oluşturma
CREATE ROLE IF NOT EXISTS lawful_intercept_readonly;     -- BTK entegrasyonu (sadece okuma)
CREATE ROLE IF NOT EXISTS lawful_intercept_admin;         -- Sistem yöneticisi
CREATE ROLE IF NOT EXISTS lawful_intercept_auditor;       -- Dış denetçi (sınırlı erişim)

-- Okuma yetkisi (BTK/Savcılık sistemi)
GRANT SELECT ON lawful_intercept.connection_metadata_logs TO lawful_intercept_readonly;
GRANT SELECT ON lawful_intercept.connection_metadata_logs_distributed TO lawful_intercept_readonly;
GRANT SELECT ON lawful_intercept.user_session_summaries TO lawful_intercept_readonly;

-- Yönetici yetkisi (sadece şirket içi yetkili personel)
GRANT ALL ON lawful_intercept.* TO lawful_intercept_admin;

-- Denetçi yetkisi (sadece access_audit_log okuyabilir)
GRANT SELECT ON lawful_intercept.access_audit_log TO lawful_intercept_auditor;

-- Kullanıcı oluşturma (şifreler deployment sırasında set edilir, Vault'dan alınır)
CREATE USER IF NOT EXISTS 'btk_readonly' IDENTIFIED WITH sha256_hash BY '' DEFAULT ROLE lawful_intercept_readonly;
CREATE USER IF NOT EXISTS 'legal_admin' IDENTIFIED WITH sha256_hash BY '' DEFAULT ROLE lawful_intercept_admin;

-- Row-level policy: BTK kullanıcısı sadece Türkiye kaynaklı kayıtları görebilir
CREATE ROW POLICY IF NOT EXISTS btk_tr_only ON lawful_intercept.connection_metadata_logs
    FOR SELECT USING source_country_code = 'TR'
    TO lawful_intercept_readonly;

-- =============================================================================
-- ÖZET: MESAJ İÇERİĞİ NEDEN SAKLANAMAZ?
-- =============================================================================
-- 1. Signal Protocol Double Ratchet: Her mesaj ayrı ephemeral key ile şifrelenir.
--    Sunucu bu key'lere hiçbir zaman sahip olmaz. (Forward Secrecy)
--
-- 2. X3DH (Extended Triple Diffie-Hellman): İlk mesajda oturum kurulumu
--    yapılır ve paylaşılan sır (shared secret) sunucudan geçmeden elde edilir.
--
-- 3. Zero-Knowledge sunucu mimarisi: Sunucular yalnızca şifreli zarfları
--    yönlendirir; anahtarlar olmadan içeriği açamazlar.
--
-- 4. Mahkeme kararı durumu: Yetkili makamlar kullanıcının anahtarlarını
--    istemek zorundadır. Bu anahtarlar yalnızca kullanıcı cihazındadır.
--    Cihaz şifreli (Secure Enclave / Android Keystore) olduğundan
--    fiziksel ele geçirme olmadan erişilemez.
--
-- 5. Bu tablo ETSI TS 101 671 "IRI (Intercept Related Information)"
--    standardındaki metadata gerekliliklerini karşılar.
-- =============================================================================
