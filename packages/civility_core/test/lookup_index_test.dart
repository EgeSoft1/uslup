// =============================================================================
// Sözlük araması · ilk harf kovaları eşdeğerlik testi
// Dosya: packages/civility_core/test/lookup_index_test.dart
//
// ── NE KANITLIYOR ─────────────────────────────────────────────────────────
// `LexicalTurkishClassifier`, sözlük adaylarını kökün ilk harfine göre
// kovalar (`fastLookup`). Bu yalnızca HIZ içindir: 4.800 karakterlik bir
// metinde sözlük yolunu 64 ms'den 9 ms'ye indirdi.
//
// Kovalar yanlış kurulursa hata SESSİZDİR — bir kök yanlış kovaya düşer,
// o kökün bütün çekimleri kaçar ve kaçan örnek kümede yoksa hiçbir metrik
// değişmez. Bu dosya kovalı ve kovasız motoru karşılaştırır; tek bir fark
// (risk, skor, bulgu, konum, bağlam gerekçesi) testi kırar.
//
// ── NEDEN ÜRETİLMİŞ VARYANTLAR ────────────────────────────────────────────
// Etiketli kümeler her kökün her çekimini içermez. Bu yüzden sözlüğün
// HER girdisi ek, yumuşama, ters yazım, bölme ve maskeleme varyantlarıyla
// ayrıca sınanır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

String _parmakIzi(CivilityAnalysis a) {
  final b = StringBuffer('${a.risk.name}|${a.toxicity.toStringAsFixed(12)}');
  for (final f in a.findings) {
    b.write(' || ${f.term}@${f.start}-${f.end}'
        ':${f.adjustedSeverity.toStringAsFixed(12)}'
        ':${f.source.name}:${f.category.name}:${f.context.reason}');
  }
  return b.toString();
}

void main() {
  final kovali = LexicalTurkishClassifier();
  final kovasiz = LexicalTurkishClassifier(fastLookup: false);

  void karsilastir(Iterable<String> metinler) {
    final farklar = <String>[];
    for (final t in metinler) {
      final a = _parmakIzi(kovali.analyze(t));
      final b = _parmakIzi(kovasiz.analyze(t));
      if (a != b) farklar.add('"$t"\n    kovalı : $a\n    kovasız: $b');
    }
    expect(farklar, isEmpty,
        reason: 'İlk harf kovası sonucu değiştirdi — bir hızlandırma '
            'davranışı değiştirmemelidir:\n${farklar.take(10).join("\n")}');
  }

  test('etiketli kümelerin tamamı birebir aynı', () {
    karsilastir([
      ...GoldDataset.cases,
      ...HoldoutDataset.cases,
      ...GeneralizationDataset.cases,
      ...Generalization2Dataset.cases,
      ...Generalization3Dataset.cases,
      ...Generalization4Dataset.cases,
      ...Generalization5Dataset.cases,
    ].map((c) => c.text));
  });

  test('her sözlük girdisinin çekim, yumuşama ve kaçış varyantları aynı', () {
    const ekler = [
      '', 'sın', 'sin', 'lar', 'ler', 'ım', 'ına', 'dır', 'cık', 'ları',
      'ya', 'e', 'ı', 'ci', 'lik', 'siz', 'ten', 'ğım', 'dı', 'iyor',
      'ecek', 'mek', 'zeme', 'aç',
    ];
    String ters(String s) => s.split('').reversed.join();

    final metinler = <String>[];
    for (final e in ToxicityLexicon.entries) {
      final t = e.term;
      for (final ek in ekler) {
        metinler.add('sen $t$ek');
      }
      metinler
        ..add('sen ${ters(t)}sın')
        ..add(t.split('').join(' '))
        ..add('Bana "$t" dedi')
        ..add(t.replaceAll('k', 'q').replaceAll('a', '4'));
    }
    for (final m in ToxicityLexicon.maskedPrefixes) {
      for (final ek in ekler) {
        metinler.add('$m$ek');
      }
    }
    karsilastir(metinler);
  });

  test('büyük harf, aksan ve boş girdi sınırları aynı', () {
    karsilastir(const [
      '', ' ', 'İ', 'ı', 'Şerefsiz', 'ŞEREFSİZSİN', 'çüş', 'ğ', '4',
      '\$', 'Malzeme listesi', 'itibarını korudu', 'Şikayet ettim',
      'salağım', 'salak', 'sen bi salaksın', 'a m k', 'orospu çocuğu',
    ]);
  });
}
