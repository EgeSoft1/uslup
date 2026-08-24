// =============================================================================
// Nefret Söylemi Katmanı — kimlik hedefli düşmanlık
// Dosya: packages/civility_core/lib/src/detect/hate_patterns.dart
//
// ── NEDEN AYRI BİR KATMAN ─────────────────────────────────────────────────
// `ToxicityCategory.nefret` kategorisi tanımlıydı ama sözlükte **sıfır girdi**
// vardı. Yani şartnamenin doğrudan bir maddesi hiç karşılanmıyordu.
//
// ── NEDEN KELİME LİSTESİ DEĞİL ────────────────────────────────────────────
// Nefret söylemini "yasaklı kelime" olarak modellemek iki yönden birden
// çuvallar:
//
//   1. KAÇIRIR. Kimlik hedefli düşmanlığın çoğu küfür içermez:
//      "Bütün Suriyeliler hırsızdır" cümlesinde tek bir yasaklı kelime yoktur.
//
//   2. YANLIŞ HEDEF VURUR — ve bu birincisinden çok daha kötüdür.
//      Kimlik adlarını ("Kürt", "Ermeni", "Alevi", "eşcinsel") toksik terim
//      listesine koyan bir sistem, kendi kimliğinden söz eden insanları
//      susturur. "Ben Kürtüm" cümlesini işaretleyen bir filtre, korumaya
//      çalıştığı grubu cezalandırır.
//
// ── TASARIM: KİMLİK = YUVA, SALDIRI = KURULUŞ ─────────────────────────────
// Bu yüzden kimlik adları burada **hiçbir zaman tek başına tetikleyici
// değildir**. Yalnızca düşmanca bir kuruluşun içindeki YUVAYI (slot)
// doldururlar:
//
//      [kimlik]  +  [düşmanca yüklem]  →  nefret söylemi
//      [kimlik]  yalnız başına         →  hiçbir şey
//
//   "Bütün Suriyeliler hırsızdır"     → yakalanır  (toplu suçlama)
//   "Suriyeli komşumuz çok yardımsever" → yakalanMAZ (aynı kimlik terimi)
//   "Ben Kürtüm"                      → yakalanMAZ
//   "Kürtler defolsun"                → yakalanır  (dışlama)
//
// Bu, mevcut "küfürsüz düşmanlık" katmanının (`implicit_patterns.dart`) aynı
// mimari fikrinin kimlik eksenine taşınmış hâlidir: saldırganlık kelimelerde
// değil, kelimelerin dizilişinde aranır.
//
// ── AMBİGÜİTE NOTU ────────────────────────────────────────────────────────
// Bazı kimlik adları aksan katlaması sonrası meşru kelimelerle çakışır:
//
//   "Kürt"  → "kurt"  ← "kurt" (hayvan), "kurtarmak", "kurtuluş"
//   "Laz"   → "laz"   ← "lazım"
//   "Roman" → "roman" ← "roman" (kitap)
//
// Bu köklerde tekil biçim KULLANILMAZ; yalnızca grup göndergesi taşıyan
// çoğul biçim alınır. Türkçe ünlü uyumu bunu aksan katlamasından SONRA da
// ayırt eder: "kurtlar" (hayvan) ≠ "kurtler" (Kürtler). Bedeli bir miktar
// duyarlılıktır ve bu bilinçli bir seçimdir — yanlış pozitif, yanlış
// negatiften pahalıdır.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'implicit_patterns.dart';

