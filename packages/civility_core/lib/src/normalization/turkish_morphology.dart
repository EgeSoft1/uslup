// =============================================================================
// Türkçe Biçimbilim Yardımcıları
// Dosya: packages/civility_core/lib/src/normalization/turkish_morphology.dart
//
// Yeniden yazıcı, saldırgan bir kelimeyi nötr karşılığıyla değiştirirken
// kelimenin TAŞIDIĞI EKİ de taşımak zorundadır. Aksi hâlde cümle bozulur:
//
//   "sen tam bir aptalsın"  →  "sen tam bir yanlış"     ✗ ek kayboldu
//   "sen tam bir aptalsın"  →  "sen tam bir yanlışsın"  ✓ ek taşındı
//
// Türkçe eklemeli bir dil olduğu için ekin biçimi köke bağlıdır: ünlü uyumu
// ve ünsüz benzeşmesi. "aptal" + 2. tekil şahıs → "aptalsın" ama
// "sersem" + aynı ek → "sersemsin". Sabit bir ek listesi işe yaramaz.
//
// Buradaki kurallar kasıtlı olarak DAR tutulmuştur: yalnızca yeniden
// yazıcının fiilen ürettiği ekler desteklenir. Genel amaçlı bir Türkçe
// biçimbilim kütüphanesi değildir ve olmaya çalışmaz.
// =============================================================================

/// Türkçe ünlü uyumu ve ek üretimi.
abstract final class TurkishMorphology {
  static const String _backUnrounded = 'aı';
  static const String _backRounded = 'ou';
  static const String _frontUnrounded = 'ei';
  static const String _frontRounded = 'öü';

  static const String _vowels = 'aeıioöuü';

  /// Sert ünsüzler — ünsüz benzeşmesinde "d" yerine "t" getirir.
  static const String _voiceless = 'fstkçşhp';

  /// Kelimenin son ünlüsü. Ünlü yoksa `null`.
  static String? lastVowel(String word) {
    final lower = toLowerTr(word);
    for (var i = lower.length - 1; i >= 0; i--) {
      if (_vowels.contains(lower[i])) return lower[i];
    }
    return null;
  }

  /// Türkçe farkındalıklı küçük harfe çevirme: 'I' → 'ı', 'İ' → 'i'.
  ///
  /// `toLowerCase()` tek başına yanlış sonuç verir; 'I'.toLowerCase() İngilizce
  /// kurallara göre 'i' üretir ve ünlü uyumu hesabını bozar.
  static String toLowerTr(String text) =>
      text.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  /// Türkçe farkındalıklı büyük harfe çevirme.
  static String toUpperTr(String text) =>
      text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  /// Dört biçimli ek ünlüsü (ı/i/u/ü) — büyük ünlü uyumu + dudak uyumu.
  ///
  /// Ünlü bulunamazsa 'i' varsayılır; bu, ek getirilen kelimenin en azından
  /// okunabilir kalmasını sağlar.
  static String vowelFour(String stem) {
    final v = lastVowel(stem);
    if (v == null) return 'i';
    if (_backUnrounded.contains(v)) return 'ı';
    if (_backRounded.contains(v)) return 'u';
    if (_frontUnrounded.contains(v)) return 'i';
    if (_frontRounded.contains(v)) return 'ü';
    return 'i';
  }

  /// İki biçimli ek ünlüsü (a/e) — yalnızca büyük ünlü uyumu.
  static String vowelTwo(String stem) {
    final v = lastVowel(stem);
    if (v == null) return 'e';
    return (_backUnrounded.contains(v) || _backRounded.contains(v)) ? 'a' : 'e';
  }

  /// Kelime sert ünsüzle mi bitiyor? ("-de" mi "-te" mi sorusu)
  static bool endsVoiceless(String word) {
    final lower = toLowerTr(word).trim();
    if (lower.isEmpty) return false;
    return _voiceless.contains(lower[lower.length - 1]);
  }

  static bool endsWithVowel(String word) {
    final lower = toLowerTr(word).trim();
    if (lower.isEmpty) return false;
    return _vowels.contains(lower[lower.length - 1]);
  }

