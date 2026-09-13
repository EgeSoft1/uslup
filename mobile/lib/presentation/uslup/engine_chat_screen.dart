// =============================================================================
// Motorla soru-cevap — cihaz üstü motorun gerekçeli cevabı
// Dosya: mobile/lib/presentation/uslup/engine_chat_screen.dart
//
// ── NE DEĞİLDİR ───────────────────────────────────────────────────────────
// Bu ekran bir dil modeli (LLM) sohbeti DEĞİLDİR ve öyle adlandırılmaz.
// Önceki adı "Üslup Yapay Zekâ Sohbeti (LLM)" idi; oysa ekranın arkasında
// hiçbir dil modeli yok ve projede bir LLM'in ölçülüp kasıtlı olarak
// kaldırıldığı belgelenmiş durumda (docs/03_LLM_SERVISI.md). Jüriye yanlış
// bir etiket göstermek, doğru olan her şeyin güvenilirliğini düşürür.
//
// Kullanıcı bir cümle yazar → cihaz üstü motor çözümler → ekran sonucu
// yapılandırılmış olarak gösterir: risk basamağı, bulgular ve gerekçeleri,
// önerilen yeni metin. Hiçbir şey cihazdan çıkmaz.
//
// ── NEDEN DÜZ METİN DEĞİL, BİLEŞEN ────────────────────────────────────────
// Önceki sürüm cevabı `**kalın**` işaretleri ve emoji içeren tek bir metin
// olarak kuruyordu. `Text` bileşeni markdown çizmez: ekranda yıldızlar
// olduğu gibi görünüyordu. Emoji ise çevrimdışı web sürümünde yazı tipi
// indirilemediği için kutu olarak çiziliyordu.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';
import '../widgets/social_widgets.dart';

class EngineChatScreen extends StatefulWidget {
  const EngineChatScreen({super.key});

  @override
  State<EngineChatScreen> createState() => _EngineChatScreenState();
}

/// Sohbet baloncuğu verisi.
class _ChatMessage {
  const _ChatMessage.user(this.text)
      : isUser = true,
        analysis = null,
        suggestion = null;

  const _ChatMessage.engine(this.text, {this.analysis, this.suggestion})
      : isUser = false;

  final String text;
  final bool isUser;
  final CivilityAnalysis? analysis;
  final RewriteSuggestion? suggestion;
}

class _EngineChatScreenState extends State<EngineChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[
    const _ChatMessage.engine(
      'Bir cümle yaz; onu bu cihazda çözümleyip hangi ifadenin neden '
      'saldırgan okunabileceğini ve daha yapıcı bir alternatifi göstereyim. '
      'Yazdığın hiçbir şey dışarı çıkmaz.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // ── CİHAZ ÜSTÜ ÇÖZÜMLEME ─────────────────────────────────────────────
    final analysis = Civility.engine.analyze(text);
    final suggestion = analysis.hasFindings
        ? await Civility.suggester.suggest(analysis)
        : null;
    if (!mounted) return;

    setState(() {
      _messages
        ..add(_ChatMessage.user(text))
        ..add(_ChatMessage.engine(
          analysis.hasFindings
              ? analysis.risk.intervention
              : analysis.needsSupport
                  // Kendine zarar ifadesi saldırı değildir (docs/20, D4).
                  ? 'Bu cümlede saldırgan bir ifade yok. Zor bir an '
                      'geçiriyor olabilirsin — güvende değilsen 112\'yi ara.'
                  : 'Bu cümlede saldırgan bir ifade bulmadım.',
          analysis: analysis,
          suggestion: suggestion,
        ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.normal,
        curve: AppCurves.standard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: const AppTopBar(title: 'Motorla soru-cevap'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _bubble(_messages[i], p),
                ),
              ),
              _inputBar(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(_ChatMessage msg, AppPalette p) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(
              bottom: AppSpacing.md, left: AppSpacing.xxl),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: p.brandGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Text(msg.text,
              style: appBody(color: Colors.white, fontSize: 15)),
        ),
      );
    }

    final analysis = msg.analysis;
    final riskColor = analysis == null ? p.textSecondary : _riskColor(analysis.risk, p);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
            bottom: AppSpacing.md, right: AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis != null) ...[
              Row(
                children: [
                  AppBadgePill(label: analysis.risk.label, color: riskColor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'nezaket puanı ${analysis.civilityScore} · '
                      '${analysis.elapsed.inMicroseconds} µs',
                      style: appBody(fontSize: 11.5, color: p.textTertiary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(msg.text,
                style: appBody(
                    color: p.textPrimary, fontSize: 14.5, height: 1.45)),
            if (analysis != null)
              for (final f in analysis.findings) ...[
                const SizedBox(height: AppSpacing.sm),
                _findingLine(f, p),
              ],
            if (msg.suggestion != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: p.successSoft,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Böyle de söyleyebilirsin',
                        style: appBody(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: p.success)),
                    const SizedBox(height: 3),
                    Text(msg.suggestion!.text,
                        style: appBody(
                            fontSize: 14.5,
                            color: p.textPrimary,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _findingLine(ToxicityFinding f, AppPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: p.dangerSoft,
            borderRadius: AppRadius.xsAll,
          ),
          child: Text(
            f.matchedText,
            style: appBody(
                fontSize: 12, fontWeight: FontWeight.w700, color: p.danger),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '${f.category.label} · ${f.sourceLabel}\n${f.explanation}',
            style: appBody(fontSize: 12, color: p.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }

  Color _riskColor(RiskLevel r, AppPalette p) => switch (r) {
        RiskLevel.temiz => p.success,
        RiskLevel.dikkat => p.info,
        RiskLevel.riskli => p.warning,
        RiskLevel.yuksek => p.danger,
      };

  Widget _inputBar(AppPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: p.border),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                style: appBody(color: p.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Bir cümle yaz…',
                  hintStyle: appBody(color: p.textTertiary, fontSize: 15),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 12),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: p.brandGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
              tooltip: 'Çözümle',
              onPressed: _sendMessage,
            ),
          ),
        ]),
      ),
    );
  }
}
