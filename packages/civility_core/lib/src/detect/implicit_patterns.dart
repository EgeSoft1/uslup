// =============================================================================
// Örtük Saldırı Örüntüleri — Türkçe edimbilimsel kalıplar
// Dosya: packages/civility_core/lib/src/detect/implicit_patterns.dart
//
// ── NEDEN VAR ─────────────────────────────────────────────────────────────
// Sözlük katmanı yalnızca YASAKLI KELİME içeren saldırıyı görür. Ölçüm bunu
// sayısallaştırdı: örtük saldırı diliminde duyarlılık %0,0 idi.
//
// Oysa sosyal medyadaki düşmanlığın büyük kısmı tek bir yasaklı kelime
// içermez:
//
//   "senin gibilerden zaten bu beklenirdi"   → ötekileştirme
//   "sen ne anlarsın bu işlerden"            → yetkinlik reddi
//   "gününü göreceksin"                      → tehdit
//
// ── NEDEN KELİME LİSTESİ DEĞİL, KALIP ─────────────────────────────────────
// Bu ifadelerde saldırganlık KELİMELERDE değil, KELİMELERİN DİZİLİŞİNDE
// taşınır. "gibi", "ne", "bak" kelimeleri tek başına masumdur; saldırgan
// olan `[2.şahıs] + gibiler` yapısıdır. Bu yüzden katman sözlük değil,
// edimbilimsel (pragmatic) örüntü kataloğudur.
//
// ── YANLIŞ POZİTİF DİSİPLİNİ ──────────────────────────────────────────────
// Her örüntü, kendisine kelime düzeyinde benzeyen masum bir cümleyle
// birlikte tasarlanmıştır ve o cümle altın kümede "yakın-kaçış" olarak
// bulunur:
//
//   "senin gibilerden bu beklenirdi"  → yakalanır
//   "senin gibi düşünenler haklı"     → yakalanMAZ   ← aynı kelimeler
//   "görüşürüz seninle"               → yakalanır
//   "görüşürüz, iyi akşamlar"         → yakalanMAZ
//   "sana ne"                         → yakalanır
//   "sana ne getireyim marketten"     → yakalanMAZ
//
// Örüntüler NORMALİZE metin üzerinde çalışır: küçük harf, aksansız,
// noktalamasız. Bu sayede "S3n ne anlarsın" gibi gizleme denemeleri de
// aynı örüntüye düşer.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'hate_patterns.dart';
import 'idiom_patterns.dart';

/// Örtük saldırının edimbilimsel türü. Şeffaflık panelinde kullanıcıya
/// "bu ifade neden sorunlu" açıklaması bu sınıflandırmadan üretilir.
enum ImplicitFamily {
  /// Muhatabın bilgi/yetkinlik kapasitesinin reddi.
  kucumseme,

  /// Bireyi bir kategoriye indirgeme, grup suçlaması.
  otekilestirme,

  /// Muhataplığın ve katkının reddi.
  yoksayma,

  /// Açık hakaret içermeyen, öfke ve misilleme vaadi.
  tehdit,

  /// Geri adım attırmaya, söz hakkını gaspetmeye yönelik kalıplar.
  susturma,

  /// Zero-Shot Sarcasm Detection (İroni ve Kinaye)
  /// Kelimeler olumlu olsa da cümlenin yapısı manipülatif ve alaycıdır.
  kinaye,

  /// Kendine Zarar Verme (Self-Harm) Tespiti
  /// Toksisitenin başkasına değil, kullanıcının kendisine yönelmesi.
  kendineZararVerme,

  /// Övgü kılığında alay.
  alayci,

  /// Yasaklı kelime içermeyen tehdit.
  ortukTehdit,

  /// Kişiliğin bütünüyle reddi (küfürsüz).
  karakterSaldirisi,

  /// "X demiyorum ama..." — inkâr kalıbıyla örtülü hakaret.
  inkarKalibi,

  // ── Kimlik hedefli aileler (bkz. hate_patterns.dart) ────────────────────
  // Bunlar `ToxicityCategory.nefret` üretir. Ayrı aile olmalarının sebebi,
  // kullanıcıya gösterilen gerekçenin farklı olması: nefret söyleminde
  // hedef muhatabın davranışı değil, DEĞİŞTİREMEYECEĞİ bir niteliğidir.

  /// Bir kimlik grubunu insan olmaktan çıkaran benzetme.
  insanliktanCikarma,

  /// Bir kimlik grubunun ülkeden/ortamdan atılması çağrısı.
  dislama,

  /// Bireysel kusurun tüm gruba yüklenmesi.
  topluSuclama,

  /// Kimliğin kendisinin değersiz/hastalıklı sayılması.
  kimlikAsagilama,

  /// Bir grubun var olma hakkının reddi, şiddete çağrı.
  varlikReddi,
}

extension ImplicitFamilyInfo on ImplicitFamily {
  String get label => switch (this) {
        ImplicitFamily.kucumseme => 'Küçümseme',
        ImplicitFamily.otekilestirme => 'Ötekileştirme',
        ImplicitFamily.yoksayma => 'Yok Sayma',
        ImplicitFamily.tehdit => 'Tehdit',
        ImplicitFamily.susturma => 'Susturma',
        ImplicitFamily.kinaye => 'Kinaye ve İroni',
        ImplicitFamily.kendineZararVerme => 'Kendine Zarar Verme (Acil Durum)',
        ImplicitFamily.alayci => 'Alay Etme',
        ImplicitFamily.ortukTehdit => 'Örtük tehdit',
        ImplicitFamily.karakterSaldirisi => 'Karakter saldırısı',
        ImplicitFamily.inkarKalibi => 'İnkâr kalıbı',
        ImplicitFamily.insanliktanCikarma => 'İnsanlıktan çıkarma',
        ImplicitFamily.dislama => 'Dışlama',
        ImplicitFamily.topluSuclama => 'Toplu suçlama',
        ImplicitFamily.kimlikAsagilama => 'Kimlik aşağılama',
        ImplicitFamily.varlikReddi => 'Varlık reddi',
      };

  /// Kullanıcıya gösterilen gerekçe. Suçlayıcı değil, açıklayıcı bir dil
  /// kasıtlıdır: amaç kullanıcıyı utandırmak değil, farkındalık yaratmaktır.
  String get explanation => switch (this) {
        ImplicitFamily.kucumseme =>
          'Karşındakinin anlama kapasitesini reddediyor. '
              'Bu, tartışmayı fikir düzeyinden çıkarır.',
        ImplicitFamily.otekilestirme =>
          'Kişiyi bir gruba indirgiyor. Muhatabın kendisi değil, '
              'temsil ettiği varsayılan kategori hedef alınıyor.',
        ImplicitFamily.yoksayma =>
          'Karşındakinin konuşma hakkını değersizleştiriyor.',
        ImplicitFamily.susturma =>
          'Karşı tarafı susturmaya yönelik. Fikir yerine kişi hedefte.',
        ImplicitFamily.alayci =>
          'Övgü biçiminde alay içeriyor. Karşı taraf bunu iğneleme '
              'olarak okuyacaktır.',
        ImplicitFamily.ortukTehdit =>
          'Örtük tehdit içeriyor. Yasaklı kelime geçmese de karşı tarafta '
              'güvenlik kaygısı yaratır.',
        ImplicitFamily.karakterSaldirisi =>
          'Kişiliğin bütününü reddediyor. Davranışı değil, kişiyi hedef alıyor.',
        ImplicitFamily.inkarKalibi =>
          '"Demiyorum ama" kalıbı, hakareti inkâr ederek söylemenin yoludur. '
              'Karşı taraf yine de hakaret olarak algılar.',
        ImplicitFamily.insanliktanCikarma =>
          'Bir insan grubunu hayvana veya zararlıya benzetiyor. '
              'Bu benzetme, sonrasında gelen her şeyi meşrulaştırır.',
        ImplicitFamily.dislama =>
          'Bir grubun buradan gitmesini istiyor. Hedef kişilerin '
              'davranışı değil, kim oldukları.',
        ImplicitFamily.topluSuclama =>
          'Bir kişinin ya da olayın sorumluluğunu koca bir gruba yüklüyor. '
              'Grubun her üyesi bu cümlede suçlanmış oluyor.',
        ImplicitFamily.kimlikAsagilama =>
          'Kimliğin kendisini kusur sayıyor. Karşındaki bunu '
              'değiştiremez — bu yüzden cümle tartışma değil, dışlama olur.',
        ImplicitFamily.varlikReddi =>
          'Bir grubun var olma hakkını reddediyor. Bu ifade Türk Ceza '
              'Kanunu 216. madde kapsamına girebilir.',
        ImplicitFamily.tehdit =>
          'Fiziksel veya psikolojik şiddet içeren, karşı tarafa zarar verme kastı taşıyan bir ifade.',
        ImplicitFamily.kinaye =>
          'Sözde övgü gibi görünse de (kinaye/ironi), aslında karşı tarafı alaya alma ve aşağılama kastı taşıyor.',
        ImplicitFamily.kendineZararVerme =>
          'İntihar, kendine zarar verme veya umutsuzluk içeren riskli bir bağlam. Lütfen yardım almayı düşün.',
      };
}