  /// İkinci tekil şahıs bildirme eki: "-sın/-sin/-sun/-sün".
  ///
  ///   haksız → haksızsın · sersem → sersemsin · yorgun → yorgunsun
  static String copulaSecondSingular(String stem) => 's${vowelFour(stem)}n';

  /// İkinci çoğul şahıs bildirme eki: "-sınız/-siniz/-sunuz/-sünüz".
  static String copulaSecondPlural(String stem) {
    final v = vowelFour(stem);
    // Ek içindeki ikinci ünlü de uyuma girer: sın+ız, sun+uz …
    return 's${v}n${v}z';
  }

  /// Üçüncü şahıs bildirme eki: "-dır/-dir/-dur/-dür" (sert ünsüzde "-tır…").
  static String copulaThird(String stem) {
    final d = endsVoiceless(stem) ? 't' : 'd';
    return '$d${vowelFour(stem)}r';
  }

  /// Çoğul eki: "-lar/-ler".
  static String plural(String stem) => 'l${vowelTwo(stem)}r';

  /// Kelimeye ek getirir; ünlüyle biten kökte kaynaştırma harfi eklenmez
  /// çünkü desteklenen eklerin hiçbiri ünlüyle başlamaz.
  static String attach(String stem, String suffix) => '$stem$suffix';

  /// Soru ekinin iskeletleri. Ünlüler `{V}` ile temsil edilir ve önceki
  /// kelimeye göre doldurulur.
  ///
  /// Soru eki Türkçe'de ayrı yazılır ama ünlü uyumuna KENDİSİNDEN ÖNCEKİ
  /// kelimeye göre girer. Yeniden yazıcı bir kelimeyi değiştirdiğinde uyum
  /// bozulur — "embesil misin" → "yanlış misin" (olması gereken "mısın").
  static const Map<String, String> _questionSkeletons = {
    'mi': 'm{V}', 'mı': 'm{V}', 'mu': 'm{V}', 'mü': 'm{V}',
    'misin': 'm{V}s{V}n', 'mısın': 'm{V}s{V}n',
    'musun': 'm{V}s{V}n', 'müsün': 'm{V}s{V}n',
    'misiniz': 'm{V}s{V}n{V}z', 'mısınız': 'm{V}s{V}n{V}z',
    'musunuz': 'm{V}s{V}n{V}z', 'müsünüz': 'm{V}s{V}n{V}z',
    'miyim': 'm{V}y{V}m', 'mıyım': 'm{V}y{V}m',
    'muyum': 'm{V}y{V}m', 'müyüm': 'm{V}y{V}m',
    'miyiz': 'm{V}y{V}z', 'mıyız': 'm{V}y{V}z',
    'muyuz': 'm{V}y{V}z', 'müyüz': 'm{V}y{V}z',
  };

  /// Verilen kelime bir soru eki mi?
  static bool isQuestionParticle(String word) =>
      _questionSkeletons.containsKey(toLowerTr(word));

  /// Soru ekini [previousWord] ile uyumlu biçimine çevirir.
  /// Kelime soru eki değilse olduğu gibi döner.
  static String harmonizeQuestionParticle(String particle, String previousWord) {
    final skeleton = _questionSkeletons[toLowerTr(particle)];
    if (skeleton == null) return particle;
    return skeleton.replaceAll('{V}', vowelFour(previousWord));
  }

  /// Metindeki tüm soru eklerini, kendilerinden önce gelen kelimeye göre
  /// yeniden uyumlar.
  static String fixQuestionParticles(String text) {
    final words = text.split(' ');
    for (var i = 1; i < words.length; i++) {
      if (!isQuestionParticle(words[i])) continue;
      final previous = words[i - 1].replaceAll(RegExp(r'[^\wçğıöşüÇĞİÖŞÜ]'), '');
      if (previous.isEmpty) continue;
      words[i] = harmonizeQuestionParticle(words[i], previous);
    }
    return words.join(' ');
  }

