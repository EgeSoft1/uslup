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
  /// Etnik / ulusal köken.
  static const List<String> ethnic = [
    // Çakışan kökler: yalnızca çoğul/grup biçimi (ünlü uyumu ayırt eder).
    r'kurtler\w*', // Kürtler — "kurtlar" (hayvan) bu kalıba düşmez
    r'lazlar\w*', // Lazlar — "lazım" düşmez
    r'romanlar\w*', // Romanlar — "roman" (kitap) düşmez
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
  ];

  /// Cinsel yönelim / cinsiyet kimliği.
  static const List<String> orientation = [
    r'escinsel\w*',
    r'geyler\w*', // "geyik" düşmez
    r'lezbiyen\w*',
    r'biseksuel\w*',
    r'translar\w*', // "transfer", "transit" düşmez
  ];

  /// Göç durumu ve diğer korunan nitelikler.
  static const List<String> status = [
    r'multeci\w*',
    r'gocmen\w*',
    r'siginmaci\w*',
    r'engelli\w*',
    r'kadinlar\w*',
    r'erkekler\w*',
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
  static const String _yuklem =
      r'(?:(?:dir|dirlar|tir|tirlar|sin|siniz|siz|dur|durlar)\b|\s*$)';

  // ── Düşmanca yüklem sözvarlıkları ────────────────────────────────────────

  /// İnsanlıktan çıkarma terimleri. Soykırım araştırmalarında en erken ve en
  /// güvenilir uyarı işaretlerinden biridir; bu yüzden şiddeti yüksektir.
  static const String _dehuman =
      r'(?:hayvan|hasarat|bocek|virus|mikrop|surungen|asalak|parazit|'
      r'yamyam|vahsi|barbar)';

  /// Toplu suçlama yüklemleri.
  static const String _suclama =
      r'(?:hirsiz|katil|terorist|yalanci|sahtekar|hain|dolandirici|'
      r'sapik|caniyi?|pis|bela|tehlike|isgalci|beles(?:ci)?)';

  /// Değersizleştirme yüklemleri.
  static const String _degersiz =
      r'(?:asagilik|degersiz|bozuk|dusuk|kirli|igrenc|'
      r'hastalikli|sapkin|anormal)';

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
