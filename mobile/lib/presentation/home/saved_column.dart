// =============================================================================
// Kaydedilenler sütunu
// Dosya: mobile/lib/presentation/home/saved_column.dart
//
// Mobil kabukta kaydedilenler profil sekmesinin üçüncü sekmesidir; masaüstü
// sol sütununda kendi hedefi vardır çünkü orada yer var ve iki tık yerine
// bir tık ediyor. Veri aynı yerden okunur (`SocialStore.bookmarks`) —
// mobilde kaydedilen gönderi burada da görünür.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';
import '../feed/post_card.dart';
import '../feed/post_detail_screen.dart';

class SavedColumn extends StatelessWidget {
  const SavedColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = SocialStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final posts = store.bookmarks;

        return ListView(
          padding: const EdgeInsets.only(
              top: AppSpacing.lg, bottom: AppSpacing.xxxl),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Kaydedilenler',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (posts.isEmpty)
              const AppEmptyState(
                icon: Icons.bookmark_border_rounded,
                title: 'Henüz bir gönderi kaydetmedin',
                message: 'Akıştaki bir gönderinin yer imi simgesine '
                    'dokunduğunda burada görünür.',
              )
            else
              for (final post in posts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: p.border),
                      boxShadow: p.cardShadow,
                    ),
                    child: PostCard(
                      post: post,
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PostDetailScreen(postId: post.id),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