/// Tek bir edimbilimsel örüntü.
class ImplicitPattern {
  /// Kararlı kimlik. Testlerde ve hata ayıklamada bu kullanılır;
  /// örüntü metni değişse de kimlik sabit kalır.
  final String id;

  /// Normalize metin üzerinde çalışan düzenli ifade.
  final RegExp pattern;

  final ImplicitFamily family;
  final ToxicityCategory category;

  /// Taban şiddet. Bağlam katmanı bunu artırıp azaltır.
  ///
  /// Örtük saldırı şiddetleri sözlük şiddetlerinden KASITLI olarak daha
  /// düşüktür: bu ifadeler daha belirsizdir ve yanlış pozitif maliyeti
  /// daha yüksektir. Tek istisna örtük tehdittir.
  final double severity;

  /// Yeniden yazma önerisinde kullanılacak nötr karşılık.
  final String? neutralAlternative;

  /// Örüntü, kimlik yuvasını bir GÖNDERGEYLE (anafora) doldurur; bu yüzden
  /// tek başına anlamsızdır ve yalnızca metnin daha önceki bir yerinde
  /// gerçek bir kimlik terimi geçtiyse bulgu üretmelidir.
  ///
  /// "Bunların soyunu kurutmak lazım" cümlesi tek başına kimin hedef
  /// alındığını söylemez. Önceki cümlede "Suriyeliler" geçtiyse söyler.
  /// Kapıyı `ImplicitDetector` uygular; örüntü yalnızca şartı beyan eder.
  final bool requiresIdentityAntecedent;

  /// Bu örüntünün DENENMESİ için metinde bulunması gereken değişmez kök.
  ///
  /// ── NEDEN VAR (İP-28) ────────────────────────────────────────────────────
  /// Deyim katmanı yüzlerce girdi taşır. Her tuş vuruşunda yüzlerce düzenli
  /// ifadeyi metnin tamamı üzerinde çalıştırmak, ürünün en sert kısıtını —
  /// 16 ms'lik kare bütçesini — tek başına yiyip bitirirdi.
  ///
  /// Deyimlerin bir avantajı vardır: her biri, o deyime özgü ve başka hiçbir
  /// yerde geçmeyen bir çekirdek kelime taşır ("takke", "çöplük", "yoğurt").
  /// Kapı kelimesi budur. Dedektör tek bir taramada metindeki bütün kapı
  /// kelimelerini toplar; hangi deyimin kapısı açıldıysa YALNIZCA o deyimin
  /// düzenli ifadesi çalıştırılır. Kapı kelimesi geçmeyen bir cümlede deyim
  /// katmanının maliyeti tek bir taramadır.
  ///
  /// Kök olarak yazılır, tam kelime olarak değil: Türkçe'de son ünsüz
  /// yumuşar ("çöplük" → "çöplüğünde"), bu yüzden değişmeyen ön ek alınır
  /// ("coplu"). Sözlük katmanındaki kök eşleşmesiyle aynı mantıktır.
  ///
  /// `null` ise örüntü her zaman denenir — kapı yalnızca bir hızlandırmadır,
  /// davranışı değiştirmesi bir hatadır ve `test/detector_gate_test.dart`
  /// bunu kapılı/kapısız iki çalıştırmayı karşılaştırarak denetler.
  final String? gateWord;

  const ImplicitPattern({
    required this.id,
    required this.pattern,
    required this.family,
    required this.category,
    required this.severity,
    this.neutralAlternative,
    this.requiresIdentityAntecedent = false,
    this.gateWord,
  });
}

/// Örüntü kataloğu.
abstract final class ImplicitPatterns {
  /// Düzenli ifade kısayolu — her örüntüde tekrar yazmamak için.
  static RegExp _re(String source) => RegExp(source, caseSensitive: false);

  // ── MORFOLOJİK TOLERANS ──────────────────────────────────────────────────
  // Ayrık küme ölçümü, kaçanların BÜYÜK ÇOĞUNLUĞUNUN tek bir kök nedene
  // dayandığını gösterdi: örüntüler Türkçe çekime karşı fazla katıydı.
  //
  //   "sesini kes"   yakalanıyordu
  //   "sesinizi kesin" yakalanMIYORDU   ← yalnızca çoğul emir eki yüzünden
  //
  // Bu, kelime ekleyerek çözülecek bir sorun değildir; çekim ekleri
  // örüntünün kendisinde karşılanmalıdır. Aşağıdaki parçalar bunun içindir.

  /// Emir kipi çoğul/nazik ekleri: kes → kesin/kesiniz
  static const String _emir = r'(?:in|iniz|un|unuz)?';

  /// Herhangi bir çekim eki kuyruğu.
  static const String _ek = r'\w*';

  /// Araya en fazla [n] kelime girebilir.
  /// "git kendine iş bul" ile "git kendine bir iş bul" aynı kalıptır.
  static String _bosluk(int n) => '(?:\\s+\\w+){0,$n}\\s+';

