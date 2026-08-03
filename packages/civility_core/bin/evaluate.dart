// =============================================================================
// Değerlendirme Aracı
// Dosya: packages/civility_core/bin/evaluate.dart
//
// Kullanım:
//   dart run bin/evaluate.dart                 → geliştirme kümesi
//   dart run bin/evaluate.dart --ayrik         → ayrık küme (genelleme)
//   dart run bin/evaluate.dart --karsilastir   → katman katkısı (A/B)
//   dart run bin/evaluate.dart --hepsi         → üçü birden
//
// Çıktı doğrudan teknik rapora yapıştırılabilir.
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';

void main(List<String> args) {
  const evaluator = Evaluator();

  final wantsAll = args.contains('--hepsi');
  final wantsHoldout = wantsAll || args.contains('--ayrik');
  final wantsCompare = wantsAll || args.contains('--karsilastir');
  final wantsDev = wantsAll || (!wantsHoldout && !wantsCompare);

  if (wantsDev) {
    stdout.write(
      evaluator.run(LexicalTurkishClassifier(), GoldDataset.cases).format(
            title: 'GELİŞTİRME KÜMESİ — ${GoldDataset.cases.length} örnek',
          ),
    );
    stdout.writeln();
  }

  if (wantsHoldout) {
    stdout
      ..write(
        evaluator.run(LexicalTurkishClassifier(), HoldoutDataset.cases).format(
              title: 'AYRIK KÜME — ${HoldoutDataset.cases.length} örnek',
            ),
      )
      ..writeln('  ⚠  UYARI: Bu küme artık gerçek anlamda AYRIK DEĞİLDİR.')
      ..writeln('     İlk (ve tek geçerli) genelleme ölçümü: F1 = %84,2.')
      ..writeln('     Ayrıntı: docs/04_MODEL_DEGERLENDIRME.md §5')
      ..writeln();
  }

  if (wantsCompare) {
    // Katmanların katkısını izole et. Tek bir toplam skor, hangi katmanın
    // ne kazandırdığını gizler; rapor bu ayrımı göstermek zorundadır.
    final lexiconOnly = evaluator.run(
      LexicalTurkishClassifier(enableImplicitPatterns: false),
      GoldDataset.cases,
    );
    final full = evaluator.run(LexicalTurkishClassifier(), GoldDataset.cases);

    stdout
      ..write(lexiconOnly.format(title: 'A) YALNIZCA SÖZLÜK KATMANI'))
      ..writeln()
      ..write(full.format(title: 'B) SÖZLÜK + ÖRTÜK SALDIRI KATMANI'))
      ..writeln()
      ..write(ReportComparison(
        before: lexiconOnly,
        after: full,
        beforeLabel: 'sözlük',
        afterLabel: '+örüntü',
      ).format());
  }
}
