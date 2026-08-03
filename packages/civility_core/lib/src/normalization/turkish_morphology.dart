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
}
