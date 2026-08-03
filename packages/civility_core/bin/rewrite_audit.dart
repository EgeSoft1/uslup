// =============================================================================
// Yeniden Yazma Kalite Denetimi
// Dosya: packages/civility_core/bin/rewrite_audit.dart
//
//     dart run bin/rewrite_audit.dart
//
// Tespit doğruluğunu `bin/evaluate.dart` ölçer. Bu araç farklı bir soruyu
// sorar: motor bir saldırıyı yakaladığında, ÖNERDİĞİ metin işe yarıyor mu?
//
// Bu ayrım önemlidir çünkü doğrulama kapısı yalnızca toksisiteye bakar.
// "gerizekalı herif" → "katılmıyorum herif" dönüşümü toksisiteyi düşürür ve
// kapıdan geçer — ama çıktı bozuktur. Sayısal metrik bunu göremez; çıktıya
// gözle bakmak gerekir. Araç tam da bunun içindir.
// =============================================================================

import 'package:civility_core/civility_core.dart';

Future<void> main(List<String> args) async {
  final limit = args.isEmpty ? 30 : int.tryParse(args.first) ?? 30;

  final engine = LexicalTurkishClassifier();
  final suggester = LocalRewriteSuggester(engine);

  var withFindings = 0, produced = 0, none = 0;
  final samples = <String>[];

  for (final testCase in GoldDataset.cases) {
    if (!testCase.shouldFlag) continue;

    final analysis = engine.analyze(testCase.text);
    if (!analysis.hasFindings) continue;
    withFindings++;

    final suggestion = await suggester.suggest(analysis);
    if (suggestion == null) {
      none++;
      continue;
    }
    produced++;

    if (samples.length < limit) {
      samples.add('  "${testCase.text}"\n'
          '   → "${suggestion.text}"  '
          '[${analysis.civilityScore} → ${suggestion.projectedCivilityScore}]');
    }
  }

  print('Müdahale gereken ve bulgu üretilen : $withFindings');
  print('Öneri üretilebildi                 : $produced');
  print('Öneri ÜRETİLEMEDİ                  : $none');
  print('');
  print('ÖRNEK ÇIKTILAR  [nezaket puanı: önce → sonra]');
  print(samples.join('\n'));
}
