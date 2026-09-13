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
// çalışma zamanında `LateInitializationError` ile çöküyordu.
//
// Artık erişim tembel: motor istendiğinde yoksa deterministik çekirdek
// kendiliğinden kurulur. `init()` bunun ÜSTÜNE ONNX ikinci görüş katmanını
// takar. Yani `init()` bir ön koşul değil, bir iyileştirmedir.
//
// ── KALDIRILANLAR (13 Eylül 2026) ─────────────────────────────────────────
// Bu dosyada sunucuya metin gönderen isteğe bağlı bir yeniden yazıcı
// (`VdsRewriteSuggester`) ve onu sarmalayan katman duruyordu. Hiçbir yerden
// bağlanmıyordu, ama "metin cihazdan çıkmaz" iddiasının yanında, çağrılmayı
// bekleyen bir metin ihracı yolu olarak duruyordu. Kaldırıldı; öneri üretimi
// yalnızca cihaz üstü `LocalRewriteSuggester` ile yapılır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/foundation.dart';

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

  /// Yeniden yazıcı — cihaz üstü, ağ yok.
  static RewriteSuggester get suggester =>
      _suggester ??= LocalRewriteSuggester(engine);

  /// ONNX ikinci görüş katmanı yüklendi mi? Şeffaflık panelinde gösterilir.
  static bool get hybridReady => _hybridReady;

  /// Melez katmanı kurar. Hata fırlatmaz — kurulamazsa ürün deterministik
  /// çekirdekle çalışmaya devam eder.
  static Future<void> init() async {
    final base = LexicalTurkishClassifier();
    _engine = base;
    // Yeniden yazıcı TEMEL motoru kullanır: öneri üretimi örüntü
    // tablolarını okur, olasılık skoru değil.
    _suggester = LocalRewriteSuggester(base);

    try {
      final hybrid = HybridOnnxClassifier(base);
      await hybrid.init();
      _engine = hybrid;
      _hybridReady = hybrid.isLoaded;
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

  // ─── Arayüzde gösterilen ölçümler — TEK KAYNAK ────────────────────────────
  //
  // Ekranda görünen her sayı buradan okunur. Bir sayı iki yerde elle
  // yazılırsa biri er ya da geç bayatlar; bu dosyadaki önceki sürümde
  // "92 sözlük girdisi" yazıyordu, motorda 250'den fazla girdi vardı.
  //
  // Sayılabilen her şey ÇALIŞMA ANINDA sayılır. Yalnızca motorun dışında
  // ölçülen şeyler (ayrık küme ilk geçişi, AOT gecikmesi) sabit olarak
  // yazılır ve kaynağı yanında belirtilir.

  /// Sözlükteki girdi sayısı — çalışma anında sayılır.
  static int get sozlukGirdisi => ToxicityLexicon.entries.length;

  /// Edimbilimsel, deyim ve nefret örüntülerinin toplamı — çalışma anında.
  static int get oruntuSayisi => ImplicitPatterns.all.length;

  /// AOT derlenmiş motorun ölçülen gecikmesi.
  ///
  /// Kaynak: `packages/civility_core/bin/benchmark.dart`, 13 Eylül 2026,
  /// 11 senaryo × 2000 tekrar, üç turun ortancası. "Mesaj" 200 karakterin
  /// altındaki 9 senaryodur (önceki raporların kapsamı); "uzun gönderi"
  /// ~600 ve ~2.400 karakterdir.
  ///
  /// Geçmiş: 219 → 159 → 357 µs. Uzun gönderi ilk kez 13 Eylül'de ölçüldü
  /// ve 600 karakterde kare bütçesinin AŞILDIĞI görüldü (p99 16,5 ms).
  /// Sözlük dizini ve örüntü ön filtresinden sonra AYNI makinede, aynı
  /// araçla: mesaj p50 1.104 → 206 µs, 2.400 kr p99 75,9 → 10,2 ms.
  /// (O oturumda makine sabahkinden yavaştı; eski motor mesajda 357 değil
  /// 1.104 µs verdi. Karşılaştırma bu yüzden aynı turda yapıldı.)
  static const String gecikmeP50 = '206 µs';
  static const String gecikmeP99 = '2.519 µs';

  /// En pahalı senaryo: ~2.400 karakterlik gönderi.
  static const String gecikmeUzunP99 = '10,2 ms';
  static const String kareButcesiUzunP99 = '%64';

  /// Etiketli değerlendirme örneklerinin toplamı — çalışma anında sayılır.
  static int get etiketliOrnek =>
      GoldDataset.cases.length +
      HoldoutDataset.cases.length +
      GeneralizationDataset.cases.length +
      Generalization2Dataset.cases.length +
      Generalization3Dataset.cases.length +
      Generalization4Dataset.cases.length +
      Generalization5Dataset.cases.length +
      EverydayDataset.cases.length +
      DirectionDataset.cases.length;

  /// Geçerli genelleme ölçümü — bugünkü motorun hiç görmediği küme.
  ///
  /// Kaynak: docs/18. Küme ölçümden önce commit edildi (`9179ee4`). İlk
  /// geçiş %96,4 / %45,0 idi; gösterilen sayı, küme DIŞINDA bulunan bir
  /// yanlış alarm onarımından (docs/21, D7) sonraki ikinci geçiştir — küme
  /// yanmadı, iki saldırı örneği kaçtı (docs/18 §7).
  static const String olcumOzeti =
      'Geçerli ayrık küme (İP-29) · kesinlik %96,2 · duyarlılık %41,7';

  /// Kapsam satırı — sayılar çalışma anında hesaplanır.
  static String get olcumKapsami =>
      '9 küme · $etiketliOrnek etiketli örnek · $sozlukGirdisi sözlük girdisi';
}
