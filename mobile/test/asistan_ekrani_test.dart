// =============================================================================
// Üslup Asistanı ekranı — arayüz testleri
// Dosya: mobile/test/asistan_ekrani_test.dart
//
// Niyet çözümleme ve içerik doğruluğu çekirdekte sınanıyor
// (`civility_core/test/asistan_test.dart`). Burada sınanan şey ARAYÜZÜN o
// çekirdeğe gerçekten bağlı olduğu: yazılan soru cevaba dönüşüyor mu,
// örnek kartına dokunmak cümleyi çözümletiyor mu, ekran kendini doğru
// adlandırıyor mu.
//
// Demoda bu ekran jürinin önünde açılacak; "hatasız" iddiası ancak bu
// yollar testliyse anlamlıdır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/civility/civility_runtime.dart';
import 'package:turkiye_mesajlasma/presentation/uslup/engine_chat_screen.dart';

void main() {
  setUpAll(() async {
    await Civility.init();
  });

  Future<void> ekraniAc(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: EngineChatScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> yaz(WidgetTester tester, String metin) async {
    await tester.enterText(find.byType(TextField), metin);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('ekran kendini dil modeli diye tanıtmaz', (tester) async {
    await ekraniAc(tester);
    expect(find.text('Üslup Asistanı'), findsOneWidget);
    expect(
      find.textContaining('dil modeli yok', findRichText: true),
      findsWidgets,
      reason: 'Şerit ekranın ne olduğunu söylemeli.',
    );
  });

  testWidgets('açılışta ne sorulabileceği gösterilir', (tester) async {
    await ekraniAc(tester);
    expect(find.textContaining('Şunları sorabilirsin'), findsOneWidget);
    // Devam önerisi çipleri dokunulabilir olmalı.
    expect(find.textContaining('nefret söylemi örnekleri sun'), findsWidgets);
  });

  testWidgets('içerik istendiğinde örnek kartları çıkar', (tester) async {
    await ekraniAc(tester);
    await yaz(tester, 'bana nefret söylemi örnekleri sun');

    expect(find.text('Nefret söylemi'), findsWidgets);
    expect(find.text('Bütün Suriyeliler hırsızdır'), findsOneWidget);
    expect(find.text('Ben Kürtüm ve bununla gurur duyuyorum'), findsOneWidget);
    // Rozetler: biri işaretlenir, biri temiz.
    expect(find.text('İşaretlenir'), findsWidgets);
    expect(find.text('Temiz'), findsWidgets);
  });

  testWidgets('örnek kartına dokunmak o cümleyi çözümletir', (tester) async {
    await ekraniAc(tester);
    await yaz(tester, 'nefret söylemi örnekleri');

    final kart = find.text('Bütün Suriyeliler hırsızdır').first;
    await tester.ensureVisible(kart);
    await tester.pumpAndSettle();
    await tester.tap(kart);
    await tester.pumpAndSettle();

    // Cümle kullanıcı baloncuğu olarak eklenir ve çözümleme başlığı çıkar.
    expect(find.textContaining('Bu cümleyi çözümledim'), findsOneWidget);
    expect(find.textContaining('µs'), findsWidgets,
        reason: 'Çözümleme süresi gösterilmeli — ölçüm iddiası ekranda.');
  });

  testWidgets('ölçüm sorusu kör küme sayılarını getirir', (tester) async {
    await ekraniAc(tester);
    await yaz(tester, 'ölçüm sonuçlarınız ne');

    expect(find.text('Ölçüm sonuçları'), findsOneWidget);
    expect(find.textContaining('%45,0'), findsWidgets);
  });

  testWidgets('mahremiyet sorusu cevaplanır', (tester) async {
    await ekraniAc(tester);
    await yaz(tester, 'yazdıklarım nereye gidiyor');
    expect(find.text('Metin cihazdan çıkmaz'), findsOneWidget);
  });

  testWidgets('düz cümle çözümlenir ve gerekçe gösterilir', (tester) async {
    await ekraniAc(tester);
    await yaz(tester, 'Sen tam bir aptalsın');

    expect(find.textContaining('Bu cümleyi çözümledim'), findsOneWidget);
    expect(find.textContaining('nezaket puanı'), findsWidgets);
  });

  testWidgets('mağdur anlatısı ekranda da temiz kalır', (tester) async {
    await ekraniAc(tester);
    await yaz(tester, 'Bana "aptal" dedi, çok üzüldüm');

    // Tırnak içindeki metin alıntı olarak ayıklanır ve çözümlenir; sonuç
    // temiz olmalı — ürünün en ayırt edici davranışı.
    expect(find.text(RiskLevel.temiz.label), findsWidgets);
  });

  testWidgets('tanınmayan girdide ekran çalışmayı sürdürür', (tester) async {
    await ekraniAc(tester);
    await yaz(tester, 'qwerty asdfgh');
    // İki kelimelik girdi bir cümle sayılıp çözümlenir; önemli olan ekranın
    // bir cevap üretmesi ve yazmaya devam edilebilmesi.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Ölçüm sonuçlarınız ne?'), findsWidgets,
        reason: 'Her cevap bir sonraki adımı önermeli.');
  });

  testWidgets('boş gönderim hiçbir şey eklemez', (tester) async {
    await ekraniAc(tester);
    final oncesi = tester.widgetList(find.byType(InkWell)).length;
    await yaz(tester, '   ');
    expect(tester.widgetList(find.byType(InkWell)).length, oncesi);
  });
}
