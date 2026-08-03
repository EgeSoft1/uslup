// =============================================================================
// Anthropic İstemcisi Testleri
// Dosya: server/test/claude_client_test.dart
//
// `MockClient` ile gerçek ağ olmadan HTTP katmanı sınanır. İki grup:
//
//   1. İSTEK ŞEKLİ — gönderdiğimiz gövde API sözleşmesine uyuyor mu?
//      Bu grup sessiz regresyonları yakalar: `thinking` yanlışlıkla açık
//      bırakılırsa gecikme sessizce artar, hiçbir test kırılmaz — bu test
//      hariç.
//
//   2. YANIT YORUMU — özellikle `stop_reason: "refusal"`. Reddedilen istek
//      HTTP 200 döner ve `content` boştur; `content[0]` doğrudan okunursa
//      kod patlar. Bu servise tanımı gereği saldırgan metin geldiği için
//      reddedilme uç bir durum değil, beklenen bir durumdur.
// =============================================================================

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nezaket_server/src/claude_client.dart';
import 'package:test/test.dart';

http.Response ok(Map<String, Object?> body) =>
    http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});

/// Modelin şemaya uygun tipik başarılı yanıtı.
Map<String, Object?> successBody(List<Map<String, String>> suggestions) => {
      'id': 'msg_test',
      'model': 'claude-opus-5',
      'stop_reason': 'end_turn',
      'content': [
        {
          'type': 'text',
          'text': jsonEncode({'suggestions': suggestions}),
        }
      ],
    };

