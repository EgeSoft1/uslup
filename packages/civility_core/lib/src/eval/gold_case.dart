// =============================================================================
// Altın Standart Veri Kümesi — Veri Modeli
// Dosya: packages/civility_core/lib/src/eval/gold_case.dart
//
// Bir sınıflandırıcının "çalıştığını" testlerin geçmesiyle iddia edemezsiniz.
// Testler seçilmiş örneklerdir; metrik ise dengeli bir küme üzerinde ölçülen
// kesinlik (precision), duyarlılık (recall) ve F1'dir.
//
// ── DÜRÜSTLÜK NOTU (teknik rapora aynen girmeli) ──────────────────────────
// Bu küme TEK BİR geliştirici tarafından etiketlenmiştir. Hakemler arası
// uyum (Cohen's kappa) ÖLÇÜLMEMİŞTİR ve küme bir akademik referans kümesi
// değildir. Amacı iki şeydir:
//   1. Regresyon kalkanı — motor değiştiğinde neyin bozulduğunu göstermek.
//   2. Taban çizgisi — ikinci bir etiketleyici geldiğinde karşılaştırılacak
//      ilk ölçüm noktası.
// Raporda "F1 = X" denirken bu koşul MUTLAKA belirtilmelidir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';

/// Örneğin ait olduğu değerlendirme dilimi.
///
/// Dilimleme, tek bir toplu F1 sayısından çok daha bilgilendiricidir:
/// bir modelin açık küfürde %99, örtük saldırıda %10 başarı göstermesi
/// toplamda "iyi" görünebilir ama ürün olarak işe yaramaz.
enum GoldGroup {
  /// Sözlükte karşılığı olan açık hakaret, küfür, tehdit.
  acikSaldiri,

  /// Küfür içermeyen düşmanlık: küçümseme, ötekileştirme, alaycılık,
  /// susturma, örtük tehdit. Sözlük tabanlı sistemlerin kör noktası.
  ortukSaldiri,

  /// Kimlik hedefli nefret söylemi VE onun yakın-kaçışları.
  ///
  /// Bu dilim kasıtlı olarak iki yönlüdür: hem "yakalıyor mu" hem de
  /// "kimliğinden söz eden masum insanı yakalamıyor mu" sorusunu birlikte
  /// ölçer. İkincisi bu üründe daha kritiktir — kimlik adlarını toksik
  /// sayan bir sistem korumaya çalıştığı grubu susturur.
  nefret,

  /// Masum metin. İçinde saldırgan alt dizi barındıran meşru kelimeler
  /// ("şikayet", "malzeme", "götürdü") ve sıradan cümleler.
  masum,

  /// Bağlamın kararı tersine çevirdiği durumlar: olumsuzlama, alıntı,
  /// öz-ifade. Mağduru cezalandırmama testi.
  baglam,
}

extension GoldGroupInfo on GoldGroup {
  String get label => switch (this) {
        GoldGroup.acikSaldiri => 'Açık saldırı',
        GoldGroup.ortukSaldiri => 'Örtük saldırı',
        GoldGroup.nefret => 'Nefret söylemi',
        GoldGroup.masum => 'Masum / tuzak',
        GoldGroup.baglam => 'Bağlam',
      };
}

/// Etiketli tek bir değerlendirme örneği.
class GoldCase {
  final String text;

  /// Motor bu metne müdahale ETMELİ mi? (risk != temiz)
  ///
  /// Bu, ikili sınıflandırma görevinin altın etiketidir.
  final bool shouldFlag;

  /// Beklenen baskın kategori. `shouldFlag` false ise null.
  /// Kategori doğruluğu ayrıca raporlanır.
  final ToxicityCategory? expectedCategory;

  final GoldGroup group;

  /// Bu örneğin neden var olduğu. Hata ayıklarken en değerli alan:
  /// bir örnek kaybedildiğinde hangi yeteneğin bozulduğunu söyler.
  final String note;

  const GoldCase({
    required this.text,
    required this.shouldFlag,
    required this.group,
    required this.note,
    this.expectedCategory,
  });

  /// Müdahale beklenen örnek.
  const GoldCase.flag({
    required this.text,
    required this.group,
    required this.note,
    required ToxicityCategory category,
  })  : shouldFlag = true,
        expectedCategory = category;

  /// Müdahale beklenmeyen örnek.
  const GoldCase.clean({
    required this.text,
    required this.group,
    required this.note,
  })  : shouldFlag = false,
        expectedCategory = null;
}
