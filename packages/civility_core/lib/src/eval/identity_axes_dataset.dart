// =============================================================================
// İP-33 · KİMLİK EKSENLERİ KÜMESİ — cinsiyet, yaş, engellilik, göç
// Dosya: packages/civility_core/lib/src/eval/identity_axes_dataset.dart
//
// ── NEDEN ─────────────────────────────────────────────────────────────────
// Nefret katmanının kimlik söz varlığı dört ekseni de kapsıyor (kadınlar,
// yaşlılar, engelliler, göçmenler…), ama YÜKLEM söz varlığı etnik ve inanç
// eksenindeki düşmanlık için yazıldı: hırsız, hain, defolsun, yok edilmeli.
// Bu dört eksendeki düşmanlık çoğunlukla başka bir kılıkta gelir:
//
//   • YETERSİZLİK ATFI   "…beceremez", "…anlamaz", "aklı ermez"
//   • YER BİÇME          "…yeri evidir", "…sokağa çıkmasın"
//   • HAK REDDİ          "…çalışmamalı", "…oy kullanmamalı"
//   • İŞE YARAMAZLIK     "hiçbir işe yaramaz", "…bir halt olmaz"
//   • SUÇ/İSTİLA ATFI    "işimizi çalıyor", "ülkeyi işgal ediyor"
//
// Sunumda "dört eksen de kapsanıyor" demeden önce bu ölçülmeli.
//
// ── PROTOKOL VE SINIRI ────────────────────────────────────────────────────
// Hata sınıfı bilindikten SONRA, düzeltmeden (docs/26) ÖNCE yazıldı; motor
// bu kümeye karşı yazım sırasında hiç çalıştırılmadı. Yazan kişi örüntü
// kataloğunu bilir — küme bu yüzden KÖR DEĞİLDİR, düzeltme öncesi kaydıdır.
// Düzeltmeden sonra alınan sayı bir genelleme kanıtı sayılmaz.
//
// İki parça, eksen başına sekizer örnek:
//   A. 32 saldırı — beş kılığın dört eksene dağılmış hâli.
//   B. 32 masum  — AYNI fiilleri ve kalıpları taşıyan meşru cümleler:
//      durum bildiren engeller ("rampa bozuk olduğu için binemiyor"),
//      kamu uyarıları ("yaşlılar öğle saatlerinde dışarı çıkmasın"),
//      iş hukuku ("doğum sonrası ağır işte çalışmamalı"), önyargıyı
//      çürüten cümleler ve politika eleştirisi. Bu parça A'dan daha
//      önemlidir: bu dört grubun HAKLARINI savunan cümleleri işaretleyen
//      bir filtre, korumaya çalıştığı insanları susturur.
//
// Tek etiketleyicilidir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class IdentityAxesDataset {
  static const List<GoldCase> cases = [
    // ═══ A · Saldırı (32) ═══════════════════════════════════════════════════
    // ── cinsiyet
    GoldCase.flag(text: 'Kadınlar araba kullanmayı hiç beceremez', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik'),
    GoldCase.flag(text: 'Kadınlar siyasetten anlamaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik'),
    GoldCase.flag(text: 'Kadınların yeri evidir', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yer biçme'),
    GoldCase.flag(text: 'Kadınlar çalışmamalı, çocuk bakmalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · hak reddi'),
    GoldCase.flag(text: 'Kadından mühendis olmaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · tekil genelleme'),
    GoldCase.flag(text: 'Kadınlara yönetici koltuğu verilmemeli', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · hak reddi'),
    GoldCase.flag(text: 'Erkekler çocuk bakmayı beceremez zaten', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik'),
    GoldCase.flag(text: 'Kadınların aklı bu işlere ermez', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik'),
    // ── yaş
    GoldCase.flag(text: 'Yaşlılar teknolojiden hiçbir şey anlamaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · yetersizlik'),
    GoldCase.flag(text: 'Yaşlılar artık hiçbir işe yaramıyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · işe yaramazlık'),
    GoldCase.flag(text: 'Yaşlılar oy kullanmamalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · hak reddi'),
    GoldCase.flag(text: 'Bu yaşlılar ölse de kurtulsak', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · varlık reddi'),
    GoldCase.flag(text: 'Yaşlıların aklı hiçbir şeye ermez', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · yetersizlik'),
    GoldCase.flag(text: 'Yaşlılar sokağa çıkmasın, ayak altında dolaşıyorlar', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · yer biçme'),
    GoldCase.flag(text: 'Yaşlılara iş vermek para israfı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · değersizleştirme'),
    GoldCase.flag(text: 'Yaşlılar yeni bir şey öğrenemez, boşuna uğraşmayın', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · yetersizlik'),
    // ── engellilik
    GoldCase.flag(text: 'Engelliler hiçbir işe yaramaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · işe yaramazlık'),
    GoldCase.flag(text: 'Engelli çalıştırmak şirkete zarar', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · değersizleştirme'),
    GoldCase.flag(text: 'Otistikler normal insan değildir', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · insanlıktan çıkarma'),
    GoldCase.flag(text: 'Engelliler evden çıkmamalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · yer biçme'),
    GoldCase.flag(text: 'Sağırlarla uğraşmak zaman kaybı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · değersizleştirme'),
    GoldCase.flag(text: 'Down sendromlular okula alınmamalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · hak reddi'),
    GoldCase.flag(text: 'Engellilerden bir halt olmaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · işe yaramazlık'),
    GoldCase.flag(text: 'Görme engelliler hiçbir şeyi beceremez', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · yetersizlik'),
    // ── göç
    GoldCase.flag(text: 'Göçmenler işimizi çalıyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · suç atfı'),
    GoldCase.flag(text: 'Sığınmacılar bizim vergimizle bedava yaşıyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · asalaklık atfı'),
    GoldCase.flag(text: 'Mülteciler suç işlemekten başka bir şey bilmez', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · suç atfı'),
    GoldCase.flag(text: 'Göçmenler ülkemizi işgal ediyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · istila atfı'),
    GoldCase.flag(text: 'Sığınmacıların hepsi bedavacı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · asalaklık atfı'),
    GoldCase.flag(text: 'Göçmenler geldi geleli mahallede huzur kalmadı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · suç atfı (nedensel)'),
    GoldCase.flag(text: 'Mültecilere hiçbir hak tanınmamalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · hak reddi'),
    GoldCase.flag(text: 'Göçmenler bu ülkenin kanını emiyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · insanlıktan çıkarma (eğretileme)'),

    // ═══ B · Masum (32) ═════════════════════════════════════════════════════
    // ── cinsiyet
    GoldCase.clean(text: 'Kadınlar da erkekler kadar iyi araba kullanır', group: GoldGroup.nefret, note: 'B · cinsiyet · olumlu genelleme'),
    GoldCase.clean(text: 'Kadınların yeri neresi olacağına kendileri karar verir', group: GoldGroup.nefret, note: 'B · cinsiyet · "yeri" savunma'),
    GoldCase.clean(text: 'Kadınlar gece bu sokakta yürüyemiyor, aydınlatma şart', group: GoldGroup.nefret, note: 'B · cinsiyet · durum bildiren engel'),
    GoldCase.clean(text: 'Kadınlar korosu yarın akşam konser veriyor', group: GoldGroup.nefret, note: 'B · cinsiyet · tamlama'),
    GoldCase.clean(text: 'Kim demiş kadınlar mühendis olamaz diye?', group: GoldGroup.nefret, note: 'B · cinsiyet · önyargıyı çürütme'),
    GoldCase.clean(text: 'Kadınlar çalışmamalı diyenlere karşı sesimizi yükseltiyoruz', group: GoldGroup.nefret, note: 'B · cinsiyet · aktarıp kınama'),
    GoldCase.clean(text: 'Erkekler de ağlayabilir, bunda utanılacak bir şey yok', group: GoldGroup.nefret, note: 'B · cinsiyet · kalıp yargıya karşı'),
    GoldCase.clean(text: 'Doğum sonrası ilk altı hafta kadınlar ağır işte çalışmamalı', group: GoldGroup.nefret, note: 'B · cinsiyet · iş hukuku'),
    // ── yaş
    GoldCase.clean(text: 'Yaşlılar bu uygulamayı kullanamıyor, yazılar çok küçük', group: GoldGroup.nefret, note: 'B · yaş · tasarım eleştirisi'),
    GoldCase.clean(text: 'Yaşlıların teknolojiden anlamadığı bir önyargı, annem benden iyi kullanıyor', group: GoldGroup.nefret, note: 'B · yaş · önyargıyı çürütme'),
    GoldCase.clean(text: 'Yaşlılar yurdundaki etkinlik için gönüllü arıyoruz', group: GoldGroup.nefret, note: 'B · yaş · tamlama'),
    GoldCase.clean(text: 'Sıcak hava uyarısı: yaşlılar öğle saatlerinde dışarı çıkmasın', group: GoldGroup.nefret, note: 'B · yaş · kamu uyarısı'),
    GoldCase.clean(text: 'Yaşlılara öncelik verilmeli, sırada çok bekliyorlar', group: GoldGroup.nefret, note: 'B · yaş · olumlu gereklilik'),
    GoldCase.clean(text: 'Dedem seksen yaşında ama hâlâ bahçede çalışıyor', group: GoldGroup.nefret, note: 'B · yaş · kişisel'),
    GoldCase.clean(text: 'Yaşlıların yalnızlığı üzerine bir belgesel çekiyoruz', group: GoldGroup.nefret, note: 'B · yaş · araştırma'),
    GoldCase.clean(text: 'Yaşlılar hiçbir işe yaramaz diyen reklam büyük tepki çekti', group: GoldGroup.nefret, note: 'B · yaş · aktarıp kınama'),
    // ── engellilik
    GoldCase.clean(text: 'Engelliler bu otobüse binemiyor çünkü rampa bozuk', group: GoldGroup.nefret, note: 'B · engellilik · durum bildiren engel'),
    GoldCase.clean(text: 'Engelliler de her işi yapabilir, yeter ki fırsat verilsin', group: GoldGroup.nefret, note: 'B · engellilik · olumlu genelleme'),
    GoldCase.clean(text: 'Kar yağışı nedeniyle engelli vatandaşlar zorunlu olmadıkça evden çıkmamalı', group: GoldGroup.nefret, note: 'B · engellilik · kamu uyarısı'),
    GoldCase.clean(text: 'Engelliler derneği bu hafta resim sergisi açıyor', group: GoldGroup.nefret, note: 'B · engellilik · tamlama'),
    GoldCase.clean(text: 'İşaret dili bilen olmadığı için sağırlar hastanede derdini anlatamıyor', group: GoldGroup.nefret, note: 'B · engellilik · durum bildiren engel'),
    GoldCase.clean(text: 'Engellilerin çalışamayacağını sanan işverenler yanılıyor', group: GoldGroup.nefret, note: 'B · engellilik · önyargıyı çürütme'),
    GoldCase.clean(text: 'Görme engelliler için sesli kütüphane uygulaması geliştirdik', group: GoldGroup.nefret, note: 'B · engellilik · hizmet'),
    GoldCase.clean(text: 'Engelli kardeşim üniversiteyi dereceyle bitirdi', group: GoldGroup.nefret, note: 'B · engellilik · kişisel'),
    // ── göç
    GoldCase.clean(text: 'Göçmenler bu fabrikada yıllardır sigortasız çalıştırılıyor', group: GoldGroup.nefret, note: 'B · göç · hak ihlali bildirimi'),
    GoldCase.clean(text: 'Sığınmacılar için Türkçe kursu ücretsiz başladı', group: GoldGroup.nefret, note: 'B · göç · hizmet'),
    GoldCase.clean(text: 'Mülteciler savaştan kaçtıkları için buradalar, anlayış göstermeliyiz', group: GoldGroup.nefret, note: 'B · göç · savunma'),
    GoldCase.clean(text: 'Göçmenlerin işimizi çaldığı iddiası verilerle çürütüldü', group: GoldGroup.nefret, note: 'B · göç · önyargıyı çürütme'),
    GoldCase.clean(text: 'Mülteciler ülkelerine dönmek istiyor ama savaş hâlâ bitmedi', group: GoldGroup.nefret, note: 'B · göç · "ülkelerine dön" yakın-kaçış'),
    GoldCase.clean(text: 'Sığınmacı sayısı ve maliyeti hakkında şeffaf veri paylaşılmalı', group: GoldGroup.nefret, note: 'B · göç · politika eleştirisi'),
    GoldCase.clean(text: 'Göçmenlerin hepsi aynı değil, her birinin hikâyesi farklı', group: GoldGroup.nefret, note: 'B · göç · genellemeye karşı'),
    GoldCase.clean(text: 'Komşumuz Afgan bir aile, çocukları okulda çok başarılı', group: GoldGroup.nefret, note: 'B · göç · kişisel'),
  ];
}
