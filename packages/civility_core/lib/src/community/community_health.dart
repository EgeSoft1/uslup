// =============================================================================
// Topluluk Sağlığı — anonim sinyal toplulaştırma
// Dosya: packages/civility_core/lib/src/community/community_health.dart
//
// ── BU KATMAN NEDEN VAR ───────────────────────────────────────────────────
// Şartnamenin örnek çözüm alanlarından biri "YZ destekli topluluk yönetimi".
// Ancak topluluk yönetimi genellikle şu şekilde yapılır: içerik sunucuya
// gider, orada saklanır, panelde okunur. Bu üründe o yol KAPALIDIR — metin
// cihazdan çıkmaz.
//
// Bu yüzden panel, metinden değil, DAVRANIŞTAN beslenir. Kullanıcı bir uyarı
// aldığında ne yaptığı (gönderdi / düzeltti / vazgeçti) tek başına bir sayıya
// indirgenebilir ve o sayı kimseyi tanımlamaz.
//
// ── MAHREMİYET YAPISAL OLARAK GARANTİ EDİLİR ──────────────────────────────
// `CommunitySignal` metin TAŞIYAMAZ. Alanlarının hepsi enum ya da tam sayı;
// String alanı yoktur ve bu, `community_health_test.dart` içinde yapısal bir
// testle korunur. "Metni buraya koymayı unuttuk" diye bir kaza mümkün değil,
// çünkü koyacak yer yok.
//
// ── K-ANONİMLİK ───────────────────────────────────────────────────────────
// Toplulaştırma tek başına yetmez. Küçük bir toplulukta "nefret söylemi: 1"
// satırı, o tek kişiyi işaret eder. Bu yüzden bir kategori, ancak en az [k]
// gözlem varsa sayı olarak açılır; altındakiler "yetersiz örnek" olarak
// gizlenir. Eşik, panelin kendisi tarafından değil, bu katman tarafından
// uygulanır — arayüzün unutması mümkün olmasın diye.
//
// ── NEREDE ÇALIŞIR ────────────────────────────────────────────────────────
// Toplulaştırma CİHAZDA yapılır. Rapor bir sunucuya gönderilecekse gönderilen
// şey `toExportMap()` çıktısıdır: yalnızca sayılar, k-anonimlik uygulanmış
// hâlde. Ham sinyaller bile dışarı çıkmaz.
// =============================================================================

import '../civility_engine.dart';
import '../lexicon/toxicity_lexicon.dart';

/// Kullanıcının uyarı karşısındaki kararı.
///
/// Ürünün asıl başarı ölçüsü budur: kaç uyarı verildiği değil, kaçının
/// davranışı değiştirdiği.
enum SignalOutcome {
  /// Uyarı yoktu; metin temizdi.
  temizGonderim,

  /// Uyarı verildi, kullanıcı yine de gönderdi.
  uyariyaRagmenGonderdi,

  /// Uyarı verildi, kullanıcı öneriyi kabul edip düzeltti.
  oneriyiKabulEtti,

  /// Uyarı verildi, kullanıcı metni kendisi değiştirdi veya sildi.
  kendiDuzeltti,
}

extension SignalOutcomeInfo on SignalOutcome {
  String get label => switch (this) {
        SignalOutcome.temizGonderim => 'Temiz gönderim',
        SignalOutcome.uyariyaRagmenGonderdi => 'Uyarıya rağmen gönderildi',
        SignalOutcome.oneriyiKabulEtti => 'Öneri kabul edildi',
        SignalOutcome.kendiDuzeltti => 'Kullanıcı kendi düzeltti',
      };

  /// Müdahalenin davranışı değiştirdiği sonuçlar.
  bool get davranisDegisti =>
      this == SignalOutcome.oneriyiKabulEtti ||
      this == SignalOutcome.kendiDuzeltti;
}

/// Gönderim anında üretilen anonim sinyal.
///
/// ⚠ BU SINIFA ASLA METİN ALANI EKLENMEZ. Ürünün "metin cihazdan çıkmaz"
/// iddiasının yapısal dayanağı budur; yapısal test bunu korur.
class CommunitySignal {
  /// Çözümlemenin ürettiği risk seviyesi.
  final RiskLevel risk;

