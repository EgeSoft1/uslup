// =============================================================================
// NSosyal Sosyal YZ — Bağlam Çözümleme Katmanı
// Dosya: packages/civility_core/lib/src/context/context_analyzer.dart
//
// PROJENİN TEKNİK KALBİ BURASIDIR.
//
// Sözlük eşleşmesi tek başına değersizdir. Aynı kelime, bağlama göre
// tamamen farklı şeyler ifade eder:
//
//   "aptalsın"                → SALDIRI          (şiddet ×1.35)
//   "aptal değilsin"          → İLTİFAT          (şiddet ×0.15)
//   "kendimi aptal hissettim" → ÖZ-İFADE         (şiddet ×0.20)
//   "bana 'aptal' dedi"       → ŞİKÂYET/AKTARIM  (şiddet ×0.30)
//   "APTALSIN!!!"             → ŞİDDETLİ SALDIRI (şiddet ×1.35×1.15×1.10)
//
// Mevcut moderasyon sistemlerinin en büyük başarısızlığı 3. ve 4. satırdır:
// tacize UĞRAYAN kişi durumu anlatırken cezalandırılır. Bu katman tam olarak
// bunu engellemek için vardır — ve "etik, ölçülebilir yapay zekâ"
// gerekliliğinin somut karşılığıdır.
//
// Türkçe'ye özgü zorluk: yönelim bilgisi ayrı bir kelimede DEĞİL, kelimenin
// EKİNDE taşınır. İngilizce "you are stupid" üç kelimedir; Türkçe'de
// "aptalsın" tek kelimedir. Bu yüzden ek çözümlemesi zorunludur.
// =============================================================================

import '../normalization/tokenizer.dart';

/// Metnin tamamı için hesaplanan bağlam sinyalleri.
class ContextSignals {
  /// Metinde ikinci şahıs zamiri geçiyor mu? ("sen", "sana", "sizi"...)
  final bool hasSecondPersonPronoun;

  /// Metinde birinci şahıs göstergesi var mı? ("ben", "kendimi"...)
  final bool hasFirstPersonMarker;

  /// Metinde bir kullanıcı etiketi (@kullanici) var mı?
  /// Etiket varsa ifade neredeyse kesinlikle birine yöneliktir.
  final bool hasMention;

  /// Büyük harf oranı [0.0 – 1.0]. Yüksekse "bağırma" göstergesi.
  final double capsRatio;

  /// Arka arkaya en fazla kaç ünlem/soru işareti var? ("!!!" → 3)
  final int punctuationBurst;

  /// Aktarma fiili var mı? ("dedi", "demiş", "diyor", "yazmış")
  final bool hasReportedSpeech;

  /// Orijinal metindeki tırnak içi aralıklar.
  /// Tırnak içindeki ifade konuşanın kendi sözü değildir.
  final List<({int start, int end})> quotedRanges;

  /// Her token'ın ait olduğu cümlenin sırası (token listesiyle aynı sırada).
  ///
  /// Boşsa cümle sınırı bilinmiyor demektir ve pencereler eskisi gibi
  /// sınırsız çalışır. Gerekçe: [ContextAnalyzer.analyze].
  final List<int> tokenSentences;

  const ContextSignals({
    required this.hasSecondPersonPronoun,
    required this.hasFirstPersonMarker,
    required this.hasMention,
    required this.capsRatio,
    required this.punctuationBurst,
    required this.hasReportedSpeech,
    required this.quotedRanges,
    this.tokenSentences = const [],
  });
}

/// Tek bir sözlük eşleşmesi için hesaplanan bağlam kararı.
class MatchContext {
  /// İkinci şahsa yöneltilmiş mi? (saldırı göstergesi)
  final bool isDirected;

  /// Olumsuzlanmış mı? ("aptal DEĞİLSİN")
  final bool isNegated;

  /// Konuşanın kendisine mi yönelik? ("kendimi aptal hissettim")
  final bool isSelfDirected;

  /// Alıntı veya aktarım içinde mi? ("bana 'aptal' dedi")
  final bool isQuoted;

  /// Taban şiddetle çarpılacak katsayı.
  final double multiplier;

  const MatchContext({
    required this.isDirected,
    required this.isNegated,
    required this.isSelfDirected,
    required this.isQuoted,
    required this.multiplier,
  });

  /// Bu eşleşme neden yumuşatıldı/sertleştirildi? Şeffaflık paneli için.
  String? get reason {
    if (isNegated) return 'Olumsuz cümle — saldırı sayılmadı';
    if (isQuoted) return 'Alıntı/aktarım — başkasının sözü';
    if (isSelfDirected) return 'Kendine yönelik ifade — saldırı sayılmadı';
    // Kategori açıklamaları çoğu zaman "Doğrudan…" diye başlar; aynı kelimeyle
    // başlayan bir gerekçe ekranda "Doğrudan … (Doğrudan …)" tekrarı üretiyordu.
    if (isDirected) return 'karşıdaki kişiye yöneltilmiş';
    return null;
  }
}

class ContextAnalyzer {
  const ContextAnalyzer();

  // ───────────────────────────────────────────────────────────────────────────
  // TÜRKÇE BAĞLAM İŞARETLEYİCİLERİ
  // Tümü normalize edilmiş (aksansız) hâlde yazılmıştır: ı→i, ü→u, ş→s ...
  // ───────────────────────────────────────────────────────────────────────────

  /// İkinci şahıs zamirleri ve çekimli hâlleri.
  static const Set<String> _secondPerson = {
    'sen', 'sana', 'seni', 'senin', 'sende', 'senden', 'seninle',
    'siz', 'size', 'sizi', 'sizin', 'sizde', 'sizden', 'sizinle',
    // İP-24: SORU EKİ ikinci şahsa yöneliktir ve ayrı bir kelimedir.
    // Eksikliği ölçümle bulundu: "salak mısın nesin" yönelimsiz sayılıyor,
    // dolayısıyla şiddeti düşük kalıyor ve yeniden yazıcı öbek moduna
    // geçemeyip bozuk çıktı üretiyordu ("Yanlış mısın nesin").
    'misin', 'mısın', 'musun', 'müsün',
    'misiniz', 'mısınız', 'musunuz', 'müsünüz',
  };

