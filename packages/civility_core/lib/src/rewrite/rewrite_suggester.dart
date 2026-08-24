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

/// Yan cümlenin konuşma edimi. Öbek modunda hangi nötr kalıbın
/// seçileceğini belirler; amaç kullanıcının NİYETİNİ korumaktır.
enum _Edim {
  /// "salak mısın nesin" — soru kuruluşu.
  soru,

  /// "maymun gibi davranıyorsun" — bir davranış eleştiriliyor.
  davranis,

  /// "kafasız bir öneri bu" — bir söz, yorum ya da fikir eleştiriliyor.
  ifade,

  /// "ne ahmak adamsın!" — ünlem kuruluşu.
  unlem,

  /// Hiçbiri ayırt edilemedi.
  genel,
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
  static const Map<ToxicityCategory, Map<_Edim, String>> _clauseTemplate = {
    ToxicityCategory.hakaret: {
      _Edim.soru: 'bu yaklaşımını anlamakta zorlanıyorum',
      _Edim.davranis: 'bu davranışını doğru bulmuyorum',
      _Edim.ifade: 'bu söylediğine katılmıyorum',
      _Edim.unlem: 'bu tavrı hiç doğru bulmuyorum',
      _Edim.genel: 'bu konuda sana katılmıyorum',
    },
    ToxicityCategory.asagilama: {
      _Edim.soru: 'bu yaklaşımı nasıl savunduğunu anlamıyorum',
      _Edim.davranis: 'bu davranışı yersiz buluyorum',
      _Edim.ifade: 'bu söylediğini yersiz buluyorum',
      _Edim.unlem: 'bu yaklaşımı hiç doğru bulmuyorum',
      _Edim.genel: 'bu yaklaşımı doğru bulmuyorum',
    },
    ToxicityCategory.kufur: {
      _Edim.soru: 'bu durumu kabul edilemez buluyorum',
      _Edim.davranis: 'bu davranışı kabul edilemez buluyorum',
      _Edim.ifade: 'bu söylediğini kabul edilemez buluyorum',
      _Edim.unlem: 'bu durum kabul edilemez',
      _Edim.genel: 'bu durumu kabul edilemez buluyorum',
    },
    ToxicityCategory.tehdit: {
      _Edim.soru: 'bu durumdan çok rahatsızım',
      _Edim.davranis: 'bu davranıştan çok rahatsızım',
      _Edim.ifade: 'bu söylediğinden çok rahatsızım',
      _Edim.unlem: 'bu durumdan çok rahatsızım',
      _Edim.genel: 'bu durumdan çok rahatsızım',
    },
    ToxicityCategory.nefret: {
      _Edim.soru: 'bu genellemeye katılmıyorum',
      _Edim.davranis: 'bu yaklaşımı doğru bulmuyorum',
      _Edim.ifade: 'bu genellemeye katılmıyorum',
      _Edim.unlem: 'bu genellemeyi hiç doğru bulmuyorum',
      _Edim.genel: 'bu genellemeye katılmıyorum',
    },
    ToxicityCategory.taciz: {
      _Edim.soru: 'bu davranışı rahatsız edici buluyorum',
      _Edim.davranis: 'bu davranışı rahatsız edici buluyorum',
      _Edim.ifade: 'bu söylediğini rahatsız edici buluyorum',
      _Edim.unlem: 'bu davranış rahatsız edici',
      _Edim.genel: 'bu davranışı rahatsız edici buluyorum',
    },
  };

