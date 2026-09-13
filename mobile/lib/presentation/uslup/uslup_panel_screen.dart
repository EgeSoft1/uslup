// =============================================================================
// Üslup Paneli — katmanın kendisi, canlı denemesi ve ölçümleri
// Dosya: mobile/lib/presentation/uslup/uslup_panel_screen.dart
//
// Bu ekran ürünün HESAP VERDİĞİ yerdir. Akış ve gönderi kutusu katmanın ne
// yaptığını gösterir; burası ne kadar iyi yaptığını ve nerede yanıldığını.
//
// ── SIRALAMA KARARI (13 Eylül 2026) ───────────────────────────────────────
// Önceki sürümde ekranın ilk görünen kısmının tamamını büyük bir başlık,
// gecikme grafiği ve istatistik kartları kaplıyordu; canlı deneme kutusu
// ancak kaydırınca görünüyordu. Jüri sunumunda ilk 5 saniyede görülmesi
// gereken şey KATMANIN ÇALIŞMASIDIR, sayılar değil. Yeni sıra:
//
//   1. Kısa başlık       — ne olduğu, tek cümle, çalışma anında sayılan rakamlar
//   2. Canlı deneme      — yazım kutusu + senaryo çipleri
//   3. Bağlam karnesi    — 12 senaryonun HEPSİ, beklenti ve gerçek sonuç yan yana
//   4. Canlı gecikme     — motor bu cihazda çalıştırılıp ölçülüyor
//   5. Sistem detayları  — işlem hattı, ölçüm geçmişi, ilkeler
//
// ── KALDIRILANLAR ─────────────────────────────────────────────────────────
// "VDS Modeli Güncelle" düğmesi: sabit sayılardan oluşan sahte bir "gradyan"
// paketini bir sunucuya gönderen katmanı tetikliyordu. Aynı ekran "tek bir
// ağ çağrısı yapmıyor" diyordu. Düğme ve katman birlikte silindi.
// =============================================================================

import 'dart:async';

import 'package:civility_core/civility_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/social/social_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../compose/civility_composer.dart';
import '../settings/about_screen.dart';
import '../widgets/social_widgets.dart';
import 'demo_scenarios.dart';
import 'engine_chat_screen.dart';