  /// Birinci şahıs göstergeleri.
  static const Set<String> _firstPerson = {
    'ben', 'bana', 'beni', 'benim', 'bende', 'benden',
    'kendimi', 'kendime', 'kendim', 'kendimde',
    'biz', 'bize', 'bizi', 'bizim',
  };

  /// Olumsuzlayıcılar. "aptal DEĞİLSİN" → saldırı değil.
  ///
  /// "hiç" ve "hiçbir" KASITLI olarak listede değildir. Bunlar Türkçe'de
  /// yüklemi değil, ad öbeğini niteler ve çoğu zaman PEKİŞTİRİCİDİR:
  ///   "hiçbir işe yaramazsın" → olumsuzlama değil, ağır hakaret
  /// Listede olmaları, en sert kalıplardan birini kaçış yoluna çeviriyordu.
  /// Gerçek olumsuzlama zaten "değil" / "yok" ile kurulur.
  static const Set<String> _negators = {
    'degil', 'degilsin', 'degilsiniz', 'degildi', 'degilim',
    'asla',
  };

  /// VARLIK olumsuzlaması — ayrı ele alınır ve YALNIZCA bitişik konumda
  /// olumsuzlayıcı sayılır.
  ///
  /// ── NEDEN AYRI (İP-19, 24 Ağustos 2026) ─────────────────────────────────
  /// "yok" başlangıçta `_negators` içindeydi ve iki token ileriye kadar
  /// taranıyordu. Bu, ölçümle bulunan bir kaçış yolu üretiyordu:
  ///
  ///   "burada senin gibilere yer YOK"     → temiz (0.00)  ✗
  ///   "senin gibilere tahammülüm YOK"     → temiz (0.00)  ✗
  ///
  /// Çünkü "yok" burada saldırıyı değil, ARADAKİ BAŞKA BİR ADI olumsuzluyor
  /// ("yer", "tahammülüm"). "değil" yüklem olumsuzlayıcısıdır ve araya
  /// kelime alabilir ("aptal da değilsin"); "yok" ise varlık olumsuzlayıcısı
  /// olarak doğrudan kendi adına bitişir. Bu yüzden penceresi tek token'dır:
  ///
  ///   "burada aptal yok"    → olumsuzlama geçerli (bitişik)
  ///   "aptalsın, param yok" → olumsuzlama geçersiz (araya ad girmiş)
  static const Set<String> _existentialNegators = {'yok', 'yoktur'};

  /// FİİL olumsuzluk çekimleri.
  ///
  /// Türkçe'de olumsuzluk ayrı bir kelime olmak zorunda değildir; "-ma/-me"
  /// eki yükleme girer: "seni aptal SANMIYORUM". Yalnızca kelime listesine
  /// bakan bir kural bunu göremez ve masum bir cümleyi hakaret sayar.
  ///
  /// Liste kasıtlı olarak dardır. "-maz/-mez" gibi geniş zaman olumsuzları
  /// BİLEREK dışarıda bırakılmıştır: "senden adam OLMAZ" olumsuz bir
  /// yüklemdir ama saldırının ta kendisidir.
  static const List<String> _negativeVerbSuffixes = [
    'miyorum', 'muyorum', 'miyoruz', 'muyoruz', 'miyor', 'muyor',
    'madim', 'medim', 'mam', 'mem',
  ];

  /// YETERLİLİK olumsuzu — olumsuzlayıcı SAYILMAZ.
  ///
  /// "-amam/-emem" biçimsel olarak olumsuzdur ("uğraşAMAM") ama anlamca
  /// bir reddetme jestidir ve çoğu zaman saldırının ta kendisidir:
  ///   "senin gibi tiplerle uğraşamam"  → ötekileştirme
  ///   "seviyene inip tartışamam"       → üstünlük iddiası
  /// Bunları olumsuzlama sayan bir kural, en açık küçümseme kalıplarını
  /// kendi eliyle temizler. (Bu regresyon ölçümle yakalandı.)
  static const List<String> _abilityNegativeSuffixes = [
    'amam', 'emem', 'amayiz', 'emeyiz',
  ];

  /// Kişiye yönelik aşağılayıcı ad çekirdekleri.
  ///
  /// Yönelim göstergesi sayılırlar: "domuz herif" ifadesinde ikinci şahıs
  /// eki veya zamir yoktur, ama "herif" kelimesi ifadenin bir KİŞİYE
  /// yöneltilmiş yakıştırma olduğunu belirler. Bu olmadan hayvan
  /// benzetmelerinin en yaygın kalıbı kör noktada kalıyordu.
  static const Set<String> _pejorativeHeads = {
    'herif', 'herifin', 'herife', 'herifi', 'herifler',
    'mahluk', 'yaratik', 'moruk',
    // İP-19: "hıyarın önde gideni", "şerefsizin tekisin" — ikinci şahıs
    // eki yok ama yönelim aşağılayıcı tamlamanın kendisiyle kuruluyor.
    'onde', 'gideni', 'teki', 'tekisin',
    // İP-21 · PEKİŞTİREÇ ADLARI. Bunlar kendileri hakaret değildir; önlerine
    // geldikleri sözcüğü bir EPİTETE çevirirler ve o sözcüğün muhataba
    // yöneltildiğini kesinleştirirler:
    //   "terbiyesizliğin daniskası"  ·  "yalancının âlâsı"  ·  "ezik kralı"
    // Ölçümde "terbiyesizliğin daniskası bu" yönelim bulunamadığı için
    // kaçıyordu — sözlük girdisi `requiresDirection` taşıyordu.
    'daniskasi', 'daniskası', 'alasi', 'krali', 'dikalasi', 'resmen',
  };

