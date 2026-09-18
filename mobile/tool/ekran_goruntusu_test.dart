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
import 'package:turkiye_mesajlasma/core/civility/civility_runtime.dart';
import 'package:turkiye_mesajlasma/core/theme/theme_controller.dart';
import 'package:turkiye_mesajlasma/main.dart';
import 'package:turkiye_mesajlasma/presentation/intro/intro_tour.dart';

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
  setUpAll(() async {
    await _yaziTipleriniYukle();
    // Üründe motor ilk kareden sonra ısıtılır (main.dart). Isıtılmamış
    // motorla çekilen karelerde risk şeridi ilk çözümlemenin derleme
    // maliyetini ("237204 µs") gösteriyordu — kullanıcının göreceği sayı değil.
    await Civility.warmUp();
  });

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

  testWidgets('masaüstü · yeni gönderi · tehdit onayı', (tester) async {
    final k = await ac(tester, masaustu);
    await tester.tap(find.text('Yeni Gönderi').first);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_14_yeni_gonderi');
    await senaryo(tester, 'Tehdit');
    await tester.tap(find.widgetWithText(FilledButton, 'Gönder').last);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_15_tehdit_onayi');
  });

  testWidgets('masaüstü · gönderi yanıtı', (tester) async {
    final k = await ac(tester, masaustu);
    // Gönderi gövdesi etiketleri vurgulamak için RichText ile çizilir ve
    // akış tembel kurulur: önce kaydırarak ağaca getirmek gerekir.
    final gonderi =
        find.textContaining('penaltı kararı', findRichText: true);
    await tester.scrollUntilVisible(gonderi, 400,
        scrollable: find.byType(Scrollable).at(1));
    await tester.pumpAndSettle();
    await tester.tap(gonderi.first);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_16_gonderi_yanitlari');
  });

  testWidgets('masaüstü · profil ve keşfet', (tester) async {
    final k = await ac(tester, masaustu);
    await tester.tap(find.text('Profil').first);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_17_profil');
    await tester.tap(find.text('Keşfet').first);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_18_kesfet');
    await tester.tap(find.text('Bildirimler').first);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_19_bildirimler');
  });

  testWidgets('masaüstü · karne · kelime listesi anahtarı (uzun)',
      (tester) async {
    final k = await ac(tester, masaustuUzun);
    await panel(tester);
    final anahtar = find.text('Kelime listesi');
    await tester.ensureVisible(anahtar);
    await tester.pumpAndSettle();
    await tester.tap(anahtar);
    await bekle(tester);
    await _cek(tester, k, 'masaustu_20_kelime_listesi');
  });

  testWidgets('masaüstü · yeni gönderi · destek kartı', (tester) async {
    final k = await ac(tester, masaustu);
    await tester.tap(find.text('Yeni Gönderi').first);
    await bekle(tester);
    await tester.enterText(
        find.byType(TextField).last, 'Artık yaşamaya dayanamıyorum');
    await bekle(tester);
    await _cek(tester, k, 'masaustu_21_destek_karti');
  });

  // ── Öneri deneyimi (docs/24 · madde 1–4) ─────────────────────────────────
  // Üç kare: kartta önce/sonra farkı, "Bunu kullan"dan sonraki dönüşüm anı,
  // ve düzeltilmiş metin + yükselen puan + "Geri al". Geri alma sayacı 6 sn
  // sürdüğü için son iki karede pumpAndSettle KULLANILMAZ.
  testWidgets('masaüstü · öneri deneyimi', (tester) async {
    final k = await ac(tester, masaustu);
    await tester.tap(find.text('Yeni Gönderi').first);
    await bekle(tester);
    await tester.enterText(
        find.byType(TextField).last, 'beyinsiz yorumlar yapıyorsun');
    await bekle(tester);
    await _cek(tester, k, 'masaustu_22_oneri_farki');

    final kullan = find.text('Bunu kullan');
    await tester.ensureVisible(kullan);
    await tester.tap(kullan);
    await tester.pump();
    // Kaydırma (260 ms) sürerken silinen kelimeler kızarıp solar…
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await _cek(tester, k, 'masaustu_23a_donusum_silinme');
    // …ardından yeni kelimeler yazılarak gelir.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await _cek(tester, k, 'masaustu_23b_donusum_yazilma');

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await _cek(tester, k, 'masaustu_24_duzeltildi_geri_al');
  });

  // ── İlk açılış turu (docs/24 · madde 31) ──────────────────────────────────
  for (final (ad, boyut) in const [
    ('masaustu_25_tanitim_turu', masaustu),
    ('telefon_05_tanitim_turu', telefon),
  ]) {
    testWidgets('tanıtım turu · $ad', (tester) async {
      final anahtar = GlobalKey();
      tester.view.physicalSize = boyut;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      ThemeController.instance.value = ThemeMode.light;
      // `tool/` test dizini sayılmaz ama bu dosya bir test çalıştırıcısıdır.
      // ignore: invalid_use_of_visible_for_testing_member
      IntroGate.resetForTest();
      await tester.pumpWidget(RepaintBoundary(
          key: anahtar, child: const NSosyalApp(showIntro: true)));
      await tester.pumpAndSettle();
      if (find.text('İleri').evaluate().isNotEmpty) {
        await tester.tap(find.text('İleri'));
        await tester.pumpAndSettle();
      }
      await _cek(tester, anahtar, ad);
    });
  }

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
