// =============================================================================
// Üslup · NSosyal — Tasarım Belirteçleri (Design Tokens)
// Dosya: mobile/lib/core/theme/app_palette.dart
//
// TEK KAYNAK İLKESİ
// -----------------
// Bu dosyadan önce uygulamada iki ayrı kırmızı (#C8102E ve #E30A17), üç ayrı
// gri ve dört ayrı "krem" dolaşıyordu; 430 satırda renk elle yazılmıştı.
// Aynı öğe ekrandan ekrana farklı görünüyordu. Artık tüm renkler burada
// tanımlanır ve `context.palette` üzerinden okunur.
//
// ── MARKA DEĞİŞİKLİĞİ (9 Eylül 2026) ──────────────────────────────────────
// Palet, devralınan "Türkiye Mesajlaşma" kırmızısından (#C8102E) NSosyal'in
// görsel diline taşındı: soğuk nötr griler üzerine mavi aksan ve camgöbeği→
// mavi gradyan. Gerekçe ürünseldir, estetik değildir — Üslup bir uygulama
// değil, bir sosyal platformun içine DÜŞEN bir katmandır. Prototipin ev
// sahibi kabuğu hedef platformun diliyle konuşmazsa, jüri katmanın kendi
// ürününe nasıl oturduğunu göremez.
//
// NSosyal'in logosu, işaretleri ve tipografisi KOPYALANMAMIŞTIR; kopyalansaydı
// prototip bir taklit olurdu. Alınan şey yerleşim ve renk ailesi düzeyindeki
// tasarım dilidir, marka kimliği değil.
//
// ── AÇIK/KOYU TEMA ────────────────────────────────────────────────────────
// Palet bir `ThemeExtension`'dır. `Theme.of(context)` hangi temayı taşıyorsa
// aynı isim (örn. `palette.surface`) doğru rengi döndürür. Ekranlar koyu tema
// için ayrıca kod yazmaz.
//
// ── KONTRAST ──────────────────────────────────────────────────────────────
// Buradaki her değer `tool/erisilebilirlik_denetimi.dart` tarafından KAYNAK
// OLARAK okunur ve WCAG 2.1 eşiklerine karşı ölçülür. Renk değiştiren biri
// aracı çalıştırmak zorundadır; elle güncellenen bir tablo bayatlar, ölçüm
// bayatlamaz.
//
//     cd mobile && dart run tool/erisilebilirlik_denetimi.dart
// =============================================================================

import 'package:flutter/material.dart';

/// Ham renk sabitleri.
///
/// Ekranlar bunları **doğrudan kullanmaz** — `context.palette` üzerinden
/// okur; böylece koyu tema kendiliğinden çalışır. Buradaki sabitler yalnızca
/// paletleri kurmak ve tema dışı bağlamlar (marka gradyanı) içindir.
abstract final class AppColors {
  // ─── Marka ────────────────────────────────────────────────────────────────
  /// Ana marka mavisi. Beyaz metinle 5,19:1 verir — WCAG 1.4.3 AA (4,5:1)
  /// eşiğini birincil butonlarda güvenle geçer.
  static const Color brand = Color(0xFF2A63E8);
  static const Color brandDark = Color(0xFF1E4CBF);
  static const Color brandDeep = Color(0xFF16368A);

  /// Gradyan uçları — camgöbeği → mavi. Yalnızca DOLGU olarak kullanılır
  /// (buton zemini, avatar halkası); üzerine küçük metin konmaz, çünkü
  /// camgöbeği ucunda beyaz metin 4,5:1'i karşılamaz.
  static const Color brandCyan = Color(0xFF35C6EA);
  static const Color brandIndigo = Color(0xFF4A6CF7);

  /// Koyu temada metin/ikon olarak kullanılan açılmış mavi.
  static const Color brandLifted = Color(0xFF7FA9FF);
  static const Color brandLiftedFill = Color(0xFF2A63E8);

  // ─── Açık tema nötrleri (soğuk gri-lavanta ailesi) ────────────────────────
  static const Color coolBackground = Color(0xFFF1F2F6);
  static const Color coolSurface = Color(0xFFFFFFFF);
  static const Color coolMuted = Color(0xFFEFF1F6);
  static const Color coolBorder = Color(0xFFE3E6ED);

  /// ETKİLEŞİMLİ bileşen kenarlığı — WCAG 2.1 §1.4.11 (3,0:1).
  ///
  /// İP-16 denetimi dekoratif kenarlığın beyaz yüzeyde 1,3:1 civarında
  /// kaldığını ölçtü. Bu, ayraçlar için sorun DEĞİLDİR: 1.4.11 yalnızca "bir
  /// arayüz bileşenini tanımak için gerekli görsel bilgiyi" kapsar, süslemeyi
  /// değil. Ama metin girdisinin sınırı dekoratif değildir — kullanıcı yazma
  /// alanının nerede başladığını oradan anlar. Bu yüzden iki belirteç ayrıdır:
  ///
  ///   coolBorder        → kart ayracı, liste çizgisi (dekoratif, muaf)
  ///   coolBorderStrong  → metin girdisi, seçilebilir çip (3,61:1)
  static const Color coolBorderStrong = Color(0xFF808795);
  static const Color coolDivider = Color(0xFFECEEF3);

  static const Color inkPrimary = Color(0xFF14171F);
  /// Zeminde 5,48:1 · yüzeyde 6,13:1 — normal metin AA eşiğini geçer.
  static const Color inkSecondary = Color(0xFF5A6272);
  /// 11,5 px metinde kullanılır — yani "büyük metin" istisnası GEÇERSİZ,
  /// eşik 4,5:1'dir. Ölçülen: 4,57:1.
  static const Color inkTertiary = Color(0xFF6E7686);