  /// Aktarma fiilleri. "bana aptal DEDİ" → şikâyet, saldırı değil.
  static const Set<String> _reportedSpeech = {
    'dedi', 'dedin', 'dediler', 'demis', 'diyor', 'diyorlar', 'diye',
    'yazmis', 'yazdi', 'soyledi', 'cagirdi', 'hitap',
    'denildi', 'deniyor',
    // Ortaç (sıfat-fiil) hâlleri: "sana salak DİYEN haksız" — mağduru
    // savunan bir cümledir ve cezalandırılmamalıdır.
    'diyen', 'diyene', 'diyenler', 'dedigi', 'dedigin', 'demesi',
    // D8 (docs/22): düşmanca görüşü BAŞKASINA atfeden sıfat-fiil ve
    // ad-fiiller. "Ermenilerin yok edilmesini SAVUNANLAR yargılanmalı"
    // nefret söylemi değil, kınamadır; "diyen" ile aynı ilke. Bedeli
    // kayıtlıdır: aynı yapıyla ONAYLAYAN cümle de yumuşar.
    'isteyen', 'isteyenler', 'isteyenlere', 'isteyenleri',
    'savunan', 'savunanlar', 'savunanlara', 'savunanlari',
    'soyleyen', 'soyleyenler', 'soyleyenlere', 'soyleyenleri',
    'iddia',
    'dendigi', 'dendiginde', 'denmesi',
    'yazan', 'yazanlar',
    'bagiran', 'bagiranlar',
  };

  /// İkinci şahıs bildirme (kopula) ekleri — normalize hâlleriyle.
  /// Türkçe: -sın/-sin/-sun/-sün → "sin"/"sun"
  ///         -sınız/-siniz/-sunuz/-sünüz → "siniz"/"sunuz"
  static const List<String> _secondPersonSuffixes = [
    'siniz', 'sunuz', 'sin', 'sun',
    // İP-24: GÖRÜLEN GEÇMİŞ ZAMAN ikinci şahıs eki — "davrandın", "yaptın",
    // "konuştun". Eksikliği "avanak gibi davrandın" cümlesini yönelimsiz
    // gösteriyordu.
    //
    // Bu ekler ad köklerinde de görünür — "kadın", "aydın", "altın". Onları
    // [_endsWithAny] içindeki uzunluk koşulu eler: kelime, ekten en az üç
    // harf uzun olmak zorundadır. Üçü de beş harflidir ve eşiğin altında
    // kalır; "davrandın" (9), "yaptın" (6), "konuştun" (8) geçer.
    //
    // Eşiği aşan ve fiil olmayan biçimler ("vaktin", "bulutun") ikinci şahıs
    // İYELİK ekidir — yani yönelim göstergesi sayılmaları zaten doğrudur.
    'din', 'dun', 'tin', 'tun',
  ];

  /// Birinci şahıs bildirme ekleri: -ım/-im/-um/-üm → "im"/"um"
  static const List<String> _firstPersonSuffixes = ['yim', 'yum', 'im', 'um'];

  /// Birinci şahıs FİİL çekimleri — yakın kelimelerde aranır.
  ///
  /// Neden gerekli: ölçüm, "aptalca bir hata YAPTIM" ve "çok salakça
  /// DAVRANDIM" cümlelerinin yanlış pozitif ürettiğini gösterdi. Öz-yönelim
  /// yalnızca zamirden ("kendimi", "ben") okunuyordu; oysa Türkçe'de özne
  /// çoğu zaman düşer ve kişi bilgisi FİİL EKİNDE taşınır.
  ///
  /// Liste kasıtlı olarak dardır: kısa ve yaygın ekler ("-im", "-um") burada
  /// yoktur, çünkü yakın kelime taramasında aşırı tetiklenirler.
  static const List<String> _firstPersonVerbSuffixes = [
    'yorum', 'acagim', 'ecegim', 'misim', 'dim', 'dum', 'tim', 'tum',
  ];

  /// Soru edatları. Olumsuzlamadan HEMEN SONRA gelirlerse cümle retoriktir:
  /// "aptal DEĞİL MİSİN" bir olumsuzlama değil, örtülü bir iddiadır.
  static const Set<String> _interrogatives = {
    'mi', 'mu', 'misin', 'misiniz', 'musun', 'musunuz',
    'miyim', 'miyiz', 'midir', 'mudur',
  };

  /// Tırnak karakterleri (açan/kapayan ayrımı yapmadan), kod birimi olarak:
  /// `" ' « » “ ” ‘ ’` — hepsi tek kod biriminde yazılır.
  static const Set<int> _quoteCodes = {
    0x22, 0x27, 0xAB, 0xBB, 0x201C, 0x201D, 0x2018, 0x2019,
  };

  // ───────────────────────────────────────────────────────────────────────────
  // HAM METİN TARAMALARI İÇİN HARF TABLOSU (docs/28)
  //
  // Büyük harf oranı, tırnak aralıkları ve cümle sınırları ham metnin
  // tamamını dolaşır. Eski sürüm her karakterde `text[i]`, `toLowerCase()` ve
  // `toUpperCase()` çağırıyordu: karakter başına üç String ayırma, metin
  // başına üç geçiş. 2.760 karakterlik bir gönderide motorun 4,1 ms'sinin
  // 0,61 ms'si buradaydı.
  //
  // Harflik ve büyüklük karakterin kendisine bağlıdır, yani önceden
  // hesaplanabilir. Tablo Latin bloklarını (0x000–0x2FF) kapsar — Türkçe
  // metnin karakterlerinin tamamına yakını buraya düşer; üstü eski yoldan
  // hesaplanır.
  //
  // Tanım eski sürümle aynı tutulur: "büyük/küçük hâli farklı olan karakter
  // harftir", "kendi büyük hâline eşit olan harf büyüktür". 'ß' gibi büyük
  // hâli iki karaktere açılan harfler böylece harf sayılır ama büyük
  // sayılmaz — eski davranış buydu.
  // ───────────────────────────────────────────────────────────────────────────

