// =============================================================================
// Deyim ve Atasözü Katmanı — Türkçe kalıplaşmış değersizleştirme
// Dosya: packages/civility_core/lib/src/detect/idiom_patterns.dart
//
// ── NEDEN AYRI BİR KATMAN (İP-28) ─────────────────────────────────────────
// Beşinci ayrık küme (İP-27) motorun tavanını ilk kez ayrıştırılabilir
// biçimde gösterdi: 31 kaçağın 16'sı tek bir sınıftaydı — DEYİM ya da
// ATASÖZÜ kılığında değersizleştirme.
//
//   "takke düştü kel göründü"              → temiz (0.00)
//   "attığın taş ürküttüğün kurbağaya değmez" → temiz (0.00)
//   "sen daha anasının kuzususun"          → temiz (0.00)
//
// Bunlar edimbilimsel örüntü katmanının kaçırdığı şeyler değildir; o
// katmanın YAPISAL OLARAK göremeyeceği şeylerdir. `implicit_patterns.dart`
// bir kuruluşu (construction) yakalar: `[2.şahıs] + gibiler`, `[kimlik] +
// düşman yüklem`. Kuruluş üretkendir — yazılan bir kalıp, hiç görülmemiş
// örnekleri de yakalar. Ölçüm bunu doğruladı: yazılmış ailelerin yeni
// örneklerinde duyarlılık %90,0.
//
// Deyimde üretkenlik YOKTUR. "Takke düştü kel göründü"nün saldırgan olması,
// kelimelerinin diziliminden TÜREMEZ; o dizilime toplumca yüklenmiş
// donmuş bir anlamdır. Hiçbir morfosentaktik kural onu "takke düştü şapka
// göründü"den ayıramaz. Bu yüzden deyim bir ÖRÜNTÜ değil, bir SÖZ VARLIĞI
// problemidir ve bir sözvarlığı kaynağı olarak yazılmalıdır.
//
// Bu ayrımı gizlemek mümkündü: 200 deyimi `implicit_patterns.dart` içine
// serpiştirip "örüntü sayısı 400'e çıktı" demek. Bu, ölçülen genelleme
// oranını da anlamsızlaştırırdı — bir deyimin ezberlenmesiyle bir
// kuruluşun genellenmesi aynı sayıya karışırdı. Ayrı dosya, ayrı ölçüm
// dilimi ve ayrı dürüstlük iddiası içindir:
//
//   Kuruluş katmanı  → genelleşir.  Ölçüsü: aynı ailenin YENİ örnekleri.
//   Deyim katmanı    → genelleşmez. Ölçüsü: kaç deyim yazıldı.
//
// ── GECİKME: KAPI KELİMESİ ────────────────────────────────────────────────
// Yüzlerce düzenli ifadeyi her tuş vuruşunda çalıştırmak 16 ms'lik kare
// bütçesini tek başına yerdi. Her deyim, kendisine özgü değişmez bir kök
// taşır ("takke", "coplu", "yogurt"); dedektör tek taramada metindeki
// bütün kapı köklerini toplar ve yalnızca kapısı açılan deyimi dener.
// Ayrıntı: `ImplicitPattern.gateWord` ve `ImplicitDetector`.
//
// ── SEÇİM ÖLÇÜTÜ ──────────────────────────────────────────────────────────
// Bir deyimin bu dosyaya girmesi için üç şart birden gerekir:
//
//   1. KALIPLAŞMIŞ olmalı. Serbest bir benzetme ("buzdolabı gibi adam")
//      buraya değil, kuruluş katmanına aittir.
//   2. Muhataba yöneldiğinde TEK İŞLEVİ değersizleştirme olmalı.
//   3. Yakın-kaçışı yazılabilmeli. Deyimin kelimeleri masum bir cümlede
//      yan yana gelebiliyorsa, kalıp o cümleyi DIŞARIDA bırakmalı.
//
// ⛔ ÖLÇÜTE TAKILIP ALINMAYANLAR — gerekçeleriyle:
//
//   "ayağını yorganına göre uzat"  → öğüt olarak da, iğneleme olarak da
//      kullanılır ve ikisini metin ayırt ettirmez. Meşru okuması baskın.
//   "damlaya damlaya göl olur"     → saldırgan kullanımı marjinal.
//   "bu ne perhiz bu ne lahana turşusu" → tutarsızlık eleştirisidir;
//      eleştiriyi hakaret saymak ürünün iddiasını çürütür.
//   "üzümünü ye bağını sorma"      → susturma sayılabilir ama meşru
//      "ayrıntıya girme" okuması en az onun kadar yaygın.
//
// Alınmayanlar burada yazılıdır çünkü bir kapsam kararının gerekçesi,
// kapsamın kendisi kadar denetlenebilir olmalıdır.
// =============================================================================

