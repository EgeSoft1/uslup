// =============================================================================
// Büyük yazı ölçeğinde taşma denetimi
// Dosya: mobile/test/buyuk_yazi_tasma_test.dart
//
// ── NEDEN ─────────────────────────────────────────────────────────────────
// `main.dart` sistem yazı ölçeğini 1,3×'e kadar kabul eder (erişilebilirlik).
// Bir satırın o ölçekte taşması, düşük görüşlü kullanıcıya sarı-siyah uyarı
// şeridi ya da kesilmiş bir düğme demektir — ve normal ölçekte çalışan hiçbir
// test bunu görmez. 13 Eylül'de bağlam karnesindeki "Yüksek risk" etiketi
// tam olarak böyle taşıyordu.
//
// ── NEDEN GERÇEK YAZI TİPLERİ ─────────────────────────────────────────────
// Test çalıştırıcısının varsayılan yazı tipinde her harf kare genişliğindedir
// (Inter'in yaklaşık iki katı). O yazı tipiyle ölçülen taşma gerçeği
// yansıtmaz; burada uygulamanın paketlediği Inter ve Outfit yüklenir.
// =============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/main.dart';

Future<void> _yaziTipleri() async {
  for (final (aile, yol) in const [
    ('Inter', 'assets/fonts/Inter-Variable.ttf'),
    ('Outfit', 'assets/fonts/Outfit-Variable.ttf'),
  ]) {
    final bayt = File(yol).readAsBytesSync();
    await (FontLoader(aile)
          ..addFont(
              Future.value(ByteData.view(Uint8List.fromList(bayt).buffer))))
        .load();
  }
}

void main() {
  setUpAll(_yaziTipleri);

  Future<void> ac(WidgetTester tester, Size boyut) async {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(const NSosyalApp());
    await tester.pumpAndSettle();
  }

  Future<void> sekme(WidgetTester tester, String ad) async {
    await tester.tap(find.text(ad).last);
    await tester.pumpAndSettle();
  }

  // Küçük bir Android telefonun mantıksal genişliği.
  const kucukTelefon = Size(360, 780);

  testWidgets('telefon · bütün sekmeler 1,3× ölçekte taşmaz', (tester) async {
    await ac(tester, kucukTelefon);
    for (final ad in ['Keşfet', 'Üslup', 'Topluluk', 'Profil', 'Akış']) {
      await sekme(tester, ad);
      expect(tester.takeException(), isNull, reason: '$ad sekmesi taştı.');
    }
  });

  testWidgets('telefon · uyarı ve öneri kartları 1,3× ölçekte taşmaz',
      (tester) async {
    await ac(tester, kucukTelefon);
    await sekme(tester, 'Üslup');

    for (final etiket in ['Doğrudan saldırı', 'Nefret söylemi', 'Tehdit']) {
      final cip = find.text(etiket).first;
      await tester.ensureVisible(cip);
      await tester.pumpAndSettle();
      await tester.tap(cip);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: '"$etiket" senaryosunda kart taştı.');
    }

    // Karnenin tamamı kurulsun diye aşağı kaydır.
    await tester.drag(find.byType(ListView).first, const Offset(0, -2500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Bağlam karnesi taştı.');
  });

  testWidgets('masaüstü · dar pencere (1024) 1,3× ölçekte taşmaz',
      (tester) async {
    await ac(tester, const Size(1024, 768));
    for (final ad in [
      'Bildirimler',
      'Keşfet',
      'Üslup Paneli',
      'Topluluk Sağlığı',
      'Kaydedilenler',
      'Profil',
      'Ana Sayfa',
    ]) {
      await tester.tap(find.byTooltip(ad).evaluate().isNotEmpty
          ? find.byTooltip(ad).first
          : find.bySemanticsLabel(RegExp('^$ad')).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$ad bölümü taştı.');
    }
  });
}