  static final List<bool> _latinIsLetter =
      List<bool>.generate(0x300, (c) => _computeIsLetter(String.fromCharCode(c)));

  static final List<bool> _latinIsUpper =
      List<bool>.generate(0x300, (c) => _computeIsUpper(String.fromCharCode(c)));

  static bool _computeIsLetter(String ch) => ch.toLowerCase() != ch.toUpperCase();

  static bool _computeIsUpper(String ch) => ch == ch.toUpperCase();

  static bool _isLetterCode(int c) => c < 0x300
      ? _latinIsLetter[c]
      : _computeIsLetter(String.fromCharCode(c));

  static bool _isUpperCode(int c) => c < 0x300
      ? _latinIsUpper[c]
      : _computeIsUpper(String.fromCharCode(c));

  /// `String.trim()`'in boşluk saydığı karakterler.
  ///
  /// Cümle sınırı kararı "noktadan sonra boşluk var mı" sorusuna dayanır ve
  /// eski sürüm bunu `sonraki.trim().isEmpty` ile soruyordu — karakter başına
  /// bir String ayırma. Küme birebir aynıdır.
  static bool _isTrimWhitespace(int c) {
    if (c == 0x20) return true;
    if (c >= 0x09 && c <= 0x0D) return true;
    if (c < 0x80) return false;
    if (c == 0x85 || c == 0xA0 || c == 0x1680) return true;
    if (c >= 0x2000 && c <= 0x200A) return true;
    return c == 0x2028 ||
        c == 0x2029 ||
        c == 0x202F ||
        c == 0x205F ||
        c == 0x3000 ||
        c == 0xFEFF;
  }

  /// Eşleşmenin çevresinde kaç token geriye/ileriye bakılacağı.
  static const int _windowSize = 4;

  /// Kullanıcı etiketi: metin başında ya da boşluktan sonra gelen `@ad`.
  ///
  /// ── NEDEN ÇIPLAK `@` DEĞİL (denetim D9 · docs/23) ──────────────────────
  /// Önceki kural metinde herhangi bir yerde `@` geçmesini yeterli sayıyordu.
  /// E-posta adresi yazan kişi, metnindeki her yönelim şartlı adı muhataba
  /// söylemiş sayılıyordu:
  ///
  ///   "ali@ornek.com adresine köpek fotoğrafı attım" → Yüksek risk ✗
  ///
  /// Etiket bir KELİME BAŞIDIR; adresin ortasındaki `@` değildir.
  static final RegExp _mention =
      RegExp(r'(?:^|\s)@[A-Za-z0-9_çğıöşüÇĞİÖŞÜ]');

  // ───────────────────────────────────────────────────────────────────────────

  /// Metnin tamamı için genel bağlam sinyallerini hesaplar.
  ///
  /// [original] ham metin (büyük harf ve tırnaklar burada korunur),
  /// [tokens] normalize edilmiş token listesi.
  ///
  /// [sourceIndices] normalize metnin her karakterinin orijinal metindeki
  /// konumudur (`NormalizedText.sourceIndices`). Verilirse her token'ın
  /// CÜMLESİ hesaplanır ve bağlam pencereleri cümle sınırını aşmaz.
  ///
  /// ── NEDEN (docs/24 · madde 13) ────────────────────────────────────────────
  /// Normalizasyon noktalamayı boşluğa indirdiği için pencereler bir önceki
  /// cümleye taşıyordu. Ölçülen kaçışlar:
  ///
  ///   "Yarın gelmiyorum. Aptal herif"  → önceki cümlenin olumsuz fiili
  ///                                     hakareti "olumsuzluyordu" → Temiz ✗
  ///   "Ne dedin? Aptal mısın"          → önceki cümlenin "dedin"i hakareti
  ///                                     aktarım sayıyordu → Temiz ✗
  ///
  /// Olumsuzlama, aktarım ve yönelim bir cümlenin içinde kurulur.
  ContextSignals analyze(
    String original,
    List<Token> tokens, {
    List<int>? sourceIndices,
  }) {
    bool secondPerson = false;
    bool firstPerson = false;
    bool reported = false;

    for (final token in tokens) {
      if (_secondPerson.contains(token.text)) secondPerson = true;
      if (_firstPerson.contains(token.text)) firstPerson = true;
      if (_reportedSpeech.contains(token.text)) reported = true;
    }

    return ContextSignals(
      hasSecondPersonPronoun: secondPerson,
      hasFirstPersonMarker: firstPerson,
      hasMention: _mention.hasMatch(original),
      capsRatio: _capsRatio(original),
      punctuationBurst: _punctuationBurst(original),
      hasReportedSpeech: reported,
      quotedRanges: _findQuotedRanges(original),
      tokenSentences: sourceIndices == null
          ? const []
          : _tokenSentences(original, tokens, sourceIndices),
    );
  }