  /// Cümlenin ilk harfini Türkçe kurallara göre büyütür.
  static String capitalize(String text) {
    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) return text;
    final first = trimmed[0];
    return toUpperTr(first) + trimmed.substring(1);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ZEMBEREK BENZERİ HAFİFLETİLMİŞ MORFOLOJİK ANALİZ & EK AYIKLAMA MOTORU
  // ───────────────────────────────────────────────────────────────────────────

  /// Sert ünsüzle biten kök sonunu ünlüyle başlayan ek aldığında yumuşatır.
  /// k ↔ ğ/g, p ↔ b, ç ↔ c, t ↔ d (normalize metinde k ↔ g, t ↔ d, p ↔ b).
  static String? softenNormalizedStem(String normalizedStem) {
    if (normalizedStem.length < 2) return null;
    final lastChar = normalizedStem[normalizedStem.length - 1];
    final prefix = normalizedStem.substring(0, normalizedStem.length - 1);
    return switch (lastChar) {
      'k' => '${prefix}g',
      't' => '${prefix}d',
      'p' => '${prefix}b',
      _ => null,
    };
  }

  /// Yumuşamış kök sonunu sert hâline geri çevirir (g → k, d → t, b → p).
  static String? hardenNormalizedStem(String normalizedStem) {
    if (normalizedStem.length < 2) return null;
    final lastChar = normalizedStem[normalizedStem.length - 1];
    final prefix = normalizedStem.substring(0, normalizedStem.length - 1);
    return switch (lastChar) {
      'g' => '${prefix}k',
      'd' => '${prefix}t',
      'b' => '${prefix}p',
      _ => null,
    };
  }

  /// Türkçe Büyük ve Küçük Ünlü Uyumu kontrolü (Normalize metin üzerinde).
  ///
  /// Kalın ünlülü kökler ('a', 'ı', 'o', 'u') eklerinde 'e' içeremez (örn: aptal+ler ✗).
  /// İnce ünlülü kökler ('e', 'i', 'ö', 'ü') eklerinde 'a' içeremez (örn: şerefsiz+lar ✗).
  ///
  /// ── KATLAMA UYUM SINIFINI SİLER (denetim D9 · docs/23) ────────────────────
  /// Normalize kökte "ı" ile "i", "ü" ile "u", "ö" ile "o" aynı harftir. Kökün
  /// sınıfı normalize hâlinden okunduğunda Türkçenin en yaygın hakaret
  /// çoğulları reddediliyordu:
  ///
  ///   "gerizekalı" → "gerizekali" → son ünlü 'i' → ince → "-lar" ✗  (kaçıyordu)
  ///   "öküz"       → "okuz"       → son ünlü 'u' → kalın → "-ler" ✗  (kaçıyordu)
  ///
  /// [stemSpelling] verildiğinde sınıf kökün TÜRKÇE yazılışından okunur;
  /// sözlük girdileri aksanlı yazıldığı için bu bilgi kurulumda hazırdır.
  /// Ekin kendisi normalize kalır: orada yalnızca 'a' ve 'e' kesin sınıf taşır.
  static bool isVowelHarmonious(
    String normalizedStem,
    String normalizedSuffix, {
    String? stemSpelling,
  }) {
    if (normalizedSuffix.isEmpty) return true;
    final stemVowel = stemSpelling == null
        ? lastVowel(normalizedStem)
        : lastVowel(_foldCircumflex(stemSpelling));
    if (stemVowel == null) return true;

    final isBackStem = _backUnrounded.contains(stemVowel) ||
        _backRounded.contains(stemVowel);
    final isFrontStem = !isBackStem;

    for (var i = 0; i < normalizedSuffix.length; i++) {
      final ch = normalizedSuffix[i];
      // -yor şimdiki zaman eki istisnadır
      if (ch == 'o') continue;

      if (isBackStem && ch == 'e') {
        return false;
      }
      if (isFrontStem && ch == 'a') {
        return false;
      }
    }
    return true;
  }

