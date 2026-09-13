// =============================================================================
// İP-27 · BEŞİNCİ AYRIK KÜME — İP-26 genişletmesinden sonraki geçerli ölçüm
// Dosya: packages/civility_core/lib/src/eval/generalization4_dataset.dart
//
// ── NEDEN YENİ BİR KÜME GEREKTİ ───────────────────────────────────────────
// İP-26'da motora 34 yeni edimbilimsel aile, 2 yeni nefret kuruluşu ve 40
// sözlük girdisi eklendi. Bu genişletme yazılırken İP-22 kümesinin
// KAÇIRDIKLARI OKUNDU.
//
// Dolayısıyla İP-22 artık genelleme ölçemez — önceki üç küme gibi YANMIŞTIR.
// Bugün o kümede %100 çıkması bir başarı ölçüsü değil, bir EZBER ölçüsüdür
// ve raporda öyle geçmelidir.
//
// Bu küme, yanan kümenin yerine geçer.
//
// ── PROTOKOL ──────────────────────────────────────────────────────────────
// İP-26 tamamlandıktan SONRA yazıldı · ölçüm bir kez alınır · sonuç
// düzeltilmeden raporlanır · bu kümeye bakılarak örüntü değiştirilirse küme
// yanar ve kayda geçer.
//
// ── KÜMENİN ÜÇ PARÇASI ────────────────────────────────────────────────────
//   1. YAZILMIŞ ailelerin HİÇ GÖRÜLMEMİŞ örnekleri (30)
//      Aynı yapı, başka sözcük, başka çekim. Aile genelleşiyorsa yakalanır.
//
//   2. Aynı ailelerin YAKIN-KAÇIŞLARI (30)
//      Kelime düzeyinde neredeyse aynı, edimbilimsel olarak masum. Aileler
//      fazla genişse kesinlik burada patlar. Bu parça kümenin asıl sınavıdır:
//      İP-26'da 34 yeni aile eklendi ve her yeni aile bir yanlış pozitif
//      riskidir.
//
//   3. Hiçbir ailede karşılığı OLMAYAN deyimler (30)
//      Tavanın nerede olduğunu ölçmeye devam etmek için. Bunların KAÇMASI
//      beklenir; yakalanırlarsa bir başka ailenin fazla geniş olduğunu
//      gösterir.
//
// ── BEKLENTİ (ölçümden ÖNCE yazılmıştır) ──────────────────────────────────
// Kesinlik: %100 kalmalı. İP-26'nın kabul koşulu buydu ve 34 yeni ailenin
//   hepsi kapalı sözcük listeleriyle ya da emir kipi şartıyla sınırlandı.
//   %95'in altına düşerse genişletme fazla açgözlüdür ve daraltılmalıdır.
//
// Duyarlılık: %55–70 bandı bekleniyor. Üçüncü parça kasıtlı olarak
//   yakalanamaz; tek başına toplamı ~%33 aşağı çeker. Birinci parçada
//   %85'in altına düşerse "aile genelleşir" iddiası zayıftır.
//
// Toplam beklenti bilerek İP-22'nin bugünkü %100'ünden UZAKTIR. Bir kümede
// %100 görmek, o kümenin artık ölçmediğinin işaretidir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class Generalization4Dataset {
  static const List<GoldCase> cases = [
    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 1 — Yazılmış ailelerin hiç görülmemiş örnekleri (30)
    // ═══════════════════════════════════════════════════════════════════════

    // ── Akıl sağlığı iması ────────────────────────────────────────────────
    GoldCase.flag(
        text: 'sen kafayı sıyırmışsın galiba',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'karakter.kafayi_yemis · "sıyırmışsın" çekimi.'),
    GoldCase.flag(
        text: 'aklını başına devşir biraz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'karakter.kendine_gel · "devşir" fiili.'),
    GoldCase.flag(
        text: 'git bir doktora görün',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'karakter.tedavi_ol · cümle sonunda emir.'),

    // ── Kibir suçlaması ───────────────────────────────────────────────────
    GoldCase.flag(
        text: 'burnunuz havada geziyorsunuz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'karakter.burnu_havada · çoğul şahıs.'),
    GoldCase.flag(
        text: 'ne sanıyorsun kendini',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'karakter.kendini_bir_sey_saniyor · devrik kuruluş.'),

    // ── Emeği / içeriği değersizleştirme ──────────────────────────────────
    GoldCase.flag(
        text: 'boşuna kürek çekme daha fazla',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'kucumseme.bosa_kurek · emir kipi.'),
    GoldCase.flag(
        text: 'ipe sapa gelmez laflar ediyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'kucumseme.ipe_sapa_gelmez · farklı yüklem.'),
    GoldCase.flag(
        text: 'laf cambazlığı yapma bana',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yoksayma.laf_ebeligi · sınıftaki başka ad.'),
    GoldCase.flag(
        text: 'boş boş konuşma orada',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yoksayma.bos_yapma · ikileme.'),
    GoldCase.flag(
        text: 'bana masal okuma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yoksayma.hikaye_anlatma · sınıftaki başka fiil.'),

    // ── Muhataplığın reddi ────────────────────────────────────────────────
    GoldCase.flag(
        text: 'siz nereden çıktınız şimdi',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yoksayma.nereden_ciktin · çoğul şahıs.'),
    GoldCase.flag(
        text: 'sen kim oluyorsun da karışıyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yoksayma.sen_kim_bu_is_kim · ikinci kol.'),
    GoldCase.flag(
        text: 'ne haddinize bunu söylemek',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yoksayma.ne_haddine · çoğul şahıs.'),
    GoldCase.flag(
        text: 'bu senin üstüne vazife değil',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'yoksayma.ustune_vazife_degil · birinci kol.'),
    GoldCase.flag(
        text: 'sizde hiç vicdan mı var',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'karakter.nitelik_reddi_hic · çoğul + pekiştireç.'),

    // ── Susturma ──────────────────────────────────────────────────────────
    GoldCase.flag(
        text: 'çenenizi tutun biraz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'susturma.ceneni_tut · çoğul emir.'),
    GoldCase.flag(
        text: 'ağzından çıkanı kulağın duysun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'susturma.agzindan_cikani · kalıbın tam hâli.'),
    GoldCase.flag(
        text: 'sen önce sıranı bil',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'susturma.yerini_bil · sınıftaki başka ad.'),
    GoldCase.flag(
        text: 'çok bilmişlik yapma lütfen',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'susturma.ukalalik_yapma · birleşik ad.'),

    // ── Örtük tehdit ──────────────────────────────────────────────────────
    GoldCase.flag(
        text: 'ağzının payını alacaksın birazdan',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'tehdit.agzinin_payi · gelecek zaman.'),
    GoldCase.flag(
        text: 'bir elime geçersen görürsün',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'tehdit.elime_gecersen · araya "bir" girmiş.'),
    GoldCase.flag(
        text: 'benimle uğraşma sen',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'tehdit.bana_bulasma · sınıftaki başka fiil.'),
    GoldCase.flag(
        text: 'iki elim yakanda olsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'tehdit.elim_yakanda · kalıbın tam hâli.'),

    // ── Alay / acıma ──────────────────────────────────────────────────────
    GoldCase.flag(
        text: 'gerçekten acıyorum sana',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'alayci.aciyorum_sana · başta zarf.'),
    GoldCase.flag(
        text: 'rezil oldun resmen',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'alayci.rezil_ettin · farklı çekim.'),

    // ── Deyimsel yetersizlik ──────────────────────────────────────────────
    GoldCase.flag(
        text: 'gözün kör mü senin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'kucumseme.gozun_kor_mu · devrik.'),
    GoldCase.flag(
        text: 'senden adam olmaz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'karakter.adam_olmaz · birinci kol.'),
    GoldCase.flag(
        text: 'sen ne işe yararsın ki',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'kucumseme.ne_ise_yariyorsun · geniş zaman.'),

    // ── Nefret söylemi (yeni kuruluşlar) ──────────────────────────────────
    GoldCase.flag(
        text: 'bu Afganlardan adam olmaz',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'nefret.kimlikten_adam_olmaz · başka kimlik terimi.'),
    GoldCase.flag(
        text: 'Ermenilerin hepsi aynı zaten',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'nefret.iceriksiz_genelleme · "aynı" + kuyruk.'),

    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 2 — Yakın-kaçışlar (30). Hepsi TEMİZ olmalı.
    // ═══════════════════════════════════════════════════════════════════════

    GoldCase.clean(
        text: 'kafayı bu projeye taktım, günlerdir uyumuyorum',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "kafayı" var ama fiil listesi kapalı.'),
    GoldCase.clean(
        text: 'kendine gelen paketleri kontrol eder misin',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "kendine gel" dizisi var ama sıfat-fiil.'),
    GoldCase.clean(
        text: 'doktora göründün mü sonuçta iyileşmen lazım',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · emir değil, ilgili bir soru.'),
    GoldCase.clean(
        text: 'burnu kanadı, mendil verdim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "burnu" var, "havada" yok.'),
    GoldCase.clean(
        text: 'kendini geliştirmek isteyen herkese bu kursu öneririm',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "kendini" + olumlu yüklem.'),
    GoldCase.clean(
        text: 'kürek çekmeyi yeni öğrendim, çok keyifli',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "kürek çek" var, "boşa" yok.'),
    GoldCase.clean(
        text: 'ipe un sermek diye bir deyim var, bunu kastetmiyorum',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "ipe" var, kalıbın devamı yok.'),
    GoldCase.clean(
        text: 'laf arasında söyledi, ciddi değildi',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "laf" var, ad tamlaması yok.'),
    GoldCase.clean(
        text: 'boş bir sayfa aç ve oraya yaz',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "boş" + fiil listesi dışı.'),
    GoldCase.clean(
        text: 'çocuğa masal okumak en sevdiğim şey',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "masal oku" var, ikinci şahıs emri yok.'),
    GoldCase.clean(
        text: 'bu fikir nereden çıktı, merak ettim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · üçüncü şahıs, ikinci şahıs değil.'),
    GoldCase.clean(
        text: 'kim olursa olsun kurallar herkese aynı',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "kim" var, kuruluş yok.'),
    GoldCase.clean(
        text: 'haddini bilen insanları severim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "haddini bil" ÖVGÜ bağlamında.'),
    GoldCase.clean(
        text: 'bu iş bana kaldı, ben hallederim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · birinci şahıs.'),
    GoldCase.clean(
        text: 'sen karışmasan da olur, ben hallederim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · şart kipi, emir değil — nazikçe yükü üstlenme.'),
    GoldCase.clean(
        text: 'sende kalem var mı, benimki bitti',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "sende ... var mı" ama somut ad.'),
    GoldCase.clean(
        text: 'çeneni bantlamışlar diye şaka yaptık, çok güldük',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "çeneni" var, "tut" yok.'),
    GoldCase.clean(
        text: 'yerini değiştirdim, pencere kenarına geçtim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "yerini" var, "bil" yok.'),
    GoldCase.clean(
        text: 'payını aldı herkes, adil bir paylaşım oldu',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "payını al" var, "ağzının" yok.'),
    GoldCase.clean(
        text: 'elime geçen ilk kitabı okudum',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "elime geç" var, tehdit çekimi yok.'),
    GoldCase.clean(
        text: 'boyaya bulaşma, üstün kirlenir',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "bulaşma" var, birinci şahıs yönelimi yok.'),
    GoldCase.clean(
        text: 'yazık oldu o kadar emeğe',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "yazık" var, ikinci şahıs yönelimi yok.'),
    GoldCase.clean(
        text: 'rezil bir hava vardı, yağmur dinmedi',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "rezil" var ama kişiye yönelik değil.'),
    GoldCase.clean(
        text: 'kör nokta uyarısı çalışmıyor, servise götüreceğim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "kör" var, soru kipi ve yönelim yok.'),
    GoldCase.clean(
        text: 'bu çocuktan adam olur, çok çalışıyor',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "adam ol" OLUMLU çekim.'),
    GoldCase.clean(
        text: 'bu alet ne işe yarıyor acaba',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · nesne hakkında, kişi hakkında değil.'),
    GoldCase.clean(
        text: 'Afgan arkadaşım burada mühendislik okuyor',
        group: GoldGroup.nefret,
        note: 'YAKIN-KAÇIŞ · kimlik terimi + tamamen nötr yüklem.'),
    GoldCase.clean(
        text: 'Ermenilerin hepsi aynı şeyi düşünmüyor, çok çeşitli görüş var',
        group: GoldGroup.nefret,
        note: 'YAKIN-KAÇIŞ · "hepsi aynı" var ama arkasından fiil geliyor.'),
    GoldCase.clean(
        text: 'omurgasızlar üzerine bir biyoloji dersi aldım',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "omurgasız" bilimsel terim (maskeleme testi).'),
    GoldCase.clean(
        text: 'kansızlık teşhisi kondu, demir takviyesi başladık',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ · "kansız" tıbbi terim (maskeleme testi).'),

    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 3 — Ailesi olmayan deyimler (30). KAÇMALARI beklenir.
    //
    // Bu parça kümenin dürüstlük çapasıdır: yakalanan her örnek sevindirici,
    // kaçan her örnek beklenen. Toplam duyarlılığı aşağı çeken asıl parça
    // budur ve bu, "kural tabanlı katmanın tavanı" iddiasının ölçüsüdür.
    // ═══════════════════════════════════════════════════════════════════════

    GoldCase.flag(
        text: 'armut piş ağzıma düş bekliyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: tembellik atfeden deyim.'),
    GoldCase.flag(
        text: 'davul bile dengi dengine',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: denklik reddi, atasözü kılığında.'),
    GoldCase.flag(
        text: 'sütten çıkmış ak kaşık mısın sanki',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: ikiyüzlülük suçlaması, soru kipinde.'),
    GoldCase.flag(
        text: 'kendi çöplüğünde ötüyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: yetki alanını daraltan deyim.'),
    GoldCase.flag(
        text: 'sen daha emekleme aşamasındasın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: olgunluk reddi, benzetme yoluyla.'),
    GoldCase.flag(
        text: 'bu işin suyunu çıkardın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: aşırıya kaçma suçlaması.'),
    GoldCase.flag(
        text: 'tencere dibin kara seninki benden kara',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: karşı suçlama, atasözü.'),
    GoldCase.flag(
        text: 'ayinesi iştir kişinin lafa bakılmaz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: söylenen sözün değersizleştirilmesi.'),
    GoldCase.flag(
        text: 'her yiğidin bir yoğurt yiyişi var ama seninki fazla',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: atasözü + kişiselleştirilmiş kuyruk.'),
    GoldCase.flag(
        text: 'bal tutan parmağını yalar diyorsun da elin boş',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: çıkarcılık imasıyla değersizleştirme.'),
    GoldCase.flag(
        text: 'gölge etme başka ihsan istemem',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: katkının reddi, klasik deyim.'),
    GoldCase.flag(
        text: 'sen benim tırnağım bile olamazsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: üstünlük kurma, benzetme yoluyla.'),
    GoldCase.flag(
        text: 'ağzınla kuş tutsan fayda etmez',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: çabanın peşinen reddi.'),
    GoldCase.flag(
        text: 'seni anlatmaya kalem yetmez',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: alaycı abartma.'),
    GoldCase.flag(
        text: 'tam da senden beklenecek bir iş',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: beklenti kalıbının farklı kuruluşu.'),
    GoldCase.flag(
        text: 'seninle aynı havayı solumak bile zor',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: tiksinme ifadesi, doğrudan hakaret içermez.'),
    GoldCase.flag(
        text: 'bu kafayla bir yere varamazsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: "kafa" ile kapasite reddi, farklı kuruluş.'),
    GoldCase.flag(
        text: 'senin ağzından bal damlasa yalamam',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: güvensizlik beyanı, deyim.'),
    GoldCase.flag(
        text: 'değirmenin suyu nereden geliyor acaba',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: örtük yolsuzluk iması.'),
    GoldCase.flag(
        text: 'takke düştü kel göründü',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: ifşa/utandırma deyimi.'),
    GoldCase.flag(
        text: 'seni adam yerine koyan mı var',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: muhataplığın reddi, soru kipinde.'),
    GoldCase.flag(
        text: 'dilinin kemiği yok senin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: sözünde durmama suçlaması.'),
    GoldCase.flag(
        text: 'kırk yılda bir doğru söyledin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: övgü kılığında genel yetersizlik atfı.'),
    GoldCase.flag(
        text: 'sen daha anasının kuzususun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: olgunluk reddi, deyim.'),
    GoldCase.flag(
        text: 'bu kadar da körlük olmaz ki',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: farkındasızlık suçlaması, soyut ad çekimi.'),
    GoldCase.flag(
        text: 'attığın taş ürküttüğün kurbağaya değmez',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: çabanın değersizleştirilmesi, atasözü.'),
    GoldCase.flag(
        text: 'sen hangi cesaretle konuşuyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'TAVAN: söz hakkının reddi, "hangi" kuruluşu.'),
    GoldCase.flag(
        text: 'bu Suriyeliler yüzünden mahallede huzur kalmadı',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'TAVAN: "yüzünden" ile toplu sorumluluk atfı — '
            'sözvarlığında düşman yüklem yok.'),
    GoldCase.flag(
        text: 'Romanların yaşadığı yere kimse gitmez',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'TAVAN: dolaylı dışlama, olumsuz genelleme kipinde.'),
    GoldCase.flag(
        text: 'Alevilerle dünürlük olmaz derler',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'TAVAN: aktarım kılığında dışlama — aktarım kipi bağlam '
            'katmanında yumuşatma tetikler.'),
  ];
}
