// =============================================================================
// Keşfet — arama ve gündem
// Dosya: mobile/lib/presentation/explore/explore_screen.dart
//
// Arama GERÇEKTEN ÇALIŞIR: bellekteki akış üzerinde metin ve hesap araması
// yapar. Çalışmayan bir arama kutusu koymaktansa kapsamı küçük ama gerçek
// olan bir arama koymak, prototipin hangi kısmının sahici olduğu sorusunu
// ortadan kaldırır.
//
// Türkçe küçük harf dönüşümü elle yapılır: Dart'ın `toLowerCase()` işlevi
// 'I' harfini 'i' yapar, oysa Türkçe'de 'ı' olmalıdır. "IŞIK" araması
// "ışık" kelimesini bulamazdı. Aynı tuzak çekirdek motorda da vardı ve
// orada da elle çözülmüştü (`turkish_normalizer.dart`).
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/social/seed_data.dart';
import '../../core/social/social_models.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../feed/post_card.dart';
import '../feed/post_detail_screen.dart';
import '../widgets/social_widgets.dart';

/// Türkçe'ye doğru küçük harf dönüşümü.
String trKucult(String value) {
  const map = {'I': 'ı', 'İ': 'i', 'Ş': 'ş', 'Ğ': 'ğ', 'Ü': 'ü', 'Ö': 'ö', 'Ç': 'ç'};
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final ch = value[i];
    buffer.write(map[ch] ?? ch.toLowerCase());
  }
  return buffer.toString();
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.initialQuery = '',
    this.showSearchBar = true,
  });

  /// Masaüstünde arama kutusu sağ sütunda durur; burada ikinci bir kutu
  /// çizmek aynı işi yapan iki alan gösterirdi.
  final bool showSearchBar;

  /// Masaüstü kabuğunda sağ sütundaki arama kutusundan gelen terim.
  ///
  /// Aramanın iki kutusu var ama tek bir çalıştırıcısı: sağ sütundaki kutu
  /// yalnızca terimi buraya taşır, eşleştirmeyi yine `_results` yapar.
  /// İkinci bir arama yolu yazılsaydı, Türkçe küçük harf dönüşümü gibi
  /// incelikler tek yerde düzeltilemezdi.
  final String initialQuery;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _query =
      TextEditingController(text: widget.initialQuery);
  final SocialStore _store = SocialStore.instance;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<SocialPost> get _results {
    final q = trKucult(_query.text.trim());
    if (q.isEmpty) return const [];
    return _store.feed
        .where((p) =>
            trKucult(p.body).contains(q) ||
            trKucult(p.author.displayName).contains(q) ||
            trKucult(p.author.handle).contains(q))
        .toList();
  }

  void _search(String term) {
    _query.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final searching = _query.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (widget.showSearchBar) _searchBar(p),
            Expanded(
              child: ListenableBuilder(
                listenable: _store,
                builder: (context, _) =>
                    searching ? _resultsView(p) : _discoverView(p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(AppPalette p) {
    return Container(
      color: p.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.md),
      child: TextField(
        controller: _query,
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 15, color: p.textPrimary),
        decoration: InputDecoration(
          hintText: 'Gönderi veya hesap ara',
          isDense: true,
          filled: true,
          fillColor: p.surfaceMuted,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 12),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.textTertiary),
          suffixIcon: _query.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _query.clear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: p.textTertiary,
                  tooltip: 'Temizle',
                ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.pill,
            borderSide: BorderSide(color: p.borderStrong),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.pill,
            borderSide: BorderSide(color: p.borderStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.pill,
            borderSide: BorderSide(color: p.brandInk, width: 2),
          ),
        ),
      ),
    );
  }

  // ─── Arama sonuçları ──────────────────────────────────────────────────────

  Widget _resultsView(AppPalette p) {
    final results = _results;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 34, color: p.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                '"${_query.text.trim()}" için sonuç yok.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Arama yalnızca bu cihazdaki akışta çalışır.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: p.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: results.length + 1,
      separatorBuilder: (_, __) => Divider(height: 1, color: p.divider),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            color: p.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.md),
            child: Text(
              '${results.length} sonuç',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          );
        }
        final post = results[index - 1];
        return PostCard(
          post: post,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PostDetailScreen(postId: post.id),
            ),
          ),
        );
      },
    );
  }

  // ─── Keşfet ana görünümü ──────────────────────────────────────────────────

  Widget _discoverView(AppPalette p) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        const SectionLabel(text: 'GÜNDEM'),
        Container(
          color: p.surface,
          child: Column(
            children: [
              for (var i = 0; i < SeedData.trends.length; i++) ...[
                _TrendRow(
                  rank: i + 1,
                  trend: SeedData.trends[i],
                  onTap: () => _search(SeedData.trends[i].tag),
                ),
                if (i < SeedData.trends.length - 1)
                  Divider(height: 1, indent: 56, color: p.divider),
              ],
            ],
          ),
        ),
        const SectionLabel(text: 'KİŞİ ÖNERİLERİ'),
        Container(
          color: p.surface,
          child: Column(
            children: [
              for (var i = 0; i < SeedData.suggested.length; i++) ...[
                _AccountRow(author: SeedData.suggested[i]),
                if (i < SeedData.suggested.length - 1)
                  Divider(height: 1, indent: 72, color: p.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Gündem satırı ───────────────────────────────────────────────────────────

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.rank,
    required this.trend,
    required this.onTap,
  });

  final int rank;
  final TrendTopic trend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: p.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.md),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trend.category,
                      style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${trend.tag}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${kisaSayi(trend.postCount)} gönderi',
                      style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                    ),
                  ],
                ),
              ),
              if (trend.risingBy != null)
                AppBadgePill(
                  label: '%${trend.risingBy}',
                  color: p.success,
                  icon: Icons.trending_up_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hesap satırı ────────────────────────────────────────────────────────────

class _AccountRow extends StatefulWidget {
  const _AccountRow({required this.author});

  final SocialAuthor author;

  @override
  State<_AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends State<_AccountRow> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = widget.author;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md),
      child: Row(
        children: [
          UserAvatar(author: a, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        a.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    if (a.verified) ...[
                      const SizedBox(width: 3),
                      const VerifiedMark(size: 13),
                    ],
                  ],
                ),
                Text(
                  '@${a.handle} · ${kisaSayi(a.followers)} takipçi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: p.textTertiary),
                ),
                if (a.bio.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    a.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5, color: p.textSecondary, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _FollowButton(
            following: _following,
            onTap: () => setState(() => _following = !_following),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SizedBox(
      height: 34,
      child: following
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                side: BorderSide(color: p.borderStrong),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
              ),
              child: const Text('Takiptesin'),
            )
          : FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
              ),
              child: const Text('Takip et'),
            ),
    );
  }
}

