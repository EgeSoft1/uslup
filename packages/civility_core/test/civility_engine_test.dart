// =============================================================================
// NSosyal Sosyal YZ — Nezaket Motoru Test Paketi
// Dosya: packages/civility_core/test/civility_engine_test.dart
//
// Bu test paketi teknik raporun "ölçülebilir yapay zekâ" iddiasının kanıtıdır.
// Dört sınıfa ayrılmıştır:
//
//   1. NORMALİZASYON       — gizleme hilelerinin geri çevrilmesi
//   2. DOĞRU POZİTİF       — gerçek saldırıların yakalanması
//   3. YANLIŞ POZİTİF      — masum metnin YAKALANMAMASI  ← en kritik grup
//   4. BAĞLAM              — aynı kelimenin bağlama göre farklı işlenmesi
//   5. PERFORMANS          — 60 FPS bütçesine uyum
//
// 3. grup neden en kritik: Bir moderasyon sistemi yanlış pozitif üretirse
// kullanıcı ona güvenmeyi bırakır ve kapatır. Kaçırılan bir hakaretin
// maliyeti, masum bir cümlenin haksız yere engellenmesinden düşüktür.
// =============================================================================

import 'package:test/test.dart';
import 'package:civility_core/civility_core.dart';

void main() {
  late LexicalTurkishClassifier engine;
  const normalizer = TurkishNormalizer();

  setUp(() {
    engine = LexicalTurkishClassifier();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Normalizasyon', () {
    test('Türkçe küçük harf dönüşümü doğru yapılır', () {
      // Dart'ın toLowerCase()'i 'I' → 'i' verir; Türkçe'de 'ı' olmalı.
      expect(normalizer.normalize('IŞIK').value, 'isik');
      expect(normalizer.normalize('İSTANBUL').value, 'istanbul');
    });

    test('aksanlar katlanır — Türkçe klavyesi olmayan kullanıcı yakalanır', () {
      expect(normalizer.normalize('şerefsiz').value, 'serefsiz');
      expect(normalizer.normalize('serefsiz').value, 'serefsiz');
      expect(normalizer.normalize('ÖĞÜT').value, 'ogut');
    });

    test('3+ tekrar eden harfler daraltılır, 2 tekrar korunur', () {
      // "çoookkk" → hile
      expect(normalizer.normalize('çoookkk').value, 'cok');
      // "elli" → meşru Türkçe, bozulmamalı
      expect(normalizer.normalize('elli').value, 'elli');
      expect(normalizer.normalize('dikkat').value, 'dikkat');
    });

    test('kelime içi ayırıcılar silinir', () {
      expect(normalizer.normalize('a.p.t.a.l').value, 'aptal');
      expect(normalizer.normalize('ap-tal').value, 'aptal');
    });

    test('temkinli varyant sayısal veriyi bozmaz', () {
      // Bu, iki varyantlı tasarımın var olma sebebi.
      expect(normalizer.normalize('saat 19:00').value, contains('19:00'));
      expect(normalizer.normalize('2026').value, '2026');
    });

    test('agresif varyant tüm leet karakterleri çevirir', () {
      expect(normalizer.normalize(r'$3r3fsiz').aggressive, 'serefsiz');
    });

    test('iki varyant her zaman aynı uzunlukta — indeks hizası korunur', () {
      const samples = [
        'saat 19:00 buluşalım',
        r'$3r3fsiz herif',
        'Merhaba! Nasılsın?',
        '2026 yılında 100 kişi',
      ];
      for (final sample in samples) {
        final n = normalizer.normalize(sample);
        expect(n.value.length, n.aggressive.length, reason: 'girdi: $sample');
        expect(n.sourceIndices.length, n.value.length, reason: 'girdi: $sample');
      }
    });

    test('offset haritası orijinal metne doğru geri döner', () {
      const input = 'sen çok aptalsın';
      final n = normalizer.normalize(input);
      final index = n.value.indexOf('aptal');
      final range = n.toOriginalRange(index, index + 5);
      expect(input.substring(range.start, range.end), 'aptal');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Doğru pozitif — gerçek saldırılar yakalanmalı', () {
    test('doğrudan hakaret tespit edilir', () {
      final result = engine.analyze('sen tam bir aptalsın');
      expect(result.hasFindings, isTrue);
      expect(result.findings.first.category, ToxicityCategory.hakaret);
      expect(result.risk.index, greaterThanOrEqualTo(RiskLevel.riskli.index));
    });

    test('Türkçe ek almış çekimli hâller yakalanır (eklemeli dil testi)', () {
      // Tek bir "aptal" kökü tüm bu çekimleri yakalamalı.
      const inflections = [
        'sen aptalsın',
        'siz aptallarsınız',
        'aptallığın daniskası sende',
        'ne aptalca bir cevap sen yazmışsın',
      ];
      for (final text in inflections) {
        expect(engine.analyze(text).hasFindings, isTrue, reason: text);
      }
    });

    test('küfür en yüksek risk seviyesini üretir', () {
      final result = engine.analyze('siktir git buradan');
      expect(result.risk, RiskLevel.yuksek);
      expect(result.findings.first.category, ToxicityCategory.kufur);
    });

    test('tehdit ayrı olarak işaretlenir — yasal yükümlülük akışı', () {
      final result = engine.analyze('seni gebertirim');
      expect(result.containsThreat, isTrue);
      expect(result.risk, RiskLevel.yuksek);
    });

    test('birden fazla hakaret tek hakaretten daha yüksek skor üretir', () {
      // Noisy-OR birikiminin doğrulaması: maksimum alsaydık eşit çıkardı.
      final tek = engine.analyze('sen aptalsın');
      final coklu = engine.analyze('sen aptalsın ve gerizekalısın');
      expect(coklu.toxicity, greaterThan(tek.toxicity));
    });

    test('düşük şiddetli aşağılama da yakalanır — ürünün asıl katma değeri', () {
      // Hiçbir platform bunu engellemiyor ama ortamı en çok bunlar bozuyor.
      final result = engine.analyze('sen kapa çeneni');
      expect(result.hasFindings, isTrue);
      expect(result.findings.first.category, ToxicityCategory.asagilama);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Yanlış pozitif — masum metin ASLA yakalanmamalı', () {
    test('aksan katlaması sonrası çakışan meşru kelimeler elenir', () {
      // Bunların hepsi naif bir filtrede küfür/hakaret sanılır.
      const innocent = [
        'bu konuda şikayet etmek istiyorum',   // "şikayet" → "sikayet"
        'çantayı yukarı götürdü',               // "götürdü" → "goturdu"
        'malzeme listesini gönderdim',          // "malzeme" → "mal..."
        'senin adın ne?',                       // "adın"   → "adi..."
        'itiraz hakkımı kullanıyorum',          // "itiraz" → "it..."
        'köpekbalığı belgeseli izledim',        // "köpek..."
        'maliyet analizi hazır',                // "mali..."
        'görev tanımı belli değil',             // "görev"  → "gor..."
      ];
      for (final text in innocent) {
        final result = engine.analyze(text);
        expect(result.risk, RiskLevel.temiz, reason: 'YANLIŞ POZİTİF: $text');
      }
    });

    test('hayvan adları literal anlamda kullanılınca yakalanmaz', () {
      // `requiresDirection` mekanizmasının doğrulaması.
      const literal = [
        'köpeğim çok hasta, veterinere götürüyorum',
        'eşek arısı soktu',
        'hayvanları çok severim',
        'domuz gribi aşısı oldum',
      ];
      for (final text in literal) {
        expect(engine.analyze(text).risk, RiskLevel.temiz, reason: text);
      }
    });

    test('hayvan adları ikinci şahsa yöneltilince YAKALANIR', () {
      // Aynı kelimeler, farklı bağlam → tam ters sonuç.
      expect(engine.analyze('sen tam bir eşeksin').hasFindings, isTrue);
      expect(engine.analyze('köpeksin sen').hasFindings, isTrue);
    });

    test('normal günlük metin temiz kalır', () {
      const everyday = [
        'Yarın saat 19:00 da Kadıköy de buluşalım mı?',
        'Toplantı notlarını paylaşabilir misin?',
        'Bu projede 2026 hedeflerimizi konuşalım',
        'Teşekkür ederim, çok yardımcı oldun 🙏',
        'Katılmıyorum ama görüşüne saygı duyuyorum',
      ];
      for (final text in everyday) {
        final result = engine.analyze(text);
        expect(result.risk, RiskLevel.temiz, reason: text);
        expect(result.civilityScore, 100, reason: text);
      }
    });

    test('boş ve boşluk metin çökmez', () {
      expect(engine.analyze('').risk, RiskLevel.temiz);
      expect(engine.analyze('   ').risk, RiskLevel.temiz);
      expect(engine.analyze('\n\t').risk, RiskLevel.temiz);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Bağlam — aynı kelime, farklı anlam', () {
    test('olumsuzlama saldırıyı iptal eder', () {
      // "aptal değilsin" bir iltifattır.
      final result = engine.analyze('sen hiç aptal değilsin');
      expect(result.risk, RiskLevel.temiz);
    });

    test('alıntı/aktarım mağduru cezalandırmaz', () {
      // Taciz bildiren kullanıcı susturulmamalı — mevcut sistemlerin
      // en büyük başarısızlığı budur.
      final result = engine.analyze('bana "aptal" dedi, çok üzüldüm');
      expect(result.risk, RiskLevel.temiz,
          reason: 'Şikâyet eden kullanıcı cezalandırılıyor');
    });

    test('öz-yönelimli ifadeye müdahale edilmez', () {
      final result = engine.analyze('kendimi çok aptal hissettim bugün');
      expect(result.risk, RiskLevel.temiz);
    });

    test('doğrudan yönelim şiddeti artırır', () {
      final yonelimsiz = engine.analyze('aptal bir karar olmuş');
      final yonelimli = engine.analyze('sen aptalsın');
      expect(yonelimli.toxicity, greaterThan(yonelimsiz.toxicity));
    });

    test('bağırma (büyük harf) şiddeti artırır', () {
      final normal = engine.analyze('sen tam bir aptalsın gerçekten');
      final bagiran = engine.analyze('SEN TAM BİR APTALSIN GERÇEKTEN');
      expect(bagiran.toxicity, greaterThan(normal.toxicity));
    });

    test('bağlam kararı kullanıcıya açıklanabilir — şeffaflık ilkesi', () {
      final result = engine.analyze('sen aptalsın');
      expect(result.findings.first.explanation, isNotEmpty);
      expect(result.findings.first.context.reason, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('5. Kaçınma (evasion) direnci', () {
    test('leet yazım yakalanır', () {
      expect(engine.analyze('sen 4pt4lsin').hasFindings, isTrue);
      expect(engine.analyze(r'sen $3r3fsizsin').hasFindings, isTrue);
    });

    test('harf arası noktalama yakalanır', () {
      expect(engine.analyze('sen a.p.t.a.l.s.i.n').hasFindings, isTrue);
    });

    test('harf arası boşluk hilesi yakalanır', () {
      expect(engine.analyze('a m k').hasFindings, isTrue);
    });

    test('harf tekrarı hilesi yakalanır', () {
      expect(engine.analyze('sen aptaaaalsın').hasFindings, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('6. Performans — 60 FPS bütçesi', () {
    test('tek çözümleme 16 ms altında tamamlanır', () {
      // Motor her tuş vuruşunda çalışır; 16 ms aşılırsa kare düşer.
      const text =
          'Sen tam bir aptalsın ve gerçekten şerefsizsin, bunu böyle bilesin. '
          'Bu arada yarın saat 19:00 da toplantı var, katılman gerekiyor.';

      // Isınma (JIT) — ilk çağrı ölçüme dâhil edilmez.
      engine.analyze(text);

      final stopwatch = Stopwatch()..start();
      const iterations = 100;
      for (int i = 0; i < iterations; i++) {
        engine.analyze(text);
      }
      stopwatch.stop();

      final avgMicros = stopwatch.elapsedMicroseconds / iterations;
      // ignore: avoid_print
      print('Ortalama çözümleme süresi: ${avgMicros.toStringAsFixed(1)} µs');

      expect(avgMicros, lessThan(16000),
          reason: '60 FPS bütçesi (16 ms) aşıldı');
    });

    test('uzun metinde de doğrusal ölçeklenir', () {
      final long = 'Bu normal bir cümledir. ' * 200;
      final result = engine.analyze(long);
      expect(result.elapsed.inMilliseconds, lessThan(100));
    });
  });
}
