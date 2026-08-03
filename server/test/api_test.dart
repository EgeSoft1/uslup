// =============================================================================
// HTTP Katmanı Testleri — uçtan uca
// Dosya: server/test/api_test.dart
//
// Gerçek bir `HttpServer` geçici portta ayağa kaldırılır ve gerçek HTTP
// istekleri atılır. Yalnızca dil modeli sahtedir.
//
// En kritik test: ONAY KAPISI. Ürünün mahremiyet vaadi bir belgede değil,
// sunucunun kabul kuralında yaşamalı.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:civility_core/civility_core.dart';
import 'package:http/http.dart' as http;
import 'package:nezaket_server/src/api.dart';
import 'package:nezaket_server/src/config.dart';
import 'package:nezaket_server/src/rate_limiter.dart';
import 'package:nezaket_server/src/rewrite_service.dart';
import 'package:test/test.dart';

import 'rewrite_service_test.dart' show FakeRewriteModel, proposing;

void main() {
  late HttpServer server;
  late NezaketApi api;
  late String base;

  Future<void> boot({int rpm = 20}) async {
    api = NezaketApi(
      // Port 0 → işletim sistemi boş bir port verir; testler paralel çalışır.
      config: ServerConfig(apiKey: 'sk-ant-test', port: 0, requestsPerMinute: rpm),
      service: RewriteService(
        engine: LexicalTurkishClassifier(),
        cloud: FakeRewriteModel(proposing(['bu kararı yanlış buluyorum'])),
      ),
      limiter: RateLimiter(maxRequests: rpm),
    );
    server = await api.start();
    base = 'http://127.0.0.1:${server.port}';
  }

  setUp(() => boot());

  tearDown(() async {
    await api.dispose();
    await server.close(force: true);
  });

  Future<http.Response> postRewrite(Object? body) => http.post(
        Uri.parse('$base/v1/rewrite'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      );

  Map<String, Object?> decode(http.Response r) =>
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, Object?>;

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Sağlık ve yönlendirme', () {
    test('GET /health servis bilgisini döner', () async {
      final response = await http.get(Uri.parse('$base/health'));
      expect(response.statusCode, 200);

      final body = decode(response);
      expect(body['status'], 'ok');
      expect(body['engine'], 'civility_core');
    });

    test('bilinmeyen yol 404 ve uç nokta listesi döner', () async {
      final response = await http.get(Uri.parse('$base/yok'));
      expect(response.statusCode, 404);
      expect(decode(response)['endpoints'], isA<List<Object?>>());
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. ONAY KAPISI — mahremiyet vaadi sözleşmede', () {
    test('onaysız istek 403 ile reddedilir', () async {
      final response = await postRewrite({'text': 'sen tam bir aptalsın'});

      expect(response.statusCode, 403,
          reason: 'Metin, kullanıcı açıkça onay vermeden buluta gidemez.');
      expect(decode(response)['error'], 'consent_required');
    });

    test('consent: false de reddedilir', () async {
      final response = await postRewrite(
        {'text': 'sen tam bir aptalsın', 'consent': false},
      );
      expect(response.statusCode, 403);
    });

    test('onay verilen istek işlenir', () async {
      final response = await postRewrite(
        {'text': 'sen tam bir aptalsın', 'consent': true},
      );

      expect(response.statusCode, 200);
      final body = decode(response);
      expect(body['analysis'], isA<Map<String, Object?>>());
      expect((body['suggestions']! as List<Object?>), isNotEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Girdi doğrulaması', () {
    test('bozuk JSON 400 döner', () async {
      final response = await http.post(
        Uri.parse('$base/v1/rewrite'),
        headers: {'content-type': 'application/json'},
        body: '{bozuk',
      );
      expect(response.statusCode, 400);
      expect(decode(response)['error'], 'invalid_json');
    });

    test('boş metin 400 döner', () async {
      final response = await postRewrite({'text': '   ', 'consent': true});
      expect(response.statusCode, 400);
      expect(decode(response)['error'], 'invalid_text');
    });

    test('metin türü yanlışsa 400 döner', () async {
      final response = await postRewrite({'text': 42, 'consent': true});
      expect(response.statusCode, 400);
      expect(decode(response)['error'], 'invalid_text');
    });

    test('çok uzun metin 400 döner', () async {
      final response = await postRewrite({
        'text': 'a' * 1001,
        'consent': true,
      });
      expect(response.statusCode, 400);
      expect(decode(response)['error'], 'text_too_long');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Hız sınırı — API anahtarını koruma', () {
    test('sınır aşılınca 429 ve retry-after döner', () async {
      // Varsayılan sunucuyu kapatıp dar sınırlı bir tane aç. `boot`
      // değişkenleri yeniden atadığı için dıştaki tearDown yenisini kapatır.
      await api.dispose();
      await server.close(force: true);
      await boot(rpm: 2);

      final body = {'text': 'sen tam bir aptalsın', 'consent': true};

      expect((await postRewrite(body)).statusCode, 200);
      expect((await postRewrite(body)).statusCode, 200);

      final blocked = await postRewrite(body);
      expect(blocked.statusCode, 429);
      expect(blocked.headers['retry-after'], '60');
      expect(decode(blocked)['error'], 'rate_limited');
    });
  });
}