import '../lexicon/toxicity_lexicon.dart';
import 'implicit_patterns.dart';

/// Kalıplaşmış Türkçe değersizleştirme deyimleri.
abstract final class IdiomPatterns {
  /// Bu katmanın bütün örüntü kimlikleri bu önekle başlar.
  ///
  /// Kapı mekanizması ve ölçüm dilimi bu öneke bakar; yeni bir deyim başka
  /// bir önekle eklenirse `test/idiom_layer_test.dart` kırılır.
  static const String idPrefix = 'deyim.';

  static RegExp _re(String source) => RegExp(source, caseSensitive: false);

  /// Herhangi bir çekim eki kuyruğu.
  static const String _ek = r'\w*';

  /// Araya en fazla [n] kelime girebilir.
  static String _gap(int n) => '(?:\\s+\\w+){0,$n}\\s+';

  /// Kapı kelimesi taramasında kullanılan tek düzenli ifade.
  ///
  /// Bütün deyimlerin kapı köklerinin almaşığıdır. Tek bir geçişte metindeki
  /// bütün kapıları bulur; dedektör yalnızca açılan kapıların arkasındaki
  /// deyimi dener. Kök olarak eşleşir (sonda `\b` YOKTUR) çünkü Türkçe'de
  /// kök çekim aldığında sonu değişir: "çöplük" → "çöplüğünde".
  static final RegExp anchorGate = () {
    final anchors = <String>{
      for (final p in all)
        if (p.gateWord != null) p.gateWord!,
    };
    // Uzun kökler önce: "kurbaga" ile "kur" aynı metinde geçtiğinde
    // almaşığın uzun olanı seçmesi gerekir.
    final sorted = anchors.toList()..sort((a, b) => b.length.compareTo(a.length));
    return RegExp('\\b(?:${sorted.join('|')})', caseSensitive: false);
  }();

  /// Metinde geçen kapı köklerinin kümesi. Tek tarama.
  static Set<String> scanAnchors(String normalized) {
    final hits = <String>{};
    for (final m in anchorGate.allMatches(normalized)) {
      hits.add(m.group(0)!);
    }
    return hits;
  }

  /// Deyim girdisi kurmak için kısayol.
  ///
  /// Her girdi bir `ImplicitPattern`'dır — böylece bağlam katmanından,
  /// tekilleştirmeden, şeffaflık panelinden ve yeniden yazıcıdan
  /// kendiliğinden yararlanır. Deyim katmanı motorun yanına değil,
  /// İÇİNE eklenir.
  static ImplicitPattern _d({
    required String id,
    // `null`: kapı yok, örüntü her metinde denenir (değişmez parça ön
    // filtresi yine uygulanır). Yalnızca tek bir kapı kelimesi bütün
    // almaşıkları kapsayamadığında kullanılır.
    required String? gate,
    required String pattern,
    required ImplicitFamily family,
    required double severity,
    ToxicityCategory category = ToxicityCategory.asagilama,
    String? neutral,
  }) =>
      ImplicitPattern(
        id: '$idPrefix$id',
        pattern: _re(pattern),
        family: family,
        category: category,
        severity: severity,
        neutralAlternative: neutral,
        gateWord: gate,
      );

