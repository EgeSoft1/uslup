// =============================================================================
// TurkiyeMesajlasma - Yerel Veritabanı Şeması
// Dosya: mobile/lib/data/local/schema/message.dart
//
// Amaç: Cihaz üzerindeki E2EE deşifre edilmiş mesajları saklamak.
// Sunucuda PLAINTEXT mesaj YOKTUR. Tümü cihazda, sqflite içinde şifreli bir
// veritabanı dosyasında bulunur.
// =============================================================================

class LocalMessage {
  int? id;

  // Global Mesaj ID'si (ScyllaDB'deki TimeUUID karşılığı)
  late String messageId;

  // Sohbet / Kullanıcı / Grup ID
  late String conversationId;

  late String senderId;
  late String senderDeviceId;

  // E2EE Çözülmüş Açık Metin (Sadece cihazda bulunur)
  late String plaintextContent;

  // Signal Protocol Meta Verisi (Mesajın yeniden şifrelenmesini önlemek için)
  late int messageType; // 1=WHISPER, 3=PREKEY vs.
  String? nonceHex; // Şifreleme/Çözme anında kullanılan IV
  
  // Medya Ekleri
  late bool hasMedia;
  String? mediaLocalPath; // Cihazdaki şifresi çözülmüş medya yolu
  String? mediaType;

  // Zaman Damgaları
  late DateTime timestamp; // Mesajın gönderilme zamanı
  DateTime? serverReceivedAt; 

  // Durum
  late MessageStatus status; // pending, sent, delivered, read, failed

  // Güvenlik & Silinme Durumu
  late bool isSelfDestructing; // Süreli Mesaj
  DateTime? destructAt; // Yok olma zamanı
  late bool isDeleted; // Soft-delete (GDPR uyumu için tamamen de silinebilir)
}

/// Mesaj Teslimat Durumu
enum MessageStatus {
  pending,    // Cihazda kuyrukta, henüz gönderilmedi (çevrimdışı vb.)
  sent,       // Sunucuya ulaştı (Tek tik)
  delivered,  // Karşı cihaza ulaştı (Çift tik)
  read,       // Karşı kullanıcı okudu (Mavi tik)
  failed      // Gönderim başarısız (Ağ veya Kripto hatası)
}
