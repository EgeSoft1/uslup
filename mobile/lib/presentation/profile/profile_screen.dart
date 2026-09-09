// =============================================================================
// Profil
// Dosya: mobile/lib/presentation/profile/profile_screen.dart
//
// Ev sahibi platformun profil ekranı — ve içinde ürünün TEK kişisel geri
// bildirim yüzeyi: "Üslup özeti".
//
// ── ÖZET NEDEN BURADA VE NEDEN GİZLİ ──────────────────────────────────────
// Kullanıcının kaç kez uyarı alıp metnini düzelttiği, yalnızca kendisine
// gösterilir. Akışta rozetlenmez, başkasının profilinde görünmez, hiçbir
// yere gönderilmez.
//
// Gerekçe ürünün etik omurgasıdır: müdahale bir CEZA değil bir DURAKSAMADIR.
// Görünür bir rozet, duraksamayı bir damgaya çevirir; damgalanan kullanıcı
// bir daha uyarılmamak için özelliği kapatır ve ürün, korumayı en çok
// gereken kişiyi kaybeder.
//
// Aynı sayı, topluluk sağlığı panelinde k-anonimlik eşiğinin ardında
// TOPLULAŞTIRILMIŞ olarak da görünür. Orada kimse tek tek görünmez.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/community/community_health_store.dart';
import '../../core/social/seed_data.dart';
import '../../core/social/social_models.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../feed/post_card.dart';
import '../feed/post_detail_screen.dart';
import '../settings/about_screen.dart';
import '../widgets/social_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final SocialStore _store = SocialStore.instance;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openPost(SocialPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(postId: post.parentId ?? post.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => NestedScrollView(
          headerSliverBuilder: (context, innerScrolled) => [
            SliverToBoxAdapter(child: _header(p)),
            SliverToBoxAdapter(child: _uslupSummary(p)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeader(
                child: DecoratedBox(
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
                      Tab(height: 44, text: 'Gönderiler'),
                      Tab(height: 44, text: 'Yanıtlar'),
                      Tab(height: 44, text: 'Kaydedilenler'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              _postList(p, _store.myPosts, 'Henüz gönderi paylaşmadın.'),
              _postList(p, _store.myReplies, 'Henüz bir yanıt yazmadın.'),
              _postList(p, _store.bookmarks,
                  'Kaydettiğin gönderiler burada görünür.'),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Başlık ───────────────────────────────────────────────────────────────

  Widget _header(AppPalette p) {
    const me = SeedData.currentUser;

    return Container(
      color: p.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kapak — marka gradyanı. Fotoğraf indirilmez.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 108,
                decoration: BoxDecoration(gradient: p.brandGradient),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      _CoverAction(
                        icon: p.isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        tooltip: 'Temayı değiştir',
                        onTap: () =>
                            ThemeController.instance.toggle(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CoverAction(
                        icon: Icons.info_outline_rounded,
                        tooltip: 'Proje hakkında',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AboutScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.base,
                bottom: -34,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration:
                      BoxDecoration(color: p.surface, shape: BoxShape.circle),
                  child: const UserAvatar(author: me, size: 76),
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me.displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  '@${me.handle}',
                  style: TextStyle(fontSize: 14, color: p.textTertiary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  me.bio,
                  style: TextStyle(
                      fontSize: 14, color: p.textSecondary, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _stat(p, _store.myPosts.length + me.postCount, 'gönderi'),
                    const SizedBox(width: AppSpacing.lg),
                    _stat(p, me.following, 'takip'),
                    const SizedBox(width: AppSpacing.lg),
                    _stat(p, me.followers, 'takipçi'),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(AppPalette p, int value, String label) {
    return Row(
      children: [
        Text(
          kisaSayi(value),
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13.5, color: p.textTertiary)),
      ],
    );
  }

  // ─── Üslup özeti ──────────────────────────────────────────────────────────

  Widget _uslupSummary(AppPalette p) {
    final duzeltme = _store.revisedThisSession;
    final ragmen = _store.sentDespiteWarningThisSession;
    final toplam = _store.sentThisSession;
    final mudahale = duzeltme + ragmen;

    return Container(
      color: p.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: p.brandSoft,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: p.brandInk.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BrandMark(size: 26),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Üslup özeti',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                AppBadgePill(
                  label: 'yalnızca sen',
                  color: p.textTertiary,
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (toplam == 0)
              Text(
                'Bu oturumda henüz gönderi paylaşmadın. Bir gönderi ya da '
                'yanıt yazdığında Üslup\'un ne yaptığı burada özetlenir.',
                style: TextStyle(
                    fontSize: 13, color: p.textSecondary, height: 1.45),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _summaryTile(
                      p,
                      value: '$toplam',
                      label: 'gönderim',
                      color: p.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _summaryTile(
                      p,
                      value: '$mudahale',
                      label: 'müdahale',
                      color: mudahale > 0 ? p.warning : p.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _summaryTile(
                      p,
                      value: '$duzeltme',
                      label: 'düzeltme',
                      color: duzeltme > 0 ? p.success : p.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                mudahale == 0
                    ? 'Bu oturumda hiç uyarı almadın.'
                    : duzeltme == 0
                        ? 'Uyarıları gördün ve gönderdin. Bu senin kararın — '
                            'sistem hiçbir gönderimi engellemedi.'
                        : 'Uyarı aldığın $mudahale gönderimin $duzeltme '
                            'tanesini göndermeden önce düzelttin.',
                style: TextStyle(
                    fontSize: 12.5, color: p.textSecondary, height: 1.45),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: p.brandInk.withValues(alpha: 0.15)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.phonelink_lock_rounded,
                    size: 13, color: p.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bu sayılar cihazdan çıkmadı. Topluluk paneline yalnızca '
                    'k-anonimlik uygulanmış toplamlar gider '
                    '(${CommunityHealthStore.instance.report.kThreshold} '
                    'gözlem altındaki kategoriler açılmaz).',
                    style: TextStyle(
                        fontSize: 11, color: p.textTertiary, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(AppPalette p,
      {required String value, required String label, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11.5, color: p.textTertiary)),
      ],
    );
  }

  // ─── Sekme içerikleri ─────────────────────────────────────────────────────

  Widget _postList(AppPalette p, List<SocialPost> posts, String emptyMessage) {
    if (posts.isEmpty) {
      return Container(
        color: p.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: p.textTertiary),
            ),
          ),
        ),
      );
    }

    return Container(
      color: p.surface,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        itemCount: posts.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: p.divider),
        itemBuilder: (context, index) => PostCard(
          post: posts[index],
          onOpen: () => _openPost(posts[index]),
        ),
      ),
    );
  }
}

// ─── Alt bileşenler ──────────────────────────────────────────────────────────

class _CoverAction extends StatelessWidget {
  const _CoverAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.black.withValues(alpha: 0.28),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              // Dokunma hedefi 40 px; kapak üzerindeki ikonlar için
              // Material'ın 48 px varsayılanı görsel olarak taşıyordu.
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 19, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `TabBar`ı kaydırma sırasında üstte sabitler.
class _TabBarHeader extends SliverPersistentHeaderDelegate {
  const _TabBarHeader({required this.child});

  final Widget child;

  static const double _height = 45;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: _height, child: child);

  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) =>
      oldDelegate.child != child;
}
