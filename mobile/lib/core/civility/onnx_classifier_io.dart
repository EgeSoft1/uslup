// =============================================================================
// Melez sınıflandırıcı — cihaz sürümü (Android · iOS · Windows · macOS · Linux)
// Dosya: mobile/lib/core/civility/onnx_classifier_io.dart
//
// Deterministik kural motoru KESİNLİK vetosu koyar, ONNX modeli DUYARLILIK
// katkısı sağlar. Kesişim mantığı kasıtlıdır: model tek başına işaretleme
// yapamaz. Kural motoru bir bulgu üretmediyse ONNX skoru ne olursa olsun
// sonuç temizdir.
//
// Bunun sebebi ürünün hedef fonksiyonunun F0.5 olması: yanlış pozitif,
// yanlış negatiften pahalıdır. Modele veto hakkı verilseydi "Ben Kürtüm"
// gibi cümlelerin işaretlenmesi bir eşik ayarı meselesine dönerdi — oysa
// şu anda YAPISAL olarak imkânsız.
//
// Model yüklenemezse (dosya yok, bellek yetmedi, mimari desteklenmiyor)
// sınıf sessizce temel motora düşer ve `modelName` bunu söyler.
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'user_profile_manager.dart';

class HybridOnnxClassifier implements ToxicityClassifier {
  HybridOnnxClassifier(this._baseClassifier);

  final ToxicityClassifier _baseClassifier;

  OrtSession? _session;
  bool _isLoaded = false;

  /// Temel (deterministik) motor — melez katman kapalıyken de erişilebilir
  /// olmalı: yeniden yazıcı örüntü tablolarını bu motordan okur.
  ToxicityClassifier get base => _baseClassifier;

  bool get isLoaded => _isLoaded;

  /// ONNX oturumunu kurar. Uygulama açılışında bir kez çağrılır.
  ///
  /// Hiçbir hata yukarı fırlatılmaz: model yüklenemediğinde ürün çalışmaya
  /// devam etmeli, yalnızca melez katman devre dışı kalmalıdır.
  Future<void> init() async {
    try {
      OrtEnv.instance.init();

      final bytes = await _loadModelBytes();
      if (bytes == null) {
        _isLoaded = false;
        return;
      }

      _session = OrtSession.fromBuffer(bytes, OrtSessionOptions());
      _isLoaded = true;
    } catch (e) {
      debugPrint('ONNX yükleme hatası: $e');
      _isLoaded = false;
    }
  }

