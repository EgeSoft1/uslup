// =============================================================================
// ONNX ikinci görüş katmanı — cihaz sürümü (Android · iOS · masaüstü)
// Dosya: mobile/lib/core/civility/onnx_classifier_io.dart
//
// ── SÖZLEŞME: MODEL KARAR VERMEZ, BASAMAĞA DA DOKUNMAZ ────────────────────
// Deterministik kural motoru "bu metin işaretlenmeli mi?" ve "hangi basamak?"
// sorularının TEK sahibidir. ONNX modeli yalnızca bir İKİNCİ GÖRÜŞ üretir:
// şeffaflık panelinde ayrı bir satırda, kullanıcıya bilgi olarak gösterilir.
//
// ── NEDEN (docs/24 · madde 22–23, 14 Eylül 2026) ──────────────────────────
// Önceki sözleşmede model, işaretlenmiş metnin skorunu (motor + model)/2 ile
// YÜKSELTEBİLİYORDU. Paketlenen model hiç ölçülmemişti; `ml/04_paket_modeli_olc.py`
// onu 971 etiketli cümlede ölçtü:
//
//   • Tek başına: gündelik 120 masum cümlenin 86'sını, İP-31'deki 30 masum
//     cümlenin 27'sini saldırgan buluyor.
//   • Melez kuralda: 53 cümlenin risk BASAMAĞINI değiştiriyor — 39'u
//     Riskli → Yüksek risk ("sen tam bir aptalsın"), yani gönderimde onay
//     diyaloğu açıyor.
//   • Web kabuğunda ONNX yok: aynı cümle telefonda Yüksek risk, jüri
//     sunumundaki masaüstünde Riskli oluyordu. "Aynı motor, aynı karar"
//     iddiası platformlar arasında bozuluyordu ve bu fark hiçbir ölçümde yoktu.
//
// Ayrıca model her işaretlenmiş tuş vuruşunda ANA İŞ PARÇACIĞINDA FFI
// çağrısıyla çalışıyordu. İkinci görüş artık `runAsync` ile ayrı bir
// isolate'te, yalnızca istendiğinde üretilir.
//
// ── KALDIRILANLAR (13 Eylül 2026) ─────────────────────────────────────────
// Kullanıcı sicili, metin "karantinası" ve "haha" ile şiddet düşürme —
// üçü de kaldırılmıştı; hiçbir metin saklanmaz.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

class HybridOnnxClassifier implements ToxicityClassifier {
  HybridOnnxClassifier(this._baseClassifier);

  final ToxicityClassifier _baseClassifier;

  OrtSession? _session;
  bool _isLoaded = false;

  ToxicityClassifier get base => _baseClassifier;

  bool get isLoaded => _isLoaded;

  /// ONNX oturumunu kurar. Uygulama açılışında bir kez çağrılır.
  ///
  /// Hiçbir hata yukarı fırlatılmaz: model yüklenemediğinde ürün çalışmaya
  /// devam etmeli, yalnızca ikinci görüş kapanmalıdır.
  Future<void> init() async {
    try {
      OrtEnv.instance.init();
      final asset = await rootBundle.load('assets/models/uslup_model.onnx');
      _session = OrtSession.fromBuffer(
        asset.buffer.asUint8List(),
        OrtSessionOptions(),
      );
      _isLoaded = true;
    } catch (e) {
      debugPrint('ONNX ikinci görüş katmanı yüklenemedi: $e');
      _isLoaded = false;
    }
  }

  void release() {
    _session?.release();
    _session = null;
    _isLoaded = false;
    OrtEnv.instance.release();
  }

  @override
  String get modelName => _isLoaded
      ? '${_baseClassifier.modelName} + ONNX ikinci görüş (bilgi amaçlı)'
      : _baseClassifier.modelName;

  /// Kararın tamamı kural motorunundur. Model sonucu değiştirmez.
  @override
  CivilityAnalysis analyze(String text) => _baseClassifier.analyze(text);

  /// Modelin metni saldırgan bulma olasılığı [0,1]; model yoksa `null`.
  ///
  /// Ayrı bir isolate'te çalışır; arayüz iş parçacığını bekletmez. Sonuç
  /// yalnızca şeffaflık panelinde gösterilir.
  Future<double?> secondOpinion(String text) async {
    final session = _session;
    if (!_isLoaded || session == null) return null;

    final runOptions = OrtRunOptions();
    final inputTensor = OrtValueTensor.createTensorWithDataList([text], [1, 1]);
    try {
      final outputs =
          await session.runAsync(runOptions, {'input_text': inputTensor});
      if (outputs == null) return null;
      try {
        final probs = outputs.length > 1
            ? outputs[1]?.value as List<List<double>>?
            : null;
        if (probs == null || probs.isEmpty || probs.first.length < 2) {
          return null;
        }
        return probs.first[1];
      } finally {
        for (final element in outputs) {
          element?.release();
        }
      }
    } catch (e) {
      debugPrint('ONNX ikinci görüş hatası: $e');
      return null;
    } finally {
      inputTensor.release();
      runOptions.release();
    }
  }
}
