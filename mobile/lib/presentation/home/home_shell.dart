// =============================================================================
// Ana Kabuk — sekmeli gezinme
// Dosya: mobile/lib/presentation/home/home_shell.dart
//
// DÜZELTİLEN YAPISAL HATA
// -----------------------
// Önceki sürümde alt çubuk `Stack` içinde `Positioned` ile içeriğin ÜSTÜNE
// çiziliyordu. Sekme ekranları bunu bilmediği için her biri listesinin altına
// elle 120 px boşluk koymak zorundaydı — koyanlar da vardı koymayanlar da.
// Sonuç: bazı ekranlarda son satır çubuğun altında kalıyor, dokunulamıyordu.
//
// Artık çubuk `Scaffold.bottomNavigationBar` olarak veriliyor. Flutter kalan
// yüksekliği kendisi hesaplıyor; ekranlar sihirli sayı taşımıyor.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';
import '../call/calls_history_screen.dart';
import '../civility/civility_composer_screen.dart';
import '../contacts/contacts_screen.dart';
import '../conversations/conversations_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex = widget.initialIndex;

  static const List<Widget> _screens = [
    ConversationsScreen(),
    CivilityComposerScreen(),
    CallsHistoryScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  static const List<_NavSpec> _items = [
    _NavSpec(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Sohbetler'),
    _NavSpec(Icons.shield_outlined, Icons.shield_rounded, 'Nezaket'),
    _NavSpec(Icons.call_outlined, Icons.call_rounded, 'Aramalar'),
    _NavSpec(Icons.people_outline_rounded, Icons.people_rounded, 'Kişiler'),
    _NavSpec(Icons.settings_outlined, Icons.settings_rounded, 'Ayarlar'),
  ];

  final int _unreadCount = 3;

  void _select(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        // Klavye açıldığında alt çubuğun yukarı fırlamasını önler.
        resizeToAvoidBottomInset: false,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          items: _items,
          badges: {0: _unreadCount},
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

/// Özel alt çubuk.
///
/// `NavigationBar` yerine elle çizildi çünkü rozetin ikonla birlikte
/// ölçeklenmesi ve seçili sekmedeki hap biçimli vurgu Material'ın
/// varsayılanıyla mümkün değildi. Dokunma hedefleri 48 px'in altına inmiyor.
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onSelect,
    this.badges = const {},
  });

  final int currentIndex;
  final List<_NavSpec> items;
  final ValueChanged<int> onSelect;
  final Map<int, int> badges;

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
                    badgeCount: badges[i] ?? 0,
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
    this.badgeCount = 0,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.brandInk : p.textTertiary;

    return Semantics(
      selected: selected,
      button: true,
      label: spec.label,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? p.brandSoft : Colors.transparent,
                borderRadius: AppRadius.pill,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(selected ? spec.activeIcon : spec.icon,
                      color: color, size: 23),
                  if (badgeCount > 0)
                    Positioned(
                      top: -5,
                      right: -9,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: badgeCount > 9 ? 4 : 0),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: p.brand,
                          borderRadius: AppRadius.pill,
                          border: Border.all(color: p.surface, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: TextStyle(
                            color: p.brandOn,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(spec.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sekme ekranlarının liste altına bırakması gereken boşluk.
///
/// Artık `Scaffold` alt çubuğu kendisi hesapladığı için bu sıfırdır; sabit
/// yalnızca eski çağrı yerlerini tek noktadan nötrlemek için duruyor.
const double kBottomNavClearance = AppSpacing.base;

/// Boş liste durumlarında kullanılmak üzere yeniden dışa açılır.
typedef HomeEmptyState = AppEmptyState;
