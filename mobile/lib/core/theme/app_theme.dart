// =============================================================================
// NSosyal / Türkiye Mesajlaşma — Tema
// Dosya: mobile/lib/core/theme/app_theme.dart
//
// Renk değerleri burada DEĞİL, `app_palette.dart` içindedir. Bu dosya yalnızca
// o belirteçleri Flutter'ın `ThemeData`'sına bağlar ve ölçü/hareket
// sabitlerini tanımlar.
//
// Açık ve koyu tema aynı `AppPalette` arayüzünü doldurur; ekranlar
// `context.palette` okur ve iki tema arasında ayrım yapmaz.
// =============================================================================

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

// ─── Hareket ─────────────────────────────────────────────────────────────────
abstract final class AppDurations {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration extraSlow = Duration(milliseconds: 700);
  static const Duration pageTransition = Duration(milliseconds: 340);
}

abstract final class AppCurves {
  /// Varsayılan. `easeOutCubic` doğal yavaşlama verir; `easeInOutQuart`
  /// kısa mesafelerde tembel görünüyordu.
  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutBack;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve bounce = Curves.elasticOut;
}

// ─── Ölçü (8 px ızgara) ──────────────────────────────────────────────────────
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Alt navigasyon çubuğunun kapladığı yükseklik. Kaydırılan listeler
  /// bu kadar alt boşluk bırakır ki son öğe çubuğun altında kalmasın.
  static const double bottomNavClearance = 92;
}

// ─── Köşe yarıçapı ───────────────────────────────────────────────────────────
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double full = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));
}

// ─── Tema kurulumu ───────────────────────────────────────────────────────────
abstract final class AppTheme {
  static ThemeData get lightTheme => _build(AppPalette.light);
  static ThemeData get darkTheme => _build(AppPalette.dark);

  // ───────────────────────────────────────────────────────────────────────────
  // KALDIRILAN SABİTLER (9 Eylül 2026)
  //
  // Burada `primaryRed`, `splashGradient`, `surfaceMid` gibi 22 sabit vardı.
  // Hepsi devralınan giriş akışından (splash, SMS doğrulama, profil kurulumu)
  // kalmıştı; o akış 24 Ağustos'ta silindiğinde bunlar öksüz kaldı. Uygulama
  // genelinde tek bir çağrı yeri bulunmadığı doğrulandıktan sonra kaldırıldı.
  //
  // Ekranların renk okumasının tek yolu `context.palette`tir. İkinci bir
  // kaynak, paletin değiştiği gün sessizce eskiyen bir kopya demektir —
  // marka kırmızıdan maviye geçerken tam olarak bu yaşandı.
  // ───────────────────────────────────────────────────────────────────────────

