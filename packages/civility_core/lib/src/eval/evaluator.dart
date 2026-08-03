// =============================================================================
// Değerlendirme Motoru — kesinlik, duyarlılık, F1
// Dosya: packages/civility_core/lib/src/eval/evaluator.dart
//
// ── NEDEN F1 DEĞİL DE F1 *VE* DİLİMLER ────────────────────────────────────
// Toplu F1 tek başına yanıltıcıdır. Bu üründe iki hata türünün maliyeti
// simetrik DEĞİLDİR:
//
//   YANLIŞ POZİTİF (masum metne müdahale)
//     → Kullanıcı güvenini kaybeder ve özelliği kapatır. Ürün ölür.
//
//   YANLIŞ NEGATİF (hakaret kaçar)
//     → Bir hakaret gönderilir. Kötü, ama ürün yaşamaya devam eder.
//
// Bu yüzden KESİNLİK (precision), duyarlılıktan (recall) daha önemlidir ve
// rapor her ikisini ayrı ayrı, dilim bazında göstermek zorundadır.
// =============================================================================

import '../civility_engine.dart';
import 'gold_case.dart';

/// İkili sınıflandırma karışıklık matrisi ve türetilmiş metrikler.
class ConfusionMatrix {
  /// Doğru pozitif: saldırgan, doğru yakalandı.
  final int truePositive;

  /// Yanlış pozitif: masum, haksız yere yakalandı. EN PAHALI HATA.
  final int falsePositive;

  /// Yanlış negatif: saldırgan, kaçtı.
  final int falseNegative;

  /// Doğru negatif: masum, doğru şekilde rahat bırakıldı.
  final int trueNegative;

  const ConfusionMatrix({
    required this.truePositive,
    required this.falsePositive,
    required this.falseNegative,
    required this.trueNegative,
  });

  int get total =>
      truePositive + falsePositive + falseNegative + trueNegative;

  int get actualPositives => truePositive + falseNegative;
  int get actualNegatives => falsePositive + trueNegative;
  int get predictedPositives => truePositive + falsePositive;

  /// Yakaladıklarımın ne kadarı gerçekten saldırgandı?
  /// Tanımsızsa (hiç yakalama yok) 1.0 kabul edilir — hiç yanlış suçlama yok.
  double get precision =>
      predictedPositives == 0 ? 1.0 : truePositive / predictedPositives;

  /// Gerçek saldırıların ne kadarını yakaladım?
  double get recall =>
      actualPositives == 0 ? 1.0 : truePositive / actualPositives;

  /// Masum metinlerin ne kadarını rahat bıraktım? (kesinliğin ikizi)
  double get specificity =>
      actualNegatives == 0 ? 1.0 : trueNegative / actualNegatives;

  double get f1 {
    final p = precision;
    final r = recall;
    return (p + r) == 0 ? 0.0 : 2 * p * r / (p + r);
  }

  /// Kesinliği duyarlılıktan iki kat önemli sayan F-ölçüsü (β = 0.5).
  /// Bu ürünün gerçek hedef fonksiyonu budur.
  double get f0point5 {
    const beta2 = 0.25;
    final p = precision;
    final r = recall;
    final denominator = beta2 * p + r;
    return denominator == 0 ? 0.0 : (1 + beta2) * p * r / denominator;
  }

  double get accuracy =>
      total == 0 ? 1.0 : (truePositive + trueNegative) / total;

  ConfusionMatrix operator +(ConfusionMatrix other) => ConfusionMatrix(
        truePositive: truePositive + other.truePositive,
        falsePositive: falsePositive + other.falsePositive,
        falseNegative: falseNegative + other.falseNegative,
        trueNegative: trueNegative + other.trueNegative,
      );

  static const ConfusionMatrix zero = ConfusionMatrix(
    truePositive: 0,
    falsePositive: 0,
    falseNegative: 0,
    trueNegative: 0,
  );
}

/// Yanlış sınıflandırılmış tek bir örnek — hata ayıklama çıktısı.
class Misclassification {
  final GoldCase gold;
  final CivilityAnalysis actual;

  const Misclassification(this.gold, this.actual);

  String get summary {
    final matched = actual.findings.isEmpty
        ? '—'
        : actual.findings.map((f) => '"${f.matchedText}"').join(', ');
    return '${gold.text}\n'
        '      beklenen: ${gold.shouldFlag ? "müdahale" : "temiz"} · '
        'gerçekleşen: ${actual.risk.name} (${actual.toxicity.toStringAsFixed(2)}) · '
        'eşleşme: $matched\n'
        '      not: ${gold.note}';
  }
}

