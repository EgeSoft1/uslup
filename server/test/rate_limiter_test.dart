// =============================================================================
// Hız Sınırlayıcı Testleri
// Dosya: server/test/rate_limiter_test.dart
//
// Saat enjekte edildiği için testler gerçek zaman beklemez; bir dakikalık
// pencere mikrosaniyede sınanır.
// =============================================================================

import 'package:nezaket_server/src/rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime(2026, 8, 1, 12, 0, 0));

  RateLimiter limiter(int max) =>
      RateLimiter(maxRequests: max, clock: clock);

  test('sınıra kadar izin verir, sonra reddeder', () {
    final rl = limiter(3);
    expect(rl.allow('1.2.3.4'), isTrue);
    expect(rl.allow('1.2.3.4'), isTrue);
    expect(rl.allow('1.2.3.4'), isTrue);
    expect(rl.allow('1.2.3.4'), isFalse);
  });

  test('anahtarlar birbirinden bağımsızdır', () {
    final rl = limiter(1);
    expect(rl.allow('1.2.3.4'), isTrue);
    expect(rl.allow('1.2.3.4'), isFalse);
    expect(rl.allow('5.6.7.8'), isTrue,
        reason: 'Bir kullanıcının sınırı diğerini etkilememeli.');
  });

  test('pencere kayınca hak yenilenir', () {
    final rl = limiter(2);
    expect(rl.allow('ip'), isTrue);
    expect(rl.allow('ip'), isTrue);
    expect(rl.allow('ip'), isFalse);

    now = now.add(const Duration(seconds: 61));
    expect(rl.allow('ip'), isTrue);
  });

  test('kayan pencere — sabit pencere açığı yoktur', () {
    // Sabit pencereli sayaçta pencere sınırında 2× trafiğe izin verilir.
    // Kayan pencerede her istek kendi zaman damgasıyla yaşlanır.
    final rl = limiter(2);

    expect(rl.allow('ip'), isTrue); // t=0
    now = now.add(const Duration(seconds: 30));
    expect(rl.allow('ip'), isTrue); // t=30
    expect(rl.allow('ip'), isFalse); // ikisi de pencerede

    now = now.add(const Duration(seconds: 31)); // t=61, ilki düştü
    expect(rl.allow('ip'), isTrue);
    expect(rl.allow('ip'), isFalse,
        reason: 't=30 ve t=61 hâlâ pencerede.');
  });

  test('kalan hak doğru raporlanır', () {
    final rl = limiter(3);
    expect(rl.remaining('ip'), 3);
    rl.allow('ip');
    expect(rl.remaining('ip'), 2);
    rl.allow('ip');
    rl.allow('ip');
    expect(rl.remaining('ip'), 0);
  });

  test('sweep boşalan anahtarları temizler — bellek sızıntısı olmaz', () {
    final rl = limiter(1);
    rl.allow('gecici');
    now = now.add(const Duration(seconds: 61));

    rl.sweep();
    expect(rl.remaining('gecici'), 1,
        reason: 'Kayıt silinmeli; anahtar sıfırdan başlamalı.');
  });
}