  /// Model baytları: önce cihazdaki OTA kopyası, sonra pakete gömülü kopya.
  ///
  /// OTA yolu yalnızca Android'de anlamlıdır (dosyayı oraya native katman
  /// indirir). Diğer platformlarda dosya hiç bulunmaz ve doğrudan pakete
  /// gömülü modele düşülür — bu bir hata değil, beklenen yoldur.
  Future<Uint8List?> _loadModelBytes() async {
    try {
      if (Platform.isAndroid) {
        final ota = File(
          '/data/user/0/com.example.turkiye_mesajlasma/files/uslup_model_ota.onnx',
        );
        if (ota.existsSync() && ota.lengthSync() > 0) {
          debugPrint('ONNX: cihazdaki güncel model (OTA) yüklendi');
          return await ota.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('ONNX: OTA modeli okunamadı, pakete gömülü sürüme dönülüyor');
    }

    try {
      final asset = await rootBundle.load('assets/models/uslup_model.onnx');
      debugPrint('ONNX: pakete gömülü model yüklendi');
      return asset.buffer.asUint8List();
    } catch (e) {
      debugPrint('ONNX: model varlığı okunamadı — melez katman kapalı: $e');
      return null;
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
      ? '${_baseClassifier.modelName} + ONNX melez (cihaz üstü)'
      : '${_baseClassifier.modelName} · ONNX katmanı kapalı';

  /// Cümledeki duygu yükü — modelin skorunu ölçekleyen küçük bir düzeltme.
  ///
  /// Tek başına hiçbir şey işaretlemez; yalnızca modelin zaten ürettiği
  /// skoru eşiğe göre biraz yukarı ya da aşağı iter.
  double _sentimentModifier(String text) {
    final lower = trKucultYerel(text);
    const ofke = ['nefret', 'iğrenç', 'igrenc', 'yeter artık', 'bıktım'];
    const saka = ['şaka', 'saka', 'haha', ':)', '🤣', '😅'];

    if (ofke.any(lower.contains)) return 0.15;
    if (saka.any(lower.contains)) return -0.20;
    return 0.0;
  }

  @override
  CivilityAnalysis analyze(
    String text, {
    double? typingSpeedMs,
    double? backspaceRatio,
  }) {
    // 1 · Deterministik motor her zaman çalışır ve kesinlik vetosunu koyar.
    final baseResult = _baseClassifier.analyze(
      text,
      typingSpeedMs: typingSpeedMs,
      backspaceRatio: backspaceRatio,
    );

    if (!_isLoaded || _session == null || text.trim().isEmpty) {
      return baseResult;
    }

    // Kural motoru hiçbir bulgu üretmediyse melez katman devreye GİRMEZ.
    // Bu erken çıkış hem kesinlik vetosunu yapısal kılar hem de temiz
    // metinlerde ONNX çıkarımının maliyetini tamamen ortadan kaldırır —
    // kullanıcı yazdığı sürelerin çoğunda metin zaten temizdir.
    if (baseResult.findings.isEmpty) {
      UserProfileManager.instance.recordCleanMessage();
      return baseResult;
    }

    try {
      final runOptions = OrtRunOptions();
      final inputTensor =
          OrtValueTensor.createTensorWithDataList([text], [1, 1]);

      final outputs = _session!.run(runOptions, {'input_text': inputTensor});
      final probs = outputs.length > 1
          ? outputs[1]?.value as List<List<double>>?
          : null;

      inputTensor.release();
      runOptions.release();
      for (final element in outputs) {
        element?.release();
      }

      var mlRisk = 0.0;
      if (probs != null && probs.isNotEmpty && probs.first.length > 1) {
        mlRisk = probs.first[1];
      }
      mlRisk = (mlRisk + _sentimentModifier(text)).clamp(0.0, 1.0);

      if (mlRisk <= UserProfileManager.instance.dynamicThreshold) {
        return baseResult;
      }

      UserProfileManager.instance.recordToxicMessage(text, mlRisk);

      final blended = ((baseResult.toxicity * 0.5) + (mlRisk * 0.5))
          .clamp(0.0, 1.0);

      return CivilityAnalysis(
        text: baseResult.text,
        toxicity: blended,
        civilityScore: ((1.0 - blended) * 100).round().clamp(0, 100),
        risk: _riskFrom(blended),
        findings: baseResult.findings,
        signals: baseResult.signals,
        elapsed: baseResult.elapsed,
      );
    } catch (e) {
      debugPrint('ONNX çıkarım hatası: $e');
      return baseResult; // Kademeli bozulma: ürün çalışmaya devam eder.
    }
  }

  RiskLevel _riskFrom(double toxicity) {
    if (toxicity < 0.30) return RiskLevel.temiz;
    if (toxicity < 0.50) return RiskLevel.dikkat;
    if (toxicity < 0.70) return RiskLevel.riskli;
    return RiskLevel.yuksek;
  }
}

/// Türkçe'ye duyarlı küçük harfe çevirme.
///
/// Dart'ın `toLowerCase()` işlevi "I" harfini "i" yapar; Türkçe'de karşılığı
/// "ı"dır. Duygu sözcüklerini ararken bu fark eşleşmeyi kaçırır.
String trKucultYerel(String value) {
  const map = {'I': 'ı', 'İ': 'i', 'Ş': 'ş', 'Ğ': 'ğ', 'Ü': 'ü', 'Ö': 'ö', 'Ç': 'ç'};
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final ch = value[i];
    buffer.write(map[ch] ?? ch.toLowerCase());
  }
  return buffer.toString();
}
