// =============================================================================
// Gönderi oluşturma yüzeyi
// Dosya: mobile/lib/presentation/compose/compose_screen.dart
//
// Yalnızca bir kabuktur: başlık çubuğu, `CivilityComposer` ve gönderim
// sonrası yönlendirme. Bütün çözümleme, müdahale ve öneri mantığı
// bileşenin içindedir — yorum kutusu da aynı bileşeni kullandığı için
// buradaki hiçbir karar orada tekrarlanmaz.
//
// ── İKİ SUNUM, TEK İÇERİK ─────────────────────────────────────────────────
// Dar ekranda tam ekran sayfa, geniş ekranda ortada iletişim kutusu olarak
// açılır — ev sahibi platformun masaüstünde yaptığı budur. İkisi de AYNI
// gövdeyi (`_ComposeBody`) çizer; yalnızca çerçeve değişir. Ayrı bir
// masaüstü kutusu yazılsaydı, katmanın davranışı iki yerde tanımlanır ve
// biri sessizce eskirdi.
//
// Çağrı yerleri değişmedi: hepsi `ComposeScreen.open(context)` çağırır ve
// hangi sunumun geleceğini bilmez.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/community/community_health_store.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/social_widgets.dart';
import 'civility_composer.dart';

class ComposeScreen extends StatelessWidget {
  const ComposeScreen({super.key, this.parentId, this.replyingTo});

  /// Doluysa bu bir yanıttır.
  final String? parentId;
  final String? replyingTo;

  /// Gönderi kutusunu açar. Geniş ekranda iletişim kutusu, dar ekranda
  /// tam ekran sayfa olarak gelir.
  static Future<void> open(
    BuildContext context, {
    String? parentId,
    String? replyingTo,
  }) {
    if (AppBreakpoints.isDesktop(context)) {
      return showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => _ComposeDialog(
          parentId: parentId,
          replyingTo: replyingTo,
        ),
      );
    }

    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ComposeScreen(
          parentId: parentId,
          replyingTo: replyingTo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isReply = parentId != null;

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
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Vazgeç',
        ),
        title: Text(
          isReply ? 'Yanıt yaz' : 'Yeni gönderi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.base),
            child: Center(child: BrandMark(size: 26)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.xxxl),
        children: [
          _ComposeBody(
            parentId: parentId,
            replyingTo: replyingTo,
            autofocus: true,
            minLines: 5,
            maxLines: 14,
          ),
          const SizedBox(height: AppSpacing.lg),
          const EngineNote(),
        ],
      ),
    );
  }
}

// ─── Masaüstü iletişim kutusu ────────────────────────────────────────────────

class _ComposeDialog extends StatelessWidget {
  const _ComposeDialog({this.parentId, this.replyingTo});

  final String? parentId;
  final String? replyingTo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isReply = parentId != null;

    return Dialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          // Kutu, uyarı paneli ve öneri kartı açıldığında büyür; ekranın
          // %80'ini geçince içi kaydırılır, iletişim kutusu taşmaz.
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.base, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isReply ? 'Yanıt Yaz' : 'Gönderi Oluştur',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Kapat',
                    style: IconButton.styleFrom(
                      backgroundColor: p.surfaceMuted,
                      foregroundColor: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ComposeBody(
                      parentId: parentId,
                      replyingTo: replyingTo,
                      autofocus: true,
                      minLines: 4,
                      maxLines: 12,
                      closeAfterSubmit: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const EngineNote(),
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

// ─── Ortak gövde ─────────────────────────────────────────────────────────────

class _ComposeBody extends StatelessWidget {
  const _ComposeBody({
    required this.parentId,
    required this.replyingTo,
    required this.autofocus,
    required this.minLines,
    required this.maxLines,
    this.closeAfterSubmit = true,
  });

  final String? parentId;
  final String? replyingTo;
  final bool autofocus;
  final int minLines;
  final int maxLines;
  final bool closeAfterSubmit;

  bool get _isReply => parentId != null;

  void _handleSubmit(BuildContext context, ComposerResult result) {
    // Messenger ve Navigator, POP'TAN ÖNCE yakalanır. Pop çağrısından sonra
    // bu `context` ağaçtan düşmüş olur ve `ScaffoldMessenger.of(context)`
    // "deactivated widget's ancestor" hatası verir.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    SocialStore.instance.publish(
      body: result.text,
      parentId: parentId,
      revised: result.revised,
      sentDespiteWarning: result.sentDespiteWarning,
    );

    // Topluluk sağlığı sinyali. Metin GEÇMEZ — `CommunitySignal` sınıfının
    // tek bir metin alanı yoktur ve bu, çekirdek pakette yapısal bir testle
    // korunmaktadır. Katman kapalıyken gönderim ölçüme girmez (docs/27).
    if (result.olcumeDahil) {
      CommunityHealthStore.instance.record(result.analysis, result.outcome,
          yanlisAlarm: result.yanlisAlarm);
    }

    if (closeAfterSubmit && navigator.canPop()) navigator.pop();

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.revised
              ? 'Gönderildi — düzelttiğin hâliyle.'
              : _isReply
                  ? 'Yanıtın gönderildi.'
                  : 'Gönderin paylaşıldı.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CivilityComposer(
      surface: _isReply ? ComposerSurface.yanit : ComposerSurface.gonderi,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      showScenarios: true,
      replyingTo: replyingTo,
      onSubmit: (result) => _handleSubmit(context, result),
    );
  }
}

// ─── Motor künyesi ───────────────────────────────────────────────────────────

/// Motorun kimliği ve ölçülen başarımı.
///
/// Ekranda durması bir teknik ayrıntı sergisi değil, bir şeffaflık
/// gereğidir: kullanıcıya karar veren şeyin ne olduğu ve ne kadar
/// yanıldığı söylenmeden "bize güven" denmiş olur.
class EngineNote extends StatelessWidget {
  const EngineNote({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.memory_rounded, size: 15, color: p.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${Civility.modelName}\n'
              '${Civility.olcumOzeti}\n'
              '${Civility.olcumKapsami}',
              style: TextStyle(
                fontSize: 11.5,
                color: p.textTertiary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
