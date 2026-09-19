// =============================================================================
// NSosyal Sosyal YZ — Nezaket Motoru (Civility Engine)
// Dosya: packages/civility_core/lib/src/civility_engine.dart
//
// Cihaz üzerinde çalışan Türkçe saldırgan dil tespit ve müdahale motoru.
// Metin CİHAZDAN ÇIKMAZ — mahremiyet tasarımın kendisinden gelir
// (privacy by design), sonradan eklenen bir politika değildir.
//
// ── İŞLEM HATTI ───────────────────────────────────────────────────────────
//   ham metin
//      → 1. Normalizasyon      (gizleme hilelerini geri çevir)
//      → 2. Tokenizasyon       (konum koruyarak böl)
//      → 3. Kaçınma birleştirme ("a m k" → "amk")
//      → 4. Sözlük eşleştirme  (kök + tam + öbek)
//      → 5. Bağlam çözümleme   (yönelim / olumsuzlama / alıntı / öz-ifade)
//      → 6. Skor birleştirme   (noisy-OR)
//      → 7. Yeniden yazma önerisi
//
// ── MİMARİ NOT: MODEL DEĞİŞTİRİLEBİLİRLİĞİ ────────────────────────────────
// `ToxicityClassifier` soyut arayüzü kasıtlıdır. Bugün deterministik
// dilbilimsel sınıflandırıcı (`LexicalTurkishClassifier`) çalışıyor;
// yarın ince ayarlı BERTurk modeli ONNX Runtime üzerinde
// `OnnxTurkishClassifier` olarak AYNI arayüzü uygular. UI katmanı ve
// bağlam katmanı hiç değişmez.
//
// Bu yalnızca bir mimari zarafet değil, ürün gerekliliğidir: sinir ağı
// modelinin veri kümesi hazır olmadan da çalışan bir ürün gerekiyor ve
// deterministik katman üretimde de yüksek-kesinlikli ön filtre olarak kalır.
//
// ── PERFORMANS HEDEFİ ─────────────────────────────────────────────────────
// Her tuş vuruşunda çalıştığı için tek çözümleme < 16 ms olmalıdır
// (60 FPS bütçesi). Ölçüm `CivilityAnalysis.elapsed` alanında raporlanır.
// =============================================================================

import 'lexicon/toxicity_lexicon.dart';
import 'normalization/tokenizer.dart';
import 'normalization/turkish_morphology.dart';
import 'normalization/turkish_normalizer.dart';
import 'context/context_analyzer.dart';
import 'detect/implicit_detector.dart';
import 'detect/implicit_patterns.dart';
import 'detect/literal_prefilter.dart';

// ─── SONUÇ MODELLERİ ─────────────────────────────────────────────────────────

/// Metnin genel risk seviyesi. UI müdahale şiddetini buna göre seçer.
enum RiskLevel {
  /// Sorun yok. Hiçbir müdahale yapılmaz.
  temiz,

  /// Sınırda. Sessiz görsel ipucu (kenarlık rengi) yeterli.
  dikkat,

  /// Saldırgan. Yeniden yazma önerisi sunulur.
  riskli,

  /// Ağır saldırı/tehdit. Gönderim öncesi açık onay istenir.
  yuksek,
}

extension RiskLevelInfo on RiskLevel {
  String get label => switch (this) {
        RiskLevel.temiz => 'Temiz',
        RiskLevel.dikkat => 'Dikkat',
        RiskLevel.riskli => 'Riskli',
        RiskLevel.yuksek => 'Yüksek risk',
      };

  /// Ürünün bu seviyede uyguladığı müdahale.
  String get intervention => switch (this) {
        RiskLevel.temiz => 'Müdahale yok',
        RiskLevel.dikkat => 'Sessiz görsel ipucu',
        RiskLevel.riskli => 'Yeniden yazma önerisi',
        RiskLevel.yuksek => 'Gönderim öncesi onay',
      };
}

/// Bulgunun hangi katmandan geldiği.
///
/// Şeffaflık paneli bunu gösterir: kullanıcı "hangi kural beni uyardı"
/// sorusunun cevabını görebilmelidir.
enum FindingSource {
  /// Sözlük eşleşmesi — yasaklı kelime veya öbek.
  sozluk,

  /// Edimbilimsel örüntü — yasaklı kelime yok, kalıp saldırgan.
  oruntu,
}

/// Tespit edilen tek bir saldırgan ifade.
class ToxicityFinding {
  /// Orijinal metindeki eşleşen parça (kullanıcıya gösterilir).
  final String matchedText;

  /// Eşleşmeyi tetikleyen sözlük terimi.
  final String term;

  final ToxicityCategory category;

  /// Sözlükteki bağlamsız taban şiddet.
  final double baseSeverity;

  /// Bağlam katmanından geçtikten sonraki nihai şiddet.
  final double adjustedSeverity;

  /// Bağlam kararının ayrıntısı — şeffaflık paneli bunu gösterir.
  final MatchContext context;

  /// Orijinal metindeki başlangıç indeksi (dâhil).
  final int start;

  /// Orijinal metindeki bitiş indeksi (hariç).
  final int end;

  /// Bulguyu üreten katman.
  final FindingSource source;

  /// Yeniden yazımda bu ifadenin yerine geçecek nötr karşılık.
  /// Bulgu kendi karşılığını taşır; yeniden yazıcı sözlüğe bakmak zorunda
  /// değildir ve örüntü kaynaklı bulgular da düzgün yeniden yazılabilir.
  final String? neutralAlternative;

  /// Örüntü kaynaklı bulgularda edimbilimsel aile; sözlük bulgularında null.
  final ImplicitFamily? implicitFamily;

  const ToxicityFinding({
    required this.matchedText,
    required this.term,
    required this.category,
    required this.baseSeverity,
    required this.adjustedSeverity,
    required this.context,
    required this.start,
    required this.end,
    this.source = FindingSource.sozluk,
    this.neutralAlternative,
    this.implicitFamily,
  });

  /// Kullanıcıya gösterilecek gerekçe. "Neden uyarıldım?" sorusunun cevabı.
  ///
  /// Örüntü bulgularında kategori açıklaması yetersiz kalır: kullanıcı
  /// "hangi kelime?" diye arar ve bulamaz. Bu yüzden örüntü bulguları
  /// KALIBI açıklar, kelimeyi değil.
  String get explanation {
    final base = implicitFamily?.explanation ?? category.explanation;
    final contextReason = context.reason;
    if (contextReason != null) {
      return '$base ($contextReason)';
    }
    return base;
  }

  /// Şeffaflık panelinde gösterilen kısa etiket.
  String get sourceLabel => switch (source) {
        FindingSource.sozluk => 'Sözlük',
        FindingSource.oruntu => implicitFamily?.label ?? 'Örüntü',
      };
}

/// Bir metnin tam çözümleme sonucu.
class CivilityAnalysis {
  /// Çözümlenen orijinal metin.
  final String text;

  /// Birleştirilmiş toksisite [0.0 – 1.0].
  final double toxicity;

  /// Kullanıcıya gösterilen nezaket puanı [0 – 100]. `100 - toksisite×100`.
  /// Pozitif çerçeveleme kasıtlı: ceza değil, geri bildirim.
  final int civilityScore;

  final RiskLevel risk;

  /// Bulunan tüm ihlaller, şiddete göre azalan sırada.
  final List<ToxicityFinding> findings;

  /// Metnin geneli için hesaplanan bağlam sinyalleri.
  final ContextSignals signals;

  /// Çözümlemenin sürdüğü süre — performans iddiasının kanıtı.
  final Duration elapsed;

  /// Metin kendine zarar ifadesi içeriyor mu?
  ///
  /// Bu bir toksisite bulgusu DEĞİLDİR: skoru, risk basamağını, öneriyi ve
  /// onay akışını etkilemez. Arayüz bu işaretle uyarı yerine bir destek
  /// kartı gösterir. Gerekçe: `ImplicitPatterns` içindeki kendine zarar
  /// bloğu ve docs/20 (D4).
  final bool needsSupport;

  const CivilityAnalysis({
    required this.text,
    required this.toxicity,
    required this.civilityScore,
    required this.risk,
    required this.findings,
    required this.signals,
    required this.elapsed,
    this.needsSupport = false,
  });

  /// Boş/temiz metin için sonuç.
  factory CivilityAnalysis.clean(String text, ContextSignals signals) {
    return CivilityAnalysis(
      text: text,
      toxicity: 0.0,
      civilityScore: 100,
      risk: RiskLevel.temiz,
      findings: const [],
      signals: signals,
      elapsed: Duration.zero,
    );
  }

  bool get hasFindings => findings.isNotEmpty;

  /// Müdahale gerektiren en baskın kategori.
  ToxicityCategory? get dominantCategory =>
      findings.isEmpty ? null : findings.first.category;

  /// Tehdit içeriyor mu? Tehdit ayrı bir akış tetikler (yasal yükümlülük).
  bool get containsThreat =>
      findings.any((f) => f.category == ToxicityCategory.tehdit);
}

// ─── SINIFLANDIRICI ARAYÜZÜ ──────────────────────────────────────────────────

/// Toksisite sınıflandırıcı sözleşmesi.
///
/// Uygulamalar:
///   • `LexicalTurkishClassifier` — deterministik, sıfır bağımlılık (aktif)
///   • `OnnxTurkishClassifier`    — ince ayarlı BERTurk, ONNX Runtime (planlı)
abstract class ToxicityClassifier {
  /// Metni çözümler ve nezaket raporu döndürür.
  CivilityAnalysis analyze(String text);

  /// Sınıflandırıcının insan-okunur adı — şeffaflık panelinde gösterilir.
  String get modelName;
}

// ─── DETERMİNİSTİK DİLBİLİMSEL SINIFLANDIRICI ────────────────────────────────

class LexicalTurkishClassifier implements ToxicityClassifier {
  final TurkishNormalizer _normalizer;
  final Tokenizer _tokenizer;
  final ContextAnalyzer _contextAnalyzer;

  /// Tam eşleşme aranan terimler: normalize terim → girdi.
  final Map<String, LexiconEntry> _exactEntries = {};

  /// Kök eşleşmesi aranan terimler. Uzundan kısaya sıralı —
  /// "gerizekali" girdisi "geri" girdisinden önce denenmeli.
  final List<({String normalized, LexiconEntry entry})> _prefixEntries = [];

  /// Çok kelimeli öbekler ("kapa çeneni"). Doğrudan metin içinde aranır.
  final List<({String normalized, LexiconEntry entry})> _phraseEntries = [];

  /// Öbek katmanının ön filtresi: tek taramada hangi öbeklerin metinde
  /// GEÇEBİLECEĞİNİ söyler (docs/28).
  ///
  /// Öbeklerin tamamı için `indexOf` çağırmak, uzun metinde motorun en pahalı
  /// ikinci adımıydı — 2.760 karakterde 983 µs. Sıradan bir gönderide bu
  /// öbeklerin hemen hiçbiri geçmez; kapı, geçmeyeni hiç aratmaz.
  ///
  /// `_buildIndex` sonunda kurulur; sıralama orada bittiği için sıra
  /// numaraları `_phraseEntries` ile aynıdır.
  late final LiteralIndex _phraseGate;

  /// Birleştirme yolunda BİREBİR aranan tabloların (`_surfaceForms`,
  /// `_despacedPhrases`) en uzun anahtarı ve anahtarların ilk kod birimleri.
  ///
  /// İki komşu kelimeyi birleştirip tabloda aramak, birleşimi kurmayı
  /// gerektirir; oysa birleşim bu iki kapıdan geçemiyorsa tabloda olamaz.
  /// Sıradan bir cümlede komşu kelimelerin neredeyse hiçbiri geçmez ve
  /// birleşim hiç kurulmaz (docs/28).
  int _joinMaxLength = 0;
  final Set<int> _joinFirstCodes = {};

  /// Boşlukları silinmiş öbekler: "amina koyim" → "aminakoyim".
  ///
  /// Öbek katmanı boşluğu sabit bir ayraç sayar; kullanıcı bitişik yazınca
  /// öbek kaçar. Bu tablo, birleşik yazımı TEK bir token olarak aramayı
  /// mümkün kılar. Bkz. `_matchEvasionJoins`.
  final Map<String, LexiconEntry> _despacedPhrases = {};

  /// Tek kelimelik BÜTÜN girdilerin yüzey biçimleri — eşleşme kipinden
  /// bağımsız olarak.
  ///
  /// `_exactEntries` yalnızca `MatchMode.exact` girdilerini tutar; kök
  /// eşleşmeli girdiler ("orospu") orada YOKTUR. Bölme kaçışını yakalayan
  /// birleştirme geçişi ise kök eşleşmesi yapamaz (gerekçe:
  /// `_matchEvasionJoins`) ve bu yüzden kendi BİREBİR tablosuna ihtiyaç
  /// duyar. "oros" + "pu" → "orospu" burada bulunur; "o" + "çocuk" →
  /// "oçocuk" bulunmaz.
  final Map<String, LexiconEntry> _surfaceForms = {};

