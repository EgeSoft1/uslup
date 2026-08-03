// =============================================================================
// AppAvatar — tek avatar bileşeni
// Dosya: mobile/lib/core/widgets/app_avatar.dart
//
// ÖNCESİ: 13 ayrı yerde ham `Image.network`. Her kaydırmada yeniden indiriliyor,
// yüklenirken boş gri daire görünüyor, ağ yoksa hiçbir şey çıkmıyordu.
// `cached_network_image` bağımlılığı pubspec'te vardı ama hiç kullanılmamıştı.
//
// SONRASI: disk önbelleği + yüklenirken iskelet + hata durumunda isimden
// üretilen baş harfler. Baş harflerin arka plan rengi isimden türetilir, yani
// aynı kişi her ekranda aynı renkte görünür.
// =============================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 52,
    this.isOnline = false,
    this.showOnlineDot = true,
    this.ringColor,
    this.ringWidth = 2,
    this.onTap,
  });

  final String? imageUrl;

  /// Görsel yoksa baş harfler bundan üretilir.
  final String name;

  final double size;
  final bool isOnline;
  final bool showOnlineDot;
  final Color? ringColor;
  final double ringWidth;
  final VoidCallback? onTap;

  /// İsimden en fazla iki harf. "Aile Grubu" → "AG", "Ahmet" → "AH".
  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length == 1 ? w : w.substring(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  /// İsimden kararlı bir renk. Rastgele değil — aynı isim her zaman aynı renk.
  static Color colorOf(String name, AppPalette p) {
    const seeds = <Color>[
      Color(0xFFC8102E),
      Color(0xFF0284C7),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
      Color(0xFFDB2777),
    ];
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    final base = seeds[hash % seeds.length];
    // Koyu temada dolgu koyu, yazı açık olacak şekilde tonu yumuşatılır.
    return p.isDark ? Color.lerp(base, p.surface, 0.62)! : base;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dotSize = (size * 0.26).clamp(10.0, 18.0);

    Widget avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? _initials(p)
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 180),
                placeholder: (_, __) => ColoredBox(color: p.surfaceMuted),
                errorWidget: (_, __, ___) => _initials(p),
              ),
      ),
    );

    if (ringColor != null) {
      avatar = Container(
        padding: EdgeInsets.all(ringWidth + 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor!, width: ringWidth),
        ),
        child: avatar,
      );
    }

    Widget result = avatar;

    if (isOnline && showOnlineDot) {
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: p.success,
                shape: BoxShape.circle,
                // Halka rengi zemine göre; koyu temada beyaz halka göz alıyordu.
                border: Border.all(color: p.surface, width: dotSize * 0.16),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: result,
      );
    }

    return SizedBox(
      width: ringColor != null ? size + (ringWidth + 1) * 2 : size,
      height: ringColor != null ? size + (ringWidth + 1) * 2 : size,
      child: result,
    );
  }

  Widget _initials(AppPalette p) {
    final bg = colorOf(name, p);
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: p.isDark ? p.textPrimary : Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
