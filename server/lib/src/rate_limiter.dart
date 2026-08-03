// =============================================================================
// Hız Sınırlayıcı
// Dosya: server/lib/src/rate_limiter.dart
//
// Servisin arkasında ücretli bir API anahtarı var. Sınırsız bir uç nokta,
// anahtarı tüketmek isteyen herkese açık bir davetiyedir.
//
// Kayan pencere (sliding window) yaklaşımı: sabit pencereli sayaçların
// pencere sınırında iki kat trafiğe izin veren bilinen açığı yoktur.
// Tek süreç içi, bellekte — tek örnekli dağıtım için yeterli.
// =============================================================================

class RateLimiter {
  final int maxRequests;
  final Duration window;

  /// Anahtar (IP) → o anahtarın penceredeki istek zaman damgaları.
  final Map<String, List<DateTime>> _hits = {};

  /// Test edilebilirlik için saat enjekte edilebilir; testler gerçek
  /// zaman beklemek zorunda kalmaz.
  final DateTime Function() _now;

  RateLimiter({
    required this.maxRequests,
    this.window = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  /// İsteğe izin veriliyorsa `true` döner ve isteği kaydeder.
  bool allow(String key) {
    final now = _now();
    final cutoff = now.subtract(window);

    final timestamps = _hits.putIfAbsent(key, () => <DateTime>[]);
    timestamps.removeWhere((t) => t.isBefore(cutoff));

    if (timestamps.length >= maxRequests) return false;

    timestamps.add(now);
    return true;
  }

  /// Bu anahtarın penceredeki kalan hakkı.
  int remaining(String key) {
    final cutoff = _now().subtract(window);
    final timestamps = _hits[key];
    if (timestamps == null) return maxRequests;
    timestamps.removeWhere((t) => t.isBefore(cutoff));
    return (maxRequests - timestamps.length).clamp(0, maxRequests);
  }

  /// Artık hiçbir kaydı kalmamış anahtarları temizler.
  /// Uzun süre çalışan süreçte bellek sızıntısını önler.
  void sweep() {
    final cutoff = _now().subtract(window);
    _hits.removeWhere((_, timestamps) {
      timestamps.removeWhere((t) => t.isBefore(cutoff));
      return timestamps.isEmpty;
    });
  }
}
