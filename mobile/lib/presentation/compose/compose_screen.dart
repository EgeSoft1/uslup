// =============================================================================
// Gönderi oluşturma ekranı
// Dosya: mobile/lib/presentation/compose/compose_screen.dart
//
// Yalnızca bir kabuktur: başlık çubuğu, `CivilityComposer` ve gönderim
// sonrası yönlendirme. Bütün çözümleme, müdahale ve öneri mantığı
// bileşenin içindedir — yorum kutusu da aynı bileşeni kullandığı için
// buradaki hiçbir karar orada tekrarlanmaz.
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

  /// Tam ekran gönderi kutusunu açar.
  static Future<void> open(
    BuildContext context, {
    String? parentId,
    String? replyingTo,
  }) {
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
    // korunmaktadır.
    CommunityHealthStore.instance.record(result.analysis, result.outcome);

    navigator.pop();

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
    final p = context.palette;

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
          _isReply ? 'Yanıt yaz' : 'Yeni gönderi',
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
          CivilityComposer(
            surface: _isReply ? ComposerSurface.yanit : ComposerSurface.gonderi,
            autofocus: true,
            minLines: 5,
            maxLines: 14,
            showScenarios: true,
            replyingTo: replyingTo,
            onSubmit: (result) => _handleSubmit(context, result),
          ),
          const SizedBox(height: AppSpacing.lg),
          _engineNote(p),
        ],
      ),
    );
  }

  /// Motorun kimliği ve ölçülen başarımı.
  ///
  /// Ekranda durması bir teknik ayrıntı sergisi değil, bir şeffaflık
  /// gereğidir: kullanıcıya karar veren şeyin ne olduğu ve ne kadar
  /// yanıldığı söylenmeden "bize güven" denmiş olur.
  Widget _engineNote(AppPalette p) {
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
