// =============================================================================
// Demo güvencesi — jüri önünde yapılacak her hamle burada bir kez yapılır
// Dosya: mobile/test/demo_guvencesi_test.dart
//
// ── NEDEN AYRI BİR DOSYA ──────────────────────────────────────────────────
// `docs/17_JURI_DEMO_SENARYOSU.md` sunumda hangi çipe dokunulacağını ve
// ekranda ne görüneceğini yazıyor. Motora ya da arayüze yapılan her değişiklik
// o senaryoyu sessizce bozabilir: bir çip artık beklenen sonucu vermez, bir
// öneri yarım cümleye döner, karne 11/12'ye düşer. Bunu sunum sabahı değil,
// değişikliği yapan kişi `flutter test` çalıştırdığında görmek gerekir.
//
// Buradaki her test, sunum belgesindeki bir adımın karşılığıdır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/civility/civility_runtime.dart';
import 'package:turkiye_mesajlasma/core/civility/naive_wordlist_filter.dart';
import 'package:turkiye_mesajlasma/main.dart';
import 'package:turkiye_mesajlasma/presentation/uslup/demo_scenarios.dart';
import 'package:turkiye_mesajlasma/presentation/uslup/engine_chat_screen.dart';

void main() {
  void ekran(WidgetTester tester, Size boyut) {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Senaryo çipleri — sunum belgesindeki beklentiler', () {
    test('12 senaryonun hepsi beklenen kararı verir', () {
      final sapmalar = <String>[];
      for (final s in demoScenarios) {
        final analiz = Civility.engine.analyze(s.text);
        final isaretlendi = analiz.risk != RiskLevel.temiz;
        if (isaretlendi != s.expectFlag) {
          sapmalar.add('${s.label}: "${s.text}" → ${analiz.risk.label}');
        }
      }
      expect(sapmalar, isEmpty,
          reason: 'Bağlam karnesi jürinin önünde 12/12 göstermeli. '
              'Sapan senaryolar: $sapmalar');
    });

    test('ilk dördü AYNI kelimeyi içerir — sunumun ayrıştığı an', () {
      for (final s in demoScenarios.take(4)) {
        expect(s.text.toLowerCase(), contains('aptal'),
            reason: 'Sunum "dördünde de aynı kelime var" diyor.');
      }
    });

    test('işaretlenen her senaryo anlamlı, daha temiz bir öneri üretir',
        () async {
      for (final s in demoScenarios.where((s) => s.expectFlag)) {
        final analiz = Civility.engine.analyze(s.text);
        final oneri = await Civility.suggester.suggest(analiz);
        expect(oneri, isNotNull, reason: '"${s.text}" için öneri yok.');

        final kelimeler = oneri!.text.trim().split(RegExp(r'\s+'));
        expect(kelimeler.length, greaterThanOrEqualTo(3),
            reason: '"${s.text}" → "${oneri.text}" yarım bir cümle. '
                'Jüri önünde "Bunu kullan"a basılacak.');

        final yeniden = Civility.engine.analyze(oneri.text);
        expect(yeniden.toxicity, lessThan(analiz.toxicity),
            reason: 'Öneri orijinalden temiz değil: "${oneri.text}"');
        expect(yeniden.risk, RiskLevel.temiz,
            reason: 'Öneri kabul edilince uyarı kaybolmalı; '
                '"${oneri.text}" hâlâ ${yeniden.risk.label}.');
      }
    });

    test('tehdit senaryosu en üst basamaktadır (onay diyaloğu açılır)', () {
      final tehdit = demoScenarios.firstWhere((s) => s.label == 'Tehdit');
      expect(Civility.engine.analyze(tehdit.text).risk, RiskLevel.yuksek);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Üslup paneli — masaüstü sunum ekranı', () {
    Future<void> paneliAc(WidgetTester tester) async {
      ekran(tester, const Size(1440, 2600));
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Üslup Paneli').first);
      await tester.pumpAndSettle();
    }

    testWidgets('bağlam karnesi 12/12 gösterir', (tester) async {
      await paneliAc(tester);
      expect(find.text('${demoScenarios.length}/${demoScenarios.length} '
          'beklendiği gibi'), findsOneWidget);
    });

    testWidgets('çipe dokununca uyarı, öneri ve beklenti satırı görünür',
        (tester) async {
      await paneliAc(tester);
      final cip = find.text('Doğrudan saldırı').first;
      await tester.ensureVisible(cip);
      await tester.tap(cip);
      await tester.pumpAndSettle();

      expect(find.text('Neden uyarıldın?'), findsOneWidget);
      expect(find.text('Böyle mi demek istedin?'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets,
          reason: 'Beklenti satırı ✓ göstermeli.');
    });

    testWidgets('mağdur anlatısı çipi uyarı üretmez', (tester) async {
      await paneliAc(tester);
      final cip = find.text('Mağdur anlatısı').first;
      await tester.ensureVisible(cip);
      await tester.tap(cip);
      await tester.pumpAndSettle();

      expect(find.text('Neden uyarıldın?'), findsNothing);
    });

    testWidgets('kelime listesi anahtarı aynı cümlelerde farkı gösterir',
        (tester) async {
      await paneliAc(tester);
      final anahtar = find.text('Kelime listesi');
      await tester.ensureVisible(anahtar);
      await tester.tap(anahtar);
      await tester.pumpAndSettle();

      final filtre = NaiveWordlistFilter.instance;
      final yanlisAlarm = demoScenarios
          .where((s) => !s.expectFlag && filtre.flags(s.text))
          .length;
      final kacan = demoScenarios
          .where((s) => s.expectFlag && !filtre.flags(s.text))
          .length;
      expect(yanlisAlarm + kacan, greaterThan(0),
          reason: 'Anahtar hiçbir fark göstermiyorsa sunumdaki an boştur.');
      expect(
          find.text('$yanlisAlarm masum cümle işaretlendi · '
              '$kacan saldırı kaçtı'),
          findsOneWidget);
      expect(
          find.text('${demoScenarios.length - yanlisAlarm - kacan}/'
              '${demoScenarios.length} beklendiği gibi'),
          findsOneWidget);

      // Geri dönünce karne yine motorun sonucunu gösterir.
      await tester.tap(find.descendant(
          of: find.byType(SegmentedButton<bool>), matching: find.text('Üslup')));
      await tester.pumpAndSettle();
      expect(find.text('${demoScenarios.length}/${demoScenarios.length} '
          'beklendiği gibi'), findsOneWidget);
    });

    testWidgets('sahte ağ düğmesi ve yanlış LLM etiketi geri gelmedi',
        (tester) async {
      await paneliAc(tester);
      expect(find.textContaining('VDS'), findsNothing);
      expect(find.textContaining('LLM'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Yeni gönderi — tehdit onayı', () {
    testWidgets('tehdit gönderilmek istenince onay diyaloğu açılır',
        (tester) async {
      ekran(tester, const Size(1440, 1800));
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yeni Gönderi').first);
      await tester.pumpAndSettle();
      final cip = find.text('Tehdit').first;
      await tester.ensureVisible(cip);
      await tester.tap(cip);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Gönder').last);
      await tester.pumpAndSettle();

      expect(find.text('Göndermeden önce bir saniye'), findsOneWidget);
      expect(find.text('Yine de gönder'), findsOneWidget,
          reason: 'Sistem engellemez; "Yine de gönder" her zaman görünür.');

      // Vazgeç — diyalog kapanır, metin kutuda kalır.
      await tester.tap(find.text('Vazgeç, düzelteyim'));
      await tester.pumpAndSettle();
      expect(find.text('Göndermeden önce bir saniye'), findsNothing);
    });

    Future<void> yeniGonderiyeYaz(WidgetTester tester, String metin) async {
      ekran(tester, const Size(1440, 1800));
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yeni Gönderi').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, metin);
      await tester.pumpAndSettle();
    }

    testWidgets('jürinin yazabileceği "ama"lı sıradan cümle uyarı üretmez',
        (tester) async {
      // docs/20: bu cümle 13 Eylül'e kadar Yüksek risk (küfür) alıyordu.
      await yeniGonderiyeYaz(tester, 'Sana katılıyorum ama bence yanlış');
      expect(find.text('Neden uyarıldın?'), findsNothing);
    });

    testWidgets('kendine zarar cümlesi destek kartı gösterir, tehdit onayı açmaz',
        (tester) async {
      await yeniGonderiyeYaz(tester, 'Artık yaşamaya dayanamıyorum');
      expect(find.text('Zor bir an geçiriyor olabilirsin'), findsOneWidget);
      expect(find.text('Neden uyarıldın?'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Gönder').last);
      await tester.pumpAndSettle();
      expect(find.text('Göndermeden önce bir saniye'), findsNothing,
          reason: 'Önceki sürüm "Tehdit, TCK kapsamında suç oluşturabilir" '
              'diyaloğu açıyordu.');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Motorla soru-cevap', () {
    testWidgets('cevap yapılandırılmış gelir, ham markdown içermez',
        (tester) async {
      ekran(tester, const Size(800, 1400));
      await tester.pumpWidget(const MaterialApp(home: EngineChatScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'sen tam bir aptalsın');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('**'), findsNothing);
      expect(find.text('Böyle de söyleyebilirsin'), findsOneWidget);
      expect(find.text('aptalsın'), findsOneWidget,
          reason: 'Eşleşen ifade bulgu satırında gösterilmeli.');
    });
  });
}
