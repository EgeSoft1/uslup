// =============================================================================
// Bulut kademesi istemcisi testleri
// Dosya: mobile/test/rewrite_api_client_test.dart
//
// Ağ mocklanmıyor. Test edilen şey, istemcinin RİSKLİ kısmı:
//   1. Sunucu yanıtının çözümlenmesi (şema değişirse istemci çökmemeli)
//   2. Onay kapısı (onay yoksa metin cihazdan ÇIKMAMALI)
//
// Bu ikisi saf mantıktır ve ağ olmadan deterministik biçimde sınanabilir.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/network/rewrite_api_client.dart';

/// `server/lib/src/rewrite_service.dart` → `RewriteResult.toJson()` çıktısının
/// birebir şekli. Sunucu sözleşmesi değişirse bu testler kırılır — istenen de
/// budur.
Map<String, Object?> _serverResponse({
  String status = 'basarili',
  List<Map<String, Object?>>? suggestions,
  String? detail,
  String? servedBy,
  int rejected = 0,
}) {
  return {
    'analysis': {
      'civilityScore': 13,
      'toxicity': 0.87,
      'risk': 'yuksek',
      'intervention': 'Gönderim öncesi onay',
      'containsThreat': false,
      'findings': const [],
    },
    'suggestions': suggestions ??
        [
          {
            'text': 'Bu karar bence yanlış ve nedenini anlamıyorum.',
            'source': 'bulut',
            'rationale': 'Hakaret çıkarıldı, eleştiri korundu.',
            'civilityScore': 96,
          },
        ],
    'cloud': {
      'status': status,
      'detail': detail,
      'servedBy': servedBy,
      'rejectedByVerification': rejected,
    },
    'elapsedMs': 812,
  };
}

void main() {
  group('1. Yanıt çözümleme — sunucu sözleşmesi', () {
    test('başarılı yanıt öneriye çevrilir', () {
      final result = CloudRewriteResult.fromJson(
        _serverResponse(servedBy: 'claude-opus-5', rejected: 2),
      );

      expect(result.status, CloudStatus.basarili);
      expect(result.suggestions, hasLength(1));
      expect(result.suggestions.first.civilityScore, 96);
      expect(result.suggestions.first.isFromCloud, isTrue);
      expect(result.servedBy, 'claude-opus-5');
      expect(result.rejectedByVerification, 2);
    });

    test('cihaz kaynaklı öneri cloudOnly dışında kalır', () {
      final result = CloudRewriteResult.fromJson(_serverResponse(suggestions: [
        {
          'text': 'Yerel öneri',
          'source': 'cihaz',
          'rationale': '',
          'civilityScore': 70,
        },
        {
          'text': 'Bulut önerisi',
          'source': 'bulut',
          'rationale': '',
          'civilityScore': 90,
        },
      ]));

      // Yerel öneri arayüzde zaten cihaz üzerinde üretiliyor; ikinci kez
      // gösterilmesi kullanıcıyı yanıltır.
      expect(result.suggestions, hasLength(2));
      expect(result.cloudOnly, hasLength(1));
      expect(result.cloudOnly.single.text, 'Bulut önerisi');
    });

    test('her bulut durumu doğru eşlenir', () {
      for (final status in CloudStatus.values) {
        final result =
            CloudRewriteResult.fromJson(_serverResponse(status: status.name));
        expect(result.status, status, reason: 'durum: ${status.name}');
      }
    });
  });

  group('2. Savunmacılık — bozuk/yeni yanıtta çökmemeli', () {
    test('tanınmayan durum kullanilamadi sayılır', () {
      final result =
          CloudRewriteResult.fromJson(_serverResponse(status: 'yeni_durum'));
      expect(result.status, CloudStatus.kullanilamadi);
    });

    test('cloud bloğu eksikse çökmez', () {
      final result = CloudRewriteResult.fromJson({'suggestions': const []});
      expect(result.status, CloudStatus.kullanilamadi);
      expect(result.suggestions, isEmpty);
    });

    test('bozuk öneri öğeleri atılır, sağlamlar kalır', () {
      final result = CloudRewriteResult.fromJson(_serverResponse(suggestions: [
        {'text': '', 'source': 'bulut'}, // boş metin
        {'source': 'bulut'}, // metin yok
        {
          'text': 'Geçerli öneri',
          'source': 'bulut',
          'rationale': '',
          'civilityScore': 88,
        },
      ]));

      expect(result.suggestions, hasLength(1));
      expect(result.suggestions.single.text, 'Geçerli öneri');
    });

    test('tamamen boş gövde çökmez', () {
      final result = CloudRewriteResult.fromJson(const {});
      expect(result.status, CloudStatus.kullanilamadi);
      expect(result.cloudOnly, isEmpty);
    });

    test('puan aralık dışındaysa kırpılır', () {
      final result = CloudRewriteResult.fromJson(_serverResponse(suggestions: [
        {
          'text': 'Öneri',
          'source': 'bulut',
          'rationale': '',
          'civilityScore': 999,
        },
      ]));
      expect(result.suggestions.single.civilityScore, 100);
    });
  });

  group('3. ONAY KAPISI — metin onaysız cihazdan çıkmamalı', () {
    test('onay yoksa istek hiç yapılmaz', () async {
      // Ulaşılamaz bir adres veriyoruz: eğer istemci yine de istek yapsaydı
      // sonuç "Sunucuya ulaşılamadı" olurdu. "Onay verilmedi" mesajı,
      // isteğin HİÇ yapılmadığının kanıtıdır.
      final client = RewriteApiClient(
        baseUrl: 'http://127.0.0.1:1',
        timeout: const Duration(milliseconds: 200),
      );
      addTearDown(client.close);

      final result = await client.rewrite(
        text: 'sen tam bir aptalsın',
        consent: false,
      );

      expect(result.status, CloudStatus.kullanilamadi);
      expect(result.detail, contains('Onay verilmedi'));
      expect(result.suggestions, isEmpty);
    });

    test('boş metin gönderilmez', () async {
      final client = RewriteApiClient(
        baseUrl: 'http://127.0.0.1:1',
        timeout: const Duration(milliseconds: 200),
      );
      addTearDown(client.close);

      final result = await client.rewrite(text: '   ', consent: true);
      expect(result.detail, contains('Gönderilecek metin yok'));
    });

    test('sunucu kapalıyken sakin bir sonuç döner, istisna fırlatmaz',
        () async {
      final client = RewriteApiClient(
        baseUrl: 'http://127.0.0.1:1',
        timeout: const Duration(milliseconds: 300),
      );
      addTearDown(client.close);

      final result = await client.rewrite(
        text: 'sen tam bir aptalsın',
        consent: true,
      );

      // Ürün kararı: bulut kademesi bir eklentidir. Kapalı olması
      // kullanıcıya hata olarak değil, durum olarak yansır.
      expect(result.status, CloudStatus.kullanilamadi);
      expect(result.status.retryable, isTrue);
      expect(result.detail, contains('Cihaz üzerindeki öneri'));
    });
  });
}