  /// Baskın kategori. Temiz metinlerde null.
  final ToxicityCategory? category;

  /// Kullanıcının kararı.
  final SignalOutcome outcome;

  /// Nezaket puanının onluk dilimi (0–10).
  ///
  /// Puanın kendisi değil dilimi tutulur: 87 ile 89 arasındaki fark hiçbir
  /// analize katkı sunmaz ama parmak izi yüzeyini genişletir.
  final int civilityBucket;

  /// Gün kovası — epoch'tan itibaren gün sayısı. Saat/dakika TUTULMAZ;
  /// gönderim zamanı tek başına güçlü bir tanımlayıcıdır.
  final int dayIndex;

  /// Kullanıcı bu uyarıya "Bu uyarı yanlış" dedi mi? (docs/27)
  ///
  /// ── NEDEN YALNIZCA BİR EVET/HAYIR ────────────────────────────────────
  /// Yanlış alarmın hangi kelimede çıktığını bilmek geliştirici için çok
  /// değerli olurdu — ama o kelime kullanıcının METNİNDEN bir parçadır.
  /// Sözlük teriminin ya da eşleşen ifadenin buraya yazılması, "metin
  /// cihazdan çıkmaz" iddiasını parça parça delerdi. Kategori zaten
  /// [category] alanındadır; daha fazlası taşınmaz.
  final bool yanlisAlarmBildirildi;

  const CommunitySignal({
    required this.risk,
    required this.outcome,
    required this.civilityBucket,
    required this.dayIndex,
    this.category,
    this.yanlisAlarmBildirildi = false,
  });

  /// Bir çözümleme ve kullanıcı kararından sinyal üretir.
  ///
  /// Metin parametre olarak dahi alınmaz — çağıran taraf yanlışlıkla
  /// gönderemesin diye.
  factory CommunitySignal.fromAnalysis(
    CivilityAnalysis analysis,
    SignalOutcome outcome, {
    DateTime? at,
    bool yanlisAlarm = false,
  }) {
    final when = at ?? DateTime.now();
    return CommunitySignal(
      risk: analysis.risk,
      category: analysis.dominantCategory,
      outcome: outcome,
      civilityBucket: (analysis.civilityScore ~/ 10).clamp(0, 10),
      dayIndex: when.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
      // Uyarı yoksa "yanlış alarm" da olamaz; çağıranın hatası sayıyı
      // bozmasın.
      yanlisAlarmBildirildi: yanlisAlarm && analysis.risk != RiskLevel.temiz,
    );
  }

  bool get mudahaleVardi => risk != RiskLevel.temiz;
}

/// Toplulaştırılmış topluluk sağlığı raporu.
class CommunityHealthReport {
  /// Rapora giren toplam sinyal sayısı.
  final int totalSignals;

  /// Müdahale edilen (risk != temiz) sinyal sayısı.
  final int interventions;

  /// Müdahale sonrası davranışın değiştiği sinyal sayısı.
  final int behaviourChanges;

  /// Kategori dağılımı — **k-anonimlik uygulanmış**. Eşiğin altındaki
  /// kategoriler bu haritada HİÇ yer almaz.
  final Map<ToxicityCategory, int> categoryCounts;

  /// Eşik altında kaldığı için gizlenen kategori sayısı.
  /// Panelde "n kategori yetersiz örnek nedeniyle gizlendi" olarak gösterilir —
  /// gizlemenin kendisi de şeffaf olmalıdır.
  final int suppressedCategories;

  /// Gün kovası → o günün müdahale oranı [0,1]. En eskiden yeniye sıralı.
  ///
  /// **k-anonimlik uygulanmış** (docs/24 · madde 35): gözlem sayısı eşiğin
  /// altında kalan günler listede YER ALMAZ. Önceden kategori sayıları
  /// gizleniyor ama trend gizlenmiyordu; tek gönderimin yapıldığı bir gün
  /// "%100 müdahale" satırıyla o kişinin kararını açığa çıkarıyordu.
  final List<({int dayIndex, double interventionRate})> trend;

  /// Eşik altında kaldığı için trendden çıkarılan gün sayısı.
  final int suppressedDays;

  /// Uygulanan k-anonimlik eşiği.
  final int kThreshold;

