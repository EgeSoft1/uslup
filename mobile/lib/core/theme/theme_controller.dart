// =============================================================================
// Tema Denetleyicisi
// Dosya: mobile/lib/core/theme/theme_controller.dart
//
// Açık / koyu / sistem seçimini tutar ve dinleyenleri uyarır.
//
// Neden BLoC değil: tek bir enum değeri için olay/durum sınıfları yazmak
// gereksiz tören. `ValueNotifier` + `ListenableBuilder` Flutter'ın kendi
// aracı ve toplam maliyeti bu dosya kadar.
// =============================================================================

import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.initial = ThemeMode.system]);

  /// Uygulama boyunca tek örnek. `main.dart` bunu `AppThemeScope` ile ağaca
  /// verir; ekranlar `AppThemeScope.of(context)` ile ulaşır.
  static final ThemeController instance = ThemeController();

  bool isDarkIn(BuildContext context) => switch (value) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      };

  void set(ThemeMode mode) => value = mode;

  /// Açık ↔ koyu arasında geçiş. "Sistem" seçiliyken, o an görünenin
  /// tersine sabitlenir — kullanıcının beklediği davranış budur.
  void toggle(BuildContext context) {
    value = isDarkIn(context) ? ThemeMode.light : ThemeMode.dark;
  }

  String get label => switch (value) {
        ThemeMode.light => 'Açık',
        ThemeMode.dark => 'Koyu',
        ThemeMode.system => 'Sistem',
      };
}

/// Tema denetleyicisini widget ağacına taşır.
class AppThemeScope extends InheritedNotifier<ThemeController> {
  const AppThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope widget ağacında bulunamadı.');
    return scope!.notifier!;
  }
}
