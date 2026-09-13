// =============================================================================
// Melez sınıflandırıcı — web yedeği
// Dosya: mobile/lib/core/civility/onnx_classifier_stub.dart
//
// Tarayıcıda `onnxruntime` eklentisi ve `dart:io` yoktur. Bu sürüm ONNX
// katmanını hiç kurmaz ve her çağrıyı deterministik motora geçirir.
//
// ── NEDEN TAKLİT ETMİYOR ──────────────────────────────────────────────────
// Sahte bir olasılık üretip "model çalışıyor" demek, masaüstü kabuğunda
// gösterilen sayıyı yalana çevirirdi. `modelName` melez katmanın bu
// platformda BULUNMADIĞINI açıkça yazar; ekranda ne yazıyorsa o doğrudur.
//
// Ürünün çekirdek vaadi bu yedekle de bozulmaz: çözümlemenin tamamı yine
// istemcide, `civility_core` içinde yapılır.
// =============================================================================

import 'package:civility_core/civility_core.dart';

class HybridOnnxClassifier implements ToxicityClassifier {
  HybridOnnxClassifier(this._baseClassifier);

  final ToxicityClassifier _baseClassifier;

  ToxicityClassifier get base => _baseClassifier;

  bool get isLoaded => false;

  /// Web'de kurulacak bir oturum yok; imza uyumluluğu için durur.
  Future<void> init() async {}

  void release() {}

  @override
  String get modelName => _baseClassifier.modelName;

  @override
  CivilityAnalysis analyze(
    String text, {
    double? typingSpeedMs,
    double? backspaceRatio,
  }) {
    return _baseClassifier.analyze(
      text,
      typingSpeedMs: typingSpeedMs,
      backspaceRatio: backspaceRatio,
    );
  }
}