  /// Terimi yazılışında taşıdığı katlanan harflere bağlar: "aq" → {q}.
  ///
  /// ── KATLAMA KANITI SİLER ─────────────────────────────────────────────────
  /// Normalizasyon q→k, w→v, x→ks dönüşümü yapar; "salaq" böylece "salak"
  /// girdisine iner. Dönüşüm girdinin KENDİSİNE de uygulanır ve "aq"
  /// kısaltması Türkçe "ak" kelimesine katlanır. Ölçülen sonuç:
  ///
  ///   "ak saçlı dede" · "AK Parti" · "akla gelen" · "dayanışma ağı" → 0.90 ✗
  ///
  /// "aq" bir kelimenin gizlenmiş yazımı DEĞİLDİR; q harfinin kendisi
  /// kısaltmanın kimliğidir. Bu yüzden böyle bir girdi, orijinal metinde o
  /// harf fiilen yazıldıysa eşleşir. "salaq" gibi kaçışlar etkilenmez:
  /// onları yakalayan "salak" girdisi q taşımaz.
  final Map<String, Set<String>> _surfaceLetterEvidence = {};

  /// Normalizasyonun katladığı yabancı harfler.
  /// `TurkishNormalizer._foreignLetters` ile aynı küme olmalıdır.
  static const String _foldedLetters = 'qwx';

  /// Normalize edilmiş maskeleme ön ekleri (yanlış pozitif engelleyici).
  final List<String> _maskedPrefixes = [];

  // ── İLK HARF KOVALARI (gecikme optimizasyonu) ─────────────────────────────
  // `_lookup` her token için bütün kök girdilerini ve bütün tam girdileri
  // sırayla dener. Ölçülen maliyet: 4.800 karakterlik bir metinde 69 ms'nin
  // ~58 ms'i buradaydı (token başına ~73 µs) — 600 karakterlik sıradan bir
  // gönderi bile her tuş vuruşunda kare bütçesine dayanıyordu.
  //
  // Bir token bir köke ancak o kökle YA DA kökün yumuşamış hâliyle
  // başlıyorsa bağlanabilir (`TurkishMorphology.isValidInflectedForm`) ve
  // yumuşama yalnızca SON harfi değiştirir. Yani ilk harfi tutmayan aday
  // hiçbir koşulda eşleşemez. Adaylar ilk harfe göre kovalanır; kova içi
  // sıra korunur, bu yüzden "ilk eşleşen aday" değişmez.
  //
  // Kovalar bir hızlandırmadır; sonucu değiştirmeleri bir hatadır.
  // `test/lookup_index_test.dart` kovalı ve kovasız motorun aynı çıktıyı
  // ürettiğini etiketli kümelerin tamamında ve üretilmiş varyantlarda kanıtlar.

  /// Kök girdileri, ilk harfe göre — `_prefixEntries` ile aynı sırada.
  final Map<int, List<_StemCandidate>> _prefixByFirst = {};

  /// Çekime girebilen tam girdiler (verbatim hariç), ilk harfe göre —
  /// `_exactEntries` sırasıyla.
  final Map<int, List<_StemCandidate>> _inflectableExactByFirst = {};

  /// Maskeleme ön ekleri, ilk harfe göre.
  final Map<int, List<String>> _maskedByFirst = {};

  /// Çekime girmeyen, yalnızca birebir eşleşen yüzeyler — birebir kipteki
  /// kısaltmalar ("amk") ve boşluksuz öbekler ("orospucocugu") — ilk harfe
  /// göre. Birleşik yazım bölmesinin ucuz ön elemesi içindir (`_mayStartEntry`).
  final Map<int, List<String>> _literalsByFirst = {};

  /// Normalize uzunluğu ≤ 3 olan tek kelimelik girdiler (D1, D2).
  final Set<LexiconEntry> _shortRoots = {};

  /// Yüzey kanıtıyla denetlenen girdilerin Türkçe yazılışı: kısa kökler (D1)
  /// ve `ToxicityLexicon.spellingSensitiveTerms` (docs/25). Yalnızca
  /// normalizasyonun harf harf (1:1) katladığı yazılışlar; yüzey kanıtı
  /// konum konum karşılaştırır.
  final Map<LexiconEntry, String> _shortRootSpelling = {};

  /// Her girdinin normalize terimi.
  final Map<LexiconEntry, String> _normalizedTerms = {};

  /// Bitişik yazımda ÖN EK olarak aranan öbekler (boşluksuz uzunluk ≥ 7):
  /// "aminakoy" → "amınakoydum", "amınakoyarım" (docs/25).
  ///
  /// `_despacedPhrases` token'ın öbeğe BİREBİR eşit olmasını ister; öbek
  /// yolu ise sağ sınır denetlemediği için ayrı yazılmış çekimleri zaten
  /// görür. İki yol arasındaki asimetri bitişik çekimli yazımı kaçırıyordu.
  /// Kısa öbekler bu tabloya alınmaz: ön ek olarak meşru kelimelerin başında
  /// geçme olasılıkları uzunlukla hızla düşer.
  final List<({String despaced, LexiconEntry entry})> _despacedPrefixes = [];

  /// Yazılışında ikili taşıyan tek kelimelik girdilerin ikilisi indirilmiş
  /// hâlleri: "namussuz" → "namusuz". Gerekçe: `_squeezedEntryFor`.
  final List<({String squeezed, List<String> pairs, LexiconEntry entry})>
      _squeezedEntries = [];

  /// `_despacedPrefixes`, ilk harfe göre — uzundan kısaya sırası korunur.
  final Map<int, List<({String despaced, LexiconEntry entry})>>
      _despacedPrefixByFirst = {};

  /// Nesne + fiil küfürleri: normalize nesne → kabul edilen normalize fiiller.
  final Map<String, Set<String>> _profanePairs = {};

  /// Nesne → fiil KÖKLERİ ("am" → koy, kod, sok). Gerekçe:
  /// `ToxicityLexicon.profanePairs` içindeki `stems` alanı.
  final Map<String, Set<String>> _profanePairStems = {};

  /// Normalize biçim → okunur Türkçe yazılış (nesne + fiil bulgularının terimi).
  final Map<String, String> _pairSpelling = {};

  /// `_profanePairs` nesneleri, ilk harfe göre (bitişik yazım araması).
  final Map<int, List<String>> _pairObjectsByFirst = {};

  final Set<String> _ellipticalObjects = {};
  final Set<String> _ellipticalFillers = {};

  /// Birleşik yazım yapıştırıcıları: soldaki parça için ilk harfe (≥ 3 harf),
  /// sağdaki parça için son harfe göre kovalanmış.
  final Map<int, List<String>> _leftGlueByFirst = {};
  final Map<int, List<String>> _rightGlueByLast = {};

  /// İlk harf kovaları açık mı?
  ///
  /// Üründe her zaman açıktır. Kapalı hâli YALNIZCA doğrulama içindir
  /// (bkz. `ImplicitDetector.fastGate` — aynı yaklaşım).
  final bool fastLookup;

  /// Örtük saldırı katmanı açık mı?
  ///
  /// Kapatılabilir olması bir hata ayıklama kolaylığı değil, ÖLÇÜM
  /// gerekliliğidir: katmanın katkısı ancak aynı veri kümesinde açık ve
  /// kapalı ölçüm alınarak raporlanabilir (`bin/evaluate.dart --karsilastir`).
  final bool enableImplicitPatterns;

  final ImplicitDetector _implicitDetector;

  LexicalTurkishClassifier({
    TurkishNormalizer normalizer = const TurkishNormalizer(),
    Tokenizer tokenizer = const Tokenizer(),
    ContextAnalyzer contextAnalyzer = const ContextAnalyzer(),
    ImplicitDetector? implicitDetector,
    this.enableImplicitPatterns = true,
    this.fastLookup = true,
  })  : _normalizer = normalizer,
        _tokenizer = tokenizer,
        _contextAnalyzer = contextAnalyzer,
        _implicitDetector = implicitDetector ?? ImplicitDetector() {
    _buildIndex();
  }

  /// İlk çözümlemenin maliyetini öne alır (docs/24 · madde 38).
  ///
  /// Düzenli ifadeleri derler ve motoru her katmana dokunan birkaç cümleyle
  /// çalıştırır. Üründe uygulama ilk kareyi çizdikten SONRA çağrılır; böylece
  /// ne açılış gecikir ne de kullanıcının ilk tuş vuruşu kare kaybeder.
  /// Motor durumsuzdur: ısıtma hiçbir sonucu değiştirmez.
  void warmUp() {
    _implicitDetector.warmUp();
    for (final cumle in const [
      'sen tam bir aptalsın',
      'Bütün Suriyeliler hırsızdır, bunların hepsi hırsız',
      'senin gibilerden zaten bu beklenirdi',
      'takke düştü kel göründü',
      r'$3r3fsiz a m k oros pu',
    ]) {
      analyze(cumle);
    }
  }

  @override
  String get modelName => enableImplicitPatterns
      ? 'Dilbilimsel Sınıflandırıcı v2 — sözlük + örüntü (cihaz-üstü)'
      : 'Dilbilimsel Sınıflandırıcı v2 — yalnızca sözlük (cihaz-üstü)';

  /// Sözlüğü normalize edip arama yapılarına yerleştirir.
  ///
  /// Sözlük dosyası okunabilirlik için Türkçe aksanlarla yazılmıştır;
  /// eşleştirme kanonik (aksansız) uzayda yapıldığı için burada bir kez
  /// dönüştürülür. Böylece sözlüğe terim eklemek isteyen biri normalizasyon
  /// kurallarını bilmek zorunda kalmaz.
  void _buildIndex() {
    for (final entry in ToxicityLexicon.entries) {
      final normalized = _normalizer.normalize(entry.term).value;
      if (normalized.isEmpty) continue;

      final folded = entry.term
          .toLowerCase()
          .split('')
          .where(_foldedLetters.contains)
          .toSet();
      if (folded.isNotEmpty) _surfaceLetterEvidence[entry.term] = folded;

      _normalizedTerms[entry] = normalized;

      final isShortRoot = !normalized.contains(' ') && normalized.length <= 3;
      if (isShortRoot) _shortRoots.add(entry);
      if (isShortRoot ||
          ToxicityLexicon.spellingSensitiveTerms.contains(normalized)) {
        final spelling = TurkishMorphology.toLowerTr(entry.term);
        if (spelling.length == normalized.length) {
          _shortRootSpelling[entry] = spelling;
        }
      }

      if (!normalized.contains(' ') &&
          normalized.length >= 4 &&
          !entry.requiresDirection) {
        final squeezed = _squeeze(normalized);
        if (squeezed != null) {
          _squeezedEntries.add((
            squeezed: squeezed,
            pairs: [
              for (var k = 1; k < normalized.length; k++)
                if (normalized[k] == normalized[k - 1]) normalized.substring(k - 1, k + 1),
            ],
            entry: entry,
          ));
        }
      }

      if (normalized.contains(' ')) {
        _phraseEntries.add((normalized: normalized, entry: entry));
        final despaced = normalized.replaceAll(' ', '');
        _despacedPhrases[despaced] = entry;
        if (despaced.length >= 7) {
          _despacedPrefixes.add((despaced: despaced, entry: entry));
        }
      } else if (entry.matchMode != MatchMode.prefix) {
        _exactEntries[normalized] = entry;
        _surfaceForms[normalized] = entry;
      } else {
        _prefixEntries.add((normalized: normalized, entry: entry));
        _surfaceForms[normalized] = entry;
      }
    }

    // Uzun kökler önce denenir: "gerizekali" > "geri"
    _prefixEntries.sort((a, b) => b.normalized.length.compareTo(a.normalized.length));
    _phraseEntries.sort((a, b) => b.normalized.length.compareTo(a.normalized.length));
    _despacedPrefixes.sort((a, b) => b.despaced.length.compareTo(a.despaced.length));
    for (final p in _despacedPrefixes) {
      _despacedPrefixByFirst.putIfAbsent(p.despaced.codeUnitAt(0), () => []).add(p);
    }

    String norm(String s) => _normalizer.normalize(s).value;
    for (final pair in ToxicityLexicon.profanePairs) {
      final verbs = <String>{};
      for (final verb in pair.verbs) {
        verbs.add(norm(verb));
        _pairSpelling[norm(verb)] = verb;
      }
      final stems = <String>{};
      for (final stem in pair.stems) {
        stems.add(norm(stem));
        _pairSpelling[norm(stem)] = stem;
      }
      for (final object in pair.objects) {
        _profanePairs.putIfAbsent(norm(object), () => {}).addAll(verbs);
        _profanePairStems.putIfAbsent(norm(object), () => {}).addAll(stems);
        _pairSpelling[norm(object)] = object;
      }
    }
    for (final object in _profanePairs.keys) {
      _pairObjectsByFirst.putIfAbsent(object.codeUnitAt(0), () => []).add(object);
    }
    _ellipticalObjects.addAll(ToxicityLexicon.ellipticalProfanity.map(norm));
    _ellipticalFillers.addAll(ToxicityLexicon.ellipticalFillers.map(norm));
    for (final glue in ToxicityLexicon.compoundGlue.map(norm).toSet()) {
      // Soldaki yapıştırıcı en az üç harf: gerekçe `_splitCompound`.
      if (glue.length >= 3) {
        _leftGlueByFirst.putIfAbsent(glue.codeUnitAt(0), () => []).add(glue);
      }
      _rightGlueByLast
          .putIfAbsent(glue.codeUnitAt(glue.length - 1), () => [])
          .add(glue);
    }

    for (final masked in ToxicityLexicon.maskedPrefixes) {
      final normalized = _normalizer.normalize(masked).value;
      if (normalized.isNotEmpty) _maskedPrefixes.add(normalized);
    }

    for (final candidate in _prefixEntries) {
      final entry = candidate.entry;
      _prefixByFirst
          .putIfAbsent(candidate.normalized.codeUnitAt(0), () => [])
          .add(_StemCandidate(
            candidate.normalized,
            entry,
            isVerbal: entry.category == ToxicityCategory.tehdit ||
                entry.term.endsWith('mek') ||
                entry.term.endsWith('mak'),
          ));
    }
    for (final exact in _exactEntries.entries) {
      if (exact.value.matchMode == MatchMode.verbatim) continue;
      _inflectableExactByFirst
          .putIfAbsent(exact.key.codeUnitAt(0), () => [])
          .add(_StemCandidate(exact.key, exact.value, isVerbal: false));
    }
    for (final masked in _maskedPrefixes) {
      _maskedByFirst.putIfAbsent(masked.codeUnitAt(0), () => []).add(masked);
    }
    for (final exact in _exactEntries.entries) {
      if (exact.value.matchMode != MatchMode.verbatim) continue;
      _literalsByFirst.putIfAbsent(exact.key.codeUnitAt(0), () => []).add(exact.key);
    }
    for (final despaced in _despacedPhrases.keys) {
      _literalsByFirst.putIfAbsent(despaced.codeUnitAt(0), () => []).add(despaced);
    }

    // Öbek kapısı en sonda kurulur: `_phraseEntries` sıralaması bitmiş
    // olmalı, çünkü kapı sıra numarasıyla sorgulanır.
    _phraseGate =
        LiteralIndex.literals([for (final p in _phraseEntries) p.normalized]);

    // Birleştirme kapıları — iki tablonun anahtarları üzerinden.
    for (final key in [..._surfaceForms.keys, ..._despacedPhrases.keys]) {
      if (key.isEmpty) continue;
      if (key.length > _joinMaxLength) _joinMaxLength = key.length;
      _joinFirstCodes.add(key.codeUnitAt(0));
    }
  }

