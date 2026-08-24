// =============================================================================
// İkinci Etiketleyici İçin Kör Etiketleme Dosyası
// Dosya: packages/civility_core/bin/annotate_export.dart
//
// Kullanım:
//   dart run bin/annotate_export.dart                  → İP-20 kümesi
//   dart run bin/annotate_export.dart --kume=ip15      → İP-15 kümesi
//   dart run bin/annotate_export.dart --kume=hepsi     → dört kümenin tamamı
//   dart run bin/annotate_export.dart > etiketleme.csv
//
// ── NEDEN VAR ─────────────────────────────────────────────────────────────
// Projenin bütün metrikleri TEK ETİKETLEYİCİLİDİR ve bu, raporda beyan
// edilen en büyük yöntemsel sınırdır. Tek kişinin etiketlediği bir kümede
// ölçülen F1, o kişinin "saldırgan" tanımını ne kadar tutarlı uyguladığını
// gösterir — o tanımın PAYLAŞILAN bir tanım olduğunu göstermez.
//
// Hakemler arası uyum (Cohen's kappa) bu farkı ölçer. Ölçebilmek için
// ikinci bir insanın aynı cümleleri, BİRİNCİ ETİKETLERİ GÖRMEDEN
// etiketlemesi gerekir. Bu araç o dosyayı üretir.
//
// ── KÖRLÜK NASIL KORUNUR ──────────────────────────────────────────────────
//   1. `shouldFlag` ve `expectedCategory` dosyaya YAZILMAZ.
//   2. `note` alanı da yazılmaz — notlar çoğu zaman doğru cevabı söyler
//      ("BİLİNEN SINIR: örtülü hakaret").
//   3. `group` yazılmaz — dilim adı ("Masum / tuzak") cevabı ele verir.
//   4. Sıra karıştırılır. Kaynak dosyalarda örnekler dilim dilim
//      gruplanmıştır; sıra korunsaydı etiketleyici blok blok "hepsi
//      saldırgan" diye işaretlerdi.
//   5. Karıştırma SABİT TOHUMLUDUR (seed: 20260824). Aynı komut aynı
//      dosyayı üretir; iki etiketleyici arasında satır kayması olamaz.
//
// Etiketleyici yalnızca `etiket` sütununu doldurur:
//   1 → bu metne müdahale edilmeli (uyarı/öneri gösterilmeli)
//   0 → bu metin olduğu gibi gönderilebilir
//
// Doldurulmuş dosya `bin/kappa.dart` ile okunur.
// =============================================================================

import 'dart:io';
import 'dart:math';

import 'package:civility_core/civility_core.dart';

/// Karıştırma tohumu. DEĞİŞTİRİLMEMELİDİR — değişirse daha önce dağıtılmış
/// etiketleme dosyalarıyla satır eşleşmesi bozulur.
const int _seed = 20260824;

void main(List<String> args) {
  final kume = _arg(args, '--kume') ?? 'ip20';

  final selected = <({String kaynak, GoldCase ornek})>[];
  void ekle(String kaynak, List<GoldCase> cases) {
    for (final c in cases) {
      selected.add((kaynak: kaynak, ornek: c));
    }
  }

  switch (kume) {
    case 'gelistirme':
      ekle('gelistirme', GoldDataset.cases);
    case 'ayrik':
      ekle('ayrik', HoldoutDataset.cases);
    case 'ip15':
      ekle('ip15', GeneralizationDataset.cases);
    case 'ip20':
      ekle('ip20', Generalization2Dataset.cases);
    case 'hepsi':
      ekle('gelistirme', GoldDataset.cases);
      ekle('ayrik', HoldoutDataset.cases);
      ekle('ip15', GeneralizationDataset.cases);
      ekle('ip20', Generalization2Dataset.cases);
    default:
      stderr.writeln('Bilinmeyen küme: $kume');
      stderr.writeln('Seçenekler: gelistirme | ayrik | ip15 | ip20 | hepsi');
      exitCode = 2;
      return;
  }

  // Kimlik, karıştırmadan ÖNCE ve kaynak sıraya göre verilir; böylece
  // `kappa.dart` doldurulmuş dosyayı ilk etiketlerle eşleştirebilir.
  final rows = <({String id, String metin})>[];
  final sayaclar = <String, int>{};
  for (final item in selected) {
    final n = (sayaclar[item.kaynak] ?? 0) + 1;
    sayaclar[item.kaynak] = n;
    rows.add((
      id: '${item.kaynak}-${n.toString().padLeft(3, '0')}',
      metin: item.ornek.text,
    ));
  }

  rows.shuffle(Random(_seed));

  final out = StringBuffer()
    ..writeln('# Kör etiketleme dosyası — küme: $kume · ${rows.length} örnek')
    ..writeln('# etiket sütununu doldurun: 1 = müdahale edilmeli, '
        '0 = olduğu gibi gönderilebilir')
    ..writeln('# Boş bırakılan satırlar kappa hesabının dışında kalır.')
    ..writeln('id,metin,etiket');

  for (final row in rows) {
    out.writeln('${row.id},${_csv(row.metin)},');
  }

  stdout.write(out);
}

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }
  return null;
}

/// CSV alanı kaçışı. Metinlerde virgül ve çift tırnak geçebiliyor
/// ('bana "kaltak" dedi, çok kırıldım') — kaçış olmadan sütunlar kayar.
String _csv(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
