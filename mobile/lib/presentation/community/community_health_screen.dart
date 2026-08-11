// =============================================================================
// Topluluk Sağlığı Paneli
// Dosya: mobile/lib/presentation/community/community_health_screen.dart
//
// Şartnamenin "YZ destekli topluluk yönetimi" maddesinin bu üründeki karşılığı.
//
// ── TASARIM KARARI: PANEL METNİ GÖREMEZ ───────────────────────────────────
// Alışıldık moderasyon panelleri ihlal eden İÇERİĞİ gösterir. Bu panelde öyle
// bir liste yoktur ve olamaz: metin cihazdan çıkmadığı gibi, bu ekrana da
// gelmez. Panel yalnızca DAVRANIŞTAN üretilmiş sayıları gösterir.
//
// Bu bir eksiklik değil, ürünün tezidir — ve ekran bunu gizlemek yerine
// başlıkta açıkça yazar.
//
// ── PANELİN ÖLÇTÜĞÜ ŞEY UYARI SAYISI DEĞİLDİR ─────────────────────────────
// "Kaç uyarı verdik" bir başarı ölçüsü değildir; hiç yazmayan bir topluluk da
// az uyarı üretir. Asıl ölçü DÜZELTME ORANIDIR: uyarı alındığında kaç kişi
// cümlesini değiştirdi. Ekranın en büyük kartı odur.
//
// ── ŞEFFAFLIK ─────────────────────────────────────────────────────────────
// "Dışarı ne gider" bölümü, sunucuya gönderilmesi hâlinde gidecek olan tam
// veriyi olduğu gibi gösterir. Kullanıcıya "veriniz güvende" demek yerine
// veriyi göstermek, bu üründe tutarlı olan tek yaklaşım.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/community/community_health_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';

class CommunityHealthScreen extends StatefulWidget {
  const CommunityHealthScreen({super.key});

  @override
  State<CommunityHealthScreen> createState() => _CommunityHealthScreenState();
}

class _CommunityHealthScreenState extends State<CommunityHealthScreen> {
  final CommunityHealthStore _store = CommunityHealthStore.instance;

  @override
  void initState() {
    super.initState();
    _store.seedDemoDataOnce();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final report = _store.report;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        appBar: const AppTopBar(title: 'Topluluk Sağlığı'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl),
          children: [
            const _PrivacyBanner(),
            const SizedBox(height: AppSpacing.base),
            _HealthScoreCard(report: report),
            const SizedBox(height: AppSpacing.base),
            _RatesRow(report: report),
            const SizedBox(height: AppSpacing.base),
            _TrendCard(report: report),
            const SizedBox(height: AppSpacing.base),
            _CategoryCard(report: report),
            const SizedBox(height: AppSpacing.base),
            _ExportCard(report: report),
            const SizedBox(height: AppSpacing.base),
            _SourceNote(
              demoCount: _store.demoCount,
              realCount: _store.realCount,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mahremiyet şeridi ────────────────────────────────────────────────────────

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.successSoft,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: p.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 20, color: p.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Bu paneldeki hiçbir sayı mesaj içeriğinden üretilmez. '
              'Metin cihazdan çıkmaz, bu ekrana da gelmez — burada yalnızca '
              'kaç uyarı verildiği ve kaçının düzeltmeyle sonuçlandığı var.',
              style: TextStyle(
                  color: p.textPrimary, fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sağlık puanı ─────────────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.report});
  final CommunityHealthReport report;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final score = report.healthScore;
    final color = score >= 80
        ? p.success
        : score >= 60
            ? p.warning
            : p.danger;

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: p.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$score',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                            height: 1)),
                    Text('/100',
                        style:
                            TextStyle(fontSize: 11, color: p.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Topluluk sağlığı puanı',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Gönderimlerin temizliği (%60) ve uyarı alındığında '
                  'düzeltme eğilimi (%40) birlikte hesaplanır.',
                  style: TextStyle(
                      fontSize: 12, color: p.textSecondary, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppBadge(
                  label: '${report.totalSignals} gönderim',
                  icon: Icons.insights_rounded,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Oranlar ──────────────────────────────────────────────────────────────────

class _RatesRow extends StatelessWidget {
  const _RatesRow({required this.report});
  final CommunityHealthReport report;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '%${(report.revisionRate * 100).round()}',
            label: 'Düzeltme oranı',
            hint: 'Uyarı alanların kaçı cümlesini değiştirdi',
            color: p.success,
            emphasised: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            value: '%${(report.interventionRate * 100).round()}',
            label: 'Müdahale oranı',
            hint: 'Gönderimlerin kaçında uyarı çıktı',
            color: p.warning,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.hint,
    required this.color,
    this.emphasised = false,
  });

  final String value;
  final String label;
  final String hint;
  final Color color;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: emphasised ? 30 : 25,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary)),
          const SizedBox(height: 3),
          Text(hint,
              style: TextStyle(
                  fontSize: 11, color: p.textTertiary, height: 1.35)),
        ],
      ),
    );
  }
}

