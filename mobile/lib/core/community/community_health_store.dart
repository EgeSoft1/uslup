// =============================================================================
// Topluluk Sağlığı Deposu — uygulama içi anonim sinyal biriktirici
// Dosya: mobile/lib/core/community/community_health_store.dart
//
// Toplulaştırma mantığı burada DEĞİLDİR; `civility_core` içindedir ve orada
// test edilir (`community_health_test.dart`). Bu sınıf yalnızca üç şey yapar:
// sinyali alır, biriktirir, dinleyicileri uyarır.
//
// ── NEDEN KALICI DEPOLAMA YOK ─────────────────────────────────────────────
// Kasıtlı. Sinyaller bellekte durur ve uygulama kapanınca kaybolur. Diske
// yazmak, "hiçbir davranış kaydı cihazda birikmiyor" iddiasını da tartışmaya
// açardı. Gerçek üründe kalıcılık gerekirse, yazılacak şey ham sinyaller
// değil `CommunityHealthReport.toExportMap()` çıktısı olmalıdır.
//
// ── GÖSTERİM VERİSİ ───────────────────────────────────────────────────────
// Panel boşken hiçbir şey anlatmaz, bu yüzden bir gösterim kümesi tohumlanır.
// Gerçek sinyallerden AYRI sayılır ve arayüz bunu açıkça yazar — jüriye
// gösterilen bir panelde hangi sayının gerçek olduğu belirsiz kalamaz.
// =============================================================================

import 'dart:math';

import 'package:civility_core/civility_core.dart';
import 'package:flutter/foundation.dart';

class CommunityHealthStore extends ChangeNotifier {
  CommunityHealthStore._();

  static final CommunityHealthStore instance = CommunityHealthStore._();

  final CommunityHealthAggregator _aggregator = CommunityHealthAggregator();

  int _demoCount = 0;
  int _realCount = 0;

  /// Gösterim amacıyla tohumlanmış sinyal sayısı.
  int get demoCount => _demoCount;

  /// Bu oturumda kullanıcının kendi gönderimlerinden üretilen sinyal sayısı.
  int get realCount => _realCount;

  CommunityHealthReport get report => _aggregator.report();

  /// Bir gönderimi kaydeder.
  ///
  /// Metin parametre olarak alınmaz — `CommunitySignal.fromAnalysis` zaten
  /// metni göremez. Çağıran taraf yanlışlıkla sızdıramaz.
  void record(CivilityAnalysis analysis, SignalOutcome outcome) {
    _aggregator.add(CommunitySignal.fromAnalysis(analysis, outcome));
    _realCount++;
    notifyListeners();
  }

  /// Panelin ilk açılışında bir kez çağrılır.
  void seedDemoDataOnce() {
    if (_demoCount > 0) return;

    // Sabit tohum: her açılışta aynı tablo. Gösterimde rastgelelik,
    // "sayılar neden değişti" sorusundan başka bir şey üretmez.
    final rnd = Random(20260812);
    final bugun = DateTime.now().toUtc().millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;

    final signals = <CommunitySignal>[];

    for (var gunOnce = 6; gunOnce >= 0; gunOnce--) {
      final gun = bugun - gunOnce;
      // Günde 55–75 gönderim.
      final adet = 55 + rnd.nextInt(21);

      for (var i = 0; i < adet; i++) {
        // Müdahale oranı hafifçe düşen bir eğilim izler: 0.22 → 0.13.
        final oran = 0.22 - (6 - gunOnce) * 0.015;

        if (rnd.nextDouble() > oran) {
          signals.add(CommunitySignal(
            risk: RiskLevel.temiz,
            category: null,
            outcome: SignalOutcome.temizGonderim,
            civilityBucket: 9 + rnd.nextInt(2),
            dayIndex: gun,
          ));
          continue;
        }

        final kategori = _agirlikliKategori(rnd);
        final risk = kategori == ToxicityCategory.tehdit ||
                kategori == ToxicityCategory.nefret
            ? RiskLevel.yuksek
            : (rnd.nextBool() ? RiskLevel.riskli : RiskLevel.dikkat);

        // Düzeltme eğilimi ~%62.
        final r = rnd.nextDouble();
        final sonuc = r < 0.44
            ? SignalOutcome.oneriyiKabulEtti
            : (r < 0.62
                ? SignalOutcome.kendiDuzeltti
                : SignalOutcome.uyariyaRagmenGonderdi);

        signals.add(CommunitySignal(
          risk: risk,
          category: kategori,
          outcome: sonuc,
          civilityBucket: rnd.nextInt(6),
          dayIndex: gun,
        ));
      }
    }

    _aggregator.addAll(signals);
    _demoCount = signals.length;
    notifyListeners();
  }

  /// Gerçekçi bir kategori dağılımı: aşağılama ve hakaret baskın, nefret
  /// söylemi seyrek. Seyrek olması önemli — k-anonimlik eşiğinin panelde
  /// gerçekten iş yaptığı görülsün.
  static ToxicityCategory _agirlikliKategori(Random rnd) {
    final r = rnd.nextDouble();
    if (r < 0.34) return ToxicityCategory.asagilama;
    if (r < 0.60) return ToxicityCategory.hakaret;
    if (r < 0.78) return ToxicityCategory.kufur;
    if (r < 0.90) return ToxicityCategory.taciz;
    if (r < 0.97) return ToxicityCategory.nefret;
    return ToxicityCategory.tehdit;
  }
}
