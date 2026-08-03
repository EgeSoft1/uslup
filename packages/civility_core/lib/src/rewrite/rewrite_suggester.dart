// =============================================================================
// NSosyal Sosyal YZ — Yeniden Yazma Önerisi
// Dosya: packages/civility_core/lib/src/rewrite/rewrite_suggester.dart
//
// Tespit tek başına yetmez. Kullanıcıya "bu mesaj saldırgan" demek,
// onu susturmaktan ibarettir — söylemek istediği şey hâlâ orada durur.
// Ürünün amacı SUSTURMAK değil, AYNI FİKRİ SALDIRMADAN söyletmektir.
//
// TEK KADEMELİ TASARIM — CİHAZ ÜSTÜ:
//   • `LocalRewriteSuggester` — cihazda, deterministik, çevrimdışı, 0 ms.
//     Metin telefondan HİÇ çıkmaz. Her zaman çalışır.
//
// ── NEDEN BULUT KADEMESİ YOK (3 Ağustos 2026 kararı) ──────────────────────
// Önceki sürümde ikinci bir kademe vardı: metni bir dil modeline gönderip
// daha akıcı bir alternatif isteyen sunucu tarafı yeniden yazıcı. Kaldırıldı.
// Gerekçe: `docs/03_LLM_SERVISI.md`.
//
// ── İKİ MOD: NEDEN TEK BAŞINA KELİME İKAMESİ YETMEZ ───────────────────────
// İlk sürüm her bulguyu, bulunduğu yerde nötr karşılığıyla değiştiriyordu.
// 130 örnek üzerinde ölçüldüğünde çıktının çoğu bozuktu:
//
//   "gerizekalı herif"   →  "katılmıyorum herif"        ✗
//   "şerefsizsin sen"    →  "katılmıyorum sen"          ✗
//   "ne ahmak adamsın"   →  "ne katılmıyorum adamsın"   ✗
//
// İki ayrı kök neden vardı:
//
//   1. Kategori varsayılanı ("katılmıyorum") bir CÜMLEDİR, ama kelime
//      yuvasına sokuluyordu.
//   2. Kişiye yönelik hakarette kelime ikamesi ilkesel olarak çalışamaz:
//      "sen tam bir ___sın" kalıbına ne koyarsanız koyun saldırı çerçevesi
//      ayakta kalır. "sen tam bir yanlışsın" hâlâ hakarettir.
//
// Bu yüzden iki mod var:
//
//   • ÖBEK MODU  — Kişiye yöneltilmiş hakaret ya da öbek karşılık. İlgili
//     yan cümlenin TAMAMI nötr bir kalıpla değiştirilir. Bedeli özgüllük
//     kaybıdır ("beyinsiz yorumlar" → "bu yorumlara katılmıyorum"); kazancı
//     dilbilgisi açısından geçerli bir cümledir.
//
//   • YERİNDE MOD — Nesneyi niteleyen sıfat, kimlik terimi gibi durumlarda
//     kelime yerinde değiştirilir ve TAŞIDIĞI EK KORUNUR:
//     "bu karar salakça" → "bu karar hatalı" · "çingene komşum" → "Roman komşum"
//
// Yan cümle sınırında bölme, ikisini aynı metinde karıştırabilmeyi sağlar:
//   "sen tam bir aptalsın, bu karar salakça"
//     → "bu konuda sana katılmıyorum, bu karar hatalı"
//        └── öbek modu ──────────┘  └── yerinde mod ──┘
// =============================================================================

import '../civility_engine.dart';
import '../lexicon/toxicity_lexicon.dart';
import '../normalization/turkish_morphology.dart';

/// Yeniden yazma önerisi.
class RewriteSuggestion {
  /// Önerilen yeni metin.
  final String text;

  /// Öneriyi üreten kaynak — kullanıcıya şeffaflık için gösterilir.
  final String source;

  /// Önerinin uygulanmasıyla beklenen nezaket puanı.
  final int projectedCivilityScore;

  const RewriteSuggestion({
    required this.text,
    required this.source,
    required this.projectedCivilityScore,
  });
}

/// Yeniden yazma sağlayıcı sözleşmesi.
abstract class RewriteSuggester {
  /// Çözümleme sonucuna göre daha nazik bir alternatif üretir.
  /// Öneri üretilemiyorsa `null` döner.
  Future<RewriteSuggestion?> suggest(CivilityAnalysis analysis);
}

/// Metnin, kendi başına yeniden yazılabilen bir parçası.
class _Clause {
  final int start;
  final int end;

