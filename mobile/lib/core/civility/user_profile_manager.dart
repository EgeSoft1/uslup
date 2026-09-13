import 'package:flutter/foundation.dart';

/// 2. Kişiselleştirilmiş Eşik Değerleri ve Davranış Sicili
///
/// Kullanıcının cihaz üzerindeki nezaket geçmişini tutar.
/// Eğer kullanıcı sürekli temiz bir dil kullanıyorsa, argo kullanımını "şaka" 
/// olarak değerlendirip tolerans (eşik) seviyesini esnetir.
/// Sürekli toksik dil kullananlarda ise uyarı eşiğini düşürür.
class UserProfileManager {
  static final UserProfileManager instance = UserProfileManager._();
  UserProfileManager._();

  int _cleanMessagesCount = 0;
  int _toxicMessagesCount = 0;

  /// Aktif Öğrenme (Active Learning) için yerel hata havuzu.
  /// Sunucuya gitmez, cihazda birikir ve Federated Learning döngüsünde
  /// modelin kendi kendini on-device eğitmesi için kullanılır.
  final List<String> _falsePositiveQueue = [];

  /// 25. Cihaz-İçi Karantina (Local Vault)
  /// Şiddeti çok yüksek (>0.90) ihlaller merkeze gönderilmez,
  /// hukuki veya ebeveyn denetimi için telefonun şifreli kasasında saklanır.
  final List<String> _localVaultQuarantine = [];

  void recordCleanMessage() {
    _cleanMessagesCount++;
    // Sicil iyileştikçe eski toksik geçmişi silinir (İyileşme payı)
    if (_cleanMessagesCount % 10 == 0 && _toxicMessagesCount > 0) {
      _toxicMessagesCount--;
    }
  }

  void recordToxicMessage(String text, double severity) {
    _toxicMessagesCount++;
    _cleanMessagesCount = 0; // Temiz seri bozuldu
    
    // Yüksek riskli mesajları Cihaz-İçi Karantinaya al (Bölüm C - Madde 25)
    if (severity > 0.90) {
      _localVaultQuarantine.add(text);
      debugPrint('🚨 Cihaz-İçi Karantinaya Alındı (Local Vault): Yüksek Şiddetli İçerik');
    }
  }

  /// Aktif öğrenme için "Bu uyarı yanlıştı" geri bildirimi kaydı.
  void recordFalsePositive(String text) {
    _falsePositiveQueue.add(text);
    debugPrint('Active Learning Havuzuna Eklendi: $text');
  }

  /// ML modeli için dinamik eşik (0.0 ile 1.0 arası).
  /// Standart eşik 0.5'tir.
  double get dynamicThreshold {
    // Sicili çok bozuk bir kullanıcı (Çok agresif): Eşik 0.35'e düşer (Çok hassas)
    if (_toxicMessagesCount > 5) return 0.35;
    
    // Sicili mükemmel bir kullanıcı: Eşik 0.65'e çıkar (Toleranslı)
    if (_cleanMessagesCount > 20) return 0.65;
    
    // Standart kullanıcı
    return 0.50;
  }
}
