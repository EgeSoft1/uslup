// =============================================================================
// NSosyal Sosyal YZ — Türkçe Metin Normalizasyon Katmanı
// Dosya: packages/civility_core/lib/src/normalization/turkish_normalizer.dart
//
// AMAÇ:
// Toksisite tespitinden KAÇMAK için kullanılan yazım hilelerini geri çevirmek.
// Gerçek dünyada kullanıcılar filtreyi şöyle atlatır:
//
//   "şerefsiz"  →  "serefsiz" / "$erefsiz" / "s.e.r.e.f.s.i.z" / "şerefsiiiz"
//   "aptal"     →  "4pt4l"    / "a p t a l" / "ap-tal"
//
// Bu katman hepsini tek bir kanonik forma indirger. Kanonik form üzerinde
// sözlük eşleşmesi yapılır.
//
// KRİTİK TASARIM KARARI — Offset Haritası:
// Normalizasyon karakter siler/değiştirir, yani indeksler kayar. Kullanıcıya
// "şu kelime sorunlu" diye ORİJİNAL metinde altını çizebilmek için, her
// normalize karakterin geldiği orijinal indeksi saklıyoruz (`sourceIndices`).
// Bu olmadan UI'da vurgulama yapılamaz.
//
// PERFORMANS: Her tuş vuruşunda çalışır. Tek geçiş (single-pass), O(n),
// düzenli ifade (regex) kullanmaz — regex backtracking riski taşımaz.
//
// ── KARAKTER PLANI (docs/28) ──────────────────────────────────────────────
// İlk sürüm her karakter için `substring`, `toLowerCase`, `trim` ve
// `runes.first` çağırıyordu: karakter başına 4-6 String ayırma. Kısa mesajda
// görünmez, uzun gönderide motorun en pahalı adımıydı — 2.760 karakterlik
// bir metinde 4,1 ms'nin 1,27 ms'si (%31) buradaydı.
//
// Dönüşüm zinciri (küçük harf → eşyazımlı → leet → aksan → q/w/x) bir
// karakterin YALNIZCA kendisine bağlıdır; tek koşullu adım olan leet ise iki
// olası sonuç verir. Yani her kaynak karakteri için sonuç ÖNCEDEN
// hesaplanabilir: `_CharPlan`. Sıcak döngü artık plan tablosundan okur ve
// hiçbir ara String üretmez.
//
// Bu bir hızlandırmadır; çıktıyı değiştirmesi bir hatadır. `value`,
// `aggressive` ve `sourceIndices` eski sürümle birebir aynı kalır —
// `test/normalizer_plan_test.dart` iki uygulamayı karşılaştırır.
// =============================================================================

/// Normalizasyon sonucu: kanonik metin + orijinal metne geri haritalama.
///
/// İKİ VARYANT ÜRETİLİR — nedeni aşağıda `aggressive` alanında açıklanmıştır.
class NormalizedText {
  /// TEMKİNLİ varyant. Rakam→harf çevirimi yalnızca harf komşuluğunda yapılır.
  /// Sayısal veriyi bozmaz: "saat 19:00" → "saat 19:00".
  final String value;

  /// AGRESİF varyant. TÜM leet karakterleri harfe çevrilir.
  /// "saat 19:00" → "saat ig:oo" (anlamsız ama zararsız — yalnızca sözlük
  /// eşleştirmesinde kullanılır, kullanıcıya hiç gösterilmez).
  ///
  /// NEDEN İKİ VARYANT?
  /// Tek varyantla iki hedef aynı anda tutturulamıyor:
  ///   • Temkinli olursak "$3r3fsiz" kaçar ('$' harf komşusu yok → çevrilmez).
  ///   • Agresif olursak "19:00" → "ig:oo" olur ve sayısal metin bozulur.
  /// Çözüm: ikisini de üret, sözlük eşleşmesini İKİSİNDE DE dene.
  ///
  /// Tüm leet ikameleri 1 karakter → 1 karakter olduğu için bu varyantın
  /// uzunluğu ve indeksleri `value` ile BİREBİR AYNIDIR. Yani `sourceIndices`
  /// her ikisi için de geçerlidir ve vurgulama doğru çalışır.
  final String aggressive;

  /// `value[i]` karakterinin orijinal metindeki indeksi.
  /// Uzunluğu `value.length`'e eşittir.
  final List<int> sourceIndices;

