// =============================================================================
// Kullanıcı Ayarları ve Müdahale Politikası
// Dosya: packages/civility_core/lib/src/policy/uslup_ayarlari.dart
//
// ── NEDEN ─────────────────────────────────────────────────────────────────
// Ürünün ilk ilkesi "karar kullanıcıda". Ama kullanıcı yalnızca TEK BİR
// metnin kararını veriyordu; katmanın kendisinin ne kadar konuşacağına karar
// veremiyordu. Arkadaşlarıyla argo konuşan biri her "lan"da uyarı görüyor,
// kendini daha sıkı denetlemek isteyen biri "dikkat" basamağında yalnızca
// kenar rengi görüyordu. Ayar olmadan "karar kullanıcıda" yarım bir iddiadır.
//
// ── ÜÇ KESİN KURAL ────────────────────────────────────────────────────────
//
//   1. AYARLAR MOTORU DEĞİŞTİRMEZ. Çözümleme her zaman aynıdır; ayar yalnızca
//      çözümlemenin KULLANICIYA NASIL YANSIYACAĞINI belirler. Raporlanan her
//      ölçüm bu yüzden geçerliliğini korur. Varsayılan ayarda politika
//      çözümlemeyi olduğu gibi döndürür — `test/uslup_ayarlari_test.dart`
//      bunu bütün etiketli kümelerde denetler.
//
//   2. BAŞKALARINI KORUYAN UYARILAR TEK TEK KAPATILAMAZ. Kullanıcı küfür/argo
//      ve alay uyarılarını susturabilir: bunlar çoğunlukla yazanın kendi
//      üslup tercihidir. Tehdit, nefret söylemi, taciz ve hakaret başka bir
//      insanı hedef alır; bunları "sessize alma" seçeneği sunmak, ürünü
//      hedef alınan kişiye karşı çalışan bir araca çevirirdi. Hiç uyarı
//      istemeyen kullanıcı katmanı bütünüyle kapatabilir — seçim yine onun.
//
//   3. DESTEK KARTI BİR UYARI DEĞİLDİR. Kendine zarar ifadesinde gösterilen
//      destek kartı katman kapalıyken de görünür; kullanıcıyı yargılamaz,
//      yalnızca yardım hattını hatırlatır (docs/20, D4).
// =============================================================================

import '../civility_engine.dart';
import '../lexicon/toxicity_lexicon.dart';

/// Katmanın ne sıklıkta konuşacağı.
enum Hassasiyet {
  /// Yalnızca ağır ifadeler (Yüksek basamak) bir şey gösterir; öneri ve onay
  /// orada başlar. Riskli ve Dikkat basamakları sessizdir.
  yalnizcaAgir,

  /// Ürünün ölçülen varsayılanı: Dikkat → kenar rengi, Riskli → gerekçe ve
  /// öneri, Yüksek → onay.
  dengeli,

  /// Dikkat basamağındaki metin de gerekçe ve öneri alır. Kendini daha sıkı
  /// denetlemek isteyen kullanıcı içindir.
  hassas,
}

extension HassasiyetInfo on Hassasiyet {
  String get label => switch (this) {
        Hassasiyet.yalnizcaAgir => 'Yalnızca ağır ifadeler',
        Hassasiyet.dengeli => 'Dengeli',
        Hassasiyet.hassas => 'Hassas',
      };

  String get aciklama => switch (this) {
        Hassasiyet.yalnizcaAgir =>
          'Yalnızca ağır saldırı ve tehditte uyarır. Sınırda ve orta '
              'düzeydeki ifadeler için hiçbir şey göstermez.',
        Hassasiyet.dengeli =>
          'Önerilen. Sınırdaki ifadede yalnızca kutunun rengi değişir; '
              'saldırgan ifadede gerekçe ve öneri, ağır ifadede onay çıkar.',
        Hassasiyet.hassas =>
          'Sınırdaki ifadelerde de gerekçe ve öneri gösterir. Kendi '
              'üslubunu daha sıkı izlemek isteyenler için.',
      };
}

