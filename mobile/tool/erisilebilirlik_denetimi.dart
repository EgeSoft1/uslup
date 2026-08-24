// =============================================================================
// İP-16 · Erişilebilirlik Denetimi — WCAG 2.1 kontrast ölçümü
// Dosya: mobile/tool/erisilebilirlik_denetimi.dart
//
// Kullanım (Flutter GEREKTİRMEZ — saf Dart):
//   dart run tool/erisilebilirlik_denetimi.dart
//   dart run tool/erisilebilirlik_denetimi.dart --sadece-hatalar
//
// ── NEDEN BU ARAÇ VAR ─────────────────────────────────────────────────────
// Teknik rapor §3.3, arayüzün WCAG 2.1 başarı ölçütlerini karşıladığını
// iddia ediyor. Bir iddia, ölçülmedikçe iddiadır. Bu araç, iddianın
// sayısal karşılığını üretir ve jürinin tek komutla yeniden üretmesini
// sağlar.
//
// ── NEDEN PALETİ AYRIŞTIRIYOR ─────────────────────────────────────────────
// Renkler `lib/core/theme/app_palette.dart` içindedir ve `dart:ui`
// bağımlıdır; saf Dart'tan import edilemez. Araç bu yüzden dosyayı
// KAYNAK OLARAK okur ve onaltılık değerleri ayrıştırır. Bunun bir yan
// faydası var: palet değişirse denetim kendiliğinden yeni değerlerle
// çalışır, elle güncellenen bir tablo bayatlayamaz.
//
// ── ÖLÇÜT ─────────────────────────────────────────────────────────────────
// WCAG 2.1 bağıl parlaklık (relative luminance) ve kontrast oranı:
//
//   L = 0.2126·R + 0.7152·G + 0.0722·B     (doğrusallaştırılmış kanallar)
//   C = (L_açık + 0.05) / (L_koyu + 0.05)
//
// Eşikler:
//   1.4.3 Kontrast (Minimum)  AA   → normal metin 4.5:1 · büyük metin 3.0:1
//   1.4.6 Kontrast (Gelişmiş) AAA  → normal metin 7.0:1 · büyük metin 4.5:1
//   1.4.11 Metin Dışı Kontrast AA  → arayüz bileşeni / grafik  3.0:1
//
// Büyük metin: ≥18,66 px kalın ya da ≥24 px normal.
// =============================================================================

import 'dart:io';

