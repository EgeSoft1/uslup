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

/// Örtük saldırının edimbilimsel türü. Şeffaflık panelinde kullanıcıya
/// "bu ifade neden sorunlu" açıklaması bu sınıflandırmadan üretilir.
enum ImplicitFamily {
  /// Muhatabın bilgi/yetkinlik kapasitesinin reddi.
  kucumseme,

  /// Bireyi bir kategoriye indirgeme, grup suçlaması.
  otekilestirme,

  /// Muhataplığın ve katkının reddi.
  yoksayma,

  /// Konuşma hakkının elinden alınması.
  susturma,

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
        ImplicitFamily.yoksayma => 'Yok sayma',
        ImplicitFamily.susturma => 'Susturma',
        ImplicitFamily.alayci => 'Alaycılık',
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

  const ImplicitPattern({
    required this.id,
    required this.pattern,
    required this.family,
    required this.category,
    required this.severity,
    this.neutralAlternative,
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
      pattern: _re(r'\b(seninle|sizinle) tartismak (zaman kaybi|bosuna|anlamsiz)\b'),
      family: ImplicitFamily.kucumseme,
      category: ToxicityCategory.asagilama,
      severity: 0.45,
    ),
    ImplicitPattern(
      id: 'kucumseme.seviye',
      pattern: _re(r'\bseviye(ne|nize|sine) in(ip|erek|mek)\b'),
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
      pattern: _re(r'\b(sana|size) anlatmak (nafile|bosuna|imkansiz)\b'),
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
      pattern: _re(r'\b(senden|sizden|onlardan) baska ne beklenir\b'),
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

    // ═══ NEFRET SÖYLEMİ ══════════════════════════════════════════════════════
    // Kimlik hedefli kuruluşlar ayrı bir dosyada: `hate_patterns.dart`.
    // Ayrı tutulmalarının sebebi tasarım farkı — orada kimlik adları bir
    // YUVA'dır, tek başlarına asla bulgu üretmezler.
    ...HatePatterns.all,
  ];
}