  /// Tablodaki bütün kalıpların düz kümesi. Komşu yan cümlelerin aynı
  /// kalıba düşüp düşmediğini denetlemek için kullanılır.
  static final Set<String> _allTemplates = {
    for (final byEdim in _clauseTemplate.values) ...byEdim.values,
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
      final isTemplate = _allTemplates.contains(rewritten);

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
      // ── ÖRÜNTÜNÜN KENDİ KARŞILIĞI ÖNCELİKLİDİR (İP-24) ────────────────────
      // Örüntüler ve sözlük girdileri, kendilerine özgü bir nötr karşılık
      // tanımlayabilir ("göç politikası hakkında farklı düşünüyorum",
      // "bu konu karmaşık"). Bunlar kategori kalıbından DAHA İYİDİR: yazar,
      // o kuruluşun ne söylemeye çalıştığını bilerek yazmıştır.
      //
      // Önceki hâlde bu karşılıklar öbek modunda tamamen atılıyordu —
      // üstelik öbek moduna geçme sebeplerinden biri tam da karşılığın çok
      // kelimeli olmasıydı. Yani karşılık ne kadar iyi yazılmışsa o kadar
      // kesin çöpe gidiyordu.
      final ozel = dominant.neutralAlternative?.trim();
      if (ozel != null && ozel.contains(' ')) return ozel;

      final byEdim = _clauseTemplate[dominant.category];
      if (byEdim == null) return 'bu konuda sana katılmıyorum';
      final edim = _edimOf(body);
      return byEdim[edim] ?? byEdim[_Edim.genel]!;
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

  // ── KONUŞMA EDİMİ ÇIKARIMI (İP-24) ────────────────────────────────────────
  // Öbek modunda kategori başına TEK kalıp vardı ve sonuç ölçümle görüldü:
  // 133 saldırı örneğinin büyük çoğunluğu aynı cümleye — "bu konuda sana
  // katılmıyorum" — çöküyordu. Sayısal kapı bunu göremez çünkü yalnızca
  // toksisiteye bakar ve kalıp her seferinde 100 puan alır.
  //
  // Ama ürünün vaadi "toksisiteyi düşürmek" değil, kullanıcının SÖYLEMEK
  // İSTEDİĞİNİ saldırmadan söyletmektir. Beş farklı hakarete beş aynı cevap
  // veren bir katman, kullanıcının niyetini silmiş olur:
  //
  //   "maymun gibi davranıyorsun"  → bir DAVRANIŞ eleştirisi
  //   "salak mısın nesin"          → bir SORU
  //   "kafasız bir öneri bu"       → bir İFADE eleştirisi
  //
  // Üçü de aynı cümleye çıkarsa kullanıcı öneriyi kullanmaz.
  //
  // Çözüm rastgelelik DEĞİLDİR — rastgele seçim yeniden üretilemez ve test
  // edilemez. Kalıp, yan cümlenin konuşma ediminden BELİRLENİMCİ olarak
  // seçilir: aynı girdi her zaman aynı öneriyi verir.

  /// Soru eki biçimleri. Ünlü uyumunun dört hâli de alınır.
  static const Set<String> _soruEki = {
    'mi', 'mı', 'mu', 'mü',
    'misin', 'mısın', 'musun', 'müsün',
    'misiniz', 'mısınız', 'musunuz', 'müsünüz',
  };

  /// Bir DAVRANIŞ eleştirildiğinde geçen kökler.
  static const List<String> _davranisKokleri = [
    'davran', 'yapıyor', 'yaptın', 'yapıyorsun', 'ediyorsun', 'edersin',
    'konuş', 'hareket', 'tavır', 'tavr', 'davranış',
  ];

  /// Bir İFADE (söz, yorum, fikir) eleştirildiğinde geçen kökler.
  static const List<String> _ifadeKokleri = [
    'yorum', 'öneri', 'fikir', 'laf', 'söz', 'cümle', 'açıklama', 'iddia',
    'diyorsun', 'dediğin', 'yazdığın', 'yazıyorsun', 'üslup', 'üslubun',
  ];

  /// Yan cümlenin konuşma edimi.
  _Edim _edimOf(String clause) {
    final lower = TurkishMorphology.toLowerTr(clause);

    if (lower.contains('!')) return _Edim.unlem;

    final words = lower
        .split(RegExp(r'[^\wçğıöşü]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (lower.contains('?')) return _Edim.soru;
    for (final w in words) {
      if (_soruEki.contains(w)) return _Edim.soru;
    }
    // "ne ahmak adamsın" — ünlem kuruluşu, ünlem işareti olmadan.
    if (words.isNotEmpty && words.first == 'ne') return _Edim.unlem;

    for (final kok in _davranisKokleri) {
      if (lower.contains(kok)) return _Edim.davranis;
    }
    for (final kok in _ifadeKokleri) {
      if (lower.contains(kok)) return _Edim.ifade;
    }
    return _Edim.genel;
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

      // Soru eki ikinci şahsa yöneliktir: "sersem misin nesin".
      if (_soruEki.contains(word)) return true;

      // İkinci şahıs çekimi taşıyan herhangi bir kelime: "yapıyorsun",
      // "adamsın", "konuşuyorsunuz". Fiil de olabilir, ad da.
      //
      // İP-24: GÖRÜLEN GEÇMİŞ ZAMAN eki de eklendi ("davrandın", "yaptın",
      // "konuştun"). Eksikliği ölçümde bozuk çıktı üretiyordu:
      //   "avanak gibi davrandın" → "Yanlış gibi davrandın"
      // Yan cümle kişiyi hedeflemiyor sayıldığı için kelime ikamesi
      // yapılıyor, oysa sıfat bir KİŞİ benzetmesinin içinde.
      for (final s in const ['sın', 'sin', 'sun', 'sün',
                             'sınız', 'siniz', 'sunuz', 'sünüz',
                             'dın', 'din', 'dun', 'dün',
                             'tın', 'tin', 'tun', 'tün']) {
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

      // ── GİZLEME NOKTASI YAN CÜMLE AYIRICISI DEĞİLDİR (İP-24) ─────────────
      // Kullanıcılar süzgeçten kaçmak için harflerin arasına noktalama
      // serpiştirir: "a.p.t.a.l", "s-a-l-a-k". Normalleştirici bunu çözer ve
      // motor tek bir bulgu üretir, ama yeniden yazıcı metni HAM hâliyle
      // parçalıyordu:
      //
      //   "a.p.t.a.l mısın" → 5 yan cümle → nötr karşılık 5 kez yazılıyordu
      //   sonuç: "Yanlış.yanlış.yanlış.yanlış.yanlış mısın"
      //
      // Gerçek bir cümle sınırı, ayırıcıdan sonra boşluk ya da metin sonu
      // ister. Harf-nokta-harf dizisi bir sınır değildir.
      final sonrasi = i + 1 < text.length ? text[i + 1] : ' ';
      final ayiriciMi = ' \t\n.!?,;:'.contains(sonrasi);
      if (!ayiriciMi) continue;

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
