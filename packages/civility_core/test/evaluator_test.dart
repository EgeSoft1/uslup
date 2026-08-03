// =============================================================================
// Değerlendirme Motoru — Test Paketi
// Dosya: packages/civility_core/test/evaluator_test.dart
//
// Ölçüm aracının kendisi de test edilmelidir. Yanlış hesaplayan bir metrik,
// hiç metrik olmamasından daha kötüdür: yanlış bir sayıya güvenilir ve
// raporlanır.
//
// Ayrıca burada veri kümesinin BÜTÜNLÜĞÜ de sınanır — çift kayıt, çelişkili
// etiket veya boş metin, ölçümü sessizce bozar.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

/// Belirli metinleri saldırgan sayan sahte sınıflandırıcı.
/// Metrik aritmetiğini gerçek motordan bağımsız sınamak için.
class StubClassifier implements ToxicityClassifier {
  final Set<String> flagged;
  const StubClassifier(this.flagged);

  @override
  String get modelName => 'sahte';

  @override
  CivilityAnalysis analyze(String text) {
    const signals = ContextSignals(
      hasSecondPersonPronoun: false,
      hasFirstPersonMarker: false,
      hasMention: false,
      capsRatio: 0.0,
      punctuationBurst: 0,
      hasReportedSpeech: false,
      quotedRanges: [],
    );

    if (!flagged.contains(text)) return CivilityAnalysis.clean(text, signals);

    return CivilityAnalysis(
      text: text,
      toxicity: 0.9,
      civilityScore: 10,
      risk: RiskLevel.yuksek,
      findings: const [],
      signals: signals,
      elapsed: Duration.zero,
    );
  }
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Metrik aritmetiği', () {
    test('kesinlik, duyarlılık ve F1 doğru hesaplanır', () {
      // 2 doğru pozitif, 1 yanlış pozitif, 1 yanlış negatif, 1 doğru negatif
      const cases = [
        GoldCase.flag(
            text: 'a',
            group: GoldGroup.acikSaldiri,
            category: ToxicityCategory.hakaret,
            note: 'DP'),
        GoldCase.flag(
            text: 'b',
            group: GoldGroup.acikSaldiri,
            category: ToxicityCategory.hakaret,
            note: 'DP'),
        GoldCase.flag(
            text: 'c',
            group: GoldGroup.acikSaldiri,
            category: ToxicityCategory.hakaret,
            note: 'YN'),
        GoldCase.clean(text: 'd', group: GoldGroup.masum, note: 'YP'),
        GoldCase.clean(text: 'e', group: GoldGroup.masum, note: 'DN'),
      ];

      final report = const Evaluator()
          .run(const StubClassifier({'a', 'b', 'd'}), cases);

      expect(report.overall.truePositive, 2);
      expect(report.overall.falsePositive, 1);
      expect(report.overall.falseNegative, 1);
      expect(report.overall.trueNegative, 1);

      expect(report.overall.precision, closeTo(2 / 3, 1e-9));
      expect(report.overall.recall, closeTo(2 / 3, 1e-9));
      expect(report.overall.f1, closeTo(2 / 3, 1e-9));
      expect(report.overall.specificity, closeTo(0.5, 1e-9));
      expect(report.overall.accuracy, closeTo(3 / 5, 1e-9));
    });

    test('F0.5 kesinliği duyarlılıktan daha ağır tartar', () {
      // Yüksek kesinlik / düşük duyarlılık, tersi durumdan daha iyi
      // puanlanmalı — bu ürünün hata maliyeti asimetriktir.
      // Kesinlik 1.00 / duyarlılık 0.50  ↔  kesinlik 0.50 / duyarlılık 1.00
      // Simetrik çift: F1 ikisini AYNI puanlar, F0.5 puanlamaz.
      const highPrecision = ConfusionMatrix(
          truePositive: 5, falsePositive: 0, falseNegative: 5, trueNegative: 10);
      const highRecall = ConfusionMatrix(
          truePositive: 10, falsePositive: 10, falseNegative: 0, trueNegative: 5);

      expect(highPrecision.f1, closeTo(highRecall.f1, 1e-9),
          reason: 'F1 ikisini eşit görür — sorun tam da budur.');
      expect(highPrecision.f0point5, greaterThan(highRecall.f0point5),
          reason: 'F0.5 kesinliği ödüllendirmeli.');
    });

    test('hiç tahmin yoksa kesinlik tanımsız değil, 1.0 sayılır', () {
      const empty = ConfusionMatrix(
          truePositive: 0, falsePositive: 0, falseNegative: 3, trueNegative: 5);
      expect(empty.precision, 1.0,
          reason: 'Hiç yakalamayan bir motor hiç haksız suçlama da yapmaz.');
      expect(empty.recall, 0.0);
    });