  /// Cümle sonu: `. ! ? …` ardından boşluk ya da metin sonu, veya satır sonu.
  /// "a.p.t.a.l" ve "3.5" gibi boşluksuz noktalar cümle bitirmez.
  static List<int> _tokenSentences(
      String original, List<Token> tokens, List<int> sourceIndices) {
    // sinirOncesi[i] = original[0..i) aralığındaki cümle sonu sayısı
    final sinirOncesi = List<int>.filled(original.length + 1, 0);
    var sayac = 0;
    for (var i = 0; i < original.length; i++) {
      final c = original.codeUnitAt(i);
      // '\n' · '.' · '!' · '?' · '…'
      final bitis = c == 0x0A ||
          ((c == 0x2E || c == 0x21 || c == 0x3F || c == 0x2026) &&
              (i + 1 == original.length ||
                  _isTrimWhitespace(original.codeUnitAt(i + 1))));
      if (bitis) sayac++;
      sinirOncesi[i + 1] = sayac;
    }

    return [
      for (final t in tokens)
        if (sourceIndices.isEmpty)
          0
        else
          sinirOncesi[sourceIndices[t.start.clamp(0, sourceIndices.length - 1)]
              .clamp(0, original.length)],
    ];
  }

  /// İki token aynı cümlede mi? Cümle bilgisi yoksa her zaman evet.
  static bool _ayniCumle(List<int> cumleler, int i, int j) =>
      cumleler.isEmpty ||
      i >= cumleler.length ||
      j >= cumleler.length ||
      cumleler[i] == cumleler[j];

  /// Belirli bir eşleşme için bağlam kararını üretir.
  ///
  /// [matchIndex] eşleşen token'ın [tokens] içindeki sırası,
  /// [originalRange] eşleşmenin ham metindeki aralığı.
  /// [matchEndIndex] çok kelimeli eşleşmelerde son token'ın sırası.
  /// Verildiğinde, eşleşmenin KENDİ İÇİNDEKİ kelimeler bağlam taramasından
  /// dışlanır. Bu şarttır: "senin harcın DEĞİL bu iş" kalıbında olumsuzlayıcı
  /// kalıbın parçasıdır ve onu yumuşatmak için değil, kurmak için oradadır.
  /// Dışlama olmadan kalıp kendi kendini iptal ediyordu.
  ///
  /// [selfDirectionApplies] false ise öz-yönelim hiç hesaplanmaz. Tehdit
  /// kategorisi için zorunludur: "öldürürüm" birinci şahıs çekimlidir ama
  /// öz-ifade değil, tehdittir. Edimbilimsel örüntülerde de kapalıdır —
  /// hedefi zaten kalıbın kendisi belirler.
  ///
  /// [negationApplies] false ise olumsuzlama hiç hesaplanmaz. Müstehcen
  /// küfür için kullanılır (docs/25): "aptal değilsin" bir iltifattır ama
  /// "sikimde değil" küfrün kendisidir — olumsuzlanan küfür değil, deyimdir.
  MatchContext evaluateMatch({
    required List<Token> tokens,
    required int matchIndex,
    required ({int start, int end}) originalRange,
    required ContextSignals signals,
    int? matchEndIndex,
    bool selfDirectionApplies = true,
    bool negationApplies = true,
  }) {
    final token = tokens[matchIndex];
    final spanEnd = matchEndIndex ?? matchIndex;
    // Bütün pencereler eşleşmenin kendi cümlesiyle sınırlıdır (docs/24 · 13).
    final cumleler = signals.tokenSentences;

    // ── 1. YÖNELİM: ikinci şahsa mı söylenmiş? ──────────────────────────────
    // ÜÇ kaynaktan gelebilir:
    //   (a) Kelimenin kendi eki: "aptalSIN"
    //   (b) Yakındaki zamir: "SEN aptal"
    //   (c) Yakındaki kelimenin eki: "alçak herifSİN", "maymun gibi
    //       davranıyorSUN"
    //
    // (c) ölçümle eklendi: "alçak herifsin", "öküz gibisin", "hayvan gibi
    // konuşuyorsun" gibi cümleler kaçıyordu. Yönelim şartlı terimler
    // (hayvan adları, çokanlamlılar) yönelim görülemediği için tamamen
    // eleniyordu — yani en yaygın hakaret kalıplarından biri kör noktaydı.
    final hasSecondPersonSuffix = _endsWithAny(token.text, _secondPersonSuffixes);
    final nearSecondPerson =
        _windowContains(tokens, matchIndex, spanEnd, _secondPerson,
            cumleler: cumleler);
    final nearSecondPersonSuffix =
        _windowHasSuffix(tokens, matchIndex, spanEnd, _secondPersonSuffixes,
            cumleler: cumleler);
    final nearPejorativeHead =
        _windowContains(tokens, matchIndex, spanEnd, _pejorativeHeads,
            cumleler: cumleler);
    final isDirected = hasSecondPersonSuffix ||
        nearSecondPerson ||
        nearSecondPersonSuffix ||
        nearPejorativeHead ||
        signals.hasMention;

    // ── 2. ÖZ-YÖNELİM: konuşan kendinden mi bahsediyor? ─────────────────────
    // "kendimi aptal hissettim" / "aptalım galiba" / "aptalca davrandIM"
    //
    // Not: ikinci şahıs göstergesi varsa öz-yönelim olamaz — "aptalsın"
    // kendine söylenmez. Bu kontrol çelişkiyi önler ve "seni geberteceğim"
    // gibi cümlelerin (birinci şahıs fiil + ikinci şahıs nesne) yanlışlıkla
    // yumuşatılmasını engeller.
    final hasFirstPersonSuffix = _endsWithAny(token.text, _firstPersonSuffixes);
    final nearFirstPerson =
        _windowContains(tokens, matchIndex, spanEnd, _firstPerson,
            cumleler: cumleler);
    final nearFirstPersonVerb =
        _windowHasSuffix(tokens, matchIndex, spanEnd, _firstPersonVerbSuffixes,
            cumleler: cumleler);
    final isSelfDirected = selfDirectionApplies &&
        !hasSecondPersonSuffix &&
        !nearSecondPerson &&
        !nearSecondPersonSuffix &&
        (hasFirstPersonSuffix || nearFirstPerson || nearFirstPersonVerb);

    // ── 3. OLUMSUZLAMA ──────────────────────────────────────────────────────
    // Türkçe'de olumsuzlayıcı SONRA gelir: "aptal değilsin".
    // Bu yüzden pencere ileri yönde daha dar (2 token) taranır.
    //
    // RETORİK İSTİSNA: olumsuzlayıcıyı bir soru edatı izliyorsa cümle
    // olumsuz DEĞİLDİR — tam tersine örtülü bir iddiadır:
    //   "aptal değilsin"   → iltifat    (olumsuzlama geçerli)
    //   "aptal değil misin" → hakaret   (olumsuzlama geçersiz)
    // Bu ayrım olmadan, olumsuzlama kuralı bir hakaret kaçış yolu olur.
    final isNegated = negationApplies &&
        (_windowContains(
              tokens,
              matchIndex,
              spanEnd,
              _negators,
              backward: 1,
              forward: 2,
              cumleler: cumleler,
            ) ||
            // Varlık olumsuzlaması yalnızca BİTİŞİK konumda geçerlidir.
            _windowContains(
              tokens,
              matchIndex,
              spanEnd,
              _existentialNegators,
              backward: 0,
              forward: 1,
              cumleler: cumleler,
            ) ||
            _hasNegativeVerb(tokens, matchIndex, spanEnd, cumleler)) &&
        !_hasRhetoricalNegation(tokens, matchIndex, cumleler);

    // ── 4. ALINTI / AKTARIM ─────────────────────────────────────────────────
    // Tırnak içindeyse ya da yakınında aktarma fiili varsa, bu ifade
    // konuşanın kendi saldırısı değildir — büyük ihtimalle şikâyet ediyor.
    final inQuotes = _isInsideQuotes(originalRange, signals.quotedRanges);
    final nearReporting = _windowContains(
        tokens, matchIndex, spanEnd, _reportedSpeech,
        forward: 3, cumleler: cumleler);
    final isQuoted = inQuotes || nearReporting;

    // ── 5. KATSAYI HESABI ───────────────────────────────────────────────────
    // Yumuşatıcılar çarpımsal ve baskın; sertleştiriciler ılımlı.
    // Sıralama önemli: en güçlü yumuşatıcı önce uygulanır.
    double multiplier = 1.0;

    // Yumuşatma katsayıları, motorun `0.12` eleme eşiğiyle birlikte
    // ayarlanmıştır: tipik bir hakaretin taban şiddeti ~0.55 olduğundan
    // 0.20 katsayısı sonucu 0.11'e indirir ve bulgu tamamen elenir.
    // Yani "aptal değilsin" / "bana aptal dedi" hiçbir uyarı üretmez.
    if (isNegated) {
      multiplier *= 0.15; // "aptal değilsin" → pratikte zararsız
    } else if (isQuoted) {
      multiplier *= 0.20; // aktarım → mağdur cezalandırılmamalı
    } else if (isSelfDirected) {
      multiplier *= 0.20; // öz-ifade → müdahale edilmemeli
    } else if (isDirected) {
      multiplier *= 1.25; // doğrudan saldırı → sertleştir
    }

    // Bağırma: yalnızca anlamlı uzunluktaki metinlerde sayılır.
    // Kısa metinde ("OK", "EVET") büyük harf oranı yanıltıcıdır.
    if (signals.capsRatio > 0.6) {
      multiplier *= 1.15;
    }

    // Noktalama patlaması: "!!!" öfke yoğunluğu göstergesi
    if (signals.punctuationBurst >= 3) {
      multiplier *= 1.10;
    }

    return MatchContext(
      isDirected: isDirected,
      isNegated: isNegated,
      isSelfDirected: isSelfDirected,
      isQuoted: isQuoted,
      multiplier: multiplier,
    );
  }

