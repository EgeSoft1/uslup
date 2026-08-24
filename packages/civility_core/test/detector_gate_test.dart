// =============================================================================
// İP-23 · Ön Kapı Eşdeğerlik Testi
// Dosya: packages/civility_core/test/detector_gate_test.dart
//
// ── NE KANITLIYOR ─────────────────────────────────────────────────────────
// `ImplicitDetector`, nefret örüntülerini iki ucuz ön kapıdan geçirir:
//
//   1. KİMLİK KAPISI    — metinde hiç kimlik terimi yoksa on beş örüntü
//                         hiç denenmez.
//   2. DÜŞMANCA SÖZCÜK  — kimlik terimi olsa bile, örüntülerin
//      KAPISI            gerektirdiği sözvarlıklarından hiçbiri yoksa
//                         yine denenmez.
//
// İkisi de yalnızca HIZ içindir. Sonuç kümesini değiştirmeleri bir hatadır
// ve o hata SESSİZDİR: kapı fazla dar olursa gerçek bir nefret söylemi
// kaçar, hiçbir test kırılmaz, hiçbir metrik değişmez — çünkü kaçan örnek
// kümede yoksa kimse fark etmez.
//
// Bu dosya o sessizliği kaldırır: kapılı ve kapısız dedektör, elimizdeki
// BÜTÜN etiketli örneklerde (beş küme, 581 cümle) karşılaştırılır. Tek bir
// bulgu farkı testi kırar.
//
// ── NEDEN BULGULAR, NEDEN SADECE RİSK DEĞİL ───────────────────────────────
// İki motorun aynı risk seviyesini üretmesi yetmez: farklı örüntüler aynı
// seviyeye çıkabilir ve kullanıcıya gösterilen GEREKÇE değişmiş olur.
// Karşılaştırma bulgu kimlikleri üzerinden yapılır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

/// Bir çözümlemenin karşılaştırılabilir parmak izi: risk seviyesi, baskın
/// kategori ve bulgu kimliklerinin sıralı listesi.
String _fingerprint(CivilityAnalysis a) {
  final terms = a.findings.map((f) => f.term).toList()..sort();
  return '${a.risk.name}|${a.dominantCategory?.name ?? "-"}|'
      '${a.toxicity.toStringAsFixed(4)}|${terms.join(",")}';
}