  /// Parçayı izleyen ayırıcı (", ", ". " gibi) — yeniden birleştirmede korunur.
  final String delimiter;

  const _Clause(this.start, this.end, this.delimiter);
}

/// Cihaz üzerinde çalışan deterministik yeniden yazıcı.
class LocalRewriteSuggester implements RewriteSuggester {
  final ToxicityClassifier _classifier;

  const LocalRewriteSuggester(this._classifier);

  /// Kişiye yöneltildiğinde kelime ikamesinin çalışmadığı kategoriler.
  /// Bunlarda saldırı, kelimede değil cümlenin KURULUŞUNDADIR.
  static const Set<ToxicityCategory> _personAttack = {
    ToxicityCategory.hakaret,
    ToxicityCategory.asagilama,
    ToxicityCategory.kufur,
    ToxicityCategory.taciz,
  };

  /// Öbek modunda kullanılan nötr kalıplar.
  ///
  /// Hepsi kullanıcının DURUŞUNU korur — "katılmıyorum", "doğru bulmuyorum" —
  /// ama saldırıyı çıkarır. Kasıtlı olarak özür veya yumuşatma içermezler;
  /// ürünün ilkesi kullanıcıyı susturmak değil, aynı itirazı saldırmadan
  /// söyletmektir.
  static const Map<ToxicityCategory, String> _clauseTemplate = {
    ToxicityCategory.hakaret: 'bu konuda sana katılmıyorum',
    ToxicityCategory.asagilama: 'bu yaklaşımı doğru bulmuyorum',
    ToxicityCategory.kufur: 'bu durumu kabul edilemez buluyorum',
    ToxicityCategory.tehdit: 'bu durumdan çok rahatsızım',
    ToxicityCategory.nefret: 'bu genellemeye katılmıyorum',
    ToxicityCategory.taciz: 'bu davranışı rahatsız edici buluyorum',
  };

  /// Yerinde modda, sözlükte karşılık tanımlanmamış terimler için.
  /// Yalnızca TEK KELİME olabilir — öbek olsaydı yerinde mod bozulurdu.
  static const Map<ToxicityCategory, String> _inlineFallback = {
    ToxicityCategory.hakaret: 'yanlış',
    ToxicityCategory.asagilama: 'yersiz',
    ToxicityCategory.nefret: '',
    ToxicityCategory.kufur: '',
    ToxicityCategory.tehdit: '',
    ToxicityCategory.taciz: '',
  };

  @override
  Future<RewriteSuggestion?> suggest(CivilityAnalysis analysis) async {
    if (!analysis.hasFindings) return null;

    final text = analysis.text;
    final clauses = _segment(text);

    final pieces = <String>[];
    String? previousTemplate;

    for (final clause in clauses) {
      final body = text.substring(clause.start, clause.end);
      final inside = analysis.findings
          .where((f) => f.start < clause.end && f.end > clause.start)
          .toList();

      if (inside.isEmpty) {
        pieces.add(body + clause.delimiter);
        previousTemplate = null;
        continue;
      }

      final rewritten = _rewriteClause(body, clause, inside);
      final isTemplate = _clauseTemplate.containsValue(rewritten);

      // İki komşu yan cümle de kalıba dönüştüyse ikincisini yutuyoruz:
      // "bu konuda sana katılmıyorum, bu konuda sana katılmıyorum" saçmadır.
      if (isTemplate && rewritten == previousTemplate) continue;

      previousTemplate = isTemplate ? rewritten : null;
      pieces.add(rewritten + clause.delimiter);
    }

    var rewritten = pieces.join();
    rewritten = _normalizeShouting(rewritten);
    rewritten = _collapsePunctuation(rewritten);
    rewritten = _tidyWhitespace(rewritten);
    // İkame, sonrasındaki soru ekinin ünlü uyumunu bozmuş olabilir:
    // "embesil misin" → "yanlış misin" (olması gereken "yanlış mısın").
    rewritten = TurkishMorphology.fixQuestionParticles(rewritten);
    rewritten = TurkishMorphology.capitalize(rewritten);

    if (rewritten.trim().isEmpty) return null;
    if (_sameIgnoringCase(rewritten, text)) return null;

    // Önerinin gerçekten daha iyi olduğunu DOĞRULA. Motoru öneri üzerinde
    // tekrar çalıştırmak, kötü bir önerinin kullanıcıya gitmesini engeller.
    final verification = _classifier.analyze(rewritten);
    if (verification.toxicity >= analysis.toxicity) return null;

    return RewriteSuggestion(
      text: rewritten,
      source: 'Cihaz üzerinde (çevrimdışı)',
      projectedCivilityScore: verification.civilityScore,
    );
  }

