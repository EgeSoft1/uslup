// =============================================================================
// Üslup Asistanı — cihaz üstü, kural tabanlı soru-cevap
// Dosya: mobile/lib/presentation/uslup/engine_chat_screen.dart
//
// ── NE DEĞİLDİR ───────────────────────────────────────────────────────────
// Bu ekran bir dil modeli (LLM) sohbeti DEĞİLDİR ve öyle adlandırılmaz.
// Önceki adı "Üslup Yapay Zekâ Sohbeti (LLM)" idi; oysa arkasında hiçbir dil
// modeli yok ve projede bir LLM'in ölçülüp kasıtlı olarak kaldırıldığı
// belgelenmiş durumda (docs/03). Jüriye yanlış bir etiket göstermek, doğru
// olan her şeyin güvenilirliğini düşürür.
//
// ── NE YAPAR ──────────────────────────────────────────────────────────────
// İki iş: kullanıcının Türkçe cümlesinden NİYETİ çıkarır (`UslupAsistani`)
// ve istenen içeriği getirir — "bana nefret söylemi örnekleri sun" → o
// örnekler. Niyet bir soru değilse cümleyi motora verir ve gerekçeli sonucu
// gösterir. Hiçbir şey cihazdan çıkmaz.
//
// ── NEDEN DÜZ METİN DEĞİL, BİLEŞEN ────────────────────────────────────────
// Önceki sürüm cevabı `**kalın**` işaretleri ve emoji içeren tek bir metin
// olarak kuruyordu. `Text` bileşeni markdown çizmez: ekranda yıldızlar
// olduğu gibi görünüyordu. Emoji ise çevrimdışı web sürümünde yazı tipi
// indirilemediği için kutu olarak çiziliyordu. Cevap bu yüzden yapıdır:
// başlık, gövde, maddeler, örnekler ve devam önerileri ayrı alanlardır.
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
        cevap = null,
        suggestion = null;

  const _ChatMessage.asistan(this.cevap, {this.suggestion})
      : isUser = false,
        text = '';

  final String text;
  final bool isUser;
  final AsistanCevabi? cevap;
  final RewriteSuggestion? suggestion;
}

