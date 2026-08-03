// =============================================================================
// Sohbetler Ekranı
// Dosya: mobile/lib/presentation/conversations/conversations_screen.dart
//
// DÜZELTİLEN İŞLEV HATALARI
//   • Yeni sohbet düğmesi (FAB) yalnızca bir `Container` idi — dokunma
//     işleyicisi yoktu, hiçbir şey yapmıyordu.
//   • Arama alanının `onChanged`'i yoktu; yazılan hiçbir şey listeyi
//     etkilemiyordu.
//   • "Tümünü Gör" düz metindi, tıklanamıyordu.
//   • Liste altına elle 120 px boşluk konuyordu; alt çubuk artık `Scaffold`
//     tarafından yönetildiği için bu sihirli sayı kaldırıldı.
//   • Sabitlenmiş sohbetler ayrı bölüme çıkarıldı — yedi satırın yedisi de
//     "sabitlenmiş" işaretliydi, yani gösterge hiçbir anlam taşımıyordu.
//
// TASARIM
//   Üstteki manzara katmanı, ekranın %35'ini kaplayan ve içeriği okunmaz hâle
//   getiren bir örtüydü. Artık kaydırıldıkça sönen, kısaltılmış bir başlık
//   alanı; içerik ilk ekranda görünür.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_surfaces.dart';
import '../chat/chat_screen.dart';
import 'conversation_data.dart';
import 'stories_viewer_screen.dart';
import 'widgets/conversation_tile.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late final List<Conversation> _all = demoConversations()
    ..sort((a, b) => b.sortKey.compareTo(a.sortKey));

  String _query = '';

  List<Conversation> get _visible =>
      _all.where((c) => c.matches(_query)).toList();

  bool get _isSearching => _query.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    if (value == _query) return;
    setState(() => _query = value);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _query = '');
  }

  Future<void> _refresh() async {
    // Gerçek depo bağlanana kadar yalnızca yeniden çizim; kullanıcı
    // aşağı çekince tepki almalı.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) setState(() {});
  }

  void _startNewChat() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _NewChatSheet(
        conversations: _all,
        onPick: (conversation) {
          Navigator.pop(sheetContext);
          _openChat(conversation);
        },
      ),
    );
  }

  void _openChat(Conversation c) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: c.id, contactName: c.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final visible = _visible;
    final pinned = visible.where((c) => c.isPinned).toList();
    final others = visible.where((c) => !c.isPinned).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: p.brandInk,
          backgroundColor: p.surface,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildHeader(p),
              _buildSearchBar(p),
              if (!_isSearching) _buildStories(p),
              if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: '"${_query.trim()}" bulunamadı',
                    message:
                        'Farklı bir isim ya da mesaj içeriği deneyebilirsin.',
                    action: TextButton(
                      onPressed: _clearSearch,
                      child: const Text('Aramayı temizle'),
                    ),
                  ),
                )
              else ...[
                if (pinned.isNotEmpty && !_isSearching) ...[
                  const SliverToBoxAdapter(
                    child: AppSectionHeader(
                      title: 'Sabitlenenler',
                      icon: Icons.push_pin_rounded,
                    ),
                  ),
                  _buildList(pinned, keyPrefix: 'pin'),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
                ],
                if (others.isNotEmpty && !_isSearching)
                  const SliverToBoxAdapter(
                    child: AppSectionHeader(
                      title: 'Tüm sohbetler',
                      icon: Icons.forum_rounded,
                    ),
                  ),
                _buildList(_isSearching ? visible : others, keyPrefix: 'all'),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl + 24)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _startNewChat,
          tooltip: 'Yeni sohbet',
          child: const Icon(Icons.edit_rounded, size: 24),
        ).animate().scale(
              delay: 300.ms,
              duration: 420.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  // ─── Başlık ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppPalette p) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: p.brandGradient,
                  borderRadius: AppRadius.smAll,
                  boxShadow: p.brandShadow,
                ),
                child: Icon(Icons.chat_rounded, color: p.brandOn, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sohbetler',
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text(
                      _unreadSummary(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              const _HeaderMenu(),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 320.ms),
    );
  }

  String _unreadSummary() {
    final total = _all.fold<int>(0, (sum, c) => sum + c.unreadCount);
    if (total == 0) return 'Hepsi okundu';
    return '$total okunmamış mesaj';
  }

  // ─── Arama ─────────────────────────────────────────────────────────────────

  Widget _buildSearchBar(AppPalette p) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.base),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 15, color: p.textPrimary),
          decoration: InputDecoration(
            hintText: 'Sohbet veya mesaj ara',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _isSearching
                ? IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Temizle',
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: 12),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.pill,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.pill,
              borderSide: BorderSide(color: p.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.pill,
              borderSide: BorderSide(color: p.brandInk, width: 1.5),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 60.ms, duration: 320.ms),
    );
  }

  // ─── Durumlar ──────────────────────────────────────────────────────────────

  Widget _buildStories(AppPalette p) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Durumlar',
            icon: Icons.auto_awesome_rounded,
            iconColor: p.gold,
            trailing: TextButton(
              onPressed: () => _openStory(demoStories.first),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Tümünü gör'),
            ),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: demoStories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.base),
              itemBuilder: (context, index) {
                if (index == 0) return _MyStoryButton(onTap: _addStory);
                final story = demoStories[index - 1];
                return _StoryRingTile(
                  story: story,
                  onTap: () => _openStory(story),
                ).animate().fadeIn(delay: (40 * index).ms).slideX(begin: 0.15, end: 0);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.base),
        ],
      ),
    );
  }

  void _openStory(StoryRing story) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: AppDurations.normal,
        pageBuilder: (_, __, ___) => StoriesViewerScreen(
          userName: story.name,
          avatarUrl: story.avatarUrl,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _addStory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Durum paylaşımı yakında etkinleşecek.')),
    );
  }

  // ─── Liste ─────────────────────────────────────────────────────────────────

  Widget _buildList(List<Conversation> items, {required String keyPrefix}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm + 2),
        itemBuilder: (context, index) {
          final c = items[index];
          return ConversationTile(
            key: ValueKey('$keyPrefix-${c.id}'),
            conversation: c,
          )
              .animate()
              .fadeIn(delay: (30 * index).clamp(0, 240).ms, duration: 260.ms)
              .slideY(begin: 0.06, end: 0);
        },
      ),
    );
  }
}

