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

import 'dart:convert';

import 'package:civility_core/civility_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/civility/civility_runtime.dart';
import 'core/civility/uslup_ayar_denetleyici.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'presentation/home/adaptive_shell.dart';
import 'presentation/intro/intro_tour.dart';

/// Dokunmatik olmayan platformlarda (masaüstü tarayıcı, Windows) yön
/// kilidi ve kenardan kenara sistem çubuğu ayarı anlamsızdır.
bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Klavye kanalı ONNX kurulumundan ÖNCE bağlanır. Önceden `init()`
  // beklendikten sonra bağlanıyordu; klavye servisinin motoru başlattığı
  // ilk saniyelerde gelen tuş vuruşları MissingPluginException ile
  // sessizce düşüyordu. `Civility.engine` tembel kurulduğu için beklemeye
  // gerek yok (denetim · docs/23).
  if (_isMobilePlatform) _bindKeyboardService();

  // Kullanıcının katman ayarı (docs/27). Kanal yoksa varsayılanda kalır.
  await UslupAyarDenetleyici.instance.yukle();

  await Civility.init();

  if (_isMobilePlatform) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Durum çubuğu ve gezinme çubuğu içeriğin altına uzanır; her ekran kendi
    // rengini `SystemUiOverlayStyle` ile bildirir.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // Tanıtım turu yalnızca gerçek açılışta gösterilir; testler ve ekran
  // görüntüsü aracı `NSosyalApp()` ile turu atlar (docs/24 · madde 31).
  runApp(const NSosyalApp(showIntro: true));

  // İlk kare çizildikten sonra motoru ısıt: açılış beklemez, kullanıcının
  // ilk tuş vuruşu da kare kaybetmez (docs/24 · madde 38).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 300), Civility.warmUp);
  });
}

/// Klavye servisinin kendi Dart giriş noktası (docs/24 · madde 27).
///
/// Klavye servisi önceden varsayılan `main()`'i çalıştırıyordu: görünmez bir
/// motorda bütün uygulama arayüzü (akış, panel, yazı tipleri) kuruluyor,
/// yön kilidi ve sistem çubuğu ayarı bir SERVİS bağlamında çağrılıyordu.
/// Klavyenin ihtiyacı yalnızca motor ve kanaldır; bellek ve açılış süresi
/// buna göre düşer. Kotlin tarafı bu işlevi adıyla çağırır.
@pragma('vm:entry-point')
Future<void> imeMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  _bindKeyboardService();
  await Civility.init();
  // Klavyede arayüz yok; ısıtma hemen yapılır, ilk tuş vuruşu beklemez.
  await Civility.warmUp();
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

    // Uygulamada seçilen ayar klavye servisinden her istekte gelir (ayrı
    // Flutter motoru, ortak yerel dosya). Bozuksa varsayılan (docs/27).
    UslupAyarlari ayar = UslupAyarlari.varsayilan;
    final hamAyar = args?['ayarlar'];
    if (hamAyar is String && hamAyar.isNotEmpty) {
      try {
        ayar = UslupAyarlari.fromMap(jsonDecode(hamAyar));
      } catch (_) {}
    }

    final analysis =
        MudahalePolitikasi.uygula(Civility.engine.analyze(text), ayar);

    // Kendine zarar ifadesi: uyarı değil destek (docs/20, D4). Şeritte
    // değiştirilecek bir öneri yoktur.
    // `sourceText`: sonucun HANGİ metin için üretildiği. Çözümleme
    // eşzamansızdır; kullanıcı yazmaya devam ederken eski bir sonucun şeride
    // düşmesi ve dokununca alanın TAMAMININ eski metnin önerisiyle
    // değiştirilmesi, yeni yazılan kelimelerin kaybolması demekti. Klavye,
    // alandaki metin bununla aynı değilse sonucu yok sayar (denetim · docs/23).
    if (analysis.needsSupport && !analysis.hasFindings) {
      await methodChannel.invokeMethod('updateSuggestion', {
        'risk': 'destek',
        'message': 'Zor bir an geçiriyor olabilirsin. Güvende değilsen 112.',
        'sourceText': text,
      });
      return null;
    }

    if (analysis.risk.index < RiskLevel.riskli.index ||
        analysis.findings.isEmpty) {
      await methodChannel.invokeMethod(
          'updateSuggestion', {'risk': 'temiz', 'sourceText': text});
      return null;
    }

    final suggestion = await Civility.suggester.suggest(analysis);

    await methodChannel.invokeMethod('updateSuggestion', {
      'risk': analysis.risk.name,
      'message': suggestion != null
          ? 'Öneri: ${suggestion.text}'
          : analysis.findings.first.explanation,
      'cleanText': suggestion?.text,
      'sourceText': text,
    });
    return null;
  });
}

class NSosyalApp extends StatelessWidget {
  const NSosyalApp({super.key, this.showIntro = false});

  /// Açılışta üç adımlı tanıtım turu gösterilsin mi?
  final bool showIntro;

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
            home: showIntro
                ? const IntroGate(child: AdaptiveShell())
                : const AdaptiveShell(),
          );
        },
      ),
    );
  }
}
