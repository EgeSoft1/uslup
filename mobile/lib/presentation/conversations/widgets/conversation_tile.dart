// =============================================================================
// Sohbet satırı
// Dosya: mobile/lib/presentation/conversations/widgets/conversation_tile.dart
//
// DÜZELTİLENLER
//   • Okunmamış rozeti `BoxShape.circle` idi; iki haneli sayılarda daire
//     rakamları kırpıyordu. Artık hap biçimli `AppCountBadge`.
//   • `Image.network` her kaydırmada yeniden indiriyordu → `AppAvatar`
//     (disk önbellekli, görsel yoksa baş harf).
//   • Sol dışa taşan `Positioned(left: -12)` gösterge, satırın dokunma
//     alanının dışına düşüyor ve dar ekranlarda kırpılıyordu; grup göstergesi
//     avatarın üstüne alındı.
//   • Renkler paletten okunur — koyu tema kendiliğinden çalışır.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../chat/chat_screen.dart';
import '../conversation_data.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
  });

  final Conversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = conversation;
    final isGroup = c.kind == ConversationKind.group;

    return AppCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md + 2),
      onTap: onTap ??
          () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatScreen(
                    conversationId: c.id,
                    contactName: c.name,
                  ),
                ),
              ),
      child: Row(
        children: [
          _Avatar(conversation: c, isGroup: isGroup),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15.5,
                          fontWeight:
                              c.hasUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (c.isMuted) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.volume_off_rounded,
                          size: 14, color: p.textTertiary),
                    ],
                    if (c.isPinned) ...[
                      const SizedBox(width: 4),
                      Transform.rotate(
                        angle: 0.6,
                        child: Icon(Icons.push_pin_rounded,
                            size: 13, color: p.textTertiary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (c.isDelivered) ...[
                      Icon(Icons.done_all_rounded, size: 15, color: p.info),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        c.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.hasUnread ? p.textSecondary : p.textTertiary,
                          fontSize: 13.5,
                          fontWeight:
                              c.hasUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.time,
                style: TextStyle(
                  color: c.hasUnread ? p.brandInk : p.textTertiary,
                  fontSize: 11.5,
                  fontWeight: c.hasUnread ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              if (c.hasUnread)
                AppCountBadge(
                  count: c.unreadCount,
                  // Sessize alınmış sohbette rozet nötr; kırmızı dikkat
                  // çekmesi gereken yerde anlamını yitirmesin.
                  color: c.isMuted ? p.textTertiary : p.brand,
                )
              else
                const SizedBox(height: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.conversation, required this.isGroup});

  final Conversation conversation;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(
            imageUrl: conversation.avatarUrl,
            name: conversation.name,
            size: 50,
            isOnline: conversation.isOnline && !isGroup,
          ),
          if (isGroup)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: p.surface,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: p.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_rounded,
                      size: 11, color: p.brandInk),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
