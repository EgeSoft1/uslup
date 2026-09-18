// =============================================================================
// Gönderi ayrıntısı ve yanıtlar
// Dosya: mobile/lib/presentation/feed/post_detail_screen.dart
//
// ── BU EKRAN NEDEN ÖNEMLİ ─────────────────────────────────────────────────
// Saldırgan dilin büyük kısmı gönderilerde değil, YANITLARDA üretilir.
// İnsan boş bir kutuya oturup hakaret yazmaz; birinin söylediği bir şeye
// sinirlenip yazar. Katman yalnızca gönderi kutusunda çalışsaydı, ürünün
// hedeflediği anın büyük bölümünü ıskalardı.
//
// Yanıt kutusu, gönderi kutusuyla AYNI `CivilityComposer` bileşenidir.
// Farkı yalnızca yerleşimdir: avatar yok, araç çubuğu yok, üç satır.
// Çözümleme, müdahale merdiveni ve ölçüm birebir aynıdır.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/community/community_health_store.dart';
import '../../core/social/social_models.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../compose/civility_composer.dart';
import '../widgets/social_widgets.dart';
import 'post_card.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = SocialStore.instance;

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
          'Gönderi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final post = store.postById(postId);
          if (post == null) {
            return Center(
              child: Text(
                'Bu gönderi artık yok.',
                style: TextStyle(color: p.textSecondary),
              ),
            );
          }

          final replies = store.repliesOf(postId);

          // Masaüstünde ekran kabuk dışında tam sayfa açılır; sınırlanmazsa
          // gönderi ve yanıtlar 1440 px'e yayılıp okunmaz hâle geliyordu.
          // Akış sütunuyla aynı genişlik kullanılır.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.feedColumnMax + AppSpacing.xxl * 2),
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                children: [
                  PostCard(
                    post: post,
                    onReply: () {},
                    threadContinues: replies.isNotEmpty,
                  ),
                  Container(height: 8, color: p.background),
                  _replyBox(context, p, post),
                  Container(height: 8, color: p.background),
                  if (replies.isEmpty)
                    _emptyReplies(p)
                  else ...[
                    SectionLabel(text: '${replies.length} YANIT'),
                    for (var i = 0; i < replies.length; i++) ...[
                      PostCard(
                        post: replies[i],
                        dense: true,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PostDetailScreen(postId: replies[i].id),
                          ),
                        ),
                      ),
                      if (i < replies.length - 1)
                        Divider(height: 1, color: p.divider),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Yanıt kutusu ─────────────────────────────────────────────────────────

  Widget _replyBox(BuildContext context, AppPalette p, SocialPost parent) {
    return Container(
      color: p.surface,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: CivilityComposer(
        surface: ComposerSurface.yanit,
        replyingTo: parent.author.handle,
        minLines: 2,
        maxLines: 8,
        showAvatar: true,
        showToolbar: false,
        onSubmit: (result) {
          final messenger = ScaffoldMessenger.of(context);

          SocialStore.instance.publish(
            body: result.text,
            parentId: parent.id,
            revised: result.revised,
            sentDespiteWarning: result.sentDespiteWarning,
          );
          if (result.olcumeDahil) {
            CommunityHealthStore.instance.record(
                result.analysis, result.outcome,
                yanlisAlarm: result.yanlisAlarm);
          }

          FocusScope.of(context).unfocus();

          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(result.revised
                    ? 'Yanıtın gönderildi — düzelttiğin hâliyle.'
                    : 'Yanıtın gönderildi.'),
                duration: const Duration(seconds: 3),
              ),
            );
        },
      ),
    );
  }

  Widget _emptyReplies(AppPalette p) {
    return Container(
      color: p.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 30, color: p.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Henüz yanıt yok.',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'İlk yanıtı sen yaz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textTertiary),
          ),
        ],
      ),
    );
  }
}
