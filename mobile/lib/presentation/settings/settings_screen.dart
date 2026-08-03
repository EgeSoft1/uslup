// =============================================================================
// Ayarlar Ekranı
// Dosya: mobile/lib/presentation/settings/settings_screen.dart
//
// DÜZELTİLENLER
//   • Ekran kendi `Switch`'ini elle çiziyordu: dokunma alanı yalnızca 52×32 px
//     (Material'ın 48 px asgari hedefinin altında), erişilebilirlik etiketi
//     yok, klavye odağı yok. Artık gerçek `Switch` — tema onu zaten
//     uygulamanın diline uyarlıyor.
//   • Satırlar `GestureDetector` ile sarılıydı: dalga geri bildirimi yoktu,
//     basıldığı belli olmuyordu. `InkWell` ile değiştirildi.
//   • Görünüm bölümü yoktu; koyu tema seçilemiyordu. Eklendi.
//   • Renkler paletten okunur.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_surfaces.dart';
import '../profile/profile_screen.dart';
import 'about_screen.dart';
import 'active_sessions_screen.dart';
import 'blocked_contacts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = true;
  bool _readReceipts = true;
  bool _lastSeen = true;
  bool _profilePhotoVisible = false;

  void _toggle(void Function(bool) apply, bool value) {
    HapticFeedback.selectionClick();
    setState(() => apply(value));
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = AppThemeScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        body: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                    AppSpacing.lg, AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ayarlar',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Hesabını yönet, tercihlerini özelleştir.',
                      style: TextStyle(fontSize: 13, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 320.ms),

            // ── Profil ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: AppCard(
                onTap: () => _open(const ProfileScreen()),
                child: Row(
                  children: [
                    AppAvatar(
                      imageUrl: 'https://i.pravatar.cc/150?img=11',
                      name: 'Ahmet Yılmaz',
                      size: 56,
                      isOnline: true,
                      ringColor: p.brandInk,
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Ahmet Yılmaz',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            '+90 532 XXX XX XX',
                            style: TextStyle(
                                fontSize: 13.5,
                                color: p.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textTertiary),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.08, end: 0),

            const SizedBox(height: AppSpacing.xl),

            // ── Görünüm ──
            const AppSectionHeader(
              title: 'Görünüm',
              subtitle: 'Uygulamanın nasıl göründüğünü seç',
              icon: Icons.palette_rounded,
            ),
            _Group(children: [_ThemeModeRow(controller: theme)])
                .animate()
                .fadeIn(delay: 120.ms)
                .slideY(begin: 0.06, end: 0),

            const SizedBox(height: AppSpacing.lg),

            // ── Güvenlik ──
            AppSectionHeader(
              title: 'Güvenlik ve Gizlilik',
              subtitle: 'Hesabını koru',
              icon: Icons.verified_user_rounded,
              iconColor: p.brandInk,
            ),
            _Group(
              children: [
                _SettingsRow(
                  icon: Icons.fingerprint_rounded,
                  tint: p.brandInk,
                  title: 'Biyometrik Kilit',
                  subtitle: 'Parmak izi veya yüz tanıma ile kilitle',
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: (v) => _toggle((x) => _biometricEnabled = x, v),
                  ),
                  onTap: () =>
                      _toggle((x) => _biometricEnabled = x, !_biometricEnabled),
                ),
                _SettingsRow(
                  icon: Icons.pin_rounded,
                  tint: p.warning,
                  title: 'İki Aşamalı Doğrulama',
                  subtitle: '6 haneli PIN kodu ayarla',
                  trailing: Switch(
                    value: _twoFactorEnabled,
                    onChanged: (v) => _toggle((x) => _twoFactorEnabled = x, v),
                  ),
                  onTap: () =>
                      _toggle((x) => _twoFactorEnabled = x, !_twoFactorEnabled),
                ),
                _SettingsRow(
                  icon: Icons.devices_rounded,
                  tint: p.info,
                  title: 'Oturum Yönetimi',
                  subtitle: 'Aktif cihazlarını yönet',
                  onTap: () => _open(const ActiveSessionsScreen()),
                ),
              ],
            ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: AppSpacing.lg),

            // ── Gizlilik ──
            AppSectionHeader(
              title: 'Gizlilik',
              subtitle: 'Seni kimin ne kadar göreceğini belirle',
              icon: Icons.visibility_off_rounded,
              iconColor: p.info,
            ),
            _Group(
              children: [
                _SettingsRow(
                  icon: Icons.done_all_rounded,
                  tint: p.info,
                  title: 'Okundu Bilgisi',
                  subtitle: 'Mesajların okunduğunu göster',
                  trailing: Switch(
                    value: _readReceipts,
                    onChanged: (v) => _toggle((x) => _readReceipts = x, v),
                  ),
                  onTap: () => _toggle((x) => _readReceipts = x, !_readReceipts),
                ),
                _SettingsRow(
                  icon: Icons.access_time_rounded,
                  tint: p.info,
                  title: 'Son Görülme',
                  subtitle: 'Çevrimiçi durumunu paylaş',
                  trailing: Switch(
                    value: _lastSeen,
                    onChanged: (v) => _toggle((x) => _lastSeen = x, v),
                  ),
                  onTap: () => _toggle((x) => _lastSeen = x, !_lastSeen),
                ),
                _SettingsRow(
                  icon: Icons.account_circle_rounded,
                  tint: p.info,
                  title: 'Profil Fotoğrafı',
                  subtitle: 'Fotoğrafını kimlerin göreceğini seç',
                  trailing: Switch(
                    value: _profilePhotoVisible,
                    onChanged: (v) => _toggle((x) => _profilePhotoVisible = x, v),
                  ),
                  onTap: () => _toggle(
                      (x) => _profilePhotoVisible = x, !_profilePhotoVisible),
                ),
              ],
            ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: AppSpacing.lg),

            // ── Diğer ──
            AppSectionHeader(
              title: 'Diğer',
              subtitle: 'Ekstra özellikler ve uygulama bilgisi',
              icon: Icons.more_horiz_rounded,
              iconColor: p.warning,
            ),
            _Group(
              children: [
                _SettingsRow(
                  icon: Icons.person_off_rounded,
                  tint: p.warning,
                  title: 'Engellenen Kişiler',
                  subtitle: 'Engellediğin hesapları yönet',
                  onTap: () => _open(const BlockedContactsScreen()),
                ),
                _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  tint: p.info,
                  title: 'Hakkında',
                  subtitle: 'Sürüm ve yasal bilgiler',
                  onTap: () => _open(const AboutScreen()),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.06, end: 0),
          ],
        ),
      ),
    );
  }
}

/// Ayar satırlarını saran kart. Aralarına ayırıcı koyar.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: AppRadius.xlAll,
          border: Border.all(color: p.border),
          boxShadow: p.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.xlAll,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: p.divider,
                    indent: 68,
                    endIndent: AppSpacing.base,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: p.isDark ? 0.20 : 0.11),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(icon, color: tint, size: 21),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12, color: p.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            trailing ?? Icon(Icons.chevron_right_rounded, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Açık / Sistem / Koyu seçimi.
class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.brandInk.withValues(alpha: p.isDark ? 0.20 : 0.11),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  p.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: p.brandInk,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tema',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Şu an: ${controller.label}',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 16),
                  label: Text('Açık'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded, size: 16),
                  label: Text('Sistem'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 16),
                  label: Text('Koyu'),
                ),
              ],
              selected: {controller.value},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                HapticFeedback.selectionClick();
                controller.set(selection.first);
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: p.surfaceMuted,
                foregroundColor: p.textSecondary,
                selectedBackgroundColor: p.brandSoft,
                selectedForegroundColor: p.brandInk,
                side: BorderSide(color: p.border),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
