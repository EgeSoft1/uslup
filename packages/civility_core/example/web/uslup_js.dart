// =============================================================================
// Flutter'sız platformlar için JavaScript derlemesi
// Dosya: packages/civility_core/example/web/uslup_js.dart
//
// Motor saf Dart'tır; Dart, JavaScript'e derlenir. Bu dosya motoru tek bir
// global fonksiyon olarak dışa açar:
//
//   dart compile js -O2 example/web/uslup_js.dart -o example/web/uslup.js
//
// Herhangi bir web sitesi (React, Vue ya da düz HTML) şöyle kullanır:
//
//   <script src="uslup.js"></script>
//   const sonuc = JSON.parse(uslupCozumle(textarea.value));
//   // { risk, riskEtiketi, toksisite, sure_us, bulgular: [...] }
//
// Çözümleme tarayıcının içinde yapılır; metin sunucuya gitmez. Web sunumu
// (`flutter build web`) aynı paketi aynı yolla derler — karar birebir aynıdır.
// Node.js'te de çalışır (`example/web/dene.js`).
// =============================================================================

import 'dart:convert';
import 'dart:js_interop';

import 'package:civility_core/civility_core.dart';

@JS('uslupCozumle')
external set _uslupCozumle(JSFunction fonksiyon);

@JS('uslupSurum')
external set _uslupSurum(JSString surum);

final _motor = LexicalTurkishClassifier();

String _cozumle(String metin) {
  final a = _motor.analyze(metin);
  return jsonEncode({
    'risk': a.risk.name,
    'riskEtiketi': a.risk.label,
    'mudahale': a.risk.intervention,
    'toksisite': a.toxicity,
    'sure_us': a.elapsed.inMicroseconds,
    'destekKarti': a.needsSupport,
    'bulgular': [
      for (final f in a.findings)
        {
          'ifade': f.matchedText,
          'terim': f.term,
          'kategori': f.category.label,
          'katman': f.sourceLabel,
          'gerekce': f.explanation,
          'baslangic': f.start,
          'bitis': f.end,
        },
    ],
  });
}

void main() {
  _uslupCozumle = ((JSString metin) => _cozumle(metin.toDart).toJS).toJS;
  _uslupSurum = CivilityCoreSurum.surum.toJS;
}
