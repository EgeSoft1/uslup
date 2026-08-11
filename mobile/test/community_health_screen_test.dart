// =============================================================================
// Topluluk Sağlığı Paneli — Arayüz Testleri
// Dosya: mobile/test/community_health_screen_test.dart
//
// Toplulaştırma mantığı `civility_core` içinde ayrıca test edilir. Buradaki
// testler panelin ÜRÜN SÖZLEŞMESİNİ korur:
//
//   • Panel mesaj içeriği gösteremez — gösterirse ürünün tezi çöker.
//   • Gizlenen kategorilerin gizlendiği yazılır; sessiz sansür yok.
//   • Gösterim verisi ile gerçek veri ayrı sayılır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/community/community_health_store.dart';
import 'package:turkiye_mesajlasma/core/theme/app_theme.dart';
import 'package:turkiye_mesajlasma/presentation/community/community_health_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      );

  /// Paneli tek ekrana sığdırır.
  ///
  /// Varsayılan 800x600 test yüzeyinde `ListView` alttaki kartları hiç
  /// KURMAZ; `find` onları bulamaz ve test "özellik yok" der. Oysa özellik
  /// vardır, yalnızca görünmez. Yüzeyi uzatmak, kaydırma taklidi yapmaktan
  /// hem daha hızlı hem daha az kırılgandır.
  void uzunEkran(WidgetTester tester) {
    tester.view.physicalSize = const Size(540, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Topluluk sağlığı paneli', () {
    testWidgets('açılır ve mahremiyet şeridini gösterir', (tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(wrap(const CommunityHealthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Topluluk Sağlığı'), findsOneWidget);
      expect(
          find.textContaining('mesaj içeriğinden üretilmez'), findsOneWidget,
          reason: 'Panelin ne OLMADIĞI, ne olduğu kadar önemli.');
    });

    testWidgets('düzeltme oranı ve müdahale oranı birlikte görünür',
        (tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(wrap(const CommunityHealthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Düzeltme oranı'), findsOneWidget);
      expect(find.text('Müdahale oranı'), findsOneWidget);
    });

    testWidgets('k-anonimlik gizlemesi kullanıcıya AÇIKÇA söylenir',
        (tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(wrap(const CommunityHealthScreen()));
      await tester.pumpAndSettle();

      final store = CommunityHealthStore.instance;
      final gizlenen = store.report.suppressedCategories;

      if (gizlenen > 0) {
        expect(find.textContaining('tür gizlendi'), findsOneWidget,
            reason: 'Sessizce gizlemek, kara kutu moderasyonun ta kendisidir. '
                'Gizlemenin kendisi de şeffaf olmalı.');
      }
    });

    testWidgets('dışa aktarım bloğu yalnızca sayı satırları içerir',
        (tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(wrap(const CommunityHealthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Dışarı ne gider'), findsOneWidget);

      final blok = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((w) => w.data)
          .whereType<String>()
          .join('\n');

      expect(blok, isNotEmpty);
      for (final satir in blok.split('\n')) {
        if (satir.trim().isEmpty) continue;
        final parcalar = satir.split(': ');
        expect(parcalar.length, 2, reason: 'Beklenen biçim "anahtar: sayı".');
        expect(num.tryParse(parcalar[1]), isNotNull,
            reason: '"$satir" satırının değeri sayı değil. Dışa aktarımdan '
                'yalnızca sayı çıkabilir.');
      }
    });

    testWidgets('gösterim verisi gerçek veriden ayrı sayılır', (tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(wrap(const CommunityHealthScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('gösterim sinyali'), findsOneWidget,
          reason: 'Jüriye gösterilen bir panelde hangi sayının gerçek olduğu '
              'belirsiz kalamaz.');
    });
  });

  group('Depo', () {
    test('gerçek sinyal kaydı raporu günceller', () {
      final store = CommunityHealthStore.instance;
      final oncekiGercek = store.realCount;
      final oncekiToplam = store.report.totalSignals;

      final engine = LexicalTurkishClassifier();
      store.record(
          engine.analyze('sen tam bir aptalsın'), SignalOutcome.oneriyiKabulEtti);

      expect(store.realCount, oncekiGercek + 1);
      expect(store.report.totalSignals, oncekiToplam + 1);
    });

    test('gösterim tohumu yalnızca bir kez ekilir', () {
      final store = CommunityHealthStore.instance
        ..seedDemoDataOnce();
      final ilk = store.demoCount;

      store.seedDemoDataOnce();
      store.seedDemoDataOnce();

      expect(store.demoCount, ilk,
          reason: 'Panel her açılışta tohumu yeniden ekerse sayılar şişer.');
    });
  });
}

