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
    // explore_screen.dart    — arama kutusu. Yazdığı şey yayımlanmaz,
    //   kimseye ulaşmaz ve bir başkasına zarar veremez; müdahale etmek
    //   kullanıcıyı sebepsiz kısıtlamak olurdu.
    const izinliDosyalar = <String>{
      'lib/presentation/compose/civility_composer.dart',
      'lib/presentation/explore/explore_screen.dart',
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