  /// Şapkalı ünlüleri düz karşılığına indirir: "zekâ" → "zeka".
  static String _foldCircumflex(String text) => toLowerTr(text)
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('û', 'u');

  /// Verilen ekin Türkçe kurallarına göre geçerli bir çekim eki olup olmadığını denetler.
  static bool isValidSuffix(
    String normalizedStem,
    String normalizedSuffix, {
    bool isVerbal = false,
    bool isStrictShortRoot = false,
    String? stemSpelling,
  }) {
    if (normalizedSuffix.isEmpty) return true;

    // 1. Ünlü uyumu kuralı
    if (!isVowelHarmonious(normalizedStem, normalizedSuffix,
        stemSpelling: stemSpelling)) {
      return false;
    }

    // 2. Kısa ve yüksek riskli kökler ("am", "bok", "it", "mal") için katı liste
    if (isStrictShortRoot || normalizedStem.length <= 3) {
      if (_joinedQuestionSuffixes.contains(normalizedSuffix)) {
        return !_verbHomographShortRoots.contains(normalizedStem);
      }
      return _strictShortRootSuffixes.contains(normalizedSuffix);
    }

    // 3. Standart isim veya fiil çekim ekleri
    if (_validNounSuffixes.contains(normalizedSuffix)) return true;
    if (_joinedQuestionSuffixes.contains(normalizedSuffix)) return true;
    if (isVerbal && _validVerbSuffixes.contains(normalizedSuffix)) return true;

    return false;
  }

  /// Verilen token'ın, [normalizedStem] kökünden türetilmiş geçerli bir çekimli
  /// form olup olmadığını doğrular (Ünsüz yumuşaması dahil).
  ///
  /// [stemSpelling] kökün Türkçe yazılışıdır ("gerizekalı"); verilirse ünlü
  /// uyumu sınıfı ondan okunur. Gerekçe: [isVowelHarmonious].
  static bool isValidInflectedForm(
    String fullNormalizedToken,
    String normalizedStem, {
    bool isVerbal = false,
    String? stemSpelling,
  }) {
    if (fullNormalizedToken == normalizedStem) return true;

    final isShort = normalizedStem.length <= 3;

    // 1. Doğrudan kök + ek ("aptal" + "sın" -> "aptalsin")
    if (fullNormalizedToken.startsWith(normalizedStem)) {
      final suffix = fullNormalizedToken.substring(normalizedStem.length);
      if (isValidSuffix(normalizedStem, suffix,
          isVerbal: isVerbal,
          isStrictShortRoot: isShort,
          stemSpelling: stemSpelling)) {
        return true;
      }
    }

    // 2. Ünsüz yumuşaması ("salak" -> "salag" + "im" -> "salagim")
    final softened = softenNormalizedStem(normalizedStem);
    if (softened != null && fullNormalizedToken.startsWith(softened)) {
      final suffix = fullNormalizedToken.substring(softened.length);
      if (suffix.isNotEmpty && _vowels.contains(suffix[0])) {
        if (isValidSuffix(normalizedStem, suffix,
            isVerbal: isVerbal,
            isStrictShortRoot: isShort,
            stemSpelling: stemSpelling)) {
          return true;
        }
      }
    }

    return false;
  }

  // ─── GEÇERLİ TÜRKÇE ÇEKİM EKİ ŞABLONLARI (NORMALIZE) ──────────────────────

  /// BİTİŞİK YAZILMIŞ SORU EKİ (docs/25).
  ///
  /// Soru eki kurala göre ayrı yazılır ama mobilde çoğu zaman bitiştirilir:
  /// "salakmısın", "gerizekalımısın", "şerefsizmisin". Ek listede olmadığı
  /// için bu biçimlerin hepsi temiz dönüyordu. Normalize yazımda ünlüleri
  /// yalnızca "i/u" olduğundan ünlü uyumu denetimi onları elemez.
  static const Set<String> _joinedQuestionSuffixes = {
    'misin', 'musun', 'misiniz', 'musunuz', 'midir', 'mudur',
    'larmi', 'lermi', 'larmisiniz', 'lermisiniz',
  };

