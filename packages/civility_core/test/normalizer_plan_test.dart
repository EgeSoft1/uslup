// =============================================================================
// Normalizasyon — karakter planı denklik testi (docs/28)
// Dosya: packages/civility_core/test/normalizer_plan_test.dart
//
// ── NE SINANIYOR ──────────────────────────────────────────────────────────
// `TurkishNormalizer` hızlandırıldı: karakter başına String ayırmak yerine
// önceden hesaplanmış bir dönüşüm planı okuyor. Hızlandırmanın çıktıyı
// değiştirmesi bir HATADIR — normalize metin motorun her katmanının girdisi
// olduğu için tek karakterlik bir sapma bütün ölçümleri geçersiz kılar.
//
// Bu yüzden hızlandırmadan ÖNCEKİ uygulama burada referans (oracle) olarak
// duruyor: yavaş ama sahada kanıtlanmış sürüm. İki uygulama aynı girdide
// aynı `value`, `aggressive` ve `sourceIndices` üretmek zorundadır.
//
// Aynı yöntem `test/detector_gate_test.dart`te de kullanılıyor: orada da bir
// hızlandırma (kapı) kapalı hâliyle karşılaştırılıyor.
//
// ── KAPSAM ────────────────────────────────────────────────────────────────
// Örnek cümle yetmez; dallar karakter sınıflarına göre ayrılıyor. Taranan:
//   • BMP'nin BÜTÜN kod noktaları — yalnız, harf arasında, üç tekrar hâlinde
//   • Vekil (surrogate) çiftleri ve eşi olmayan vekil yarıları
//   • Zor karakterlerden rastgele üretilmiş birleşimler
//   • Etiketli veri kümelerinin bütün cümleleri
// =============================================================================

