// =============================================================================
// NSosyal Sosyal YZ — Türkçe Toksisite Sözlüğü
// Dosya: packages/civility_core/lib/src/lexicon/toxicity_lexicon.dart
//
// AMAÇ:
// Türkçe saldırgan dil için kategorili, ağırlıklı ve BAĞLAM DUYARLI sözlük.
//
// Bu dosya bir "yasaklı kelime listesi" DEĞİLDİR. Naif kelime listeleri
// üretimde işe yaramaz; iki yönden birden çuvallarlar:
//
//   YANLIŞ POZİTİF: "şikayet" → normalize → "sikayet" → "sik" içeriyor → ✗
//                   "götürdü" → normalize → "goturdu" → "got" içeriyor → ✗
//                   "adı ne?"  → normalize → "adi ne"  → "adi" (aşağılama) → ✗
//                   "malzeme"  → "mal" içeriyor → ✗
//
//   YANLIŞ NEGATİF: "şerefsizsin" (çekimli hâl) sözlükte yok → kaçar
//                   "$3r3fsiz" (gizlenmiş) → kaçar
//
// ÇÖZÜM — üç mekanizma:
//   1. `MatchMode.prefix`   : Türkçe eklemeli bir dildir. Hakaret kökü daima
//                             ÖN EK konumundadır ("şerefsiz|sin", "aptal|lar").
//                             Kök eşleşmesi tüm çekimleri yakalar.
//   2. `MatchMode.exact`    : Kısa/çokanlamlı terimler ("it", "mal", "adi")
//                             yalnızca tam eşleşmede tetiklenir.
//   3. `requiresDirection`  : Hayvan adları ("eşek", "öküz", "domuz") ancak
//                             İKİNCİ ŞAHSA yöneltildiğinde hakarettir.
//                             "Eşek arısı soktu" ≠ "eşeksin".
//   + `maskedPrefixes`      : Yanlış pozitif üreten meşru kelimeler.
//
// VERİ KAYNAĞI NOTU (teknik rapor için):
// Aşağıdaki liste, etiketli veri kümesiyle eğitilecek sınıflandırıcı için
// TOHUM (seed) sözlüktür ve deterministik taban çizgisini (baseline) oluşturur.
// Üretimde bu katman, ONNX üzerinde çalışan ince ayarlı BERTurk modelinin
// yüksek-kesinlikli (high-precision) ön filtresi olarak konumlanır.
// =============================================================================

/// Saldırgan dil kategorileri. Her kategorinin ürün içinde farklı bir
/// müdahale stratejisi vardır (uyar / öner / engelle / bildir).
enum ToxicityCategory {
  /// Küfür, müstehcen sövgü. En yüksek şiddet.
  kufur,

  /// Kişiye yönelik hakaret, zeka/karakter saldırısı.
  hakaret,

  /// Fiziksel şiddet tehdidi. Yasal olarak da suç teşkil eder.
  tehdit,

  /// Kimliğe (etnik köken, inanç, cinsiyet, yönelim) yönelik nefret söylemi.
  nefret,

  /// Cinsel taciz, rıza dışı cinsel içerikli hitap.
  taciz,

  /// Küçümseme, alay, değersizleştirme. Düşük şiddet ama yaygın.
  asagilama,
}

extension ToxicityCategoryInfo on ToxicityCategory {
  /// Kullanıcıya gösterilecek Türkçe etiket.
  String get label => switch (this) {
        ToxicityCategory.kufur => 'Küfür',
        ToxicityCategory.hakaret => 'Hakaret',
        ToxicityCategory.tehdit => 'Tehdit',
        ToxicityCategory.nefret => 'Nefret söylemi',
        ToxicityCategory.taciz => 'Taciz',
        ToxicityCategory.asagilama => 'Aşağılama',
      };

  /// Kullanıcıya gösterilecek kısa açıklama — şeffaflık ilkesi gereği
  /// her uyarı "neden" sorusuna cevap vermek zorundadır.
  String get explanation => switch (this) {
        ToxicityCategory.kufur =>
          'Müstehcen ifade içeriyor. Topluluk kurallarına aykırı.',
        ToxicityCategory.hakaret =>
          'Doğrudan kişiye yönelik hakaret içeriyor.',
        ToxicityCategory.tehdit =>
          'Şiddet tehdidi içeriyor. Bu ifade suç teşkil edebilir.',
        ToxicityCategory.nefret =>
          'Bir kimlik grubunu hedef alan nefret söylemi içeriyor.',
        ToxicityCategory.taciz =>
          'Rıza dışı cinsel içerikli ifade içeriyor.',
        ToxicityCategory.asagilama =>
          'Karşındakini küçümseyen bir ifade. Daha yapıcı kurulabilir.',
      };
}

