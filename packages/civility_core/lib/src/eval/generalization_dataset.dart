// =============================================================================
// İP-15 · İKİNCİ AYRIK KÜME — bağımsız genelleme ölçümü
// Dosya: packages/civility_core/lib/src/eval/generalization_dataset.dart
//
// ── NEDEN İKİNCİ BİR AYRIK KÜME ───────────────────────────────────────────
// Birinci ayrık küme (`holdout_dataset.dart`) artık YANMIŞTIR: üzerinde
// ölçüm alındıktan sonra motor o kümeye bakılarak düzeltildi ve bugünkü
// %99,0'lık skoru bir genelleme kanıtı değildir. O kümenin tek geçerli
// ölçümü, ilk geçişte alınan **F1 = %84,2**'dir.
//
// Bu dosya, o tek atışlık ölçümü tekrar mümkün kılmak için vardır.
//
// ── PROTOKOL ──────────────────────────────────────────────────────────────
//   1. Küme, İP-17 söz varlığı genişletmesi TAMAMLANDIKTAN SONRA yazıldı.
//      Yani genişletmenin bu kümeye göre ayarlanmış olması MÜMKÜN DEĞİLDİR;
//      küme, kendisinden önce donmuş bir motoru ölçer.
//   2. Ölçüm BİR KEZ alınır ve sonuç düzeltme yapılmadan raporlanır.
//   3. Bu kümeye bakılarak tek bir örüntü veya sözlük girdisi değiştirilirse,
//      küme yanar ve sonuç bir daha "ayrık" olarak raporlanamaz. O anda
//      `docs/04_MODEL_DEGERLENDIRME.md` §5'e bir yanma kaydı düşülür.
//
// ── DÜRÜSTLÜK BEYANI — BU KÜME NE DEĞİLDİR ────────────────────────────────
// Bu küme **kör değildir**. Yazarı motorun örüntülerini ve sözlüğünü görmüş
// durumdadır; dolayısıyla "hiç görülmemiş bir dil dağılımı" temsil ettiği
// İDDİA EDİLEMEZ. Sağladığı tek şey — ki değerlidir — motorun bu kümeye göre
// AYARLANMAMIŞ olmasıdır.
//
// Gerçek bağımsızlık için gereken şey ikinci bir ETİKETLEYİCİDİR ve o iş
// hâlâ açıktır. Altyapısı hazırdır:
//
//   dart run bin/annotate_export.dart   → karışık sırada, etiketsiz CSV
//   dart run bin/kappa.dart <dosya>     → Cohen's kappa + uyuşmazlık dökümü
//
// İkinci etiketleyicinin etiketleri geldiğinde kappa ölçülür ve raporlanır.
// O ölçüm alınana kadar tüm metrikler TEK ETİKETLEYİCİLİDİR ve raporda
// böyle beyan edilmek zorundadır.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class GeneralizationDataset {
  static const List<GoldCase> cases = [
    // ═══════════════════════════════════════════════════════════════════════
    // AÇIK SALDIRI — sözlük katmanının çekim ve dizilişten bağımsızlığı
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'ne biçim insansın sen ya, tam bir dallamasın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'İki cümlecikli kuruluş, hakaret sonda.'),
    GoldCase.flag(
        text: 'bu kadar mankafa olunmaz ki',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Sözlükte olmayan eşanlamlı — kapsam sınırını ölçer.'),
    GoldCase.flag(
        text: 'hayvan herif yine yapmış yapacağını',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Üçüncü şahıs; yönelim aşağılayıcı adla ("herif") kuruluyor.'),
    GoldCase.flag(
        text: 'sen adam olmazsın, ezik kalacaksın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Gelecek zaman çekimi.'),
    GoldCase.flag(
        text: 'hıyarın önde gideni',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'İyelik + deyim; ikinci şahıs eki YOK.'),
    GoldCase.flag(
        text: 'yeter artık kapa çeneni',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'İfade eşleşmesi, önünde iki kelime.'),
    GoldCase.flag(
        text: 'gerizekalılığın daniskası',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'İsimden isim türetme + iyelik.'),
    GoldCase.flag(
        text: 'iki lafı bir araya getiremeyen zavallı',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Sıfat-fiil öbeğinin sonunda hakaret.'),
    GoldCase.flag(
        text: 'seni bulurum merak etme',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Sözlükteki "bulurum seni" ifadesinin devrik hâli.'),
    GoldCase.flag(
        text: 'kafanı kırarım senin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Sözlükte olmayan tehdit fiili.'),
    GoldCase.flag(
        text: 'ahlaksız herif çıktın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'İP-17 girdisi, üçüncü şahıs kuruluşunda.'),
    GoldCase.flag(
        text: 'şerefsizce davrandın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Zarf çekimi.'),
    GoldCase.flag(
        text: 'sana had bildiririm',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Sözlükteki "haddini bil" ifadesinin farklı çekimi.'),
    GoldCase.flag(
        text: 'orospu evladı',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.kufur,
        note: 'Yaygın küfür tamlaması.'),
    GoldCase.flag(
        text: 'cahilsin resmen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Yönelim ekiyle; pekiştireç sonda.'),

    // ═══════════════════════════════════════════════════════════════════════
    // ÖRTÜK SALDIRI — küfürsüz düşmanlık, kelimede değil dizilişte
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'senin gibiler yüzünden bu ülke böyle',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Ötekileştirme; tek bir yasaklı kelime yok.'),
    GoldCase.flag(
        text: 'boşuna konuşma, zaten anlamazsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Susturma + yetersizlik atfı.'),
    GoldCase.flag(
        text: 'hadi canım sen de, komik oluyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Alaycı küçümseme.'),
    GoldCase.flag(
        text: 'bu seviyede biriyle tartışmam',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Seviye üstünlüğü kalıbı, dolaylı kuruluş.'),
    GoldCase.flag(
        text: 'sana bir şey anlatmak nafile',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Eski Türkçe sözcükle kurulmuş küçümseme.'),
    GoldCase.flag(
        text: 'senden başka ne beklenirdi ki',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kalıbın geniş zaman değil, hikâye bileşik çekimi.'),
    GoldCase.flag(
        text: 'ağzından çıkanı kulağın duyuyor mu',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Deyimsel aşağılama, soru kipinde.'),
    GoldCase.flag(
        text: 'kim sordu ki senin fikrini',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Değersizleştirme, devrik soru.'),
    GoldCase.flag(
        text: 'sen önce kendine bak',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Karşı suçlama kalıbı.'),
    GoldCase.flag(
        text: 'bu yazdığın tam senlik',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kişiye indirgeyen alay; sözlük karşılığı yok.'),
    GoldCase.flag(
        text: 'acıdım sana gerçekten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Acıma yoluyla aşağılama.'),
    GoldCase.flag(
        text: 'seviyene inmeyeceğim',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Seviye kalıbının farklı çekimi.'),
    GoldCase.flag(
        text: 'sus da adam konuşsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Susturma + insan yerine koymama.'),
    GoldCase.flag(
        text: 'eğitimsizliğin konuşuyor',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kusuru kişiye atfeden kuruluş.'),
    GoldCase.flag(
        text: 'bir de utanmadan savunuyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Utandırma kalıbı.'),
    GoldCase.flag(
        text: 'senin kafan basmaz bunlara',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Deyimsel yetersizlik atfı.'),
    GoldCase.flag(
        text: 'boşver, sana anlatmak zaman kaybı',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Muhatap almama.'),
    GoldCase.flag(
        text: 'kendini bir halt sanıyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kaba deyim, küfür sınırında.'),
    GoldCase.flag(
        text: 'burada senin gibilere yer yok',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Dışlama, kimlik yuvası olmadan.'),
    GoldCase.flag(
        text: 'haddini aşıyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Had kalıbının üçüncü çekimi.'),
    GoldCase.flag(
        text: 'bak şu işe, konuşan da kim',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Muhatabı yetkisiz ilan etme.'),
    GoldCase.flag(
        text: 'senin yerinde olsam susardım',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Susturma, dilek-şart kipinde.'),
    GoldCase.flag(
        text: 'bu ne cehalet böyle',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Ünlem kuruluşu; "cahil" değil "cehalet".'),
    GoldCase.flag(
        text: 'adam gibi konuşmayı öğren',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Emir kipiyle terbiye etme.'),
    GoldCase.flag(
        text: 'sana kalmış bir konu değil bu',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Yetkisizleştirme, nazik yüzeyli.'),

    // ═══════════════════════════════════════════════════════════════════════
    // NEFRET SÖYLEMİ — ve yakın-kaçışları (iki yönlü dilim)
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.flag(
        text: 'bu Suriyeliler yüzünden mahalle battı, hepsi hırsız',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Toplu suçlama, iki cümlecikli.'),
    GoldCase.flag(
        text: 'Ermeniler hep aynı, güvenilmez',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Sözvarlığında olmayan yüklem ("güvenilmez").'),
    GoldCase.flag(
        text: 'Afganlar defolup gitsin ülkelerine',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Dışlama, birleşik fiil.'),
    GoldCase.flag(
        text: 'Romanlar hep dolandırıcıdır',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Toplu suçlama, bildirme ekiyle.'),
    GoldCase.flag(
        text: 'eşcinsellik sapkınlıktır',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Kimliğin kendisini kusur ilan etme; isimleşmiş biçim.'),
    GoldCase.flag(
        text: 'Alevileri istemiyoruz mahallemizde',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Dışlama, belirtme durumu + devrik.'),
    GoldCase.flag(
        text: 'bu mültecilerin hepsi asalak',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'İnsanlıktan çıkarma, niceleyici öne alınmış.'),
    GoldCase.flag(
        text: 'Yahudiler dünyayı yönetiyor, hepsi hain',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Komplo kalıbı + toplu suçlama.'),
    GoldCase.flag(
        text: 'Kürtler bu ülkeden gitmeli',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Dışlama, gereklilik kipi ("gitmeli").'),
    GoldCase.flag(
        text: 'translar hasta insanlar',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Patolojileştirme; "hastalıklı" değil "hasta".'),
    GoldCase.flag(
        text: 'Araplar pis, hepsi öyle',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Toplu suçlama, yüklem eki YOK (cümle sonu değil).'),
    GoldCase.flag(
        text: 'şu Çingeneler yine geldi',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Sözlükteki epitet, düşmanca yüklem olmadan.'),
    GoldCase.clean(
        text: 'Suriyeli öğrencilerimiz için burs kampanyası başlattık',
        group: GoldGroup.nefret,
        note: 'Aynı kimlik terimi, dayanışma bağlamında.'),
    GoldCase.clean(
        text: 'Ermeni müziği dinlemeyi seviyorum',
        group: GoldGroup.nefret,
        note: 'Kimlik adı + olumlu yüklem.'),
    GoldCase.clean(
        text: 'Alevi inancı üzerine bir belgesel izledim',
        group: GoldGroup.nefret,
        note: 'Konuyu adlandırmak nefret söylemi değildir.'),
    GoldCase.clean(
        text: 'Ben eşcinselim ve bundan utanmıyorum',
        group: GoldGroup.nefret,
        note: 'Kimlik beyanı — bu cümlenin işaretlenmesi ürünü çürütür.'),
    GoldCase.clean(
        text: 'mülteci çocuklar için kışlık kıyafet topluyoruz',
        group: GoldGroup.nefret,
        note: 'Yardım çağrısı.'),
    GoldCase.clean(
        text: 'Roman vatandaşlarımızın sorunları mecliste konuşuldu',
        group: GoldGroup.nefret,
        note: 'Hak temelli haber dili.'),
    GoldCase.clean(
        text: 'trans bireylerin sağlık hakkı tartışıldı',
        group: GoldGroup.nefret,
        note: 'Akademik/haber bağlamı.'),
    GoldCase.clean(
        text: 'Kürtçe kursuna kaydoldum',
        group: GoldGroup.nefret,
        note: 'Dil adı; kimlik yuvasına bile düşmemeli.'),

    // ═══════════════════════════════════════════════════════════════════════
    // MASUM / TUZAK — aksan katlaması ve ön ek çakışmaları
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.clean(
        text: 'yarın maça gidiyoruz, çok heyecanlıyım',
        group: GoldGroup.masum,
        note: 'Sıradan cümle.'),
    GoldCase.clean(
        text: 'şikayetimi ilettim ama dönüş olmadı',
        group: GoldGroup.masum,
        note: 'Tuzak: "şikayet" → "sikayet".'),
    GoldCase.clean(
        text: 'malzeme listesini gönderir misin',
        group: GoldGroup.masum,
        note: 'Tuzak: "malzeme" → "mal".'),
    GoldCase.clean(
        text: 'götürdüğüm kitabı unuttum',
        group: GoldGroup.masum,
        note: 'Tuzak: "götür-" → "göt".'),
    GoldCase.clean(
        text: 'alçak basınç sistemi geliyor',
        group: GoldGroup.masum,
        note: 'Tuzak: "alçak" meteoroloji anlamında.'),
    GoldCase.clean(
        text: 'hayvanat bahçesine gittik',
        group: GoldGroup.masum,
        note: 'Tuzak: "hayvan" ön eki.'),
    GoldCase.clean(
        text: 'itiraz dilekçesi yazdım',
        group: GoldGroup.masum,
        note: 'Tuzak: "it" ön eki.'),
    GoldCase.clean(
        text: 'köpekbalığı belgeseli izledim',
        group: GoldGroup.masum,
        note: 'Tuzak: "köpek" ön eki.'),
    GoldCase.clean(
        text: 'adına sevindim gerçekten',
        group: GoldGroup.masum,
        note: 'Tuzak: "adı" → "adi".'),
    GoldCase.clean(
        text: 'eşek arısı soktu beni',
        group: GoldGroup.masum,
        note: 'Tuzak: hayvan adı, yönelim yok.'),
    GoldCase.clean(
        text: 'sikke koleksiyonu yapıyor',
        group: GoldGroup.masum,
        note: 'Maskeleme listesi denetimi.'),
    GoldCase.clean(
        text: 'pislik birikmiş, temizledim',
        group: GoldGroup.masum,
        note: 'Tuzak: "pislik" temizlik bağlamında.'),
    GoldCase.clean(
        text: 'bu roman çok sürükleyici',
        group: GoldGroup.masum,
        note: 'Tuzak: "roman" (kitap) ≠ "Romanlar" (halk).'),
    GoldCase.clean(
        text: 'kurtarma ekipleri bölgede',
        group: GoldGroup.masum,
        note: 'Tuzak: "kurt" → "Kürt" katlaması.'),
    GoldCase.clean(
        text: 'transfer dönemi başladı',
        group: GoldGroup.masum,
        note: 'Tuzak: "trans" ön eki.'),
    GoldCase.clean(
        text: 'korkuluk boyandı',
        group: GoldGroup.masum,
        note: 'Tuzak: "kor" → "kör" katlaması.'),
    GoldCase.clean(
        text: 'sağır duymaz uydurur derler',
        group: GoldGroup.masum,
        note: 'Tuzak: İP-17 kimlik terimi, atasözünde.'),
    GoldCase.clean(
        text: 'yaşlı çınar ağacı devrildi',
        group: GoldGroup.masum,
        note: 'Tuzak: tekil "yaşlı" listede DEĞİL, yalnızca "yaşlılar".'),
    GoldCase.clean(
        text: 'kazak ördüm anneme',
        group: GoldGroup.masum,
        note: 'Tuzak: "kazak" bilinçli olarak listeye alınmadı.'),
    GoldCase.clean(
        text: 'kör düğüm oldu iş',
        group: GoldGroup.masum,
        note: 'Tuzak: tekil "kör" listede değil.'),
    GoldCase.clean(
        text: 'parazit sesi geliyor telefonda',
        group: GoldGroup.masum,
        note: 'Tuzak: İP-17 sözlük girdisi, yönelim yok.'),
    GoldCase.clean(
        text: 'manyak bir hava var bugün',
        group: GoldGroup.masum,
        note: 'Tuzak: argo pekiştireç.'),
    GoldCase.clean(
        text: 'psikoloji bölümü okuyorum',
        group: GoldGroup.masum,
        note: 'Tuzak: "psikopat" ile ilk hecelerde çakışma.'),
    GoldCase.clean(
        text: 'defne ağacı diktik bahçeye',
        group: GoldGroup.masum,
        note: 'Tuzak: "defol" ile ilk hecelerde çakışma.'),
    GoldCase.clean(
        text: 'toplantı çok verimli geçti, herkese teşekkürler',
        group: GoldGroup.masum,
        note: 'Sıradan olumlu cümle.'),

    // ═══════════════════════════════════════════════════════════════════════
    // BAĞLAM — mağdur korunur: alıntı, aktarım, olumsuzlama, öz-ifade
    // ═══════════════════════════════════════════════════════════════════════
    GoldCase.clean(
        text: 'bana "kaltak" dedi, çok kırıldım',
        group: GoldGroup.baglam,
        note: 'Tacizi bildiren kişi işaretlenmez — ürünün ayırt edici iddiası.'),
    GoldCase.clean(
        text: '"geri zekalı" diye bağırdı arkamdan',
        group: GoldGroup.baglam,
        note: 'Alıntı; İP-17 girdisiyle.'),
    GoldCase.clean(
        text: 'aptal değilsin, sadece yorgunsun',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama — iltifat bağlamı.'),
    GoldCase.clean(
        text: 'kendimi çok beceriksiz hissediyorum',
        group: GoldGroup.baglam,
        note: 'Öz-ifade.'),
    GoldCase.clean(
        text: 'sınavda salak gibi hissettim',
        group: GoldGroup.baglam,
        note: 'Öz-ifade, benzetme yapısıyla.'),
    GoldCase.clean(
        text: 'hocam bana "işe yaramaz" dedi',
        group: GoldGroup.baglam,
        note: 'Aktarım.'),
    GoldCase.clean(
        text: 'nefret söylemi mağdurlarıyla röportaj yaptık',
        group: GoldGroup.baglam,
        note: 'Konuyu adlandırma.'),
    GoldCase.clean(
        text: 'arkadaşım "şerefsiz" hakaretine uğradı',
        group: GoldGroup.baglam,
        note: 'Üçüncü şahıs adına bildirim.'),
    GoldCase.clean(
        text: 'kimseye aptal demedim ki',
        group: GoldGroup.baglam,
        note: 'Olumsuz fiil çekimi.'),
    GoldCase.clean(
        text: 'sen aptal değilsin, tam tersi çok zekisin',
        group: GoldGroup.baglam,
        note: 'İkinci şahıs + olumsuzlama + iltifat.'),
    GoldCase.clean(
        text: '"defol" dedi ve kapıyı çarptı',
        group: GoldGroup.baglam,
        note: 'Alıntı; İP-17 girdisiyle.'),
    GoldCase.clean(
        text: 'hakaret etmek istemiyorum ama bu yanlış',
        group: GoldGroup.baglam,
        note: 'İnkâr kalıbı ama içinde saldırı YOK — bilinen kırılgan nokta.'),
    GoldCase.clean(
        text: 'bu yorumu saldırgan buldum, bildirdim',
        group: GoldGroup.baglam,
        note: 'Moderasyon bildirimi.'),
    GoldCase.clean(
        text: 'küfür etmeden de anlatabilirsin',
        group: GoldGroup.baglam,
        note: 'Nezakete çağrı — kategori adı geçiyor.'),
    GoldCase.clean(
        text: 'geçen yıl bana çok ağır sözler söylenmişti',
        group: GoldGroup.baglam,
        note: 'Mağduriyet anlatısı, terim geçmeden.'),
  ];
}