ClaudeRewriteModel modelWith(
  Future<http.Response> Function(http.Request) handler,
) =>
    ClaudeRewriteModel(
      apiKey: 'sk-ant-test',
      model: 'claude-opus-5',
      httpClient: MockClient(handler),
    );

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  group('1. İstek şekli — API sözleşmesi', () {
    late Map<String, Object?> captured;
    late Map<String, String> capturedHeaders;

    Future<LlmOutcome> send() {
      final model = modelWith((request) async {
        captured =
            jsonDecode(utf8.decode(request.bodyBytes)) as Map<String, Object?>;
        capturedHeaders = request.headers;
        return ok(successBody([
          {'text': 'daha nazik', 'rationale': 'gerekçe'}
        ]));
      });
      return model.propose('sen aptalsın', maxSuggestions: 3);
    }

    test('zorunlu başlıklar gönderilir', () async {
      await send();
      expect(capturedHeaders['x-api-key'], 'sk-ant-test');
      expect(capturedHeaders['anthropic-version'], '2023-06-01');
      expect(capturedHeaders['content-type'], contains('application/json'));
    });

    test('geri düşme açık — reddedilen istek başka modele yönlendirilsin',
        () async {
      await send();
      expect(captured['fallbacks'], 'default');
      expect(capturedHeaders['anthropic-beta'],
          contains('server-side-fallback'));
    });

    test('düşünme kapalı ve efor düşük — gecikme ürünün kendisidir', () async {
      await send();
      expect((captured['thinking']! as Map<String, Object?>)['type'],
          'disabled');
      final outputConfig = captured['output_config']! as Map<String, Object?>;
      expect(outputConfig['effort'], 'low');
    });

    test('yapılandırılmış çıktı şeması gönderilir', () async {
      await send();
      final outputConfig = captured['output_config']! as Map<String, Object?>;
      final format = outputConfig['format']! as Map<String, Object?>;
      expect(format['type'], 'json_schema');

      final schema = format['schema']! as Map<String, Object?>;
      expect(schema['additionalProperties'], false,
          reason: 'Yapılandırılmış çıktı bunu zorunlu kılar.');
      expect(schema['required'], contains('suggestions'));
    });

    test('sistem istemi önbelleğe alınır — tekrar eden maliyet düşer',
        () async {
      await send();
      final system = captured['system']! as List<Object?>;
      final block = system.first! as Map<String, Object?>;
      expect(block['cache_control'], {'type': 'ephemeral'});
      expect((block['text']! as String).length, greaterThan(500),
          reason: 'Önbellekleme için asgari uzunluk gerekir; kısa istem '
              'sessizce önbelleğe alınmaz.');
    });

    test('kullanıcı metni gövdeye eklenir', () async {
      await send();
      final messages = captured['messages']! as List<Object?>;
      final first = messages.first! as Map<String, Object?>;
      expect(first['role'], 'user');
      expect(first['content'], contains('sen aptalsın'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Yanıt yorumu', () {
    test('geçerli yanıt önerilere çevrilir', () async {
      final model = modelWith((_) async => ok(successBody([
            {'text': 'birinci', 'rationale': 'a'},
            {'text': 'ikinci', 'rationale': 'b'},
          ])));
      final outcome = await model.propose('x', maxSuggestions: 2);

      expect(outcome, isA<LlmProposed>());
      final proposed = outcome as LlmProposed;
      expect(proposed.suggestions.map((s) => s.text), ['birinci', 'ikinci']);
      expect(proposed.servedBy, 'claude-opus-5');
    });

    test('REDDEDİLME hata değil, sonuçtur — ve kod patlamaz', () async {
      // HTTP 200, boş content. `content[0]` okunsaydı burada çökerdi.
      final model = modelWith((_) async => ok({
            'id': 'msg_test',
            'model': 'claude-opus-5',
            'stop_reason': 'refusal',
            'stop_details': {'type': 'refusal', 'category': 'cyber'},
            'content': <Object?>[],
          }));
      final outcome = await model.propose('x', maxSuggestions: 3);

      expect(outcome, isA<LlmRefused>());
      expect((outcome as LlmRefused).category, 'cyber');
    });

    test('geri düşme devreye girdiyse gerçek model raporlanır', () async {
      final model = modelWith((_) async => ok({
            'id': 'msg_test',
            'model': 'claude-opus-4-8', // istenen değil, geri düşülen
            'stop_reason': 'end_turn',
            'content': [
              {
                'type': 'text',
                'text': jsonEncode({
                  'suggestions': [
                    {'text': 'öneri', 'rationale': 'r'}
                  ]
                }),
              }
            ],
          }));
      final outcome = await model.propose('x', maxSuggestions: 1);

      expect((outcome as LlmProposed).servedBy, 'claude-opus-4-8');
    });

    test('kesilen yanıt yeniden denenebilir olarak işaretlenmez', () async {
      final model = modelWith((_) async => ok({
            'stop_reason': 'max_tokens',
            'content': <Object?>[],
          }));
      final outcome = await model.propose('x', maxSuggestions: 3);

      expect(outcome, isA<LlmUnavailable>());
      expect((outcome as LlmUnavailable).retryable, isFalse,
          reason: 'Aynı istek yine kesilir; tekrar denemek anlamsız.');
    });

    test('şemaya uymayan metin bloğu düzgün ele alınır', () async {
      final model = modelWith((_) async => ok({
            'stop_reason': 'end_turn',
            'content': [
              {'type': 'text', 'text': 'bu JSON değil'}
            ],
          }));
      final outcome = await model.propose('x', maxSuggestions: 3);

      expect(outcome, isA<LlmUnavailable>());
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Hata eşlemesi — hangi hata tekrar denenebilir?', () {
    Future<LlmUnavailable> failWith(int status, [String body = '{}']) async {
      final model = modelWith((_) async => http.Response(body, status));
      final outcome = await model.propose('x', maxSuggestions: 3);
      expect(outcome, isA<LlmUnavailable>());
      return outcome as LlmUnavailable;
    }

    test('401 — anahtar sorunu, tekrar denemek işe yaramaz', () async {
      final outcome = await failWith(401);
      expect(outcome.retryable, isFalse);
      expect(outcome.reason, contains('anahtar'));
    });

    test('404 — model kimliği yanlış, tekrar denemek işe yaramaz', () async {
      final outcome = await failWith(404);
      expect(outcome.retryable, isFalse);
      expect(outcome.reason, contains('claude-opus-5'));
    });

    test('429 — hız sınırı, tekrar denenebilir', () async {
      final outcome = await failWith(429);
      expect(outcome.retryable, isTrue);
    });

    test('529 — aşırı yük, tekrar denenebilir', () async {
      final outcome = await failWith(529);
      expect(outcome.retryable, isTrue);
    });

    test('400 — istek hatalı, tekrar denemek işe yaramaz', () async {
      final outcome = await failWith(
        400,
        jsonEncode({
          'error': {'type': 'invalid_request_error', 'message': 'kötü istek'}
        }),
      );
      expect(outcome.retryable, isFalse);
      expect(outcome.reason, contains('invalid_request_error'));
    });

    test('ağ hatası yeniden denenebilir olarak sınıflanır', () async {
      final model = modelWith((_) async => throw const SocketExceptionStub());
      final outcome = await model.propose('x', maxSuggestions: 3);

      expect(outcome, isA<LlmUnavailable>());
      expect((outcome as LlmUnavailable).retryable, isTrue);
    });
  });
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
