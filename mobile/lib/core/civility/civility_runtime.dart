// =============================================================================
// Üslup çalışma zamanı — tek motor örneği
// Dosya: mobile/lib/core/civility/civility_runtime.dart
//
// ── NEDEN TEK ÖRNEK ───────────────────────────────────────────────────────
// `LexicalTurkishClassifier` kurucusunda sözlüğü normalize eder ve arama
// yapılarını kurar (`_buildIndex`). Bu iş bir kez yapılır; her metin
// kutusunun kendi motorunu kurması aynı işi ekran sayısı kadar tekrarlamak
// olurdu.
//
// Motor DURUMSUZDUR: `analyze` çağrısı yalnızca girdisine bağlıdır ve hiçbir
// alan yazmaz. Bu yüzden paylaşmak güvenlidir.
//
// ── NEDEN `late` DEĞİL, TEMBEL VARSAYILAN ─────────────────────────────────
// Alanlar önceden `late` idi ve yalnızca `main()` içindeki `Civility.init()`
// onları dolduruyordu. Sonuç: `init()` çağırmayan her giriş noktası
// çalışma zamanında `LateInitializationError` ile çöküyordu —
// `flutter test` içindeki sekiz arayüz testi bu yüzden kırmızıydı ve
// uygulama, `init()` tamamlanmadan bir kare çizilirse aynı hataya düşüyordu.
//
// Artık erişim tembel: motor istendiğinde yoksa deterministik çekirdek
// kendiliğinden kurulur. `init()` bunun ÜSTÜNE melez ONNX katmanını takar.
// Yani `init()` bir ön koşul değil, bir iyileştirmedir; çağrılmadığında
// ürün bozulmaz, yalnızca melez katmansız çalışır.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:civility_core/civility_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'onnx_classifier.dart';

abstract final class Civility {
  static ToxicityClassifier? _engine;
  static RewriteSuggester? _suggester;
  static bool _hybridReady = false;

  /// Uygulamadaki tek sınıflandırıcı.
  ///
  /// İlk erişimde deterministik çekirdek kurulur. `init()` daha sonra
  /// melez sürümle değiştirir; arada kalan çağrılar hata almaz.
  static ToxicityClassifier get engine =>
      _engine ??= LexicalTurkishClassifier();

  /// Yeniden yazıcı — cihaz üstü öneri her zaman vardır.
  static RewriteSuggester get suggester =>
      _suggester ??= LayeredRewriteSuggester(LocalRewriteSuggester(engine));

  /// Melez ONNX katmanı yüklendi mi? Şeffaflık panelinde gösterilir.
  static bool get hybridReady => _hybridReady;

  /// Melez katmanı kurar. Hata fırlatmaz — kurulamazsa ürün deterministik
  /// çekirdekle çalışmaya devam eder.
  static Future<void> init() async {
    final base = LexicalTurkishClassifier();
    _engine = base;
    _suggester = LayeredRewriteSuggester(LocalRewriteSuggester(base));

    try {
      final hybrid = HybridOnnxClassifier(base);
      await hybrid.init();
      _engine = hybrid;
      _hybridReady = hybrid.isLoaded;
      // Yeniden yazıcı TEMEL motoru kullanmaya devam eder: öneri üretimi
      // örüntü tablolarını okur, olasılık skoru değil.
      _suggester = LayeredRewriteSuggester(LocalRewriteSuggester(base));
    } catch (e) {
      debugPrint('Melez katman kurulamadı, deterministik çekirdek sürüyor: $e');
      _hybridReady = false;
    }
  }

  /// Testlerin kendi motorunu takabilmesi için.
  @visibleForTesting
  static void overrideForTest({
    ToxicityClassifier? engine,
    RewriteSuggester? suggester,
  }) {
    _engine = engine;
    _suggester = suggester;
    _hybridReady = false;
  }

  /// Şeffaflık panelinde gösterilen model adı.
  static String get modelName => engine.modelName;