import 'dart:math';

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  const yeni = TurkishNormalizer();
  const referans = _ReferenceNormalizer();

  /// İki uygulamanın [metin] üzerindeki çıktısını karşılaştırır; ayrıldıkları
  /// yeri okunur biçimde anlatan bir açıklama döndürür, aynılarsa null.
  String? fark(String metin) {
    final y = yeni.normalize(metin);
    final r = referans.normalize(metin);
    if (y.value != r.value) return 'value "${y.value}" != "${r.value}"';
    if (y.aggressive != r.aggressive) {
      return 'aggressive "${y.aggressive}" != "${r.aggressive}"';
    }
    if (y.original != r.original) return 'original bozuldu';
    if (y.sourceIndices.length != r.sourceIndices.length) {
      return 'indeks sayısı ${y.sourceIndices.length} != ${r.sourceIndices.length}';
    }
    for (var i = 0; i < y.sourceIndices.length; i++) {
      if (y.sourceIndices[i] != r.sourceIndices[i]) {
        return 'indeks[$i] ${y.sourceIndices[i]} != ${r.sourceIndices[i]}';
      }
    }
    return null;
  }

  /// Ayrılan ilk girdiyi kod noktalarıyla birlikte bildirir — görünmez
  /// karakterlerde "beklenen X, gelen Y" tek başına okunmaz olurdu.
  void hepsiAyni(Iterable<String> girdiler, String baslik) {
    for (final metin in girdiler) {
      final f = fark(metin);
      if (f != null) {
        fail('$baslik ayrıldı\n'
            '  girdi : "$metin"\n'
            '  kodlar: ${metin.codeUnits}\n'
            '  fark  : $f');
      }
    }
  }

  group('Karakter planı, referans uygulamayla birebir aynı', () {
    test('BMP kod noktalarının tamamı — yalnız ve harf komşuluğunda', () {
      final girdiler = <String>[];
      for (var cp = 1; cp < 0x10000; cp++) {
        // Eşi olmayan vekiller ayrı testte.
        if (cp >= 0xD800 && cp <= 0xDFFF) continue;
        final ch = String.fromCharCode(cp);
        girdiler
          ..add(ch)
          // Harf arası: gizleme dalı (ayırıcı ve emoji silme) burada açılır.
          ..add('a${ch}b')
          // Kenarda: leet ikamesinin komşuluk koşulu burada ayrışır.
          ..add('ab$ch')
          ..add('$ch ab')
          // Üç tekrar: daraltma ön geçişi.
          ..add('$ch$ch$ch');
      }
      hepsiAyni(girdiler, 'BMP taraması');
    });

    test('vekil çiftleri ve eşi olmayan vekil yarıları', () {
      final girdiler = <String>[];
      for (var cp = 0x10000; cp < 0x1FBFF; cp += 3) {
        final ch = String.fromCharCode(cp);
        girdiler
          ..add(ch)
          ..add('a${ch}b')
          ..add('$ch$ch$ch');
      }
      for (var u = 0xD800; u <= 0xDFFF; u++) {
        final ch = String.fromCharCode(u);
        girdiler
          ..add(ch)
          ..add('a${ch}b')
          ..add('$ch$ch$ch');
      }
      hepsiAyni(girdiler, 'vekil taraması');
    });

    test('zor karakterlerden üretilmiş rastgele birleşimler', () {
      // Sabit tohum: başarısızlık yeniden üretilebilir olmalı.
      final rnd = Random(20260915);
      final girdiler = <String>[];
      for (var n = 0; n < 60000; n++) {
        final sb = StringBuffer();
        final uzunluk = 1 + rnd.nextInt(10);
        for (var k = 0; k < uzunluk; k++) {
          sb.write(_zorParcalar[rnd.nextInt(_zorParcalar.length)]);
        }
        girdiler.add(sb.toString());
      }
      hepsiAyni(girdiler, 'rastgele birleşim');
    });

    test('uzun metinler — tampon ve indeks hizası', () {
      final rnd = Random(4242);
      final girdiler = <String>[];
      for (var n = 0; n < 300; n++) {
        final sb = StringBuffer();
        for (var k = 0; k < 400; k++) {
          sb.write(_zorParcalar[rnd.nextInt(_zorParcalar.length)]);
        }
        girdiler.add(sb.toString());
      }
      hepsiAyni(girdiler, 'uzun metin');
    });

    test('etiketli veri kümelerinin bütün cümleleri', () {
      hepsiAyni(
        [
          for (final c in <GoldCase>[
            ...GoldDataset.cases,
            ...HoldoutDataset.cases,
            ...GeneralizationDataset.cases,
            ...Generalization2Dataset.cases,
            ...Generalization3Dataset.cases,
            ...Generalization4Dataset.cases,
            ...Generalization5Dataset.cases,
            ...EverydayDataset.cases,
            ...DirectionDataset.cases,
            ...StanceDataset.cases,
            ...IdentityAxesDataset.cases,
            ...IdentityAxesBlindDataset.cases,
            ...IdentityAxesBlind2Dataset.cases,
          ])
            c.text,
        ],
        'veri kümesi',
      );
    });

    test('sınır girdileri', () {
      hepsiAyni(
        const ['', ' ', '   ', '\n', '​', '​​', 'a', 'ab'],
        'sınır',
      );
    });
  });
}