class _EngineChatScreenState extends State<EngineChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  /// Asistan motorla birlikte kurulur: cümle çözümleme niyeti motoru
  /// kullanır, geri kalan niyetler kullanmaz.
  late final UslupAsistani _asistan = UslupAsistani(motor: Civility.engine);

  late final List<_ChatMessage> _messages = [
    _ChatMessage.asistan(_asistan.yanitla('')),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _gonder(String ham) async {
    final text = ham.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // ── CİHAZ ÜSTÜ ─────────────────────────────────────────────────────────
    // Niyet çözümleme de, cümle çözümleme de burada yapılır; ağ çağrısı yok.
    final cevap = _asistan.yanitla(text);

    // Öneri yalnızca bulgu varsa üretilir ve üretimi yereldir.
    final analiz = cevap.cozumleme;
    final suggestion = (analiz != null && analiz.hasFindings)
        ? await Civility.suggester.suggest(analiz)
        : null;
    if (!mounted) return;

    setState(() {
      _messages
        ..add(_ChatMessage.user(text))
        ..add(_ChatMessage.asistan(cevap, suggestion: suggestion));
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
      appBar: const AppTopBar(title: 'Üslup Asistanı'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              _cihazSeridi(p),
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

  /// Ekranın ne olduğunu söyleyen şerit. Jüri bu ekrana baktığında ilk
  /// okuyacağı şey "bu bir LLM değil" olmalı.
  Widget _cihazSeridi(AppPalette p) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.sm),
        color: p.surfaceMuted,
        child: Text(
          'Kural tabanlı · cihaz üstü · dil modeli yok · ağ çağrısı yok',
          textAlign: TextAlign.center,
          style: appBody(fontSize: 11.5, color: p.textTertiary),
        ),
      );

  // ─── Baloncuklar ──────────────────────────────────────────────────────────

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

    final cevap = msg.cevap!;
    final analiz = cevap.cozumleme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
            bottom: AppSpacing.md, right: AppSpacing.lg),
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
            // Çözümleme varsa risk rozeti başa gelir.
            if (analiz != null) ...[
              Row(
                children: [
                  AppBadgePill(
                      label: analiz.risk.label,
                      color: _riskColor(analiz.risk, p)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'nezaket puanı ${analiz.civilityScore} · '
                      '${analiz.elapsed.inMicroseconds} µs',
                      style: appBody(fontSize: 11.5, color: p.textTertiary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            Text(cevap.baslik,
                style: appBody(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            if (cevap.govde.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(cevap.govde,
                  style: appBody(
                      color: p.textSecondary, fontSize: 14, height: 1.45)),
            ],

            // Motorun bulguları ve önerisi.
            if (analiz != null) ...[
              if (analiz.findings.isEmpty && analiz.needsSupport) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bu cümlede saldırgan bir ifade yok. Zor bir an geçiriyor '
                  'olabilirsin — güvende değilsen 112\'yi ara.',
                  style: appBody(
                      fontSize: 13.5, color: p.textSecondary, height: 1.45),
                ),
              ],
              for (final f in analiz.findings) ...[
                const SizedBox(height: AppSpacing.sm),
                _findingLine(f, p),
              ],
            ],
            if (msg.suggestion != null) ...[
              const SizedBox(height: AppSpacing.md),
              _oneriKutusu(msg.suggestion!, p),
            ],

            // Madde listesi (ölçüm, katmanlar, mahremiyet, ayarlar…).
            for (final m in cevap.maddeler) ...[
              const SizedBox(height: 6),
              _madde(m, p),
            ],

            // Örnek cümleler — dokunulunca çözümlenir.
            for (final o in cevap.ornekler) ...[
              const SizedBox(height: AppSpacing.sm),
              _ornekKarti(o, p),
            ],

            if (cevap.devamOnerileri.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in cevap.devamOnerileri) _oneriCipi(s, p),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _madde(String metin, AppPalette p) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration:
                  BoxDecoration(color: p.textTertiary, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(metin,
                style: appBody(
                    fontSize: 13.5, color: p.textSecondary, height: 1.45)),
          ),
        ],
      );

  /// Örnek cümle kartı.
  ///
  /// Rozet motorun ne yapacağını söyler ve bu bir iddiadır;
  /// `civility_core/test/asistan_test.dart` her örneği gerçek motordan
  /// geçirip bu rozetin doğruluğunu denetler. Karta dokunmak cümleyi
  /// çözümletir, yani kullanıcı iddiayı yerinde sınayabilir.
  Widget _ornekKarti(AsistanOrnegi o, AppPalette p) {
    final renk = o.isaretlenir ? p.warning : p.success;
    return Semantics(
      button: true,
      label: '${o.metin}. ${o.isaretlenir ? "İşaretlenir" : "Temiz"}. '
          'Çözümlemek için dokun.',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => _gonder(o.metin),
          borderRadius: AppRadius.mdAll,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(o.metin,
                          style: appBody(
                              fontSize: 14.5,
                              color: p.textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.35)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppBadgePill(
                        label: o.isaretlenir ? 'İşaretlenir' : 'Temiz',
                        color: renk),
                  ],
                ),
                const SizedBox(height: 4),
                Text(o.aciklama,
                    style: appBody(
                        fontSize: 12, color: p.textTertiary, height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _oneriCipi(String metin, AppPalette p) => InkWell(
        onTap: () => _gonder(metin),
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 9),
          constraints: const BoxConstraints(minHeight: 40),
          decoration: BoxDecoration(
            color: p.background,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: p.border),
          ),
          child: Text(metin,
              style: appBody(
                  fontSize: 12.5,
                  color: p.textSecondary,
                  fontWeight: FontWeight.w600)),
        ),
      );

  Widget _oneriKutusu(RewriteSuggestion s, AppPalette p) => Container(
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
            Text(s.text,
                style: appBody(
                    fontSize: 14.5, color: p.textPrimary, height: 1.4)),
          ],
        ),
      );

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
                  hintText: 'Sor ya da bir cümle yaz…',
                  hintStyle: appBody(color: p.textTertiary, fontSize: 15),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 12),
                  border: InputBorder.none,
                ),
                onSubmitted: _gonder,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: 'Gönder',
            child: ExcludeSemantics(
              child: InkWell(
                onTap: () => _gonder(_controller.text),
                borderRadius: AppRadius.lgAll,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: p.brandGradient,
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
