// =============================================================================
// İP-35 · KİMLİK EKSENLERİ İKİNCİ AYRIK KÜME — ikinci turdan SONRA, tek geçiş
// Dosya: packages/civility_core/lib/src/eval/identity_axes_blind2_dataset.dart
//
// ── NEDEN ─────────────────────────────────────────────────────────────────
// İP-34'ün ilk geçişi kesinlik %100 · duyarlılık %15,0 verdi. Kaçaklar
// hata sınıflarına ayrıldı ve genel çözümler yazıldı (docs/26 §6); bu da
// İP-34'ü YAKTI. Bu küme o turdan SONRA yazıldı ve motor ona karşı bir kez
// çalıştırıldı. Sonuç docs/26 §7'dedir. Motor bu kümeye bakılarak
// DEĞİŞTİRİLMEYECEKTİR — İP-33 çalışmasının son geçerli sayısı budur.
//
// ── SINIRI ────────────────────────────────────────────────────────────────
// Yazan kişi kuruluşları bilir. Saldırı parçasında bilerek kapsanmayan
// biçimler de vardır (öjeni çağrısı, "tehdit oluşturuyor", tekil genel ad,
// iki cümlecikli dışlama). Tek etiketleyicilidir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class IdentityAxesBlind2Dataset {
  static const List<GoldCase> cases = [
    // ═══ A · Saldırı (20) ═══════════════════════════════════════════════════
    GoldCase.flag(text: 'Kadınlar mantıklı düşünemez, hep duygusal karar verirler', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik'),
    GoldCase.flag(text: 'Kadın şoför görünce hemen anlıyorum, yine sollamayı beceremedi', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik (tekil genel ad)'),
    GoldCase.flag(text: 'Kadınlar bilim insanı olamaz, beyinleri yetmez', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yetersizlik'),
    GoldCase.flag(text: 'Erkekler duygusal zekadan yoksun, hepsi hayvan', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · insanlıktan çıkarma'),
    GoldCase.flag(text: 'Kızların mühendislikte işi yok', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · cinsiyet · yer biçme'),
    GoldCase.flag(text: 'Yaşlı insanlar trafikte tehlike, ehliyetleri alınmalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · hak reddi'),
    GoldCase.flag(text: 'Bu moruklar yüzünden ülke batıyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · toplu suçlama (aşağılayıcı ad)'),
    GoldCase.flag(text: 'Yaşlılar gençlerin işini elinden alıyor, emekli olsunlar artık', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · suç atfı + yer biçme'),
    GoldCase.flag(text: 'Emekliler boş boş parkta oturup vergimizi yiyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · asalaklık atfı'),
    GoldCase.flag(text: 'Yaşlıların fikri sorulmamalı, çağın gerisinde kaldılar', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · yaş · hak reddi'),
    GoldCase.flag(text: 'Engelliler başkalarına muhtaç yaşar, kimseye faydası olmaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · işe yaramazlık'),
    GoldCase.flag(text: 'Otistiklerle aynı sınıfta okumak çocuğumun vaktini çalıyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · maliyet'),
    GoldCase.flag(text: 'Sağırlar işe alınmamalı, iletişim kuramazlar', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · hak reddi'),
    GoldCase.flag(text: 'Zihinsel engelliler kısırlaştırılmalı', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · varlık reddi (öjeni)'),
    GoldCase.flag(text: 'Tekerlekli sandalyeli biri bu işi asla yapamaz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · engellilik · yetersizlik (tekil genel ad)'),
    GoldCase.flag(text: 'Göçmenler geldiğinden beri sokaklar güvensiz', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · nedensel suçlama'),
    GoldCase.flag(text: 'Sığınmacılar kiraları uçurdu, hepsini gönderin', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · suç atfı + dışlama'),
    GoldCase.flag(text: 'Mülteciler bu ülkeye yük, bir an önce gitsinler', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · yük + dışlama'),
    GoldCase.flag(text: 'Afganların hepsi potansiyel suçlu', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · toplu suçlama'),
    GoldCase.flag(text: 'Göçmenler bizim kadınlarımıza tehdit oluşturuyor', group: GoldGroup.nefret, category: ToxicityCategory.nefret, note: 'A · göç · tehdit atfı'),

    // ═══ B · Masum (20) ═════════════════════════════════════════════════════
    GoldCase.clean(text: 'Kadınlar mantıklı düşünemez diyen yöneticiye kurul uyarı verdi', group: GoldGroup.nefret, note: 'B · cinsiyet · aktarıp kınama'),
    GoldCase.clean(text: 'Kadın şoförlerin kaza oranı erkeklerden düşük çıktı', group: GoldGroup.nefret, note: 'B · cinsiyet · veri'),
    GoldCase.clean(text: 'Kızların mühendislikte başarılı olması için burs programı açıldı', group: GoldGroup.nefret, note: 'B · cinsiyet · hizmet'),
    GoldCase.clean(text: 'Erkekler de duygularını rahatça ifade edebilmeli', group: GoldGroup.nefret, note: 'B · cinsiyet · kalıp yargıya karşı'),
    GoldCase.clean(text: 'Kadınlar bu işi yapamaz mı sandın, sonuçlara bak', group: GoldGroup.nefret, note: 'B · cinsiyet · önyargıyı çürütme'),
    GoldCase.clean(text: 'Yaşlı insanların ehliyet yenilemesinde sağlık raporu isteniyor', group: GoldGroup.nefret, note: 'B · yaş · mevzuat bilgisi'),
    GoldCase.clean(text: 'Emekliler parkta satranç turnuvası düzenledi', group: GoldGroup.nefret, note: 'B · yaş · haber'),
    GoldCase.clean(text: 'Yaşlıların fikri sorulmadan bu park projesi yapılmamalı', group: GoldGroup.nefret, note: 'B · yaş · katılım savunusu'),
    GoldCase.clean(text: 'Yaşlılar gençlerle aynı teknoloji kursunda buluştu', group: GoldGroup.nefret, note: 'B · yaş · haber'),
    GoldCase.clean(text: 'Dedem emekli olduğundan beri gönüllü öğretmenlik yapıyor', group: GoldGroup.nefret, note: 'B · yaş · kişisel'),
    GoldCase.clean(text: 'Engelliler başkalarına muhtaç değil, erişim imkânına muhtaç', group: GoldGroup.nefret, note: 'B · engellilik · hak savunusu'),
    GoldCase.clean(text: 'Otistik öğrencilerle aynı sınıfta okumak çocuğuma empati öğretti', group: GoldGroup.nefret, note: 'B · engellilik · kişisel'),
    GoldCase.clean(text: 'Sağırlar için işaret dili tercümanı işe alınmalı', group: GoldGroup.nefret, note: 'B · engellilik · hak savunusu'),
    GoldCase.clean(text: 'Zihinsel engelliler için istihdam kotası artırılmalı', group: GoldGroup.nefret, note: 'B · engellilik · politika'),
    GoldCase.clean(text: 'Tekerlekli sandalyeli sporcumuz olimpiyatta altın aldı', group: GoldGroup.nefret, note: 'B · engellilik · haber'),
    GoldCase.clean(text: 'Göçmenler geldiğinden beri mahallenin fırını hiç bu kadar kazanmamıştı', group: GoldGroup.nefret, note: 'B · göç · olumlu'),
    GoldCase.clean(text: 'Sığınmacılar kiraların arttığı mahallelerde en çok zorlanan grup', group: GoldGroup.nefret, note: 'B · göç · hak savunusu'),
    GoldCase.clean(text: 'Mültecilerin bu ülkeye yük olduğu yalanını kimse yemiyor', group: GoldGroup.nefret, note: 'B · göç · önyargıyı çürütme'),
    GoldCase.clean(text: 'Afganların hepsi aynı dili konuşmuyor, Peştuca ve Darice var', group: GoldGroup.nefret, note: 'B · göç · bilgi'),
    GoldCase.clean(text: 'Göçmen kadınlara yönelik tehditler raporlandı', group: GoldGroup.nefret, note: 'B · göç · haber'),
  ];
}