  /// Normalizasyondan önceki ham metin.
  final String original;

  const NormalizedText({
    required this.value,
    required this.aggressive,
    required this.sourceIndices,
    required this.original,
  });

  /// Kanonik metindeki [start, end) aralığını orijinal metindeki aralığa çevirir.
  /// UI'da doğru karakterlerin altını çizmek için kullanılır.
  ({int start, int end}) toOriginalRange(int start, int end) {
    if (sourceIndices.isEmpty) return (start: 0, end: 0);

    final safeStart = start.clamp(0, sourceIndices.length - 1);
    final safeEnd = (end - 1).clamp(0, sourceIndices.length - 1);

    return (
      start: sourceIndices[safeStart],
      // +1: bitiş indeksi dışlayıcı (exclusive) olmalı
      end: sourceIndices[safeEnd] + 1,
    );
  }

  bool get isEmpty => value.isEmpty;
}

/// Tek bir kaynak karakterinin önceden hesaplanmış dönüşüm sonucu.
///
/// Zincirin tek koşullu adımı leet ikamesidir (komşusu harf mi?), bu yüzden
/// iki sonuç saklanır: [base] (leet uygulanmadan) ve [leet] (uygulanarak).
/// Leet eşlemesi olmayan karakterlerde ikisi aynı String nesnesidir.
///
/// Agresif varyant leet'i KOŞULSUZ uyguladığı için her zaman [leet]'e eşittir
/// — ayrı bir alan tutmak gerekmez.
class _CharPlan {
  const _CharPlan({
    required this.base,
    required this.leet,
    required this.hasLeet,
    required this.baseIsSeparator,
    required this.leetIsSeparator,
    required this.baseIsBoundary,
    required this.leetIsBoundary,
    required this.baseIsSpace,
    required this.leetIsSpace,
    required this.isEmoji,
  });

  /// Leet ikamesi UYGULANMADAN elde edilen karakter.
  final String base;

  /// Leet ikamesi uygulanarak elde edilen karakter (= agresif varyant).
  final String leet;

  /// Bu karakterin bir leet karşılığı var mı? Yoksa [base] ile [leet] aynıdır
  /// ve sıcak döngü komşu harf kontrolünü hiç yapmaz.
  final bool hasLeet;

  /// Sonuç kelime içi ayırıcı mı? Ayırıcılık dönüşüm SONRASI karaktere
  /// bakılarak belirlenir ('|' leet uygulanınca 'l' olur ve ayırıcı olmaktan
  /// çıkar), bu yüzden iki varyant için ayrı tutulur.
  final bool baseIsSeparator;
  final bool leetIsSeparator;

  /// Sonuç cümle sınırı işareti mi? (Ayırıcı olsa bile silinmez, boşluğa iner.)
  final bool baseIsBoundary;
  final bool leetIsBoundary;

  /// Sonuç boşluk mu? (`ch.trim().isEmpty` karşılığı.)
  final bool baseIsSpace;
  final bool leetIsSpace;

  /// Kaynak karakter emoji mi? Dönüşümden ÖNCEKİ hâline bakılır.
  final bool isEmoji;
}

