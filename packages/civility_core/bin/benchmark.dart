// =============================================================================
// Gecikme Ölçümü — çözümleme süresi bütçesi
// Dosya: packages/civility_core/bin/benchmark.dart
//
// Kullanım:
//   dart compile exe bin/benchmark.dart -o benchmark.exe && ./benchmark.exe
//   dart run bin/benchmark.dart            (JIT — sayı 3-5 kat yüksek çıkar)
//
// ── NEDEN AYRI BİR ARAÇ ───────────────────────────────────────────────────
// Rapor §3.1, çözümlemenin 87–193 µs sürdüğünü ve 16 ms'lik kare bütçesinin
// %1,2'sini geçmediğini iddia ediyor. Bu iddia, motorun O GÜNKÜ hâli için
// ölçülmüştü. O günden bu yana:
//
//   • kimlik söz varlığı 35 → 94 terime çıktı (İP-17)
//   • örüntü kataloğuna 30'dan fazla yeni kalıp eklendi (İP-19, İP-21)
//
// Kimlik yuvası `(?:t1|t2|…|t94)` biçiminde ON ÜÇ ayrı örüntünün içine
// gömülüdür ve her biri `_gap(3)` gibi geri izleme (backtracking) üretebilen
// bir boşlukla birleşir. Yani söz varlığını üç katına çıkarmak, en kötü
// durumda çözümleme maliyetini de üç katına çıkarabilir.
//
// Bir gecikme iddiası, motor büyüdükçe yeniden ölçülmezse bayatlar. Bu araç
// ölçümü tek komuta indirir.
//
// ── NEDEN AOT ─────────────────────────────────────────────────────────────
// JIT ölçümü ürünü temsil etmez: uygulama AOT derlenmiş ikili olarak dağıtılır.
// JIT sayıları ısınma ve yorumlayıcı yükü taşır ve 3–5 kat yüksek çıkar.
// Rapor bu farkı §3.1'de beyan eder; araç da hangi modda çalıştığını yazar.
//
// ── NEDEN YÜZDELİK ────────────────────────────────────────────────────────
// Ortalama, kullanıcının hissettiği şey değildir. Kullanıcı en yavaş tuş
// vuruşunu hisseder. Bu yüzden p50/p95/p99 ve en kötü durum ayrı raporlanır;
// bütçe denetimi p99 üzerinden yapılır.
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';

/// 60 FPS kare bütçesi. Gecikmeli tetikleme olmadığı için tek bir
/// çözümlemenin bunun altında kalması gerekir.
const int _kareButcesiUs = 16000;