/// Tam değerlendirme raporu.
class EvaluationReport {
  final ConfusionMatrix overall;
  final Map<GoldGroup, ConfusionMatrix> byGroup;

  /// Doğru yakalanan örneklerde baskın kategori de doğru muydu?
  final int categoryCorrect;
  final int categoryTotal;

  final List<Misclassification> falsePositives;
  final List<Misclassification> falseNegatives;

  /// Örnek başına ortalama çözümleme süresi (mikrosaniye).
  final double averageMicroseconds;

  const EvaluationReport({
    required this.overall,
    required this.byGroup,
    required this.categoryCorrect,
    required this.categoryTotal,
    required this.falsePositives,
    required this.falseNegatives,
    required this.averageMicroseconds,
  });

  double get categoryAccuracy =>
      categoryTotal == 0 ? 1.0 : categoryCorrect / categoryTotal;

  /// İnsan-okunur rapor. Doğrudan teknik rapora yapıştırılabilir.
  String format({String title = 'Nezaket Motoru — Değerlendirme'}) {
    final buffer = StringBuffer()
      ..writeln('═' * 78)
      ..writeln(title)
      ..writeln('═' * 78)
      ..writeln();

    buffer
      ..writeln('GENEL')
      ..writeln('  Örnek sayısı        : ${overall.total}')
      ..writeln('  Kesinlik (precision): ${_pct(overall.precision)}')
      ..writeln('  Duyarlılık (recall) : ${_pct(overall.recall)}')
      ..writeln('  Özgüllük            : ${_pct(overall.specificity)}')
      ..writeln('  F1                  : ${_pct(overall.f1)}')
      ..writeln('  F0.5 (kesinlik ağır): ${_pct(overall.f0point5)}')
      ..writeln('  Doğruluk (accuracy) : ${_pct(overall.accuracy)}')
      ..writeln('  Kategori doğruluğu  : ${_pct(categoryAccuracy)} '
          '($categoryCorrect/$categoryTotal)')
      ..writeln('  Ortalama süre       : '
          '${averageMicroseconds.toStringAsFixed(1)} µs')
      ..writeln();

    buffer
      ..writeln('KARIŞIKLIK MATRİSİ')
      ..writeln('                  │ tahmin: saldırgan │ tahmin: temiz')
      ..writeln('  ────────────────┼───────────────────┼──────────────')
      ..writeln('  gerçek saldırgan│ ${_cell(overall.truePositive)} (DP)'
          '          │ ${_cell(overall.falseNegative)} (YN)')
      ..writeln('  gerçek temiz    │ ${_cell(overall.falsePositive)} (YP)'
          '          │ ${_cell(overall.trueNegative)} (DN)')
      ..writeln();

    buffer.writeln('DİLİM BAZINDA');
    for (final group in GoldGroup.values) {
      final matrix = byGroup[group];
      if (matrix == null || matrix.total == 0) continue;

      // Tek sınıflı dilimlerde anlamlı olan metrik farklıdır:
      // saldırı dilimlerinde duyarlılık, masum diliminde özgüllük.
      final headline = matrix.actualNegatives == 0
          ? 'duyarlılık ${_pct(matrix.recall)}'
          : matrix.actualPositives == 0
              ? 'özgüllük   ${_pct(matrix.specificity)}'
              : 'F1         ${_pct(matrix.f1)}';

      buffer.writeln('  ${group.label.padRight(16)} '
          '${matrix.total.toString().padLeft(3)} örnek · $headline');
    }
    buffer.writeln();

    if (falsePositives.isNotEmpty) {
      buffer.writeln(
          'YANLIŞ POZİTİFLER (${falsePositives.length}) — en pahalı hata');
      for (final item in falsePositives) {
        buffer.writeln('  ✗ ${item.summary}');
      }
      buffer.writeln();
    }

    if (falseNegatives.isNotEmpty) {
      buffer.writeln('YANLIŞ NEGATİFLER (${falseNegatives.length}) — kaçanlar');
      for (final item in falseNegatives) {
        buffer.writeln('  ✗ ${item.summary}');
      }
      buffer.writeln();
    }

    if (falsePositives.isEmpty && falseNegatives.isEmpty) {
      buffer.writeln('Hatalı sınıflandırma yok.');
    }

    return buffer.toString();
  }

  static String _pct(double value) =>
      '${(value * 100).toStringAsFixed(1).padLeft(5)} %';

  static String _cell(int value) => value.toString().padLeft(6);
}

