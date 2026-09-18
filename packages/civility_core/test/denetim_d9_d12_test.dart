// =============================================================================
// Kod denetimi düzeltmeleri — D9 · D10 · D11 · D12
// Dosya: packages/civility_core/test/denetim_d9_d12_test.dart
//
// 13 Eylül 2026 kod denetiminde bulunan hataların regresyon kilitleri.
// Kayıt ve gerekçeler: docs/23_KOD_DENETIMI.md
//
//   D9  · bağlam ve nefret yapısı — kesme işareti tırnak sayılıyordu, e-posta
//         içindeki "@" bahsetme sayılıyordu, aksan katlaması ünlü uyumu
//         sınıfını siliyordu, kimlik adı niteleyen tamlama nefret sayılıyordu
//   D10 · "kendimi öldüreceğim" tehdit sayılıp suç uyarısı açıyordu
//   D11 · geçmiş zaman ve adlarda yanlış alarm veren örüntü/sözlük girdileri
//   D12 · kapı kelimesiyle çelişen ölü dallar ve yinelenen örüntü kimlikleri
//
// Her grup iki yönlü yazılmıştır: düzeltilen cümle ARTIK doğru sonuç verir,
// ve düzeltmenin daraltmadığı saldırgan kuruluş hâlâ yakalanır.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:civility_core/src/detect/idiom_patterns.dart';
import 'package:civility_core/src/detect/literal_prefilter.dart';
import 'package:test/test.dart';

/// İfadenin en üst düzeyinde (parantez dışında) `|` var mı?
bool _ustDuzeyAlmasik(String kaynak) {
  var derinlik = 0;
  for (var i = 0; i < kaynak.length; i++) {
    final c = kaynak[i];
    if (c == r'\') {
      i++;
      continue;
    }
    if (c == '(') derinlik++;
    if (c == ')') derinlik--;
    if (c == '|' && derinlik == 0) return true;
  }
  return false;
}