/// Korunan kimlik gruplarının söz varlığı.
///
/// ⚠ Bu liste bir "toksik terim listesi" DEĞİLDİR ve asla öyle
/// kullanılmamalıdır. Buradaki hiçbir kelime tek başına bir bulgu üretmez;
/// yalnızca düşmanca kuruluşların içinde yuva doldurur.
abstract final class IdentityTerms {
  // ── İP-17 · SÖZ VARLIĞI GENİŞLETMESİ (24 Ağustos 2026) ────────────────────
  // İlk sürümde 35 terim vardı; kapsam Türkiye'de en görünür beş-altı grupla
  // sınırlıydı ve rapor bunu açık bir sınır olarak beyan etti. Genişletme
  // İKİ KURALLA yapılmıştır:
  //
  //   K1 — Kapsam KORUNAN NİTELİK ekseninde belirlenir: etnik/ulusal köken,
  //        inanç, cinsel yönelim ve cinsiyet kimliği, göç durumu, engellilik,
  //        yaş, sosyoekonomik durum. **Siyasi görüş kasıtlı olarak
  //        dışarıdadır** — siyasi aidiyet, uluslararası nefret söylemi
  //        tanımlarının hiçbirinde korunan nitelik değildir ve listeye
  //        girmesi, siyasi eleştiriyi nefret söylemi saymak olurdu. Bu ürün
  //        bir sansür aracı değildir; sınır burada çizilir.
  //
  //   K2 — Aksan katlaması sonrası meşru bir kelimeyle çakışan her kökte
  //        TEKİL BİÇİM KULLANILMAZ; yalnızca grup göndergesi taşıyan çoğul
  //        biçim alınır. Her çakışma tek tek denetlenmiş ve kararı
  //        `test/hate_layer_test.dart` §3'te bir regresyon testiyle
  //        kilitlenmiştir.
  //
  // ⛔ DENETLENİP ALINMAYANLAR — hepsi meşru kullanımda düşmanca yüklem
  //    alabildiği için dışarıda bırakıldı:
  //      "kazaklar"  → giysi çoğulu ("kazaklar bozuk")
  //      "siyahlar"  → renk çoğulu  ("siyahlar kirli")
  //      "sii"       → "şiir" düşerdi        ("şiirler kirli")
  //      "sih"       → "sihir" düşerdi
  //      "kor"       → "korku", "koru", "korkak"
  //      "yasli"     → "yaslı" (matem)
  //      "rus"       → "rustik"

  /// Etnik / ulusal köken.
  static const List<String> ethnic = [
    // Çakışan kökler: yalnızca çoğul/grup biçimi (ünlü uyumu ayırt eder).
    r'kurtler\w*', // Kürtler — "kurtlar" (hayvan) bu kalıba düşmez
    r'lazlar\w*', // Lazlar — "lazım" düşmez
    r'romanlar\w*', // Romanlar — "roman" (kitap) düşmez
    r'turkler\w*', // Türkler — "türkiye", "türkçe", "türkü" düşmez
    r'ruslar\w*', // Ruslar — "rustik" düşmez
    r'tatarlar\w*', // Tatarlar — tekil biçim gereksiz risk
    // Çakışmayan kökler: tekil biçim de güvenli.
    r'ermeni\w*',
    r'rumlar\w*',
    r'yahudi\w*',
    r'arap\w*', // "araba" düşmez: b ≠ p
    r'suriyeli\w*',
    r'afgan\w*',
    r'cerkes\w*',
    r'gurcu\w*',
    r'arnavut\w*',
    r'bosnak\w*',
    r'pomak\w*',
    r'suryani\w*',
    r'zaza\w*',
    // İP-17 — Türkiye'de görünür diğer etnik ve ulusal kökenler.
    r'azeri\w*',
    r'turkmen\w*',
    r'uygur\w*', // "uygun" düşmez: r ≠ n
    r'kirgiz\w*',
    r'ozbek\w*',
    r'cecen\w*',
    r'abhaz\w*',
    r'gagavuz\w*',
    r'keldani\w*',
    r'levanten\w*',
    r'yunan\w*',
    r'bulgar\w*', // "bulgur" düşmez: a ≠ u
    r'ukraynali\w*',
    r'iranli\w*',
    r'irakli\w*',
    r'pakistanli\w*',
    r'hintli\w*',
    r'cinli\w*',
    r'afrikali\w*',
    r'siyahi\w*', // "siyahlar" ALINMADI — renk çoğulu
    r'dogulu\w*',
    r'karadenizli\w*',
  ];

  /// İnanç / mezhep.
  static const List<String> religious = [
    r'alevi\w*',
    r'sunni\w*',
    r'hri?stiyan\w*',
    r'musevi\w*',
    r'musluman\w*',
    r'ateist\w*',
    r'ezidi\w*',
    r'kizilbas\w*',
    // İP-17
    r'yezidi\w*',
    r'siiler\w*', // tekil "sii" ALINMADI — "şiir" düşerdi
    r'sihler\w*', // tekil "sih" ALINMADI — "sihir" düşerdi
    r'caferi\w*',
    r'bektasi\w*',
    r'nusayri\w*',
    r'katolik\w*',
    r'ortodoks\w*',
    r'protestan\w*',
    r'budist\w*',
    r'hindu\w*', // "hindi" düşmez: u ≠ i
    r'yehova\w*',
    r'deist\w*',
    r'agnostik\w*',
    r'basortulu\w*', // belgelenmiş ayrımcılık hedefi
  ];