  /// "Bu uyarı yanlış" bildirilen müdahale sayısı — **k-anonimlik
  /// uygulanmış**: eşiğin altındaysa `null` (docs/27).
  ///
  /// Tek bir bildirimi göstermek, küçük bir toplulukta o kişinin hangi gün
  /// uyarıya itiraz ettiğini söyler.
  final int? falseAlarmReports;

  /// Yanlış alarm bildirimlerinin kategori dağılımı — k-anonimlik
  /// uygulanmış. Hangi katmanın sahada yanlış alarm ürettiğini gösterir.
  final Map<ToxicityCategory, int> falseAlarmByCategory;

  const CommunityHealthReport({
    required this.totalSignals,
    required this.interventions,
    required this.behaviourChanges,
    required this.categoryCounts,
    required this.suppressedCategories,
    required this.trend,
    required this.kThreshold,
    this.suppressedDays = 0,
    this.falseAlarmReports,
    this.falseAlarmByCategory = const {},
    int reportedInterventions = 0,
  }) : _reportedInterventions = reportedInterventions;

  /// Yanlış alarm bildirilen müdahale sayısı — yalnızca eşiği geçtiyse,
  /// aksi hâlde 0. Oranların paydasında kullanılır.
  final int _reportedInterventions;

  /// Müdahale oranı [0,1]. Kaç gönderimde uyarı çıktı?
  double get interventionRate =>
      totalSignals == 0 ? 0.0 : interventions / totalSignals;

  /// Kullanıcının yanlış bulmadığı müdahaleler.
  int get validInterventions => interventions - _reportedInterventions;

  /// Düzeltme oranı [0,1] — **ürünün asıl başarı ölçüsü.**
  ///
  /// Payda müdahale sayısıdır, toplam değil: hiç uyarı almamış gönderimler
  /// bu oranı şişirmemelidir. Kullanıcının "yanlış" dediği uyarılar da
  /// paydadan çıkarılır: yanlış bir uyarıyı dikkate almadan göndermek
  /// "uyarıyı görmezden gelmek" değildir ve oranı haksız yere düşürürdü.
  double get revisionRate =>
      validInterventions <= 0 ? 0.0 : behaviourChanges / validInterventions;

  /// Yanlış alarm oranı [0,1] — kural katmanının SAHADAKİ kesinlik
  /// göstergesi. Bildirim sayısı eşiğin altındaysa `null`.
  double? get falseAlarmRate {
    final n = falseAlarmReports;
    if (n == null || interventions == 0) return null;
    return n / interventions;
  }

  /// Panel başlığındaki 0–100 topluluk sağlığı puanı.
  ///
  /// Yalnızca "az uyarı = sağlıklı" demek yanıltıcıdır: hiç yazmayan bir
  /// topluluk da az uyarı üretir. Bu yüzden puan iki bileşenlidir —
  /// gönderimlerin temizliği ve uyarı alındığında düzeltme eğilimi.
  ///
  /// Müdahale hiç yoksa düzeltme oranı tanımsızdır; o durumda puan tamamen
  /// temizlik bileşeninden gelir (ikinci bileşeni 0 saymak, kusursuz bir
  /// topluluğu 60 puana düşürürdü).
  int get healthScore {
    if (totalSignals == 0) return 100;
    final temizlik = 1.0 - interventionRate;
    if (interventions == 0) return (temizlik * 100).round().clamp(0, 100);
    return ((temizlik * 0.6 + revisionRate * 0.4) * 100).round().clamp(0, 100);
  }

  bool get hasEnoughData => totalSignals >= kThreshold;

  /// Sunucuya gönderilmesi hâlinde gidecek olan tek şey.
  ///
  /// Yalnızca sayı içerir. Ham sinyaller, zaman damgaları ve elbette metin
  /// burada YOKTUR. Yapısal test, değerlerin tamamının sayı olduğunu kontrol
  /// eder — haritaya bir gün metin sızarsa test kırılır.
  Map<String, num> toExportMap() => {
        'toplam': totalSignals,
        'mudahale': interventions,
        'davranis_degisimi': behaviourChanges,
        'saglik_puani': healthScore,
        'k_esigi': kThreshold,
        'gizlenen_kategori': suppressedCategories,
        for (final entry in categoryCounts.entries)
          'kategori_${entry.key.name}': entry.value,
        if (falseAlarmReports != null) 'yanlis_alarm': falseAlarmReports!,
        for (final entry in falseAlarmByCategory.entries)
          'yanlis_alarm_${entry.key.name}': entry.value,
      };
}

