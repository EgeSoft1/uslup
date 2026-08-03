// =============================================================================
// Hakkında Ekranı
// Dosya: mobile/lib/presentation/settings/about_screen.dart
//
// DÜZELTİLEN İÇERİK HATALARI — bunlar kozmetik değil
// --------------------------------------------------
// Ekran, doğru olmayan üç şey iddia ediyordu:
//
//   1. "Şifreleme: Uçtan uca (E2EE)" → `ffi_bridge.dart` kendi başlığında
//      "MOCK YAPI" yazıyor; `encryptE2EEMessage` yalnızca `plaintext.codeUnits`
//      döndürüyor. Uçtan uca şifreleme YOK. (docs/02_TEKNIK_BORC.md §1)
//   2. "Backend: Rust (Actix-web)" → depodaki ağ geçidi Axum ile yazılmış,
//      üstelik derlenmiyor ve bu teslimatta kapsam dışı. (§2, §5)
//   3. "Sunucu: Türkiye (İstanbul)" → çalışan bir sunucu dağıtımı yok.
//
// Yarışma teknik raporunda kanıtlanamayan iddia, kanıtlanabilir olanların da
// güvenilirliğini düşürür. Ekran artık durumu olduğu gibi yazıyor: neyin
// çalıştığı, neyin planlandığı ayrı ayrı işaretli.
//
// Ayrıca: yasal bağlantılar tıklanamayan düz metindi, telif yılı 2024'te
// kalmıştı ve renkler sabit yazılıydı (koyu tema çalışmıyordu).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';

/// Bir bileşenin gerçek durumu.
enum FeatureStatus { working, planned, outOfScope }

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: const AppTopBar(title: 'Hakkında'),
      body: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.xl, AppSpacing.base, AppSpacing.xxl),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: p.brandGradient,
                borderRadius: AppRadius.xlAll,
                boxShadow: p.brandShadow,
              ),
              child: Icon(Icons.shield_rounded, color: p.brandOn, size: 36),
            ),
          ).animate().scale(duration: 380.ms, curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.base),
          Center(
            child: Text('NSosyal — Nezaket Koçu',
                style: Theme.of(context).textTheme.headlineSmall),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Sürüm 1.0.0 · Prototip',
              style: TextStyle(fontSize: 13, color: p.textSecondary),
            ),
          ).animate().fadeIn(delay: 120.ms),

          const SizedBox(height: AppSpacing.xl),

          // ── Ne çalışıyor ──
          const AppSectionHeader(
            title: 'Durum',
            subtitle: 'Neyin çalıştığı, neyin planlandığı',
            icon: Icons.fact_check_rounded,
            padding: EdgeInsets.only(bottom: AppSpacing.md),
          ),
          const AppCard(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: Column(
              children: [
                _FeatureRow(
                  icon: Icons.psychology_rounded,
                  label: 'Türkçe nezaket motoru',
                  detail: 'Cihaz üzerinde · 280 µs · F1 %84,2',
                  status: FeatureStatus.working,
                ),
                _FeatureRow(
                  icon: Icons.phonelink_lock_rounded,
                  label: 'Metin cihazdan çıkmaz',
                  detail: 'Çözümleme tamamen yerel',
                  status: FeatureStatus.working,
                ),
                _FeatureRow(
                  icon: Icons.auto_fix_high_rounded,
                  label: 'Yerel yeniden yazma önerisi',
                  detail: 'Deterministik, ağ gerektirmez',
                  status: FeatureStatus.working,
                ),
                _FeatureRow(
                  icon: Icons.cloud_sync_rounded,
                  label: 'LLM yeniden yazma servisi',
                  detail: 'Yazıldı; uçtan uca doğrulama bekliyor',
                  status: FeatureStatus.planned,
                ),
                _FeatureRow(
                  icon: Icons.lock_rounded,
                  label: 'Uçtan uca şifreleme',
                  detail: 'Kripto köprüsü henüz sahte — faz 2',
                  status: FeatureStatus.planned,
                ),
                _FeatureRow(
                  icon: Icons.dns_rounded,
                  label: 'Rust mesajlaşma altyapısı',
                  detail: 'Bu teslimatın kapsamı dışında',
                  status: FeatureStatus.outOfScope,
                  isLast: true,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: AppSpacing.lg),

          // ── Teknoloji ──
          const AppSectionHeader(
            title: 'Teknoloji',
            icon: Icons.code_rounded,
            padding: EdgeInsets.only(bottom: AppSpacing.md),
          ),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.phone_android_rounded,
                  label: 'Arayüz',
                  value: 'Flutter',
                  tint: p.brandInk,
                ),
                Divider(height: AppSpacing.xl, color: p.divider),
                _InfoRow(
                  icon: Icons.memory_rounded,
                  label: 'Nezaket motoru',
                  value: 'Saf Dart · paylaşımlı',
                  tint: p.success,
                ),
                Divider(height: AppSpacing.xl, color: p.divider),
                _InfoRow(
                  icon: Icons.dns_rounded,
                  label: 'LLM servisi',
                  value: 'Dart · Shelf',
                  tint: p.info,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: AppSpacing.lg),

          // ── Mahremiyet ──
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.textSecondary
                            .withValues(alpha: p.isDark ? 0.18 : 0.10),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(Icons.gavel_rounded,
                          color: p.textSecondary, size: 19),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text('Mahremiyet ve yasal',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nezaket çözümlemesi tamamen cihazda çalışır; yazdığın metin '
                  'varsayılan akışta telefonundan hiç çıkmaz. Bulut yeniden '
                  'yazma yalnızca sen açıkça istediğinde ve onay verdiğinde '
                  'devreye girer.\n\n'
                  'Sistem hiçbir metni kendiliğinden değiştirmez veya engellemez. '
                  'Öneri sunar; kararı sen verirsin.',
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Divider(color: p.divider),
                const SizedBox(height: AppSpacing.sm),
                const _LegalLink('Gizlilik Politikası'),
                const _LegalLink('Kullanım Koşulları'),
                const _LegalLink('KVKK Aydınlatma Metni'),
              ],
            ),
          ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              '© ${DateTime.now().year} NSosyal İnovasyon Yarışması projesi',
              style: TextStyle(fontSize: 11.5, color: p.textTertiary),
            ),
          ).animate().fadeIn(delay: 340.ms),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.status,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final FeatureStatus status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final (Color tint, String badge) = switch (status) {
      FeatureStatus.working => (p.success, 'Çalışıyor'),
      FeatureStatus.planned => (p.warning, 'Planlı'),
      FeatureStatus.outOfScope => (p.textTertiary, 'Kapsam dışı'),
    };

    return Padding(
      padding: EdgeInsets.only(
          top: AppSpacing.sm + 2, bottom: isLast ? AppSpacing.sm + 2 : AppSpacing.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppBadge(label: badge, color: tint, dense: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: p.isDark ? 0.20 : 0.11),
            borderRadius: AppRadius.smAll,
          ),
          child: Icon(icon, color: tint, size: 19),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 12.5,
              color: p.textSecondary,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InkWell(
      borderRadius: AppRadius.xsAll,
      onTap: () {
        // Metinler henüz yazılmadı; sessizce hiçbir şey yapmak yerine
        // durumu söylemek, tıklanmayan bir bağlantıdan iyidir.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$text metni hazırlanıyor.')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.chevron_right_rounded, color: p.brandInk, size: 18),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                color: p.brandInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
