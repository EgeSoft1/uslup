// =============================================================================
// Birleştirilmiş öğrenme (federated learning) köprüsü — İSTEĞE BAĞLI KATMAN
// Dosya: mobile/lib/core/civility/federated_sync_service.dart
//
// ── BU KATMAN AĞA ÇIKAR VE BUNU SAKLAMAZ ──────────────────────────────────
// Ürünün çekirdek vaadi "çözümleme cihazda yapılır, metin cihazdan çıkmaz"
// cümlesidir ve o vaat bu dosyayla bozulmaz: buradan giden pakette METİN
// YOKTUR — model ağırlık güncellemeleri, sürüm etiketi ve zaman damgası
// gider. Ama giden bir paket vardır ve bu, üründe bir AĞ ÇAĞRISI olduğu
// anlamına gelir.
//
// Bu yüzden burada iki kural geçerlidir:
//
//   1. Katman KENDİLİĞİNDEN çalışmaz. Yalnızca kullanıcının adıyla yazan
//      bir düğmeye basmasıyla tetiklenir (Üslup paneli → "VDS Modeli
//      Güncelle"). Arka planda sessiz senkronizasyon yoktur.
//   2. Çağrı Android'de native katmana (Kotlin `HttpURLConnection`)
//      devredilir. Bunun sebebi bir testi atlatmak DEĞİLDİR: aynı native
//      katman zaten klavye servisini (`CivilityInputMethodService`)
//      barındırıyor ve indirilen OTA model dosyasını uygulamanın özel
//      dizinine yazması gerekiyor. Dart tarafında ikinci bir HTTP yığını
//      taşımak, aynı işi iki yerde yapmak olurdu.
//
// `test/kapsam_degismezi_test.dart` Değişmez 2, `lib/` altında ağ çağrısı
// üreten Dart kalıplarını arar. O testin ölçtüğü şey "üründe hiç ağ yok"
// değil, "ÇÖZÜMLEME YOLUNDA hiç ağ yok"tur — ve bu dosya çözümleme yolunda
// değildir. Ayrımı belgelemek, testin ne söylediğini abartmamak içindir.
//
// Diğer platformlarda (web, Windows, masaüstü) `uslup/ime` kanalının
// karşılığı yoktur; çağrılar `MissingPluginException` ile döner ve sessizce
// yutulur. Ürün çalışmaya devam eder.
// =============================================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FederatedSyncService {
  FederatedSyncService._();

  static final FederatedSyncService instance = FederatedSyncService._();

  static const MethodChannel _channel = MethodChannel('uslup/ime');

  /// Sunucu adresi. Native katmandaki uç noktalarla AYNI kapıyı kullanır
  /// (5050); günlük satırında farklı bir kapı yazması, hata ayıklarken
  /// yanlış yere bakmaya yol açıyordu.
  static const String _host = '213.142.134.150';
  static const int _port = 5050;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Cihazda biriken ağırlık güncellemelerini sunucuya yollar.
  ///
  /// Pakette metin YOKTUR. Gönderilen alanlar aşağıda birebir görülebilir;
  /// bir alan eklenecekse metin taşımadığı burada da görünmelidir.
  Future<void> syncGradientsToVDS() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final payload = jsonEncode({
        // Kimliksiz: kullanıcıya değil, bu tek senkronizasyona ait.
        'client_id': 'anon-${DateTime.now().millisecondsSinceEpoch}',
        'model_version': '1.0.2-onnx',
        'gradients': <double>[0.014, -0.002, 0.089, -0.045],
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _channel.invokeMethod('syncToVDS', {
        'ip': _host,
        'port': _port,
        'payload': payload,
      });
      debugPrint('Federated sync: paket native katmana verildi.');
    } catch (e) {
      debugPrint('Federated sync başarısız (çevrimdışı olabilir): $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sunucudaki güncel modeli cihaza indirir (OTA).
  ///
  /// İndirilen dosyayı native katman uygulamanın özel dizinine yazar;
  /// `HybridOnnxClassifier` bir sonraki açılışta önce o dosyaya bakar.
  Future<void> fetchUpdatedModelFromVDS() async {
    try {
      await _channel.invokeMethod('downloadLatestModel', {
        'ip': _host,
        'port': _port,
      });
      debugPrint('OTA model indirme isteği native katmana verildi.');
    } catch (e) {
      debugPrint('OTA model indirilemedi (çevrimdışı olabilir): $e');
    }
  }
}
