// =============================================================================
// Değerlendirme Aracı
// Dosya: packages/civility_core/bin/evaluate.dart
//
// Kullanım:
//   dart run bin/evaluate.dart                 → geliştirme kümesi
//   dart run bin/evaluate.dart --ayrik         → birinci ayrık küme (YANMIŞ)
//   dart run bin/evaluate.dart --genelleme     → İP-15 ikinci küme (YANMIŞ)
//   dart run bin/evaluate.dart --genelleme2    → İP-20 üçüncü küme (YANMIŞ)
//   dart run bin/evaluate.dart --genelleme3    → İP-22 dördüncü küme (YANMIŞ)
//   dart run bin/evaluate.dart --genelleme4    → İP-27 beşinci küme (YANMIŞ)
//   dart run bin/evaluate.dart --genelleme5    → İP-29 altıncı ayrık küme ✅
//   dart run bin/evaluate.dart --gundelik      → İP-30 gündelik metin (yanlış alarm)
//   dart run bin/evaluate.dart --karsilastir   → katman katkısı (A/B)
//   dart run bin/evaluate.dart --hepsi         → hepsi birden
//
// Çıktı doğrudan teknik rapora yapıştırılabilir.
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';

/// Bir parçanın özet satırı: saldırgan parçada duyarlılık, masum parçada
/// özgüllük anlamlıdır — diğeri tanımsız kalır.
String _parca(Evaluator evaluator, ToxicityClassifier engine,
    List<GoldCase> cases) {
  final m = evaluator.run(engine, cases).overall;
  String yuzde(double v) =>
      '%${(v * 100).toStringAsFixed(1).replaceAll('.', ',')}';
  return m.actualPositives > 0
      ? '${m.truePositive}/${m.actualPositives} yakalandı · '
          'duyarlılık ${yuzde(m.recall)}'
      : '${m.trueNegative}/${m.actualNegatives} temiz kaldı · '
          'özgüllük ${yuzde(m.specificity)}';
}

