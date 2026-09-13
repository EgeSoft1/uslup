// =============================================================================
// Üslup Yapay Zekâ Sohbet Arayüzü
// Dosya: mobile/lib/presentation/uslup/llm_chat_screen.dart
//
// ── MİMARİ KARAR ──────────────────────────────────────────────────────────
// Bu ekran VDS (sunucu) ÇAĞIRMAZ. Tüm çözümleme ve yeniden yazma, 
// cihaz üstündeki CivilityEngine + LocalRewriteSuggester ile yapılır.
//
// Rapordaki iddia: "metin cihazdan çıkmaz". Bu ekran o iddiayı BOZMAZ.
//
// Kullanıcı bir metin yazar → Motor analiz eder → Yeniden yazıcı öneri üretir.
// Sonuçlar: toksisite skoru, risk seviyesi, bulunan ihlaller ve gerekçeleri,
// önerilen yeni metin — tümü cihazda, tümü 193 µs'nin altında.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';

class LlmChatScreen extends StatefulWidget {
  const LlmChatScreen({super.key});

  @override
  State<LlmChatScreen> createState() => _LlmChatScreenState();
}

/// Sohbet baloncuğu verisi.
class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;

  // Motor çıktıları (yalnızca bot mesajlarında dolu)
  final double? toxicity;
  final int? civilityScore;
  final RiskLevel? risk;
  final List<ToxicityFinding>? findings;
  final String? suggestion;
  final Duration? elapsed;
  final String? modelName;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.toxicity,
    this.civilityScore,
    this.risk,
    this.findings,
    this.suggestion,
    this.elapsed,
    this.modelName,
  });
}

class _LlmChatScreenState extends State<LlmChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];

  // Cihaz üstü yeniden yazıcı — VDS'e çıkmaz.
  late final LocalRewriteSuggester _localSuggester;

  @override
  void initState() {
    super.initState();
    _localSuggester = LocalRewriteSuggester(Civility.engine);

    _messages.add(const _ChatMessage(
      text:
          'Merhaba! Ben Üslup Yapay Zekâ Motoru. Tamamıyla senin cihazında çalışıyorum '
          '— yazdığın hiçbir şey dışarı çıkmaz.\n\n'
          'Bana bir cümle yaz, ben onu 7 katmanlı işlem hattımdan geçirip '
          'sana toksisite skoru, risk seviyesi, bulunan ihlaller ve nazik '
          'bir alternatif önereyim.',
      isUser: false,
      modelName: 'Cihaz Üstü Motor',
    ));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(const _ChatMessage(
        text: 'Çözümleniyor…',
        isUser: false,
        isLoading: true,
      ));
    });
    _scrollToBottom();

    // ── CİHAZ ÜSTÜ ÇÖZÜMLEME ─────────────────────────────────────────────
    final analysis = Civility.engine.analyze(text);
    RewriteSuggestion? suggestion;
    if (analysis.hasFindings) {
      suggestion = await _localSuggester.suggest(analysis);
    }

    if (!mounted) return;

    // ── YANIT İNŞASI ────────────────────────────────────────────────────────
    final buf = StringBuffer();

    if (!analysis.hasFindings) {
      buf.writeln('✅ Bu metin temiz görünüyor. Herhangi bir ihlal tespit edemedim.');
    } else {
      buf.writeln('⚠️ **${analysis.risk.label}** — '
          'Toksisite: ${(analysis.toxicity * 100).toStringAsFixed(1)}%');
      buf.writeln();

      for (final f in analysis.findings) {
        buf.writeln('• **"${f.matchedText}"** → ${f.category.explanation}');
        buf.writeln('  Kaynak: ${f.sourceLabel} · '
            'Şiddet: ${(f.adjustedSeverity * 100).toStringAsFixed(0)}%');
        if (f.context.reason != null) {
          buf.writeln('  Bağlam: ${f.context.reason}');
        }
      }

      if (suggestion != null) {
        buf.writeln();
        buf.writeln('💬 **Öneri:** "${suggestion.text}"');
      }
    }

    setState(() {
      _messages.removeLast(); // "Çözümleniyor…" baloncuğunu kaldır
      _messages.add(_ChatMessage(
        text: buf.toString().trim(),
        isUser: false,
        toxicity: analysis.toxicity,
        civilityScore: analysis.civilityScore,
        risk: analysis.risk,
        findings: analysis.findings,
        suggestion: suggestion?.text,
        elapsed: analysis.elapsed,
        modelName: Civility.modelName,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: const AppTopBar(title: 'Üslup YZ · Cihaz Üstü'),
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

  // ─── BALONLAR ──────────────────────────────────────────────────────────────

  Widget _bubble(_ChatMessage msg, AppPalette p) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(
            bottom: AppSpacing.md,
            left: AppSpacing.xxl,
          ),
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
              style: const TextStyle(color: Colors.white, fontSize: 15)),
        ),
      );
    }

    // ── BOT BALONU ──────────────────────────────────────────────────────────
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: AppSpacing.md,
          right: AppSpacing.xxl,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: p.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isLoading)
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: p.brand),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Motor çözümlüyor…',
                    style:
                        TextStyle(color: p.textSecondary, fontSize: 13)),
              ])
            else
              Text(msg.text,
                  style:
                      TextStyle(color: p.textPrimary, fontSize: 14.5, height: 1.5)),

            // ── ETİKETLER ──────────────────────────────────────────────────
            if (!msg.isLoading && msg.modelName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tag(msg.modelName!, Icons.memory, p),
                  if (msg.elapsed != null)
                    _tag('${msg.elapsed!.inMicroseconds} µs', Icons.timer_outlined, p),
                  if (msg.risk != null)
                    _tag(msg.risk!.label, Icons.shield_outlined, p,
                        color: _riskColor(msg.risk!, p)),
                  if (msg.civilityScore != null)
                    _tag('Puan: ${msg.civilityScore}', Icons.favorite_outline, p),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _riskColor(RiskLevel r, AppPalette p) => switch (r) {
        RiskLevel.temiz => p.success,
        RiskLevel.dikkat => p.warning,
        RiskLevel.riskli => p.danger,
        RiskLevel.yuksek => p.danger,
      };

  Widget _tag(String text, IconData icon, AppPalette p, {Color? color}) {
    final c = color ?? p.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 10, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── GİRDİ ÇUBUĞU ────────────────────────────────────────────────────────

  Widget _inputBar(AppPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
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
                style: TextStyle(color: p.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Bir cümle yaz, motor analiz etsin…',
                  hintStyle: TextStyle(color: p.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 12),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              gradient: p.brandGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ]),
      ),
    );
  }
}
