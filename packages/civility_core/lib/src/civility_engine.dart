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
import 'normalization/turkish_normalizer.dart';
import 'context/context_analyzer.dart';
import 'detect/implicit_detector.dart';
import 'detect/implicit_patterns.dart';

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

  const CivilityAnalysis({
    required this.text,
    required this.toxicity,
    required this.civilityScore,
    required this.risk,
    required this.findings,
    required this.signals,
    required this.elapsed,
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

  /// Normalize edilmiş maskeleme ön ekleri (yanlış pozitif engelleyici).
  final List<String> _maskedPrefixes = [];

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
  })  : _normalizer = normalizer,
        _tokenizer = tokenizer,
        _contextAnalyzer = contextAnalyzer,
        _implicitDetector = implicitDetector ?? ImplicitDetector() {
    _buildIndex();
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

      if (normalized.contains(' ')) {
        _phraseEntries.add((normalized: normalized, entry: entry));
      } else if (entry.matchMode == MatchMode.exact) {
        _exactEntries[normalized] = entry;
      } else {
        _prefixEntries.add((normalized: normalized, entry: entry));
      }
    }

    // Uzun kökler önce denenir: "gerizekali" > "geri"
    _prefixEntries.sort((a, b) => b.normalized.length.compareTo(a.normalized.length));
    _phraseEntries.sort((a, b) => b.normalized.length.compareTo(a.normalized.length));

    for (final masked in ToxicityLexicon.maskedPrefixes) {
      final normalized = _normalizer.normalize(masked).value;
      if (normalized.isNotEmpty) _maskedPrefixes.add(normalized);
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
    final signals = _contextAnalyzer.analyze(text, tokens);

    // ── 4. Eşleştirme ───────────────────────────────────────────────────────
    final findings = <ToxicityFinding>[];

    // 4a. Öbek eşleşmeleri (çok kelimeli)
    findings.addAll(_matchPhrases(normalized, tokens, signals));

    // 4b. Token eşleşmeleri (tek kelimeli)
    findings.addAll(_matchTokens(normalized, tokens, signals));

    // 4c. Edimbilimsel örüntüler — yasaklı kelime içermeyen saldırı.
    if (enableImplicitPatterns) {
      findings.addAll(_matchImplicit(normalized, tokens, signals));
    }

    // Aynı karakter aralığında birden fazla bulgu varsa en şiddetlisini tut.
    final deduped = _deduplicate(findings);
    deduped.sort((a, b) => b.adjustedSeverity.compareTo(a.adjustedSeverity));

    // ── 6. Skor birleştirme ─────────────────────────────────────────────────
    final toxicity = _combineSeverities(deduped);

    stopwatch.stop();

    return CivilityAnalysis(
      text: text,
      toxicity: toxicity,
      civilityScore: ((1.0 - toxicity) * 100).round().clamp(0, 100),
      risk: _riskFrom(toxicity),
      findings: deduped,
      signals: signals,
      elapsed: stopwatch.elapsed,
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

    for (final candidate in _phraseEntries) {
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
            selfDirectionApplies:
                candidate.entry.category != ToxicityCategory.tehdit,
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

      final matched = _lookup(token.text) ??
          (aggressiveText == token.text ? null : _lookup(aggressiveText));

      if (matched == null) continue;

      final originalRange = normalized.toOriginalRange(token.start, token.end);

      final context = _contextAnalyzer.evaluateMatch(
        tokens: tokens,
        matchIndex: i,
        originalRange: originalRange,
        signals: signals,
        // Tehdit birinci şahıs çekimlidir ("öldürürüm") ama öz-ifade
        // değildir. Bu ayrım olmadan her tehdit yumuşatılıp eleniyordu.
        selfDirectionApplies: matched.category != ToxicityCategory.tehdit,
      );

      final finding = _buildFinding(
        term: matched.term,
        category: matched.category,
        severity: matched.severity,
        requiresDirection: matched.requiresDirection,
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
  List<ToxicityFinding> _matchImplicit(
    NormalizedText normalized,
    List<Token> tokens,
    ContextSignals signals,
  ) {
    final results = <ToxicityFinding>[];

    for (final match in _implicitDetector.detect(normalized.value)) {
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

    return results;
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

  /// Tam eşleşmeli terimlerin kabul ettiği ikinci şahıs bildirme ekleri.
  /// Kapalı liste olması kasıtlıdır — açık uçlu bir kural bu terimleri
  /// yeniden yanlış pozitif kaynağına çevirirdi.
  static const List<String> _copulaSuffixes = ['siniz', 'sunuz', 'sin', 'sun'];

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
    final exact = _exactEntries[text];
    if (exact != null) return exact;

    // Tam eşleşmeli terim + ikinci şahıs bildirme eki: "mal" + "sın".
    //
    // Ölçüm bu açığı gösterdi: "sen tam bir malsın" hiç yakalanmıyordu,
    // çünkü "mal" çokanlamlı olduğu için tam eşleşmeye kilitlenmiş ve
    // "malsın" token'ı tam eşleşmiyordu. Kök eşleşmesine açmak "malzeme"yi
    // yanlış pozitif yapardı.
    //
    // Çözüm ikisinin arası: yalnızca KAPALI bir ek listesi kabul edilir.
    // "malsın" = mal + ikinci şahıs eki → hakaret.
    // "malzeme" = bu eklerin hiçbiriyle bitmez → masum.
    for (final suffix in _copulaSuffixes) {
      if (text.length > suffix.length + 2 && text.endsWith(suffix)) {
        final stem = text.substring(0, text.length - suffix.length);
        final stemEntry = _exactEntries[stem];
        if (stemEntry != null) return stemEntry;
      }
    }

    // Kök eşleşmesi: Türkçe eklemeli çekimleri yakalar.
    // "aptal" kökü → "aptalsın", "aptallar", "aptallığın" hepsini bulur.
    for (final candidate in _prefixEntries) {
      if (text.startsWith(candidate.normalized)) return candidate.entry;
    }

    return null;
  }

  /// Token meşru bir kelimenin başlangıcı mı?
  bool _isMasked(String token) {
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