/// Sözlük girdisinin metinle nasıl eşleştirileceği.
enum MatchMode {
  /// Kök eşleşmesi: token bu terimle BAŞLIYORSA eşleşir.
  /// Türkçe eklemeli yapıyı tek kuralla çözer: "aptal" → "aptallar",
  /// "aptalsın", "aptallığın" hepsini yakalar.
  prefix,

  /// Tam eşleşme: token birebir bu terime eşitse eşleşir.
  /// Kısa veya çokanlamlı terimler için — yanlış pozitifi engeller.
  exact,
}

/// Tek bir sözlük girdisi.
class LexiconEntry {
  /// Terimin okunabilir Türkçe hâli. Çalışma anında normalize edilir.
  final String term;

  final ToxicityCategory category;

  /// Taban şiddet [0.0 – 1.0]. Bağlam katmanı bunu artırıp azaltır.
  final double severity;

  final MatchMode matchMode;

  /// True ise: bu terim yalnızca İKİNCİ ŞAHSA yöneltildiğinde saldırgandır.
  /// "Eşek arısı" zararsız, "eşeksin" hakaret.
  final bool requiresDirection;

  /// Yeniden yazma önerisinde bu terimin yerine geçecek nötr karşılık.
  /// null ise terim tamamen çıkarılır.
  final String? neutralAlternative;

  const LexiconEntry({
    required this.term,
    required this.category,
    required this.severity,
    this.matchMode = MatchMode.prefix,
    this.requiresDirection = false,
    this.neutralAlternative,
  });
}

/// Türkçe toksisite sözlüğü — tohum veri kümesi.
class ToxicityLexicon {
  const ToxicityLexicon._();

