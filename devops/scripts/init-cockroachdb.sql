-- turkiye_mesajlasma veritabanını oluştur
CREATE DATABASE IF NOT EXISTS turkiye_mesajlasma;

USE turkiye_mesajlasma;

-- Kullanıcılar tablosu
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_hash TEXT NOT NULL,
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    region TEXT
);

-- Cihazlar tablosu (Her kullanıcının birden fazla cihazı olabilir)
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    platform TEXT,
    push_token TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Cihaz anahtarları (Uçtan uca şifreleme için kimlik anahtarları)
CREATE TABLE IF NOT EXISTS device_keys (
    device_id UUID PRIMARY KEY REFERENCES devices(id) ON DELETE CASCADE,
    identity_key BYTEA NOT NULL,
    signed_prekey BYTEA NOT NULL,
    signed_prekey_signature BYTEA NOT NULL
);

-- Tek kullanımlık ön anahtarlar (E2EE)
CREATE TABLE IF NOT EXISTS one_time_prekeys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    key_id INT NOT NULL,
    public_key BYTEA NOT NULL
);

-- Hızlı erişim için indeksler
CREATE INDEX IF NOT EXISTS idx_users_phone_hash ON users(phone_hash);
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_one_time_prekeys_device_id ON one_time_prekeys(device_id);
