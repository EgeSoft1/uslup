// =============================================================================
// Gönderi kartı
// Dosya: mobile/lib/presentation/feed/post_card.dart
//
// Akış, gönderi ayrıntısı, profil ve kaydedilenler ekranları aynı kartı
// kullanır. Kart yalnızca gösterir; beğeni/yükseltme gibi eylemleri doğrudan
// `SocialStore`a yazar, çünkü aynı gönderi birden fazla ekranda açık olabilir
// ve durum tek yerde durmak zorundadır.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/social/social_models.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/social_widgets.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onOpen,
    this.onReply,
    this.dense = false,
    this.showActions = true,
    this.threadContinues = false,
  });

  final SocialPost post;

  /// Karta dokunulunca gönderi ayrıntısını açar.
  final VoidCallback? onOpen;

  /// Yanıt düğmesi. Verilmezse [onOpen] çalışır.
  final VoidCallback? onReply;

  final bool dense;
  final bool showActions;

  /// Altında bağlı bir yanıt var mı? Varsa avatardan aşağı iplik çizgisi iner.
  final bool threadContinues;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  /// Uzun gönderiler kısaltılır; ev sahibi platformun davranışı budur.
  static const int _kisaltmaEsigi = 240;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final post = widget.post;
    final store = SocialStore.instance;
    final avatarSize = widget.dense ? 36.0 : 44.0;

    final kisaltilabilir =
        post.body.length > _kisaltmaEsigi && !_expanded;
    final govde = kisaltilabilir
        ? '${post.body.substring(0, _kisaltmaEsigi).trimRight()}…'
        : post.body;

    final topPad = widget.dense ? AppSpacing.md : AppSpacing.base;

    return Semantics(
      button: widget.onOpen != null,
      child: Material(
        color: p.surface,
        child: InkWell(
          onTap: widget.onOpen,
          child: Stack(
            children: [
              // ── İPLİK ÇİZGİSİ ────────────────────────────────────────────
              // `Positioned(top:…, bottom: 0)` kasıtlıdır. İlk kurulumda çizgi
              // avatarın altındaki `Column` içinde `Expanded` ile çiziliyordu;
              // o `Column`, yüksekliği sınırsız bir `Row`un içindeydi ve
              // Flutter "RenderFlex children have non-zero flex but incoming
              // height constraints are unbounded" diye kırılıyordu. Stack,
              // kartın yüksekliğini yerleşmeyen çocuktan alır ve çizgiyi o
              // yüksekliğe uzatır — ölçüye ihtiyaç kalmaz.
              if (widget.threadContinues)
                Positioned(
                  left: AppSpacing.base + avatarSize / 2 - 1,
                  top: topPad + avatarSize + 6,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: AppRadius.pill,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  topPad,
                  AppSpacing.base,
                  widget.dense ? AppSpacing.sm : AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(author: post.author, size: avatarSize),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _header(p, post),
                          const SizedBox(height: 3),
                          _body(p, govde),
                          if (kisaltilabilir)
                            GestureDetector(
                              onTap: () => setState(() => _expanded = true),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 4, bottom: 2),
                                child: Text(
                                  'Daha fazla göster',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: p.brandInk,
                                  ),
                                ),
                              ),
                            ),
                          if (!post.attachment.isEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            PostAttachmentView(attachment: post.attachment),
                          ],
                          if (post.author.isCurrentUser &&
                              post.revisedBeforeSending) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _privateRevisionNote(p),
                          ],
                          if (widget.showActions) ...[
                            SizedBox(height: widget.dense ? 2 : 4),
                            PostActionBar(
                              post: post,
                              dense: widget.dense,
                              onReply:
                                  widget.onReply ?? widget.onOpen ?? () {},
                              onLike: () {
                                HapticFeedback.selectionClick();
                                store.toggleLike(post.id);
                              },
                              onBoost: () {
                                HapticFeedback.selectionClick();
                                store.toggleBoost(post.id);
                              },
                              onBookmark: () {
                                HapticFeedback.selectionClick();
                                store.toggleBookmark(post.id);
                              },
                            ),
                          ],
                        ],
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

  Widget _header(AppPalette p, SocialPost post) {
    return Row(
      children: [
        Flexible(
          child: Text(
            post.author.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
        ),
        if (post.author.verified) ...[
          const SizedBox(width: 3),
          const VerifiedMark(size: 14),
        ],
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '@${post.author.handle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: p.textTertiary),
          ),
        ),
        Text(' · ${kisaSure(post.createdAt)}',
            style: TextStyle(fontSize: 13, color: p.textTertiary)),
        const Spacer(),
        Icon(Icons.more_horiz_rounded, size: 17, color: p.textTertiary),
      ],
    );
  }

  Widget _body(AppPalette p, String text) {
    return Text.rich(
      buildSocialTextSpan(text, p),
      style: TextStyle(
        fontSize: 15,
        color: p.textPrimary,
        height: 1.42,
      ),
    );
  }

  /// Yalnızca gönderinin SAHİBİNE görünen not.
  ///
  /// Bu satırın akışta herkese gösterilmemesi bir tasarım kararı değil, bir
  /// etik karardır: müdahale bir duraksamadır, bir damga değil. Rozetlenen
  /// kullanıcı, bir daha uyarılmamak için özelliği kapatır.
  Widget _privateRevisionNote(AppPalette p) {
    return Row(
      children: [
        Icon(Icons.lock_outline_rounded, size: 12, color: p.textTertiary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Bunu göndermeden önce düzelttin — yalnızca sen görüyorsun.',
            style: TextStyle(fontSize: 11.5, color: p.textTertiary),
          ),
        ),
      ],
    );
  }
}

// ─── Metin biçimleme ─────────────────────────────────────────────────────────

/// Etiketleri (#) ve bahsetmeleri (@) marka renginde gösterir.
///
/// Türkçe karakterler sınıfa AÇIKÇA eklenmiştir: `\w` Dart'ın varsayılan
/// (Unicode olmayan) kipinde yalnızca `[A-Za-z0-9_]` demektir ve
/// `#Şanlıurfa` etiketi `#` + `anl` diye bölünürdü.
InlineSpan buildSocialTextSpan(String text, AppPalette p) {
  final pattern = RegExp(r'(#[A-Za-z0-9_çğıöşüÇĞİÖŞÜ]+|@[A-Za-z0-9_]+)');
  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    spans.add(TextSpan(
      text: match.group(0),
      style: TextStyle(color: p.brandInk, fontWeight: FontWeight.w600),
    ));
    cursor = match.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }

  return spans.isEmpty ? TextSpan(text: text) : TextSpan(children: spans);
}