// ─── Eğilim ───────────────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.report});
  final CommunityHealthReport report;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final trend = report.trend;

    if (trend.length < 2) {
      return AppCard(
        child: Text('Eğilim için en az iki günlük veri gerekiyor.',
            style: TextStyle(fontSize: 13, color: p.textSecondary)),
      );
    }

    final enYuksek =
        trend.map((t) => t.interventionRate).reduce((a, b) => a > b ? a : b);
    // Sıfıra bölmeyi önler ve tamamen temiz bir haftada çubukları
    // tavana yapıştırmaz.
    final tavan = enYuksek <= 0 ? 1.0 : enYuksek;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Günlük müdahale oranı',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary)),
          const SizedBox(height: 4),
          Text('Son ${trend.length} gün',
              style: TextStyle(fontSize: 11.5, color: p.textTertiary)),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < trend.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Semantics(
                      label: '${trend.length - i} gün önce, müdahale oranı '
                          'yüzde ${(trend[i].interventionRate * 100).round()}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '%${(trend[i].interventionRate * 100).round()}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 8 +
                                72 * (trend[i].interventionRate / tavan),
                            decoration: BoxDecoration(
                              color: i == trend.length - 1
                                  ? p.brand
                                  : p.brand.withValues(alpha: 0.35),
                              borderRadius: AppRadius.smAll,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kategori dağılımı ────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.report});
  final CommunityHealthReport report;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final entries = report.categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final enBuyuk = entries.isEmpty ? 1 : entries.first.value;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uyarı türleri',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Text('Henüz sayı açılacak kadar veri yok.',
                style: TextStyle(fontSize: 13, color: p.textSecondary))
          else
            for (final e in entries) ...[
              _CategoryBar(
                label: e.key.label,
                count: e.value,
                ratio: e.value / enBuyuk,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (report.suppressedCategories > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.visibility_off_outlined,
                      size: 16, color: p.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${report.suppressedCategories} tür gizlendi: '
                      '${report.kThreshold} gözlemin altındaki sayılar tek bir '
                      'kişiyi işaret edebileceği için açılmıyor.',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: p.textSecondary,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.count,
    required this.ratio,
  });

  final String label;
  final int count;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      label: '$label: $count uyarı',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 13, color: p.textPrimary)),
              Text('$count',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textSecondary)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: p.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(p.brand),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dışa aktarım şeffaflığı ──────────────────────────────────────────────────

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.report});
  final CommunityHealthReport report;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final export = report.toExportMap();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file_outlined, size: 18, color: p.brandInk),
              const SizedBox(width: 6),
              Text('Dışarı ne gider',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bu rapor platforma gönderilseydi, giden veri harfi harfine '
            'aşağıdakinden ibaret olurdu. Metin yok, zaman damgası yok, '
            'kullanıcı kimliği yok.',
            style:
                TextStyle(fontSize: 12, color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: p.border),
            ),
            child: SelectableText(
              export.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Veri kaynağı notu ────────────────────────────────────────────────────────

class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.demoCount, required this.realCount});

  final int demoCount;
  final int realCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.warningSoft,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: p.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 18, color: p.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Bu panelde $demoCount gösterim sinyali ve bu oturumda '
              'gönderdiğin $realCount gerçek sinyal var. Gösterim verisi '
              'sabit bir tohumla üretilir; hangi sayının gerçek olduğu '
              'belirsiz kalmasın diye ayrı sayılıyor.',
              style: TextStyle(
                  fontSize: 11.5, color: p.textPrimary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
