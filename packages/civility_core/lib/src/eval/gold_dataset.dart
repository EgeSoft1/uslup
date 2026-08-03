// =============================================================================
// Altın Standart Veri Kümesi — Türkçe
// Dosya: packages/civility_core/lib/src/eval/gold_dataset.dart
//
// 254 etiketli örnek, dört dilim:
//
//   1. AÇIK SALDIRI   — sözlükte karşılığı olan hakaret/küfür/tehdit
//   2. ÖRTÜK SALDIRI  — küfürsüz düşmanlık (küçümseme, ötekileştirme,
//                       alaycılık, susturma, örtük tehdit)
//   3. MASUM / TUZAK  — masum metin; içinde saldırgan alt dizi barındıran
//                       meşru kelimeler ve "yakın-kaçış" cümleleri
//   4. BAĞLAM         — olumsuzlama, alıntı, öz-ifade
//
// ── 3. DİLİM NEDEN EN KALABALIK ──────────────────────────────────────────
// Yanlış pozitif bu üründe en pahalı hatadır: kullanıcı haksız yere
// uyarılırsa özelliği kapatır ve bir daha açmaz. Bu yüzden kümenin %35'i
// masum metindir ve bunların çoğu KASITLI TUZAKTIR — naif filtreleri
// düşüren gerçek Türkçe kelimeler.
//
// ── YAKIN-KAÇIŞ (near-miss) ÖRNEKLERİ ────────────────────────────────────
// Masum dilimin en değerli kısmı, saldırgan kalıplara kelime düzeyinde
// benzeyen ama düşmanca OLMAYAN cümlelerdir:
//
//   "senin gibilerden bu beklenirdi"  → saldırı
//   "senin gibi düşünenler haklı"     → masum      ← ayırt edilmeli
//   "çok başarılısın gerçekten :)"    → içten övgü ← ayırt edilmeli
//
// Bu çiftler olmadan ölçülen kesinlik değeri şişkindir.
//
// ── DÜRÜSTLÜK UYARISI ────────────────────────────────────────────────────
// Tek etiketleyici. Hakem uyumu (kappa) ölçülmemiştir. Örtük saldırı
// desenleri bu küme görüldükten SONRA yazılmıştır — yani örtük dilimdeki
// başarı, bağımsız bir küme üzerinde tekrar ölçülmelidir. Ayrıntı:
// `docs/04_MODEL_DEGERLENDIRME.md` §5.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'gold_case.dart';