    test('dilim bazında ayrıştırma doğru toplanır', () {
      const cases = [
        GoldCase.flag(
            text: 'a',
            group: GoldGroup.acikSaldiri,
            category: ToxicityCategory.hakaret,
            note: ''),
        GoldCase.flag(
            text: 'b',
            group: GoldGroup.ortukSaldiri,
            category: ToxicityCategory.hakaret,
            note: ''),
        GoldCase.clean(text: 'c', group: GoldGroup.masum, note: ''),
      ];

      final report =
          const Evaluator().run(const StubClassifier({'a'}), cases);

      expect(report.byGroup[GoldGroup.acikSaldiri]!.recall, 1.0);
      expect(report.byGroup[GoldGroup.ortukSaldiri]!.recall, 0.0);
      expect(report.byGroup[GoldGroup.masum]!.specificity, 1.0);
    });

    test('yanlış sınıflandırmalar hata ayıklama için raporlanır', () {
      const cases = [
        GoldCase.clean(text: 'masum', group: GoldGroup.masum, note: 'tuzak'),
      ];
      final report =
          const Evaluator().run(const StubClassifier({'masum'}), cases);

      expect(report.falsePositives, hasLength(1));
      expect(report.falsePositives.single.summary, contains('tuzak'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Veri kümesi bütünlüğü', () {
    void checkIntegrity(String name, List<GoldCase> cases) {
      test('$name — metinler benzersiz', () {
        final seen = <String>{};
        final duplicates = <String>[];
        for (final c in cases) {
          if (!seen.add(c.text)) duplicates.add(c.text);
        }
        expect(duplicates, isEmpty,
            reason: 'Çift kayıt, o örneği ölçümde iki kez ağırlıklandırır.');
      });

      test('$name — metinler boş değil', () {
        expect(cases.where((c) => c.text.trim().isEmpty), isEmpty);
      });

      test('$name — etiket ve kategori tutarlı', () {
        for (final c in cases) {
          if (c.shouldFlag) {
            expect(c.expectedCategory, isNotNull,
                reason: '"${c.text}" müdahale bekliyor ama kategorisi yok.');
          } else {
            expect(c.expectedCategory, isNull,
                reason: '"${c.text}" temiz ama kategori atanmış.');
          }
        }
      });

      test('$name — her örnek gerekçelendirilmiş', () {
        expect(cases.where((c) => c.note.trim().isEmpty), isEmpty,
            reason: 'Gerekçesiz örnek, kaybedildiğinde neyin bozulduğunu '
                'söyleyemez.');
      });
    }

    checkIntegrity('geliştirme kümesi', GoldDataset.cases);
    checkIntegrity('ayrık küme', HoldoutDataset.cases);

    test('iki küme birbiriyle örtüşmez', () {
      final devTexts = GoldDataset.cases.map((c) => c.text).toSet();
      final overlap =
          HoldoutDataset.cases.where((c) => devTexts.contains(c.text));

      expect(overlap, isEmpty,
          reason: 'Örtüşme, ayrık kümeyi anlamsız kılar.');
    });

    test('kümeler dengeli — masum dilim yeterince ağırlıklı', () {
      final clean = GoldDataset.cases.where((c) => !c.shouldFlag).length;
      final ratio = clean / GoldDataset.cases.length;

      expect(ratio, greaterThan(0.35),
          reason: 'Yanlış pozitif en pahalı hatadır; küme bunu ölçebilecek '
              'kadar masum örnek içermeli.');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Katman katkısı — raporlanabilir olmalı', () {
    test('örüntü katmanı örtük dilimde duyarlılığı artırır', () {
      const evaluator = Evaluator();
      final ortuk = GoldDataset.ortukSaldiri;

      final without = evaluator.run(
          LexicalTurkishClassifier(enableImplicitPatterns: false), ortuk);
      final with_ = evaluator.run(LexicalTurkishClassifier(), ortuk);

      expect(without.overall.recall, lessThan(0.2),
          reason: 'Sözlük katmanı örtük saldırıya karşı kördür.');
      expect(with_.overall.recall, greaterThan(0.9));
    });

    test('örüntü katmanı masum dilimde kesinliği düşürmez', () {
      const evaluator = Evaluator();
      final masum = GoldDataset.masum;

      final without = evaluator.run(
          LexicalTurkishClassifier(enableImplicitPatterns: false), masum);
      final with_ = evaluator.run(LexicalTurkishClassifier(), masum);

      expect(with_.overall.specificity,
          greaterThanOrEqualTo(without.overall.specificity),
          reason: 'Yeni katman yanlış pozitif getirmemeli — bu, katmanın '
              'kabul koşuludur.');
    });
  });
}
