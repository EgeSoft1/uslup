// =============================================================================
// Kelime listesi karşılaştırması — sunumdaki iddianın ölçümü
// Dosya: mobile/test/kelime_listesi_karsilastirma_test.dart
//
// Sunumda "bir kelime listesi bu dört cümlenin dördünü de işaretler"
// deniyor. Bu test o cümlenin DOĞRU olduğunu, aynı sözlük ve aynı
// normalizasyonla kurulmuş bir filtre üzerinde doğrular. Filtre bir saman
// adam olursa (ör. gizlemeyi çözemezse) karşılaştırma dürüst olmaz; bu
// yüzden filtrenin YAKALAMASI gerekenler de burada sınanır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/civility/civility_runtime.dart';
import 'package:turkiye_mesajlasma/core/civility/naive_wordlist_filter.dart';
import 'package:turkiye_mesajlasma/presentation/uslup/demo_scenarios.dart';

void main() {
  final filtre = NaiveWordlistFilter.instance;

  group('filtre bir saman adam değildir', () {
    test('açık hakareti ve gizlenmiş hâlini yakalar', () {
      expect(filtre.flags('Sen tam bir aptalsın'), isTrue);
      expect(filtre.flags(r'sen $3r3fsizsin'), isTrue,
          reason: 'Filtre de aynı normalizasyonu kullanıyor.');
      expect(filtre.flags('Seni gebertirim'), isTrue);
    });

    test('kısa terimleri alt dizi olarak aramaz', () {
      expect(filtre.flags('malzeme listesi hazır'), isFalse);
      expect(filtre.flags('itibarını korudu'), isFalse);
    });
  });

  group('sunumdaki iddia', () {
    test('"aptal" geçen dört cümlenin dördünü de işaretler', () {
      for (final s in demoScenarios.take(4)) {
        expect(filtre.flags(s.text), isTrue,
            reason: 'Kelime listesi "${s.text}" cümlesini işaretlemeli — '
                'sunum bunu söylüyor.');
      }
    });

    test('Üslup demo senaryolarında kelime listesinden kesinlikle daha iyi',
        () {
      var uslupDogru = 0;
      var listeDogru = 0;
      for (final s in demoScenarios) {
        final uslup = Civility.engine.analyze(s.text).risk != RiskLevel.temiz;
        if (uslup == s.expectFlag) uslupDogru++;
        if (filtre.flags(s.text) == s.expectFlag) listeDogru++;
      }
      expect(uslupDogru, demoScenarios.length);
      expect(listeDogru, lessThan(uslupDogru));
    });
  });
}
