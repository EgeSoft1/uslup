// =============================================================================
// NSosyal / Türkiye Mesajlaşma — Tasarım Belirteçleri (Design Tokens)
// Dosya: mobile/lib/core/theme/app_palette.dart
//
// TEK KAYNAK İLKESİ
// -----------------
// Bu dosyadan önce uygulamada iki ayrı kırmızı (#C8102E ve #E30A17), üç ayrı
// gri ve dört ayrı "krem" dolaşıyordu; 430 satırda renk elle yazılmıştı.
// Aynı öğe ekrandan ekrana farklı görünüyordu. Artık tüm renkler burada
// tanımlanır ve `context.palette` üzerinden okunur.
//
// AÇIK/KOYU TEMA
// --------------
// Palet bir `ThemeExtension`'dır. `Theme.of(context)` hangi temayı taşıyorsa
// aynı isim (örn. `palette.surface`) doğru rengi döndürür. Ekranlar koyu tema
// için ayrıca kod yazmaz.
// =============================================================================

import 'package:flutter/material.dart';

/// Ham renk sabitleri.
///
/// Ekranlar bunları **doğrudan kullanmaz** — `context.palette` üzerinden
/// okur; böylece koyu tema kendiliğinden çalışır. Buradaki sabitler yalnızca
/// paletleri kurmak ve tema dışı bağlamlar (splash, bayrak) içindir.
abstract final class AppColors {
  // ─── Marka ────────────────────────────────────────────────────────────────
  /// Türk bayrağı kırmızısının koyu, ekranda göz yormayan tonu. Ana marka rengi.
  static const Color brand = Color(0xFFC8102E);
  static const Color brandDark = Color(0xFFA00D22);
  static const Color brandDeep = Color(0xFF7D0A1B);

  /// Bayrağın resmî kırmızısı — yalnızca bayrak/splash anlarında.
  static const Color flagRed = Color(0xFFE30A17);

  /// Koyu tema için açılmış kırmızı: koyu zeminde metin/ikon olarak
  /// WCAG AA kontrastını sağlar (#C8102E koyu zeminde okunmuyordu).
  static const Color brandLifted = Color(0xFFFF6B7D);
  static const Color brandLiftedFill = Color(0xFFD81E39);

  // ─── Açık tema nötrleri (sıcak krem ailesi) ───────────────────────────────
  static const Color creamBackground = Color(0xFFFBF7F2);
  static const Color creamSurface = Color(0xFFFFFFFF);
  static const Color creamMuted = Color(0xFFF4EEE6);
  static const Color creamBorder = Color(0xFFEBE2D6);

  /// ETKİLEŞİMLİ bileşen kenarlığı — WCAG 2.1 §1.4.11 (3,0:1).
  ///
  /// İP-16 denetimi `creamBorder`ın beyaz yüzeyde 1,28:1 verdiğini ölçtü.
  /// Bu, dekoratif ayraçlar için sorun DEĞİLDİR: 1.4.11 yalnızca "bir arayüz
  /// bileşenini tanımak için gerekli görsel bilgiyi" kapsar, süslemeyi değil.
  /// Ama metin girdisinin sınırı dekoratif değildir — kullanıcı yazma
  /// alanının nerede başladığını oradan anlar. Bu yüzden iki belirteç ayrıldı:
  ///
  ///   creamBorder        → kart ayracı, liste çizgisi (dekoratif, muaf)
  ///   creamBorderStrong  → metin girdisi, seçilebilir çip (3,75:1)
  static const Color creamBorderStrong = Color(0xFF8F8271);
  static const Color creamDivider = Color(0xFFF1EBE3);

  static const Color inkPrimary = Color(0xFF1C1C1E);
  // İP-16: 0xFF77726E kremde 4,46:1 veriyordu — WCAG 1.4.3 AA eşiği 4,5:1.
  // Ölçümle 4,94:1'e çekildi (`tool/erisilebilirlik_denetimi.dart`).
  static const Color inkSecondary = Color(0xFF706B67);
  // İP-16: 0xFFA9A29C beyazda 2,52:1 veriyordu. Bu renk 11,5 px metinde
  // kullanılıyor — yani "büyük metin" istisnası GEÇERSİZ, eşik 4,5:1.
  // 4,90:1'e çekildi. Görsel hiyerarşi korunuyor: ana metin 17:1.
  static const Color inkTertiary = Color(0xFF767068);

  // ─── Koyu tema nötrleri (sıcak kömür ailesi) ──────────────────────────────
  // Saf siyah değil: OLED'de kontrast şoku yapar ve marka sıcaklığını öldürür.
  static const Color charcoalBackground = Color(0xFF141110);
  static const Color charcoalSurface = Color(0xFF1E1A19);
  static const Color charcoalMuted = Color(0xFF272220);
  static const Color charcoalBorder = Color(0xFF352E2B);

