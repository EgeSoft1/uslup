// =============================================================================
// Sohbet Detayı
// Dosya: mobile/lib/presentation/chat/chat_detail_screen.dart
//
// DÜZELTİLENLER
//   • İki eylem düğmesi de "Ara" etiketini taşıyordu — biri telefon araması,
//     diğeri sohbet içinde metin arama. Yan yana duran iki aynı etiket.
//   • "Şifreleme · Uçtan uca şifreli" satırı doğru değildi: kripto köprüsü
//     sahte (docs/02_TEKNIK_BORC.md §1). Satır gerçek durumu yazıyor.
//   • `Image.network` → `AppAvatar` (önbellek + baş harf yedeği).
//   • Renkler paletten okunur; koyu tema çalışıyor.
//   • Liste altındaki 120 px sihirli boşluk kaldırıldı.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_surfaces.dart';
import '../call/call_screen.dart';
import 'media_viewer_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    this.contactName = 'Ahmet Yılmaz',
    this.avatarUrl = 'https://i.pravatar.cc/150?img=11',
  });

  final String contactName;
  final String avatarUrl;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);
  bool _isMuted = false;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(p)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(child: _buildAboutCard(p)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(child: _buildMediaCard(p)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(child: _buildSettingsCard(p)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(child: _buildDangerCard(p)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  // ─── Başlık ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppPalette p) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    color: p.textPrimary,
                    tooltip: 'Geri',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: p.textSecondary,
                    tooltip: 'Daha fazla',
                    onPressed: _showMoreMenu,
                  ),
                ],
              ),
            ),
            AppAvatar(
              imageUrl: widget.avatarUrl,
              name: widget.contactName,
              size: 92,
              showOnlineDot: false,
              ringColor: p.brandInk,
              ringWidth: 2.5,
            ).animate().scale(duration: 380.ms, curve: Curves.easeOutBack),
            const SizedBox(height: AppSpacing.md),
            Text(widget.contactName,
                    style: Theme.of(context).textTheme.headlineSmall)
                .animate()
                .fadeIn(delay: 80.ms),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: p.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('çevrimiçi',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: p.success,
                        fontWeight: FontWeight.w500)),
              ],
            ).animate().fadeIn(delay: 120.ms),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.call_rounded,
                    // Önceden bu ve arama düğmesi ikisi de "Ara" idi.
                    label: 'Sesli',
                    tint: p.brandInk,
                    onTap: () => _openCall(false),
                  ),
                  _ActionButton(
                    icon: Icons.videocam_rounded,
                    label: 'Görüntülü',
                    tint: p.info,
                    onTap: () => _openCall(true),
                  ),
                  _ActionButton(
                    icon: Icons.search_rounded,
                    label: 'Mesaj ara',
                    tint: p.textSecondary,
                    onTap: () =>
                        _notify('Sohbet içi arama yakında etkinleşecek.'),
                  ),
                  _ActionButton(
                    icon: _isMuted
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_rounded,
                    label: _isMuted ? 'Sessiz' : 'Bildirim',
                    tint: p.warning,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isMuted = !_isMuted);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ─── Kartlar ───────────────────────────────────────────────────────────────

  Widget _buildAboutCard(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HAKKINDA',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.textTertiary,
                    letterSpacing: 0.8)),
            const SizedBox(height: AppSpacing.sm),
            Text('Hayat kısa, gülümse 🌟',
                style: TextStyle(
                    fontSize: 15,
                    color: p.textPrimary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSpacing.base),
            Divider(color: p.divider),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.phone_rounded, color: p.textTertiary, size: 17),
                const SizedBox(width: AppSpacing.md),
                Text('+90 532 XXX XX XX',
                    style: TextStyle(
                        fontSize: 14.5,
                        color: p.textPrimary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMediaCard(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: AppRadius.mdAll,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: p.brand,
                    borderRadius: AppRadius.smAll,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: p.brandOn,
                  unselectedLabelColor: p.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w500),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Medya'),
                    Tab(text: 'Dosyalar'),
                    Tab(text: 'Linkler'),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 210,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMediaGrid(p),
                  const _EmptyTab(
                      icon: Icons.folder_open_rounded,
                      label: 'Paylaşılan dosya yok'),
                  const _EmptyTab(
                      icon: Icons.link_rounded, label: 'Paylaşılan link yok'),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMediaGrid(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MediaViewerScreen(
                  heroTag: 'media_$index',
                  title: widget.contactName,
                  time: 'Bugün, 14:30',
                ),
              ),
            ),
            borderRadius: AppRadius.smAll,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: AppRadius.smAll,
              ),
              child: Center(
                child:
                    Icon(Icons.image_rounded, color: p.textTertiary, size: 28),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsCard(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _Tile(
              icon: Icons.group_rounded,
              tint: p.info,
              title: 'Ortak gruplar',
              subtitle: '2 grup',
              onTap: () => _notify('Ortak gruplar yakında listelenecek.'),
            ),
            Divider(
                height: 1,
                color: p.divider,
                indent: 64,
                endIndent: AppSpacing.base),
            // Doğru olmayan "uçtan uca şifreli" iddiası kaldırıldı.
            _Tile(
              icon: Icons.lock_open_rounded,
              tint: p.warning,
              title: 'Şifreleme',
              subtitle: 'Faz 2\'de etkinleşecek — henüz aktif değil',
              onTap: () => _notify(
                  'Uçtan uca şifreleme bu prototipte henüz etkin değil.'),
            ),
            Divider(
                height: 1,
                color: p.divider,
                indent: 64,
                endIndent: AppSpacing.base),
            _Tile(
              icon: Icons.wallpaper_rounded,
              tint: p.gold,
              title: 'Duvar kâğıdı',
              subtitle: 'Sohbet arka planını değiştir',
              onTap: () => _notify('Duvar kâğıdı seçimi yakında etkinleşecek.'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDangerCard(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _Tile(
              icon: Icons.block_rounded,
              tint: p.danger,
              title: 'Engelle',
              subtitle: '${widget.contactName} sana ulaşamaz',
              titleColor: p.danger,
              onTap: () => _confirmDanger(
                  'Engelle', '${widget.contactName} engellensin mi?'),
            ),
            Divider(
                height: 1,
                color: p.divider,
                indent: 64,
                endIndent: AppSpacing.base),
            _Tile(
              icon: Icons.flag_rounded,
              tint: p.danger,
              title: 'Şikâyet et',
              subtitle: 'Bu kişiyi moderasyona bildir',
              titleColor: p.danger,
              onTap: () =>
                  _confirmDanger('Şikâyet et', 'Şikâyet gönderilsin mi?'),
            ),
            Divider(
                height: 1,
                color: p.divider,
                indent: 64,
                endIndent: AppSpacing.base),
            _Tile(
              icon: Icons.delete_rounded,
              tint: p.danger,
              title: 'Sohbeti sil',
              subtitle: 'Tüm mesajlar bu cihazdan silinir',
              titleColor: p.danger,
              onTap: () => _confirmDanger('Sohbeti sil',
                  'Bu sohbeti cihazından silmek istediğine emin misin?'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // ─── Eylemler ──────────────────────────────────────────────────────────────

  void _openCall(bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CallScreen(
          contactName: widget.contactName,
          avatarUrl: widget.avatarUrl,
          callType: isVideo ? CallType.video : CallType.voice,
        ),
      ),
    );
  }

  void _notify(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _confirmDanger(String action, String content) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(action),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _notify('$action işlemi tamamlandı.');
  }

  void _showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('Sohbeti sabitle'),
              onTap: () {
                Navigator.pop(sheetContext);
                _notify('Sohbet sabitlendi.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper_rounded),
              title: const Text('Duvar kâğıdı'),
              onTap: () {
                Navigator.pop(sheetContext);
                _notify('Duvar kâğıdı seçimi yakında etkinleşecek.');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ─── Alt bileşenler ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: p.isDark ? 0.20 : 0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tint, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: p.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(label,
              style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

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
                          fontWeight: FontWeight.w600,
                          color: titleColor ?? p.textPrimary)),
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
