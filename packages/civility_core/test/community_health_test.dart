// =============================================================================
// Topluluk Sağlığı — Test Paketi
// Dosya: packages/civility_core/test/community_health_test.dart
//
// Bu katmanın iki iddiası var ve ikisi de ayrı ayrı kanıtlanmalı:
//
//   1. DOĞRU SAYAR   — oranlar, eğilim ve sağlık puanı beklenen değeri verir.
//   2. SIZDIRMAZ     — sinyal metin taşıyamaz, küçük sayılar açığa çıkmaz.
//
// İkincisi ürünün etik iddiasının parçasıdır: "metin cihazdan çıkmaz" diyen
// bir üründe, panelin kendisi bir sızıntı yüzeyi olamaz.
// =============================================================================

import 'dart:mirrors' as mirrors;

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  CommunitySignal signal({
    RiskLevel risk = RiskLevel.riskli,
    ToxicityCategory? category = ToxicityCategory.hakaret,
    SignalOutcome outcome = SignalOutcome.oneriyiKabulEtti,
    int bucket = 5,
    int day = 100,
  }) =>
      CommunitySignal(
        risk: risk,
        category: category,
        outcome: outcome,
        civilityBucket: bucket,
        dayIndex: day,
      );

  CommunitySignal temiz({int day = 100}) => signal(
        risk: RiskLevel.temiz,
        category: null,
        outcome: SignalOutcome.temizGonderim,
        bucket: 10,
        day: day,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. MAHREMİYET — yapısal güvenceler', () {
    test('CommunitySignal metin alanı TAŞIYAMAZ', () {
      // Yapısal test: sınıfa bir gün String alan eklenirse burası kırılır.
      // Yorumla "metin koymayın" demek yetmez; kod bunu imkânsız kılmalı.
      final sinif = mirrors.reflectClass(CommunitySignal);
      final stringAlanlar = <String>[];

      sinif.declarations.forEach((ad, bildirim) {
        if (bildirim is mirrors.VariableMirror) {
          if (bildirim.type.reflectedType == String) {
            stringAlanlar.add(mirrors.MirrorSystem.getName(ad));
          }
        }
      });

      expect(stringAlanlar, isEmpty,
          reason: 'CommunitySignal bir String alan kazandı: $stringAlanlar. '
              'Bu sınıf metin taşıyamaz — ürünün "metin cihazdan çıkmaz" '
              'iddiasının yapısal dayanağı budur.');
    });

    test('dışa aktarım haritası yalnızca SAYI içerir', () {
      final agg = CommunityHealthAggregator()
        ..addAll(List.generate(20, (_) => signal()))
        ..addAll(List.generate(30, (_) => temiz()));

      final export = agg.report().toExportMap();

      expect(export, isNotEmpty);
      for (final entry in export.entries) {
        expect(entry.value, isA<num>(),
            reason: '"${entry.key}" sayı değil. Dışa aktarımdan sunucuya '
                'yalnızca sayı gidebilir.');
      }
    });

    test('eşik altındaki kategori sayıyla açılmaz', () {
      // Tek bir nefret söylemi bulgusu, küçük bir toplulukta o kişiyi
      // doğrudan işaret eder.
      final agg = CommunityHealthAggregator(k: 5)
        ..add(signal(category: ToxicityCategory.nefret))
        ..addAll(List.generate(10, (_) => signal(category: ToxicityCategory.hakaret)));

      final r = agg.report();

      expect(r.categoryCounts.containsKey(ToxicityCategory.nefret), isFalse,
          reason: '1 gözlem k=5 eşiğinin altında; açılmamalı.');
      expect(r.categoryCounts[ToxicityCategory.hakaret], 10);
      expect(r.suppressedCategories, 1,
          reason: 'Gizlemenin kendisi de şeffaf olmalı — kaç kategorinin '
              'gizlendiği söylenmeli.');
    });

    test('gizlenen kategori dışa aktarımda da yoktur', () {
      final agg = CommunityHealthAggregator(k: 5)
        ..add(signal(category: ToxicityCategory.nefret))
        ..addAll(List.generate(6, (_) => signal(category: ToxicityCategory.kufur)));

      final export = agg.report().toExportMap();
      expect(export.containsKey('kategori_nefret'), isFalse);
      expect(export['kategori_kufur'], 6);
    });

    test('sinyal saat/dakika taşımaz — yalnızca gün kovası', () {
      final analysis = LexicalTurkishClassifier().analyze('merhaba');
      final sabah = CommunitySignal.fromAnalysis(
          analysis, SignalOutcome.temizGonderim,
          at: DateTime.utc(2026, 8, 12, 3, 14));
      final aksam = CommunitySignal.fromAnalysis(
          analysis, SignalOutcome.temizGonderim,
          at: DateTime.utc(2026, 8, 12, 23, 59));

      expect(sabah.dayIndex, aksam.dayIndex,
          reason: 'Gönderim saati tek başına güçlü bir tanımlayıcıdır; '
              'aynı günün iki ucu ayırt edilememeli.');
    });

    test('nezaket puanı diliminde tutulur, ham puan değil', () {
      final engine = LexicalTurkishClassifier();
      final s = CommunitySignal.fromAnalysis(
          engine.analyze('merhaba nasılsın'), SignalOutcome.temizGonderim);
      expect(s.civilityBucket, inInclusiveRange(0, 10));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Oranlar doğru hesaplanır', () {
    test('müdahale oranı toplam üzerinden, düzeltme oranı MÜDAHALE üzerinden',
        () {
      final agg = CommunityHealthAggregator()
        ..addAll(List.generate(75, (_) => temiz()))
        ..addAll(List.generate(15, (_) => signal(
            outcome: SignalOutcome.oneriyiKabulEtti)))
        ..addAll(List.generate(10, (_) => signal(
            outcome: SignalOutcome.uyariyaRagmenGonderdi)));

      final r = agg.report();

      expect(r.totalSignals, 100);
      expect(r.interventions, 25);
      expect(r.interventionRate, closeTo(0.25, 1e-9));
      expect(r.behaviourChanges, 15);
      expect(r.revisionRate, closeTo(0.60, 1e-9),
          reason: 'Payda müdahale sayısı olmalı (25), toplam (100) değil. '
              'Aksi hâlde hiç uyarı almamış gönderimler oranı şişirir.');
    });

    test('kullanıcının kendi düzeltmesi de davranış değişimidir', () {
      final agg = CommunityHealthAggregator()
        ..addAll(List.generate(5, (_) => signal(
            outcome: SignalOutcome.kendiDuzeltti)))
        ..addAll(List.generate(5, (_) => signal(
            outcome: SignalOutcome.uyariyaRagmenGonderdi)));

      expect(agg.report().revisionRate, closeTo(0.5, 1e-9),
          reason: 'Ürün öneriyi dayatmaz; kullanıcının kendi bulduğu '
              'düzeltme de başarıdır.');
    });

    test('boş toplulaştırıcı sıfıra bölme yapmaz', () {
      final r = CommunityHealthAggregator().report();
      expect(r.totalSignals, 0);
      expect(r.interventionRate, 0.0);
      expect(r.revisionRate, 0.0);
      expect(r.healthScore, 100);
      expect(r.hasEnoughData, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Sağlık puanı', () {
    test('hiç müdahale yoksa puan yalnızca temizlikten gelir', () {
      final agg = CommunityHealthAggregator()
        ..addAll(List.generate(50, (_) => temiz()));
      expect(agg.report().healthScore, 100,
          reason: 'Kusursuz bir topluluk, tanımsız düzeltme oranı yüzünden '
              'cezalandırılmamalı.');
    });

    test('aynı müdahale oranında, düzelten topluluk daha yüksek puan alır', () {
      final duzelten = CommunityHealthAggregator()
        ..addAll(List.generate(80, (_) => temiz()))
        ..addAll(List.generate(20, (_) => signal(
            outcome: SignalOutcome.oneriyiKabulEtti)));

      final direten = CommunityHealthAggregator()
        ..addAll(List.generate(80, (_) => temiz()))
        ..addAll(List.generate(20, (_) => signal(
            outcome: SignalOutcome.uyariyaRagmenGonderdi)));

      expect(duzelten.report().healthScore,
          greaterThan(direten.report().healthScore),
          reason: 'Panelin ölçtüğü şey uyarı sayısı değil, uyarının işe '
              'yarayıp yaramadığıdır.');
    });

    test('puan 0-100 aralığını aşmaz', () {
      final kotu = CommunityHealthAggregator()
        ..addAll(List.generate(100, (_) => signal(
            risk: RiskLevel.yuksek,
            outcome: SignalOutcome.uyariyaRagmenGonderdi)));
      expect(kotu.report().healthScore, inInclusiveRange(0, 100));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Eğilim (trend)', () {
    test('günler artan sırada gelir ve günlük oran doğru hesaplanır', () {
      // Günlük gözlem sayısı 4; trend de k-anonimliğe tabi olduğu için
      // (docs/24 · madde 35) eşik bu testin veri boyutuna indirildi.
      final agg = CommunityHealthAggregator(k: 4)
        // 102. gün önce eklendi — sıralama giriş sırasına göre olmamalı.
        ..addAll(List.generate(2, (_) => signal(day: 102)))
        ..addAll(List.generate(2, (_) => temiz(day: 102)))
        ..addAll(List.generate(1, (_) => signal(day: 101)))
        ..addAll(List.generate(3, (_) => temiz(day: 101)));

      final trend = agg.report().trend;

      expect(trend.map((t) => t.dayIndex).toList(), [101, 102]);
      expect(trend[0].interventionRate, closeTo(0.25, 1e-9));
      expect(trend[1].interventionRate, closeTo(0.50, 1e-9));
    });

    test('eşik altındaki gün trendde görünmez (k-anonimlik)', () {
      // Tek gönderimli bir gün: oranı %0 ya da %100'dür ve o kişinin
      // uyarı alıp almadığını doğrudan söyler.
      final agg = CommunityHealthAggregator()
        ..addAll(List.generate(6, (_) => temiz(day: 200)))
        ..add(signal(day: 201));

      final r = agg.report();
      expect(r.trend.map((t) => t.dayIndex), [200]);
      expect(r.suppressedDays, 1);
      expect(r.totalSignals, 7,
          reason: 'Gizleme yalnızca günlük dökümü etkiler, toplamı değil.');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4b. "Bu uyarı yanlış" bildirimi (docs/27)', () {
    CommunitySignal itiraz({ToxicityCategory c = ToxicityCategory.hakaret}) =>
        CommunitySignal(
          risk: RiskLevel.riskli,
          category: c,
          outcome: SignalOutcome.uyariyaRagmenGonderdi,
          civilityBucket: 5,
          dayIndex: 100,
          yanlisAlarmBildirildi: true,
        );

    test('eşik altındaki bildirim sayısı açılmaz ve geri hesaplanamaz', () {
      final agg = CommunityHealthAggregator(k: 5)
        ..addAll(List.generate(3, (_) => itiraz()))
        ..addAll(List.generate(10, (_) => signal()));
      final r = agg.report();
      expect(r.falseAlarmReports, isNull);
      expect(r.falseAlarmRate, isNull);
      expect(r.falseAlarmByCategory, isEmpty);
      // Payda da değişmez: 3 bildirim düzeltme oranından türetilemez.
      expect(r.revisionRate, closeTo(10 / 13, 1e-9));
      expect(r.toExportMap().keys.where((k) => k.startsWith('yanlis_alarm')),
          isEmpty);
    });

    test('eşiği geçen bildirim sayılır ve düzeltme oranının paydasından çıkar',
        () {
      final agg = CommunityHealthAggregator(k: 5)
        ..addAll(List.generate(6, (_) => itiraz()))
        ..addAll(List.generate(4, (_) => itiraz(c: ToxicityCategory.kufur)))
        ..addAll(List.generate(10, (_) => signal()));
      final r = agg.report();
      expect(r.falseAlarmReports, 10);
      expect(r.falseAlarmRate, closeTo(10 / 20, 1e-9));
      expect(r.falseAlarmByCategory, {ToxicityCategory.hakaret: 6},
          reason: '4 küfür bildirimi eşiğin altında.');
      expect(r.revisionRate, closeTo(10 / 10, 1e-9),
          reason: 'Yanlış bulunan uyarıyı dikkate almamak "görmezden '
              'gelmek" sayılmaz.');
      final export = r.toExportMap();
      expect(export['yanlis_alarm'], 10);
      expect(export['yanlis_alarm_hakaret'], 6);
      expect(export.containsKey('yanlis_alarm_kufur'), isFalse);
      for (final v in export.values) {
        expect(v, isA<num>());
      }
    });

    test('uyarı olmayan çözümlemede yanlış alarm işareti konamaz', () {
      final temizAnaliz = LexicalTurkishClassifier().analyze('merhaba');
      final s = CommunitySignal.fromAnalysis(
          temizAnaliz, SignalOutcome.temizGonderim,
          yanlisAlarm: true);
      expect(s.yanlisAlarmBildirildi, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('5. Motorla uçtan uca', () {
    test('gerçek çözümlemeden üretilen sinyal doğru sınıflanır', () {
      final engine = LexicalTurkishClassifier();

      final temizAnaliz = engine.analyze('Yarın buluşalım mı?');
      final kotuAnaliz = engine.analyze('sen tam bir aptalsın');

      final s1 = CommunitySignal.fromAnalysis(
          temizAnaliz, SignalOutcome.temizGonderim);
      final s2 = CommunitySignal.fromAnalysis(
          kotuAnaliz, SignalOutcome.oneriyiKabulEtti);

      expect(s1.mudahaleVardi, isFalse);
      expect(s2.mudahaleVardi, isTrue);
      expect(s2.category, isNotNull);

      final r = (CommunityHealthAggregator()..addAll([s1, s2])).report();
      expect(r.totalSignals, 2);
      expect(r.interventions, 1);
      expect(r.revisionRate, 1.0);
    });
  });
}