  // ─── Yan cümle düzeyi ──────────────────────────────────────────────────────

  /// Tek bir yan cümleyi yeniden yazar; moda burada karar verilir.
  String _rewriteClause(String body, _Clause clause, List<ToxicityFinding> inside) {
    final targetsPerson = _targetsPerson(body);

    // Öbek modu gerekiyor mu? Tek bir bulgunun gerektirmesi yeter: yan cümlenin
    // tamamı zaten değişeceği için kalanları ayrıca işlemeye gerek kalmaz.
    ToxicityFinding? dominant;
    for (final f in inside) {
      if (!_needsClauseMode(f, targetsPerson)) continue;
      if (dominant == null || f.adjustedSeverity > dominant.adjustedSeverity) {
        dominant = f;
      }
    }

    if (dominant != null) {
      return _clauseTemplate[dominant.category] ?? 'bu konuda sana katılmıyorum';
    }

    // Yerinde mod: sondan başa doğru değiştir ki henüz işlenmemiş bulguların
    // indeksleri kaymasın.
    final ordered = List<ToxicityFinding>.from(inside)
      ..sort((a, b) => b.start.compareTo(a.start));

    var result = body;
    for (final f in ordered) {
      final from = (f.start - clause.start).clamp(0, result.length);
      final to = (f.end - clause.start).clamp(from, result.length);
      result = result.replaceRange(from, to, _inlineReplacement(f));
    }
    return result;
  }

  /// İkinci şahıs zamirleri — yan cümlenin bir kişiyi hedefleyip
  /// hedeflemediğinin en güçlü işareti.
  static const Set<String> _secondPersonPronouns = {
    'sen', 'sana', 'seni', 'senin', 'sende', 'senden',
    'siz', 'size', 'sizi', 'sizin', 'sizde', 'sizden',
  };

  /// Hitap olarak kullanılan kişi adları. "gerizekalı herif" cümlesinde
  /// zamir yoktur ama hedef açıkça bir kişidir.
  static const Set<String> _personNouns = {
    'herif', 'adam', 'adamsın', 'kadın', 'insan', 'tip', 'eleman',
    'çocuk', 'moruk', 'kişi', 'insanlar', 'insanlarsınız',
  };

  /// Bu yan cümle bir KİŞİYİ mi hedefliyor?
  ///
  /// Motorun `context.isDirected` alanı metnin TAMAMI için hesaplanır; bir
  /// cümlede "sen" geçmesi, aynı cümlenin ikinci yan cümlesindeki nesne
  /// sıfatını da kişiye yönelik göstermeye yeter. O zaman:
  ///
  ///   "sen tam bir aptalsın, bu karar salakça"
  ///     → her iki yan cümle de kalıba dönüşür, ELEŞTİRİ BUHARLAŞIR.
  ///
  /// Bu yüzden yönelim, yan cümle düzeyinde burada yeniden ölçülür.
  bool _targetsPerson(String clause) {
    final words = TurkishMorphology.toLowerTr(clause)
        .split(RegExp(r'[^\wçğıöşü]+'))
        .where((w) => w.isNotEmpty);

    for (final word in words) {
      if (_secondPersonPronouns.contains(word)) return true;
      if (_personNouns.contains(word)) return true;

      // İkinci şahıs çekimi taşıyan herhangi bir kelime: "yapıyorsun",
      // "adamsın", "konuşuyorsunuz". Fiil de olabilir, ad da.
      for (final s in const ['sın', 'sin', 'sun', 'sün',
                             'sınız', 'siniz', 'sunuz', 'sünüz']) {
        if (word.length > s.length + 1 && word.endsWith(s)) return true;
      }
    }
    return false;
  }

  /// Kelime ikamesinin çalışamayacağı durumlar.
  bool _needsClauseMode(ToxicityFinding finding, bool targetsPerson) {
    // 1. Kişiye yöneltilmiş saldırı — kalıbın kendisi saldırgan.
    //    Motorun genel yönelim kararı YAN CÜMLE düzeyinde doğrulanır.
    if (_personAttack.contains(finding.category) &&
        finding.context.isDirected &&
        targetsPerson) {
      return true;
    }

    // 2. Karşılık bir öbek/cümle — kelime yuvasına sığmaz.
    final replacement = finding.neutralAlternative;
    if (replacement != null && replacement.trim().contains(' ')) return true;

    // 3. Örüntü bulgusu ve karşılığı yok — örüntüler cümle kuruluşunu
    //    tanımlar, tek kelimeyle onarılamazlar.
    if (finding.source == FindingSource.oruntu &&
        (replacement == null || replacement.isEmpty)) {
      return true;
    }

    return false;
  }

