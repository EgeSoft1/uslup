// =============================================================================
// Kapsam değişmezleri — kaynak kod düzeyinde
// Dosya: mobile/test/kapsam_degismezi_test.dart
//
// ── NEDEN KAYNAK OKUYAN BİR TEST ──────────────────────────────────────────
// Bu dosyadaki iki test bir DAVRANIŞ değil, bir KARAR korur. İkisi de
// ürünün jüriye verdiği sözlerdir ve ikisi de tek bir dosyanın sessizce
// eklenmesiyle çiğnenebilir:
//
//   1. "Katman platformun HER metin giriş noktasında çalışır."
//      Bir ekran kendi ham `TextField`ini koyarsa bu söz bozulur ve hiçbir
//      davranış testi bunu göremez — çünkü kırılan bir şey yoktur, eksik
//      olan bir şey vardır.
//
//   2. "Ürün çalışma zamanında tek bir ağ çağrısı yapmaz."
//      Tek bir `Image.network` avatarı bu iddiayı çürütür ve uygulama
//      kusursuz çalışmaya devam eder.
//
// Eksik olanı davranış testiyle yakalayamazsınız. Kaynağı okumak gerekir.
//
// Aynı yöntem projede başka yerlerde de kullanılıyor: kimlik adlarının
// sözlüğe sızmasını engelleyen test, anonim sinyalin metin taşımasını
// engelleyen test ve `tool/erisilebilirlik_denetimi.dart`.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/` altındaki tüm Dart kaynakları, depo köküne göre `/` ayraçlı yolla.
List<({String path, String source})> _libSources() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    fail('Testler `mobile/` dizininden çalıştırılmalı: `flutter test`');
  }

  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => (
            path: f.path.replaceAll(r'\', '/'),
            source: f.readAsStringSync(),
          ))
      .toList();
}

