-- Yasal dinleme (Lawful Intercept) veritabanı
CREATE DATABASE IF NOT EXISTS lawful_intercept;

-- Bağlantı logları tablosu
CREATE TABLE IF NOT EXISTS lawful_intercept.connection_logs (
    session_id String,
    user_id String,
    device_id String,
    node_id String,
    ip_hash String,
    platform String,
    event_type UInt8,
    connected_at DateTime,
    duration_ms UInt32
) ENGINE = MergeTree() 
PARTITION BY toYYYYMMDD(connected_at) 
ORDER BY (connected_at, user_id);
