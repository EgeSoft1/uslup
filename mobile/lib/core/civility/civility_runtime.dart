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

  /// Deterministik çekirdek — melez katman da bunu sarar. Tek örnektir.
  static LexicalTurkishClassifier? _base;

  static LexicalTurkishClassifier get _cekirdek =>
      _base ??= LexicalTurkishClassifier();

  /// Uygulamadaki tek sınıflandırıcı.
  ///
  /// İlk erişimde deterministik çekirdek kurulur. `init()` daha sonra
  /// melez sürümle değiştirir; arada kalan çağrılar hata almaz.
  static ToxicityClassifier get engine => _engine ??= _cekirdek;

  static bool _isitildi = false;

  /// İlk çözümlemenin maliyetini öne alır (docs/24 · madde 38).
  ///
  /// Ölçüm (AOT): ısıtılmamış motorda ilk çözümleme 55,9 ms — kullanıcının
  /// İLK tuş vuruşunda üç kare kaybı ve risk şeridinde "55931 µs". Isıtmadan
  /// sonra ilk çözümleme ~100 µs. `main()` bunu ilk kare çizildikten sonra
  /// çağırır: açılış gecikmez, maliyet kullanıcı akışı okurken ödenir.
  static Future<void> warmUp() async {
    if (_isitildi) return;
    _isitildi = true;
    _cekirdek.warmUp();
    // Yeniden yazıcının düzenli ifadeleri de ilk kullanımda derlenir.
    await suggester.suggestTones(_cekirdek.analyze('sen tam bir aptalsın'));
  }

  /// Yeniden yazıcı — cihaz üstü, ağ yok.
  static RewriteSuggester get suggester =>
      _suggester ??= LocalRewriteSuggester(engine);

  /// ONNX ikinci görüş katmanı yüklendi mi? Şeffaflık panelinde gösterilir.
  static bool get hybridReady => _hybridReady;

  /// Melez katmanı kurar. Hata fırlatmaz — kurulamazsa ürün deterministik
  /// çekirdekle çalışmaya devam eder.
  static Future<void> init() async {
    final base = _cekirdek;
    _engine = base;
    // Yeniden yazıcı TEMEL motoru kullanır: öneri üretimi örüntü
    // tablolarını okur, olasılık skoru değil.
    _suggester = LocalRewriteSuggester(base);

    try {
      final hybrid = HybridOnnxClassifier(base);
      await hybrid.init();
      _engine = hybrid;
      _hybrid = hybrid;
      _hybridReady = hybrid.isLoaded;
    } catch (e) {
      debugPrint('Melez katman kurulamadı, deterministik çekirdek sürüyor: $e');
      _hybridReady = false;
    }
  }

  static HybridOnnxClassifier? _hybrid;

  /// ONNX modelinin ikinci görüşü [0,1] — yalnızca BİLGİ amaçlı.
  ///
  /// Karar ve basamak her zaman kural motorunundur (docs/24 · madde 22):
  /// paketlenen model ölçüldüğünde gündelik masum cümlelerin %72'sini
  /// saldırgan buldu. Model yoksa (web, yükleme hatası) `null`.
  static Future<double?> secondOpinion(String text) async {
    final hybrid = _hybrid;
    if (!_hybridReady || hybrid == null) return null;
    return hybrid.secondOpinion(text);
  }

  /// Testlerin kendi motorunu takabilmesi için.
  @visibleForTesting
  static void overrideForTest({
    ToxicityClassifier? engine,
    RewriteSuggester? suggester,
  }) {
    _engine = engine;
    _suggester = suggester;
    _hybrid = null;
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
  /// Kaynak: `packages/civility_core/bin/benchmark.dart`, 15 Eylül 2026,
  /// 11 senaryo × 2000 tekrar. "Mesaj" 200 karakterin altındaki 9
  /// senaryodur (önceki raporların kapsamı); "uzun gönderi" ~600 ve ~2.400
  /// karakterdir.
  ///
  /// Geçmiş: 219 → 159 → 357 µs. Uzun gönderi ilk kez 13 Eylül'de ölçüldü
  /// ve 600 karakterde kare bütçesinin AŞILDIĞI görüldü (p99 16,5 ms).
  /// İki hızlandırma geçişi yapıldı, ikisi de çıktıyı değiştirmeden:
  ///   • sözlük dizini + örüntü ön filtresi (docs/19)
  ///   • karakter başına String ayırmanın kaldırılması (docs/28)
  /// İkinci geçişte AYNI makinede, aynı araçla: mesaj p50 169 → 84 µs,
  /// 2.400 kr p99 8,8 → 2,7 ms.
  ///
  /// Mutlak sayı makinenin anlık durumuna göre kat kat oynar; bu yüzden her
  /// karşılaştırma aynı turda yapılır ve karşılaştırılabilir olan orandır.
  static const String gecikmeP50 = '84 µs';
  static const String gecikmeP99 = '1.219 µs';

  /// En pahalı senaryo: ~2.400 karakterlik gönderi.
  static const String gecikmeUzunP99 = '2,7 ms';
  static const String kareButcesiUzunP99 = '%17';

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
      DirectionDataset.cases.length +
      StanceDataset.cases.length +
      IdentityAxesDataset.cases.length +
      IdentityAxesBlindDataset.cases.length +
      IdentityAxesBlind2Dataset.cases.length;

  /// Geçerli genelleme ölçümü — bugünkü motorun hiç görmediği küme.
  ///
  /// Kaynak: docs/18. Küme ölçümden önce commit edildi (`9179ee4`). İlk
  /// geçiş %96,4 / %45,0 idi. Gösterilen sayı, küme DIŞINDA bulunan
  /// onarımlardan sonraki altıncı geçiştir: D7 (docs/21) iki saldırı örneğini
  /// kaçırdı; D9 (docs/23, kod denetimi) kesme işaretinin tırnak sayılmasını
  /// düzeltti ve kümenin tek yanlış pozitifi kendiliğinden temizlendi;
  /// docs/25 ve docs/26 birer örnek daha kazandırdı. Altıncı geçişteki
  /// +1 örnek (`karşıma çıkma, iyi olmaz`) KÖR DEĞİLDİR — onu yakalayan
  /// örüntünün açıklaması kümenin cümlesini alıntılar (docs/30).
  static const String olcumOzeti =
      'Geçerli ayrık küme (İP-29) · kesinlik %100,0 · duyarlılık %46,7';

  /// Kapsam satırı — sayılar çalışma anında hesaplanır.
  static String get olcumKapsami =>
      '13 küme · $etiketliOrnek etiketli örnek · $sozlukGirdisi sözlük girdisi';
}
