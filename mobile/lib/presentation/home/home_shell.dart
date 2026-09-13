// =============================================================================
// Ana Kabuk — ev sahibi platformun sekmeli gezinmesi
// Dosya: mobile/lib/presentation/home/home_shell.dart
//
// ── KAPSAM: NE EKLENDİ, NE EKLENMEDİ ──────────────────────────────────────
// 24 Ağustos'ta devralınan MESAJLAŞMA arayüzü (sohbet, arama, kişiler,
// kimlik doğrulama, ayarlar) üründen tamamen silinmişti ve o karar geçerli:
// bu kabukta hiçbiri yok ve geri sızarsa `test/widget_test.dart` kırılır.
//
// 9 Eylül'de eklenen şey farklıdır: bir SOSYAL AKIŞ KABUĞU. Gerekçesi
// ürünseldir. Üslup bir uygulama değil, bir platformun metin giriş
// noktalarına düşen bir katmandır; katmanı tek başına bir ekranda göstermek
// onu bir yazım denetleyicisine indirger. Saldırgan dilin büyük kısmı da boş
// bir kutuda değil, birinin söylediği bir şeye YANIT olarak üretilir.
//
// Kabuğun kapsam sınırı bir cümleyle yazılabilir: KATMANA YÜZEY OLMAYAN
// hiçbir şey eklenmez. Bu sınır da bir belgede değil, testte korunur —
// `test/kapsam_degismezi_test.dart`, uygulamadaki her ham `TextField`
// kullanımını sayar ve Üslup katmanından geçmeyen bir metin girişi
// eklenirse kırılır.
//
// ── ALT ÇUBUK ─────────────────────────────────────────────────────────────
// `NavigationBar` yerine elle çizildi: seçili sekmedeki hap biçimli vurgu
// ve rozetin ikonla birlikte ölçeklenmesi Material'ın varsayılanıyla
// mümkün değildi. Dokunma hedefleri 48 px'in altına inmiyor.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../community/community_health_screen.dart';
import '../compose/compose_screen.dart';
import '../explore/explore_screen.dart';
import '../feed/feed_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../uslup/uslup_panel_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex = widget.initialIndex;

  static const List<_NavSpec> _items = [
    _NavSpec(Icons.home_outlined, Icons.home_rounded, 'Akış'),
    _NavSpec(Icons.explore_outlined, Icons.explore_rounded, 'Keşfet'),
    _NavSpec(Icons.shield_outlined, Icons.shield_rounded, 'Üslup'),
    _NavSpec(Icons.insights_outlined, Icons.insights_rounded, 'Topluluk'),
    _NavSpec(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  void _select(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Yazma eylemi yalnızca içerik sekmelerinde anlamlıdır. Ölçüm ve
    // topluluk panellerinde bir "gönderi yaz" düğmesi, kullanıcının o an
    // yapmadığı bir işe davet olurdu.
    final showCompose = _currentIndex == 0 || _currentIndex == 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            FeedScreen(
              onOpenProfile: () => _select(4),
              onOpenNotifications: _openNotifications,
            ),
            const ExploreScreen(),
            const UslupPanelScreen(),
            const CommunityHealthScreen(),
            const ProfileScreen(),
          ],
        ),
        floatingActionButton: AnimatedScale(
          scale: showCompose ? 1.0 : 0.0,
          duration: AppDurations.normal,
          curve: AppCurves.emphasized,
          child: _ComposeFab(onTap: () => ComposeScreen.open(context)),
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          items: _items,
          onSelect: _select,
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// ─── Yeni gönderi düğmesi ────────────────────────────────────────────────────

class _ComposeFab extends StatelessWidget {
  const _ComposeFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: 'Yeni gönderi',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: p.brandShadow,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: p.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Alt gezinme çubuğu ──────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onSelect,
  });

  final int currentIndex;
  final List<_NavSpec> items;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.divider)),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: p.isDark ? 0.5 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    spec: items[i],
                    selected: currentIndex == i,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.brandInk : p.textTertiary;

    return Semantics(
      selected: selected,
      button: true,
      label: spec.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          splashColor: p.brand.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.standard,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? p.brandSoft : Colors.transparent,
                  borderRadius: AppRadius.pill,
                ),
                child: Icon(selected ? spec.activeIcon : spec.icon,
                    color: color, size: 22),
              ),
              const SizedBox(height: 3),
              // `AnimatedDefaultTextStyle` üst stili BİRLEŞTİRMEZ, değiştirir:
              // yazı tipi ailesi burada verilmezse etiketler Inter yerine
              // platformun varsayılan yazı tipiyle çiziliyordu.
              AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: appBody(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
