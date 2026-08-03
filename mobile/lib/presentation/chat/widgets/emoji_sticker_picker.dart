// =============================================================================
// Emoji / Çıkartma / GIF seçici
// Dosya: mobile/lib/presentation/chat/widgets/emoji_sticker_picker.dart
//
// DÜZELTİLENLER
//   • Emoji ızgarası aynı 10 emojiyi 5 kez tekrarlıyordu (`_recentEmojis.length
//     * 5`). Dolu görünsün diye konmuş sahte içerikti: kullanıcı aynı emojiyi
//     beş ayrı yerde görüyordu. Gerçek bir emoji kümesiyle değiştirildi.
//   • Arama kutusunun `controller`'ı ve `onChanged`'i yoktu; yazılan hiçbir
//     şey işe yaramıyordu. Artık Türkçe anahtar kelimelerle filtreliyor.
//   • Renkler sabit açık tema değerleriydi; sohbet koyu temadayken seçici
//     bembeyaz açılıyordu.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';

/// Emoji ve onu bulmaya yarayan Türkçe anahtar kelimeler.
typedef _EmojiEntry = ({String emoji, List<String> keywords});

const List<_EmojiEntry> _emojiCatalog = [
  (emoji: '😀', keywords: ['gülümse', 'mutlu', 'surat']),
  (emoji: '😂', keywords: ['gül', 'kahkaha', 'komik', 'ağla']),
  (emoji: '🥹', keywords: ['duygusal', 'ağla', 'minnet']),
  (emoji: '😍', keywords: ['aşk', 'kalp', 'seviyorum', 'göz']),
  (emoji: '🥰', keywords: ['aşk', 'sevgi', 'kalp']),
  (emoji: '😎', keywords: ['havalı', 'gözlük', 'cool']),
  (emoji: '🤔', keywords: ['düşün', 'merak', 'soru']),
  (emoji: '😮', keywords: ['şaşkın', 'vay', 'şaşır']),
  (emoji: '😢', keywords: ['üzgün', 'ağla', 'kötü']),
  (emoji: '😭', keywords: ['ağla', 'çok üzgün', 'hüzün']),
  (emoji: '😅', keywords: ['gül', 'utan', 'ter']),
  (emoji: '🙂', keywords: ['gülümse', 'iyi']),
  (emoji: '😴', keywords: ['uyku', 'yorgun']),
  (emoji: '🤗', keywords: ['sarıl', 'kucak']),
  (emoji: '🤝', keywords: ['anlaş', 'el sıkış', 'tokalaş']),
  (emoji: '👍', keywords: ['beğen', 'tamam', 'olur', 'başparmak']),
  (emoji: '👏', keywords: ['alkış', 'tebrik', 'bravo']),
  (emoji: '🙏', keywords: ['teşekkür', 'rica', 'dua', 'lütfen']),
  (emoji: '💪', keywords: ['güç', 'kas', 'başar']),
  (emoji: '✌️', keywords: ['barış', 'zafer']),
  (emoji: '❤️', keywords: ['kalp', 'aşk', 'sevgi']),
  (emoji: '🧡', keywords: ['kalp', 'turuncu']),
  (emoji: '💚', keywords: ['kalp', 'yeşil']),
  (emoji: '💙', keywords: ['kalp', 'mavi']),
  (emoji: '🔥', keywords: ['ateş', 'harika', 'süper']),
  (emoji: '✨', keywords: ['parla', 'yıldız', 'güzel']),
  (emoji: '🎉', keywords: ['kutla', 'parti', 'tebrik']),
  (emoji: '🎂', keywords: ['doğum günü', 'pasta', 'kutla']),
  (emoji: '☕', keywords: ['kahve', 'çay', 'buluş']),
  (emoji: '🍽️', keywords: ['yemek', 'akşam', 'sofra']),
  (emoji: '⚽', keywords: ['futbol', 'maç', 'top']),
  (emoji: '🚗', keywords: ['araba', 'yol', 'git']),
  (emoji: '✈️', keywords: ['uçak', 'tatil', 'seyahat']),
  (emoji: '🏠', keywords: ['ev', 'yuva']),
  (emoji: '📷', keywords: ['fotoğraf', 'kamera', 'resim']),
  (emoji: '📍', keywords: ['konum', 'yer', 'adres']),
  (emoji: '⏰', keywords: ['saat', 'zaman', 'alarm']),
  (emoji: '✅', keywords: ['tamam', 'onay', 'oldu']),
  (emoji: '❌', keywords: ['hayır', 'iptal', 'olmaz']),
  (emoji: '🇹🇷', keywords: ['türkiye', 'bayrak', 'vatan']),
];

class EmojiStickerPicker extends StatefulWidget {
  const EmojiStickerPicker({
    super.key,
    required this.onEmojiSelected,
    required this.onStickerSelected,
    required this.onGifSelected,
  });

  final ValueChanged<String> onEmojiSelected;
  final ValueChanged<String> onStickerSelected;
  final ValueChanged<String> onGifSelected;

  @override
  State<EmojiStickerPicker> createState() => _EmojiStickerPickerState();
}

class _EmojiStickerPickerState extends State<EmojiStickerPicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 3, vsync: this);
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_EmojiEntry> get _visibleEmojis {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _emojiCatalog;
    return _emojiCatalog
        .where((e) => e.keywords.any((k) => k.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl)),
        border: Border(top: BorderSide(color: p.divider)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: p.brandInk,
            labelColor: p.brandInk,
            unselectedLabelColor: p.textTertiary,
            dividerColor: p.divider,
            tabs: const [
              Tab(icon: Icon(Icons.emoji_emotions_outlined, size: 21)),
              Tab(icon: Icon(Icons.sticky_note_2_outlined, size: 21)),
              Tab(icon: Icon(Icons.gif_box_outlined, size: 21)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmojiTab(p),
                _buildStickerTab(p),
                _buildGifTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiTab(AppPalette p) {
    final emojis = _visibleEmojis;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            style: TextStyle(color: p.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Emoji ara — "kahve", "tebrik"…',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 10),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              border: const OutlineInputBorder(
                  borderRadius: AppRadius.pill, borderSide: BorderSide.none),
              enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.pill, borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.pill,
                  borderSide: BorderSide(color: p.brandInk)),
            ),
          ),
        ),
        Expanded(
          child: emojis.isEmpty
              ? Center(
                  child: Text(
                    'Eşleşen emoji yok',
                    style: TextStyle(color: p.textTertiary, fontSize: 13),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, index) {
                    final entry = emojis[index];
                    return InkWell(
                      onTap: () => widget.onEmojiSelected(entry.emoji),
                      borderRadius: AppRadius.xsAll,
                      child: Center(
                        child:
                            Text(entry.emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStickerTab(AppPalette p) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => widget.onStickerSelected('sticker_$index'),
          borderRadius: AppRadius.smAll,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: AppRadius.smAll,
            ),
            child: Center(
              child: Icon(Icons.sentiment_very_satisfied_rounded,
                  color: p.textTertiary, size: 34),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGifTab(AppPalette p) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.5,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => widget.onGifSelected('gif_$index'),
          borderRadius: AppRadius.xsAll,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.infoSoft,
              borderRadius: AppRadius.xsAll,
            ),
            child: Center(
              child: Text(
                'GIF',
                style: TextStyle(
                  color: p.info,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