  /// Cinsel yönelim / cinsiyet kimliği.
  static const List<String> orientation = [
    r'escinsel\w*',
    r'geyler\w*', // "geyik" düşmez
    r'lezbiyen\w*',
    r'biseksuel\w*',
    r'translar\w*', // "transfer", "transit" düşmez
    // İP-17
    r'lgbt\w*', // lgbti / lgbtq / lgbtiq biçimlerini de kapsar
    r'kuir\w*',
    r'queer\w*',
    r'nonbiner\w*',
    r'interseks\w*',
    r'aseksuel\w*',
    r'panseksuel\w*',
    r'travesti\w*',
    r'trans (?:kadin|erkek|birey)\w*',
  ];

  /// Göç durumu, engellilik, yaş ve sosyoekonomik durum.
  static const List<String> status = [
    r'multeci\w*',
    r'gocmen\w*',
    r'siginmaci\w*',
    r'engelli\w*', // "görme/işitme/zihinsel engelli" bu kökle kapsanır
    r'kadinlar\w*',
    r'erkekler\w*',
    // İP-17
    r'otistik\w*',
    r'otizmli\w*',
    r'down sendromlu\w*',
    r'sagir\w*', // "sığır" → "sigir"; a ≠ i, çakışmaz
    r'korler\w*', // tekil "kor" ALINMADI — "korku", "koru", "korkak"
    r'yaslilar\w*', // tekil "yasli" ALINMADI — "yaslı" (matem)
    r'yetimler\w*',
    r'oksuzler\w*',
    r'evsizler\w*',
    r'yoksullar\w*',
    r'fakirler\w*',
    r'issizler\w*',
    r'koyluler\w*',
    r'hiv pozitif\w*',
  ];

  static const List<String> all = [
    ...ethnic,
    ...religious,
    ...orientation,
    ...status,
  ];

  /// Örüntülerin içine gömülecek yuva: `(?:kimlik1|kimlik2|…)`.
  static final String slot = '(?:${all.join('|')})';

  /// Metinde geçen kimlik terimlerini bulmak için derlenmiş biçim.
  /// Gönderge çözümlemesinde ÖNCÜL (antecedent) araması bunu kullanır.
  static final RegExp mention = RegExp('\\b$slot', caseSensitive: false);

  // ── GÖNDERGE (ANAFORA) YUVASI ────────────────────────────────────────────
  // Yalnızca ÇOĞUL işaret zamirleri alınır. "bu", "o", "şu" tekil biçimleri
  // kasıtlı olarak dışarıdadır: tekil gönderge nesneleri de işaret eder
  // ("bu karar", "o film") ve yanlış pozitif kaynağıdır.
  //
  // Çoğul biçim de tek başına yeterli değildir; bu yuvayı taşıyan her örüntü
  // `requiresIdentityAntecedent: true` ile işaretlidir ve öncül olmadan
  // hiçbir bulgu üretmez.
  static const String anaphora =
      r'(?:bunlar|onlar|sunlar|bunlari|onlari|sunlari|'
      r'bunlarin|onlarin|sunlarin|bunlara|onlara|sunlara|'
      r'bunlardan|onlardan|sunlardan)';
}

/// Nefret söylemi kuruluşları.
abstract final class HatePatterns {
  /// Bu dosyadaki her örüntünün kimliği bu önekle başlar.
  ///
  /// Yalnızca bir adlandırma kuralı DEĞİLDİR — çalışma zamanı davranışı buna
  /// bağlıdır. `ImplicitDetector`, kimlik terimi geçmeyen metinlerde bu
  /// önekli örüntülerin tamamını atlar (kimlik kapısı, İP-23). Önek
  /// tutmayan bir nefret örüntüsü, kapının dışında kalır ve gereksiz yere
  /// her cümlede çalışır.
  ///
  /// Değişmez `test/hate_layer_test.dart` içinde denetlenir.
  static const String idPrefix = 'nefret.';

  static RegExp _re(String source) => RegExp(source, caseSensitive: false);

  /// Kimlik yuvası ile yüklem arasına en fazla [n] kelime girebilir.
  /// "Suriyeliler hırsız" ile "Suriyeliler zaten hep hırsız" aynı kuruluştur.
  static String _gap(int n) => '(?:\\s+\\w+){0,$n}\\s+';

