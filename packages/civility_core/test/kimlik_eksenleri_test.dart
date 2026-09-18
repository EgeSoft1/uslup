// =============================================================================
// İP-33 · Kimlik Eksenleri — cinsiyet, yaş, engellilik, göç (docs/26)
// Dosya: packages/civility_core/test/kimlik_eksenleri_test.dart
//
// Nefret katmanının kimlik söz varlığı bu dört grubu kapsıyordu ama yüklem
// söz varlığı kapsamıyordu: İP-33 önce-ölçümünde 32 saldırının 0'ı
// yakalanıyordu. Bu dosya yeni kuruluşları ve — daha önemlisi — onların
// SUSTURMAMASI gereken cümleleri kilitler.
//
// Buradaki cümleler ölçüm kümesi DEĞİLDİR; geliştirme sırasında yazılan
// ek taramadır (docs/26 §4). Geçerli ölçüm İP-35'tir.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  final engine = LexicalTurkishClassifier();

  group('1. Dört eksende saldırı yakalanır ve nefret sayılır', () {
    const saldirilar = [
      // cinsiyet
      'Kadınlar hiçbir şeyi beceremez',
      'Kadınlar matematikten anlamaz zaten',
      'Kadınların yeri mutfaktır',
      'Kadınlar evlendikten sonra çalışmamalı',
      'Kızdan mühendis olmaz',
      'Kadın milleti para yönetmeyi bilmez',
      'Kadınların futbolla ne işi var',
      // yaş
      'Yaşlılar bir şey öğrenemez',
      'Yaşlıların aklı ermez bu işlere',
      'Yaşlıların oy hakkı alınmalı',
      'Yaşlılar gebersin',
      'Emekliler bir işe yaramaz',
      // engellilik
      'Engelliler hiçbir işe yaramıyor artık',
      'Engellilerin yeri evleridir',
      'Otistikler insan değil',
      'Engellilerle uğraşmak zaman kaybı',
      'Engelliler okula gitmemeli',
      'Sakatlar ortalıkta dolaşmasın',
      // göç
      'Göçmenler ekmeğimizi elimizden alıyor',
      'Mülteciler suç makinesi',
      'Sığınmacılar sırtımızdan geçiniyor',
      'Göçmenler ölse de kurtulsak',
      'Göçmenler yüzünden huzur kalmadı',
      'Göçmenlere iş verilmemeli',
    ];
    for (final text in saldirilar) {
      test(text, () {
        final a = engine.analyze(text);
        expect(a.risk, isNot(RiskLevel.temiz), reason: 'KAÇTI: $text');
        expect(a.dominantCategory, ToxicityCategory.nefret);
      });
    }
  });

  group('2. Aynı kalıpları taşıyan masum cümleler temiz kalır', () {
    const masumlar = {
      'durum bildiren engel': [
        'Engelliler bu binaya giremez çünkü asansör yok',
        'Kadınlar gece bu sokakta yürüyemiyor, aydınlatma şart',
        'Engelliler oy kullanamıyor çünkü sandık ikinci katta',
      ],
      'ilgeç tümleci — yüklemin öznesi grup değil': [
        'Engelliler için yapılan rampa hiçbir işe yaramıyor',
        'Kadınlara yönelik ayrımcılık hiçbir işe yaramaz, herkes kaybeder',
      ],
      'koşul tümleci — kamu uyarısı ve mevzuat': [
        'Kar yağışı nedeniyle engelli vatandaşlar zorunlu olmadıkça evden çıkmamalı',
        'Doğum sonrası ilk altı hafta kadınlar ağır işte çalışmamalı',
        'Salgın süresince yaşlılar sokağa çıkmamalı kararı kaldırıldı',
        'Engelliler polis olamaz çünkü yönetmelik fiziksel şart arıyor',
      ],
      'anma — aktarma, soru, önyargının adı': [
        'Kadınların aklı ermez diyenlere bu başarı cevap olsun',
        'Yaşlılar teknolojiden anlamaz önyargısını yıkan bir proje',
        'Göçmenler işimizi çalıyor mu? Verilere bakalım',
        'Göçmenler ülkemizi işgal ediyor söylemi tehlikeli',
        'Kızdan şoför olmaz sanıyorlardı, şimdi otobüs kullanıyor',
        'Göçmenler bu ülkenin kanını emiyor gibi cümleler nefret söylemidir',
      ],
      'olumsuzlanmış yargı ve eşitlik savunusu': [
        'Kadınlar ikinci sınıf insan değildir',
        'Mülteciler de bizim gibi insan değil mi?',
        'Yaşlıların yeri huzurevi değil, ailesinin yanı',
        'Mülteciler yüzünden değil, kötü yönetim yüzünden huzur kalmadı',
        'Engellileri işe almamak para israfı, yetenek kaybı',
        'Göçmenleri sigortasız çalıştırmak devlete zarar',
      ],
      'grubun kendi isteği ve politika görüşü': [
        'Mülteciler ülkelerine dönmek istiyor ama savaş hâlâ bitmedi',
        'Mülteciler ülkelerine dönmek zorunda kalmamalı, savaş sürüyor',
        'Sığınmacı sayısı ve maliyeti hakkında şeffaf veri paylaşılmalı',
        'Sığınmacılar oy kullanmamalı',
      ],
      'tek bir kişi — nefret değil': [
        'Bu kadından doktor olmaz, çok dikkatsiz',
      ],
    };
    masumlar.forEach((tur, cumleler) {
      group(tur, () {
        for (final text in cumleler) {
          test(text, () {
            final a = engine.analyze(text);
            // "Bu kadından doktor olmaz" kişiye yöneltilmiş olabilir; burada
            // denetlenen yalnızca NEFRET kategorisinin üretilmemesidir.
            if (tur.startsWith('tek bir kişi')) {
              expect(a.findings.where((f) => f.term.startsWith('nefret.')),
                  isEmpty);
            } else {
              expect(a.risk, RiskLevel.temiz,
                  reason: 'YANLIŞ ALARM: $text → '
                      '${a.findings.map((f) => f.term).toList()}');
            }
          });
        }
      });
    });
  });

  group('3. Yapısal değişmezler', () {
    test('normalize metinde geçemeyen harf (q, w, x) hiçbir örüntüde yok', () {
      // Normalleştirici q → k, w → v, x → ks çevirir. Bu harflerden birini
      // taşıyan örüntü parçası ÖLÜDÜR: "queer" ve "down sendromlu" İP-17'den
      // İP-33'e kadar hiçbir metinde eşleşmedi ve hiçbir test bunu görmedi.
      final olu = <String>[];
      for (final p in ImplicitPatterns.all) {
        final kaynak = p.pattern.pattern.replaceAll(RegExp(r'\\[wWsSbBdD]'), '');
        if (RegExp('[qwx]').hasMatch(kaynak)) olu.add(p.id);
      }
      expect(olu, isEmpty, reason: 'Ölü harf taşıyan örüntüler: $olu');
    });

    test('İP-17 ölü terimleri artık eşleşiyor', () {
      expect(engine.analyze('Down sendromlular aşağılıktır').risk,
          isNot(RiskLevel.temiz));
      expect(engine.analyze('Queer bireyler hastalıklı').risk,
          isNot(RiskLevel.temiz));
    });

    test('vatandaşlık hakkı yuvası göç statüsünü içermez', () {
      final yuva = RegExp('^${IdentityTerms.slotExceptMigration}\$');
      for (final g in ['multeciler', 'gocmenler', 'siginmacilar']) {
        expect(yuva.hasMatch(g), isFalse, reason: g);
      }
      for (final g in ['kadinlar', 'yaslilar', 'aleviler', 'engelliler']) {
        expect(yuva.hasMatch(g), isTrue, reason: g);
      }
    });

    test('koşul tümecine bağlı örüntüler bu denetimi taşır', () {
      const kosullu = {
        'nefret.yetersizlik_atfi',
        'nefret.hak_reddi',
        'nefret.yer_bicme_istek',
        'nefret.oy_hakki_reddi',
      };
      for (final p in HatePatterns.all) {
        if (kosullu.contains(p.id)) {
          expect(p.suppressedBy, isNotNull, reason: p.id);
        }
      }
    });

    test('yeni aileler kullanıcıya gerekçe gösterir', () {
      for (final f in [ImplicitFamily.kalipYargi, ImplicitFamily.hakReddi]) {
        expect(f.label, isNotEmpty);
        expect(f.explanation.length, greaterThan(40));
      }
    });
  });
}
