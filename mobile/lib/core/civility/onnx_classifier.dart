// =============================================================================
// Melez sınıflandırıcı — platform seçici
// Dosya: mobile/lib/core/civility/onnx_classifier.dart
//
// ── NEDEN KOŞULLU DIŞA AKTARIM ────────────────────────────────────────────
// `onnxruntime` paketi yalnızca Android, iOS, macOS, Windows ve Linux için
// derlenir; web hedefi yoktur (yerel kitaplığa `dart:ffi` ile bağlanır).
// Model uygulamanın kendi varlıklarından yüklenir; ağdan model indirilmez
// (13 Eylül 2026'da klavye servisindeki HTTP'den model indirme yolu
// kaldırıldı).
//
// Bu kısıt, tek bir dosyada yazıldığında ürünü tarayıcıda DERLENMEZ
// hâle getiriyordu. Jüri demosunun masaüstü kabuğu tarayıcıda çalışacağı
// için bu, gösterilemeyen bir ürün demekti.
//
// Çözüm, Dart'ın koşullu dışa aktarımı: `dart:io` varsa gerçek melez
// sınıflandırıcı, yoksa (web) yalnızca deterministik motoru yansıtan
// yedek. İki dosya da AYNI arayüzü sunar; çağıran taraf hangisinde
// olduğunu bilmez.
//
// Yedek sürüm ONNX'i taklit ETMEZ — modeli olmadığını `modelName` üzerinden
// açıkça söyler. Çalışmayan bir şeyi çalışıyormuş gibi göstermek, çalışan
// katmanın güvenilirliğini düşürür.
// =============================================================================

export 'onnx_classifier_stub.dart'
    if (dart.library.io) 'onnx_classifier_io.dart';
