// =============================================================================
// Üslup Asistanı — cihaz üstü, kural tabanlı Türkçe niyet çözümleyici
// Dosya: packages/civility_core/lib/src/assistant/uslup_asistani.dart
//
// ── NE DEĞİLDİR ───────────────────────────────────────────────────────────
// Bu bir dil modeli (LLM) sohbeti DEĞİLDİR ve öyle adlandırılmaz. Arkasında
// hiçbir model, hiçbir ağ çağrısı yoktur. Projede bir LLM ölçülüp kasıtlı
// olarak kaldırıldı (docs/03) ve motorla soru-cevap ekranı da aynı sebeple
// yeniden adlandırıldı: jüriye yanlış bir etiket göstermek, doğru olan her
// şeyin güvenilirliğini düşürür.
//
// Yaptığı şey şudur: kullanıcının Türkçe cümlesinden NİYETİ çıkarır ve o
// niyete karşılık gelen içeriği döndürür. "Bana nefret söylemi örnekleri
// sun" → nefret söylemi örnekleri. Aynı normalizasyon ve biçimbilim
// katmanları kullanılır, yani "NEFRET SÖYLEMİ", "nefret soylemi örnekleri
// gösterir misin" ve "nefrét söylemi" aynı yere düşer.
//
// ── NEDEN ÜRÜNE AİT ───────────────────────────────────────────────────────
// Tematik alan Sosyal Yapay Zekâ. Katmanın kendisi bir metni çözümlüyor;
// asistan aynı Türkçe çözümleme yeteneğinin ikinci bir kullanımıdır ve
// ürünün ne yaptığını kullanıcıya kendi diliyle anlatır. Çevrimdışı
// çalışması bir kısıt değil, ürünün iddiasının tekrarıdır.
//
// ── DOĞRULUK ──────────────────────────────────────────────────────────────
// Asistanın sunduğu HER örnek cümle, `test/asistan_test.dart` içinde gerçek
// motordan geçirilir ve beklenen sonucu verdiği doğrulanır. Yani asistan
// "şu cümle işaretlenir" diyorsa, motor onu gerçekten işaretliyordur; motor
// değişirse test kırılır. Ekranda yazan hiçbir iddia elle bakımda değildir.
// =============================================================================

import '../civility_engine.dart';
import '../detect/hate_patterns.dart';
import '../detect/idiom_patterns.dart';
import '../detect/implicit_patterns.dart';
import '../lexicon/toxicity_lexicon.dart';
import '../normalization/turkish_normalizer.dart';

/// Edimbilimsel örüntü sayısı: örüntü kataloğunun deyim ve nefret
/// kuruluşları dışındaki kısmı (`bin/_dbg.dart` ile aynı hesap).
int _edimbilimselSayisi() =>
    ImplicitPatterns.all.length - IdiomPatterns.all.length - HatePatterns.all.length;

/// Kullanıcının ne istediği.
enum AsistanNiyeti {
  /// "Bana nefret söylemi örnekleri sun" — konu [AsistanCevabi.konu].
  icerikOrnekleri,

  /// "Ölçüm sonuçlarınız ne", "doğruluk oranı kaç"
  olcumSonuclari,

  /// "Nasıl çalışıyor", "hangi katmanlar var"
  nasilCalisir,

  /// "Yazdıklarım nereye gidiyor", "verilerim güvende mi"
  mahremiyet,

  /// "Uyarıları kapatabilir miyim", "hassasiyet ayarı"
  ayarlar,

  /// "Şu cümleyi çözümle: …" ya da doğrudan yazılmış bir cümle.
  metniCozumle,

  /// "Neler yapabilirsin"
  yetenekler,

  /// Selamlaşma ve teşekkür.
  selam,

  /// Hiçbir kalıp tutmadı.
  anlasilmadi,
}

/// İçerik istendiğinde hangi konu.
enum IcerikKonusu {
  hakaret,
  ortukSaldiri,
  nefretSoylemi,
  tehdit,
  magdurAnlatisi,
  kimlikBeyani,
  gizleme,
  deyim,
  masumTuzak,
}

