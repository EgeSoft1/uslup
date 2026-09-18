// =============================================================================
// docs/25 · Küfür Kapsamı — Bitişik, Çekimli ve Gizlenmiş Yazım
// Dosya: packages/civility_core/test/kufur_kapsami_test.dart
//
// ── NEDEN BU DOSYA VAR ────────────────────────────────────────────────────
// 14 Eylül 2026'daki 286 cümlelik çekişmeli taramada 111 küfür/hakaret
// biçimi TEMİZ dönüyordu. En ağır olanlar dahil:
//
//   "sikerim" · "SİKERİM" · "s i k e r i m"  → öz-ifade sayılıp siliniyordu
//   "senisikerim" · "siktirgit" · "piçkurusu" → bitişik yazım
//   "salakmısın" · "gerizekalımısın"          → bitişik soru eki
//   "amına koydum" · "amına koyarım"          → öbek çekimi
//   "amkk" · "s*kerim" · "s!kerim"            → gizleme
//
// Aynı taramada iki masum cümle Yüksek risk alıyordu: "ananın yemekleri çok
// güzel", "kuş bu dala kondu".
//
// Bu dosya iki yönlü çalışır. İkinci grup birinciden DAHA önemlidir: her
// yeni yol, 91.861 biçimlik kelime listesinde ve aşağıdaki masum cümlelerde
// yeni bir yanlış alarm üretmediği gösterilerek eklendi.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  late LexicalTurkishClassifier engine;
  setUp(() => engine = LexicalTurkishClassifier());

  bool flags(String text) => engine.analyze(text).risk != RiskLevel.temiz;

  void caught(String title, List<String> texts) {
    group(title, () {
      for (final text in texts) {
        test('"$text" işaretlenir', () {
          final a = engine.analyze(text);
          expect(a.risk, isNot(RiskLevel.temiz),
              reason: 'Bu biçim 14 Eylül 2026 taramasında temiz dönüyordu.');
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  caught('1. Ağır küfür öz-ifade sayılmaz', const [
    'sikerim',
    'sikeyim',
    'SİKERİM',
    'SIKERIM',
    's i k e r i m',
    'bacını sikerim',
    'sülaleni sikerim',
    'yarrağım',
    'amk ben yoruldum',
    'sikimde değil',
  ]);

  test('ağır küfür Yüksek risk alır', () {
    expect(engine.analyze('sikerim').risk, RiskLevel.yuksek);
    expect(engine.analyze('amk ben yoruldum').risk, RiskLevel.yuksek);
  });

  caught('2. Bitişik yazım', const [
    'senisikerim',
    'sikerimseni',
    'sikerimlan',
    'ananısikerim',
    'ağzınısikerim',
    'siktirgit',
    'piçkurusu',
    'yarrakkafa',
    'salakherif',
    'aptalherif',
    'siktiriboktan',
    'amınakoydum',
    'amınakoyarım',
    'orospuçocuğu',
    'götünesokarım',
    'itoğluit',
  ]);

  caught('3. Bitişik soru eki', const [
    'salakmısın',
    'salakmisin',
    'aptalmısın',
    'gerizekalımısın',
    'şerefsizmisin',
    'embesilmisin',
    'malmısın',
  ]);

  caught('4. Öbek ve nesne + fiil çekimleri', const [
    'amına koyarım',
    'amına koydum',
    'amına kodum',
    'amına koyacağım',
    'amınıza koyayım',
    'ananı siktim',
    'götüne sokarım',
    'ağzına sıçtı',
    'ulan bacını',
    'ananı',
  ]);

  caught('4b. "amına koy-" kısaltmaları (ekran görüntüsüyle bildirildi)', const [
    'Senin ben amkoyayim',
    'senin ben amkoyayım',
    'AMKOYAYIM',
    'amkoyim',
    'amkoydum',
    'amkoyarım',
    'amkoyucam',
    'amkoyduğum',
    'amkoyayımm',
    'am koyayım',
    'am koydum',
    'amna koyayım',
    'amnakoyim',
    'amnkoyayım',
    'amınakoyduğum',
    'ananıskm',
    'ananısikim',
    'annenisikerim',
    'senin ben ananı',
    'skerim',
  ]);

  caught('5. Gizleme', const [
    'amkk',
    'aqq',
    'salakk',
    'aptaal',
    's!kerim',
    's*kerim',
    'g*t herif',
    'p*ç',
    'eşşek herif',
    'dalyarrak',
  ]);

  caught('6. Söz varlığı', const [
    'sikiyim',
    'sikicem seni',
    'sikeceğim seni',
    'sikim',
    'siktim seni',
    'sikko',
    'hasiktir',
    'sikişelim mi',
    'kahbe',
    'oruspu',
    'orospunun',
    'kavat',
    'pezo',
    'götlek',
    'deyyus',
    'dürzü',
    'şırfıntı',
    'kerhaneci',
    'fahişenin çocuğu',
    'sıçarım',
    'sıçtın',
    'skm',
    's2m',
    'orsp',
    'amına',
    'amın oğlu',
    'it oğlu it',
    'köpek oğlu köpek',
    'geber',
    'geberesice',
    'kahrolasıca',
    'lanet olası',
    'belanı versin',
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  group('7. Bedel ödenmedi — masum metin temiz kalır', () {
    const innocent = <String>[
      // "sık-" ailesi: normalize metinde "sik-" ile aynı dizgi
      'canım çok sıkıldı',
      'canim cok sikildi',
      'sıkıntı yok',
      'sikinti yok',
      'bu film çok sıkıcı',
      'limonu sıktım',
      'limonu siktim',
      'trafik sıkıştı',
      'canımı sıktı bu iş',
      'canimi siktin ya',
      'seni sıktım mı',
      'kafanı sıkma boşver',
      'ağzını sıkı tut',
      // Nesne + fiil yolunun tuzakları
      'ağzına sıcak çorba koyma',
      'anahtarı kapıya sokarım',
      'ananın yemekleri çok güzel',
      'ananı özledin mi',
      'ananın amiri geldi',
      'bacını selamla',
      // "am + koy-" kök eşleşmesinin ve "anneni" nesnesinin tuzakları
      'senin ben de arkadaşınım',
      'kalem koyayım masaya',
      'şuraya koyayım mı',
      'Mina koyuldu yola',
      'imam koydu',
      'adam koydu',
      'bu parayı hesaba koydum',
      'anneni özledim',
      'annenin yemekleri güzel',
      'anneni sıktım mı',
      'anneni siktim mi hiç',
      // Alt dizgi çakışmaları
      'şekerim nasılsın',
      'sekerim nasilsin',
      'adamına söyle',
      'adamina soyle',
      'yarım yamalak bir iş',
      'yıllanmış bir şarap',
      'Gavuroğlu ailesi geldi',
      'pico de gallo sosu',
      // "am" kökü: ASCII ikizleri
      'amin oğlum amin',
      'amina gitti',
      'Amine Hanım geldi',
      // Komşu token birleştirmesi
      'kuş bu dala kondu',
      'bu dala bak',
      // Öz-ifade ve hafif argo — yumuşatma korunuyor
      'geberdim sıcaktan',
      'sıcaktan gebereceğim',
      'kahrolsun zulüm',
      'götüm donuyor',
      // Yıldız başka bir şey için
      '3*5 kaç eder',
      '*önemli* not',
      '5*5=25',
    ];

    for (final text in innocent) {
      test('"$text" temiz kalır', () {
        final a = engine.analyze(text);
        expect(a.risk, RiskLevel.temiz,
            reason: 'YANLIŞ POZİTİF: ${a.findings.map((f) => f.term).toList()}');
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('8. Bağlam korunuyor — ağır küfürde de mağdur susturulmaz', () {
    // Öz-yönelim ve olumsuzlama müstehcen küfrü artık yumuşatmıyor; ALINTI
    // ve AKTARIM ise yumuşatmaya devam etmeli. Tacize uğrayanın anlatısı
    // ürünün var olma sebebidir.
    for (final text in const [
      'bana "amına koyayım" diye bağırdı',
      'bana sikerim dedi çok üzüldüm',
    ]) {
      test('"$text" temiz kalır', () {
        expect(flags(text), isFalse);
      });
    }

    test('hakarette olumsuzlama çalışmaya devam eder', () {
      expect(flags('sen hiç aptal değilsin'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('9. Yapısal güvence', () {
    const normalizer = TurkishNormalizer();

    test('yapıştırıcı kelimelerin hiçbiri tek başına bir bulgu üretmez', () {
      // Yapıştırıcı bir sözlük girdisiyle eşleşseydi "girdi + yapıştırıcı"
      // kuralı iki girdiyi birleştiren kısıtsız bir kurala dönüşürdü.
      for (final glue in ToxicityLexicon.compoundGlue) {
        if (glue == 'amk') continue; // kasıtlı: kısaltma hem girdi hem ünlem
        expect(engine.analyze(glue).hasFindings, isFalse, reason: glue);
      }
    });

    test('yapıştırıcı listesinde soyadı eki yok', () {
      expect(ToxicityLexicon.compoundGlue, isNot(contains('oğlu')),
          reason: '"Gavuroğlu" → gavur + oğlu. Gerekçe: compoundGlue.');
    });

    test('birleştirme durak kelimeleri normalize yazılmıştır', () {
      // Motor bu listeyi token metniyle (normalize) doğrudan karşılaştırır.
      for (final word in ToxicityLexicon.joinStopWords) {
        expect(normalizer.normalize(word).value, word, reason: word);
      }
    });

    test('nesne + fiil listelerindeki fiiller tek başına küfür değilse '
        'yalnızca nesneyle yakalanır', () {
      expect(flags('limonu siktim'), isFalse);
      expect(flags('ananı siktim'), isTrue);
      expect(flags('anahtarı sokarım'), isFalse);
      expect(flags('götüne sokarım'), isTrue);
    });
  });
}