  // ─── Koyu tema nötrleri (soğuk kömür ailesi) ──────────────────────────────
  // Saf siyah değil: OLED'de kontrast şoku yapar ve yüzey hiyerarşisini
  // (zemin / kart / yükseltilmiş kart) görünmez kılar.
  static const Color charcoalBackground = Color(0xFF0E1116);
  static const Color charcoalSurface = Color(0xFF161A21);
  static const Color charcoalMuted = Color(0xFF1E232C);
  static const Color charcoalBorder = Color(0xFF272D38);

  /// Koyu temanın etkileşimli bileşen kenarlığı — 4,39:1.
  /// Gerekçe için bkz. [coolBorderStrong].
  static const Color charcoalBorderStrong = Color(0xFF78808F);
  static const Color charcoalDivider = Color(0xFF22272F);

  static const Color snowPrimary = Color(0xFFE9EDF4);
  static const Color snowSecondary = Color(0xFF9AA3B2);
  static const Color snowTertiary = Color(0xFF7B8496);

  // ─── Durum renkleri ───────────────────────────────────────────────────────
  // Durum rengi bir BİLGİ TAŞIYICIDIR; ayırt edilemezse renk körü kullanıcı
  // için sinyal kaybolur. Hepsi WCAG 1.4.11 (3,0:1) eşiğine karşı ölçüldü.
  static const Color success = Color(0xFF0B8258);
  static const Color successLifted = Color(0xFF34D399);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLifted = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLifted = Color(0xFFF87171);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLifted = Color(0xFF38BDF8);
  static const Color gold = Color(0xFFB4860B);
  static const Color goldLifted = Color(0xFFE8C55F);
}

/// Uygulamanın anlamsal renk paleti.
///
/// İsimler *ne olduğunu* değil *ne işe yaradığını* söyler: `surface` bir
/// karttır, `brandInk` mavi bir metindir. Bu sayede koyu temada değerler
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

  // Alıntı / yorum baloncukları
  final Color bubbleIncoming;
  final Color bubbleIncomingText;
  final Color bubbleOutgoing;
  final Color bubbleOutgoingText;

  // ─── Açık tema ────────────────────────────────────────────────────────────
  static const AppPalette light = AppPalette(
    isDark: false,
    background: AppColors.coolBackground,
    surface: AppColors.coolSurface,
    surfaceMuted: AppColors.coolMuted,
    surfaceElevated: AppColors.coolSurface,
    border: AppColors.coolBorder,
    borderStrong: AppColors.coolBorderStrong,
    divider: AppColors.coolDivider,
    textPrimary: AppColors.inkPrimary,
    textSecondary: AppColors.inkSecondary,
    textTertiary: AppColors.inkTertiary,
    brand: AppColors.brand,
    brandOn: Color(0xFFFFFFFF),
    brandInk: AppColors.brand,
    brandSoft: Color(0xFFE8EFFE),
    success: AppColors.success,
    successSoft: Color(0xFFE6F6F0),
    warning: AppColors.warning,
    warningSoft: Color(0xFFFDF3E2),
    danger: AppColors.danger,
    dangerSoft: Color(0xFFFDECEC),
    info: AppColors.info,
    infoSoft: Color(0xFFE6F3FB),
    gold: AppColors.gold,
    goldSoft: Color(0xFFFAF3E0),
    shadow: Color(0xFF1B2440),
    scrim: Color(0xFF0B0E14),
    bubbleIncoming: AppColors.coolMuted,
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
    brandSoft: Color(0xFF16233F),
    success: AppColors.successLifted,
    successSoft: Color(0xFF10291F),
    warning: AppColors.warningLifted,
    warningSoft: Color(0xFF2C2412),
    danger: AppColors.dangerLifted,
    dangerSoft: Color(0xFF2E1A1B),
    info: AppColors.infoLifted,
    infoSoft: Color(0xFF11242E),
    gold: AppColors.goldLifted,
    goldSoft: Color(0xFF2A2517),
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

  /// Marka rengiyle renklendirilmiş gölge — mavi butonların altında.
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
            ? const [Color(0xFF12161D), AppColors.charcoalBackground]
            : const [Color(0xFFF7F8FB), AppColors.coolBackground],
      );

  /// Marka gradyanı — birincil aksiyonlar, avatar halkaları, logo işareti.
  ///
  /// Camgöbeği→mavi. Üzerine küçük metin KONMAZ; büyük ikon ve beyaz
  /// kalın etiket dışında kullanımı kontrast ölçütünü zorlar.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF3DD0F0), Color(0xFF5B7BFF)]
            : const [AppColors.brandCyan, AppColors.brandIndigo],
      );

  /// Tam genişlikte başlık panelleri için KOYU marka gradyanı.
  ///
  /// [brandGradient]den ayrı olması bir kontrast zorunluluğudur:
  /// camgöbeği ucunda (#35C6EA) beyaz metin 1,9:1 verir ve WCAG 1.4.3'ün
  /// çok altında kalır. Bu gradyanın iki ucu da beyaz metinle en az 5,19:1
  /// sağlar, yani üzerine gerçek başlık ve paragraf yazılabilir.
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF1B3A7A), Color(0xFF10204A)]
            : const [AppColors.brand, AppColors.brandDeep],
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
/// `Theme.of(this).extension<AppPalette>()` her seferinde yazmak yerine.
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  /// Kısa kullanım — yoğun widget ağaçlarında okunabilirliği artırır.
  AppPalette get c => palette;
}
