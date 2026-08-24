// =============================================================================
// İP-20 · ÜÇÜNCÜ AYRIK KÜME — onarım sonrası dürüst genelleme ölçümü
// Dosya: packages/civility_core/lib/src/eval/generalization2_dataset.dart
//
// ── NEDEN ÜÇÜNCÜ BİR KÜME ─────────────────────────────────────────────────
// İkinci ayrık küme (`generalization_dataset.dart`, İP-15) ilk geçişte
// F1 = %55,6 verdi. Bu ölçüm, örüntü katmanının ezberleme payını ilk kez
// görünür kıldı: geliştirme kümesinde %100 olan örtük saldırı duyarlılığı,
// taze veride %12,0'ye düşüyordu.
//
// Kaçakların taksonomisi kullanılarak İP-19 onarımı yapıldı ve aynı kümede
// F1 %98,0'e çıktı. **Ancak o sayı bir genelleme kanıtı DEĞİLDİR** — onarım
// o kümeye bakılarak yapıldığı için küme yanmıştır. Bu, birinci ayrık kümenin
// başına gelenin birebir aynısıdır ve kayıt altına alınmıştır.
//
// Bu dosya, onarımın gerçekten GENELLEŞİP genelleşmediğini ölçer.
//
// ── PROTOKOL ──────────────────────────────────────────────────────────────
//   1. Küme, İP-19 onarımı TAMAMLANDIKTAN SONRA yazıldı.
//   2. Cümleler, İP-15'tekilerden FARKLI edimbilimsel kuruluşlar seçilerek
//      kuruldu; aynı kalıbın başka bir çekimi değil, başka bir kalıp.
//   3. Kümenin üçte biri, İP-19'da EKLENEN örüntülerin yakın-kaçışlarıdır.
//      Amaç, onarımın kesinliği bozup bozmadığını doğrudan ölçmektir:
//        "sus da adam konuşsun"      → saldırı
//        "sustu da öyle başladı"     → masum   ← aynı harf dizisi
//        "acıdım sana gerçekten"     → saldırı
//        "acıdım ona, zor durumda"   → masum   ← üçüncü şahıs
//   4. Ölçüm BİR KEZ alınır ve düzeltme yapılmadan raporlanır.
//
// ── BEKLENTİ BEYANI (ölçümden ÖNCE yazılmıştır) ───────────────────────────
// Bu kümede F1'in %98'e yakın çıkması BEKLENMİYOR. Küme kasıtlı olarak,
// hiçbir örüntü ailesinde karşılığı olmayan deyimsel saldırılar içeriyor
// ("boyunu aşan işlere karışma", "sende akıl mı var", "senin çapın bu
// kadar"). Kural tabanlı bir katmanın deyim uzayını kapsaması mümkün
// değildir; ölçümün amacı bu sınırı gizlemek değil, büyüklüğünü bildirmektir.
//
// Beklenen: kesinlik yüksek kalır, duyarlılık İP-15'in onarım sonrası
// değerinin altında çıkar. Arasındaki fark, onarımın ne kadarının
// genelleme, ne kadarının yeni ezberleme olduğunu gösterir.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class Generalization2Dataset {
  static const List<GoldCase> cases = [
    // ═══════════════════════════════════════════════════════════════════════
    // AÇIK SALDIRI
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'ne kadar da beceriksizsin ya',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Ünlem kuruluşu.'),
    GoldCase.flag(
        text: 'sersem herif yine geç kaldı',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Üçüncü şahıs + aşağılayıcı ad.'),
    GoldCase.flag(
        text: 'namussuzun tekiymiş meğer',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Rivayet kipi.'),
    GoldCase.flag(
        text: 'yavşaklığın alemi yok',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.kufur,
        note: 'İsimden isim türetme; ayrıca "yok" var — olumsuzlama tuzağı.'),
    GoldCase.flag(
        text: 'canına okurum bak',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Sözlük ifadesi, pekiştireçle.'),
    GoldCase.flag(
        text: 'salağa yatma şimdi',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Yönelme durumu + deyim.'),
    GoldCase.flag(
        text: 'aptallık etme lütfen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'İsimden fiil; nazik yüzeyli.'),
    GoldCase.flag(
        text: 'terbiyesizliğin daniskası bu',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'İP-17 girdisi, türetilmiş biçimde.'),
    GoldCase.flag(
        text: 'pişman edeceğim seni buna',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Sözlük ifadesi, araya nesne girmiş.'),
    GoldCase.flag(
        text: 'iğrenç bir insansın gerçekten',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: '"iğrenç" sözlüğe BİLİNÇLİ olarak alınmadı — bu örnek o '
            'kararın maliyetini ölçüde görünür tutar.'),

    // ═══════════════════════════════════════════════════════════════════════
    // ÖRTÜK SALDIRI — İP-15'tekilerden farklı deyimsel kuruluşlar
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'iki çift laf edemiyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Deyimsel yetersizlik atfı — örüntü ailesi YOK.'),
    GoldCase.flag(
        text: 'senin çapın bu kadar',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kapasite sınırlaması — örüntü ailesi YOK.'),
    GoldCase.flag(
        text: 'boyunu aşan işlere karışma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Yetkisizleştirme deyimi — örüntü ailesi YOK.'),
    GoldCase.flag(
        text: 'sende akıl mı var',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Retorik soruyla zekâ reddi.'),
    GoldCase.flag(
        text: 'bu kafayla bir yere varamazsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Gelecek reddi; "kafan basmaz" ailesine yakın ama farklı.'),
    GoldCase.flag(
        text: 'sen ne ayaksın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Argo yetkisizleştirme.'),
    GoldCase.flag(
        text: 'gözüm görmesin seni',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Dışlama deyimi.'),
    GoldCase.flag(
        text: 'yazık sana yazık',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Acıma yoluyla aşağılama, İP-19 kalıbından farklı sözcükle.'),
    GoldCase.flag(
        text: 'büyük konuşuyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Haddini bilmeme atfı, örtük.'),
    GoldCase.flag(
        text: 'seninki de laf mı',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Katkının değersizleştirilmesi.'),
    GoldCase.flag(
        text: 'hava atma bize',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Küçümseyici emir.'),
    GoldCase.flag(
        text: 'senden bana fayda yok',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Yararsızlık atfı; "yok" olumsuzlama tuzağıyla birlikte.'),
    GoldCase.flag(
        text: 'sen önce kendine bak da sonra konuş',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İP-19 kalıbının uzatılmış hâli.'),
    GoldCase.flag(
        text: 'sus da bir dinle bakalım',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İP-19 "sus da" kalıbı, farklı devamla.'),
    GoldCase.flag(
        text: 'konuşan da kim ya',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İP-19 kalıbı, pekiştireçle.'),
    GoldCase.flag(
        text: 'adam gibi davranmayı öğren önce',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İP-19 kalıbı, farklı fiil ve sıralamayla.'),
    GoldCase.flag(
        text: 'kafan basmıyor galiba bu işlere',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İP-19 kalıbı, şimdiki zaman olumsuzuyla.'),
    GoldCase.flag(
        text: 'senin yerinde olsam hiç yazmazdım',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İP-19 kalıbı, araya "hiç" girmiş.'),
    GoldCase.flag(
        text: 'ne cahillik ama',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İP-19 kalıbı, "bu" olmadan.'),
    GoldCase.flag(
        text: 'sizin gibilerin yeri yok burada',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İP-19 kalıbı, çoğul ve devrik.'),

    // ═══════════════════════════════════════════════════════════════════════
    // NEFRET SÖYLEMİ
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'Afganların hepsi tehlikeli',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Niceleyici + sıfat çekimli suçlama.'),
    GoldCase.flag(
        text: 'Suriyeliler ülkelerine dönmeli artık',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Dışlama, gereklilik kipi + birleşik fiil.'),
    GoldCase.flag(
        text: 'Ezidiler sapkındır bence',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'İP-17 kimlik terimi + değersizleştirme.'),
    GoldCase.flag(
        text: 'bu Romanlarla aynı mahallede yaşanmaz',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Dolaylı dışlama — örüntü ailesi zayıf.'),
    GoldCase.flag(
        text: 'Yunanlılara güvenilmez hiçbir zaman',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'İP-19 sözvarlığı, yönelme durumuyla.'),
    GoldCase.flag(
        text: 'engelliler topluma yük',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Yük söylemi — sözvarlığında YOK.'),
    GoldCase.flag(
        text: 'Uygurlar hakkında konuştuk uzun uzun. Bunlar yok edilmeli',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Gönderge çözümlemesi, İP-17 kimlik terimiyle.'),
    GoldCase.flag(
        text: 'başörtülüler geri kafalıdır',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'İP-17 kimlik terimi + sözvarlığında olmayan yüklem.'),
    GoldCase.clean(
        text: 'Afgan mutfağı üzerine bir yazı hazırlıyorum',
        group: GoldGroup.nefret,
        note: 'Kimlik adı + nötr bağlam.'),
    GoldCase.clean(
        text: 'Suriyeli aileler için Türkçe kursu açıldı',
        group: GoldGroup.nefret,
        note: 'Dayanışma bağlamı.'),
    GoldCase.clean(
        text: 'Ezidi toplumunun tarihi üzerine sunum yaptım',
        group: GoldGroup.nefret,
        note: 'Akademik bağlam.'),
    GoldCase.clean(
        text: 'engelliler için asansör talebimiz kabul edildi',
        group: GoldGroup.nefret,
        note: 'Hak talebi.'),
    GoldCase.clean(
        text: 'başörtülü öğrencilerin üniversite hakkı tartışıldı',
        group: GoldGroup.nefret,
        note: 'Hak temelli haber dili.'),
    GoldCase.clean(
        text: 'Yunanlı meslektaşımızla ortak proje yürütüyoruz',
        group: GoldGroup.nefret,
        note: 'İş bağlamı.'),
    GoldCase.clean(
        text: 'Uygur kültürü sergisini gezdik',
        group: GoldGroup.nefret,
        note: 'Kültür bağlamı.'),

    // ═══════════════════════════════════════════════════════════════════════
    // MASUM / TUZAK — üçte biri İP-19 örüntülerinin yakın-kaçışıdır
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.clean(
        text: 'sustu da öyle başladı anlatmaya',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: "sus da" ile aynı harf dizisi.'),
    GoldCase.clean(
        text: 'acıdım ona, çok zor durumda',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: üçüncü şahıs, samimi acıma.'),
    GoldCase.clean(
        text: 'kim sordu bunu acaba, ben de merak ettim',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: ikinci şahıs göstergesi YOK.'),
    GoldCase.clean(
        text: 'önce kendine iyi bak, sağlığın önemli',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: araya nitelik girmiş, samimi öğüt.'),
    GoldCase.clean(
        text: 'senin yerinde olsam ben de üzülürdüm',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: empati, susturma yüklemi yok.'),
    GoldCase.clean(
        text: 'adam gibi bir iş buldu sonunda',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: "adam gibi" nitelik olarak.'),
    GoldCase.clean(
        text: 'utanmadan söylüyorum, gurur duyuyorum',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: birinci şahıs çekimi.'),
    GoldCase.clean(
        text: 'cehaletle mücadele en temel iş',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: atfetme yüklemi yok.'),
    GoldCase.clean(
        text: 'bu seviyede bir oyuncu bulmak zor',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: "bu seviyede" olumlu kullanımda.'),
    GoldCase.clean(
        text: 'market soyulmuş, hepsi hırsız çıkmış',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: niceleyici + suçlama ama kimlik ÖNCÜLÜ YOK.'),
    GoldCase.clean(
        text: 'Suriyeli doktorlar hasta insanlar için gönüllü çalışıyor',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: "hasta insanlar" nesne konumunda.'),
    GoldCase.clean(
        text: 'bu makine bozuktur, tamire vereceğim',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: yuvarlak ünlülü bildirme eki, kimlik yok.'),
    GoldCase.clean(
        text: 'tehlikeli bir virajdı, yavaşladım',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: "tehlikeli" kimlik yuvası olmadan.'),
    GoldCase.clean(
        text: 'bu kaynak güvenilmez, başkasına bakalım',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: "güvenilmez" kimlik yuvası olmadan.'),
    GoldCase.clean(
        text: 'haddini bilen bir insandı, saygı duyardım',
        group: GoldGroup.masum,
        note: 'İP-19 yakın-kaçış: "had" kalıbı olumlu kullanımda.'),
    GoldCase.clean(
        text: 'sus payı vermişler diye duydum',
        group: GoldGroup.masum,
        note: 'Klasik tuzak: "sus" ifade içinde.'),
    GoldCase.clean(
        text: 'kafamı topladım, işe döndüm',
        group: GoldGroup.masum,
        note: 'Tuzak: "kafa" birinci şahıs iyeliğinde.'),
    GoldCase.clean(
        text: 'yıkım kararı mahkemeden döndü',
        group: GoldGroup.masum,
        note: 'Tuzak: "yıkıl karşımdan" ile ortak kök.'),
    GoldCase.clean(
        text: 'defter aldım kırtasiyeden',
        group: GoldGroup.masum,
        note: 'Tuzak: "defol" ile ilk heceler ortak.'),
    GoldCase.clean(
        text: 'toplantıyı erteledik, herkes yoğun',
        group: GoldGroup.masum,
        note: 'Sıradan cümle.'),
    GoldCase.clean(
        text: 'kitabı bitirdim, çok beğendim',
        group: GoldGroup.masum,
        note: 'Sıradan olumlu cümle.'),
    GoldCase.clean(
        text: 'hasta ziyaretinden yeni döndüm',
        group: GoldGroup.masum,
        note: 'Tuzak: "hasta" kimlik yuvası olmadan.'),
    GoldCase.clean(
        text: 'parazit yapıyor bu telsiz',
        group: GoldGroup.masum,
        note: 'Tuzak: İP-17 sözlük girdisi, yönelim yok.'),
    GoldCase.clean(
        text: 'asalak bitkiler üzerine ödev hazırladım',
        group: GoldGroup.masum,
        note: 'Tuzak: biyoloji bağlamı.'),
    GoldCase.clean(
        text: 'yaşlılar günü etkinliği düzenlendi',
        group: GoldGroup.masum,
        note: 'Tuzak: İP-17 kimlik terimi, olumlu bağlam.'),

    // ═══════════════════════════════════════════════════════════════════════
    // BAĞLAM
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.clean(
        text: 'bana "puşt" diye seslendi, şikayetçi oldum',
        group: GoldGroup.baglam,
        note: 'İP-17 küfrü, aktarım bağlamında.'),
    GoldCase.clean(
        text: 'komşum "defol" diye bağırdı, çok korktum',
        group: GoldGroup.baglam,
        note: 'İP-17 girdisi, alıntı + mağduriyet.'),
    GoldCase.clean(
        text: 'terbiyesiz değil, sadece heyecanlı bir çocuk',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama, İP-17 girdisiyle.'),
    GoldCase.clean(
        text: 'kendimi çok değersiz hissettim o gün',
        group: GoldGroup.baglam,
        note: 'Öz-ifade, İP-17 girdisiyle.'),
    GoldCase.clean(
        text: 'nankör olduğumu söylediler, çok üzüldüm',
        group: GoldGroup.baglam,
        note: 'Aktarım + mağduriyet.'),
    GoldCase.clean(
        text: 'psikopat değil, sadece çok yorgun',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama.'),
    GoldCase.clean(
        text: 'ona asalak demek doğru değil bence',
        group: GoldGroup.baglam,
        note: 'Terimi eleştirmek, kullanmak değil.'),
    GoldCase.clean(
        text: 'nefret söylemiyle mücadele eğitimi aldık',
        group: GoldGroup.baglam,
        note: 'Konuyu adlandırma.'),
    GoldCase.clean(
        text: '"senin gibiler" diye başlayan yorumları bildiriyorum',
        group: GoldGroup.baglam,
        note: 'Örüntünün kendisi alıntı içinde.'),
    GoldCase.clean(
        text: 'kimseye geri zekalı demem, doğru bulmuyorum',
        group: GoldGroup.baglam,
        note: 'İP-17 girdisi, olumsuz fiil çekimiyle.'),
  ];
}
