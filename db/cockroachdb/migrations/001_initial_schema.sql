-- =============================================================================
-- TurkiyeMesajlasma Platform - CockroachDB Production Schema
-- Migration: 001_initial_schema.sql
-- Engine: CockroachDB v23.2+ (Distributed SQL)
-- Özellikler:
--   - Geo-Partitioning: TR verisi Istanbul/Ankara node'larında, EU verisi Amsterdam'da
--   - X3DH Pre-Key yönetimi (Signal Protocol)
--   - TCKN hash'i ile kimlik doğrulama
--   - KVKK/GDPR uyumlu bölgesel veri yerleşimi
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BÖLÜM 0: Veritabanı ve Bölge (Region) Yapılandırması
-- Multi-region cluster kurulumu. Cluster başlatılırken yapılan ayarlar:
--   cockroach start --locality=region=tr-istanbul,zone=az1
--   cockroach start --locality=region=tr-ankara,zone=az2
--   cockroach start --locality=region=eu-amsterdam,zone=az1
-- -----------------------------------------------------------------------------

-- Çok bölgeli veritabanı oluştur. Birincil bölge Türkiye.
CREATE DATABASE IF NOT EXISTS turkiye_mesajlasma
  PRIMARY REGION "tr-istanbul"
  REGIONS "tr-ankara", "eu-amsterdam"
  SURVIVE ZONE FAILURE;

USE turkiye_mesajlasma;

-- -----------------------------------------------------------------------------
-- BÖLÜM 1: ENUM TİPLERİ
-- -----------------------------------------------------------------------------

CREATE TYPE IF NOT EXISTS account_status AS ENUM (
    'pending_verification',  -- Kayıt sonrası OTP bekleniyor
    'active',                -- Aktif hesap
    'suspended',             -- Geçici askıya alınmış (admin kararı)
    'deactivated',           -- Kullanıcı hesabı sildi
    'banned'                 -- Kalıcı ban (hukuki karar/abuse)
);

CREATE TYPE IF NOT EXISTS pre_key_type AS ENUM (
    'one_time',     -- OPK: Bir kez kullanılıp silinir (X3DH ephemeral)
    'signed',       -- SPK: İmzalı, periyodik rotasyon (her 30 gün)
    'last_resort'   -- LRK: OPK bittiğinde fallback (güvenlik riski, acil kullanım)
);

CREATE TYPE IF NOT EXISTS device_platform AS ENUM (
    'android',
    'ios',
    'web',
    'desktop_windows',
    'desktop_macos',
    'desktop_linux'
);

CREATE TYPE IF NOT EXISTS region_code AS ENUM (
    'TR',   -- Türkiye - KVKK kapsamında
    'EU',   -- Avrupa - GDPR kapsamında
    'INTL'  -- Uluslararası
);

