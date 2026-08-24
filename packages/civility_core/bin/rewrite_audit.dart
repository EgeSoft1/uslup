// =============================================================================
// Yeniden Yazma Kalite Denetimi
// Dosya: packages/civility_core/bin/rewrite_audit.dart
//
//     dart run bin/rewrite_audit.dart              → özet + örnekler
//     dart run bin/rewrite_audit.dart --hepsi      → bütün kümeler
//     dart run bin/rewrite_audit.dart --ornek=60   → daha çok örnek
//
// Tespit doğruluğunu `bin/evaluate.dart` ölçer. Bu araç farklı bir soruyu
// sorar: motor bir saldırıyı yakaladığında, ÖNERDİĞİ metin işe yarıyor mu?
//
// ── NEDEN AYRI BİR ÖLÇÜM GEREKİYOR (İP-24) ────────────────────────────────
// Doğrulama kapısı yalnızca toksisiteye bakar. Bu, iki farklı kusuru
// GÖRÜNMEZ kılar ve ikisi de ölçümle bulundu:
//
//   1. KALIP ÇÖKÜŞÜ. Kategori başına tek bir nötr kalıp vardı; 133 saldırı
//      örneğinin büyük çoğunluğu aynı cümleye çöküyordu. Toksisite her
//      seferinde 100 puan alıyordu, yani sayısal kapı "başarılı" diyordu.
//
//        "maymun gibi davranıyorsun"  → "Bu konuda sana katılmıyorum"
//        "domuz herif"                → "Bu konuda sana katılmıyorum"
//        "eşeksin sen"                → "Bu konuda sana katılmıyorum"
//
//      Ürünün vaadi toksisiteyi düşürmek değil, kullanıcının SÖYLEMEK
//      İSTEDİĞİNİ saldırmadan söyletmektir. Beş farklı eleştiriye beş aynı
//      cevap veren bir katman, kullanıcının niyetini siler — ve kullanıcı
//      öneriyi kullanmaz.
//
//   2. BOZUK ÇIKTI. Kelime ikamesi, sıfatın bir kişi benzetmesi içinde
//      olduğu durumlarda dilbilgisini bozuyordu:
//
//        "avanak gibi davrandın" → "Yanlış gibi davrandın"   ✗
//        "sersem misin nesin"    → "Yanlış mısın nesin"       ✗
//
// Bu araç ikisini de sayıya çevirir: çeşitlilik oranı, en sık kalıbın payı
// ve şüpheli dilbilgisi işaretleri.
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';