  /// Yerinde ikame: karşılığı bulur ve eşleşen kelimenin TAŞIDIĞI EKİ aktarır.
  String _inlineReplacement(ToxicityFinding finding) {
    final base = (finding.neutralAlternative?.trim().isNotEmpty ?? false)
        ? finding.neutralAlternative!.trim()
        : (_inlineFallback[finding.category] ?? '');

    if (base.isEmpty) return '';

    final suffix = _carriedSuffix(finding.matchedText);
    if (suffix == null) return base;

    return TurkishMorphology.attach(base, suffix(base));
  }

  /// Eşleşen metnin taşıdığı çekim ekini tanır ve karşılığa uygun biçimini
  /// üretecek fonksiyonu döner. Tanınmayan ek için `null`.
  ///
  /// Kapalı liste olması kasıtlı: açık uçlu bir ek çözümleyici, yanlış
  /// tanıdığı her ekte cümleyi bozardı. Tanımadığımız eki hiç taşımamak,
  /// yanlış taşımaktan iyidir.
  String Function(String stem)? _carriedSuffix(String matched) {
    final lower = TurkishMorphology.toLowerTr(matched).trim();

    for (final s in const ['sınız', 'siniz', 'sunuz', 'sünüz']) {
      if (lower.endsWith(s)) return TurkishMorphology.copulaSecondPlural;
    }
    for (final s in const ['sın', 'sin', 'sun', 'sün']) {
      if (lower.endsWith(s)) return TurkishMorphology.copulaSecondSingular;
    }
    for (final s in const ['dır', 'dir', 'dur', 'dür', 'tır', 'tir', 'tur', 'tür']) {
      if (lower.endsWith(s)) return TurkishMorphology.copulaThird;
    }
    for (final s in const ['lar', 'ler']) {
      if (lower.endsWith(s)) return TurkishMorphology.plural;
    }
    return null;
  }

  // ─── Metni yan cümlelere bölme ─────────────────────────────────────────────

  /// Metni virgül/nokta gibi sınırlardan parçalara ayırır.
  ///
  /// Amaç, aynı metinde iki modu birlikte kullanabilmek: bir yan cümle
  /// kalıpla değiştirilirken diğerindeki sıfat yerinde düzeltilebilir.
  List<_Clause> _segment(String text) {
    final clauses = <_Clause>[];
    var start = 0;

    for (var i = 0; i < text.length; i++) {
      if (!'.!?,;:'.contains(text[i])) continue;

      // Ayırıcıyı ve ardındaki boşluğu topla.
      var end = i;
      while (end < text.length && '.!?,;: '.contains(text[end])) {
        end++;
      }
      clauses.add(_Clause(start, i, text.substring(i, end)));
      start = end;
      i = end - 1;
    }

    if (start < text.length) {
      clauses.add(_Clause(start, text.length, ''));
    }
    return clauses;
  }

  // ─── Biçimsel temizlik ─────────────────────────────────────────────────────

  bool _sameIgnoringCase(String a, String b) =>
      TurkishMorphology.toLowerTr(a).trim() ==
      TurkishMorphology.toLowerTr(b).trim();

  /// Tümü büyük harfle yazılmış metni normal yazıma indirir.
  /// Kısa metinler ("OK", "TAMAM") bağırma sayılmaz.
  String _normalizeShouting(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-ZçğıöşüÇĞİÖŞÜ]'), '');
    if (letters.length < 8) return text;

    final upperCount = letters
        .split('')
        .where((c) => c == TurkishMorphology.toUpperTr(c))
        .length;
    if (upperCount / letters.length < 0.7) return text;

    return TurkishMorphology.toLowerTr(text);
  }

  /// "!!!" → "!",  "???" → "?"
  String _collapsePunctuation(String text) {
    return text
        .replaceAll(RegExp(r'!{2,}'), '!')
        .replaceAll(RegExp(r'\?{2,}'), '?');
  }

  /// Kelime çıkarılınca oluşan çift boşluk ve sarkan noktalamayı temizler.
  String _tidyWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\s+([,.!?;:])'), r'$1')
        .replaceAll(RegExp(r'^[\s,;:]+'), '')
        .replaceAll(RegExp(r'[\s,;:]+$'), '')
        .trim();
  }
}
