// =============================================================================
// ONNX ikinci görüş katmanı — cihaz sürümü (Android · iOS · masaüstü)
// Dosya: mobile/lib/core/civility/onnx_classifier_io.dart
//
// ── SÖZLEŞME: MODEL KARAR VERMEZ, YALNIZCA ŞİDDETİ TEYİT EDER ─────────────
// Deterministik kural motoru "bu metin işaretlenmeli mi?" sorusunun TEK
// sahibidir. ONNX modeli (ml/ altında eğitilen denetimli taban çizgisi)
// yalnızca ZATEN işaretlenmiş bir metnin basamağını yükseltebilir:
//
//   kural motoru temiz      → model hiç çalışmaz, sonuç temiz
//   kural motoru işaretledi → model aynı fikirdeyse şiddet artabilir,
//                             ama ASLA düşmez ve temize dönmez
//
// Sebebi ölçümdür. Aynı ayrık kümede model, kural motorunun kaçırdığı
// hiçbir örneği yakalamadı ve motorun yapmadığı altı yanlış pozitif üretti
// (hepsi iltifat, olumsuzlama ya da mağduru savunan cümle — ml/README.md).
// Modele temiz/işaretli kararı üzerinde söz hakkı vermek, raporlanan
// kesinliği uygulamada geçersiz kılardı. Bu sözleşmeyle ölçülen kesinlik ve
// duyarlılık, uygulamada da birebir geçerlidir.
//
// ── KALDIRILANLAR (13 Eylül 2026) ─────────────────────────────────────────
// Önceki sürümde üç sorun vardı:
//   1. `analyze` her TUŞ VURUŞUNDA çağrılıyor ama bir "kullanıcı sicili"
//      bunu MESAJ sayıyordu; 20 temiz tuştan sonra eşik gevşiyordu.
//   2. Yüksek skorlu metinlerin kendisi bellekte bir listede "karantina"
//      adıyla biriktiriliyordu — ürünün hiçbir metni saklamama ilkesine
//      aykırı; "şifreli kasa" diye anılan yapı düz bir listeydi.
//   3. "haha", ":)" gibi ifadeler skoru düşürüyordu: "amk haha" yazmak
//      şiddeti azaltmanın yolu hâline geliyordu.
// Üçü de kaldırıldı. Eşik sabittir ve hiçbir metin saklanmaz.
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

  /// Modelin "saldırgan" dediği olasılık eşiği. Sabittir.
  static const double _modelThreshold = 0.5;

  ToxicityClassifier get base => _baseClassifier;

  bool get isLoaded => _isLoaded;

  /// ONNX oturumunu kurar. Uygulama açılışında bir kez çağrılır.
  ///
  /// Hiçbir hata yukarı fırlatılmaz: model yüklenemediğinde ürün çalışmaya
  /// devam etmeli, yalnızca ikinci görüş katmanı devre dışı kalmalıdır.
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
      ? '${_baseClassifier.modelName} + ONNX ikinci görüş'
      : _baseClassifier.modelName;

  @override
  CivilityAnalysis analyze(String text) {
    final baseResult = _baseClassifier.analyze(text);

    // Temiz/işaretli kararı kural motorunundur. Temiz bir metinde model
    // hiç çalışmaz — hem sözleşme hem de maliyet gereği.
    if (!_isLoaded || _session == null || baseResult.risk == RiskLevel.temiz) {
      return baseResult;
    }

    try {
      final modelRisk = _modelProbability(text);
      if (modelRisk == null || modelRisk <= _modelThreshold) return baseResult;

      // Model aynı fikirde: iki bağımsız yöntemin ortalaması, kural motorunun
      // skorundan YÜKSEKSE kullanılır. Düşükse kural motorunun skoru kalır.
      final blended = (baseResult.toxicity + modelRisk) / 2;
      if (blended <= baseResult.toxicity) return baseResult;

      return CivilityAnalysis(
        text: baseResult.text,
        toxicity: blended,
        civilityScore: ((1.0 - blended) * 100).round().clamp(0, 100),
        risk: _riskFrom(blended),
        findings: baseResult.findings,
        signals: baseResult.signals,
        elapsed: baseResult.elapsed,
        needsSupport: baseResult.needsSupport,
      );
    } catch (e) {
      debugPrint('ONNX çıkarım hatası: $e');
      return baseResult;
    }
  }

  double? _modelProbability(String text) {
    final runOptions = OrtRunOptions();
    final inputTensor = OrtValueTensor.createTensorWithDataList([text], [1, 1]);
    try {
      final outputs = _session!.run(runOptions, {'input_text': inputTensor});
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
    } finally {
      inputTensor.release();
      runOptions.release();
    }
  }

  /// Kural motoruyla AYNI eşikler (`LexicalTurkishClassifier._riskFrom`).
  /// Farklı eşik kullanmak, aynı skorun iki ekranda iki farklı basamak
  /// göstermesine yol açardı.
  RiskLevel _riskFrom(double toxicity) {
    if (toxicity < 0.15) return RiskLevel.temiz;
    if (toxicity < 0.40) return RiskLevel.dikkat;
    if (toxicity < 0.70) return RiskLevel.riskli;
    return RiskLevel.yuksek;
  }
}