  @override
  CivilityAnalysis analyze(String text) {
    final stopwatch = Stopwatch()..start();

    if (text.trim().isEmpty) {
      return CivilityAnalysis.clean(
        text,
        const ContextSignals(
          hasSecondPersonPronoun: false,
          hasFirstPersonMarker: false,
          hasMention: false,
          capsRatio: 0.0,
          punctuationBurst: 0,
          hasReportedSpeech: false,
          quotedRanges: [],
        ),
      );
    }

    // ── 1-2. Normalizasyon ve tokenizasyon ──────────────────────────────────
    final normalized = _normalizer.normalize(text);
    final baseTokens = _tokenizer.tokenize(normalized.value);

    // ── 3. Kaçınma birleştirme ──────────────────────────────────────────────
    // "a m k" gibi harf-arası-boşluk hilesi için sanal token üretilir.
    // Konum bilgisi korunur, böylece vurgulama doğru yerde kalır.
    final tokens = _withEvasionTokens(baseTokens);

    // ── 5a. Genel bağlam sinyalleri ─────────────────────────────────────────
    // Kaynak indeksleri, bağlam pencerelerini cümle sınırında durdurmak
    // için verilir (docs/24 · madde 13).
    final signals = _contextAnalyzer.analyze(text, tokens,
        sourceIndices: normalized.sourceIndices);

    // ── 4. Eşleştirme ───────────────────────────────────────────────────────
    final findings = <ToxicityFinding>[];

    // 4a. Öbek eşleşmeleri (çok kelimeli)
    findings.addAll(_matchPhrases(normalized, tokens, signals));

    // 4b. Token eşleşmeleri (tek kelimeli)
    findings.addAll(_matchTokens(normalized, tokens, signals));

    // 4b2. Bölme/bitişik yazma kaçışları ("oros pu", "aminakoyim").
    findings.addAll(_matchEvasionJoins(normalized, tokens, signals));

    // 4b3. Nesne + fiil küfürleri ve tek başına küfür nesnesi (docs/25).
    findings.addAll(_matchProfanePairs(normalized, tokens, signals));

    // 4b4. Önceki yolların hiçbirine takılmayan token'larda birleşik yazım
    // ("siktirgit", "senisikerim") ve yıldızla sansür ("s*kerim").
    findings.addAll(_matchCompounds(normalized, tokens, signals, findings));

    // 4c. Edimbilimsel örüntüler — yasaklı kelime içermeyen saldırı.
    var needsSupport = false;
    if (enableImplicitPatterns) {
      final implicit = _matchImplicit(normalized, tokens, signals);
      findings.addAll(implicit.findings);
      needsSupport = implicit.needsSupport;
    }

    // Aynı karakter aralığında birden fazla bulgu varsa en şiddetlisini tut.
    final deduped = _deduplicate(findings);
    deduped.sort((a, b) => b.adjustedSeverity.compareTo(a.adjustedSeverity));

    // ── 6. Skor birleştirme ─────────────────────────────────────────────────
    final toxicity = _combineSeverities(deduped);

    // ── KALDIRILAN: "davranışsal biyometri" (13 Eylül 2026) ─────────────────
    // Burada, Android klavyesinin gönderdiği yazma hızı ve silme oranına göre
    // skora +0,25'e kadar "öfke cezası" ekleyen bir adım vardı. Kaldırıldı:
    //   • Hiç ölçülmedi. Hiçbir etiketli kümede, hiçbir değerlendirmede
    //     çalışmıyordu; raporlanan her sayı onsuz üretildi.
    //   • Hızlı yazmayı ve çok silmeyi öfke saymak, hızlı yazanı, yeni
    //     öğreneni ve motor güçlüğü olan kullanıcıyı sistematik olarak daha
    //     sert yargılar. Aynı cümle, yazanın parmağına göre farklı karar almaz.
    //   • Klavyede tuş vuruşu zamanlaması toplamayı gerektiriyordu.

    stopwatch.stop();

    return CivilityAnalysis(
      text: text,
      toxicity: toxicity,
      civilityScore: ((1.0 - toxicity) * 100).round().clamp(0, 100),
      risk: _riskFrom(toxicity),
      findings: deduped,
      signals: signals,
      elapsed: stopwatch.elapsed,
      needsSupport: needsSupport,
    );
  }

  // ─── Eşleştirme ───────────────────────────────────────────────────────────

  /// Çok kelimeli öbekleri normalize metin içinde doğrudan arar.
  List<ToxicityFinding> _matchPhrases(
    NormalizedText normalized,
    List<Token> tokens,
    ContextSignals signals,
  ) {
    final results = <ToxicityFinding>[];

    // Tek tarama: hangi öbekler bu metinde geçebilir? "Geçemez" kesindir,
    // "geçebilir" yalnızca aramaya değer demektir (docs/28).
    final hits = _phraseGate.scan(normalized.value);

    for (int p = 0; p < _phraseEntries.length; p++) {
      if (!hits.mayMatch(p)) continue;
      final candidate = _phraseEntries[p];
      int searchFrom = 0;

      while (true) {
        final index = normalized.value.indexOf(candidate.normalized, searchFrom);
        if (index < 0) break;

        final end = index + candidate.normalized.length;

        // Kelime sınırı kontrolü: "sen kimsin" öbeği "sen kimsindir" içinde
        // geçerli ama "essen kimsin" içinde değil.
        final leftOk = index == 0 || normalized.value[index - 1] == ' ';
        if (leftOk) {
          final originalRange = normalized.toOriginalRange(index, end);

          // Öbeğin kapladığı token aralığını bul — bağlam penceresi için.
          final tokenIndex = _tokenIndexAt(tokens, index);
          final tokenEndIndex =
              _tokenIndexEndAt(tokens, index, end, tokenIndex);

          final context = _contextAnalyzer.evaluateMatch(
            tokens: tokens,
            matchIndex: tokenIndex,
            matchEndIndex: tokenEndIndex,
            originalRange: originalRange,
            signals: signals,
            selfDirectionApplies: _selfDirectionApplies(candidate.entry),
            negationApplies: !_isObscene(candidate.entry),
          );

          final finding = _buildFinding(
            term: candidate.entry.term,
            category: candidate.entry.category,
            severity: candidate.entry.severity,
            requiresDirection: candidate.entry.requiresDirection,
            neutralAlternative: candidate.entry.neutralAlternative,
            originalText: normalized.original,
            originalRange: originalRange,
            context: context,
          );
          if (finding != null) results.add(finding);
        }

        searchFrom = index + 1;
      }
    }

    return results;
  }

