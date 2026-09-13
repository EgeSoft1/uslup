// =============================================================================
// Akış sütunu — masaüstü yerleşiminin orta sütunu
// Dosya: mobile/lib/presentation/feed/feed_column.dart
//
// Mobil `FeedScreen` ile aynı veriyi, aynı `SocialStore` örneğini ve aynı
// `PostCard` bileşenini kullanır; ayrıldığı tek yer YERLEŞİMDİR:
//
//   • Üst çubuk yok — gezinme sol sütunda, arama sağ sütunda.
//   • Gönderiler tam genişlik şeritler değil, aralıklı kartlar.
//   • Medya sekmesi listede değil ızgarada açılır (geniş ekranda tek
//     sütunluk video listesi ekranın yarısını boş bırakıyordu).
//
// Kartların içi yeniden yazılmadı. Yazılsaydı iki gönderi kartı olurdu ve
// biri — test edilmeyen — sessizce eskirdi; bu depoda aynı hata daha önce
// yorum kutusunda yapılmamak için `CivilityComposer` tek bileşen tutuluyor.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/social/seed_data.dart';
import '../../core/social/social_models.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../compose/compose_screen.dart';
import '../widgets/social_widgets.dart';
import 'post_card.dart';
import 'post_detail_screen.dart';

class FeedColumn extends StatelessWidget {
  const FeedColumn({
    super.key,
    required this.mediaTab,
    required this.onTabChanged,
  });

  /// Medya sekmesi açık mı? Durum sol sütundaki anahtarla paylaşılır, bu
  /// yüzden burada tutulmaz — yukarıdan verilir.
  final bool mediaTab;
  final ValueChanged<bool> onTabChanged;

  void _openPost(BuildContext context, SocialPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PostDetailScreen(postId: post.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = SocialStore.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ColumnTabs(mediaTab: mediaTab, onChanged: onTabChanged),
        Expanded(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) => mediaTab
                ? _mediaGrid(context, p, store)
                : _postList(context, p, store),
          ),
        ),
      ],
    );
  }

  // ─── Akış sekmesi ─────────────────────────────────────────────────────────

  Widget _postList(BuildContext context, AppPalette p, SocialStore store) {
    final posts = store.feed;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: posts.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return const _ComposerCard();
        if (index == 1) return _highlights(p);

        final post = posts[index - 2];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _Card(
            child: PostCard(
              post: post,
              onOpen: () => _openPost(context, post),
            ),
          ),
        );
      },
    );
  }

  Widget _highlights(AppPalette p) {
    const hesaplar = SeedData.suggested;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _Card(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: SizedBox(
          height: 84,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: hesaplar.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _storyItem(p, SeedData.currentUser, 'Sen', ring: false);
              }
              final hesap = hesaplar[index - 1];
              return _storyItem(p, hesap, hesap.handle);
            },
          ),
        ),
      ),
    );
  }

  Widget _storyItem(AppPalette p, SocialAuthor author, String label,
      {bool ring = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(author: author, size: 52, ring: ring),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Medya sekmesi ────────────────────────────────────────────────────────

  Widget _mediaGrid(BuildContext context, AppPalette p, SocialStore store) {
    final posts = store.mediaFeed;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _ComposerCard()),
        if (posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Center(
                child: Text(
                  'Henüz medya içeren gönderi yok.',
                  style: TextStyle(color: p.textSecondary),
                ),
              ),
            ),
          )
        else
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.74,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                return _MediaTile(
                  post: post,
                  onTap: () => _openPost(context, post),
                );
              },
              childCount: posts.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }
}

// ─── Sekme çubuğu ────────────────────────────────────────────────────────────

/// İki hedefli sekme çubuğu.
///
/// `TabBar` yerine elle çizildi: burada kaydırılabilir bir `TabBarView` yok
/// (iki sekme farklı kaydırma fizikleri istiyor — liste ve ızgara) ve
/// sekmenin durumu sol sütundaki anahtarla paylaşılıyor. `TabController`
/// bu durumu ikinci bir yerde tutardı.
class _ColumnTabs extends StatelessWidget {
  const _ColumnTabs({required this.mediaTab, required this.onChanged});

