// =============================================================================
// Profilim
// Dosya: mobile/lib/presentation/profile/profile_screen.dart
//
// DÜZELTİLENLER
//   • Başlıktaki isim sabit "Ahmet Yılmaz" yazıyordu; alttaki isim alanını
//     düzenlemek onu değiştirmiyordu. İki yer aynı kaynağı okumuyordu.
//   • Kamera düğmesi, QR kartı, "Çıkış Yap" ve "Hesabı Sil" satırlarının
//     hiçbirinde dokunma işleyicisi yoktu — dördü de ölü süstü.
//     "Hesabı Sil" gibi geri alınamaz bir işlem artık iki adımlı onay ister.
//   • Değişiklikler kaydedilmiyordu; kaydet düğmesi eklendi.
//   • Renkler paletten okunur.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_surfaces.dart';
import '../contacts/qr_scanner_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _initialName = 'Ahmet Yılmaz';
  static const _initialAbout = 'Hayat kısa, gülümse 🌟';
  static const _phone = '+90 532 XXX XX XX';
  static const _avatarUrl = 'https://i.pravatar.cc/150?img=11';

  final _nameController = TextEditingController(text: _initialName);
  final _aboutController = TextEditingController(text: _initialAbout);

  String _displayName = _initialName;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    _aboutController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final dirty = _nameController.text != _displayName ||
        _aboutController.text != _initialAbout;
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsim boş bırakılamaz.')),
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      // Başlık artık düzenlenen değeri gösteriyor.
      _displayName = name;
      _dirty = false;
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil güncellendi.')),
    );
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text(
            'Bu cihazdaki oturumun kapatılacak. Tekrar giriş yapman gerekecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _notify('Oturum kapatma backend bağlandığında etkinleşecek.');
    }
  }

  /// Geri alınamaz işlem: tek onay yetmez, kullanıcı adını yazarak doğrular.
  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final p = dialogContext.palette;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            icon: Icon(Icons.warning_amber_rounded, color: p.danger, size: 28),
            title: const Text('Hesabı kalıcı olarak sil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tüm sohbetlerin, kişilerin ve ayarların silinir. '
                  'Bu işlem geri alınamaz.',
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Onaylamak için "$_displayName" yaz:',
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(isDense: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: p.danger),
                onPressed: controller.text.trim() == _displayName
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Sil'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();

    if (confirmed == true && mounted) {
      _notify('Hesap silme backend bağlandığında etkinleşecek.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        appBar: AppTopBar(
          title: 'Profilim',
          actions: [
            if (_dirty)
              TextButton(
                onPressed: _save,
                style: TextButton.styleFrom(
                  foregroundColor: p.brandInk,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: const Text('Kaydet'),
              ),
          ],
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            // ── Üst kart ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: AppSpacing.xl, bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(bottom: BorderSide(color: p.divider)),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppAvatar(
                        imageUrl: _avatarUrl,
                        name: _displayName,
                        size: 104,
                        showOnlineDot: false,
                        ringColor: p.brandInk,
                        ringWidth: 2.5,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () =>
                              _notify('Fotoğraf değiştirme yakında etkinleşecek.'),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: p.brand,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.surface, width: 3),
                            ),
                            child: Icon(Icons.camera_alt_rounded,
                                color: p.brandOn, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 380.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: AppSpacing.base),
                  Text(_displayName,
                      style: Theme.of(context).textTheme.headlineSmall)
                      .animate()
                      .fadeIn(delay: 80.ms),
                  const SizedBox(height: 2),
                  Text(
                    _phone,
                    style: TextStyle(fontSize: 13.5, color: p.textSecondary),
                  ).animate().fadeIn(delay: 120.ms),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Düzenlenebilir bilgiler ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _EditableField(
                      icon: Icons.person_rounded,
                      tint: p.brandInk,
                      label: 'İsim',
                      controller: _nameController,
                      maxLength: 40,
                    ),
                    Divider(
                        height: 1,
                        color: p.divider,
                        indent: 64,
                        endIndent: AppSpacing.base),
                    _EditableField(
                      icon: Icons.info_outline_rounded,
                      tint: p.info,
                      label: 'Hakkımda',
                      controller: _aboutController,
                      maxLength: 90,
                    ),
                    Divider(
                        height: 1,
                        color: p.divider,
                        indent: 64,
                        endIndent: AppSpacing.base),
                    _ReadOnlyField(
                      icon: Icons.phone_rounded,
                      tint: p.success,
                      label: 'Telefon',
                      value: _phone,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: AppSpacing.lg),

            // ── QR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: AppCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const QrScannerScreen()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: p.brandInk
                            .withValues(alpha: p.isDark ? 0.20 : 0.11),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(Icons.qr_code_2_rounded,
                          color: p.brandInk, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('QR Kodum',
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Kodunu paylaşarak hızlı kişi ekle',
                              style: TextStyle(
                                  fontSize: 12, color: p.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textTertiary),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: AppSpacing.lg),

            // ── Hesap işlemleri ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _DangerTile(
                      icon: Icons.logout_rounded,
                      tint: p.warning,
                      title: 'Çıkış yap',
                      subtitle: 'Bu cihazdaki oturumu kapat',
                      onTap: _signOut,
                    ),
                    Divider(
                        height: 1,
                        color: p.divider,
                        indent: 64,
                        endIndent: AppSpacing.base),
                    _DangerTile(
                      icon: Icons.delete_forever_rounded,
                      tint: p.danger,
                      title: 'Hesabı sil',
                      subtitle: 'Kalıcı olarak sil — geri alınamaz',
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.05, end: 0),
          ],
        ),
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.icon,
    required this.tint,
    required this.label,
    required this.controller,
    required this.maxLength,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
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
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: p.textSecondary,
                        fontWeight: FontWeight.w500)),
                TextField(
                  controller: controller,
                  maxLength: maxLength,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_rounded, color: p.textTertiary, size: 17),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.base),
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
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: p.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary)),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: p.textTertiary, size: 16),
        ],
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
                  Text(title,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: tint)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: p.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}