  /// Aynı zamanda fiil kökü olan kısa kökler. ASCII yazımda "-mişsin"
  /// geçmiş zaman eki soru ekiyle aynı dizgiye iner: "itmisin" (itmişsin),
  /// "kazmisin" (kazmışsın), "sikmisin" (sıkmışsın). Bunlarda bitişik soru
  /// eki kabul edilmez.
  static const Set<String> _verbHomographShortRoots = {'it', 'kaz', 'sik'};

  /// Kısa kökler ("am", "bok", "it", "mal") için sınırlı güvenli çekim ekleri.
  static const Set<String> _strictShortRootSuffixes = {
    // İyelik ve Hâl
    'i', 'u', 'e', 'a', 'in', 'un', 'im', 'um',
    'ina', 'ine', 'ini', 'unu', 'inda', 'inde', 'indan', 'inden', 'inin', 'unun',
    'imden', 'imdan', 'imde', 'imda', 'ime', 'ima', 'imi', 'umu',
    'imiz', 'umuz', 'imize', 'imuza', 'imizi', 'umuzu', 'imizden', 'umuzdan',
    'iniz', 'unuz', 'inize', 'inuza', 'inizi', 'unuzu', 'inizden', 'unuzdan',
    'da', 'de', 'ta', 'te', 'dan', 'den', 'tan', 'ten',
    'la', 'le', 'yla', 'yle',
    // Çoğul
    'lar', 'ler', 'lara', 'lere', 'lari', 'leri', 'larin', 'lerin',
    'larina', 'lerine', 'larinda', 'lerinde', 'larindan', 'lerinden', 'larini', 'lerini',
    // Şahıs / Bildirme
    'sin', 'sun', 'siniz', 'sunuz', 'tir', 'tur', 'dir', 'dur',
    // Küçültme (argo türevleri: amcık vb.)
    'cik', 'cuk', 'cigi', 'cugu', 'ciklar', 'cuklar', 'ciga', 'cuga',
    'tanlik', 'tenlik',
  };

