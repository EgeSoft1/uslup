// =============================================================================
// Giriş noktası
// Dosya: mobile/lib/main.dart
//
// Üç iş yapar: motoru kurar, Android klavye servisinden (IME) gelen metin
// çözümleme isteklerini karşılar ve uyarlanır kabuğu çalıştırır.
//
// ── NEDEN `init()` BEKLENİYOR AMA ZORUNLU DEĞİL ───────────────────────────
// `Civility.init()` melez ONNX katmanını yükler. Yüklenemezse ürün yine
// çalışır: `Civility.engine` ilk erişimde deterministik çekirdeği kendisi
// kurar (`civility_runtime.dart`). Bu yüzden burada bir hata ürünü
// açılmaz hâle getirmez — yalnızca melez katmanı kapatır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/civility/civility_runtime.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'presentation/home/adaptive_shell.dart';

/// Dokunmatik olmayan platformlarda (masaüstü tarayıcı, Windows) yön
/// kilidi ve kenardan kenara sistem çubuğu ayarı anlamsızdır.
bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Civility.init();

  if (_isMobilePlatform) {
    _bindKeyboardService();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Durum çubuğu ve gezinme çubuğu içeriğin altına uzanır; her ekran kendi
    // rengini `SystemUiOverlayStyle` ile bildirir.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  runApp(const NSosyalApp());
}

/// Klavye (IME) servisinden gelen metinleri yakalayıp çözümler.
///
/// Katmanın uygulama sınırının DIŞINDA da çalıştığı yer burasıdır: kullanıcı
/// başka bir uygulamada yazarken bile aynı motor, aynı cihazda çalışır.
///
/// ── 13 EYLÜL 2026 DÜZELTMELERİ ────────────────────────────────────────────
/// • Şerit `toxicity > 0.5` eşiğine bakıyordu; uygulamadaki kutu ise öneriyi
///   `riskli` basamağında (≥ 0,40) açıyor. 0,40–0,50 arasındaki metinler
///   klavyede hiç uyarı almıyordu. Artık basamak adı gönderilir, iki yüzey
///   aynı kuralı izler.
/// • Öneri üretilemediğinde kullanıcının KENDİ metni "Öneri: …" diye
///   gösteriliyor, dokununca metin kendisiyle değiştiriliyordu. Artık
///   gerekçe gösterilir ve dokunulacak bir öneri yoktur.
/// • Klavye yazma hızı ve silme oranı gönderiyordu; motor bunları skora
///   ceza olarak ekliyordu. Kaldırıldı (gerekçe: `civility_engine.dart`).
void _bindKeyboardService() {
  const methodChannel = MethodChannel('uslup/ime');

  methodChannel.setMethodCallHandler((call) async {
    if (call.method != 'analyze') return null;

    final args = call.arguments as Map?;
    final text = args?['text'] as String?;
    if (text == null || text.isEmpty) return null;

    final analysis = Civility.engine.analyze(text);

    if (analysis.risk.index < RiskLevel.riskli.index ||
        analysis.findings.isEmpty) {
      await methodChannel.invokeMethod('updateSuggestion', {'risk': 'temiz'});
      return null;
    }

    final suggestion = await Civility.suggester.suggest(analysis);

    await methodChannel.invokeMethod('updateSuggestion', {
      'risk': analysis.risk.name,
      'message': suggestion != null
          ? 'Öneri: ${suggestion.text}'
          : analysis.findings.first.explanation,
      'cleanText': suggestion?.text,
    });
    return null;
  });
}

class NSosyalApp extends StatelessWidget {
  const NSosyalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return AppThemeScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Üslup — Sosyal Yapay Zekâ Katmanı',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.value,
            // Sistem yazı tipi ölçeği 1.3'ün üstüne çıkınca sabit yükseklikli
            // kartlar taşıyordu; erişilebilirliği koruyup taşmayı önleyen üst sınır.
            builder: (context, child) {
              final scale = MediaQuery.textScalerOf(context)
                  .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scale),
                child: child!,
              );
            },
            home: const AdaptiveShell(),
          );
        },
      ),
    );
  }
}
