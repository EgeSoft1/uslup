// =============================================================================
// Kullanıcı Ayarları ve Müdahale Politikası — Test Paketi (docs/27)
// Dosya: packages/civility_core/test/uslup_ayarlari_test.dart
//
// Üç iddia sınanır:
//   1. Varsayılan ayar ölçülen davranışın AYNISIDIR — raporlanan hiçbir sayı
//      ayar yüzünden geçersizleşmez.
//   2. Başkalarını koruyan uyarılar tek tek susturulamaz.
//   3. Her ayar, kullanıcıya söylediği şeyi yapar.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  final engine = LexicalTurkishClassifier();
  CivilityAnalysis uygula(String metin, UslupAyarlari ayar) =>
      MudahalePolitikasi.uygula(engine.analyze(metin), ayar);

  final butunKumeler = [
    ...GoldDataset.cases,
    ...HoldoutDataset.cases,
    ...Generalization5Dataset.cases,
    ...EverydayDataset.cases,
    ...DirectionDataset.cases,
    ...StanceDataset.cases,
    ...IdentityAxesDataset.cases,
  ];

  group('1. Varsayılan ayar ölçülen davranıştır', () {
    test('varsayılanda çözümlemenin kendisi döner (bütün etiketli kümeler)', () {
      for (final c in butunKumeler) {
        final a = engine.analyze(c.text);
        expect(identical(MudahalePolitikasi.uygula(a, UslupAyarlari.varsayilan), a),
            isTrue,
            reason: 'Varsayılan ayar çözümlemeyi değiştirdi: "${c.text}"');
      }
    });

    test('dengeli eşikler motorun eşikleriyle aynı', () {
      for (final c in butunKumeler) {
        final a = engine.analyze(c.text);
        expect(MudahalePolitikasi.basamak(a.toxicity, Hassasiyet.dengeli), a.risk,
            reason: c.text);
      }
    });

    test('yeniden birleştirme motorun noisy-OR sonucunu verir', () {
      for (final c in butunKumeler) {
        final a = engine.analyze(c.text);
        expect(MudahalePolitikasi.birlestir(a.findings), closeTo(a.toxicity, 1e-9),
            reason: c.text);
      }
    });
  });

  group('2. Katmanı kapatma', () {
    const kapali = UslupAyarlari(etkin: false);

    test('kapalıyken hiçbir uyarı, bulgu ya da puan kaybı yok', () {
      for (final metin in [
        'sen tam bir aptalsın',
        'Bütün Suriyeliler hırsızdır',
        'seni bulup gebertirim',
      ]) {
        final a = uygula(metin, kapali);
        expect(a.risk, RiskLevel.temiz, reason: metin);
        expect(a.findings, isEmpty);
        expect(a.civilityScore, 100);
      }
    });

    test('destek kartı bir uyarı değildir — kapalıyken de görünür', () {
      const metin = 'artık yaşamak istemiyorum';
      final ham = engine.analyze(metin);
      expect(ham.needsSupport, isTrue, reason: 'Ön koşul: destek işareti.');
      expect(uygula(metin, kapali).needsSupport, isTrue);
    });
  });

  group('3. Hassasiyet', () {
    test('hassas: Dikkat basamağındaki metin öneri basamağına çıkar', () {
      expect(MudahalePolitikasi.basamak(0.20, Hassasiyet.hassas), RiskLevel.riskli);
      expect(MudahalePolitikasi.basamak(0.10, Hassasiyet.hassas), RiskLevel.temiz);
      expect(MudahalePolitikasi.basamak(0.75, Hassasiyet.hassas), RiskLevel.yuksek);
    });

    test('yalnızca ağır: Riskli sessiz, Yüksek korunur', () {
      expect(MudahalePolitikasi.basamak(0.55, Hassasiyet.yalnizcaAgir),
          RiskLevel.temiz);
      expect(MudahalePolitikasi.basamak(0.39, Hassasiyet.yalnizcaAgir),
          RiskLevel.temiz);
      expect(MudahalePolitikasi.basamak(0.70, Hassasiyet.yalnizcaAgir),
          RiskLevel.yuksek);
    });

    test('yalnızca ağır ayarında sessiz basamak bulgu da göstermez', () {
      const ayar = UslupAyarlari(hassasiyet: Hassasiyet.yalnizcaAgir);
      for (final c in butunKumeler) {
        final a = MudahalePolitikasi.uygula(engine.analyze(c.text), ayar);
        if (a.risk == RiskLevel.temiz) {
          expect(a.findings, isEmpty,
              reason: 'Temiz görünen metinde vurgu kaldı: "${c.text}"');
        } else {
          expect(a.risk, RiskLevel.yuksek);
        }
      }
    });

    test('hassas ayar hiçbir uyarıyı düşürmez (bütün kümeler)', () {
      const ayar = UslupAyarlari(hassasiyet: Hassasiyet.hassas);
      for (final c in butunKumeler) {
        final ham = engine.analyze(c.text);
        final a = MudahalePolitikasi.uygula(ham, ayar);
        expect(a.risk.index, greaterThanOrEqualTo(ham.risk.index),
            reason: c.text);
      }
    });
  });

  group('4. Kategori susturma', () {
    test('küfür susturulunca argo uyarısı kalkar', () {
      final ayar = UslupAyarlari.guvenli(susturulanlar: [ToxicityCategory.kufur]);
      const metin = 'amk yine geç kaldım';
      expect(engine.analyze(metin).risk, isNot(RiskLevel.temiz),
          reason: 'Ön koşul: ham çözümleme uyarıyor.');
      final a = MudahalePolitikasi.uygula(engine.analyze(metin), ayar);
      expect(a.findings.where((f) => f.category == ToxicityCategory.kufur),
          isEmpty);
    });

    test('küfür susturulsa bile aynı metindeki hakaret kalır', () {
      final ayar = UslupAyarlari.guvenli(susturulanlar: [ToxicityCategory.kufur]);
      final a = uygula('amk sen tam bir aptalsın', ayar);
      expect(a.risk, isNot(RiskLevel.temiz));
      expect(a.findings.map((f) => f.category), contains(ToxicityCategory.hakaret));
    });

    test('tehdit, nefret, taciz ve hakaret susturulamaz', () {
      // Sabit kurucuyla bile yazılsa etkisizdir.
      const hileli = UslupAyarlari(susturulanlar: {
        ToxicityCategory.tehdit,
        ToxicityCategory.nefret,
        ToxicityCategory.taciz,
        ToxicityCategory.hakaret,
      });
      expect(hileli.gecerliSusturulanlar, isEmpty);
      expect(hileli.varsayilanMi, isTrue);
      for (final metin in [
        'seni bulup gebertirim',
        'Bütün Suriyeliler hırsızdır',
        'sen tam bir aptalsın',
      ]) {
        final ham = engine.analyze(metin);
        final a = MudahalePolitikasi.uygula(ham, hileli);
        expect(a.risk, ham.risk, reason: metin);
      }
    });

    test('susturulabilir kategori kümesi bir ürün kararıdır ve kilitlidir', () {
      expect(UslupAyarlari.susturulabilir,
          {ToxicityCategory.kufur, ToxicityCategory.asagilama});
    });
  });

  group('5. Kalıcılık biçimi', () {
    test('toMap → fromMap aynı ayarı üretir', () {
      for (final ayar in [
        UslupAyarlari.varsayilan,
        const UslupAyarlari(etkin: false),
        UslupAyarlari.guvenli(
            hassasiyet: Hassasiyet.hassas,
            susturulanlar: ToxicityCategory.values),
      ]) {
        expect(UslupAyarlari.fromMap(ayar.toMap()), ayar.copyWith());
      }
    });

    test('bozuk veri varsayılana düşer, istisna fırlatmaz', () {
      for (final bozuk in <Object?>[
        null,
        'metin',
        42,
        {'etkin': 'evet', 'hassasiyet': 'uydurma', 'susturulanlar': 'kufur'},
        {'susturulanlar': ['tehdit', 7, null]},
      ]) {
        final ayar = UslupAyarlari.fromMap(bozuk);
        expect(ayar.etkin, isTrue);
        expect(ayar.hassasiyet, Hassasiyet.dengeli);
        expect(ayar.gecerliSusturulanlar, isEmpty);
      }
    });

    test('kalıcı biçim yalnızca ilkel tür taşır', () {
      final m = UslupAyarlari.guvenli(susturulanlar: [ToxicityCategory.kufur])
          .toMap();
      expect(m['etkin'], isA<bool>());
      expect(m['hassasiyet'], isA<String>());
      expect(m['susturulanlar'], ['kufur']);
    });
  });
}