void main(List<String> args) {
  const evaluator = Evaluator();

  final wantsAll = args.contains('--hepsi');
  final wantsHoldout = wantsAll || args.contains('--ayrik');
  final wantsCompare = wantsAll || args.contains('--karsilastir');
  final wantsGeneralization = wantsAll || args.contains('--genelleme');
  final wantsGeneralization2 = wantsAll || args.contains('--genelleme2');
  final wantsGeneralization3 = wantsAll || args.contains('--genelleme3');
  final wantsGeneralization4 = wantsAll || args.contains('--genelleme4');
  final wantsGeneralization5 = wantsAll || args.contains('--genelleme5');
  final wantsEveryday = wantsAll || args.contains('--gundelik');
  final wantsDev = wantsAll ||
      (!wantsHoldout &&
          !wantsCompare &&
          !wantsGeneralization &&
          !wantsGeneralization2 &&
          !wantsGeneralization3 &&
          !wantsGeneralization4 &&
          !wantsGeneralization5 &&
          !wantsEveryday);

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
      ..writeln('     Bu kümedeki ilk ölçüm F1 = %84,2 idi; motor sonradan')
      ..writeln('     bu kümeye bakılarak düzeltildiği için YANMIŞTIR.')
      ..writeln('     Bugün geçerli olan genelleme ölçümü İP-29 kümesidir:')
      ..writeln('     dart run bin/evaluate.dart --genelleme5')
      ..writeln('     Ayrıntı: docs/04_MODEL_DEGERLENDIRME.md §5, docs/14 §5')
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
      ..writeln('  ⚠  UYARI: Bu küme YANMIŞTIR — İP-19 onarımı ona bakılarak')
      ..writeln('     yapıldı. İlk (ve tek geçerli) ölçümü: F1 = %55,6,')
      ..writeln('     duyarlılık %38,5. Aşağıdaki sayı genelleme DEĞİLDİR.')
      ..writeln('  ⓘ  Bu küme TEK ETİKETLEYİCİLİDİR; hakemler arası uyum')
      ..writeln("     (Cohen's kappa) henüz ölçülmemiştir. İkinci")
      ..writeln('     etiketleyici altyapısı: bin/annotate_export.dart')
      ..writeln();
  }

  if (wantsGeneralization2) {
    // İP-20 — Üçüncü ayrık küme. İP-19 onarımı TAMAMLANDIKTAN SONRA yazıldı
    // ve o onarımın genelleşip genelleşmediğini ölçtü: F1 %66,7.
    //
    // SONRA YANDI. İP-21'in "yapısal aile" onarımı bu kümeye bakılarak
    // yapıldı ve F1'i %97,3'e çıkardı. O sayı bir genelleme kanıtı değildir;
    // geçerli ölçüm artık İP-22 kümesindedir.
    stdout
      ..write(
        evaluator
            .run(LexicalTurkishClassifier(), Generalization2Dataset.cases)
            .format(
              title: 'İP-20 · ÜÇÜNCÜ AYRIK KÜME — '
                  '${Generalization2Dataset.cases.length} örnek',
            ),
      )
      ..writeln('  ⚠  UYARI: Bu küme de YANMIŞTIR — İP-21 onarımı ona')
      ..writeln('     bakılarak yapıldı. İlk (ve tek geçerli) ölçümü:')
      ..writeln('     F1 = %66,7, duyarlılık %50,0, kesinlik %100,0.')
      ..writeln('     Geçerli genelleme ölçümü: --genelleme5 (İP-29)')
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
      ..writeln('  ⚠  UYARI: Bu küme de YANMIŞTIR — İP-26 genişletmesi ona')
      ..writeln('     bakılarak yapıldı. İlk (ve tek geçerli) ölçümü:')
      ..writeln('     kesinlik %90,5, duyarlılık %54,3, F1 %67,9.')
      ..writeln('     Aşağıdaki sayı genelleme DEĞİLDİR — ezber ölçüsüdür.')
      ..writeln('     Geçerli genelleme ölçümü: --genelleme5 (İP-29)')
      ..writeln();
  }

  if (wantsGeneralization4) {
    // İP-27 — Beşinci ayrık küme. İP-26 genişletmesi TAMAMLANDIKTAN SONRA
    // yazıldı. Bugün geçerli olan tek genelleme ölçümü budur.
    stdout
      ..write(
        evaluator
            .run(LexicalTurkishClassifier(), Generalization4Dataset.cases)
            .format(
              title: 'İP-27 · BEŞİNCİ AYRIK KÜME — '
                  '${Generalization4Dataset.cases.length} örnek',
            ),
      )
      ..writeln('  ⚠  UYARI: Bu küme de YANMIŞTIR — İP-28 deyim katmanı,')
      ..writeln('     bu kümenin ilk geçişte kaçırdığı 31 örneğe bakılarak')
      ..writeln('     yazıldı (60 saldırgan örnekten 31 kaçak, duyarlılık')
      ..writeln('     ≈%48). İlk geçiş kesinliği kayda geçmedi.')
      ..writeln('     Geçerli genelleme ölçümü: --genelleme5 (İP-29) —')
      ..writeln('     bu kümeden SONRA, motora bakılmadan yazıldı.')
      ..writeln('     Kayıt: docs/18_IP29_ILK_GECIS.md')
      ..writeln('  ⓘ  Bu küme TEK ETİKETLEYİCİLİDİR; hakemler arası uyum')
      ..writeln("     (Cohen's kappa) henüz ölçülmemiştir.")
      ..writeln();
  }

  if (wantsGeneralization5) {
    // İP-29 — Altıncı ayrık küme. İP-28 tamamlandıktan SONRA, motor bu
    // kümeye karşı hiç çalıştırılmadan yazıldı ve ölçümden önce commit edildi.
    final cases = Generalization5Dataset.cases;
    final engine = LexicalTurkishClassifier();
    stdout
      ..write(evaluator.run(engine, cases).format(
            title: 'İP-29 · ALTINCI AYRIK KÜME — ${cases.length} örnek',
          ))
      ..writeln('  PARÇALARA GÖRE')
      ..writeln('    1. bilinen yeteneklerin yeni örnekleri : '
          '${_parca(evaluator, engine, cases.sublist(0, 30))}')
      ..writeln('    2. yakın-kaçış ve bağlam tuzakları    : '
          '${_parca(evaluator, engine, cases.sublist(30, 60))}')
      ..writeln('    3. serbest düşmanca ifadeler          : '
          '${_parca(evaluator, engine, cases.sublist(60, 90))}')
      ..writeln()
      ..writeln('  ⓘ  GEÇERLİ GENELLEME ÖLÇÜMÜ BUDUR — ilk geçiş, düzeltilmeden.')
      ..writeln('     Bu kümeye bakılarak motor değiştirilirse küme yanar.')
      ..writeln('  ⓘ  Bu küme TEK ETİKETLEYİCİLİDİR; hakemler arası uyum')
      ..writeln("     (Cohen's kappa) henüz ölçülmemiştir.")
      ..writeln();
  }

  if (wantsEveryday) {
    // İP-30 — Gündelik metin. Tamamı masum; tek anlamlı metrik özgüllük.
    // Yanlış alarmların listesi de basılır: sayıdan çok HANGİ cümlenin
    // işaretlendiği önemlidir.
    final cases = EverydayDataset.cases;
    final engine = LexicalTurkishClassifier();
    final alarmlar = [
      for (final c in cases)
        if (engine.analyze(c.text) case final a when a.risk != RiskLevel.temiz)
          '    ${a.risk.label.padRight(12)} ${c.text}  '
              '[${a.findings.map((f) => f.term).join(", ")}]',
    ];
    stdout
      ..writeln('═' * 78)
      ..writeln('İP-30 · GÜNDELİK METİN KÜMESİ — ${cases.length} masum cümle')
      ..writeln('═' * 78)
      ..writeln('  ${_parca(evaluator, engine, cases)}')
      ..writeln('  Yanlış alarm: ${alarmlar.length}')
      ..writeln();
    for (final satir in alarmlar) {
      stdout.writeln(satir);
    }
    stdout
      ..writeln()
      ..writeln('  ⓘ  Hata sınıfları fark edildikten SONRA, düzeltmelerden ÖNCE')
      ..writeln('     yazıldı; o sınıflar için kör değildir. Kayıt: docs/20.')
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
