// =============================================================================
// Üslup çalışma zamanı — tek motor örneği
// Dosya: mobile/lib/core/civility/civility_runtime.dart
//
// ── NEDEN TEK ÖRNEK ───────────────────────────────────────────────────────
// `LexicalTurkishClassifier` kurucusunda sözlüğü normalize eder ve arama
// yapılarını kurar (`_buildIndex`). Bu iş 92 sözlük girdisi ve 94 kimlik
// terimi için bir kez yapılır; her metin kutusunun kendi motorunu kurması
// aynı işi ekran sayısı kadar tekrarlamak olurdu.
//
// Motor DURUMSUZDUR: `analyze` çağrısı yalnızca girdisine bağlıdır ve hiçbir
// alan yazmaz. Bu yüzden paylaşmak güvenlidir; iki ekran aynı anda
// çözümleme yapsa bile birbirini etkileyemez.
//
// ── NEDEN InheritedWidget DEĞİL ───────────────────────────────────────────
// InheritedWidget, ağaçta AŞAĞIYA doğru değişebilen bir değer taşımak için
// vardır. Burada değişen bir şey yok — motor uygulama ömrü boyunca aynı.
// Ceremonisi, sağladığı hiçbir şeyi karşılamıyordu.
// =============================================================================

import 'package:civility_core/civility_core.dart';

abstract final class Civility {
  /// Uygulamadaki tek sınıflandırıcı.
  ///
  /// Aynı paket komut satırı değerlendirme aracında ve testlerde de çalışır;
  /// arayüzün farklı karar vermesi mümkün değildir.
  static final ToxicityClassifier engine = LexicalTurkishClassifier();

  /// Yerel yeniden yazıcı. Sunucuya çıkmaz, dil modeli çağırmaz.
  static final RewriteSuggester suggester = LocalRewriteSuggester(engine);

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

  static const String olcumKapsami =
      'Beş küme · 581 etiketli örnek · 246 test';
}