void main() {
  final engine = LexicalTurkishClassifier();
  bool flags(String text) => engine.analyze(text).risk != RiskLevel.temiz;

  void temiz(List<String> cumleler) {
    for (final c in cumleler) {
      test('temiz · "$c"', () {
        final a = engine.analyze(c);
        expect(a.risk, RiskLevel.temiz,
            reason: 'Masum cümle işaretlendi: '
                '${a.findings.map((f) => f.term).join(", ")}');
      });
    }
  }

  void yakalanir(List<String> cumleler) {
    for (final c in cumleler) {
      test('yakalanır · "$c"', () {
        expect(flags(c), isTrue, reason: 'Saldırgan kuruluş kaçtı.');
      });
    }
  }

  group('D9.1 · Kesme işareti tırnak değildir', () {
    yakalanir(const [
      "Ali'ye söyle sen şerefsizsin Veli'ye de",
      "Ahmet'e dedim ki sen tam bir aptalsın, Ayşe'ye de söyledim",
    ]);
    // Gerçek tırnak hâlâ aktarımı yumuşatır.
    temiz(const [
      "bana 'aptal' dedi",
      'Selin\'e "senin gibilerden bu beklenirdi" demişler, çok ayıp',
    ]);
  });

  group('D9.2 · E-posta adresindeki @ bahsetme değildir', () {
    temiz(const ['ali@ornek.com adresine köpek fotoğrafı attım']);
    yakalanir(const ['@ali köpek', 'bak @ayse tam bir domuz']);
  });

  group('D9.3 · Ünlü uyumu kökün Türkçe yazılışından okunur', () {
    yakalanir(const [
      'gerizekalılar',
      'siz zavallılarsınız',
      'sürtükler',
      'kafasızlar hepiniz',
    ]);

    test('ince ünlülü kök kalın eki hâlâ reddeder', () {
      expect(
          TurkishMorphology.isValidInflectedForm('serefsizlar', 'serefsiz',
              stemSpelling: 'şerefsiz'),
          isFalse);
    });

    test('yazım verilmezse eski davranış korunur', () {
      expect(TurkishMorphology.isValidInflectedForm('aptallar', 'aptal'),
          isTrue);
      expect(TurkishMorphology.isValidInflectedForm('aptaller', 'aptal'),
          isFalse);
    });
  });

  group('D9.4 · Kimlik adı niteleyen tamlama nefret söylemi değildir', () {
    temiz(const [
      'Kadınlar tuvaleti çok kirli',
      'Engelliler rampası bozuk',
      'Erkekler soyunma odası pis',
      'Yaşlılar parkı çok kirli',
      'Kadınlar tuvaleti temizlenmeli',
    ]);
    yakalanir(const [
      'Bütün Suriyeliler hırsızdır',
      'Ermeniler hep aynı, güvenilmez',
      'bu Romanlarla aynı mahallede yaşanmaz',
      'Ermeniler kanı bozuk',
      'Kürtlerin kafası bozuk',
    ]);
  });

  group('D9.5 · Kimlik yaftalamada yuvarlak ünlülü çekim', () {
    yakalanir(const ['sen zaten Uygursun', 'siz Hindusunuz zaten']);
    temiz(const ['Ben Kürtüm', 'sen de Ermeni misin, ben de']);
  });

  group('D10 · Kendine yönelik tehdit fiili tehdit değildir', () {
    for (final c in const [
      'Kendimi öldüreceğim',
      'kendimi gerçekten öldüreceğim',
      'intihar etmek istiyorum',
      'yaşamak istemiyorum',
    ]) {
      test('destek, uyarı yok · "$c"', () {
        final a = engine.analyze(c);
        expect(a.containsThreat, isFalse);
        expect(a.risk, RiskLevel.temiz);
        expect(a.needsSupport, isTrue);
      });
    }

    test('başkası da nesneyse tehdit sürer', () {
      final a = engine.analyze('Seni ve kendimi öldüreceğim');
      expect(a.containsThreat, isTrue);
    });

    test('dönüşlü nesne olmayan tehdit değişmez', () {
      expect(engine.analyze('seni öldüreceğim').containsThreat, isTrue);
      expect(engine.analyze('Seni kendim öldüreceğim').containsThreat, isTrue);
    });
  });

  group('D11 · Geçmiş zaman ve somut adlarda yanlış alarm', () {
    temiz(const [
      'Banka müdürüne kredi kartı hesabını sordum',
      'Annem torununun düğün gününü gördü',
      'Barajlardaki su normal seviyesine indi',
      'Vücudun ihtiyacı olan vitaminleri almalısın',
      'Sana yatağa gitmeden önce yazarım',
      'Yeni maskaramı denedim, çok güzel',
      'Ciltte kaşınma ve kızarıklık var',
      'Anadolu kuzu tandır yedik',
      'Çorbaya ekmek doğradım',
      'Diş hekimi çürük dişini söktü',
      'Tırnağı olmayan kediler',
      'Bu güzelliği anlatmaya kelime yetmez',
      'Kırk yılda bir yemek yaptık',
      'Bu mantıkla bu iş yürümez',
    ]);
    yakalanir(const [
      'hesabını sorarım',
      'hesabını soracağım senden',
      'gününü göreceksin',
      'gününü görürsün',
      'seviyene inmeyeceğim',
      'onun seviyesine inmem',
      'iki liralık adam',
      'maskara oldun',
      'sen daha anasının kuzususun',
      'kanına ekmek doğrarım',
      'dişlerini dökerim',
      'sen benim tırnağım bile olamazsın',
      'seni anlatmaya kalem yetmez',
      'kırk yılda bir doğru söyledin',
      'benimle yatağa gel',
    ]);
  });

  group('docs/24 · 11–12 · Normalleştirici gizleme açıkları', () {
    yakalanir(const [
      'sen aptAaAlsın', // büyük/küçük karışık tekrar
      'a🫠p🫠t🫠a🫠l', // yeni emoji bloğu
      'şerefsiz⭐sin', // yıldız sembolü
      'sen salak🇹🇷sın', // bayrak harfleri
    ]);
    temiz(const [
      'Harika bir gün ⭐⭐⭐',
      'Tatile 🇹🇷 gidiyoruz',
      'Elli kere söyledim',
      'DİKKAT edin',
    ]);

    test('indeks haritası emoji ve karışık tekrarda bozulmaz', () {
      const metin = 'sen aptAaAlsın';
      final a = engine.analyze(metin);
      final f = a.findings.single;
      expect(metin.substring(f.start, f.end), 'aptAaAlsın');
    });
  });

  group('docs/24 · 10 · Noktalamayla bitişen kelimeler', () {
    yakalanir(const [
      'Harika,salaksın',
      'tamam,aptalsın sen',
      'Bence yanlış,şerefsizsin',
      // harf harf gizleme hâlâ çözülür
      'a,p,t,a,l',
      's/i/k/t/i/r',
      'ap-tal mısın',
      'şeref.siz',
    ]);
    temiz(const ['Tamam,ama bence yanlış', 've/veya bir seçim']);
  });

  group('docs/24 · 13 · Bağlam penceresi cümle sınırında durur', () {
    yakalanir(const [
      'Yarın gelmiyorum. Aptal herif', // önceki cümlenin olumsuz fiili
      'Ne dedin? Aptal mısın', // önceki cümlenin aktarma fiili
    ]);
    temiz(const [
      'Bana aptal dedi, çok üzüldüm',
      'Bana "aptal" dedi. Çok üzüldüm',
      'Seni sevmiyorum. Aptal değilsin ama',
    ]);
  });

  group('docs/24 · 15 · Somut ad konu ya da tamlama niteleyicisiyse', () {
    temiz(const [
      'Sen maymunlar hakkında ödev hazırlıyordun',
      'Sen sülük tedavisine inanıyor musun?',
      'Sen hayvan haklarını savunuyorsun',
    ]);
    yakalanir(const [
      'sen tam bir öküz herifsin',
      'sen domuz yavrususun',
      'köpek misin sen',
      'seni gidi domuz seni',
      'maymun gibi davranıyorsun',
    ]);
  });

  group('D12 · Kapı kelimesi ve örüntü kimlikleri', () {
    // Önceden kapı kelimesi bu dalları hiç denetmiyordu.
    yakalanir(const [
      'bu akılla bir yere varamazsın',
      'bu zihniyetle hiçbir şey başaramazsın',
      'haddini bildireceğim',
    ]);

    test('kapılı ve kapısız dedektör denetim cümlelerinde aynı', () {
      final ungated = LexicalTurkishClassifier(
        implicitDetector: ImplicitDetector(fastGate: false),
      );
      const cumleler = [
        'bu akılla bir yere varamazsın',
        'bu kafanla bir yere varamazsın',
        'haddini bildireceğim',
        'dişlerini dökerim',
        'Kadınlar tuvaleti çok kirli',
        'Kendimi öldüreceğim',
      ];
      for (final c in cumleler) {
        final a = engine.analyze(c);
        final b = ungated.analyze(c);
        expect(a.findings.map((f) => f.term).toList(),
            b.findings.map((f) => f.term).toList(),
            reason: '"$c" kapılı/kapısız farklı');
        expect(a.needsSupport, b.needsSupport);
      }
    });

    test('her deyimin kapı kelimesi bütün almaşıklarda zorunlu (docs/24 · 17)',
        () {
      // Kapı kelimesi metinde yoksa deyim hiç denenmez. Bir almaşık kapıyı
      // içermiyorsa o dal SESSİZCE ölüdür — D12'de altı örüntüde böyleydi ve
      // hiçbir test kırılmamıştı, çünkü etiketli kümelerde o dallara düşen
      // cümle yoktu. Kural: kapı ya ifadenin her zorunlu parçasında geçer ya
      // da ifadenin almaşıksız zorunlu ön ekidir.
      final ihlal = <String>[];
      for (final p in IdiomPatterns.all) {
        final kapi = p.gateWord;
        if (kapi == null) continue;

        final kaynak = p.pattern.pattern;
        final onEk = kaynak.replaceFirst(RegExp(r'^\\b'), '');
        if (!_ustDuzeyAlmasik(kaynak) && onEk.startsWith(kapi)) continue;

        final parcalar = LiteralPrefilter.requiredAnyOf(p.pattern);
        if (parcalar != null && parcalar.every((s) => s.contains(kapi))) {
          continue;
        }
        ihlal.add('${p.id}: kapı "$kapi", zorunlu parçalar $parcalar');
      }
      expect(ihlal, isEmpty,
          reason: 'Kapı kelimesi bazı dalları hiç denetmiyor:\n'
              '${ihlal.join("\n")}\n'
              'Kapıyı düzeltin ya da `gate: null` verin (değişmez parça ön '
              'filtresi hızı yine korur).');
    });

    test('örüntü kimlikleri benzersiz', () {
      final seen = <String>{};
      final dup = <String>[];
      for (final p in ImplicitPatterns.all) {
        if (!seen.add(p.id)) dup.add(p.id);
      }
      expect(dup, isEmpty,
          reason: 'Yinelenen kimlikler: $dup — şeffaflık paneli ve testler '
              'örüntüyü kimliğiyle anar.');
    });

    test('örüntüler normalize metinde bulunmayan harf içermez', () {
      // Normalize metinde ı ğ ş ç ö ü yoktur; bu harfleri taşıyan bir almaşık
      // hiçbir zaman eşleşemez (D11: "liralık").
      final ihlal = <String>[
        for (final p in ImplicitPatterns.all)
          if (RegExp('[ığşçöüİĞŞÇÖÜ]').hasMatch(p.pattern.pattern)) p.id,
      ];
      expect(ihlal, isEmpty);
    });
  });
}