  /// Yüklemin gerçekten **yüklem konumunda** olmasını şart koşar.
  ///
  /// Katmanın en kritik kesinlik mekanizması budur. İlk sürümde ek isteğe
  /// bağlıydı ve arkasından boşluk gelmesi yetiyordu; sonuç:
  ///
  ///   "Suriyeli gönüllüler hayvan haklarıyla ilgileniyor" → YANLIŞ POZİTİF
  ///
  /// Çünkü "hayvan" kelimesi cümlede nesne konumundaydı, yüklem değil.
  /// Artık iki bitişten biri zorunlu:
  ///   • bildirme eki  → "hayvandır", "hastalıklısınız"
  ///   • metin sonu    → "Eşcinseller hastalıklı"
  ///
  /// `-lar/-ler` KASITLI olarak dışarıda: çoğul eki yüklem işareti değildir.
  /// İçeride olsaydı "Suriyeliler hayvanları sever" yine yakalanırdı.
  ///
  /// Bedeli: "Suriyeliler hırsız ve gitmeliler" gibi bağlaçla süren
  /// cümlelerde ilk yüklem kaçar. Bilinçli bir seçim — yanlış pozitif,
  /// yanlış negatiften pahalıdır (`00_URUN_TANIMI.md` §6.4).
  ///
  /// ── İP-19 DÜZELTMESİ (24 Ağustos 2026) ──────────────────────────────────
  /// İlk listede YUVARLAK ÜNLÜLÜ çekimler eksikti. Türkçe'de bildirme eki
  /// ünlü uyumuna girer ve son hecenin ünlüsü yuvarlaksa ek de yuvarlaklaşır:
  ///
  ///   bozuk + -TUR   → "bozuktur"     ← eski listede YOKTU
  ///   bozuk + -SUN   → "bozuksun"     ← eski listede YOKTU
  ///
  /// Ölçümde bunun bedeli somuttu: "Katolikler bozuktur" temiz dönüyordu,
  /// "Katolikler bozuk" ise yakalanıyordu. Yani ek eklendiğinde saldırı
  /// GÖRÜNMEZ oluyordu — ekin varlığı bir kaçış yoluna dönüşmüştü.
  static const String _yuklem =
      r'(?:(?:dir|dirlar|tir|tirlar|dur|durlar|tur|turlar|'
      r'sin|siniz|sun|sunuz|siz)\b|'
      '$_kuyruk)';

  /// Cümle sonu belirteçleri — yüklemden SONRA gelebilen ve cümleyi
  /// bitirmeyen zarflar.
  ///
  /// ── İP-21 · NEDEN EKLENDİ ────────────────────────────────────────────────
  /// `_yuklem`in ikinci kolu "metin sonu" (`\s*$`) idi. Bu, yüklemin
  /// ardından tek bir zarf gelse bile kalıbı kırıyordu:
  ///
  ///   "Yunanlılara güvenilmez"                → yakalanıyordu
  ///   "Yunanlılara güvenilmez hiçbir zaman"   → temiz (0.00)   ✗
  ///
  /// Yani cümleye pekiştireç eklemek bir KAÇIŞ YOLUYDU — üstelik pekiştireç
  /// saldırıyı yumuşatmıyor, sertleştiriyor.
  ///
  /// Liste kapalı ve KASITLI olarak dardır: yalnızca yüklem sonrası
  /// konumda durabilen, kendisi bir ad öbeği kurmayan zarflar. Bir ad
  /// gelirse ("hayvan hakları") kalıp yine düşmez — kesinlik mekanizması
  /// olduğu gibi korunur.
  static const String _kuyruk = r'(?:\s+(?:artik|zaten|hep|hepsi|'
      r'hicbir zaman|asla|kesinlikle|tabii|elbette|bence|valla|vallahi|'
      r'her zaman|maalesef|ne yazik ki|iste|resmen|aynen))*\s*$';

  // ── Düşmanca yüklem sözvarlıkları ────────────────────────────────────────

  /// İnsanlıktan çıkarma terimleri. Soykırım araştırmalarında en erken ve en
  /// güvenilir uyarı işaretlerinden biridir; bu yüzden şiddeti yüksektir.
  static const String _dehuman =
      r'(?:hayvan|hasarat|bocek|virus|mikrop|surungen|asalak|parazit|'
      r'yamyam|vahsi|barbar)';

