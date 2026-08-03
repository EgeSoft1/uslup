// =============================================================================
// QR Kod — göster ve tara
// Dosya: mobile/lib/presentation/contacts/qr_scanner_screen.dart
//
// DÜZELTİLENLER
//   • "QR Kodu Paylaş" ve "Galeriden Seç" düğmelerinin ikisi de dokunma
//     işleyicisi olmayan `Container`'dı — basılıyor, hiçbir şey olmuyordu.
//   • Bir kod okunduktan sonra `_hasReadCode` bir daha sıfırlanmıyordu:
//     tarayıcı durduruluyor ve ekrandan çıkıp girmeden ikinci bir kod
//     okunamıyordu. Artık kısa bir beklemeden sonra tarama sürüyor.
//   • Kamera, sekme "Kod Tara"ya geçilmese de açık kalıyordu; pil ve
//     mahremiyet açısından gereksiz. Sekme değişince durduruluyor.
//   • Renkler paletten okunur. QR karesi ise KASITLI olarak koyu temada da
//     beyaz zemin + koyu modül: tarayıcılar ters kontrastta okuyamıyor.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_surfaces.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  static const _profileUri = 'nsosyal://contact/ahmet-yilmaz';

  late final TabController _tabController =
      TabController(length: 2, vsync: this)..addListener(_onTabChanged);
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  /// Kamera yalnızca tarama sekmesi görünürken çalışır.
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      _scannerController.start();
    } else {
      _scannerController.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR kod okundu: $code')),
      );
    }

    // Aynı kodun art arda okunmasını engelleyecek kadar bekle, sonra devam et.
    // Eskiden bayrak hiç sıfırlanmadığı için ikinci kod hiç okunamıyordu.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isProcessing = false);
  }

  void _shareCode() {
    Clipboard.setData(const ClipboardData(text: _profileUri));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil bağlantın panoya kopyalandı.')),
    );
  }

  void _pickFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Galeriden okuma yakında etkinleşecek.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayFor(p),
      child: Scaffold(
        backgroundColor: p.background,
        appBar: const AppTopBar(title: 'QR Kod'),
        body: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: p.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: p.brand,
                    borderRadius: AppRadius.pill,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: p.brandOn,
                  unselectedLabelColor: p.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w500),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'QR Kodum'),
                    Tab(text: 'Kod Tara'),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyQrTab(p),
                  _buildScannerTab(p),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyQrTab(AppPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        children: [
          const AppAvatar(
            imageUrl: 'https://i.pravatar.cc/150?img=11',
            name: 'Ahmet Yılmaz',
            size: 70,
            showOnlineDot: false,
          ).animate().scale(duration: 380.ms, curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.md),
          Text('Ahmet Yılmaz',
                  style: Theme.of(context).textTheme.headlineSmall)
              .animate()
              .fadeIn(delay: 80.ms),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            radius: AppRadius.xxl,
            child: Column(
              children: [
                // QR karesi her iki temada da beyaz zemin + koyu modül:
                // ters kontrastta çoğu tarayıcı kodu okuyamıyor.
                Container(
                  width: 196,
                  height: 196,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: const Color(0xFFE5E1DA), width: 2),
                  ),
                  child: QrImageView(
                    data: _profileUri,
                    version: QrVersions.auto,
                    eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square, color: Color(0xFF1C1C1E)),
                    dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1C1C1E)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _shareCode,
                    icon: const Icon(Icons.share_rounded, size: 19),
                    label: const Text('QR kodu paylaş'),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.08, end: 0),
        ],
      ),
    );
  }

  Widget _buildScannerTab(AppPalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: SizedBox(
              width: 268,
              height: 268,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ColoredBox(color: p.surfaceMuted),
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.no_photography_rounded,
                                color: p.textTertiary, size: 32),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Kameraya erişilemiyor',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._buildCornerLines(p),
                  if (_isProcessing)
                    ColoredBox(
                      color: p.scrim.withValues(alpha: 0.55),
                      child: Center(
                        child: Icon(Icons.check_circle_rounded,
                            color: p.success, size: 48),
                      ),
                    ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 80.ms)
              .scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'QR kodu kamerayla tara',
            style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Kişi eklemek için kodu çerçeve içine hizala',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_rounded, size: 19),
            label: const Text('Galeriden seç'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerLines(AppPalette p) {
    final color = p.brand;
    const w = 3.0;
    const len = 28.0;
    const off = 22.0;

    Widget bar({double? width, double? height}) =>
        Container(width: width, height: height, color: color);

    return [
      Positioned(left: off, top: off, child: bar(width: len, height: w)),
      Positioned(left: off, top: off, child: bar(width: w, height: len)),
      Positioned(right: off, top: off, child: bar(width: len, height: w)),
      Positioned(right: off, top: off, child: bar(width: w, height: len)),
      Positioned(left: off, bottom: off, child: bar(width: len, height: w)),
      Positioned(left: off, bottom: off, child: bar(width: w, height: len)),
      Positioned(right: off, bottom: off, child: bar(width: len, height: w)),
      Positioned(right: off, bottom: off, child: bar(width: w, height: len)),
    ];
  }
}
