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
      final agg = CommunityHealthAggregator()
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