  /// Koyu temanın etkileşimli bileşen kenarlığı — 3,60:1. Gerekçe için
  /// bkz. [creamBorderStrong].
  static const Color charcoalBorderStrong = Color(0xFF7A7167);
  static const Color charcoalDivider = Color(0xFF2A2523);

  static const Color snowPrimary = Color(0xFFF6F1EB);
  static const Color snowSecondary = Color(0xFFA8A19B);
  static const Color snowTertiary = Color(0xFF716A65);

  // ─── Durum renkleri ───────────────────────────────────────────────────────
  // İP-16: 0xFF10B981 beyaz yüzeyde 2,54:1 — WCAG 1.4.11 (metin dışı
  // kontrast) eşiği 3,0:1. Durum rengi bir BİLGİ TAŞIYICIDIR; ayırt
  // edilemezse renk körü kullanıcı için sinyal kaybolur. 4,83:1.
  static const Color success = Color(0xFF0B8258);
  static const Color successLifted = Color(0xFF34D399);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLifted = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLifted = Color(0xFFF87171);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLifted = Color(0xFF38BDF8);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLifted = Color(0xFFE8C55F);
  static const Color turquoise = Color(0xFF007A99);
  static const Color turquoiseLifted = Color(0xFF22B8D9);
}

