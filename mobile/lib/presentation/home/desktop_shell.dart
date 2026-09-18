// =============================================================================
// Masaüstü kabuğu — ev sahibi platformun üç sütunlu web yerleşimi
// Dosya: mobile/lib/presentation/home/desktop_shell.dart
//
// ── NEDEN AYRI BİR KABUK ──────────────────────────────────────────────────
// Mobil kabuk (`HomeShell`) alt sekme çubuğuyla çalışır: beş hedef, tek
// sütun, dokunma için ölçülmüş yükseklikler. Aynı ağacı geniş ekrana
// esnetmek iki şeyi birden bozuyordu — akış sütunu 1900 px'e yayılıp
// okunmaz hâle geliyor, alt çubuk ise farenin hiç gitmediği yerde duruyordu.
//
// Bu yüzden geniş ekran kendi yerleşimini taşır: solda kalıcı gezinme,
// ortada sabit genişlikte akış, sağda arama ve gündem. Hangi kabuğun
// çizileceğine `AdaptiveShell` karar verir; ikisi de AYNI ekranları ve
// AYNI `SocialStore` örneğini kullanır. Yani masaüstünde beğenilen bir
// gönderi mobilde de beğenilidir — ikinci bir veri yolu yoktur.
//
// ── KAPSAM ────────────────────────────────────────────────────────────────
// Sol sütuna yalnızca ürünün ZATEN sahip olduğu yüzeyler kondu. Ev sahibi
// platformun menüsünde bulunan ama bu üründe karşılığı olmayan girdiler
// (mesajlaşma, oyun, topluluklar) EKLENMEDİ: tıklanınca bir şey yapmayan
// bir menü, jüriye çalışmayan bir ürün gösterir. Mesajlaşma ayrıca
// 24 Ağustos'ta kapsam dışına alınmıştı ve `widget_test.dart` geri
// gelmediğini denetler.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../community/community_health_screen.dart';
import '../compose/compose_screen.dart';
import '../explore/explore_screen.dart';
import '../feed/feed_column.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/uslup_ayarlari_screen.dart';
import '../uslup/uslup_panel_screen.dart';
import '../widgets/social_widgets.dart';
import 'desktop_right_rail.dart';
import 'saved_column.dart';

/// Sol sütundaki gezinme hedefleri.
enum DesktopSection {
  anaSayfa('Ana Sayfa', Icons.home_outlined, Icons.home_rounded),
  bildirimler('Bildirimler', Icons.notifications_none_rounded,
      Icons.notifications_rounded),
  kesfet('Keşfet', Icons.explore_outlined, Icons.explore_rounded),
  uslup('Üslup Paneli', Icons.shield_outlined, Icons.shield_rounded),
  topluluk('Topluluk Sağlığı', Icons.insights_outlined, Icons.insights_rounded),
  kaydedilenler('Kaydedilenler', Icons.bookmark_border_rounded,
      Icons.bookmark_rounded),
  profil('Profil', Icons.person_outline_rounded, Icons.person_rounded);

