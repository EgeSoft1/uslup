// =============================================================================
// civility_core — genel API yüzeyi
// Dosya: packages/civility_core/lib/civility_core.dart
//
// Tüketiciler (mobile, server) yalnızca bu dosyayı import eder:
//
//     import 'package:civility_core/civility_core.dart';
//
// `lib/src/` altındaki iç yapı bu sözleşmeyi bozmadan değiştirilebilir —
// örneğin `LexicalTurkishClassifier` yerine `OnnxTurkishClassifier`
// geldiğinde çağıran taraflarda tek satır değişmez.
// =============================================================================

export 'src/civility_engine.dart';
export 'src/community/community_health.dart';
export 'src/context/context_analyzer.dart';
export 'src/detect/hate_patterns.dart';
export 'src/detect/implicit_detector.dart';
export 'src/detect/implicit_patterns.dart';
export 'src/eval/evaluator.dart';
export 'src/eval/gold_case.dart';
export 'src/eval/gold_dataset.dart';
export 'src/lexicon/toxicity_lexicon.dart';
export 'src/normalization/tokenizer.dart';
export 'src/normalization/turkish_morphology.dart';
export 'src/normalization/turkish_normalizer.dart';
export 'src/rewrite/rewrite_suggester.dart';
export 'src/eval/holdout_dataset.dart';
export 'src/eval/generalization_dataset.dart';
export 'src/eval/generalization2_dataset.dart';
export 'src/eval/generalization3_dataset.dart';
