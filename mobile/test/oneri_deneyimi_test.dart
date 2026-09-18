// =============================================================================
// Öneri deneyimi — fark, animasyonlu düzeltme, geri al (docs/24 · madde 1–4)
// Dosya: mobile/test/oneri_deneyimi_test.dart
//
// Jüri önünde yapılacak hamle: saldırgan bir cümle yazılır, öneri kartında
// neyin değişeceği görülür, "Bunu kullan"a basılır, metin gözün önünde
// dönüşür, puan yükselir, "Geri al" ile eski hâline döner. Her adım burada
// bir kez yapılır.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/main.dart';
import 'package:turkiye_mesajlasma/presentation/compose/suggestion_morph.dart';

void main() {
  group('1. Kelime farkı', () {
    String yeniden(List<DiffToken> t) => t
        .where((x) => x.op != DiffOp.silinen)
        .map((x) => x.text)
        .join();
    String eski(List<DiffToken> t) => t
        .where((x) => x.op != DiffOp.eklenen)
        .map((x) => x.text)
        .join();

    test('parçalar birleşince iki metin de birebir geri gelir', () {
      const a = 'beyinsiz yorumlar yapıyorsun, bu karar salakça';
      const b = 'Bu yorumlarına katılmıyorum, bu karar hatalı';
      final fark = kelimeFarki(a, b);
      expect(yeniden(fark), b);
      // Aynı sayılan parçalar YENİ metnin yazılışını taşır; eski metin
      // büyük/küçük harf dışında birebir geri gelmeli.
      expect(eski(fark).toLowerCase(), a.toLowerCase());
    });

    test('ortak kısım "aynı" kalır, yalnızca değişen kelime işaretlenir', () {
      final fark = kelimeFarki('bu karar salakça', 'bu karar hatalı');
      expect(fark.first.op, DiffOp.ayni);
      expect(fark.first.text, 'bu karar ');
      expect(fark.where((t) => t.op == DiffOp.silinen).single.text, 'salakça');
      expect(fark.where((t) => t.op == DiffOp.eklenen).single.text, 'hatalı');
    });

    test('büyük/küçük harf farkı değişiklik sayılmaz (Türkçe İ/I dâhil)', () {
      final fark = kelimeFarki('sen İstanbul ışık', 'Sen istanbul Işık');
      expect(fark.every((t) => t.op == DiffOp.ayni), isTrue);
    });

    test('boş girdiler', () {
      expect(kelimeFarki('', ''), isEmpty);
      expect(kelimeFarki('', 'yeni').single.op, DiffOp.eklenen);
      expect(kelimeFarki('eski', '').single.op, DiffOp.silinen);
    });
  });

  group('2. Yazım kutusunda öneri uygulama', () {
    Future<void> yeniGonderi(WidgetTester tester, String metin) async {
      tester.view.physicalSize = const Size(1440, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yeni Gönderi').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, metin);
      await tester.pumpAndSettle();
    }

    TextField kutu(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField).last);

    testWidgets('öneri konuyu korur ve kartta fark gösterilir', (tester) async {
      await yeniGonderi(tester, 'beyinsiz yorumlar yapıyorsun');

      expect(find.text('Böyle mi demek istedin?'), findsOneWidget);
      expect(find.byType(SuggestionDiffPreview), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Önerilen metin: Bu yorumlarına')),
        findsOneWidget,
        reason: 'Öneri "yorum" konusunu taşımalı (docs/24 · madde 1).',
      );
    });

    testWidgets('Bunu kullan → dönüşüm → yeni metin → Geri al', (tester) async {
      const saldirgan = 'beyinsiz yorumlar yapıyorsun';
      await yeniGonderi(tester, saldirgan);

      final kullan = find.text('Bunu kullan');
      await tester.ensureVisible(kullan);
      await tester.tap(kullan);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Animasyon sürerken metin kutusu yerine dönüşüm çizilir ve gönderim
      // kapalıdır.
      expect(find.byType(SuggestionMorphText), findsOneWidget);
      final gonder = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Gönder').last);
      expect(gonder.onPressed, isNull,
          reason: 'Dönüşüm sırasında gönderim yapılamamalı.');

      // Dönüşüm biter (≈1,1 sn) — geri alma sayacı 6 sn olduğu için
      // pumpAndSettle KULLANILMAZ.
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SuggestionMorphText), findsNothing);
      final yeni = kutu(tester).controller!.text;
      expect(yeni, startsWith('Bu yorumlarına'));
      expect(find.text('Neden uyarıldın?'), findsNothing,
          reason: 'Öneri uygulanınca uyarı kaybolmalı.');
      expect(find.textContaining('Artık temiz görünüyor'), findsOneWidget);
      expect(find.textContaining('Nezaket puanı'), findsOneWidget);
      expect(find.text('Geri al'), findsOneWidget);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(kutu(tester).controller!.text, saldirgan);
      expect(find.text('Geri al'), findsNothing);
      expect(find.text('Neden uyarıldın?'), findsOneWidget);
    });

    testWidgets('ton seçilir ve seçilen ton uygulanır (docs/24 · 5)',
        (tester) async {
      await yeniGonderi(tester, 'beyinsiz yorumlar yapıyorsun');

      expect(find.text('Net'), findsOneWidget);
      expect(find.text('Nazik'), findsOneWidget);
      expect(find.text('Diyalog'), findsOneWidget);

      await tester.ensureVisible(find.text('Nazik'));
      await tester.tap(find.text('Nazik'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('Önerilen metin: Kırmak istemem ama')),
        findsOneWidget,
      );

      final kullan = find.text('Bunu kullan');
      await tester.ensureVisible(kullan);
      await tester.tap(kullan);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(kutu(tester).controller!.text,
          'Kırmak istemem ama bu yorumlarına katılmıyorum');
      expect(find.text('Neden uyarıldın?'), findsNothing);
    });

    testWidgets('geri alma teklifi süre dolunca kaybolur', (tester) async {
      await yeniGonderi(tester, 'kapa çeneni artık');

      final kullan = find.text('Bunu kullan');
      await tester.ensureVisible(kullan);
      await tester.tap(kullan);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(find.text('Geri al'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      await tester.pump();
      expect(find.text('Geri al'), findsNothing);
      expect(kutu(tester).controller!.text, 'Biraz dinler misin?',
          reason: 'Süre dolması metni değiştirmez, yalnızca teklifi kaldırır.');
    });

    testWidgets('kullanıcı metne dokununca geri alma teklifi düşer',
        (tester) async {
      await yeniGonderi(tester, 'dangalak gibi konuşuyorsun');

      final kullan = find.text('Bunu kullan');
      await tester.ensureVisible(kullan);
      await tester.tap(kullan);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();
      expect(find.text('Geri al'), findsOneWidget);

      final uygulanan = kutu(tester).controller!.text;
      await tester.enterText(find.byType(TextField).last, '$uygulanan, lütfen');
      await tester.pumpAndSettle();
      expect(find.text('Geri al'), findsNothing,
          reason: 'Geri almak kullanıcının sonradan yazdıklarını silerdi.');
    });
  });
}