void main(List<String> args) {
  final iterations =
      int.tryParse(_arg(args, '--tekrar') ?? '') ?? 2000;

  final engine = LexicalTurkishClassifier();

  // Temsilî girdi kümesi. Kasıtlı olarak DENGELİ değil, GERÇEKÇİ:
  // sıradan mesajlar çoğunluktadır, çünkü kullanıcı çoğu zaman saldırgan
  // bir şey yazmaz. En pahalı durumlar (uzun metin, çok kimlik terimi,
  // gönderge zinciri) ayrıca ölçülür.
  const senaryolar = <(String, String)>[
    ('Kısa · temiz', 'yarın buluşalım mı'),
    ('Orta · temiz', 'toplantı notlarını paylaşır mısın, bugün bakacağım'),
    ('Kısa · sözlük eşleşmesi', 'aptalsın'),
    ('Orta · örüntü eşleşmesi', 'senin gibilerle tartışmak zaman kaybı'),
    ('Kimlik yuvası · temiz', 'Suriyeli komşumuz çok yardımsever bir insan'),
    ('Kimlik yuvası · eşleşme', 'Bütün Suriyeliler hırsızdır'),
    ('Gönderge zinciri', 'Suriyeliler her yeri doldurdu. '
        'Bunların soyunu kurutmak lazım'),
    ('Uzun · karışık', 'dün akşam mahallede uzun uzun konuştuk, herkes '
        'kendi derdini anlattı ve sonunda ortak bir karara vardık ama '
        'bazıları hâlâ ikna olmuş değil, yarın tekrar toplanacağız'),
    ('En kötü durum · çok kimlik', 'Kürtler Ermeniler Aleviler Suriyeliler '
        'Romanlar Yahudiler eşcinseller mülteciler engelliler yaşlılar '
        'hepsi burada yaşıyor ve hepsi bu ülkenin vatandaşı'),
  ];

  // ── Isınma ───────────────────────────────────────────────────────────────
  // İlk çağrı sözlüğü kurar ve düzenli ifadeleri derler. Ölçüme girerse
  // sonuç kurulum maliyetini taşır.
  for (var i = 0; i < 200; i++) {
    for (final (_, metin) in senaryolar) {
      engine.analyze(metin);
    }
  }

  final rapor = StringBuffer()
    ..writeln('═' * 78)
    ..writeln('GECİKME ÖLÇÜMÜ — çözümleme süresi')
    ..writeln('═' * 78)
    ..writeln()
    ..writeln('  Derleme modu : ${_aotMu() ? "AOT (ürün)" : "JIT (geliştirme)"}')
    ..writeln('  Tekrar       : $iterations / senaryo')
    ..writeln('  Kare bütçesi : $_kareButcesiUs µs (60 FPS)')
    ..writeln();

  final tumOlcumler = <double>[];
  var enKotuSenaryo = '';
  var enKotuP99 = 0.0;

  rapor
    ..writeln('  ${"Senaryo".padRight(30)}'
        '${"p50".padLeft(8)}${"p95".padLeft(8)}'
        '${"p99".padLeft(8)}${"en kötü".padLeft(9)}')
    ..writeln('  ${"-" * 30}${"-" * 33}');

  for (final (ad, metin) in senaryolar) {
    final olcumler = <double>[];
    for (var i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      engine.analyze(metin);
      sw.stop();
      olcumler.add(sw.elapsedMicroseconds.toDouble());
    }
    olcumler.sort();
    tumOlcumler.addAll(olcumler);

    final p99 = _yuzdelik(olcumler, 0.99);
    if (p99 > enKotuP99) {
      enKotuP99 = p99;
      enKotuSenaryo = ad;
    }

    rapor.writeln('  ${ad.padRight(30)}'
        '${_us(_yuzdelik(olcumler, 0.50))}'
        '${_us(_yuzdelik(olcumler, 0.95))}'
        '${_us(p99)}'
        '${_us(olcumler.last, 9)}');
  }

  tumOlcumler.sort();
  final genelP99 = _yuzdelik(tumOlcumler, 0.99);
  final butceOrani = genelP99 / _kareButcesiUs * 100;

  rapor
    ..writeln()
    ..writeln('═' * 78)
    ..writeln('ÖZET')
    ..writeln('═' * 78)
    ..writeln('  Toplam ölçüm  : ${tumOlcumler.length}')
    ..writeln('  Genel p50     : ${_yuzdelik(tumOlcumler, 0.50)
        .toStringAsFixed(1)} µs')
    ..writeln('  Genel p95     : ${_yuzdelik(tumOlcumler, 0.95)
        .toStringAsFixed(1)} µs')
    ..writeln('  Genel p99     : ${genelP99.toStringAsFixed(1)} µs')
    ..writeln('  En pahalı     : $enKotuSenaryo '
        '(p99 ${enKotuP99.toStringAsFixed(1)} µs)')
    ..writeln()
    ..writeln('  Kare bütçesinin p99\'da kullanılan oranı: '
        '%${butceOrani.toStringAsFixed(2)}')
    ..writeln();

  if (genelP99 < _kareButcesiUs) {
    rapor.writeln('  ✓ Bütçe korunuyor: p99 kare bütçesinin altında.');
  } else {
    rapor
      ..writeln('  ✗ BÜTÇE AŞILDI. Gecikmeli tetikleme (debounce) olmadan')
      ..writeln('    her tuş vuruşunda çözümleme yapmak kare atlatır.');
  }

  if (!_aotMu()) {
    rapor
      ..writeln()
      ..writeln('  ⓘ  Bu bir JIT ölçümüdür ve ÜRÜNÜ TEMSİL ETMEZ.')
      ..writeln('     Rapora girecek sayı için AOT derleyin:')
      ..writeln('       dart compile exe bin/benchmark.dart -o benchmark.exe');
  }

  stdout.write(rapor);
  exitCode = genelP99 < _kareButcesiUs ? 0 : 1;
}

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }
  return null;
}

/// AOT derlenmiş ikilide `Platform.script` bir `.dart` dosyasına işaret
/// etmez. Kesin bir API olmadığı için ölçüt budur.
bool _aotMu() => !Platform.script.path.endsWith('.dart');

double _yuzdelik(List<double> sirali, double q) {
  if (sirali.isEmpty) return 0;
  final index = ((sirali.length - 1) * q).round();
  return sirali[index];
}

String _us(double v, [int width = 8]) =>
    '${v.toStringAsFixed(0)} µs'.padLeft(width);
