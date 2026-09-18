// =============================================================================
// İlk açılış turu — üç adımda ürünün tamamı (docs/24 · madde 31)
// Dosya: mobile/lib/presentation/intro/intro_tour.dart
//
// Uygulama açıldığında ekranda bir sosyal akış görünür ve katmanın kendisi
// görünmez: kullanıcı (ya da jüri) bir şey yazmadıkça Üslup'un ne yaptığını
// bilmez. Tur üç cümleyle bunu söyler:
//
//   1. Yazarken çözümler — bu cihazda, metin hiçbir yere gitmez.
//   2. Neden uyardığını söyler ve aynı fikri saldırmadan söylemenin yolunu
//      önerir. Bu adımdaki örnek, motorun GERÇEK çıktısıdır; elle yazılmış bir
//      ekran görüntüsü değil.
//   3. Karar senin — hiçbir şey engellenmez.
//
// ── NE ZAMAN AÇILIR ───────────────────────────────────────────────────────
// Yalnızca `main()` uygulamayı `showIntro: true` ile başlattığında ve oturum
// başına bir kez. Kalıcı "bir daha gösterme" kaydı TUTULMAZ: uygulama diske
// hiçbir şey yazmaz (docs/16). Hakkında ekranından yeniden açılabilir.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/social_widgets.dart';

/// Kabuğu sarar ve ilk karede turu bir kez açar.
class IntroGate extends StatefulWidget {
  const IntroGate({super.key, required this.child});

  final Widget child;

  /// "Oturumda bir kez" bayrağını sıfırlar — aynı süreçte birden çok
  /// uygulama kuran testler ve ekran görüntüsü aracı için.
  @visibleForTesting
  static void resetForTest() => _IntroGateState._gosterildi = false;

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> {
  /// Tema değişimi ağacı yeniden kurar; tur oturumda yalnızca bir kez açılır.
  static bool _gosterildi = false;

  @override
  void initState() {
    super.initState();
    if (_gosterildi) return;
    _gosterildi = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) IntroTour.show(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class IntroTour extends StatefulWidget {
  const IntroTour({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (_) => const IntroTour(),
      );

  @override
  State<IntroTour> createState() => _IntroTourState();
}

class _IntroTourState extends State<IntroTour> {
  final _sayfa = PageController();
  int _index = 0;

  static const _ornek = 'Sen tam bir aptalsın';

  // Örnek, motorun gerçek çıktısıdır; tur açılırken bir kez hesaplanır.
  late final CivilityAnalysis _analiz = Civility.engine.analyze(_ornek);
  late final Future<RewriteSuggestion?> _oneri =
      Civility.suggester.suggest(_analiz);

  @override
  void dispose() {
    _sayfa.dispose();
    super.dispose();
  }

  void _ileri() {
    HapticFeedback.selectionClick();
    if (_index == 2) {
      Navigator.of(context).maybePop();
      return;
    }
    _sayfa.nextPage(duration: AppDurations.slow, curve: AppCurves.standard);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dar = MediaQuery.sizeOf(context).width < 480;

    return Dialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.all(dar ? AppSpacing.base : AppSpacing.xl),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const BrandMark(size: 28, showWordmark: true),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: TextButton.styleFrom(foregroundColor: p.textTertiary),
                    child: const Text('Geç'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: SizedBox(
                  height: 380,
                  child: PageView(
                    controller: _sayfa,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      const _Adim(
                        ikon: Icons.edit_note_rounded,
                        baslik: 'Yazarken çözümler',
                        metin: 'Gönderi ya da yorum yazarken her cümlen bu '
                            'cihazda çözümlenir. Metin hiçbir yere '
                            'gönderilmez; uygulamanın internet izni bile yok.',
                        alt: _Rozet(
                          ikon: Icons.phonelink_lock_rounded,
                          metin: 'Cihaz üstü · ${Civility.gecikmeP50} (p50)',
                        ),
                      ),
                      _Adim(
                        ikon: Icons.auto_fix_high_rounded,
                        baslik: 'Nedenini söyler, öneri sunar',
                        metin: 'Saldırgan bir ifade görürse neden uyardığını '
                            'açıklar ve aynı fikri saldırmadan söylemenin '
                            'yolunu önerir.',
                        alt: _CanliOrnek(analiz: _analiz, oneri: _oneri),
                      ),
                      const _Adim(
                        ikon: Icons.verified_user_rounded,
                        baslik: 'Karar senin',
                        metin: 'Hiçbir şey engellenmez ya da kendiliğinden '
                            'değiştirilmez. Öneriyi kullanabilir, kendin '
                            'düzeltebilir ya da olduğu gibi gönderebilirsin.',
                        alt: _Rozet(
                          ikon: Icons.balance_rounded,
                          metin: 'Sansür değil, farkındalık',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: AppDurations.normal,
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? p.brand : p.border,
                        borderRadius: AppRadius.pill,
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _ileri,
                    child: Text(_index == 2 ? 'Başla' : 'İleri'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Adim extends StatelessWidget {
  const _Adim({
    required this.ikon,
    required this.baslik,
    required this.metin,
    required this.alt,
  });

  final IconData ikon;
  final String baslik;
  final String metin;
  final Widget alt;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: p.brandGradient,
              borderRadius: AppRadius.lgAll,
            ),
            child: Icon(ikon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            baslik,
            style: appDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            metin,
            style: appBody(fontSize: 15, color: p.textSecondary, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          alt,
        ],
      ),
    );
  }
}

class _Rozet extends StatelessWidget {
  const _Rozet({required this.ikon, required this.metin});

  final IconData ikon;
  final String metin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 16, color: p.brandInk),
          const SizedBox(width: 6),
          Flexible(
            child: Text(metin,
                style: appBody(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary)),
          ),
        ],
      ),
    );
  }
}

/// İkinci adımdaki örnek: motorun gerçek kararı ve gerçek önerisi.
class _CanliOrnek extends StatelessWidget {
  const _CanliOrnek({required this.analiz, required this.oneri});

  final CivilityAnalysis analiz;
  final Future<RewriteSuggestion?> oneri;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final renk = analiz.risk.index >= RiskLevel.riskli.index ? p.warning : p.info;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: renk.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(analiz.text,
                    style: appBody(fontSize: 14.5, color: p.textPrimary)),
              ),
              AppBadgePill(label: analiz.risk.label, color: renk),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Icon(Icons.south_rounded, size: 18, color: p.textTertiary),
        const SizedBox(height: 6),
        FutureBuilder<RewriteSuggestion?>(
          future: oneri,
          builder: (context, snap) {
            final metin = snap.data?.text;
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: p.successSoft,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: p.success.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high_rounded, size: 16, color: p.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(metin ?? '…',
                        style: appBody(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
