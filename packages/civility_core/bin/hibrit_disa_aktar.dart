// =============================================================================
// Melez katman ölçümü için motor çıktısını dışa aktarır (docs/24 · madde 22)
// Dosya: packages/civility_core/bin/hibrit_disa_aktar.dart
//
//     dart run bin/hibrit_disa_aktar.dart > ../../ml/motor_ciktisi.json
//     python ml/04_paket_modeli_olc.py
//
// Uygulamaya paketlenen ONNX modeli (`mobile/assets/models/uslup_model.onnx`)
// README'de ölçülen karakter n-gram modeli DEĞİLDİR ve hiç ölçülmemişti.
// Melez sözleşme modelin yalnızca kural motorunun ZATEN işaretlediği bir
// metnin basamağını yükseltmesine izin verir; ama basamak da ürün davranışıdır
// (Yüksek risk gönderimde onay diyaloğu açar). Bu araç, Python tarafının
// modeli aynı sözleşmeyle çalıştırıp etkisini sayabilmesi için motorun her
// etiketli cümledeki kararını yazar.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:civility_core/civility_core.dart';

void main(List<String> args) {
  final engine = LexicalTurkishClassifier();
  final kumeler = <String, List<GoldCase>>{
    'gelistirme': GoldDataset.cases,
    'ayrik': HoldoutDataset.cases,
    'ip15': GeneralizationDataset.cases,
    'ip20': Generalization2Dataset.cases,
    'ip22': Generalization3Dataset.cases,
    'ip27': Generalization4Dataset.cases,
    'ip29': Generalization5Dataset.cases,
    'ip30': EverydayDataset.cases,
    'ip31': DirectionDataset.cases,
    'ip32': StanceDataset.cases,
  };

  final satirlar = [
    for (final e in kumeler.entries)
      for (final c in e.value)
        if (engine.analyze(c.text) case final a)
          {
            'kume': e.key,
            'text': c.text,
            'label': c.shouldFlag ? 1 : 0,
            'group': c.group.name,
            'toxicity': a.toxicity,
            'risk': a.risk.name,
          },
  ];
  final json = const JsonEncoder.withIndent(' ').convert(satirlar);
  // Dosya yolu verilirse doğrudan yazılır: kabuk yönlendirmesi (özellikle
  // Windows PowerShell) kodlamayı değiştirip BOM ekleyebiliyor.
  if (args.isNotEmpty) {
    File(args.first).writeAsStringSync(json);
    stderr.writeln('${satirlar.length} satır → ${args.first}');
  } else {
    stdout.write(json);
  }
}
