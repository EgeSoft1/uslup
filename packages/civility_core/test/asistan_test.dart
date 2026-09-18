// =============================================================================
// Üslup Asistanı — niyet çözümleme ve içerik doğruluğu
// Dosya: packages/civility_core/test/asistan_test.dart
//
// İki ayrı iddia sınanır:
//
//   1. NİYET. Kullanıcının aynı şeyi söylemenin farklı yolları aynı yere
//      düşer: "bana nefret söylemi örnekleri sun", "NEFRET SÖYLEMİ göster",
//      "nefret soylemi ornegi var mi" — hepsi aynı içeriği getirir.
//
//   2. İÇERİK DOĞRULUĞU — asıl önemli olan bu. Asistan bir örnek gösterirken
//      "bu cümle işaretlenir" ya da "işaretlenmez" diye bir İDDİADA bulunur.
//      Aşağıdaki test her örneği GERÇEK motordan geçirir. Motor bir gün
//      farklı karar verirse bu test kırılır ve ekrandaki yalan yayına
//      çıkmadan yakalanır.
//
// Ekranda yazan hiçbir iddia elle bakımda değildir.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:civility_core/src/detect/idiom_patterns.dart';
import 'package:test/test.dart';

void main() {
  final motor = LexicalTurkishClassifier();
  final asistan = UslupAsistani(motor: motor);

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Sunulan her örnek, motorun gerçek davranışıyla aynı', () {
    for (final giris in UslupAsistani.icerikOrnekleri.entries) {
      final konu = giris.key;
      for (final ornek in giris.value) {
        test('${konu.baslik}: "${ornek.metin}"', () {
          final sonuc = motor.analyze(ornek.metin);
          final isaretlendi = sonuc.risk != RiskLevel.temiz;
          expect(
            isaretlendi,
            ornek.isaretlenir,
            reason: 'Asistan bu cümle için "işaretlenir: ${ornek.isaretlenir}" '
                'diyor ama motor ${sonuc.risk.name} döndürdü '
                '(toksisite ${sonuc.toxicity.toStringAsFixed(2)}).\n'
                'Ya örnek güncellenmeli ya da motordaki değişiklik geri '
                'alınmalı — ekranda yanlış bir iddia kalmamalı.',
          );
        });
      }
    }

    test('her konunun en az bir örneği var', () {
      for (final konu in IcerikKonusu.values) {
        expect(UslupAsistani.icerikOrnekleri[konu], isNotNull,
            reason: '${konu.baslik} için örnek tanımlanmamış.');
        expect(UslupAsistani.icerikOrnekleri[konu]!, isNotEmpty);
      }
    });

    test('örnek metinleri boş ya da açıklamasız değil', () {
      for (final liste in UslupAsistani.icerikOrnekleri.values) {
        for (final o in liste) {
          expect(o.metin.trim(), isNotEmpty);
          expect(o.aciklama.trim(), isNotEmpty);
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. İçerik isteği — aynı niyetin farklı söylenişleri', () {
    void ayniKonu(String soru, IcerikKonusu beklenen) {
      test('"$soru" → ${beklenen.baslik}', () {
        final c = asistan.yanitla(soru);
        expect(c.niyet, AsistanNiyeti.icerikOrnekleri);
        expect(c.konu, beklenen);
        expect(c.ornekler, isNotEmpty);
      });
    }

    ayniKonu('Bana nefret söylemi örnekleri sun', IcerikKonusu.nefretSoylemi);
    ayniKonu('NEFRET SÖYLEMİ ÖRNEKLERİ GÖSTER', IcerikKonusu.nefretSoylemi);
    ayniKonu('nefret soylemi ornegi var mi', IcerikKonusu.nefretSoylemi);
    ayniKonu('nefret söylemi', IcerikKonusu.nefretSoylemi);
    ayniKonu('bana mağdur anlatısı örnekleri getir', IcerikKonusu.magdurAnlatisi);
    ayniKonu('masum tuzak içerikleri listele', IcerikKonusu.masumTuzak);
    ayniKonu('gizleme denemesi örnekleri', IcerikKonusu.gizleme);
    ayniKonu('örtük saldırı senaryoları sun', IcerikKonusu.ortukSaldiri);
    ayniKonu('tehdit örneği göster', IcerikKonusu.tehdit);
    ayniKonu('deyimle aşağılama örnekleri', IcerikKonusu.deyim);
    ayniKonu('kimlik beyanı örnekleri', IcerikKonusu.kimlikBeyani);
    ayniKonu('hakaret örnekleri sun', IcerikKonusu.hakaret);

    test('konu söylenmeden içerik istenirse başlık listesi döner', () {
      final c = asistan.yanitla('bana içerik sun');
      expect(c.niyet, AsistanNiyeti.icerikOrnekleri);
      expect(c.konu, isNull);
      expect(c.maddeler.length, IcerikKonusu.values.length);
    });

    test('daha belirli konu kazanır: "nefret söylemi" ≠ yalnızca "nefret"', () {
      final c = asistan.yanitla('nefret söylemi örnekleri');
      expect(c.konu, IcerikKonusu.nefretSoylemi);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Bilgi niyetleri', () {
    void niyet(String soru, AsistanNiyeti beklenen) {
      test('"$soru" → ${beklenen.name}', () {
        expect(asistan.yanitla(soru).niyet, beklenen);
      });
    }

    niyet('Ölçüm sonuçlarınız ne?', AsistanNiyeti.olcumSonuclari);
    niyet('doğruluk oranınız kaç', AsistanNiyeti.olcumSonuclari);
    niyet('kesinlik ve duyarlılık nedir', AsistanNiyeti.olcumSonuclari);
    niyet('nasıl çalışıyor', AsistanNiyeti.nasilCalisir);
    niyet('hangi katmanlar var', AsistanNiyeti.nasilCalisir);
    niyet('yapay zeka modeli mi kullanıyorsunuz', AsistanNiyeti.nasilCalisir);
    niyet('yazdıklarım nereye gidiyor', AsistanNiyeti.mahremiyet);
    niyet('verilerim güvende mi', AsistanNiyeti.mahremiyet);
    niyet('mesajlarımı kaydediyor musunuz', AsistanNiyeti.mahremiyet);
    niyet('uyarıları kapatabilir miyim', AsistanNiyeti.ayarlar);
    niyet('hassasiyet ayarı var mı', AsistanNiyeti.ayarlar);
    niyet('çok fazla uyarı alıyorum', AsistanNiyeti.ayarlar);
    niyet('neler yapabilirsin', AsistanNiyeti.yetenekler);
    niyet('merhaba', AsistanNiyeti.selam);
    niyet('teşekkürler', AsistanNiyeti.selam);

    test('her bilgi cevabı dolu ve markdown işareti taşımıyor', () {
      for (final soru in const [
        'ölçüm sonuçları',
        'nasıl çalışıyor',
        'yazdıklarım nereye gidiyor',
        'uyarıları kapatabilir miyim',
        'neler yapabilirsin',
      ]) {
        final c = asistan.yanitla(soru);
        expect(c.baslik.trim(), isNotEmpty);
        expect(c.govde.trim(), isNotEmpty);
        expect(c.maddeler, isNotEmpty);
        // Ekran düz metin çizer; `**kalın**` ekranda yıldız olarak görünürdü.
        for (final m in [c.baslik, c.govde, ...c.maddeler]) {
          expect(m.contains('**'), isFalse, reason: 'markdown kaçağı: $m');
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Cümle çözümleme', () {
    test('tırnak içindeki cümle çözümlenir', () {
      final c = asistan.yanitla('şunu çözümle: "Sen tam bir aptalsın"');
      expect(c.niyet, AsistanNiyeti.metniCozumle);
      expect(c.cozumleme, isNotNull);
      expect(c.cozumleme!.risk, isNot(RiskLevel.temiz));
      expect(c.cozumleme!.text, 'Sen tam bir aptalsın');
    });

    test('iki nokta üstünden çözümleme', () {
      final c = asistan.yanitla('analiz et: Sen tam bir aptalsın');
      expect(c.niyet, AsistanNiyeti.metniCozumle);
      expect(c.cozumleme!.risk, isNot(RiskLevel.temiz));
    });

    test('düz yazılmış cümle çözümlenir', () {
      final c = asistan.yanitla('Senin gibilerden zaten bu beklenirdi');
      expect(c.niyet, AsistanNiyeti.metniCozumle);
      expect(c.cozumleme!.risk, isNot(RiskLevel.temiz));
    });

    test('masum cümle temiz döner', () {
      final c = asistan.yanitla('Yarın parkta buluşalım mı');
      expect(c.cozumleme?.risk ?? RiskLevel.temiz, RiskLevel.temiz);
    });

    test('cümle İÇİNDEKİ tırnak alıntı sayılmaz — mağdur temiz kalır', () {
      // Ürünün en ayırt edici davranışı. Tırnak eğer alıntı sayılsaydı
      // yalnızca «aptal» çözümlenir ve şikâyet eden işaretlenirdi.
      const cumle = 'Bana "aptal" dedi, çok üzüldüm';
      final c = asistan.yanitla(cumle);
      expect(c.niyet, AsistanNiyeti.metniCozumle);
      expect(c.cozumleme!.text, cumle,
          reason: 'Cümlenin tamamı çözümlenmeli, tırnak içi değil.');
      expect(c.cozumleme!.risk, RiskLevel.temiz);
    });

    test('baştan sona tırnaklı mesaj alıntıdır', () {
      final c = asistan.yanitla('"Sen tam bir aptalsın"');
      expect(c.cozumleme!.text, 'Sen tam bir aptalsın');
    });

    test('her devam önerisi tanınan bir niyete gider', () {
      // Çıkmaz sokak çipi olmamalı: bir öneriye dokunan kullanıcı
      // "bunu anlamadım" cevabı almamalı.
      final gorulen = <String>{};
      final kuyruk = <String>['', 'neler yapabilirsin'];
      while (kuyruk.isNotEmpty) {
        final soru = kuyruk.removeLast();
        if (!gorulen.add(soru)) continue;
        final c = asistan.yanitla(soru);
        for (final oneri in c.devamOnerileri) {
          final hedef = asistan.yanitla(oneri);
          expect(hedef.niyet, isNot(AsistanNiyeti.anlasilmadi),
              reason: '"$oneri" önerisi anlaşılmıyor.');
          kuyruk.add(oneri);
        }
      }
      expect(gorulen.length, greaterThan(5));
    });

    test('motor verilmezse istisna atmaz, çözümleme boş döner', () {
      final motorsuz = UslupAsistani();
      final c = motorsuz.yanitla('Sen tam bir aptalsın');
      expect(c.niyet, AsistanNiyeti.metniCozumle);
      expect(c.cozumleme, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('5. Dayanıklılık — hiçbir girdi çökertmez', () {
    test('boş, boşluk, tek karakter, çok uzun, emoji, kontrol karakteri', () {
      final girdiler = <String>[
        '', '   ', '\n', 'a', '?', '...', '!!!',
        'x' * 5000,
        '😀😀😀',
        '​​',
        r'$3r3fsiz',
        'nefret' * 300,
        '"',
        '""',
        ':',
        'çözümle:',
      ];
      for (final g in girdiler) {
        expect(() => asistan.yanitla(g), returnsNormally,
            reason: 'girdi çökertti: ${g.length} karakter');
        final c = asistan.yanitla(g);
        expect(c.baslik.trim(), isNotEmpty);
      }
    });

    test('anlaşılmayan soru dürüstçe söylenir', () {
      final c = asistan.yanitla('bugün hava nasıl olacak');
      expect(c.niyet, anyOf(AsistanNiyeti.anlasilmadi, AsistanNiyeti.metniCozumle));
      expect(c.baslik.trim(), isNotEmpty);
    });

    test('her cevap en az bir devam önerisi ya da madde taşır', () {
      for (final soru in const [
        'merhaba', 'neler yapabilirsin', 'nefret söylemi örnekleri',
        'ölçüm', 'nasıl çalışıyor', 'mahremiyet', 'ayarlar',
        'kjhgfdsa qwerty',
      ]) {
        final c = asistan.yanitla(soru);
        expect(c.devamOnerileri.isNotEmpty || c.maddeler.isNotEmpty, isTrue,
            reason: '"$soru" için çıkmaz sokak cevabı');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('6. Dürüstlük değişmezleri', () {
    test('asistan kendini dil modeli diye tanıtmaz', () {
      final metinler = <String>[];
      for (final soru in const [
        'neler yapabilirsin', 'merhaba', 'nasıl çalışıyor',
      ]) {
        final c = asistan.yanitla(soru);
        metinler.addAll([c.baslik, c.govde, ...c.maddeler]);
      }
      final hepsi = metinler.join(' ').toLowerCase();
      // "bir dil modeli değilim" gibi OLUMSUZ kullanım serbest; iddia yasak.
      expect(hepsi.contains('gpt'), isFalse);
      expect(hepsi.contains('chatgpt'), isFalse);
      expect(RegExp(r'llm(?! değil)').hasMatch(hepsi), isFalse);
    });

    test('katman sayıları motorun GERÇEK sayılarıyla aynı', () {
      // Bu sayılar sunumda ve mimari şeklinde de geçiyor. Bir kalıp eklenip
      // burası unutulursa jüriye yanlış sayı söylenir; 15 Eylül'de tam bu
      // oldu: ekranda "127 örüntü · 58 deyim" yazıyordu, gerçek 126 ve 59'du.
      final metin = asistan.yanitla('nasıl çalışıyor').maddeler.join(' ');

      final deyim = IdiomPatterns.all.length;
      final nefret = HatePatterns.all.length;
      final edimbilimsel = ImplicitPatterns.all.length - deyim - nefret;

      expect(metin, contains('$edimbilimsel örüntü'),
          reason: 'Edimbilimsel örüntü sayısı tutmuyor.');
      expect(metin, contains('$deyim deyim'), reason: 'Deyim sayısı tutmuyor.');
      expect(metin, contains('$nefret kuruluş'),
          reason: 'Nefret kuruluşu sayısı tutmuyor.');
      expect(metin, contains('${ToxicityLexicon.entries.length} girdi'),
          reason: 'Sözlük girdi sayısı tutmuyor.');
      expect(metin, contains('${IdentityTerms.all.length} kimlik terimi'),
          reason: 'Kimlik terimi sayısı tutmuyor.');
    });

    test('ölçüm cevabı kör küme ile geliştirme kümesini ayırır', () {
      final c = asistan.yanitla('ölçüm sonuçlarınız ne');
      final hepsi = c.maddeler.join(' ');
      expect(hepsi.contains('Kör küme'), isTrue);
      expect(hepsi.contains('ezber'), isTrue,
          reason: 'geliştirme kümesi ezber ölçüsü olarak nitelenmeli');
      expect(hepsi.contains('%45,0'), isTrue);
      expect(hepsi.contains('%100'), isTrue);
    });
  });
}
