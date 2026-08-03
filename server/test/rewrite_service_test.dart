// =============================================================================
// Yeniden Yazma Servisi Testleri — DOĞRULAMA KAPISININ KANITI
// Dosya: server/test/rewrite_service_test.dart
//
// Bu dosya servisin merkezi iddiasını sınar: bir dil modeli ne üretirse
// üretsin, nezaket motorunun onaylamadığı hiçbir öneri kullanıcıya ulaşmaz.
//
// Sahte model (`FakeRewriteModel`) sayesinde testler ağ, API anahtarı ve
// maliyet olmadan çalışır ve tamamen deterministiktir. Modelin "kötü
// davrandığı" senaryolar gerçek API'de güvenilir biçimde tetiklenemez;
// enjeksiyon bunu mümkün kılar.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:nezaket_server/src/claude_client.dart';
import 'package:nezaket_server/src/rewrite_service.dart';
import 'package:test/test.dart';

/// Önceden belirlenmiş sonucu döndüren sahte model.
class FakeRewriteModel implements RewriteModel {
  final LlmOutcome outcome;

  /// Servisin modeli gerçekten çağırıp çağırmadığını gözlemler.
  int callCount = 0;
  int? lastMaxSuggestions;

  FakeRewriteModel(this.outcome);

  /// Metni olduğu gibi öneri diye geri veren model.
  factory FakeRewriteModel.echo() => FakeRewriteModel(
        const LlmProposed(suggestions: [], servedBy: 'sahte'),
      );

  @override
  String get modelName => 'sahte-model';

  @override
  Future<LlmOutcome> propose(String text, {required int maxSuggestions}) async {
    callCount++;
    lastMaxSuggestions = maxSuggestions;
    return outcome;
  }
}

LlmOutcome proposing(List<String> texts) => LlmProposed(
      suggestions: [
        for (final t in texts)
          LlmSuggestion(text: t, rationale: 'test gerekçesi'),
      ],
      servedBy: 'claude-test',
    );