  /// Tek kelimeli terimleri token bazında eşleştirir.
  List<ToxicityFinding> _matchTokens(
    NormalizedText normalized,
    List<Token> tokens,
    ContextSignals signals,
  ) {
    final results = <ToxicityFinding>[];

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // ── Maskeleme kontrolü: meşru kelime mi? ──
      // "şikayet", "götürdü", "malzeme" burada elenir.
      if (_isMasked(token.text)) continue;

      // Token'ın agresif varyanttaki karşılığı. İki varyant birebir aynı
      // uzunlukta olduğu için indeksler doğrudan kullanılabilir.
      // Sanal (birleştirilmiş) token'lar bu aralığın dışında kalabileceğinden
      // sınır kontrolü yapılır.
      var aggressiveText = (token.end <= normalized.aggressive.length)
          ? normalized.aggressive.substring(token.start, token.end)
          : token.text;

      // Birleştirilmiş kaçınma token'ları ("a m k") aralıklarında boşluk
      // taşır; agresif dilimden de aynı şekilde temizlenmeleri gerekir.
      if (aggressiveText.length != token.text.length) {
        aggressiveText = aggressiveText.replaceAll(' ', '');
      }

      // Agresif varyant da meşru bir kelimeye denk geliyorsa elenir.
      if (aggressiveText != token.text && _isMasked(aggressiveText)) continue;

      var matched = _lookup(token.text) ??
          (aggressiveText == token.text ? null : _lookup(aggressiveText));

      // ── ÇİFT HARF UZATMASI (docs/25) ─────────────────────────────────────
      // Normalizasyon 3+ tekrarı daraltır ama ikiliyi KORUR ("elli",
      // "dikkat"). Uzatma çoğu zaman tam iki harfle yapılır ve kaçıyordu:
      //
      //   "amkk" · "aqq" · "salakk" · "aptaal" · "eşşek herif" → Temiz ✗
      //
      // İkililer yalnızca başka hiçbir eşleşme yoksa tek harfe indirilir.
      // Kısa kökler bu yoldan eşleşemez (kısaltmalar hariç): "itti" → "iti"
      // = it + i, "amma" → "ama" gibi çakışmalar kısa köklerde toplanır.
      var dedoubled = false;
      if (matched == null) {
        final single = _dedouble(token.text);
        if (single != null && !_isMasked(single)) {
          final candidate = _lookup(single);
          if (candidate != null &&
              (!_shortRoots.contains(candidate) ||
                  candidate.matchMode == MatchMode.verbatim) &&
              !ToxicityLexicon.shortRootCollisions.contains(single)) {
            matched = candidate;
            dedoubled = true;
          }
        }
      }

      // ── UZATMA KUYRUĞU ───────────────────────────────────────────────────
      // Tuş basılı tutulurken uzatmanın ARDINDAN bir iki karakter daha
      // düşer. Normalizasyon uzatmayı daraltır ama bu artığı bırakır; ortaya
      // çıkan biçim geçerli bir Türkçe çekim olmadığı için sözlükte bulunmaz:
      //
      //   "sikerimmmmmmmmo" → "sikerimo" → Temiz ✗
      //   "siktirrrrrrrra"  → "siktira"  → Temiz ✗
      //   "salakkkkkkko"    → "salako"   → Temiz ✗
      //   "aptalllllllx"    → "aptalks"  → Temiz ✗
      //
      // Kuyruksuz uzatma ("sikerimmmmm") zaten yakalanıyordu; kaçan yalnızca
      // kuyruklu biçimdi. Uzatmanın SONUNDA olduğu hâller de etkilenmez.
      //
      // ── NEDEN YANLIŞ POZİTİF ÜRETMEZ ───────────────────────────────────
      // Üç koşul birden aranır: özgün metinde gerçekten 3+ tekrar olacak,
      // kuyruk en fazla iki karakter olacak, ve kalan kök ≥ 3 harf olacak.
      // Gündelik uzatmalar bu kapıdan zararsız geçer:
      //
      //   "tamammmmmma" → "tamam"  (sözlükte yok)
      //   "seeeeeeni"   → "se"     (3 harften kısa, reddedilir)
      //   "çoookkkkta"  → "cok"    (sözlükte yok)
      //   "okeyyyyyy"   → kuyruk yok, hiç denenmez
      //
      // Kısa kökler (D1) bu yoldan eşleşemez: "ammmma" → "am" tek harflik
      // kuyrukla meşru "ama" bağlacına çok yakındır.
      //
      // Kuyruk yalnızca SONDAN kesildiği için kökün harf konumları özgün
      // metinde yerinde kalır; `_dedouble`'ın aksine yüzey kanıtı denetimi
      // (`_surfaceContradictsRoot`) bu yolda da geçerlidir ve atlanmaz.
      // Uzatma kuyruğu ikileme yolunda da aday üretir; bir kez hesaplanır.
      ({String value, String aggressive})? stripped;
      if (matched == null) {
        stripped = _stripElongationTail(normalized, token);
        if (stripped != null) {
          for (final form in {stripped.value, stripped.aggressive}) {
            if (form.length < 3 || _isMasked(form)) continue;
            final candidate = _lookup(form);
            if (candidate != null &&
                !_shortRoots.contains(candidate) &&
                !ToxicityLexicon.shortRootCollisions.contains(form)) {
              matched = candidate;
              break;
            }
          }
        }
      }

      // ── KELİME İÇİ HARF İKİLEMESİ (docs/32) ──────────────────────────────
      // `_dedouble` ünsüz ikilisini yalnızca kelime SONUNDA indirir; kelime
      // içindeki ikili ve ikiliden sonra düşen tek harflik kuyruk kaçıyordu:
      //
      //   "sikerriimmo" · "şerrefsiz" · "pezzevenk" · "orrospu" · "ssalak"
      //   · "göttveren" · "gerizekkalı" · "sikttir"                → Temiz ✗
      //
      // Bu yol yalnızca önceki yolların HİÇBİRİ eşleşmediğinde çalışır ve
      // `_dedouble`'ın kelime içi ünsüz sınırını kaldırır. Sınırın gerekçesi
      // ("yıllanma" → "yılanma") geçerliliğini korur; ama o gerekçe masum bir
      // kelimenin BAŞKA bir masum kelimeye inmesiyle ilgilidir. Burada iniş
      // yalnızca sözlükte geçerli bir kök + ek bulursa sonuç verir ve bu,
      // 91.861 biçimlik kelime listesinde denetlendi (docs/32).
      //
      // Maliyet: yol, eşleşmeyen HER token'da çalışır. Kopya üretmeden önce
      // iki ucuz kapı sorulur — token'da ikili var mı, özgün yazılış normalize
      // biçimden uzun mu (3+ tekrar daraltılmış olabilir). Gündelik token'ların
      // çoğu ikisinden de geçemez ve hiçbir dizgi üretilmez.
      if (matched == null) {
        final capped = _originalLonger(normalized, token)
            ? _cappedElongationForms(normalized, token)
            : null;
        if (capped != null ||
            stripped != null ||
            _hasDouble(token.text) ||
            _hasDouble(aggressiveText)) {
          final squeezed = _squeezeLookup(
            normalized,
            token,
            {
              token.text,
              aggressiveText,
              if (stripped != null) ...[stripped.value, stripped.aggressive],
              ...?capped,
            },
            direct: capped ?? const {},
          );
          if (squeezed != null) {
            matched = squeezed;
            dedoubled = true;
          }
        }
      }

      // ── KALDIRILAN: ters yazım denemesi (13 Eylül 2026) ─────────────────────
      // Burada 4+ harfli her token TERSTEN de sözlükte aranıyordu ("latpa" →
      // "aptal"). Tersten okunan kelime kök + ek denetiminden geçtiği için
      // Türkçenin en sık kelimeleri saldırıya dönüşüyordu:
      //
      //   "Sen taş atma"                → "amta" = am + ta   → Yüksek risk ✗
      //   "Sen de çöpü yere atma"       → aynı                → Yüksek risk ✗
      //   "Sen bizden uzak dur"         → "kazu" = kaz + u   → Riskli      ✗
      //   "Bahçeye kalas taşıdık"       → "salak"             → Riskli      ✗
      //
      // Yüksek risk gönderimde onay diyaloğu açar; yani çöpü yere atma diyen
      // kişi "suç teşkil edebilir" uyarısı alıyordu. Karşılığında yakaladığı
      // kaçış ek alınca ("latpasın") zaten çalışmıyordu ve hiçbir etiketli
      // kümede örneği yoktu. Kesinlik önce gelir; deneme kaldırıldı ve
      // `test/civility_engine_test.dart` bu cümleleri koruyor.

      if (matched == null) continue;

      // ── KISA KÖK ÇAKIŞMALARI (D1 + D2 · docs/20) ───────────────────────────
      // ≤ 3 harfli köklere tanınan çekim listesi, bu köklerle başlayan en sık
      // Türkçe kelimeleri de kapsıyordu: "ama" = am + a → Yüksek risk,
      // "sıkı" = sik + i → Yüksek risk, "kaza" = kaz + a → Riskli.
      // Çakışma listesi ASCII yazımı içindir: "amin" (dua) ile "amın" normalize
      // metinde aynıdır ama kullanıcı "ı" yazdıysa dua kastedilmemiştir.
      if (_shortRoots.contains(matched) &&
          (ToxicityLexicon.shortRootCollisions.contains(token.text) ||
              ToxicityLexicon.shortRootCollisions.contains(aggressiveText)) &&
          !_surfaceConfirms(normalized, token, matched)) {
        continue;
      }
      // Yüzey kanıtı: kısa kökler (D1) ve "ı" ikizi olan uzun girdiler
      // ("sıktım", "sıkım" · docs/25). Çift harfi indirilmiş token'da harf
      // konumları kaydığı için karşılaştırma yapılamaz.
      if (!dedoubled && _surfaceContradictsRoot(normalized, token, matched)) {
        continue;
      }

      // ── D10 · KENDİNE YÖNELİK TEHDİT FİİLİ (docs/23) ─────────────────────
      // "Kendimi öldüreceğim" bir tehdit DEĞİLDİR; nesnesi konuşanın
      // kendisidir. Önceki sürüm bu cümleyi Yüksek risk yapıyor ve gönderimde
      // "Tehdit, TCK kapsamında suç oluşturabilir" onayı açıyordu — D4'ün
      // korumak istediği kişiyi, D4'ün kapattığı yoldan ikinci kez
      // cezalandırıyordu. Bulgu üretilmez; destek işaretini
      // `kendineZarar.*` örüntüleri koyar.
      if (matched.category == ToxicityCategory.tehdit &&
          _hasReflexiveObject(tokens, i)) {
        continue;
      }

      final originalRange = normalized.toOriginalRange(token.start, token.end);

      final context = _contextAnalyzer.evaluateMatch(
        tokens: tokens,
        matchIndex: i,
        originalRange: originalRange,
        signals: signals,
        // Tehdit birinci şahıs çekimlidir ("öldürürüm") ama öz-ifade
        // değildir. Bu ayrım olmadan her tehdit yumuşatılıp eleniyordu.
        // Ağır küfürde de aynı ilke geçerli: bkz. `_selfDirectionApplies`.
        selfDirectionApplies: _selfDirectionApplies(matched),
        negationApplies: !_isObscene(matched),
      );

      // ── D7 · SOMUT ADLARDA YAPISAL YÖNELİM (docs/21) ─────────────────────
      // Yakınlık yönelimi "Sana köpeğimin fotoğrafını atayım" cümlesini
      // Yüksek risk yapıyordu. Bu adlar yalnızca muhataba YAKIŞTIRILMIŞSA
      // (öküzsün · seni gidi domuz · köpek misin · maymun gibi
      // davranıyorsun · eşek herif) bulgu üretir.
      if (matched.requiresDirection &&
          ToxicityLexicon.predicativeDirectionTerms.contains(matched.term) &&
          !_contextAnalyzer.isPredicativelyDirected(
              tokens: tokens, matchIndex: i, signals: signals)) {
        continue;
      }

      final finding = _buildFinding(
        term: matched.term,
        category: matched.category,
        severity: matched.severity,
        requiresDirection: matched.requiresDirection &&
            !_surfaceConfirms(normalized, token, matched),
        neutralAlternative: matched.neutralAlternative,
        originalText: normalized.original,
        originalRange: originalRange,
        context: context,
      );
      if (finding != null) results.add(finding);
    }