  /// İsim ve sıfat köklerine gelebilen tüm meşru Türkçe çekim ve yapım ekleri.
  static const Set<String> _validNounSuffixes = {
    // Çoğul ve halleri
    'lar', 'ler', 'lara', 'lere', 'lari', 'leri', 'larin', 'lerin',
    'larina', 'lerine', 'larinda', 'lerinde', 'larindan', 'lerinden', 'larini', 'lerini',
    'larimiz', 'lerimiz', 'lariniz', 'leriniz',
    'larsin', 'lersin', 'larsiniz', 'lersiniz', 'lardir', 'lerdir',
    'lardi', 'lerdi', 'larsa', 'lerse', 'larmis', 'lermis', 'larken', 'lerken',

    // İyelik ve hâl bileşimleri
    'm', 'im', 'um', 'ma', 'me', 'ima', 'ime', 'uma', 'ume',
    'mi', 'imi', 'umu', 'mda', 'mde', 'imda', 'imde', 'umda', 'umde',
    'mdan', 'mden', 'imdan', 'imden', 'umdan', 'umden',
    'min', 'imin', 'umin', 'mla', 'mle', 'imle', 'umle',

    'n', 'in', 'un', 'na', 'ne', 'ina', 'ine', 'una', 'une',
    'ni', 'ini', 'unu', 'nda', 'nde', 'inda', 'inde', 'unda', 'unde',
    'ndan', 'nden', 'indan', 'inden', 'undan', 'unden',
    'nin', 'inin', 'unin', 'nla', 'nle', 'inle', 'unle',
    // Yuvarlak ünlüyle biten köklerin belirtme ve ilgi eki (docs/25):
    // "orospunun", "orospunu" kaçıyordu; düz karşılıkları ('ni', 'nin') vardı.
    'nu', 'nun',

    'si', 'su', 'sine', 'sina', 'sini', 'sunu', 'sinde', 'sinda',
    'sinden', 'sindan', 'sinin', 'sunun', 'siyle', 'suyla',

    'miz', 'muz', 'mize', 'miza', 'imize', 'imiza', 'muza', 'umuza',
    'mizi', 'imizi', 'muzu', 'umuzu', 'mizde', 'imizde', 'muzda', 'umuzda',
    'mizden', 'imizden', 'muzdan', 'umuzdan', 'mizin', 'imizin', 'muzun', 'umuzun',

    'niz', 'nuz', 'nize', 'niza', 'inize', 'iniza', 'nuza', 'unuza',
    'nizi', 'inizi', 'nuzu', 'unuzu', 'nizde', 'inizde', 'nuzda', 'unuzda',
    'nizden', 'inizden', 'nuzdan', 'unuzdan', 'nizin', 'inizin', 'nuzun', 'unuzun',

    // Hâl ekleri (Yalın)
    'a', 'e', 'ya', 'ye', 'i', 'u', 'yi', 'yu',
    'da', 'de', 'ta', 'te', 'dan', 'den', 'tan', 'ten',
    'la', 'le', 'yla', 'yle', 'ca', 'ce', 'casina', 'cesine',
    'larla', 'lerle', 'lariyla', 'leriyle', 'larinla', 'lerinle',

    // Şahıs ve bildirme ekleri (Ek-Fiil)
    'sin', 'sun', 'siniz', 'sunuz',
    'dir', 'dur', 'tir', 'tur', 'dirler', 'durler', 'tirlar', 'turlar',
    'yim', 'yum', 'yiz', 'yuz',
    'dim', 'din', 'di', 'dik', 'diniz', 'diler',
    'tim', 'tin', 'ti', 'tik', 'tiniz', 'tiler',
    'mis', 'mus', 'missin', 'mussun', 'missiniz', 'mussunuz', 'misler', 'muslar',
    'sa', 'se', 'san', 'sen', 'sak', 'sek', 'saniz', 'seniz', 'salar', 'seler',

    // Yaygın yapım ekleri ve çekimleri
    'lik', 'luk', 'lig', 'lug', 'lige', 'luga', 'likten', 'luktan', 'likte', 'lukta',
    'likler', 'luklar', 'ligim', 'ligin', 'ligi', 'ligimiz', 'liginiz', 'liktir', 'luktur',
    'siz', 'suz', 'sizler', 'suzlar', 'sizsin', 'suzsun', 'sizsiniz', 'suzsunuz',
    'size', 'suza', 'sizden', 'suzdan', 'sizlik', 'suzluk',
    'ci', 'cu', 'ciler', 'cular', 'cisin', 'cusun',
  };

  /// Fiil köklerine gelebilen çekim ekleri.
  static const Set<String> _validVerbSuffixes = {
    'ma', 'me', 'mayi', 'meyi', 'maya', 'meye', 'madan', 'meden',
    'er', 'ar', 'ir', 'ur', 'erim', 'arim', 'ersin', 'arsin', 'eriz', 'ariz', 'erler', 'arlar',
    'mez', 'maz', 'mezsin', 'mazsin', 'mezsiniz', 'mazsiniz', 'mezler', 'mazlar',
    'iyor', 'uyor', 'iyorum', 'uyorum', 'iyorsun', 'uyorsun', 'iyorlar', 'uyorlar', 'iyoruz', 'uyoruz',
    'ecek', 'acak', 'ecegim', 'acagim', 'eceksin', 'acaksin', 'ecekler', 'acaklar',
    'meli', 'mali', 'melisin', 'malisin', 'melisiniz', 'malisiniz', 'meliyiz', 'maliyiz',
    'tir', 'tur', 'tirdi', 'turdu', 'tirmis', 'turmus', 'tirmek', 'turmak',
    'dik', 'duk', 'tik', 'tuk', 'tiler', 'tular', 'dim', 'din', 'di', 'tim', 'tin', 'ti',
    'se', 'sa', 'sen', 'san', 'sek', 'sak',
    'mek', 'mak', 'mekten', 'maktan',
    'in', 'iniz',
  };
}
