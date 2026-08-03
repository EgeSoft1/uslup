// =============================================================================
// Aktif Oturumlar
// Dosya: mobile/lib/presentation/settings/active_sessions_screen.dart
//
// DÜZELTİLENLER
//   • "Sonlandır" onay veriyor, bildirim gösteriyor ama oturumu listeden
//     KALDIRMIYORDU — ekran `StatelessWidget` olduğu için kaldıramazdı da.
//     Kullanıcı güvenlik önlemi aldığını sanıp cihazı listede görmeye
//     devam ediyordu. Güvenlik ekranında bu ciddi bir yanılsama.
//   • "Tümünü Sonlandır", diğer oturum kalmadığında da görünüyordu.
//   • Renkler paletten okunur.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';

class DeviceSession {
  const DeviceSession({
    required this.icon,
    required this.deviceName,
    required this.location,
    required this.lastActive,
    this.isActive = false,
    this.isCurrent = false,
  });

  final IconData icon;
  final String deviceName;
  final String location;
  final String lastActive;
  final bool isActive;
  final bool isCurrent;
}

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  static const _current = DeviceSession(
    icon: Icons.phone_android_rounded,
    deviceName: 'Samsung Galaxy S24 Ultra',
    location: 'İstanbul, Türkiye',
    lastActive: 'Şu an aktif',
    isActive: true,
    isCurrent: true,
  );

  final List<DeviceSession> _others = [
    const DeviceSession(
      icon: Icons.laptop_mac_rounded,
      deviceName: 'MacBook Pro',
      location: 'İstanbul, Türkiye',
      lastActive: '2 saat önce',
    ),
    const DeviceSession(
      icon: Icons.tablet_mac_rounded,
      deviceName: 'iPad Air',
      location: 'Ankara, Türkiye',
      lastActive: '3 gün önce',
    ),
  ];

  Future<bool> _confirm(String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Oturumu sonlandır'),
        content: Text('$label sonlandırmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.palette.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sonlandır'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _endSession(DeviceSession session) async {
    if (!await _confirm('${session.deviceName} oturumunu')) return;
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    // DÜZELTME: eskiden yalnızca bildirim gösteriliyor, oturum listede kalıyordu.
    setState(() => _others.remove(session));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${session.deviceName} oturumu sonlandırıldı.')),
    );
  }

  Future<void> _endAll() async {
    if (!await _confirm('diğer tüm oturumları')) return;
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(_others.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diğer tüm oturumlar sonlandırıldı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppTopBar(
        title: 'Aktif Oturumlar',
        subtitle: '${_others.length + 1} cihaz',
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.xxl),
        children: [
          const AppSectionHeader(
            title: 'Bu cihaz',
            padding: EdgeInsets.fromLTRB(
                AppSpacing.xs, AppSpacing.sm, AppSpacing.xs, AppSpacing.md),
          ),
          const _SessionCard(session: _current)
              .animate()
              .fadeIn(duration: 320.ms)
              .slideY(begin: 0.06, end: 0),

          const SizedBox(height: AppSpacing.xl),

          AppSectionHeader(
            title: 'Diğer oturumlar',
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.md),
            trailing: _others.isEmpty
                ? null
                : TextButton(
                    onPressed: _endAll,
                    style: TextButton.styleFrom(
                      foregroundColor: p.danger,
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Tümünü sonlandır'),
                  ),
          ),

          if (_others.isEmpty)
            const AppEmptyState(
              icon: Icons.verified_user_rounded,
              title: 'Başka açık oturum yok',
              message: 'Hesabına yalnızca bu cihazdan erişiliyor.',
            ).animate().fadeIn()
          else
            for (var i = 0; i < _others.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                child: _SessionCard(
                  session: _others[i],
                  onEnd: () => _endSession(_others[i]),
                ),
              )
                  .animate()
                  .fadeIn(delay: (60 * i).ms)
                  .slideY(begin: 0.06, end: 0),

          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: p.warningSoft,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: p.warning, size: 19),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Tanımadığın bir oturum görürsen hemen "Sonlandır"a bas ve '
                    'şifreni değiştir.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: p.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 220.ms),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, this.onEnd});

  final DeviceSession session;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = session.isCurrent ? p.success : p.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: session.isCurrent
              ? p.success.withValues(alpha: 0.4)
              : p.border,
          width: session.isCurrent ? 1.5 : 1,
        ),
        boxShadow: p.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: p.isDark ? 0.20 : 0.11),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(session.icon, color: tint, size: 23),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.deviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 12, color: p.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          session.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: p.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.lastActive,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: session.isActive ? p.success : p.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (!session.isCurrent && onEnd != null)
              TextButton(
                onPressed: onEnd,
                style: TextButton.styleFrom(
                  foregroundColor: p.danger,
                  backgroundColor: p.dangerSoft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  minimumSize: const Size(0, 36),
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                child: const Text('Sonlandır'),
              ),
          ],
        ),
      ),
    );
  }
}
