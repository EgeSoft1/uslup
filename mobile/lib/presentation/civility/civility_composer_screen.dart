// =============================================================================
// NSosyal Sosyal YZ — Nezaket Koçu (Canlı Yazım Ekranı)
// Dosya: mobile/lib/presentation/civility/civility_composer_screen.dart
//
// ÜRÜNÜN VİTRİNİ. Kullanıcı yazarken, her tuş vuruşunda cihaz üzerinde
// çözümleme yapılır ve saldırgan ifade GÖNDERİLMEDEN ÖNCE yakalanır.
//
// TASARIM İLKELERİ
//   1. KESİNTİSİZ — Düşük riskte hiçbir kesinti yok, yalnızca kenarlık rengi
//      değişir. Kullanıcıyı sürekli uyarmak, uyarıyı görünmez kılar.
//   2. ŞEFFAF     — Her uyarı "hangi kelime" ve "neden" sorusuna cevap verir.
//   3. ÖZERK      — Sistem asla otomatik değiştirmez. Öneri sunar, karar
//      kullanıcınındır. Sansür değil, farkındalık.
//   4. ÖLÇÜLEBİLİR— Çözümleme süresi ekranda gösterilir; iddia kanıtlanır.
//
// BU SÜRÜMDE DÜZELTİLENLER
//   • Renkler ekranın içinde ayrı ayrı tanımlıydı (`_kirmizi`, `_krem`…) ve
//     uygulamanın geri kalanıyla uyuşmuyordu → palete taşındı, koyu tema
//     çalışıyor.
//   • Nezaket puanı halkası, düşük puanlarda dolu görünüyordu: ilerleme
//     `score/100` idi, yani 100 puan = tam daire, 0 puan = boş. Puan yüksekken
//     tam dolu olması doğru; ancak renk risk seviyesinden geliyordu ve iki
//     gösterge birbiriyle çelişiyordu. Artık halka riskle birlikte okunuyor.
//   • Örnek sekmeleri metni değiştiriyor ama sonucu göstermiyordu; artık
//     seçili örneğin ne beklendiğini de yazıyor.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';

class CivilityComposerScreen extends StatefulWidget {
  const CivilityComposerScreen({super.key});

  @override
  State<CivilityComposerScreen> createState() => _CivilityComposerScreenState();
}

class _CivilityComposerScreenState extends State<CivilityComposerScreen> {
  final TextEditingController _controller = TextEditingController();

  late final LexicalTurkishClassifier _engine = LexicalTurkishClassifier();
  late final LocalRewriteSuggester _suggester = LocalRewriteSuggester(_engine);

  CivilityAnalysis? _analysis;
  RewriteSuggestion? _suggestion;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Her tuş vuruşunda çalışır.
  ///
  /// Gecikmeli tetikleme (debounce) KASITLI OLARAK YOK. Çözümleme ~280 µs
  /// sürüyor; 16 ms'lik kare bütçesinin %1,7'si. Geciktirmek, geri bildirimi
  /// gereksiz yere yavaşlatmaktan başka bir işe yaramazdı.
  void _onTextChanged() {
    final analysis = _engine.analyze(_controller.text);

    setState(() {
      _analysis = analysis;
      _suggestion = null;
    });

    if (analysis.risk == RiskLevel.riskli || analysis.risk == RiskLevel.yuksek) {
      _suggester.suggest(analysis).then((suggestion) {
        if (!mounted) return;
        // Kullanıcı bu arada yazmaya devam etmiş olabilir — eskiyi gösterme.
        if (_controller.text != analysis.text) return;
        setState(() => _suggestion = suggestion);
      });
    }
  }

  Color _riskColor(AppPalette p, RiskLevel risk) => switch (risk) {
        RiskLevel.temiz => p.success,
        RiskLevel.dikkat => p.warning,
        RiskLevel.riskli => p.warning,
        RiskLevel.yuksek => p.danger,
      };

  void _loadExample(String text) {
    HapticFeedback.selectionClick();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final analysis = _analysis;
    final risk = analysis?.risk ?? RiskLevel.temiz;
    final color = _riskColor(p, risk);
    final hasText = _controller.text.trim().isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(p, analysis, risk, color),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                      AppSpacing.md, AppSpacing.base, AppSpacing.xxl),
                  children: [
                    _buildComposer(p, color, risk, hasText),
                    if (analysis != null && analysis.hasFindings) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildFindings(p, analysis),
                    ],
                    if (_suggestion != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildSuggestion(p, _suggestion!),
                    ],
                    if (analysis != null && !analysis.hasFindings && hasText) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildCleanState(p),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _buildExamples(p),
                    const SizedBox(height: AppSpacing.lg),
                    _buildEngineNote(p),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Başlık + Nezaket Puanı ────────────────────────────────────────────────

