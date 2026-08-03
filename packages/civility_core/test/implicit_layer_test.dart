// =============================================================================
// Örtük Saldırı Katmanı ve Motor Düzeltmeleri — Test Paketi
// Dosya: packages/civility_core/test/implicit_layer_test.dart
//
// İki bölüm:
//
//   1. ÖRTÜK KATMAN — her edimbilimsel aile yakalanıyor mu, ve daha
//      önemlisi: kelime düzeyinde benzeyen MASUM cümle yakalanMIYOR mu?
//      Her aile için bir "yakalanır" ve bir "yakalanmaz" çifti vardır.
//      Tek başına pozitif testler bir kesinlik iddiasını kanıtlamaz.
//
//   2. REGRESYON — değerlendirme kümesinin ortaya çıkardığı beş motor
//      hatası. Her biri ölçümle bulundu; her biri burada kilitlendi.
//      Testin adı hatayı anlatır, çözümü değil.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  late LexicalTurkishClassifier engine;

  setUp(() => engine = LexicalTurkishClassifier());

  /// Motor bu metne müdahale eder mi?
  bool flags(String text) => engine.analyze(text).risk != RiskLevel.temiz;

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Örtük katman — yakalar / yakalamaz çiftleri', () {
    test('küçümseme yakalanır, alçakgönüllülük yakalanmaz', () {
      expect(flags('sen ne anlarsın bu işlerden'), isTrue);
      expect(flags('ne anlarım ben bu işlerden'), isFalse,
          reason: 'Birinci şahıs alçakgönüllülük saldırı değildir.');
    });

    test('ötekileştirme yakalanır, benzetme yakalanmaz', () {
      expect(flags('senin gibilerden zaten bu beklenirdi'), isTrue);
      expect(flags('senin gibi düşünenler haklı bence'), isFalse,
          reason: '"senin gibi" tek başına ötekileştirme değildir; '
              'ayrım "gibiler" bitişik biçimindedir.');
    });

    test('yok sayma yakalanır, aynı kelimelerle kurulmuş soru yakalanmaz', () {
      expect(flags('sana ne'), isTrue);
      expect(flags('sana ne getireyim marketten'), isFalse,
          reason: '"sana ne" yalnızca tümce sonunda muhataplık reddidir.');
    });

    test('örtük tehdit yakalanır, vedalaşma yakalanmaz', () {
      expect(flags('görüşürüz seninle'), isTrue);
      expect(flags('görüşürüz, iyi akşamlar'), isFalse,
          reason: 'Ayrım ikinci şahıs vasıta hâlinin varlığıdır.');
    });

    test('alaycı övgü yakalanır, içten övgü yakalanmaz', () {
      expect(flags('çok başarılısın gerçekten, bravo'), isTrue);
      expect(flags('gerçekten çok başarılısın, tebrikler'), isFalse,
          reason: 'En zor ayrım: alay parçacığı olmadan övgü cezalandırılmaz.');
    });

    test('susturma yakalanır, deyim içindeki aynı kelime yakalanmaz', () {
      expect(flags('sus artık'), isTrue);
      expect(flags('sus payı vermişler'), isFalse,
          reason: 'Susturma emri tümce sonunda yüklem olarak kurulur.');
    });

    test('karakter saldırısı yakalanır, nesneye yönelik eleştiri yakalanmaz',
        () {
      expect(flags('hiçbir işe yaramazsın'), isTrue);
      expect(flags('bu çözüm işe yaramaz çünkü bellek sızıntısı var'), isFalse,
          reason: 'Fikre yönelik sert eleştiri korunmalıdır.');
    });

    test('genelleme saldırısı yakalanır, birleştirici dil yakalanmaz', () {
      expect(flags('hepiniz aynısınız'), isTrue);
      expect(flags('hepimiz aynı takımdayız'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Örtük katman — meta davranış', () {
    test('katman kapatılabilir — ölçüm için şart', () {
      final withoutPatterns =
          LexicalTurkishClassifier(enableImplicitPatterns: false);

      expect(withoutPatterns.analyze('senin gibilerden bu beklenirdi').risk,
          RiskLevel.temiz,
          reason: 'Katman kapalıyken örüntü bulgusu üretilmemeli.');
      expect(engine.analyze('senin gibilerden bu beklenirdi').risk,
          isNot(RiskLevel.temiz));
    });

    test('örüntü bulgusu kaynağını ve ailesini bildirir', () {
      final analysis = engine.analyze('gününü göreceksin');
      final finding = analysis.findings.single;

      expect(finding.source, FindingSource.oruntu);
      expect(finding.implicitFamily, ImplicitFamily.ortukTehdit);
      expect(finding.sourceLabel, 'Örtük tehdit');
      expect(finding.explanation, contains('tehdit'));
    });

    test('örtük tehdit "riskli", açık tehdit "yüksek" bandındadır', () {
      // Kasıtlı asimetri. Örtük sinyal daha belirsizdir ve en sert
      // müdahaleyi (gönderim öncesi zorunlu onay) tetiklememelidir:
      // "görüşürüz seninle" bazı bağlamlarda gerçekten vedalaşmadır.
      // Açık tehdit ise belirsiz değildir.
      expect(engine.analyze('gününü göreceksin').risk, RiskLevel.riskli,
          reason: 'Örtük tehdit öneri bandında kalır.');
      expect(engine.analyze('seni geberteceğim').risk, RiskLevel.yuksek,
          reason: 'Açık tehdit en sert müdahaleyi tetikler.');

      // Yine de "dikkat" ile geçiştirilmez — ikisi de öneri üstü banttadır.
      expect(engine.analyze('gununu goreceksin').toxicity, greaterThan(0.40));
    });

    test('AKTARILAN kalıp cezalandırılmaz', () {
      // Kalıp kullanılmıyor, aktarılıyor. Örüntü bulguları da bağlam
      // katmanından geçtiği için bu ayrım korunur.
      expect(flags('işine bak diyorlar ama ben yardım etmek istiyorum'),
          isFalse);
    });

    test('örüntü bulgusu yeniden yazımda kendi karşılığını kullanır',
        () async {
      final analysis = engine.analyze('senin gibilerden bu beklenirdi');
      final suggestion = await LocalRewriteSuggester(engine).suggest(analysis);

      expect(suggestion, isNotNull);
      expect(suggestion!.text, isNot(contains('gibiler')));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Regresyon — ölçümün bulduğu motor hataları', () {
    test('yönelim, KOMŞU kelimenin ekinden de okunur', () {
      // "alçak" yönelim şartlıdır. Yönelim yalnızca eşleşen kelimenin kendi
      // ekinden okunsaydı, bu cümlede hiç yönelim görülmez ve bulgu tamamen
      // elenirdi.
      expect(flags('alçak herifsin'), isTrue);
      expect(flags('öküz gibisin'), isTrue);
      expect(flags('hayvan gibi konuşuyorsun'), isTrue);

      // Yönelim yoksa aynı kelimeler masumdur.
      expect(flags('alçak basınç sistemi geliyor'), isFalse);
      expect(flags('öküz arabası müzede sergileniyor'), isFalse);
    });

    test('öz-yönelim, FİİL çekiminden de okunur', () {
      // Özne düşer, kişi bilgisi fiil ekinde taşınır. Zamir aranmakla
      // yetinilseydi bu iki cümle yanlış pozitif olurdu.
      expect(flags('aptalca bir hata yaptım kusura bakma'), isFalse);
      expect(flags('çok salakça davrandım orada'), isFalse);
    });

    test('yumuşatma tavanı yüksek şiddetli terimlerde de geçerlidir', () {
      // Çarpan tek başına yetmiyordu: 0.88 × 0.20 = 0.176 eşiği aşıyordu ve
      // tacize UĞRAYAN kişi uyarı alıyordu.
      expect(flags("'şerefsiz' diye bağırdı bana"), isFalse);
      expect(flags('sana salak diyen haksız'), isFalse,
          reason: 'Mağduru savunan cümle de cezalandırılmamalı.');
    });

    test('retorik olumsuzlama bir kaçış yolu değildir', () {
      expect(flags('sen hiç aptal değilsin'), isFalse,
          reason: 'Gerçek olumsuzlama iltifattır.');
      expect(flags('sen aptal değil misin zaten'), isTrue,
          reason: 'Soru edatı olumsuzlamayı iddiaya çevirir.');
    });

    test('tam eşleşmeli terim, bildirme ekiyle çekimlenebilir', () {
      expect(flags('sen tam bir malsın'), isTrue);
      expect(flags('malzeme listesini hazırladım'), isFalse);
      expect(flags('mal beyanında bulundu'), isFalse);
    });

    test('tehdit birinci şahıs çekimlidir ama öz-ifade değildir', () {
      // "öldürürüm" -üm ekiyle biter; öz-yönelim sayılsaydı elenirdi.
      expect(flags('öldürürüm valla'), isTrue);
      expect(flags('mahvederim hayatını'), isTrue);
    });

    test('kalıbın kendi içindeki olumsuzlayıcı kalıbı iptal etmez', () {
      // "senin harcın DEĞİL bu iş" — olumsuzlayıcı kalıbın parçasıdır.
      expect(flags('senin harcın değil bu iş'), isTrue);
      expect(flags('bu konu sana göre değil'), isTrue);
    });

    test('"hiçbir" bir olumsuzlayıcı değil, pekiştiricidir', () {
      expect(flags('hiçbir işe yaramazsın'), isTrue);
    });

    test('yeterlilik olumsuzu ("-amam") olumsuzlama sayılmaz', () {
      expect(flags('senin gibi tiplerle uğraşamam'), isTrue);
      expect(flags('seviyene inip tartışamam'), isTrue);
    });

    test('fiil olumsuzluğu ("-mıyorum") olumsuzlama sayılır', () {
      expect(flags('seni aptal sanmıyorum'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Performans — katman eklendi, bütçe korunuyor', () {
    test('örüntü katmanıyla birlikte tek çözümleme 16 ms altında kalır', () {
      const sample = 'senin gibilerden zaten bu beklenirdi, '
          'sen ne anlarsın bu işlerden, gününü göreceksin';

      // Isınma — ilk çağrıda düzenli ifadeler derlenir.
      engine.analyze(sample);

      final stopwatch = Stopwatch()..start();
      const iterations = 200;
      for (var i = 0; i < iterations; i++) {
        engine.analyze(sample);
      }
      stopwatch.stop();

      final average = stopwatch.elapsedMicroseconds / iterations;
      print('Ortalama çözümleme (örüntü katmanı dahil): '
          '${average.toStringAsFixed(1)} µs');

      expect(average, lessThan(16000),
          reason: '60 FPS bütçesi: her tuş vuruşunda çalışır.');
    });
  });
}
