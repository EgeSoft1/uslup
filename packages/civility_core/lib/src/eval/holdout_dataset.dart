// =============================================================================
// AYRIK (HOLD-OUT) KÜME — genelleme ölçümü
// Dosya: packages/civility_core/lib/src/eval/holdout_dataset.dart
//
// ── NEDEN VAR ─────────────────────────────────────────────────────────────
// Örtük saldırı örüntüleri, `gold_dataset.dart` görüldükten SONRA yazıldı.
// O küme üzerinde ölçülen %100 başarı bu yüzden GENELLEME KANITI DEĞİLDİR;
// büyük ölçüde ezberleme olabilir. Bir modelin kendi geliştirme kümesindeki
// skoru, o modelin işe yarayıp yaramadığı hakkında çok az şey söyler.
//
// Bu küme o soruyu yanıtlamak için vardır. Kural:
//
//   1. Cümleler, örüntülerin düzenli ifadelerine BAKILMADAN yazıldı.
//      Yöntem: her edimbilimsel yapı için "gerçek bir kullanıcı bunu başka
//      nasıl yazardı" sorusu soruldu — çekim değiştirildi, kelime sırası
//      bozuldu, tekil/çoğul çevrildi, eşanlamlı kullanıldı.
//   2. Ölçüm BİR KEZ alındı.
//   3. Sonuçlar, düzeltme yapılMADAN raporlandı.
//
// Buradaki sayı gerçek genelleme tahminidir ve `gold_dataset` sayısından
// düşük olması BEKLENİR. Düşük olması bir başarısızlık değil, dürüst bir
// ölçümdür — ve hangi yapıların kırılgan olduğunu gösterir.
//
// Bu kümeye bakılarak örüntü düzeltilirse küme YANAR ve artık ayrık
// değildir. Böyle bir düzeltme yapılırsa, ölçüm "ayrık" olarak
// raporlanamaz. Ayrıntı: `docs/04_MODEL_DEGERLENDIRME.md` §5.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class HoldoutDataset {
  static const List<GoldCase> cases = [
    // ═══════════════════════════════════════════════════════════════════════
    // AÇIK SALDIRI — sözlük katmanının genellemesi
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'ne kadar salak bir yorum',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Farklı sözdizimi.'),
    GoldCase.flag(
        text: 'aptalca konuşuyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Zarf çekimi.'),
    GoldCase.flag(
        text: 'şerefsizin tekisin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'İyelik çekimi.'),
    GoldCase.flag(
        text: 'gerizekalısın sen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Devrik cümle.'),
    GoldCase.flag(
        text: 'yavşak herif',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.kufur,
        note: 'Küfür + aşağılayıcı ad çekirdeği.'),
    GoldCase.flag(
        text: 'geberteceğim seni',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Devrik tehdit.'),
    GoldCase.flag(
        text: 'ezerim seni',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Farklı tehdit fiili.'),
    GoldCase.flag(
        text: 'öküzsün resmen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Hayvan benzetmesi, bildirme eki.'),
    GoldCase.flag(
        text: 'eşek herif',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Hayvan benzetmesi + ad çekirdeği.'),
    GoldCase.flag(
        text: 'sizler tam birer malsınız',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Çokanlamlı terim, çoğul bildirme eki.'),

    // ═══════════════════════════════════════════════════════════════════════
    // ÖRTÜK SALDIRI — asıl genelleme sınavı
    // ═══════════════════════════════════════════════════════════════════════

    // ── Küçümseme, çekim ve sıra değişimleriyle ──
    GoldCase.flag(
        text: 'siz ne anlarsınız ki bundan',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),
    GoldCase.flag(
        text: 'sen bundan ne anlarsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kelime sırası değişti — araya nesne girdi.'),
    GoldCase.flag(
        text: 'anlamazsınız zaten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),
    GoldCase.flag(
        text: 'senin haddin değil bu iş',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Eşanlamlı deyim ("harcın" yerine "haddin").'),
    GoldCase.flag(
        text: 'bu konu sana göre değil',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kelime sırası değişti.'),
    GoldCase.flag(
        text: 'sizinle tartışmak anlamsız',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul + eşanlamlı.'),
    GoldCase.flag(
        text: 'sorun sizde',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),
    GoldCase.flag(
        text: 'size anlatmak boşuna',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),
    GoldCase.flag(
        text: 'sen anlamazsın bunu, boş ver',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Farklı bağlam içinde aynı çekirdek.'),

    // ── Ötekileştirme ──
    GoldCase.flag(
        text: 'onun gibilerden ne beklenir',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Üçüncü şahıs ötekileştirme.'),
    GoldCase.flag(
        text: 'sizin gibi kişilerle çalışılmaz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kategori adı çekimli.'),
    GoldCase.flag(
        text: 'hepiniz birsiniz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Genelleme, farklı yüklem.'),
    GoldCase.flag(
        text: 'hep böylesin zaten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Tekil çekim.'),
    GoldCase.flag(
        text: 'senden başka ne beklenir',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Tekil çekim.'),

    // ── Yok sayma ──
    GoldCase.flag(
        text: 'yine mi siz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),
    GoldCase.flag(
        text: 'boş konuşma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Emir kipi varyantı.'),
    GoldCase.flag(
        text: 'size ne',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim, cümle sonu.'),
    GoldCase.flag(
        text: 'siz karışmayın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul emir.'),
    GoldCase.flag(
        text: 'sizi ilgilendirmez',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),
    GoldCase.flag(
        text: 'kimse sormuyor size',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Geniş zaman çekimi.'),
    GoldCase.flag(
        text: 'bıktım sizden artık',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),

    // ── Susturma ──
    GoldCase.flag(
        text: 'sesinizi kesin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul emir çekimi.'),
    GoldCase.flag(
        text: 'çenenizi kapatın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul emir çekimi.'),
    GoldCase.flag(
        text: 'haddinizi aşmayın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul olumsuz emir.'),
    GoldCase.flag(
        text: 'siz kim oluyorsunuz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),

    // ── Aşağılayıcı emir ──
    GoldCase.flag(
        text: 'git kendine bir iş bul',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Araya kelime girdi.'),
    GoldCase.flag(
        text: 'işinize bakın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul emir çekimi.'),
    GoldCase.flag(
        text: 'önce aynaya bak',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Başa zarf eklendi.'),

    // ── Karakter saldırısı ──
    GoldCase.flag(
        text: 'sizden adam olmaz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Çoğul çekim.'),
    GoldCase.flag(
        text: 'işe yaramazsınız',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Çoğul çekim.'),
    GoldCase.flag(
        text: 'hiçbir halt beceremiyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Kümede hiç görülmemiş kalıp.'),

    // ── Alaycılık ──
    GoldCase.flag(
        text: 'helal olsun valla sana',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kelime sırası değişti.'),
    GoldCase.flag(
        text: 'bravo gerçekten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kısaltılmış alay.'),
    GoldCase.flag(
        text: 'ne kadar da akıllısınız',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Çoğul çekim.'),

    // ── Örtük tehdit ──
    GoldCase.flag(
        text: 'gününü görürsün',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Geniş zaman çekimi.'),
    GoldCase.flag(
        text: 'hesabını sorarım',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Geniş zaman çekimi.'),
    GoldCase.flag(
        text: 'bu yaptığın yanına kalmayacak',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Genişletilmiş cümle.'),
    GoldCase.flag(
        text: 'sizinle görüşeceğiz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Çoğul + gelecek zaman.'),
    GoldCase.flag(
        text: 'bize bulaşma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Çoğul nesne.'),
    GoldCase.flag(
        text: 'sonun kötü olacak',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Eşanlamlı yüklem.'),

    // ═══════════════════════════════════════════════════════════════════════
    // MASUM — kesinliğin genellemesi (yeni tuzaklar ve yakın-kaçışlar)
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.clean(
        text: 'senin gibi birini tanımak güzel',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "senin gibi" + övgü.'),
    GoldCase.clean(
        text: 'sana ne kadar teşekkür etsem az',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "sana ne" alt dizisi.'),
    GoldCase.clean(
        text: 'görüşürüz kardeşim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: vedalaşma.'),
    GoldCase.clean(
        text: 'bu konuyu geçelim artık',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "geç" çekimli, düşmanlık yok.'),
    GoldCase.clean(
        text: 'işine bakan adamı severim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "işine bak" alt dizisi, övgü bağlamı.'),
    GoldCase.clean(
        text: 'hepimiz insanız sonuçta',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "hepimiz" birleştirici.'),
    GoldCase.clean(
        text: 'sorun bende, kusura bakma',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "sorun sende" kalıbının birinci şahsı.'),
    GoldCase.clean(
        text: 'hiçbir işe yaramayan bir uygulama bu',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: nesneye yönelik, kişiye değil.'),
    GoldCase.clean(
        text: 'kimse sormadan cevap verdim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "kimse sorma" alt dizisi.'),
    GoldCase.clean(
        text: 'bravo diyorum sana, harikaydı',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: içten "bravo", alay parçacığı yok.'),
    GoldCase.clean(
        text: 'aferin sana, gerçekten hak ettin',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: içten takdir.'),
    GoldCase.clean(
        text: 'vay be, ne güzel olmuş',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "vay be" içten hayranlık da olabilir. '
            'Bu örüntünün en kırılgan noktası.'),
    GoldCase.clean(
        text: 'malumat sahibi değilim bu konuda',
        group: GoldGroup.masum,
        note: 'TUZAK: "mal" ile başlar.'),
    GoldCase.clean(
        text: 'itfaiye çok hızlı geldi',
        group: GoldGroup.masum,
        note: 'TUZAK: "it" ile başlar.'),
    GoldCase.clean(
        text: 'sikkeler müzayedede satıldı',
        group: GoldGroup.masum,
        note: 'TUZAK: müstehcen alt dizi.'),
    GoldCase.clean(
        text: 'köpeğimi gezdiriyorum parkta',
        group: GoldGroup.masum,
        note: 'TUZAK: hayvan adı, yönelim yok.'),
    GoldCase.clean(
        text: 'öküz gibi çalıştım bugün',
        group: GoldGroup.masum,
        note: 'TUZAK: hayvan benzetmesi ama BİRİNCİ şahıs — öz-ifade.'),
    GoldCase.clean(
        text: 'eşek şakası yapmışlar bana',
        group: GoldGroup.masum,
        note: 'TUZAK: deyim içinde hayvan adı.'),
    GoldCase.clean(
        text: 'sus payı vermişler',
        group: GoldGroup.masum,
        note: 'TUZAK: "sus" deyim içinde.'),
    GoldCase.clean(
        text: 'raporu hazırladım, yarın gönderiyorum',
        group: GoldGroup.masum,
        note: 'Nötr iş dili.'),
    GoldCase.clean(
        text: 'bu öneriye kesinlikle karşıyım',
        group: GoldGroup.masum,
        note: 'Güçlü itiraz, saldırı yok.'),
    GoldCase.clean(
        text: 'sonuçlar beklediğimden kötü çıktı',
        group: GoldGroup.masum,
        note: 'Olumsuz değerlendirme.'),
    GoldCase.clean(
        text: 'yardımın için minnettarım',
        group: GoldGroup.masum,
        note: 'Olumlu.'),
    GoldCase.clean(
        text: 'toplantıyı erteleyebilir miyiz',
        group: GoldGroup.masum,
        note: 'Nötr istek.'),

    // ═══════════════════════════════════════════════════════════════════════
    // BAĞLAM
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.clean(
        text: "bana 'salak' diye hitap etti",
        group: GoldGroup.baglam,
        note: 'Aktarım, farklı fiil.'),
    GoldCase.clean(
        text: 'kendimi çok aptal hissediyorum',
        group: GoldGroup.baglam,
        note: 'Öz-ifade, şimdiki zaman.'),
    GoldCase.clean(
        text: 'aptal olduğumu düşünmüyorum',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama, farklı yapı.'),
    GoldCase.clean(
        text: 'sana salak diyen haksız',
        group: GoldGroup.baglam,
        note: 'Aktarım; mağduru SAVUNAN cümle.'),
    GoldCase.clean(
        text: 'seni aptal sanmıyorum',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama, ikinci şahıs nesne.'),
    GoldCase.clean(
        text: 'şerefsiz demek istemem ama üzdü beni',
        group: GoldGroup.baglam,
        note: 'SINIR: inkâr kalıbı ama gerçek bir sitem. '
            'Etiket tartışmaya açıktır.'),
  ];
}