/// Referans taramasında kullanılan karakterler: normalleştiricinin her
/// dalına en az bir tane değer.
const List<String> _zorParcalar = [
  // Türkçe büyük/küçük ikilileri — I/İ ayrımı dâhil
  'a', 'A', 'I', 'İ', 'ı', 'i', 'Ç', 'ç', 'Ğ', 'ğ', 'Ö', 'ö', 'Ş', 'ş',
  'Ü', 'ü', 'â', 'î', 'û',
  // Türk alfabesinde olmayan harfler (q · w · x → 1→2 dönüşümü)
  'q', 'Q', 'w', 'W', 'x', 'X',
  // Leet
  '0', '1', '3', '4', '5', '6', '7', '8', '9', '@', r'$', '€', '#', '|', 'ß',
  // Kelime içi ayırıcılar
  '.', '*', '-', '_', "'", '`', '^', '~', '·', '•', ',', '/', '\\',
  // Cümle sınırı işaretleri
  '!', '?', ';', '"', '(', ')', '[', ']', '{', '}', '<', '>', '=',
  // Boşluk aileleri
  ' ', '  ', '\n', '\t', ' ', ' ', '　',
  // Sıfır genişlikliler
  '​', '‌', '‍', '﻿', '­',
  // Eşyazımlılar (Kiril + Yunan)
  'а', 'е', 'о', 'р', 'с', 'у', 'х', 'α', 'ε', 'ο',
  // Emoji blokları ve birleştiriciler
  '😀', '🫠', '🇹🇷', '⭐', '⌛', '☕', '✂', '🀄', '️', '⃣',
  // Büyük/küçük katlaması ASCII'ye düşen ender harfler
  'ſ', 'K', 'ẞ',
  // Latin dışı
  'ك', '中', 'Ω',
  // Tekrar dizileri
  'aa', 'aaa', 'aAa', 'AAAA', 'sss',
];

// =============================================================================
// REFERANS UYGULAMA
//
// Hızlandırmadan önceki `TurkishNormalizer`. Mantığı birebir korunmuştur;
// yalnızca açıklama blokları kısaltıldı — gerekçeler asıl dosyada durur.
// Bilerek yavaştır: karakter başına String ayırır ve tablo kullanmaz. Değeri
// de budur; okunurken doğruluğu doğrudan görülebilir.
//
// DEĞİŞTİRME: Bu sınıf sınanan davranışın tanımıdır. `TurkishNormalizer`
// kasıtlı olarak değiştirilecekse önce burası güncellenir, sonra asıl dosya.
// =============================================================================

class _ReferenceNormalizer {
  const _ReferenceNormalizer();

  static const Map<String, String> _turkishLower = {
    'I': 'ı', 'İ': 'i', 'Ç': 'ç', 'Ğ': 'ğ', 'Ö': 'ö', 'Ş': 'ş', 'Ü': 'ü',
  };

  static const Map<String, String> _homoglyphMap = {
    'а': 'a', 'е': 'e', 'о': 'o', 'р': 'p', 'с': 'c', 'у': 'y', 'х': 'x',
    'α': 'a', 'ε': 'e', 'ο': 'o',
  };

  static const Map<String, String> _foldDiacritics = {
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
    'â': 'a', 'î': 'i', 'û': 'u',
  };

  static const Map<String, String> _leetMap = {
    '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '6': 'g', '7': 't',
    '8': 'b', '9': 'g', '@': 'a', '\$': 's', '€': 'e', '#': 'h', '|': 'l',
    'ß': 'b',
  };

  static const Map<String, String> _foreignLetters = {
    'q': 'k', 'w': 'v', 'x': 'ks',
  };

  static const Set<String> _innerSeparators = {
    '.', '*', '-', '_', "'", '`', '^', '~', '·', '•', ',', '|', '/', '\\',
    '!', '?', ';', '"', '(', ')', '[', ']', '{', '}', '<', '>', '=',
  };

  static const Set<String> _boundaryMarks = {
    ',', '|', '/', '\\', '!', '?', ';', '"', '(', ')', '[', ']', '{', '}',
    '<', '>', '=',
  };

  static bool _isLetter(String ch) {
    if (ch.isEmpty) return false;
    final c = ch.codeUnitAt(0);
    if (c >= 0x61 && c <= 0x7A) return true;
    if (c >= 0x41 && c <= 0x5A) return true;
    const turkish = 'çğıöşüâîûÇĞİÖŞÜÂÎÛ';
    return turkish.contains(ch);
  }