/// Türkçe farkındalıklı metin normalizasyonu.
///
/// Tüm tablolar `static const` — her çağrıda yeniden kurulmaz.
class TurkishNormalizer {
  const TurkishNormalizer();

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TÜRKÇE KÜÇÜK HARF DÖNÜŞÜMÜ
  //
  // Dart'ın `String.toLowerCase()` metodu yerel-bağımsızdır (locale-invariant)
  // ve Türkçe için YANLIŞ sonuç verir:
  //   'I'.toLowerCase()  → 'i'   ✗ (Türkçe'de 'ı' olmalı)
  //   'İ'.toLowerCase()  → 'i̇'  ✗ (i + birleşen nokta, iki karakter!)
  // Bu yüzden kendi tablomuzu kullanıyoruz.
  // ───────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _turkishLower = {
    'I': 'ı',
    'İ': 'i',
    'Ç': 'ç',
    'Ğ': 'ğ',
    'Ö': 'ö',
    'Ş': 'ş',
    'Ü': 'ü',
  };

  // ───────────────────────────────────────────────────────────────────────────
  // 2. EŞYAZIMLI (HOMOGLYPH) DİRENCİ
  //
  // Görsel olarak Latin harflerine benzeyen Kiril (Cyrillic) ve Yunanca (Greek)
  // karakterlerin Latin karşılıklarına dönüştürülmesi.
  // ───────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _homoglyphMap = {
    // Kiril (Cyrillic)
    'а': 'a',
    'е': 'e',
    'о': 'o',
    'р': 'p',
    'с': 'c',
    'у': 'y',
    'х': 'x',
    // Yunanca (Greek)
    'α': 'a',
    'ε': 'e',
    'ο': 'o',
  };

  // ───────────────────────────────────────────────────────────────────────────
  // 3. AKSAN KATLAMA (diacritic folding)
  //
  // "şerefsiz" ve "serefsiz" aynı sözlük girdisine düşmeli. Türkçe klavyesi
  // olmayan kullanıcılar (ve filtreden kaçmaya çalışanlar) aksansız yazar.
  // Not: 'ı' ve 'i' ikisi de 'i'ye katlanır — bu kasıtlı.
  // ───────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _foldDiacritics = {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'i',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
    'â': 'a',
    'î': 'i',
    'û': 'u',
  };

  // ───────────────────────────────────────────────────────────────────────────
  // 4. LEETSPEAK / RAKAM İKAMESİ
  //
  // "4pt4l" → "aptal", "$erefsiz" → "serefsiz", "0rospu" → "orospu"
  //
  // Not: '!' ve '+' kasıtlı olarak DIŞARIDA bırakılmıştır. Bunlar günlük
  // metinde noktalama olarak çok sık geçer ("Merhaba!" → "merhabai") ve
  // kazandırdıkları tespitten çok daha fazla gürültü üretirler.
  // ───────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _leetMap = {
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '6': 'g',
    '7': 't',
    '8': 'b',
    '9': 'g',
    '@': 'a',
    '\$': 's',
    '€': 'e',
    '#': 'h',
    '|': 'l',
    'ß': 'b',
  };

  // ───────────────────────────────────────────────────────────────────────────
  // 4b. TÜRK ALFABESİNDE BULUNMAYAN HARFLER  (q · w · x)
  //
  // Türk alfabesinde q, w, x YOKTUR. Bir Türkçe kelimenin içinde geçtiklerinde
  // iki olasılık vardır: yabancı bir özel ad, ya da KASITLI GİZLEME.
  //
  // Gizleme tarafı ölçüldü ve katmanın en büyük tek açığıydı:
  //
  //   "salak"  → yakalanıyordu        "salaq"  → temiz (0.00)   ✗
  //   "siktir" → yakalanıyordu        "siqtir" → temiz (0.00)   ✗
  //   "yavşak" → yakalanıyordu        "yavşaq" → temiz (0.00)   ✗
  //
  // Bu, leetspeak'ten (4pt4l) çok daha yaygın bir kaçıştır çünkü hiç
  // "hacklenmiş" görünmez: Türkçe klavyede q tuşu zaten vardır ve yazılan
  // kelime okunurluğunu tamamen korur. Filtre atlatmanın en ucuz yolu budur.
  //
  // ── NEDEN YANLIŞ POZİTİF ÜRETMEZ ─────────────────────────────────────────
  // Dönüşüm ancak ortaya çıkan kelime SÖZLÜKTE varsa bir şey değiştirir.
  // Yabancı kelimeler zararsız karşılıklara iner ve hiçbiri sözlükte yoktur:
  //
  //   "Qatar" → "katar"    "web" → "veb"      "Xbox" → "ksboks"
  //   "IQ"    → "ik"       "www" → "vvv"      "fax"  → "faks"
  //
  // TEK İSTİSNA sözlüğün kendisinden gelir: katlanan harfi TERİMİN içinde
  // taşıyan girdi ("aq") katlanınca meşru bir kelimeye ("ak") iner ve o
  // kelimeyi yakalar. Bu girdiler motor tarafında harfin orijinal metinde
  // fiilen yazılmış olmasını şart koşar — bkz.
  // `LexicalTurkishClassifier._surfaceLetterEvidence`.
  //
  // ── x NEDEN İKİ HARF ─────────────────────────────────────────────────────
  // q→k ve w→v birebirdir; x ise Türkçe'de "ks" sesine karşılık gelir
  // ("taxi" → "taksi"). Tek harfe indirmek "sixiym" gibi bir kaçışı yine
  // kaçırırdı. Bu, normalizasyonun tek 1→2 dönüşümüdür ve indeks haritası
  // buna göre iki giriş üretir; `value` ile `aggressive` aynı dönüşümü
  // aldığı için uzunluk eşitliği değişmezi korunur.
  // ───────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _foreignLetters = {
    'q': 'k',
    'w': 'v',
    'x': 'ks',
  };

  // ───────────────────────────────────────────────────────────────────────────
  // 5. KELİME İÇİ AYIRICILAR
  //
  // "s.e.r.e.f.s.i.z" veya "a*m*k" gibi harf arası noktalama ile yapılan
  // gizleme. Harfler arasında geçtiğinde silinir.
  // ───────────────────────────────────────────────────────────────────────────
  static const Set<String> _innerSeparators = {
    '.', '*', '-', '_', "'", '`', '^', '~', '·', '•', ',', '|', '/', '\\',
    '!', '?', ';', '"', '(', ')', '[', ']', '{', '}', '<', '>', '=',
  };

  /// Cümle sınırı işaretleri — iki harf arasında olsalar bile SİLİNMEZ,
  /// boşluğa dönüşür (docs/24 · madde 10).
  ///
  /// Önceki kural harf arasındaki HER ayırıcıyı gizleme sayıp siliyordu.
  /// Mobilde virgül ya da soru işaretinden sonra boşluk bırakmamak çok
  /// yaygındır ve kelimeler birleşiyordu:
  ///
  ///   "Harika,salaksın"          → "harikasalaksin"     → Temiz ✗
  ///   "Ne dedin?Aptal mısın"     → "ne dedinaptal misin" → Temiz ✗
  ///   "Bence yanlış,şerefsizsin" → "…yanlisserefsizsin"  → Temiz ✗
  ///
  /// Harf harf gizleme ("a,p,t,a,l", "s/i/k/t/i/r") bundan etkilenmez: tek
  /// harfli parçalar zaten kaçınma birleştirmesiyle yeniden kurulur. Kelime
  /// içi gizlemede gerçekten kullanılan işaretler (`. - * _ '` …) silinmeye
  /// devam eder: "ap-tal", "şeref.siz", "Ali'nin".
  static const Set<String> _boundaryMarks = {
    ',', '|', '/', '\\', '!', '?', ';', '"', '(', ')', '[', ']', '{', '}',
    '<', '>', '=',
  };

  /// Görünmez (sıfır genişlikli) karakter mi? Filtre atlatmada kelimenin
  /// ortasına serpiştirilir; normalizasyondan önce atılır.
  static bool _isZeroWidth(int code) =>
      code == 0x200B ||
      code == 0x200C ||
      code == 0x200D ||
      code == 0xFEFF ||
      code == 0x00AD;

  /// Bir kod biriminin Türkçe dâhil harf olup olmadığı — String ayırmaz.
  ///
  /// Komşu harf kontrolü karakter başına iki kez çağrılır; eski sürüm her
  /// çağrıda `source[i]` ile tek harflik bir String ayırıp 18 harflik bir
  /// dizgide `contains` araması yapıyordu.
  ///
  /// Vekil (surrogate) yarıları hiçbir aralığa girmez ve `false` döner —
  /// eski sürümün davranışı da buydu.
  static bool _isLetterCode(int c) {
    if (c >= 0x61 && c <= 0x7A) return true; // a-z
    if (c >= 0x41 && c <= 0x5A) return true; // A-Z
    switch (c) {
      // Türkçe'ye özgü küçük harfler: ç ğ ı ö ş ü â î û
      case 0x00E7:
      case 0x011F:
      case 0x0131:
      case 0x00F6:
      case 0x015F:
      case 0x00FC:
      case 0x00E2:
      case 0x00EE:
      case 0x00FB:
      // Büyükleri: Ç Ğ İ Ö Ş Ü Â Î Û
      case 0x00C7:
      case 0x011E:
      case 0x0130:
      case 0x00D6:
      case 0x015E:
      case 0x00DC:
      case 0x00C2:
      case 0x00CE:
      case 0x00DB:
        return true;
    }
    return false;
  }

  /// Latin blokları için önceden kurulmuş küçük harf tablosu.
  ///
  /// Değer, küçük harf karşılığının kod birimidir; karşılık tek karakterde
  /// ifade edilemiyorsa (Dart'ın 'İ' → "i̇" gibi ürettiği hâller) -1.
  static final List<int> _lowerTable = List<int>.generate(0x300, _computeLower);

  static int _computeLower(int c) {
    final raw = String.fromCharCode(c);
    final low = _turkishLower[raw] ?? raw.toLowerCase();
    return low.length == 1 ? low.codeUnitAt(0) : -1;
  }

  static int _lowerCode(int c) => c < 0x300 ? _lowerTable[c] : _computeLower(c);

  /// İki kod birimi büyük/küçük harf farkı dışında aynı mı? (Türkçe I/İ dâhil)
  ///
  /// Motor, uzatma kuyruğunu ÖZGÜN metin üzerinde arar ("sikerimMMMMo") ve
  /// tekrar ölçümünü bu katmanla birebir aynı kuralla yapmak zorundadır;
  /// aksi hâlde iki taraf farklı yerde "tekrar" görür. Tek kullanıcı
  /// `LexicalTurkishClassifier._stripElongationTail`.
  static bool sameIgnoringCaseCode(int a, int b) => _sameIgnoringCaseCode(a, b);

  /// İki kod birimi büyük/küçük harf farkı dışında aynı mı?
  static bool _sameIgnoringCaseCode(int a, int b) {
    if (a == b) return true;
    final la = _lowerCode(a);
    final lb = _lowerCode(b);
    // Tek karaktere inmeyen ender hâller: eski String yoluna düş.
    if (la < 0 || lb < 0) {
      return _sameIgnoringCase(String.fromCharCode(a), String.fromCharCode(b));
    }
    return la == lb;
  }

  /// Emojileri tespit eder.
  ///
  /// docs/24 · madde 11: yeni emoji bloğu (🫠 🥹 🫶 — 1FA70–1FAFF), bayrak
  /// harfleri (🇹🇷), yıldız/ok sembolleri (⭐ ⬛ — 2B00–2BFF) ve saat/araç
  /// sembolleri (⌛ ⏰ — 2300–23FF) listede yoktu. Harf arasına konduklarında
  /// ayırıcı sayılmıyor ve kelimeyi bölüyorlardı:
  ///   "a🫠p🫠t🫠a🫠l" · "şerefsiz⭐sin" · "salak🇹🇷sın" → Temiz ✗
  static bool _isEmojiCp(int cp) {
    if (cp >= 0x1F600 && cp <= 0x1F64F) return true; // Yüzler
    if (cp >= 0x1F300 && cp <= 0x1F5FF) return true; // Semboller ve Piktogramlar
    if (cp >= 0x1F680 && cp <= 0x1F6FF) return true; // Ulaşım ve Harita
    if (cp >= 0x1F900 && cp <= 0x1F9FF) return true; // Ek Emojiler
    if (cp >= 0x1FA70 && cp <= 0x1FAFF) return true; // Genişletilmiş-A
    if (cp >= 0x1F1E6 && cp <= 0x1F1FF) return true; // Bayrak harfleri
    if (cp >= 0x1F000 && cp <= 0x1F2FF) return true; // Oyun kartları, çevrili harfler
    if (cp >= 0x2600 && cp <= 0x26FF) return true;   // Çeşitli Semboller
    if (cp >= 0x2700 && cp <= 0x27BF) return true;   // Dingbats
    if (cp >= 0x2300 && cp <= 0x23FF) return true;   // Teknik semboller (⌛ ⏰)
    if (cp >= 0x2B00 && cp <= 0x2BFF) return true;   // Oklar ve yıldızlar (⭐)
    if (cp >= 0xFE00 && cp <= 0xFE0F) return true;   // Varyasyon Seçiciler (VS1-VS16)
    if (cp == 0x200D || cp == 0x20E3) return true;   // ZWJ, tuş başlığı birleştiricisi
    return false;
  }

  /// İki karakter büyük/küçük harf farkı dışında aynı mı? (Türkçe I/İ dâhil)
  static bool _sameIgnoringCase(String a, String b) {
    if (a == b) return true;
    final la = _turkishLower[a] ?? a.toLowerCase();
    final lb = _turkishLower[b] ?? b.toLowerCase();
    return la == lb;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // KARAKTER PLANI TABLOSU
  //
  // Latin blokları (0x000–0x2FF) açılışta doldurulur: 768 giriş, Türkçe
  // metnin karakterlerinin tamamına yakını buraya düşer. Üstü — emoji,
  // Kiril, Yunanca — ilk görüldüğünde hesaplanıp belleğe alınır.
  //
  // Tablo saf bir fonksiyonun belleğidir: aynı karakter her zaman aynı planı
  // verir, paylaşılması güvenlidir.
  // ───────────────────────────────────────────────────────────────────────────

  static final List<_CharPlan> _latinPlans =
      List<_CharPlan>.generate(0x300, (cp) => _computePlan(cp));

  static final Map<int, _CharPlan> _otherPlans = <int, _CharPlan>{};

  static _CharPlan _planFor(int cp) {
    if (cp < 0x300) return _latinPlans[cp];
    return _otherPlans[cp] ??= _computePlan(cp);
  }

  /// Dönüşüm zincirinin leet dışındaki bütün adımları.
  static String _chain(String ch) {
    var out = _foldDiacritics[ch] ?? ch;
    return _foreignLetters[out] ?? out;
  }

  static _CharPlan _computePlan(int cp) {
    final raw = String.fromCharCode(cp);

    // Aşama 1-2: Türkçe küçük harf, ardından eşyazımlı dönüşümü.
    final lowered = _turkishLower[raw] ?? raw.toLowerCase();
    final homo = _homoglyphMap[lowered] ?? lowered;

    // Aşama 3: leet ikamesi — koşullu olduğu için iki dal.
    final leetReplacement = _leetMap[homo];

    // Aşama 4-4b: aksan katlama ve q/w/x, iki dala da uygulanır.
    final base = _chain(homo);
    final leet = leetReplacement == null ? base : _chain(leetReplacement);

    return _CharPlan(
      base: base,
      leet: leet,
      hasLeet: leetReplacement != null,
      baseIsSeparator: _innerSeparators.contains(base),
      leetIsSeparator: _innerSeparators.contains(leet),
      baseIsBoundary: _boundaryMarks.contains(base),
      leetIsBoundary: _boundaryMarks.contains(leet),
      baseIsSpace: base.trim().isEmpty,
      leetIsSpace: leet.trim().isEmpty,
      isEmoji: _isEmojiCp(cp),
    );
  }

  /// Ham metni kanonik forma indirger.
  ///
  /// Aşamalar (tek geçişte, sırayla):
  ///   0. Sıfır genişlikli (zero-width) temizliği
  ///   1. Türkçe küçük harf
  ///   2. Eşyazımlı (Homoglyph) dönüşümü
  ///   3. Leet ikamesi (yalnızca harf komşuluğunda)
  ///   4. Aksan katlama
  ///   5. Kelime içi ayırıcı ve emoji temizliği
  ///   6. Tekrar eden harf daraltma ("çoookk" → "cok")
  ///   7. Boşluk sadeleştirme
  NormalizedText normalize(String input) {
    if (input.isEmpty) {
      return NormalizedText(
        value: '',
        aggressive: '',
        sourceIndices: const [],
        original: input,
      );
    }

    // ── Ön geçiş 0: Sıfır genişlikli karakter (zero-width) temizliği ──────────
    // Görünmez karakterlerle yapılan filtre atlatmalarını engeller.
    //
    // Sıradan metinde böyle bir karakter yoktur. Önce varlığı sorulur; yoksa
    // metin olduğu gibi kullanılır ve N elemanlı kimlik dizisi hiç kurulmaz
    // (`null` = "her karakter yerinde duruyor").
    var hasZeroWidth = false;
    for (int i = 0; i < input.length; i++) {
      if (_isZeroWidth(input.codeUnitAt(i))) {
        hasZeroWidth = true;
        break;
      }
    }

    String cleaned;
    List<int>? cleanIndices;
    if (hasZeroWidth) {
      final cleanInput = StringBuffer();
      final kept = <int>[];
      for (int i = 0; i < input.length; i++) {
        final code = input.codeUnitAt(i);
        if (_isZeroWidth(code)) continue;
        cleanInput.writeCharCode(code);
        kept.add(i);
      }
      cleaned = cleanInput.toString();
      cleanIndices = kept;
    } else {
      cleaned = input;
    }

    // ── Ön geçiş 1: Tekrar eden harf daraltma ───────────────────────
    // "çoookkk" → "cok", "aptaaaalsın" → "aptalsın"
    //
    // Kural: 3 VEYA DAHA FAZLA ardışık aynı harf → tek harfe iner.
    //        2 tekrar KORUNUR, çünkü Türkçe'de anlamlıdır:
    //        "elli", "dikkat", "affet", "millet"...
    //
    // Neden ayrı bir ön geçiş: Bir dizinin uzunluğu ancak dizi bittiğinde
    // bilinir. Tek geçişli akış mantığıyla "2 mi 3 mü" ayrımı yapılamaz —
    // ileriye bakış (lookahead) gerekir.
    // Daraltılacak bir dizi var mı? Sıradan metinde yoktur; yoksa metin ve
    // indeksler olduğu gibi devralınır, iki ara yapı birden kurulmaz.
    var hasRun = false;
    for (int i = 2; i < cleaned.length; i++) {
      final c = cleaned.codeUnitAt(i);
      if (_sameIgnoringCaseCode(c, cleaned.codeUnitAt(i - 1)) &&
          _sameIgnoringCaseCode(c, cleaned.codeUnitAt(i - 2))) {
        hasRun = true;
        break;
      }
    }

    String source;
    List<int>? collapsedIndices;
    if (hasRun) {
      final collapsed = StringBuffer();
      final kept = <int>[];

      int scan = 0;
      while (scan < cleaned.length) {
        final chCode = cleaned.codeUnitAt(scan);

        // Büyük/küçük harf karışık tekrar da tekrardır (docs/24 · madde 12):
        // "aptAaAl" daralmıyor ve "sen aptAaAlsın" temiz dönüyordu.
        int runEnd = scan;
        while (runEnd + 1 < cleaned.length &&
            _sameIgnoringCaseCode(cleaned.codeUnitAt(runEnd + 1), chCode)) {
          runEnd++;
        }

        final runLength = runEnd - scan + 1;
        final keepCount = runLength >= 3 ? 1 : runLength;

        for (int k = 0; k < keepCount; k++) {
          // Dizinin İLK karakteri yazılır; ikili tekrarda ikincinin büyük/
          // küçük hâli birinciye uyar. Ana geçiş zaten küçük harfe indirdiği
          // için `value` bundan etkilenmez.
          collapsed.writeCharCode(chCode);
          kept.add(cleanIndices == null
              ? scan + k
              : cleanIndices[scan + k]);
        }

        scan = runEnd + 1;
      }

      source = collapsed.toString();
      collapsedIndices = kept;
    } else {
      source = cleaned;
      collapsedIndices = cleanIndices;
    }

    // ── Ana geçiş ───────────────────────────────────────────────────────────
    final buffer = StringBuffer();
    final aggressiveBuffer = StringBuffer();
    final indices = <int>[];

    bool lastWasSpace = false;
    final int sourceLength = source.length;

    int i = 0;
    while (i < sourceLength) {
      final int unit = source.codeUnitAt(i);
      int charLen = 1;
      int cp = unit;
      if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < sourceLength) {
        final int unit2 = source.codeUnitAt(i + 1);
        if (unit2 >= 0xDC00 && unit2 <= 0xDFFF) {
          charLen = 2;
          cp = 0x10000 + ((unit - 0xD800) << 10) + (unit2 - 0xDC00);
        }
      }

      // ── Aşama 1-4b: küçük harf · eşyazımlı · leet · aksan · q/w/x ──
      // Hepsi karakterin kendisine bağlı; sonuç tablodan okunur.
      final plan = _planFor(cp);

      // Leet ikamesi tek koşullu adım (iki varyant):
      // Temkinli: yalnızca komşularından biri harfse çevir → "4pt4l" düzelir,
      //           "2026" bozulmaz.
      // Agresif : koşulsuz çevir → "$3r3fsiz" yakalanır.
      var useLeet = false;
      if (plan.hasLeet) {
        useLeet = (i > 0 && _isLetterCode(source.codeUnitAt(i - 1))) ||
            (i + charLen < sourceLength &&
                _isLetterCode(source.codeUnitAt(i + charLen)));
      }

      String ch = useLeet ? plan.leet : plan.base;
      // Agresif varyant leet'i koşulsuz uygular — yani her zaman `plan.leet`.
      String aggressiveCh = plan.leet;
      var chIsSpace = useLeet ? plan.leetIsSpace : plan.baseIsSpace;

      // ── Aşama 5: Kelime içi ayırıcı ve Emoji temizliği ──
      final chIsSeparator = useLeet ? plan.leetIsSeparator : plan.baseIsSeparator;
      if (chIsSeparator || plan.isEmoji) {
        final prevIsLetter = i > 0 && _isLetterCode(source.codeUnitAt(i - 1));
        final nextIsLetter = i + charLen < sourceLength &&
            _isLetterCode(source.codeUnitAt(i + charLen));

        // İki harf arasındaysa gizleme hilesidir → at. Cümle sınırı
        // işaretleri hariç: onlar kelimeleri ayırır.
        final chIsBoundary =
            useLeet ? plan.leetIsBoundary : plan.baseIsBoundary;
        if (prevIsLetter && nextIsLetter && !chIsBoundary) {
          i += charLen;
          continue;
        }

        // Değilse normal noktalama; boşluğa indirge (cümle sınırı korunur).
        ch = ' ';
        aggressiveCh = ' ';
        chIsSpace = true;
      }

      // ── Aşama 6: Boşluk sadeleştirme ──
      if (chIsSpace) {
        // Ardışık boşlukları tek boşluğa indir, baştaki boşluğu at.
        if (buffer.isEmpty || lastWasSpace) {
          i += charLen;
          continue;
        }
        buffer.write(' ');
        aggressiveBuffer.write(' ');
        indices.add(collapsedIndices == null ? i : collapsedIndices[i]);
        lastWasSpace = true;
        i += charLen;
        continue;
      }

      // Tekrar daraltma yukarıdaki ön geçişte tamamlandı.
      buffer.write(ch);
      aggressiveBuffer.write(aggressiveCh);
      // `ch` bir karakterden uzun olabilir (yalnızca x → "ks"). Her çıktı
      // karakteri, geldiği ORİJİNAL karaktere işaret etmelidir; aksi hâlde
      // vurgulama aralığı kayar ve kullanıcıya yanlış harflerin altı çizilir.
      final sourceIndex = collapsedIndices == null ? i : collapsedIndices[i];
      for (int k = 0; k < ch.length; k++) {
        indices.add(sourceIndex);
      }
      // Buraya yalnızca boşluk OLMAYAN karakterler gelir.
      lastWasSpace = false;

      i += charLen;
    }

    // Sondaki boşluğu kırp. Her iki varyant da aynı uzunlukta olduğu için
    // kırpma ikisine de birebir uygulanır — indeks hizası korunur.
    var value = buffer.toString();
    var aggressive = aggressiveBuffer.toString();
    var trimmedIndices = indices;

    if (value.endsWith(' ')) {
      value = value.substring(0, value.length - 1);
      aggressive = aggressive.substring(0, value.length);
      trimmedIndices = indices.sublist(0, value.length);
    }

    return NormalizedText(
      value: value,
      aggressive: aggressive,
      sourceIndices: trimmedIndices,
      original: input,
    );
  }

  /// Harf-arası-boşluk hilesini geri çevirir: "a m k" → "amk".
  ///
  /// Ayrı bir adım çünkü metnin tamamına uygulanamaz — normal cümlelerdeki
  /// tek harfli kelimeleri ("o gitti", "bu ve şu") bozar. Yalnızca ÜÇ veya
  /// daha fazla ardışık tek-harfli token dizisi hile kabul edilir.
  ///
  /// Sözlük eşleşmesi bu varyant üzerinde de denenir.
  String collapseSpacedLetters(String normalized) {
    if (normalized.isEmpty) return normalized;

    final tokens = normalized.split(' ');
    final out = <String>[];

    int i = 0;
    while (i < tokens.length) {
      // Tek harfli ardışık token dizisinin uzunluğunu ölç
      int run = 0;
      while (i + run < tokens.length && tokens[i + run].length == 1) {
        run++;
      }

      if (run >= 3) {
        // Hile: birleştir
        out.add(tokens.sublist(i, i + run).join());
        i += run;
      } else {
        for (int k = 0; k < (run == 0 ? 1 : run); k++) {
          if (i + k < tokens.length) out.add(tokens[i + k]);
        }
        i += (run == 0 ? 1 : run);
      }
    }

    return out.join(' ');
  }
}
