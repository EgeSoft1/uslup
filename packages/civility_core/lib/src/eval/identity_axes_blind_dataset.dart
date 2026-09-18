// =============================================================================
// İP-34 · KİMLİK EKSENLERİ AYRIK KÜMESİ — düzeltmeden SONRA, tek geçiş
// Dosya: packages/civility_core/lib/src/eval/identity_axes_blind_dataset.dart
//
// ── NEDEN ─────────────────────────────────────────────────────────────────
// İP-33 düzeltmenin yazıldığı kümedir; oradaki 31/32 bir ezber ölçüsüdür.
// Bu küme İP-33 kuruluşları (docs/26) TAMAMLANDIKTAN SONRA yazıldı ve
// motor ona karşı bir kez çalıştırıldı. İlk geçişin sonucu docs/26 §5'te
// kayıtlıdır ve bu kümeye bakılarak motor DEĞİŞTİRİLMEYECEKTİR; değişirse
// küme yanar ve bu başlığa yazılır.
//
// ── SINIRI ────────────────────────────────────────────────────────────────
// Yazan kişi yeni kuruluşları bilir; küme bu anlamda kör değildir. Bunu
// dengelemek için saldırı parçasına kuruluşların BİLEREK kapsamadığı
// biçimler de yazıldı: şimdiki zaman ("beceremiyor"), yuvada olmayan grup
// adları ("emekliler", "sakatlar", "kadın milleti"), eğretileme ("ekmeğimizi
// yiyor"). Masum parça aynı kelimeleri taşır.
//
// Eksen başına beşer örnek. Tek etiketleyicilidir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class IdentityAxesBlindDataset {
  static const List<GoldCase> cases = [
    // ═══ A · Saldırı (20) ═══════════════════════════════════════════════════
    GoldCase.flag(text: 'Kadın milleti para yönetmeyi bilmez', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik (yuva dışı ad)'),
    GoldCase.flag(text: 'Kadınlar liderlik yapamaz, fazla duygusallar', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik'),
    GoldCase.flag(text: 'Erkekler bulaşık yıkamayı bile beceremiyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik (şimdiki zaman)'),
    GoldCase.flag(text: 'Kadınların futbolla ne işi var, evde otursunlar', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yer biçme'),
    GoldCase.flag(text: 'Kadınlara ehliyet verilmemeli', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · hak reddi'),
    GoldCase.flag(text: 'Yaşlılar bu ülkenin geleceğini karartıyor, oy hakları alınmalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · hak reddi'),
    GoldCase.flag(text: 'Bu ihtiyarlar da artık ölüp gitse', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · varlık reddi (yuva dışı ad)'),
    GoldCase.flag(text: 'Yaşlıların sosyal medyada ne işi var', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · yer biçme'),
    GoldCase.flag(text: 'Yaşlılar hiçbir şeyi öğrenemez, zaman kaybı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · yetersizlik'),
    GoldCase.flag(text: 'Emekliler bir işe yaramaz, maaşları kesilmeli', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · işe yaramazlık (yuva dışı ad)'),
    GoldCase.flag(text: 'Engelliler topluma bir şey katmaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · değersizleştirme'),
    GoldCase.flag(text: 'Otizmli çocuklar normal okullara alınmamalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · hak reddi'),
    GoldCase.flag(text: 'Sakatlar ortalıkta dolaşmasın', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · yer biçme (yuva dışı ad)'),
    GoldCase.flag(text: 'Zihinsel engelliler hiçbir şeyi anlamaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · yetersizlik'),
    GoldCase.flag(text: 'Engellilere para harcamak boşa gidiyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · maliyet'),
    GoldCase.flag(text: 'Suriyeliler bizim ekmeğimizi yiyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · suç atfı (eğretileme)'),
    GoldCase.flag(text: 'Göçmenler ülkeyi istila etti', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · istila atfı (geçmiş zaman)'),
    GoldCase.flag(text: 'Afganlar sınırdan akın ediyor, hepsi suçlu', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · istila + toplu suçlama'),
    GoldCase.flag(text: 'Sığınmacılar devletin sırtında yaşıyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · asalaklık atfı'),
    GoldCase.flag(text: 'Mülteciler hiçbir zaman bu topluma uyum sağlayamaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · yetersizlik'),

    // ═══ B · Masum (20) ═════════════════════════════════════════════════════
    GoldCase.clean(text: 'Kadınlar liderlik yapamaz diyenler bu seçimi izlesin', group: GoldGroup.nefret, note: 'B · cinsiyet · aktarıp çürütme'),
    GoldCase.clean(text: 'Kadınların futbolda ne kadar başarılı olduğunu gördük', group: GoldGroup.nefret, note: 'B · cinsiyet · olumlu'),
    GoldCase.clean(text: 'Kadınlara ehliyet kursunda yüzde yirmi indirim var', group: GoldGroup.nefret, note: 'B · cinsiyet · hizmet'),
    GoldCase.clean(text: 'Erkekler de bulaşık yıkayabilir, bu bir beceri değil alışkanlık', group: GoldGroup.nefret, note: 'B · cinsiyet · kalıp yargıya karşı'),
    GoldCase.clean(text: 'Kadın mühendislerin sayısı son on yılda iki katına çıktı', group: GoldGroup.nefret, note: 'B · cinsiyet · haber'),
    GoldCase.clean(text: 'Yaşlıların sosyal medyada dolandırılmaması için eğitim veriyoruz', group: GoldGroup.nefret, note: 'B · yaş · hizmet'),
    GoldCase.clean(text: 'Yaşlılar sıcak havalarda bol su içmeli', group: GoldGroup.nefret, note: 'B · yaş · sağlık önerisi'),
    GoldCase.clean(text: 'Emekliler maaşlarının geç yattığını söylüyor', group: GoldGroup.nefret, note: 'B · yaş · haber'),
    GoldCase.clean(text: 'Yaşlılar hiçbir şeyi öğrenemez sanılıyor ama kursumuz dolu', group: GoldGroup.nefret, note: 'B · yaş · önyargıyı çürütme'),
    GoldCase.clean(text: 'Babaannem yetmiş yaşında yüzmeyi öğrendi', group: GoldGroup.nefret, note: 'B · yaş · kişisel'),
    GoldCase.clean(text: 'Engelliler topluma çok şey katıyor, yeter ki önleri açılsın', group: GoldGroup.nefret, note: 'B · engellilik · olumlu'),
    GoldCase.clean(text: 'Otizmli çocuklar için kaynaştırma sınıfları yetersiz', group: GoldGroup.nefret, note: 'B · engellilik · hak savunusu'),
    GoldCase.clean(text: 'Zihinsel engelliler için hazırlanan kitaplar çok anlaşılır', group: GoldGroup.nefret, note: 'B · engellilik · hizmet'),
    GoldCase.clean(text: 'Engellilere ayrılan bütçe bu yıl artırılmalı', group: GoldGroup.nefret, note: 'B · engellilik · politika'),
    GoldCase.clean(text: 'Belediye engelliler için ücretsiz servis başlattı', group: GoldGroup.nefret, note: 'B · engellilik · haber'),
    GoldCase.clean(text: 'Suriyeliler bizim ekmeğimizi yiyor sözü ırkçı bir klişe', group: GoldGroup.nefret, note: 'B · göç · aktarıp kınama'),
    GoldCase.clean(text: 'Göçmenler bu şehre yeni bir kültür kattı', group: GoldGroup.nefret, note: 'B · göç · olumlu'),
    GoldCase.clean(text: 'Afganlar sınırda günlerce bekletiliyor, insanlık dışı', group: GoldGroup.nefret, note: 'B · göç · hak ihlali bildirimi'),
    GoldCase.clean(text: 'Sığınmacılar devletin desteğiyle iş kurmayı öğreniyor', group: GoldGroup.nefret, note: 'B · göç · haber'),
    GoldCase.clean(text: 'Mültecilerin topluma uyum sağlaması için dil kursu şart', group: GoldGroup.nefret, note: 'B · göç · politika'),
  ];
}