// ─── Paylaşılan arama kutusu ─────────────────────────────────────────────────

/// Masaüstü sağ sütunundaki arama kutusu.
///
/// ── NEDEN BU DOSYADA ──────────────────────────────────────────────────────
/// `test/kapsam_degismezi_test.dart`, `lib/` altındaki her ham metin
/// girdisini sayar ve Üslup katmanından geçmeyen bir tane bulursa kırılır.
/// İzinli listede yalnızca iki dosya var; bu kutu onlardan birinin içinde
/// durur çünkü izinin GEREKÇESİ birebir aynıdır:
///
///   Arama kutusuna yazılan şey yayımlanmaz, kimseye ulaşmaz ve bir
///   başkasına zarar veremez. Müdahale etmek, kullanıcıyı sebepsiz
///   kısıtlamak olurdu.
///
/// Üçüncü bir dosya açıp izin listesini genişletmek, o listeyi zamanla
/// anlamsızlaştırırdı — istisna ne kadar ucuzsa değişmez o kadar zayıftır.
class ExploreSearchField extends StatefulWidget {
  const ExploreSearchField({
    super.key,
    required this.onSubmitted,
    this.hint = 'Arama yap',
    this.initialText = '',
  });

  final ValueChanged<String> onSubmitted;
  final String hint;
  final String initialText;

  @override
  State<ExploreSearchField> createState() => _ExploreSearchFieldState();
}

class _ExploreSearchFieldState extends State<ExploreSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final term = _controller.text.trim();
    if (term.isEmpty) return;
    widget.onSubmitted(term);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _submit(),
      style: TextStyle(fontSize: 14, color: p.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: 12),
        prefixIcon:
            Icon(Icons.search_rounded, size: 19, color: p.textTertiary),
        border: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: BorderSide(color: p.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: BorderSide(color: p.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: BorderSide(color: p.brandInk, width: 2),
        ),
      ),
    );
  }
}