/// Kullanıcının katman tercihleri. Değişmezdir.
class UslupAyarlari {
  /// Katman açık mı? Kapalıyken hiçbir uyarı, öneri ya da onay gösterilmez.
  final bool etkin;

  final Hassasiyet hassasiyet;

  /// Uyarısı susturulmak istenen kategoriler. Yalnızca [susturulabilir]
  /// içindekiler etkilidir: sabit kurucu listeyi süzemediği için süzme
  /// [gecerliSusturulanlar] ile her kullanımda yapılır. "tehdit" buraya
  /// yazılsa bile hiçbir etkisi olmaz.
  final Set<ToxicityCategory> susturulanlar;

  /// [susturulanlar]ın gerçekten uygulanacak kısmı.
  Set<ToxicityCategory> get gecerliSusturulanlar =>
      susturulanlar.where(susturulabilir.contains).toSet();

  const UslupAyarlari({
    this.etkin = true,
    this.hassasiyet = Hassasiyet.dengeli,
    this.susturulanlar = const {},
  });

  /// Susturulamayan kategorileri ayıklayarak kurar.
  factory UslupAyarlari.guvenli({
    bool etkin = true,
    Hassasiyet hassasiyet = Hassasiyet.dengeli,
    Iterable<ToxicityCategory> susturulanlar = const [],
  }) =>
      UslupAyarlari(
        etkin: etkin,
        hassasiyet: hassasiyet,
        susturulanlar: Set.unmodifiable(
            susturulanlar.where(susturulabilir.contains)),
      );

  /// Ürünün ölçülen davranışı.
  static const UslupAyarlari varsayilan = UslupAyarlari();

  /// Kullanıcının tek tek susturabileceği kategoriler. Gerekçe: dosya başı,
  /// kural 2. Genişletilmesi bir ürün kararıdır ve testle kilitlidir.
  static const Set<ToxicityCategory> susturulabilir = {
    ToxicityCategory.kufur,
    ToxicityCategory.asagilama,
  };

  /// Ayar varsayılanla aynı mı? Aynıysa politika çözümlemeye dokunmaz.
  bool get varsayilanMi =>
      etkin &&
      hassasiyet == Hassasiyet.dengeli &&
      !susturulanlar.any(susturulabilir.contains);

  UslupAyarlari copyWith({
    bool? etkin,
    Hassasiyet? hassasiyet,
    Iterable<ToxicityCategory>? susturulanlar,
  }) =>
      UslupAyarlari.guvenli(
        etkin: etkin ?? this.etkin,
        hassasiyet: hassasiyet ?? this.hassasiyet,
        susturulanlar: susturulanlar ?? this.susturulanlar,
      );

  /// Kalıcı depolama ve klavye kanalı için yalnızca ilkel türler.
  Map<String, Object> toMap() => {
        'etkin': etkin,
        'hassasiyet': hassasiyet.name,
        'susturulanlar': [for (final c in susturulanlar) c.name]..sort(),
      };

