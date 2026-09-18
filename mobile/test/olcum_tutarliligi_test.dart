// =============================================================================
// Ekrandaki ölçüm sayıları motorun gerçek ölçümüyle aynı mı? (docs/24 · 46)
// Dosya: mobile/test/olcum_tutarliligi_test.dart
//
// Geçerli ayrık kümenin (İP-29) sayıları arayüzde üç yerde ELLE yazılıdır:
// motor künyesi (`Civility.olcumOzeti`), Hakkında ekranı ve Üslup panelindeki
// ölçüm tablosu. 13 Eylül kod denetiminde motor değişti ve dört yer elle
// güncellendi (docs/23). Unutulan bir yer, jüriye bayat bir sayı gösterir.
//
// Bu test sayıyı ÇALIŞMA ANINDA ölçer ve üç kaynağın onu taşıdığını denetler.
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turkiye_mesajlasma/core/civility/civility_runtime.dart';

String _yuzde(double v) => '%${(v * 100).toStringAsFixed(1).replaceAll('.', ',')}';

void main() {
  final olcum = const Evaluator()
      .run(LexicalTurkishClassifier(), Generalization5Dataset.cases)
      .overall;
  final kesinlik = _yuzde(olcum.precision);
  final duyarlilik = _yuzde(olcum.recall);
  final f05 = _yuzde(olcum.f0point5);

  test('motor künyesi güncel İP-29 ölçümünü taşır', () {
    expect(Civility.olcumOzeti, contains('kesinlik $kesinlik'));
    expect(Civility.olcumOzeti, contains('duyarlılık $duyarlilik'));
  });

  test('Hakkında ekranı güncel İP-29 ölçümünü taşır', () {
    final kaynak =
        File('lib/presentation/settings/about_screen.dart').readAsStringSync();
    expect(kaynak, contains('İP-29 · kesinlik $kesinlik · duyarlılık $duyarlilik'));
    expect(kaynak, contains('F0.5 $f05'));
  });

  test('Üslup panelindeki ölçüm tablosu güncel İP-29 ölçümünü taşır', () {
    final kaynak = File('lib/presentation/uslup/uslup_panel_screen.dart')
        .readAsStringSync();
    final satir = RegExp(
      r"kume: '6\. ayrık küme \(İP-29\)',\s*boyut: '90',\s*"
      r"kesinlik: '([^']+)',\s*duyarlilik: '([^']+)',\s*f1: '([^']+)'",
    ).firstMatch(kaynak);
    expect(satir, isNotNull, reason: 'Panel tablosunda İP-29 satırı bulunamadı.');
    expect(satir!.group(1), kesinlik);
    expect(satir.group(2), duyarlilik);
    expect(satir.group(3), _yuzde(olcum.f1));
  });

  test('ONNX ikinci görüşü kararı ve basamağı değiştiremez (docs/24 · 22)', () {
    // Ölçülen sayıların uygulamada geçerli olmasının şartı: melez katman
    // yeni bir çözümleme ÜRETMEZ, motorunkini olduğu gibi döndürür. Paketlenen
    // model gündelik masum cümlelerin %72'sini saldırgan buluyor; basamağa
    // dokunduğu anda telefon ile web sunumu farklı karar verir.
    final kaynak =
        File('lib/core/civility/onnx_classifier_io.dart').readAsStringSync();
    final kodSatirlari = kaynak
        .split('\n')
        .where((s) => !s.trimLeft().startsWith('//'))
        .join('\n');
    expect(kodSatirlari.contains('CivilityAnalysis('), isFalse,
        reason: 'Melez katman kendi çözümlemesini kuruyor — model yeniden '
            'karar/basamak üretiyor olabilir.');
  });

  test('README geçerli ölçüm tablosu güncel sayıyı taşır', () {
    final readme = File('../README.md').readAsStringSync();
    expect(readme, contains('**$kesinlik**'),
        reason: 'README İP-29 tablosundaki bugünkü kesinlik bayat.');
    expect(readme, contains('**$f05**'),
        reason: 'README İP-29 tablosundaki bugünkü F0.5 bayat.');
  });

  // ── SÖZ VARLIĞI SAYILARI ───────────────────────────────────────────────
  //
  // 18 Eylül'de dört yerde bayat ÖLÇÜM sayısı bulundu (docs/30 §2) ve bu
  // dosyadaki testler onu yakaladı. Aynı gün, testin BAKMADIĞI söz varlığı
  // sayılarının da bayatladığı görüldü: README "94 kimlik terimi" diyordu,
  // motorda 104 vardı; jüri demo metni "308 sözlük girdisi, 214 örüntü"
  // diyordu, motorda 310 ve 221 vardı.
  //
  // Sayıyı ekranda gösterip "motordan sayılıyor" demek, ancak gerçekten
  // sayılıyorsa dürüsttür. Aşağıdaki testler bu iddiayı kilitler.

  test('README kimlik söz varlığı sayısı motordakiyle aynı', () {
    final readme = File('../README.md').readAsStringSync();
    expect(readme, contains('Kimlik söz varlığı ${IdentityTerms.all.length} terimdir'),
        reason: 'README kimlik terimi sayısı bayat — motorda '
            '${IdentityTerms.all.length} terim var.');
  });

  test('jüri demo metnindeki söz varlığı sayıları motordakiyle aynı', () {
    final senaryo = File('../docs/17_JURI_DEMO_SENARYOSU.md').readAsStringSync();
    final sozluk = ToxicityLexicon.entries.length;
    final oruntu = ImplicitPatterns.all.length;
    expect(senaryo, contains('$sozluk sözlük girdisi, $oruntu örüntü'),
        reason: 'docs/17 jüriye okunacak sayılar bayat — motorda $sozluk '
            'sözlük girdisi ve $oruntu örüntü var.');
  });
}
