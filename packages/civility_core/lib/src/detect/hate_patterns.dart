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
    // İP-33 (docs/26): normalleştirici q → k, w → v çevirir. "queer" ve
    // "down" yazımları hiçbir normalize metinde geçemezdi; iki terim de
    // İP-17'den beri ÖLÜ girdiydi. `test/hate_layer_test.dart` artık
    // kaynakta q/w/x harfini yapısal olarak yasaklıyor.
    r'kueer\w*',
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
    r'dovn sendromlu\w*', // "Down" — normalize biçimi (w → v)
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
    // İP-34 hata sınıfı E1 (docs/26 §6): aynı grupların gündelik ve
    // aşağılayıcı adları yuvada yoktu — "emekliler bir işe yaramaz",
    // "sakatlar ortalıkta dolaşmasın" kimlik kapısından hiç geçemiyordu.
    // "yasli" tekil biçimi hâlâ ALINMADI (yaslı · matem); yalnızca insan
    // bildiren adla birlikte alınır.
    r'emekliler\w*',
    r'ihtiyarlar\w*',
    r'yasli (?:insan|kisi|birey)ler\w*',
    r'sakatlar\w*',
    r'ozurluler\w*',
    r'kadin milleti\w*',
  ];

  /// Göç STATÜSÜ bildiren terimler. Oy hakkı, seçilme gibi vatandaşlığa
  /// bağlı haklar bu gruplar için bir göç politikası tartışmasıdır ve
  /// [IdentityTerms] K1 gereği nefret söylemi sayılmaz (docs/26 §6 · E6).
  static const List<String> migrationStatus = [
    r'multeci\w*',
    r'gocmen\w*',
    r'siginmaci\w*',
  ];

  /// [migrationStatus] dışındaki bütün kimlikler.
  static final String slotExceptMigration = '(?:${[
    for (final t in [...ethnic, ...religious, ...orientation, ...status])
      if (!migrationStatus.contains(t)) t,
  ].join('|')})';

  static const List<String> all = [
    ...ethnic,
    ...religious,
    ...orientation,
    ...status,
  ];

  /// Örüntülerin içine gömülecek yuva: `(?:kimlik1|kimlik2|…)`.
  static final String slot = '(?:${all.join('|')})';

  // ── İP-33 · TEKİL GENEL AD, YALNIZCA ÇIKMA HÂLİNDE (docs/26) ─────────────
  // "Kadından mühendis olmaz" · "Kızdan şoför olmaz" — cinsiyet kalıp
  // yargısının en yaygın Türkçe biçimi tekil ve çıkma hâlindedir. "kadın"
  // YUVAYA ALINMADI: tekil biçim çoğunlukla tek bir kişiyi gösterir ("bu
  // kadından ne beklenir" bir kişiye yöneltilmiş aşağılamadır, nefret
  // söylemi değil) ve bütün örüntülerde yuva doldursaydı o cümlelerin
  // kategorisini değiştirirdi. Bu biçimler YALNIZCA `nefret.tekil_genelleme`
  // tarafından kullanılır; kimlik kapısının onu atlamaması için [mention]
  // içindedir.
  static const String genericAblative =
      r'(?:kadin|kiz|yasli|ihtiyar)(?:dan|tan)';

  /// Metinde geçen kimlik terimlerini bulmak için derlenmiş biçim.
  /// Gönderge çözümlemesinde ÖNCÜL (antecedent) araması bunu kullanır.
  static final RegExp mention =
      RegExp('\\b(?:$slot|$genericAblative\\b)', caseSensitive: false);

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

  /// Kimlik yuvası + ara kelimeler, ADLANDIRILMIŞ gruplarla.
  ///
  /// Yalnızca yuvanın yüklemden ÖNCE geldiği kuruluşlarda kullanılır.
  /// Gruplar [isCompoundModifier] denetimi içindir: dedektör, eşleşmenin
  /// kimlik kelimesini ve araya giren kelimeleri bu adlarla okur.
  static String _kimlikVeAra(int n) =>
      '\\b(?<kimlik>${IdentityTerms.slot})(?<ara>(?:\\s+\\w+){0,$n})\\s+';

  // ── TAMLAMA DENETİMİ (denetim D9 · docs/23) ──────────────────────────────
  // Kimlik adı, belirtisiz isim tamlamasında bir NESNEYİ niteleyebilir:
  //
  //   "Kadınlar tuvaleti çok kirli"   → Yüksek risk · nefret söylemi ✗
  //   "Engelliler rampası bozuk"      → Yüksek risk · nefret söylemi ✗
  //   "Yaşlılar parkı çok kirli"      → Yüksek risk · nefret söylemi ✗
  //
  // Yüklemin öznesi grup değil, tamlamanın başıdır (tuvalet, rampa, park).
  // Bu cümleler tam da korunan grubun HAKLARINI savunan şikâyetlerdir; onları
  // işaretlemek README'deki "kimlik adı yasaklı kelime değildir" ilkesinin
  // yapısal karşılığını deler.
  //
  // İşaret: kimlik kelimesi yalın çoğul ("Kürtlerin", "Romanlarla" değil) ve
  // hemen ardındaki kelimelerden biri üçüncü tekil iyelik eki taşıyor ("-(s)I"). İyelik
  // biçiminde olup tamlama başı OLMAYAN sık kelimeler (zarflar, niceleyiciler)
  // ve grubun kendisine ait nitelik adları ("kanı", "aslı", "kafası") ayrıca
  // dışarıda tutulur; onlarda grup gerçekten hedeftir.

  /// Belirtisiz tamlamanın niteleyicisi yalın ÇOĞULDUR: "Kadınlar tuvaleti".
  /// Hâl eki almış kimlik ("Romanlarla", "Kürtlerin") niteleyici olamaz.
  static final RegExp _bareplural = RegExp(r'(?:lar|ler)$');
  static final RegExp _possessive3 = RegExp(r'^[a-z]{2,}(?:[^aeiouy][iu]|s[iu])$');

  static const Set<String> _notCompoundHead = {
    // zarf, bağlaç, niceleyici
    'gibi', 'sanki', 'yani', 'simdi', 'belki', 'hani', 'bari', 'dahi',
    'vallahi', 'billahi', 'resmi', 'kotu', 'ayni', 'hepsi', 'tumu', 'tamami',
    'cogu', 'bircogu', 'bazisi', 'bazilari', 'kimi', 'kimisi', 'cogunlugu',
    // İP-33: iyelik ekine BENZEYEN sıfat ve zarflar. "Yaşlılar YENİ bir şey
    // öğrenemez" cümlesinde "yeni" tamlama başı sanılıyor, saldırı
    // eleniyordu (docs/26).
    'yeni', 'eski', 'dogru', 'cesitli', 'farkli', 'turlu', 'bile', 'yine',
    'kendi', 'boyle', 'oyle', 'soyle',
    // grubun kendisine ait nitelik — hedef gruptur
    'kani', 'asli', 'ozu', 'kafasi', 'kafalari', 'beyni', 'beyinleri',
    'akli', 'akillari', 'ruhu', 'ruhlari', 'zihniyeti', 'zihniyetleri',
    'karakteri', 'karakterleri', 'ahlaki', 'ahlaklari', 'tabiati', 'dogasi',
    'genleri', 'kokeni', 'kokleri', 'soylari', 'huyu', 'huylari',
    'kulturu', 'kulturleri',
    // belirtme hâlindeki zamirler — tamlama başı değil, nesne
    'beni', 'seni', 'bizi', 'sizi', 'onlari', 'bunlari', 'sunlari',
    'herkesi', 'hepimizi', 'hepinizi',
  };

  /// Eşleşmede kimlik adı bir isim tamlamasının niteleyicisi mi?
  ///
  /// `true` ise yüklemin öznesi grup değildir ve eşleşme bulgu ÜRETMEZ.
  /// Adlandırılmış grupları taşımayan örüntülerde her zaman `false` döner.
  static bool isCompoundModifier(RegExpMatch match) {
    final names = match.groupNames;
    if (!names.contains('kimlik') || !names.contains('ara')) return false;

    final kimlik = match.namedGroup('kimlik')?.toLowerCase() ?? '';
    if (!_bareplural.hasMatch(kimlik)) return false;

    final ara = match.namedGroup('ara')?.trim().toLowerCase() ?? '';
    if (ara.isEmpty) return false;

    // Tamlama başı niteleyicinin hemen ardından gelir; bileşik başta
    // ("soyunma odası") ikinci kelimeye kadar uzanır. Daha uzağa bakmak,
    // yüklemden önceki nesneleri ("devleti") tamlama başı sanmak olurdu.
    for (final word in ara.split(RegExp(r'\s+')).take(2)) {
      if (word.length < 4 || _notCompoundHead.contains(word)) continue;
      if (_possessive3.hasMatch(word)) return true;
    }
    return false;
  }

  // ── İLGEÇ TÜMLECİ (İP-33 · docs/26) ──────────────────────────────────────
  // Kimlik adının hemen ardından bir ilgeç geliyorsa grup yüklemin öznesi
  // değil, ilgecin tümlecidir:
  //
  //   "Engelliler için yapılan rampa hiçbir işe yaramıyor"  → rampa yaramıyor
  //   "Kadınlara yönelik ayrımcılık kabul edilemez"         → ayrımcılık
  //
  // İkisi de grubun HAKKINI savunan cümlelerdir. Tamlama denetimiyle aynı
  // ilkedir: yüklemin kime söylendiğine bakılır.
  static const Set<String> _postpositions = {
    'icin', 'adina', 'yararina', 'lehine', 'hakkinda', 'uzerine',
    'konusunda', 'dair', 'yonelik', 'karsi', 'ozelinde',
  };

  /// Eşleşmede kimlik adı yüklemin öznesi DEĞİL mi?
  ///
  /// İki yapısal durum: belirtisiz tamlamanın niteleyicisi
  /// ([isCompoundModifier]) ya da bir ilgecin tümleci. Adlandırılmış
  /// grupları taşımayan örüntülerde her zaman `false` döner.
  static bool groupIsNotSubject(RegExpMatch match) {
    if (isCompoundModifier(match)) return true;
    final names = match.groupNames;
    if (!names.contains('ara')) return false;
    final ara = match.namedGroup('ara')?.trimLeft().toLowerCase() ?? '';
    if (ara.isEmpty) return false;
    final end = ara.indexOf(' ');
    final first = end < 0 ? ara : ara.substring(0, end);
    // "Göçmenler DEĞİL, yöneticiler suçlu" — grup olumsuzlanmış öznedir;
    // yüklem başka bir özneye aittir (İP-34 E9).
    return first == 'degil' || _postpositions.contains(first);
  }

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
  ///
  /// ── İP-26 EKLEMESİ ──────────────────────────────────────────────────────
  /// Durum bildiren son öbekler de aynı işlevi görüyordu ve aynı kaçışı
  /// açıyordu:
  ///
  ///   "Afganlar devlete yük olmuş"          → yakalanıyordu
  ///   "Afganlar devlete yük olmuş durumda"  → temiz (0.00)   ✗
  ///
  /// "durumda", "halde", "hale geldi" bir ad öbeği kurmaz; yüklemin
  /// ardından durur ve cümleyi bitirir. Kesinlik mekanizması bozulmaz.
  static const String _kuyruk = r'(?:\s+(?:artik|zaten|hep|hepsi|'
      r'hicbir zaman|asla|kesinlikle|tabii|elbette|bence|valla|vallahi|'
      r'her zaman|maalesef|ne yazik ki|iste|resmen|aynen|'
      r'durumda|durumdalar|halde|hale geldi|hale geldiler|'
      r'oldu|oldular|oluyor|oluyorlar))*\s*$';

  // ── Düşmanca yüklem sözvarlıkları ────────────────────────────────────────

  /// İnsanlıktan çıkarma terimleri. Soykırım araştırmalarında en erken ve en
  /// güvenilir uyarı işaretlerinden biridir; bu yüzden şiddeti yüksektir.
  static const String _dehuman =
      r'(?:hayvan|hasarat|bocek|virus|mikrop|surungen|asalak|parazit|'
      r'yamyam|vahsi|barbar)';

  /// Genelleyici zarflar. Bir durum bildirimini bütün gruba yayılan bir
  /// hükme çeviren kelimeler — bkz. İP-36 kuruluşları.
  static const String _genelleyici =
      r'(?:zaten|hep|hepsi|nasilsa|surekli|illa|tabii ki|elbette)';

  /// Toplu suçlama yüklemleri.
  static const String _suclama =
      r'(?:hirsiz|katil|terorist|yalanci|sahtekar|hain|dolandirici|'
      r'sapik|caniyi?|pis|bela|tehlikeli?|isgalci|beles(?:ci)?|'
      // İP-19: ölçümde kaçan güvenilmezlik atfı ("Ermeniler güvenilmez")
      // ve sıfat çekimli biçim ("tehlikeli", eski liste yalnızca "tehlike").
      r'guvenilmez|guvenilemez|'
      // İP-33: asalaklık atfı, göç ekseninde en yaygın biçimiyle.
      r'bedavaci|otlakci|'
      // İP-34 E9: "hepsi suçlu". "X değil, Y suçlu" yapısı
      // `groupIsNotSubject` içinde elenir.
      r'suclu)';

  /// Varlık reddi fiilleri. İP-33: "ölse de kurtulsak", "ölsünler",
  /// "gebersin" eklendi. "ölsün" ALINMADI: aksan katlaması sonrası "olsun"
  /// ile çakışır ("kadınlar da aday olsun"). "ölsünler" ise ünlü uyumuyla
  /// ayrılır: "olsunler" ≠ "olsunlar".
  static const String _varlikReddi =
      r'(?:yok edil|temizlen|yasamamali|olmamali|kokunu kurut|'
      r'soyunu kurut|gebertil|asilmali|yakilmali|'
      r'olse de kurtul|olsunler|gebersin|geberip git|'
      // İP-34 E8: dilek kipli eğretileme — "ölüp gitse(ler)".
      r'olup git(?:se|sin))';

  /// Ülkeden gönderme çağrısı. İP-33 öncesinde `ulkelerine don\w*` idi ve
  /// mastarı da alıyordu: "Mülteciler ülkelerine DÖNMEK istiyor ama savaş
  /// bitmedi" · Yüksek risk ✗. Grubun KENDİ isteği bir çağrı değildir;
  /// yalnızca istek, gereklilik ve ettirgen biçimler alınır.
  ///
  /// Gereklilik de olumsuzlanabilir: "ülkelerine dönmek zorunda
  /// KALMAMALI, savaş sürüyor" bir savunudur (ek tarama, docs/26 §4).
  static const String _ulkeyeDon =
      r'ulke(?:si|leri)ne (?:geri )?(?:'
      r'(?:don(?:sun|meli|mesi (?:lazim|gerek|sart)|durul|dursun)|yollan)\w*|'
      r'donmek zorunda\b(?!\s+(?:kal|birakil)ma))';

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

  // ── İP-33 · DÖRT EKSENİN YÜKLEMLERİ (15 Eylül 2026 · docs/26) ────────────
  // Yukarıdaki sözvarlıkları etnik ve inanç eksenindeki düşmanlık için
  // yazıldı. Cinsiyet, yaş, engellilik ve göç eksenindeki düşmanlık çoğunlukla
  // "hırsız" ya da "defolsun" demez; grubun YAPABİLECEKLERİNİ ve HAKLARINI
  // reddeder. İP-33 önce-ölçümü: bu dört eksende 32 saldırının 0'ı.

  /// Alıntı ya da soru değil. Yüklemin HEMEN ardından aktarma fiili, soru
  /// edatı ya da yargının kendisini ad olarak anan bir kelime geliyorsa
  /// cümle o yargıyı kurmuyor, anıyordur:
  ///
  ///   "Kim demiş kadınlar mühendis olamaz DİYE?"
  ///   "Göçmenler işimizi çalıyor MU, veriye bakalım"
  ///   "Yaşlılar teknolojiden anlamaz ÖNYARGISI"
  ///
  /// Bu parça yalnızca İP-33 kuruluşlarında kullanılır; bitiş şartı
  /// (`_yuklem`) taşımayan fiil yüklemleri içindir.
  static const String _anmaDegil =
      r'\b(?!\s+(?:diye|diyen\w*|dedi\w*|demek|denir|deniyor|denmesi\w*|'
      r'mi|mu|misin\w*|musun\w*|midir|mudur|'
      r'onyargi\w*|klise\w*|kalip yargi\w*|efsane\w*|soylem\w*|iddia\w*|'
      // Ek tarama (docs/26 §4): inanç fiilleri ve üst-dil "gibi"si.
      //   "Kızdan şoför olmaz SANIYORLARDI, şimdi otobüs kullanıyor"
      //   "Göçmenler kanımızı emiyor GİBİ CÜMLELER nefret söylemidir"
      r'sani\w*|sanan\w*|sandi\w*|zanned\w*|zanneden\w*|dusunen\w*|'
      r'dusunul\w*|inanan\w*|'
      r'gibi (?:cumle|soz|soylem|ifade|laf|yorum|paylasim|yazi|slogan)\w*|'
      // İP-34: yargıyı tümleç yapan konuşma adları — "… yiyor SÖZÜ klişe".
      r'sozu\w*|lafi\w*|cumlesi\w*|ifadesi\w*|slogani\w*)\b)';

  /// YETERSİZLİK ATFI — geniş zamanın olumsuzu, yetkinlik ve kavrayış
  /// fiilleri. Geniş zaman bir GENELLEMEDİR; şimdiki zaman bir DURUM
  /// bildirir ve alınmaz:
  ///
  ///   "Kadınlar araba kullanmayı beceremez"          → kalıp yargı
  ///   "Kadınlar gece bu sokakta yürüyemiyor"         → durum (aydınlatma yok)
  ///
  /// "yapamaz" / "kullanamaz" gibi genel fiiller KASITLI olarak yoktur:
  /// "engelliler bu binaya giremez, asansör yok" bir erişilebilirlik
  /// şikâyetidir. Yalnızca nesnesi bir BECERİ adı olduğunda alınır
  /// ("liderlik yapamaz", "para yönetmeyi bilmez" — İP-34 E3).
  ///
  /// "becer-" tek istisnadır ve şimdiki zamanda da alınır (İP-34 E2): fiilin
  /// kendisi yetkinlik bildirir; "beceremiyor" bir durum değil bir hükümdür.
  static const String _yetersizlik =
      r'(?:becerem(?:ez|ezler|iyor|iyorlar)|basaramaz(?:lar)?|anlamaz(?:lar)?|'
      r'ogrenemez(?:ler)?|kavrayamaz(?:lar)?|araba kullanamaz(?:lar)?|'
      r'(?:muhendis|yonetici|lider|pilot|sofor|doktor|asker|polis|hakim|'
      r'siyasetci|patron|sef|bilim insani|mimar|kaptan)\s+olamaz(?:lar)?|'
      r'(?:akli|akillari)(?:\s+\w+){0,2}\s+ermez(?:ler)?|'
      r'baska (?:bir )?sey bilmez(?:ler)?|'
      r'(?:\w+(?:lik|luk)|siyaset|bilim|matematik|ticaret) yapamaz(?:lar)?|'
      r'\w+(?:mayi|meyi) bilmez(?:ler)?|uyum saglayamaz(?:lar)?)';

  /// HAK REDDİ — kamusal hayata katılımı kısıtlayan gereklilik ve istek
  /// kipleri. Nesne listesi dardır ve bilinçli olarak VATANDAŞLIK, ÇALIŞMA
  /// İZNİ, OTURMA İZNİ gibi hukuki statüleri içermez: "sığınmacılara
  /// vatandaşlık verilmemeli" bir göç politikası görüşüdür ve bu ürün siyasi
  /// görüşü nefret söylemi saymaz (bkz. [IdentityTerms] K1). "Hiçbir hak
  /// tanınmamalı" ise bir politika değil, insan haklarının reddidir.
  static const String _hakReddi =
      r'(?:calismamali|okumamali|evlenmemeli|konusmamali|'
      r'araba kullanmamali|cocuk (?:sahibi olmamali|dogurmamali)|'
      r'(?:okula|ise|universiteye|okullara|siniflara|kadroya|meclise) '
      r'(?:alinmamali|gitmemeli|gonderilmemeli|kabul edilmemeli|girmemeli)|'
      r'(?:hicbir |hic )?(?:hak|haklari|hakki|is|gorev|koltugu?|makam|yetki|'
      r'kadro|soz hakki|egitim hakki|terfi|'
      // İP-34 E6: vatandaşlığa bağlı OLMAYAN belge ve haklar.
      r'ehliyet|diploma|burs|miras|velayet|ruhsat) '
      r'(?:verilmemeli|taninmamali)|'
      r'(?:sokaga|disari|evden|ortaya|ortalikta) '
      r'(?:cikmamali|cikmasin|cikmasinlar))\w*';

  /// Vatandaşlık hakkı reddi — oy, seçilme. Yalnızca [IdentityTerms
  /// .slotExceptMigration] ile kullanılır (İP-34 E6): "yaşlıların oy hakkı
  /// alınmalı" hak reddidir; "sığınmacılar oy kullanmamalı" bir vatandaşlık
  /// politikası tartışmasıdır.
  static const String _oyHakki =
      r'(?:oy (?:kullanmamali|vermemeli)|secilmemeli|aday olmamali|'
      r'(?:oy|secme|secilme) hak(?:ki|lari) (?:alinmali|kaldirilmali|'
      r'ellerinden alinmali|olmamali|verilmemeli))\w*';

  /// Yer biçme: "kadınların yeri evidir" · "yaşlıların yeri huzurevidir".
  static const String _yerBicme =
      r'yeri\s+(?:\w+\s+)?(?:evi|evleri|mutfak|mutfagi|yuvasi|huzurevi|'
      r'bakimevi|kamplar|kamp|kendi ulkesi|kendi ulkeleri)';

  /// Yer biçmenin istek kipi (İP-34 E5): "evde otursunlar", "ortalıkta
  /// dolaşmasın". Kamu uyarısı biçimi ("sıcak havalarda evde kalsınlar")
  /// koşul tümleciyle elenir.
  static const String _yerBicmeIstek =
      r'(?:evde|evlerinde|evinde|mutfakta|yerinde|yerlerinde|kosesinde|'
      r'koselerinde) (?:otursun|kalsin|dursun)\w*|'
      r'(?:ortalikta|sokakta|sokaklarda|disarida|gozumuzun onunde) '
      r'(?:dolasmasin|gezmesin|gorunmesin)\w*';

  /// Suç, istila ve asalaklık atfı — FİİL yüklemli. Ortaç biçimler ("işimizi
  /// çaldığı iddiası") çekimli yüklem olmadığı için kalıba düşmez.
  static const String _sucAtfi =
      r'(?:(?:isimizi|islerimizi|ekmegimizi|topraklarimizi|rizkimizi) '
      r'(?:caliyor|elimizden aliyor|kapiyor|yiyor)|'
      r'(?:ulkemizi|ulkeyi|topraklarimizi|sehrimizi|sehirlerimizi|mahallemizi|'
      r'her yeri) (?:isgal|istila) (?:ediyor|etti|etmis|edecek)|'
      // İP-34 E9: geçmiş zaman ve "akın" eğretilemesi.
      r'(?:ulkeye|ulkemize|sinirdan|sinirlardan|sehre|sehirlere|avrupaya) '
      r'akin (?:ediyor|etti|etmis)|'
      r'(?:bedava(?:ya|dan)?|vergimizle|paramizla|sirtimizdan) (?:yasiyor|geciniyor)|'
      r'(?:devletin|milletin|bizim|halkin|devletimizin) sirtinda '
      r'(?:yasiyor|geciniyor)|'
      r'(?:ulkenin|ulkemizin|milletin|devletin|halkin|bizim) kanini emiyor|'
      r'kanimizi emiyor|suc isliyor|suc makinesi)(?:lar|ler)?';

  /// Maliyet söylemi: bir gruba yönelik ÇABAYI israf ilan etmek.
  /// "zarar" KASITLI olarak yoktur: "göçmenleri sigortasız çalıştırmak
  /// devlete zarar" bir hak savunusudur ve bu kalıpla yazılır.
  static const String _maliyet =
      r'(?:para israfi|zaman kaybi|israf|bosa masraf|gereksiz masraf|'
      r'bosa gid(?:iyor|er))';

  /// Katkı reddi (İP-34 E7): "engelliler topluma bir şey katmaz".
  static const String _katkiReddi =
      r'(?:topluma|ulkeye|bize|hayata|dunyaya|ekonomiye) (?:hicbir|bir) '
      r'(?:sey|katki|fayda|deger) (?:katmaz|saglamaz|vermez|getirmez|katmiyor)'
      r'(?:lar|ler)?';

  /// Koşul, gerekçe ve düzenleme tümleçleri. Kısıtlamayı bir kamu uyarısına,
  /// sağlık önerisine ya da mevzuat bildirimine çevirir. [ImplicitPattern
  /// .suppressedBy] ile kullanılır; gerekçe orada.
  ///
  /// "-dıktan sonra" KASITLI olarak yoktur: "kadınlar evlendikten sonra
  /// çalışmamalı" bir uyarı değil, hak reddidir. Yalnızca ad öbeği kuran
  /// "doğum sonrası" alınır. Bilinen bedel: listedeki bir kelimeyi
  /// ("yönetmelik", "tedbir") taşıyan gerçek bir saldırı da yumuşar.
  static final RegExp _kosulTumleci = RegExp(
    r'\b(?:nedeniyle|sebebiyle|dolayisiyla|dolayi|olmadikca|gerekmedikce|'
    r'surece|boyunca|suresince|saatlerinde|saatleri|sonrasi|sonrasinda|'
    r'oncesinde|uyari\w*|tavsiye\w*|salgin\w*|karantina\w*|tedbir\w*|'
    r'hamile\w*|gebe\w*|doktor(?:u|lari|unuz)? onerisi\w*|hekim\w*|'
    r'yonetmelik\w*|mevzuat\w*|kanunen|yasal olarak|kural geregi|'
    r'sicak hava\w*|sicakta|soguk hava\w*|firtina\w*|yagis\w*)\b',
    caseSensitive: false,
  );

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
    // İP-26 · yeni kuruluşların zorunlu sabit parçaları.
    r'|adam olmaz|adam olmuyor'
    r'|\b(?:sen|siz)\b'
    r'|\b(?:butun|tum|hepsi|hepiniz|her|tamami|tumu)\b'
    // İP-33 · dört eksenin kuruluşları (docs/26).
    r'|olse de kurtul|olsunler|gebersin|geberip|olup git|ulkesine|ulkelerine'
    r'|becerem|basaramaz|anlamaz|ogrenemez|kavrayamaz|kullanamaz|olamaz'
    r'|ermez|bilmez|ise yara|halt ol|hayir gelmez|fayda gelmez|olmaz|olmuyor'
    r'|calismamali|okumamali|evlenmemeli|konusmamali|kullanmamali'
    r'|vermemeli|secilmemeli|dogurmamali|alinmamali|gitmemeli'
    r'|gonderilmemeli|edilmemeli|girmemeli|verilmemeli|taninmamali'
    r'|cikmamali|cikmasin|yeri'
    r'|caliyor|aliyor|kapiyor|ediyor|yasiyor|geciniyor|emiyor|isliyor'
    // İP-36 · zarflı kuruluşların zorunlu yüklemleri. Kapı daraltılamaz
    // ama GENİŞLETİLMESİ her zaman güvenlidir: eksik bir sözcük sessiz
    // kaçak üretir, fazlası yalnızca birkaç mikrosaniyeye mal olur.
    r'|calar|calisamaz|hirsizlik'
    r'|suc makinesi|israf|kaybi|masraf|degil|geleli|den beri|yuzunden'
    // İP-34 hata sınıfları (docs/26 §6).
    r'|suclu|yapamaz|saglayamaz|katmaz|saglamaz|vermez|getirmez|katmiyor'
    r'|bosa gid|isi var|otursun|kalsin|dursun|dolasmasin|gezmesin'
    r'|gorunmesin|etti|etmis|edecek|akin|sirtinda|yiyor|alinmali'
    r'|kaldirilmali|olmamali'
    ')',
    caseSensitive: false,
  );

  static final List<ImplicitPattern> all = [
    // ═══ İNSANLIKTAN ÇIKARMA ═════════════════════════════════════════════════
    // "Suriyeliler hayvandır" · "Bunlar hasarat"
    // Yakın-kaçış: "Suriyeli gönüllüler hayvan haklarıyla ilgileniyor"
    ImplicitPattern(
      id: 'nefret.insanliktan_cikarma',
      pattern: _re('${_kimlikVeAra(3)}$_dehuman$_yuklem'),
      family: ImplicitFamily.insanliktanCikarma,
      category: ToxicityCategory.nefret,
      severity: 0.92,
    ),

    // ═══ VARLIK REDDİ / ŞİDDETE ÇAĞRI ════════════════════════════════════════
    // En ağır biçim. Yasal olarak da suç teşkil eder (TCK 216).
    // Bu kategoride "öneri" değil, doğrudan üst düzey uyarı üretilir.
    ImplicitPattern(
      id: 'nefret.varlik_reddi',
      pattern: _re('${_kimlikVeAra(3)}$_varlikReddi\\w*'),
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
      pattern: _re('${_kimlikVeAra(3)}'
          r'(?:defol\w*|gitsin\w*|gonderil\w*|kovul\w*|sinir disi|'
          '$_ulkeyeDon|'
          r'istemiyoruz|istemiyorum|'
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
      pattern: _re('${_kimlikVeAra(3)}$_suclama$_yuklem'),
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
      pattern: _re('${_kimlikVeAra(3)}$_yuk$_yuklem'),
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
      pattern: _re('${_kimlikVeAra(4)}'
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
      pattern: _re('${_kimlikVeAra(3)}$_degersiz$_yuklem'),
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
          // Denetim D9 (docs/23): almaşık "sin|siniz|siniz" idi — yinelenen
          // "siniz" yazım hatasıydı ve yuvarlak ünlülü çekimi hiç üretmiyordu:
          // "sen zaten Uygursun", "siz Hindusunuz" kaçıyordu.
          r'\s*(?:sin|siniz|sun|sunuz)\b'),
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
      pattern: _re('\\b${IdentityTerms.anaphora}${_gap(3)}$_varlikReddi\\w*'),
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
          '$_ulkeyeDon)'),
      family: ImplicitFamily.dislama,
      category: ToxicityCategory.nefret,
      severity: 0.80,
      requiresIdentityAntecedent: true,
      neutralAlternative: 'göç politikası hakkında farklı düşünüyorum',
    ),

    // ═══ İP-26 · YENİ KURULUŞLAR (12 Eylül 2026) ═════════════════════════════
    //
    // İkisi de "bu grubun bireyleri düzelemez" önermesini kurar; kişinin
    // davranışını değil, GRUBUNU sebep gösterirler. Ölçümde ikisi de
    // kaçıyordu ve ikisi de Türkçe'de son derece yaygın.

    ImplicitPattern(
      // "bu Romanlardan adam olmaz" · "Suriyelilerden adam olmuyor"
      //
      // Yakın-kaçış: "bu çocuktan adam olmaz" — kimlik yuvası yok, kalıba
      // düşmez. Kişiye yöneltilmiş hâli `karakter.adam_olmaz` içindedir ve
      // orada nefret değil hakarettir; ayrımı yapan tek şey yuvadır.
      id: 'nefret.kimlikten_adam_olmaz',
      pattern: _re('${_kimlikVeAra(2)}'
          // İP-33: aynı önermenin argo ve "hayır" biçimleri.
          r'(?:(?:adam|bir halt) ol(?:maz|muyor)|(?:hayir|fayda) gelmez)\w*'),
      family: ImplicitFamily.kimlikAsagilama,
      category: ToxicityCategory.nefret,
      severity: 0.84,
      neutralAlternative: 'bu konuda olumsuz deneyimlerim oldu',
    ),

    ImplicitPattern(
      // "Alevilerin hepsi öyle zaten" · "Ermenilerin tümü aynı"
      //
      // İÇERİKSİZ TOPLU GENELLEME: yüklem bir sözvarlığına düşmez çünkü
      // yüklem yoktur — suçlama, "öyle" işaret zarfına yüklenip okuyucunun
      // zihnindeki olumsuz içeriğe bırakılır. Kuruluşun kendisi saldırıdır.
      //
      // Yakın-kaçış: "Alevilerin hepsi öyle düşünmüyor" → kalıba DÜŞMEZ.
      // `_yuklem` cümle sonu şart koşar; arkasından bir fiil gelirse eşleşme
      // kırılır. Bu, olumsuzlamayı da doğal olarak dışarıda bırakır.
      id: 'nefret.iceriksiz_genelleme',
      pattern: _re('${_kimlikVeAra(2)}'
          '(?:hepsi|tumu|tamami|hepsi de)\\s+(?:oyle|boyle|ayni|bir)$_yuklem'),
      family: ImplicitFamily.topluSuclama,
      category: ToxicityCategory.nefret,
      severity: 0.78,
      neutralAlternative: 'bu konuda genelleme yapmak istemiyorum',
    ),

    // ═══ İP-36 · GENELLEYİCİ ZARF, DURUMU HÜKME ÇEVİRİR ═════════════════════
    //
    // Jüri sondasında iki kaçak vardı: "Romanlar zaten çalar" ve
    // "Engelliler çalışamaz zaten". İkisi de mevcut sözvarlıklarına
    // düşmüyordu — `_suclama` ADLARDAN oluşur (hırsız, katil), fiillerden
    // değil; `_yetersizlik` ise genel fiilleri (yapamaz, çalışamaz) KASITLI
    // olarak dışarıda bırakır, çünkü "engelliler bu binada çalışamaz,
    // asansör yok" bir erişilebilirlik şikâyetidir.
    //
    // ── AYIRT EDİCİ: GENELLEYİCİ ZARF ────────────────────────────────────
    // Farkı yaratan şey fiil değil, yanındaki zarftır. "Zaten", "hep",
    // "nasılsa" bir DURUM bildirimini bütün gruba yayılan bir HÜKME çevirir:
    //
    //   "Romanlar davul çalar"            → kültürel bir gözlem      → temiz
    //   "Romanlar zaten çalar"            → hırsızlık ithamı         → nefret
    //   "Engelliler bu katta çalışamaz"   → erişilebilirlik sorunu   → temiz
    //   "Engelliler zaten çalışamaz"      → kalıp yargı              → nefret
    //
    // Bu yüzden zarf kalıbın ZORUNLU parçasıdır. Zarfsız hiçbir şey üretmez.
    ImplicitPattern(
      id: 'nefret.zarfli_hirsizlik_atfi',
      pattern: _re('${_kimlikVeAra(2)}$_genelleyici'
          r'(?:\s+\w+){0,2}\s+cal(?:ar|arlar|iyor|iyorlar)\b'
          '|${_kimlikVeAra(2)}'
          r'hirsizlik yap(?:ar|arlar|iyor|iyorlar)\b'),
      family: ImplicitFamily.topluSuclama,
      category: ToxicityCategory.nefret,
      severity: 0.82,
      neutralAlternative: 'bu davranışı yapan kişiden rahatsızım',
    ),
    ImplicitPattern(
      id: 'nefret.zarfli_yetersizlik',
      pattern: _re('${_kimlikVeAra(2)}$_genelleyici'
          r'(?:\s+\w+){0,2}\s+(?:calisamaz|calisamazlar|is yapamaz'
          r'|is yapamazlar|ise yaramaz|ise yaramazlar)\b'
          '|${_kimlikVeAra(2)}'
          r'(?:calisamaz|calisamazlar|ise yaramaz|ise yaramazlar)\s+'
          '$_genelleyici'),
      family: ImplicitFamily.kalipYargi,
      category: ToxicityCategory.nefret,
      severity: 0.78,
      neutralAlternative: 'bu konuda kaygılarım var',
    ),

    // ═══ İP-33 · CİNSİYET · YAŞ · ENGELLİLİK · GÖÇ (15 Eylül 2026) ══════════
    //
    // Önce-ölçüm (docs/26): bu dört eksende 32 saldırının 0'ı yakalanıyordu.
    // Kimlik söz varlığı bu grupları zaten kapsıyordu; eksik olan YÜKLEMDİ.
    // Aşağıdaki kuruluşların hepsi yuvayı yüklemden önce ister ve hepsi
    // `groupIsNotSubject` denetiminden geçer.

    ImplicitPattern(
      // "Kadınlar siyasetten anlamaz" · "Yaşlılar yeni bir şey öğrenemez"
      // Yakın-kaçış: "Kadınlar gece bu sokakta yürüyemiyor" (şimdiki zaman,
      // durum bildirir) · "Kim demiş kadınlar mühendis olamaz diye?" (anma)
      id: 'nefret.yetersizlik_atfi',
      pattern: _re('${_kimlikVeAra(4)}$_yetersizlik$_anmaDegil'),
      family: ImplicitFamily.kalipYargi,
      category: ToxicityCategory.nefret,
      // Kalıp yargı, insanlıktan çıkarma ya da dışlama kadar ağır değildir;
      // Riskli bandında kalır ve gönderim öncesi onay istemez.
      severity: 0.62,
      neutralAlternative: 'bu konuda herkesin deneyimi farklı olabiliyor',
      suppressedBy: _kosulTumleci,
    ),

    ImplicitPattern(
      // "Engelliler hiçbir işe yaramaz" · "Yaşlılar artık bir işe yaramıyor"
      // Yakın-kaçış: "Engelliler için yapılan rampa hiçbir işe yaramıyor"
      // (ilgeç tümleci — yaramayan rampadır)
      id: 'nefret.ise_yaramazlik',
      pattern: _re('${_kimlikVeAra(3)}'
          r'(?:(?:(?:hicbir|bir) )?ise yara(?:maz|mazlar|miyor|miyorlar)|'
          '$_katkiReddi)'
          '$_anmaDegil'),
      family: ImplicitFamily.kalipYargi,
      category: ToxicityCategory.nefret,
      severity: 0.82,
      neutralAlternative: 'bu konuda olumsuz deneyimlerim oldu',
    ),

    ImplicitPattern(
      // "Kadından mühendis olmaz" · "Kızdan şoför olmaz"
      // Yakın-kaçış: "Bu kadından doktor olmaz" — işaret sıfatı tek bir
      // kişiyi gösterir; o cümle bir kişiye hakarettir, nefret söylemi değil.
      id: 'nefret.tekil_genelleme',
      pattern: _re('(?<!\\b(?:bu|su|o) )\\b${IdentityTerms.genericAblative}'
          r'\s+(?:\w+\s+)?'
          r'(?:muhendis|yonetici|lider|pilot|sofor|doktor|asker|polis|hakim|'
          r'siyasetci|patron|sef|bilim insani|mimar|kaptan|adam|is|bir halt)'
          r'\s+ol(?:maz|muyor)'
          '$_anmaDegil'),
      family: ImplicitFamily.kalipYargi,
      category: ToxicityCategory.nefret,
      severity: 0.66,
      neutralAlternative: 'bu meslekte herkes kendini kanıtlayabilir',
    ),

    ImplicitPattern(
      // "Yaşlılar oy kullanmamalı" · "Kadınlara yönetici koltuğu verilmemeli"
      // Yakın-kaçış: "Kar yağışı nedeniyle engelliler evden çıkmamalı"
      // (kamu uyarısı — koşul tümleci) · "Kadınlar çalışmamalı diyenlere
      // karşı sesimizi yükseltiyoruz" (anma)
      id: 'nefret.hak_reddi',
      pattern: _re('${_kimlikVeAra(3)}$_hakReddi$_anmaDegil'),
      family: ImplicitFamily.hakReddi,
      category: ToxicityCategory.nefret,
      severity: 0.80,
      neutralAlternative: 'bu konuda farklı düşünüyorum',
      suppressedBy: _kosulTumleci,
    ),

    ImplicitPattern(
      // "Kadınların yeri evidir" · "Yaşlıların yeri huzurevidir"
      // Yakın-kaçış: "Kadınların yeri neresi olacağına kendileri karar
      // verir" · "Yaşlıların yeri huzurevi değil, ailesinin yanı" (bitiş şartı)
      id: 'nefret.yer_bicme',
      pattern: _re('${_kimlikVeAra(1)}$_yerBicme$_yuklem'),
      family: ImplicitFamily.hakReddi,
      category: ToxicityCategory.nefret,
      severity: 0.74,
      neutralAlternative: 'herkes kendi hayatına kendisi karar verebilmeli',
    ),

    ImplicitPattern(
      // "Kadınlar evde otursun" · "Sakatlar ortalıkta dolaşmasın"
      // Yakın-kaçış: "Sıcak havalarda yaşlılar evde kalsın" (koşul tümleci)
      id: 'nefret.yer_bicme_istek',
      pattern: _re('${_kimlikVeAra(4)}$_yerBicmeIstek$_anmaDegil'),
      family: ImplicitFamily.hakReddi,
      category: ToxicityCategory.nefret,
      severity: 0.74,
      neutralAlternative: 'herkes kendi hayatına kendisi karar verebilmeli',
      suppressedBy: _kosulTumleci,
    ),

    ImplicitPattern(
      // "Kadınların futbolla ne işi var" · "Yaşlıların sosyal medyada ne işi var"
      // Retorik soru biçimli dışlama (İP-34 E4). Yakın-kaçış: "… ne işi var
      // diye soran müdür uyarıldı" (anma).
      id: 'nefret.ne_isi_var',
      pattern: _re('${_kimlikVeAra(3)}ne isi (?:var|olur)$_anmaDegil'),
      family: ImplicitFamily.hakReddi,
      category: ToxicityCategory.nefret,
      severity: 0.72,
      neutralAlternative: 'bu alanda kimlerin yer alacağını tartışabiliriz',
    ),

    ImplicitPattern(
      // "Yaşlıların oy hakkı alınmalı" · "Aleviler seçilmemeli"
      // Göç statüsü yuvası KASITLI olarak dışarıda — gerekçe: `_oyHakki`.
      id: 'nefret.oy_hakki_reddi',
      pattern: _re('\\b(?<kimlik>${IdentityTerms.slotExceptMigration})'
          r'(?<ara>(?:\s+\w+){0,3})\s+'
          '$_oyHakki$_anmaDegil'),
      family: ImplicitFamily.hakReddi,
      category: ToxicityCategory.nefret,
      severity: 0.80,
      neutralAlternative: 'bu konuda farklı düşünüyorum',
      suppressedBy: _kosulTumleci,
    ),

    ImplicitPattern(
      // "Göçmenler işimizi çalıyor" · "Sığınmacılar vergimizle bedava yaşıyor"
      // Yakın-kaçış: "Göçmenlerin işimizi çaldığı iddiası verilerle
      // çürütüldü" (ortaç, çekimli yüklem değil) · "… çalıyor mu?" (soru)
      id: 'nefret.suc_atfi',
      pattern: _re('${_kimlikVeAra(4)}$_sucAtfi$_anmaDegil'),
      family: ImplicitFamily.topluSuclama,
      category: ToxicityCategory.nefret,
      severity: 0.84,
      neutralAlternative: 'göç politikasının ekonomik etkileri konusunda kaygılıyım',
    ),

    ImplicitPattern(
      // "Sağırlarla uğraşmak zaman kaybı" · "Yaşlılara iş vermek para israfı"
      // Yakın-kaçış: "Engellileri işe almamak para israfı" — olumsuz ad-fiil
      // bir hak savunusudur ve kalıba düşmez.
      id: 'nefret.maliyet_soylemi',
      pattern: _re('${_kimlikVeAra(2)}'
          r'\w+(?:mak|mek)(?<!mamak|memek)\s+(?:\w+\s+){0,2}'
          '$_maliyet$_yuklem'),
      family: ImplicitFamily.kimlikAsagilama,
      category: ToxicityCategory.nefret,
      severity: 0.78,
      neutralAlternative: 'bu desteğin nasıl verildiği konusunda kaygılarım var',
    ),

    ImplicitPattern(
      // "Otistikler normal insan değildir"
      // Yakın-kaçış: "Kadınlar ikinci sınıf insan değildir" — araya yalnızca
      // pekiştireç girebilir; niteleyici olumsuzlanınca cümle eşitlik
      // savunusudur. "… insan değil mi?" soru olduğu için bitiş şartına düşer.
      id: 'nefret.insan_degil',
      pattern: _re('\\b(?<kimlik>${IdentityTerms.slot})'
          r'(?<ara>(?:\s+(?:zaten|hic|asla|hepsi|artik))?)\s+'
          r'(?:normal |gercek |tam |bizim gibi )?insan(?:lar)?\s+'
          r'degil(?:dir|dirler|ler)?'
          '$_kuyruk'),
      family: ImplicitFamily.insanliktanCikarma,
      category: ToxicityCategory.nefret,
      severity: 0.90,
    ),

    ImplicitPattern(
      // "Göçmenler geldi geleli mahallede huzur kalmadı"
      // Yakın-kaçış: "Mülteciler yüzünden değil, kötü yönetim yüzünden huzur
      // kalmadı" — aradaki "değil" suçlamayı gruptan alır.
      id: 'nefret.nedensel_suclama',
      pattern: _re('${_kimlikVeAra(1)}'
          r'(?:geldi geleli|geldiginden beri|geldiklerinden beri|yuzunden)\s+'
          r'(?:(?!degil\b)\w+\s+){0,3}'
          r'(?:huzur|rahat|guven|asayis|bereket|is|ekmek)\w*\s+'
          r'(?:kalmadi|bozuldu)'
          '$_kuyruk'),
      family: ImplicitFamily.topluSuclama,
      category: ToxicityCategory.nefret,
      severity: 0.74,
      neutralAlternative: 'mahallede yaşanan sorunlardan rahatsızım',
    ),
  ];
}
