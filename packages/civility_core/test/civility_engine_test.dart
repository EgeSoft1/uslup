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

    test('ünsüz yumuşaması içeren çekimli hakaretler yakalanır (k->ğ, p->b)', () {
      const softenedInflections = [
        'sen tam bir salağın tekisin',
        // Önceki cümle "senin gibi bir köpeği kimse istemez" idi. Somut
        // adlarda yönelim artık yapıyla aranıyor (docs/21, D7) ve "senin
        // gibi X" kuruluşu o yapılardan biri değil — bu, kayıtta öngörülen
        // bedeldir. Test biçimbilimi (k→ğ) sınar; aynı yumuşama D7'nin
        // tanıdığı bir hitapla sınanıyor.
        'köpeğin tekisin sen',
        'sen tam bir dalyarağın tekisin',
      ];
      for (final text in softenedInflections) {
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

    test('morfolojik ek ayıklama ile kök çakışmaları (amaç, malzeme, boksör, itfaiye) elenir', () {
      const morphologicallyInnocent = [
        'Bu projedeki temel amacımız nedir?',
        'Yeni ambalaj tasarımı çok başarılı oldu.',
        'Amcamlar yarın akşam yemeğe gelecek.',
        'Fabrikadaki bütün malzemeleri depoya taşıdık.',
        'Milli boksör olimpiyatlarda altın madalya kazandı.',
        'İtfaiye ekipleri yangına hızla müdahale etti.',
        'Bu ayki ithalat ve ihracat rakamları açıklandı.',
      ];
      for (final text in morphologicallyInnocent) {
        final result = engine.analyze(text);
        expect(result.risk, RiskLevel.temiz, reason: 'YANLIŞ POZİTİF: $text');
        expect(result.civilityScore, 100, reason: 'SKOR DÜŞMEMELİ: $text');
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

    test('tersten okununca sözlüğe denk gelen gündelik kelimeler temiz kalır', () {
      // 13 Eylül 2026'ya kadar 4+ harfli her token tersten de aranıyordu.
      // "atma" → "amta" = am + ta, küfür, YÜKSEK RİSK: çöpü yere atma diyen
      // kişi gönderimde "suç teşkil edebilir" onayı görüyordu. Gerekçe:
      // `LexicalTurkishClassifier._matchTokens`.
      const everyday = [
        'Sen taş atma',
        'Sen de çöpü yere atma lütfen',
        'sen de adım atma korkusunu yen',
        'Sen bizden uzak dur',
        'sen uzak kalma bizden',
        'Bahçeye kalas taşıdık',
      ];
      for (final text in everyday) {
        final result = engine.analyze(text);
        expect(result.risk, RiskLevel.temiz,
            reason: 'YANLIŞ POZİTİF: "$text" → '
                '${result.findings.map((f) => f.term).toList()}');
      }
    });

    test('kısa kökle başlayan gündelik kelimeler temiz kalır (D1 + D2)', () {
      // "ama" = am + a · "sıkı" = sik + i · "kaza" = kaz + a … Hepsi ikinci
      // şahıs geçen cümlede Riskli ya da Yüksek risk alıyordu (docs/20).
      const everyday = [
        'Sana katılıyorum ama bence yanlış',
        'Haklısın ama zamanlama kötü oldu',
        'Allah razı olsun senden, amin',
        'Sana sıkı sıkı sarılıyorum',
        'Sen sığın buraya, yağmur başladı',
        'Sen boğa burcusun değil mi',
        'Sen boga burcusun degil mi',
        'Kaza mı geçirdin sen?',
        'Sana Kazım abiyi tanıştırayım',
        'Sen o zaman haklı idin',
        'Yeni gelen arkadaşın adı ne?',
        'Sana malları yarın gönderirim',
      ];
      for (final text in everyday) {
        final result = engine.analyze(text);
        expect(result.risk, RiskLevel.temiz,
            reason: 'YANLIŞ POZİTİF: "$text" → '
                '${result.findings.map((f) => f.term).toList()}');
      }
    });

    test('somut adlar ikinci şahıs geçen gündelik cümlede hakaret sayılmaz (D7)',
        () {
      const everyday = [
        'Sana köpeğimin fotoğrafını atayım',
        'Senin için domuz eti yok, merak etme',
        'Sana yeni bir fare aldım, eskisi bozulmuştu',
        'Sana hıyar turşusu getirdim',
        'Senin köpek havlıyor, sesini duyuyor musun?',
        'Sen hiç maymun gördün mü hayvanat bahçesinde?',
        'Sana bir komedi filmi önereyim',
      ];
      for (final text in everyday) {
        final result = engine.analyze(text);
        expect(result.risk, RiskLevel.temiz,
            reason: 'YANLIŞ POZİTİF: "$text" → '
                '${result.findings.map((f) => f.term).toList()}');
      }
      const insults = [
        'sen tam bir eşeksin',
        'seni gidi maymun',
        'köpek herif sen',
        'köpek misin sen',
        'maymun gibi davranıyorsun',
        'sen hıyarın tekisin',
        '@ali tam bir domuz',
      ];
      for (final text in insults) {
        expect(engine.analyze(text).risk, isNot(RiskLevel.temiz),
            reason: 'KAÇTI: $text');
      }
    });

    test('kısa kök düzeltmesi gerçek hakaretleri kaçırmaz', () {
      // D1 yalnızca Türkçeye ÖZGÜ bir harf kökle çelişirse devreye girer;
      // ASCII yazım ve doğru Türkçe yazım yakalanmaya devam eder.
      const insults = [
        'sen tam bir malsın',
        'sen malsin',
        'amına koyayım',
        'sen götsün',
        'göt herif',
        'sen bir itsin',
        'SEN MALSIN',
        'adi herif sen',
      ];
      for (final text in insults) {
        expect(engine.analyze(text).risk, isNot(RiskLevel.temiz),
            reason: 'KAÇTI: $text');
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
      // Önceki hâli ısınmamış TEK bir çağrının süresine bakıyordu ve
      // doğrusallığı hiç ölçmüyordu; yüklü makinede 102 ms ile kırılıyordu.
      //
      // Zaman ölçen bir test, paralel çalışan test dosyalarının gürültüsüne
      // dayanmak zorunda. İlk düzeltme (4× metin, ≤ 8× süre, beşin en küçüğü)
      // bile bir kez 12× ile kırıldı; tek başına ölçümde maliyet doğrusaldı.
      // Bu yüzden:
      //   • boyut farkı 8×: doğrusal 8×, karesel 64× verir — arada geniş pay
      //   • iki boyut İÇ İÇE turlarla ölçülür: yük dalgası ikisine de düşer
      //   • her boyutun en küçük süresi alınır
      const cumle = 'Bu normal bir cümledir. ';
      final kisaMetin = cumle * 25; //   600 kr
      final uzunMetin = cumle * 200; // 4.800 kr
      for (var i = 0; i < 3; i++) {
        engine.analyze(kisaMetin);
        engine.analyze(uzunMetin);
      }
      var kisa = 1 << 62, uzun = 1 << 62;
      for (var tur = 0; tur < 9; tur++) {
        final k = engine.analyze(kisaMetin).elapsed.inMicroseconds;
        final u = engine.analyze(uzunMetin).elapsed.inMicroseconds;
        if (k < kisa) kisa = k;
        if (u < uzun) uzun = u;
      }
      // ignore: avoid_print
      print('600 kr: $kisa µs · 4.800 kr: $uzun µs');

      expect(uzun, lessThan(100000));
      expect(uzun, lessThan(kisa * 24 + 2000),
          reason: 'Metin 8× uzadı, süre ${uzun / kisa}× arttı — karesel '
              'bir maliyet olabilir (doğrusal 8×, karesel 64×).');
    });
  });
}