  /// Bozuk, eksik ya da eski biçimli veride varsayılana düşer; hiçbir
  /// durumda istisna fırlatmaz. Susturulamayan kategori adları ATILIR —
  /// depolamaya elle yazılmış "tehdit" bu yoldan susturulamaz.
  factory UslupAyarlari.fromMap(Object? veri) {
    if (veri is! Map) return varsayilan;
    final etkin = veri['etkin'];
    final hassasiyetAdi = veri['hassasiyet'];
    final liste = veri['susturulanlar'];
    return UslupAyarlari.guvenli(
      etkin: etkin is bool ? etkin : true,
      hassasiyet: Hassasiyet.values
              .where((h) => h.name == hassasiyetAdi)
              .firstOrNull ??
          Hassasiyet.dengeli,
      susturulanlar: [
        if (liste is List)
          for (final ad in liste)
            ...ToxicityCategory.values.where((c) => c.name == ad),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UslupAyarlari &&
      other.etkin == etkin &&
      other.hassasiyet == hassasiyet &&
      other.susturulanlar.length == susturulanlar.length &&
      other.susturulanlar.containsAll(susturulanlar);

  @override
  int get hashCode => Object.hash(etkin, hassasiyet,
      Object.hashAllUnordered(susturulanlar));

  @override
  String toString() => 'UslupAyarlari(${toMap()})';
}

/// Motorun çözümlemesini kullanıcı ayarına göre YANSITIR.
abstract final class MudahalePolitikasi {
  /// [analiz]in kullanıcıya gösterilecek hâli.
  ///
  /// Varsayılan ayarda [analiz]in kendisi döner (aynı örnek). Aksi hâlde:
  ///   • katman kapalıysa bulgusuz, temiz bir çözümleme — destek işareti
  ///     korunur;
  ///   • susturulan kategorilerin bulguları çıkarılır ve toksisite kalan
  ///     bulgulardan motorla AYNI yöntemle (noisy-OR) yeniden hesaplanır;
  ///   • basamak [basamak] ile seçilir; seçilen basamak hiçbir şey
  ///     göstermiyorsa bulgular da gösterilmez.
  static CivilityAnalysis uygula(CivilityAnalysis analiz, UslupAyarlari ayar) {
    if (ayar.varsayilanMi) return analiz;

    if (!ayar.etkin) return _sessiz(analiz);

    final susturulan = ayar.gecerliSusturulanlar;
    final gorunen = susturulan.isEmpty
        ? analiz.findings
        : [
            for (final f in analiz.findings)
              if (!susturulan.contains(f.category)) f,
          ];

    final toksisite = identical(gorunen, analiz.findings)
        ? analiz.toxicity
        : birlestir(gorunen);
    final risk = basamak(toksisite, ayar.hassasiyet);

    // "Yalnızca ağır" ayarında Riskli bir metin temiz görünür; bulguları
    // göstermek (vurgu, gerekçe paneli) ayarı delmek olurdu.
    if (risk == RiskLevel.temiz && gorunen.isNotEmpty &&
        ayar.hassasiyet == Hassasiyet.yalnizcaAgir) {
      return _sessiz(analiz);
    }

    return CivilityAnalysis(
      text: analiz.text,
      toxicity: toksisite,
      civilityScore: ((1.0 - toksisite) * 100).round().clamp(0, 100),
      risk: risk,
      findings: gorunen,
      signals: analiz.signals,
      elapsed: analiz.elapsed,
      needsSupport: analiz.needsSupport,
    );
  }

  /// Motorun birleştirme yöntemi: 1 − Π(1 − sᵢ).
  static double birlestir(List<ToxicityFinding> bulgular) {
    var tumleyen = 1.0;
    for (final f in bulgular) {
      tumleyen *= 1.0 - f.adjustedSeverity;
    }
    return (1.0 - tumleyen).clamp(0.0, 1.0);
  }

  /// Toksisiteyi hassasiyete göre basamağa çevirir. [Hassasiyet.dengeli]
  /// motorun eşikleridir (0,15 · 0,40 · 0,70).
  static RiskLevel basamak(double toksisite, Hassasiyet hassasiyet) =>
      switch (hassasiyet) {
        Hassasiyet.dengeli => toksisite < 0.15
            ? RiskLevel.temiz
            : toksisite < 0.40
                ? RiskLevel.dikkat
                : toksisite < 0.70
                    ? RiskLevel.riskli
                    : RiskLevel.yuksek,
        Hassasiyet.yalnizcaAgir =>
          toksisite < 0.70 ? RiskLevel.temiz : RiskLevel.yuksek,
        Hassasiyet.hassas => toksisite < 0.15
            ? RiskLevel.temiz
            : toksisite < 0.70
                ? RiskLevel.riskli
                : RiskLevel.yuksek,
      };

  static CivilityAnalysis _sessiz(CivilityAnalysis analiz) => CivilityAnalysis(
        text: analiz.text,
        toxicity: 0.0,
        civilityScore: 100,
        risk: RiskLevel.temiz,
        findings: const [],
        signals: analiz.signals,
        elapsed: analiz.elapsed,
        needsSupport: analiz.needsSupport,
      );
}
