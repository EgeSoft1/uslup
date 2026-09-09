// =============================================================================
// Arayüz testleri
// Dosya: mobile/test/widget_test.dart
//
// KAPSAM KARARI (24 Ağustos 2026 · 9 Eylül 2026'da güncellendi)
// -------------------------------------------------------------
// Devralınan MESAJLAŞMA arayüzü (sohbet, arama, kişiler, kimlik doğrulama)
// üründen silindi ve geri gelmedi.
//
// 9 Eylül'de eklenen sosyal AKIŞ KABUĞU bu kararla çelişmez: katmana yüzey
// sağlar. Ayrımı bir cümleyle söylemek gerekirse — silinen şey ürünün
// yerine geçmeye çalışan bir uygulamaydı, eklenen şey ürünün içine
// takıldığı bir platform.
//
// Kaynak düzeyindeki değişmezler ayrı dosyada: `kapsam_degismezi_test.dart`.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/theme/app_palette.dart';
import 'package:turkiye_mesajlasma/core/theme/app_theme.dart';
import 'package:turkiye_mesajlasma/main.dart';

void main() {
  /// Testleri uzun bir yüzeyde çalıştırır.
  ///
  /// Varsayılan 800x600'de `ListView` alttaki bileşenleri hiç KURMAZ; `find`
  /// onları bulamaz ve test "özellik yok" der. Oysa özellik vardır, yalnızca
  /// görünmez.
  void uzunEkran(WidgetTester tester) {
    tester.view.physicalSize = const Size(560, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Uygulama açılışı', () {
    testWidgets('akış ekranıyla açılır', (tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();

      expect(find.text('Gönderi oluşturmak için…'), findsOneWidget);
      expect(find.text('Akış'), findsWidgets);
    });

    testWidgets('alt çubukta beş sekme vardır', (tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();

      for (final label in ['Akış', 'Keşfet', 'Üslup', 'Topluluk', 'Profil']) {
        expect(find.text(label), findsWidgets, reason: '$label sekmesi yok');
      }
    });
  });

  group('Kapsam değişmezi', () {
    testWidgets('devralınan mesajlaşma ekranları geri gelmemiştir',
        (tester) async {
      uzunEkran(tester);
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();

      const kapsamDisi = [
        'Sohbetler',
        'Aramalar',
        'Kişiler',
        'Telefon Numaranız',
      ];

      for (final label in kapsamDisi) {
        expect(
          find.text(label),
          findsNothing,
          reason: '"$label" kapsam dışıdır; arayüze geri girmiş',
        );
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Ürünün merkezî vaadi, uçtan uca.
  //
  // Bu grup çekirdek motoru DEĞİL, motorun arayüze bağlı olduğunu sınar.
  // Motor 246 testle ayrıca korunuyor; buradaki soru şu: kullanıcı gerçekten
  // yazarken uyarı alıyor mu, ve mağdur gerçekten alMIYOR mu.
  // ───────────────────────────────────────────────────────────────────────────
  group('Üslup katmanı gönderi kutusunda çalışır', () {
    Future<void> gonderiKutusunuAc(WidgetTester tester) async {
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gönderi oluşturmak için…'));
      await tester.pumpAndSettle();
    }

    testWidgets('saldırgan metin gerekçeli uyarı üretir', (tester) async {
      uzunEkran(tester);
      await gonderiKutusunuAc(tester);

      await tester.enterText(
          find.byType(TextField).first, 'sen tam bir aptalsın');
      await tester.pumpAndSettle();

      expect(find.text('Neden uyarıldın?'), findsOneWidget,
          reason: 'Uyarı var ama gerekçesi yoksa bu bir hata mesajıdır, '
              'geri bildirim değil.');
    });

    testWidgets('mağdur anlatısı UYARI ALMAZ', (tester) async {
      uzunEkran(tester);
      await gonderiKutusunuAc(tester);

      await tester.enterText(
          find.byType(TextField).first, 'Bana "aptal" dedi, çok üzüldüm');
      await tester.pumpAndSettle();

      expect(find.text('Neden uyarıldın?'), findsNothing,
          reason: 'Mevcut filtrelerin en ağır kusuru budur: hakaret sözcüğü '
              'geçtiği için ŞİKÂYET EDEN susturulur. Bu ürün tam olarak '
              'bunu yapmamak için var.');
    });

    testWidgets('kimlik beyanı UYARI ALMAZ', (tester) async {
      uzunEkran(tester);
      await gonderiKutusunuAc(tester);

      await tester.enterText(
          find.byType(TextField).first, 'Ben Kürtüm ve bununla gurur duyuyorum');
      await tester.pumpAndSettle();

      expect(find.text('Neden uyarıldın?'), findsNothing,
          reason: 'Kimlik adını yasaklı kelime listesine koyan bir sistem, '
              'korumayı vaat ettiği grubu susturur.');
    });

    testWidgets('sert ama meşru eleştiri UYARI ALMAZ', (tester) async {
      uzunEkran(tester);
      await gonderiKutusunuAc(tester);

      await tester.enterText(find.byType(TextField).first,
          'Bu karar bence tamamen hatalı ve geri alınmalı');
      await tester.pumpAndSettle();

      expect(find.text('Neden uyarıldın?'), findsNothing,
          reason: 'Eleştiriyi hakaret sayan bir katman, ürünün "sansür değil" '
              'iddiasını çürütür.');
    });
  });

  group('Tema', () {
    test('açık ve koyu tema paleti taşır', () {
      final light = AppTheme.lightTheme.extension<AppPalette>();
      final dark = AppTheme.darkTheme.extension<AppPalette>();

      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(light!.isDark, isFalse);
      expect(dark!.isDark, isTrue);
    });

    test('koyu temada zemin ile metin farklı; marka rengi açılmış', () {
      final dark = AppTheme.darkTheme.extension<AppPalette>()!;
      final light = AppTheme.lightTheme.extension<AppPalette>()!;

      expect(dark.background, isNot(dark.textPrimary));
      // Koyu zeminde okunabilmesi için marka mürekkebi açık tonda olmalı.
      expect(dark.brandInk.computeLuminance(),
          greaterThan(light.brandInk.computeLuminance()));
    });
  });
}
