-- Keyspace oluşturma (Turkiye Mesajlasma için)
CREATE KEYSPACE IF NOT EXISTS turkiye_mesajlasma 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE turkiye_mesajlasma;

-- Mesajlar tablosu
CREATE TABLE IF NOT EXISTS messages (
    conversation_id text,
    message_id timeuuid,
    sender_device_id text,
    ciphertext blob,
    nonce blob,
    created_at timestamp,
    read_at timestamp,
    PRIMARY KEY (conversation_id, message_id)
) WITH CLUSTERING ORDER BY (message_id DESC) 
AND default_time_to_live = 31536000; -- 1 yıllık (sn cinsinden) saklama süresi

-- Çevrimdışı mesaj kuyruğu (Alıcı cihaz çevrimdışı olduğunda mesajları tutmak için)
CREATE TABLE IF NOT EXISTS offline_message_queue (
    device_id text,
    message_id timeuuid,
    envelope blob,
    created_at timestamp,
    PRIMARY KEY (device_id, message_id)
);