  final bool mediaTab;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _tab(p, 'Akış', !mediaTab, () => onChanged(false)),
          ),
          Expanded(
            child: _tab(p, 'Medya', mediaTab, () => onChanged(true)),
          ),
        ],
      ),
    );
  }

  Widget _tab(AppPalette p, String label, bool selected, VoidCallback onTap) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? p.brandInk : p.textTertiary,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.standard,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? p.brandInk : Colors.transparent,
                  borderRadius: AppRadius.pill,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gönderi kutusu kısayolu ─────────────────────────────────────────────────

/// Akışın üstündeki kutu.
///
/// Canlı çözümleme yapan gerçek kutu burada AÇILMAZ; tıklanınca ortada bir
/// iletişim kutusu olarak gelir. Akışın içinde sürekli çözümleyen bir kutu
/// tutmak, kullanıcı yalnızca okurken de motoru çalışır durumda bırakırdı.
class _ComposerCard extends StatelessWidget {
  const _ComposerCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    void open() => ComposeScreen.open(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _Card(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const UserAvatar.currentUser(size: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Gönderi oluştur',
                    child: ExcludeSemantics(
                      child: InkWell(
                        onTap: open,
                        borderRadius: AppRadius.smAll,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Gönderi oluşturmak için…',
                            style: TextStyle(
                                fontSize: 16, color: p.textTertiary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: p.divider, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final icon in const [
                  Icons.image_outlined,
                  Icons.bar_chart_rounded,
                  Icons.info_outline_rounded,
                  Icons.event_outlined,
                  Icons.emoji_emotions_outlined,
                ])
                  IconButton(
                    onPressed: open,
                    icon: Icon(icon, size: 20),
                    color: p.textTertiary,
                    tooltip: 'Gönderi kutusunu aç',
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                _GradientPill(label: 'Gönder', onTap: open),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientPill extends StatelessWidget {
  const _GradientPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.pill,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.pill,
            child: Ink(
              decoration: BoxDecoration(
                gradient: p.brandGradient,
                borderRadius: AppRadius.pill,
              ),
              child: Container(
                height: 38,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_rounded,
                        size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Medya kutucuğu ──────────────────────────────────────────────────────────

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.post, required this.onTap});

  final SocialPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final attachment = post.attachment;
    final isVideo = attachment.kind == PostAttachmentKind.video;
    final isPoll = attachment.kind == PostAttachmentKind.anket;

    return Semantics(
      button: true,
      label: '${post.author.displayName}: ${attachment.label}',
      child: ExcludeSemantics(
        child: Material(
          color: p.surface,
          borderRadius: AppRadius.lgAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: attachment.tint.length >= 2
                          ? attachment.tint
                          : [p.brand, p.brandInk],
                    ),
                  ),
                ),
                // Alt kenardaki koyu geçiş, üzerine yazılan beyaz metnin
                // kontrastını her gradyan tonunda garanti eder.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                    ),
                  ),
                ),
                if (isVideo || isPoll)
                  Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.34),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75),
                            width: 1.5),
                      ),
                      child: Icon(
                        isPoll
                            ? Icons.bar_chart_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: Row(
                    children: [
                      UserAvatar(author: post.author, size: 22),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          post.author.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(blurRadius: 6, color: Color(0x99000000)),
                            ],
                          ),
                        ),
                      ),
                      if (post.author.verified) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.verified_rounded,
                            size: 13, color: Colors.white),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attachment.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (attachment.duration != null) ...[
                            _chip(attachment.duration!),
                            const SizedBox(width: 4),
                          ],
                          _chip('temsilî'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: AppRadius.xsAll,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Kart yüzeyi ─────────────────────────────────────────────────────────────

/// Masaüstü sütunundaki beyaz kart.
///
/// `AppCard` kullanılmadı: o bileşen kendi `InkWell`ini kurar ve içindeki
/// `PostCard`ın kendi dokunma alanını yutardı — gönderiye tıklamak
/// ayrıntıyı açmaz, yalnızca kartı dalgalandırırdı.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      padding: padding,
      child: child,
    );
  }
}
