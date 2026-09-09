// =============================================================================
// Üslup Yazım Kutusu — platformun HER metin giriş noktasında çalışan katman
// Dosya: mobile/lib/presentation/compose/civility_composer.dart
//
// ── ÜRÜNÜN TAMAMI BU DOSYADA GÖRÜNÜR ──────────────────────────────────────
// Gönderi kutusu, yorum kutusu ve biyografi alanı AYNI bileşeni kullanır.
// Bu bir kod tasarrufu değil, bir ürün kararıdır: katman yalnızca bir
// ekranda çalışıyorsa "platforma düşen katman" değil, "bir demo ekranı"dır.
// İkinci bir kod yolu açmak, o yolun test edilmediği için sessizce
// eskimesiyle biterdi.
//
// ── MÜDAHALE MERDİVENİ ────────────────────────────────────────────────────
//   temiz    → hiçbir şey olmaz. Kesinti yok.
//   dikkat   → yalnızca kenarlık rengi değişir. Metin, panel, ses yok.
//   riskli   → gerekçe paneli + yeniden yazma önerisi açılır.
//   yüksek   → ek olarak gönderim öncesi onay istenir.
//
// Hiçbir basamakta gönderim ENGELLENMEZ. "Yine de gönder" her zaman
// bir tıklama uzaktadır ve varsayılan seçenek olarak vurgulanmaz.
//
// ── ÖLÇÜM ─────────────────────────────────────────────────────────────────
// Kutu, gönderim anında dört sonuçtan birini üretir ve topluluk sağlığı
// katmanına yollar: temiz gönderim · öneriyi kabul etti · kendi düzeltti ·
// uyarıya rağmen gönderdi. Ürünün birincil etkinlik göstergesi olan
// "düzeltme oranı" doğrudan buradan hesaplanır.
//
// Giden sinyalde METİN YOKTUR — `CommunitySignal` sınıfının tek bir metin
// alanı bulunmaz ve bu, çekirdek pakette yapısal bir testle korunur.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/civility/civility_text_controller.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/social_widgets.dart';

/// Yazım kutusunun kullanıldığı yer. Yalnızca metinleri değiştirir;
/// çözümleme davranışı her yerde birebir aynıdır.
enum ComposerSurface { gonderi, yanit, biyografi }

/// Gönderim anında kutunun ürettiği sonuç.
///
/// [analysis] birlikte taşınır çünkü topluluk sağlığı sinyali metinden
/// değil ÇÖZÜMLEMEDEN üretilir (`CommunitySignal.fromAnalysis`). Çağıran
/// tarafın metni yeniden çözümlemesi hem gereksiz bir iş hem de iki farklı
/// sonuç üretme riski olurdu.
@immutable
class ComposerResult {
  const ComposerResult({
    required this.text,
    required this.analysis,
    required this.outcome,
  });

  final String text;
  final CivilityAnalysis analysis;
  final SignalOutcome outcome;

  /// Kullanıcı uyarıyı gördü ve metnini değiştirdi.
  bool get revised =>
      outcome == SignalOutcome.oneriyiKabulEtti ||
      outcome == SignalOutcome.kendiDuzeltti;

  /// Kullanıcı uyarıyı gördü ve yine de gönderdi. Sistem engellemedi.
  bool get sentDespiteWarning =>
      outcome == SignalOutcome.uyariyaRagmenGonderdi;
}

class CivilityComposer extends StatefulWidget {
  const CivilityComposer({
    super.key,
    this.onSubmit,
    this.surface = ComposerSurface.gonderi,
    this.initialText = '',
    this.autofocus = false,
    this.minLines = 3,
    this.maxLines = 10,
    this.showAvatar = true,
    this.showToolbar = true,
    this.showScenarios = false,
    this.replyingTo,
  });

  /// Gönderim isteği. Sonuç, müdahale merdiveninin bu oturumdaki çıktısıdır
  /// ve topluluk sağlığı ölçümünü besler.
  ///
  /// `null` verilirse gönderim düğmesi hiç çizilmez ve kutu yalnızca CANLI
  /// ÇÖZÜMLEME yapar. Üslup panelindeki deneme kutusu bu kipi kullanır:
  /// orada gönderilecek bir yer yok, gösterilecek bir davranış var.
  final void Function(ComposerResult result)? onSubmit;