void main() {
  late LexicalTurkishClassifier engine;

  setUp(() => engine = LexicalTurkishClassifier());

  RewriteService serviceWith(RewriteModel model) =>
      RewriteService(engine: engine, cloud: model);

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Maliyet ve mahremiyet — bulut gereksiz yere çağrılmaz', () {
    test('temiz metinde model HİÇ çağrılmaz', () async {
      final model = FakeRewriteModel(proposing(['olmamalı']));
      final result = await serviceWith(model)
          .rewrite('bu kararı yanlış buluyorum, gerekçesini merak ediyorum');

      expect(model.callCount, 0,
          reason: 'Temiz metin için buluta istek gitmemeli — '
              'hem maliyet hem mahremiyet kararı.');
      expect(result.cloudStatus, CloudStatus.gereksiz);
      expect(result.suggestions, isEmpty);
    });

    test('saldırgan metinde model çağrılır', () async {
      final model = FakeRewriteModel(proposing(['bu kararı yanlış buluyorum']));
      await serviceWith(model).rewrite('sen tam bir aptalsın');

      expect(model.callCount, 1);
    });

    test('istenen öneri sayısı modele iletilir', () async {
      final model = FakeRewriteModel(proposing(['bu kararı yanlış buluyorum']));
      await serviceWith(model)
          .rewrite('sen tam bir aptalsın', maxSuggestions: 2);

      expect(model.lastMaxSuggestions, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. DOĞRULAMA KAPISI — motorun onaylamadığı öneri geçemez', () {
    test('gerçekten daha temiz öneri kabul edilir', () async {
      final model = FakeRewriteModel(
        proposing(['bu kararı yanlış buluyorum ve nedenini anlamıyorum']),
      );
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      final cloud = result.suggestions.where((s) => s.source == 'bulut');
      expect(cloud, hasLength(1));
      expect(cloud.first.civilityScore, 100);
      expect(result.cloudStatus, CloudStatus.basarili);
      expect(result.rejectedByVerification, 0);
    });

    test('HAKARETİ BAŞKA HAKARETLE değiştiren öneri REDDEDİLİR', () async {
      // Bu, doğrulama katmanının varlık sebebidir. Model akıcı ama işe
      // yaramaz bir çıktı üretti: "aptal" (0.55) yerine "şerefsiz" (0.88).
      // İstem bunu yasaklıyor, ama istem bir garanti değildir — motor
      // garantidir.
      final model = FakeRewriteModel(proposing(['sen tam bir şerefsizsin']));
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      expect(result.suggestions.any((s) => s.source == 'bulut'), isFalse,
          reason: 'Daha toksik bir öneri kullanıcıya ulaşmamalı.');
      expect(result.rejectedByVerification, 1);
      expect(result.cloudStatus, CloudStatus.dogrulamadaElendi);
    });

    test('orijinali aynen döndüren öneri reddedilir', () async {
      final model = FakeRewriteModel(proposing(['sen tam bir aptalsın']));
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      expect(result.suggestions.any((s) => s.source == 'bulut'), isFalse);
      expect(result.rejectedByVerification, 1);
    });

    test('boş öneri reddedilir', () async {
      final model = FakeRewriteModel(proposing(['   ']));
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      expect(result.suggestions.any((s) => s.source == 'bulut'), isFalse);
      expect(result.rejectedByVerification, 1);
    });

    test('aşırı şişirilmiş öneri reddedilir', () async {
      // Model "yardımcı olmaya çalışırken" cümleyi romana çevirdi.
      // Kullanıcı kendi cümlesinin katbekat uzunundaki bir metni göndermez.
      final bloated = 'Bu konudaki düşüncelerimi sizinle paylaşmak istiyorum '
          've bu kararın arka planını daha iyi anlayabilmek adına biraz daha '
          'ayrıntılı bir açıklama yapılmasının faydalı olacağını düşünüyorum.';
      final model = FakeRewriteModel(proposing([bloated]));
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      expect(result.suggestions.any((s) => s.source == 'bulut'), isFalse);
      expect(result.rejectedByVerification, 1);
    });

    test('karışık partide yalnızca geçerli öneriler kabul edilir', () async {
      final model = FakeRewriteModel(proposing([
        'sen tam bir şerefsizsin', // reddedilmeli — daha toksik
        'bu kararı yanlış buluyorum', // kabul
        '', // reddedilmeli — boş
      ]));
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      final cloud =
          result.suggestions.where((s) => s.source == 'bulut').toList();
      expect(cloud, hasLength(1));
      expect(cloud.first.text, 'bu kararı yanlış buluyorum');
      expect(result.rejectedByVerification, 2);
      expect(result.cloudStatus, CloudStatus.basarili);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Bozulmaya dayanıklılık — bulut çökse de ürün çalışır', () {
    test('model reddederse yerel öneri yine sunulur', () async {
      final model = FakeRewriteModel(const LlmRefused('cyber'));
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      expect(result.cloudStatus, CloudStatus.reddedildi);
      expect(result.suggestions.any((s) => s.source == 'cihaz'), isTrue,
          reason: 'Çevrimdışı kademe ürünün tabanıdır; hiçbir bulut '
              'sonucu onu ortadan kaldıramaz.');
      expect(result.cloudDetail, contains('güvenlik'));
    });

    test('model ulaşılamazsa yerel öneri yine sunulur', () async {
      final model = FakeRewriteModel(
        const LlmUnavailable('Ağ hatası', retryable: true),
      );
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      expect(result.cloudStatus, CloudStatus.kullanilamadi);
      expect(result.suggestions.any((s) => s.source == 'cihaz'), isTrue);
      expect(result.cloudDetail, 'Ağ hatası');
    });

    test('model boş liste dönerse servis çökmez', () async {
      final model = FakeRewriteModel.echo();
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      expect(result.cloudStatus, CloudStatus.dogrulamadaElendi);
      expect(result.suggestions.any((s) => s.source == 'cihaz'), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Sıralama ve raporlama', () {
    test('öneriler nezaket puanına göre azalan sırada döner', () async {
      final model = FakeRewriteModel(proposing([
        'bu kararı yanlış buluyorum', // temiz → 100
      ]));
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');

      final scores = result.suggestions.map((s) => s.civilityScore).toList();
      expect(scores, equals(List.of(scores)..sort((a, b) => b.compareTo(a))),
          reason: 'Kullanıcı listeyi baştan okur; en iyi öneri başta olmalı.');
    });

    test('JSON çıktısı sözleşmeye uyar', () async {
      final model = FakeRewriteModel(proposing(['bu kararı yanlış buluyorum']));
      final result =
          await serviceWith(model).rewrite('sen tam bir aptalsın');
      final json = result.toJson();

      expect(json['analysis'], isA<Map<String, Object?>>());
      expect(json['suggestions'], isA<List<Object?>>());
      expect(json['cloud'], isA<Map<String, Object?>>());
      expect(json['elapsedMs'], isA<int>());

      final analysis = json['analysis']! as Map<String, Object?>;
      expect(analysis['civilityScore'], isA<int>());
      expect(analysis['risk'], isA<String>());
      expect(analysis['findings'], isA<List<Object?>>());

      final cloud = json['cloud']! as Map<String, Object?>;
      expect(cloud['servedBy'], 'claude-test');
      expect(cloud['status'], 'basarili');
    });

    test('bağlam duyarlılığı sunucuda da korunur', () async {
      // Mağdur cezalandırılmaz: alıntı bağlamı cihazdakiyle aynı şekilde
      // çalışır, çünkü aynı motordur.
      final model = FakeRewriteModel(proposing(['olmamalı']));
      final result =
          await serviceWith(model).rewrite("bana 'aptal' dedi, çok üzüldüm");

      expect(result.cloudStatus, CloudStatus.gereksiz,
          reason: 'Alıntılanmış hakaret saldırı değildir.');
      expect(model.callCount, 0);
    });
  });
}
