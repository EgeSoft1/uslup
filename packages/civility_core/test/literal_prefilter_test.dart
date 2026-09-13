// =============================================================================
// Değişmez parça ön filtresi — doğruluk testleri
// Dosya: packages/civility_core/test/literal_prefilter_test.dart
//
// Ön filtre bir hızlandırmadır ve yanılgısı SESSİZDİR: yanlış bir parça
// çıkarılırsa örüntü o cümlede hiç denenmez, bulgu kaybolur, hiçbir şey
// kırılmaz. Bu dosya üç ayrı katmanda sınar:
//
//   1. Çıkarıcı — elle doğrulanmış ifadelerde beklenen parçaları buluyor,
//      anlamadığı yapıda "kısıt yok" diyor.
//   2. Otomat — tek geçişli tarama, naif `contains` ile birebir aynı sonucu
//      veriyor (rastgele metinlerde).
//   3. Katalog — üründeki her örüntü, etiketli kümelerde GERÇEKTEN
//      eşleştiği her cümlede kapıyı açık buluyor.
//
// Kapılı/kapısız dedektörün bulgu düzeyinde eşdeğerliği ayrıca
// `detector_gate_test.dart` içinde sınanır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:civility_core/src/detect/literal_prefilter.dart';
import 'package:test/test.dart';

Set<String>? _req(String source) =>
    LiteralPrefilter.requiredAnyOf(RegExp(source, caseSensitive: false));

