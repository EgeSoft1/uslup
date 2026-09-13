// =============================================================================
// İP-29 · ALTINCI AYRIK KÜME — İP-28 genişletmesinden sonraki geçerli ölçüm
// Dosya: packages/civility_core/lib/src/eval/generalization5_dataset.dart
//
// ── NEDEN YENİ BİR KÜME GEREKTİ ───────────────────────────────────────────
// İP-27 kümesi yandı: deyim katmanı (İP-28) onun ilk geçişte kaçırdığı 31
// örneğe bakılarak yazıldı. Aynı dönemde sözlüğe gizleme varyantları ve yeni
// girdiler eklendi. Bugünkü motorun hiç görmediği cümlelerdeki başarımını
// ölçen geçerli bir sayı YOKTU; bu küme o boşluğu kapatır.
//
// ── PROTOKOL ──────────────────────────────────────────────────────────────
// 13 Eylül 2026'da, motor bu kümeye karşı HİÇ çalıştırılmadan yazıldı ve
// ölçümden ÖNCE ayrı bir commit olarak depoya girdi (commit zamanı kanıttır).
// Ölçüm bir kez alınır, sonuç düzeltilmeden raporlanır. Bu kümeye bakılarak
// sözlük, örüntü ya da bağlam kuralı değiştirilirse küme yanar ve kayda geçer.
//
// Yazar, örüntü dosyalarının düzenli ifadelerini okumadan, yalnızca ürünün
// kamuya açık yetenek tanımlarından (README, demo senaryoları) yola çıktı.
// Yine de tek etiketleyicilidir ve motoru geliştiren ekiple aynı kaynaktan
// gelir — bu, önceki kümelerle aynı sınırdır ve raporda belirtilmelidir.
//
// ── KÜMENİN ÜÇ PARÇASI ────────────────────────────────────────────────────
//   1. Bilinen yeteneklerin YENİ örnekleri (30 · müdahale)
//      Biçimbilim, gizleme, ötekileştirme, susturma, tehdit, toplu suçlama —
//      ürünün yapabildiğini söylediği şeylerin hiç görülmemiş kuruluşları.
//
//   2. Yakın-kaçışlar ve bağlam tuzakları (30 · temiz)
//      Mağdur anlatısı, olumsuzlama, alıntı, öz-ifade, kimliğin nötr anılışı,
//      sert ama meşru eleştiri ve alt dizi tuzakları. Kesinliğin sınavı.
//
//   3. Serbest düşmanca ifadeler (30 · müdahale)
//      Hiçbir aileye bakılmadan yazılmış deyimler, lanetler, örtük tehditler,
//      cinsiyet/yaş/engellilik hedefli genellemeler. Tavanın ölçüsü.
//
// ── BEKLENTİ (ölçümden ÖNCE yazılmıştır) ──────────────────────────────────
// Kesinlik: %95 ve üstü. İkinci parçadaki alıntı ve mağdur cümleleri bağlam
//   katmanının en zor olduğu yerdir; bir iki yanlış pozitif sürpriz olmaz.
// Duyarlılık: birinci parçada %80 civarı; üçüncü parçada %30–50. Toplam
//   %55–70 bandı. Cinsiyet ve yaş hedefli cümlelerin kaçması beklenir —
//   kimlik söz varlığının kapsamı etnik köken, inanç ve yönelim ağırlıklıdır.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

