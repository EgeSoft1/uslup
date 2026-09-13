# Üslup

**Cihaz üzerinde çalışan, Türkçe'ye özel nezaket katmanı.**
Saldırgan bir gönderi *gönderilmeden önce*, cihazın kendi içinde tespit edilir
ve daha yapıcı bir alternatif önerilir. Metin cihazdan hiç çıkmaz.

> NSosyal İnovasyon Yarışması 2026 · Tematik alan: **Sosyal Yapay Zekâ**

---

## Problem

Sosyal medyada nefret söylemi ve hakaret bugün **yayın sonrasında** yönetiliyor:
içerik yayınlanır → şikâyet edilir → moderatör inceler → silinir. Üç kırılgan
nokta var:

- **Zarar çoktan oluşmuştur.** Silmek, hedef kişinin onu görmüş olmasını geri almaz.
- **Yaptırım davranışı değiştirmez.** Cezalandırıldığını hisseden kullanıcı öfkelenir.
- **Mağdur cezalandırılır.** Tacize uğradığını anlatan kullanıcı ("bana 'şerefsiz'
  dedi") kendi mesajı işaretlendiği için susturulur.

## Yaklaşım

Müdahale, yayın sonrasından **yayın öncesine** taşınır. Kullanıcı cümleyi
yazarken çözümleme yapılır; sistem hiçbir metni engellemez veya değiştirmez —
öneri sunar, kararı kullanıcı verir.

```
Kullanıcı yazıyor
   │
   ▼  ── CİHAZ ÜZERİNDE ──────────────────────────────────────────────
   │  1. Normalizasyon      "$3r3fsiz" → "serefsiz", "aptaaaal" → "aptal"
   │  2. Sözlük eşleştirme  Türkçe eklemeli yapı: kök eşleşmesi
   │  3. Örüntü katmanı     Küfürsüz düşmanlık — kelimede değil, DİZİLİŞTE
   │  4. Nefret katmanı     Kimlik hedefli düşmanlık (kimlik adı ≠ yasaklı kelime)
   │  5. Gönderge katmanı   Kimlik önceki cümledeyse zamiri ona bağlar
   │  6. Bağlam çözümleme   saldırı / iltifat / şikâyet / öz-ifade ayrımı
   │  7. Öneri üretimi      Yerel, deterministik yeniden yazım
   ▼  ─────────────────────────────────────────────────────────────────
Kullanıcı seçer → gönderir

Sunucu adımı yoktur. Hattın tamamı cihazda biter.
```

### Kimlik adı yasaklı kelime değildir

Nefret söylemi filtrelerinin yaygın kusuru, korunan grubun adını yasaklı kelime
listesine koymaktır — sonuç ters teper ve korumaya çalıştığı grubu susturur.

```
"Ben Kürtüm"                   → işaretlenmez
"Eşcinsel hakları konferansı"  → işaretlenmez
"Bütün Kürtler hırsızdır"      → işaretlenir
```

Kimlik adları yalnızca düşmanca bir **kuruluşun** içindeki yuvayı doldurur;
tek başlarına hiçbir şey tetiklemez. Sözlükte tek bir kimlik adı yoktur ve bu,
`test/hate_layer_test.dart` içinde **yapısal bir testle** korunur — sözlüğe
kimlik adı sızarsa test kırılır.

---

## Ürün kabuğu — katman nereye takılıyor

Üslup bir uygulama değil, bir sosyal platformun **metin giriş noktalarına
düşen bir katmandır**. Bunu boş bir ekranda göstermek onu bir yazım
denetleyicisine indirgerdi; bu yüzden prototip gerçek bir akış kabuğu taşır:

| Yüzey | Katman burada çalışıyor mu |
|---|---|
| Akış · gönderi kartları · medya | — (okuma yüzeyi) |
| **Yeni gönderi kutusu** | **Evet** |
| **Gönderi altındaki yanıt kutusu** | **Evet** |
| **Üslup panelindeki deneme kutusu** | **Evet** |
| Keşfet arama kutusu | Hayır — yazılan metin kimseye ulaşmaz |
| Bildirimler · profil · topluluk paneli | — |

Üçü de **aynı** `CivilityComposer` bileşenidir. Yorum kutusuna ikinci bir kod
yolu yazılsaydı, o yol test edilmediği için sessizce eskirdi.

Yanıt kutusunun ayrıca olması ürünsel bir karardır: **insan boş bir kutuya
oturup hakaret yazmaz, birinin söylediği bir şeye sinirlenip yazar.** Katman
yalnızca gönderi kutusunda çalışsaydı, hedeflediği anın büyük bölümünü
ıskalardı.

### İki iddia, iki yapısal test

`mobile/test/kapsam_degismezi_test.dart` kaynak kodu okur ve iki cümleyi
kilitler:

```
1. "Katman her metin giriş noktasında çalışır."
   → lib/ altındaki her ham TextField sayılır; izinli listede olmayan
     bir tane bulunursa test kırılır.

2. "Ürün çalışma zamanında tek bir ağ çağrısı yapmaz."
   → Image.network, NetworkImage, HttpClient, WebSocket, package:http
     aranır. Tek bir avatar görselini indirmek bu iddiayı çürütürdü.
```

Eksik olanı davranış testiyle yakalayamazsınız — kırılan bir şey yoktur,
eksik olan bir şey vardır. Kaynağı okumak gerekir. Aynı yöntem sözlüğe
kimlik adı sızmasını ve anonim sinyalin metin taşımasını engelleyen
testlerde de kullanılıyor.

Ayrıntı: [`docs/16_URUN_KABUGU.md`](docs/16_URUN_KABUGU.md)

---

## Ölçülen sonuçlar

Geçerli genelleme ölçümü **altıncı ayrık kümedir (İP-29)** — bugünkü motor,
hiç görmediği 90 cümle, küme ölçümden ÖNCE commit edildi (`9179ee4`), sonuç
düzeltilmeden raporlanıyor. Kayıt:
[`docs/18_IP29_ILK_GECIS.md`](docs/18_IP29_ILK_GECIS.md)

| İP-29 ilk geçiş | Değer |
|---|---|
| **Kesinlik** | **%96,4** — 30 masum cümlenin 29'u temiz kaldı |
| **Duyarlılık** | **%45,0** |
| **F0.5** — ürünün hedef fonksiyonu | **%78,5** |
| Açık saldırı · örtük saldırı (duyarlılık) | %83,3 · %32,4 |
| Bilinen yeteneklerin yeni kuruluşları | 16/30 (%53,3) |
| Serbest düşmanca ifadeler (deyim, lanet, cinsiyet/yaş hedefli) | 11/30 (%36,7) |

Önceki beş ayrık kümenin beşi de yanmıştır — motor her birine bakılarak
düzeltildi. Aşağıdaki tablo **önceki** raporlanan ölçümdür (İP-22); tam geçmiş:
[`docs/14_MENTORLUK_PENCERESI_SONUCLARI.md`](docs/14_MENTORLUK_PENCERESI_SONUCLARI.md)

| İP-22 (geçmiş kayıt) | Değer |
|---|---|
| Kesinlik (İP-22 ilk geçiş) | %90,5 → **%100,0** (iki kusur düzeltildikten sonra) |
| F0.5 — ürünün hedef fonksiyonu | %79,8 → **%85,6** |
| F1 | %67,9 → %70,4 |
| Duyarlılık | **%54,3** |
| **Yapısal ailenin genelleme oranı** | **%90,0** — aynı yapının hiç görülmemiş örneklerinde |
| Çözümleme süresi | Mesaj **p50 206 µs · p99 2.519 µs** · 2.400 karakterlik gönderi **p99 10,2 ms** (kare bütçesinin %64'ü) — AOT, 13 Eylül 2026, `bin/benchmark.dart`. Aynı gün, aynı makinede eski motor 600 karakterde bütçeyi aşıyordu (p99 16,5 ms); sözlük dizini ve örüntü ön filtresi çıktıyı değiştirmeden 5–7 kat hızlandırdı |

### Ölçüm geçmişi — neden tek bir sayı yok

| Küme | Boyut | Kesinlik | Duyarlılık | F1 | Durum |
|---|:--:|:--:|:--:|:--:|---|
| Geliştirme | 256 | %100 | %97,0 | %98,5 | Ezberleme payı içerir (13 Eylül: 3 alay örneği bilerek bırakıldı — docs/20) |
| 1. ayrık | 80 | %98,0 | %100 | %99,0 | Yanmış (ilk ölçüm F1 %84,2) |
| 2. ayrık (İP-15) | 100 | %100 | %38,5 | %55,6 | Yanmış (İP-19 onarımında kullanıldı) |
| 3. ayrık (İP-20) | 80 | %100 | %50,0 | %66,7 | Yanmış (İP-21 onarımında kullanıldı) |
| 4. ayrık (İP-22) | 65 | %90,5 | %54,3 | %67,9 | Yanmış (İP-26 genişletmesinde kullanıldı) |
| 5. ayrık (İP-27) | 90 | kayıt yok | ≈%48 | — | Yanmış (İP-28 deyim katmanında kullanıldı) |
| **6. ayrık (İP-29)** | **90** | **%96,4** | **%45,0** | **%61,4** | **Geçerli — ilk geçiş, ölçümden önce kilitlendi** |
| Gündelik metin (İP-30) | 120 masum | — | — | — | Yanlış alarm **17 → 0** (özgüllük %85,8 → %100). Hata türleri bilindikten sonra, düzeltmeden önce yazıldı — o türlere kör değil |

### Gündelik metin — İP-29'un göremediği kesinlik açığı

İP-29'un masum dilimi 30 bağlam tuzağından oluşur ve gündelik metni temsil
etmez. 13 Eylül'deki küme dışı tarama bunu gösterdi: **"Sana katılıyorum ama
bence yanlış"** cümlesi Yüksek risk (küfür) alıyordu — "ama", kısa kök "am" +
"a" diye çözülüyordu. "Sana sıkı sıkı sarılıyorum", "Allah razı olsun senden,
amin", "Çok yazık oldu, geçmiş olsun" ve kendine zarar ifadeleri de işaretlenen
gündelik cümleler arasındaydı; sonuncusu "suç oluşturabilir" onayı açıyordu.

Düzeltmeler ölçümden önce kayda geçirildi (docs/20), yeni bir gündelik küme
düzeltmeden önce commit edildi. Sonuç: gündelik kümede 17 yanlış alarm 0'a
indi, **İP-29'da tek bir örnek değişmedi**. Bedeli açık: yazılı tek cümlede
içten övgüden ayırt edilemeyen alay kalıpları kaldırıldı ve geliştirme
kümesinde duyarlılık %99,2'den %97,0'a indi.

### Duyarlılık sayısı neyin cevabı

İP-22 üç eşit parçadan kuruldu ve toplam duyarlılığı ayrıştırdı:

| Parça | Örnek | Sonuç |
|---|:--:|:--:|
| Yapısal ailelerin **hiç görülmemiş örnekleri** | 20 | **%90,0** |
| Aynı ailelerin **yakın-kaçışları** (masum) | 20 | **11 yeni ailenin hiçbirinden yanlış pozitif yok** |
| Hiçbir ailede karşılığı **olmayan** deyimler | 15 | %6,7 |

Yani %54,3, "motor ne kadar iyi" sorusunun değil, **"kaç yapı ailesi
yazıldı"** sorusunun cevabıdır. Yazılmış bir ailenin yeni örneklerini motor
%90 görüyor; yazılmamış bir aileyi göremiyor. Türkçe deyim uzayı sonlu bir
örüntü kataloğuyla kapatılamaz — bu, kural tabanlı katmanın tavanıdır ve
gizlenmemektedir.

**Dürüstlük notu.** Geliştirme kümesindeki %98,5 (F1) bir genelleme kanıtı
**değildir** — kümeyi de örüntüleri de aynı kişi yazmıştır. Ayrık kümeler bunu
sayıya çevirdi: örtük saldırı diliminde duyarlılık %100'den %12,0'ye düştü.

**Dördüncü küme bir kesinlik felaketi buldu.** `"bardak dolu"` cümlesi yüksek
riskli **nefret söylemi** sayılıyordu. Sebep: `dölü` epiteti aksan
katlamasından sonra (`ö→o`, `ü→u`) `dolu` ile birebir aynı hâle geliyor ve tam
eşleşme modundaki girdi Türkçe'nin en sık kelimelerinden birini yakalıyordu.
Önceki 521 örneğin hiçbirinde "dolu" geçmediği için kusur görünmemişti.
Girdi kaldırıldı; ayrıntı [`docs/14`](docs/14_MENTORLUK_PENCERESI_SONUCLARI.md) §9.3.

Bu, ayrık küme disiplininin neden vazgeçilmez olduğunun kanıtıdır: kusuru
bulan şey, kümenin **saldırganlıkla hiç ilgisi olmayan** kısmıydı.

---

## Çalıştırma

Çekirdek motor **saf Dart**'tır; Flutter gerektirmez.

```bash
cd packages/civility_core
dart pub get
dart test                          # çekirdek testler
dart run bin/evaluate.dart --hepsi # tüm metrikler
dart run bin/evaluate.dart --karsilastir  # katman katkısı A/B
dart run bin/evaluate.dart --genelleme3   # geçerli genelleme ölçümü (İP-22)
dart run bin/rewrite_audit.dart --hepsi   # öneri kalitesi: çeşitlilik + dilbilgisi

# Gecikme ölçümü — ÜRÜN sayısı için AOT derleyin
dart compile exe bin/benchmark.dart -o benchmark.exe && ./benchmark.exe

# İkinci etiketleyici için kör etiketleme dosyası + hakemler arası uyum
dart run bin/annotate_export.dart --kume=ip20 > etiketleme.csv
dart run bin/kappa.dart etiketleme.csv
```

Erişilebilirlik denetimi (Flutter gerektirmez):

```bash
cd mobile
dart run tool/erisilebilirlik_denetimi.dart   # WCAG 2.1 AA kontrast oranları
```

Mobil uygulama (Flutter):

```bash
cd mobile
flutter pub get
flutter run
```

Jüri sunumu — **internetsiz** masaüstü demo:

```bash
cd mobile
flutter build web --release --no-web-resources-cdn   # bir kez, internet varken
# sonra depo kökünde SUNUMU_BASLAT.bat → yerel sunucu + tam ekran pencere
flutter test tool/ekran_goruntusu_test.dart          # slayt ekran görüntüleri
```

Sunum akışı ve hazır cevaplar: [`docs/17_JURI_DEMO_SENARYOSU.md`](docs/17_JURI_DEMO_SENARYOSU.md)

---

## Depo yapısı

| Dizin | İçerik |
|---|---|
| `packages/civility_core/` | **Nezaket motoru** — saf Dart, bağımlılıksız. Projenin çekirdeği. |
| `mobile/` | Flutter istemci — sosyal akış kabuğu, gönderi ve yanıt kutuları (katman burada çalışır), Üslup ölçüm paneli, topluluk sağlığı paneli |
| `ml/` | **Denetimli taban çizgisi** — Python/scikit-learn ile eğitilen karşılaştırma modeli. Uygulamada yalnızca ONNX **ikinci görüş** olarak durur: temiz/işaretli kararını hiçbir zaman değiştiremez, yalnızca kural motorunun zaten işaretlediği bir metnin basamağını yükseltebilir. Böylece ölçülen kesinlik uygulamada da birebir geçerlidir. |
| `docs/` | Ürün tanımı, model değerlendirme, kullanıcı akışları, teknik rapor, erişilebilirlik denetimi |
> **Not.** Bu depo, devralınan bir mesajlaşma platformu iskeletinin üzerine
> kurulmuştur. Devralınan sunucu altyapısı (`crates/`, `db/`, `devops/`)
> **üründe kullanılmamaktadır** ve depodan çıkarılmıştır; gerekçesi
> [`docs/02_TEKNIK_BORC.md`](docs/02_TEKNIK_BORC.md) §5'te kayıtlıdır. Üslup'un
> çalışma zamanında hiçbir sunucu bileşeni yoktur.

### Motorun içi

```
packages/civility_core/lib/src/
├── normalization/   tokenizer, Türkçe morfoloji, gizleme direnci
├── lexicon/         toksisite sözlüğü (kimlik adı İÇERMEZ)
├── detect/          edimbilimsel örüntüler + nefret söylemi örüntüleri
├── context/         bağlam çözümleyici — saldırı/iltifat/şikâyet/öz-ifade
├── rewrite/         iki modlu yerel yeniden yazıcı
├── community/       anonim topluluk sağlığı sinyalleri (k-anonimlik)
└── eval/            581 etiketli örnek (5 küme) + kesinlik/duyarlılık/F1/F0.5
```

---

## Etik duruş

1. **Mahremiyet tasarımdan gelir.** Metin cihazdan çıkmaz — gizlilik politikası
   maddesi değil, mimarinin kendisi.
2. **Sansür değil, farkındalık.** Sistem hiçbir metni kendiliğinden değiştirmez
   veya engellemez.
3. **Açıklanabilirlik zorunlu.** Her uyarı "hangi kelime" ve "neden" sorusuna
   cevap verir.
4. **Yanlış pozitif, yanlış negatiften pahalıdır.** Bu yüzden raporlanan asıl
   hedef fonksiyon F0.5'tir.
5. **Mağdur korunur.** Alıntı, aktarım ve öz-ifade ayırt edilir.

## Bilinen sınırlar

- Metrikler **tek etiketleyicilidir**; hakemler arası uyum (kappa) ölçülmemiştir.
  Ölçüm altyapısı hazırdır — `bin/annotate_export.dart` kör etiketleme dosyası
  üretir, `bin/kappa.dart` Cohen's kappa'yı hesaplar; eksik olan ikinci insandır.
- **Duyarlılık sınırlıdır ve örtük saldırıda düşüktür.** Geçerli ayrık
  kümede (İP-29) toplam %45,0: açık saldırıda %83,3, örtük saldırıda %32,4.
  İP-22'de ölçülen "yazılmış ailenin yeni örneklerinde %90" genellenmedi —
  devrik sıra, araya giren zamir ya da farklı kip kalıbın dışına düşüyor
  (İP-29 birinci parça: %53,3). Kural tabanlı bir katman Türkçe deyim ve
  kuruluş uzayını kapsayamaz.
- **Cinsiyet, yaş, engellilik ve göç statüsü hedefli genellemeler
  yakalanmıyor.** Kimlik söz varlığı etnik köken, inanç ve yönelim
  ağırlıklıdır (İP-29 üçüncü parça).
- **Alıntılanan örüntüde mağdur koruması eksik.** Sözlük bulgularında alıntı
  ve aktarım yumuşatılıyor; örüntü bulgusu tırnak içinde kınanarak
  aktarıldığında yumuşatma çalışmadı (İP-29'un tek yanlış pozitifi).
- **"dölü" epiteti kaldırıldı** — aksan katlaması onu "dolu" ile birebir
  aynı hâle getiriyor ve ayırt etmenin normalize metin üzerinde yolu yok.
- Öncülsüz gönderge **kasıtlı olarak** kaçırılır — hedefin kim olduğu metinden
  bilinemez ve zamirden kimlik uydurmak kesinlik iddiasını çürütür.
- Kimlik söz varlığı 94 terimdir (İP-17'de 35'ten genişletildi); siyasi
  görüş **kasıtlı olarak** kapsam dışıdır — korunan nitelik değildir.
- Tüm veri sentetiktir; hiçbir örnek gerçek kullanıcıdan gelmemiştir.
- **Öneri çeşitliliği sınırlı.** En sık öneri, üretilen tüm önerilerin
  %30,8'ini kaplıyor (13 Eylül'de %28,9'dan yükseldi: bozuk Türkçe üreten
  iki yeniden yazım yolu kapatıldı ve o cümleler genel kalıba düşüyor). Daha ileri gitmek her örüntüye kendi nötr karşılığını
  yazmayı gerektirir — algoritma işi değil, veri işi.
- Yalnızca Türkçe desteklenmektedir.
- Bir Büyük Dil Modeli **kullanılmamaktadır** — yazılmış, ölçülmüş ve kasıtlı
  olarak kaldırılmıştır. Gerekçe: [`docs/03_LLM_SERVISI.md`](docs/03_LLM_SERVISI.md)
- Denetimli bir model de eğitilip ölçülmüştür ([`ml/`](ml/)). Aynı ayrık kümede
  kural motorunun kaçırdığı **hiçbir örneği yakalamamış**, buna karşılık motorun
  yapmadığı altı yanlış pozitif üretmiştir — hepsi iltifat, olumsuzlama ya da
  mağduru savunan cümle. Bu, doğrusal bir taban çizgisinin **bu veri hacmindeki**
  sınırıdır; önceden eğitilmiş bir Türkçe modelin de başarısız olacağı
  **iddia edilmemektedir**.

---

## Lisans

MIT — ayrıntı: [`LICENSE`](LICENSE).
Kod, veri kümesi ve ölçüm araçları serbestçe kullanılabilir; tek koşul telif
notunun korunmasıdır.