  static ThemeData _build(AppPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    final textTheme = _textTheme(p);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      extensions: <ThemeExtension<dynamic>>[p],
      visualDensity: VisualDensity.standard,

      // Her yerde aynı yumuşak dalga; Material'ın varsayılan mürekkep sıçraması
      // 2026 tasarım diline göre çok agresif.
      splashFactory: InkSparkle.splashFactory,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.brand,
        onPrimary: p.brandOn,
        primaryContainer: p.brandSoft,
        onPrimaryContainer: p.brandInk,
        secondary: p.info,
        onSecondary: p.isDark ? const Color(0xFF06202B) : Colors.white,
        secondaryContainer: p.infoSoft,
        onSecondaryContainer: p.info,
        tertiary: p.gold,
        onTertiary: p.isDark ? const Color(0xFF241E0C) : Colors.white,
        tertiaryContainer: p.goldSoft,
        onTertiaryContainer: p.gold,
        error: p.danger,
        onError: Colors.white,
        errorContainer: p.dangerSoft,
        onErrorContainer: p.danger,
        surface: p.surface,
        onSurface: p.textPrimary,
        surfaceContainerLowest: p.background,
        surfaceContainerLow: p.background,
        surfaceContainer: p.surface,
        surfaceContainerHigh: p.surfaceMuted,
        surfaceContainerHighest: p.surfaceMuted,
        onSurfaceVariant: p.textSecondary,
        outline: p.border,
        outlineVariant: p.divider,
        shadow: p.shadow,
        scrim: p.scrim,
        inverseSurface: p.textPrimary,
        onInverseSurface: p.background,
        inversePrimary: p.brandInk,
      ),

      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: systemOverlayFor(p),
        iconTheme: IconThemeData(color: p.textPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: p.textPrimary, size: 24),
        titleTextStyle: appDisplay(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      iconTheme: IconThemeData(color: p.textPrimary, size: 24),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.brandSoft,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? p.brandInk
                : p.textTertiary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => appBody(
            fontSize: 11,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? p.brandInk
                : p.textTertiary,
          ),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: p.brandInk,
        unselectedLabelColor: p.textTertiary,
        indicatorColor: p.brandInk,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: appBody(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            appBody(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlAll,
          side: BorderSide(color: p.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),

      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
        hintStyle: appBody(color: p.textTertiary, fontSize: 15),
        labelStyle: appBody(color: p.textSecondary, fontSize: 15),
        prefixIconColor: p.textTertiary,
        suffixIconColor: p.textTertiary,
        // İP-16 · WCAG 1.4.11 — metin girdisinin sınırı işlevsel bilgidir,
        // dekorasyon değil. Dekoratif `p.border` beyaz yüzeyde 1,28:1
        // veriyordu; burada 3,0:1 eşiğini karşılayan belirteç kullanılır.
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: p.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: p.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: p.brandInk, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: p.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: p.danger, width: 2),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.brand,
        foregroundColor: p.brandOn,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.brandOn,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.textTertiary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: appBody(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppSpacing.xl),
          minimumSize: const Size(0, 52),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.brandOn,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.textTertiary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: appBody(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppSpacing.xl),
          minimumSize: const Size(0, 52),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: appBody(fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppSpacing.xl),
          minimumSize: const Size(0, 52),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brandInk,
          textStyle: appBody(fontSize: 15, fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.brandSoft,
        side: BorderSide(color: p.border),
        labelStyle: appBody(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return p.textTertiary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.brand;
          return p.isDark ? p.surfaceMuted : const Color(0xFFE5E1DA);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        elevation: 0,
        titleTextStyle: appDisplay(
          color: p.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: appBody(
          color: p.textSecondary,
          fontSize: 15,
          height: 1.45,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: p.shadow.withValues(alpha: p.isDark ? 0.6 : 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: p.border),
        ),
        textStyle: appBody(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.textPrimary,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? p.surfaceMuted : p.textPrimary,
        contentTextStyle: appBody(
          color: p.isDark ? p.textPrimary : p.background,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: p.brandInk,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.base),
        elevation: 0,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brandInk,
        linearTrackColor: p.surfaceMuted,
        circularTrackColor: p.surfaceMuted,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: p.brand,
        inactiveTrackColor: p.surfaceMuted,
        thumbColor: p.brand,
        overlayColor: p.brand.withValues(alpha: 0.12),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.isDark ? p.surfaceMuted : p.textPrimary,
          borderRadius: AppRadius.xsAll,
        ),
        textStyle: appBody(
          fontSize: 12,
          color: p.isDark ? p.textPrimary : p.background,
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Duruma göre durum çubuğu / gezinme çubuğu stili.
  static SystemUiOverlayStyle systemOverlayFor(AppPalette p) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: p.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: p.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: p.background,
      systemNavigationBarIconBrightness:
          p.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tipografi ölçeği
  //
  // 9 Eylül'de yeniden ayarlandı. Önceki ölçek okunaklıydı ama SESSİZDİ:
  // başlıklarla gövde arasındaki ağırlık farkı azdı, negatif harf aralığı
  // zayıftı ve ekranlar birbirine benziyordu. Yeni ölçek üç şeyi değiştirir:
  //
  //   • Başlıklar büyüdü ve 800 ağırlığa çıktı — bir başlık, bir başlık gibi
  //     görünmeli.
  //   • Negatif harf aralığı arttı; Outfit sıkışınca karakterini gösteriyor.
  //   • Gövde satır yüksekliği 1,5'e çıktı — Türkçe'nin uzun kelimeleri ve
  //     ğ/ş/ç inen-çıkan kuyrukları nefes alacak yer istiyor.
  //
  // Kontrast değerleri değişmedi; ölçek büyüdüğü için erişilebilirlik
  // yalnızca iyileşir (büyük metin eşiği daha düşüktür).
  // ───────────────────────────────────────────────────────────────────────────
  static TextTheme _textTheme(AppPalette p) {
    return TextTheme(
      displayLarge: appDisplay(
          color: p.textPrimary, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.6),
      displayMedium: appDisplay(
          color: p.textPrimary, fontSize: 37, fontWeight: FontWeight.w800, letterSpacing: -1.3),
      displaySmall: appDisplay(
          color: p.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0),
      headlineLarge: appDisplay(
          color: p.textPrimary, fontSize: 29, fontWeight: FontWeight.w800, letterSpacing: -0.9),
      headlineMedium: appDisplay(
          color: p.textPrimary, fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.7),
      headlineSmall: appDisplay(
          color: p.textPrimary, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge: appBody(
          color: p.textPrimary, fontSize: 17.5, fontWeight: FontWeight.w800, letterSpacing: -0.35),
      titleMedium: appBody(
          color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleSmall: appBody(
          color: p.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
      bodyLarge: appBody(
          color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: appBody(
          color: p.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: appBody(
          color: p.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w400, height: 1.45),
      labelLarge: appBody(
          color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: appBody(
          color: p.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      // Bölüm etiketleri büyük harfle yazılıyor; harf aralığı olmadan
      // büyük harf dizisi okunmaz bir blok hâline gelir.
      labelSmall: appBody(
          color: p.textTertiary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
    );
  }
}

// ─── Yazı tipi aileleri ──────────────────────────────────────────────────────
//
// ── NEDEN google_fonts KALDIRILDI (9 Eylül 2026) ───────────────────────────
// `google_fonts` paketi, yazı tipi dosyalarını ÇALIŞMA ZAMANINDA
// fonts.gstatic.com üzerinden indirir ve cihaza önbellekler. Yani ürünün
// "çalışma zamanında tek bir ağ çağrısı yapılmaz" iddiası, ilk açılışta
// sessizce çiğneniyordu.
//
// Bu, metin göndermekten farklı bir sızıntıdır ama iddiayı yine de yanlış
// kılar — ve bir mahremiyet iddiası "neredeyse doğru" olamaz. İki değişken
// yazı tipi (`assets/fonts/`) depoya alındı, paket kaldırıldı.
//
// Kazanç yalnızca dürüstlük değil: uygulama artık ilk açılışta ağ beklemiyor
// ve uçak modunda yazı tipleri yedek fonta düşmüyor. Jüri demosu uçak
// modunda yapılacak (`docs/17`), yani bu fark ekranda görünürdü.
//
// Değişmez `test/kapsam_degismezi_test.dart` içinde korunuyor: `lib/`
// altında `google_fonts` importu belirirse test kırılır.
//
// Lisans: her iki aile de SIL Open Font License 1.1 — `assets/fonts/OFL.txt`.

/// Başlık ailesi — **Outfit**. Geniş, geometrik, sıkıştırıldığında karakterli.
TextStyle appDisplay({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
}) =>
    _familyStyle('Outfit',
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
        fontFeatures: fontFeatures,
        decoration: decoration);

/// Gövde ailesi — **Inter**. Ekranda en okunaklı nötr grotesk.
/// Türkçe'nin ğ/ş/ı/İ/ç karakterlerini tam destekler.
TextStyle appBody({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
}) =>
    _familyStyle('Inter',
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
        fontFeatures: fontFeatures,
        decoration: decoration);

TextStyle _familyStyle(
  String family, {
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
}) {
  final weight = fontWeight ?? FontWeight.w400;
  return TextStyle(
    fontFamily: family,
    color: color,
    fontSize: fontSize,
    fontWeight: weight,
    // ── NEDEN HEM fontWeight HEM fontVariations ────────────────────────────
    // Paketlenen dosyalar DEĞİŞKEN (variable) yazı tipleridir; gerçek ağırlık
    // `wght` ekseninden gelir ve onu yalnızca `fontVariations` sürer.
    // `fontWeight` tek başına verilirse bazı ortamlar sentetik kalınlaştırma
    // yapar ve harfler şişer. İkisi birlikte verilince: ekseni destekleyen
    // ortam gerçek ağırlığı çizer, desteklemeyen ortamda `fontWeight` yedek
    // kalır — hiçbir ortamda ağırlık kaybolmaz.
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    letterSpacing: letterSpacing,
    height: height,
    fontStyle: fontStyle,
    fontFeatures: fontFeatures,
    decoration: decoration,
  );
}