  // ─── Yapısal yönelim (D7 · docs/21) ───────────────────────────────────────

  /// Hitapta ad ile zamir arasına girebilen kelimeler: "sen TAM BİR öküz",
  /// "seni GİDİ domuz", "sen NE BİÇİM bir hayvan".
  static const Set<String> _addressFillers = {
    'tam', 'bir', 'gidi', 'resmen', 'koca', 'ne', 'bicim',
  };

  /// Yalın ve belirtme hâlindeki ikinci şahıs zamirleri — hitap ve yüklem
  /// kurabilen biçimler. "sana", "senin", "senden" BİLEREK yoktur.
  static const Set<String> _addressPronouns = {'sen', 'seni', 'siz', 'sizi'};

  /// İkinci şahsa yönelik soru ekleri (normalize): "köpek MİSİN".
  static const Set<String> _secondPersonQuestion = {
    'misin', 'musun', 'misiniz', 'musunuz',
  };

  /// Yalnızca ikinci şahıs BİLDİRME ekleri (görülen geçmiş hariç).
  static const List<String> _copulaSuffixes = ['siniz', 'sunuz', 'sin', 'sun'];

  /// Adı bir KONU yapan ilgeçler: "maymunlar hakkında", "köpek için".
  static const Set<String> _topicPostpositions = {
    'hakkinda', 'hakkindaki', 'konusunda', 'konusundaki', 'uzerine',
    'ile', 'icin', 'ilgili',
  };

  /// Belirtisiz tamlama başı: üçüncü tekil iyelik (+ hâl eki).
  /// "sülük tedavisi(ne)", "hayvan hakları(nı)", "köpek maması".
  static final RegExp _compoundHead = RegExp(
      r'^[a-z]{2,}(?:[^aeiouy][iu]|s[iu])(?:n?[ae]|n?[iu]|nd[ae]|nd[ae]n|n[iu]n)?$');

  /// İyelik biçiminde görünen ama tamlama başı olmayan sık kelimeler.
  static const Set<String> _notCompoundHeads = {
    'gibi', 'bile', 'degil', 'simdi', 'hani', 'yani', 'sanki', 'belki',
    'resmi', 'hepsi', 'kendisi', 'birisi', 'biri',
  };