/// Anonim sinyalleri toplulaştırır.
///
/// Cihazda çalışır ve durumu bellektedir; kalıcılık çağıran tarafın işidir.
class CommunityHealthAggregator {
  /// Bir kategorinin sayı olarak açılabilmesi için gereken en az gözlem.
  ///
  /// 5, mahremiyet yazınındaki yaygın alt sınırdır. Daha düşük bir eşik,
  /// küçük topluluklarda tek bir kişinin davranışını görünür kılar.
  static const int defaultK = 5;

  final int k;
  final List<CommunitySignal> _signals = [];

  CommunityHealthAggregator({this.k = defaultK})
      : assert(k >= 1, 'k-anonimlik eşiği en az 1 olmalı');

  int get signalCount => _signals.length;

  void add(CommunitySignal signal) => _signals.add(signal);

  void addAll(Iterable<CommunitySignal> signals) => _signals.addAll(signals);

  void clear() => _signals.clear();

  /// Toplulaştırılmış raporu üretir.
  CommunityHealthReport report() {
    if (_signals.isEmpty) {
      return CommunityHealthReport(
        totalSignals: 0,
        interventions: 0,
        behaviourChanges: 0,
        categoryCounts: const {},
        suppressedCategories: 0,
        trend: const [],
        kThreshold: k,
      );
    }

    var interventions = 0;
    var behaviourChanges = 0;
    var reported = 0;
    final rawCategories = <ToxicityCategory, int>{};
    final rawFalseAlarms = <ToxicityCategory, int>{};
    final perDay = <int, ({int total, int flagged})>{};

    for (final s in _signals) {
      if (s.mudahaleVardi) {
        interventions++;
        if (s.outcome.davranisDegisti) behaviourChanges++;
        final c = s.category;
        if (c != null) rawCategories[c] = (rawCategories[c] ?? 0) + 1;
        if (s.yanlisAlarmBildirildi) {
          reported++;
          if (c != null) rawFalseAlarms[c] = (rawFalseAlarms[c] ?? 0) + 1;
        }
      }

      final day = perDay[s.dayIndex] ?? (total: 0, flagged: 0);
      perDay[s.dayIndex] = (
        total: day.total + 1,
        flagged: day.flagged + (s.mudahaleVardi ? 1 : 0),
      );
    }

    // ── k-anonimlik ──────────────────────────────────────────────────────────
    final visible = <ToxicityCategory, int>{};
    var suppressed = 0;
    for (final entry in rawCategories.entries) {
      if (entry.value >= k) {
        visible[entry.key] = entry.value;
      } else {
        suppressed++;
      }
    }

    final days = perDay.keys.toList()..sort();
    var suppressedDays = 0;
    final trend = <({int dayIndex, double interventionRate})>[];
    for (final d in days) {
      final day = perDay[d]!;
      // Günlük oran da bir toplulaştırmadır ve aynı eşiğe tabidir.
      if (day.total < k) {
        suppressedDays++;
        continue;
      }
      trend.add((dayIndex: d, interventionRate: day.flagged / day.total));
    }

    return CommunityHealthReport(
      totalSignals: _signals.length,
      interventions: interventions,
      behaviourChanges: behaviourChanges,
      categoryCounts: visible,
      suppressedCategories: suppressed,
      trend: trend,
      kThreshold: k,
      suppressedDays: suppressedDays,
      falseAlarmReports: reported >= k ? reported : null,
      falseAlarmByCategory: {
        for (final e in rawFalseAlarms.entries)
          if (e.value >= k) e.key: e.value,
      },
      // Eşiğin altındaki bildirim paydadan da ÇIKARILMAZ: çıkarılsaydı
      // `interventions`, `behaviourChanges` ve `revisionRate` üzerinden
      // gizlenen sayı geri hesaplanabilirdi.
      reportedInterventions: reported >= k ? reported : 0,
    );
  }
}