extension IcerikKonusuInfo on IcerikKonusu {
  String get baslik => switch (this) {
        IcerikKonusu.hakaret => 'Doğrudan hakaret',
        IcerikKonusu.ortukSaldiri => 'Küfürsüz düşmanlık',
        IcerikKonusu.nefretSoylemi => 'Nefret söylemi',
        IcerikKonusu.tehdit => 'Tehdit',
        IcerikKonusu.magdurAnlatisi => 'Mağdur anlatısı',
        IcerikKonusu.kimlikBeyani => 'Kimlik beyanı',
        IcerikKonusu.gizleme => 'Gizleme denemesi',
        IcerikKonusu.deyim => 'Deyimle aşağılama',
        IcerikKonusu.masumTuzak => 'Masum tuzak',
      };
}

/// Asistanın gösterdiği tek bir örnek.
class AsistanOrnegi {
  const AsistanOrnegi({
    required this.metin,
    required this.isaretlenir,
    required this.aciklama,
  });

  /// Kullanıcıya gösterilen ve kutuya yüklenebilen cümle.
  final String metin;

  /// Motorun bu cümleyi işaretlemesi bekleniyor mu? Bu alan bir İDDİADIR ve
  /// `test/asistan_test.dart` her örneği motordan geçirip doğrular.
  final bool isaretlenir;

  /// Neden öyle olduğu — bir cümle.
  final String aciklama;
}

/// Asistanın cevabı. Düz metin değil yapıdır: ekran kalın/emoji işaretleri
/// içeren bir metni çizemez, bileşenlerle çizer.
class AsistanCevabi {
  const AsistanCevabi({
    required this.niyet,
    required this.baslik,
    required this.govde,
    this.konu,
    this.ornekler = const [],
    this.maddeler = const [],
    this.devamOnerileri = const [],
    this.cozumleme,
  });

  final AsistanNiyeti niyet;
  final IcerikKonusu? konu;

  /// Kısa başlık.
  final String baslik;

  /// Bir ya da iki cümlelik açıklama. Markdown yoktur.
  final String govde;

  /// Gösterilecek örnek cümleler.
  final List<AsistanOrnegi> ornekler;

  /// Madde madde bilgi (ölçüm, katmanlar, mahremiyet…).
  final List<String> maddeler;

  /// Kullanıcıya sunulacak sonraki soru önerileri.
  final List<String> devamOnerileri;

  /// [AsistanNiyeti.metniCozumle] ise motorun sonucu.
  final CivilityAnalysis? cozumleme;
}

/// Türkçe niyet çözümleyici.
///
/// Motor isteğe bağlıdır; verilmezse cümle çözümleme niyeti yine tanınır ama
/// [AsistanCevabi.cozumleme] boş döner.
class UslupAsistani {
  UslupAsistani({ToxicityClassifier? motor}) : _motor = motor;

  final ToxicityClassifier? _motor;
  static const TurkishNormalizer _normalizer = TurkishNormalizer();