Future<void> main(List<String> args) async {
  final limit = int.tryParse(_arg(args, '--ornek') ?? '') ?? 24;
  final hepsi = args.contains('--hepsi');

  final engine = LexicalTurkishClassifier();
  final suggester = LocalRewriteSuggester(engine);

  final kumeler = <String, List<GoldCase>>{
    'geliştirme': GoldDataset.cases,
    if (hepsi) 'ayrık': HoldoutDataset.cases,
    if (hepsi) 'İP-15': GeneralizationDataset.cases,
    if (hepsi) 'İP-20': Generalization2Dataset.cases,
    if (hepsi) 'İP-22': Generalization3Dataset.cases,
  };

  var withFindings = 0, produced = 0, none = 0;
  final oneriler = <String>[];
  final samples = <String>[];
  final supheli = <String>[];

  for (final entry in kumeler.entries) {
    for (final testCase in entry.value) {
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
      oneriler.add(suggestion.text);

      final sorun = _dilbilgisiSuphesi(suggestion.text);
      if (sorun != null) {
        supheli.add('  "${testCase.text}"\n'
            '   → "${suggestion.text}"   ⚠ $sorun');
      }

      if (samples.length < limit) {
        samples.add('  "${testCase.text}"\n'
            '   → "${suggestion.text}"  '
            '[${analysis.civilityScore} → ${suggestion.projectedCivilityScore}]');
      }
    }
  }

  // ── Çeşitlilik ───────────────────────────────────────────────────────────
  final sayim = <String, int>{};
  for (final o in oneriler) {
    sayim[o] = (sayim[o] ?? 0) + 1;
  }
  final sirali = sayim.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final benzersiz = sayim.length;
  final cesitlilik = oneriler.isEmpty ? 0.0 : benzersiz / oneriler.length;
  final enSikPay =
      oneriler.isEmpty ? 0.0 : (sirali.isEmpty ? 0 : sirali.first.value) / oneriler.length;

  final out = StringBuffer()
    ..writeln('═' * 78)
    ..writeln('YENİDEN YAZMA KALİTE DENETİMİ')
    ..writeln('═' * 78)
    ..writeln()
    ..writeln('  Küme(ler)                          : ${kumeler.keys.join(", ")}')
    ..writeln('  Müdahale gereken ve bulgu üretilen : $withFindings')
    ..writeln('  Öneri üretilebildi                 : $produced')
    ..writeln('  Öneri ÜRETİLEMEDİ                  : $none')
    ..writeln()
    ..writeln('ÇEŞİTLİLİK')
    ..writeln('  Benzersiz öneri                    : $benzersiz / $produced')
    ..writeln('  Çeşitlilik oranı                   : '
        '%${(cesitlilik * 100).toStringAsFixed(1)}')
    ..writeln('  En sık önerinin payı               : '
        '%${(enSikPay * 100).toStringAsFixed(1)}')
    ..writeln()
    ..writeln('  En sık beş öneri:');

  for (final e in sirali.take(5)) {
    out.writeln('    ${e.value.toString().padLeft(4)}×  "${e.key}"');
  }

  out
    ..writeln()
    ..writeln('DİLBİLGİSİ ŞÜPHESİ  (${supheli.length} çıktı)');
  if (supheli.isEmpty) {
    out.writeln('  Şüpheli kuruluş bulunamadı.');
  } else {
    out.writeln(supheli.take(12).join('\n'));
    if (supheli.length > 12) {
      out.writeln('  … ve ${supheli.length - 12} tane daha');
    }
  }

  out
    ..writeln()
    ..writeln('ÖRNEK ÇIKTILAR  [nezaket puanı: önce → sonra]')
    ..writeln(samples.join('\n'));

  stdout.write(out);

  // Kalıp çöküşü bir GERİLEME göstergesidir: tek bir öneri örneklerin
  // yarısından fazlasını kaplıyorsa katman kullanıcının niyetini siliyor.
  exitCode = (enSikPay > 0.5 || supheli.isNotEmpty) ? 1 : 0;
}

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }
  return null;
}

/// Kelime ikamesinin ürettiği bilinen bozuk kuruluşlar.
///
/// Bunlar dilbilgisi çözümlemesi DEĞİLDİR — ölçümle görülmüş somut hata
/// biçimlerinin sezgisel işaretleridir. Amaç, bir insanın gözle bakmadan
/// önce nereye bakması gerektiğini söylemek.
String? _dilbilgisiSuphesi(String oneri) {
  final t = oneri.toLowerCase();

  // Nötr karşılık bir benzetmenin içine düşmüş: "yanlış gibi davrandın".
  if (RegExp(r'\b(yanlış|yersiz|hatalı)\s+gibi\b').hasMatch(t)) {
    return 'nötr karşılık benzetme içinde';
  }
  // Nötr karşılık soru ekiyle birleşmiş: "yanlış mısın nesin".
  if (RegExp(r'\b(yanlış|yersiz|hatalı)\s+m[iıuü](sin|sın|sun|sün)?\b')
      .hasMatch(t)) {
    return 'nötr karşılık soru kuruluşunda';
  }
  // Kalıp cümle bir kelime yuvasına sokulmuş: "katılmıyorum herif".
  if (RegExp(r'katılmıyorum\s+(herif|adam|sen|siz)\b').hasMatch(t)) {
    return 'kalıp cümle kelime yuvasında';
  }
  // İkame sonrası boşluk bırakmış: "  bir insansın".
  if (t.contains('  ') || t.trimLeft().startsWith('bir insansın')) {
    return 'ikame sonrası boşluk';
  }
  return null;
}