  /// Rapor edilen genelleme başarımı — arayüzde tek kaynaktan okunur.
  ///
  /// Bu sayılar `docs/14_MENTORLUK_PENCERESI_SONUCLARI.md` §5'teki ölçüm
  /// tablosundan gelir ve İP-22'nin İLK GEÇİŞİDİR. Kesinlik için düzeltme
  /// sonrası bir sayı (%100) mevcuttur ama o küme artık yanmıştır; arayüzde
  /// dürüst olanı, ilk geçişi göstermektir.
  static const String olcumOzeti =
      'İP-22 ayrık küme · 65 örnek · kesinlik %90,5 · F1 %67,9';

  /// 9 Eylül 2026'da ölçüldü: `dart test` → 258 geçti.
  static const String olcumKapsami =
      'Beş küme · 581 etiketli örnek · 258 test';
}

// ─── Yeniden yazıcı katmanı ──────────────────────────────────────────────────

/// Cihaz üstü öneriyi TABAN alan, sunucu önerisini yalnızca İYİLEŞTİRME
/// olarak kabul eden yeniden yazıcı.
///
/// ── NEDEN SIRA BÖYLE ──────────────────────────────────────────────────────
/// Önceki sürüm önce VDS'e gidiyor, cevap gelmezse sabit bir cümleye
/// düşüyordu: *"Bu cümlenin üslubunu yumuşatmak daha sağlıklı bir iletişim
/// kurmanı sağlayabilir."* Bunun iki sonucu vardı:
///
///   1. Jüri demosu UÇAK MODUNDA yapılıyor (`docs/17` §0). Yani demoda
///      gösterilen her öneri, cümleye özel yeniden yazım değil, o tek
///      genel cümle olacaktı — sunumun en güçlü anı boşa çıkıyordu.
///   2. `suggest()` her tuş vuruşunda çağrılır. Ağ önce denendiğinde bu,
///      tuş başına bir ağ turu demekti.
///
/// Şimdi: yerel öneri her zaman üretilir ve hemen döner. Sunucu önerisi
/// isteğe bağlıdır, kısa bir zaman aşımıyla denenir ve yalnızca gerçekten
/// daha iyi bir metin döndürürse tercih edilir. Ağ yokken davranış
/// bozulmaz — yalnızca iyileştirme gelmez.
class LayeredRewriteSuggester implements RewriteSuggester {
  LayeredRewriteSuggester(this._local, {RewriteSuggester? remote})
      : _remote = remote;

  final RewriteSuggester _local;
  final RewriteSuggester? _remote;

  @override
  Future<RewriteSuggestion?> suggest(CivilityAnalysis analysis) async {
    final local = await _local.suggest(analysis);
    final remote = _remote;
    if (remote == null) return local;

    try {
      final enhanced = await remote
          .suggest(analysis)
          .timeout(const Duration(milliseconds: 900));
      if (enhanced != null && enhanced.text.trim().isNotEmpty) return enhanced;
    } catch (_) {
      // Ağ yok, yavaş ya da kapalı: yerel öneri zaten hazır.
    }
    return local;
  }
}

/// Sunucudaki yeniden yazma servisine giden isteğe bağlı katman.
///
/// ── AÇIKÇA: BU KATMAN METNİ CİHAZDAN ÇIKARIR ──────────────────────────────
/// Varsayılan olarak KURULU DEĞİLDİR (`Civility.init` onu bağlamaz) ve
/// bağlanmadığı sürece üründe tek bir ağ çağrısı yoktur. Bağlanacaksa,
/// kullanıcıya bunun ne anlama geldiği söylenmeden bağlanmamalıdır:
/// "metin cihazdan çıkmaz" cümlesi, bu katman açıkken doğru değildir.
class VdsRewriteSuggester implements RewriteSuggester {
  const VdsRewriteSuggester({required this.host});

  static const MethodChannel _channel = MethodChannel('uslup/ime');

  final String host;

  @override
  Future<RewriteSuggestion?> suggest(CivilityAnalysis analysis) async {
    final response = await _channel.invokeMethod<String>('llmRewrite', {
      'ip': host,
      'text': analysis.text,
    });
    if (response == null) return null;

    final data = jsonDecode(response) as Map<String, dynamic>;
    if (data['status'] != 'success') return null;

    final text = data['suggestion'] as String?;
    if (text == null || text.trim().isEmpty) return null;

    final model = data['model'] as String? ?? 'VDS';
    return RewriteSuggestion(
      text: text,
      source: 'Sunucu · $model',
      projectedCivilityScore: 100,
    );
  }
}