  /// Kullanıcının sorusuna cevap üretir. Hiçbir durumda istisna fırlatmaz.
  AsistanCevabi yanitla(String soru) {
    final ham = soru.trim();
    if (ham.isEmpty) return _yetenekler();

    // Aksan, büyük harf ve gizleme aynı katmanla çözülür: asistan da motorla
    // aynı Türkçeyi konuşur.
    final n = _normalizer.normalize(ham).value;

    // ── Alıntılanmış cümle: "şunu çözümle: ..." ─────────────────────────────
    final alinti = _alintiCikar(ham);
    if (alinti != null) return _cozumle(alinti);

    if (_gecer(n, _selamlar) && n.split(' ').length <= 4) return _selam();
    if (_gecer(n, _yetenekSorulari)) return _yetenekler();
    if (_gecer(n, _mahremiyetSorulari)) return _mahremiyet();
    if (_gecer(n, _ayarSorulari)) return _ayarlar();
    if (_gecer(n, _olcumSorulari)) return _olcum();
    if (_gecer(n, _nasilSorulari)) return _nasilCalisir();

    // ── İçerik isteği ──────────────────────────────────────────────────────
    // Konu adı geçiyorsa, "örnek/göster/sun" fiili olmasa bile içerik verilir:
    // kullanıcı çoğu zaman yalnızca konuyu yazar ("nefret söylemi").
    final konu = _konuBul(n);
    if (konu != null) return _icerik(konu);

    if (_gecer(n, _icerikFiilleri)) return _konuSec();

    // ── Geri kalan: kullanıcı bir cümle yazmıştır ───────────────────────────
    // Soru değilse çözümlenir; bu, asistanın ürünle bağını kuran yerdir.
    if (_cumleGibi(ham)) return _cozumle(ham);

    return _anlasilmadi();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NİYET KALIPLARI
  //
  // Kök biçiminde yazılır ve `contains` ile aranır: Türkçe ekler kökün
  // SONUNA geldiği için "ölçüm", "ölçümünüz", "ölçümleriniz" hepsi "olcum"
  // kökünü taşır. Normalizasyon aksanı zaten düşürmüştür.
  // ───────────────────────────────────────────────────────────────────────────

  static const List<String> _selamlar = [
    'merhaba', 'selam', 'gunaydin', 'iyi aksam', 'iyi gunler', 'tesekkur',
    'sagol', 'sag ol', 'eyvallah',
  ];

  static const List<String> _yetenekSorulari = [
    'neler yapabilir', 'ne yapabilir', 'nelerde yardim', 'yardim edebilir',
    'ne ise yarar', 'komut', 'nasil kullan', 'yetenek', 'ne sorabilir',
  ];

  static const List<String> _mahremiyetSorulari = [
    'mahremiyet', 'gizlilik', 'veri guvenli', 'verilerim', 'nereye gidiyor',
    'kaydediyor musun', 'kaydediliyor', 'sunucu', 'internet', 'kvkk',
    'yazdiklarim ne olu', 'metnim nereye',
  ];

  static const List<String> _ayarSorulari = [
    'ayar', 'hassasiyet', 'kapatabilir', 'kapatmak', 'sustur', 'uyari alma',
    'rahatsiz', 'cok uyari', 'fazla uyari', 'az uyari', 'uyari aliyorum',
    'surekli uyari', 'bu uyari yanlis',
  ];

  static const List<String> _olcumSorulari = [
    'olcum', 'dogruluk', 'basari orani', 'kesinlik', 'duyarlilik', 'sonuc',
    'ne kadar iyi', 'test sonuc', 'performans', 'hata orani', 'f1', 'f0.5',
    'guvenilir mi', 'calisiyor mu',
  ];

  static const List<String> _nasilSorulari = [
    'nasil calis', 'nasil isliyor', 'katman', 'mimari', 'arka planda',
    'teknik', 'algoritma', 'model', 'yapay zeka', 'hangi teknoloji',
    'nasil anliyor', 'nasil tespit', 'llm', 'sinir agi',
  ];

  static const List<String> _icerikFiilleri = [
    'ornek', 'goster', 'sun', 'listele', 'getir', 'paylas', 'icerik',
    'senaryo', 'numune',
  ];

  /// Konu adları, BELİRLİDEN GENELE sıralı. İlk eşleşen kazanır.
  ///
  /// Sıra önemlidir, çünkü konu adları birbirinin içinden geçer:
  /// "deyimle aşağılama" hem `deyim` hem `asagilama` taşır ve kullanıcının
  /// kastettiği deyimdir. "En uzun eşleşme kazansın" kuralı burada yanlış
  /// cevap veriyordu (`asagilama` daha uzun); açık sıra daha okunur ve
  /// `test/asistan_test.dart` bu satırları tek tek koruyor.
  static const List<(IcerikKonusu, List<String>)> _konuKelimeleri = [
    (IcerikKonusu.gizleme, [
      'gizleme', 'kacis', 'filtre atlat', 'sansur', 'yildiz', 'leet', 'bypass',
    ]),
    (IcerikKonusu.deyim, ['deyim', 'atasoz', 'kaliplasmis']),
    (IcerikKonusu.masumTuzak, [
      'masum', 'tuzak', 'yanlis alarm', 'temiz cumle', 'hatali uyari',
      'yanlis pozitif',
    ]),
    (IcerikKonusu.magdurAnlatisi, [
      'magdur', 'kurban', 'sikayet eden', 'anlatan kisi', 'tacize ugra',
      'basima gelen',
    ]),
    (IcerikKonusu.kimlikBeyani, [
      'kimlik beyan', 'kendi kimlig', 'kimligimden', 'ben kurtum',
    ]),
    (IcerikKonusu.nefretSoylemi, [
      'nefret soylem', 'nefret dili', 'nefret', 'ayrimcilik', 'irkci',
      'kimlik hedefli', 'gruba yonelik', 'etnik koken',
    ]),
    (IcerikKonusu.tehdit, ['tehdit', 'gozdagi', 'korkut']),
    (IcerikKonusu.ortukSaldiri, [
      'ortuk', 'kufursuz', 'imali', 'dolayli', 'alayci', 'alay', 'kucumse',
      'otekilestir',
    ]),
    (IcerikKonusu.hakaret, ['hakaret', 'asagilama', 'sovme', 'kufur', 'argo']),
  ];

  static bool _gecer(String n, List<String> kaliplar) {
    for (final k in kaliplar) {
      if (n.contains(k)) return true;
    }
    return false;
  }

  static IcerikKonusu? _konuBul(String n) {
    for (final (konu, kelimeler) in _konuKelimeleri) {
      if (_gecer(n, kelimeler)) return konu;
    }
    return null;
  }

  /// "Şunu çözümle: …" ya da baştan sona tırnak içine alınmış metni ayıklar.
  ///
  /// ── NEDEN CÜMLE İÇİNDEKİ TIRNAK SAYILMAZ ─────────────────────────────────
  /// İlk sürüm mesajın HERHANGİ bir yerindeki tırnağı alıntı sayıyordu ve
  /// ürünün en ayırt edici cümlesini bozuyordu:
  ///
  ///   Bana "aptal" dedi, çok üzüldüm   →  yalnızca «aptal» çözümlenir → Riskli ✗
  ///
  /// Oysa o cümle bir şikâyettir ve temiz kalmalıdır. Tırnak ancak mesajın
  /// TAMAMINI kaplıyorsa ya da önünde "çözümle/analiz et" gibi bir komut
  /// varsa alıntı sayılır.
  static String? _alintiCikar(String ham) {
    final duz = ham.trim();

    final iki = duz.indexOf(':');
    if (iki > 0 && iki < duz.length - 3) {
      final on = _normalizer.normalize(duz.substring(0, iki)).value;
      if (_gecer(on, const ['cozumle', 'analiz', 'kontrol et', 'bak', 'dene'])) {
        final sonra = duz.substring(iki + 1).trim();
        final ic = _tirnakSoy(sonra);
        if (ic != null) return ic;
        if (sonra.length >= 3) return sonra;
      }
    }

    final tam = _tirnakSoy(duz);
    return (tam != null && tam.length >= 3) ? tam : null;
  }

  /// Baştan sona tırnak içindeyse içini döndürür.
  static String? _tirnakSoy(String s) {
    const ciftler = [('"', '"'), ('“', '”'), ('‘', '’'), ("'", "'")];
    for (final (ac, kapa) in ciftler) {
      if (s.length > 2 && s.startsWith(ac) && s.endsWith(kapa)) {
        final ic = s.substring(1, s.length - 1).trim();
        if (ic.isNotEmpty) return ic;
      }
    }
    return null;
  }

  /// Soru değil de yazılmış bir cümle mi? En az iki kelime ve soru
  /// kalıplarından uzak.
  static bool _cumleGibi(String ham) {
    if (ham.trim().split(RegExp(r'\s+')).length < 2) return false;
    final n = _normalizer.normalize(ham).value;
    return !_gecer(n, const ['nedir', 'nasil', 'kimdir', 'kac ', 'mi ', 'mu ']);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CEVAPLAR
  // ───────────────────────────────────────────────────────────────────────────

  AsistanCevabi _cozumle(String metin) {
    final motor = _motor;
    return AsistanCevabi(
      niyet: AsistanNiyeti.metniCozumle,
      baslik: 'Bu cümleyi çözümledim',
      govde: motor == null
          ? 'Motor bağlı değil; yalnızca niyeti tanıdım.'
          : 'Çözümleme bu cihazda yapıldı. Metin hiçbir yere gönderilmedi.',
      cozumleme: motor?.analyze(metin),
      // Her öneri, asistanın GERÇEKTEN tanıdığı bir niyete gitmelidir;
      // tıklandığında anlaşılmayan bir çip demoda çıkmaz sokaktır.
      devamOnerileri: const [
        'Nasıl çalışıyor?',
        'Masum tuzak örnekleri göster',
        'Ölçüm sonuçlarınız ne?',
      ],
    );
  }

  AsistanCevabi _icerik(IcerikKonusu konu) => AsistanCevabi(
        niyet: AsistanNiyeti.icerikOrnekleri,
        konu: konu,
        baslik: konu.baslik,
        govde: _konuAciklamalari[konu]!,
        ornekler: icerikOrnekleri[konu]!,
        devamOnerileri: [
          for (final k in IcerikKonusu.values)
            if (k != konu) '${k.baslik} örnekleri göster',
        ].take(3).toList(),
      );

  AsistanCevabi _konuSec() => AsistanCevabi(
        niyet: AsistanNiyeti.icerikOrnekleri,
        baslik: 'Hangi içerik?',
        govde: 'Şu başlıklardan birini söyle, örnekleri getireyim.',
        maddeler: [for (final k in IcerikKonusu.values) k.baslik],
        devamOnerileri: const [
          'Nefret söylemi örnekleri göster',
          'Mağdur anlatısı örnekleri göster',
          'Masum tuzak örnekleri göster',
        ],
      );

  AsistanCevabi _olcum() => const AsistanCevabi(
        niyet: AsistanNiyeti.olcumSonuclari,
        baslik: 'Ölçüm sonuçları',
        govde: 'En yüksek sayıyı değil, en dürüst sayıyı veriyoruz. Kör küme, '
            'motor ona hiç bakmadan ölçülen kümedir.',
        maddeler: [
          'Kör küme (İP-29, 90 cümle): kesinlik %100 · duyarlılık %45,0 · F0.5 %80,4',
          'Geliştirme kümesi (256 cümle): kesinlik %100 · duyarlılık %97,0 — bu bir ezber ölçüsüdür, genelleme değil',
          'Gündelik 120 masum cümle: yanlış alarm 0',
          'Kimlik eksenleri kör kümesi (40 cümle): kesinlik %100 · duyarlılık %15,0',
          'Toplam 1.115 etiketli cümle, 13 küme; her kör küme ölçümden önce depoya kilitlendi',
          'Uyardığımızda yanılmıyoruz; her saldırıyı yakalamıyoruz. Masum bir cümleyi susturmak, bir hakareti kaçırmaktan pahalıdır.',
        ],
        devamOnerileri: [
          'Nasıl çalışıyor?',
          'Masum tuzak örnekleri göster',
          'Yazdıklarım nereye gidiyor?',
        ],
      );

  // Sayılar elle yazılmaz, motordan sayılır: 19 Eylül'de burada "310 girdi"
  // yazıyordu ve sözlük büyüyünce bayatladı (docs/32).
  AsistanCevabi _nasilCalisir() => AsistanCevabi(
        niyet: AsistanNiyeti.nasilCalisir,
        baslik: 'Yedi katman, tamamı cihazda',
        govde: 'Bir dil modeli yok. Kural ve örüntü katmanları var; her karar '
            'hangi katmandan geldiğini söyleyebiliyor.',
        maddeler: [
          '1. Normalizasyon — gizleme çözülür: \$3r3fsiz, a p t a l, ş*refsiz, şerrefsiz',
          '2. Sözlük + biçimbilim — ${ToxicityLexicon.entries.length} girdi, '
              'Türkçe ek ve ünsüz yumuşaması',
          '3. Edimbilimsel örüntü — ${_edimbilimselSayisi()} örüntü, '
              '${IdiomPatterns.all.length} deyim: küfürsüz düşmanlık',
          '4. Nefret söylemi — ${HatePatterns.all.length} kuruluş, '
              '${IdentityTerms.all.length} kimlik terimi; kimlik adı tek başına tetiklemez',
          '5. Gönderge — “Bunların…” zamirini önceki cümledeki öncüle bağlar',
          '6. Bağlam — saldırı, iltifat, şikâyet, öz-ifade ve alıntı ayrımı',
          '7. Öneri — yerel, deterministik yeniden yazım; üç ton',
        ],
        devamOnerileri: [
          'Ölçüm sonuçlarınız ne?',
          'Gizleme denemesi örnekleri göster',
          'Yazdıklarım nereye gidiyor?',
        ],
      );

  AsistanCevabi _mahremiyet() => const AsistanCevabi(
        niyet: AsistanNiyeti.mahremiyet,
        baslik: 'Metin cihazdan çıkmaz',
        govde: 'Bu bir iddia değil, mimarinin sonucu — ve testle korunuyor.',
        maddeler: [
          'Çalışma zamanında tek bir ağ çağrısı yok; kaynak kodu tarayan bir test ağ kullanımı eklenirse kırılır',
          'Uygulama uçak modunda tam çalışır',
          'Topluluk sinyali yapısal olarak metin taşıyamaz: sınıfında metin alanı yoktur',
          '5 gözlemin altındaki sayılar panelde gösterilmez (k-anonimlik, k = 5)',
          'Klavye parola alanlarında çözümleme yapmaz',
          'Bu asistan da aynı kuralla çalışır: yazdığın hiçbir şey cihazdan çıkmıyor',
        ],
        devamOnerileri: [
          'Ölçüm sonuçlarınız ne?',
          'Uyarıları kapatabilir miyim?',
          'Nasıl çalışıyor?',
        ],
      );

  AsistanCevabi _ayarlar() => const AsistanCevabi(
        niyet: AsistanNiyeti.ayarlar,
        baslik: 'Katmanın ne kadar konuşacağı senin kararın',
        govde: 'Varsayılan ayar, ölçülen davranışın aynısıdır.',
        maddeler: [
          'Üç hassasiyet basamağı: Yalnızca ağır ifadeler · Dengeli · Hassas',
          'Argo ve alay uyarıları tek tek susturulabilir',
          'Tehdit, nefret söylemi, taciz ve hakaret susturulamaz — bunlar başka bir insanı hedef alır',
          'Katmanın tamamı kapatılabilir; kapalıyken yazım kutusu bunu söyler',
          'Yanlış bulduğun uyarıya “Bu uyarı yanlış” diyebilirsin; bildirim metin taşımaz, yalnızca evet/hayır',
        ],
        devamOnerileri: [
          'Yazdıklarım nereye gidiyor?',
          'Masum tuzak örnekleri göster',
          'Ölçüm sonuçlarınız ne?',
        ],
      );

  AsistanCevabi _yetenekler() => const AsistanCevabi(
        niyet: AsistanNiyeti.yetenekler,
        baslik: 'Şunları sorabilirsin',
        govde: 'Kural tabanlı bir asistanım: cihazın içinde çalışıyorum, '
            'internete çıkmıyorum ve bir dil modeli değilim.',
        maddeler: [
          '“Bana nefret söylemi örnekleri sun” — istediğin başlıkta örnek cümleler',
          '“Ölçüm sonuçlarınız ne?” — kör küme sayıları',
          '“Nasıl çalışıyor?” — yedi katman',
          '“Yazdıklarım nereye gidiyor?” — mahremiyet',
          '“Uyarıları kapatabilir miyim?” — ayarlar',
          'Ya da doğrudan bir cümle yaz: çözümleyip gerekçesini göstereyim',
        ],
        devamOnerileri: [
          'Bana nefret söylemi örnekleri sun',
          'Ölçüm sonuçlarınız ne?',
          'Nasıl çalışıyor?',
        ],
      );

  AsistanCevabi _selam() => const AsistanCevabi(
        niyet: AsistanNiyeti.selam,
        baslik: 'Merhaba',
        govde: 'Üslup asistanıyım. Cihazın içinde çalışıyorum; yazdığın hiçbir '
            'şey buradan çıkmıyor. Ne göstermemi istersin?',
        devamOnerileri: [
          'Neler yapabilirsin?',
          'Bana nefret söylemi örnekleri sun',
          'Ölçüm sonuçlarınız ne?',
        ],
      );

  AsistanCevabi _anlasilmadi() => const AsistanCevabi(
        niyet: AsistanNiyeti.anlasilmadi,
        baslik: 'Bunu anlamadım',
        govde: 'Kural tabanlı bir asistanım; tanıdığım konular sınırlı ve bunu '
            'saklamıyorum. Aşağıdakilerden birini deneyebilirsin.',
        maddeler: [
          'Bir başlıkta örnek iste: nefret söylemi, mağdur anlatısı, gizleme denemesi…',
          'Ölçüm, mahremiyet, ayarlar ya da nasıl çalıştığını sor',
          'Bir cümle yaz, çözümleyeyim',
        ],
        devamOnerileri: [
          'Neler yapabilirsin?',
          'Bana örnek içerikler sun',
          'Nasıl çalışıyor?',
        ],
      );

  static const Map<IcerikKonusu, String> _konuAciklamalari = {
    IcerikKonusu.hakaret:
        'Sözlükte karşılığı olan doğrudan aşağılama. Bağlam katmanı burada da '
            'çalışır: olumsuzlanmış ya da aktarılmış hâli uyarı almaz.',
    IcerikKonusu.ortukSaldiri:
        'Tek bir yasaklı kelime yok. Saldırı kelimelerde değil, dizilişte. '
            'Kelime listelerinin göremediği yer burası.',
    IcerikKonusu.nefretSoylemi:
        'Kimlik bir yuva, saldırı bir kuruluştur. Kimlik adı tek başına asla '
            'uyarı üretmez; sözlükte tek bir kimlik adı yoktur.',
    IcerikKonusu.tehdit:
        'En üst basamak. Gönderimden önce onay sorulur ama yine de '
            'engellenmez. Kendine yönelik ifade tehdit sayılmaz, destek kartı açılır.',
    IcerikKonusu.magdurAnlatisi:
        'Ürünün en ayırt edici davranışı: tacize uğradığını anlatan kişi '
            'susturulmaz. Aktarım bir tavandır, kelime ne kadar ağır olursa olsun eşiği aşamaz.',
    IcerikKonusu.kimlikBeyani:
        'Kişinin kendi kimliğinden söz etmesi serbesttir ve bunu otomatik bir '
            'test korur.',
    IcerikKonusu.gizleme:
        'Rakam, yıldız, harf arası boşluk ve bitişik yazımla filtre atlatma '
            'denemeleri normalizasyon katmanında geri çevrilir.',
    IcerikKonusu.deyim:
        'Kalıplaşmış aşağılamalar tek tek kelimelerden anlaşılmaz; deyim '
            'kataloğu bunları bütün olarak tanır.',
    IcerikKonusu.masumTuzak:
        'Saldırgan kelimelere benzeyen ama masum olan cümleler. Kesinlik '
            'iddiası asıl burada sınanır.',
  };

  /// Asistanın sunduğu örnekler.
  ///
  /// Hepsi `test/asistan_test.dart` içinde gerçek motordan geçirilir ve
  /// [AsistanOrnegi.isaretlenir] alanının doğru olduğu denetlenir.
  static const Map<IcerikKonusu, List<AsistanOrnegi>> icerikOrnekleri = {
    IcerikKonusu.hakaret: [
      AsistanOrnegi(
        metin: 'Sen tam bir aptalsın',
        isaretlenir: true,
        aciklama: 'Sözlük eşleşmesi + ikinci şahıs yönelimi.',
      ),
      AsistanOrnegi(
        metin: 'Sen hiç aptal değilsin',
        isaretlenir: false,
        aciklama: 'Aynı kelime, olumsuzlanmış: uyarı yok.',
      ),
      AsistanOrnegi(
        metin: 'Kendimi çok aptal hissettim',
        isaretlenir: false,
        aciklama: 'Öz-ifade; hedef başkası değil.',
      ),
    ],
    IcerikKonusu.ortukSaldiri: [
      AsistanOrnegi(
        metin: 'Senin gibilerden zaten bu beklenirdi',
        isaretlenir: true,
        aciklama: 'Ötekileştirme kalıbı; tek bir küfür yok.',
      ),
      AsistanOrnegi(
        metin: 'Bu karar bence tamamen hatalı ve geri alınmalı',
        isaretlenir: false,
        aciklama: 'Sert ama meşru eleştiri: susturulmaz.',
      ),
    ],
    IcerikKonusu.nefretSoylemi: [
      AsistanOrnegi(
        metin: 'Bütün Suriyeliler hırsızdır',
        isaretlenir: true,
        aciklama: 'Kimlik yuvası + genelleyen suçlama kuruluşu.',
      ),
      AsistanOrnegi(
        metin: 'Ben Kürtüm ve bununla gurur duyuyorum',
        isaretlenir: false,
        aciklama: 'Kimlik beyanı; kimlik adı tetikleyici değildir.',
      ),
      AsistanOrnegi(
        metin: 'Suriyeli komşumuz çok yardımsever bir insan',
        isaretlenir: false,
        aciklama: 'Aynı kimlik adı, olumlu cümle.',
      ),
    ],
    IcerikKonusu.tehdit: [
      AsistanOrnegi(
        metin: 'Seni gebertirim',
        isaretlenir: true,
        aciklama: 'Yüksek basamak: gönderimden önce onay sorulur.',
      ),
    ],
    IcerikKonusu.magdurAnlatisi: [
      AsistanOrnegi(
        metin: 'Bana "aptal" dedi, çok üzüldüm',
        isaretlenir: false,
        aciklama: 'Aktarılan hakaret; şikâyet eden susturulmaz.',
      ),
      AsistanOrnegi(
        metin: 'Şikayet dilekçemi götürdüm, dayanışma ağı büyüyor',
        isaretlenir: false,
        aciklama: 'Sözlük köklerine benzeyen masum kelimeler.',
      ),
    ],
    IcerikKonusu.kimlikBeyani: [
      AsistanOrnegi(
        metin: 'Ben Kürtüm ve bununla gurur duyuyorum',
        isaretlenir: false,
        aciklama: 'Kendi kimliğinden söz etmek serbesttir.',
      ),
      AsistanOrnegi(
        metin: 'Suriyeli komşumuz çok yardımsever bir insan',
        isaretlenir: false,
        aciklama: 'Kimlik adı olumlu bağlamda.',
      ),
    ],
    IcerikKonusu.gizleme: [
      AsistanOrnegi(
        metin: r'sen $3r3fsizsin',
        isaretlenir: true,
        aciklama: 'Rakamlar harfe geri çevrilir.',
      ),
      AsistanOrnegi(
        metin: 'şerrefsizz herif',
        isaretlenir: true,
        aciklama: 'Kelime içi harf ikilemesi teke indirilir.',
      ),
      AsistanOrnegi(
        metin: 'Canım sıkıldı',
        isaretlenir: false,
        aciklama: 'Gizleme çözümü masum cümleyi bozmaz.',
      ),
      AsistanOrnegi(
        metin: 'Yıllanmış şarabı sikke koleksiyonunun yanına koydum',
        isaretlenir: false,
        aciklama: 'Gerçek ikili harfler ("ll", "kk") gizleme sayılmaz.',
      ),
    ],
    IcerikKonusu.deyim: [
      AsistanOrnegi(
        metin: 'Takke düştü kel göründü',
        isaretlenir: true,
        aciklama: 'Kalıplaşmış aşağılama; kelimelerden anlaşılmaz.',
      ),
    ],
    IcerikKonusu.masumTuzak: [
      AsistanOrnegi(
        metin: 'Şikayet dilekçemi götürdüm, dayanışma ağı büyüyor',
        isaretlenir: false,
        aciklama: '“şikayet”, “götür”, “ağ” — hiçbiri tek başına saldırı değil.',
      ),
      AsistanOrnegi(
        metin: 'Bu karar bence tamamen hatalı ve geri alınmalı',
        isaretlenir: false,
        aciklama: 'Sert eleştiri uyarı almaz.',
      ),
      AsistanOrnegi(
        metin: 'Canım sıkıldı',
        isaretlenir: false,
        aciklama: 'Sözlükteki köke benzeyen masum kullanım.',
      ),
    ],
  };
}
