// =============================================================================
// Arayüz testleri
// Dosya: mobile/test/widget_test.dart
//
// KAPSAM KARARI (24 Ağustos 2026)
// -------------------------------
// Devralınan mesajlaşma arayüzü (sohbet, arama, kişiler, kimlik doğrulama,
// ayarlar) üründen silindi; uygulama yalnızca Sosyal Yapay Zekâ katmanından
// oluşuyor. O ekranlara ait testler bu dosyadan kaldırıldı.
//
// Yerlerine YAPISAL bir test kondu: alt gezinme çubuğu, kapsam dışı ilan
// edilen bir sekmeyi geri kabul ederse test kırılır. Kapsam beyanı bir
// belgede değil, test hattında korunur.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/theme/app_palette.dart';
import 'package:turkiye_mesajlasma/core/theme/app_theme.dart';
import 'package:turkiye_mesajlasma/main.dart';

void main() {
  group('Uygulama açılışı', () {
    testWidgets('doğrudan Nezaket Koçu ekranıyla açılır', (tester) async {
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();

      expect(find.text('Nezaket Koçu'), findsWidgets);
    });

    testWidgets('alt çubukta yalnızca üç sekme vardır', (tester) async {
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();

      for (final label in ['Nezaket', 'Topluluk', 'Hakkında']) {
        expect(find.text(label), findsWidgets, reason: '$label sekmesi yok');
      }
    });
  });

  group('Kapsam değişmezi', () {
    // Bu test bir davranışı değil, bir KARARI korur: devralınan mesajlaşma
    // arayüzü ürüne geri sızarsa kırılır.
    testWidgets('kapsam dışı sekmeler arayüze geri gelmemiştir',
        (tester) async {
      await tester.pumpWidget(const NSosyalApp());
      await tester.pumpAndSettle();

      const kapsamDisi = [
        'Sohbetler',
        'Aramalar',
        'Kişiler',
        'Ayarlar',
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