class UslupPanelScreen extends StatelessWidget {
  const UslupPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            const _Hero(),
            const SectionLabel(text: 'CANLI DENEME'),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bir cümle yaz ya da hazır senaryolara dokun. Çözümleme '
                    'bu cihazda, her tuş vuruşunda yapılır; hiçbir şey '
                    'gönderilmez.',
                    style: appBody(
                        fontSize: 13, color: p.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Gönderim geri çağrısı YOK: burada gönderilecek bir yer
                  // yok, gösterilecek bir davranış var.
                  const CivilityComposer(
                    showAvatar: false,
                    showToolbar: false,
                    showScenarios: true,
                    surface: ComposerSurface.deneme,
                    minLines: 3,
                    maxLines: 8,
                  ),
                ],
              ),
            ),
            const SectionLabel(text: 'BAĞLAM KARNESİ'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: _ContextScorecard(),
            ),
            const SectionLabel(text: 'CANLI GECİKME · BU CİHAZDA ÖLÇÜLÜYOR'),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Container(
                height: 190,
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220),
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: p.brand.withValues(alpha: 0.35)),
                ),
                child: const _LiveLatencyGraph(),
              ),
            ),
            const SectionLabel(text: 'DAHA FAZLASI'),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                children: [
                  _NavCard(
                    icon: Icons.analytics_rounded,
                    title: 'Sistem detayları',
                    subtitle: 'İşlem hattı · ölçüm geçmişi · yanmış kümeler · '
                        'ilkeler',
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute<void>(
                          builder: (_) => const UslupDetailsScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _NavCard(
                    icon: Icons.forum_rounded,
                    title: 'Motorla soru-cevap',
                    subtitle: 'Bir cümle yaz, motor gerekçesiyle cevaplasın',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const EngineChatScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _NavCard(
                    icon: Icons.description_outlined,
                    title: 'Proje künyesi',
                    subtitle: 'Durum, teknoloji, mahremiyet',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const AboutScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Başlık ──────────────────────────────────────────────────────────────────

/// Kısa marka başlığı.
///
/// Koyu marka gradyanı (`heroGradient`) üzerinde beyaz metin — her iki
/// ucunda da en az 5,19:1 kontrast verir. Camgöbeğine kaçan `brandGradient`
/// burada KULLANILAMAZ; üzerine paragraf yazılamaz.
///
/// Rakamların hiçbiri elle yazılmaz: sözlük, örüntü ve örnek sayıları
/// çalışma anında motordan sayılır.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: p.heroGradient),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -70,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Ü',
                        style: appDisplay(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Üslup',
                        style: appDisplay(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const _OfflinePill(),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Saldırgan bir cümle gönderilmeden önce, yazıldığı cihazda '
                  'fark edilir. Sistem engellemez — önerir, gerekçesini '
                  'söyler, kararı sana bırakır.',
                  style: appBody(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Dar ekranda 2×2, geniş ekranda tek sıra.
                    final perRow = constraints.maxWidth >= 520 ? 4 : 2;
                    final chipWidth = (constraints.maxWidth -
                            AppSpacing.sm * (perRow - 1)) /
                        perRow;
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final stat in [
                          ('${Civility.sozlukGirdisi}', 'sözlük girdisi'),
                          ('${Civility.oruntuSayisi}', 'örüntü ve deyim'),
                          ('${Civility.etiketliOrnek}', 'etiketli örnek'),
                          (Civility.gecikmeP50, 'tipik çözümleme'),
                        ])
                          SizedBox(
                            width: chipWidth,
                            child: _StatChip(value: stat.$1, label: stat.$2),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                // ── OTURUM SAYAÇLARI ──────────────────────────────────────
                // Elle yazılmış "Engellenen Mesaj: 1450" gibi sabitlerin
                // yerine bu oturumun GERÇEK sayaçları. Demoda jürinin gözü
                // önünde artmaları, sabit bir sayıdan daha ikna edicidir.
                ListenableBuilder(
                  listenable: SocialStore.instance,
                  builder: (context, _) {
                    final store = SocialStore.instance;
                    return Row(
                      children: [
                        Expanded(
                          child: _HeroCounter(
                            label: 'bu oturumda gönderim',
                            value: '${store.sentThisSession}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _HeroCounter(
                            label: 'uyarıdan sonra düzeltilen',
                            value: '${store.revisedThisSession}',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .slideY(begin: -0.03, end: 0, curve: AppCurves.standard);
  }
}

class _OfflinePill extends StatelessWidget {
  const _OfflinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.pill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            'Çevrimdışı çalışır',
            style: appBody(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 2, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: appDisplay(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appBody(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCounter extends StatelessWidget {
  const _HeroCounter({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Text(
            value,
            style: appDisplay(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: appBody(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bağlam karnesi ──────────────────────────────────────────────────────────

/// Bütün demo senaryolarının, bu cihazda şu anda motordan geçirilmiş sonucu.
///
/// ── NEDEN TABLO ───────────────────────────────────────────────────────────
/// Çiplerle senaryoları tek tek göstermek canlı anlatım için iyidir ama
/// jüri aynı anda en fazla bir sonuç görür. Karne on iki sonucu tek bakışta
/// verir ve her satırda BEKLENTİYİ de yazar: "Sen tam bir aptalsın"
/// işaretlenir, "Bana 'aptal' dedi" işaretlenmez — ve bu satırlar bir
/// slayttan değil, motorun kendisinden gelir.
class _ContextScorecard extends StatelessWidget {
  const _ContextScorecard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final results = [
      for (final s in demoScenarios) (s, Civility.engine.analyze(s.text)),
    ];
    final matched = results
        .where((r) => (r.$2.risk != RiskLevel.temiz) == r.$1.expectFlag)
        .length;
    final allMatched = matched == results.length;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aynı kelime, farklı bağlam',
                        style: appDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Her satır şu anda bu cihazda motordan geçirildi. '
                        'Beklenti, motor çalışmadan önce yazıldı.',
                        style: appBody(
                            fontSize: 12, color: p.textTertiary, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppBadgePill(
                  label: '$matched/${results.length} beklendiği gibi',
                  color: allMatched ? p.success : p.warning,
                  icon: allMatched
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.divider),
          for (var i = 0; i < results.length; i++) ...[
            _ScorecardRow(scenario: results[i].$1, analysis: results[i].$2),
            if (i < results.length - 1)
              Divider(
                  height: 1,
                  indent: AppSpacing.base,
                  endIndent: AppSpacing.base,
                  color: p.divider),
          ],
        ],
      ),
    );
  }
}

class _ScorecardRow extends StatelessWidget {
  const _ScorecardRow({required this.scenario, required this.analysis});

  final DemoScenario scenario;
  final CivilityAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final flagged = analysis.risk != RiskLevel.temiz;
    final ok = flagged == scenario.expectFlag;
    final riskColor = switch (analysis.risk) {
      RiskLevel.temiz => p.success,
      RiskLevel.dikkat => p.info,
      RiskLevel.riskli => p.warning,
      RiskLevel.yuksek => p.danger,
    };

    return Semantics(
      label: '${scenario.label}: ${scenario.text}. Sonuç ${analysis.risk.label}. '
          '${ok ? "Beklendiği gibi" : "Beklenenden farklı"}.',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.label,
                      style: appBody(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '“${scenario.text}”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: appBody(
                          fontSize: 12.5, color: p.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Sabit genişlik DEĞİL, alt sınır: satırlar hizalı durur ama
              // "Yüksek risk" büyük yazı ölçeğinde (1,3×) kutuyu taşırmaz.
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 86),
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: 1,
                  child: AppBadgePill(
                    label: analysis.risk.label,
                    color: riskColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                ok ? Icons.check_rounded : Icons.close_rounded,
                size: 18,
                color: ok ? p.success : p.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gezinme kartı ───────────────────────────────────────────────────────────

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      color: p.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.brandSoft,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, size: 20, color: p.brandInk),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: appBody(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: appBody(fontSize: 12, color: p.textTertiary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Canlı gecikme grafiği ───────────────────────────────────────────────────

/// Motoru bu cihazda gerçekten çalıştırıp ölçülen süreyi çizen grafik.
///
/// ── NEDEN GERÇEK ÖLÇÜM ────────────────────────────────────────────────────
/// Önceki bir sürüm `Random()` ile "ağ tehdit yoğunluğu" çiziyordu. Ürünün
/// ağ savunması yok; grafiğin ölçtüğü bir şey de yoktu. Şimdi her nokta
/// gerçek bir çözümlemedir: senaryo cümlelerinden biri motora verilir ve
/// `analysis.elapsed` noktalanır.
///
/// ── NEDEN BİTEN BİR ÖLÇÜM ────────────────────────────────────────────────
/// Hiç durmayan bir zamanlayıcı `pumpAndSettle`'ı sonlandırmaz ve ekranda
/// "sürekli bir şey oluyor" havası yaratır. Sayısı ve sonucu olan bir ölçüm
/// koşusu daha dürüsttür; "Yeniden ölç" ile tekrarlanabilir.
class _LiveLatencyGraph extends StatefulWidget {
  const _LiveLatencyGraph();

  @override
  State<_LiveLatencyGraph> createState() => _LiveLatencyGraphState();
}

class _LiveLatencyGraphState extends State<_LiveLatencyGraph> {
  static const int _ornekSayisi = 50;

  final List<int> _points = <int>[];

  Timer? _timer;
  int _cursor = 0;

  @override
  void initState() {
    super.initState();
    _olc();
  }

  void _olc() {
    _timer?.cancel();
    setState(() {
      _points.clear();
      _cursor = 0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final metin = demoScenarios[_cursor % demoScenarios.length].text;
      final elapsed = Civility.engine.analyze(metin).elapsed.inMicroseconds;

      setState(() {
        _points.add(elapsed);
        _cursor++;
      });

      if (_points.length >= _ornekSayisi) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Ortanca — ortalama değil. Tek bir yavaş kare (çöp toplama, ilk
  /// çalıştırmadaki ısınma) ortalamayı sürükler; raporlanan sayı da p50'dir.
  int get _median {
    if (_points.isEmpty) return 0;
    final sorted = [..._points]..sort();
    return sorted[sorted.length ~/ 2];
  }

  int get _worst =>
      _points.isEmpty ? 0 : _points.reduce((a, b) => a > b ? a : b);

  bool get _bitti => _points.length >= _ornekSayisi;

  String _ms(int micro) =>
      '${(micro / 1000).toStringAsFixed(2).replaceAll('.', ',')} ms';

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4ADE80);
    final enBuyuk = _points.isEmpty ? 1 : _worst;
    final butce = _median == 0 ? 0.0 : _median / 16000 * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _bitti ? Icons.check_circle_rounded : Icons.bolt_rounded,
              color: accent,
              size: 14,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _bitti
                    ? '$_ornekSayisi ÇÖZÜMLEME TAMAMLANDI'
                    : 'MOTOR ÇALIŞIYOR · ${_points.length}/$_ornekSayisi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appBody(
                    color: accent, fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
            if (_bitti)
              TextButton(
                onPressed: _olc,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Yeniden ölç',
                    style: appBody(
                        color: accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _ms(_median),
              style: appDisplay(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'ortanca · 16 ms\'lik karenin '
                '%${butce.toStringAsFixed(1).replaceAll('.', ',')}\'i',
                style: appBody(color: Colors.white70, fontSize: 11.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: CustomPaint(
            painter: _LatencyPainter(List.of(_points), enBuyuk, _ornekSayisi),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Her nokta bu cihazda gerçekten çalıştırılan bir çözümlemedir · '
          'en yavaşı ${_ms(_worst)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appBody(color: Colors.white54, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _LatencyPainter extends CustomPainter {
  _LatencyPainter(this.points, this.maxValue, this.slots);

  final List<int> points;
  final int maxValue;

  /// Toplam yuva sayısı. Çizgi soldan sağa DOLAR; ölçüm ilerledikçe
  /// noktalar kaymaz. Kayan bir eksen, süre karşılaştırmasını imkânsız
  /// kılardı.
  final int slots;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || maxValue <= 0 || slots < 2) return;

    const accent = Color(0xFF4ADE80);
    final step = size.width / (slots - 1);
    double yOf(int v) => size.height - (v / maxValue) * size.height * 0.92;

    final sorted = [...points]..sort();
    final median = sorted[sorted.length ~/ 2];
    canvas.drawLine(
      Offset(0, yOf(median)),
      Offset(size.width, yOf(median)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.20)
        ..strokeWidth = 1,
    );

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * step;
      final y = yOf(points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    final lastX = (points.length - 1) * step;
    canvas.drawCircle(
        Offset(lastX, yOf(points.last)), 3.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_LatencyPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.maxValue != maxValue;
}

// ─── Sistem detayları ────────────────────────────────────────────────────────

class UslupDetailsScreen extends StatelessWidget {
  const UslupDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        iconTheme: IconThemeData(color: p.textPrimary),
        title: Text('Sistem detayları',
            style: appBody(color: p.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                const SectionLabel(text: 'NASIL ÇALIŞIR'),
                _pipeline(p),
                const SectionLabel(text: 'ÖLÇÜM GEÇMİŞİ'),
                _measurements(p),
                const SectionLabel(text: 'KATMAN KATKISI'),
                _layerContribution(p),
                const SectionLabel(text: 'GECİKME'),
                _latency(p),
                const SectionLabel(text: 'İLKELER'),
                _principles(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pipeline(AppPalette p) {
    final steps = <({String title, String detail})>[
      (
        title: 'Normalizasyon',
        detail: 'Gizleme hilelerini geri çevirir: \$3r3fsiz, a.p.t.a.l, '
            'şerefsiiiz, salaq. Türkçe küçük harf tablosu elle yazıldı — '
            'Dart\'ın kendi işlevi "I" harfini yanlış çeviriyor.'
      ),
      (
        title: 'Sözlük katmanı',
        detail: '${Civility.sozlukGirdisi} girdi. Her girdi kategori, taban '
            'şiddet, eşleşme kipi, yönelim şartı ve nötr karşılık taşır. '
            'Türkçe eklemeli olduğu için kök + çekim eki doğrulanır.'
      ),
      (
        title: 'Edimbilimsel örüntü ve deyim',
        detail: '${Civility.oruntuSayisi} örüntü. Saldırganlığı kelimelerde '
            'değil kelimelerin DİZİLİŞİNDE arar: "Senin gibilerden bu '
            'beklenirdi" tek bir yasaklı kelime içermez.'
      ),
      (
        title: 'Nefret söylemi',
        detail: 'Kimlik adı yasaklı kelime DEĞİLDİR; yalnızca düşmanca bir '
            'kuruluşun içindeki yuvayı doldurur. "Ben Kürtüm" işaretlenmez '
            've bu, yapısal bir testle korunur.'
      ),
      (
        title: 'Gönderge çözümlemesi',
        detail: 'Cümleler arası bağ kurar: "Suriyeliler her yeri doldurdu. '
            'Bunların…" — kimlik yuvası ikinci cümlede yoktur.'
      ),
      (
        title: 'Bağlam ağırlıklandırma',
        detail: 'Aynı sözcük saldırı, iltifat, şikâyet ve öz-ifade '
            'eksenlerinde yeniden ağırlıklandırılır. Yumuşatma bir çarpan '
            'DEĞİL bir tavandır: aktarılan bir hakaret, şiddeti ne olursa '
            'olsun eşiğin altında kalır.'
      ),
      (
        title: 'Skor birleştirme ve öneri',
        // Formül kasıtlı olarak yazılmadı: alt simge karakteri (sᵢ) gömülü
        // yazı tipinde yok ve çevrimdışı web sürümünde kutu olarak çizilirdi.
        detail: 'Bulguların şiddeti noisy-OR ile birleşir: birden fazla '
            'saldırı toplamı artırır ama skor 1\'i asla aşmaz. Öneri '
            'üretildikten sonra motor öneriyi YENİDEN çözümler; daha temiz '
            'değilse öneri gösterilmez.'
      ),
    ];

    return Container(
      color: p.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: p.brandSoft,
                      borderRadius: AppRadius.xsAll,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: appBody(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: p.brandInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          steps[i].title,
                          style: appBody(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].detail,
                          style: appBody(
                              fontSize: 12.5,
                              color: p.textSecondary,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _measurements(AppPalette p) {
    const rows = <({
      String kume,
      String boyut,
      String kesinlik,
      String duyarlilik,
      String f1,
      String durum,
      bool vurgu,
    })>[
      (
        kume: 'Geliştirme',
        boyut: '256',
        kesinlik: '%100,0',
        duyarlilik: '%99,2',
        f1: '%99,6',
        durum: 'Ezberleme payı içerir — genelleme kanıtı DEĞİLDİR',
        vurgu: false,
      ),
      (
        kume: '1. ayrık küme',
        boyut: '80',
        kesinlik: '—',
        duyarlilik: '—',
        f1: '%84,2',
        durum: 'İlk ölçüm. Motor bu kümeye bakılarak düzeltildi — yandı',
        vurgu: false,
      ),
      (
        kume: '2. ayrık küme (İP-15)',
        boyut: '100',
        kesinlik: '%100,0',
        duyarlilik: '%38,5',
        f1: '%55,6',
        durum: 'İlk ölçüm. Örtük saldırı diliminde duyarlılık %100 → %12,0',
        vurgu: false,
      ),
      (
        kume: '3. ayrık küme (İP-20)',
        boyut: '80',
        kesinlik: '%100,0',
        duyarlilik: '%50,0',
        f1: '%66,7',
        durum: 'İlk ölçüm. Kaçakların çoğu deyim — kural tabanlı katmanın '
            'tavanı',
        vurgu: false,
      ),
      (
        kume: '4. ayrık küme (İP-22)',
        boyut: '65',
        kesinlik: '%90,5',
        duyarlilik: '%54,3',
        f1: '%67,9',
        durum: 'İlk geçiş. Sonraki genişletme bu kümeye bakılarak yapıldı — '
            'yandı',
        vurgu: false,
      ),
      (
        kume: '5. ayrık küme (İP-27)',
        boyut: '90',
        kesinlik: 'kayıt yok',
        duyarlilik: '≈%48',
        f1: '—',
        durum: 'İlk geçişte 60 saldırgan örneğin 31\'i kaçtı. Deyim katmanı '
            'bu kaçaklara bakılarak yazıldı — yandı',
        vurgu: false,
      ),
      (
        kume: '6. ayrık küme (İP-29)',
        boyut: '90',
        kesinlik: '%96,4',
        duyarlilik: '%45,0',
        f1: '%61,4',
        durum: 'GEÇERLİ — bugünkü motor, ölçümden önce kilitlenmiş küme. '
            'Açık saldırı %83, örtük saldırı %32, masum 30\'da 29 temiz',
        vurgu: true,
      ),
    ];

    return Column(
      children: [
        Container(
          color: p.surface,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _MeasurementRow(row: rows[i]),
                if (i < rows.length - 1) Divider(height: 1, color: p.divider),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.md, AppSpacing.base, 0),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: p.warningSoft,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 16, color: p.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '"Yanmış" ne demek: motor bir kümeye bakılarak '
                    'düzeltildiğinde o küme artık ayrık değildir ve bir daha '
                    'genelleme ölçemez. Bu satırlar silinmedi, çünkü ölçümün '
                    'nasıl bozulduğunu göstermek de ölçümün parçasıdır.',
                    style: appBody(
                        fontSize: 11.5, color: p.textSecondary, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _layerContribution(AppPalette p) {
    return Container(
      color: p.surface,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aynı 256 örnek üzerinde, yalnız sözlük katmanı ile bütün '
            'örüntü katmanları ayrı ayrı ölçüldü '
            '(bin/evaluate.dart --karsilastir).',
            style:
                appBody(fontSize: 13, color: p.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.base),
          _CompareBar(
            label: 'Duyarlılık · yalnız sözlük',
            value: 45.1,
            color: p.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompareBar(
            label: 'Duyarlılık · tüm katmanlar',
            value: 99.2,
            color: p.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompareBar(
            label: 'Kesinlik · her iki yapılandırmada',
            value: 100.0,
            color: p.brandInk,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Duyarlılık 54,1 puan arttı ve kesinlikten hiçbir şey '
            'götürmedi. Örtük saldırı diliminde kazanç %1,8 → %100,0: '
            'küfürsüz düşmanlığı yalnızca örüntü katmanı görüyor.',
            style: appBody(
                fontSize: 12.5, color: p.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _latency(AppPalette p) {
    return Container(
      color: p.surface,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _metricTile(p, Civility.gecikmeP50, 'tipik (p50)')),
              Expanded(child: _metricTile(p, Civility.gecikmeP99, 'p99')),
              Expanded(
                  child: _metricTile(
                      p, Civility.kareButcesiP99, 'p99\'da kare bütçesi')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'AOT derlenmiş ikili üzerinde, 9 senaryo × 2000 tekrar ölçüldü. '
            '60 FPS\'te bir kare 16 ms sürer; en kötü durumda bile bunun '
            'yedide birinden azını harcıyoruz. Bu yüzden gecikmeli tetikleme '
            '(debounce) yok — çözümleme her tuş vuruşunda çalışıyor.',
            style: appBody(
                fontSize: 12.5, color: p.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bu sayı iki kez bayatladı: önce 219 µs\'den 159 µs\'ye indi, '
            'deyim katmanı ve sözlük genişledikten sonra 357 µs\'ye çıktı. '
            'Ölçülmeyen bir gecikme iddiası, motor büyüdükçe yanlışa döner.',
            style: appBody(
                fontSize: 11.5, color: p.textTertiary, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(AppPalette p, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: appDisplay(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
            height: 1.15,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, style: appBody(fontSize: 11.5, color: p.textTertiary)),
      ],
    );
  }

  Widget _principles(AppPalette p) {
    const items = <({IconData icon, String title, String body})>[
      (
        icon: Icons.phonelink_lock_rounded,
        title: 'Metin cihazdan çıkmaz',
        body: 'Bu bir gizlilik politikası maddesi değil, mimarinin kendisi. '
            'Çekirdek paketin bağımlılık listesi boş ve arayüz kodunda ağ '
            'çağrısı üreten tek bir kalıp olmadığı bir testle denetleniyor.',
      ),
      (
        icon: Icons.lock_open_rounded,
        title: 'Hiçbir metin engellenmez',
        body: 'Sistem öneri sunar, kararı kullanıcıya bırakır. "Yine de '
            'gönder" her zaman bir tıklama uzakta ve varsayılan olarak '
            'vurgulanmıyor.',
      ),
      (
        icon: Icons.visibility_rounded,
        title: 'Her uyarı gerekçesini söyler',
        body: 'Hangi ifade, hangi katman, neden. Gerekçesiz kaldırma, '
            'kullanıcıların moderasyona güvenmemesinin başlıca sebebi.',
      ),
      (
        icon: Icons.shield_moon_rounded,
        title: 'Mağdur susturulmaz',
        body: 'Tacize uğradığını anlatan kullanıcı uyarı almaz: aktarılan '
            'hakaretin şiddeti ne olursa olsun yumuşatma bir tavandır. '
            'Bilinen boşluk: tırnak içinde kınanarak aktarılan küfürsüz bir '
            'kalıp, ölçümde bir kez işaretlendi (İP-29).',
      ),
      (
        icon: Icons.badge_outlined,
        title: 'Kimlik adı tetikleyici değildir',
        body: '"Ben Kürtüm" işaretlenmez. Sözlükte tek bir kimlik adı yok '
            've bu, sızması hâlinde kırılan bir testle korunuyor.',
      ),
    ];

    return Container(
      color: p.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                  AppSpacing.sm, AppSpacing.base, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: p.brandSoft,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(item.icon, size: 17, color: p.brandInk),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: appBody(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.body,
                          style: appBody(
                              fontSize: 12.5,
                              color: p.textSecondary,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.row});

  final ({
    String kume,
    String boyut,
    String kesinlik,
    String duyarlilik,
    String f1,
    String durum,
    bool vurgu,
  }) row;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.kume,
                  style: appBody(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: row.vurgu ? p.textPrimary : p.textSecondary,
                  ),
                ),
              ),
              Text(
                '${row.boyut} örnek',
                style: appBody(fontSize: 11.5, color: p.textTertiary),
              ),
              if (row.vurgu) ...[
                const SizedBox(width: AppSpacing.sm),
                AppBadgePill(label: 'raporlanan', color: p.success),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _cell(p, 'kesinlik', row.kesinlik, row.vurgu)),
              Expanded(
                  child: _cell(p, 'duyarlılık', row.duyarlilik, row.vurgu)),
              Expanded(child: _cell(p, 'F1', row.f1, row.vurgu)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            row.durum,
            style: appBody(fontSize: 11.5, color: p.textTertiary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _cell(AppPalette p, String label, String value, bool strong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: appBody(fontSize: 10.5, color: p.textTertiary)),
        Text(
          value,
          style: appBody(
            fontSize: 14,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: strong ? p.textPrimary : p.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final yuzde = value.toStringAsFixed(1).replaceAll('.', ',');

    return Semantics(
      label: '$label: yüzde $yuzde',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: appBody(fontSize: 12.5, color: p.textSecondary),
                  ),
                ),
                Text(
                  '%$yuzde',
                  style: appBody(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value / 100),
                duration: AppDurations.extraSlow,
                curve: AppCurves.standard,
                builder: (context, t, __) => LinearProgressIndicator(
                  value: t,
                  minHeight: 7,
                  backgroundColor: p.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