  final ComposerSurface surface;
  final String initialText;
  final bool autofocus;
  final int minLines;
  final int maxLines;
  final bool showAvatar;
  final bool showToolbar;

  /// Hazır senaryo çipleri gösterilsin mi?
  ///
  /// ── BU BİR DEMO ARACIDIR VE ÖYLE ETİKETLENİR ────────────────────────
  /// Gerçek üründe bulunmaz. Var olma sebebi, jüri sunumunda katmanın
  /// bağlam duyarlılığının tek dokunuşla gösterilebilmesidir: aynı kelime
  /// dört farklı bağlamda dört farklı sonuç üretir ve bunu canlı yazarak
  /// göstermek hem yavaştır hem de yazım hatası riski taşır.
  final bool showScenarios;

  /// Yanıt kutusunda üstteki hesabın kullanıcı adı ("@zeynepaydin").
  final String? replyingTo;

  @override
  State<CivilityComposer> createState() => _CivilityComposerState();
}

class _CivilityComposerState extends State<CivilityComposer> {
  late final CivilityTextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  CivilityAnalysis? _analysis;
  RewriteSuggestion? _suggestion;

  /// Bu yazım oturumunda hiç `riskli`/`yüksek` seviyeye çıkıldı mı?
  ///
  /// Sonucun "temiz gönderim" mi yoksa "düzeltti" mi olduğunu ayıran tek
  /// bilgi budur. Yalnızca son duruma bakmak, uyarıyı görüp düzelten
  /// kullanıcıyı hiç uyarı almamış saymak olurdu — ürünün ölçmek istediği
  /// davranış tam olarak o düzeltmedir.
  bool _sawWarning = false;

  /// Kullanıcı önerilen metni kabul etti mi?
  bool _acceptedSuggestion = false;

  /// Gerekçe paneli açık mı? `riskli` seviyede kendiliğinden açılır.
  bool _reasonsExpanded = true;

  /// Yeniden girişi (re-entrancy) engelleyen bayrak.
  ///
  /// `_controller.findings` atanınca denetleyici dinleyicilerini uyarır —
  /// çünkü işaretlemenin yeniden çizilmesi gerekir. Ama bu sınıf da o
  /// dinleyicilerden biridir; bayrak olmasaydı her tuş vuruşu çözümlemeyi
  /// iki kez çalıştırırdı. Ölçüm ekranda gösterildiği için bu, yanlış bir
  /// süre raporlamak anlamına da gelirdi.
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _controller = CivilityTextEditingController(
      text: widget.initialText,
      resolveColor: _severityColorStatic,
    )..addListener(_onTextChanged);

    if (widget.initialText.isEmpty) return;

    // İlk metin varsa çözümleme burada, DOĞRUDAN alanlara yazılarak yapılır.
    // `_onTextChanged` çağrılamaz çünkü o `setState` eder ve `initState`
    // içinde `setState` etmek, ağaç kurulurken yeniden çizim istemektir.
    // İlk çizim zaten bundan hemen sonra olacağı için gerek de yok.
    //
    // `_analyzing` bayrağı burada da gerekli: `findings` atanınca denetleyici
    // dinleyicilerini uyarır ve `_onTextChanged` dolaylı olarak tetiklenirdi.
    _analyzing = true;
    final analysis = Civility.engine.analyze(widget.initialText);
    _controller.findings = analysis.findings;
    _analysis = analysis;
    _sawWarning =
        analysis.risk == RiskLevel.riskli || analysis.risk == RiskLevel.yuksek;
    _analyzing = false;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Çözümleme ────────────────────────────────────────────────────────────

