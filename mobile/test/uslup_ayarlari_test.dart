// =============================================================================
// Kullanıcı kontrolü — ayarlar ve "Bu uyarı yanlış" (docs/27)
// Dosya: mobile/test/uslup_ayarlari_test.dart
//
// Politika mantığı çekirdekte test edilir (`uslup_ayarlari_test.dart`). Bu
// dosya arayüzün o politikaya GERÇEKTEN bağlı olduğunu sınar: ayar ekranında
// seçilen şey yazım kutusunda olur, itiraz uyarıyı gizler ve sinyale geçer.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/civility/uslup_ayar_denetleyici.dart';
import 'package:turkiye_mesajlasma/core/theme/app_theme.dart';
import 'package:turkiye_mesajlasma/presentation/compose/civility_composer.dart';
import 'package:turkiye_mesajlasma/presentation/settings/uslup_ayarlari_screen.dart';

void main() {
  void uzunEkran(WidgetTester tester) {
    tester.view.physicalSize = const Size(560, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  tearDown(() => UslupAyarDenetleyici.instance.sifirla());

  /// Ayarı doğrudan atar. `guncelle` platform kanalına yazar ve widget
  /// testinin sahte zamanında o yanıt hiç gelmez; `await` testi kilitler.
  /// Kalıcılık bu dosyanın konusu değildir.
  void ayarla(UslupAyarlari ayar) => UslupAyarDenetleyici.instance.value = ayar;

  Future<ComposerResult? Function()> kutuyuKur(WidgetTester tester) async {
    ComposerResult? sonuc;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CivilityComposer(onSubmit: (r) => sonuc = r),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return () => sonuc;
  }

  group('Yazım kutusu ayarı izler', () {
    testWidgets('katman kapalıyken saldırgan metin uyarı almaz ve bunu söyler',
        (tester) async {
      uzunEkran(tester);
      await kutuyuKur(tester);
      ayarla(const UslupAyarlari(etkin: false));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'sen tam bir aptalsın');
      await tester.pumpAndSettle();

      expect(find.text('Neden uyarıldın?'), findsNothing);
      expect(find.text('Üslup kapalı · Ayarlar'), findsOneWidget,
          reason: 'Kullanıcı neden uyarı almadığını görebilmeli.');
    });

    testWidgets('katman kapalıyken gönderim topluluk ölçümüne girmez',
        (tester) async {
      uzunEkran(tester);
      final sonuc = await kutuyuKur(tester);
      ayarla(const UslupAyarlari(etkin: false));
      await tester.enterText(find.byType(TextField), 'merhaba');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      expect(sonuc(), isNotNull);
      expect(sonuc()!.olcumeDahil, isFalse);
    });

    testWidgets('"yalnızca ağır" ayarında orta düzey hakaret sessiz kalır',
        (tester) async {
      uzunEkran(tester);
      await kutuyuKur(tester);
      ayarla(const UslupAyarlari(hassasiyet: Hassasiyet.yalnizcaAgir));

      await tester.enterText(find.byType(TextField), 'sen tam bir aptalsın');
      await tester.pumpAndSettle();
      expect(find.text('Neden uyarıldın?'), findsNothing);

      await tester.enterText(find.byType(TextField), 'seni bulup gebertirim');
      await tester.pumpAndSettle();
      expect(find.text('Neden uyarıldın?'), findsOneWidget,
          reason: 'Tehdit bu ayarda da uyarı almalı.');
    });

    testWidgets('ayar değişince aynı metin yeniden yansıtılır', (tester) async {
      uzunEkran(tester);
      await kutuyuKur(tester);
      await tester.enterText(find.byType(TextField), 'sen tam bir aptalsın');
      await tester.pumpAndSettle();
      expect(find.text('Neden uyarıldın?'), findsOneWidget);

      ayarla(const UslupAyarlari(etkin: false));
      await tester.pumpAndSettle();
      expect(find.text('Neden uyarıldın?'), findsNothing);
    });
  });

  group('"Bu uyarı yanlış"', () {
    testWidgets('itiraz uyarıyı gizler, geri alınabilir', (tester) async {
      uzunEkran(tester);
      await kutuyuKur(tester);
      await tester.enterText(find.byType(TextField), 'sen tam bir aptalsın');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bu uyarı yanlış'));
      await tester.pumpAndSettle();
      expect(find.text('Neden uyarıldın?'), findsNothing);
      expect(find.text('Teşekkürler — uyarı bu metin için gizlendi.'),
          findsOneWidget);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(find.text('Neden uyarıldın?'), findsOneWidget);
    });

    testWidgets('itiraz edilen metin gönderilince sinyale yalnızca işaret geçer',
        (tester) async {
      uzunEkran(tester);
      final sonuc = await kutuyuKur(tester);
      await tester.enterText(find.byType(TextField), 'sen tam bir aptalsın');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bu uyarı yanlış'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      final r = sonuc();
      expect(r, isNotNull, reason: 'İtirazdan sonra gönderim beklemeden olur.');
      expect(r!.yanlisAlarm, isTrue);
      final sinyal = CommunitySignal.fromAnalysis(r.analysis, r.outcome,
          yanlisAlarm: r.yanlisAlarm);
      expect(sinyal.yanlisAlarmBildirildi, isTrue);
    });

    testWidgets('metin değişirse itiraz düşer ve uyarı döner', (tester) async {
      uzunEkran(tester);
      await kutuyuKur(tester);
      await tester.enterText(find.byType(TextField), 'sen tam bir aptalsın');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bu uyarı yanlış'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'sen tam bir aptalsın be');
      await tester.pumpAndSettle();
      expect(find.text('Neden uyarıldın?'), findsOneWidget);
    });
  });

  group('Ayar ekranı', () {
    Future<void> ekraniAc(WidgetTester tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const UslupAyarlariScreen(),
      ));
      await tester.pumpAndSettle();
    }

    String sonucu(WidgetTester tester, String metin) =>
        tester.widget<Text>(find.byKey(ValueKey('onizleme-$metin'))).data!;

    testWidgets('önizleme motordan gelir ve seçimle değişir', (tester) async {
      await ekraniAc(tester);
      expect(sonucu(tester, 'sen tam bir aptalsın'), 'Gerekçe ve öneri');
      expect(sonucu(tester, 'seni bulup gebertirim'), 'Gönderim öncesi onay');

      await tester.tap(find.byKey(const ValueKey('ayar-hassasiyet-yalnizcaAgir')));
      await tester.pumpAndSettle();
      expect(sonucu(tester, 'sen tam bir aptalsın'), 'Hiçbir şey gösterilmez');
      expect(sonucu(tester, 'seni bulup gebertirim'), 'Gönderim öncesi onay');

      await tester.tap(find.byKey(const ValueKey('ayar-hassasiyet-hassas')));
      await tester.pumpAndSettle();
      expect(sonucu(tester, 'sus artık'), 'Gerekçe ve öneri');
    });

    testWidgets('argo susturulunca argo cümlesi sessiz, tehdit değişmez',
        (tester) async {
      await ekraniAc(tester);
      await tester.tap(find.byKey(const ValueKey('ayar-kategori-kufur')));
      await tester.pumpAndSettle();
      expect(sonucu(tester, 'amk yine geç kaldım'), 'Hiçbir şey gösterilmez');
      expect(sonucu(tester, 'seni bulup gebertirim'), 'Gönderim öncesi onay');
    });

    testWidgets('katmanı kapatınca hiçbir örnek bir şey göstermez',
        (tester) async {
      await ekraniAc(tester);
      await tester.tap(find.byKey(const ValueKey('ayar-etkin')));
      await tester.pumpAndSettle();
      for (final o in UslupAyarlariScreen.ornekler) {
        expect(sonucu(tester, o.metin), 'Hiçbir şey gösterilmez');
      }
      expect(find.textContaining('kapatılamaz'), findsOneWidget,
          reason: 'Kilitli kategoriler gerekçesiyle yazılmalı.');
    });
  });
}
