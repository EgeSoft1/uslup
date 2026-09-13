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

  /// Bir karakterin Türkçe dâhil harf olup olmadığı.
  static bool _isLetter(String ch) {
    if (ch.isEmpty) return false;
    final c = ch.codeUnitAt(0);
    // a-z
    if (c >= 0x61 && c <= 0x7A) return true;
    // A-Z
    if (c >= 0x41 && c <= 0x5A) return true;
    // Türkçe'ye özgü harfler (küçük ve büyük)
    const turkish = 'çğıöşüâîûÇĞİÖŞÜÂÎÛ';
    return turkish.contains(ch);
  }

  /// Emojileri tespit eder.
  static bool _isEmoji(String ch) {
    if (ch.isEmpty) return false;
    final int cp = ch.runes.first;
    if (cp >= 0x1F600 && cp <= 0x1F64F) return true; // Yüzler
    if (cp >= 0x1F300 && cp <= 0x1F5FF) return true; // Semboller ve Piktogramlar
    if (cp >= 0x1F680 && cp <= 0x1F6FF) return true; // Ulaşım ve Harita
    if (cp >= 0x1F900 && cp <= 0x1F9FF) return true; // Ek Emojiler
    if (cp >= 0x2600 && cp <= 0x26FF) return true;   // Çeşitli Semboller
    if (cp >= 0x2700 && cp <= 0x27BF) return true;   // Dingbats
    if (cp >= 0xFE00 && cp <= 0xFE0F) return true;   // Varyasyon Seçiciler (VS1-VS16)
    if (cp == 0x200D) return true;                   // ZWJ (Sıfır genişlikli birleştirici)
    return false;
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
    final cleanInput = StringBuffer();
    final cleanIndices = <int>[];
    for (int i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code == 0x200B || code == 0x200C || code == 0x200D || code == 0xFEFF || code == 0x00AD) {
        continue;
      }
      cleanInput.writeCharCode(code);
      cleanIndices.add(i);
    }
    final cleaned = cleanInput.toString();

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
    final collapsed = StringBuffer();
    final collapsedIndices = <int>[];

    int scan = 0;
    while (scan < cleaned.length) {
      final ch = cleaned[scan];

      int runEnd = scan;
      while (runEnd + 1 < cleaned.length && cleaned[runEnd + 1] == ch) {
        runEnd++;
      }

      final runLength = runEnd - scan + 1;
      final keepCount = runLength >= 3 ? 1 : runLength;

      for (int k = 0; k < keepCount; k++) {
        collapsed.write(ch);
        collapsedIndices.add(cleanIndices[scan + k]);
      }

      scan = runEnd + 1;
    }

    final source = collapsed.toString();

    // ── Ana geçiş ───────────────────────────────────────────────────────────
    final buffer = StringBuffer();
    final aggressiveBuffer = StringBuffer();
    final indices = <int>[];

    String lastEmitted = '';

    int i = 0;
    while (i < source.length) {
      final int cp = source.codeUnitAt(i);
      int charLen = 1;
      if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < source.length) {
        final int cp2 = source.codeUnitAt(i + 1);
        if (cp2 >= 0xDC00 && cp2 <= 0xDFFF) {
          charLen = 2;
        }
      }
      final raw = source.substring(i, i + charLen);

      // ── Aşama 1: Türkçe küçük harf ──
      String ch = _turkishLower[raw] ?? raw.toLowerCase();
      String aggressiveCh = ch;

      // ── Aşama 2: Homoglyph (Eşyazımlı) Direnci ──
      ch = _homoglyphMap[ch] ?? ch;
      aggressiveCh = _homoglyphMap[aggressiveCh] ?? aggressiveCh;

      // ── Aşama 3: Leet ikamesi (iki varyant) ──
      // Temkinli: yalnızca komşularından biri harfse çevir → "4pt4l" düzelir,
      //           "2026" bozulmaz.
      // Agresif : koşulsuz çevir → "$3r3fsiz" yakalanır.
      final leetReplacement = _leetMap[ch];
      if (leetReplacement != null) {
        aggressiveCh = leetReplacement;

        final prevIsLetter = i > 0 && _isLetter(source[i - 1]);
        final nextIsLetter = i + charLen < source.length && _isLetter(source[i + charLen]);
        if (prevIsLetter || nextIsLetter) {
          ch = leetReplacement;
        }
      }

      // ── Aşama 4: Aksan katlama ──
      ch = _foldDiacritics[ch] ?? ch;
      aggressiveCh = _foldDiacritics[aggressiveCh] ?? aggressiveCh;

      // ── Aşama 4b: Türk alfabesinde bulunmayan harfler (q · w · x) ──
      // İki varyanta da AYNI dönüşüm uygulanır; uzunluk eşitliği böyle korunur.
      ch = _foreignLetters[ch] ?? ch;
      aggressiveCh = _foreignLetters[aggressiveCh] ?? aggressiveCh;

      // ── Aşama 5: Kelime içi ayırıcı ve Emoji temizliği ──
      if (_innerSeparators.contains(ch) || _isEmoji(raw)) {
        final prevIsLetter = i > 0 && _isLetter(source[i - 1]);
        final nextIsLetter = i + charLen < source.length && _isLetter(source[i + charLen]);

        // İki harf arasındaysa gizleme hilesidir → at.
        if (prevIsLetter && nextIsLetter) {
          i += charLen;
          continue;
        }

        // Değilse normal noktalama; boşluğa indirge (cümle sınırı korunur).
        ch = ' ';
        aggressiveCh = ' ';
      }

      // ── Aşama 6: Boşluk sadeleştirme ──
      if (ch.trim().isEmpty) {
        // Ardışık boşlukları tek boşluğa indir, baştaki boşluğu at.
        if (buffer.isEmpty || lastEmitted == ' ') {
          i += charLen;
          continue;
        }
        buffer.write(' ');
        aggressiveBuffer.write(' ');
        indices.add(collapsedIndices[i]);
        lastEmitted = ' ';
        i += charLen;
        continue;
      }

      // Tekrar daraltma yukarıdaki ön geçişte tamamlandı.
      buffer.write(ch);
      aggressiveBuffer.write(aggressiveCh);
      // `ch` bir karakterden uzun olabilir (yalnızca x → "ks"). Her çıktı
      // karakteri, geldiği ORİJİNAL karaktere işaret etmelidir; aksi hâlde
      // vurgulama aralığı kayar ve kullanıcıya yanlış harflerin altı çizilir.
      for (int k = 0; k < ch.length; k++) {
        indices.add(collapsedIndices[i]);
      }
      lastEmitted = ch.substring(ch.length - 1);

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