  // ───────────────────────────────────────────────────────────────────────────
  // MASKELEME LİSTESİ — YANLIŞ POZİTİF ENGELLEYİCİ
  //
  // Bu ön ekle BAŞLAYAN hiçbir token toksik sayılmaz; sözlük eşleşmesi olsa
  // bile iptal edilir. Aksan katlaması sonrası çakışan meşru kelimeler.
  //
  // Her satırın yanındaki yorum, hangi terimle çakıştığını gösterir —
  // liste büyüdükçe bakım yapılabilir kalması için.
  // ───────────────────────────────────────────────────────────────────────────
  static const List<String> maskedPrefixes = [
    // "şikayet" → "sikayet" → "sik" ile çakışır
    'sikaye',
    // "sikke" (para birimi)
    'sikke',
    // "götür-" fiili → "goturdu", "goturecek" → "got" ile çakışır
    'gotur',
    // "göreceli, görüş, görev" → "gor" güvenli ama "göt" ile karışmasın
    'gorev', 'gorus', 'gorunt', 'goster',
    // "malzeme, malum, maliyet, mali, malik, maliye" → "mal" ile çakışır
    'malz', 'malum', 'maliy', 'malik', 'mali ', 'malta', 'malul',
    // "adı, adına, adında" (isim) → "adi" (bayağı) ile çakışır
    'adin', 'adiy',
    // "alçak basınç, alçalmak" → "alçak" (bayağı) ile çakışır
    'alcal', 'alcag',
    // "hayvancılık, hayvanat" → "hayvan" hakaretiyle çakışır
    'hayvanc', 'hayvanat', 'hayvanse',
    // "itibar, itiraz, itiraf, ithal, itina" → "it" ile çakışır
    'itib', 'itir', 'ithal', 'itin', 'itaat', 'itici',
    // "köpekbalığı, köpekgiller" → "köpek" hakaretiyle çakışır
    'kopekb', 'kopekg',
    // "pislik" meşru kullanım (temizlik bağlamı) — düşük öncelikli
    'pisli',
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // SÖZLÜK
  //
  // Terimler okunabilirlik için Türkçe aksanlarıyla yazılmıştır;
  // `CivilityEngine` bunları başlatma anında normalize eder.
  // ───────────────────────────────────────────────────────────────────────────
  static const List<LexiconEntry> entries = [
    // ═══ KÜFÜR ═══════════════════════════════════════════════════════════════
    // Kısaltmalar tam eşleşme ister — 2-3 harfli oldukları için ön ek
    // eşleşmesinde çok fazla meşru kelimeyi yakalarlar.
    LexiconEntry(term: 'amk', category: ToxicityCategory.kufur, severity: 0.95, matchMode: MatchMode.exact),
    LexiconEntry(term: 'aq', category: ToxicityCategory.kufur, severity: 0.90, matchMode: MatchMode.exact),
    LexiconEntry(term: 'mk', category: ToxicityCategory.kufur, severity: 0.75, matchMode: MatchMode.exact),
    LexiconEntry(term: 'oç', category: ToxicityCategory.kufur, severity: 0.95, matchMode: MatchMode.exact),

    LexiconEntry(term: 'siktir', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'sikeyim', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'sikerim', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'sikik', category: ToxicityCategory.kufur, severity: 0.90),
    LexiconEntry(term: 'orospu', category: ToxicityCategory.kufur, severity: 0.98),
    LexiconEntry(term: 'piç', category: ToxicityCategory.kufur, severity: 0.92),
    LexiconEntry(term: 'yarrak', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'yarak', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'pezevenk', category: ToxicityCategory.kufur, severity: 0.92),
    LexiconEntry(term: 'gavat', category: ToxicityCategory.kufur, severity: 0.90),
    LexiconEntry(term: 'kahpe', category: ToxicityCategory.kufur, severity: 0.92),
    LexiconEntry(term: 'sürtük', category: ToxicityCategory.kufur, severity: 0.90),
    LexiconEntry(term: 'yavşak', category: ToxicityCategory.kufur, severity: 0.90),
    LexiconEntry(term: 'göt', category: ToxicityCategory.kufur, severity: 0.70, matchMode: MatchMode.exact),
    LexiconEntry(term: 'götveren', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'ananı', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'avradını', category: ToxicityCategory.kufur, severity: 0.95),

    // ═══ HAKARET ═════════════════════════════════════════════════════════════
    // Zekâ / karakter saldırıları. Ön ek eşleşmesi tüm çekimleri kapsar:
    // "aptal" → aptalsın, aptallar, aptallığın, aptalca
    LexiconEntry(term: 'aptal', category: ToxicityCategory.hakaret, severity: 0.55, neutralAlternative: 'yanlış'),
    LexiconEntry(term: 'salak', category: ToxicityCategory.hakaret, severity: 0.58, neutralAlternative: 'hatalı'),
    LexiconEntry(term: 'gerizekalı', category: ToxicityCategory.hakaret, severity: 0.70),
    LexiconEntry(term: 'dangalak', category: ToxicityCategory.hakaret, severity: 0.68),
    LexiconEntry(term: 'ahmak', category: ToxicityCategory.hakaret, severity: 0.62),
    LexiconEntry(term: 'embesil', category: ToxicityCategory.hakaret, severity: 0.70),
    LexiconEntry(term: 'budala', category: ToxicityCategory.hakaret, severity: 0.58),
    LexiconEntry(term: 'ebleh', category: ToxicityCategory.hakaret, severity: 0.65),
    LexiconEntry(term: 'beyinsiz', category: ToxicityCategory.hakaret, severity: 0.68),
    LexiconEntry(term: 'kafasız', category: ToxicityCategory.hakaret, severity: 0.62),
    LexiconEntry(term: 'şerefsiz', category: ToxicityCategory.hakaret, severity: 0.88),
    LexiconEntry(term: 'haysiyetsiz', category: ToxicityCategory.hakaret, severity: 0.85),
    LexiconEntry(term: 'namussuz', category: ToxicityCategory.hakaret, severity: 0.88),
    LexiconEntry(term: 'onursuz', category: ToxicityCategory.hakaret, severity: 0.80),
    LexiconEntry(term: 'rezil', category: ToxicityCategory.hakaret, severity: 0.55),
    LexiconEntry(term: 'çirkef', category: ToxicityCategory.hakaret, severity: 0.70),
    LexiconEntry(term: 'dallama', category: ToxicityCategory.hakaret, severity: 0.72),
    LexiconEntry(term: 'keriz', category: ToxicityCategory.hakaret, severity: 0.55),
    LexiconEntry(term: 'avanak', category: ToxicityCategory.hakaret, severity: 0.58),
    LexiconEntry(term: 'andaval', category: ToxicityCategory.hakaret, severity: 0.60),
    LexiconEntry(term: 'sersem', category: ToxicityCategory.hakaret, severity: 0.45),
    LexiconEntry(term: 'ezik', category: ToxicityCategory.hakaret, severity: 0.50),
    LexiconEntry(term: 'zavallı', category: ToxicityCategory.hakaret, severity: 0.45),
    LexiconEntry(term: 'hıyar', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),

    // Ölçümle eklendi: yetersizlik hakaretleri kümede kaçıyordu.
    // ("beceriksizin tekisin" → hiçbir eşleşme yoktu)
    LexiconEntry(term: 'beceriksiz', category: ToxicityCategory.hakaret, severity: 0.55, neutralAlternative: 'bu işte zorlanıyor'),
    LexiconEntry(term: 'yeteneksiz', category: ToxicityCategory.hakaret, severity: 0.52),
    LexiconEntry(term: 'işe yaramaz', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),

    // Çokanlamlı — yalnızca tam eşleşme + ikinci şahıs yönelimi ile tetiklenir.
    LexiconEntry(term: 'mal', category: ToxicityCategory.hakaret, severity: 0.50, matchMode: MatchMode.exact, requiresDirection: true),
    LexiconEntry(term: 'adi', category: ToxicityCategory.hakaret, severity: 0.55, matchMode: MatchMode.exact, requiresDirection: true),
    LexiconEntry(term: 'alçak', category: ToxicityCategory.hakaret, severity: 0.60, matchMode: MatchMode.exact, requiresDirection: true),

    // ═══ HAYVAN BENZETMESİ ═══════════════════════════════════════════════════
    // Hepsi meşru anlamlara sahip. YALNIZCA ikinci şahsa yöneltilince hakaret.
    // "Köpeğim hasta" zararsız — "köpeksin" hakaret.
    LexiconEntry(term: 'eşek', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),
    LexiconEntry(term: 'öküz', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'domuz', category: ToxicityCategory.hakaret, severity: 0.65, requiresDirection: true),
    LexiconEntry(term: 'maymun', category: ToxicityCategory.hakaret, severity: 0.60, requiresDirection: true),
    LexiconEntry(term: 'köpek', category: ToxicityCategory.hakaret, severity: 0.60, requiresDirection: true),
    LexiconEntry(term: 'hayvan', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'it', category: ToxicityCategory.hakaret, severity: 0.55, matchMode: MatchMode.exact, requiresDirection: true),

    // ═══ TEHDİT ══════════════════════════════════════════════════════════════
    // En yüksek öncelik: TCK kapsamında suç teşkil edebilir. Ürün akışında
    // bu kategori "öneri" değil "engelleme + bildirim" tetikler.
    LexiconEntry(term: 'öldürürüm', category: ToxicityCategory.tehdit, severity: 0.98),
    LexiconEntry(term: 'öldüreceğim', category: ToxicityCategory.tehdit, severity: 0.98),
    LexiconEntry(term: 'gebertirim', category: ToxicityCategory.tehdit, severity: 0.98),
    LexiconEntry(term: 'geberteceğim', category: ToxicityCategory.tehdit, severity: 0.98),
    LexiconEntry(term: 'gebertecem', category: ToxicityCategory.tehdit, severity: 0.98),
    LexiconEntry(term: 'parçalarım', category: ToxicityCategory.tehdit, severity: 0.90),
    LexiconEntry(term: 'mahvederim', category: ToxicityCategory.tehdit, severity: 0.85),
    LexiconEntry(term: 'ezerim', category: ToxicityCategory.tehdit, severity: 0.82),
    LexiconEntry(term: 'canına okurum', category: ToxicityCategory.tehdit, severity: 0.90),
    LexiconEntry(term: 'kanını akıtırım', category: ToxicityCategory.tehdit, severity: 0.98),
    LexiconEntry(term: 'bulurum seni', category: ToxicityCategory.tehdit, severity: 0.88),
    LexiconEntry(term: 'adresini biliyorum', category: ToxicityCategory.tehdit, severity: 0.92),
    LexiconEntry(term: 'pişman edeceğim', category: ToxicityCategory.tehdit, severity: 0.80),

    // ═══ AŞAĞILAMA (düşük şiddet, yüksek sıklık) ═════════════════════════════
    // Küfür değil ama tartışmayı zehirleyen kalıplar. Ürünün asıl katma
    // değeri burada: bu ifadeler hiçbir platformda engellenmiyor ama
    // "yüz yüze bakar gibi" bir ortamı en çok bunlar bozuyor.
    LexiconEntry(term: 'cahil', category: ToxicityCategory.asagilama, severity: 0.40, requiresDirection: true),
    LexiconEntry(term: 'saçmalıyorsun', category: ToxicityCategory.asagilama, severity: 0.38, neutralAlternative: 'katılmıyorum'),
    LexiconEntry(term: 'boş konuşuyorsun', category: ToxicityCategory.asagilama, severity: 0.40),
    LexiconEntry(term: 'komiksin', category: ToxicityCategory.asagilama, severity: 0.35),
    LexiconEntry(term: 'gülünç', category: ToxicityCategory.asagilama, severity: 0.32),
    LexiconEntry(term: 'acınası', category: ToxicityCategory.asagilama, severity: 0.42),
    // NOT: "sus" buradan ÇIKARILDI. Susturma emri konum bilgisi taşır
    // (tümce sonunda yüklem olarak kurulur) ve sözlük bu bilgiyi taşıyamaz:
    // "sus payı vermişler" yanlış pozitif üretiyordu. Kalıp olarak
    // `implicit_patterns.dart` → `susturma.sus` içine taşındı.
    LexiconEntry(term: 'kapa çeneni', category: ToxicityCategory.asagilama, severity: 0.60),
    LexiconEntry(term: 'haddini bil', category: ToxicityCategory.asagilama, severity: 0.55),
    LexiconEntry(term: 'sen kimsin', category: ToxicityCategory.asagilama, severity: 0.35),

    // ═══ NEFRET SÖYLEMİ ══════════════════════════════════════════════════════
    // ⚠ BURADA KİMLİK ADI YOKTUR — VE OLMAYACAKTIR.
    //
    // "Kürt", "Ermeni", "Alevi", "eşcinsel", "Suriyeli" gibi kimlik adları
    // nötr kelimelerdir. Bunları toksik terim listesine koyan bir sistem,
    // kendi kimliğinden söz eden insanı susturur — yani korumaya çalıştığı
    // grubu cezalandırır. (Bkz. `00_URUN_TANIMI.md` §6.5 "Mağdur korunur".)
    //
    // Bu bölümde YALNIZCA, tek işlevi aşağılamak olan hakaret sözcükleri
    // bulunur. Kimlik + düşmanca kuruluş birleşimleri sözlükte değil,
    // `detect/hate_patterns.dart` içindeki örüntü katmanındadır.
    //
    // `neutralAlternative` alanları, terimin saygılı karşılığını gösterir;
    // yeniden yazma önerisi bunu kullanır.
    LexiconEntry(term: 'çingene', category: ToxicityCategory.nefret, severity: 0.80, neutralAlternative: 'Roman'),
    LexiconEntry(term: 'zenci', category: ToxicityCategory.nefret, severity: 0.82, neutralAlternative: 'siyahi'),
    LexiconEntry(term: 'gavur', category: ToxicityCategory.nefret, severity: 0.75),
    LexiconEntry(term: 'kıro', category: ToxicityCategory.nefret, severity: 0.72, matchMode: MatchMode.exact),
    LexiconEntry(term: 'ibne', category: ToxicityCategory.nefret, severity: 0.88),
    LexiconEntry(term: 'nonoş', category: ToxicityCategory.nefret, severity: 0.80),
    LexiconEntry(term: 'sapkın', category: ToxicityCategory.nefret, severity: 0.70),
    // "X dölü" — kimliği kalıtsal bir kusur gibi kuran epitet.
    // Ön ek eşleşmesi yerine ifade olarak: "döl" tek başına meşru bir
    // biyoloji terimidir.
    LexiconEntry(term: 'dölü', category: ToxicityCategory.nefret, severity: 0.85, matchMode: MatchMode.exact),

    // ═══ TACİZ ═══════════════════════════════════════════════════════════════
    LexiconEntry(term: 'seni becer', category: ToxicityCategory.taciz, severity: 0.95),
    LexiconEntry(term: 'yatağa', category: ToxicityCategory.taciz, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'vücudun', category: ToxicityCategory.taciz, severity: 0.40, requiresDirection: true),
  ];
}
