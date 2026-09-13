// =============================================================================
// Sunum ekran görüntüleri — gerçek yazı tipleriyle, başsız (headless) çizim
// Dosya: mobile/tool/ekran_goruntusu_test.dart
//
// Çalıştırma:
//   cd mobile
//   flutter test tool/ekran_goruntusu_test.dart
//
// Çıktı: docs/gorseller/ekranlar/*.png (2× piksel yoğunluğu)
//
// ── NEDEN TEST ÇALIŞTIRICISI ──────────────────────────────────────────────
// Sunum slaytları için aynı ekranın her seferinde AYNI durumda çekilmesi
// gerekir: aynı metin, aynı sekme, aynı pencere boyutu. Elle ekran görüntüsü
// almak her sürümde farklı bir kare üretir. Bu dosya ekranları uygulamanın
// kendi kodundan, gerçek Outfit/Inter yazı tipleri ve Material ikonlarıyla
// çizer. `flutter test` kapsamına GİRMEZ (test/ altında değil).
//
// Her kare motorun GERÇEK çıktısıdır; hiçbir sonuç elle yerleştirilmez.
// =============================================================================

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/theme/theme_controller.dart';
import 'package:turkiye_mesajlasma/main.dart';

const _cikti = '../docs/gorseller/ekranlar';

Future<void> _yaziTipleriniYukle() async {
  Future<void> yukle(String aile, String yol) async {
    final dosya = File(yol);
    if (!dosya.existsSync()) return;
    final bayt = dosya.readAsBytesSync();
    final loader = FontLoader(aile)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bayt).buffer)));
    await loader.load();
  }

  final flutterKok = Platform.environment['FLUTTER_ROOT'] ?? r'C:\flutter';
  final materyal = '$flutterKok/bin/cache/artifacts/material_fonts';
  await yukle('Outfit', 'assets/fonts/Outfit-Variable.ttf');
  await yukle('Inter', 'assets/fonts/Inter-Variable.ttf');
  await yukle('MaterialIcons', '$materyal/materialicons-regular.otf');
  await yukle('Roboto', '$materyal/roboto-regular.ttf');
}