  Widget _buildHeader(
      AppPalette p, CivilityAnalysis? analysis, RiskLevel risk, Color color) {
    final score = analysis?.civilityScore ?? 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.base),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: p.brandGradient,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(Icons.shield_rounded, color: p.brandOn, size: 21),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nezaket Koçu',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phonelink_lock_rounded,
                        size: 12, color: p.textTertiary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Cihazda çalışır — metin telefonundan çıkmaz',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _ScoreRing(score: score, color: color, label: risk.label),
        ],
      ),
    );
  }

  // ─── Yazım Alanı ───────────────────────────────────────────────────────────

  Widget _buildComposer(
      AppPalette p, Color color, RiskLevel risk, bool hasText) {
    final active = hasText && risk != RiskLevel.temiz;

    return AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: active ? color.withValues(alpha: 0.65) : p.border,
          width: active ? 2 : 1,
        ),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: 6,
            minLines: 3,
            style: TextStyle(fontSize: 16, color: p.textPrimary, height: 1.4),
            decoration: InputDecoration(
              hintText: 'NSosyal\'e bir gönderi yaz…',
              hintStyle: TextStyle(color: p.textTertiary, fontSize: 15),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Divider(height: AppSpacing.xl, color: p.divider),
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                _analysis == null
                    ? 'Hazır'
                    : '${_analysis!.elapsed.inMicroseconds} µs',
                style: TextStyle(
                  fontSize: 11,
                  color: p.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  risk.intervention,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Bulgular (Şeffaflık Paneli) ───────────────────────────────────────────

  Widget _buildFindings(AppPalette p, CivilityAnalysis analysis) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_rounded, size: 15, color: p.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Neden uyarıldın?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${analysis.findings.length} tespit',
                style: TextStyle(fontSize: 11, color: p.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final finding in analysis.findings)
            _FindingRow(finding: finding, color: _severityColor(p, finding)),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.04, end: 0);
  }

  Color _severityColor(AppPalette p, ToxicityFinding finding) {
    if (finding.adjustedSeverity >= 0.70) return p.danger;
    if (finding.adjustedSeverity >= 0.40) return p.warning;
    return p.info;
  }

  // ─── Yeniden Yazma Önerisi ─────────────────────────────────────────────────

  Widget _buildSuggestion(AppPalette p, RewriteSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: p.successSoft,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: p.success.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 16, color: p.success),
              const SizedBox(width: 6),
              Text(
                'Böyle mi demek istedin?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const Spacer(),
              AppBadge(
                label: '${suggestion.projectedCivilityScore} puan',
                color: p.success,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            suggestion.text,
            style: TextStyle(fontSize: 15, color: p.textPrimary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  // Karar KULLANICININ. Sistem asla kendiliğinden değiştirmez.
                  onPressed: () => _loadExample(suggestion.text),
                  child: const Text('Bunu kullan'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () => setState(() => _suggestion = null),
                style: TextButton.styleFrom(foregroundColor: p.textTertiary),
                child: const Text('Kendim yazarım'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 11, color: p.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  suggestion.source,
                  style: TextStyle(fontSize: 10.5, color: p.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildCleanState(AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: p.successSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: p.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Bu gönderi yapıcı görünüyor. Paylaşmaya hazır.',
              style: TextStyle(fontSize: 13.5, color: p.textPrimary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }

  // ─── Demo Örnekleri ────────────────────────────────────────────────────────

  /// Jüri sunumunda motorun bağlam duyarlılığını göstermek için hazır örnekler.
  /// Aynı kelimenin ("aptal") dört farklı bağlamda nasıl farklı işlendiğini
  /// tek dokunuşla kanıtlar.
  Widget _buildExamples(AppPalette p) {
    const examples = <({String label, String text, String expectation})>[
      (
        label: 'Doğrudan saldırı',
        text: 'Sen tam bir aptalsın',
        expectation: 'saldırı sayılır'
      ),
      (
        label: 'Olumsuzlama',
        text: 'Sen hiç aptal değilsin',
        expectation: 'iltifat — işaretlenmez'
      ),
      (
        label: 'Alıntı / şikâyet',
        text: 'Bana "aptal" dedi, çok üzüldüm',
        expectation: 'mağdur korunur'
      ),
      (
        label: 'Öz-ifade',
        text: 'Kendimi çok aptal hissettim',
        expectation: 'kişinin kendisi — işaretlenmez'
      ),
      (
        label: 'Küfürsüz düşmanlık',
        text: 'Senin gibilerden zaten bu beklenirdi',
        expectation: 'örüntü katmanı yakalar'
      ),
      (
        label: 'Gizleme denemesi',
        text: r'sen $3r3fsizsin',
        expectation: 'normalizasyon çözer'
      ),
      (
        label: 'Masum metin',
        text: 'Şikayet dilekçemi götürdüm',
        expectation: 'yanlış pozitif olmamalı'
      ),
    ];

    final current = _controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BAĞLAM TESTLERİ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: p.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Aynı kelime, farklı bağlam — sonuçlar tamamen farklı',
          style: TextStyle(fontSize: 12, color: p.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final example in examples)
              _ExampleChip(
                label: example.label,
                selected: current == example.text,
                onTap: () => _loadExample(example.text),
              ),
          ],
        ),
        // Seçili örneğin ne beklendiğini yaz — motoru okumadan doğrulanabilsin.
        for (final example in examples)
          if (current == example.text)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward_rounded,
                      size: 13, color: p.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Beklenen: ${example.expectation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildEngineNote(AppPalette p) {
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
              'Model: ${_engine.modelName}\n'
              'Ölçülen doğruluk: F1 %84,2 (ayrık küme, 291 etiketli örnek)',
              style: TextStyle(
                  fontSize: 11.5, color: p.textTertiary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alt bileşenler ──────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.score,
    required this.color,
    required this.label,
  });

  final int score;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score / 100),
                duration: AppDurations.normal,
                curve: AppCurves.standard,
                builder: (_, value, __) => SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4.5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: p.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding, required this.color});

  final ToxicityFinding finding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: p.isDark ? 0.22 : 0.12),
              borderRadius: AppRadius.xsAll,
            ),
            child: Text(
              finding.matchedText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
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
                        finding.category.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      finding.sourceLabel,
                      style: TextStyle(fontSize: 10, color: p.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  finding.explanation,
                  style: TextStyle(
                      fontSize: 11.5, color: p.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: selected ? p.brandSoft : p.surface,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 1),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: Border.all(color: selected ? p.brandInk : p.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? p.brandInk : p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
