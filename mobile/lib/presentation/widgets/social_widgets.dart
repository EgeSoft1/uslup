// =============================================================================
// Ev sahibi platformun ortak bileşenleri
// Dosya: mobile/lib/presentation/widgets/social_widgets.dart
//
// Avatar, doğrulama işareti, gönderi eki ve eylem çubuğu. Akış, gönderi
// ayrıntısı, profil ve bildirimler ekranları bu bileşenleri paylaşır;
// aynı öğenin ekrandan ekrana kayması böyle önlenir.
//
// ── AĞ YOK ────────────────────────────────────────────────────────────────
// Hiçbir bileşen görsel indirmez. Avatarlar baş harf + gradyan olarak,
// gönderi ekleri desenli yüzey olarak çizilir. Ürünün "çalışma zamanında
// tek bir ağ çağrısı yapılmaz" iddiası bir profil fotoğrafı için delinmez.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/social/seed_data.dart';
import '../../core/social/social_models.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

// ─── Marka işareti ───────────────────────────────────────────────────────────

/// Uygulamanın kendi işareti.
///
/// Ev sahibi platformun logosu KOPYALANMAMIŞTIR. Prototip onun tasarım
/// dilini (soğuk nötrler, camgöbeği→mavi gradyan, yerleşim) konuşur ama
/// kimliğini taşımaz; taşısaydı bu bir entegrasyon önerisi değil, bir
/// taklit olurdu.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: p.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      // Marka harfi başlık ailesindendir (Outfit). Varsayılan gövde
      // ailesiyle çizilince işaret, bir logodan çok bir metin gibi duruyordu.
      child: Text(
        'Ü',
        style: appDisplay(
          color: Colors.white,
          fontSize: size * 0.56,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Üslup',
              style: appDisplay(
                color: p.textPrimary,
                fontSize: size * 0.56,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
                height: 1.08,
              ),
            ),
            Text(
              'PROTOTİP',
              style: appBody(
                color: p.textTertiary,
                fontSize: size * 0.215,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.author,
    this.size = 44,
    this.ring = false,
  });

  /// Cihaz sahibinin avatarı. Ayrı kurucu, çağrı yerlerinin `SeedData`'yı
  /// import etmesini gereksiz kılar.
  const UserAvatar.currentUser({super.key, this.size = 44, this.ring = false})
      : author = SeedData.currentUser;

  final SocialAuthor author;
  final double size;

  /// Hikâye halkası — profil ve hikâye şeridinde.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: author.avatarColors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        author.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0.2,
        ),
      ),
    );

    final labelled = Semantics(
      label: '${author.displayName} profil resmi',
      image: true,
      child: ExcludeSemantics(child: circle),
    );

    if (!ring) return labelled;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: p.brandGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: p.surface),
        child: labelled,
      ),
    );
  }
}

// ─── Doğrulama işareti ───────────────────────────────────────────────────────

class VerifiedMark extends StatelessWidget {
  const VerifiedMark({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Doğrulanmış hesap',
      child: Icon(Icons.verified_rounded, size: size, color: p.brandInk),
    );
  }
}

// ─── Rozet ───────────────────────────────────────────────────────────────────

/// Küçük, yumuşak zeminli etiket.
class AppBadgePill extends StatelessWidget {
  const AppBadgePill({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = color ?? p.brandInk;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: p.isDark ? 0.20 : 0.11),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gönderi eki ─────────────────────────────────────────────────────────────

/// Görsel / video / anket eki.
///
/// Görseller çizilir, indirilmez. Video oynatılmaz — yerine süre etiketi ve
/// oynat işareti gösterilir. Prototipte çalışmayan bir şeyi çalışıyormuş
/// gibi göstermek, çalışan katmanın güvenilirliğini düşürür.
class PostAttachmentView extends StatelessWidget {
  const PostAttachmentView({super.key, required this.attachment});

  final PostAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return switch (attachment.kind) {
      PostAttachmentKind.yok => const SizedBox.shrink(),
      PostAttachmentKind.anket => _PollView(attachment: attachment),
      _ => _MediaView(attachment: attachment),
    };
  }
}

class _MediaView extends StatelessWidget {
  const _MediaView({required this.attachment});

  final PostAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isVideo = attachment.kind == PostAttachmentKind.video;

    return Semantics(
      label: '${isVideo ? "Video" : "Görsel"}: ${attachment.label}',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: attachment.tint,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Düz gradyan bir fotoğraf gibi durmuyor; ince bir desen
                  // yüzeyi "medya" olarak okutuyor.
                  CustomPaint(painter: _MeshPainter()),
                  if (isVideo)
                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.34),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.75),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 30),
                      ),
                    ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            attachment.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              shadows: const [
                                Shadow(blurRadius: 6, color: Color(0x66000000)),
                              ],
                            ),
                          ),
                        ),
                        if (attachment.duration != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Text(
                              attachment.duration!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.scrim.withValues(alpha: 0.40),
                        borderRadius: AppRadius.xsAll,
                      ),
                      child: const Text(
                        'temsilî',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Medya yüzeyine derinlik veren ince ızgara.
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 1;

    const step = 26.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height * 0.4, size.height),
          paint);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(
          Rect.fromCircle(center: Offset(size.width * 0.28, size.height * 0.3),
              radius: size.width * 0.5));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => false;
}