void main(List<String> args) {
  final sadeceHatalar = args.contains('--sadece-hatalar');

  final kaynak = File('lib/core/theme/app_palette.dart');
  if (!kaynak.existsSync()) {
    stderr.writeln('Palet dosyası bulunamadı. Aracı `mobile/` dizininden '
        'çalıştırın:  dart run tool/erisilebilirlik_denetimi.dart');
    exitCode = 2;
    return;
  }

  final metin = kaynak.readAsStringSync();
  final sabitler = _sabitleriAyristir(metin);
  final acik = _temaAyristir(metin, 'light', sabitler);
  final koyu = _temaAyristir(metin, 'dark', sabitler);

  if (acik.isEmpty || koyu.isEmpty) {
    stderr.writeln('Tema tanımları ayrıştırılamadı — palet dosyasının '
        'yapısı değişmiş olabilir.');
    exitCode = 2;
    return;
  }

  final rapor = StringBuffer()
    ..writeln('═' * 78)
    ..writeln('İP-16 · ERİŞİLEBİLİRLİK DENETİMİ — WCAG 2.1 kontrast oranları')
    ..writeln('═' * 78)
    ..writeln()
    ..writeln('Kaynak: lib/core/theme/app_palette.dart')
    ..writeln('Ayrıştırılan sabit: ${sabitler.length} · '
        'açık tema alanı: ${acik.length} · koyu tema alanı: ${koyu.length}')
    ..writeln();

  var toplam = 0;
  var basarisiz = 0;

  for (final tema in [('AÇIK TEMA', acik), ('KOYU TEMA', koyu)]) {
    final ad = tema.$1;
    final p = tema.$2;

    // Denetlenecek ön plan / arka plan çiftleri ve hangi ölçüte tabi
    // oldukları. Kural: metin renkleri 1.4.3, arayüz bileşenleri 1.4.11.
    final ciftler = <_Cift>[
      _Cift('Ana metin / zemin', p['textPrimary'], p['background'], _Tur.metin),
      _Cift('Ana metin / yüzey', p['textPrimary'], p['surface'], _Tur.metin),
      _Cift('İkincil metin / zemin', p['textSecondary'], p['background'],
          _Tur.metin),
      _Cift('İkincil metin / yüzey', p['textSecondary'], p['surface'],
          _Tur.metin),
      _Cift('Üçüncül metin / yüzey', p['textTertiary'], p['surface'],
          _Tur.buyukMetin),
      _Cift('Marka üstü metin', p['brandOn'], p['brand'], _Tur.metin),
      _Cift('Marka mürekkebi / yüzey', p['brandInk'], p['surface'],
          _Tur.buyukMetin),
      _Cift('Marka / zemin (bileşen)', p['brand'], p['background'],
          _Tur.bilesen),
      _Cift('Başarı / yüzey (bileşen)', p['success'], p['surface'],
          _Tur.bilesen),
      _Cift('Uyarı / yüzey (bileşen)', p['warning'], p['surface'],
          _Tur.bilesen),
      _Cift('Tehlike / yüzey (bileşen)', p['danger'], p['surface'],
          _Tur.bilesen),
      _Cift('Bilgi / yüzey (bileşen)', p['info'], p['surface'], _Tur.bilesen),
      // WCAG 1.4.11 yalnızca bir bileşeni TANIMAK İÇİN GEREKLİ görsel
      // bilgiyi kapsar. `border` dekoratif ayraçtır (kart çizgisi, liste
      // ayracı) ve ölçütün dışındadır; `borderStrong` metin girdisinin
      // sınırıdır ve ölçüte tabidir. Ayrım İP-16'da yapıldı.
      _Cift('Etkileşimli kenarlık / yüzey', p['borderStrong'], p['surface'],
          _Tur.bilesen),
      _Cift('Gelen baloncuk metni', p['bubbleIncomingText'],
          p['bubbleIncoming'], _Tur.metin),
      _Cift('Giden baloncuk metni', p['bubbleOutgoingText'],
          p['bubbleOutgoing'], _Tur.metin),
    ];

    rapor
      ..writeln('─' * 78)
      ..writeln(ad)
      ..writeln('─' * 78)
      ..writeln('  ${"Çift".padRight(32)}${"Oran".padLeft(7)}   '
          '${"Gerekli".padLeft(7)}   Ölçüt              Sonuç');

    for (final c in ciftler) {
      if (c.on == null || c.arka == null) continue;
      toplam++;

      final oran = _kontrast(c.on!, c.arka!);
      final gerekli = c.tur.esik;
      final gecti = oran >= gerekli;
      if (!gecti) basarisiz++;
      if (sadeceHatalar && gecti) continue;

      final aaa = c.tur == _Tur.metin
          ? (oran >= 7.0 ? ' · AAA' : '')
          : (c.tur == _Tur.buyukMetin && oran >= 4.5 ? ' · AAA' : '');

      rapor.writeln('  ${c.ad.padRight(32)}'
          '${oran.toStringAsFixed(2).padLeft(6)}:1   '
          '${gerekli.toStringAsFixed(1).padLeft(5)}:1   '
          '${c.tur.olcut.padRight(18)} '
          '${gecti ? "GEÇTİ$aaa" : "KALDI"}');
    }
    rapor.writeln();
  }

  rapor
    ..writeln('═' * 78)
    ..writeln('ÖZET')
    ..writeln('═' * 78)
    ..writeln('  Denetlenen çift : $toplam')
    ..writeln('  Eşiği geçen     : ${toplam - basarisiz}')
    ..writeln('  Eşiğin altında  : $basarisiz')
    ..writeln();

  if (basarisiz == 0) {
    rapor.writeln('  Bütün çiftler ilgili WCAG 2.1 AA eşiğini karşılıyor.');
  } else {
    rapor
      ..writeln('  ⚠ $basarisiz çift eşiğin altında. Rapor §3.3\'te WCAG')
      ..writeln('    uyumu iddia edilmeden önce bunlar düzeltilmelidir.');
  }

  rapor
    ..writeln()
    ..writeln('  NOT: Kontrast, erişilebilirliğin ÖLÇÜLEBİLİR parçasıdır.')
    ..writeln('  Ekran okuyucu etiketleri, odak sırası ve dokunma hedefi')
    ..writeln('  boyutu bu araçla ölçülmez; onlar cihaz üstü denetim ister.')
    ..writeln('  Kapsam beyanı: docs/13_ERISILEBILIRLIK_DENETIMI.md');

  stdout.write(rapor);
  exitCode = basarisiz == 0 ? 0 : 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ölçüt türleri

enum _Tur {
  metin(4.5, '1.4.3 AA metin'),
  buyukMetin(3.0, '1.4.3 AA büyük'),
  bilesen(3.0, '1.4.11 AA bileşen');

  const _Tur(this.esik, this.olcut);
  final double esik;
  final String olcut;
}

class _Cift {
  const _Cift(this.ad, this.on, this.arka, this.tur);
  final String ad;
  final int? on;
  final int? arka;
  final _Tur tur;
}

// ─────────────────────────────────────────────────────────────────────────────
// Palet ayrıştırma

/// `static const Color brand = Color(0xFFC8102E);` satırlarını toplar.
Map<String, int> _sabitleriAyristir(String kaynak) {
  final re = RegExp(
      r'static\s+const\s+Color\s+(\w+)\s*=\s*Color\(0x([0-9A-Fa-f]{8})\)');
  final out = <String, int>{};
  for (final m in re.allMatches(kaynak)) {
    out[m.group(1)!] = int.parse(m.group(2)!, radix: 16);
  }
  return out;
}

/// `static const AppPalette light = AppPalette( ... );` gövdesindeki
/// `alan: AppColors.x` ve `alan: Color(0xFF...)` atamalarını çözer.
Map<String, int> _temaAyristir(
    String kaynak, String ad, Map<String, int> sabitler) {
  final basla = kaynak.indexOf('static const AppPalette $ad = AppPalette(');
  if (basla < 0) return {};
  final bit = kaynak.indexOf(');', basla);
  if (bit < 0) return {};

  final govde = kaynak.substring(basla, bit);
  final out = <String, int>{};

  for (final m in RegExp(r'(\w+):\s*AppColors\.(\w+)').allMatches(govde)) {
    final deger = sabitler[m.group(2)!];
    if (deger != null) out[m.group(1)!] = deger;
  }
  for (final m
      in RegExp(r'(\w+):\s*Color\(0x([0-9A-Fa-f]{8})\)').allMatches(govde)) {
    out[m.group(1)!] = int.parse(m.group(2)!, radix: 16);
  }
  return out;
}

// ─────────────────────────────────────────────────────────────────────────────
// WCAG 2.1 hesabı

double _kanal(int deger) {
  final s = deger / 255.0;
  // WCAG 2.1, sRGB'yi doğrusallaştırırken bu eşiği kullanır.
  return s <= 0.03928 ? s / 12.92 : _pow((s + 0.055) / 1.055, 2.4);
}

double _parlaklik(int argb) {
  final r = _kanal((argb >> 16) & 0xFF);
  final g = _kanal((argb >> 8) & 0xFF);
  final b = _kanal(argb & 0xFF);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _kontrast(int on, int arka) {
  final l1 = _parlaklik(on);
  final l2 = _parlaklik(arka);
  final acik = l1 > l2 ? l1 : l2;
  final koyu = l1 > l2 ? l2 : l1;
  return (acik + 0.05) / (koyu + 0.05);
}

/// `dart:math` yerine yerel üs — araç bağımlılıksız kalsın diye.
double _pow(double taban, double us) {
  // exp(us * ln(taban)) — çift duyarlıkla WCAG için fazlasıyla yeterli.
  return _exp(us * _ln(taban));
}

double _ln(double x) {
  // Doğal logaritma, atanh serisiyle: ln(x) = 2·atanh((x−1)/(x+1))
  if (x <= 0) return double.negativeInfinity;
  var k = 0;
  var v = x;
  while (v > 1.5) {
    v /= 2;
    k++;
  }
  while (v < 0.75) {
    v *= 2;
    k--;
  }
  final z = (v - 1) / (v + 1);
  final z2 = z * z;
  var terim = z;
  var toplam = 0.0;
  for (var n = 0; n < 24; n++) {
    toplam += terim / (2 * n + 1);
    terim *= z2;
  }
  return 2 * toplam + k * 0.6931471805599453;
}

double _exp(double x) {
  var toplam = 1.0;
  var terim = 1.0;
  for (var n = 1; n < 40; n++) {
    terim *= x / n;
    toplam += terim;
  }
  return toplam;
}