/// Uygulamanın anlamsal renk paleti.
///
/// İsimler *ne olduğunu* değil *ne işe yaradığını* söyler: `surface` bir
/// karttır, `brandInk` kırmızı bir metindir. Bu sayede koyu temada değerler
/// değişse de anlam sabit kalır.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.brandOn,
    required this.brandInk,
    required this.brandSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.gold,
    required this.goldSoft,
    required this.shadow,
    required this.scrim,
    required this.bubbleIncoming,
    required this.bubbleIncomingText,
    required this.bubbleOutgoing,
    required this.bubbleOutgoingText,
  });

  /// Koyu tema mı? Gölge/parlaklık kararları için.
  final bool isDark;

  // Yüzeyler
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceElevated;
  final Color border;

  /// Etkileşimli bileşen sınırı. [border]dan farklıdır ve WCAG 1.4.11
  /// eşiğini (3,0:1) karşılamak zorundadır — metin girdisinin sınırı
  /// dekoratif değil, işlevsel bilgidir.
  final Color borderStrong;
  final Color divider;

  // Metin
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Marka
  final Color brand;
  final Color brandOn;
  final Color brandInk;
  final Color brandSoft;

  // Durum
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;
  final Color gold;
  final Color goldSoft;

  // Efekt
  final Color shadow;
  final Color scrim;

  // Sohbet baloncukları
  final Color bubbleIncoming;
  final Color bubbleIncomingText;
  final Color bubbleOutgoing;
  final Color bubbleOutgoingText;

  // ─── Açık tema ────────────────────────────────────────────────────────────
  static const AppPalette light = AppPalette(
    isDark: false,
    background: AppColors.creamBackground,
    surface: AppColors.creamSurface,
    surfaceMuted: AppColors.creamMuted,
    surfaceElevated: AppColors.creamSurface,
    border: AppColors.creamBorder,
    borderStrong: AppColors.creamBorderStrong,
    divider: AppColors.creamDivider,
    textPrimary: AppColors.inkPrimary,
    textSecondary: AppColors.inkSecondary,
    textTertiary: AppColors.inkTertiary,
    brand: AppColors.brand,
    brandOn: Color(0xFFFFFFFF),
    brandInk: AppColors.brand,
    brandSoft: Color(0xFFFDECEE),
    success: AppColors.success,
    successSoft: Color(0xFFE7F8F1),
    warning: AppColors.warning,
    warningSoft: Color(0xFFFDF3E2),
    danger: AppColors.danger,
    dangerSoft: Color(0xFFFDECEC),
    info: AppColors.info,
    infoSoft: Color(0xFFE6F3FB),
    gold: AppColors.gold,
    goldSoft: Color(0xFFFBF4E1),
    shadow: Color(0xFF6B5B4E),
    scrim: Color(0xFF1C1C1E),
    bubbleIncoming: AppColors.creamSurface,
    bubbleIncomingText: AppColors.inkPrimary,
    bubbleOutgoing: AppColors.brand,
    bubbleOutgoingText: Color(0xFFFFFFFF),
  );

  // ─── Koyu tema ────────────────────────────────────────────────────────────
  static const AppPalette dark = AppPalette(
    isDark: true,
    background: AppColors.charcoalBackground,
    surface: AppColors.charcoalSurface,
    surfaceMuted: AppColors.charcoalMuted,
    surfaceElevated: AppColors.charcoalMuted,
    border: AppColors.charcoalBorder,
    borderStrong: AppColors.charcoalBorderStrong,
    divider: AppColors.charcoalDivider,
    textPrimary: AppColors.snowPrimary,
    textSecondary: AppColors.snowSecondary,
    textTertiary: AppColors.snowTertiary,
    brand: AppColors.brandLiftedFill,
    brandOn: Color(0xFFFFFFFF),
    brandInk: AppColors.brandLifted,
    brandSoft: Color(0xFF33191D),
    success: AppColors.successLifted,
    successSoft: Color(0xFF13291F),
    warning: AppColors.warningLifted,
    warningSoft: Color(0xFF2E2312),
    danger: AppColors.dangerLifted,
    dangerSoft: Color(0xFF321918),
    info: AppColors.infoLifted,
    infoSoft: Color(0xFF14252E),
    gold: AppColors.goldLifted,
    goldSoft: Color(0xFF2C2617),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    bubbleIncoming: AppColors.charcoalMuted,
    bubbleIncomingText: AppColors.snowPrimary,
    bubbleOutgoing: AppColors.brandLiftedFill,
    bubbleOutgoingText: Color(0xFFFFFFFF),
  );

  // ─── Türetilmiş yardımcılar ───────────────────────────────────────────────

  /// Kart gölgesi. Koyu temada gölge görünmez; onun yerine kenarlık taşır —
  /// bu yüzden koyu temada daha zayıf ama daha geniş bir gölge kullanılır.
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.40 : 0.05),
          blurRadius: isDark ? 18 : 14,
          offset: const Offset(0, 4),
        ),
      ];

  /// Yüzen öğeler (FAB, alt menü) için daha derin gölge.
  List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.55 : 0.10),
          blurRadius: 24,
          spreadRadius: -2,
          offset: const Offset(0, 8),
        ),
      ];

  /// Marka rengiyle renklendirilmiş gölge — kırmızı butonların altında.
  List<BoxShadow> get brandShadow => [
        BoxShadow(
          color: brand.withValues(alpha: isDark ? 0.35 : 0.28),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Ekran arka planı için yumuşak dikey geçiş.
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? const [Color(0xFF1B1614), AppColors.charcoalBackground]
            : const [Color(0xFFFFFCF8), AppColors.creamBackground],
      );

  /// Marka gradyanı — birincil aksiyonlar ve başlıklar.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFFE23A52), Color(0xFFA81D33)]
            : const [AppColors.brand, AppColors.brandDark],
      );

  @override
  AppPalette copyWith({
    bool? isDark,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceElevated,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? brand,
    Color? brandOn,
    Color? brandInk,
    Color? brandSoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? infoSoft,
    Color? gold,
    Color? goldSoft,
    Color? shadow,
    Color? scrim,
    Color? bubbleIncoming,
    Color? bubbleIncomingText,
    Color? bubbleOutgoing,
    Color? bubbleOutgoingText,
  }) {
    return AppPalette(
      isDark: isDark ?? this.isDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      brand: brand ?? this.brand,
      brandOn: brandOn ?? this.brandOn,
      brandInk: brandInk ?? this.brandInk,
      brandSoft: brandSoft ?? this.brandSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      bubbleIncoming: bubbleIncoming ?? this.bubbleIncoming,
      bubbleIncomingText: bubbleIncomingText ?? this.bubbleIncomingText,
      bubbleOutgoing: bubbleOutgoing ?? this.bubbleOutgoing,
      bubbleOutgoingText: bubbleOutgoingText ?? this.bubbleOutgoingText,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceMuted: c(surfaceMuted, other.surfaceMuted),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      divider: c(divider, other.divider),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      brand: c(brand, other.brand),
      brandOn: c(brandOn, other.brandOn),
      brandInk: c(brandInk, other.brandInk),
      brandSoft: c(brandSoft, other.brandSoft),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      info: c(info, other.info),
      infoSoft: c(infoSoft, other.infoSoft),
      gold: c(gold, other.gold),
      goldSoft: c(goldSoft, other.goldSoft),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
      bubbleIncoming: c(bubbleIncoming, other.bubbleIncoming),
      bubbleIncomingText: c(bubbleIncomingText, other.bubbleIncomingText),
      bubbleOutgoing: c(bubbleOutgoing, other.bubbleOutgoing),
      bubbleOutgoingText: c(bubbleOutgoingText, other.bubbleOutgoingText),
    );
  }
}

/// `context.palette` — ekranlarda renk okumanın tek yolu.
///
/// `Theme.of(context).extension<AppPalette>()` her seferinde yazmak yerine.
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  /// Kısa kullanım — yoğun widget ağaçlarında okunabilirliği artırır.
  AppPalette get c => palette;
}
