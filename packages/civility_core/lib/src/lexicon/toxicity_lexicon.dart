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

  /// Tam eşleşme: token bu terime eşitse ya da terim + DAR bir çekim eki
  /// listesinden oluşuyorsa eşleşir ("mal" → "malsın").
  /// Kısa veya çokanlamlı terimler için — yanlış pozitifi engeller.
  exact,

  /// Birebir eşleşme: token terime eşit olmalıdır; HİÇBİR ek kabul edilmez.
  ///
  /// Kısaltmalar ve ünsüz iskeletleri içindir ("amk", "aq", "sktr"). Bunlar
  /// kelime değil harf dizisidir ve Türkçe'de çekime girmez; çekim denemek
  /// yalnızca masum kelimelere uydurma bir kök yakıştırır. Ölçülen hata:
  ///
  ///   "aq" → normalize → "ak"   ·   "ağı" = "ak" + yumuşama + "ı"  → küfür ✗
  ///   "mk" + "a" → "mka"        ·   ünlüsüz kökte uyum denetimi boşa düşer ✗
  verbatim,
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
    // ── İP-17 ölçümüyle eklenenler ────────────────────────────────────────
    // "psikopatoloji, psikopatolojik" → "psikopat" ile çakışır
    'psikopatol',
    // "parazitoloji" → "parazit" ile çakışır
    'parazitolo',
    // "değersizleştirme" (akademik terim) → "değersiz" ile çakışır
    'degersizles',
    // ── İP-26 ölçümüyle eklenenler ────────────────────────────────────────
    // "kansızlık" (tıbbi terim, anemi) → "kansız" ile çakışır
    'kansizl',
    // "omurgasızlar" (biyoloji) → "omurgasız" ile çakışır
    'omurgasizl',
    // "kenevir" → "kene" ile çakışır
    'kenev',
    // "çakallık" meşru değil ama "çakal kuyruğu" doğa yazısı olabilir;
    // asıl çakışma "Çakalburnu" gibi yer adlarıdır
    'cakalb',
    // "yılanbalığı", "yılankavi" → "yılan" ile çakışır
    'yilanb', 'yilank',
    // "sülüklü" (yer adı), "sülün" ayrı kök ama tarayıcı ön eki karıştırmasın
    'sulukl',
    // "avarage"/"avara" denizcilik terimi ile çakışmayı önler
    'avarya',
    // "palavracılık" hakaret, "palavra kule" (mimari) değil
    'palavrak',
    // "tembellik etmek" bir davranış eleştirisidir, kişi hakareti değil;
    // "tembel" girdisi yönelim şartıyla korunuyor, bu ek güvence
    'tembelh',
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // KISA KÖK ÇAKIŞMALARI — TAM KELİME (D2 · docs/20 · 13 Eylül 2026)
  //
  // ≤ 3 harfli kökler dar bir çekim listesiyle eşleşir ("mal" → "malsın").
  // O listeden geçen bazı biçimler Türkçenin en sık kelimeleridir ve ASCII
  // yazımda saldırgan okumadan ayırt edilemez. Türkçe harfle yazılanlar
  // ("sıkı", "boğa", "adı") motorda özgün metinden ayrıca ayıklanır; bu
  // liste harf kanıtı TAŞIMAYAN biçimler içindir.
  //
  // Maskeleme listesinden farkı: ön ek değil, TAM kelimedir. "amin" ön ek
  // olarak maskelenseydi "amina" da maskelenirdi.
  // ───────────────────────────────────────────────────────────────────────────
  static const Set<String> shortRootCollisions = {
    // am + a / in → "ama" (bağlaç), "amin" (dua)
    'ama', 'amin',
    // kaz + a / ı / ım → "kaza", "kazı", "Kazım"
    'kaza', 'kazi', 'kazim',
    // it → id (yumuşama) + ek-fiil → "idi", "idin", "idim", "idiniz"
    'idi', 'idin', 'idim', 'idiniz',
    // adi + le → "Adile" (ad)
    'adile',
    // bok → bog (yumuşama) + a → "boga" (ASCII "boğa")
    'boga',
    // sik + i → "siki" (ASCII "sıkı")
    'siki',
    // mal + a / lar / ları → "mala", "mallar", "malları" (eşya, mal varlığı)
    'mala', 'mallar', 'mallari',
  };

  // ───────────────────────────────────────────────────────────────────────────
  // SÖZLÜK
  //
  // Terimler okunabilirlik için Türkçe aksanlarıyla yazılmıştır;
  // `CivilityEngine` bunları başlatma anında normalize eder.
  // ───────────────────────────────────────────────────────────────────────────
  static const List<LexiconEntry> entries = [
    // ═══ KÜFÜR ═══════════════════════════════════════════════════════════════
    // Kısaltmalar BİREBİR eşleşme ister — 2-3 harfli oldukları için ön ek
    // eşleşmesinde çok fazla meşru kelimeyi yakalarlar, çekim denemesinde
    // ise masum kelimelere kök yakıştırırlar (bkz. `MatchMode.verbatim`).
    LexiconEntry(term: 'amk', category: ToxicityCategory.kufur, severity: 0.95, matchMode: MatchMode.verbatim),
    LexiconEntry(term: 'aq', category: ToxicityCategory.kufur, severity: 0.90, matchMode: MatchMode.verbatim),
    LexiconEntry(term: 'mk', category: ToxicityCategory.kufur, severity: 0.75, matchMode: MatchMode.verbatim),
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
    // İP-17 — çekişmeli taramada kaçtığı ölçülenler
    LexiconEntry(term: 'kaltak', category: ToxicityCategory.kufur, severity: 0.92),
    LexiconEntry(term: 'şıllık', category: ToxicityCategory.kufur, severity: 0.85),
    LexiconEntry(term: 'puşt', category: ToxicityCategory.kufur, severity: 0.90),
    LexiconEntry(term: 'ana avrat', category: ToxicityCategory.kufur, severity: 0.90),
    // Meşru bağlamı vardır (gazetecilik, sosyoloji): yalnızca yöneltilince.
    LexiconEntry(term: 'fahişe', category: ToxicityCategory.kufur, severity: 0.80, requiresDirection: true),
    LexiconEntry(term: 'amcık', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'amına koyayım', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'amına koyim', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'orospu çocuğu', category: ToxicityCategory.kufur, severity: 0.98),
    LexiconEntry(term: 'dalyarak', category: ToxicityCategory.kufur, severity: 0.92),
    LexiconEntry(term: 'hassiktir', category: ToxicityCategory.kufur, severity: 0.95),
    LexiconEntry(term: 'götoş', category: ToxicityCategory.kufur, severity: 0.88),
    LexiconEntry(term: 'yarram', category: ToxicityCategory.kufur, severity: 0.90),
    LexiconEntry(term: 'taşşak', category: ToxicityCategory.kufur, severity: 0.70, requiresDirection: true),
    LexiconEntry(term: 'taşak', category: ToxicityCategory.kufur, severity: 0.70, requiresDirection: true),
    LexiconEntry(term: 'sik', category: ToxicityCategory.kufur, severity: 0.90, matchMode: MatchMode.exact, requiresDirection: true),
    LexiconEntry(term: 'am', category: ToxicityCategory.kufur, severity: 0.85, matchMode: MatchMode.exact, requiresDirection: true),
    LexiconEntry(term: 'bok', category: ToxicityCategory.kufur, severity: 0.60, matchMode: MatchMode.exact, requiresDirection: true),
    LexiconEntry(term: 'boktan', category: ToxicityCategory.kufur, severity: 0.65),

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
    // "rezil" tek başına bir hakaret DEĞİLDİR — Türkçe'de bir durumu,
    // havayı, maçı ya da yemeği niteleyen sıradan bir sıfattır. İP-27
    // ölçümü bunu bir yanlış pozitifle gösterdi: "rezil bir hava vardı,
    // yağmur dinmedi" 0.55 ile işaretleniyordu. Yönelim şartı eklendi;
    // kişiye söylenmiş hâlleri ("rezil ettin kendini", "rezil oldun")
    // ayrıca `alayci.rezil_ettin` kalıbında durur.
    LexiconEntry(term: 'rezil', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'çirkef', category: ToxicityCategory.hakaret, severity: 0.70),
    LexiconEntry(term: 'dallama', category: ToxicityCategory.hakaret, severity: 0.72),
    LexiconEntry(term: 'keriz', category: ToxicityCategory.hakaret, severity: 0.55),
    LexiconEntry(term: 'avanak', category: ToxicityCategory.hakaret, severity: 0.58),
    LexiconEntry(term: 'andaval', category: ToxicityCategory.hakaret, severity: 0.60),
    LexiconEntry(term: 'sersem', category: ToxicityCategory.hakaret, severity: 0.45),
    LexiconEntry(term: 'ezik', category: ToxicityCategory.hakaret, severity: 0.50),
    LexiconEntry(term: 'zavallı', category: ToxicityCategory.hakaret, severity: 0.45),
    LexiconEntry(term: 'hıyar', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),

    // ── İP-17 · DUYARLILIK GENİŞLETMESİ (24 Ağustos 2026) ────────────────────
    // Aşağıdakiler, kimlik söz varlığı genişletilirken yapılan çekişmeli
    // taramada bulundu: 41 yaygın Türkçe hakaretin 41'i de motorda KAÇIYORDU.
    // Geliştirme kümesindeki %99,6'lık skor bunu göstermiyordu, çünkü küme
    // sözlüğün kendisine bakılarak yazılmıştı — ezberleme payının doğrudan
    // kanıtı budur ve ayrık kümedeki %84,2 ile arasındaki farkı açıklar.
    //
    // ⛔ DENETLENİP ALINMAYANLAR — davranış niteleyen sıfatlar:
    //      "çirkin", "iğrenç"  → "çirkin bir davranış sergiledin" meşru bir
    //      eleştiridir. İkinci şahıs yönelimi bu ikisini kurtarmaya yetmiyor;
    //      eleştiriyi hakaret sayan bir katman, ürünün "sansür değil" iddiasını
    //      çürütür. Kaçırılan duyarlılık bilinçli olarak kabul edilmiştir.

    // Boşluklu yazım — sözlükte YALNIZCA bitişik biçim vardı ("gerizekalı").
    // Türkçe'de standart yazım boşukludur; en yaygın hakaret tamamen kaçıyordu.
    LexiconEntry(term: 'geri zekalı', category: ToxicityCategory.hakaret, severity: 0.70, neutralAlternative: 'yanlış'),
    LexiconEntry(term: 'gerzek', category: ToxicityCategory.hakaret, severity: 0.65, neutralAlternative: 'yanlış'),
    LexiconEntry(term: 'karaktersiz', category: ToxicityCategory.hakaret, severity: 0.70),
    LexiconEntry(term: 'ahlaksız', category: ToxicityCategory.hakaret, severity: 0.68, requiresDirection: true),
    LexiconEntry(term: 'soysuz', category: ToxicityCategory.hakaret, severity: 0.82),
    LexiconEntry(term: 'hödük', category: ToxicityCategory.hakaret, severity: 0.60),
    // İP-19 — ikinci ayrık küme ölçümünde kaçtı.
    LexiconEntry(term: 'mankafa', category: ToxicityCategory.hakaret, severity: 0.62),
    // İP-21 — "geri zekalı" ile aynı boşluklu kuruluş, farklı ad.
    LexiconEntry(term: 'geri kafalı', category: ToxicityCategory.hakaret, severity: 0.66),
    LexiconEntry(term: 'dar kafalı', category: ToxicityCategory.hakaret, severity: 0.58, requiresDirection: true),
    LexiconEntry(term: 'ruh hastası', category: ToxicityCategory.hakaret, severity: 0.68),
    LexiconEntry(term: 'yüz karası', category: ToxicityCategory.hakaret, severity: 0.60),

    // Çokanlamlı ya da meşru kullanımı olan kökler — yalnızca ikinci şahsa
    // yöneltildiğinde hakarettir. ("asalak canlılar" ≠ "asalak herif")
    LexiconEntry(term: 'aşağılık', category: ToxicityCategory.hakaret, severity: 0.68, requiresDirection: true),
    LexiconEntry(term: 'değersiz', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'manyak', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),
    LexiconEntry(term: 'terbiyesiz', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'edepsiz', category: ToxicityCategory.hakaret, severity: 0.52, requiresDirection: true),
    LexiconEntry(term: 'saygısız', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'nankör', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'arsız', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'yüzsüz', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),
    LexiconEntry(term: 'ödlek', category: ToxicityCategory.hakaret, severity: 0.48, requiresDirection: true),
    LexiconEntry(term: 'dönek', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),
    LexiconEntry(term: 'korkak', category: ToxicityCategory.hakaret, severity: 0.42, requiresDirection: true),
    LexiconEntry(term: 'psikopat', category: ToxicityCategory.hakaret, severity: 0.62, requiresDirection: true),
    LexiconEntry(term: 'şişko', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'asalak', category: ToxicityCategory.hakaret, severity: 0.68, requiresDirection: true),
    LexiconEntry(term: 'parazit', category: ToxicityCategory.hakaret, severity: 0.60, requiresDirection: true),

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
    // ⛔ TAŞINDI (İP-22) — "haddini bil" ifadesi `susturma.haddini_bil`
    // örüntüsüne geçti. Sebep: ifade eşleşmesi SAĞ SINIR denetlemez (Türkçe
    // eklemeli olduğu için bilinçli bir tasarım: "işe yaramaz" girdisi
    // "işe yaramazsın"ı da görmek zorundadır). Ama bu terimde ek anlamı
    // TERSİNE ÇEVİRİYORDU:
    //
    //   "haddini bil"              → susturma emri        ✓
    //   "haddini bilen insanlar"   → ÖVGÜ, işaretlendi    ✗
    //
    // Düzenli ifade sağ sınırı ifade edebilir, sözlük edemez.
    LexiconEntry(term: 'sen kimsin', category: ToxicityCategory.asagilama, severity: 0.35),
    // İP-17 — kovma / değersizleştirme kalıpları
    LexiconEntry(term: 'defol', category: ToxicityCategory.asagilama, severity: 0.60),
    LexiconEntry(term: 'halta yaramaz', category: ToxicityCategory.asagilama, severity: 0.55),
    LexiconEntry(term: 'yıkıl karşımdan', category: ToxicityCategory.asagilama, severity: 0.58),

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
    // İP-17 — "ibne" ön eki bu yazım biçimini yakalamıyordu.
    LexiconEntry(term: 'ipne', category: ToxicityCategory.nefret, severity: 0.88),
    // İnanca yönelik düşmanlık epiteti. Kimlik ADI değildir — "Müslüman"
    // sözlüğe girmez; "yobaz" tek işlevi aşağılamak olan bir sıfattır.
    LexiconEntry(term: 'yobaz', category: ToxicityCategory.nefret, severity: 0.70),
    LexiconEntry(term: 'sapkın', category: ToxicityCategory.nefret, severity: 0.70),
    // ⛔ KALDIRILDI (İP-22, 24 Ağustos 2026) — "dölü" epiteti.
    //
    // Girdinin kendisi doğruydu: "X dölü", kimliği kalıtsal bir kusur gibi
    // kuran gerçek bir nefret epitetidir. Kaldırılmasının sebebi anlam
    // değil, MİMARİ:
    //
    //   Normalizasyon aksanları katlar:  ö → o,  ü → u
    //   Dolayısıyla:  "dölü"  →  "dolu"      ve      "dolu"  →  "dolu"
    //
    // Katlamadan sonra iki kelime BİREBİR AYNIDIR. Tam eşleşme modundaki
    // girdi bu yüzden Türkçe'nin en sık kelimelerinden birini nefret
    // söylemi sayıyordu — ölçümle bulundu:
    //
    //   "bardak dolu"     → yüksek risk · nefret · 0,85   ✗
    //   "programın dolu"  → yüksek risk · nefret · 0,85   ✗
    //   "dolu yağdı"      → yüksek risk · nefret · 0,85   ✗
    //
    // Kusur dört ölçüm kümesinin hiçbirinde görünmedi çünkü hiçbirinde
    // "dolu" kelimesi geçmiyordu. Yalnızca dördüncü ayrık kümede, bambaşka
    // bir örüntüyü sınamak için yazılmış bir cümlede ("yarın gelemezsin
    // galiba, programın dolu") ortaya çıktı.
    //
    // ── NEDEN ÖRÜNTÜYE TAŞINMADI ────────────────────────────────────────
    // Kimlik yuvasıyla ("Ermeni dölü") kurtarmak da çalışmaz: katlamadan
    // sonra "Suriyeli dölü" ile "Suriyeli dolu" da ayırt edilemez. Epiteti
    // güvenilir biçimde görmenin tek yolu ham metne bakmaktır ve bu, tüm
    // hattın normalize metin üzerinde çalışması ilkesini tek bir terim için
    // delerdi.
    //
    // Karar: duyarlılık kaybı KABUL EDİLDİ. Yanlış pozitif, yanlış
    // negatiften pahalıdır — ve buradaki yanlış pozitif, sıradan bir
    // cümleyi nefret söylemi ilan ediyordu.

    // ═══ TACİZ ═══════════════════════════════════════════════════════════════
    LexiconEntry(term: 'seni becer', category: ToxicityCategory.taciz, severity: 0.95),
    LexiconEntry(term: 'yatağa', category: ToxicityCategory.taciz, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'vücudun', category: ToxicityCategory.taciz, severity: 0.40, requiresDirection: true),

    // ═══ İP-26 · SÖZ VARLIĞI GENİŞLETMESİ (12 Eylül 2026) ════════════════════
    //
    // Seçim ölçütü, İP-17'dekiyle aynı: Türkçe'de YAYGIN, sözlükte YOK ve
    // eklendiğinde masum bir cümleyi yakalamayacak terimler. Çokanlamlı ya
    // da meşru kullanımı olan her kök `requiresDirection: true` ile korundu —
    // yani yalnızca ikinci şahsa yöneltildiğinde bulgu üretir.
    //
    // ⛔ DENETLENİP ALINMAYANLAR:
    //   "hırsız", "yalancı", "sahtekâr" → bunlar SUÇLAMADIR, hakaret değil.
    //     "Bu kişi hırsız" cümlesi bir iddiadır; doğru ya da yanlış olabilir
    //     ama susturulacak bir şey değildir. Kimlik yuvasıyla birleştiğinde
    //     zaten nefret katmanı yakalıyor ("Bütün X'ler hırsızdır").
    //   "terörist" → aynı gerekçe, ayrıca siyasi tartışmanın merkezinde.
    //   "çirkin", "iğrenç" → İP-17'de de alınmamıştı; davranış niteleyen
    //     sıfatlardır ve eleştiriyi hakaret saymak ürünün iddiasını çürütür.

    // ── Zekâ / yetkinlik ekseni ──────────────────────────────────────────
    LexiconEntry(term: 'akılsız', category: ToxicityCategory.hakaret, severity: 0.58, neutralAlternative: 'düşüncesiz'),
    LexiconEntry(term: 'şuursuz', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'şapşal', category: ToxicityCategory.hakaret, severity: 0.35, requiresDirection: true),
    LexiconEntry(term: 'aval', category: ToxicityCategory.hakaret, severity: 0.45, matchMode: MatchMode.exact, requiresDirection: true),
    LexiconEntry(term: 'sünepe', category: ToxicityCategory.hakaret, severity: 0.48, requiresDirection: true),
    LexiconEntry(term: 'pısırık', category: ToxicityCategory.hakaret, severity: 0.42, requiresDirection: true),
    LexiconEntry(term: 'zibidi', category: ToxicityCategory.hakaret, severity: 0.55),
    LexiconEntry(term: 'zübük', category: ToxicityCategory.hakaret, severity: 0.55),
    LexiconEntry(term: 'lavuk', category: ToxicityCategory.hakaret, severity: 0.62),
    LexiconEntry(term: 'ibiş', category: ToxicityCategory.hakaret, severity: 0.50),
    LexiconEntry(term: 'godoş', category: ToxicityCategory.kufur, severity: 0.85),

    // ── Karakter ekseni ──────────────────────────────────────────────────
    LexiconEntry(term: 'seviyesiz', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'hadsiz', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'küstah', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'densiz', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),
    LexiconEntry(term: 'hayasız', category: ToxicityCategory.hakaret, severity: 0.60, requiresDirection: true),
    LexiconEntry(term: 'utanmaz', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'omurgasız', category: ToxicityCategory.hakaret, severity: 0.62, requiresDirection: true),
    LexiconEntry(term: 'ciğersiz', category: ToxicityCategory.hakaret, severity: 0.60, requiresDirection: true),
    LexiconEntry(term: 'kansız', category: ToxicityCategory.hakaret, severity: 0.58, requiresDirection: true),
    LexiconEntry(term: 'sütü bozuk', category: ToxicityCategory.hakaret, severity: 0.75),
    LexiconEntry(term: 'iki yüzlü', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'yalaka', category: ToxicityCategory.hakaret, severity: 0.52, requiresDirection: true),
    LexiconEntry(term: 'dalkavuk', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'miskin', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'tembel', category: ToxicityCategory.hakaret, severity: 0.38, requiresDirection: true, neutralAlternative: 'bu işte yavaş ilerliyor'),
    LexiconEntry(term: 'ukala', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),

    // ── Hayvan benzetmesi (yönelim şartlı) ───────────────────────────────
    LexiconEntry(term: 'çakal', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'yılan', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'sırtlan', category: ToxicityCategory.hakaret, severity: 0.58, requiresDirection: true),
    LexiconEntry(term: 'kene', category: ToxicityCategory.hakaret, severity: 0.60, requiresDirection: true),
    LexiconEntry(term: 'sülük', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'keçi', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'kaz', category: ToxicityCategory.hakaret, severity: 0.45, matchMode: MatchMode.exact, requiresDirection: true),

    // ── İçeriği değersizleştirme (aşağılama) ─────────────────────────────
    LexiconEntry(term: 'zırva', category: ToxicityCategory.asagilama, severity: 0.40, requiresDirection: true),
    LexiconEntry(term: 'palavra', category: ToxicityCategory.asagilama, severity: 0.38, requiresDirection: true),
    LexiconEntry(term: 'saçma sapan', category: ToxicityCategory.asagilama, severity: 0.38),
    LexiconEntry(term: 'gevezelik', category: ToxicityCategory.asagilama, severity: 0.35, requiresDirection: true),

    // ── Tehdit (deyimsel, öbek olarak) ───────────────────────────────────
    // Hepsi ÖBEK: tek kelimelik biçimleri meşru bağlamda geçer
    // ("rekoru kırarım", "ateşi yakarım").
    LexiconEntry(term: 'canını yakarım', category: ToxicityCategory.tehdit, severity: 0.90),
    LexiconEntry(term: 'kemiklerini kırarım', category: ToxicityCategory.tehdit, severity: 0.95),
    LexiconEntry(term: 'ayağını kırarım', category: ToxicityCategory.tehdit, severity: 0.90),
    LexiconEntry(term: 'kolunu kırarım', category: ToxicityCategory.tehdit, severity: 0.90),
    LexiconEntry(term: 'yakarım seni', category: ToxicityCategory.tehdit, severity: 0.88),
    LexiconEntry(term: 'seni bitiririm', category: ToxicityCategory.tehdit, severity: 0.88),
    LexiconEntry(term: 'gününü göstereceğim', category: ToxicityCategory.tehdit, severity: 0.85),

    // ═══ İP-28 · GİZLEME VARYANTLARI ═════════════════════════════════════════
    //
    // ── NEDEN AYRI BİR BLOK ──────────────────────────────────────────────────
    // Gizleme kaçışlarının BÜYÜK ÇOĞUNLUĞU artık normalizasyon katmanında
    // çözülüyor ve sözlüğe hiçbir şey eklemeyi gerektirmiyor:
    //
    //   "salaq" → q→k dönüşümü      → "salak"      (mevcut girdi yakalar)
    //   "$3r3fsiz" → leet çevirimi  → "serefsiz"   (mevcut girdi yakalar)
    //   "oros pu" → birleştirme     → "orospu"     (mevcut girdi yakalar)
    //   "a m k" → tek-harf birleşimi→ "amk"        (mevcut girdi yakalar)
    //
    // Geriye TEK bir sınıf kalıyor: SESLİ HARF DÜŞÜRME. "siktir" → "sktr".
    // Bu, algoritmayla çözülmesi TEHLİKELİ olan tek sınıftır; her kelimenin
    // ünsüz iskeletini üretip aramak, kısaltmaları ve özel adları toplu
    // hâlde yanlış pozitife çevirirdi (parti kısaltmaları, kurum adları,
    // "TRT", "MHP" gibi üç harfli diziler).
    //
    // Bu yüzden ünsüz iskeletleri ÜRETİLMEZ, tek tek YAZILIR. Yazılan her
    // biçim, Türkçe'de yalnızca ve yalnızca o küfrün yerine kullanılan bir
    // dizidir; masum bir okuması yoktur. Kök eşleşmesi bunları kelime
    // başlangıcı sayıp uzun kelimeleri yakalardı. Ünlüsüz iskeletler
    // (sktr, skym, pzvnk) ayrıca BİREBİR kiptedir: ünlü içermeyen bir kökte
    // ünlü uyumu denetimi hiçbir şeyi eleyemez ve her ek "geçerli" görünür.
    LexiconEntry(term: 'sktr', category: ToxicityCategory.kufur, severity: 0.85, matchMode: MatchMode.verbatim),
    LexiconEntry(term: 'sktir', category: ToxicityCategory.kufur, severity: 0.85, matchMode: MatchMode.exact),
    LexiconEntry(term: 'sikiym', category: ToxicityCategory.kufur, severity: 0.90, matchMode: MatchMode.exact),
    LexiconEntry(term: 'sixiym', category: ToxicityCategory.kufur, severity: 0.90, matchMode: MatchMode.exact),
    LexiconEntry(term: 'skym', category: ToxicityCategory.kufur, severity: 0.88, matchMode: MatchMode.verbatim),
    LexiconEntry(term: 'orspu', category: ToxicityCategory.kufur, severity: 0.92, matchMode: MatchMode.exact),
    LexiconEntry(term: 'pzvnk', category: ToxicityCategory.kufur, severity: 0.85, matchMode: MatchMode.verbatim),
    LexiconEntry(term: 'amnkoyim', category: ToxicityCategory.kufur, severity: 0.95, matchMode: MatchMode.exact),

    // ═══ İP-28 · SÖZ VARLIĞI GENİŞLETMESİ ════════════════════════════════════
    //
    // Ölçüt İP-17 ve İP-26'dakiyle aynı: Türkçe'de YAYGIN, sözlükte YOK,
    // ve eklendiğinde masum bir cümleyi yakalamayan terimler. Çokanlamlı ya
    // da meşru kullanımı olan her kök `requiresDirection: true` ile korundu.

    // ── Hakaret · zekâ ve yetkinlik ──────────────────────────────────────
    LexiconEntry(term: 'malak', category: ToxicityCategory.hakaret, severity: 0.55, neutralAlternative: 'düşüncesiz'),
    LexiconEntry(term: 'yontulmamış', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'görgüsüz', category: ToxicityCategory.hakaret, severity: 0.50, requiresDirection: true),
    LexiconEntry(term: 'nobran', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    // "kaba saba bir masa" — eşya ve üslup betimlemesi; yalnızca yöneltilince.
    LexiconEntry(term: 'kaba saba', category: ToxicityCategory.hakaret, severity: 0.42, requiresDirection: true),
    LexiconEntry(term: 'odun kafalı', category: ToxicityCategory.hakaret, severity: 0.60),
    LexiconEntry(term: 'tahta kafalı', category: ToxicityCategory.hakaret, severity: 0.60),
    LexiconEntry(term: 'boş kafalı', category: ToxicityCategory.hakaret, severity: 0.60),
    LexiconEntry(term: 'kalın kafalı', category: ToxicityCategory.hakaret, severity: 0.55),
    LexiconEntry(term: 'düşük zekâlı', category: ToxicityCategory.hakaret, severity: 0.70),
    LexiconEntry(term: 'zekâ özürlü', category: ToxicityCategory.hakaret, severity: 0.80),
    LexiconEntry(term: 'anlayışsız', category: ToxicityCategory.asagilama, severity: 0.35, requiresDirection: true),
    LexiconEntry(term: 'kavrayışsız', category: ToxicityCategory.asagilama, severity: 0.38, requiresDirection: true),
    // "bu telefon beş para etmez" — ürün yorumu; yalnızca yöneltilince.
    LexiconEntry(term: 'beş para etmez', category: ToxicityCategory.asagilama, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'sıfırı tüketmiş', category: ToxicityCategory.asagilama, severity: 0.45),

    // ── Hakaret · karakter ───────────────────────────────────────────────
    LexiconEntry(term: 'kişiliksiz', category: ToxicityCategory.hakaret, severity: 0.70, requiresDirection: true),
    LexiconEntry(term: 'sinsi', category: ToxicityCategory.hakaret, severity: 0.48, requiresDirection: true),
    LexiconEntry(term: 'ikiyüzlü', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'riyakâr', category: ToxicityCategory.hakaret, severity: 0.52, requiresDirection: true),
    LexiconEntry(term: 'beleşçi', category: ToxicityCategory.hakaret, severity: 0.48, requiresDirection: true),
    LexiconEntry(term: 'çıkarcı', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'menfaatçi', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'vefasız', category: ToxicityCategory.hakaret, severity: 0.42, requiresDirection: true),
    LexiconEntry(term: 'köküne kadar bozuk', category: ToxicityCategory.hakaret, severity: 0.70),
    LexiconEntry(term: 'zibidi herif', category: ToxicityCategory.hakaret, severity: 0.65),

    // ── Hayvan benzetmesi (yönelim şartlı) ───────────────────────────────
    LexiconEntry(term: 'kurbağa', category: ToxicityCategory.hakaret, severity: 0.40, requiresDirection: true),
    LexiconEntry(term: 'karga', category: ToxicityCategory.hakaret, severity: 0.38, requiresDirection: true),
    LexiconEntry(term: 'akbaba', category: ToxicityCategory.hakaret, severity: 0.48, requiresDirection: true),
    // ÇIKARILDI (ölçümle): 'tilki' — mecazı çoğu zaman övgüdür; yönelim şartı
    // korumuyor, "sen tilki gibi zekisin" 0.53 ile işaretleniyordu.
    LexiconEntry(term: 'sıçan', category: ToxicityCategory.hakaret, severity: 0.55, requiresDirection: true),
    LexiconEntry(term: 'fare', category: ToxicityCategory.hakaret, severity: 0.42, requiresDirection: true),
    LexiconEntry(term: 'solucan', category: ToxicityCategory.hakaret, severity: 0.48, requiresDirection: true),
    LexiconEntry(term: 'böcek', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'hamamböceği', category: ToxicityCategory.hakaret, severity: 0.60, requiresDirection: true),
    LexiconEntry(term: 'ayı', category: ToxicityCategory.hakaret, severity: 0.42, matchMode: MatchMode.exact, requiresDirection: true),
    LexiconEntry(term: 'katır', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'manda', category: ToxicityCategory.hakaret, severity: 0.45, requiresDirection: true),

    // ── Tehdit ───────────────────────────────────────────────────────────
    // Tek kelimelik hâlleri meşru bağlamda geçtiği için hepsi ÖBEK.
    LexiconEntry(term: 'seni gebertirim', category: ToxicityCategory.tehdit, severity: 0.96),
    LexiconEntry(term: 'kafanı kırarım', category: ToxicityCategory.tehdit, severity: 0.92),
    LexiconEntry(term: 'çeneni kırarım', category: ToxicityCategory.tehdit, severity: 0.92),
    LexiconEntry(term: 'boynunu kırarım', category: ToxicityCategory.tehdit, severity: 0.94),
    LexiconEntry(term: 'ellerini kırarım', category: ToxicityCategory.tehdit, severity: 0.90),
    LexiconEntry(term: 'gözünü oyarım', category: ToxicityCategory.tehdit, severity: 0.94),
    LexiconEntry(term: 'kafanı koparırım', category: ToxicityCategory.tehdit, severity: 0.94),
    LexiconEntry(term: 'seni ezerim', category: ToxicityCategory.tehdit, severity: 0.82),
    LexiconEntry(term: 'seni mahvederim', category: ToxicityCategory.tehdit, severity: 0.85),
    LexiconEntry(term: 'seni yok ederim', category: ToxicityCategory.tehdit, severity: 0.90),
    LexiconEntry(term: 'seni perişan ederim', category: ToxicityCategory.tehdit, severity: 0.82),
    LexiconEntry(term: 'nerede oturduğunu biliyorum', category: ToxicityCategory.tehdit, severity: 0.88),
    LexiconEntry(term: 'seni bulurum', category: ToxicityCategory.tehdit, severity: 0.78),
    // "bu davanın peşini bırakmam" — kararlılık beyanı; yalnızca yöneltilince.
    LexiconEntry(term: 'peşini bırakmam', category: ToxicityCategory.tehdit, severity: 0.65, requiresDirection: true),
    LexiconEntry(term: 'yaşatmam seni', category: ToxicityCategory.tehdit, severity: 0.92),
    LexiconEntry(term: 'ailene zarar', category: ToxicityCategory.tehdit, severity: 0.95),
    // ÇIKARILDI (ölçümle): 'çoluk çocuğuna' — tehdit fiili taşımayan öbek
    // "çoluk çocuğuna iyi bak" cümlesini 0.70 ile işaretliyordu.

    // ── Taciz ────────────────────────────────────────────────────────────
    // ÇIKARILDI (ölçümle): 'soyun' — "soy" + iyelik ekiyle birebir aynı
    // yazılır; "senin soyun nereden geliyor" 0.75 ile işaretleniyordu.
    LexiconEntry(term: 'çıplak fotoğraf', category: ToxicityCategory.taciz, severity: 0.80),
    LexiconEntry(term: 'resmini gönder', category: ToxicityCategory.taciz, severity: 0.45, requiresDirection: true),
    LexiconEntry(term: 'yalnız mısın', category: ToxicityCategory.taciz, severity: 0.30, requiresDirection: true),
    LexiconEntry(term: 'seni izliyorum', category: ToxicityCategory.taciz, severity: 0.70),
    LexiconEntry(term: 'peşindeyim', category: ToxicityCategory.taciz, severity: 0.65),
    // Yalın "nerede yaşadığını" kargo ve adres sorusunu da yakalıyordu;
    // tehdit olan, bilginin ELDE olduğunun söylenmesidir.
    LexiconEntry(term: 'nerede yaşadığını biliyorum', category: ToxicityCategory.tehdit, severity: 0.88),

    // ── Aşağılama · içeriğin reddi ───────────────────────────────────────
    LexiconEntry(term: 'saçmalık', category: ToxicityCategory.asagilama, severity: 0.32, requiresDirection: true),
    LexiconEntry(term: 'ipe sapa gelmez', category: ToxicityCategory.asagilama, severity: 0.42),
    LexiconEntry(term: 'kof', category: ToxicityCategory.asagilama, severity: 0.35, matchMode: MatchMode.exact, requiresDirection: true),
    // ÇIKARILDI (ölçümle): 'sudan sebep' — kişiye değil gerekçeye yönelik
    // bir betimleme; "sudan sebeplerle kavga ettiler" anlatısını işaretliyordu.
    LexiconEntry(term: 'komedi', category: ToxicityCategory.asagilama, severity: 0.28, requiresDirection: true),
    LexiconEntry(term: 'trajikomik', category: ToxicityCategory.asagilama, severity: 0.30, requiresDirection: true),
  ];
}