  const DesktopSection(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  DesktopSection _section = DesktopSection.anaSayfa;

  /// Akış sütununun hangi sekmede olduğu. Sol sütundaki "Medya" anahtarı ve
  /// ortadaki sekme çubuğu AYNI durumu sürer; ikisinden biri değişince
  /// diğeri de değişir — ev sahibi platformdaki davranış budur.
  bool _mediaTab = false;

  /// Keşfet sütununa taşınan arama sorgusu. Sağ paneldeki kutudan gelir.
  String _query = '';

  void _select(DesktopSection section) {
    if (_section == section) return;
    setState(() => _section = section);
  }

  void _search(String term) {
    setState(() {
      _query = term;
      _section = DesktopSection.kesfet;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final showRail = width >= AppBreakpoints.wide;
    final compactNav = width < AppBreakpoints.wide;

    return Scaffold(
      backgroundColor: p.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.shellMax),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Sidebar(
                current: _section,
                compact: compactNav,
                mediaTab: _mediaTab,
                onSelect: _select,
                onMediaTab: (value) => setState(() {
                  _mediaTab = value;
                  _section = DesktopSection.anaSayfa;
                }),
                onCompose: () => ComposeScreen.open(context),
              ),
              Expanded(child: _center(p)),
              if (showRail)
                DesktopRightRail(
                  onSearch: _search,
                  onOpenProfile: () => _select(DesktopSection.profil),
                  onOpenTrends: () => _select(DesktopSection.kesfet),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Orta sütun ───────────────────────────────────────────────────────────

  Widget _center(AppPalette p) {
    final content = switch (_section) {
      DesktopSection.anaSayfa => FeedColumn(
          mediaTab: _mediaTab,
          onTabChanged: (value) => setState(() => _mediaTab = value),
        ),
      DesktopSection.bildirimler =>
        const NotificationsScreen(embedded: true),
      // `ValueKey` sorgu değişince ekranı yeniden kurar; arama kutusundan
      // gelen terim `initialQuery` ile içeri geçer.
      DesktopSection.kesfet => ExploreScreen(
          key: ValueKey(_query),
          initialQuery: _query,
          showSearchBar: false,
        ),
      DesktopSection.uslup => const UslupPanelScreen(),
      DesktopSection.topluluk => const CommunityHealthScreen(),
      DesktopSection.kaydedilenler => const SavedColumn(),
      DesktopSection.profil => const ProfileScreen(),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppBreakpoints.feedColumnMax),
          child: content,
        ),
      ),
    );
  }
}

// ─── Sol sütun ───────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.current,
    required this.compact,
    required this.mediaTab,
    required this.onSelect,
    required this.onMediaTab,
    required this.onCompose,
  });

  final DesktopSection current;
  final bool compact;
  final bool mediaTab;
  final ValueChanged<DesktopSection> onSelect;
  final ValueChanged<bool> onMediaTab;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width =
        compact ? AppBreakpoints.sidebarRail : AppBreakpoints.sidebarWide;

    return SizedBox(
      width: width,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? AppSpacing.md : AppSpacing.lg,
          AppSpacing.xl,
          compact ? AppSpacing.md : AppSpacing.base,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: compact ? 0 : AppSpacing.md, bottom: AppSpacing.xl),
              child: Align(
                alignment:
                    compact ? Alignment.center : Alignment.centerLeft,
                child: BrandMark(size: 34, showWordmark: !compact),
              ),
            ),
            // Rozet sayacı `SocialStore`dan okunur; bildirimler okunduğunda
            // sol sütunun da sönmesi için dinleyici burada kurulur.
            ListenableBuilder(
              listenable: SocialStore.instance,
              builder: (context, _) {
                final unread = SocialStore.instance.unreadNotificationCount;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final section in DesktopSection.values)
                      _NavTile(
                        section: section,
                        selected: current == section,
                        compact: compact,
                        badge: section == DesktopSection.bildirimler
                            ? unread
                            : 0,
                        onTap: () => onSelect(section),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.base),
            _ComposeButton(compact: compact, onTap: onCompose),
            const SizedBox(height: AppSpacing.lg),
            Divider(color: p.divider, height: 1),
            const SizedBox(height: AppSpacing.md),
            _SwitchRow(
              icon: Icons.play_circle_outline_rounded,
              label: 'Medya',
              value: mediaTab,
              compact: compact,
              onChanged: onMediaTab,
            ),
            _DarkModeRow(compact: compact),
            _NavAction(
              icon: Icons.tune_rounded,
              label: 'Ayarlar',
              compact: compact,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const UslupAyarlariScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.section,
    required this.selected,
    required this.compact,
    required this.badge,
    required this.onTap,
  });

  final DesktopSection section;
  final bool selected;
  final bool compact;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      selected: selected,
      button: true,
      label: badge > 0 ? '${section.label}, $badge okunmamış' : section.label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Material(
            color: selected ? p.brandSoft : Colors.transparent,
            borderRadius: AppRadius.pill,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.pill,
              hoverColor: p.surfaceMuted,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 0 : AppSpacing.md,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Badge(
                      isLabelVisible: badge > 0,
                      label: Text('$badge'),
                      backgroundColor: p.brand,
                      textColor: p.brandOn,
                      child: Icon(
                        selected ? section.activeIcon : section.icon,
                        size: 23,
                        color: selected ? p.brandInk : p.textSecondary,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          section.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                selected ? p.textPrimary : p.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gezinme görünümlü ama bir sekme seçmeyen satır (Ayarlar).
class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.icon,
    required this.label,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.pill,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pill,
            hoverColor: p.surfaceMuted,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 0 : AppSpacing.md,
                vertical: 11,
              ),
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(icon, size: 21, color: p.textSecondary),
                  if (!compact) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// İkon + etiket + anahtar. Dar şeritte etiket düşer, anahtar ikona iner.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final bool compact;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (compact) {
      return Semantics(
        toggled: value,
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: IconButton(
            onPressed: () => onChanged(!value),
            icon: Icon(icon, size: 21),
            color: value ? p.brandInk : p.textSecondary,
            tooltip: label,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 21, color: p.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: p.textSecondary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DarkModeRow extends StatelessWidget {
  const _DarkModeRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _SwitchRow(
        icon: Icons.dark_mode_outlined,
        label: 'Karanlık mod',
        value: controller.isDarkIn(context),
        compact: compact,
        onChanged: (_) => controller.toggle(context),
      ),
    );
  }
}

/// Sol sütundaki birincil eylem.
///
/// Gradyan yalnızca DOLGU olarak kullanılır; üzerindeki etiket beyaz ve
/// kalındır. Camgöbeği ucunda normal ağırlıkta metin WCAG 1.4.3 eşiğini
/// karşılamazdı.
class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: 'Yeni gönderi',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.pill,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pill,
            child: Ink(
              decoration: BoxDecoration(
                gradient: p.brandGradient,
                borderRadius: AppRadius.pill,
                boxShadow: p.brandShadow,
              ),
              child: SizedBox(
                height: 46,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_rounded,
                        size: 17, color: Colors.white),
                    if (!compact) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Yeni Gönderi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