void main() {
  // Üründeki motor — kapılar açık.
  final gated = LexicalTurkishClassifier();

  // Referans motor — kapılar kapalı, her örüntü her cümlede çalışır.
  final ungated = LexicalTurkishClassifier(
    implicitDetector: ImplicitDetector(fastGate: false),
  );

  final corpora = <String, List<GoldCase>>{
    'gelistirme': GoldDataset.cases,
    'ayrik': HoldoutDataset.cases,
    'ip15': GeneralizationDataset.cases,
    'ip20': Generalization2Dataset.cases,
    'ip22': Generalization3Dataset.cases,
  };

  group('1. Ön kapılar sonucu değiştirmiyor — etiketli kümelerin tamamı', () {
    corpora.forEach((ad, cases) {
      test('$ad kümesi (${cases.length} örnek) birebir aynı', () {
        final farklar = <String>[];

        for (final c in cases) {
          final a = _fingerprint(gated.analyze(c.text));
          final b = _fingerprint(ungated.analyze(c.text));
          if (a != b) {
            farklar.add('"${c.text}"\n    kapılı : $a\n    kapısız: $b');
          }
        }

        expect(farklar, isEmpty,
            reason: 'Ön kapı bir bulguyu yuttu ya da uydurdu. Kapı yalnızca '
                'hızlandırma olmalıdır:\n${farklar.join("\n")}');
      });
    });
  });

  group('2. Kapıların açıkça sınandığı sınır durumları', () {
    // Bu grup, kümelerde tesadüfen bulunmayan durumları doğrudan sınar.
    const kritik = <String>[
      // Kimlik VAR, düşmanca sözcük VAR → her iki kapı da açılmalı
      'Bütün Suriyeliler hırsızdır',
      'Kürtler defolsun',
      'Eşcinseller hastalıklı',
      'engelliler topluma yük',
      'Ermeniler yalancıdır zaten',
      'sen zaten Ermenisin',
      'Ermeniden başka ne beklenir',
      'bu Romanlarla aynı mahallede yaşanmaz',
      // Kimlik VAR, düşmanca sözcük YOK → ikinci kapı kapalı kalmalı
      'Suriyeli komşumuz çok yardımsever',
      'Alevi kültürü üzerine tez yazıyorum',
      'Ben Kürtüm',
      'Kürtçe kursuna kaydoldum',
      // Kimlik YOK, düşmanca sözcük VAR → birinci kapı kapalı kalmalı
      'bu yemek çok pis olmuş',
      'hırsızlık olayı aydınlatıldı',
      'bütün öğrenciler sınava girecek',
      // Gönderge — kimlik önceki cümlede
      'Suriyeliler her yeri doldurdu. Bunların soyunu kurutmak lazım',
      'bunların soyunu kurutmak lazım',
      // İkisi de yok
      'yarın buluşalım mı',
    ];

    for (final text in kritik) {
      test('"$text"', () {
        expect(_fingerprint(gated.analyze(text)),
            _fingerprint(ungated.analyze(text)));
      });
    }
  });

  group('3. Yapısal değişmez — kapının dayandığı adlandırma kuralı', () {
    test('her nefret örüntüsünün kimliği "nefret." ile başlar', () {
      // Kapı bu önek üzerinden çalışır. Başka bir önekle eklenen bir nefret
      // örüntüsü kapının DIŞINDA kalır: yanlış sonuç üretmez ama her cümlede
      // gereksiz yere çalışır ve optimizasyonun tamamını görünmez biçimde
      // etkisizleştirebilir.
      for (final pattern in HatePatterns.all) {
        expect(pattern.id.startsWith(HatePatterns.idPrefix), isTrue,
            reason: '"${pattern.id}" öneki tutmuyor. Ya kimliği düzeltin ya '
                'da kapıyı bu örüntüyü kapsayacak biçimde genişletin.');
      }
    });

    test('düşmanca sözcük kapısı, örüntülerin sözvarlığını kapsıyor', () {
      // Kapı bir BİRLEŞİM olmak zorundadır. Her ailenin en az bir temsilci
      // cümlesi kapıdan geçmelidir; geçmiyorsa kapı daralmış demektir.
      const temsilciler = <String, String>{
        'insanlıktan çıkarma': 'Suriyeliler hayvandır',
        'varlık reddi': 'Yahudiler yok edilmeli',
        'dışlama': 'Kürtler defolsun',
        'dışlama (gereklilik)': 'Kürtler bu ülkeden gitmeli',
        'toplu suçlama': 'Bütün Suriyeliler hırsızdır',
        'kimlik aşağılama': 'Aleviler aşağılıktır',
        'kimlik yaftalama': 'sen zaten Ermenisin',
        'ne beklenir': 'Ermeniden başka ne beklenir',
        'yük söylemi': 'engelliler topluma yük',
        'dolaylı dışlama': 'bu Araplarla aynı binada oturulmaz',
      };

      // Kapı NORMALİZE metin üzerinde çalışır ("aşağılıktır" → "asagiliktir").
      // Ham metinle sınamak yanlış sonuç verir; normalleştirici burada da
      // aynısı olmalıdır.
      const normalizer = TurkishNormalizer();

      temsilciler.forEach((aile, cumle) {
        final normalize = normalizer.normalize(cumle).value;
        expect(HatePatterns.hostileGate.hasMatch(normalize), isTrue,
            reason: '"$aile" ailesinin temsilcisi kapıdan geçemiyor. '
                'Kapı daralmış: bu ailenin bütün bulguları sessizce kaybolur.');
      });
    });
  });
}