  /// Her tuş vuruşunda çalışır.
  ///
  /// Gecikmeli tetikleme (debounce) KASITLI OLARAK YOKTUR. AOT derlemede
  /// tipik çözümleme 159 µs; p99 bile (1459 µs) 16 ms'lik kare bütçesinin
  /// %9,1'i. Geciktirmek yalnızca geri bildirimi yavaşlatırdı.
  /// Ölçüm: `packages/civility_core/bin/benchmark.dart` (İP-23).
  void _onTextChanged() {
    if (_analyzing) return;
    _analyzing = true;

    final CivilityAnalysis analysis;
    try {
      analysis = Civility.engine.analyze(_controller.text);
      // İşaretleme aralıklarını denetleyiciye ver; o da metni yeniden çizer.
      _controller.findings = analysis.findings;
    } finally {
      _analyzing = false;
    }

    final warned =
        analysis.risk == RiskLevel.riskli || analysis.risk == RiskLevel.yuksek;

    setState(() {
      _analysis = analysis;
      _suggestion = null;
      if (warned) {
        _sawWarning = true;
        _reasonsExpanded = true;
      }
    });

    if (!warned) return;

    Civility.suggester.suggest(analysis).then((suggestion) {
      if (!mounted) return;
      // Kullanıcı bu arada yazmaya devam etmiş olabilir — eski öneriyi gösterme.
      if (_controller.text != analysis.text) return;
      setState(() => _suggestion = suggestion);
    });
  }

  /// Palet bağlamı olmadan çağrılabilen sabit eşlemesi.
  ///
  /// `CivilityTextEditingController` bir widget değildir ve `context.palette`
  /// okuyamaz; bu yüzden işaretleme renkleri buradan verilir. Değerler
  /// paletteki `warning` / `danger` / `info` ile aynı tutulur.
  static Color _severityColorStatic(double severity) {
    if (severity >= 0.70) return const Color(0xFFDC2626);
    if (severity >= 0.40) return const Color(0xFFD97706);
    return const Color(0xFF0284C7);
  }

  Color _riskColor(AppPalette p, RiskLevel risk) => switch (risk) {
        RiskLevel.temiz => p.success,
        RiskLevel.dikkat => p.info,
        RiskLevel.riskli => p.warning,
        RiskLevel.yuksek => p.danger,
      };

  Color _severityColor(AppPalette p, double severity) {
    if (severity >= 0.70) return p.danger;
    if (severity >= 0.40) return p.warning;
    return p.info;
  }

  // ─── Gönderim ─────────────────────────────────────────────────────────────

  /// Kullanıcının bu oturumdaki davranışını dört sonuçtan birine indirger.
  SignalOutcome _outcome(RiskLevel finalRisk) {
    if (!_sawWarning) return SignalOutcome.temizGonderim;
    if (finalRisk == RiskLevel.riskli || finalRisk == RiskLevel.yuksek) {
      return SignalOutcome.uyariyaRagmenGonderdi;
    }
    return _acceptedSuggestion
        ? SignalOutcome.oneriyiKabulEtti
        : SignalOutcome.kendiDuzeltti;
  }

  Future<void> _submit() async {
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final analysis = _analysis ?? Civility.engine.analyze(text);
    final risk = analysis.risk;

    // Yalnızca EN ÜST basamakta onay istenir. Her uyarıda diyalog açmak,
    // uyarıyı bir engele çevirir ve kullanıcıyı özelliği kapatmaya iter.
    if (risk == RiskLevel.yuksek) {
      final proceed = await _confirmHighRisk(analysis);
      if (!mounted || proceed != true) return;
    }

    HapticFeedback.mediumImpact();
    onSubmit(ComposerResult(
      text: text,
      analysis: analysis,
      outcome: _outcome(risk),
    ));

    _controller.clear();
    setState(() {
      _analysis = null;
      _suggestion = null;
      _sawWarning = false;
      _acceptedSuggestion = false;
    });
  }