Future<void> _cek(WidgetTester tester, GlobalKey anahtar, String ad) async {
  await tester.runAsync(() async {
    final sinir =
        anahtar.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image resim = await sinir.toImage(pixelRatio: 2);
    final veri = await resim.toByteData(format: ui.ImageByteFormat.png);
    final dosya = File('$_cikti/$ad.png')..createSync(recursive: true);
    dosya.writeAsBytesSync(veri!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(_yaziTipleriniYukle);

  const masaustu = Size(1440, 900);
  const masaustuUzun = Size(1440, 2600);
  const telefon = Size(412, 915);

  Future<GlobalKey> ac(WidgetTester tester, Size boyut,
      {bool koyu = false}) async {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    ThemeController.instance.value = koyu ? ThemeMode.dark : ThemeMode.light;

    final anahtar = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: anahtar, child: const NSosyalApp()));
    await tester.pumpAndSettle();
    return anahtar;
  }

  Future<void> bekle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> panel(WidgetTester tester, {bool masaustuMu = true}) async {
    await tester.tap(find.text(masaustuMu ? 'Üslup Paneli' : 'Üslup').last);
    await bekle(tester);
  }

  /// Senaryo çipine dokunur. Aynı etiket bağlam karnesinde de geçtiği için
  /// ağaçtaki İLK eşleşme (çip) seçilir.
  Future<void> senaryo(WidgetTester tester, String etiket) async {
    final cip = find.text(etiket).first;
    await tester.ensureVisible(cip);
    await tester.pumpAndSettle();
    await tester.tap(cip);
    await bekle(tester);
  }

  /// Yazım kutusunu görünür alanın en üstüne kaydırır.
  ///
  /// `ListView` ekran dışına çıkan başlığı ağaçtan düşürür; bu yüzden önce
  /// en başa dönülür, sonra başlığın KENDİ kaydırıcısı kaydırılır (masaüstünde
  /// ağaçtaki ilk `Scrollable` kenar çubuğudur).
  Future<void> kutuyaKaydir(WidgetTester tester) async {
    final liste = find.byType(ListView).first;
    await tester.drag(liste, const Offset(0, 5000));
    await tester.pumpAndSettle();
    final etiket = find.text('CANLI DENEME');
    final ust = tester.getTopLeft(etiket).dy;
    await tester.drag(liste, Offset(0, -(ust - 8)));
    await bekle(tester);
  }

  testWidgets('masaüstü · akış', (tester) async {
    final k = await ac(tester, masaustu);
    await _cek(tester, k, 'masaustu_01_akis');
  });

  testWidgets('masaüstü · üslup paneli', (tester) async {
    final k = await ac(tester, masaustu);
    await panel(tester);
    await _cek(tester, k, 'masaustu_02_uslup_paneli');
  });

  for (final sahne in const [
    ('03', 'Doğrudan saldırı', 'dogrudan_saldiri'),
    ('04', 'Mağdur anlatısı', 'magdur_anlatisi'),
    ('05', 'Olumsuzlama', 'olumsuzlama'),
    ('06', 'Küfürsüz düşmanlık', 'kufursuz_dusmanlik'),
    ('07', 'Kimlik beyanı', 'kimlik_beyani'),
    ('08', 'Nefret söylemi', 'nefret_soylemi'),
    ('09', 'Gizleme denemesi', 'gizleme'),
  ]) {
    testWidgets('masaüstü · senaryo ${sahne.$2}', (tester) async {
      final k = await ac(tester, masaustu);
      await panel(tester);
      await senaryo(tester, sahne.$2);
      await kutuyaKaydir(tester);
      await _cek(tester, k, 'masaustu_${sahne.$1}_${sahne.$3}');
    });
  }

  testWidgets('masaüstü · bağlam karnesi (uzun)', (tester) async {
    final k = await ac(tester, masaustuUzun);
    await panel(tester);
    await _cek(tester, k, 'masaustu_10_panel_tam_sayfa');
  });

  testWidgets('masaüstü · sistem detayları (uzun)', (tester) async {
    final k = await ac(tester, masaustuUzun);
    await panel(tester);
    final kart = find.text('Sistem detayları');
    await tester.ensureVisible(kart);
    await tester.pumpAndSettle();
    await tester.tap(kart);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_11_sistem_detaylari');
  });

  testWidgets('masaüstü · topluluk', (tester) async {
    final k = await ac(tester, masaustu);
    await tester.tap(find.text('Topluluk Sağlığı').first);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_12_topluluk');
  });

  testWidgets('masaüstü · koyu tema', (tester) async {
    final k = await ac(tester, masaustu, koyu: true);
    await panel(tester);
    await senaryo(tester, 'Doğrudan saldırı');
    await kutuyaKaydir(tester);
    await _cek(tester, k, 'masaustu_13_koyu_tema');
  });

  testWidgets('telefon · akış', (tester) async {
    final k = await ac(tester, telefon);
    await _cek(tester, k, 'telefon_01_akis');
  });

  testWidgets('telefon · üslup', (tester) async {
    final k = await ac(tester, telefon);
    await panel(tester, masaustuMu: false);
    await _cek(tester, k, 'telefon_02_uslup');
  });

  testWidgets('telefon · canlı uyarı', (tester) async {
    final k = await ac(tester, telefon);
    await panel(tester, masaustuMu: false);
    await senaryo(tester, 'Doğrudan saldırı');
    await kutuyaKaydir(tester);
    await _cek(tester, k, 'telefon_03_canli_uyari');
  });

  testWidgets('telefon · mağdur anlatısı', (tester) async {
    final k = await ac(tester, telefon);
    await panel(tester, masaustuMu: false);
    await senaryo(tester, 'Mağdur anlatısı');
    await kutuyaKaydir(tester);
    await _cek(tester, k, 'telefon_04_magdur_anlatisi');
  });
}
