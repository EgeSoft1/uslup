// =============================================================================
// Üslup Ayarları Ekranı
// Dosya: mobile/lib/presentation/settings/uslup_ayarlari_screen.dart
//
// Kullanıcı katmanın ne kadar konuşacağına kendisi karar verir (docs/27):
// katmanı kapatabilir, hassasiyeti seçebilir, küfür/argo ve alay uyarılarını
// susturabilir. Politika `civility_core` içindedir ve testlidir; bu ekran
// yalnızca seçimi alır ve seçimin SONUCUNU aynı motorla canlı gösterir.
//
// ── NEDEN CANLI ÖNİZLEME ──────────────────────────────────────────────────
// "Hassas" ya da "Yalnızca ağır" kelimeleri kullanıcıya bir şey söylemez.
// Dört örnek cümlenin o ayarda hangi basamağa düştüğünü görmek söyler.
// Önizleme sabit bir tablo DEĞİLDİR; her satır motordan o an üretilir.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/civility/uslup_ayar_denetleyici.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_surfaces.dart';

class UslupAyarlariScreen extends StatelessWidget {
  const UslupAyarlariScreen({super.key});

  /// Önizleme cümleleri: her biri farklı bir basamak ve kategoriden.
  /// Seçimleri `civility_core` üzerinde doğrulandı (docs/27 §3).
  static const List<({String metin, String not})> ornekler = [
    (metin: 'sus artık', not: 'alay · sınırda'),
    (metin: 'sen tam bir aptalsın', not: 'hakaret · orta'),
    (metin: 'amk yine geç kaldım', not: 'argo · ağır'),
    (metin: 'seni bulup gebertirim', not: 'tehdit · ağır'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final denetleyici = UslupAyarDenetleyici.instance;

    return Scaffold(
      backgroundColor: p.background,
      appBar: const AppTopBar(title: 'Üslup ayarları'),
      body: ValueListenableBuilder<UslupAyarlari>(
        valueListenable: denetleyici,
        builder: (context, ayar, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.xxl),
            children: [
              // ── Açık / kapalı ──
              AppCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                child: SwitchListTile.adaptive(
                  key: const ValueKey('ayar-etkin'),
                  contentPadding: EdgeInsets.zero,
                  value: ayar.etkin,
                  onChanged: (v) => denetleyici.guncelle(ayar.copyWith(etkin: v)),
                  title: Text('Üslup katmanı',
                      style: appBody(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary)),
                  subtitle: Text(
                    ayar.etkin
                        ? 'Açık. Yazarken gerekçe ve öneri gösterir; hiçbir '
                            'gönderiyi engellemez.'
                        : 'Kapalı. Uyarı, öneri ve onay gösterilmez. Kendine '
                            'zarar ifadesinde destek kartı yine görünür.',
                    style: appBody(
                        fontSize: 13, color: p.textSecondary, height: 1.4),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              const AppSectionHeader(
                title: 'Hassasiyet',
                subtitle: 'Katman ne zaman konuşsun?',
                icon: Icons.tune_rounded,
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              for (final h in Hassasiyet.values) ...[
                _HassasiyetKarti(
                  hassasiyet: h,
                  secili: ayar.hassasiyet == h,
                  etkin: ayar.etkin,
                  onTap: () =>
                      denetleyici.guncelle(ayar.copyWith(hassasiyet: h)),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Kategoriler',
                subtitle: 'Kendi üslup tercihin olan uyarıları susturabilirsin',
                icon: Icons.category_rounded,
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base, vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    for (final c in const [
                      ToxicityCategory.kufur,
                      ToxicityCategory.asagilama,
                    ])
                      SwitchListTile.adaptive(
                        key: ValueKey('ayar-kategori-${c.name}'),
                        contentPadding: EdgeInsets.zero,
                        value: !ayar.gecerliSusturulanlar.contains(c),
                        onChanged: ayar.etkin
                            ? (uyar) {
                                final yeni = {...ayar.gecerliSusturulanlar};
                                uyar ? yeni.remove(c) : yeni.add(c);
                                denetleyici.guncelle(
                                    ayar.copyWith(susturulanlar: yeni));
                              }
                            : null,
                        title: Text(
                          c == ToxicityCategory.kufur
                              ? 'Küfür ve argo uyarıları'
                              : 'Alay ve küçümseme uyarıları',
                          style: appBody(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary),
                        ),
                        subtitle: Text(
                          c == ToxicityCategory.kufur
                              ? 'Arkadaşlarınla argo konuşuyorsan kapatabilirsin.'
                              : '“Sus artık”, “boş konuşma” gibi ifadeler.',
                          style: appBody(fontSize: 12.5, color: p.textSecondary),
                        ),
                      ),
                    Divider(color: p.divider, height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_rounded,
                              size: 18, color: p.textTertiary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Tehdit, nefret söylemi, taciz ve hakaret '
                              'uyarıları tek tek kapatılamaz: bunlar başka '
                              'bir insanı hedef alır. Hiç uyarı istemiyorsan '
                              'katmanın tamamını kapatabilirsin.',
                              style: appBody(
                                  fontSize: 12.5,
                                  color: p.textSecondary,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              const AppSectionHeader(
                title: 'Bu ayarla ne olur?',
                subtitle: 'Her satır şu anda motordan üretiliyor',
                icon: Icons.preview_rounded,
                padding: EdgeInsets.only(bottom: AppSpacing.md),
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    for (final o in ornekler)
                      _OnizlemeSatiri(
                        metin: o.metin,
                        not: o.not,
                        analiz: MudahalePolitikasi.uygula(
                            Civility.engine.analyze(o.metin), ayar),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phonelink_lock_rounded,
                      size: 14, color: p.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      denetleyici.kalici
                          ? 'Ayar bu cihazda saklanır ve Üslup klavyesiyle '
                              'paylaşılır. Ayar dosyasında metin ya da kullanım '
                              'kaydı yoktur.'
                          : 'Bu sürümde ayar oturum boyunca geçerlidir. Ayar '
                              'hiçbir yere gönderilmez.',
                      style: appBody(
                          fontSize: 12, color: p.textTertiary, height: 1.4),
                    ),
                  ),
                ],
              ),
              if (!ayar.varsayilanMi) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        denetleyici.guncelle(UslupAyarlari.varsayilan),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Önerilen ayara dön'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HassasiyetKarti extends StatelessWidget {
  const _HassasiyetKarti({
    required this.hassasiyet,
    required this.secili,
    required this.etkin,
    required this.onTap,
  });

  final Hassasiyet hassasiyet;
  final bool secili;
  final bool etkin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final renk = secili && etkin ? p.brand : p.border;

    return Semantics(
      button: true,
      selected: secili,
      enabled: etkin,
      label: '${hassasiyet.label}. ${hassasiyet.aciklama}',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: etkin ? 1 : 0.55,
          child: Material(
            color: secili && etkin ? p.brandSoft : p.surface,
            borderRadius: AppRadius.lgAll,
            child: InkWell(
              key: ValueKey('ayar-hassasiyet-${hassasiyet.name}'),
              onTap: etkin ? onTap : null,
              borderRadius: AppRadius.lgAll,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: renk, width: secili ? 2 : 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      secili
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: secili ? p.brandInk : p.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hassasiyet.label,
                              style: appBody(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary)),
                          const SizedBox(height: 2),
                          Text(hassasiyet.aciklama,
                              style: appBody(
                                  fontSize: 12.5,
                                  color: p.textSecondary,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnizlemeSatiri extends StatelessWidget {
  const _OnizlemeSatiri({
    required this.metin,
    required this.not,
    required this.analiz,
  });

  final String metin;
  final String not;
  final CivilityAnalysis analiz;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (renk, sonuc) = switch (analiz.risk) {
      RiskLevel.temiz => (p.textTertiary, 'Hiçbir şey gösterilmez'),
      RiskLevel.dikkat => (p.info, 'Yalnızca kutu rengi'),
      RiskLevel.riskli => (p.warning, 'Gerekçe ve öneri'),
      RiskLevel.yuksek => (p.danger, 'Gönderim öncesi onay'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('“$metin”',
                    style: appBody(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary)),
                Text(not, style: appBody(fontSize: 11.5, color: p.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              sonuc,
              key: ValueKey('onizleme-$metin'),
              textAlign: TextAlign.right,
              style: appBody(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: renk),
            ),
          ),
        ],
      ),
    );
  }
}
