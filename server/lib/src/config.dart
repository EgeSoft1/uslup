// =============================================================================
// Servis Yapılandırması
// Dosya: server/lib/src/config.dart
//
// Tüm ayarlar ortam değişkeninden okunur. Kaynak kodda API anahtarı YOKTUR
// ve olamaz — depo jüri tarafından incelenecek bir teslimattır.
// =============================================================================

/// Yapılandırma hatası — servis başlarken erken ve anlaşılır şekilde patlar.
/// Yanlış yapılandırılmış bir servisin sessizce çalışmaya devam etmesi,
/// çalışmamasından daha kötüdür.
class ConfigError implements Exception {
  final String message;
  const ConfigError(this.message);
  @override
  String toString() => 'Yapılandırma hatası: $message';
}

class ServerConfig {
  /// Anthropic API anahtarı. `ANTHROPIC_API_KEY` ortam değişkeni.
  final String apiKey;

  /// Kullanılacak model kimliği.
  final String model;

  /// Dinlenecek port.
  final int port;

  /// Dinlenecek arayüz. Varsayılan yalnızca yerel — yanlışlıkla internete
  /// açılmasın diye. Dağıtımda açıkça `0.0.0.0` verilmelidir.
  final String host;

  /// Bir IP'nin dakikada yapabileceği en fazla istek sayısı.
  final int requestsPerMinute;

  /// Kabul edilen en uzun metin. LLM maliyetini ve kötüye kullanımı sınırlar.
  final int maxTextLength;

  const ServerConfig({
    required this.apiKey,
    this.model = 'claude-opus-5',
    this.port = 8080,
    this.host = '127.0.0.1',
    this.requestsPerMinute = 20,
    this.maxTextLength = 1000,
  });

  /// Ortam değişkenlerinden okur.
  ///
  /// [env] enjekte edilebilir; testler gerçek ortamı kirletmeden çalışır.
  factory ServerConfig.fromEnvironment(Map<String, String> env) {
    final key = env['ANTHROPIC_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw const ConfigError(
        'ANTHROPIC_API_KEY tanımlı değil. Şu şekilde ayarlayın:\n'
        r'  PowerShell : $env:ANTHROPIC_API_KEY = "sk-ant-..."'
        '\n'
        r'  bash       : export ANTHROPIC_API_KEY="sk-ant-..."',
      );
    }

    return ServerConfig(
      apiKey: key,
      model: env['NEZAKET_MODEL']?.trim().isNotEmpty == true
          ? env['NEZAKET_MODEL']!.trim()
          : 'claude-opus-5',
      port: _intOr(env['PORT'], 8080, 'PORT'),
      host: env['NEZAKET_HOST']?.trim().isNotEmpty == true
          ? env['NEZAKET_HOST']!.trim()
          : '127.0.0.1',
      requestsPerMinute: _intOr(env['NEZAKET_RPM'], 20, 'NEZAKET_RPM'),
      maxTextLength:
          _intOr(env['NEZAKET_MAX_TEXT'], 1000, 'NEZAKET_MAX_TEXT'),
    );
  }

  static int _intOr(String? raw, int fallback, String name) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      throw ConfigError('$name pozitif bir tam sayı olmalı, "$raw" verildi.');
    }
    return parsed;
  }
}