  static final List<ImplicitPattern> all = <ImplicitPattern>[
    // ═══ 1. YETERSİZLİK / OLGUNLUK REDDİ ═══════════════════════════════════
    // Ortak önerme: "sen bu işi yapacak kişi değilsin". Muhatabın
    // yaptığına değil, YAPABİLİRLİĞİNE saldırır.

    _d(
      // "sen daha anasının kuzususun" · "anasının kuzusu bunlar"
      // Yakın-kaçış: "kuzu eti aldım" — "ana" iyeliği şart.
      id: 'anasinin_kuzusu',
      gate: 'kuzu',
      // D11 (docs/23): kökten sonraki serbest `\w*` "Anadolu kuzu tandır" cümlesini
      // "ana" + "dolu" diye yakalıyordu. İyelikli "kuzusu" şart.
      pattern: r'\ban(a|asi|anin|asinin) kuzus' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.42,
      neutral: 'bu konuda deneyimin sınırlı görünüyor',
    ),
    _d(
      // "sen daha emekleme aşamasındasın"
      // Yakın-kaçış: "bebek emeklemeye başladı" — mecaz şartı: "aşama",
      // "seviye", "devre" gibi soyut bir ad izlemeli.
      id: 'emekleme_asamasi',
      gate: 'emekl',
      pattern: r'\bemekle\w* (asama|seviye|devre|donem)' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.40,
      neutral: 'bu alanda daha yeni olduğunu düşünüyorum',
    ),
    _d(
      // "sen benim tırnağım bile olamazsın"
      // Yakın-kaçış: "tırnağım kırıldı" — "bile ol(a)ma" kuyruğu şart.
      id: 'tirnagi_olamazsin',
      gate: 'tirnag',
      // D11 (docs/23): `ol(a)?ma\w*` ortacı da alıyordu: "Tırnağı olmayan kediler"
      // → Riskli ✗. Yalnızca yetersizlik yüklemi ("olamaz/olamazsın").
      pattern: r'\btirnag\w*( bile)? ola?ma(z|zsin|zsiniz)\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.55,
      neutral: 'bu karşılaştırmayı yapmak istemiyorum',
    ),
    _d(
      // "ağzınla kuş tutsan (bile) fayda etmez / kâr etmez"
      id: 'agzinla_kus_tutsan',
      gate: 'kus tut',
      pattern: r'\bkus tuts' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.48,
      neutral: 'bu noktada ikna olmam zor',
    ),
    _d(
      // "seni anlatmaya kalem yetmez" · "anlatmaya kelime yetmez"
      // Alaycı abartma: övgü kalıbının tersine çevrilmiş hâli.
      id: 'kalem_yetmez',
      gate: 'yetmez',
      // D11 (docs/23): çıplak kalıp içten övgüyü işaretliyordu: "Bu güzelliği
      // anlatmaya kelime yetmez" → Riskli ✗ (D5 ilkesi). İkinci şahıs nesnesi
      // şart. Kalan sınır: "seni anlatmaya kelimeler yetmez" iltifatı hâlâ
      // işaretlenir; yazılı metin alayı samimiyetten ayırmaz.
      pattern: r'\b(seni|sizi)\b(?:\s+\w+){0,2}\s+(kalem|kelime|kagit|defter|sayfa)\w* yetmez\b',
      family: ImplicitFamily.alayci,
      severity: 0.40,
    ),
    _d(
      // "bu kafayla / bu akılla / bu zihniyetle bir yere varamazsın"
      //
      // ÜRETKEN KURULUŞ gibi görünür ama değildir: "bu kafayla" öbeği
      // kalıplaşmıştır ve "bu şapkayla" ile değiştirilemez. Kapalı ad
      // listesi bu yüzdendir.
      // Yakın-kaçış: "bu kafayla yatarsam ağrır" — ikinci şahıs yüklem şart.
      id: 'bu_kafayla_varamazsin',
      // D12 (docs/23): kapı "kafayla" idi; "bu akılla", "bu zihniyetle",
      // "bu kafanla" dalları hiç denenmiyordu (sessiz kaçak). Kapı kaldırıldı —
      // değişmez parça ön filtresi (`LiteralPrefilter`) hızı yine korur.
      // Yeni açılan dallar yalnızca İKİNCİ ŞAHIS yetersizlik yüklemini alır:
      // "bu mantıkla bu iş yürümez" bir eleştiridir, saldırı değildir.
      gate: null,
      pattern: '\\bbu kafayla\\b${_gap(3)}'
          '\\w*(mazsin|mezsin|mazsiniz|mezsiniz|maz|mez)\\b'
          // "-la/-le": ince ünlülü "zihniyetLE" yalnızca "-la" kabul edildiği
          // için almaşıkta durduğu hâlde hiç eşleşemiyordu.
          '|\\bbu (kafa|akil|zihniyet|mantik|tavir)\\w*l[ae]\\b${_gap(3)}'
          '\\w*(mazsin|mezsin|mazsiniz|mezsiniz)\\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.46,
      neutral: 'bu yaklaşımın sonuç vereceğine inanmıyorum',
    ),
    _d(
      // "boyundan büyük işlere kalkışıyorsun" — deyimsel biçim.
      // (Sıfat hâli `kucumseme.boyundan_buyuk` kalıbındadır; burada
      // fiille birlikte gelen serbest kuruluş yakalanır.)
      id: 'boyunu_asan',
      gate: 'boyunu',
      pattern: r'\bboyunu as' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.42,
    ),
    _d(
      // "haddini bilmiyorsun" · "haddini aştın"
      //
      // ── BU KALIP BİR KEZ YANLIŞ YAZILDI ─────────────────────────────────
      // İlk yazımda fiil listesi çıplak `bil` içeriyordu ve serbest ek
      // kuyruğu onu ORTACA da uyduruyordu. Sonuç, iki ayrı ayrık kümede
      // aynı anda beliren bir yanlış pozitifti:
      //
      //   "haddini bilen bir insandı, saygı duyardım"  → işaretleniyordu ✗
      //   "haddini bilen insanlara saygı duyarım"      → işaretleniyordu ✗
      //
      // Türkçe'de "haddini bilmek" bir ÖVGÜDÜR; saldırı olan şey onun
      // OLUMSUZUDUR ("bilmiyorsun") ya da "aşmak" fiilidir. Bir deyimin
      // olumlu ve olumsuz çekimi zıt edimlere karşılık gelebiliyorsa,
      // fiil listesi çekimiyle birlikte kapatılmalıdır.
      //
      // İki kümenin de bunu aynı anda göstermesi rastlantı değil: bu ifade
      // Türkçe'de yaygındır ve kalıp yayına çıksaydı gerçek kullanıcıların
      // ÖVGÜLERİ işaretlenecekti.
      id: 'haddini_asmak',
      pattern: r'\bhaddin\w* (as(ti|tin|tiniz|iyor|acak|arsan)\w*'
          r'|bilmi\w+|bilmez\w*|bilmedin\w*)\b',
      gate: 'haddin',
      family: ImplicitFamily.yoksayma,
      severity: 0.48,
      neutral: 'bu konuda farklı düşünüyorum',
    ),
    _d(
      // "eline yüzüne bulaştırdın"
      id: 'eline_yuzune_bulastirmak',
      gate: 'yuzune bulas',
      pattern: r'\byuzune bulastir' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.44,
      neutral: 'sonuç beklediğim gibi olmadı',
    ),
    _d(
      // "bu işin suyunu çıkardın"
      // Yakın-kaçış: "limonun suyunu çıkar" — "iş/konu/espri" şart.
      id: 'suyunu_cikarmak',
      gate: 'suyunu',
      pattern: r'\b(is|isin|konu|konunun|espri|esprinin|olay|olayin) '
          '''suyunu cikar$_ek\\b''',
      family: ImplicitFamily.kucumseme,
      severity: 0.38,
    ),
    _d(
      // "kırk yılda bir doğru söyledin" — övgü kılığında genel yetersizlik.
      id: 'kirk_yilda_bir',
      gate: 'kirk yil',
      // D11 (docs/23): birinci şahıs anlatıyı da alıyordu: "Kırk yılda bir yemek
      // yaptık" → Riskli ✗. Alay ikinci şahsa yöneliktir ("doğru söyledin").
      pattern: r'\bkirk yil\w*( bir)?\b' + _gap(2) +
          r'(soyle|yap|et|bul)\w*(din|dun|tin|tun|diniz|dunuz|tiniz|tunuz)\b',
      family: ImplicitFamily.alayci,
      severity: 0.44,
      neutral: 'bu noktada sana katılıyorum',
    ),

    // ═══ 2. EMEĞİN / KATKININ DEĞERSİZLEŞTİRİLMESİ ═════════════════════════

    _d(
      // "attığın taş ürküttüğün kurbağaya değmez"
      id: 'attigin_tas_kurbaga',
      gate: 'kurbaga',
      // D12 (docs/23): ikinci almaşık ("attığın taş") kapı kelimesi "kurbaga"yı
      // içermediği için hiç denenmiyordu; ölü dal kaldırıldı.
      pattern: r'\bkurbaga\w* degmez\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.44,
      neutral: 'bu çabanın karşılığını vereceğini düşünmüyorum',
    ),
    _d(
      // "gölge etme başka ihsan istemem"
      id: 'golge_etme',
      gate: 'golge et',
      pattern: r'\bgolge etme' + _ek + r'\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.46,
      neutral: 'bu konuda kendi başıma ilerlemek istiyorum',
    ),
    _d(
      // "boşa kürek çekiyorsun" ile aynı aileden: "havanda su dövmek"
      id: 'havanda_su_dovmek',
      gate: 'havanda',
      pattern: r'\bhavanda su dov' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.40,
      neutral: 'bu yolun sonuç vereceğine inanmıyorum',
    ),
    _d(
      // "dağ fare doğurdu" — sonucun küçümsenmesi.
      id: 'dag_fare_dogurdu',
      gate: 'fare dogur',
      pattern: r'\bfare dogur' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.42,
    ),
    _d(
      // "pire için yorgan yakmak"
      id: 'pire_icin_yorgan',
      gate: 'yorgan yak',
      pattern: r'\byorgan yak' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.36,
    ),
    _d(
      // "armut piş ağzıma düş" — tembellik atfı.
      id: 'armut_pis_agzima_dus',
      gate: 'armut pis',
      pattern: r'\barmut pis\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.46,
      neutral: 'bu işte daha fazla katkı bekliyorum',
    ),
    _d(
      // "hazıra konmak" · "hazır yiyici"
      id: 'hazira_konmak',
      gate: 'hazira kon',
      pattern: r'\bhazira kon' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.42,
    ),
    _d(
      // "eli boş" — çıkarcılık/verimsizlik iması.
      // "bal tutan parmağını yalar" kısmı tek başına atasözüdür ve masum
      // kullanılabilir; saldırganlığı kuran şey bitişik "elin boş" kuyruğu.
      id: 'bal_tutan_elin_bos',
      gate: 'bal tut',
      pattern: r'\bbal tutan\b' + _gap(4) + r'el(in|iniz) bos\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.42,
    ),
    _d(
      // "ayinesi iştir kişinin lafa bakılmaz"
      id: 'ayinesi_istir',
      gate: 'ayinesi',
      pattern: r'\bayinesi is' + _ek + r'\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.38,
      neutral: 'söylenenden çok sonucu merak ediyorum',
    ),
    _d(
      // "lafla peynir gemisi yürümez"
      id: 'lafla_peynir_gemisi',
      gate: 'peynir gemi',
      pattern: r'\bpeynir gemisi\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.38,
    ),
    _d(
      // "havadan sudan konuşuyorsun" — içeriğin reddi.
      id: 'havadan_sudan',
      gate: 'havadan sudan',
      pattern: r'\bhavadan sudan\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.30,
    ),

    // ═══ 3. AHLAK / DÜRÜSTLÜK SUÇLAMASI ════════════════════════════════════

    _d(
      // "sütten çıkmış ak kaşık" — ikiyüzlülük suçlaması.
      id: 'sutten_cikmis_ak_kasik',
      gate: 'ak kasik',
      pattern: r'\bak kasik\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.48,
      neutral: 'bu konuda senin de payın olduğunu düşünüyorum',
    ),
    _d(
      // "tencere dibin kara" — karşı suçlama.
      id: 'tencere_dibin_kara',
      gate: 'tencere dib',
      pattern: r'\btencere dib' + _ek + r'\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.46,
    ),
    _d(
      // "takke düştü kel göründü" — ifşa/utandırma.
      id: 'takke_dustu',
      neutral: 'bence bu durum bazı şeyleri netleştirdi',
      gate: 'takke',
      pattern: r'\btakke dus' + _ek + r'\b',
      family: ImplicitFamily.alayci,
      severity: 0.42,
    ),
    _d(
      // "dilinin kemiği yok" — sözünde durmama suçlaması.
      // Yakın-kaçış: "dilimin ucunda" — "kemiği yok" bitişikliği şart.
      id: 'dilinin_kemigi_yok',
      gate: 'kemig',
      pattern: r'\bdil(in|iniz|inin)\w* kemig\w* yok\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.50,
      neutral: 'söylediklerinin tutarlı olmasını bekliyorum',
    ),
    _d(
      // "senin ağzından bal damlasa yalamam" — güvensizlik beyanı.
      id: 'agzindan_bal_damlasa',
      gate: 'bal damla',
      pattern: r'\bbal damlas' + _ek + r'\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.50,
    ),
    _d(
      // "değirmenin suyu nereden geliyor" — örtük yolsuzluk iması.
      id: 'degirmenin_suyu',
      gate: 'degirmen',
      pattern: r'\bdegirmen\w* suyu\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.48,
      neutral: 'bu kaynağın nereden geldiğini merak ediyorum',
    ),
    _d(
      // "yüzsüzlük etme" · "yüzsüzün tekisin" — yüz+süz sözlükte yok.
      id: 'yuzsuzluk',
      gate: 'yuzsuz',
      pattern: r'\byuzsuz' + _ek + r'\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.52,
    ),
    _d(
      // "kaşınıyorsun" — provokasyon suçlaması.
      // Yakın-kaçış: "sırtım kaşınıyor" — ikinci şahıs çekimi şart.
      id: 'kasiniyorsun',
      gate: 'kasin',
      // D11 (docs/23): çıplak "kaşınma" adı da eşleşiyordu: "Ciltte kaşınma ve
      // kızarıklık var" → Riskli · tehdit ✗. Emir kipi yalnızca hitapla.
      pattern: r'\bkasin(iyorsun|iyorsunuz|mayin)\b|\bkasinma (lan|be|bana|benimle)\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.48,
    ),
    _d(
      // "ipiyle kuyuya inilmez" — güvenilmezlik.
      id: 'ipiyle_kuyuya',
      gate: 'kuyuya in',
      pattern: r'\bkuyuya in' + _ek + r'\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.46,
    ),
    _d(
      // "kem küm etme" · "kem söz"
      id: 'kem_kum',
      gate: 'kem kum',
      pattern: r'\bkem kum\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.32,
    ),

    // ═══ 4. MUHATAPLIĞIN / YETKİNİN REDDİ ══════════════════════════════════

    _d(
      // "seni adam yerine koyan mı var"
      id: 'adam_yerine_koymak',
      gate: 'adam yerine',
      pattern: r'\badam yerine koy' + _ek + r'\b',
      family: ImplicitFamily.yoksayma,
      category: ToxicityCategory.hakaret,
      severity: 0.56,
      neutral: 'bu konuda seninle aynı fikirde değilim',
    ),
    _d(
      // "sen hangi cesaretle konuşuyorsun" · "hangi yüzle"
      id: 'hangi_cesaretle',
      gate: 'hangi',
      pattern: r'\bhangi (cesaret|yuz|akil|hak)\w*le\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.48,
      neutral: 'bu görüşe katılmıyorum',
    ),
    _d(
      // "kendi çöplüğünde ötüyorsun" — yetki alanını daraltma.
      id: 'kendi_coplugunde',
      gate: 'coplu',
      pattern: r'\bcoplug' + _ek + r'\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.46,
    ),
    _d(
      // "davul dengi dengine" · "dengi dengine"
      id: 'dengi_dengine',
      gate: 'dengi deng',
      pattern: r'\bdengi dengine\b',
      family: ImplicitFamily.otekilestirme,
      severity: 0.40,
    ),
    _d(
      // "her yiğidin bir yoğurt yiyişi var" + kişiselleştirilmiş kuyruk.
      // Atasözü tek başına HOŞGÖRÜ ifadesidir ("herkesin yöntemi farklı");
      // saldırganlığı kuran şey "ama seninki" kuyruğudur. Kuyruksuz hâli
      // KASITLI olarak dışarıda bırakılmıştır.
      id: 'yogurt_yiyisi_ama_senin',
      gate: 'yogurt yiy',
      pattern: r'\byogurt yiyis' + _ek + r'\b' + _gap(4) + r'senin' + _ek + r'\b',
      family: ImplicitFamily.kucumseme,
      severity: 0.40,
    ),
    _d(
      // "sen kendi işine bak" deyimsel varyantı: "sen kendi yoluna"
      id: 'kendi_yoluna',
      gate: 'kendi yolu',
      pattern: r'\bkendi yolu' + _ek + r' (git|bak|devam)' + _ek + r'\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.30,
    ),
    _d(
      // "sana mı soracağız" · "sana mı danışacağız"
      id: 'sana_mi_soracagiz',
      gate: 'soracag',
      // D12 (docs/23): kapı "soracag" olduğu için "danış" dalı hiç denenmiyordu.
      // Ölçülen davranış korunarak kalıp kapıyla hizalandı.
      pattern: r'\b(sana|size) mi soracag' + _ek + r'\b',
      family: ImplicitFamily.yoksayma,
      severity: 0.46,
    ),
    _d(
      // "haddini bildiririm" — tehdit kuyruğu.
      id: 'haddini_bildiririm',
      // D12 (docs/23): kapı "bildirir" idi; "haddini bildireceğim" bu kalıbı
      // hiç denemiyordu.
      gate: 'bildir',
      pattern: r'\bhaddin\w* bildir' + _ek + r'\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.62,
    ),

    // ═══ 5. TİKSİNME / DIŞLAMA (kimlik hedefli DEĞİL) ══════════════════════
    // Kimlik hedefli olanlar `hate_patterns.dart` içindedir. Buradakiler
    // muhatabın kendisine yöneliktir ve nefret söylemi değil, hakarettir.

    _d(
      // "seninle aynı havayı solumak bile zor"
      id: 'ayni_havayi_solumak',
      gate: 'havayi solu',
      pattern: r'\bhavayi solu' + _ek + r'\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.55,
      neutral: 'bu ortamda birlikte çalışmakta zorlanıyorum',
    ),
    _d(
      // "gözüm görmesin" · "gözüm görmek istemiyor"
      id: 'gozum_gormesin',
      gate: 'gormesin',
      pattern: r'\bgoz(um|umuz) gormesin\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.52,
    ),
    _d(
      // "adını bile duymak istemiyorum"
      id: 'adini_duymak_istemiyorum',
      gate: 'duymak istemi',
      pattern: r'\b(adin|adini|sesin|sesini)\w*( bile)? duymak istemi' + _ek + r'\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.48,
    ),
    _d(
      // "yüzünü görmeyeyim" · "bir daha yüzünü görmeyeyim"
      id: 'yuzunu_gormeyeyim',
      gate: 'gormeyeyim',
      pattern: r'\byuz(un|unu|unuzu)\w* gormeyeyim\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.50,
    ),
    _d(
      // "defol git" tek kelimelik hâli sözlükte; deyimsel hâli burada:
      // "yolun açık olsun" alaycı bağlamda — KASITLI OLARAK ALINMADI,
      // çünkü samimi kullanımı baskın. Yerine kesin olan:
      // "arkana bakmadan git"
      id: 'arkana_bakmadan_git',
      gate: 'arkana bak',
      pattern: r'\barkana bakma' + _ek + r' git' + _ek + r'\b',
      family: ImplicitFamily.karakterSaldirisi,
      category: ToxicityCategory.hakaret,
      severity: 0.45,
    ),

    // ═══ 6. ALAY / KÜÇÜK DÜŞÜRME ═══════════════════════════════════════════

    _d(
      // "komik duruma düştün" · "gülünç oldun"
      id: 'gulunc_oldun',
      gate: 'gulunc',
      pattern: r'\bgulunc ol' + _ek + r'\b|\bgulunc duruma dus' + _ek + r'\b',
      family: ImplicitFamily.alayci,
      severity: 0.40,
    ),
    _d(
      // "maskara oldun" · "maskaraya döndün"
      id: 'maskara_oldun',
      gate: 'maskara',
      // D11 (docs/23): `maskara\w*` makyaj malzemesini işaretliyordu: "Yeni
      // maskaramı denedim" → Riskli ✗. Deyimin yüklemi şart.
      pattern: r'\bmaskara (ol|oldun|olmus|ettin|etti|etme)\w*\b'
          r'|\bmaskaraya don\w*|\bmaskaralik\w*',
      family: ImplicitFamily.alayci,
      severity: 0.42,
    ),
    _d(
      // "kendinle dalga mı geçiyorsun" · "dalga mı geçiyorsun"
      // Yakın-kaçış: "dalgalar yükseldi" — "geç" fiili şart.
      id: 'dalga_mi_geciyorsun',
      gate: 'dalga',
      pattern: r'\bdalga mi gec' + _ek + r'\b',
      family: ImplicitFamily.alayci,
      severity: 0.36,
    ),
    _d(
      // "güldürme beni" · "güldürme insanı"
      id: 'guldurme_beni',
      gate: 'guldurme',
      pattern: r'\bguldurme (beni|insani|adami)\b',
      family: ImplicitFamily.alayci,
      severity: 0.44,
      neutral: 'bu açıklamayı ikna edici bulmuyorum',
    ),
    _d(
      // "yerin dibine sokmak" değil; "yerin dibine gir" (utandırma emri)
      id: 'yerin_dibine_gir',
      gate: 'yerin dibine',
      pattern: r'\byerin dibine gir' + _ek + r'\b',
      family: ImplicitFamily.alayci,
      severity: 0.46,
    ),
    _d(
      // "eğlenceli oldu ama sen değil": alaycı "helal olsun" kalıbı
      // KASITLI OLARAK ALINMADI — samimi kullanımı çok baskın.
      // Yerine kesin olan: "bravo sana" tek başına da alaycı sayılamaz;
      // alınan yalnızca "ne büyük başarı" ironisidir.
      id: 'ne_buyuk_basari',
      gate: 'buyuk basari',
      // D12 (docs/23): kapı "buyuk basari" olduğu için diğer dallar hiç
      // denenmiyordu. Açılsaydı "ne büyük iş başardın" övgüsünü işaretlerdi (D5).
      pattern: r'\bne buyuk basari\b',
      family: ImplicitFamily.alayci,
      severity: 0.38,
    ),

    // ═══ 7. TEHDİT / GÖZDAĞI (deyimsel) ════════════════════════════════════

    _d(
      // "burnundan getiririm"
      id: 'burnundan_getirmek',
      gate: 'burnundan',
      pattern: r'\bburnundan getir' + _ek + r'\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.72,
    ),
    _d(
      // "canına okurum"
      id: 'canina_okumak',
      gate: 'canina',
      pattern: r'\bcanina oku' + _ek + r'\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.80,
    ),
    _d(
      // "dişini sökerim" · "dişlerini dökerim"
      id: 'disini_sokmek',
      gate: 'dis',
      // D11 (docs/23): `(sok|dok)\w*` geçmiş zamanı da alıyordu: "Diş hekimi
      // çürük dişini söktü" → Yüksek risk · tehdit ✗. Birinci şahıs gelecek/
      // geniş zaman şart. D12: kapı "disini" iken "dişlerini" dalı hiç
      // denenmiyordu.
      pattern: r'\bdis(ini|lerini) (sok|dok)(erim|eriz|ecegim|ecegiz|ecem)\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.85,
    ),
    _d(
      // "başına iş açarım" · "başını belaya sokarım"
      id: 'basina_is_acmak',
      gate: 'basin',
      pattern: r'\bbasin\w* (is ac|belaya sok)' + _ek + r'\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.68,
    ),
    _d(
      // "sen beni tanımıyorsun" — örtük gözdağı.
      // Yakın-kaçış: "beni tanımıyorsun ki, ilk kez görüşüyoruz" —
      // KASITLI olarak düşük şiddet: tek başına müdahale üretmez,
      // başka bir bulguyla birleşince skoru yukarı iter.
      id: 'beni_tanimiyorsun',
      gate: 'tanimiyor',
      pattern: r'\b(sen|siz) beni tanimiyor' + _ek + r'\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.30,
    ),
    _d(
      // "yaptığın yanına kalmaz"
      id: 'yanina_kalmaz',
      gate: 'yanina kalmaz',
      pattern: r'\byanina kalmaz\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.58,
    ),
    _d(
      // "hesabını sorarım" · "hesap sorarım"
      id: 'hesabini_sormak',
      gate: 'hesab',
      // D11 (docs/23): geçmiş zamanı da alıyordu ("hesabını sordum").
      pattern: r'\bhesab(ini|inizi) sor(arim|ariz|acagim|acagiz|acam|acaz|ucam|ucaz)\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.55,
    ),
    _d(
      // "kanına ekmek doğramak"
      id: 'kanina_ekmek',
      gate: 'ekmek dogra',
      // D11 (docs/23): "Çorbaya ekmek doğradım" → Riskli · tehdit ✗. Deyim
      // "kanına ekmek doğramak"tır; "kan" şart.
      pattern: r'\bkan(ina|iniza|larina) ekmek dogra' + _ek + r'\b',
      family: ImplicitFamily.ortukTehdit,
      category: ToxicityCategory.tehdit,
      severity: 0.65,
    ),
  ];
}