  /// Somut bir ad muhataba YAKIŞTIRILMIŞ mı? (D7)
  ///
  /// `evaluateMatch` yönelimi yakınlıkla arar: dört kelime içinde "sana"
  /// geçmesi yeter. Hayvan adları ve somut anlamı yaygın adlar için bu,
  /// "Sana köpeğimin fotoğrafını atayım" cümlesini Yüksek risk yapıyordu.
  /// Bu yöntem YAPI arar; biri yeterlidir:
  ///
  ///   1. kelimenin kendi bildirme eki   → "öküzsün"
  ///   2. önünde hitap zamiri            → "sen tam bir öküz", "seni gidi domuz"
  ///   3. ardında zamir ya da soru eki   → "köpek sen", "köpek misin"
  ///   4. yakınında aşağılayıcı baş      → "eşek herif", "sırtlanın tekisin"
  ///   5. "gibi" + ikinci şahıs yüklem   → "maymun gibi davranıyorsun"
  ///   6. @bahsetme                      → "@ali köpek"
  bool isPredicativelyDirected({
    required List<Token> tokens,
    required int matchIndex,
    required ContextSignals signals,
  }) {
    final token = tokens[matchIndex];
    final cumleler = signals.tokenSentences;

    // 1
    if (_endsWithAny(token.text, _copulaSuffixes)) return true;

    // Aynı cümledeki bir sonraki kelime (yoksa null).
    final next = matchIndex + 1 < tokens.length &&
            _ayniCumle(cumleler, matchIndex + 1, matchIndex)
        ? tokens[matchIndex + 1].text
        : null;

    // ── KONU ve TAMLAMA KORUMASI (docs/24 · madde 15) ─────────────────────
    // D7'nin kalan iki yanlış alarmı İP-31 A diliminde kayıtlıydı:
    //
    //   "Sen maymunlar hakkında ödev hazırlıyordun" → Yüksek risk ✗
    //   "Sen sülük tedavisine inanıyor musun?"     → Riskli ✗
    //
    // İkisinde de ad muhataba yakıştırılmıyor: birincisinde bir KONU
    // ("… hakkında"), ikincisinde bir tamlamanın NİTELEYİCİSİ ("sülük
    // tedavisi"). Hitap kuralı (2) önündeki "sen"i görüp yönelim sayıyordu.
    if (next != null) {
      if (_topicPostpositions.contains(next)) return false;
      if (_compoundHead.hasMatch(next) &&
          !_endsWithAny(next, _copulaSuffixes) &&
          !_pejorativeHeads.contains(next) &&
          !_addressPronouns.contains(next) &&
          !_notCompoundHeads.contains(next)) {
        return false;
      }
    }

    // 2
    final cogul = token.text.endsWith('lar') || token.text.endsWith('ler');
    for (var i = matchIndex - 1, skipped = 0; i >= 0 && skipped <= 3; i--) {
      if (!_ayniCumle(cumleler, i, matchIndex)) break;
      final text = tokens[i].text;
      if (_addressPronouns.contains(text)) {
        // Tekil hitap çoğul adı yüklem yapamaz: "sen maymunlar" bir
        // yakıştırma değildir ("siz hayvanlar!" ise çoğul hitaptır).
        if (cogul && (text == 'sen' || text == 'seni')) break;
        return true;
      }
      if (!_addressFillers.contains(text)) break;
      skipped++;
    }

    // 3
    if (next != null &&
        (_addressPronouns.contains(next) ||
            _secondPersonQuestion.contains(next))) {
      return true;
    }

    // 4
    if (_windowContains(tokens, matchIndex, matchIndex, _pejorativeHeads,
        backward: 2, forward: 2, cumleler: signals.tokenSentences)) {
      return true;
    }

    // 5
    if (next != null) {
      if (next == 'gibisin' || next == 'gibisiniz') return true;
      if (next == 'gibi') {
        final to = (matchIndex + 4).clamp(0, tokens.length);
        for (var i = matchIndex + 2; i < to; i++) {
          if (!_ayniCumle(cumleler, i, matchIndex)) break;
          if (_endsWithAny(tokens[i].text, _secondPersonSuffixes)) return true;
        }
      }
    }

    // 6
    return signals.hasMention;
  }

  // ─── Yardımcılar ──────────────────────────────────────────────────────────

  /// Token'ın çevresindeki pencerede verilen kümeden bir kelime var mı?
  bool _windowContains(
    List<Token> tokens,
    int spanStart,
    int spanEnd,
    Set<String> vocabulary, {
    int backward = _windowSize,
    int forward = _windowSize,
    List<int> cumleler = const [],
  }) {
    final from = (spanStart - backward).clamp(0, tokens.length);
    final to = (spanEnd + forward + 1).clamp(0, tokens.length);

    for (int i = from; i < to; i++) {
      // Eşleşmenin kendi kelimeleri bağlam sayılmaz.
      if (i >= spanStart && i <= spanEnd) continue;
      if (!_ayniCumle(cumleler, i, spanStart)) continue;
      if (vocabulary.contains(tokens[i].text)) return true;
    }
    return false;
  }

  /// Pencerede, verilen eklerden biriyle biten bir kelime var mı?
  ///
  /// `_windowContains` kapalı bir KELİME listesi arar; bu ise EK arar.
  /// Türkçe'de kişi bilgisi çoğu zaman ayrı bir kelimede değil, komşu
  /// kelimenin ekinde taşındığı için ikisi de gereklidir.
  bool _windowHasSuffix(
    List<Token> tokens,
    int spanStart,
    int spanEnd,
    List<String> suffixes, {
    int backward = _windowSize,
    int forward = _windowSize,
    List<int> cumleler = const [],
  }) {
    final from = (spanStart - backward).clamp(0, tokens.length);
    final to = (spanEnd + forward + 1).clamp(0, tokens.length);

    for (int i = from; i < to; i++) {
      if (i >= spanStart && i <= spanEnd) continue;
      if (!_ayniCumle(cumleler, i, spanStart)) continue;
      if (_endsWithAny(tokens[i].text, suffixes)) return true;
    }
    return false;
  }

