// =============================================================================
// TurkiyeMesajlasma - Dart FFI (Rust Kripto Entegrasyonu) - MOCK YAPI
// Dosya: mobile/lib/domain/crypto/ffi_bridge.dart
//
// Amaç: Web'de test edilebilmesi için FFI kullanmayan Mock Kripto motoru.
// =============================================================================

import 'dart:typed_data';

/// Kripto Motoru Sınıfı (Singleton) - MOCK
class CryptoEngine {
  static final CryptoEngine _instance = CryptoEngine._internal();
  factory CryptoEngine() => _instance;

  CryptoEngine._internal();

  /// Mesajı E2EE şifreler (Mock)
  ({Uint8List ciphertext, Uint8List nonce}) encryptE2EEMessage(String sessionId, String plaintext) {
    // Mock şifreleme - sadece metnin byte'larını döndürür
    final ciphertext = Uint8List.fromList(plaintext.codeUnits);
    final nonce = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    return (ciphertext: ciphertext, nonce: nonce);
  }
}
