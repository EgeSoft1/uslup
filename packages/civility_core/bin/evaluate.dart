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
//   dart run bin/evaluate.dart --yonelim       → İP-31 somut adlar + ikinci şahıs
//   dart run bin/evaluate.dart --savunma       → İP-32 aktarılan düşmanca görüş
//   dart run bin/evaluate.dart --eksenler      → İP-33 cinsiyet · yaş · engellilik · göç
//                                                (İP-34 ayrık küme de birlikte basılır)
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
  final wantsDirection = wantsAll || args.contains('--yonelim');
  final wantsStance = wantsAll || args.contains('--savunma');
  final wantsAxes = wantsAll || args.contains('--eksenler');
  final wantsDev = wantsAll ||
      (!wantsHoldout &&
          !wantsCompare &&
          !wantsGeneralization &&
          !wantsGeneralization2 &&
          !wantsGeneralization3 &&
          !wantsGeneralization4 &&
          !wantsGeneralization5 &&
          !wantsEveryday &&
          !wantsDirection &&
          !wantsStance &&
          !wantsAxes);

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

  if (wantsDirection) {
    // İP-31 — Somut adlar ve ikinci şahıs. A parçası masum, B parçası saldırı.
    final cases = DirectionDataset.cases;
    final engine = LexicalTurkishClassifier();
    final hatalar = [
      for (final c in cases)
        if (engine.analyze(c.text) case final a
            when (a.risk != RiskLevel.temiz) != c.shouldFlag)
          '    ${c.shouldFlag ? "KAÇTI      " : "YANLIŞ ALARM"} '
              '${a.risk.label.padRight(12)} ${c.text}  '
              '[${a.findings.map((f) => f.term).join(", ")}]',
    ];
    stdout
      ..writeln('═' * 78)
      ..writeln('İP-31 · YÖNELİM KÜMESİ — ${cases.length} örnek')
      ..writeln('═' * 78)
      ..writeln('  A. somut anlam, ikinci şahıs yüklem/hitap dışı : '
          '${_parca(evaluator, engine, cases.sublist(0, 30))}')
      ..writeln('  B. yüklem · hitap · soru · benzetme          : '
          '${_parca(evaluator, engine, cases.sublist(30, 50))}')
      ..writeln();
    for (final satir in hatalar) {
      stdout.writeln(satir);
    }
    stdout
      ..writeln()
      ..writeln('  ⓘ  Hata sınıfı bilindikten SONRA, düzeltmeden ÖNCE yazıldı.')
      ..writeln('     Kayıt: docs/21.')
      ..writeln();
  }

  if (wantsStance) {
    // İP-32 — Aktarılan düşmanca görüş. A masum (kınama), B ve C saldırı.
    final cases = StanceDataset.cases;
    final engine = LexicalTurkishClassifier();
    final hatalar = [
      for (final c in cases)
        if (engine.analyze(c.text) case final a
            when (a.risk != RiskLevel.temiz) != c.shouldFlag)
          '    ${c.shouldFlag ? "KAÇTI      " : "YANLIŞ ALARM"} '
              '${a.risk.label.padRight(12)} ${c.text}  '
              '[${a.findings.map((f) => f.term).join(", ")}]',
    ];
    stdout
      ..writeln('═' * 78)
      ..writeln('İP-32 · SAVUNMA DİLİ KÜMESİ — ${cases.length} örnek')
      ..writeln('═' * 78)
      ..writeln('  A. aktarıp kınayan (masum)        : '
          '${_parca(evaluator, engine, cases.sublist(0, 20))}')
      ..writeln('  B. konuşanın kendi görüşü         : '
          '${_parca(evaluator, engine, cases.sublist(20, 30))}')
      ..writeln('  C. aktarıp onaylayan (D8 bedeli)  : '
          '${_parca(evaluator, engine, cases.sublist(30, 40))}')
      ..writeln();
    for (final satir in hatalar) {
      stdout.writeln(satir);
    }
    stdout
      ..writeln()
      ..writeln('  ⓘ  Hata sınıfı bilindikten SONRA, düzeltmeden ÖNCE yazıldı.')
      ..writeln('     Kayıt: docs/22.')
      ..writeln();
  }

  if (wantsAxes) {
    // İP-33 — Kimlik eksenleri. A saldırı, B aynı fiilleri taşıyan masum.
    final cases = IdentityAxesDataset.cases;
    final engine = LexicalTurkishClassifier();
    final hatalar = [
      for (final c in cases)
        if (engine.analyze(c.text) case final a
            when (a.risk != RiskLevel.temiz) != c.shouldFlag)
          '    ${c.shouldFlag ? "KAÇTI      " : "YANLIŞ ALARM"} '
              '${a.risk.label.padRight(12)} ${c.text}  '
              '[${a.findings.map((f) => f.term).join(", ")}]',
    ];
    const eksenler = ['cinsiyet', 'yaş', 'engellilik', 'göç'];
    stdout
      ..write(evaluator.run(engine, cases).format(
            title: 'İP-33 · KİMLİK EKSENLERİ KÜMESİ — ${cases.length} örnek',
          ))
      ..writeln('  A. saldırı                        : '
          '${_parca(evaluator, engine, cases.sublist(0, 32))}')
      ..writeln('  B. aynı kalıpları taşıyan masum   : '
          '${_parca(evaluator, engine, cases.sublist(32, 64))}');
    for (var e = 0; e < eksenler.length; e++) {
      stdout.writeln('     ${eksenler[e].padRight(11)} saldırı '
          '${_parca(evaluator, engine, cases.sublist(e * 8, e * 8 + 8))}'
          '  ·  masum '
          '${_parca(evaluator, engine, cases.sublist(32 + e * 8, 40 + e * 8))}');
    }
    stdout.writeln();
    for (final satir in hatalar) {
      stdout.writeln(satir);
    }
    stdout
      ..writeln()
      ..writeln('  ⓘ  Hata sınıfı bilindikten SONRA, düzeltmeden ÖNCE yazıldı;')
      ..writeln('     yazan örüntü kataloğunu bilir, küme kör değildir.')
      ..writeln('     Düzeltme bu kümeye bakılarak yapıldı: YANMIŞTIR.')
      ..writeln('     Kayıt: docs/26.')
      ..writeln();

    void ayrikKume(String baslik, List<GoldCase> kor, List<String> notlar) {
      final korHatalar = [
        for (final c in kor)
          if (engine.analyze(c.text) case final a
              when (a.risk != RiskLevel.temiz) != c.shouldFlag)
            '    ${c.shouldFlag ? "KAÇTI      " : "YANLIŞ ALARM"} '
                '${a.risk.label.padRight(12)} ${c.text}  '
                '[${a.findings.map((f) => f.term).join(", ")}]',
      ];
      stdout
        ..write(evaluator.run(engine, kor).format(
              title: '$baslik — ${kor.length} örnek',
            ))
        ..writeln('  A. saldırı : ${_parca(evaluator, engine, kor.sublist(0, 20))}')
        ..writeln('  B. masum   : ${_parca(evaluator, engine, kor.sublist(20, 40))}');
      for (var e = 0; e < eksenler.length; e++) {
        stdout.writeln('     ${eksenler[e].padRight(11)} saldırı '
            '${_parca(evaluator, engine, kor.sublist(e * 5, e * 5 + 5))}'
            '  ·  masum '
            '${_parca(evaluator, engine, kor.sublist(20 + e * 5, 25 + e * 5))}');
      }
      stdout.writeln();
      for (final satir in korHatalar) {
        stdout.writeln(satir);
      }
      stdout.writeln();
      for (final satir in notlar) {
        stdout.writeln(satir);
      }
      stdout.writeln();
    }

    // İP-34 — ilk turdan SONRA yazıldı; ikinci tur ona bakılarak yapıldı.
    ayrikKume('İP-34 · KİMLİK EKSENLERİ AYRIK KÜMESİ',
        IdentityAxesBlindDataset.cases, const [
      '  ⚠  YANMIŞTIR — ikinci tur (docs/26 §6) bu kümenin kaçaklarından',
      '     çıkarılan hata sınıflarıyla yapıldı. İlk ve tek geçerli geçişi:',
      '     kesinlik %100,0 · duyarlılık %15,0 · özgüllük %100,0.',
    ]);

    // İP-35 — ikinci turdan SONRA yazıldı. İP-33 çalışmasının geçerli sayısı.
    ayrikKume('İP-35 · KİMLİK EKSENLERİ İKİNCİ AYRIK KÜME',
        IdentityAxesBlind2Dataset.cases, const [
      '  ⓘ  İkinci tur bittikten SONRA yazıldı, bir kez ölçüldü.',
      '     Bu kümeye bakılarak motor değiştirilirse küme yanar.',
      '     Kayıt: docs/26 §7.',
    ]);
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