class _PollView extends StatelessWidget {
  const _PollView({required this.attachment});

  final PostAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = attachment.totalVotes;
    var leadIndex = 0;
    for (var i = 1; i < attachment.pollVotes.length; i++) {
      if (attachment.pollVotes[i] > attachment.pollVotes[leadIndex]) {
        leadIndex = i;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < attachment.pollOptions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _PollRow(
              label: attachment.pollOptions[i],
              votes: attachment.pollVotes[i],
              total: total,
              leading: i == leadIndex,
            ),
          ),
        Text(
          '${kisaSayi(total)} oy · sonuçlar temsilî',
          style: TextStyle(fontSize: 11.5, color: p.textTertiary),
        ),
      ],
    );
  }
}

class _PollRow extends StatelessWidget {
  const _PollRow({
    required this.label,
    required this.votes,
    required this.total,
    required this.leading,
  });

  final String label;
  final int votes;
  final int total;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = total == 0 ? 0.0 : votes / total;
    final percent = (ratio * 100).round();
    final fill = leading ? p.brandInk : p.textTertiary;

    return Semantics(
      label: '$label, yüzde $percent',
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: AppRadius.smAll,
              ),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.clamp(0.0, 1.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: AppDurations.slow,
                  curve: AppCurves.standard,
                  builder: (_, t, child) => Opacity(opacity: t, child: child),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: fill.withValues(alpha: p.isDark ? 0.28 : 0.16),
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              leading ? FontWeight.w700 : FontWeight.w500,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '%$percent',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: leading ? p.brandInk : p.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gönderi eylem çubuğu ────────────────────────────────────────────────────

/// Yanıt · alıntı · yükselt · görüntülenme + kaydet / paylaş.
///
/// "Yükselt" (roket), ev sahibi platformun yeniden paylaşım eylemidir;
/// terminoloji oradan alınmıştır ki katman yabancı bir dille konuşmasın.
class PostActionBar extends StatelessWidget {
  const PostActionBar({
    super.key,
    required this.post,
    required this.onReply,
    required this.onBoost,
    required this.onLike,
    required this.onBookmark,
    this.dense = false,
  });

  final SocialPost post;
  final VoidCallback onReply;
  final VoidCallback onBoost;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.mode_comment_outlined,
            label: kisaSayi(post.replyCount),
            semantic: '${post.replyCount} yanıt',
            onTap: onReply,
            dense: dense,
          ),
        ),
        Expanded(
          child: _ActionButton(
            icon: post.boosted
                ? Icons.rocket_launch_rounded
                : Icons.rocket_launch_outlined,
            label: kisaSayi(post.boostCount),
            semantic: '${post.boostCount} yükseltme',
            color: post.boosted ? p.success : null,
            onTap: onBoost,
            dense: dense,
          ),
        ),
        Expanded(
          child: _ActionButton(
            icon: post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: kisaSayi(post.likeCount),
            semantic: '${post.likeCount} beğeni',
            color: post.liked ? const Color(0xFFE0245E) : null,
            onTap: onLike,
            dense: dense,
          ),
        ),
        Expanded(
          child: _ActionButton(
            icon: Icons.bar_chart_rounded,
            label: kisaSayi(post.viewCount),
            semantic: '${post.viewCount} görüntülenme',
            onTap: () {},
            dense: dense,
          ),
        ),
        _ActionButton(
          icon: post.bookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          label: '',
          semantic: post.bookmarked ? 'Kaydedilenlerden çıkar' : 'Kaydet',
          color: post.bookmarked ? p.brandInk : null,
          onTap: onBookmark,
          dense: dense,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.semantic,
    required this.onTap,
    this.color,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final String semantic;
  final VoidCallback onTap;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = color ?? p.textTertiary;

    return Semantics(
      button: true,
      label: semantic,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pill,
          child: Padding(
            // Dokunma hedefi 44 px'in altına inmiyor (WCAG 2.5.5 / iOS HIG).
            padding: EdgeInsets.symmetric(
                vertical: dense ? 8 : 10, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: dense ? 16 : 17.5, color: tint),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: dense ? 11.5 : 12.5,
                      fontWeight: FontWeight.w600,
                      color: tint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bölüm etiketi ───────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: p.textTertiary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Tutarlı SnackBar yardımcısı ─────────────────────────────────────────────

/// Uygulama genelinde tutarlı SnackBar gösterimi sağlar.
///
/// Farklı ekranlarda farklı renk/stil kullanmak yerine, bu yardımcı üzerinden
/// geçen her SnackBar aynı tasarım diline uyar.
class AppSnackBar {
  AppSnackBar._();

  /// Başarı mesajı gösterir (yeşil arka plan).
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  /// Bilgi mesajı gösterir (marka rengi arka plan).
  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.brand, Icons.info_rounded);
  }

  /// Uyarı mesajı gösterir (turuncu arka plan).
  static void warning(BuildContext context, String message) {
    _show(context, message, AppColors.warning, Icons.warning_rounded);
  }

  /// Hata mesajı gösterir (kırmızı arka plan).
  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.danger, Icons.error_rounded);
  }

  static void _show(
      BuildContext context, String message, Color color, IconData icon) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