  /// Pencerede olumsuz çekimli bir fiil var mı?
  ///
  /// Yeterlilik olumsuzu ("-amam/-emem") önce elenir; biçimsel olarak
  /// olumsuz görünse de anlamca olumsuzlama değildir.
  bool _hasNegativeVerb(
      List<Token> tokens, int spanStart, int spanEnd, List<int> cumleler) {
    final from = (spanStart - 1).clamp(0, tokens.length);
    final to = (spanEnd + 3).clamp(0, tokens.length);

    for (int i = from; i < to; i++) {
      if (i >= spanStart && i <= spanEnd) continue;
      if (!_ayniCumle(cumleler, i, spanStart)) continue;
      final text = tokens[i].text;
      if (_endsWithAny(text, _abilityNegativeSuffixes)) continue;
      if (_endsWithAny(text, _negativeVerbSuffixes)) return true;
    }
    return false;
  }

  /// Penceredeki olumsuzlayıcıyı bir soru edatı izliyor mu?
  ///
  /// "değil misin", "değil mi" → retorik; cümle aslında olumlu iddiadır.
  bool _hasRhetoricalNegation(
      List<Token> tokens, int index, List<int> cumleler) {
    final from = (index - 1).clamp(0, tokens.length);
    final to = (index + 3).clamp(0, tokens.length);

    for (int i = from; i < to; i++) {
      if (i == index) continue;
      if (!_ayniCumle(cumleler, i, index)) continue;
      if (!_negators.contains(tokens[i].text)) continue;

      // Olumsuzlayıcıdan hemen sonraki kelime soru edatı mı?
      if (i + 1 < tokens.length &&
          _interrogatives.contains(tokens[i + 1].text)) {
        return true;
      }
    }
    return false;
  }

  /// Kelime verilen eklerden biriyle bitiyor mu?
  ///
  /// Minimum kök uzunluğu 3 — aksi hâlde "sin" kelimesinin kendisi
  /// "-sin eki almış" sayılır ve saçmalar.
  bool _endsWithAny(String word, List<String> suffixes) {
    for (final suffix in suffixes) {
      if (word.length >= suffix.length + 3 && word.endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }

  /// Ham metindeki büyük harf oranı. Yalnızca harfler sayılır.
  double _capsRatio(String text) {
    int letters = 0;
    int upper = 0;

    for (int i = 0; i < text.length; i++) {
      final c = text.codeUnitAt(i);

      // Büyük/küçük hâli farklıysa harftir
      if (!_isLetterCode(c)) continue;
      letters++;
      if (_isUpperCode(c)) upper++;
    }

    // Çok kısa metinlerde oran anlamsız — "OK" %100 büyük harf ama bağırma değil.
    if (letters < 8) return 0.0;
    return upper / letters;
  }

  /// Arka arkaya gelen en uzun ünlem/soru işareti dizisi.
  int _punctuationBurst(String text) {
    int maxRun = 0;
    int run = 0;

    for (int i = 0; i < text.length; i++) {
      final c = text.codeUnitAt(i);
      if (c == 0x21 || c == 0x3F) {
        run++;
        if (run > maxRun) maxRun = run;
      } else {
        run = 0;
      }
    }
    return maxRun;
  }

  /// Ham metindeki tırnak içi aralıkları bulur.
  ///
  /// Basit eşleştirme: tırnak karakterleri sırayla açar/kapatır.
  /// Kapanmayan tırnak yok sayılır.
  ///
  /// ── KESME İŞARETİ TIRNAK DEĞİLDİR (denetim D9 · docs/23) ───────────────
  /// Türkçede özel adın ekini ayıran kesme işareti (`'` ya da `’`) iki harfin
  /// ARASINDA durur: "Ali'ye", "Ankara'da". Önceki sürüm bunları da tırnak
  /// sayıyordu; iki özel ad arasına yazılan her şey "alıntı" oluyor ve
  /// yumuşatma tavanıyla eleniyordu. Ölçülen kaçış:
  ///
  ///   "Ali'ye söyle sen şerefsizsin Veli'ye de"  → Temiz ✗
  ///
  /// Harf–işaret–harf dizisi bu yüzden tırnak olarak sayılmaz.
  List<({int start, int end})> _findQuotedRanges(String text) {
    final ranges = <({int start, int end})>[];
    int? openIndex;

    for (int i = 0; i < text.length; i++) {
      if (!_quoteCodes.contains(text.codeUnitAt(i))) continue;
      if (_isApostrophe(text, i)) continue;

      if (openIndex == null) {
        openIndex = i;
      } else {
        ranges.add((start: openIndex, end: i + 1));
        openIndex = null;
      }
    }

    // Kapanmamış tırnak → geçersiz, yok sayılır.
    return ranges;
  }

  /// [i] konumundaki tek tırnak, iki harf arasında duran bir kesme işareti mi?
  static bool _isApostrophe(String text, int i) {
    final c = text.codeUnitAt(i);
    if (c != 0x27 && c != 0x2019) return false;
    if (i == 0 || i + 1 >= text.length) return false;
    return _isLetterCode(text.codeUnitAt(i - 1)) &&
        _isLetterCode(text.codeUnitAt(i + 1));
  }

  /// Eşleşme aralığı, tırnak aralıklarından birinin içinde mi?
  bool _isInsideQuotes(
    ({int start, int end}) match,
    List<({int start, int end})> quoted,
  ) {
    for (final range in quoted) {
      if (match.start >= range.start && match.end <= range.end) return true;
    }
    return false;
  }
}
