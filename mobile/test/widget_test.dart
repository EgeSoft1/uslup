// =============================================================================
// Arayüz testleri
// Dosya: mobile/test/widget_test.dart
//
// Devralınan kod tabanında 9.600 satır arayüz için tek bir "açılıyor mu"
// testi vardı. Bu dosya, bu turda düzeltilen davranışların bir daha
// bozulmamasını sağlar — özellikle mesaj sırası hatası gibi sessiz olanları.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/theme/app_palette.dart';
import 'package:turkiye_mesajlasma/core/theme/app_theme.dart';
import 'package:turkiye_mesajlasma/core/widgets/app_avatar.dart';
import 'package:turkiye_mesajlasma/main.dart';
import 'package:turkiye_mesajlasma/presentation/chat/chat_screen.dart';
import 'package:turkiye_mesajlasma/presentation/conversations/conversation_data.dart';

void main() {
  group('Uygulama açılışı', () {
    testWidgets('splash sonrası kimlik doğrulama akışına geçer',
        (tester) async {
      await tester.pumpWidget(const NSosyalApp());
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('Telefon Numaranız'), findsWidgets);
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

  group('Sohbet verisi', () {
    test('Türkçe arama büyük/küçük harf ve İ/ı farkını yok sayar', () {
      final c = Conversation(
        id: '1',
        name: 'İrem Doğan',
        preview: 'Şimdi geliyorum',
        time: '10:00',
        sortKey: DateTime(2026, 8, 1),
      );

      expect(c.matches('irem'), isTrue);
      expect(c.matches('İREM'), isTrue);
      expect(c.matches('dogan'), isTrue);
      expect(c.matches('simdi'), isTrue);
      expect(c.matches('bulunmayan'), isFalse);
    });

    test('boş arama her sohbeti eşler', () {
      for (final c in demoConversations()) {
        expect(c.matches('   '), isTrue);
      }
    });
  });

  group('AppAvatar', () {
    test('isimden baş harf üretir', () {
      expect(AppAvatar.initialsOf('Ahmet Yılmaz'), 'AY');
      expect(AppAvatar.initialsOf('Aile Grubu'), 'AG');
      expect(AppAvatar.initialsOf('Mehmet'), 'ME');
      expect(AppAvatar.initialsOf('  '), '?');
    });

    test('aynı isim her zaman aynı rengi verir', () {
      final a = AppAvatar.colorOf('Ayşe Kaya', AppPalette.light);
      final b = AppAvatar.colorOf('Ayşe Kaya', AppPalette.light);
      expect(a, b);
    });
  });

  group('Sohbet ekranı — mesaj sırası', () {
    testWidgets('gönderilen mesaj listenin SONUNA eklenir', (tester) async {
      // Gerileme testi: `insert(0, …)` yeni mesajı en eski konuma koyuyor,
      // gönderilen mesaj konuşmanın en üstünde beliriyordu.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ChatScreen(contactName: 'Ahmet Yılmaz'),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byType(ListView);
      expect(listFinder, findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Yeni mesajım');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final newMessage = find.text('Yeni mesajım');
      expect(newMessage, findsOneWidget);

      // Ters çizilen listede en yeni mesaj en ALTTA olmalı: ekranda,
      // ilk (en eski) mesajdan daha aşağıda görünmeli.
      final newY = tester.getCenter(newMessage).dy;
      final oldY = tester.getCenter(find.text('Selam, nasılsın?')).dy;
      expect(newY, greaterThan(oldY));
    });

    testWidgets('temiz metinde nezaket şeridi görünmez', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ChatScreen(contactName: 'Ahmet Yılmaz'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).first, 'Yarın buluşalım mı?');
      await tester.pumpAndSettle();

      // Kesintisizlik ilkesi: düşük riskte hiçbir uyarı çıkmaz.
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('yüksek riskli metinde gönder düğmesi kalkana döner',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ChatScreen(contactName: 'Ahmet Yılmaz'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Sen tam bir aptalsın');
      await tester.pumpAndSettle();

      // Motor bir şey gördü: şerit belirir. Gönderme ENGELLENMEZ,
      // yalnızca kullanıcı basmadan önce bilgilendirilir.
      expect(find.byIcon(Icons.shield_outlined), findsWidgets);
    });
  });
}