  static bool _isEmoji(String ch) {
    if (ch.isEmpty) return false;
    final int cp = ch.runes.first;
    if (cp >= 0x1F600 && cp <= 0x1F64F) return true;
    if (cp >= 0x1F300 && cp <= 0x1F5FF) return true;
    if (cp >= 0x1F680 && cp <= 0x1F6FF) return true;
    if (cp >= 0x1F900 && cp <= 0x1F9FF) return true;
    if (cp >= 0x1FA70 && cp <= 0x1FAFF) return true;
    if (cp >= 0x1F1E6 && cp <= 0x1F1FF) return true;
    if (cp >= 0x1F000 && cp <= 0x1F2FF) return true;
    if (cp >= 0x2600 && cp <= 0x26FF) return true;
    if (cp >= 0x2700 && cp <= 0x27BF) return true;
    if (cp >= 0x2300 && cp <= 0x23FF) return true;
    if (cp >= 0x2B00 && cp <= 0x2BFF) return true;
    if (cp >= 0xFE00 && cp <= 0xFE0F) return true;
    if (cp == 0x200D || cp == 0x20E3) return true;
    return false;
  }

  static bool _sameIgnoringCase(String a, String b) {
    if (a == b) return true;
    final la = _turkishLower[a] ?? a.toLowerCase();
    final lb = _turkishLower[b] ?? b.toLowerCase();
    return la == lb;
  }

  NormalizedText normalize(String input) {
    if (input.isEmpty) {
      return NormalizedText(
        value: '',
        aggressive: '',
        sourceIndices: const [],
        original: input,
      );
    }

    // Ön geçiş 0: sıfır genişlikli temizliği.
    final cleanInput = StringBuffer();
    final cleanIndices = <int>[];
    for (int i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code == 0x200B ||
          code == 0x200C ||
          code == 0x200D ||
          code == 0xFEFF ||
          code == 0x00AD) {
        continue;
      }
      cleanInput.writeCharCode(code);
      cleanIndices.add(i);
    }
    final cleaned = cleanInput.toString();

    // Ön geçiş 1: 3+ tekrar daraltma (2 tekrar korunur).
    final collapsed = StringBuffer();
    final collapsedIndices = <int>[];

    int scan = 0;
    while (scan < cleaned.length) {
      final ch = cleaned[scan];

      int runEnd = scan;
      while (runEnd + 1 < cleaned.length &&
          _sameIgnoringCase(cleaned[runEnd + 1], ch)) {
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

    // Ana geçiş.
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

      String ch = _turkishLower[raw] ?? raw.toLowerCase();
      String aggressiveCh = ch;

      ch = _homoglyphMap[ch] ?? ch;
      aggressiveCh = _homoglyphMap[aggressiveCh] ?? aggressiveCh;

      final leetReplacement = _leetMap[ch];
      if (leetReplacement != null) {
        aggressiveCh = leetReplacement;

        final prevIsLetter = i > 0 && _isLetter(source[i - 1]);
        final nextIsLetter =
            i + charLen < source.length && _isLetter(source[i + charLen]);
        if (prevIsLetter || nextIsLetter) {
          ch = leetReplacement;
        }
      }

      ch = _foldDiacritics[ch] ?? ch;
      aggressiveCh = _foldDiacritics[aggressiveCh] ?? aggressiveCh;

      ch = _foreignLetters[ch] ?? ch;
      aggressiveCh = _foreignLetters[aggressiveCh] ?? aggressiveCh;

      if (_innerSeparators.contains(ch) || _isEmoji(raw)) {
        final prevIsLetter = i > 0 && _isLetter(source[i - 1]);
        final nextIsLetter =
            i + charLen < source.length && _isLetter(source[i + charLen]);

        if (prevIsLetter && nextIsLetter && !_boundaryMarks.contains(ch)) {
          i += charLen;
          continue;
        }

        ch = ' ';
        aggressiveCh = ' ';
      }

      if (ch.trim().isEmpty) {
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

      buffer.write(ch);
      aggressiveBuffer.write(aggressiveCh);
      for (int k = 0; k < ch.length; k++) {
        indices.add(collapsedIndices[i]);
      }
      lastEmitted = ch.substring(ch.length - 1);

      i += charLen;
    }

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
}