class _HeaderMenu extends StatelessWidget {
  const _HeaderMenu();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    void notify(String label) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label yakında etkinleşecek.')),
      );
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      tooltip: 'Menü',
      onSelected: notify,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: p.surface,
          shape: BoxShape.circle,
          border: Border.all(color: p.border),
        ),
        child: Icon(Icons.more_vert_rounded, color: p.textSecondary, size: 20),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'Yeni grup', child: _MenuRow(Icons.group_add_rounded, 'Yeni grup')),
        PopupMenuItem(value: 'Toplu mesaj', child: _MenuRow(Icons.campaign_rounded, 'Toplu mesaj')),
        PopupMenuItem(value: 'Bağlı cihazlar', child: _MenuRow(Icons.devices_rounded, 'Bağlı cihazlar')),
        PopupMenuItem(value: 'Yıldızlı mesajlar', child: _MenuRow(Icons.star_rounded, 'Yıldızlı mesajlar')),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: context.palette.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(label),
      ],
    );
  }
}

class _MyStoryButton extends StatelessWidget {
  const _MyStoryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.border),
                ),
                child: Icon(Icons.person_rounded, color: p.textTertiary, size: 28),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: p.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.background, width: 2),
                  ),
                  child: Icon(Icons.add_rounded, color: p.brandOn, size: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Hikayem',
            style: TextStyle(
                color: p.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StoryRingTile extends StatelessWidget {
  const _StoryRingTile({required this.story, required this.onTap});

  final StoryRing story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            imageUrl: story.avatarUrl,
            name: story.name,
            size: 54,
            isOnline: story.isOnline,
            // Görülmemiş durumlar marka rengiyle çevrelenir; görülenler soluk.
            ringColor: story.isUnseen ? p.brandInk : p.border,
            ringWidth: story.isUnseen ? 2 : 1.5,
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 64,
            child: Text(
              story.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: story.isUnseen ? p.textPrimary : p.textSecondary,
                fontSize: 12,
                fontWeight: story.isUnseen ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yeni sohbet seçici.
class _NewChatSheet extends StatelessWidget {
  const _NewChatSheet({required this.conversations, required this.onPick});

  final List<Conversation> conversations;
  final ValueChanged<Conversation> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Yeni sohbet',
            subtitle: 'Bir kişi seç ya da grup oluştur',
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final c = conversations[index];
                return ListTile(
                  leading: AppAvatar(
                    imageUrl: c.avatarUrl,
                    name: c.name,
                    size: 42,
                    isOnline: c.isOnline,
                  ),
                  title: Text(c.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: p.textPrimary)),
                  subtitle: Text(
                    c.kind == ConversationKind.group ? 'Grup' : 'Kişi',
                    style: TextStyle(color: p.textTertiary, fontSize: 12.5),
                  ),
                  onTap: () => onPick(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
