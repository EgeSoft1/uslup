// =============================================================================
// Bildirimler
// Dosya: mobile/lib/presentation/notifications/notifications_screen.dart
//
// Ev sahibi platformun bildirim listesi. Aralarında bir tane de Üslup
// bildirimi vardır ve o, diğerlerinden yapısal olarak ayrıdır:
//
//   • Bir yazarı yoktur — sistemin kendisindendir.
//   • Bir gönderiye götürmez — kişisel bir özettir.
//   • YALNIZCA CİHAZIN SAHİBİNE görünür ve hiçbir yere gönderilmez.
//
// "Bu hafta 3 gönderiyi göndermeden önce düzelttin" cümlesi, ürünün tek
// olumlu geri bildirim kanalıdır. Kasıtlı olarak bir rozet değil bir
// aynadır: paylaşılabilir olsaydı, düzeltmeyen kullanıcı için bir utanç
// kaynağına dönüşürdü.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/social/social_models.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../feed/post_detail_screen.dart';
import '../widgets/social_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SocialStore _store = SocialStore.instance;

  @override
  void initState() {
    super.initState();
    // Ekran açıldıktan sonra okundu işaretlenir; `initState` içinde
    // `notifyListeners` çağırmak, çizim sırasında setState hatası verir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _store.markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: p.divider)),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Geri',
        ),
        title: Text(
          'Bildirimler',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final items = _store.notifications;

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: p.divider),
            itemBuilder: (context, index) =>
                _NotificationRow(notification: items[index]),
          );
        },
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final SocialNotification notification;

  Color _tint(AppPalette p) => switch (notification.kind) {
        NotificationKind.begeni => const Color(0xFFE0245E),
        NotificationKind.yukseltme => p.success,
        NotificationKind.takip => p.brandInk,
        NotificationKind.yanit => p.info,
        NotificationKind.bahsetme => p.info,
        NotificationKind.uslup => p.brandInk,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = _tint(p);
    final isUslup = notification.kind == NotificationKind.uslup;

    return Material(
      color: notification.unread ? p.brandSoft.withValues(alpha: 0.45) : p.surface,
      child: InkWell(
        onTap: notification.postId == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PostDetailScreen(postId: notification.postId!),
                  ),
                ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: p.isDark ? 0.20 : 0.11),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(notification.kind.icon, size: 18, color: tint),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (notification.author != null) ...[
                      Row(
                        children: [
                          UserAvatar(
                              author: notification.author!, size: 22),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              notification.author!.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                          if (notification.author!.verified) ...[
                            const SizedBox(width: 3),
                            const VerifiedMark(size: 13),
                          ],
                          const Spacer(),
                          Text(
                            kisaSure(notification.createdAt),
                            style: TextStyle(
                                fontSize: 11.5, color: p.textTertiary),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            'Üslup',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppBadgePill(
                            label: 'yalnızca sen',
                            color: p.textTertiary,
                            icon: Icons.lock_outline_rounded,
                          ),
                          const Spacer(),
                          Text(
                            kisaSure(notification.createdAt),
                            style: TextStyle(
                                fontSize: 11.5, color: p.textTertiary),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      notification.text,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isUslup ? p.textPrimary : p.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