void main() {
  group('Değişmez 1 · Her metin girişi Üslup katmanından geçer', () {
    // Ham metin girdisi kullanmasına İZİN VERİLEN dosyalar.
    //
    // civility_composer.dart — katmanın kendisi; içindeki `TextField`
    //   zaten çözümlenen kutudur.
    // explore_screen.dart    — arama kutuları (akış içi ve masaüstü sağ
    //   sütun). Yazdığı şey yayımlanmaz, kimseye ulaşmaz ve bir başkasına
    //   zarar veremez; müdahale etmek kullanıcıyı sebepsiz kısıtlamak
    //   olurdu. Masaüstü kutusu da BU dosyada durur: izin listesini
    //   büyütmek, değişmezi zamanla anlamsızlaştırırdı.
    // engine_chat_screen.dart — motorun kendisiyle konuşulan deneme
    //   ekranı. Buradaki kutu bir yayın yüzeyi DEĞİLDİR: yazılan cümle
    //   hiçbir yere gönderilmez, doğrudan motora verilir ve çıktısı
    //   (toksisite, bulgular, gerekçe, öneri) ekrana yazılır. Yani metin
    //   zaten katmandan geçer — `CivilityComposer` ile sarmak, çözümlemeyi
    //   iki kez çalıştırmak olurdu. Aşağıdaki ikinci test bu dosyanın
    //   motoru gerçekten çağırdığını denetler; çağırmayı bırakırsa istisna
    //   kendiliğinden geçersizleşir.
    const izinliDosyalar = <String>{
      'lib/presentation/compose/civility_composer.dart',
      'lib/presentation/explore/explore_screen.dart',
      'lib/presentation/uslup/engine_chat_screen.dart',
    };

    final girdiKaliplari = RegExp(
      r'\b(TextField|TextFormField|EditableText|CupertinoTextField)\s*\(',
    );

    test('ham metin girdisi yalnızca izinli dosyalarda bulunur', () {
      final ihlaller = <String>[];

      for (final file in _libSources()) {
        if (!girdiKaliplari.hasMatch(file.source)) continue;
        if (izinliDosyalar.any(file.path.endsWith)) continue;
        ihlaller.add(file.path);
      }

      expect(
        ihlaller,
        isEmpty,
        reason: 'Şu dosyalar Üslup katmanından geçmeyen bir metin girişi '
            'ekliyor: ${ihlaller.join(", ")}.\n'
            'Kullanıcının başkalarına ulaşacak metin yazdığı her yüzey '
            '`CivilityComposer` kullanmalıdır. Gerçekten istisna gerekiyorsa '
            'bu testteki izinli listeye GEREKÇESİYLE eklenmelidir.',
      );
    });

    test('katmanın kendisi motoru gerçekten çağırır', () {
      final composer = _libSources().firstWhere(
        (f) => f.path.endsWith('lib/presentation/compose/civility_composer.dart'),
        orElse: () => fail('civility_composer.dart bulunamadı'),
      );

      // İzinli listedeki dosyanın adı doğru ama içi boşsa değişmez anlamsız
      // kalırdı: kutu çözümleme yapmıyorsa "katman her yerde çalışıyor"
      // cümlesi yine yanlış olur.
      expect(
        composer.source.contains('Civility.engine.analyze'),
        isTrue,
        reason: 'CivilityComposer motoru çağırmıyor; kutu bir metin '
            'kutusundan ibaret kalmış.',
      );
    });

    test('deneme ekranı istisnası motoru çağırdığı sürece geçerlidir', () {
      final chat = _libSources().firstWhere(
        (f) => f.path.endsWith('lib/presentation/uslup/engine_chat_screen.dart'),
        orElse: () => fail('engine_chat_screen.dart bulunamadı'),
      );

      // İstisnanın GEREKÇESİ "metin zaten motora gidiyor"du. Gitmiyorsa
      // istisna da yok: bu ekran o zaman sıradan bir metin kutusudur ve
      // `CivilityComposer` kullanmak zorundadır.
      //
      // Ekran asistana dönüştüğünde çağrı biçimi değişti: motor artık
      // doğrudan değil, `UslupAsistani`ye verilerek çağrılıyor
      // (`UslupAsistani(motor: Civility.engine)`). Gerekçe aynı — metin hâlâ
      // motora gidiyor — ama düz metin araması bunu göremiyordu. Aranan şey
      // motorun bu dosyada gerçekten bağlanmış olmasıdır.
      expect(
        chat.source.contains('Civility.engine'),
        isTrue,
        reason: 'engine_chat_screen.dart motoru bağlamıyor; izinli listedeki '
            'gerekçesi düşmüş. Ya motoru çağırsın ya CivilityComposer '
            'kullansın.',
      );
      expect(
        chat.source.contains('UslupAsistani') ||
            chat.source.contains('.analyze('),
        isTrue,
        reason: 'Motor bağlanmış ama çözümleme yapılmıyor görünüyor.',
      );
    });
  });

  group('Değişmez 2 · Çalışma zamanında ağ çağrısı yoktur', () {
    // Rapor §2.2: "ürün çalışma zamanında tek bir ağ çağrısı yapmaz".
    // Aşağıdakilerin her biri o cümleyi tek satırda çürütür.
    final agKaliplari = <String, RegExp>{
      'Image.network': RegExp(r'\bImage\s*\.\s*network\s*\('),
      'NetworkImage': RegExp(r'\bNetworkImage\s*\('),
      'HttpClient': RegExp(r'\bHttpClient\s*\('),
      'WebSocket': RegExp(r'\bWebSocket\b'),
      'Socket.connect': RegExp(r'\bSocket\s*\.\s*connect\s*\('),
      'package:http': RegExp(r'''package:http/'''),
      'package:dio': RegExp(r'''package:dio/'''),
      // google_fonts, yazı tiplerini çalışma zamanında fonts.gstatic.com'dan
      // indirir. Görünür bir ağ çağrısı yazmaya gerek yok — paketi import
      // etmek yeterli. 9 Eylül'de kaldırıldı; geri gelirse burada yakalanır.
      'package:google_fonts': RegExp(r'''package:google_fonts/'''),
    };

    test('ağ çağrısı üreten hiçbir kalıp lib/ altında yok', () {
      final ihlaller = <String>[];

      for (final file in _libSources()) {
        for (final entry in agKaliplari.entries) {
          if (entry.value.hasMatch(file.source)) {
            ihlaller.add('${file.path} → ${entry.key}');
          }
        }
      }

      expect(
        ihlaller,
        isEmpty,
        reason: 'Ağ çağrısı üreten kalıplar bulundu:\n'
            '${ihlaller.join("\n")}\n'
            'Mahremiyet iddiası bir politika maddesi değil, mimari bir '
            'kısıttır. Bir avatar görselini indirmek bile onu bozar.',
      );
    });

    // ── NATIVE KATMAN (13 Eylül 2026) ─────────────────────────────────────
    // Bu grup yalnızca `lib/` altını tarıyordu. Android klavye servisine
    // metni şifresiz HTTP ile sunucuya POST eden üç yol eklendi, manifeste
    // INTERNET izni ve düz metin trafiği geri girdi — ve bu test yeşil kaldı.
    // Manifestin kendi yorumu "bu dosyada hiçbir izin yok" demeye devam
    // ediyordu. Artık native kaynak ve üretim manifesti de okunur.
    test('Android native kaynaklarında ağ çağrısı yok', () {
      final dir = Directory('android/app/src/main');
      if (!dir.existsSync()) fail('android/app/src/main bulunamadı');

      final nativeKaliplari = <String, RegExp>{
        'java.net.URL': RegExp(r'\bjava\.net\.URL\b|\bURL\s*\('),
        'HttpURLConnection': RegExp(r'\bHttps?URLConnection\b'),
        'Socket': RegExp(r'\bSocket\s*\('),
        'OkHttp': RegExp(r'\bokhttp3?\b', caseSensitive: false),
        'Retrofit': RegExp(r'\bretrofit2?\b', caseSensitive: false),
        'Volley': RegExp(r'\bcom\.android\.volley\b'),
      };

      final ihlaller = <String>[];
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.kt') && !f.path.endsWith('.java')) continue;
        final source = f.readAsStringSync();
        for (final entry in nativeKaliplari.entries) {
          if (entry.value.hasMatch(source)) {
            ihlaller.add('${f.path.replaceAll(r'\', '/')} → ${entry.key}');
          }
        }
      }

      expect(ihlaller, isEmpty,
          reason: 'Native katmanda ağ çağrısı:\n${ihlaller.join("\n")}');
    });

    test('üretim manifesti hiçbir izin ve düz metin trafiği istemez', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml');
      if (!manifest.existsSync()) fail('AndroidManifest.xml bulunamadı');

      // Yorumlar çıkarılır: gerekçe yorumu izin adlarını ANLATIR.
      final source = manifest
          .readAsStringSync()
          .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

      final izinler = RegExp(r'<uses-permission[^>]*android:name="([^"]+)"')
          .allMatches(source)
          .map((m) => m.group(1))
          .toList();
      expect(izinler, isEmpty,
          reason: 'Üretim manifesti izin istiyor: $izinler. Kullanıcının '
              'Ayarlar\'dan doğrulayabileceği "internet izni yok" kanıtı '
              'bozulur. Geliştirme izni src/debug ve src/profile altındadır.');

      expect(source.contains('usesCleartextTraffic="true"'), isFalse,
          reason: 'Düz metin (HTTP) trafiğine izin verilmiş.');

      // docs/24 · madde 42: cihaz dışı yedek de bir veri çıkış yoludur.
      expect(source.contains('android:allowBackup="false"'), isTrue,
          reason: 'Uygulama verisi bulut yedeğine ve adb backup ile dışarı '
              'alınabilir hâle gelmiş.');
    });
  });

  group('Değişmez 3 · Devralınan mesajlaşma arayüzü geri gelmemiştir', () {
    // 24 Ağustos'ta silinen katman: sohbet, arama, kişiler, kimlik doğrulama.
    // Kabuğa 9 Eylül'de eklenen sosyal AKIŞ bu karara aykırı değildir —
    // akış katmana yüzey sağlar, mesajlaşma sağlamazdı.
    final yasakliDosyalar = RegExp(
      r'lib/presentation/(chat|call|contacts|auth)/',
      caseSensitive: false,
    );

    test('kapsam dışı ekran dizinleri yok', () {
      final ihlaller = _libSources()
          .where((f) => yasakliDosyalar.hasMatch(f.path))
          .map((f) => f.path)
          .toList();

      expect(ihlaller, isEmpty,
          reason: 'Kapsam dışı ekranlar geri eklenmiş: $ihlaller');
    });
  });
}
