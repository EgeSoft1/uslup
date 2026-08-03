// =============================================================================
// Engellenen Kişiler
// Dosya: mobile/lib/presentation/settings/blocked_contacts_screen.dart
//
// DÜZELTİLENLER
//   • "Engeli Kaldır" ve "Yeni Kişi Engelle" düğmelerinin ikisi de
//     `onTap: () {}` idi — basılıyor, hiçbir şey olmuyordu.
//   • Ekran `StatelessWidget`'tı, dolayısıyla listeyi değiştirmek zaten
//     mümkün değildi.
//   • Liste boşalınca bomboş beyaz kart kalıyordu; boş durum eklendi.
//   • Renkler paletten okunur.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_surfaces.dart';

class BlockedContact {
  const BlockedContact(this.name, this.phone, {this.avatarUrl});

  final String name;
  final String phone;
  final String? avatarUrl;
}

class BlockedContactsScreen extends StatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  State<BlockedContactsScreen> createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends State<BlockedContactsScreen> {
  final List<BlockedContact> _blocked = [
    const BlockedContact('Mehmet Y.', '+90 532 111 22 33',
        avatarUrl: 'https://i.pravatar.cc/150?img=8'),
    const BlockedContact('Bilinmeyen Numara', '+90 505 444 55 66'),
  ];

  Future<void> _unblock(BlockedContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Engeli kaldır'),
        content: Text(
            '${contact.name} yeniden sana mesaj gönderebilecek ve seni arayabilecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Engeli kaldır'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _blocked.remove(contact));

    // Geri alma sunmak, yanlışlıkla kaldırılan engeli kurtarır.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contact.name} engeli kaldırıldı.'),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () => setState(() => _blocked.add(contact)),
        ),
      ),
    );
  }

  Future<void> _blockNew() async {
    final controller = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yeni kişi engelle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telefon numarası',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (phone == null || phone.isEmpty || !mounted) return;
    setState(() => _blocked.add(BlockedContact('Bilinmeyen Numara', phone)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$phone engellendi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppTopBar(
        title: 'Engellenenler',
        subtitle: _blocked.isEmpty ? null : '${_blocked.length} kişi',
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'Engellenen kişiler seni arayamaz ve sana mesaj gönderemez.',
              style:
                  TextStyle(fontSize: 13, color: p.textSecondary, height: 1.5),
            ),
          ).animate().fadeIn(duration: 320.ms),
          const SizedBox(height: AppSpacing.lg),

          if (_blocked.isEmpty)
            const AppEmptyState(
              icon: Icons.block_rounded,
              title: 'Engellenen kimse yok',
              message: 'Birini engellersen burada görünür.',
            ).animate().fadeIn()
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _blocked.length; i++) ...[
                    if (i > 0)
                      Divider(
                          height: 1,
                          color: p.divider,
                          indent: 72,
                          endIndent: AppSpacing.base),
                    _BlockedTile(
                      contact: _blocked[i],
                      onUnblock: () => _unblock(_blocked[i]),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06, end: 0),

          const SizedBox(height: AppSpacing.lg),

          AppCard(
            onTap: _blockNew,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.brandInk.withValues(alpha: p.isDark ? 0.20 : 0.11),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(Icons.person_add_disabled_rounded,
                      color: p.brandInk, size: 22),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    'Yeni kişi engelle',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.brandInk,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.textTertiary),
              ],
            ),
          ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.06, end: 0),
        ],
      ),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.contact, required this.onUnblock});

  final BlockedContact contact;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: contact.avatarUrl,
            name: contact.name,
            size: 44,
            showOnlineDot: false,
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.phone,
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onUnblock,
            style: TextButton.styleFrom(
              foregroundColor: p.textPrimary,
              backgroundColor: p.surfaceMuted,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              minimumSize: const Size(0, 36),
              textStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            child: const Text('Engeli kaldır'),
          ),
        ],
      ),
    );
  }
}
