// =============================================================================
// Üslup Paneli — katmanın kendisi, canlı denemesi ve ölçümleri
// Dosya: mobile/lib/presentation/uslup/uslup_panel_screen.dart
//
// Bu ekran ürünün VİTRİNİ değil, HESAP VERDİĞİ yerdir. Akış ve gönderi
// kutusu katmanın ne yaptığını gösterir; burası ne kadar iyi yaptığını ve
// nerede yanıldığını gösterir.
//
// ── NEDEN BAŞARISIZ SAYILAR DA BURADA ─────────────────────────────────────
// Ölçüm tablosunda %99,6 da var %55,6 da. İkincisini gizlemek daha güzel
// bir ekran üretirdi ve ürünü savunulamaz hâle getirirdi: geliştirme
// kümesindeki %99,6 bir genelleme kanıtı DEĞİLDİR, çünkü kümeyi de
// örüntüleri de aynı kişi yazmıştır. Taze bir kümede duyarlılığın %100'den
// %12'ye düşmesi, bu projenin en değerli ölçümüdür — çünkü ezberin
// büyüklüğünü sayıya çevirmiştir.
//
// Kaynak: docs/14_MENTORLUK_PENCERESI_SONUCLARI.md §5 (ölçüm geçmişi),
// §10 (gecikme), §1.3 (katman katkısı).
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/civility/civility_runtime.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../compose/civility_composer.dart';
import '../settings/about_screen.dart';
import '../widgets/social_widgets.dart';

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
            _header(context, p),
            const SectionLabel(text: 'CANLI DENEME'),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bir cümle yaz ya da aşağıdaki hazır senaryolara dokun. '
                    'Çözümleme bu telefonda yapılır; hiçbir şey gönderilmez.',
                    style: TextStyle(
                        fontSize: 13, color: p.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Gönderim geri çağrısı YOK: burada gönderilecek bir yer
                  // yok, gösterilecek bir davranış var.
                  const CivilityComposer(
                    showAvatar: false,
                    showToolbar: false,
                    showScenarios: true,
                    minLines: 3,
                    maxLines: 8,
                  ),
                ],
              ),
            ),
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
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                ),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Proje künyesi ve kaynak kod'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Başlık ───────────────────────────────────────────────────────────────

  Widget _header(BuildContext context, AppPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandMark(size: 40, showWordmark: true),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Gönderilmeden önce müdahale eden, cihaz üzerinde çalışan '
            'Türkçe sosyal yapay zekâ katmanı.',
            style: TextStyle(
              fontSize: 15,
              color: p.textPrimary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppBadgePill(
                label: 'cihaz üstü',
                color: p.success,
                icon: Icons.phonelink_lock_rounded,
              ),
              AppBadgePill(
                label: 'sıfır ağ çağrısı',
                color: p.info,
                icon: Icons.wifi_off_rounded,
              ),
              AppBadgePill(
                label: 'engellemez, önerir',
                color: p.brandInk,
                icon: Icons.how_to_reg_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
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
                    '${Civility.modelName}\n${Civility.olcumKapsami}',
                    style: TextStyle(
                        fontSize: 11.5, color: p.textTertiary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── İşlem hattı ──────────────────────────────────────────────────────────

  Widget _pipeline(AppPalette p) {
    const steps = <({String title, String detail})>[
      (
        title: 'Normalizasyon',
        detail: 'Gizleme hilelerini geri çevirir: \$3r3fsiz, a.p.t.a.l, '
            'şerefsiiiz. Türkçe küçük harf tablosu elle yazıldı — Dart\'ın '
            'kendi işlevi "I" harfini yanlış çeviriyor.'
      ),
      (
        title: 'Sözlük katmanı',
        detail: '92 girdi. Her girdi kategori, taban şiddet, eşleşme kipi, '
            'yönelim şartı ve nötr karşılık taşır. Tek başına yetmez ve '
            'bu ölçüldü.'
      ),
      (
        title: 'Edimbilimsel örüntü',
        detail: 'Saldırganlığı kelimelerde değil kelimelerin DİZİLİŞİNDE '
            'arar. "Senin gibilerden bu beklenirdi" tek bir yasaklı kelime '
            'içermez.'
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
            'DEĞİL bir tavandır — mağdurun uyarı alması yapısal olarak '
            'imkânsızdır.'
      ),
      (
        title: 'Skor birleştirme',
        detail: 'noisy-OR: 1 − Π(1 − sᵢ). Toplama taşar, maksimum birikimi '
            'göremez.'
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
                      style: TextStyle(
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].detail,
                          style: TextStyle(
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

  // ─── Ölçüm geçmişi ────────────────────────────────────────────────────────

  Widget _measurements(AppPalette p) {
    const rows = <({
      String kume,
      String boyut,
      String kesinlik,
      String duyarlilik,
      String f1,
      String durum,
      bool gecerli,
    })>[
      (
        kume: 'Geliştirme',
        boyut: '256',
        kesinlik: '%100,0',
        duyarlilik: '%99,3',
        f1: '%99,6',
        durum: 'Ezberleme payı içerir — genelleme kanıtı DEĞİLDİR',
        gecerli: false,
      ),
      (
        kume: '1. ayrık küme',
        boyut: '80',
        kesinlik: '%98,0',
        duyarlilik: '%100,0',
        f1: '%99,0',
        durum: 'Yanmış. İlk ölçüm F1 %84,2 idi; motor bu kümeye bakılarak '
            'düzeltildi',
        gecerli: false,
      ),
      (
        kume: '2. ayrık küme (İP-15)',
        boyut: '100',
        kesinlik: '%100,0',
        duyarlilik: '%38,5',
        f1: '%55,6',
        durum: 'İlk ölçüm. Örtük saldırı diliminde duyarlılık %100 → %12,0',
        gecerli: false,
      ),
      (
        kume: '3. ayrık küme (İP-20)',
        boyut: '80',
        kesinlik: '%100,0',
        duyarlilik: '%50,0',
        f1: '%66,7',
        durum: 'İlk ölçüm. Kaçakların çoğu deyim — kural tabanlı katmanın '
            'tavanı',
        gecerli: false,
      ),
      (
        kume: '4. ayrık küme (İP-22)',
        boyut: '65',
        kesinlik: '%90,5',
        duyarlilik: '%54,3',
        f1: '%67,9',
        durum: 'GEÇERLİ — raporlanan genelleme sayısı budur',
        gecerli: true,
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
                if (i < rows.length - 1)
                  Divider(height: 1, color: p.divider),
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
                    style: TextStyle(
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

  // ─── Katman katkısı ───────────────────────────────────────────────────────

  Widget _layerContribution(AppPalette p) {
    return Container(
      color: p.surface,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aynı 256 örnek üzerinde, yalnız sözlük katmanı ile bütün '
            'örüntü katmanları ayrı ayrı ölçüldü.',
            style:
                TextStyle(fontSize: 13, color: p.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.base),
          _CompareBar(
            label: 'Duyarlılık · yalnız sözlük',
            value: 44.0,
            color: p.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompareBar(
            label: 'Duyarlılık · tüm katmanlar',
            value: 99.3,
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
            'Duyarlılık 55,2 puan arttı ve kesinlikten hiçbir şey '
            'götürmedi. Örtük saldırı diliminde kazanç %1,8 → %100,0: yani '
            'küfürsüz düşmanlığın ellide kırk dokuzunu yalnızca örüntü '
            'katmanı görüyor.',
            style: TextStyle(
                fontSize: 12.5, color: p.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }

  // ─── Gecikme ──────────────────────────────────────────────────────────────

  Widget _latency(AppPalette p) {
    return Container(
      color: p.surface,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _metricTile(p, '159 µs', 'tipik (p50)')),
              Expanded(child: _metricTile(p, '1459 µs', 'p99')),
              Expanded(child: _metricTile(p, '%9,1', 'kare bütçesi')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'AOT derlenmiş ikili üzerinde ölçüldü. 60 FPS\'te bir kare '
            '16 ms sürer; en kötü durumda bile bunun onda birinden azını '
            'harcıyoruz. Bu yüzden gecikmeli tetikleme (debounce) yok — '
            'çözümleme her tuş vuruşunda çalışıyor.',
            style: TextStyle(
                fontSize: 12.5, color: p.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bu sayı bir kez bayatladı: kimlik söz varlığı 35\'ten 94 terime '
            'çıkınca p50 219 µs\'ye yükselmişti. İki ön kapı eklendi ve '
            '159 µs\'ye indi. Ölçülmeyen bir gecikme iddiası, motor '
            'büyüdükçe bayatlar.',
            style: TextStyle(
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
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
            height: 1.15,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11.5, color: p.textTertiary)),
      ],
    );
  }

  // ─── İlkeler ──────────────────────────────────────────────────────────────

  Widget _principles(AppPalette p) {
    const items = <({IconData icon, String title, String body})>[
      (
        icon: Icons.phonelink_lock_rounded,
        title: 'Metin cihazdan çıkmaz',
        body: 'Bu bir gizlilik politikası maddesi değil, mimarinin kendisi. '
            'Çekirdek paketin bağımlılık listesi boş ve ürün çalışma '
            'zamanında tek bir ağ çağrısı yapmıyor.',
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
        body: 'Tacize uğradığını anlatan kullanıcı uyarı ALMAZ. Yumuşatma '
            'bir çarpan değil bir tavandır; terimin taban şiddeti ne olursa '
            'olsun eşiğin altında kalır.',
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.body,
                          style: TextStyle(
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

// ─── Alt bileşenler ──────────────────────────────────────────────────────────

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.row});

  final ({
    String kume,
    String boyut,
    String kesinlik,
    String duyarlilik,
    String f1,
    String durum,
    bool gecerli,
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
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: row.gecerli ? p.textPrimary : p.textSecondary,
                  ),
                ),
              ),
              Text(
                '${row.boyut} örnek',
                style: TextStyle(fontSize: 11.5, color: p.textTertiary),
              ),
              if (row.gecerli) ...[
                const SizedBox(width: AppSpacing.sm),
                AppBadgePill(label: 'geçerli', color: p.success),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _cell(p, 'kesinlik', row.kesinlik, row.gecerli)),
              Expanded(
                  child: _cell(p, 'duyarlılık', row.duyarlilik, row.gecerli)),
              Expanded(child: _cell(p, 'F1', row.f1, row.gecerli)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            row.durum,
            style: TextStyle(
                fontSize: 11.5, color: p.textTertiary, height: 1.4),
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
        Text(label, style: TextStyle(fontSize: 10.5, color: p.textTertiary)),
        Text(
          value,
          style: TextStyle(
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

    return Semantics(
      label: '$label: yüzde ${value.toStringAsFixed(1).replaceAll('.', ',')}',
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
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                ),
                Text(
                  '%${value.toStringAsFixed(1).replaceAll('.', ',')}',
                  style: TextStyle(
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