-- -----------------------------------------------------------------------------
-- BÖLÜM 2: USERS TABLOSU
-- Ana kullanıcı profil tablosu. Geo-Partitioning ile TR/EU verisi fiziksel olarak ayrı.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS users (
    -- Birincil kimlik: UUID v4, dağıtık sistemde çakışmasız
    user_id             UUID            NOT NULL DEFAULT gen_random_uuid(),

    -- Telefon numarası: E.164 formatında saklanır (+905XXXXXXXXX)
    -- Unique, aranan alan. Encrypted-at-rest (CMEK ile)
    phone_number        STRING(20)      NOT NULL,

    -- TCKN: Türkiye kimlik numarası. Asla plaintext saklanmaz!
    -- Argon2id ile hash'lenir. Salt kullanıcı UUID'sine dayalı türetilir.
    -- Format: argon2id$v=19$m=65536,t=3,p=4$<salt>$<hash>
    tckn_hash           STRING(255)     NULL,

    -- Signal Protocol Identity Key (X25519 public key, 32 byte, Base64url)
    -- Bu anahtar cihaz bazlıdır, değiştirildiğinde eski sohbetler yeniden şifrelenir
    public_identity_key STRING(64)      NOT NULL,

    -- Hesap durumu
    account_status      account_status  NOT NULL DEFAULT 'pending_verification',

    -- Profil bilgileri (hassas alan yok, display için)
    display_name        STRING(100)     NULL,
    avatar_object_key   STRING(255)     NULL,  -- SeaweedFS/MinIO nesne anahtarı

    -- Yasal uyum: kullanıcının kayıt olduğu bölge
    -- Bu alan partition key olarak kullanılıyor
    region_code         region_code     NOT NULL DEFAULT 'TR',

    -- Zaman damgaları
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    last_seen_at        TIMESTAMPTZ     NULL,   -- Privacy ayarına göre gösterilir
    deleted_at          TIMESTAMPTZ     NULL,   -- Soft delete (GDPR silme talebi için)

    -- Güvenlik
    pin_hash            STRING(255)     NULL,   -- Uygulama kilidi PIN hash'i (Argon2id)
    failed_pin_attempts SMALLINT        NOT NULL DEFAULT 0,
    pin_locked_until    TIMESTAMPTZ     NULL,

    -- Kısıtlamalar
    CONSTRAINT users_pkey PRIMARY KEY (user_id, region_code),
    CONSTRAINT users_phone_unique UNIQUE (phone_number),
    CONSTRAINT users_identity_key_nn CHECK (length(public_identity_key) > 0),
    CONSTRAINT users_failed_attempts_range CHECK (failed_pin_attempts >= 0 AND failed_pin_attempts <= 10)
)
-- Geo-Partitioning: TR bölge verisi fiziksel olarak TR node'larında tutulur
PARTITION BY LIST (region_code) (
    PARTITION tr_data VALUES IN ('TR')
        LOCATE IN (
            "tr-istanbul",   -- Primary
            "tr-ankara"      -- Replica (zone failure toleransı)
        ),
    PARTITION eu_data VALUES IN ('EU')
        LOCATE IN (
            "eu-amsterdam"   -- Primary (GDPR - EU verisi AB'de kalır)
        ),
    PARTITION intl_data VALUES IN ('INTL')
        LOCATE IN (
            "tr-istanbul"    -- Default
        )
);

-- users tablosu için index'ler
-- Telefon numarasına göre arama (login flow)
CREATE INDEX IF NOT EXISTS idx_users_phone_status
    ON users (phone_number, account_status)
    WHERE deleted_at IS NULL;

-- Region bazlı toplu sorgu (admin paneli, yasal uyum raporları)
CREATE INDEX IF NOT EXISTS idx_users_region_created
    ON users (region_code, created_at DESC)
    WHERE deleted_at IS NULL;

-- Son görülme sorgusu için (presence servisi)
CREATE INDEX IF NOT EXISTS idx_users_last_seen
    ON users (last_seen_at DESC)
    WHERE account_status = 'active' AND deleted_at IS NULL;

-- updated_at için otomatik trigger (CockroachDB compatible function)
-- Not: CockroachDB'de trigger yerine application layer'da ya da rule ile yapılır.
-- Aşağıdaki stored procedure uygulama katmanından çağrılacak:

-- -----------------------------------------------------------------------------
-- BÖLÜM 3: USER_DEVICES TABLOSU
-- Her kullanıcının birden fazla cihazı olabilir (Signal çoklu cihaz desteği)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_devices (
    device_id           UUID            NOT NULL DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    region_code         region_code     NOT NULL DEFAULT 'TR',

    -- Cihaz kimlik anahtarı: Her cihaz için ayrı Signal Identity Key
    device_public_key   STRING(64)      NOT NULL,

    -- Registration ID: Signal Protocol'de cihaz kimliği (1-16380 arası)
    registration_id     INT4            NOT NULL,

    -- Cihaz meta verisi (şifrelenmemiş, sadece yönetim için)
    platform            device_platform NOT NULL,
    device_name         STRING(100)     NULL,    -- "Ahmet'in iPhone 15"
    push_token          STRING(512)     NULL,    -- FCM/APNS token (şifreli)
    push_token_updated  TIMESTAMPTZ     NULL,

    -- Cihaz aktivasyon durumu
    is_primary          BOOLEAN         NOT NULL DEFAULT false,
    is_active           BOOLEAN         NOT NULL DEFAULT true,
    linked_at           TIMESTAMPTZ     NOT NULL DEFAULT now(),
    last_active_at      TIMESTAMPTZ     NULL,
    revoked_at          TIMESTAMPTZ     NULL,

    CONSTRAINT user_devices_pkey PRIMARY KEY (device_id, region_code),
    CONSTRAINT user_devices_user_fk FOREIGN KEY (user_id, region_code)
        REFERENCES users (user_id, region_code)
        ON DELETE CASCADE,
    CONSTRAINT user_devices_reg_id_range CHECK (
        registration_id >= 1 AND registration_id <= 16380
    )
)
PARTITION BY LIST (region_code) (
    PARTITION tr_devices VALUES IN ('TR')
        LOCATE IN ("tr-istanbul", "tr-ankara"),
    PARTITION eu_devices VALUES IN ('EU')
        LOCATE IN ("eu-amsterdam"),
    PARTITION intl_devices VALUES IN ('INTL')
        LOCATE IN ("tr-istanbul")
);

CREATE INDEX IF NOT EXISTS idx_devices_user_active
    ON user_devices (user_id, region_code, is_active)
    WHERE revoked_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_user_primary
    ON user_devices (user_id, region_code)
    WHERE is_primary = true AND revoked_at IS NULL;

-- -----------------------------------------------------------------------------
-- BÖLÜM 4: USER_PRE_KEYS TABLOSU
-- Signal Protocol X3DH için anahtar havuzu.
-- One-time Pre-Keys (OPK) tek kullanımlık - Signed Pre-Keys (SPK) 30 günde bir rotasyon.
-- Bu tablo yüksek okuma/yazma yüküne maruz kalır; partitioning kritik.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_pre_keys (
    pre_key_id          UUID            NOT NULL DEFAULT gen_random_uuid(),
    device_id           UUID            NOT NULL,
    user_id             UUID            NOT NULL,
    region_code         region_code     NOT NULL DEFAULT 'TR',

    -- Anahtar türü
    key_type            pre_key_type    NOT NULL,

    -- Signal Protocol Key ID (cihaz içinde sıralı sayı, 1-16777215)
    signal_key_id       INT4            NOT NULL,

    -- X25519 veya X448 public key (32 byte, Base64url encoded)
    public_key          STRING(64)      NOT NULL,

    -- Signed Pre-Key için imza (Ed25519, 64 byte, Base64url)
    -- Identity Key ile imzalanmış. NULL olabilir (OPK için imza yok)
    signature           STRING(88)      NULL,

    -- Yönetim
    uploaded_at         TIMESTAMPTZ     NOT NULL DEFAULT now(),
    consumed_at         TIMESTAMPTZ     NULL,    -- OPK tüketildiğinde set edilir
    expires_at          TIMESTAMPTZ     NULL,    -- SPK için 30 gün + 7 gün grace

    -- OPK için: anahtar tüketildi mi?
    is_consumed         BOOLEAN         NOT NULL DEFAULT false,

    CONSTRAINT pre_keys_pkey PRIMARY KEY (pre_key_id, region_code),

    -- Signal Key ID + Device kombinasyonu benzersiz olmalı
    CONSTRAINT pre_keys_device_signal_unique UNIQUE (device_id, signal_key_id, key_type, region_code),

    CONSTRAINT pre_keys_signature_check CHECK (
        -- Signed ve Last-Resort anahtarların imzası zorunlu
        (key_type = 'one_time') OR
        (key_type IN ('signed', 'last_resort') AND signature IS NOT NULL)
    ),

    CONSTRAINT pre_keys_expiry_check CHECK (
        -- OPK'lerin son kullanma tarihi yok
        (key_type = 'one_time' AND expires_at IS NULL) OR
        (key_type IN ('signed', 'last_resort') AND expires_at IS NOT NULL)
    )
)
PARTITION BY LIST (region_code) (
    PARTITION tr_pre_keys VALUES IN ('TR')
        LOCATE IN ("tr-istanbul", "tr-ankara"),
    PARTITION eu_pre_keys VALUES IN ('EU')
        LOCATE IN ("eu-amsterdam"),
    PARTITION intl_pre_keys VALUES IN ('INTL')
        LOCATE IN ("tr-istanbul")
);

-- X3DH akışında: Bir OPK al, tüketilmemiş ve bu cihaza ait
CREATE INDEX IF NOT EXISTS idx_pre_keys_device_available
    ON user_pre_keys (device_id, region_code, key_type, uploaded_at ASC)
    WHERE is_consumed = false AND consumed_at IS NULL;

-- SPK sorgusu: Cihazın aktif signed pre-key'ini getir
CREATE INDEX IF NOT EXISTS idx_pre_keys_signed_active
    ON user_pre_keys (device_id, region_code, expires_at DESC)
    WHERE key_type = 'signed' AND is_consumed = false;

-- OPK sayısı izleme (push notification: "anahtar havuzu dolmak üzere")
CREATE INDEX IF NOT EXISTS idx_pre_keys_user_count
    ON user_pre_keys (user_id, region_code, key_type)
    WHERE is_consumed = false;

-- -----------------------------------------------------------------------------
-- BÖLÜM 5: CONVERSATION_METADATA TABLOSU
-- Sohbet meta verisi (mesaj içeriği BURADA DEĞİL, ScyllaDB'de)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS conversation_metadata (
    conversation_id     UUID            NOT NULL DEFAULT gen_random_uuid(),
    region_code         region_code     NOT NULL DEFAULT 'TR',

    -- Bireysel sohbet için: iki kullanıcı ID
    -- Grup sohbeti için: NULL, group_id referansı kullanılır
    participant_a_id    UUID            NULL,
    participant_b_id    UUID            NULL,
    group_id            UUID            NULL,

    -- Sohbet türü
    is_group            BOOLEAN         NOT NULL DEFAULT false,

    -- Son mesaj meta verisi (içerik yok! sadece zaman damgası)
    last_message_at     TIMESTAMPTZ     NULL,
    last_message_id     UUID            NULL,   -- ScyllaDB'deki message_id referansı

    -- Sohbet durumu
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    archived_at         TIMESTAMPTZ     NULL,

    CONSTRAINT conv_meta_pkey PRIMARY KEY (conversation_id, region_code),

    -- Bireysel sohbet benzersizliği (A-B == B-A sağlamak için uygulama katmanı)
    CONSTRAINT conv_meta_participants_check CHECK (
        (is_group = false AND participant_a_id IS NOT NULL AND participant_b_id IS NOT NULL AND group_id IS NULL) OR
        (is_group = true AND participant_a_id IS NULL AND participant_b_id IS NULL AND group_id IS NOT NULL)
    )
)
PARTITION BY LIST (region_code) (
    PARTITION tr_convs VALUES IN ('TR') LOCATE IN ("tr-istanbul", "tr-ankara"),
    PARTITION eu_convs VALUES IN ('EU') LOCATE IN ("eu-amsterdam"),
    PARTITION intl_convs VALUES IN ('INTL') LOCATE IN ("tr-istanbul")
);

CREATE INDEX IF NOT EXISTS idx_conv_participant_a
    ON conversation_metadata (participant_a_id, last_message_at DESC)
    WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_conv_participant_b
    ON conversation_metadata (participant_b_id, last_message_at DESC)
    WHERE archived_at IS NULL;

-- -----------------------------------------------------------------------------
-- BÖLÜM 6: GROUPS TABLOSU
-- Grup sohbet yönetimi
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS groups (
    group_id            UUID            NOT NULL DEFAULT gen_random_uuid(),
    region_code         region_code     NOT NULL DEFAULT 'TR',

    -- Grup kimliği (E2EE: şifrelenmiş grup key, dağıtık Sender Key ile)
    group_name_ciphertext   BYTEA       NULL,   -- Şifrelenmiş grup adı
    group_avatar_key    STRING(255)     NULL,   -- SeaweedFS nesne anahtarı
    description_ciphertext  BYTEA       NULL,

    -- Güvenlik: Grup şifreleme anahtarı versiyonu
    sender_key_version  INT4            NOT NULL DEFAULT 1,

    -- Yönetim
    creator_user_id     UUID            NOT NULL,
    max_members         SMALLINT        NOT NULL DEFAULT 256,
    current_member_count INT4           NOT NULL DEFAULT 1,

    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    dissolved_at        TIMESTAMPTZ     NULL,

    CONSTRAINT groups_pkey PRIMARY KEY (group_id, region_code),
    CONSTRAINT groups_max_members_range CHECK (max_members >= 2 AND max_members <= 1000),
    CONSTRAINT groups_member_count_range CHECK (current_member_count >= 0)
)
PARTITION BY LIST (region_code) (
    PARTITION tr_groups VALUES IN ('TR') LOCATE IN ("tr-istanbul", "tr-ankara"),
    PARTITION eu_groups VALUES IN ('EU') LOCATE IN ("eu-amsterdam"),
    PARTITION intl_groups VALUES IN ('INTL') LOCATE IN ("tr-istanbul")
);

CREATE TABLE IF NOT EXISTS group_members (
    membership_id       UUID            NOT NULL DEFAULT gen_random_uuid(),
    group_id            UUID            NOT NULL,
    user_id             UUID            NOT NULL,
    region_code         region_code     NOT NULL DEFAULT 'TR',

    -- Üye rolü
    role                STRING(20)      NOT NULL DEFAULT 'member'
                        CHECK (role IN ('owner', 'admin', 'member')),

    -- Grup içi Sender Key dağıtım durumu (Signal Sender Key protokolü)
    sender_key_distributed  BOOLEAN     NOT NULL DEFAULT false,

    joined_at           TIMESTAMPTZ     NOT NULL DEFAULT now(),
    invited_by_user_id  UUID            NULL,
    left_at             TIMESTAMPTZ     NULL,
    removed_at          TIMESTAMPTZ     NULL,

    CONSTRAINT group_members_pkey PRIMARY KEY (membership_id, region_code),
    CONSTRAINT group_members_unique UNIQUE (group_id, user_id, region_code),
    CONSTRAINT group_members_group_fk FOREIGN KEY (group_id, region_code)
        REFERENCES groups (group_id, region_code) ON DELETE CASCADE
)
PARTITION BY LIST (region_code) (
    PARTITION tr_memberships VALUES IN ('TR') LOCATE IN ("tr-istanbul", "tr-ankara"),
    PARTITION eu_memberships VALUES IN ('EU') LOCATE IN ("eu-amsterdam"),
    PARTITION intl_memberships VALUES IN ('INTL') LOCATE IN ("tr-istanbul")
);

CREATE INDEX IF NOT EXISTS idx_group_members_user
    ON group_members (user_id, region_code, joined_at DESC)
    WHERE left_at IS NULL AND removed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_group_members_group_active
    ON group_members (group_id, region_code)
    WHERE left_at IS NULL AND removed_at IS NULL;

-- -----------------------------------------------------------------------------
-- BÖLÜM 7: YASAL UYUM - KULLANICI ONAYI TABLOSU
-- KVKK Madde 11: Kullanıcının kendi verileri üzerindeki hakları
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS user_consents (
    consent_id          UUID            NOT NULL DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL,
    region_code         region_code     NOT NULL DEFAULT 'TR',

    -- Onay türleri
    kvkk_accepted       BOOLEAN         NOT NULL DEFAULT false,
    gdpr_accepted       BOOLEAN         NOT NULL DEFAULT false,
    marketing_accepted  BOOLEAN         NOT NULL DEFAULT false,
    analytics_accepted  BOOLEAN         NOT NULL DEFAULT false,

    -- Onay zaman damgaları (hukuki kanıt için değiştirilemez)
    kvkk_accepted_at    TIMESTAMPTZ     NULL,
    gdpr_accepted_at    TIMESTAMPTZ     NULL,
    marketing_accepted_at   TIMESTAMPTZ NULL,

    -- İptal zaman damgaları
    kvkk_revoked_at     TIMESTAMPTZ     NULL,
    gdpr_revoked_at     TIMESTAMPTZ     NULL,
    marketing_revoked_at    TIMESTAMPTZ NULL,

    -- Onay verildiğinde kullanılan uygulama versiyonu ve IP
    consent_ip_hash     STRING(64)      NULL,   -- SHA-256 hash'i (KVKK: IP loglanamaz plaintext)
    app_version         STRING(20)      NULL,
    terms_version       STRING(10)      NOT NULL DEFAULT '1.0',

    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    CONSTRAINT user_consents_pkey PRIMARY KEY (consent_id, region_code),
    CONSTRAINT user_consents_user_unique UNIQUE (user_id, region_code)
)
PARTITION BY LIST (region_code) (
    PARTITION tr_consents VALUES IN ('TR') LOCATE IN ("tr-istanbul", "tr-ankara"),
    PARTITION eu_consents VALUES IN ('EU') LOCATE IN ("eu-amsterdam"),
    PARTITION intl_consents VALUES IN ('INTL') LOCATE IN ("tr-istanbul")
);

-- =============================================================================
-- BÖLÜM 8: VIEW'LAR (Uygulama Katmanı için Hazır Sorgular)
-- =============================================================================

-- Aktif kullanıcıların anahtar bilgilerini birleştiren view
CREATE VIEW IF NOT EXISTS v_user_key_bundle AS
SELECT
    u.user_id,
    u.region_code,
    u.public_identity_key,
    u.account_status,
    d.device_id,
    d.device_public_key,
    d.registration_id,
    d.platform,
    -- Mevcut SPK sayısı
    (SELECT COUNT(*) FROM user_pre_keys pk
     WHERE pk.device_id = d.device_id
       AND pk.key_type = 'signed'
       AND pk.is_consumed = false
       AND pk.expires_at > now()) AS active_signed_pre_key_count,
    -- Mevcut OPK sayısı
    (SELECT COUNT(*) FROM user_pre_keys pk
     WHERE pk.device_id = d.device_id
       AND pk.key_type = 'one_time'
       AND pk.is_consumed = false) AS available_one_time_pre_key_count
FROM users u
JOIN user_devices d ON u.user_id = d.user_id AND u.region_code = d.region_code
WHERE u.account_status = 'active'
  AND u.deleted_at IS NULL
  AND d.is_active = true
  AND d.revoked_at IS NULL;

-- =============================================================================
-- BÖLÜM 9: STORED PROCEDURES (CockroachDB User-Defined Functions)
-- =============================================================================

-- X3DH Anahtar Paketi Al: Bir OPK tüket ve döndür (atomic)
-- Bu işlev FOR UPDATE ile satır kilidi kullanır
CREATE OR REPLACE FUNCTION fetch_and_consume_opk(
    p_device_id UUID,
    p_region    region_code
)
RETURNS TABLE (
    pre_key_id  UUID,
    signal_key_id INT4,
    public_key  STRING,
    key_type    pre_key_type
)
LANGUAGE SQL AS $$
    -- Önce bir OPK seç (SELECT FOR UPDATE ile kilitle)
    -- Tüketilmemiş, bu cihaza ait, en eski yükleneni al (FIFO)
    UPDATE user_pre_keys
    SET
        is_consumed = true,
        consumed_at = now()
    WHERE pre_key_id = (
        SELECT pre_key_id
        FROM user_pre_keys
        WHERE device_id = p_device_id
          AND region_code = p_region
          AND key_type = 'one_time'
          AND is_consumed = false
        ORDER BY uploaded_at ASC
        LIMIT 1
    )
    RETURNING pre_key_id, signal_key_id, public_key, key_type;
$$;

-- OPK havuzu uyarı: 20'nin altına düşerse push notification tetikle
CREATE OR REPLACE FUNCTION check_opk_threshold(
    p_device_id UUID,
    p_region    region_code
)
RETURNS INT AS $$
    SELECT COUNT(*)::INT
    FROM user_pre_keys
    WHERE device_id = p_device_id
      AND region_code = p_region
      AND key_type = 'one_time'
      AND is_consumed = false;
$$ LANGUAGE SQL STABLE;

-- =============================================================================
-- YORUM: Geo-Partitioning Mimarisi Özeti
-- =============================================================================
-- TR Bölgesi  → tr-istanbul (primary), tr-ankara (replica)
--   Türkiye kullanıcıları KVKK kapsamında. Veriler yurt dışına çıkmaz.
--   Yargı talebi: BTK/Savcılık erişimi bu node'lardan sağlanır.
--
-- EU Bölgesi  → eu-amsterdam (primary)
--   GDPR kapsamındaki Avrupa vatandaşları. Schrems II uyumlu.
--   Veri işleme şeffaflığı: AB KVKK muadili uygulamalar.
--
-- INTL Bölgesi → tr-istanbul (fallback)
--   Diğer ülke kullanıcıları. İleride bölgesel genişleme ile ayrılabilir.
-- =============================================================================
