// =============================================================================
// docs/32 · Harf İkilemesi ve Söz Varlığı Genişletmesi
// Dosya: packages/civility_core/test/ikileme_test.dart
//
// ── NEDEN BU DOSYA VAR ────────────────────────────────────────────────────
// 19 Eylül 2026'da telefonda bildirilen cümle: "sikerriimmo" → Temiz.
// Normalizasyon 3+ tekrarı daraltıyor, `_dedouble` ünlü ikilisini ve kelime
// SONUNDAKİ ünsüz ikilisini indiriyordu; kelime içindeki ünsüz ikilisi
// ("rr", "zz", "kk") ve ikiliden sonra düşen tek harf ("…mm-o") kaçıyordu.
// Sözlükteki kök girdilerinden üretilen 3.636 ikileme varyantının yalnızca
// %34,4'ü yakalanıyordu.
//
// Dosya iki yönlü çalışır ve ikinci grup birinciden DAHA önemlidir: kelime
// içi ikili Türkçenin olağan yapısıdır ("yıllanmış", "elli", "dikkat") ve
// bu yolun gerekçesi ("yıllanma" → "yılanma") hâlâ geçerlidir.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  late LexicalTurkishClassifier engine;
  setUp(() => engine = LexicalTurkishClassifier());

  void caught(String title, List<String> texts) {
    group(title, () {
      for (final text in texts) {
        test('"$text" işaretlenir', () {
          final a = engine.analyze(text);
          expect(a.risk, isNot(RiskLevel.temiz),
              reason: 'Bu biçim 19 Eylül 2026 taramasında temiz dönüyordu.');
        });
      }
    });
  }

  void clean(String title, List<String> texts) {
    group(title, () {
      for (final text in texts) {
        test('"$text" temiz kalır', () {
          final a = engine.analyze(text);
          expect(a.risk, RiskLevel.temiz,
              reason: 'YANLIŞ POZİTİF: ${a.findings.map((f) => f.term).toList()}');
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  caught('1. Bildirilen cümle', const [
    'sikerriimmo',
    'SİKERRİİMMO',
    'Sikerriimmo',
    'seni sikerriimm',
    'sikerimmo',
  ]);

  caught('2. Kelime içi ünsüz ikilisi', const [
    'şerrefsiz',
    'orrospu çocuğu',
    'pezzevenk',
    'yavvşak',
    'gerizekkalı mısın',
    'göttveren',
    'kahhpe',
    'sikttir git',
    'amınnakoyim',
    'sikkerim',
    'ananı sikkerim',
    'sikkeyim',
  ]);

  caught('3. Kelime başında ikili', const [
    'ssalak',
    'aapptal',
    'ssikerim',
    'ananı ssikim',
  ]);

  caught('4. Yazılışında ikili olan girdinin uzatılması', const [
    'namusssuz',
    'zavalllı herif',
    'sikkko',
    'yarrram',
    'dalllama',
  ]);

  caught('5. Kısa kök — Türkçe harf fiilen yazılmışsa', const [
    'piiç',
    'piçç kurusu',
  ]);

  test('ikileme kararı özgün aralığı vurgular', () {
    final a = engine.analyze('sen şerrefsizsin');
    expect(a.findings, isNotEmpty);
    expect(a.findings.first.term, 'şerefsiz');
    expect(a.findings.first.matchedText, 'şerrefsizsin');
  });

  // ═══════════════════════════════════════════════════════════════════════════
  caught('6. Söz varlığı genişletmesi', const [
    'kevaşe',
    'sen tam bir enayisin',
    'sen kaşarsın',
    'sen tam bir angutsun',
    'kancık herif',
    'sen boynuzlusun',
    'seni bıçaklarım',
    'ağzını burnunu kırarım',
    'allahın belası herif',
    'sik kafalı',
    'sen ne sapıksın',
    'ucube misin',
    'hanzo musun',
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  clean('7. Bedel ödenmedi — gerçek ikili harf gizleme değildir', const [
    // Kelime listesi taramasında bu yolun ilk sürümünü yakalayanlar
    'yıllanmış bir şarap',
    'sen yıllanma',
    'şallak',
    'Şiilik',
    // Olağan ikililer
    'elli kişi geldi',
    'anneciğim geldi',
    'dikkat et',
    'hatta öyle',
    'sallama beni',
    'mall',
    'millet meclisi',
    'affet beni',
    // "sikke" maskesi daraltıldı; para anlamı korunuyor
    'sikke koleksiyonum var',
    'sikkeleri sattım',
    'bu sikkeyi nereden buldun',
    'sikkeci dükkanı',
  ]);

  clean('8. Bedel ödenmedi — yeni girdilerin gündelik anlamı', const [
    'kaşar peyniri aldım',
    'kaşarlı tost yaptım',
    'kasara çıktı tayfa',
    'angut kuşu gördük gölde',
    'sümsük kuşu denize daldı',
    'kancık köpek yavruladı',
    'boynuzlu geyik ormanda',
    'bıçaklarım çok keskin',
    'bıçaklarımı biledim',
    'sapık bir adam takip etti beni',
    'enayi yerine koydular beni',
    // Alınmayan girdi: öbek sağ sınır denetlemez, öz-ifade susturulurdu
    'sınavda bok yedim yine',
    // Alınmayan girdi: dizi adı
    'Stargate SG-1',
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  group('9. Kapsam değişmezi — tek harf ikilemesi', () {
    // Yönelim şartı olmayan her küfür/hakaret kök girdisinin her harfi tek
    // tek ikilendiğinde yakalanır. Alışılmış bir harf dizisi olmayan ünsüz
    // iskeletleri ("yrrk", "sixiym") ve kendi içinde ikili taşıyan "eşşoğlu"
    // bu iddianın dışındadır — docs/32 §4'te kayıtlı.
    const disari = {'yrrk', 'sixiym', 'eşşoğlu'};
    test('her ikileme varyantı işaretlenir', () {
      final kacak = <String>[];
      for (final e in ToxicityLexicon.entries) {
        if (e.requiresDirection || e.term.contains(' ')) continue;
        if (e.category != ToxicityCategory.kufur &&
            e.category != ToxicityCategory.hakaret) {
          continue;
        }
        final t = e.term.toLowerCase();
        if (t.length < 4 || disari.contains(t)) continue;
        for (var i = 0; i < t.length; i++) {
          final v = '${t.substring(0, i + 1)}${t[i]}${t.substring(i + 1)}';
          if (engine.analyze(v).risk == RiskLevel.temiz) kacak.add(v);
        }
      }
      expect(kacak, isEmpty, reason: 'Kaçan ikileme varyantları: $kacak');
    });
  });
}
