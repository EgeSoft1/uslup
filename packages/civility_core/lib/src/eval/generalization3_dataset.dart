// =============================================================================
// İP-22 · DÖRDÜNCÜ AYRIK KÜME — "yapısal aile" iddiasının sınavı
// Dosya: packages/civility_core/lib/src/eval/generalization3_dataset.dart
//
// ── SORU ──────────────────────────────────────────────────────────────────
// İP-19 onarımı yüzey biçimlerini genişletmişti ve İP-20'de duyarlılık
// %50,0'de kaldı: eklenen örüntüler yeni çekimleri gördü, yeni DEYİMLERİ
// görmedi.
//
// İP-21 farklı bir yol denedi. Kaçan deyimleri tek tek yazmak yerine, her
// birinin dayandığı YAPIYI hedefleyen aileler kuruldu ve bu aileler kapalı
// SOYUT AD SINIFLARIYLA parametrelendi:
//
//   [2.şahıs]da [soyut nitelik] mı var    ← akıl, vicdan, insaf, izan…
//   [kapasite adı] bu kadar               ← çap, kapasite, seviye, ayar…
//   [kapasite adı]nı aşan                 ← boy, had, çap
//   [değerlendirme nesnesi] + yetersizlik çekimi
//
// İddia şudur: sınıf tabanlı bir aile, hiç görülmemiş bir deyimi de görür —
// yeter ki deyim aynı yapıyı kullansın.
//
// **Bu küme o iddiayı sınamak için vardır ve iddiayı çürütecek biçimde
// kurulmuştur.**
//
// ── KÜMENİN ÜÇ EŞİT PARÇASI ───────────────────────────────────────────────
//   1/3 · İP-21 ailelerinin BAŞKA ÖRNEKLERİ — aynı yapı, sözvarlığındaki
//         başka bir ad, başka bir çekim. Aile genelleşiyorsa yakalanır.
//   1/3 · Aynı ailelerin YAKIN-KAÇIŞLARI — sınıfa girmeyen somut ad,
//         üçüncü şahıs, olumsuzlama. Aile fazla genişse burada patlar.
//   1/3 · Hiçbir ailede karşılığı OLMAYAN deyimler — tavanın nerede
//         olduğunu ölçmeye devam etmek için. Bunların kaçması beklenir.
//
// ── PROTOKOL ──────────────────────────────────────────────────────────────
// İP-21 onarımı tamamlandıktan sonra yazıldı · ölçüm bir kez alınır ·
// sonuç düzeltilmeden raporlanır · bu kümeye bakılarak örüntü değiştirilirse
// küme yanar ve kayda geçer.
//
// ── BEKLENTİ (ölçümden ÖNCE yazılmıştır) ──────────────────────────────────
// Kesinlik: %100 kalmalı. Yapısal aileler kapalı ad sınıflarıyla sınırlı
// olduğu için yakın-kaçışlarda patlamamalı. Patlarsa iddia yanlıştır ve
// aileler daraltılmalıdır.
//
// Duyarlılık: %60–75 bandı bekleniyor. İP-20'nin ilk ölçümü (%50,0) ile
// arasındaki fark, "yapısal aile" yaklaşımının yüzey genişletmeye göre
// getirisidir. %50'ye yakın çıkarsa yaklaşım işe yaramamıştır; %90'a yakın
// çıkarsa kümenin üçüncü parçası yeterince zor değildir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class Generalization3Dataset {
  static const List<GoldCase> cases = [
    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 1 — İP-21 ailelerinin başka örnekleri (aynı yapı, başka sözcük)
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'sizde vicdan mı var gerçekten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'nitelik_reddi · çoğul şahıs + sınıftaki başka ad.'),
    GoldCase.flag(
        text: 'sende insaf mı kalmış',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'nitelik_reddi · "kalmış" çekimi.'),
    GoldCase.flag(
        text: 'sende hiç edep mi var',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'nitelik_reddi · araya "hiç" pekiştireci girmiş.'),
    GoldCase.flag(
        text: 'kapasiten o kadar işte',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'kapasite_tavani · "o kadar" + sonda pekiştireç.'),
    GoldCase.flag(
        text: 'senin ayarın bu kadar',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'kapasite_tavani · sınıftaki başka ad.'),
    GoldCase.flag(
        text: 'haddini aşan bir laf ettin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'haddini_asan · sıfat-fiil, farklı yüklemle.'),
    GoldCase.flag(
        text: 'doğru düzgün bir iş beceremiyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yetersizlik_cekimi · nesne + araya iki kelime.'),
    GoldCase.flag(
        text: 'tek bir cümle kuramıyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yetersizlik_cekimi · "cümle" nesnesi, farklı fiil.'),
    GoldCase.flag(
        text: 'ne biçim adamsın sen',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'ne_bicim · devrik.'),
    GoldCase.flag(
        text: 'yazık size gerçekten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yazik_sana · çoğul şahıs.'),
    GoldCase.flag(
        text: 'caka satma bize burada',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'bobürlenme_suclamasi · sınıftaki başka deyim.'),
    GoldCase.flag(
        text: 'bu dediğin de fikir mi',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'seninki_de · "bu dediğin" + "fikir".'),
    GoldCase.flag(
        text: 'sizden bize hayır yok',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'fayda_yok · çoğul şahıs + "hayır".'),
    GoldCase.flag(
        text: 'aptala yatma şimdi bana',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'salaga_yatma · sınıftaki başka ad.'),
    GoldCase.flag(
        text: 'mülteciler ekonomiye yük',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'yuk_soylemi · başka kimlik, başka yük tamlaması.'),
    GoldCase.flag(
        text: 'Afganlar devlete yük olmuş durumda',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'yuk_soylemi · "yük olmuş" + kuyruk.'),
    GoldCase.flag(
        text: 'Ermeniler yalancıdır zaten',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: '_kuyruk · yüklemden sonra pekiştireç.'),
    GoldCase.flag(
        text: 'Suriyeliler hırsızdır maalesef',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: '_kuyruk · farklı belirteç.'),
    GoldCase.flag(
        text: 'bu Araplarla aynı binada oturulmaz',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'dolayli_dislama · başka kimlik, başka yüklem.'),
    GoldCase.flag(
        text: 'terbiyesizliğin âlâsı bu yaptığın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Pekiştireç adı yönelim kuruyor — "âlâsı".'),

    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 2 — Aynı ailelerin yakın-kaçışları (aile fazla genişse patlar)
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.clean(
        text: 'sende kalem mi var acaba',
        group: GoldGroup.masum,
        note: 'nitelik_reddi yakın-kaçış: SOMUT ad, gerçek soru.'),
    GoldCase.clean(
        text: 'sende fazladan bilet mi var',
        group: GoldGroup.masum,
        note: 'nitelik_reddi yakın-kaçış: somut ad.'),
    GoldCase.clean(
        text: 'yarın gelemezsin galiba, programın dolu',
        group: GoldGroup.masum,
        note: 'yetersizlik_cekimi yakın-kaçış: değerlendirme nesnesi YOK.'),
    GoldCase.clean(
        text: 'bu saatten sonra yetişemezsin',
        group: GoldGroup.masum,
        note: 'yetersizlik_cekimi yakın-kaçış: bilgi cümlesi.'),
    GoldCase.clean(
        text: 'boyu aşan bir dalga geldi kıyıya',
        group: GoldGroup.masum,
        note: 'haddini_asan yakın-kaçış: ikinci şahıs iyeliği yok.'),
    GoldCase.clean(
        text: 'yük treni gece geçiyor buradan',
        group: GoldGroup.masum,
        note: 'yuk_soylemi yakın-kaçış: kimlik yuvası yok.'),
    GoldCase.clean(
        text: 'engelliler topluma yük değil, zenginliktir',
        group: GoldGroup.masum,
        note: 'yuk_soylemi yakın-kaçış: OLUMSUZLAMA. Bu satır kırılırsa '
            'katman, savunan kişiyi susturuyor demektir.'),
    GoldCase.clean(
        text: 'bu gürültüyle burada çalışılmaz',
        group: GoldGroup.masum,
        note: 'dolayli_dislama yakın-kaçış: kimlik yuvası yok.'),
    GoldCase.clean(
        text: 'seviyen çok yükselmiş, tebrik ederim',
        group: GoldGroup.masum,
        note: 'kapasite_tavani yakın-kaçış: "bu kadar" yok, iltifat var.'),
    GoldCase.clean(
        text: 'çapı bu kadar olan bir boru lazım',
        group: GoldGroup.masum,
        note: 'kapasite_tavani yakın-kaçış: üçüncü şahıs iyeliği, teknik ölçü.'),
    GoldCase.clean(
        text: 'hava atmayı hiç sevmez o',
        group: GoldGroup.masum,
        note: 'bobürlenme yakın-kaçış: üçüncü şahıs, mastar.'),
    GoldCase.clean(
        text: 'yazık oldu o güzel eve',
        group: GoldGroup.masum,
        note: 'yazik_sana yakın-kaçış: yönelim yok.'),
    GoldCase.clean(
        text: 'ona acıdım, çok yorulmuştu',
        group: GoldGroup.masum,
        note: 'acidim_sana yakın-kaçış: üçüncü şahıs.'),
    GoldCase.clean(
        text: 'Yunanlılar bu konuda haklıdır bence',
        group: GoldGroup.masum,
        note: '_kuyruk yakın-kaçış: pekiştireç var ama yüklem DÜŞMANCA değil.'),
    GoldCase.clean(
        text: 'Suriyeli öğrenciler çok çalışkandır maalesef yeterince '
            'desteklenmiyorlar',
        group: GoldGroup.masum,
        note: '_kuyruk yakın-kaçış: olumlu yüklem + belirteç.'),
    GoldCase.clean(
        text: 'haddini bilen insanlara saygı duyarım',
        group: GoldGroup.masum,
        note: 'haddini_asan yakın-kaçış: olumlu kullanım.'),
    GoldCase.clean(
        text: 'dar kafalı olmamak lazım bu konularda',
        group: GoldGroup.masum,
        note: 'Sözlük yakın-kaçış: yönelim yok, öz-eleştiri.'),
    GoldCase.clean(
        text: 'yatma vakti geldi çocuklar',
        group: GoldGroup.masum,
        note: 'salaga_yatma yakın-kaçış: fiil tek başına.'),
    GoldCase.clean(
        text: 'ne biçim bir hava bu böyle',
        group: GoldGroup.masum,
        note: 'ne_bicim yakın-kaçış: ad sınıfı insan DEĞİL.'),
    GoldCase.clean(
        text: 'akıl sağlığı çok önemli bir konu',
        group: GoldGroup.masum,
        note: 'nitelik_reddi yakın-kaçış: "akıl" var, kalıp yok.'),

    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 3 — Hiçbir ailede karşılığı olmayan deyimler (tavan ölçümü)
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'burnu havada geziyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: kibir suçlaması deyimi.'),
    GoldCase.flag(
        text: 'kafayı yemişsin sen',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: akıl sağlığı imalı deyim.'),
    GoldCase.flag(
        text: 'aklını peynir ekmekle mi yedin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: uzun deyim.'),
    GoldCase.flag(
        text: 'boşa kürek çekiyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: emeği değersizleştiren deyim.'),
    GoldCase.flag(
        text: 'laf ebeliği yapma bana',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: söz hakkını reddeden deyim.'),
    GoldCase.flag(
        text: 'ipe sapa gelmez şeyler konuşuyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: içerik reddi deyimi.'),
    GoldCase.flag(
        text: 'nereden çıktın sen şimdi',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: muhataplığın reddi, soru kipinde.'),
    GoldCase.flag(
        text: 'sen kim, bu iş kim',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: yetkisizleştirme, eliptik kuruluş.'),
    GoldCase.flag(
        text: 'kendine gel biraz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: örtük akıl sağlığı iması.'),
    GoldCase.flag(
        text: 'ne haddine senin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: "had" ailesinin eliptik biçimi.'),
    GoldCase.flag(
        text: 'çeneni tut da dinle',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: susturma, "kapa çeneni"den farklı fiil.'),
    GoldCase.flag(
        text: 'ağzının payını alacaksın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'TAVAN: örtük tehdit deyimi.'),
    GoldCase.flag(
        text: 'Kürtlerle bir arada yaşanmaz derler',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'dolayli_dislama · "bir arada" araya girmiş, aktarım kılığında.'),
    GoldCase.flag(
        text: 'Alevilerin hepsi öyle zaten',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'TAVAN: içeriksiz toplu genelleme — yüklem sözvarlıkta yok.'),
    GoldCase.flag(
        text: 'bu Romanlardan adam olmaz',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'TAVAN: kimlik + "adam olmaz" kuruluşu.'),

    // ═══════════════════════════════════════════════════════════════════════
    // BAĞLAM VE MASUM — mağdur korunuyor mu, hâlâ
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.clean(
        text: 'bana "geri kafalı" dedi, çok kırıldım',
        group: GoldGroup.baglam,
        note: 'İP-21 sözlük girdisi, aktarım bağlamında.'),
    GoldCase.clean(
        text: 'birisi "sende akıl mı var" diye yazmış, bildirdim',
        group: GoldGroup.baglam,
        note: 'İP-21 örüntüsü ALINTI içinde — mağdur korunmalı.'),
    GoldCase.clean(
        text: 'mültecilere "yük" demek insanlık dışı',
        group: GoldGroup.baglam,
        note: 'Terimi eleştirmek, kullanmak değil.'),
    GoldCase.clean(
        text: 'kendimi bu işte yetersiz hissediyorum',
        group: GoldGroup.baglam,
        note: 'Öz-ifade.'),
    GoldCase.clean(
        text: 'toplantı saatini değiştirebilir miyiz',
        group: GoldGroup.masum,
        note: 'Sıradan cümle.'),
    GoldCase.clean(
        text: 'kütüphaneden üç kitap aldım',
        group: GoldGroup.masum,
        note: 'Sıradan cümle.'),
    GoldCase.clean(
        text: 'kapasite artırımı için bütçe istedik',
        group: GoldGroup.masum,
        note: 'Tuzak: "kapasite" kalıpsız.'),
    GoldCase.clean(
        text: 'çeneni sıkma dedi doktor, çene kası gerilir',
        group: GoldGroup.masum,
        note: 'Tuzak: "çene" tıbbi bağlamda.'),
    GoldCase.clean(
        text: 'ayarları sıfırladım telefonun',
        group: GoldGroup.masum,
        note: 'Tuzak: "ayar" teknik anlamda.'),
    GoldCase.clean(
        text: 'vicdanlı bir karar verdiler sonunda',
        group: GoldGroup.masum,
        note: 'Tuzak: "vicdan" olumlu kullanımda.'),
  ];
}