/// Değerlendirme kümesi.
abstract final class GoldDataset {
  static const List<GoldCase> cases = [
    ...acikSaldiri,
    ...ortukSaldiri,
    ...nefret,
    ...masum,
    ...baglam,
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // NEFRET SÖYLEMİ — kimlik hedefli düşmanlık ve yakın-kaçışları
  //
  // Bu dilim ÇİFT YÖNLÜ ölçer ve bilinçli olarak yarı yarıya bölünmüştür:
  //
  //   Yakalanmalı  → kimlik + düşmanca kuruluş
  //   Yakalanmamalı→ AYNI kimlik terimleri, masum cümlelerde
  //
  // İkinci yarı birincisinden daha önemlidir. Kimlik adlarını yasaklı kelime
  // sayan bir sistem "Ben Kürtüm" cümlesini işaretler ve korumayı vaat ettiği
  // insanı susturur. Bu dilimdeki özgüllük, katmanın var olma şartıdır.
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<GoldCase> nefret = [
    // ── İnsanlıktan çıkarma ──
    GoldCase.flag(
        text: 'Suriyeliler hayvandır',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'İnsanlıktan çıkarma — bildirme ekiyle yüklem konumunda.'),
    GoldCase.flag(
        text: 'bu mülteciler hasarat',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'İnsanlıktan çıkarma — metin sonu, ek yok.'),

    // ── Varlık reddi / şiddete çağrı (en ağır) ──
    GoldCase.flag(
        text: 'Yahudiler yok edilmeli',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Varlık reddi. TCK 216 kapsamına girebilir.'),
    GoldCase.flag(
        text: 'bunların soyunu kurutmak lazım',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'BİLİNEN SINIR: kimlik yuvası yok, yalnızca "bunlar". '
            'Şu an KAÇIYOR — gönderge çözümlemesi gerekiyor.'),

    // ── Dışlama / sürgün ──
    GoldCase.flag(
        text: 'Suriyeliler defolsun ülkelerine',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Dışlama — istek kipi.'),
    GoldCase.flag(
        text: 'Defolsun bu mülteciler',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Dışlama — ters diziliş, yüklem önde.'),
    GoldCase.flag(
        text: 'Afganları istemiyoruz burada',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Dışlama — çoğul birinci şahıs adına ret.'),

    // ── Toplu suçlama ──
    GoldCase.flag(
        text: 'Bütün Suriyeliler hırsızdır',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Toplu suçlama — niceleyici + kimlik + suç yüklemi.'),
    GoldCase.flag(
        text: 'Bu Romanlar hep dolandırıcı',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Toplu suçlama — ek olmadan, metin sonu.'),
    GoldCase.flag(
        text: 'Araplar hain',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Toplu suçlama — en kısa biçim.'),

    // ── Kimlik aşağılama ──
    GoldCase.flag(
        text: 'Aleviler aşağılıktır',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Kimlik aşağılama — inanç ekseni.'),
    GoldCase.flag(
        text: 'Eşcinseller hastalıklı',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Kimlik aşağılama — yönelim ekseni.'),
    GoldCase.flag(
        text: 'Ermeniden başka ne beklenir',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Kimliği kusurun sebebi sayan kuruluş.'),
    GoldCase.flag(
        text: 'sen zaten Ermenisin',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Kimlik yaftalama — ikinci şahsa yöneltilmiş.'),

    // ── Sözlük katmanı: hakaret sözcükleri ──
    GoldCase.flag(
        text: 'seni çingene',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Sözlük — aşağılayıcı etnik sıfat. Saygılı karşılığı "Roman".'),
    GoldCase.flag(
        text: 'o gavurlarla iş yapılmaz',
        group: GoldGroup.nefret,
        category: ToxicityCategory.nefret,
        note: 'Sözlük — inanç temelli aşağılama.'),

    // ═══ YAKALANMAMALI — kimlik terimleri masum cümlelerde ═══════════════════
    // Bu bölüm katmanın var olma şartıdır. Buradaki tek bir yanlış pozitif,
    // ürünün etik iddiasını çürütür.
    GoldCase.clean(
        text: 'Ben Kürtüm',
        group: GoldGroup.nefret,
        note: 'Kendi kimliğini beyan. ASLA işaretlenmemeli.'),
    GoldCase.clean(
        text: 'Ermeni arkadaşım geldi',
        group: GoldGroup.nefret,
        note: 'Kimlik terimi nötr bağlamda.'),
    GoldCase.clean(
        text: 'Suriyeli komşumuz çok yardımsever',
        group: GoldGroup.nefret,
        note: 'Kimlik + OLUMLU yüklem.'),
    GoldCase.clean(
        text: 'Alevi kültürü üzerine tez yazıyorum',
        group: GoldGroup.nefret,
        note: 'Akademik bağlam.'),
    GoldCase.clean(
        text: 'Eşcinsel hakları konferansına katıldım',
        group: GoldGroup.nefret,
        note: 'Hak savunuculuğu bağlamı.'),
    GoldCase.clean(
        text: 'Bütün Kürt arkadaşlarım çok misafirperver',
        group: GoldGroup.nefret,
        note: 'YAKIN-KAÇIŞ: niceleyici + kimlik, ama yüklem olumlu.'),
    GoldCase.clean(
        text: 'Romanlar müzikte çok yetenekli',
        group: GoldGroup.nefret,
        note: 'YAKIN-KAÇIŞ: genelleme ama olumlu — nefret söylemi değil.'),
    GoldCase.clean(
        text: 'Translar için dayanışma ağı kuruldu',
        group: GoldGroup.nefret,
        note: 'Dayanışma bağlamı.'),
    GoldCase.clean(
        text: 'Mülteci çocuklara ders veriyorum',
        group: GoldGroup.nefret,
        note: 'Gönüllülük bağlamı.'),
    GoldCase.clean(
        text: 'Yahudi cemaatiyle görüştük',
        group: GoldGroup.nefret,
        note: 'Haber/bildirim dili.'),

    // ── Yakın-kaçış: aynı kelimeler, düşmanca olmayan diziliş ──
    GoldCase.clean(
        text: 'Suriyeli gönüllüler hayvan haklarıyla ilgileniyor',
        group: GoldGroup.nefret,
        note: 'YAKIN-KAÇIŞ: kimlik + "hayvan" yan yana ama nesne konumunda. '
            'İlk sürümde bu cümle yanlış pozitif üretiyordu — yüklem eki '
            'şartı bu yüzden eklendi.'),
    GoldCase.clean(
        text: 'Suriyeli komşumuz memleketine gitti',
        group: GoldGroup.nefret,
        note: 'YAKIN-KAÇIŞ: bildirme kipi ("gitti"), istek kipi değil.'),
    GoldCase.clean(
        text: 'Bütün öğrenciler sınava girecek',
        group: GoldGroup.nefret,
        note: 'YAKIN-KAÇIŞ: niceleyici var, kimlik yuvası yok.'),

    // ── Ambigü kökler: aksan katlaması sonrası çakışanlar ──
    GoldCase.clean(
        text: 'Kurtlar ormanda sürü hâlinde yaşar',
        group: GoldGroup.nefret,
        note: 'AMBİGÜ KÖK: "kurtlar" (hayvan) ≠ "kurtler" (Kürtler). '
            'Ünlü uyumu aksan katlamasından sonra da ayırt ediyor.'),
    GoldCase.clean(
        text: 'Kurtarma ekibi bölgeye ulaştı',
        group: GoldGroup.nefret,
        note: 'AMBİGÜ KÖK: "kurtar-" fiili.'),
    GoldCase.clean(
        text: 'Bu roman çok güzeldi',
        group: GoldGroup.nefret,
        note: 'AMBİGÜ KÖK: "roman" (kitap) ≠ "romanlar" (halk).'),
    GoldCase.clean(
        text: 'Lazım olan malzemeyi aldım',
        group: GoldGroup.nefret,
        note: 'AMBİGÜ KÖK: "lazım" ≠ "lazlar".'),
    GoldCase.clean(
        text: 'Transfer işlemi tamamlandı',
        group: GoldGroup.nefret,
        note: 'AMBİGÜ KÖK: "transfer" ≠ "translar".'),
    GoldCase.clean(
        text: 'Arabayı tamire götürdüm',
        group: GoldGroup.nefret,
        note: 'AMBİGÜ KÖK: "araba" ≠ "Arap" (b ≠ p).'),
    GoldCase.clean(
        text: 'Geyik sürüsü yolu kesti',
        group: GoldGroup.nefret,
        note: 'AMBİGÜ KÖK: "geyik" ≠ "geyler".'),

    // ── Mağdur korunur: nefret söylemini BİLDİREN kişi işaretlenmez ──
    GoldCase.clean(
        text: 'Bana "zenci" dedi, çok üzüldüm',
        group: GoldGroup.nefret,
        note: 'MAĞDUR: tacizi aktaran kişi cezalandırılmaz. '
            'Bağlam katmanı alıntıyı tanıyor.'),
    GoldCase.clean(
        text: 'Sırf Kürt olduğum için işe alınmadım',
        group: GoldGroup.nefret,
        note: 'MAĞDUR: ayrımcılık bildirimi.'),
    GoldCase.clean(
        text: 'Nefret söylemine karşı kampanya başlattık',
        group: GoldGroup.nefret,
        note: 'Karşı söylem — konuyu ADLANDIRMAK nefret söylemi değildir.'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. AÇIK SALDIRI — sözlük katmanının görevi
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<GoldCase> acikSaldiri = [
    // ── Zekâ/karakter hakareti, doğrudan yönelim ──
    GoldCase.flag(
        text: 'sen tam bir aptalsın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Temel durum: kök + ikinci şahıs eki.'),
    GoldCase.flag(
        text: 'salak mısın nesin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Soru biçiminde hakaret.'),
    GoldCase.flag(
        text: 'gerizekalı herif',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Zamir yok; kelime tek başına saldırgan.'),
    GoldCase.flag(
        text: 'şerefsizsin sen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Yüksek şiddetli karakter saldırısı.'),
    GoldCase.flag(
        text: 'ne ahmak adamsın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Ünlem yapısı içinde hakaret.'),
    GoldCase.flag(
        text: 'embesil misin gerçekten',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Yabancı kökenli hakaret.'),
    GoldCase.flag(
        text: 'beyinsiz yorumlar yapıyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Sıfat olarak kullanılan hakaret.'),
    GoldCase.flag(
        text: 'kafasız bir öneri bu',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Kişi yerine fikre yöneltilmiş ama yine hakaret.'),
    GoldCase.flag(
        text: 'dangalak gibi konuşuyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Benzetme yapısı.'),
    GoldCase.flag(
        text: 'budala mısın sen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Eski dilde hakaret.'),
    GoldCase.flag(
        text: 'namussuz insanlarsınız',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Çoğul yönelim.'),
    GoldCase.flag(
        text: 'haysiyetsiz davranıyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Onur saldırısı.'),
    GoldCase.flag(
        text: 'onursuz bir tavır sergiledin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Fiile yöneltilmiş karakter saldırısı.'),
    GoldCase.flag(
        text: 'rezil bir davranış',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Orta şiddet.'),
    GoldCase.flag(
        text: 'ezik herifin tekisin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Yaygın internet hakareti.'),
    GoldCase.flag(
        text: 'zavallı bir insansın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Acıma kılıfında aşağılama.'),
    GoldCase.flag(
        text: 'keriz misin sen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Argo hakaret.'),
    GoldCase.flag(
        text: 'avanak gibi davrandın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Argo hakaret.'),
    GoldCase.flag(
        text: 'sersem misin nesin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Düşük şiddetli hakaret; yine de müdahale beklenir.'),
    GoldCase.flag(
        text: 'çirkef bir üslubun var',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Üsluba yöneltilmiş hakaret.'),

    // ── Çokanlamlı terimler, yönelim ŞART ──
    GoldCase.flag(
        text: 'sen tam bir malsın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Çokanlamlı "mal", ikinci şahıs eki ile hakarete dönüşür.'),
    GoldCase.flag(
        text: 'adi bir insansın sen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Çokanlamlı "adi", yönelimle tetiklenir.'),
    GoldCase.flag(
        text: 'alçak herifsin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Çokanlamlı "alçak", yönelimle tetiklenir.'),
    GoldCase.flag(
        text: 'hıyarsın resmen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Sebze adı, yönelimle hakaret.'),

    // ── Hayvan benzetmesi, yönelim ŞART ──
    GoldCase.flag(
        text: 'eşeksin sen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Hayvan benzetmesi, ikinci şahıs eki.'),
    GoldCase.flag(
        text: 'öküz gibisin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Hayvan benzetmesi, zamirli.'),
    GoldCase.flag(
        text: 'domuz herif',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Hayvan benzetmesi; yönelim zamir olmadan zayıf.'),
    GoldCase.flag(
        text: 'maymun gibi davranıyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Hayvan benzetmesi, fiil ekiyle yönelim.'),
    GoldCase.flag(
        text: 'köpeksin sen resmen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Hayvan benzetmesi, ikinci şahıs eki.'),
    GoldCase.flag(
        text: 'hayvan gibi konuşuyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Genel hayvan benzetmesi.'),

    // ── Aşağılama (düşük şiddet, yüksek sıklık) ──
    GoldCase.flag(
        text: 'saçmalıyorsun resmen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Fikri değersizleştirme.'),
    GoldCase.flag(
        text: 'boş konuşuyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Fikri değersizleştirme.'),
    GoldCase.flag(
        text: 'komiksin gerçekten',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Alaycı değersizleştirme.'),
    GoldCase.flag(
        text: 'gülünç duruma düşüyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Küçümseme.'),
    GoldCase.flag(
        text: 'acınası bir savunma',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Küçümseme.'),
    GoldCase.flag(
        text: 'kapa çeneni artık',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Susturma, öbek eşleşmesi.'),
    GoldCase.flag(
        text: 'haddini bil biraz',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Susturma, öbek eşleşmesi.'),
    GoldCase.flag(
        text: 'sen kimsin ki konuşuyorsun',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Meşruiyet reddi, öbek eşleşmesi.'),
    GoldCase.flag(
        text: 'sus artık',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Tam eşleşme; "susadım" ile karışmamalı.'),
    GoldCase.flag(
        text: 'cahilsin bu konuda',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Yönelim şartlı aşağılama.'),

    // ── Tehdit ──
    GoldCase.flag(
        text: 'seni geberteceğim',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Açık ölüm tehdidi.'),
    GoldCase.flag(
        text: 'gebertirim seni',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Açık ölüm tehdidi, devrik.'),
    GoldCase.flag(
        text: 'öldürürüm valla',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Açık ölüm tehdidi.'),
    GoldCase.flag(
        text: 'parçalarım seni',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Fiziksel şiddet tehdidi.'),
    GoldCase.flag(
        text: 'mahvederim hayatını',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Dolaylı ama açık tehdit.'),
    GoldCase.flag(
        text: 'adresini biliyorum senin',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Takip imalı tehdit — en tehlikeli kalıplardan.'),
    GoldCase.flag(
        text: 'bulurum seni merak etme',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Takip imalı tehdit.'),
    GoldCase.flag(
        text: 'canına okurum',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Deyimsel tehdit.'),
    GoldCase.flag(
        text: 'pişman edeceğim seni',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Deyimsel tehdit.'),

    // ── Kaçınma (evasion) ──
    GoldCase.flag(
        text: r'$3r3fsiz herif',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Leet yazım ile gizleme.'),
    GoldCase.flag(
        text: 'a.p.t.a.l mısın',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Harf arası noktalama ile gizleme.'),
    GoldCase.flag(
        text: 'aptaaaaal',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Harf tekrarı ile gizleme.'),
    GoldCase.flag(
        text: '4pt4l mısın sen',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Rakam ikamesi ile gizleme.'),
    GoldCase.flag(
        text: 'SEN APTALSIN!!!',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Bağırma + noktalama patlaması şiddeti artırmalı.'),
    GoldCase.flag(
        text: 'gerizekalisin ya',
        group: GoldGroup.acikSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Aksansız yazım (Türkçe klavyesi olmayan kullanıcı).'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. ÖRTÜK SALDIRI — küfürsüz düşmanlık
  //
  // Sözlük tabanlı sistemlerin tamamen kör olduğu dilim. Sosyal medyadaki
  // düşmanlığın büyük kısmı buradadır: tek bir yasaklı kelime içermeyen,
  // ama tartışmayı zehirleyen ve karşı tarafı susturan ifadeler.
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<GoldCase> ortukSaldiri = [
    // ── Küçümseme / yetersizlik atfı ──
    GoldCase.flag(
        text: 'sen ne anlarsın bu işlerden',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Bilgi yetkinliğinin reddi.'),
    GoldCase.flag(
        text: 'sen ne bilirsin ki',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Bilgi yetkinliğinin reddi.'),
    GoldCase.flag(
        text: 'boşuna uğraşma, anlamazsın sen',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Öğrenme kapasitesinin reddi.'),
    GoldCase.flag(
        text: 'anlatsam da anlamazsın zaten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Öğrenme kapasitesinin reddi.'),
    GoldCase.flag(
        text: 'senin harcın değil bu iş',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Deyimsel yetersizlik atfı.'),
    GoldCase.flag(
        text: 'sana göre değil bu konu',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Yetersizlik atfı.'),
    GoldCase.flag(
        text: 'önce bir öğren de öyle konuş',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Meşruiyet reddi, emir kipiyle.'),
    GoldCase.flag(
        text: 'git de biraz araştır önce',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Meşruiyet reddi, emir kipiyle.'),
    GoldCase.flag(
        text: 'seninle tartışmak zaman kaybı',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Muhatap alınmama.'),
    GoldCase.flag(
        text: 'seviyene inip tartışamam',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Açık üstünlük iddiası.'),
    GoldCase.flag(
        text: 'bu kadarını da anlamıyorsan sorun sende',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kusuru karşı tarafa yıkma.'),
    GoldCase.flag(
        text: 'sana anlatmak nafile',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Muhatap alınmama.'),

    // ── Ötekileştirme / genelleme ──
    GoldCase.flag(
        text: 'senin gibilerden zaten bu beklenirdi',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Bireyi bir kategoriye indirgeme — ötekileştirmenin çekirdeği.'),
    GoldCase.flag(
        text: 'sizin gibi insanlar yüzünden bu hâldeyiz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Grup suçlaması; nefret söyleminin yapısal öncülü.'),
    GoldCase.flag(
        text: 'senin gibi tiplerle uğraşamam',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kategoriye indirgeme.'),
    GoldCase.flag(
        text: 'sizin gibilerle aynı ortamda bulunmak istemiyorum',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Dışlama beyanı.'),
    GoldCase.flag(
        text: 'hep böylesiniz zaten',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Genelleme saldırısı.'),
    GoldCase.flag(
        text: 'hepiniz aynısınız',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Genelleme saldırısı.'),
    GoldCase.flag(
        text: 'sizden başka ne beklenir ki',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Genelleme + küçümseme.'),
    GoldCase.flag(
        text: 'senin gibiler yüzünden bu ülke düzelmiyor',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Grup suçlaması.'),

    // ── Yok sayma / bıkkınlık ──
    GoldCase.flag(
        text: 'yine mi sen',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Varlığın yük olarak işaretlenmesi.'),
    GoldCase.flag(
        text: 'geç bunları',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Konuyu değersizleştirme.'),
    GoldCase.flag(
        text: 'boş yapma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Argo değersizleştirme.'),
    GoldCase.flag(
        text: 'saçmalama şimdi',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Emir kipi; sözlükteki "saçmalıyorsun" çekimini yakalamaz.'),
    GoldCase.flag(
        text: 'sana ne',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Muhataplığın reddi. "sana ne getireyim" ile karışmamalı.'),
    GoldCase.flag(
        text: 'sen karışma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Susturma.'),
    GoldCase.flag(
        text: 'seni ilgilendirmez',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Muhataplığın reddi.'),
    GoldCase.flag(
        text: 'kimse sormadı sana',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Katkının değersizleştirilmesi.'),
    GoldCase.flag(
        text: 'yeter artık bıktım senden',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Kişiye yönelik bıkkınlık.'),

    // ── Susturma ──
    GoldCase.flag(
        text: 'sesini kes',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Susturma emri.'),
    GoldCase.flag(
        text: 'çeneni kapat',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Sözlükteki "kapa çeneni" öbeğinin devrik hâli — kaçar.'),
    GoldCase.flag(
        text: 'haddini aşma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Sözlükteki "haddini bil" varyantı — kaçar.'),
    GoldCase.flag(
        text: 'sen kim oluyorsun da konuşuyorsun',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Sözlükteki "sen kimsin" varyantı — kaçar.'),
    GoldCase.flag(
        text: 'benimle bu şekilde konuşma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Sınırdaki durum; düşük şiddet beklenir.'),

    // ── Aşağılayıcı emir ──
    GoldCase.flag(
        text: 'git kendine iş bul',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Değersizleştirici emir.'),
    GoldCase.flag(
        text: 'otur oturduğun yerde',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Değersizleştirici emir.'),
    GoldCase.flag(
        text: 'işine bak sen',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Muhataplığın reddi.'),
    GoldCase.flag(
        text: 'aynaya bak önce',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Deyimsel karşı suçlama.'),

    // ── Karakter saldırısı (küfürsüz) ──
    GoldCase.flag(
        text: 'senden adam olmaz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Kişiliğin bütünüyle reddi — küfürsüz ama ağır.'),
    GoldCase.flag(
        text: 'sen adam olmazsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Kişiliğin bütünüyle reddi.'),
    GoldCase.flag(
        text: 'hiçbir işe yaramazsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Değersizleştirme.'),
    GoldCase.flag(
        text: 'beceriksizin tekisin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Sözlükte olmayan yetersizlik hakareti.'),
    GoldCase.flag(
        text: 'bir baltaya sap olamamışsın',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.hakaret,
        note: 'Deyimsel değersizleştirme.'),
    GoldCase.flag(
        text: 'senin yüzünden oldu hepsi',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Suçlama; sınırdaki durum.'),

    // ── Alaycılık ──
    GoldCase.flag(
        text: 'helal olsun sana valla',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Övgü sözcüğü + alay parçacığı.'),
    GoldCase.flag(
        text: 'çok başarılısın gerçekten, bravo',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Alaycı övgü. İçten övgüden ayırt edilmesi en zor durum.'),
    GoldCase.flag(
        text: 'aferin sana valla',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Övgü sözcüğü + alay parçacığı.'),
    GoldCase.flag(
        text: 'ne kadar da zekisin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Abartı kalıbıyla alay.'),
    GoldCase.flag(
        text: 'vay be, ne büyük keşif',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.asagilama,
        note: 'Abartı kalıbıyla alay.'),

    // ── Örtük tehdit ──
    GoldCase.flag(
        text: 'gününü göreceksin',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Deyimsel tehdit; hiçbir yasaklı kelime yok.'),
    GoldCase.flag(
        text: 'bu yanına kalmaz',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Deyimsel tehdit.'),
    GoldCase.flag(
        text: 'hesabını soracağım senden',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Deyimsel tehdit.'),
    GoldCase.flag(
        text: 'görüşürüz seninle',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Bağlama duyarlı tehdit; "görüşürüz, iyi akşamlar" masumdur.'),
    GoldCase.flag(
        text: 'bana bulaşma',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Örtük tehdit.'),
    GoldCase.flag(
        text: 'sonun iyi olmayacak',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Örtük tehdit.'),
    GoldCase.flag(
        text: 'yaptığın yanına kâr kalmayacak',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Örtük tehdit.'),
    GoldCase.flag(
        text: 'beni tanımıyorsun daha',
        group: GoldGroup.ortukSaldiri,
        category: ToxicityCategory.tehdit,
        note: 'Örtük tehdit.'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. MASUM / TUZAK — kesinliğin gerçek sınavı
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<GoldCase> masum = [
    // ── Alt dizi tuzakları: naif filtreleri düşüren meşru kelimeler ──
    GoldCase.clean(
        text: 'şikayetimi yazılı olarak ilettim',
        group: GoldGroup.masum,
        note: 'ş→s normalizasyonu sonrası müstehcen alt dizi içerir.'),
    GoldCase.clean(
        text: 'kargoyu bu sabah götürdü',
        group: GoldGroup.masum,
        note: 'Normalize edilince müstehcen alt dizi içerir.'),
    GoldCase.clean(
        text: 'malzeme listesini hazırladım',
        group: GoldGroup.masum,
        note: '"mal" ile başlar; tam eşleşme kuralı korumalı.'),
    GoldCase.clean(
        text: 'maliyet hesabını çıkardık',
        group: GoldGroup.masum,
        note: '"mal" ile başlar.'),
    GoldCase.clean(
        text: 'malum durumu biliyorsun',
        group: GoldGroup.masum,
        note: '"mal" ile başlar; ikinci şahıs var ama kelime meşru.'),
    GoldCase.clean(
        text: 'bu filmin adı neydi',
        group: GoldGroup.masum,
        note: '"adı" → "adi"; yönelim şartı korumalı.'),
    GoldCase.clean(
        text: 'itiraz etmek istiyorum',
        group: GoldGroup.masum,
        note: '"it" ile başlar; tam eşleşme kuralı korumalı.'),
    GoldCase.clean(
        text: 'ithalat rakamları açıklandı',
        group: GoldGroup.masum,
        note: '"it" ile başlar.'),
    GoldCase.clean(
        text: 'itibarını korumaya çalışıyor',
        group: GoldGroup.masum,
        note: '"it" ile başlar.'),
    GoldCase.clean(
        text: 'köpeğim hasta, veterinere götürüyorum',
        group: GoldGroup.masum,
        note: 'Hayvan adı + yönelim yok. İki tuzak bir arada.'),
    GoldCase.clean(
        text: 'eşek arısı soktu beni',
        group: GoldGroup.masum,
        note: 'Hayvan adı, yönelim yok.'),
    GoldCase.clean(
        text: 'hıyar salatası yaptım akşama',
        group: GoldGroup.masum,
        note: 'Sebze adı, yönelim yok.'),
    GoldCase.clean(
        text: 'domuz gribi aşısı çıkmış',
        group: GoldGroup.masum,
        note: 'Hayvan adı, tıbbi bağlam.'),
    GoldCase.clean(
        text: 'hayvan hakları derneğine üye oldum',
        group: GoldGroup.masum,
        note: 'Hayvan kelimesi, yönelim yok.'),
    GoldCase.clean(
        text: 'maymunlar adası belgeselini izledim',
        group: GoldGroup.masum,
        note: 'Hayvan adı, yönelim yok.'),
    GoldCase.clean(
        text: 'öküz arabası müzede sergileniyor',
        group: GoldGroup.masum,
        note: 'Hayvan adı, yönelim yok.'),
    GoldCase.clean(
        text: 'alçak basınç sistemi geliyor',
        group: GoldGroup.masum,
        note: 'Çokanlamlı "alçak", meteoroloji bağlamı.'),
    GoldCase.clean(
        text: 'mal beyanında bulundu',
        group: GoldGroup.masum,
        note: 'Çokanlamlı "mal", hukuki bağlam.'),
    GoldCase.clean(
        text: 'susadım, su alabilir miyim',
        group: GoldGroup.masum,
        note: '"sus" ile başlar; tam eşleşme kuralı korumalı.'),
    GoldCase.clean(
        text: 'sussuz kalan bölgeye tanker gönderildi',
        group: GoldGroup.masum,
        note: '"sus" ile başlar.'),
    GoldCase.clean(
        text: 'kahve içmeye çıkalım mı',
        group: GoldGroup.masum,
        note: 'Küfre bir harf uzaklıkta meşru kelime.'),
    GoldCase.clean(
        text: 'yarası iyileşmiş çok şükür',
        group: GoldGroup.masum,
        note: 'Küfre bir harf uzaklıkta meşru kelime.'),
    GoldCase.clean(
        text: 'sikke koleksiyonunu müzeye bağışladı',
        group: GoldGroup.masum,
        note: 'Müstehcen alt dizi ile başlayan meşru tarihî terim.'),
    GoldCase.clean(
        text: 'amcam yarın geliyor',
        group: GoldGroup.masum,
        note: 'Küfür kısaltmasına benzeyen akrabalık adı.'),
    GoldCase.clean(
        text: 'ambulans çağırdık hemen',
        group: GoldGroup.masum,
        note: 'Küfür kısaltmasıyla aynı harflerle başlar.'),
    GoldCase.clean(
        text: 'amacımız kaliteyi artırmak',
        group: GoldGroup.masum,
        note: 'Küfür kısaltmasıyla aynı harflerle başlar.'),
    GoldCase.clean(
        text: 'pişirdiğin yemek çok güzeldi',
        group: GoldGroup.masum,
        note: 'Normalize edilince riskli alt dizi içerir.'),
    GoldCase.clean(
        text: 'salatalık ve domates aldım',
        group: GoldGroup.masum,
        note: 'Hakarete benzeyen başlangıç.'),
    GoldCase.clean(
        text: 'geri dönüşüm kutusuna attım',
        group: GoldGroup.masum,
        note: '"geri" hakaret kökü değildir.'),
    GoldCase.clean(
        text: 'kafası karışmış biraz',
        group: GoldGroup.masum,
        note: '"kafasız" hakaretine benzer ama farklı kelime.'),

    // ── Yakın-kaçış: saldırgan kalıplara benzeyen masum cümleler ──
    GoldCase.clean(
        text: 'senin gibi düşünenler haklı bence',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "senin gibi" var ama ötekileştirme yok.'),
    GoldCase.clean(
        text: 'senin gibi çalışkan birini daha görmedim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "senin gibi" + övgü.'),
    GoldCase.clean(
        text: 'sana ne getireyim marketten',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "sana ne" alt dizisi, tamamen masum soru.'),
    GoldCase.clean(
        text: 'sana ne kadar borcum var',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "sana ne" alt dizisi.'),
    GoldCase.clean(
        text: 'gerçekten çok başarılısın, tebrikler',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: içten övgü, alaycı övgüden ayrılmalı.'),
    GoldCase.clean(
        text: 'helal olsun, hak ettin bu ödülü',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: içten takdir.'),
    GoldCase.clean(
        text: 'aferin, gurur duydum seninle',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: içten takdir.'),
    GoldCase.clean(
        text: 'görüşürüz, iyi akşamlar',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "görüşürüz" vedalaşma, tehdit değil.'),
    GoldCase.clean(
        text: 'yarın görüşürüz o zaman',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: vedalaşma.'),
    GoldCase.clean(
        text: 'bu konuyu geç, sonra bakarız',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "geç" kelimesi, düşmanlık yok.'),
    GoldCase.clean(
        text: 'işine bak diyorlar ama ben yardım etmek istiyorum',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: kalıp aktarılıyor, kullanılmıyor.'),
    GoldCase.clean(
        text: 'haddimi bilirim, karışmam',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: birinci şahıs, kendine yönelik.'),
    GoldCase.clean(
        text: 'ne anlarım ben bu işlerden',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: birinci şahıs alçakgönüllülük.'),
    GoldCase.clean(
        text: 'anlamıyorum, açıklar mısın',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: samimi soru.'),
    GoldCase.clean(
        text: 'yine mi bu hata, düzeltelim',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "yine mi" var ama kişiye yönelik değil.'),
    GoldCase.clean(
        text: 'kendime iş bulmam lazım',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: birinci şahıs.'),
    GoldCase.clean(
        text: 'hepimiz aynı takımdayız',
        group: GoldGroup.masum,
        note: 'YAKIN-KAÇIŞ: "hepimiz" birleştirici, "hepiniz aynısınız" değil.'),
    GoldCase.clean(
        text: 'sen karışmasan da olur, ben hallederim',
        group: GoldGroup.masum,
        note: 'SINIR DURUMU: nazik biçimde yükü üstlenme.'),

    // ── Sıradan, tamamen masum metin ──
    GoldCase.clean(
        text: 'bu kararı yanlış buluyorum ve nedenini anlamıyorum',
        group: GoldGroup.masum,
        note: 'Sert ama saygılı eleştiri — ürünün korumak istediği ifade.'),
    GoldCase.clean(
        text: 'katılmıyorum ama görüşüne saygı duyuyorum',
        group: GoldGroup.masum,
        note: 'Yapıcı muhalefet.'),
    GoldCase.clean(
        text: 'bu yaklaşımın zayıf yanları var bence',
        group: GoldGroup.masum,
        note: 'Yapıcı eleştiri.'),
    GoldCase.clean(
        text: 'gerekçeyi açıklarsan daha iyi anlayacağım',
        group: GoldGroup.masum,
        note: 'İş birliğine açık dil.'),
    GoldCase.clean(
        text: 'bu hata yıllardır tekrarlanıyor ve düzeltilmiyor',
        group: GoldGroup.masum,
        note: 'Öfkeli ama saldırgan olmayan eleştiri — korunmalı.'),
    GoldCase.clean(
        text: 'kararın arkasındaki mantığı göremiyorum',
        group: GoldGroup.masum,
        note: 'Sert eleştiri, hakaret yok.'),
    GoldCase.clean(
        text: 'bu tamamen kabul edilemez bir durum',
        group: GoldGroup.masum,
        note: 'Güçlü itiraz, kişiye saldırı yok.'),
    GoldCase.clean(
        text: 'yarın toplantı saat kaçta başlıyor',
        group: GoldGroup.masum,
        note: 'Nötr soru.'),
    GoldCase.clean(
        text: 'teşekkür ederim, çok yardımcı oldun',
        group: GoldGroup.masum,
        note: 'Olumlu ifade.'),
    GoldCase.clean(
        text: 'projeyi zamanında teslim ettik',
        group: GoldGroup.masum,
        note: 'Nötr bilgi.'),
    GoldCase.clean(
        text: 'hava bugün çok güzel',
        group: GoldGroup.masum,
        note: 'Nötr.'),
    GoldCase.clean(
        text: 'raporu inceledim, birkaç önerim olacak',
        group: GoldGroup.masum,
        note: 'Nötr iş dili.'),
    GoldCase.clean(
        text: 'maalesef bu sefer olmadı, tekrar deneyelim',
        group: GoldGroup.masum,
        note: 'Olumsuz haber, saldırı yok.'),
    GoldCase.clean(
        text: 'sınav sonuçları açıklandı mı',
        group: GoldGroup.masum,
        note: 'Nötr soru.'),
    GoldCase.clean(
        text: 'bu konuda kaynak önerebilir misin',
        group: GoldGroup.masum,
        note: 'İş birliğine açık soru.'),
    GoldCase.clean(
        text: 'çok yoruldum bugün, erken yatacağım',
        group: GoldGroup.masum,
        note: 'Kişisel paylaşım.'),
    GoldCase.clean(
        text: 'fiyatlar yine arttı, zor durumdayız',
        group: GoldGroup.masum,
        note: 'Şikâyet, saldırı değil.'),
    GoldCase.clean(
        text: 'sistem yine çöktü, çok sinirliyim',
        group: GoldGroup.masum,
        note: 'Öfke ifadesi, kişiye yönelik değil.'),
    GoldCase.clean(
        text: 'bu ürün beklentimi karşılamadı',
        group: GoldGroup.masum,
        note: 'Olumsuz değerlendirme.'),
    GoldCase.clean(
        text: 'kargo bir haftadır gelmedi, iade istiyorum',
        group: GoldGroup.masum,
        note: 'Müşteri şikâyeti.'),
    GoldCase.clean(
        text: 'yorumun için teşekkürler, düşüneceğim',
        group: GoldGroup.masum,
        note: 'Nazik yanıt.'),
    GoldCase.clean(
        text: 'burada bir yanlış anlaşılma var sanırım',
        group: GoldGroup.masum,
        note: 'Yatıştırıcı dil.'),
    GoldCase.clean(
        text: 'daha önce böyle bir şey denemedim',
        group: GoldGroup.masum,
        note: 'Nötr.'),
    GoldCase.clean(
        text: 'bence iki tarafın da haklı olduğu noktalar var',
        group: GoldGroup.masum,
        note: 'Uzlaştırıcı dil.'),
    GoldCase.clean(
        text: 'kod incelemesinde birkaç sorun buldum, paylaşıyorum',
        group: GoldGroup.masum,
        note: 'Yapıcı teknik geri bildirim.'),
    GoldCase.clean(
        text: 'bu çözüm işe yaramaz çünkü bellek sızıntısı var',
        group: GoldGroup.masum,
        note: 'Teknik itiraz; "işe yaramaz" fikre yönelik, kişiye değil.'),
    GoldCase.clean(
        text: 'sabah antrenmana gidiyorum',
        group: GoldGroup.masum,
        note: 'Nötr.'),
    GoldCase.clean(
        text: 'kitabı bitirdim, tavsiye ederim',
        group: GoldGroup.masum,
        note: 'Olumlu.'),
    GoldCase.clean(
        text: 'toplantı notlarını paylaşabilir misin',
        group: GoldGroup.masum,
        note: 'Nötr istek.'),
    GoldCase.clean(
        text: 'bugün kendimi pek iyi hissetmiyorum',
        group: GoldGroup.masum,
        note: 'Öz-ifade.'),
    GoldCase.clean(
        text: 'tartışmayı burada bitirelim, kimseye faydası yok',
        group: GoldGroup.masum,
        note: 'Yatıştırıcı kapanış.'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. BAĞLAM — mağduru cezalandırmama testi
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<GoldCase> baglam = [
    // ── Olumsuzlama ──
    GoldCase.clean(
        text: 'sen hiç aptal değilsin',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama iltifata çevirir.'),
    GoldCase.clean(
        text: 'aptal değilim ben',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama + birinci şahıs.'),
    GoldCase.clean(
        text: 'salak değil o adam, gayet zeki',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama üçüncü şahıs için.'),
    GoldCase.clean(
        text: 'kimse aptal değil burada',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama.'),
    GoldCase.clean(
        text: 'seni asla aptal olarak görmedim',
        group: GoldGroup.baglam,
        note: 'Olumsuzlama, ikinci şahıs var ama saldırı yok.'),

    // ── Alıntı / aktarım — MAĞDUR CEZALANDIRILMAMALI ──
    GoldCase.clean(
        text: "bana 'aptal' dedi, çok üzüldüm",
        group: GoldGroup.baglam,
        note: 'Tacize uğrayan kişi durumu anlatıyor.'),
    GoldCase.clean(
        text: "'şerefsiz' diye bağırdı bana",
        group: GoldGroup.baglam,
        note: 'Şikâyet; ağır hakaret aktarılıyor.'),
    GoldCase.clean(
        text: 'bana salak dedi ve engelledi',
        group: GoldGroup.baglam,
        note: 'Tırnaksız aktarım — aktarma fiili ile yakalanmalı.'),
    GoldCase.clean(
        text: 'yorumda bana "gerizekalı" yazmış',
        group: GoldGroup.baglam,
        note: 'Aktarım, yazılı ihbar.'),
    GoldCase.clean(
        text: 'beni salak yerine koydu',
        group: GoldGroup.baglam,
        note: 'Birinci şahıs mağduriyet anlatımı.'),
    GoldCase.clean(
        text: 'bana hakaret etti, ne yapmalıyım',
        group: GoldGroup.baglam,
        note: 'Yardım isteyen mağdur.'),
    GoldCase.clean(
        text: 'moderatöre "aptal" dediğini bildirdim',
        group: GoldGroup.baglam,
        note: 'İhbar süreci anlatımı.'),

    // ── Öz-ifade ──
    GoldCase.clean(
        text: 'kendimi aptal gibi hissettim',
        group: GoldGroup.baglam,
        note: 'Öz-ifade; müdahale duygusal zarar verir.'),
    GoldCase.clean(
        text: 'aptalca bir hata yaptım kusura bakma',
        group: GoldGroup.baglam,
        note: 'Öz-eleştiri + özür.'),
    GoldCase.clean(
        text: 'çok salakça davrandım orada',
        group: GoldGroup.baglam,
        note: 'Öz-eleştiri.'),
    GoldCase.clean(
        text: 'kendimi rezil ettim',
        group: GoldGroup.baglam,
        note: 'Öz-eleştiri.'),
    GoldCase.clean(
        text: 'ben cahilim bu konuda, öğrenmek istiyorum',
        group: GoldGroup.baglam,
        note: 'Öz-ifade + öğrenme talebi.'),

    // ── Bağlamın kurtarMADIĞI durumlar (müdahale beklenir) ──
    GoldCase.flag(
        text: 'sen aptal değil misin zaten',
        group: GoldGroup.baglam,
        category: ToxicityCategory.hakaret,
        note: 'BİLİNEN SINIR: retorik soru olumsuzlama gibi görünür ama '
            'hakarettir. Olumsuzlama kuralı bunu yanlışlıkla kurtarır.'),
    GoldCase.flag(
        text: 'aptal demiyorum ama düşünsene',
        group: GoldGroup.baglam,
        category: ToxicityCategory.hakaret,
        note: 'BİLİNEN SINIR: örtülü hakaret, inkâr kalıbıyla.'),
    GoldCase.flag(
        text: 'kimseye salak demem ama sen bir istisnasın',
        group: GoldGroup.baglam,
        category: ToxicityCategory.hakaret,
        note: 'BİLİNEN SINIR: olumsuzlama sonrası istisna ile hakaret.'),
  ];
}
