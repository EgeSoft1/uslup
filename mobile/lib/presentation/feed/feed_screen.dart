// =============================================================================
// Akış — ev sahibi platformun ana ekranı
// Dosya: mobile/lib/presentation/feed/feed_screen.dart
//
// İki sekme: Akış ve Medya. Üstte gönderi kutusuna giden kısayol, altında
// öne çıkan hesaplar şeridi ve gönderiler.
//
// Üslup katmanı bu ekranda GÖRÜNMEZ — ve bu kasıtlıdır. Katman okurken
// değil, yazarken devreye girer. Akışta sürekli bir "korunuyorsunuz" şeridi
// tutmak, ürünü bir güvenlik uygulamasına çevirirdi; oysa iddia şudur:
// kullanıcı katmanı yalnızca ihtiyaç duyduğu anda fark eder.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/social/seed_data.dart';
import '../../core/social/social_models.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../compose/compose_screen.dart';
import '../widgets/social_widgets.dart';
import 'post_card.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.onOpenProfile, this.onOpenNotifications});

  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotifications;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final SocialStore _store = SocialStore.instance;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openComposer() async {
    HapticFeedback.selectionClick();
    await ComposeScreen.open(context);
  }

  void _openPost(SocialPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(postId: post.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(p),
            _tabBar(p),
            Expanded(
              child: ListenableBuilder(
                listenable: _store,
                builder: (context, _) => TabBarView(
                  controller: _tabs,
                  children: [
                    _akisSekmesi(p),
                    _medyaSekmesi(p),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Üst çubuk ────────────────────────────────────────────────────────────

  Widget _topBar(AppPalette p) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: p.surface),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Profilim',
            child: InkWell(
              onTap: widget.onOpenProfile,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: UserAvatar.currentUser(size: 30),
              ),
            ),
          ),
          const Spacer(),
          const BrandMark(size: 30, showWordmark: true),
          const Spacer(),
          ListenableBuilder(
            listenable: _store,
            builder: (context, _) {
              final unread = _store.unreadNotificationCount;
              return Semantics(
                button: true,
                label: unread > 0
                    ? '$unread okunmamış bildirim'
                    : 'Bildirimler',
                child: ExcludeSemantics(
                  child: IconButton(
                    onPressed: widget.onOpenNotifications,
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      backgroundColor: p.brand,
                      textColor: p.brandOn,
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                    color: p.textSecondary,
                    tooltip: 'Bildirimler',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tabBar(AppPalette p) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: TabBar(
        controller: _tabs,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 3,
        labelColor: p.brandInk,
        unselectedLabelColor: p.textTertiary,
        indicatorColor: p.brandInk,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(height: 44, text: 'Akış'),
          Tab(height: 44, text: 'Medya'),
        ],
      ),
    );
  }

  // ─── Akış sekmesi ─────────────────────────────────────────────────────────

  Widget _akisSekmesi(AppPalette p) {
    final posts = _store.feed;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: posts.isEmpty ? 3 : posts.length + 2,
      separatorBuilder: (context, index) =>
          index == 0 ? const SizedBox.shrink() : Divider(height: 1, color: p.divider),
      itemBuilder: (context, index) {
        if (index == 0) return _composerShortcut(p);
        if (index == 1) return _oneCikanlar(p);
        
        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded, size: 64, color: p.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text('Henüz gönderi yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('İlk gönderiyi sen oluştur!', style: TextStyle(fontSize: 13, color: p.textTertiary)),
                ],
              ),
            ),
          );
        }

        final post = posts[index - 2];
        return PostCard(
          post: post,
          onOpen: () => _openPost(post),
        );
      },
    );
  }

  /// Gönderi kutusuna kısayol.
  ///
  /// Gerçek yazım kutusu burada AÇILMAZ; tam ekran açılır. Akışın içinde
  /// canlı çözümleme yapan bir kutu tutmak, kullanıcı akışı kaydırırken de
  /// motoru çalışır durumda bırakırdı — tuş vuruşu başına yüzlerce µs,
  /// boşuna harcanacak bir bütçe değil.
  Widget _composerShortcut(AppPalette p) {
    return Container(
      color: p.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.md),
      child: Row(
        children: [
          const UserAvatar.currentUser(size: 38),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Gönderi oluştur',
              child: InkWell(
                onTap: _openComposer,
                borderRadius: AppRadius.pill,
                child: Container(
                  height: 40,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    'Gönderi oluşturmak için…',
                    style: TextStyle(fontSize: 14.5, color: p.textTertiary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _GradientButton(
            label: 'Gönder',
            icon: Icons.edit_rounded,
            onTap: _openComposer,
          ),
        ],
      ),
    );
  }

  Widget _oneCikanlar(AppPalette p) {
    const hesaplar = SeedData.suggested;

    return Container(
      color: p.surface,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      // Sabit 84 px, 1,3× yazı ölçeğinde etiket satırını 3 px taşırıyordu.
      // Avatar sabit, etiket yazı ölçeğiyle büyür; yükseklik de onunla büyür.
      child: SizedBox(
        height: 66 + MediaQuery.textScalerOf(context).scale(18),
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
    );
  }

  Widget _storyItem(AppPalette p, SocialAuthor author, String label,
      {bool ring = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 62,
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

  Widget _medyaSekmesi(AppPalette p) {
    final posts = _store.mediaFeed;

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            'Henüz medya içeren gönderi yok.',
            style: TextStyle(color: p.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: posts.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: p.divider),
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(post: post, onOpen: () => _openPost(post));
      },
    );
  }
}

// ─── Gradyanlı birincil düğme ────────────────────────────────────────────────

/// Ev sahibi platformun "Yeni Gönderi" düğmesinin karşılığı.
///
/// Gradyan yalnızca DOLGU olarak kullanılır ve üzerindeki etiket beyaz +
/// kalındır; camgöbeği ucunda normal ağırlıkta küçük metin, WCAG 1.4.3
/// eşiğini karşılamazdı.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
                height: 40,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: Colors.white),
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