abstract final class Generalization5Dataset {
  static const List<GoldCase> cases = [
    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 1 — Bilinen yeteneklerin yeni örnekleri (30)
    // ═══════════════════════════════════════════════════════════════════════

    // ── Açık saldırı: biçimbilim ve gizleme ───────────────────────────────
    GoldCase.flag(
        text: 'sen gerçekten tam bir salaksın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P1 · kök + 2. tekil bildirme eki.'),
    GoldCase.flag(
        text: 'bu adam resmen bir şerefsiz',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P1 · üçüncü kişiye yöneltilmiş açık hakaret.'),
    GoldCase.flag(
        text: 'aptallığın had safhada',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P1 · yapım + iyelik eki zinciri (aptal+lık+ın).'),
    GoldCase.flag(
        text: 'geri zekalılar gibi davranma',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P1 · boşluklu öbek + çoğul + benzetme.'),
    GoldCase.flag(
        text: 's3n t4m bir 4ptalsın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P1 · birden fazla kelimeye yayılmış leet gizleme.'),
    GoldCase.flag(
        text: 'ahmakk mısın nesin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P1 · harf tekrarı + soru kuruluşu.'),
    GoldCase.flag(
        text: 'yavşağın tekisin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.kufur,
        note: 'P1 · ünsüz yumuşaması (yavşak → yavşağ).'),
    GoldCase.flag(
        text: 'kolunu kırarım senin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P1 · fiziksel tehdit, devrik; sözlükte olmayan organ adı.'),
    GoldCase.flag(
        text: 'gerzek herif, ne anlarsın futboldan',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P1 · hitap + bilgi yetkinliğinin reddi.'),
    GoldCase.flag(
        text: 'çeneni kapatmazsan pişman olursun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P1 · koşullu örtük tehdit.'),

    // ── Örtük saldırı: ötekileştirme, küçümseme, susturma ─────────────────
    GoldCase.flag(
        text: 'senin gibilerle aynı masada oturmam',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · "gibiler" ötekileştirme, dışlama beyanı.'),
    GoldCase.flag(
        text: 'sende hiç utanma yok mu',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · nitelik reddi soru kuruluşu.'),
    GoldCase.flag(
        text: 'kes sesini artık',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · susturma emri, devrik.'),
    GoldCase.flag(
        text: 'sana soran oldu mu',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · katkının değersizleştirilmesi.'),
    GoldCase.flag(
        text: 'bu kafayla daha çok beklersin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · yetkinlik küçümseme.'),
    GoldCase.flag(
        text: 'bu gidişle sizden adam olmayacak',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · kişiliğin reddi, çoğul hitap, gelecek zaman.'),
    GoldCase.flag(
        text: 'haddini bilmeyen tiplerle konuşmuyorum',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · had kuruluşu + kategoriye indirgeme.'),
    GoldCase.flag(
        text: 'sen kim oluyorsun da bana akıl veriyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · meşruiyet reddi.'),
    GoldCase.flag(
        text: 'sen otur oturduğun yerde de büyüklerin işine karışma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P1 · değersizleştirici emir, uzatılmış.'),
    GoldCase.flag(
        text: 'gününü sana göstereceğim',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P1 · deyimsel tehdit, araya giren zamir.'),
    GoldCase.flag(
        text: 'bu yaptığını ödeyeceksin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P1 · örtük tehdit, bedel kuruluşu.'),
    GoldCase.flag(
        text: 'evinin yolunu biliyorum, dikkatli ol',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P1 · adres bilgisiyle tehdit.'),

    // ── Nefret: toplu suçlama, insanlıktan çıkarma, dışlama ───────────────
    GoldCase.flag(
        text: 'Suriyelilerin hepsi asalak',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P1 · niceleyici + kimlik + insanlıktan çıkarma.'),
    GoldCase.flag(
        text: 'Afganlar bu ülkeden gönderilmeli',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P1 · dışlama, edilgen zorunluluk.'),
    GoldCase.flag(
        text: 'Kürtler zaten hep böyledir, güvenilmez',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P1 · genelleme + düşman yüklem.'),
    GoldCase.flag(
        text: 'Ermeniler hain bir millettir',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P1 · toplu suçlama, sıfat tamlaması.'),
    GoldCase.flag(
        text: 'eşcinseller hasta insanlar',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P1 · yönelim ekseni, hastalıklaştırma.'),
    GoldCase.flag(
        text: 'bu Romanların hepsi hırsız',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P1 · gösterici + niceleyici + suç yüklemi.'),
    GoldCase.flag(
        text: 'Aleviler bu mahalleye taşınmasın',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P1 · dışlama, istek kipi.'),
    GoldCase.flag(
        text: 'Yahudilerin kökü kazınmalı',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P1 · varlık reddi, deyimsel.'),

    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 2 — Yakın-kaçışlar ve bağlam tuzakları (30)
    // ═══════════════════════════════════════════════════════════════════════

    // ── Bağlam: mağdur, olumsuzlama, alıntı, öz-ifade ─────────────────────
    GoldCase.clean(
        text: 'bana "salak" dedi diye ağladım',
        group: GoldGroup.baglam,
        note: 'P2 · mağdur anlatısı, tırnaklı alıntı.'),
    GoldCase.clean(
        text: 'hiç de aptal değilsin, sadece yorgunsun',
        group: GoldGroup.baglam,
        note: 'P2 · olumsuzlama + teselli.'),
    GoldCase.clean(
        text: 'kendime kızıyorum, ne aptalca bir hata yaptım',
        group: GoldGroup.baglam,
        note: 'P2 · öz-ifade, eylemi niteleyen sıfat.'),
    GoldCase.clean(
        text: 'öğretmen "şerefsiz" kelimesini kullanmanın suç olabileceğini anlattı',
        group: GoldGroup.baglam,
        note: 'P2 · üst-dil alıntısı, eğitim bağlamı.'),
    GoldCase.clean(
        text: 'birisi bana tehdit mesajı attı, "seni bulurum" yazmış',
        group: GoldGroup.baglam,
        note: 'P2 · tehdidin mağdur tarafından aktarılması.'),
    GoldCase.clean(
        text: 'kimseye gerzek demem, doğru bulmuyorum',
        group: GoldGroup.baglam,
        note: 'P2 · olumsuz fiil çekimiyle ret.'),
    GoldCase.clean(
        text: 'annem "eşek gibi çalışıyorsun" dedi, gülüştük',
        group: GoldGroup.baglam,
        note: 'P2 · "eşek gibi çalışmak" deyimi = çok çalışmak, aktarım.'),
    GoldCase.clean(
        text: 'ben aptal değilim, sadece dikkatsizim',
        group: GoldGroup.baglam,
        note: 'P2 · birinci şahıs olumsuzlama.'),
    GoldCase.clean(
        text: 'Selin\'e "senin gibilerden bu beklenirdi" demişler, çok ayıp',
        group: GoldGroup.baglam,
        note: 'P2 · ötekileştirme kalıbının kınanarak aktarılması.'),
    GoldCase.clean(
        text: '"haddini bil" diyen müdüre itiraz ettim',
        group: GoldGroup.baglam,
        note: 'P2 · susturma kalıbının aktarımı.'),
    GoldCase.clean(
        text: 'romanda kötü adam kahramana "gebertirim seni" diye bağırıyor',
        group: GoldGroup.baglam,
        note: 'P2 · kurgu betimlemesi, alıntı.'),
    GoldCase.clean(
        text: 'sınavda salak gibi bir hata yaptım',
        group: GoldGroup.baglam,
        note: 'P2 · öz-ifade, benzetme konuşanın kendisine.'),

    // ── Masum: alt dizi tuzakları ve sert ama meşru eleştiri ──────────────
    GoldCase.clean(
        text: 'şikayetçi olduğum konuyu dilekçeyle bildirdim',
        group: GoldGroup.masum,
        note: 'P2 · "şik" alt dizisi.'),
    GoldCase.clean(
        text: 'kargoyu yarın ofise götürürüm',
        group: GoldGroup.masum,
        note: 'P2 · "göt" alt dizisi, gelecek zaman.'),
    GoldCase.clean(
        text: 'elektrik akımı yüzünden sigorta attı',
        group: GoldGroup.masum,
        note: 'P2 · "ak" çekimi — "aq" kısaltmasıyla çakışma tuzağı.'),
    GoldCase.clean(
        text: 'malzemeleri market listesine ekledim',
        group: GoldGroup.masum,
        note: 'P2 · "mal" alt dizisi.'),
    GoldCase.clean(
        text: 'köpeğim bugün parkta çok yoruldu',
        group: GoldGroup.masum,
        note: 'P2 · hayvan adı, gerçek anlam.'),
    GoldCase.clean(
        text: 'eşek arısı kolumu soktu, şişti',
        group: GoldGroup.masum,
        note: 'P2 · hayvan adı öbek içinde, yönelim yok.'),
    GoldCase.clean(
        text: 'bu fikir bence tamamen yanlış ve savunulamaz',
        group: GoldGroup.masum,
        note: 'P2 · sert ama fikre yönelik meşru eleştiri.'),
    GoldCase.clean(
        text: 'o çocuk bahçede top oynuyor',
        group: GoldGroup.masum,
        note: 'P2 · "o ç…" komşuluğu — birleştirme tuzağı.'),
    GoldCase.clean(
        text: 'sikke ve pul koleksiyonum var',
        group: GoldGroup.masum,
        note: 'P2 · "sik" alt dizisi, maskelenmiş kök.'),
    GoldCase.clean(
        text: 'ağaç diktik, dayanışma ağımız büyüdü',
        group: GoldGroup.masum,
        note: 'P2 · "ağ" çekimi — yumuşama çakışması tuzağı.'),
    GoldCase.clean(
        text: 'yönetimin bu kararı çok kötü, bir an önce değişmeli',
        group: GoldGroup.masum,
        note: 'P2 · kuruma yönelik sert eleştiri.'),
    GoldCase.clean(
        text: 'dün akşam maç çok sıkıcıydı, erken kapattım',
        group: GoldGroup.masum,
        note: 'P2 · "sık" alt dizisi.'),

    // ── Nefret dilimi yakın-kaçışları: kimliğin nötr anılışı ──────────────
    GoldCase.clean(
        text: 'Kürt arkadaşımın düğününe gittik',
        group: GoldGroup.nefret,
        note: 'P2 · kimlik adı, olumlu bağlam.'),
    GoldCase.clean(
        text: 'Suriyeli komşumuz bize yemek getirdi',
        group: GoldGroup.nefret,
        note: 'P2 · kimlik adı, gündelik.'),
    GoldCase.clean(
        text: 'cemevinde Alevi müziği konseri vardı',
        group: GoldGroup.nefret,
        note: 'P2 · inanç ekseni, kültürel.'),
    GoldCase.clean(
        text: 'eşcinsel bireylerin hakları panelde konuşuldu',
        group: GoldGroup.nefret,
        note: 'P2 · yönelim ekseni, hak savunusu.'),
    GoldCase.clean(
        text: 'Yahudi tarihi üzerine bir kitap okuyorum',
        group: GoldGroup.nefret,
        note: 'P2 · inanç ekseni, akademik.'),
    GoldCase.clean(
        text: 'Roman müziği dinlemeyi çok severim',
        group: GoldGroup.nefret,
        note: 'P2 · etnik eksen, olumlu.'),

    // ═══════════════════════════════════════════════════════════════════════
    // PARÇA 3 — Serbest düşmanca ifadeler (30)
    // ═══════════════════════════════════════════════════════════════════════

    // ── Deyim ve kalıplaşmış küçümseme ────────────────────────────────────
    GoldCase.flag(
        text: 'senin aklın ermez bu işlere',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · yetkinlik reddi, "aklı ermek".'),
    GoldCase.flag(
        text: 'ağzından çıkanı kulağın duymuyor',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · deyim.'),
    GoldCase.flag(
        text: 'sen daha dünkü çocuksun, bilmezsin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · deyim + bilgi yetkinliğinin reddi.'),
    GoldCase.flag(
        text: 'boyundan büyük laflar etme',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · deyim, emir kipi.'),
    GoldCase.flag(
        text: 'eşek hoşaftan ne anlar, sen de bundan anlamazsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P3 · atasözü + hayvan benzetmesi kişiye bağlanıyor.'),
    GoldCase.flag(
        text: 'kafan çalışmıyor galiba bugün',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · zihinsel yetkinlik küçümseme.'),
    GoldCase.flag(
        text: 'tam bir kaz kafalısın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P3 · "kaz kafalı" argo hakaret.'),
    GoldCase.flag(
        text: 'bir sen eksiktin zaten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · varlığın yük sayılması, deyimsel.'),
    GoldCase.flag(
        text: 'senin gibi bir tipi kim takar',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · kategoriye indirgeme + önemsizleştirme.'),
    GoldCase.flag(
        text: 'senin yaptığın tam bir cahil cesareti',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · "cahil cesareti" deyimi kişiye yöneltilmiş.'),
    GoldCase.flag(
        text: 'ağzını açma, rezil olursun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · susturma + küçük düşürme.'),
    GoldCase.flag(
        text: 'o kafayla ancak bu kadar olur',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · yetkinlik küçümseme.'),
    GoldCase.flag(
        text: 'senin gibi kaba birini hayatımda görmedim',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P3 · karakter saldırısı, karşılaştırma kuruluşu.'),
    GoldCase.flag(
        text: 'hepiniz aynı kafadasınız, bir işe yaramazsınız',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · genelleme + değersizleştirme.'),
    GoldCase.flag(
        text: 'senin yerin burası değil, çek git',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · dışlama + kovma.'),

    // ── Lanet ve ilenme ───────────────────────────────────────────────────
    GoldCase.flag(
        text: 'dilini eşek arısı soksun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P3 · ilenme; hayvan adı öbek içinde ama işlev saldırı.'),
    GoldCase.flag(
        text: 'Allah belanı versin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P3 · lanet.'),
    GoldCase.flag(
        text: 'ömrün boyunca sürün inşallah',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'P3 · ilenme, dilek kipi.'),

    // ── Örtük tehdit ──────────────────────────────────────────────────────
    GoldCase.flag(
        text: 'sen bittin, bunu unutma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P3 · örtük tehdit.'),
    GoldCase.flag(
        text: 'karşıma çıkma, iyi olmaz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P3 · koşullu örtük tehdit.'),
    GoldCase.flag(
        text: 'sokakta görürsem tanırım seni',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P3 · örtük fiziksel tehdit.'),
    GoldCase.flag(
        text: 'o ağzını dağıtırım',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P3 · fiziksel tehdit, sözlükte olmayan fiil.'),
    GoldCase.flag(
        text: 'bir daha yazarsan evinin önünde beklerim',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'P3 · takip tehdidi.'),

    // ── Cinsiyet, yaş, engellilik, göç hedefli genelleme ──────────────────
    GoldCase.flag(
        text: 'kadınlar direksiyona geçmesin',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P3 · cinsiyet ekseni, dışlama.'),
    GoldCase.flag(
        text: 'kızlar zaten mühendislikten anlamaz',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P3 · cinsiyet ekseni, yetkinlik reddi.'),
    GoldCase.flag(
        text: 'engelliler evde otursun',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P3 · engellilik ekseni, dışlama.'),
    GoldCase.flag(
        text: 'yaşlılar yük oluyor, bir an önce gitsinler',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P3 · yaş ekseni, varlığın yük sayılması.'),
    GoldCase.flag(
        text: 'bu göçmenler ülkeyi kirletiyor',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P3 · göç statüsü, insanlıktan çıkarma.'),
    GoldCase.flag(
        text: 'bu ülkede senin gibilere yer yok',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'P3 · dışlama, "yer yok" kuruluşu.'),
    GoldCase.flag(
        text: 'Karadenizliler zaten kafasız olur',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'P3 · bölgesel köken ekseni, genelleme.'),
  ];
}
