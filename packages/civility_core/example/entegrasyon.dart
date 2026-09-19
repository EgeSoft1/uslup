// =============================================================================
// Entegrasyon örneği — bir platform Üslup'u nasıl ekler?
// Dosya: packages/civility_core/example/entegrasyon.dart
//
// Çalıştırma:  dart run example/entegrasyon.dart
//
// Bir Dart/Flutter uygulaması için entegrasyonun tamamı budur:
//   1. pubspec.yaml → dependencies: civility_core (path ya da git)
//   2. Motoru bir kez kur (sözlük dizini kurulumda hazırlanır)
//   3. Metin kutusunun her değişiminde analyze() çağır, sonucu göster
//
// Sunucu yok, API anahtarı yok, ağ çağrısı yok. Mobil uygulamadaki gönderi ve
// yanıt kutusu (`mobile/lib/presentation/compose/civility_composer.dart`)
// motoru tam olarak bu üç adımla kullanır.
// =============================================================================

import 'package:civility_core/civility_core.dart';

Future<void> main() async {
  // 2. Bir kez kurulur; uygulama boyunca paylaşılır. Motor durumsuzdur.
  final motor = LexicalTurkishClassifier();
  final oneriler = LocalRewriteSuggester(motor);
  // İlk çözümlemenin maliyetini (düzenli ifade derlemesi) öne alır. Uygulama
  // bunu ilk kareden sonra çağırır; kullanıcının ilk tuş vuruşu beklemez.
  motor.warmUp();

  // 3. Metin kutusunun her değişiminde (TextField.onChanged) çağrılır.
  for (final metin in const [
    'Bu fikre katılmıyorum',
    'sen tam bir şerrefsizsin',
    'Bana "şerefsiz" dedi, çok üzüldüm',
  ]) {
    final sonuc = motor.analyze(metin);
    print('"$metin"');
    print('  basamak   : ${sonuc.risk.label} → ${sonuc.risk.intervention}');
    print('  süre      : ${sonuc.elapsed.inMicroseconds} µs');
    for (final bulgu in sonuc.findings) {
      print('  gerekçe   : "${bulgu.matchedText}" · ${bulgu.sourceLabel} · '
          '${bulgu.explanation}');
    }
    // Öneri yalnızca Riskli ve üstünde gösterilir; karar kullanıcınındır.
    if (sonuc.risk.index >= RiskLevel.riskli.index) {
      for (final o in await oneriler.suggestTones(sonuc)) {
        print('  öneri     : [${o.tone ?? '-'}] ${o.text}');
      }
    }
    print('');
  }
}
