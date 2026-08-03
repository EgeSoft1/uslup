import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'presentation/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Durum çubuğu ve gezinme çubuğu içeriğin altına uzanır; her ekran kendi
  // rengini `SystemUiOverlayStyle` ile bildirir.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const NSosyalApp());
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
            title: 'NSosyal — Nezaket Koçu',
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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Eski ad — dış referanslar bozulmasın diye korunuyor.
@Deprecated('NSosyalApp kullanın')
typedef MyApp = NSosyalApp;
