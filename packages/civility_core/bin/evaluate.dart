// =============================================================================
// Değerlendirme Aracı
// Dosya: packages/civility_core/bin/evaluate.dart
//
// Kullanım:
//   dart run bin/evaluate.dart                 → geliştirme kümesi
//   dart run bin/evaluate.dart --ayrik         → birinci ayrık küme (YANMIŞ)
//   dart run bin/evaluate.dart --genelleme     → İP-15 ikinci küme (YANMIŞ)
//   dart run bin/evaluate.dart --genelleme2    → İP-20 üçüncü küme (YANMIŞ)
//   dart run bin/evaluate.dart --genelleme3    → İP-22 dördüncü ayrık küme
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
  final wantsGeneralization = wantsAll || args.contains('--genelleme');
  final wantsGeneralization2 = wantsAll || args.contains('--genelleme2');
  final wantsGeneralization3 = wantsAll || args.contains('--genelleme3');
  final wantsDev = wantsAll ||
      (!wantsHoldout &&
          !wantsCompare &&
          !wantsGeneralization &&
          !wantsGeneralization2 &&
          !wantsGeneralization3);

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

  if (wantsGeneralization) {
    // İP-15 — İkinci ayrık küme. Bu kümeye BAKILARAK hiçbir örüntü veya
    // sözlük girdisi değiştirilmemiştir; küme, kendisinden önce donmuş bir
    // motoru ölçer. Ayrıntı: lib/src/eval/generalization_dataset.dart
    stdout
      ..write(
        evaluator
            .run(LexicalTurkishClassifier(), GeneralizationDataset.cases)
            .format(
              title: 'İP-15 · İKİNCİ AYRIK KÜME — '
                  '${GeneralizationDataset.cases.length} örnek',
            ),
      )
      ..writeln('  ⓘ  Bu küme TEK ETİKETLEYİCİLİDİR; hakemler arası uyum')
      ..writeln("     (Cohen's kappa) henüz ölçülmemiştir. İkinci")
      ..writeln('     etiketleyici altyapısı: bin/annotate_export.dart')
      ..writeln();
  }

  if (wantsGeneralization2) {
    // İP-20 — Üçüncü ayrık küme. İP-19 onarımı TAMAMLANDIKTAN SONRA yazıldı;
    // onarımın genelleşip genelleşmediğini ölçen tek geçerli sayı budur.
    stdout
      ..write(
        evaluator
            .run(LexicalTurkishClassifier(), Generalization2Dataset.cases)
            .format(
              title: 'İP-20 · ÜÇÜNCÜ AYRIK KÜME — '
                  '${Generalization2Dataset.cases.length} örnek',
            ),
      )
      ..writeln('  ⓘ  Onarım sonrası tek geçerli genelleme ölçümü budur.')
      ..writeln('     İP-15 kümesi onarımda kullanıldığı için YANMIŞTIR.')
      ..writeln();
  }

  if (wantsGeneralization3) {
    // İP-22 — Dördüncü ayrık küme. İP-21 "yapısal aile" onarımı bittikten
    // sonra yazıldı; ailelerin gerçekten genelleşip genelleşmediğini ölçen
    // tek geçerli sayı budur.
    stdout
      ..write(
        evaluator
            .run(LexicalTurkishClassifier(), Generalization3Dataset.cases)
            .format(
              title: 'İP-22 · DÖRDÜNCÜ AYRIK KÜME — '
                  '${Generalization3Dataset.cases.length} örnek',
            ),
      )
      ..writeln('  ⓘ  Geçerli genelleme ölçümü budur.')
      ..writeln('     İP-15 ve İP-20 kümeleri onarımlarda kullanıldığı için')
      ..writeln('     YANMIŞTIR; geçmiş için docs/14.')
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