void main() {
  group('1. Çıkarıcı', () {
    test('düz dizi ve almaşık', () {
      expect(_req(r'\bkim sordu\b'), {'kim sordu'});
      expect(_req(r'\bkim sordu\b|\bsana mi sorduk\b'),
          {'kim sordu', 'sana mi sorduk'});
    });

    test('isteğe bağlı parça kesin kümeye iki biçimde girer', () {
      expect(_req(r'\bhad(dini|dinizi)? bildir\w+'),
          {'had bildir', 'haddini bildir', 'haddinizi bildir'});
    });

    test('başka elemanı içeren eleman atılır', () {
      expect(_req(r'\b(capin|capiniz) bu\b'), {'capin bu', 'capiniz bu'});
      expect(_req(r'(ab|abc)'), {'ab'});
    });

    test('sıfır ya da daha fazla tekrar kısıt değildir', () {
      expect(_req(r'(abc)*'), isNull);
      expect(_req(r'(abc){0,2}'), isNull);
      expect(_req(r'x*'), isNull);
      // ama zincirin geri kalanı hâlâ kısıttır
      expect(_req(r'(abc)*defg'), {'defg'});
    });

    test('en az bir tekrar atomun kısıtını korur', () {
      expect(_req(r'(?:uzun)+'), {'uzun'});
      expect(_req(r'(?:uzun){2,}'), {'uzun'});
    });

    test('bir dalı kısıtsız olan almaşık kısıtsızdır', () {
      expect(_req(r'kelime|\w+'), isNull);
      expect(_req(r'kelime|'), isNull);
    });

    test('bakış grupları ve sınırlar hiçbir şey tüketmez', () {
      expect(_req(r'\bkim sordu\b(?=.{0,30}\b(sen|siz)\b)'), {'kim sordu'});
      expect(_req(r'(?!yok)var'), {'var'});
      expect(_req(r'^merhaba$'), {'merhaba'});
    });

    test('küçük harf sınıfı kesin küme, geniş sınıf bilinmeyen karakter', () {
      expect(_req(r'[ae]mez'), {'amez', 'emez'});
      // Bilinmeyen karakter zinciri böler; iki yarıdan biri yeter ve ikisi
      // eşit seçicidir.
      expect(_req(r'x[a-z]y'), anyOf(equals({'x'}), equals({'y'})));
      expect(_req(r'ab[^!]cd'), anyOf(equals({'ab'}), equals({'cd'})));
      expect(_req(r'abc[a-z]de'), {'abc'}, reason: 'uzun yarı daha seçici');
    });

    test('ASCII dışı harf parçaya alınmaz; büyük harf küçültülür', () {
      expect(_req(r'liralık'), {'liral'});
      expect(_req(r'KIM'), {'kim'});
    });

    test('desteklenmeyen yapıda kısıt çıkarılmaz', () {
      expect(_req(r'(a)\1'), isNull); // geri başvuru
      expect(_req(r'\qabc'), isNull); // tanınmayan harf kaçışı
      expect(_req(r'[]abc'), isNull); // ECMAScript boş sınıfı
      expect(
          LiteralPrefilter.requiredAnyOf(RegExp('abc')), isNull); // duyarlı
      expect(
          LiteralPrefilter.requiredAnyOf(
              RegExp('abc', caseSensitive: false, unicode: true)),
          isNull);
    });
  });

  group('2. Otomat', () {
    test('tek geçişli tarama, naif contains ile birebir aynı', () {
      const parts = [
        'a', 'ab', 'bab', 'abab', 'b c', 'cc', 'aaa', 'ca b', 'bcb', 'c a'
      ];
      final index = LiteralIndex([
        for (final p in parts) RegExp(RegExp.escape(p), caseSensitive: false)
      ]);

      var seed = 7;
      int next(int n) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        return seed % n;
      }

      const alphabet = 'abc AB';
      for (var round = 0; round < 3000; round++) {
        final len = next(18);
        final text = String.fromCharCodes(
            [for (var i = 0; i < len; i++) alphabet.codeUnitAt(next(alphabet.length))]);
        final hits = index.scan(text);
        final lowered = text.toLowerCase();
        for (var i = 0; i < parts.length; i++) {
          expect(hits.mayMatch(i), lowered.contains(parts[i]),
              reason: '"${parts[i]}" · metin "$text"');
        }
      }
    });

    test('ASCII dışı karakter otomatı başa döndürür, eşleşme uydurmaz', () {
      final index = LiteralIndex([RegExp('abc', caseSensitive: false)]);
      expect(index.scan('abçabc').mayMatch(0), isTrue);
      expect(index.scan('abçbc').mayMatch(0), isFalse);
      expect(index.scan('ABC').mayMatch(0), isTrue);
    });

    test('regex motorunun katlayabileceği Unicode harfleri kapıyı kapatmaz', () {
      // "İ", "ı", "ſ", "K" — hangi motor kuralı geçerli olursa olsun
      // fazladan denemek güvenli taraftır.
      final index = LiteralIndex([
        RegExp('kis', caseSensitive: false),
      ]);
      expect(index.scan('KİS').mayMatch(0), isTrue);
      expect(index.scan('kıſ').mayMatch(0), isTrue);
    });
  });

  group('3. Katalog', () {
    final all = ImplicitPatterns.all;
    final index = LiteralIndex([for (final p in all) p.pattern]);
    const normalizer = TurkishNormalizer();

    test('üründeki her örüntüden bir ön filtre çıkarılabiliyor', () {
      // Doğruluk değil HIZ denetimi: yeni bir örüntü desteklenmeyen bir
      // yapı kullanırsa sessizce her cümlede çalışmaya başlar.
      final kisitsiz = [
        for (final p in all)
          if (LiteralPrefilter.requiredAnyOf(p.pattern) == null) p.id
      ];
      expect(kisitsiz, isEmpty,
          reason: 'Bu örüntüler her tuş vuruşunda çalışacak: $kisitsiz');
    });

    test('etiketli kümelerde her gerçek eşleşmede kapı açık', () {
      final metinler = [
        ...GoldDataset.cases,
        ...HoldoutDataset.cases,
        ...GeneralizationDataset.cases,
        ...Generalization2Dataset.cases,
        ...Generalization3Dataset.cases,
        ...Generalization4Dataset.cases,
        ...Generalization5Dataset.cases,
      ].map((c) => c.text);

      var eslesme = 0;
      final ihlaller = <String>[];
      for (final ham in metinler) {
        // Dedektör normalize metin alır; ham metin de denenir çünkü
        // `detect` herkese açıktır.
        for (final text in {normalizer.normalize(ham).value, ham}) {
          final hits = index.scan(text);
          for (var i = 0; i < all.length; i++) {
            if (!all[i].pattern.hasMatch(text)) continue;
            eslesme++;
            if (!hits.mayMatch(i)) ihlaller.add('${all[i].id} :: "$text"');
          }
        }
      }

      expect(eslesme, greaterThan(300),
          reason: 'Sınama anlamlı olmak için yeterince gerçek eşleşme görmeli.');
      expect(ihlaller, isEmpty,
          reason: 'Kapı gerçek bir eşleşmeyi kapattı:\n${ihlaller.join("\n")}');
    });
  });
}