  /// Toplu suçlama yüklemleri.
  static const String _suclama =
      r'(?:hirsiz|katil|terorist|yalanci|sahtekar|hain|dolandirici|'
      r'sapik|caniyi?|pis|bela|tehlikeli?|isgalci|beles(?:ci)?|'
      // İP-19: ölçümde kaçan güvenilmezlik atfı ("Ermeniler güvenilmez")
      // ve sıfat çekimli biçim ("tehlikeli", eski liste yalnızca "tehlike").
      r'guvenilmez|guvenilemez)';

  /// Değersizleştirme yüklemleri.
  /// YÜK SÖYLEMİ — insanlıktan çıkarmanın ekonomik kılığı.
  ///
  /// İP-21: "engelliler topluma yük" cümlesi hiçbir sözvarlığına düşmüyordu.
  /// Bu kuruluş, bir grubun varlığını bir MALİYET olarak tanımlar ve
  /// soykırım araştırmalarında insanlıktan çıkarmanın en yaygın ikinci
  /// biçimidir. Tek başına "yük" ALINMAZ ("yük treni"); ad tamlaması şart.
  static const String _yuk =
      r'(?:topluma yuk|ulkeye yuk|devlete yuk|millete yuk|bize yuk|'
      r'sirtimizda yuk|ekonomiye yuk|yuk olmus|yuk oluyor)';

  static const String _degersiz =
      r'(?:asagilik|degersiz|bozuk|dusuk|kirli|igrenc|'
      r'hastalikli|sapkin|anormal|'
      // İP-19: patolojileştirme, "hastalıklı" dışındaki en yaygın biçimiyle
      // ("translar HASTA İNSANLAR"). Tek başına "hasta" ALINMADI — "Suriyeli
      // komşum hasta" masum bir cümledir; ad tamlaması şart koşuluyor.
      r'hasta insan\w*|hasta kisi\w*|ruh hastasi)';

  /// DÜŞMANCA SÖZCÜK KAPISI — gecikme optimizasyonu (İP-23).
  ///
  /// Kimlik kapısı, kimlik terimi geçmeyen metinlerde nefret örüntülerini
  /// atlar. Ama gerçek hayatta insanlar kimliklerden çok daha sık NÖTR
  /// bağlamda söz eder: "Suriyeli komşumuz çok yardımsever", "Alevi kültürü
  /// üzerine tez yazıyorum". Bu cümlelerde kimlik kapısı açılır ve on beş
  /// örüntü boşuna çalışır — ölçümde en pahalı ikinci senaryo buydu.
  ///
  /// Bu kapı ikinci koşulu ekler: metinde nefret örüntülerinden HERHANGİ
  /// BİRİNİ tetikleyebilecek bir sözcük var mı?
  ///
  /// ── DOĞRULUK ŞARTI ──────────────────────────────────────────────────────
  /// Kapı, örüntülerin gerektirdiği sözvarlıklarının BİRLEŞİMİDİR ve daha
  /// dar olamaz. Her nefret örüntüsünün zorunlu bir sabit parçası vardır;
  /// aşağıdaki birleşim onların hepsini kapsar:
  ///
  ///   insanlıktan çıkarma  → _dehuman        toplu suçlama   → _suclama
  ///   kimlik aşağılama     → _degersiz       yük söylemi     → _yuk
  ///   varlık reddi         → fiil listesi    dışlama         → fiil listesi
  ///   dolaylı dışlama      → yaşanmaz…       "ne beklenir"   → ne beklen
  ///   kimlik yaftalama     → sen / siz       niceleyici      → bütün / hepsi…
  ///
  /// Kapının daraltılması SESSİZ kaçak üretir. Bu yüzden `test/
  /// detector_gate_test.dart`, kapılı ve kapısız dedektörü 581 etiketli
  /// örneğin tamamında karşılaştırır ve tek bir bulgu farkı olsa test kırılır.
  static final RegExp hostileGate = RegExp(
    '(?:'
    '$_dehuman|$_suclama|$_degersiz|$_yuk'
    r'|yok edil|temizlen|yasamamali|olmamali|kokunu kurut|soyunu kurut'
    r'|gebertil|asilmali|yakilmali'
    r'|defol|gitsin|gitmeli|cikmali|gonder|kovul|kovun|sinir disi'
    r'|ulkesine don|ulkelerine don|istemiyoruz|istemiyorum|burada istenm'
    r'|yasanmaz|oturulmaz|durulmaz|calisilmaz|yasanmiyor|oturulmuyor'
    r'|ne beklen'
    r'|\b(?:sen|siz)\b'
    r'|\b(?:butun|tum|hepsi|hepiniz|her|tamami|tumu)\b'
    ')',
    caseSensitive: false,
  );

