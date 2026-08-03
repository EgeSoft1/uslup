// =============================================================================
// Nefret Söylemi Katmanı — Test Paketi
// Dosya: packages/civility_core/test/hate_layer_test.dart
//
// Bu katmanın iki iddiası vardır ve ikisi de ayrı ayrı kanıtlanmak zorundadır:
//
//   1. YAKALAR   — kimlik hedefli düşmanlığı, küfür geçmese bile görür.
//   2. YAKALAMAZ — kimliğinden söz eden insanı ASLA işaretlemez.
//
// İkincisi olmadan birincisi bir başarı değil, bir tehlikedir: kimlik
// adlarını yasaklı kelime sayan bir sistem, korumayı vaat ettiği grubu
// susturur. Bu yüzden her aile için bir "yakalanır" / "yakalanmaz" çifti,
// ayrıca ayrı bir özgüllük bölümü vardır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  late LexicalTurkishClassifier engine;

  setUp(() => engine = LexicalTurkishClassifier());

  bool flags(String text) => engine.analyze(text).risk != RiskLevel.temiz;
  CivilityAnalysis analyze(String text) => engine.analyze(text);

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Kimlik terimleri tek başına ASLA işaretlenmez', () {
    // Katmanın var olma şartı. Bu grup kırmızıysa katman yayına çıkamaz.
    const innocent = <String>[
      'Ben Kürtüm',
      'Ermeni arkadaşım geldi',
      'Suriyeli komşumuz çok yardımsever',
      'Alevi kültürü üzerine tez yazıyorum',
      'Eşcinsel hakları konferansına katıldım',
      'Yahudi cemaatiyle görüştük',
      'Romanlar müzikte çok yetenekli',
      'Translar için dayanışma ağı kuruldu',
      'Mülteci çocuklara ders veriyorum',
      'Arnavut böreği yaptık',
      'Çerkes düğününe davetliyiz',
      'Süryani kilisesini gezdik',
      'Müslüman ve Hristiyan cemaatler bir araya geldi',
      'Engelli erişimi için rampa yapıldı',
      'Kadınlar futbol takımı şampiyon oldu',
    ];

    for (final text in innocent) {
      test('"$text" temiz kalır', () {
        expect(flags(text), isFalse,
            reason: 'Kimlik adı tek başına toksik değildir. Bu cümlenin '
                'işaretlenmesi, ürünün etik iddiasını çürütür.');
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Aile bazında yakalar / yakalamaz çiftleri', () {
    test('insanlıktan çıkarma yakalanır, aynı kelimeler nesne konumunda değil',
        () {
      expect(flags('Suriyeliler hayvandır'), isTrue);
      expect(flags('Suriyeli gönüllüler hayvan haklarıyla ilgileniyor'), isFalse,
          reason: 'Ayrım yüklem ekidir. İlk sürümde bu cümle yanlış pozitif '
              'üretiyordu; "hayvan" burada nesne, yüklem değil.');
    });

    test('dışlama yakalanır, bildirme kipi yakalanmaz', () {
      expect(flags('Suriyeliler defolsun ülkelerine'), isTrue);
      expect(flags('Suriyeli komşumuz memleketine gitti'), isFalse,
          reason: 'Ayrım kiptir: istek kipi çağrı, bildirme kipi haberdir.');
    });

    test('toplu suçlama yakalanır, olumlu genelleme yakalanmaz', () {
      expect(flags('Bütün Suriyeliler hırsızdır'), isTrue);
      expect(flags('Bütün Kürt arkadaşlarım çok misafirperver'), isFalse,
          reason: 'Niceleyici + kimlik tek başına saldırı değildir; '
              'düşmanca yüklem şarttır.');
      expect(flags('Bütün öğrenciler sınava girecek'), isFalse,
          reason: 'Kimlik yuvası yok.');
    });

    test('kimlik aşağılama yakalanır, kimlik beyanı yakalanmaz', () {
      expect(flags('Eşcinseller hastalıklı'), isTrue);
      expect(flags('Aleviler aşağılıktır'), isTrue);
      expect(flags('Eşcinsel bireylerin hakları anayasal güvencede'), isFalse);
    });

    test('varlık reddi yakalanır ve en yüksek seviyeyi tetikler', () {
      final analysis = analyze('Yahudiler yok edilmeli');
      expect(analysis.risk, RiskLevel.yuksek,
          reason: 'Şiddete çağrı en ağır müdahaleyi gerektirir.');
      expect(analysis.dominantCategory, ToxicityCategory.nefret);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Ambigü kökler — aksan katlaması sonrası çakışanlar', () {
    // "Kürt" → "kurt" gibi katlamalar meşru kelimelerle çakışır. Ünlü uyumu
    // bu ayrımı katlamadan SONRA da koruduğu için tekil biçim yerine
    // çoğul biçim kullanılıyor. Bu testler o kararı kilitler.
    test('"kurtlar" (hayvan) ile "kurtler" (Kürtler) karışmaz', () {
      expect(flags('Kurtlar ormanda sürü hâlinde yaşar'), isFalse);
      expect(flags('Kurtarma ekibi bölgeye ulaştı'), isFalse);
      expect(flags('Kürtler defolsun'), isTrue);
    });

    test('"roman" (kitap) ile "Romanlar" (halk) karışmaz', () {
      expect(flags('Bu roman çok güzeldi'), isFalse);
      expect(flags('Romanları okumayı seviyorum'), isFalse);
      expect(flags('Bu Romanlar hep dolandırıcı'), isTrue);
    });

    test('"lazım", "transfer", "araba", "geyik" tuzağa düşmez', () {
      expect(flags('Lazım olan malzemeyi aldım'), isFalse);
      expect(flags('Transfer işlemi tamamlandı'), isFalse);
      expect(flags('Arabayı tamire götürdüm'), isFalse);
      expect(flags('Geyik sürüsü yolu kesti'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Mağdur korunur', () {
    // Ürünün en ayırt edici iddiası: tacizi BİLDİREN kişi işaretlenmez.
    test('nefret söylemini aktaran kişi cezalandırılmaz', () {
      expect(flags('Bana "zenci" dedi, çok üzüldüm'), isFalse);
      expect(flags('Sırf Kürt olduğum için işe alınmadım'), isFalse);
    });

    test('konuyu adlandırmak nefret söylemi değildir', () {
      expect(flags('Nefret söylemine karşı kampanya başlattık'), isFalse);
      expect(flags('Ayrımcılıkla mücadele raporu yayımlandı'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('5. Kategori ve açıklanabilirlik', () {
    test('bulgu nefret kategorisine atanır', () {
      final analysis = analyze('Bütün Suriyeliler hırsızdır');
      expect(analysis.dominantCategory, ToxicityCategory.nefret);
    });

    test('her bulgu bir gerekçe taşır — kara kutu yok', () {
      final analysis = analyze('Eşcinseller hastalıklı');
      expect(analysis.findings, isNotEmpty);
      for (final finding in analysis.findings) {
        expect(finding.explanation, isNotEmpty,
            reason: 'Şeffaflık ilkesi: her uyarı "neden" sorusuna '
                'cevap vermek zorunda.');
      }
    });

    test('kimlik söz varlığı örüntüye gömülüdür, sözlükte değildir', () {
      // Yapısal güvence: sözlüğe kimlik adı sızarsa bu test kırılır.
      final identityRoots = ['kurt', 'ermeni', 'alevi', 'escinsel', 'suriyeli'];
      for (final entry in ToxicityLexicon.entries) {
        final term = entry.term.toLowerCase();
        for (final root in identityRoots) {
          expect(term.contains(root), isFalse,
              reason: '"${entry.term}" bir kimlik adı içeriyor. Kimlik adları '
                  'sözlüğe ASLA girmez — yalnızca hate_patterns.dart '
                  'içinde yuva doldurur.');
        }
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('6. Performans — katman eklendi, bütçe korunuyor', () {
    test('nefret katmanıyla birlikte tek çözümleme 16 ms altında kalır', () {
      const samples = [
        'Bütün Suriyeliler hırsızdır',
        'Ben Kürtüm ve bu ülkede yaşıyorum',
        'Merhaba, yarın buluşalım mı?',
      ];

      // Isınma — ilk çağrı sözlüğü kurar.
      for (final s in samples) {
        engine.analyze(s);
      }

      final stopwatch = Stopwatch()..start();
      const iterations = 300;
      for (var i = 0; i < iterations; i++) {
        engine.analyze(samples[i % samples.length]);
      }
      stopwatch.stop();

      final perCall = stopwatch.elapsedMicroseconds / iterations;
      // ignore: avoid_print
      print('Ortalama çözümleme (nefret katmanı dahil): '
          '${perCall.toStringAsFixed(1)} µs');

      expect(perCall, lessThan(16000),
          reason: '60 FPS kare bütçesi 16 ms. Gecikmeli tetikleme '
              'olmadığı için tek çözümleme bunun altında kalmalı.');
    });
  });
}
