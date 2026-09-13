// =============================================================================
// Sağ sütun — arama, gündem ve katmanın künyesi
// Dosya: mobile/lib/presentation/home/desktop_right_rail.dart
//
// Ev sahibi platformun masaüstü yerleşiminde sağ sütun arama kutusu ve
// "Popüler" başlıklarını taşır. Buraya üçüncü bir kart eklendi: ÜSLUP
// ÖZETİ.
//
// Gerekçesi ürünseldir. Masaüstü kabuğunda akış ekranın ortasını kaplar ve
// katman yalnızca kullanıcı yazarken görünür — yani jüri, ekranın büyük
// kısmında ürünü değil kabuğu izler. Sağdaki kart, katmanın orada olduğunu
// ve hangi sayılarla iddia edildiğini bir tıklama uzakta tutar.
//
// Karttaki sayılar elle yazılmadı: `Civility.olcumOzeti` ve
// `Civility.olcumKapsami` üzerinden okunur. Ekranda görünen her ölçümün
// tek bir kaynağı vardır; ikinci bir kopya, ölçüm güncellendiği gün
// sessizce yalan söylemeye başlardı.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/social/seed_data.dart';
import '../../core/social/social_models.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../explore/explore_screen.dart';
import '../widgets/social_widgets.dart';

class DesktopRightRail extends StatelessWidget {
  const DesktopRightRail({
    super.key,
    required this.onSearch,
    required this.onOpenProfile,
    required this.onOpenTrends,
  });

  final ValueChanged<String> onSearch;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenTrends;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SizedBox(
      width: AppBreakpoints.rightRail,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, 0, AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ExploreSearchField(
                    hint: 'Arama yap',
                    onSubmitted: onSearch,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  button: true,
                  label: 'Profilim',
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: onOpenProfile,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: UserAvatar.currentUser(size: 36),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _RailCard(
              title: 'Popüler',
              actionLabel: 'Tümünü gör',
              onAction: onOpenTrends,
              child: Column(
                children: [
                  for (var i = 0; i < SeedData.trends.length; i++) ...[
                    _TrendTile(
                      trend: SeedData.trends[i],
                      onTap: () => onSearch(SeedData.trends[i].tag),
                    ),
                    if (i < SeedData.trends.length - 1)
                      Divider(height: 1, color: p.divider),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            const _UslupCard(),
          ],
        ),
      ),
    );
  }
}

// ─── Kart kabuğu ─────────────────────────────────────────────────────────────

class _RailCard extends StatelessWidget {
  const _RailCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                AppSpacing.base, AppSpacing.sm, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (actionLabel != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: TextStyle(
                              fontSize: 12.5, color: p.textTertiary),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: p.textTertiary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ─── Gündem satırı ───────────────────────────────────────────────────────────

class _TrendTile extends StatelessWidget {
  const _TrendTile({required this.trend, required this.onTap});

  final TrendTopic trend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: '#${trend.tag}, ${trend.postCount} gönderi',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.tag_rounded, size: 20, color: p.brandInk),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trend.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${kisaSayi(trend.postCount)} gönderi',
                        style:
                            TextStyle(fontSize: 12, color: p.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (trend.risingBy != null)
                  AppBadgePill(
                    label: '+%${trend.risingBy}',
                    color: p.success,
                    icon: Icons.trending_up_rounded,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Üslup künyesi ───────────────────────────────────────────────────────────

class _UslupCard extends StatelessWidget {
  const _UslupCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 18, color: p.brandInk),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Üslup katmanı açık',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Yazdığın metin çözümlenir, hiçbir yere gönderilmez. '
            'Sistem engellemez — önerir, gerekçesini yazar, kararı sana '
            'bırakır.',
            style: TextStyle(
                fontSize: 12.5, color: p.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: p.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          Text(
            Civility.olcumOzeti,
            style: TextStyle(fontSize: 11.5, color: p.textTertiary, height: 1.5),
          ),
          Text(
            Civility.olcumKapsami,
            style: TextStyle(fontSize: 11.5, color: p.textTertiary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