  static final List<ImplicitPattern> all = [
    // ── KENDİNE ZARAR VERME (Self-Harm Detection - Madde 29) ─────────────
    ImplicitPattern(
      id: 'kendineZarar.intihar_ima',
      pattern: _re(r'\b(yasamaya|hayata)\s+(dayanamiyorum|son verecegim|gucum kalmadi)\b'),
      family: ImplicitFamily.kendineZararVerme,
      category: ToxicityCategory.tehdit, // Acil durum uyarı seviyesi
      severity: 1.0, // En yüksek risk
    ),
    ImplicitPattern(
      id: 'kendineZarar.olmek',
      pattern: _re(r'\b(olmek|yok olmak)\s+(istiyorum)\b'),
      family: ImplicitFamily.kendineZararVerme,
      category: ToxicityCategory.tehdit,
      severity: 1.0,
    ),

    // ── KİNAYE VE İRONİ (Zero-Shot Sarcasm Detection) ───────────────────
    ImplicitPattern(
      id: 'kinaye.zeka_seviyesi',
      pattern: _re(r'\b(zeka|iq)\s+(seviyen|kapasiten|masallah)\b'),
      family: ImplicitFamily.kinaye,
      category: ToxicityCategory.asagilama,
      severity: 0.65,
    ),
    ImplicitPattern(
      id: 'kinaye.zavalli',
      pattern: _re(r'\b(ne kadar|cok)\s+(zavalli|bos|yazik|acinasi)\b'),
      family: ImplicitFamily.kinaye,
      category: ToxicityCategory.asagilama,
      severity: 0.60,
    ),

    // ═══ KÜÇÜMSEME ═══════════════════════════════════════════════════════════
    ImplicitPattern(
      id: 'kucumseme.yetkinlik_reddi',
      // Araya nesne girebilir: "sen BUNDAN ne anlarsın".
      pattern: _re(r'\b(sen|siz)\b' +
          _bosluk(2) +
          r'ne (anlarsin|anlarsiniz|bilirsin|bilirsiniz)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
      neutralAlternative: 'bu konuda farklı düşünüyorum',
    ),
    ImplicitPattern(
      // "anlamazsın" / "anlamazsınız" — öğrenme kapasitesinin reddi.
      id: 'kucumseme.anlamazsin',
      pattern: _re(r'\banlamazs(in|iniz)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
      neutralAlternative: 'anlatmakta zorlanıyorum',
    ),
    ImplicitPattern(
      id: 'kucumseme.harcin_degil',
      pattern: _re(r'\b(senin|sizin) (harc|hadd)(in|iniz) degil\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
      neutralAlternative: 'bu konu zor',
    ),
    ImplicitPattern(
      id: 'kucumseme.sana_gore_degil',
      pattern: _re(r'\b(sana|size) gore degil\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),
    ImplicitPattern(
      // "önce bir öğren de öyle konuş" / "git de biraz araştır"
      id: 'kucumseme.once_ogren',
      pattern: _re(r'\b(ogren|arastir|oku) de (oyle )?(konus|yaz)\b'
          r'|\bgit de (biraz )?(arastir|oku|ogren)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
      neutralAlternative: 'şu kaynağa bakmanı öneririm',
    ),
    ImplicitPattern(
      id: 'kucumseme.zaman_kaybi',
      // İP-19: eylem ve yönelim biçimleri çeşitlendi. Eski hâli YALNIZCA
      // "seninle tartışmak zaman kaybı" yazımını görüyordu; ölçümde
      // "sana anlatmak zaman kaybı" kaçtı.
      pattern: _re('\\b(seninle|sizinle|sana|size)\\b${_bosluk(2)}'
          r'(tartismak|anlatmak|konusmak|yazmak|ugrasmak) '
          r'(zaman kaybi|bosuna|anlamsiz|nafile|imkansiz)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
    ),
    ImplicitPattern(
      id: 'kucumseme.seviye',
      // İP-19: fiil çekimi açıldı ("inmeyeceğim", "inmem") ve seviye
      // üstünlüğünün ikinci kuruluşu eklendi ("bu seviyede biriyle").
      pattern: _re(r'\bseviye(ne|nize|sine) in\w+'
          r'|\bbu seviyede (biri|birisi|insan|kisi|tip)\w*'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      id: 'kucumseme.sorun_sende',
      pattern: _re(r'\bsorun (sende|sizde)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      id: 'kucumseme.anlatmak_nafile',
      // İP-19: "sana BİR ŞEY anlatmak nafile" — araya nesne girebiliyor.
      pattern: _re(r'\b(sana|size)\b' +
          _bosluk(2) +
          r'anlatmak (nafile|bosuna|imkansiz)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),

    // ═══ ÖTEKİLEŞTİRME ═══════════════════════════════════════════════════════
    ImplicitPattern(
      // "senin gibiler", "sizin gibilerden", "senin gibilerle"
      // KRİTİK: "senin gibi düşünenler" bu örüntüye DÜŞMEZ — "gibiler"
      // bitişik bir kelimedir, "gibi" + ayrı kelime değil.
      id: 'otekilestirme.gibiler',
      pattern: _re(r'\b(senin|sizin|onun|onlarin) gibiler'),
      family: ImplicitFamily.otekilestirme,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
      neutralAlternative: 'sen',
    ),
    ImplicitPattern(
      // "senin gibi insanlar/tipler/kişiler" — kapalı isim listesi.
      // Açık uçlu bırakılsaydı "senin gibi çalışkan birini" de yakalanırdı.
      id: 'otekilestirme.gibi_kategori',
      // `\w*` eki ŞART: Türkçe eklemeli bir dildir ve kategori adı çekime
      // girer — "tipler" değil "tiplerLE", "insanlar" değil "insanlarIN".
      // Kelime sınırıyla bitirmek en yaygın hâlleri kaçırıyordu.
      pattern: _re(
          r'\b(senin|sizin) gibi (insanlar|tipler|kisiler|adamlar|olanlar|yaratiklar)\w*'),
      family: ImplicitFamily.otekilestirme,
      category: ToxicityCategory.asagilama,
      severity: 0.52,
      neutralAlternative: 'sen',
    ),
    ImplicitPattern(
      id: 'otekilestirme.hep_boylesiniz',
      pattern: _re(r'\bhep (boylesiniz|boylesin|oylesiniz)\b'),
      family: ImplicitFamily.otekilestirme,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
    ),
    ImplicitPattern(
      // "hepiniz aynısınız" — "hepimiz" ile karışmaması kritik.
      id: 'otekilestirme.hepiniz_aynisiniz',
      pattern: _re(r'\bhepiniz (aynisiniz|ayni|birsiniz)\b'),
      family: ImplicitFamily.otekilestirme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      id: 'otekilestirme.baska_ne_beklenir',
      // İP-19: "beklenirDİ", "beklenebilir" — bileşik çekimler kaçıyordu.
      pattern: _re(r'\b(senden|sizden|onlardan|bunlardan) baska ne beklen\w+'),
      family: ImplicitFamily.otekilestirme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),

    // ═══ YOK SAYMA ═══════════════════════════════════════════════════════════
    ImplicitPattern(
      // "yine mi sen" — "yine mi bu hata" masumdur.
      id: 'yoksayma.yine_mi_sen',
      pattern: _re(r'\byine mi (sen|siz)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),
    ImplicitPattern(
      id: 'yoksayma.gec_bunlari',
      pattern: _re(r'\bgec (bunlari|sunlari|bu konulari)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.34,
    ),
    ImplicitPattern(
      id: 'yoksayma.bos_yapma',
      pattern: _re(r'\bbos (yapma|yapiyorsun|konusma)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      id: 'yoksayma.sacmalama',
      pattern: _re(r'\bsacmalama\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
      neutralAlternative: 'katılmıyorum',
    ),
    ImplicitPattern(
      // "sana ne" YALNIZCA cümle sonunda veya bir edatla biterse.
      // "sana ne getireyim marketten" bu kurala takılmaz.
      id: 'yoksayma.sana_ne',
      pattern: _re(r'\b(sana|size) ne\s*(ki|be|ya|canim)?\s*$'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      // "sen karışma" — "sen karışmasan da olur" takılmaz (kelime sınırı).
      id: 'yoksayma.sen_karisma',
      pattern: _re(r'\b(sen|siz) (karisma|karismayin)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      id: 'yoksayma.ilgilendirmez',
      pattern: _re(r'\b(seni|sizi) ilgilendirmez\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      id: 'yoksayma.kimse_sormadi',
      pattern: _re(r'\bkimse (sormadi|sormuyor)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      id: 'yoksayma.biktim_senden',
      pattern: _re(r'\bbiktim (senden|sizden|artik senden)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),

    // ═══ SUSTURMA ════════════════════════════════════════════════════════════
    ImplicitPattern(
      id: 'susturma.sesini_kes',
      pattern: _re(r'\b(sesini|sesinizi) kes' + _emir + r'\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.52,
      neutralAlternative: 'sözümü bitirebilir miyim',
    ),
    ImplicitPattern(
      // Sözlükteki "kapa çeneni" öbeğinin devrik hâli.
      id: 'susturma.ceneni_kapat',
      pattern: _re(r'\b(ceneni|cenenizi) (kapat|kapa)' + _emir + r'\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.55,
    ),
    ImplicitPattern(
      // Sözlükteki "haddini bil" varyantı.
      id: 'susturma.haddini_asma',
      pattern: _re(r'\bhaddin(i|izi) (asma|asmayin|asiyorsun|asiyorsunuz|bilmiyorsun)' + _ek + r'\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
    ),
    ImplicitPattern(
      // Sözlükteki "sen kimsin" varyantı.
      id: 'susturma.kim_oluyorsun',
      pattern: _re(r'\b(sen|siz) kim oluyorsun(uz)?\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
    ),
    ImplicitPattern(
      id: 'susturma.boyle_konusma',
      pattern: _re(r'\bbenimle (bu sekilde|boyle|bu tonda) konusma\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.30,
    ),

    // ═══ AŞAĞILAYICI EMİR ════════════════════════════════════════════════════
    ImplicitPattern(
      id: 'yoksayma.git_is_bul',
      pattern: _re(r'\bgit\b' + _bosluk(3) + r'is bul' + _emir + r'\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      id: 'yoksayma.otur_yerinde',
      pattern: _re(r'\botur (oturdugun|oturdugunuz) yerde\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      id: 'yoksayma.isine_bak',
      pattern: _re(r'\bis(ine|inize) bak' + _emir + r'\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      id: 'yoksayma.aynaya_bak',
      pattern: _re(r'\baynaya bak' + _emir + r'\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),

    // ═══ KARAKTER SALDIRISI (küfürsüz) ═══════════════════════════════════════
    ImplicitPattern(
      id: 'karakter.adam_olmaz',
      pattern: _re(r'\b(senden|sizden) adam olmaz\b|\b(sen|siz) adam olmaz(sin|siniz)\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.58,
      neutralAlternative: 'bu davranışını doğru bulmuyorum',
    ),
    ImplicitPattern(
      // "işe yaramazsın" — "bu çözüm işe yaramaz" masumdur, çünkü
      // örüntü ikinci şahıs ekini ZORUNLU kılar.
      id: 'karakter.ise_yaramazsin',
      pattern: _re(r'\bise yaramaz(sin|siniz)\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.55,
    ),
    ImplicitPattern(
      // "hiçbir halt beceremiyorsun" / "bir bok beceremiyorsun"
      // Ayrık kümede hiç görülmemiş bir yapıydı; kalıp olarak eklendi.
      id: 'karakter.beceremiyorsun',
      pattern: _re(r'\b(hicbir halt|bir halt|bir bok|hicbir sey) becer' + _ek + r'\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.55,
    ),
    ImplicitPattern(
      // Susturma emri — sözlükten buraya taşındı.
      //
      // "sus" sözlükte tam eşleşmeli bir terimdi ve "SUS payı vermişler"
      // cümlesini yanlış pozitif yapıyordu. Susturma emri konum bilgisi
      // taşır: yüklem olarak, tümce sonunda kurulur. Sözlük bu bilgiyi
      // taşıyamaz, örüntü taşır.
      id: 'susturma.sus',
      pattern: _re(r'\b(sus|susun|sussana|sussaniza|sussanize)\b'
          r'\s*(artik|ya|be|lan|biraz)?\s*!?$'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),
    ImplicitPattern(
      id: 'karakter.baltaya_sap',
      pattern: _re(r'\bbir baltaya sap ol\w*\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.52,
    ),
    ImplicitPattern(
      id: 'karakter.senin_yuzunden',
      pattern: _re(r'\b(senin|sizin) yuzunden\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.30,
      neutralAlternative: 'bu durumda',
    ),

    // ═══ ALAYCILIK ═══════════════════════════════════════════════════════════
    // En zor sınıf. Övgü sözcüğü TEK BAŞINA yeterli değildir; bir alay
    // parçacığı ("valla", "gerçekten") eşlik etmelidir. Aksi hâlde içten
    // takdir cezalandırılır.
    ImplicitPattern(
      id: 'alayci.helal_olsun_valla',
      pattern: _re(r'\bhelal olsun\b[^!]{0,20}\b(valla|vallahi|bee?)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.36,
    ),
    ImplicitPattern(
      id: 'alayci.aferin_valla',
      pattern: _re(r'\baferin\b[^!]{0,20}\b(valla|vallahi|bee?)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.36,
    ),
    ImplicitPattern(
      // "bravo" + alay parçacığı. "gerçekten çok başarılısın, tebrikler"
      // içinde "bravo" olmadığı için takılmaz.
      id: 'alayci.bravo',
      pattern: _re(
          r'\b(gercekten|valla|vallahi|hakikaten)\b[^!]{0,40}\bbravo\b|\bbravo\b[^!]{0,40}\b(gercekten|valla|vallahi)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),
    ImplicitPattern(
      // "ne kadar da zekisin/akıllısın" — abartı kalıbı.
      id: 'alayci.ne_kadar_da',
      pattern: _re(r'\bne kadar da \w+s(in|iniz)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),
    ImplicitPattern(
      id: 'alayci.vay_be',
      pattern: _re(r'\bne buyuk (kesif|basari|zafer|zeka)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.34,
    ),

    // ═══ ÖRTÜK TEHDİT ════════════════════════════════════════════════════════
    // Tek yüksek şiddetli örtük sınıf. Güvenlik kaygısı yarattığı için
    // "dikkat" değil doğrudan "riskli/yüksek" bandına düşmeli.
    ImplicitPattern(
      id: 'tehdit.gununu_goreceksin',
      pattern: _re(r'\bgununu gor' + _ek + r'\b|\bgor' + _ek + r' gununu\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.65,
    ),
    ImplicitPattern(
      id: 'tehdit.yanina_kalmaz',
      pattern: _re(r'\byanin(a|iza) (kalmaz|kar kalmaz|kar kalmayacak|kalmayacak)\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.62,
    ),
    ImplicitPattern(
      id: 'tehdit.hesabini_sorarim',
      pattern: _re(r'\bhesabin(i|izi) sor\w*\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.62,
    ),
    ImplicitPattern(
      // "görüşürüz seninle" tehdittir; "görüşürüz, iyi akşamlar" değildir.
      // Ayrım TAM OLARAK ikinci şahıs vasıta hâlinin varlığıdır.
      id: 'tehdit.gorusuruz_seninle',
      pattern: _re(r'\bgorusuruz (seninle|sizinle)\b|\b(seninle|sizinle) gorusec' + _ek + r'\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.60,
    ),
    ImplicitPattern(
      id: 'tehdit.bulasma',
      pattern: _re(r'\b(bana|bize) bulasma\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.58,
    ),
    ImplicitPattern(
      id: 'tehdit.sonun_iyi_olmaz',
      pattern: _re(r'\bsonun (iyi olmayacak|iyi olmaz|kotu olacak)\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.65,
    ),
    ImplicitPattern(
      id: 'tehdit.beni_tanimiyorsun',
      pattern: _re(r'\bbeni (tanimiyorsun|taniyor musun)\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.58,
    ),

    // ═══ İP-19 · GENELLEME ONARIMI ═══════════════════════════════════════════
    // Aşağıdaki örüntüler, İP-15 ikinci ayrık kümesindeki 22 kaçağın
    // taksonomisinden üretildi. Her biri TEK BİR CÜMLEYİ değil, o cümlenin
    // temsil ettiği EDİMBİLİMSEL KURULUŞU hedefler — aksi hâlde katman
    // yeniden ezberlemeye döner ve bir sonraki ayrık kümede yine kaçırır.
    //
    // ⚠ MALİYET BEYANI: bu örüntüler İP-15 kümesine BAKILARAK yazıldı.
    //   O küme bu andan itibaren YANMIŞTIR ve bir daha "ayrık" olarak
    //   raporlanamaz. Onarım sonrası dürüst ölçüm, aynı protokolle yazılan
    //   üçüncü kümeye (İP-20) aittir.

    ImplicitPattern(
      // "senin kafan basmaz bunlara" — deyimsel yetersizlik atfı.
      id: 'kucumseme.kafan_basmaz',
      pattern: _re(r'\bkafa(n|niz|si) bas(maz|miyor)\w*'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
      neutralAlternative: 'bu konu karmaşık',
    ),
    ImplicitPattern(
      // "ağzından çıkanı kulağın duyuyor mu" — muhakeme yetisinin reddi.
      id: 'kucumseme.agzindan_cikan',
      pattern: _re(r'\bagzindan cikani kulag(in|iniz) duy\w+'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      // "bu ne cehalet" · "cehaletin konuşuyor" — kusuru kişiye atfetme.
      // Yakın-kaçış: "cehaletle mücadele" kalıba DÜŞMEZ; ya bir niteleme
      // ünlemi ya da bir atfetme yüklemi şarttır.
      id: 'kucumseme.cehalet_atfi',
      pattern: _re(r'\b(bu )?ne (cehalet|cahillik|aptallik)\b'
          r'|\b(cehaletin|cahilligin|egitimsizligin|kompleksin) konus\w+'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      // "kim sordu ki senin fikrini" · "konuşan da kim" — muhataplığın reddi.
      // "kim sordu" tek başına bir bilgi sorusu olabilir; ikinci şahıs
      // göstergesi ya da "konuşan da kim" kuruluşu şarttır.
      id: 'yoksayma.kim_sordu',
      pattern: _re(r'\bkim sordu\b(?=.{0,30}\b(sen|senin|sana|siz|sizin|size)\b)'
          r'|\b(konusan|yazan) da kim\b'
          r'|\bsana mi sorduk\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
    ),
    ImplicitPattern(
      // "sen önce kendine bak" — karşı suçlamayla muhataplığı reddetme.
      id: 'yoksayma.once_kendine_bak',
      pattern: _re(r'\b(sen |siz )?once (bir )?kendi(ne|nize) bak\w*'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      // "sana kalmış bir konu değil" — yetkisizleştirme, nazik yüzeyli.
      id: 'yoksayma.sana_kalmis_degil',
      pattern: _re(r'\b(sana|size) kalmis\b' + _bosluk(2) + r'degil\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      // "seninle konuşmaya değmez" · "sana laf anlatılmaz".
      id: 'yoksayma.degmez',
      pattern: _re(r'\b(seninle|sizinle) (konusmaya|tartismaya) degmez\b'
          r'|\b(sana|size) laf anlatilmaz\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.44,
    ),
    ImplicitPattern(
      // "sus da adam konuşsun" — susturma + insan yerine koymama.
      // `susturma.sus` yalnızca tümce SONUNU görüyordu.
      id: 'susturma.sus_da',
      pattern: _re(r'\b(sus|susun) da\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      // "senin yerinde olsam susardım" — öğüt kılığında susturma.
      id: 'susturma.yerinde_olsam',
      pattern: _re(r'\b(senin|sizin) yerinde olsam\b' +
          _bosluk(2) +
          r'(susar|konusmaz|yazmaz)\w*'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      // "sana had bildiririm" — `susturma.haddini_asma` kalıbının tehdit
      // yüzü; farklı çekim, farklı yüklem.
      id: 'susturma.had_bildiririm',
      pattern: _re(r'\bhad(dini|dinizi)? bildir\w+'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
    ),
    ImplicitPattern(
      // "burada senin gibilere yer yok" — dışlama.
      // NOT: `otekilestirme.gibiler` bu cümleyi zaten eşleştiriyordu; kaçağın
      // asıl sebebi bağlam katmanındaki varlık olumsuzlaması hatasıydı
      // (bkz. context_analyzer.dart, `_existentialNegators`). Bu örüntü
      // kuruluşu ayrıca adlandırır ve gerekçeyi doğru aileye bağlar.
      id: 'otekilestirme.yer_yok',
      pattern: _re(r'\b(senin|sizin) gibiler\w*' +
          _bosluk(2) +
          r'(yer|isi|yeri) yok\b'),
      family: ImplicitFamily.otekilestirme,
      category: ToxicityCategory.asagilama,
      severity: 0.52,
    ),
    ImplicitPattern(
      // "bu yazdığın tam senlik" — kişiye indirgeyen alay.
      id: 'alayci.tam_senlik',
      pattern: _re(r'\btam (senlik|sizlik)\b'
          r'|\bsenden beklenen\w* (bu|buydu)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.44,
    ),
    ImplicitPattern(
      // "acıdım sana gerçekten" — acıma yoluyla aşağılama.
      // Yakın-kaçış: samimi acıma da bu kalıba düşer. Şiddet bu yüzden
      // KASITLI olarak dikkat düzeyinde tutuldu; öneri değil, sessiz ipucu.
      id: 'alayci.acidim_sana',
      pattern: _re(r'\b(acidim|aciyorum) (sana|size)\b'
          r'|\b(sana|size) (acidim|aciyorum)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.32,
    ),
    ImplicitPattern(
      // "hadi canım sen de" — muhatabı ciddiye almama jesti.
      id: 'alayci.hadi_canim_sen_de',
      pattern: _re(r'\bhadi (canim|be) (sen|siz) de\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.35,
    ),
    ImplicitPattern(
      // "bir de utanmadan savunuyorsun" — utandırma.
      id: 'karakter.utanmadan',
      pattern: _re(r'\b(bir de )?utanmadan\b' +
          _bosluk(2) +
          r'\w+(yorsun|yorsunuz|din|diniz)\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.44,
    ),
    ImplicitPattern(
      // "kendini bir halt sanıyorsun" — kaba deyim, küfür sınırında.
      id: 'karakter.bir_halt',
      pattern: _re(r'\bkendini (bir sey|bir halt|adam) san\w+'
          r'|\bhalt (yedin|yiyorsun|karistirdin)\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.52,
    ),
    ImplicitPattern(
      // "adam gibi konuşmayı öğren" — terbiye etme kuruluşu.
      // Yakın-kaçış: "adam gibi bir iş buldum" kalıba DÜŞMEZ; ikinci şahsa
      // yönelik emir ya da öğrenme yüklemi şarttır.
      id: 'karakter.adam_gibi',
      pattern: _re(r'\badam gibi (konusmayi|davranmayi|yazmayi) ogren\w*'
          r'|\badam gibi (konus|davran|yaz)(un|sana|sanize)?\b'
          r'|\badam olmayi ogren\w*'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
    ),
    ImplicitPattern(
      // "kafanı kırarım" — sözlükte olmayan tehdit fiili ailesi.
      id: 'tehdit.kafani_kirarim',
      pattern: _re(r'\bkafa(ni|nizi) (kirarim|patlatirim|dagitirim|kopartirim)\b'
          r'|\b(dislerini|kemiklerini) (kirarim|dokerim)\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.85,
    ),
    ImplicitPattern(
      // "seni bulurum merak etme" — sözlükteki "bulurum seni" devrik hâli.
      id: 'tehdit.seni_bulurum',
      pattern: _re(r'\b(seni|sizi) bulurum\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.80,
    ),

    // ═══ İP-21 · DEYİM KAPSAMI (yapısal aileler) ═════════════════════════════
    // İP-20 ölçümü, kaçakların çoğunun DEYİM olduğunu gösterdi. Buradaki
    // yanıt "19 deyimi tek tek yazmak" DEĞİLDİR — o, ezberlemenin üçüncü
    // turu olurdu. Onun yerine her aile, deyimin dayandığı YAPIYI hedefler
    // ve o yapının kapalı bir sözvarlığıyla parametrelenir:
    //
    //   yapı                                sözvarlığı
    //   ─────────────────────────────────   ─────────────────────────────
    //   [2.şahıs]da [nitelik] mı var        soyut nitelik adları
    //   [kapasite adı] bu kadar             kapasite adları
    //   [kapasite adı]nı aşan               kapasite adları
    //
    // Sözvarlıkları soyut ad sınıflarıdır, cümle listesi değil: yeni bir
    // deyim aynı yapıyı kullanıyorsa örüntü onu da görür.
    //
    // ⚠ MALİYET BEYANI: İP-20 kümesi bu onarımda kullanıldı ve YANDI.
    //   Onarım sonrası dürüst ölçüm, dördüncü kümeye (İP-22) aittir.

    ImplicitPattern(
      // "haddini bil" — susturma emri. Sözlükten buraya taşındı (İP-22).
      //
      // Kritik ayrım SAĞ SINIRDIR: emir kipi işaretlenir, sıfat-fiil
      // işaretlenMEZ. Sözlüğün ifade eşleşmesi bu ayrımı yapamıyordu,
      // çünkü Türkçe eklemeli olduğu için ifade eşleşmesi kasıtlı olarak
      // sağ sınır aramaz ("işe yaramaz" girdisi "işe yaramazsın"ı da
      // görmek zorundadır). Bu terimde ise ek, anlamı TERSİNE çeviriyordu:
      //
      //   "haddini bil"            → susturma emri        ✓
      //   "haddini bilen insanlar" → ÖVGÜ, işaretleniyordu ✗
      id: 'susturma.haddini_bil',
      pattern: _re(r'\bhadd(ini|inizi) bil\b|\bhaddinizi bilin\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.55,
    ),
    ImplicitPattern(
      // "sende akıl mı var" · "sizde vicdan mı var" · "sende utanma yok"
      //
      // Muhatabın bir SOYUT NİTELİĞE sahip olduğunu reddeder. Ad sınıfı
      // kapalıdır ve kasıtlı olarak yalnızca ahlaki/bilişsel nitelikleri
      // içerir — somut ad girerse kalıp düşmez:
      //   "sende kalem mi var"  → gerçek bir soru, işaretlenmez
      id: 'kucumseme.nitelik_reddi',
      pattern: _re(r'\b(sende|sizde)\b\s+'
          r'(akil|vicdan|utanma|ar|haya|beyin|karakter|insaf|izan|edep|'
          r'terbiye|saygi|onur|seref|gurur|mantik|ahlak|kafa|zeka)\w*\s+'
          r'(mi|mu) (var|kalmis|kalmadi)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
      neutralAlternative: 'bu yaklaşımı doğru bulmuyorum',
    ),
    ImplicitPattern(
      // "senin çapın bu kadar" · "kapasiten bu kadar" · "seviyen o kadar"
      //
      // Muhatabın yetenek TAVANINI ilan eder. Kapasite adları kapalı bir
      // sınıftır; "boyun bu kadar" fiziksel ölçü de olabileceği için
      // `boy` bu kalıba ALINMADI (aşağıdaki `haddini_asan`da var).
      id: 'kucumseme.kapasite_tavani',
      pattern: _re(r'\b(senin |sizin )?'
          r'(capin|capiniz|kapasiten|kapasiteniz|seviyen|seviyeniz|'
          r'haddin|haddiniz|ayarin|ayariniz|tipin)\b\s+'
          r'(bu|o|iste bu|ancak bu) kadar\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      // "boyunu aşan işlere karışma" · "haddini aşan bir laf"
      //
      // Muhatabın yetki sınırını ilan eder. `susturma.haddini_asma`nın
      // sıfat-fiil hâli; o örüntü yalnızca yüklem biçimini görüyordu.
      id: 'susturma.haddini_asan',
      pattern: _re(r'\b(boyunu|boyunuzu|haddini|haddinizi|capini) as(an|arak)\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.46,
    ),
    ImplicitPattern(
      // "iki çift laf edemiyorsun" · "bir yere varamazsın" · "bu işi
      // beceremezsin"
      //
      // Türkçe YETERSİZLİK çekimi (-ama/-eme) ikinci şahısta muhatabın
      // yapabilirliğini reddeder. Çekimin kendisi TEK BAŞINA yeterli
      // DEĞİLDİR — "yarın gelemezsin" bir bilgi cümlesidir. Bu yüzden
      // kalıp, çekimi bir DEĞERLENDİRME NESNESİNE bağlar: laf, iş,
      // bir yere, hiçbir şey. Nesne yoksa bulgu da yok.
      id: 'kucumseme.yetersizlik_cekimi',
      pattern: _re(r'\b(laf|kelam|cumle|is|isin|bir yere|hicbir yere|'
          'hicbir sey|adam)\\b${_bosluk(3)}'
          r'\w*(?:[ae]m[ei]yorsun|[ae]mezsin|[ae]m[ei]yorsunuz|[ae]mezsiniz)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
    ),
    ImplicitPattern(
      // "sen ne biçim insansın" · "sen ne ayaksın"
      // KRİTİK: "sen ne güzelsin" bir iltifattır. Bu yüzden açık uçlu
      // `sen ne \w+sin` ALINMADI; yalnızca "ne biçim" kuruluşu ve kapalı
      // bir argo listesi alındı.
      id: 'kucumseme.ne_bicim',
      pattern: _re(r'\bne bicim (insan|adam|tip|birisin|birisiniz)\w*'
          r'|\bsen ne (ayaksin|malsin|tipsin)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      // "yazık sana yazık" — acıma yoluyla aşağılama, `alayci.acidim_sana`
      // ailesinin ikinci sözcüğü.
      id: 'alayci.yazik_sana',
      pattern: _re(r'\byazik (sana|size)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.34,
    ),
    ImplicitPattern(
      // "hava atma bize" · "büyük konuşuyorsun" · "caka satma"
      // Böbürlenme suçlaması: muhatabın söylediğini içeriğiyle değil,
      // niyetiyle reddeder.
      id: 'yoksayma.bobürlenme_suclamasi',
      pattern: _re(r'\b(hava atma|caka satma|racon kesme)\b'
          r'|\bbuyuk (konusuyorsun|konusma|konusuyorsunuz)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      // "seninki de laf mı" — katkının tür olarak reddi.
      id: 'yoksayma.seninki_de',
      pattern: _re(r'\b(seninki|sizinki|bu dedigin|bu yazdigin) de '
          r'(laf|fikir|yorum|is|soz) mi\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.44,
    ),
    ImplicitPattern(
      // "senden bana fayda yok" · "sizden bize hayır yok"
      id: 'yoksayma.fayda_yok',
      pattern: _re(r'\b(senden|sizden)\b' +
          _bosluk(2) +
          r'(fayda|hayir|medet) yok\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.44,
    ),
    ImplicitPattern(
      // "gözüm görmesin seni" — ortamdan çıkarma isteği (kimlik yuvasız).
      id: 'otekilestirme.gozum_gormesin',
      pattern: _re(r'\bgozum gormesin\b|\bgozume gorunme\b'),
      family: ImplicitFamily.otekilestirme,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
    ),
    ImplicitPattern(
      // "salağa yatma" · "aptala yatma" — muhatabı numara yapmakla suçlarken
      // aynı anda o sıfatı yakıştırır.
      id: 'karakter.salaga_yatma',
      pattern: _re(r'\b(salaga|aptala|deliye|manyaga|kaz(a|i)ga) yat\w+'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.50,
    ),

    // ═══ İNKÂR KALIBI ════════════════════════════════════════════════════════
    // "X demiyorum ama..." — hakareti inkâr ederek söyleme yolu.
    // Bağlam katmanı bu cümlelerde olumsuzlama gördüğü için sözlük
    // eşleşmesini yumuşatır; bu örüntü açığı kapatır.
    ImplicitPattern(
      id: 'inkar.demiyorum_ama',
      pattern: _re(r'\b(demiyorum|demek istemem|demeyecegim) (ama|fakat|de)\b'),
      family: ImplicitFamily.inkarKalibi,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      id: 'inkar.demem_ama',
      pattern: _re(r'\bdemem ama\b|\bdemek istemiyorum ama\b'),
      family: ImplicitFamily.inkarKalibi,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),

    // ═══ İP-25 · MOTOR GENİŞLETMESİ (Eylül 2026) ═══════════════════════════
    // İstanbul Küme Vakfı testleri ve gerçek dünya kullanımında kaçan
    // edimbilimsel kalıplar. Her biri bir CÜMLEYİ değil, o cümlenin
    // temsil ettiği EDİMBİLİMSEL KURULUŞU hedefler.

    // ── BEDDUA KALIPLARI ──────────────────────────────────────────────────
    // Türkçe sosyal medyada çok yaygın, hiçbir platformda filtrelenmez.
    // Meşru kullanımı yoktur — Allah'a dua etmek ile birine beddua etmek
    // yapısal olarak farklıdır: beddua İKİNCİ ŞAHSA yöneliktir.
    ImplicitPattern(
      // "allah belanı versin" / "allah cezanı versin" / "allah kahretsin"
      id: 'beddua.allah_belani',
      pattern: _re(r'\ballah\b' +
          _bosluk(1) +
          r'(belani|cezani|kahretsin|canini alsin|batirsin)' + _ek + r'\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.55,
    ),
    ImplicitPattern(
      // "cehenneme kadar yolun var" / "cehennemin dibi boylasın"
      id: 'beddua.cehennem',
      pattern: _re(r'\bcehennem' + _ek + r'\b' +
          _bosluk(2) +
          r'(yolun|dibi|kadar)' + _ek + r'\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.52,
    ),

    // ── DEYİMSEL HAKARET ──────────────────────────────────────────────────
    ImplicitPattern(
      // "iki paralık adam" / "beş kuruşluk adam" — değersizleştirme deyimi.
      // Yakın-kaçış: "iki paralık eşya" kalıba DÜŞMEZ — kapalı isim listesi.
      id: 'kucumseme.paralik_adam',
      pattern: _re(r'\b(iki|uc|bes|on) (paralik|kurusluk|liralık)\b' +
          _bosluk(1) +
          r'(adam|herif|insan|tip|kisi)' + _ek + r'\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      // "yüzüne tüküreyim" / "yüzüne tükürseler" — ağır aşağılama.
      id: 'karakter.yuzune_tukur',
      pattern: _re(r'\byuzun(e|uze) tukur' + _ek + r'\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.70,
    ),
    ImplicitPattern(
      // "aklını peynir ekmekle mi yedin" — deyimsel yetersizlik atfı.
      id: 'kucumseme.aklini_peynir_ekmekle',
      pattern: _re(r'\baklin(i|izi) peynir ekmekle' + _bosluk(1) +
          r'(mi |mu )?ye' + _ek + r'\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
      neutralAlternative: 'bu kararı anlamakta zorlanıyorum',
    ),

    // ── AGRESİF SORGULAMA ─────────────────────────────────────────────────
    ImplicitPattern(
      // "senin derdin ne" — yok sayma/küçümseme. Karşındakinin kaygısını
      // bir problem olarak çerçeveler.
      // Yakın-kaçış: "derdin ne kadar büyük" kalıba DÜŞMEZ (çekim farkı).
      id: 'yoksayma.derdin_ne',
      pattern: _re(r'\b(senin|sizin) derdin(iz)? ne\b\s*(ki|be|ya|lan)?\s*[?!]?\s*$'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      // "sana ne oluyor" / "sana ne oluyorsa" — muhatabın tepkisini
      // patolojikleştirme.
      id: 'yoksayma.sana_ne_oluyor',
      pattern: _re(r'\b(sana|size) ne oluyor' + _ek + r'\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),

    // ── UTANDIRMA / TERBIYE ETME ──────────────────────────────────────────
    ImplicitPattern(
      // "terbiyeni takın" / "terbiyeni takınız" — emir kipi susturma.
      id: 'susturma.terbiyeni_takin',
      pattern: _re(r'\bterbiye(ni|nizi) tak' + _emir + r'\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      // "ağzını topla" / "ağzınızı toplayın" — susturma.
      id: 'susturma.agzini_topla',
      pattern: _re(r'\bagz(ini|inizla|inizl|inizi) topla' + _emir + r'\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.52,
    ),
    ImplicitPattern(
      // "ne ayıp" / "ayıp değil mi" — utandırma.
      // Yakın-kaçış: "ayıp olur" kalıba DÜŞMEZ — ikinci şahıs yönelimi yok.
      id: 'karakter.ne_ayip',
      pattern: _re(r'\bne ayip\b|\bayip degil mi\b|\butanmiyor musun\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),

    // ── KİNAYE VE İRONİ (Zero-Shot Sarcasm) ───────────────────────────────
    ImplicitPattern(
      // "zeka fışkırıyor" / "zekan taşıyor" — sözde övgü, gerçekte aşağılama.
      id: 'kinaye.zeka_fiskiriyor',
      pattern: _re(r'\bzeka(si|niz|n)? (fiskir|tas)' + _ek + r'\b'),
      family: ImplicitFamily.kinaye,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
      neutralAlternative: 'fikrinize katılmıyorum',
    ),
    ImplicitPattern(
      // "çok zekisin ya" / "ne kadar zekisin be" — cümlenin sonundaki parçacıklar alay atfı taşır.
      id: 'kinaye.cok_zekisin_ya',
      pattern: _re(r'\b(cok|ne kadar da|masallah) (zeki|akilli)sin( ya| be)\b'),
      family: ImplicitFamily.kinaye,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      // "bizim dahi" / "sayın dahi" / "einstein mısın"
      id: 'kinaye.dahi_benzetmesi',
      pattern: _re(r'\b(bizim dahi|sayin dahi|einstein( misin| misiniz)?)\b'),
      family: ImplicitFamily.kinaye,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      // "aferin çok büyük iş yaptın" / "ayakta alkışlıyorum" — sahte onaylama.
      id: 'kinaye.sahte_alkis',
      pattern: _re(r'\b(ayakta alkisliyorum|buyuk is yaptin(iz|)\b|aferin sana\b)'),
      family: ImplicitFamily.kinaye,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),

    // ═══ İP-26 · DEYİM AİLELERİ (12 Eylül 2026) ════════════════════════════
    //
    // ── NEDEN BU GENİŞLETME ───────────────────────────────────────────────
    // Dört ayrık kümenin ortak bulgusu tekti ve motorun bir kusuru değildi:
    // duyarlılık, YAZILMIŞ AİLE SAYISIYLA sınırlı. İP-22 ölçümünde yazılmış
    // ailelerin hiç görülmemiş örneklerinde duyarlılık %90,0 iken hiç
    // yazılmamış ailelerde %6,7 çıktı. Yani yapılacak iş algoritma işi
    // değil, VERİ işiydi ve bu blok o işin karşılığıdır.
    //
    // ── BEDELİ AÇIKÇA YAZILIYOR ───────────────────────────────────────────
    // Bu blok yazılırken İP-22'nin kaçırdıkları OKUNDU. Dolayısıyla İP-22
    // artık bir genelleme ölçümü DEĞİLDİR — önceki üç küme gibi YANMIŞTIR.
    // Bunu gizlemek mümkündü (kaçanların çoğu zaten genel Türkçe deyimidir
    // ve bakmadan da yazılabilirdi) ama ölçüm disiplini "bakmadım" demenin
    // değil, "baktım" demenin üstüne kurulur.
    //
    // Yerine yazılan taze küme: `eval/generalization4_dataset.dart` (İP-27).
    // Geçerli genelleme sayısı oradan okunur.
    //
    // ── SEÇİM ÖLÇÜTÜ ──────────────────────────────────────────────────────
    // Her aile, Türkçe'de KALIPLAŞMIŞ ve muhataba yöneldiğinde tek işlevi
    // değersizleştirmek olan bir deyimdir. Deyimin meşru bir okuması varsa
    // (örn. "kendine gel" bir arkadaşı sarsmak için de kullanılır) şiddeti
    // eşiğin hemen altında tutuldu: tek başına müdahale üretmez, başka bir
    // bulguyla birleşince skoru yukarı iter.

    // ── AKIL SAĞLIĞI İMASI ────────────────────────────────────────────────
    ImplicitPattern(
      // "kafayı yemişsin" · "kafayı sıyırmışsın" · "kafayı üşütmüşsün"
      // Yakın-kaçış: "kafayı bu işe taktım" — kapalı fiil listesi.
      id: 'karakter.kafayi_yemis',
      pattern: _re(r'\bkafayi (yemis|siyirmis|usutmus|bulmus)' + _ek + r'\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.52,
      neutralAlternative: 'bu yaklaşımı hiç anlamıyorum',
    ),
    ImplicitPattern(
      // "kendine gel" · "aklını başına al" · "aklını başına devşir"
      // Meşru kullanımı vardır (endişeli bir uyarı); şiddet düşük tutuldu.
      id: 'karakter.kendine_gel',
      pattern: _re(r'\bkendine gel\b|\bakl(ini|inizi) bas(ina|iniza) (al|devsir)' +
          _emir + r'\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.34,
    ),
    ImplicitPattern(
      // "tedavi ol" · "doktora görün" — akıl sağlığını hakaret aracı yapar.
      // Yakın-kaçış: "doktora göründün mü" (soru, tavsiye) kalıba düşmez:
      // emir kipi ve cümle sonu şart.
      id: 'karakter.tedavi_ol',
      pattern: _re(r'\b(tedavi ol|doktora gorun|ilaclarini al)' + _emir +
          r'\b\s*[.!]?\s*$'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.55,
    ),

    // ── KİBİR SUÇLAMASI ───────────────────────────────────────────────────
    ImplicitPattern(
      // "burnu havada" · "burnun havada geziyorsun"
      // Yakın-kaçış: "burnu kanadı" — kapalı "havada" şartı.
      id: 'karakter.burnu_havada',
      pattern: _re(r'\bburn(u|un|unuz) havada\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      // "kendini bir şey sanıyorsun" · "ne sanıyorsun kendini"
      id: 'karakter.kendini_bir_sey_saniyor',
      pattern: _re('\\bkendin(i|izi) (bir sey|adam|dahi|allah) san$_ek\\b'
          r'|\bne san(iyorsun|iyorsunuz) kendin(i|izi)\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
      neutralAlternative: 'bu konuda aynı fikirde değiliz',
    ),
    ImplicitPattern(
      // "havalara girme" · "havalanma" (ikinci şahıs emir)
      id: 'karakter.havalara_girme',
      pattern: _re(r'\bhavalara girm' + _ek + r'\b|\bhavalanma' + _emir + r'\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.asagilama,
      severity: 0.32,
    ),

    // ── EMEĞİ / İÇERİĞİ DEĞERSİZLEŞTİRME ──────────────────────────────────
    ImplicitPattern(
      // "boşa kürek çekiyorsun" · "boşuna kürek çekme"
      id: 'kucumseme.bosa_kurek',
      pattern: _re(r'\b(bosa|bosuna) kurek cek' + _ek + r'\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
      neutralAlternative: 'bu yolun sonuç vereceğine inanmıyorum',
    ),
    ImplicitPattern(
      // "ipe sapa gelmez şeyler konuşuyorsun"
      id: 'kucumseme.ipe_sapa_gelmez',
      pattern: _re(r'\bipe sapa gelmez\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
      neutralAlternative: 'söylediklerini takip edemiyorum',
    ),
    ImplicitPattern(
      // "laf ebeliği yapma" · "laf cambazlığı" · "laf kalabalığı yapma"
      id: 'yoksayma.laf_ebeligi',
      pattern: _re(r'\blaf (ebeligi|cambazligi|kalabaligi|salatasi)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.44,
    ),
    ImplicitPattern(
      // "boş yapma" · "boş konuşma" · "boş boş konuşma"
      // Yakın-kaçış: "boş bir sayfa" — fiil listesi kapalı.
      id: 'yoksayma.bos_yapma',
      pattern: _re(r'\bbos (bos )?(yapma|konusma|sallama)' + _emir + r'\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      // "hava civa" · "hikâye anlatma bana"
      id: 'yoksayma.hikaye_anlatma',
      pattern: _re(r'\bhikaye anlatma\b|\bmasal (anlatma|okuma)\b|\bhava civa\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),

    // ── MUHATAPLIĞIN / YETKİNİN REDDİ ─────────────────────────────────────
    ImplicitPattern(
      // "nereden çıktın sen şimdi" · "nereden çıktınız"
      // Yakın-kaçış: "bu fikir nereden çıktı" — ikinci şahıs şart.
      id: 'yoksayma.nereden_ciktin',
      pattern: _re(r'\bnereden cikt(in|iniz)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      // "sen kim, bu iş kim" · "sen kim oluyorsun"
      // Eliptik kuruluş: iki "kim" arasında en fazla üç kelime.
      id: 'yoksayma.sen_kim_bu_is_kim',
      pattern: _re('\\bsen kim\\b${_bosluk(3)}kim\\b'
          r'|\b(sen|siz) kim ol(uyorsun|uyorsunuz)\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.46,
    ),
    ImplicitPattern(
      // "ne haddine" · "haddin değil" (eliptik "had" ailesi)
      id: 'yoksayma.ne_haddine',
      pattern: _re(r'\bne hadd(ine|inize)\b|\bhadd(in|iniz) degil\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.46,
    ),
    ImplicitPattern(
      // "üstüne vazife değil" · "sana mı kaldı" · "sen karışma"
      //
      // Yakın-kaçış 1: "bu iş bana kaldı" — ikinci şahıs şart.
      // Yakın-kaçış 2: "sen karışmasan da olur, ben hallederim" — ÖLÇÜMLE
      //   bulundu. İlk yazımda fiil kuyruğu serbestti (`karism\w*`) ve
      //   şart kipini de yakalıyordu; oysa "karışmasan da olur" bir
      //   susturma değil, NAZİKÇE YÜKÜ ÜSTLENMEDİR. Kalıp artık yalnızca
      //   EMİR kipini görür: "karışma", "karışmayın". Şart eki (-sa/-se)
      //   kelime sınırını kırdığı için kendiliğinden dışarıda kalır.
      id: 'yoksayma.ustune_vazife_degil',
      pattern: _re(r'\b(ustune|uzerine) vazife degil\b'
          r'|\b(sana|size) mi kaldi\b'
          r'|\b(sen|siz) karisma(yin|yiniz)?\b'),
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      // "sende hiç X mi var" — niteliğin topluca reddi.
      // İP-22'de "sende hiç edep mi var" kaçmıştı: mevcut nitelik_reddi
      // kalıbı araya giren "hiç" pekiştirecini görmüyordu.
      // Yakın-kaçış: "sende hiç kalem var mı" — nitelik listesi kapalı.
      //
      // İP-27 DÜZELTMESİ. Çoğul/nazik biçim ("sizde hiç vicdan mı var")
      // kaçıyordu ve sebebi bir yazım hatasıydı: `sen(de|izde)` yalnızca
      // "sende" ve "senizde" üretir — ikincisi Türkçe'de var olmayan bir
      // kelimedir, "sizde" ise hiç üretilmiyordu. Nazik hitap, saldırıyı
      // yumuşatmaz; kalıbın onu görmemesi bir kusurdur.
      id: 'karakter.nitelik_reddi_hic',
      pattern: _re(r'\b(sende|sizde) (hic )?'
          r'(edep|utanma|vicdan|ar|haya|insaf|saygi|ahlak|onur|seref|'
          r'merhamet|adalet|dusunce)\w* (mi|mu) var\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.58,
      neutralAlternative: 'bu davranışı doğru bulmuyorum',
    ),

    // ── SUSTURMA (yeni fiiller) ───────────────────────────────────────────
    ImplicitPattern(
      // "çeneni tut" · "çenenizi tutun" — "kapa çeneni"den farklı fiil.
      id: 'susturma.ceneni_tut',
      pattern: _re(r'\bcene(ni|nizi) tut' + _emir + r'\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.55,
    ),
    ImplicitPattern(
      // "ağzından çıkanı kulağın duysun"
      id: 'susturma.agzindan_cikani',
      pattern: _re(r'\bagz(indan|inizdan) cikani kulag(in|iniz)\w* duys' + _ek + r'\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
    ),
    ImplicitPattern(
      // "yerini bil" · "sıranı bil" · "hizanı bil"
      id: 'susturma.yerini_bil',
      pattern: _re(r'\b(yer(ini|inizi)|sira(ni|nizi)|hiza(ni|nizi)) bil' +
          _emir + r'\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.52,
    ),
    ImplicitPattern(
      // "ukalalık yapma" · "çok bilmişlik yapma" · "bilmiş bilmiş konuşma"
      id: 'susturma.ukalalik_yapma',
      pattern: _re('\\b(ukalalik|bilmislik|cok bilmislik) yap$_emir\\w*\\b'
          r'|\bukala dumbelegi\b'),
      family: ImplicitFamily.susturma,
      category: ToxicityCategory.asagilama,
      severity: 0.46,
    ),

    // ── ÖRTÜK TEHDİT (deyimsel) ───────────────────────────────────────────
    ImplicitPattern(
      // "ağzının payını alacaksın" · "ağzının payını verdim"
      id: 'tehdit.agzinin_payi',
      pattern: _re(r'\bagz(inin|inizin) payini (al|ver)' + _ek + r'\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.62,
    ),
    ImplicitPattern(
      // "elime geçersen" · "elime bir geçersin" · "elime geçerse"
      //
      // Yakın-kaçış: "elime geçen ilk kitabı okudum" — İP-27 ÖLÇÜMÜYLE
      //   bulunmuş bir YANLIŞ POZİTİFTİR. İlk yazımda alternatifler arasında
      //   çıplak `gec` vardı ve arkasındaki serbest ek kuyruğu (`_ek`) onu
      //   "geçen" ortacına da uyduruyordu. "Elime geçen X" Türkçe'de son
      //   derece sıradan bir sıfat-fiil kuruluşudur ve tehditle ilgisi yoktur.
      //
      //   Tehdidi kuran şey ikinci şahsın ŞART ya da GENİŞ ZAMAN çekimidir:
      //   "geçersen", "geçersin", "geçerse", "geçersiniz". Ortaç (-en) ve
      //   geçmiş zaman (-ti) artık kalıbın dışındadır.
      id: 'tehdit.elime_gecersen',
      pattern: _re(r'\belime (bir )?gecer(sen|sin|se|seniz|siniz)\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.70,
    ),
    ImplicitPattern(
      // "bana bulaşma" · "benimle uğraşma" — misilleme uyarısı.
      // Yakın-kaçış: "boyaya bulaşma" — birinci şahıs yönelimi şart.
      id: 'tehdit.bana_bulasma',
      pattern: _re(r'\b(bana|benimle) (bulasma|ugrasma|dalga gecme)' +
          _emir + r'\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.52,
    ),
    ImplicitPattern(
      // "iki elim yakanda olsun" — klasik beddua/tehdit kuruluşu.
      id: 'tehdit.elim_yakanda',
      pattern: _re(r'\biki elim yaka(nda|nizda)\b'),
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.68,
    ),

    // ── ALAY / ACIMA ──────────────────────────────────────────────────────
    ImplicitPattern(
      // "acıyorum sana" · "sana acıyorum" · "yazık sana"
      // Yakın-kaçış: "yazık oldu" — ikinci şahıs yönelimi şart.
      id: 'alayci.aciyorum_sana',
      pattern: _re(r'\baciyorum (sana|size)\b|\b(sana|size) aciyorum\b'
          r'|\byazik (sana|size)\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.40,
    ),
    ImplicitPattern(
      // "gülerler adama" · "el âlem güler" — utandırma yoluyla susturma.
      id: 'alayci.gulerler_adama',
      pattern: _re(r'\bguler(ler)? adama\b|\bel alem gul' + _ek + r'\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.38,
    ),
    ImplicitPattern(
      // "rezil ettin kendini" · "rezil oldun"
      id: 'alayci.rezil_ettin',
      pattern: _re(r'\brezil (ettin|oldun|olmussun)' + _ek + r'\b'),
      family: ImplicitFamily.alayci,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),

    // ── DEYİMSEL YETERSİZLİK ATFI ─────────────────────────────────────────
    ImplicitPattern(
      // "gözün kör mü" · "kör müsün" · "okuma yazman yok mu"
      // Yakın-kaçış: "kör nokta" — soru kipi ve ikinci şahıs şart.
      id: 'kucumseme.gozun_kor_mu',
      pattern: _re(r'\bgoz(un|unuz) kor mu\b|\bkor mus(un|unuz)\b'
          r'|\bokuma yazma(n|niz) yok mu\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.48,
    ),
    ImplicitPattern(
      // "boyundan büyük işlere kalkışma"
      id: 'kucumseme.boyundan_buyuk',
      pattern: _re(r'\bboy(undan|unuzdan) buyuk\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.42,
    ),
    ImplicitPattern(
      // "adam olmazsın" · "senden adam olmaz"
      // Kimlik eksenli hâli `nefret.kimlikten_adam_olmaz` içindedir.
      id: 'karakter.adam_olmaz',
      pattern: _re(r'\b(senden|sizden) adam olmaz\b|\badam olmazs(in|iniz)\b'),
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.60,
      neutralAlternative: 'bu davranışın değişmesini bekliyorum',
    ),
    ImplicitPattern(
      // "ne işe yarıyorsun" · "ne işe yararsın"
      id: 'kucumseme.ne_ise_yariyorsun',
      pattern: _re(r'\bne ise yar(iyorsun|arsin|iyorsunuz|arsiniz)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
    ),
    ImplicitPattern(
      // "cahilliğinle övünme" · "cehaletinle övünme"
      id: 'kucumseme.cahillikle_ovunme',
      pattern: _re(r'\b(cahillig(in|iniz)le|cehalet(in|iniz)le) ovun' +
          _emir + r'\w*\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.50,
    ),

    // ═══ DEYİM VE ATASÖZÜ ════════════════════════════════════════════════════
    // Kalıplaşmış değersizleştirme ayrı bir dosyada: `idiom_patterns.dart`.
    // Ayrı tutulmalarının sebebi ÖLÇÜM dürüstlüğüdür — buradaki kalıplar
    // ÜRETKENDİR (yazılan bir kuruluş, hiç görülmemiş örnekleri de yakalar),
    // deyimler değildir. İkisini aynı listede saymak, ezberlenen deyim
    // sayısını genelleme oranına karıştırırdı.
    ...IdiomPatterns.all,

    // ═══ NEFRET SÖYLEMİ ══════════════════════════════════════════════════════
    // Kimlik hedefli kuruluşlar ayrı bir dosyada: `hate_patterns.dart`.
    // Ayrı tutulmalarının sebebi tasarım farkı — orada kimlik adları bir
    // YUVA'dır, tek başlarına asla bulgu üretmezler.
    ...HatePatterns.all,
  ];
}
