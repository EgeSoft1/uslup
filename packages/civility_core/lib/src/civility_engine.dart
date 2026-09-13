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

  /// Davranışsal biyometri (varsa) — Kullanıcının klavye vuruş hızı (ms) ve silme oranı.
  final double? typingSpeedMs;
  final double? backspaceRatio;

  const CivilityAnalysis({
    required this.text,
    required this.toxicity,
    required this.civilityScore,
    required this.risk,
    required this.findings,
    required this.signals,
    required this.elapsed,
    this.typingSpeedMs,
    this.backspaceRatio,
  });

  /// Boş/temiz metin için sonuç.
  factory CivilityAnalysis.clean(String text, ContextSignals signals, {double? typingSpeedMs, double? backspaceRatio}) {
    return CivilityAnalysis(
      text: text,
      toxicity: 0.0,
      civilityScore: 100,
      risk: RiskLevel.temiz,
      findings: const [],
      signals: signals,
      elapsed: Duration.zero,
      typingSpeedMs: typingSpeedMs,
      backspaceRatio: backspaceRatio,
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
  CivilityAnalysis analyze(String text, {double? typingSpeedMs, double? backspaceRatio});

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

      final folded = entry.term
          .toLowerCase()
          .split('')
          .where(_foldedLetters.contains)
          .toSet();
      if (folded.isNotEmpty) _surfaceLetterEvidence[entry.term] = folded;

      if (normalized.contains(' ')) {
        _phraseEntries.add((normalized: normalized, entry: entry));
        _despacedPhrases[normalized.replaceAll(' ', '')] = entry;
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

    for (final masked in ToxicityLexicon.maskedPrefixes) {
      final normalized = _normalizer.normalize(masked).value;
      if (normalized.isNotEmpty) _maskedPrefixes.add(normalized);
    }
  }

  @override
  CivilityAnalysis analyze(String text, {double? typingSpeedMs, double? backspaceRatio}) {
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

    // 4b2. Bölme/bitişik yazma kaçışları ("oros pu", "aminakoyim").
    findings.addAll(_matchEvasionJoins(normalized, tokens, signals));

    // 4c. Edimbilimsel örüntüler — yasaklı kelime içermeyen saldırı.
    if (enableImplicitPatterns) {
      findings.addAll(_matchImplicit(normalized, tokens, signals));
    }

    // Aynı karakter aralığında birden fazla bulgu varsa en şiddetlisini tut.
    final deduped = _deduplicate(findings);
    deduped.sort((a, b) => b.adjustedSeverity.compareTo(a.adjustedSeverity));

    // ── 6. Skor birleştirme ─────────────────────────────────────────────────
    double toxicity = _combineSeverities(deduped);

    // ── 7. Davranışsal Biyometri (Madde 60) ─────────────────────────────────
    // Hızlı yazım (<150ms) ve yoğun silme (>%30) yüksek öfke belirtisidir.
    // Siber Kalkan, içeriği sınırda (dikkat) olan bir mesajı, salt klavye 
    // şiddetinden dolayı (riskli) seviyesine çekebilir.
    if (typingSpeedMs != null && backspaceRatio != null && toxicity > 0) {
      double stressPenalty = 0.0;
      if (typingSpeedMs < 120.0) {
        stressPenalty += 0.15; // Çok hızlı, agresif yazım
      } else if (typingSpeedMs < 180.0) {
        stressPenalty += 0.08;
      }

      if (backspaceRatio > 0.3) {
        stressPenalty += 0.10; // Cümleyi sürekli bozup yeniden yazma
      } else if (backspaceRatio > 0.15) {
        stressPenalty += 0.05;
      }

      // Maksimum %25 biyometrik ceza eklenebilir. Eşik atlatıcı görevi görür.
      toxicity = (toxicity + stressPenalty).clamp(0.0, 1.0);
    }

    stopwatch.stop();

    return CivilityAnalysis(
      text: text,
      toxicity: toxicity,
      civilityScore: ((1.0 - toxicity) * 100).round().clamp(0, 100),
      risk: _riskFrom(toxicity),
      findings: deduped,
      signals: signals,
      elapsed: stopwatch.elapsed,
      typingSpeedMs: typingSpeedMs,
      backspaceRatio: backspaceRatio,
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

      var matched = _lookup(token.text) ??
          (aggressiveText == token.text ? null : _lookup(aggressiveText));

      // ── İP-29: Ters Yazım Tespiti ("kallas" -> "sallak", "latpa" -> "aptal") ──
      // Yanlış pozitifleri (çip -> piç) önlemek için yalnızca 4 harf ve üzeri
      // kelimelerde tersten okuma denemesi yapılır.
      if (matched == null && token.text.length > 3) {
        final reversedText = token.text.split('').reversed.join('');
        if (!_isMasked(reversedText)) {
          matched = _lookup(reversedText);
        }
      }

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
        final buffer = StringBuffer();
        var allSingleLetters = true;
        for (int k = 0; k < width; k++) {
          buffer.write(tokens[i + k].text);
          if (tokens[i + k].length != 1) allSingleLetters = false;
        }
        final joined = buffer.toString();

        // Kısa birleşimler gürültüdür — TEK İSTİSNA, parçaların hepsinin
        // tek harf olmasıdır. "a q" kasıtlı bir gizlemedir ve iki harflik
        // bir sonuç üretir; mevcut tek-harf birleştirmesi ise ancak ÜÇ
        // harften itibaren devreye girdiği için tam bu aralığı kaçırıyordu.
        final minLength = allSingleLetters ? 2 : 4;
        if (joined.length < minLength) continue;

        final entry = width == 1
            ? _despacedPhrases[joined]
            : (_surfaceForms[joined] ?? _despacedPhrases[joined]);
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
          isVerbal: isVerbal)) {
        return candidate.entry;
      }
    }

    // 2. Kısa exact-mode kökler için morfolojik çekim kontrolü.
    // Bu aşama prefix'lerde bulunamazsa devreye girer.
    // ("mal" -> "malsın", "am" -> "amına", "bok" -> "boktan")
    // Birebir kipteki kısaltmalar çekime girmez (bkz. `MatchMode.verbatim`).
    for (final exact in _exactEntries.entries) {
      if (exact.value.matchMode == MatchMode.verbatim) continue;
      if (TurkishMorphology.isValidInflectedForm(text, exact.key)) {
        return exact.value;
      }
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
