// =============================================================================
// Ortak yüzeyler ve durum bileşenleri
// Dosya: mobile/lib/core/widgets/app_surfaces.dart
//
// Ekranlarda onlarca kez elle yazılan "beyaz kart + 24 köşe + gölge" bloğu
// ile "başlık + alt başlık" satırını tek yerde toplar. Böylece kart görünümü
// değiştiğinde 30 dosya değil, bu dosya güncellenir.
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// Alt ekranların ortak başlık çubuğu.
///
/// Her alt ekran kendi `PreferredSize` + `Container` + `SafeArea` yığınını
/// elle kuruyordu; başlıklar ekrandan ekrana 2–4 px kayıyordu.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.centerTitle = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                color: p.textPrimary,
                tooltip: 'Geri',
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11.5, color: p.textSecondary),
                      ),
                  ],
                ),
              ),
              if (actions.isEmpty && centerTitle)
                const SizedBox(width: 48)
              else
                ...actions,
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standart kart yüzeyi.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.base),
    this.radius = AppRadius.xl,
    this.onTap,
    this.color,
    this.bordered = true,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final bool bordered;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: borderRadius,
        border: bordered ? Border.all(color: p.border) : null,
        boxShadow: shadow ? p.cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: p.brand.withValues(alpha: 0.06),
          highlightColor: p.brand.withValues(alpha: 0.03),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Bölüm başlığı: ikon + başlık + açıklama.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = iconColor ?? p.brandInk;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: p.isDark ? 0.18 : 0.10),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(icon, color: tint, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Liste boşken gösterilen durum. Boş ekran yerine ne yapılacağını söyler.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: p.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: p.textSecondary),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Renkli, yumuşak arka planlı küçük etiket (rozet).
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color,
    this.background,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = color ?? p.brandInk;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background ?? fg.withValues(alpha: p.isDark ? 0.20 : 0.10),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: dense ? 10.5 : 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Okunmamış mesaj sayacı.
///
/// Eskiden `BoxShape.circle` + yatay padding ile çiziliyordu; iki haneli
/// sayılarda daire rakamları kırpıyordu. Artık hap (pill) biçimli ve
/// tek hanede daire oranını korur.
class AppCountBadge extends StatelessWidget {
  const AppCountBadge({super.key, required this.count, this.color});

  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: EdgeInsets.symmetric(horizontal: text.length > 1 ? 7 : 0),
      decoration: BoxDecoration(
        color: color ?? p.brand,
        borderRadius: AppRadius.pill,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: p.brandOn,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

/// Yükleniyor iskeleti — nabız gibi solup açılan bir blok.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.xs,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
