// =============================================================================
// Hakemler Arası Uyum — Cohen's Kappa
// Dosya: packages/civility_core/bin/kappa.dart
//
// Kullanım:
//   dart run bin/kappa.dart etiketleme_dolu.csv
//
// Girdi: `bin/annotate_export.dart` ile üretilmiş, `etiket` sütunu ikinci
// etiketleyici tarafından doldurulmuş CSV.
//
// ── NEDEN HAM UYUŞMA ORANI YETMEZ ─────────────────────────────────────────
// İki etiketleyici %90 örtüşebilir ve bu yine de bilgisiz bir sayı olabilir:
// küme %90 masum örnekten oluşuyorsa, her şeye "masum" diyen bir etiketleyici
// de %90 tutturur. Cohen's kappa, RASTLANTIYLA beklenen uyuşmayı düşer:
//
//   κ = (Po − Pe) / (1 − Pe)
//
//   Po = gözlenen uyuşma oranı
//   Pe = etiketleyicilerin marjinal dağılımlarından beklenen uyuşma
//
// Yorum ölçeği (Landis & Koch 1977):
//   < 0,00  uyuşmazlık        0,41–0,60  orta
//   0,00–0,20  önemsiz        0,61–0,80  önemli
//   0,21–0,40  zayıf          0,81–1,00  neredeyse tam
//
// ── SONUÇ NASIL RAPORLANIR ────────────────────────────────────────────────
// κ, motorun başarısı DEĞİLDİR; VERİ KÜMESİNİN güvenilirliğidir. Düşük
// çıkarsa raporlanacak şey "motor kötü" değil, "bu kümedeki F1 sayıları
// göründükleri kadar kesin değil"dir. Uyuşmazlık listesi de basılır:
// tartışmalı örnekler genellikle kümedeki en öğretici örneklerdir.
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Kullanım: dart run bin/kappa.dart <doldurulmus.csv>');
    exitCode = 2;
    return;
  }

  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('Dosya bulunamadı: ${args.first}');
    exitCode = 2;
    return;
  }

  // ── 1. Birinci etiketleyicinin (kümelerin kendi) etiketleri ──────────────
  final birinci = <String, GoldCase>{};
  void indeksle(String kaynak, List<GoldCase> cases) {
    for (var i = 0; i < cases.length; i++) {
      birinci['$kaynak-${(i + 1).toString().padLeft(3, '0')}'] = cases[i];
    }
  }

  indeksle('gelistirme', GoldDataset.cases);
  indeksle('ayrik', HoldoutDataset.cases);
  indeksle('ip15', GeneralizationDataset.cases);
  indeksle('ip20', Generalization2Dataset.cases);

  // ── 2. İkinci etiketleyicinin dosyası ────────────────────────────────────
  final ikinci = <String, bool>{};
  final bilinmeyen = <String>[];
  var bosBirakilan = 0;

  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    if (trimmed.startsWith('id,')) continue;

    final cells = _parseCsvLine(trimmed);
    if (cells.length < 3) continue;

    final id = cells[0].trim();
    final label = cells[2].trim();

    if (label.isEmpty) {
      bosBirakilan++;
      continue;
    }
    if (label != '0' && label != '1') {
      stderr.writeln('Geçersiz etiket "$label" (satır kimliği: $id) — atlandı.');
      continue;
    }
    if (!birinci.containsKey(id)) {
      bilinmeyen.add(id);
      continue;
    }
    ikinci[id] = label == '1';
  }

  if (ikinci.isEmpty) {
    stderr.writeln('Doldurulmuş etiket bulunamadı.');
    exitCode = 1;
    return;
  }

  // ── 3. Karışıklık matrisi ────────────────────────────────────────────────
  // a: ikisi de "müdahale"   b: birinci müdahale, ikinci temiz
  // c: birinci temiz, ikinci müdahale   d: ikisi de temiz
  var a = 0, b = 0, c = 0, d = 0;
  final uyusmazliklar = <({String id, String metin, bool ilk, bool ikinciL})>[];

  for (final entry in ikinci.entries) {
    final gold = birinci[entry.key]!;
    final ilk = gold.shouldFlag;
    final son = entry.value;

    if (ilk && son) {
      a++;
    } else if (ilk && !son) {
      b++;
      uyusmazliklar
          .add((id: entry.key, metin: gold.text, ilk: ilk, ikinciL: son));
    } else if (!ilk && son) {
      c++;
      uyusmazliklar
          .add((id: entry.key, metin: gold.text, ilk: ilk, ikinciL: son));
    } else {
      d++;
    }
  }

  final n = a + b + c + d;
  final po = (a + d) / n;

  // Marjinaller — rastlantısal uyuşma buradan hesaplanır.
  final ilkMudahale = (a + b) / n;
  final ilkTemiz = (c + d) / n;
  final ikinciMudahale = (a + c) / n;
  final ikinciTemiz = (b + d) / n;
  final pe = ilkMudahale * ikinciMudahale + ilkTemiz * ikinciTemiz;

  final kappa = pe == 1.0 ? 1.0 : (po - pe) / (1 - pe);

  // ── 4. Rapor ─────────────────────────────────────────────────────────────
  final o = StringBuffer()
    ..writeln('═' * 78)
    ..writeln('HAKEMLER ARASI UYUM — Cohen\'s Kappa')
    ..writeln('═' * 78)
    ..writeln()
    ..writeln('  Eşleşen örnek       : $n')
    ..writeln('  Boş bırakılan       : $bosBirakilan')
    ..writeln('  Tanınmayan kimlik   : ${bilinmeyen.length}')
    ..writeln()
    ..writeln('KARIŞIKLIK MATRİSİ')
    ..writeln('                     │ 2. etiketleyici: müdahale │ temiz')
    ..writeln('  ───────────────────┼───────────────────────────┼────────')
    ..writeln('  1. etiketleyici:')
    ..writeln('    müdahale         │  ${a.toString().padLeft(6)}'
        '                   │ ${b.toString().padLeft(6)}')
    ..writeln('    temiz            │  ${c.toString().padLeft(6)}'
        '                   │ ${d.toString().padLeft(6)}')
    ..writeln()
    ..writeln('  Gözlenen uyuşma  Po : ${_pct(po)}')
    ..writeln('  Beklenen uyuşma  Pe : ${_pct(pe)}')
    ..writeln('  Cohen\'s kappa    κ  : ${kappa.toStringAsFixed(3)}'
        '   (${_yorum(kappa)})')
    ..writeln();

  if (uyusmazliklar.isEmpty) {
    o.writeln('UYUŞMAZLIK YOK.');
  } else {
    o.writeln('UYUŞMAZLIKLAR (${uyusmazliklar.length}) — '
        'kümedeki en tartışmalı örnekler');
    for (final u in uyusmazliklar) {
      final yon = u.ilk ? '1:müdahale · 2:temiz' : '1:temiz · 2:müdahale';
      o
        ..writeln('  • [${u.id}] $yon')
        ..writeln('      "${u.metin}"');
    }
    o
      ..writeln()
      ..writeln('  Bu satırlar kümenin etiket kılavuzundaki boşlukları '
          'gösterir.')
      ..writeln('  Kılavuz güncellenmeden etiketler DEĞİŞTİRİLMEMELİDİR — '
          'aksi hâlde')
      ..writeln('  ölçüm, ikinci etiketleyiciye göre ayarlanmış olur.');
  }

  if (bilinmeyen.isNotEmpty) {
    o
      ..writeln()
      ..writeln('⚠ Tanınmayan kimlikler: ${bilinmeyen.take(10).join(", ")}'
          '${bilinmeyen.length > 10 ? " …" : ""}');
  }

  stdout.write(o);
}

String _pct(double v) => '${(v * 100).toStringAsFixed(1)} %';

String _yorum(double k) {
  if (k < 0) return 'uyuşmazlık';
  if (k <= 0.20) return 'önemsiz';
  if (k <= 0.40) return 'zayıf';
  if (k <= 0.60) return 'orta';
  if (k <= 0.80) return 'önemli';
  return 'neredeyse tam';
}

/// Tırnaklı alanları ("bana ""kaltak"" dedi, üzüldüm") doğru bölen
/// küçük CSV çözümleyicisi.
List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(ch);
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == ',') {
      cells.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  cells.add(buffer.toString());
  return cells;
}
