import 'package:test/test.dart';
import 'package:civility_core/civility_core.dart';

void main() {
  group('Türkçe Biçimbilim (Morphology) Testleri', () {
    test('Büyük ve küçük ünlü uyumu kuralları doğru çalışır', () {
      // Kalın kök + kalın ek: Geçerli
      expect(TurkishMorphology.isVowelHarmonious('aptal', 'lar'), isTrue);
      expect(TurkishMorphology.isVowelHarmonious('aptal', 'sin'), isTrue);
      expect(TurkishMorphology.isVowelHarmonious('aptal', 'dan'), isTrue);

      // Kalın kök + ince ek: Geçersiz
      expect(TurkishMorphology.isVowelHarmonious('aptal', 'ler'), isFalse);
      expect(TurkishMorphology.isVowelHarmonious('aptal', 'den'), isFalse);

      // İnce kök + ince ek: Geçerli
      expect(TurkishMorphology.isVowelHarmonious('serefsiz', 'ler'), isTrue);
      expect(TurkishMorphology.isVowelHarmonious('serefsiz', 'sin'), isTrue);
      expect(TurkishMorphology.isVowelHarmonious('serefsiz', 'den'), isTrue);

      // İnce kök + kalın ek: Geçersiz
      expect(TurkishMorphology.isVowelHarmonious('serefsiz', 'lar'), isFalse);
      expect(TurkishMorphology.isVowelHarmonious('serefsiz', 'dan'), isFalse);
    });

    test('Ünsüz yumuşaması ve sertleşmesi doğru türetilir', () {
      expect(TurkishMorphology.softenNormalizedStem('salak'), 'salag');
      expect(TurkishMorphology.softenNormalizedStem('kopek'), 'kopeg');
      expect(TurkishMorphology.softenNormalizedStem('dalyarak'), 'dalyarag');
      expect(TurkishMorphology.softenNormalizedStem('got'), 'god');

      expect(TurkishMorphology.hardenNormalizedStem('salag'), 'salak');
      expect(TurkishMorphology.hardenNormalizedStem('kopeg'), 'kopek');
      expect(TurkishMorphology.hardenNormalizedStem('god'), 'got');
    });

    test('Meşru Türkçe çekim ekleri onaylanır, sahte ekler reddedilir', () {
      // Meşru ekler
      expect(TurkishMorphology.isValidSuffix('aptal', 'lar'), isTrue);
      expect(TurkishMorphology.isValidSuffix('aptal', 'sin'), isTrue);
      expect(TurkishMorphology.isValidSuffix('aptal', 'siniz'), isTrue);
      expect(TurkishMorphology.isValidSuffix('aptal', 'lik'), isTrue);
      expect(TurkishMorphology.isValidSuffix('aptal', 'dan'), isTrue);

      // Sahte / Geçersiz ekler
      expect(TurkishMorphology.isValidSuffix('am', 'ac'), isFalse); // amaç
      expect(TurkishMorphology.isValidSuffix('am', 'balaj'), isFalse); // ambalaj
      expect(TurkishMorphology.isValidSuffix('mal', 'zeme'), isFalse); // malzeme
      expect(TurkishMorphology.isValidSuffix('mal', 'iyet'), isFalse); // maliyet
      expect(TurkishMorphology.isValidSuffix('bok', 'sor'), isFalse); // boksör
      expect(TurkishMorphology.isValidSuffix('bok', 's'), isFalse); // boks
      expect(TurkishMorphology.isValidSuffix('it', 'faiye'), isFalse); // itfaiye
    });

    test('Kısa kök kuralı hassas terimleri izole eder', () {
      // "am" kökü — yalnızca meşru küfür çekimlerine izin verir
      expect(TurkishMorphology.isValidInflectedForm('amina', 'am'), isTrue);
      expect(TurkishMorphology.isValidInflectedForm('amini', 'am'), isTrue);
      expect(TurkishMorphology.isValidInflectedForm('aminda', 'am'), isTrue);
      expect(TurkishMorphology.isValidInflectedForm('amindan', 'am'), isTrue);
      expect(TurkishMorphology.isValidInflectedForm('amcik', 'am'), isTrue);

      // "am" kökü ile başlayan ama ekleri uymayan meşru kelimeler ASLA yakalanmaz
      expect(TurkishMorphology.isValidInflectedForm('amac', 'am'), isFalse);
      expect(TurkishMorphology.isValidInflectedForm('ambalaj', 'am'), isFalse);
      expect(TurkishMorphology.isValidInflectedForm('amca', 'am'), isFalse);
      expect(TurkishMorphology.isValidInflectedForm('amir', 'am'), isFalse);
      expect(TurkishMorphology.isValidInflectedForm('ameliyat', 'am'), isFalse);
    });

    test('Ünsüz yumuşaması içeren çekimli hakaretler tespit edilir', () {
      // salak -> salağım (normalize: salagim)
      expect(TurkishMorphology.isValidInflectedForm('salagim', 'salak'), isTrue);
      expect(TurkishMorphology.isValidInflectedForm('salagi', 'salak'), isTrue);

      // köpek -> köpeği (normalize: kopegi)
      expect(TurkishMorphology.isValidInflectedForm('kopegi', 'kopek'), isTrue);

      // dalyarak -> dalyarağı (normalize: dalyaragi)
      expect(TurkishMorphology.isValidInflectedForm('dalyaragi', 'dalyarak'), isTrue);
    });
  });
}
