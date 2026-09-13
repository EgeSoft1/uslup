// =============================================================================
// İP-31 · YÖNELİM KÜMESİ — somut adlar ve ikinci şahıs
// Dosya: packages/civility_core/lib/src/eval/direction_dataset.dart
//
// ── NEDEN ─────────────────────────────────────────────────────────────────
// Hayvan adları ve somut anlamı yaygın bazı adlar ("hıyar", "komedi")
// sözlükte yönelim şartıyla durur: "köpeğim hasta" temiz, "köpeksin"
// hakaret. Yönelim ise YAKINLIKLA belirleniyordu — dört kelimelik pencerede
// "sana", "senin", "sen" geçmesi yetiyordu. 13 Eylül'deki küme dışı taramada
// ikinci şahıs geçen 13 gündelik cümlenin 12'si işaretlendi:
//
//   "Sana köpeğimin fotoğrafını atayım"          → Yüksek risk
//   "Senin için domuz eti yok, merak etme"       → Yüksek risk
//   "Sana yeni bir fare aldım"                   → Riskli
//
// ── PROTOKOL VE SINIRI ────────────────────────────────────────────────────
// Hata sınıfı bilindikten sonra, düzeltme (docs/21, D7) yazılmadan ÖNCE
// yazıldı ve düzeltmeden önce commit edildi. Taramadaki 18 cümle bu kümeye
// ALINMADI; hepsi yeniden yazıldı. Küme hata sınıfına kör değildir.
//
// İki parça:
//   A. 30 masum cümle — adlar gerçek anlamında, ikinci şahıs yüklem ya da
//      hitap DIŞI bir görevde (yönelme, tamlama, özne + başka yüklem).
//   B. 20 saldırı — aynı adlar yüklem, hitap, soru, "gibi" benzetmesi ya da
//      aşağılayıcı baş kelimeyle muhataba yöneltilmiş. Düzeltmenin
//      duyarlılığı düşürmediğinin sınavıdır.
//
// Tek etiketleyicilidir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class DirectionDataset {
  static const List<GoldCase> cases = [
    // ═══ A · Masum — somut anlam, ikinci şahıs yüklem/hitap dışı (30) ═══════
    GoldCase.clean(text: 'Sana bahçedeki kazları göstereyim', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin köyde hâlâ manda yetiştiriyorlar mı?', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Sen hiç deve ya da katır bindin mi?', group: GoldGroup.masum, note: 'A · özne + başka yüklem'),
    GoldCase.clean(text: 'Sana hamamböceği ilacı aldım, mutfağa sıktım', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin bilgisayarın faresi bozulmuş, yenisini getirdim', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Seninle hayvanat bahçesine gidip ayıları izledik', group: GoldGroup.masum, note: 'A · birliktelik'),
    GoldCase.clean(text: 'Sana tavuk pişireyim, domuz eti yemediğini biliyorum', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin bahçende kurbağalar ötüyordu dün gece', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Sen de köpeğini gezdirmeye çıkar mısın?', group: GoldGroup.masum, note: 'A · özne + başka yüklem'),
    GoldCase.clean(text: 'Sana kargalar hakkında bir belgesel önereyim', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin için kene aşısını ayarladım veterinerde', group: GoldGroup.masum, note: 'A · için'),
    GoldCase.clean(text: 'Sana bir komedi filmi önerebilirim, dram sevmiyorsan', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin getirdiğin keçi peynirini çok sevdim', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Sen maymunlar hakkında ödev hazırlıyordun, bu kitap işine yarar', group: GoldGroup.masum, note: 'A · özne + başka yüklem'),
    GoldCase.clean(text: 'Sana hıyar mı domates mi lazım?', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin yılan korkun geçti mi?', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Sana solucan gübresi getirdim, saksılara karıştır', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin çektiğin öküz arabası fotoğrafı çok güzel', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Sana eşeklerin ne kadar zeki olduğunu anlatan bir yazı attım', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senden sonra kediyle köpek kavga etti', group: GoldGroup.masum, note: 'A · ayrılma'),
    GoldCase.clean(text: 'Sana akbabaların göç rotasını gösteren haritayı yolladım', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin evde fare mi var, tıkırtı geliyor', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Sen sülük tedavisine inanıyor musun?', group: GoldGroup.masum, note: 'A · özne + başka yüklem'),
    GoldCase.clean(text: 'Sana böcek kovucu sprey aldım', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin önerdiğin sırtlan belgeselini izledim', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Sana çakalların gece neden uluduğunu anlatayım', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Seninle kaz yemeğine gidelim mi?', group: GoldGroup.masum, note: 'A · birliktelik'),
    GoldCase.clean(text: 'Sana en çok hangi hayvan ilginç geliyor, ayı mı kurt mu?', group: GoldGroup.masum, note: 'A · yönelme'),
    GoldCase.clean(text: 'Senin barınaktaki hayvanlar için mama topladık', group: GoldGroup.masum, note: 'A · tamlama'),
    GoldCase.clean(text: 'Sana köyden manda yoğurdu getireyim mi?', group: GoldGroup.masum, note: 'A · yönelme'),

    // ═══ B · Saldırı — yüklem, hitap, soru, benzetme, aşağılayıcı baş (20) ═══
    GoldCase.flag(text: 'sen tam bir öküzsün', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · yüklem eki'),
    GoldCase.flag(text: 'seni gidi domuz seni', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · hitap'),
    GoldCase.flag(text: 'sen ne biçim bir hayvansın', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · yüklem eki'),
    GoldCase.flag(text: 'köpek misin sen', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · soru eki'),
    GoldCase.flag(text: 'maymun gibi davranıyorsun', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · gibi + 2. şahıs'),
    GoldCase.flag(text: 'sen resmen bir akbabasın', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · yüklem eki'),
    GoldCase.flag(text: 'eşek herif, çekil yolumdan', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · aşağılayıcı baş'),
    GoldCase.flag(text: 'sülük gibisin, bırak artık yakamı', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · gibisin'),
    GoldCase.flag(text: 'sen bir asalaksın', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · yüklem eki'),
    GoldCase.flag(text: 'kene gibi yapıştın bize', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · gibi + 2. şahıs geçmiş'),
    GoldCase.flag(text: 'yılan gibi sokuluyorsun herkese', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · gibi + 2. şahıs'),
    GoldCase.flag(text: 'seni katır seni', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · hitap'),
    GoldCase.flag(text: 'sen hıyarın önde gidenisin', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · aşağılayıcı tamlama'),
    GoldCase.flag(text: 'ayı mısın be', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · soru eki'),
    GoldCase.flag(text: 'manda gibi yayılmışsın koltuğa', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · gibi + 2. şahıs'),
    GoldCase.flag(text: 'sen sırtlanın tekisin', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · aşağılayıcı tamlama'),
    GoldCase.flag(text: 'solucan herif', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · aşağılayıcı baş'),
    GoldCase.flag(text: 'sen tam bir çakalsın', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · yüklem eki'),
    GoldCase.flag(text: 'sen kaz kafalı bir hıyarsın', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · yüklem eki'),
    GoldCase.flag(text: 'domuzsunuz hepiniz', group: GoldGroup.acikSaldiri, category: ToxicityCategory.hakaret, note: 'B · çoğul yüklem eki'),
  ];
}