  static final List<ImplicitPattern> all = [
    // ═══ İNSANLIKTAN ÇIKARMA ═════════════════════════════════════════════════
    // "Suriyeliler hayvandır" · "Bunlar hasarat"
    // Yakın-kaçış: "Suriyeli gönüllüler hayvan haklarıyla ilgileniyor"
    ImplicitPattern(
      id: 'nefret.insanliktan_cikarma',
      pattern: _re('\\b${IdentityTerms.slot}${_gap(3)}$_dehuman$_yuklem'),
      family: ImplicitFamily.insanliktanCikarma,
      category: ToxicityCategory.nefret,
      severity: 0.92,
    ),

    // ═══ VARLIK REDDİ / ŞİDDETE ÇAĞRI ════════════════════════════════════════
    // En ağır biçim. Yasal olarak da suç teşkil eder (TCK 216).
    // Bu kategoride "öneri" değil, doğrudan üst düzey uyarı üretilir.
    ImplicitPattern(
      id: 'nefret.varlik_reddi',
      pattern: _re('\\b${IdentityTerms.slot}${_gap(3)}'
          r'(?:yok edil|temizlen|yasamamali|olmamali|kokunu kurut|'
          r'soyunu kurut|gebertil|asilmali|yakilmali)\w*'),
      family: ImplicitFamily.varlikReddi,
      category: ToxicityCategory.nefret,
      severity: 0.98,
    ),

    // ═══ DIŞLAMA / SÜRGÜN ════════════════════════════════════════════════════
    // "Suriyeliler defolsun" · "Kürtler ülkelerine gitsin"
    // Yakın-kaçış: "Suriyeli komşumuz memleketine gitti" (bildirme kipi,
    // istek kipi değil — kalıba düşmez).
    ImplicitPattern(
      id: 'nefret.dislama',
      pattern: _re('\\b${IdentityTerms.slot}${_gap(3)}'
          r'(?:defol\w*|gitsin\w*|gonderil\w*|kovul\w*|sinir disi|'
          r'ulkesine don\w*|ulkelerine don\w*|istemiyoruz|istemiyorum|'
          // İP-19: gereklilik kipi ("Kürtler bu ülkeden GİTMELİ") ve
          // birleşik fiil ("defolup gitsin") ölçümde kaçıyordu. Gereklilik
          // kipi bir ÇAĞRIDIR; bildirme kipinden ("gitti") ayrıdır.
          r'gitmeli\w*|cikmali\w*|kovulmali\w*|gonderilmeli\w*|'
          r'burada istenm\w*)'),
      family: ImplicitFamily.dislama,
      category: ToxicityCategory.nefret,
      severity: 0.88,
      neutralAlternative: 'göç politikası hakkında farklı düşünüyorum',
    ),
    ImplicitPattern(
      // Ters diziliş: "Defolsun bu Suriyeliler"
      id: 'nefret.dislama_ters',
      pattern: _re(r'\b(?:defolsun|gitsinler|gonderin|kovun)'
          '${_gap(3)}${IdentityTerms.slot}'),
      family: ImplicitFamily.dislama,
      category: ToxicityCategory.nefret,
      severity: 0.88,
    ),

    // ═══ TOPLU SUÇLAMA ═══════════════════════════════════════════════════════
    // "Bütün Suriyeliler hırsızdır" · "Bu Romanlar hep dolandırıcı"
    // Yakın-kaçış: "Bütün öğrenciler sınava girecek" (kimlik yuvası yok),
    //              "Bütün Kürt arkadaşlarım misafirperver" (yüklem düşman değil)
    ImplicitPattern(
      id: 'nefret.toplu_suclama',
      pattern: _re('\\b${IdentityTerms.slot}${_gap(3)}$_suclama$_yuklem'),
      family: ImplicitFamily.topluSuclama,
      category: ToxicityCategory.nefret,
      severity: 0.85,
      neutralAlternative: 'bu konuda kaygılarım var',
    ),
    ImplicitPattern(
      // Niceleyici öne çıkarılmış: "hepsi hırsız bu Suriyelilerin"
      id: 'nefret.toplu_suclama_niceleyici',
      pattern: _re(r'\b(?:butun|tum|hepsi|hepiniz|her)\b'
          '${_gap(2)}${IdentityTerms.slot}'),
      family: ImplicitFamily.topluSuclama,
      category: ToxicityCategory.nefret,
      // Tek başına niceleyici + kimlik saldırgan DEĞİLDİR ("bütün Kürt
      // arkadaşlarım"). Şiddet kasıtlı olarak eşiğin altındadır; yalnızca
      // başka bir bulguyla birleştiğinde toplam skoru yukarı iter.
      severity: 0.18,
    ),

    ImplicitPattern(
      // "bu Suriyeliler yüzünden mahalle battı, HEPSİ HIRSIZ"
      //
      // İP-19 ölçümünde kaçtı. Sebep: doğrudan kuruluş kimlik yuvası ile
      // yüklem arasına en fazla üç kelime alır (`_gap(3)`); iki cümlecikli
      // kurulumda araya dört kelime giriyordu. Boşluğu büyütmek kesinliği
      // düşürürdü — bunun yerine niceleyici (`hepsi`, `tümü`) bir çapa
      // olarak kullanılır ve kimlik önceli GÖNDERGE KAPISIYLA aranır.
      //
      // Böylece "hepsi hırsız" tek başına hiçbir şey üretmez; yalnızca
      // metinde daha önce gerçek bir kimlik terimi geçtiyse bulgu olur.
      id: 'nefret.niceleyici_suclama_anafora',
      pattern: _re(r'\b(?:hepsi|tumu|hepsi de|tamami)\b'
          '${_gap(2)}$_suclama$_yuklem'),
      family: ImplicitFamily.topluSuclama,
      category: ToxicityCategory.nefret,
      severity: 0.82,
      requiresIdentityAntecedent: true,
      neutralAlternative: 'bu konuda kaygılarım var',
    ),

    ImplicitPattern(
      // "engelliler topluma yük" · "mülteciler ekonomiye yük olmuş"
      id: 'nefret.yuk_soylemi',
      pattern: _re('\\b${IdentityTerms.slot}${_gap(3)}$_yuk$_yuklem'),
      family: ImplicitFamily.insanliktanCikarma,
      category: ToxicityCategory.nefret,
      severity: 0.86,
      neutralAlternative: 'sosyal politika maliyetleri konusunda kaygılıyım',
    ),
    ImplicitPattern(
      // "bu Romanlarla aynı mahallede yaşanmaz" — dolaylı dışlama.
      // Doğrudan dışlama ("defolsun") kadar açık değildir; hedefi ortamdan
      // çıkarmak yerine ortamı yaşanmaz ilan eder. Sonuç aynıdır.
      //
      // Yakın-kaçış: "bu gürültüyle burada çalışılmaz" — kimlik yuvası yok.
      id: 'nefret.dolayli_dislama',
      pattern: _re('\\b${IdentityTerms.slot}${_gap(4)}'
          r'(?:yasanmaz|oturulmaz|durulmaz|calisilmaz|yasanmiyor|'
          r'oturulmuyor)\b'),
      family: ImplicitFamily.dislama,
      category: ToxicityCategory.nefret,
      severity: 0.80,
      neutralAlternative: 'komşuluk ilişkilerinde sorun yaşıyorum',
    ),

    // ═══ KİMLİK AŞAĞILAMA ════════════════════════════════════════════════════
    // "Aleviler aşağılıktır" · "Eşcinseller hastalıklı"
    ImplicitPattern(
      id: 'nefret.kimlik_asagilama',
      pattern: _re('\\b${IdentityTerms.slot}${_gap(3)}$_degersiz$_yuklem'),
      family: ImplicitFamily.kimlikAsagilama,
      category: ToxicityCategory.nefret,
      severity: 0.86,
    ),
    ImplicitPattern(
      // "Ermeniden ne beklenir" — kimliği kusurun sebebi sayan kuruluş.
      // `otekilestirme.baska_ne_beklenir` kalıbının kimlik eksenli hâli;
      // orada aşağılama, burada nefret söylemidir.
      id: 'nefret.kimlikten_ne_beklenir',
      pattern: _re('\\b${IdentityTerms.slot}'
          r'\s*(?:d[ae]n|t[ae]n)?\s+(?:baska )?ne beklen'),
      family: ImplicitFamily.kimlikAsagilama,
      category: ToxicityCategory.nefret,
      severity: 0.84,
    ),
    ImplicitPattern(
      // "Kürt olduğu için işe alınmamış" gibi bildirimlerle karışmasın diye
      // yalnızca ikinci şahsa yöneltilmiş hâli alınır:
      // "sen zaten Ermenisin" · "siz Alevisiniz zaten"
      id: 'nefret.kimlik_yaftalama',
      pattern: _re(r'\b(?:sen|siz)\b\s+(?:zaten\s+)?'
          '${IdentityTerms.slot}'
          r'\s*(?:sin|siniz|siniz)\b'),
      family: ImplicitFamily.kimlikAsagilama,
      category: ToxicityCategory.nefret,
      severity: 0.72,
    ),

    // ═══ GÖNDERGE (ANAFORA) ÇÖZÜMLEMESİ ══════════════════════════════════════
    // Belgelenmiş en büyük kaçak buydu (`04_MODEL_DEGERLENDIRME.md` §6):
    //
    //   "Suriyeliler her yeri doldurdu. Bunların soyunu kurutmak lazım."
    //                                    ▲
    //                       kimlik yuvası BU cümlede yok — kaçıyordu
    //
    // Kimlik bir önceki cümlededir; ikinci cümle ona bir çoğul işaret
    // zamiriyle gönderme yapar. Cümle cümle bakan bir katman bunu göremez.
    //
    // ── NEDEN YALNIZCA EN AĞIR ÜÇ SÖZVARLIĞI ────────────────────────────────
    // Gönderge çözümlemesi bir ÇIKARIMDIR; zamirin gerçekten kimliğe işaret
    // ettiğini kanıtlayamayız. "Suriyeli arkadaşlarımla yemek yaptık, bunlar
    // çok kötü oldu" cümlesinde zamir yemeğe gönderir.
    //
    // Bu belirsizlik, yüklem sözvarlığı seçilerek kapatılır: varlık reddi,
    // insanlıktan çıkarma ve dışlama sözvarlıkları nesneler hakkında iyi
    // niyetle KULLANILMAZ. "Bunların soyunu kurutmak lazım" bir yemek için
    // kurulmaz. Buna karşılık toplu suçlama (`hirsiz`, `pis`) ve
    // değersizleştirme (`bozuk`, `kirli`) sözvarlıkları nesneler için
    // gayet olağandır — bu yüzden gönderge sürümleri KASITLI olarak yoktur.
    //
    // Şiddetler doğrudan karşılıklarının altındadır: çıkarımın kendisi bir
    // belirsizlik payı taşır ve bu paya sayısal karşılık verilir.
    ImplicitPattern(
      id: 'nefret.varlik_reddi_anafora',
      pattern: _re('\\b${IdentityTerms.anaphora}${_gap(3)}'
          r'(?:yok edil|temizlen|yasamamali|olmamali|kokunu kurut|'
          r'soyunu kurut|gebertil|asilmali|yakilmali)\w*'),
      family: ImplicitFamily.varlikReddi,
      category: ToxicityCategory.nefret,
      severity: 0.90,
      requiresIdentityAntecedent: true,
    ),
    ImplicitPattern(
      id: 'nefret.insanliktan_cikarma_anafora',
      pattern: _re('\\b${IdentityTerms.anaphora}${_gap(3)}$_dehuman$_yuklem'),
      family: ImplicitFamily.insanliktanCikarma,
      category: ToxicityCategory.nefret,
      severity: 0.84,
      requiresIdentityAntecedent: true,
    ),
    ImplicitPattern(
      id: 'nefret.dislama_anafora',
      pattern: _re('\\b${IdentityTerms.anaphora}${_gap(3)}'
          r'(?:defol\w*|gitsin\w*|gonderil\w*|kovul\w*|sinir disi|'
          r'ulkesine don\w*|ulkelerine don\w*)'),
      family: ImplicitFamily.dislama,
      category: ToxicityCategory.nefret,
      severity: 0.80,
      requiresIdentityAntecedent: true,
      neutralAlternative: 'göç politikası hakkında farklı düşünüyorum',
    ),
  ];
}