    return results;
  }

  /// Edimbilimsel örüntüleri eşleştirir.
  ///
  /// Örüntü bulguları da AYNI bağlam katmanından geçer. Bu şart:
  /// "işine bak diyorlar ama ben yardım etmek istiyorum" cümlesinde kalıp
  /// AKTARILIYOR, kullanılmıyor — aktarma fiili bunu yumuşatmalı.
  ///
  /// Kendine zarar ailesi bulgu üretmez; yalnızca destek işaretini koyar.
  ({List<ToxicityFinding> findings, bool needsSupport}) _matchImplicit(
    NormalizedText normalized,
    List<Token> tokens,
    ContextSignals signals,
  ) {
    final results = <ToxicityFinding>[];
    var needsSupport = false;

    for (final match in _implicitDetector.detect(normalized.value)) {
      if (match.pattern.family == ImplicitFamily.kendineZararVerme) {
        needsSupport = true;
        continue;
      }

      final originalRange = normalized.toOriginalRange(match.start, match.end);
      final tokenIndex = _tokenIndexAt(tokens, match.start);
      final tokenEndIndex =
          _tokenIndexEndAt(tokens, match.start, match.end, tokenIndex);

      final context = _contextAnalyzer.evaluateMatch(
        tokens: tokens,
        matchIndex: tokenIndex,
        matchEndIndex: tokenEndIndex,
        originalRange: originalRange,
        signals: signals,
        // Örüntüler hedefi kendi yapılarında taşır; öz-yönelim hesabı
        // anlamsızdır ve "aptal demiyorum ama" gibi kalıpları eliyordu.
        selfDirectionApplies: false,
      );

      final finding = _buildFinding(
        term: match.pattern.id,
        category: match.pattern.category,
        severity: match.pattern.severity,
        requiresDirection: false,
        originalText: normalized.original,
        originalRange: originalRange,
        context: context,
        source: FindingSource.oruntu,
        neutralAlternative: match.pattern.neutralAlternative,
        implicitFamily: match.pattern.family,
      );
      if (finding != null) results.add(finding);
    }

    return (findings: results, needsSupport: needsSupport);
  }

  /// Kelimeyi bölerek veya bitiştirerek yapılan gizlemeyi yakalar.
  ///
  /// ── İKİ AYRI KAÇIŞ, TEK MEKANİZMA ────────────────────────────────────────
  /// Ölçüm iki gerçek açık gösterdi ve ikisi de aynı kökten geliyordu:
  /// katman BOŞLUĞU sabit bir kelime sınırı sayıyordu.
  ///
  ///   "orospu"      → yakalanıyordu     "oros pu"     → temiz  ✗  (bölme)
  ///   "amina koyim" → yakalanıyordu     "aminakoyim"  → temiz  ✗  (bitiştirme)
  ///
  /// Mevcut kaçınma birleştirmesi yalnızca ÜÇ ya da daha fazla ardışık TEK
  /// HARFLİ token'ı ("a m k") görüyordu; hece düzeyinde bölmeyi görmüyordu.
  ///
  /// ── NEDEN BÜTÜN METNİN BOŞLUKLARI SİLİNMİYOR ─────────────────────────────
  /// En kısa çözüm, metnin boşluklarını silip içinde arama yapmaktır. Bu
  /// çözüm KABUL EDİLMEDİ çünkü masum cümlelerden saldırgan dizgiler üretir:
  ///
  ///   "o çocuk"  → "ococuk"   içinde "oç" epiteti var  → yanlış pozitif
  ///
  /// Bunun yerine yalnızca KOMŞU token'lar birleştirilir ve sonuç TAM
  /// EŞLEŞME olarak aranır — kök eşleşmesi (prefix) KASITLI olarak devre
  /// dışıdır. "oçocuk" hiçbir sözlük girdisiyle birebir aynı olmadığı için
  /// elenir; "orospu" olduğu için yakalanır. Kesinlik, mekanizmanın
  /// kendisinden gelir; bir istisna listesinden değil.
  ///
  /// Pencere en fazla üç token'dır: daha uzun bölmeler ("o r o s p u") zaten
  /// tek-harf birleştirmesinin alanına girer.
  List<ToxicityFinding> _matchEvasionJoins(
    NormalizedText normalized,
    List<Token> tokens,
    ContextSignals signals,
  ) {
    if (tokens.isEmpty) return const [];

    final results = <ToxicityFinding>[];

    // width = 1 YALNIZCA birleşik yazılmış ÖBEKLER için taranır
    // ("aminakoyim"). Tek kelimelik girdiler zaten `_matchTokens` yolunda
    // ve orada kök eşleşmesiyle birlikte aranıyor; burada tekrarlanmaları
    // aynı bulgunun iki kez üretilmesinden başka bir şey yapmaz.
    for (int width = 1; width <= 3; width++) {
      for (int i = 0; i + width <= tokens.length; i++) {
        // Birleşimin UZUNLUĞU parçalardan hesaplanır; String kurmak için
        // önce aşağıdaki kapıların geçilmesi beklenir (docs/28).
        var joinedLength = 0;
        var allSingleLetters = true;
        for (int k = 0; k < width; k++) {
          final t = tokens[i + k];
          joinedLength += t.text.length;
          if (t.length != 1) allSingleLetters = false;
        }

        // Kısa birleşimler gürültüdür — TEK İSTİSNA, parçaların hepsinin
        // tek harf olmasıdır. "a q" kasıtlı bir gizlemedir ve iki harflik
        // bir sonuç üretir; mevcut tek-harf birleştirmesi ise ancak ÜÇ
        // harften itibaren devreye girdiği için tam bu aralığı kaçırıyordu.
        final minLength = allSingleLetters ? 2 : 4;
        if (joinedLength < minLength) continue;

        // İşlev kelimeleri bir hecenin yarısı değildir (docs/25):
        // "kuş bu dala kondu" → "bu" + "dala" → "budala" · Riskli ✗
        if (width > 1 && !allSingleLetters) {
          var stop = false;
          for (int k = 0; k < width; k++) {
            if (ToxicityLexicon.joinStopWords.contains(tokens[i + k].text)) {
              stop = true;
              break;
            }
          }
          if (stop) continue;
        }

        LexiconEntry? entry;
        if (width == 1) {
          // Tek token: birleşim zaten token'ın kendisidir.
          final joined = tokens[i].text;
          entry = _despacedPhrases[joined] ?? _despacedPrefix(joined);
        } else if (joinedLength <= _joinMaxLength &&
            _joinFirstCodes.contains(tokens[i].text.codeUnitAt(0))) {
          // Çok token: yalnızca BİREBİR tablolarda aranır, yani birleşim
          // tablodaki bir anahtardan uzun olamaz ve onunla aynı harfle
          // başlamak zorundadır. Kapıyı geçmeyen birleşim hiç kurulmaz.
          final joined = width == 2
              ? tokens[i].text + tokens[i + 1].text
              : tokens[i].text + tokens[i + 1].text + tokens[i + 2].text;
          entry = _surfaceForms[joined] ?? _despacedPhrases[joined];
        }

        // ── ÜNLEM İŞARETİYLE "i" GİZLEMESİ (docs/25) ───────────────────────
        // '!' cümle sınırı sayıldığı için ("Ne dedin?Aptal") "s!kerim"
        // normalizasyonda "s kerim" diye ikiye bölünüyordu. İki parça
        // arasında özgün metinde YALNIZCA tek bir '!' varsa, işaret "i"
        // harfi yerine konmuş olarak da denenir.
        if (entry == null &&
            width == 2 &&
            _isBangGap(normalized, tokens[i], tokens[i + 1])) {
          final withI = '${tokens[i].text}i${tokens[i + 1].text}';
          final candidate = _lookup(withI);
          if (candidate != null && !_shortRoots.contains(candidate)) {
            entry = candidate;
          }
        }
        if (entry == null) continue;

        final start = tokens[i].start;
        final end = tokens[i + width - 1].end;
        final originalRange = normalized.toOriginalRange(start, end);

        final context = _contextAnalyzer.evaluateMatch(
          tokens: tokens,
          matchIndex: i,
          matchEndIndex: i + width - 1,
          originalRange: originalRange,
          signals: signals,
          // ── ÖZ-YÖNELİM BU YOLDA HESAPLANMAZ ─────────────────────────────
          // Öbek yolunda (`_matchPhrases`) eşleşmenin KENDİ İÇİNDEKİ
          // kelimeler bağlam taramasından dışlanır: "amına koyim" öbeğinde
          // "koyim"in birinci şahıs eki öbeğin parçasıdır, konuşanın
          // kendinden bahsettiğinin işareti değildir.
          //
          // Birleştirme yolunda bu dışlama kendiliğinden çalışmaz, çünkü
          // öbek TEK bir token hâline gelmiştir ve bağlam katmanı onun
          // kendi son ekine bakar. Ölçülen sonuç şuydu:
          //
          //   "amina koyim" → 0.95        "aminakoyim" → 0.00  ✗
          //
          // Bitişik yazmak bir küfrü öz-ifadeye çevirmez. Dışlama burada
          // açıkça yapılır; aksi hâlde kaçış yolu kapanmış görünürken
          // bağlam katmanı üzerinden yeniden açılıyordu.
          selfDirectionApplies: false,
          negationApplies: !_isObscene(entry),
        );

        final finding = _buildFinding(
          term: entry.term,
          category: entry.category,
          severity: entry.severity,
          requiresDirection: entry.requiresDirection,
          neutralAlternative: entry.neutralAlternative,
          originalText: normalized.original,
          originalRange: originalRange,
          context: context,
        );
        if (finding != null) results.add(finding);
      }
    }

    return results;
  }

  /// Nesne + fiil küfürlerini ve tek başına kullanılan küfür nesnesini arar
  /// (docs/25). Gerekçe: `ToxicityLexicon.profanePairs`.
  ///
  ///   "ananı siktim"   → iki token, nesne + fiil
  ///   "ananısiktim"    → tek token, bitişik yazım
  ///   "ulan bacını"    → mesajın tamamı küfür nesnesi (+ ünlem)
  ///   "ananı özledin mi" → hiçbiri
  List<ToxicityFinding> _matchProfanePairs(
    NormalizedText normalized,
    List<Token> tokens,
    ContextSignals signals,
  ) {
    final n = _baseTokenCount(tokens);
    if (n == 0) return const [];
    final results = <ToxicityFinding>[];

    ToxicityFinding? build(String term, int from, int to, double severity) {
      final range = normalized.toOriginalRange(tokens[from].start, tokens[to].end);
      return _buildFinding(
        term: term,
        category: ToxicityCategory.kufur,
        severity: severity,
        requiresDirection: false,
        originalText: normalized.original,
        originalRange: range,
        context: _contextAnalyzer.evaluateMatch(
          tokens: tokens,
          matchIndex: from,
          matchEndIndex: to,
          originalRange: range,
          signals: signals,
          selfDirectionApplies: false,
          negationApplies: false,
        ),
      );
    }

    for (int i = 0; i < n; i++) {
      final text = tokens[i].text;

      // Ayrı yazım: nesne ve hemen ardından fiil.
      if (_profanePairs.containsKey(text) && i + 1 < n) {
        final next = tokens[i + 1];
        final verb = _pairVerb(text, next.text);
        if (verb != null &&
            !_writtenContradicts(normalized, next, 0, _pairSpelling[verb]!)) {
          final f = build('${_pairSpelling[text]} ${_pairSpelling[verb]}',
              i, i + 1, 0.95);
          if (f != null) results.add(f);
          continue;
        }
      }

      // Bitişik yazım: nesneyle başlayan ve kalanı listedeki fiil olan token.
      // Kelime sonu uzatması da denenir: "amkoyayımm".
      final objects =
          text.isEmpty ? null : _pairObjectsByFirst[text.codeUnitAt(0)];
      if (objects == null) continue;
      var found = false;
      for (var pass = 0; pass < 2 && !found; pass++) {
        // İkinci tur yalnızca uzatma varsa kopya üretir (`_dedouble`).
        final candidate = pass == 0 ? text : _dedouble(text);
        if (candidate == null) break;
        for (final object in objects) {
          if (candidate.length <= object.length || !candidate.startsWith(object)) {
            continue;
          }
          final verb = _pairVerb(object, candidate.substring(object.length));
          if (verb == null) continue;
          // Harf konumları yalnızca indirilmemiş token'da özgün metne denk düşer.
          if (pass == 0 &&
              _writtenContradicts(
                  normalized, tokens[i], object.length, _pairSpelling[verb]!)) {
            continue;
          }
          final f = build('${_pairSpelling[object]} ${_pairSpelling[verb]}', i, i, 0.95);
          if (f != null) results.add(f);
          found = true;
          break;
        }
      }
    }

    // Mesajın tamamı küfür nesnesi ve ünlemlerden oluşuyor mu?
    var objectIndex = -1;
    for (int i = 0; i < n; i++) {
      final text = tokens[i].text;
      if (_ellipticalObjects.contains(text)) {
        objectIndex = i;
      } else if (!_ellipticalFillers.contains(text)) {
        objectIndex = -1;
        break;
      }
    }
    if (objectIndex >= 0) {
      final f = build(_pairSpelling[tokens[objectIndex].text] ??
          tokens[objectIndex].text, objectIndex, objectIndex, 0.90);
      if (f != null) results.add(f);
    }

    return results;
  }

  /// [verbText] bu nesnenin kabul ettiği bir fiil mi? Tam biçim listesinde
  /// varsa kendisini, bir fiil köküyle başlıyorsa o kökü (normalize) döndürür.
  String? _pairVerb(String object, String verbText) {
    if (_profanePairs[object]?.contains(verbText) ?? false) return verbText;
    final stems = _profanePairStems[object];
    if (stems != null) {
      for (final stem in stems) {
        if (verbText.startsWith(stem)) return stem;
      }
    }
    return null;
  }

  /// [token] içinde [offset] konumundan başlayarak özgün metne yazılmış
  /// Türkçeye özgü harfler, [spelling] yazılışıyla çelişiyor mu?
  ///
  /// "anneni sıktım" → normalize "anneni siktim"; ama "ı" yazılmıştır ve
  /// "siktim" yazılışıyla çelişir. Kural `_surfaceContradictsRoot` ile
  /// aynıdır: ASCII harf ve belirsiz büyük "I" hiçbir şeyle çelişmez.
  bool _writtenContradicts(
      NormalizedText normalized, Token token, int offset, String spelling) {
    if (token.end - token.start != token.text.length) return false;
    final expected = TurkishMorphology.toLowerTr(spelling);
    for (var k = 0; k < expected.length; k++) {
      final j = token.start + offset + k;
      if (j >= token.end || j >= normalized.sourceIndices.length) return false;
      final raw = normalized.original[normalized.sourceIndices[j]];
      if (raw == 'I') continue;
      final written = raw == 'İ' ? 'i' : raw.toLowerCase();
      if (written == expected[k] || !_turkishOnlyLetters.contains(written)) {
        continue;
      }
      return true;
    }
    return false;
  }

  /// Önceki yolların hiçbirine takılmamış token'larda iki kaçışı arar
  /// (docs/25):
  ///
  /// 1. YILDIZLA SANSÜR — "s*kerim", "g*t", "p*ç". Normalizasyon harf
  ///    arasındaki '*' işaretini gizleme sayıp siler ve "skerim" kalır. Silinen
  ///    yıldızın yerine sırayla her ünlü konup sözlükte aranır. Yıldız
  ///    kullanıcının KENDİ sansürüdür; hangi kelimenin kastedildiğini açıkça
  ///    bildirir. Ünsüz denenmez: "a*k" hem "amk" hem "aşk" olabilir.
  ///
  /// 2. BİRLEŞİK YAZIM — "siktirgit", "senisikerim", "piçkurusu". Token iki
  ///    tam parçaya bölünür; kurallar `ToxicityLexicon.compoundGlue`
  ///    açıklamasında.
  List<ToxicityFinding> _matchCompounds(
    NormalizedText normalized,
    List<Token> tokens,
    ContextSignals signals,
    List<ToxicityFinding> existing,
  ) {
    final n = _baseTokenCount(tokens);
    final results = <ToxicityFinding>[];

    for (int i = 0; i < n; i++) {
      final token = tokens[i];
      final text = token.text;
      if (text.length < 2 || text.length > 24 || !_isPlainWord(text)) continue;
      if (_isMasked(text)) continue;

      ({int from, int to, LexiconEntry entry})? hit;

      final slots = _wildcardSlots(normalized, token);
      if (slots.isNotEmpty && slots.length <= 2) {
        final entry = _fillWildcards(text, slots);
        if (entry != null) hit = (from: 0, to: text.length, entry: entry);
      }

      if (hit == null && text.length >= 5) hit = _splitCompound(text);
      if (hit == null) continue;

      // Yalnızca önceki yolların hiçbirine takılmamış token'lar.
      final tokenRange = normalized.toOriginalRange(token.start, token.end);
      if (existing.any((f) => f.start < tokenRange.end && f.end > tokenRange.start)) {
        continue;
      }

      final entry = hit.entry;
      final range = normalized.toOriginalRange(
          token.start + hit.from, token.start + hit.to);
      final context = _contextAnalyzer.evaluateMatch(
        tokens: tokens,
        matchIndex: i,
        originalRange: range,
        signals: signals,
        selfDirectionApplies: false,
        negationApplies: !_isObscene(entry),
      );
      if (entry.requiresDirection &&
          ToxicityLexicon.predicativeDirectionTerms.contains(entry.term) &&
          !_contextAnalyzer.isPredicativelyDirected(
              tokens: tokens, matchIndex: i, signals: signals)) {
        continue;
      }
      final finding = _buildFinding(
        term: entry.term,
        category: entry.category,
        severity: entry.severity,
        requiresDirection: entry.requiresDirection,
        neutralAlternative: entry.neutralAlternative,
        originalText: normalized.original,
        originalRange: range,
        context: context,
      );
      if (finding != null) results.add(finding);
    }

    return results;
  }

  /// Token'ın içinde, özgün metinde yıldızla ('*') doldurulmuş boşlukların
  /// normalize konumları. "s*kerim" → normalize "skerim" → [1].
  List<int> _wildcardSlots(NormalizedText normalized, Token token) {
    final indices = normalized.sourceIndices;
    // Ucuz ön eleme: özgün metinde harfleri bitişik duran token'da silinmiş
    // karakter yoktur.
    if (token.end > indices.length ||
        indices[token.end - 1] - indices[token.start] + 1 <= token.text.length) {
      return const [];
    }
    List<int>? slots;
    for (var k = 1; k < token.text.length; k++) {
      final b = token.start + k;
      if (b >= indices.length) break;
      final from = indices[b - 1] + 1;
      final to = indices[b];
      if (to <= from) continue;
      var allStars = true;
      for (var c = from; c < to; c++) {
        if (normalized.original.codeUnitAt(c) != 0x2A) {
          allStars = false;
          break;
        }
      }
      if (allStars) (slots ??= []).add(k);
    }
    return slots ?? const [];
  }

  static const String _wildcardVowels = 'aeiou';

  /// Yıldız yuvalarını ünlülerle doldurup sözlükte arar; ilk eşleşme kazanır.
  LexiconEntry? _fillWildcards(String text, List<int> slots) {
    LexiconEntry? tryText(String candidate) {
      if (_isMasked(candidate) ||
          ToxicityLexicon.shortRootCollisions.contains(candidate)) {
        return null;
      }
      return _lookup(candidate);
    }

    for (final v1 in _wildcardVowels.split('')) {
      final once = '${text.substring(0, slots[0])}$v1${text.substring(slots[0])}';
      if (slots.length == 1) {
        final e = tryText(once);
        if (e != null) return e;
        continue;
      }
      final at = slots[1] + 1; // ilk ekleme ikinci yuvayı bir kaydırır
      for (final v2 in _wildcardVowels.split('')) {
        final e = tryText('${once.substring(0, at)}$v2${once.substring(at)}');
        if (e != null) return e;
      }
    }
    return null;
  }

  /// Birleşik yazılmış token'ı iki tam parçaya böler. Parçalardan biri
  /// sözlük girdisi, öteki yapıştırıcı kelime ya da ikinci bir girdi olmalı.
  /// İkisi de girdiyse daha şiddetli olanın aralığı döner.
  ///
  /// ── MALİYET ──────────────────────────────────────────────────────────────
  /// Bu yol, metindeki eşleşmeyen HER token'da çalışır. İlk sürüm her bölme
  /// noktasında iki alt dizgi üretip sözlükte arıyordu; 4.800 karakterlik
  /// metinde çözümleme süresini ~2 katına çıkardı (AOT 5,9 → 10,5 ms).
  /// Bölme noktaları artık KOPYA ÜRETMEYEN ön koşullarla seçilir:
  ///   • yapıştırıcı parça  → `startsWith` / `endsWith`
  ///   • sözlük parçası     → ilk harf kovasındaki bir kökle başlamalı
  /// Gündelik bir token ("normal", "cümledir") bu koşulların hiçbirini
  /// sağlamaz ve tek bir alt dizgi üretilmeden geçilir.
  ({int from, int to, LexiconEntry entry})? _splitCompound(String text) {
    // 1. Yapıştırıcı + girdi: "senisikerim". Soldaki yapıştırıcı en az üç
    // harf olmalı: "ya" + "malak" → "yamalak" (yarım yamalak). Türkçede
    // "ya", "be" ile BAŞLAYAN kelime çoktur; bu ikisiyle BİTEN kelime azdır.
    final leftGlues = _leftGlueByFirst[text.codeUnitAt(0)];
    if (leftGlues != null) {
      for (final glue in leftGlues) {
        if (text.length - glue.length < 3 ||
            !text.startsWith(glue) ||
            !_mayStartEntry(text, glue.length)) {
          continue;
        }
        final entry = _compoundEntry(text.substring(glue.length));
        if (entry != null && _glueFits(entry, glue)) {
          return (from: glue.length, to: text.length, entry: entry);
        }
      }
    }

    // Soldaki parça bir girdi olacaksa token bir kökle başlamalı.
    if (!_mayStartEntry(text, 0)) return null;

    // 2. Girdi + yapıştırıcı: "siktirgit", "piçkurusu".
    final rightGlues = _rightGlueByLast[text.codeUnitAt(text.length - 1)];
    if (rightGlues != null) {
      for (final glue in rightGlues) {
        final split = text.length - glue.length;
        if (split < 3 || !text.endsWith(glue)) continue;
        final entry = _compoundEntry(text.substring(0, split));
        if (entry != null && _glueFits(entry, glue)) {
          return (from: 0, to: split, entry: entry);
        }
      }
    }

    // 3. Girdi + girdi: "siktiriboktan". Kısa kökler bu kuruluşa giremez.
    for (var split = 4; split <= text.length - 4; split++) {
      if (!_mayStartEntry(text, split)) continue;
      final leftEntry = _compoundEntry(text.substring(0, split));
      if (leftEntry == null || _shortRoots.contains(leftEntry)) continue;
      final rightEntry = _compoundEntry(text.substring(split));
      if (rightEntry == null || _shortRoots.contains(rightEntry)) continue;
      return rightEntry.severity > leftEntry.severity
          ? (from: split, to: text.length, entry: rightEntry)
          : (from: 0, to: split, entry: leftEntry);
    }
    return null;
  }

  /// [text] içinde [at] konumundan başlayan parça bir sözlük girdisine
  /// bağlanabilir mi? Kopya üretmeyen ucuz ön eleme: parça, ilk harf
  /// kovasındaki bir kökle (ya da yumuşamış hâliyle) başlamalıdır —
  /// `TurkishMorphology.isValidInflectedForm` bunu zaten şart koşar.
  /// Bitişik öbekler ("amınakoyim") `_despacedPhrases` üzerinden ayrıca aranır.
  bool _mayStartEntry(String text, int at) {
    if (at >= text.length) return false;
    final first = text.codeUnitAt(at);
    if (_bucketStartsAt(_prefixByFirst[first], text, at) ||
        _bucketStartsAt(_inflectableExactByFirst[first], text, at)) {
      return true;
    }
    final literals = _literalsByFirst[first];
    if (literals != null) {
      for (final literal in literals) {
        if (text.startsWith(literal, at)) return true;
      }
    }
    return false;
  }

  static bool _bucketStartsAt(List<_StemCandidate>? bucket, String text, int at) {
    if (bucket == null) return false;
    for (final c in bucket) {
      if (text.startsWith(c.normalized, at) ||
          (c.softened != null && text.startsWith(c.softened!, at))) {
        return true;
      }
    }
    return false;
  }

  /// Birleşik yazımın bir parçası olabilecek girdi.
  ///
  /// Yönelim şartlı girdiler ("mal", "köpek") ve harf kanıtı isteyen
  /// kısaltmalar ("aq") parça olamaz; kısa köklerden yalnızca küfür
  /// girdileri ("piç", "göt", "amk") kabul edilir.
  LexiconEntry? _compoundEntry(String part) {
    if (part.length < 3 || _isMasked(part)) return null;
    final entry = _lookup(part) ?? _despacedPhrases[part];
    if (entry == null || entry.requiresDirection) return null;
    if (_surfaceLetterEvidence.containsKey(entry.term)) return null;
    if (_shortRoots.contains(entry) &&
        (entry.category != ToxicityCategory.kufur ||
            ToxicityLexicon.shortRootCollisions.contains(part))) {
      return null;
    }
    return entry;
  }

  /// Kısa kök ancak en az üç harfli bir yapıştırıcıyla birleşebilir:
  /// "piç" + "o" → "pico" (özel ad) · "piç" + "kurusu" → küfür.
  bool _glueFits(LexiconEntry entry, String glue) =>
      !_shortRoots.contains(entry) || glue.length >= 3;

  /// Yalnızca a–z harflerinden oluşan token. Rakam, '@', emoji artığı ya da
  /// URL parçası taşıyan token'lar bölünmez.
  static bool _isPlainWord(String text) {
    for (var k = 0; k < text.length; k++) {
      final c = text.codeUnitAt(k);
      if (c < 0x61 || c > 0x7A) return false;
    }
    return true;
  }

  /// Token listesinin başındaki gerçek token sayısı; sonrası kaçınma
  /// birleştirmesinin eklediği sanal token'lardır (`_withEvasionTokens`).
  static int _baseTokenCount(List<Token> tokens) {
    var n = 0;
    while (n < tokens.length && tokens[n].position == n) {
      n++;
    }
    return n;
  }

  /// İki komşu token arasında özgün metinde YALNIZCA tek bir '!' mi duruyor?
  /// Her token çiftinde çalıştığı için alt dizgi üretmeden bakar.
  static bool _isBangGap(NormalizedText normalized, Token left, Token right) {
    final indices = normalized.sourceIndices;
    if (left.end < 1 ||
        left.end - 1 >= indices.length ||
        right.start >= indices.length) {
      return false;
    }
    final from = indices[left.end - 1] + 1;
    return indices[right.start] - from == 1 &&
        normalized.original.codeUnitAt(from) == 0x21; // '!'
  }

  /// Bitişik yazılmış çekimli öbek: token uzun bir öbeğin boşluksuz hâliyle
  /// başlıyorsa o öbek. Gerekçe: `_despacedPrefixes`.
  LexiconEntry? _despacedPrefix(String text) {
    if (text.isEmpty) return null;
    final bucket = _despacedPrefixByFirst[text.codeUnitAt(0)];
    if (bucket == null) return null;
    for (final p in bucket) {
      if (text.length > p.despaced.length && text.startsWith(p.despaced)) {
        return p.entry;
      }
    }
    return null;
  }

  /// Uzatma ikililerini teke indirir; değişiklik yoksa null.
  ///
  /// Ünlü ikilisi her konumda indirilir ("aptaal", "gerizekaali"): Türkçe
  /// kelimelerde ünlü ikilisi yalnızca birkaç alıntıda geçer ("saat",
  /// "kanaat") ve onların teklisi sözlükte değildir. ÜNSÜZ ikilisi yalnızca
  /// kelime SONUNDA indirilir ("amkk", "salakk"): kelime içi ünsüz ikilisi
  /// Türkçenin olağan yapısıdır ve teke indirmek başka bir kelime üretir —
  /// kelime listesi taramasında "yıllanma" → "yılanma", "şallak" → "salak".
  static String? _dedouble(String text) {
    if (text.length < 3) return null;
    var any = false;
    for (var k = 1; k < text.length && !any; k++) {
      any = _collapsesAt(text, k);
    }
    if (!any) return null; // gündelik token'da kopya üretme

    final buffer = StringBuffer();
    for (var k = 0; k < text.length; k++) {
      if (k > 0 && _collapsesAt(text, k)) continue;
      buffer.writeCharCode(text.codeUnitAt(k));
    }
    return buffer.toString();
  }

  static bool _collapsesAt(String text, int k) {
    final c = text.codeUnitAt(k);
    return c == text.codeUnitAt(k - 1) &&
        (_vowelCodes.contains(c) || k == text.length - 1);
  }

  static const Set<int> _vowelCodes = {0x61, 0x65, 0x69, 0x6F, 0x75}; // a e i o u

  /// Kelime içi ikilileri de teke indirerek sözlükte arar (docs/32).
  ///
  /// [forms] token'ın normalize biçimleridir (temkinli, agresif ve varsa
  /// uzatma kuyruğu atılmış hâlleri). Her biri için iki aday denenir:
  ///   • bütün ikilileri indirilmiş biçim     "sikerriimm"  → "sikerim"
  ///   • ikiliden sonra düşen tek harf atılmış "sikerriimmo" → "sikerim"
  ///
  /// Kuyruk yalnızca bir İKİLİNİN hemen ardındaysa atılır: tuş basılı
  /// tutulurken ikinci harfle birlikte bir sonraki tuş da düşer. Kuyruklu
  /// bir biçimin yakalanması için kökün en az dört harf olması gerekir.
  ///
  /// Kısa kökler (D1) bu yoldan eşleşemez; tek istisna, kökün Türkçeye özgü
  /// harfinin ("piç" → ç) özgün metinde fiilen yazılmış olmasıdır: "piiç",
  /// "piçç". ASCII "mall" (AVM) ya da "itt" bu yüzden hiçbir şey tetiklemez.
  ///
  /// [direct] biçimleri ikilileri indirilmeden de denenir: özgün metindeki
  /// 3+ tekrarın ikiye indirildiği hâller ("namusssuz" → "namussuz").
  LexiconEntry? _squeezeLookup(
      NormalizedText normalized, Token token, Set<String> forms,
      {Set<String> direct = const {}}) {
    LexiconEntry? accept(String form, String written, {required bool tail}) {
      if (form.length < (tail ? 4 : 3) ||
          _isMasked(form) ||
          ToxicityLexicon.shortRootCollisions.contains(form)) {
        return null;
      }
      final candidate = _lookup(form) ??
          _squeezedEntryFor(form, written) ??
          _despacedPhrases[form] ??
          (tail ? null : _despacedPrefix(form));
      if (candidate == null) return null;
      // Yönelim şartlı girdiler gündelik kelimelerdir ("yılan", "eşek");
      // belirsiz bir kelimenin üstüne belirsiz bir gizleme kanıtı yığılmaz.
      // Kelime listesinde: "sen yıllanma" → yılan ✗.
      if (candidate.requiresDirection) return null;
      if (_shortRoots.contains(candidate) &&
          candidate.matchMode != MatchMode.verbatim &&
          (tail || !_writesTurkishLetterOf(normalized, token, candidate))) {
        return null;
      }
      if (_squeezedSpellingContradicts(normalized, token, candidate)) {
        return null;
      }
      return candidate;
    }

    for (final form in forms) {
      if (direct.contains(form)) {
        final hit = accept(form, form, tail: false);
        if (hit != null) return hit;
      }
      final squeezed = _squeeze(form);
      if (squeezed == null) continue;
      final hit = accept(squeezed, form, tail: false);
      if (hit != null) return hit;
      final n = form.length;
      if (n >= 4 &&
          form.codeUnitAt(n - 2) == form.codeUnitAt(n - 3) &&
          form.codeUnitAt(n - 1) != form.codeUnitAt(n - 2)) {
        final cut = accept(squeezed.substring(0, squeezed.length - 1),
            form.substring(0, n - 1),
            tail: true);
        if (cut != null) return cut;
      }
    }
    return null;
  }

  /// Yazılışında zaten ikili taşıyan girdiler ("namussuz", "dallama",
  /// "deyyus"): ikilileri indirilmiş token, girdinin de indirilmiş hâliyle
  /// karşılaştırılır. Aksi hâlde "namusssuz" → "namusuz" hiçbir girdiye
  /// denk gelmez.
  ///
  /// [written] ikilileri indirilmemiş biçimdir ve girdinin kendi ikilisini
  /// ("ss", "ll") fiilen taşımalıdır. Yoksa eşleşme, ikilisi indirilmiş
  /// girdinin denk geldiği BAŞKA bir kelimeye kayar — kelime listesinde:
  /// "Şiilik" → "silik" = "şıllık"ın indirilmiş hâli ✗.
  LexiconEntry? _squeezedEntryFor(String squeezed, String written) {
    for (final s in _squeezedEntries) {
      if (squeezed.startsWith(s.squeezed) &&
          s.pairs.any(written.contains) &&
          TurkishMorphology.isValidInflectedForm(squeezed, s.squeezed,
              stemSpelling: s.entry.term)) {
        return s.entry;
      }
    }
    return null;
  }

  /// Bütün ardışık ikilileri teke indirir; ikili yoksa null.
  static String? _squeeze(String text) {
    var any = false;
    for (var k = 1; k < text.length && !any; k++) {
      any = text.codeUnitAt(k) == text.codeUnitAt(k - 1);
    }
    if (!any) return null;
    final buffer = StringBuffer();
    for (var k = 0; k < text.length; k++) {
      if (k > 0 && text.codeUnitAt(k) == text.codeUnitAt(k - 1)) continue;
      buffer.writeCharCode(text.codeUnitAt(k));
    }
    return buffer.toString();
  }

  /// Kökün Türkçeye özgü harflerinden biri (ç ğ ı ö ş ü) token'ın özgün
  /// yazılışında geçiyor mu? Kısa kökün ikileme yoluyla eşleşmesi için
  /// kanıttır: "piiç" yazan kişi "pic" ile başlayan bir yabancı kelime
  /// yazmıyordur.
  bool _writesTurkishLetterOf(
      NormalizedText normalized, Token token, LexiconEntry entry) {
    if (token.end - token.start != token.text.length) return false;
    final spelling = TurkishMorphology.toLowerTr(entry.term);
    final range = normalized.toOriginalRange(token.start, token.end);
    final raw = TurkishMorphology.toLowerTr(
        normalized.original.substring(range.start, range.end));
    for (final letter in _turkishOnlyLetters.split('')) {
      if (spelling.contains(letter) && raw.contains(letter)) return true;
    }
    return false;
  }

  /// İkilileri indirilmiş özgün yazılış, kökün Türkçe yazılışıyla çelişiyor
  /// mu? `_surfaceContradictsRoot`'un ikileme yolundaki karşılığı: orada
  /// konumlar birebir hizalıdır, burada ikisi de indirildikten sonra
  /// hizalanır. Kelime listesinde: "şallak" → salak ✗ ("ş" yazılmış).
  ///
  /// Noktasız "ı" kanıt sayılmaz: "sıkerriim" bir çelişki değil, gizleme
  /// denemesidir (gerekçe: `ToxicityLexicon.spellingSensitiveTerms`).
  bool _squeezedSpellingContradicts(
      NormalizedText normalized, Token token, LexiconEntry entry) {
    if (token.end - token.start != token.text.length) return false;
    final spelling = TurkishMorphology.toLowerTr(entry.term);
    if (spelling.contains(' ')) return false;
    final range = normalized.toOriginalRange(token.start, token.end);
    final raw = TurkishMorphology.toLowerTr(
        normalized.original.substring(range.start, range.end));
    final written = _squeeze(raw) ?? raw;
    final n = written.length < spelling.length ? written.length : spelling.length;
    for (var k = 0; k < n; k++) {
      final w = written[k];
      final e = spelling[k];
      if (w == e || w == 'ı' || !_turkishOnlyLetters.contains(w)) continue;
      if (k == spelling.length - 1 && e == 'k' && w == 'ğ') continue;
      return true;
    }
    return false;
  }

  /// Özgün yazılıştaki 3+ tekrarlar İKİYE indirilerek normalize edilmiş
  /// biçimler; 3+ tekrar yoksa null.
  ///
  /// Normalizasyon 3+ tekrarı TEK harfe indirir ("çoookk" → "cok") ve bu,
  /// yazılışında ikili taşıyan girdilerin uzatılmış hâlini siler:
  /// "namusssuz" → "namusuz", "zavalllı" → "zavali", "sikkko" → "siko".
  Set<String>? _cappedElongationForms(NormalizedText normalized, Token token) {
    if (token.end - token.start != token.text.length) return null;
    final range = normalized.toOriginalRange(token.start, token.end);
    final raw = normalized.original.substring(range.start, range.end);
    final out = StringBuffer();
    var capped = false;
    var run = 0;
    for (var k = 0; k < raw.length; k++) {
      final c = raw.codeUnitAt(k);
      run = (k > 0 &&
              TurkishNormalizer.sameIgnoringCaseCode(c, raw.codeUnitAt(k - 1)))
          ? run + 1
          : 1;
      if (run > 2) {
        capped = true;
        continue;
      }
      out.writeCharCode(c);
    }
    if (!capped) return null;
    final n = _normalizer.normalize(out.toString());
    if (n.value.isEmpty || n.value.contains(' ')) return null;
    return {n.value, n.aggressive};
  }

  /// Token'da ardışık iki özdeş karakter var mı? Kopya üretmez.
  static bool _hasDouble(String text) {
    for (var k = 1; k < text.length; k++) {
      if (text.codeUnitAt(k) == text.codeUnitAt(k - 1)) return true;
    }
    return false;
  }

  /// Token'ın özgün metinde kapladığı aralık, normalize uzunluğundan uzun
  /// mu? Değilse normalizasyon hiçbir karakter silmemiştir ve 3+ tekrar da
  /// yoktur. Kopya üretmez.
  static bool _originalLonger(NormalizedText normalized, Token token) {
    final indices = normalized.sourceIndices;
    if (token.end - token.start != token.text.length ||
        token.end > indices.length) {
      return false;
    }
    return indices[token.end - 1] - indices[token.start] + 1 >
        token.text.length;
  }

  /// Uzatma kuyruğu atılmış token'ın normalize biçimleri. Kuyruk yoksa `null`.
  ///
  /// Kuyruk, ÖZGÜN metinde 3+ tekrarlı bir dizinin hemen ardından gelen en
  /// fazla iki karakterdir ("sikerim**mmmm**·o"). Ölçüm normalize metinde
  /// değil özgün metinde yapılır, çünkü normalizasyon uzatmayı zaten
  /// daraltmış olur ve kanıt kaybolur.
  ({String value, String aggressive})? _stripElongationTail(
      NormalizedText normalized, Token token) {
    // Birleştirilmiş sanal token'ın ("a m k") harfleri özgün metinde bitişik
    // değildir; aralık tek bir kelimeye denk düşmez.
    if (token.end - token.start != token.text.length) return null;

    final range = normalized.toOriginalRange(token.start, token.end);
    if (range.end - range.start < 4) return null;
    final raw = normalized.original.substring(range.start, range.end);

    final trimmed = _elongationStem(raw);
    if (trimmed == null) return null;

    final n = _normalizer.normalize(trimmed);
    // Kuyruk atıldıktan sonra geriye tek bir kelime kalmalı.
    if (n.value.isEmpty || n.value.contains(' ')) return null;
    return (value: n.value, aggressive: n.aggressive);
  }

  /// [raw] bir uzatma + kuyruk ile bitiyorsa kuyruksuz hâlini döndürür.
  ///
  /// Kuyruk 1 veya 2 karakterdir ve kendisi boşluk içeremez. Hemen öncesinde
  /// büyük/küçük harf farkı gözetmeden 3 özdeş karakter bulunmalıdır —
  /// yani kullanıcı tuşu gerçekten basılı tutmuş olmalıdır.
  static String? _elongationStem(String raw) {
    final n = raw.length;
    for (var tail = 1; tail <= 2; tail++) {
      final cut = n - tail; // kuyruğun başladığı (dizinin bittiği) konum
      if (cut < 3) break;

      final c = raw.codeUnitAt(cut - 1);
      if (!TurkishNormalizer.sameIgnoringCaseCode(c, raw.codeUnitAt(cut - 2)) ||
          !TurkishNormalizer.sameIgnoringCaseCode(c, raw.codeUnitAt(cut - 3))) {
        continue;
      }

      var tailHasSpace = false;
      for (var k = cut; k < n; k++) {
        if (raw.codeUnitAt(k) == 0x20) {
          tailHasSpace = true;
          break;
        }
      }
      if (tailHasSpace) continue;

      return raw.substring(0, cut);
    }
    return null;
  }

  /// Öz-yönelim yumuşatması bu girdiye uygulanır mı?
  ///
  /// ── AĞIR KÜFÜR ÖZ-İFADE DEĞİLDİR (docs/25) ─────────────────────────────
  /// Öz-yönelim, birinci şahıs ekini "konuşan kendinden bahsediyor" diye
  /// okur: "kendimi aptal hissettim", "aptalım galiba". Oysa en ağır
  /// küfürlerin SÖZLÜK BİÇİMİ zaten birinci şahıs çekimlidir. Ölçülen sonuç:
  ///
  ///   "sikerim" · "sikeyim" · "SİKERİM" · "s i k e r i m" → Temiz (0.00) ✗
  ///   "amk ben yoruldum" ("ben" yakında)                  → Temiz ✗
  ///   "bacını sikerim" · "yarrağım"                        → Temiz ✗
  ///
  /// Tehdit için aynı ilke zaten vardı ("öldürürüm"). Eşik 0.85: sözlükte
  /// yalnızca müstehcen küfürler bu şiddettedir. "götüm donuyor" (0.70),
  /// "boktan bir gündü" (0.65) gibi hafif argo öz-ifade olarak yumuşamaya
  /// devam eder. Alıntı ve olumsuzlama yumuşatmaları etkilenmez: tacize
  /// uğrayanın anlatısı ("bana 'sikerim' dedi") hâlâ korunur.
  static bool _selfDirectionApplies(LexiconEntry entry) =>
      entry.category != ToxicityCategory.tehdit && !_isObscene(entry);

  /// Müstehcen küfür: öz-yönelim ve olumsuzlama onu yumuşatmaz (docs/25).
  /// "sikimde değil", "amk değil mi" — olumsuzlanan küfür değil, deyimdir.
  static bool _isObscene(LexiconEntry entry) =>
      entry.category == ToxicityCategory.kufur &&
      entry.severity >= _obsceneSeverity;

  static const double _obsceneSeverity = 0.85;

  /// Token'ın özgün yazılışı, girdinin yönelim şartını kaldıran bir biçimle
  /// mi başlıyor? Gerekçe: `ToxicityLexicon.surfaceConfirmedForms`.
  bool _surfaceConfirms(NormalizedText normalized, Token token, LexiconEntry entry) {
    final forms = ToxicityLexicon.surfaceConfirmedForms[entry.term];
    if (forms == null || token.end - token.start != token.text.length) {
      return false;
    }
    for (final form in forms) {
      if (token.text.length < form.length) continue;
      var ok = true;
      for (var k = 0; k < form.length; k++) {
        final j = token.start + k;
        if (j >= normalized.sourceIndices.length) return false;
        final raw = normalized.original[normalized.sourceIndices[j]];
        // 'I' → 'i': büyük I belirsizdir ve 'ı' ile eşleşmez.
        final written = raw == 'İ' ? 'i' : raw.toLowerCase();
        if (written != form[k]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  /// Bulgu nesnesini kurar; bağlam kuralları elerse null döner.
  ToxicityFinding? _buildFinding({
    required String term,
    required ToxicityCategory category,
    required double severity,
    required bool requiresDirection,
    required String originalText,
    required ({int start, int end}) originalRange,
    required MatchContext context,
    FindingSource source = FindingSource.sozluk,
    String? neutralAlternative,
    ImplicitFamily? implicitFamily,
  }) {
    // Yönelim şartı olan terimler (hayvan adları, çokanlamlılar) yalnızca
    // ikinci şahsa yöneltildiğinde saldırgandır. "Köpeğim hasta" elenir.
    if (requiresDirection && !context.isDirected) return null;

    var adjusted = (severity * context.multiplier).clamp(0.0, 1.0);

    // ── YUMUŞATMA TAVANI ────────────────────────────────────────────────────
    // Çarpan tek başına yetmez: yüksek taban şiddetli bir terim
    // ("şerefsiz" = 0.88), alıntı çarpanından (×0.20) sonra bile 0.176'da
    // kalır ve eşiği aşar. Sonuç: tacize UĞRAYAN kişi, olayı anlatırken
    // uyarı alır — ürünün önlemek için var olduğu tam da budur.
    //
    // Bu yüzden yumuşatıcı bağlamlarda sonuç bir TAVANLA sınırlanır.
    // Böylece kural taban şiddetten bağımsız olarak geçerlidir.
    if (context.isNegated || context.isQuoted || context.isSelfDirected) {
      adjusted = adjusted.clamp(0.0, _softeningCeiling);
    }

    // Bağlam katmanı şiddeti eşiğin altına düşürdüyse bulgu üretme.
    // Örn. "aptal değilsin" → 0.55 × 0.15 = 0.08 → elenir.
    if (adjusted < _eliminationThreshold) return null;

    final safeStart = originalRange.start.clamp(0, originalText.length);
    final safeEnd = originalRange.end.clamp(safeStart, originalText.length);

    // Katlanan harfe dayanan girdi, o harf yazılmadıysa eşleşmiş sayılmaz
    // ("ak" ≠ "aq"). Gerekçe: `_surfaceLetterEvidence`. Kontrol burada,
    // TEK noktada yapılır; token, öbek ve birleştirme yollarının üçü de
    // buradan geçer.
    final evidence =
        source == FindingSource.sozluk ? _surfaceLetterEvidence[term] : null;
    if (evidence != null) {
      final span = originalText.substring(safeStart, safeEnd).toLowerCase();
      if (!evidence.every(span.contains)) return null;
    }

    return ToxicityFinding(
      matchedText: originalText.substring(safeStart, safeEnd),
      term: term,
      category: category,
      baseSeverity: severity,
      adjustedSeverity: adjusted,
      context: context,
      start: safeStart,
      end: safeEnd,
      source: source,
      neutralAlternative: neutralAlternative,
      implicitFamily: implicitFamily,
    );
  }

  // NOT. Burada bir `_copulaSuffixes` alanı vardı ve hiçbir yerden
  // okunmuyordu: ikinci şahıs bildirme eki bilgisi `TurkishMorphology` ile
  // `ContextAnalyzer` içine taşındığında bu kopya geride kalmıştı. İki ayrı
  // yerde duran bir "doğruluk kaynağı" er ya da geç birbirinden ayrılır;
  // ölü olanı silmek, sonradan yanlışlıkla canlandırılmasından ucuzdur.

  /// Yumuşatıcı bağlamda ulaşılabilecek en yüksek şiddet.
  /// Eleme eşiğinin altındadır — yani yumuşatma daima elemeyle sonuçlanır.
  static const double _softeningCeiling = 0.10;

  /// Bu değerin altındaki bulgular kullanıcıya hiç gösterilmez.
  static const double _eliminationThreshold = 0.12;

  // ─── Yardımcılar ──────────────────────────────────────────────────────────

  /// Tek bir token'ı sözlükte arar: önce tam eşleşme, sonra kök eşleşmesi.
  ///
  /// Tam eşleşme önceliklidir çünkü daha kesindir ve çokanlamlı kısa
  /// terimler ("mal", "it", "adi") yalnızca bu yolla tetiklenebilir.
  LexiconEntry? _lookup(String text) {
    // 0. Birebir tam eşleşme (en yüksek kesinlik).
    final exact = _exactEntries[text];
    if (exact != null) return exact;

    if (fastLookup) return _lookupIndexed(text);

    // 1. Kök eşleşmesi: Önce prefix (ön ek) girdilerini dene.
    // Prefix girdileri uzundan kısaya sıralıdır; bu sayede "siktir" (6 harf)
    // "sik" (3 harf, exact) girdisinden ÖNCE bulunur. Bu kritiktir:
    // "siktir" sözlükte ayrı bir girdi olarak varken, "sik+tir" morfolojik
    // parçalaması istenmeyen bir requiresDirection kontrolü tetikler.
    //
    // Örn: "aptal" -> "aptalsın", "aptallar", "aptallığa" (geçerli)
    // "salak" -> "salağım" (yumuşama ile geçerli)
    // "amaç" -> "am" + "aç" (geçersiz ek dizilimi -> reddedilir)
    // "malzeme" -> "mal" + "zeme" (geçersiz ek -> reddedilir)
    for (final candidate in _prefixEntries) {
      final isVerbal = candidate.entry.category == ToxicityCategory.tehdit ||
          candidate.entry.term.endsWith('mek') ||
          candidate.entry.term.endsWith('mak');
      if (TurkishMorphology.isValidInflectedForm(text, candidate.normalized,
          isVerbal: isVerbal, stemSpelling: candidate.entry.term)) {
        return candidate.entry;
      }
    }

    // 2. Kısa exact-mode kökler için morfolojik çekim kontrolü.
    // Bu aşama prefix'lerde bulunamazsa devreye girer.
    // ("mal" -> "malsın", "am" -> "amına", "bok" -> "boktan")
    // Birebir kipteki kısaltmalar çekime girmez (bkz. `MatchMode.verbatim`).
    for (final exact in _exactEntries.entries) {
      if (exact.value.matchMode == MatchMode.verbatim) continue;
      if (TurkishMorphology.isValidInflectedForm(text, exact.key,
          stemSpelling: exact.value.term)) {
        return exact.value;
      }
    }

    return null;
  }

  /// `_lookup`'ın 1. ve 2. adımı, ilk harf kovalarıyla. Sonucu kovasız
  /// yolla birebir aynıdır; gerekçe `_prefixByFirst` alanında.
  LexiconEntry? _lookupIndexed(String text) {
    if (text.isEmpty) return null;
    final first = text.codeUnitAt(0);

    final prefixes = _prefixByFirst[first];
    if (prefixes != null) {
      for (final c in prefixes) {
        if (c.canStart(text) &&
            TurkishMorphology.isValidInflectedForm(text, c.normalized,
                isVerbal: c.isVerbal, stemSpelling: c.entry.term)) {
          return c.entry;
        }
      }
    }

    final exacts = _inflectableExactByFirst[first];
    if (exacts != null) {
      for (final c in exacts) {
        if (c.canStart(text) &&
            TurkishMorphology.isValidInflectedForm(text, c.normalized,
                stemSpelling: c.entry.term)) {
          return c.entry;
        }
      }
    }

    return null;
  }

  /// Kökün yazılışı, özgün metinde fiilen yazılan harflerle çelişiyor mu? (D1)
  ///
  /// Normalizasyon Türkçe harfleri katlar: "sıkı" ve "siki" aynı dizgiye
  /// iner. Ama kullanıcı "ı" YAZDIYSA, noktalı "i" taşıyan "sik" kökünü
  /// kastetmemiştir. Katlama kanıtı siler; bu yöntem onu özgün metinden
  /// geri okur (`_surfaceLetterEvidence` ile aynı fikir, ters yönde).
  ///
  /// Kanıt yalnızca TÜRKÇEYE ÖZGÜ bir harftir. ASCII yazan (Türkçe klavyesi
  /// olmayan) kullanıcı hiçbir şeyle çelişmez; büyük "I" ise hem "ı" hem "i"
  /// için yazılır ve belirsiz sayılır. Kökün son harfindeki k→ğ, Türkçe
  /// ünsüz yumuşamasıdır ("salağım") ve çelişki değildir.
  bool _surfaceContradictsRoot(
      NormalizedText normalized, Token token, LexiconEntry entry) {
    final root = _shortRootSpelling[entry];
    if (root == null) return false;
    // Birleştirilmiş sanal token'ların harfleri özgün metinde bitişik değildir.
    if (token.end - token.start != token.text.length) return false;

    for (var k = 0; k < root.length; k++) {
      final j = token.start + k;
      if (j >= normalized.sourceIndices.length) return false;
      final raw = normalized.original[normalized.sourceIndices[j]];
      if (raw == 'I') continue;
      final written = raw == 'İ' ? 'i' : raw.toLowerCase();
      final expected = root[k];
      if (written == expected || !_turkishOnlyLetters.contains(written)) {
        continue;
      }
      if (k == root.length - 1 && expected == 'k' && written == 'ğ') continue;
      return true;
    }
    return false;
  }

  static const String _turkishOnlyLetters = 'ığşçöü';

  /// Dönüşlü nesne: fiilin hedefi konuşanın kendisidir (D10).
  static const Set<String> _reflexiveObjects = {'kendimi', 'kendimizi'};

  /// Başkasına yönelik nesneler. Dönüşlü nesneyle birlikte geçerlerse
  /// ("seni ve kendimi öldüreceğim") cümle tehdit olmayı sürdürür.
  static const Set<String> _otherObjects = {
    'seni', 'sizi', 'onu', 'onlari', 'hepinizi', 'herkesi', 'aileni',
  };

  /// [index] konumundaki fiilin nesnesi yalnızca konuşanın kendisi mi?
  ///
  /// Nesne fiilden hemen önce ya da araya tek bir zarf girmiş hâlde durur:
  /// "kendimi öldüreceğim", "kendimi gerçekten öldüreceğim".
  bool _hasReflexiveObject(List<Token> tokens, int index) {
    var reflexive = false;
    for (var k = index - 1; k >= 0 && k >= index - 3; k--) {
      final text = tokens[k].text;
      if (_otherObjects.contains(text)) return false;
      if (k >= index - 2 && _reflexiveObjects.contains(text)) reflexive = true;
    }
    return reflexive;
  }

  /// Token meşru bir kelimenin başlangıcı mı?
  bool _isMasked(String token) {
    if (fastLookup) {
      if (token.isEmpty) return false;
      final bucket = _maskedByFirst[token.codeUnitAt(0)];
      if (bucket == null) return false;
      for (final masked in bucket) {
        if (token.startsWith(masked)) return true;
      }
      return false;
    }
    for (final masked in _maskedPrefixes) {
      if (token.startsWith(masked)) return true;
    }
    return false;
  }

  /// Harf-arası-boşluk hilesi için birleşik sanal token üretir.
  ///
  /// "b u a m k" → tek harfli 5 token → birleşik "buamk" token'ı eklenir.
  /// Orijinal token'lar da listede kalır; birleşik olan ek bir aday olur.
  List<Token> _withEvasionTokens(List<Token> tokens) {
    final result = List<Token>.from(tokens);

    int i = 0;
    while (i < tokens.length) {
      if (tokens[i].length != 1) {
        i++;
        continue;
      }

      int run = 0;
      while (i + run < tokens.length && tokens[i + run].length == 1) {
        run++;
      }

      // Üç veya daha fazla ardışık tek harf → kasıtlı gizleme kabul edilir.
      if (run >= 3) {
        final merged = tokens.sublist(i, i + run).map((t) => t.text).join();
        result.add(Token(
          text: merged,
          start: tokens[i].start,
          end: tokens[i + run - 1].end,
          position: tokens[i].position,
        ));
      }

      i += run;
    }

    return result;
  }

  /// Normalize metindeki karakter indeksini içeren token'ın sırasını bulur.
  int _tokenIndexAt(List<Token> tokens, int charIndex) {
    for (int i = 0; i < tokens.length; i++) {
      if (charIndex >= tokens[i].start && charIndex < tokens[i].end) return i;
    }
    return 0;
  }

  /// Çok kelimeli bir eşleşmenin bittiği token'ın sırasını bulur.
  ///
  /// Aralık İKİ UÇTAN sınırlanır: sanal (birleştirilmiş) kaçınma token'ları
  /// listenin sonuna eklenir ve konumları metnin başına işaret edebilir.
  /// Yalnızca üst sınır kullanılsaydı, böyle bir token eşleşme aralığını
  /// metnin tamamına yayar ve bağlam taraması tamamen körelirdi.
  int _tokenIndexEndAt(
    List<Token> tokens,
    int charStart,
    int charEnd,
    int fallback,
  ) {
    var result = fallback;
    for (int i = fallback + 1; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.start >= charStart && token.start < charEnd) result = i;
    }
    return result;
  }

  /// Çakışan bulgulardan en şiddetlisini tutar.
  ///
  /// Gerekli çünkü "kapa çeneni" hem öbek hem de tek tek token olarak
  /// eşleşebilir; kullanıcıya aynı yer iki kez işaretlenmemeli.
  List<ToxicityFinding> _deduplicate(List<ToxicityFinding> findings) {
    if (findings.length < 2) return findings;

    final sorted = List<ToxicityFinding>.from(findings)
      ..sort((a, b) => b.adjustedSeverity.compareTo(a.adjustedSeverity));

    final kept = <ToxicityFinding>[];

    for (final candidate in sorted) {
      final overlaps = kept.any(
        (k) => candidate.start < k.end && candidate.end > k.start,
      );
      if (!overlaps) kept.add(candidate);
    }

    return kept;
  }

  /// Birden fazla bulgunun şiddetini tek skora indirger.
  ///
  /// YÖNTEM — Noisy-OR:  toplam = 1 − Π(1 − sᵢ)
  ///
  /// Neden toplama değil: iki hakaret 0.6 + 0.6 = 1.2 → taşar, anlamsız.
  /// Neden maksimum değil: "aptalsın ve şerefsizsin" tek hakaretten daha
  /// saldırgandır; maksimum bu farkı göremez.
  ///
  /// Noisy-OR her iki sorunu da çözer: sınırlıdır [0,1) ve birikimlidir.
  /// Olasılıksal bağımsızlık varsayımına dayanır — bu varsayım burada
  /// yaklaşıktır ama pratikte doğru sıralamayı üretir.
  double _combineSeverities(List<ToxicityFinding> findings) {
    if (findings.isEmpty) return 0.0;

    double complement = 1.0;
    for (final finding in findings) {
      complement *= (1.0 - finding.adjustedSeverity);
    }

    return (1.0 - complement).clamp(0.0, 1.0);
  }

  /// Skoru risk seviyesine çevirir.
  ///
  /// Eşikler, müdahale şiddetiyle hizalıdır: kullanıcıyı gereksiz yere
  /// rahatsız etmemek için "dikkat" seviyesinde hiçbir kesinti yapılmaz.
  RiskLevel _riskFrom(double toxicity) {
    if (toxicity < 0.15) return RiskLevel.temiz;
    if (toxicity < 0.40) return RiskLevel.dikkat;
    if (toxicity < 0.70) return RiskLevel.riskli;
    return RiskLevel.yuksek;
  }
}

/// İlk harf kovasındaki tek aday. Kurulumda bir kez hesaplanır.
class _StemCandidate {
  _StemCandidate(this.normalized, this.entry, {required this.isVerbal})
      : softened = TurkishMorphology.softenNormalizedStem(normalized);

  final String normalized;

  /// `TurkishMorphology.softenNormalizedStem` sonucu; yumuşamayan kökte null.
  final String? softened;

  final LexiconEntry entry;
  final bool isVerbal;

  /// Token bu köke bağlanabilir mi? `isValidInflectedForm`'un iki dalı da
  /// token'ın kökle ya da yumuşamış kökle başlamasını şart koşar; bu ucuz
  /// ön eleme, pahalı çağrıyı eşleşemeyecek adaylarda hiç yapmaz.
  bool canStart(String text) =>
      text.startsWith(normalized) ||
      (softened != null && text.startsWith(softened!));
}