  Future<bool?> _confirmHighRisk(CivilityAnalysis analysis) {
    final p = context.palette;
    final threat = analysis.containsThreat;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          threat ? Icons.gavel_rounded : Icons.report_gmailerrorred_rounded,
          color: p.danger,
          size: 30,
        ),
        title: const Text('Göndermeden önce bir saniye'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              threat
                  ? 'Bu gönderi tehdit olarak okunabilecek bir ifade '
                      'içeriyor. Tehdit, Türk Ceza Kanunu kapsamında suç '
                      'oluşturabilir.'
                  : 'Bu gönderi ağır saldırgan bir ifade içeriyor. '
                      'Gönderildikten sonra silmek, karşı tarafın okumuş '
                      'olmasını geri almaz.',
              style: TextStyle(color: p.textSecondary, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: p.dangerSoft,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: p.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Karar senin. Bu metin hiçbir yere raporlanmadı.',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          // Yıkıcı olan seçenek vurgulanmaz. "Vazgeç" birincil eylemdir
          // ama "Yine de gönder" gizlenmez de — sistem engellemiyor.
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: p.textTertiary),
            child: const Text('Yine de gönder'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç, düzelteyim'),
          ),
        ],
      ),
    );
  }

  void _applySuggestion(RewriteSuggestion suggestion) {
    HapticFeedback.selectionClick();
    _acceptedSuggestion = true;
    _controller.value = TextEditingValue(
      text: suggestion.text,
      selection: TextSelection.collapsed(offset: suggestion.text.length),
    );
  }

  // ─── Görünüm ──────────────────────────────────────────────────────────────

  String get _hint => switch (widget.surface) {
        ComposerSurface.gonderi => 'Gönderi oluşturmak için…',
        ComposerSurface.yanit => 'Yanıtını yaz…',
        ComposerSurface.biyografi => 'Kendini birkaç cümleyle anlat…',
      };

  String get _submitLabel => switch (widget.surface) {
        ComposerSurface.gonderi => 'Gönder',
        ComposerSurface.yanit => 'Yanıtla',
        ComposerSurface.biyografi => 'Kaydet',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final analysis = _analysis;
    final risk = analysis?.risk ?? RiskLevel.temiz;
    final hasText = _controller.text.trim().isNotEmpty;
    final showBorder = hasText && risk != RiskLevel.temiz;
    final riskColor = _riskColor(p, risk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyingTo != null) _replyingBanner(p),
        AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: AppRadius.xlAll,
            border: Border.all(
              color: showBorder ? riskColor.withValues(alpha: 0.70) : p.border,
              width: showBorder ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputRow(p),
              if (widget.showToolbar) ...[
                const SizedBox(height: AppSpacing.sm),
                Divider(height: AppSpacing.lg, color: p.divider),
                _toolbar(p, risk, riskColor, hasText),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                _toolbar(p, risk, riskColor, hasText),
              ],
            ],
          ),
        ),

        // ── Müdahale merdiveni · 3. ve 4. basamak ────────────────────────
        if (analysis != null && analysis.hasFindings) ...[
          const SizedBox(height: AppSpacing.md),
          _reasonPanel(p, analysis),
        ],
        if (_suggestion != null) ...[
          const SizedBox(height: AppSpacing.md),
          _suggestionCard(p, _suggestion!),
        ],
        if (analysis != null &&
            !analysis.hasFindings &&
            hasText &&
            _sawWarning) ...[
          const SizedBox(height: AppSpacing.md),
          _resolvedBanner(p),
        ],
        if (widget.showScenarios) ...[
          const SizedBox(height: AppSpacing.xl),
          _scenarioDeck(p),
        ],
      ],
    );
  }

  // ─── Senaryo destesi (yalnızca demo) ──────────────────────────────────────

  /// Aynı kelimenin bağlama göre nasıl farklı işlendiğini tek dokunuşla
  /// gösteren hazır cümleler.
  ///
  /// Her senaryonun BEKLENTİSİ de yazılıdır. Beklentiyi göstermek, jürinin
  /// motoru okumadan sonucu doğrulayabilmesini sağlar — "doğru çıktı" demek
  /// yerine "doğrusu buydu, çıktı da bu" demek.
  static const List<({String label, String text, String expectation})>
      _scenarios = [
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
      label: 'Mağdur anlatısı',
      text: 'Bana "aptal" dedi, çok üzüldüm',
      expectation: 'şikâyet eden susturulmaz'
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
      label: 'Yapısal aile',
      text: 'Sende akıl mı var',
      expectation: 'kapalı ad sınıfı — yakalanır'
    ),
    (
      label: 'Gizleme denemesi',
      text: r'sen $3r3fsizsin',
      expectation: 'normalizasyon çözer'
    ),
    (
      label: 'Kimlik beyanı',
      text: 'Ben Kürtüm ve bununla gurur duyuyorum',
      expectation: 'kimlik adı tetikleyici değil'
    ),
    (
      label: 'Nefret söylemi',
      text: 'Bütün Suriyeliler hırsızdır',
      expectation: 'yuva + düşmanca kuruluş'
    ),
    (
      label: 'Sert ama meşru',
      text: 'Bu karar bence tamamen hatalı ve geri alınmalı',
      expectation: 'eleştiri sansürlenmez'
    ),
    (
      label: 'Masum tuzak',
      text: 'Şikayet dilekçemi götürdüm, bardak dolu geldi',
      expectation: 'yanlış pozitif olmamalı'
    ),
  ];

  void _loadScenario(String text) {
    HapticFeedback.selectionClick();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  Widget _scenarioDeck(AppPalette p) {
    final current = _controller.text;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 15, color: p.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'BAĞLAM TESTLERİ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: p.textSecondary,
                  ),
                ),
              ),
              AppBadgePill(label: 'demo aracı', color: p.textTertiary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aynı kelime, farklı bağlam — sonuçlar tamamen farklı. '
            'Bu bölüm gerçek üründe bulunmaz.',
            style: TextStyle(fontSize: 12, color: p.textTertiary, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in _scenarios)
                _ScenarioChip(
                  label: s.label,
                  selected: current == s.text,
                  onTap: () => _loadScenario(s.text),
                ),
            ],
          ),
          for (final s in _scenarios)
            if (current == s.text)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded,
                        size: 13, color: p.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Beklenen: ${s.expectation}',
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
      ),
    );
  }

  Widget _replyingBanner(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right_rounded,
              size: 14, color: p.textTertiary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '@${widget.replyingTo} kullanıcısına yanıt veriyorsun',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: p.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputRow(AppPalette p) {
    final field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      style: TextStyle(fontSize: 16, color: p.textPrimary, height: 1.45),
      decoration: InputDecoration(
        hintText: _hint,
        hintStyle: TextStyle(color: p.textTertiary, fontSize: 15.5),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );

    if (!widget.showAvatar) return field;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const UserAvatar.currentUser(size: 38),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: field),
      ],
    );
  }

  Widget _toolbar(
      AppPalette p, RiskLevel risk, Color riskColor, bool hasText) {
    return Row(
      children: [
        if (widget.showToolbar) ...[
          const _ToolbarIcon(icon: Icons.image_outlined, tooltip: 'Görsel ekle'),
          const _ToolbarIcon(icon: Icons.bar_chart_rounded, tooltip: 'Anket ekle'),
          const _ToolbarIcon(
              icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji ekle'),
          const SizedBox(width: AppSpacing.sm),
        ],

        // Risk göstergesi — merdivenin ilk basamağı. Metin yokken ya da
        // temizken hiçbir şey söylemez.
        Expanded(child: _riskMeter(p, risk, riskColor, hasText)),

        if (widget.onSubmit != null) ...[
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: hasText ? _submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: Text(_submitLabel),
          ),
        ] else if (hasText) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () => _controller.clear(),
            icon: const Icon(Icons.backspace_outlined, size: 18),
            color: p.textTertiary,
            tooltip: 'Temizle',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  /// Dört basamaklı risk şeridi + çözümleme süresi.
  ///
  /// Süreyi göstermek bir hata ayıklama alışkanlığı değil, ürün iddiasının
  /// kanıtıdır: "cihazda, her tuş vuruşunda, kare bütçesinin altında".
  /// Jüri bunu okumadan iddiaya inanmak zorunda kalır.
  Widget _riskMeter(
      AppPalette p, RiskLevel risk, Color riskColor, bool hasText) {
    final elapsed = _analysis?.elapsed.inMicroseconds;

    return Semantics(
      liveRegion: true,
      label: hasText
          ? 'Üslup durumu: ${risk.label}. ${risk.intervention}.'
          : 'Üslup hazır',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < RiskLevel.values.length; i++)
              AnimatedContainer(
                duration: AppDurations.fast,
                margin: const EdgeInsets.only(right: 3),
                width: i <= risk.index && hasText ? 14 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: hasText && i <= risk.index
                      ? riskColor
                      : p.border,
                  borderRadius: AppRadius.pill,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                !hasText
                    ? 'Üslup hazır'
                    : elapsed == null
                        ? risk.label
                        : '${risk.label} · $elapsed µs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasText && risk != RiskLevel.temiz
                      ? riskColor
                      : p.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Gerekçe paneli (şeffaflık) ───────────────────────────────────────────

  Widget _reasonPanel(AppPalette p, CivilityAnalysis analysis) {
    final color = _riskColor(p, analysis.risk);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _reasonsExpanded = !_reasonsExpanded),
            borderRadius: AppRadius.lgAll,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                  AppSpacing.md, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.visibility_rounded, size: 16, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Neden uyarıldın?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${analysis.findings.length} tespit',
                    style: TextStyle(fontSize: 11.5, color: p.textTertiary),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _reasonsExpanded ? 0.5 : 0,
                    duration: AppDurations.fast,
                    child: Icon(Icons.expand_more_rounded,
                        size: 18, color: p.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, 0, AppSpacing.base, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final finding in analysis.findings)
                    _FindingRow(
                      finding: finding,
                      color: _severityColor(p, finding.adjustedSeverity),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phonelink_lock_rounded,
                          size: 12, color: p.textTertiary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Bu çözümleme telefonunda yapıldı. Metin cihazdan '
                          'çıkmadı.',
                          style:
                              TextStyle(fontSize: 11, color: p.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _reasonsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.fast,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0);
  }

  // ─── Yeniden yazma önerisi ────────────────────────────────────────────────

  Widget _suggestionCard(AppPalette p, RewriteSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: p.successSoft,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: p.success.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 16, color: p.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Böyle mi demek istedin?',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              AppBadgePill(
                label: '${suggestion.projectedCivilityScore} puan',
                color: p.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            suggestion.text,
            style: TextStyle(fontSize: 15, color: p.textPrimary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  // Karar KULLANICININ. Sistem asla kendiliğinden değiştirmez.
                  onPressed: () => _applySuggestion(suggestion),
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
          Row(
            children: [
              Icon(Icons.memory_rounded, size: 11, color: p.textTertiary),
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
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.05, end: 0);
  }

  /// Uyarı alıp düzelten kullanıcıya olumlu geri bildirim.
  ///
  /// Yalnızca daha önce uyarı görülmüşse çıkar. Her temiz cümlede
  /// "aferin" demek, geri bildirimi gürültüye çevirir.
  Widget _resolvedBanner(AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md),
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
              'Şimdi gönderilebilir. Uyarı kayda geçmedi.',
              style: TextStyle(fontSize: 13.5, color: p.textPrimary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ─── Alt bileşenler ──────────────────────────────────────────────────────────

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Bu düğmeler prototipte işlevsizdir ve öyle görünürler (soluk).
    // Çalışıyormuş gibi göstermek, çalışan katmanın güvenilirliğini düşürür.
    return Tooltip(
      message: '$tooltip — prototipte etkin değil',
      child: Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Icon(icon, size: 19, color: p.textTertiary.withValues(alpha: 0.55)),
      ),
    );
  }
}

class _ScenarioChip extends StatelessWidget {
  const _ScenarioChip({
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
            // Seçilebilir bir çipin sınırı işlevsel bilgidir (WCAG 1.4.11):
            // kullanıcı dokunulabilir alanın nerede bittiğini oradan anlar.
            border: Border.all(
                color: selected ? p.brandInk : p.borderStrong,
                width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? p.brandInk : p.textSecondary,
            ),
          ),
        ),
      ),
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
            margin: const EdgeInsets.only(top: 1),
            constraints: const BoxConstraints(maxWidth: 132),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: p.isDark ? 0.22 : 0.12),
              borderRadius: AppRadius.xsAll,
            ),
            child: Text(
              finding.matchedText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        finding.sourceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 10, color: p.textTertiary),
                      ),
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
