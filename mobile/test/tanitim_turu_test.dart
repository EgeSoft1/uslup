// =============================================================================
// İlk açılış turu (docs/24 · madde 31)
// Dosya: mobile/test/tanitim_turu_test.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/main.dart';

void main() {
  testWidgets('tur üç adımda ilerler, örnek motorun gerçek çıktısıdır',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const NSosyalApp(showIntro: true));
    await tester.pumpAndSettle();

    expect(find.text('Yazarken çözümler'), findsOneWidget);
    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();

    expect(find.text('Nedenini söyler, öneri sunar'), findsOneWidget);
    expect(find.text('Sen tam bir aptalsın'), findsOneWidget);
    expect(find.text('Bu konuda sana katılmıyorum'), findsOneWidget,
        reason: 'Turdaki öneri motorun gerçek çıktısı olmalı.');

    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    expect(find.text('Karar senin'), findsOneWidget);

    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Karar senin'), findsNothing);
  });

  testWidgets('testler ve ekran görüntüsü aracı turu görmez', (tester) async {
    await tester.pumpWidget(const NSosyalApp());
    await tester.pumpAndSettle();
    expect(find.text('Yazarken çözümler'), findsNothing);
  });
}