/// Bir sınıflandırıcıyı altın kümeye karşı ölçer.
class Evaluator {
  const Evaluator();

  EvaluationReport run(ToxicityClassifier engine, List<GoldCase> cases) {
    var overall = ConfusionMatrix.zero;
    final byGroup = <GoldGroup, ConfusionMatrix>{};
    final falsePositives = <Misclassification>[];
    final falseNegatives = <Misclassification>[];

    var categoryCorrect = 0;
    var categoryTotal = 0;

    final stopwatch = Stopwatch()..start();

    for (final gold in cases) {
      final analysis = engine.analyze(gold.text);

      // Ürün kararı: "temiz" dışındaki her seviye bir müdahaledir.
      final predictedFlag = analysis.risk != RiskLevel.temiz;

      final cell = ConfusionMatrix(
        truePositive: gold.shouldFlag && predictedFlag ? 1 : 0,
        falsePositive: !gold.shouldFlag && predictedFlag ? 1 : 0,
        falseNegative: gold.shouldFlag && !predictedFlag ? 1 : 0,
        trueNegative: !gold.shouldFlag && !predictedFlag ? 1 : 0,
      );

      overall = overall + cell;
      byGroup[gold.group] = (byGroup[gold.group] ?? ConfusionMatrix.zero) + cell;

      if (cell.falsePositive == 1) {
        falsePositives.add(Misclassification(gold, analysis));
      }
      if (cell.falseNegative == 1) {
        falseNegatives.add(Misclassification(gold, analysis));
      }

      // Kategori doğruluğu yalnızca doğru yakalanan örneklerde anlamlıdır.
      if (cell.truePositive == 1 && gold.expectedCategory != null) {
        categoryTotal++;
        if (analysis.dominantCategory == gold.expectedCategory) {
          categoryCorrect++;
        }
      }
    }

    stopwatch.stop();

    return EvaluationReport(
      overall: overall,
      byGroup: byGroup,
      categoryCorrect: categoryCorrect,
      categoryTotal: categoryTotal,
      falsePositives: falsePositives,
      falseNegatives: falseNegatives,
      averageMicroseconds:
          cases.isEmpty ? 0 : stopwatch.elapsedMicroseconds / cases.length,
    );
  }
}

/// İki raporu karşılaştırır — "yeni katman neyi değiştirdi?" sorusunun cevabı.
class ReportComparison {
  final EvaluationReport before;
  final EvaluationReport after;
  final String beforeLabel;
  final String afterLabel;

  const ReportComparison({
    required this.before,
    required this.after,
    this.beforeLabel = 'önce',
    this.afterLabel = 'sonra',
  });

  String format() {
    final buffer = StringBuffer()
      ..writeln('═' * 78)
      ..writeln('KARŞILAŞTIRMA: $beforeLabel → $afterLabel')
      ..writeln('═' * 78)
      ..writeln()
      ..writeln('  Metrik              ${beforeLabel.padLeft(9)} '
          '${afterLabel.padLeft(9)}     değişim');

    void row(String name, double a, double b) {
      final delta = (b - a) * 100;
      final sign = delta > 0.05 ? '+' : (delta < -0.05 ? '' : ' ');
      buffer.writeln('  ${name.padRight(20)}'
          '${EvaluationReport._pct(a)} '
          '${EvaluationReport._pct(b)}  '
          '$sign${delta.toStringAsFixed(1)} puan');
    }

    row('Kesinlik', before.overall.precision, after.overall.precision);
    row('Duyarlılık', before.overall.recall, after.overall.recall);
    row('Özgüllük', before.overall.specificity, after.overall.specificity);
    row('F1', before.overall.f1, after.overall.f1);
    row('F0.5', before.overall.f0point5, after.overall.f0point5);
    row('Doğruluk', before.overall.accuracy, after.overall.accuracy);

    buffer.writeln();
    buffer.writeln('  Dilim bazında duyarlılık:');
    for (final group in GoldGroup.values) {
      final a = before.byGroup[group];
      final b = after.byGroup[group];
      if (a == null || b == null || a.actualPositives == 0) continue;
      final delta = (b.recall - a.recall) * 100;
      final sign = delta > 0.05 ? '+' : (delta < -0.05 ? '' : ' ');
      buffer.writeln('    ${group.label.padRight(18)}'
          '${EvaluationReport._pct(a.recall)} '
          '${EvaluationReport._pct(b.recall)}  '
          '$sign${delta.toStringAsFixed(1)} puan');
    }

    return buffer.toString();
  }
}
