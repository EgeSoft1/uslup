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

### Üslup Asistanı

Kabuk ayrıca bir **Türkçe niyet çözümleyici** taşır (docs/29): kullanıcı
"bana nefret söylemi örnekleri sun" ya da "yazdıklarım nereye gidiyor" yazar,
asistan niyeti çıkarıp içeriği getirir; düz bir cümle yazılırsa motora verip
gerekçeli sonucu gösterir.

**Dil modeli yoktur, ağ çağrısı yoktur.** Motorun kendi normalizasyon ve
biçimbilim katmanlarını kullanır — bu yüzden "NEFRET SÖYLEMİ", "nefret
soylemi" ve "nefrét söylemi" aynı yere düşer. Sunduğu her örnek cümle, "bu
işaretlenir / bu temiz" iddiasıyla birlikte gelir ve `test/asistan_test.dart`
her iddiayı gerçek motordan geçirip doğrular: motor değişirse test kırılır,
ekranda yanlış bir iddia kalmaz.

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
hiç görmediği 90 cümle, küme ölçümden ÖNCE commit edildi (`55881fb`), sonuç
düzeltilmeden raporlanıyor. Kayıt:
[`docs/18_IP29_ILK_GECIS.md`](docs/18_IP29_ILK_GECIS.md)

| İP-29 | İlk geçiş | İkinci geçiş (D7) | Üçüncü geçiş (D9) | Dördüncü geçiş (docs/25) | Beşinci geçiş (docs/26) | Bugünkü motor (altıncı geçiş · docs/30) |
|---|---|---|---|---|---|---|
| **Kesinlik** | **%96,4** — 30 masum cümlenin 29'u temiz | %96,2 | %100,0 | %100,0 | %100,0 | **%100,0** — 30 masumun 30'u temiz |
| **Duyarlılık** | **%45,0** | %41,7 | %41,7 | %43,3 | %45,0 | **%46,7** |
| **F0.5** — ürünün hedef fonksiyonu | **%78,5** | %76,2 | %78,1 | %79,3 | %80,4 | **%81,4** |
| Açık saldırı · örtük saldırı (duyarlılık) | %83,3 · %32,4 | %75,0 · %29,4 | %75,0 · %29,4 | %83,3 · %29,4 | %83,3 · %29,4 | %83,3 · %32,4 |
| Bilinen yeteneklerin yeni kuruluşları | 16/30 (%53,3) | 16/30 | 16/30 | 17/30 | 17/30 | 17/30 |
| Serbest düşmanca ifadeler (deyim, lanet, cinsiyet/yaş hedefli) | 11/30 (%36,7) | 9/30 | 9/30 | 9/30 | 10/30 | 11/30 |

İkinci geçiş, kümenin DIŞINDA bulunan bir kesinlik açığının onarımından
sonradır (somut adlarda yapısal yönelim, docs/21): ikinci şahıs geçen gündelik
cümlelerde yanlış alarm 30'da 29'dan 30'da 2'ye indi, karşılığında İP-29'da iki
saldırı örneği kaçtı. Değişiklik bu kümeye bakılarak yapılmadı; küme yanmadı.

Üçüncü geçiş, 13 Eylül kod denetiminin (docs/23) düzeltmelerinden sonradır.
Kümenin tek yanlış pozitifi (`Selin'e "senin gibilerden bu beklenirdi"
demişler`) bir bağlam kuralının değil, **kesme işaretinin tırnak sayılmasının**
sonucuymuş: "Selin'e"deki `'` tırnak açıyor, gerçek tırnaklar yanlış eşleşiyor
ve alıntı görülmüyordu. Hata bu cümleye bakılarak değil, kaynak kod
okunurken bulundu ("Ali'ye söyle sen şerefsizsin Veli'ye de" → Temiz kaçışı);
ancak bu yanlış pozitif README'de önceden yazılı olduğu için sayı **yarı-kör**
kabul edilmeli. Diğer dokuz kümede tek bir örnek değişmedi.

Dördüncü geçiş, küfür kapsamı çalışmasından sonradır (docs/25, 14 Eylül).
Çalışma İP-29'a hiç bakılmadan, 317 cümlelik ayrı bir çekişmeli tarama ve
91.861 biçimlik Türkçe kelime listesiyle yürütüldü: taramada kaçan 111 küfür
biçimi 5'e indi ve kelime listesinde tek bir masum biçim yeni işaretlenmedi.
İP-29'da değişen tek örnek `ahmakk mısın nesin` — kelime sonunda çift harfle
uzatılmış hakaret kuralının hiç görülmemiş bir örneği. Diğer dokuz kümede tek
bir örnek değişmedi.

Beşinci geçiş, kimlik eksenleri çalışmasından sonradır (docs/26, 15 Eylül):
cinsiyet, yaş, engellilik ve göç hedefli genellemeler için 12 yeni kuruluş.
İP-29'da değişen tek örnek `engelliler evde otursun` — istek kipli yer biçme
onarımı İP-34'ün kaçak sınıfından geldi, İP-29'a bakılmadı; ama İP-29'un
kaçak listesi bu README'de yazılı olduğu için sayı **yarı-kör** kabul
edilmeli. Kimlik eksenlerinin kendi geçerli ölçümü aşağıdaki İP-35 satırıdır.

Altıncı geçiş, docs/27–29 çalışmalarından sonradır (18 Eylül). İP-29'da değişen
tek örnek `karşıma çıkma, iyi olmaz` — koşullu örtük tehdit. **Bu örnek kör
sayılmamalıdır:** onu yakalayan `tehdit.denk_gelme` örüntüsünün kaynak
kodundaki açıklaması kümenin kendi cümlesini ("karşıma çıkma") alıntılar, yani
örüntü bu örneğe bakılarak yazılmıştır. Değişikliğin kendisi yazıldığı sırada
hiçbir belgeye geçirilmemişti; kayıt 18 Eylül'de, sayı ölçülüp kaynağı kod
okunarak bulunduktan sonra eklendi ([`docs/30`](docs/30_ALTINCI_GECIS_VE_KULLANILABILIRLIK.md)).
Bunun anlamı açıktır: **duyarlılıktaki +%1,7 bir genelleme kanıtı değildir.**
Kesinlik tarafında tek bir masum cümle bile işaretlenmedi (30/30) ve diğer
dokuz kümede tek bir örnek değişmedi.

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
| Çözümleme süresi | Mesaj **p50 84 µs · p99 1.219 µs** · 2.400 karakterlik gönderi **p99 2,7 ms** (kare bütçesinin %17'si) — AOT, 15 Eylül 2026, `bin/benchmark.dart`. İki geçişte hızlandırıldı: sözlük dizini + örüntü ön filtresi (docs/19) ve karakter başına ayırmanın kaldırılması (docs/28). İkisi de çıktıyı değiştirmedi; denklik testle kilitli |

### Ölçüm geçmişi — neden tek bir sayı yok

| Küme | Boyut | Kesinlik | Duyarlılık | F1 | Durum |
|---|:--:|:--:|:--:|:--:|---|
| Geliştirme | 256 | %100 | %97,0 | %98,5 | Ezberleme payı içerir (13 Eylül: 3 alay örneği bilerek bırakıldı — docs/20) |
| 1. ayrık | 80 | %98,0 | %100 | %99,0 | Yanmış (ilk ölçüm F1 %84,2) |
| 2. ayrık (İP-15) | 100 | %100 | %38,5 | %55,6 | Yanmış (İP-19 onarımında kullanıldı) |
| 3. ayrık (İP-20) | 80 | %100 | %50,0 | %66,7 | Yanmış (İP-21 onarımında kullanıldı) |
| 4. ayrık (İP-22) | 65 | %90,5 | %54,3 | %67,9 | Yanmış (İP-26 genişletmesinde kullanıldı) |
| 5. ayrık (İP-27) | 90 | kayıt yok | ≈%48 | — | Yanmış (İP-28 deyim katmanında kullanıldı) |
| **6. ayrık (İP-29)** | **90** | **%96,4 → %96,2 → %100 → %100 → %100 → %100** | **%45,0 → %41,7 → %43,3 → %45,0 → %46,7** | **%61,4 → %58,1 → %58,8 → %60,5 → %62,1 → %63,6** | **Geçerli kesinlik tarafında; duyarlılık artık kör değil — ilk geçiş → D7 → D9 → docs/25 → docs/26 yarı-kör → docs/30 kör değil (docs/18 §7, docs/23, docs/30)** |
| Kimlik eksenleri (İP-33) | 32 saldırı + 32 masum | — | 0/32 → 31/32 | — | Düzeltmeden önce yazıldı, düzeltme ona bakılarak yapıldı — yanmış. Masum 31/32 → 32/32 (docs/26) |
| Kimlik eksenleri · 1. ayrık (İP-34) | 20 + 20 | %100 | **%15,0** | %26,1 | Birinci turdan sonra yazıldı; ilk geçiş. İkinci tur bu kümenin hata sınıflarıyla yapıldı — yanmış (bugün 19/20) |
| **Kimlik eksenleri · 2. ayrık (İP-35)** | **20 + 20** | **%100** | **%15,0** | **%26,1** | **Geçerli — ikinci turdan sonra, tek geçiş. 20 masumun 20'si temiz. Kural katmanı bu eksende kesinlik bekçisi; duyarlılık kaynağı değil (docs/26 §8)** |
| Küfür kapsamı (docs/25) | 317 çekişmeli + 91.861 kelime | — | 111 kaçak → 5 | — | Bitişik, çekimli ve gizlenmiş küfür; kelime listesinde yeni yanlış alarm **0**. Taramanın masum cümlelerinde yanlış alarm **6 → 4**: üçü önceden vardı, biri yeni ve bilinçli bedel (`skm` kısaltması, "SKM" gibi bir kurum adıyla çakışır — docs/25) |
| Gündelik metin (İP-30) | 120 masum | — | — | — | Yanlış alarm **17 → 0** (özgüllük %85,8 → %100). Hata türleri bilindikten sonra, düzeltmeden önce yazıldı — o türlere kör değil |
| Yönelim (İP-31) | 30 masum + 20 saldırı | — | 20/20 | — | Somut adlar + ikinci şahıs: yanlış alarm **29 → 2 → 0**, saldırıların hepsi yakalanmaya devam (docs/21, docs/24 · 15) |
| Savunma dili (İP-32) | 20 masum + 20 saldırı | — | — | — | Düşmanca görüşü aktarıp **kınayan** cümlede yanlış alarm **7 → 0**; konuşanın kendi nefret söylemi 10/10; aktarıp **onaylayan** cümle 4/10 → **0/10** (bilinen bedel, docs/22) |

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
| `ml/` | **Denetimli taban çizgisi** — Python/scikit-learn ile eğitilen karşılaştırma modeli. Uygulamada yalnızca ONNX **ikinci görüş** olarak durur ve **hiçbir karara dokunmaz**: ne temiz/işaretli kararını ne de risk basamağını değiştirir; şeffaflık panelinde bilgi amaçlı bir satırdır. Önceki sözleşmede basamağı yükseltebiliyordu; paketlenen model ölçülünce (`ml/04_paket_modeli_olc.py`) gündelik 120 masum cümlenin 86'sını saldırgan bulduğu ve 53 cümlenin basamağını değiştirdiği görüldü — aynı cümle telefonda Yüksek risk, web sunumunda Riskli oluyordu (docs/24 · madde 22). Böylece ölçülen motor davranışı her platformda birebir geçerlidir. |
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
  kümede (İP-29) bugünkü motorla toplam %46,7 (ilk geçiş %45,0; aradaki fark
  kör değil — docs/30): açık saldırıda %83,3, örtük saldırıda %32,4.
  İP-22'de ölçülen "yazılmış ailenin yeni örneklerinde %90" genellenmedi —
  devrik sıra, araya giren zamir ya da farklı kip kalıbın dışına düşüyor
  (İP-29 birinci parça: %56,7). Kural tabanlı bir katman Türkçe deyim ve
  kuruluş uzayını kapsayamaz. İP-29'un 60 saldırı örneğinden 32'si hâlâ
  kaçmaktadır ve bu kaçakların büyük bölümü örtük dilimdedir.
- **Cinsiyet, yaş, engellilik ve göç statüsü hedefli genellemelerde
  duyarlılık düşük.** 12 yeni kuruluş yazıldı (docs/26) ve bu gruplardan söz
  eden masum cümlelerde yanlış alarm üretmiyor (iki ayrık kümede 40/40), ama
  hiç görülmemiş ifadelerde duyarlılık **%15,0** (İP-35, tek geçiş). Geçmiş
  zaman, tekil genel ad ("kadın şoför"), eğretileme ("vergimizi yiyor") ve iki
  cümlecikli yapılar kuruluş listesinin dışına düşüyor.
- ~~**Alıntılanan örüntüde mağdur koruması eksik.**~~ **Düzeltildi (D9 ·
  docs/23).** İP-29'un tek yanlış pozitifinin sebebi örüntü değil, özel
  addaki kesme işaretinin (`Selin'e`) tırnak sayılmasıydı. Kalan sınır:
  tırnak kullanılmadan, yalnızca "demişler" gibi bir aktarma fiiliyle kınanan
  örüntü hâlâ pencereye (4 kelime) bağlıdır.
- **Kimlik adı yalın çoğul olmayan tamlamada hâlâ işaretlenebilir.** "Kadınlar
  tuvaleti kirli" artık temiz (D9); "Ermeni mahallesi kirli" gibi tekil
  niteleyici kuruluşlar denetimin dışındadır.
- **Yazılı tek cümlede alay ile içten övgü ayırt edilemiyor.** "Helal olsun
  valla", "bravo gerçekten" gibi kalıplar içten övgüyü de işaretlediği için
  kaldırıldı; alaycı kullanımları artık kaçıyor (docs/20, D3 + D5).
- **Somut adlarda yönelim yapıyla aranıyor; bazı kuruluşlar dışarıda kalıyor.**
  "senin gibi bir köpek", "tam bir kaz kafalısın" artık yakalanmıyor (docs/21,
  D7). D7'nin kalan iki yanlış alarmı ("Sen maymunlar hakkında ödev
  hazırlıyordun", "Sen sülük tedavisine inanıyor musun?") 14 Eylül'de konu
  ilgeci ve tamlama korumasıyla giderildi (docs/24 · madde 15).
- **Düşmanca görüşü aktaran cümlede kınama ile onay ayırt edilemiyor.**
  "…yok edilmesini savunanlar yargılanmalı" (kınama) temiz kalsın diye
  "…yok edilmesini savunanlar çok haklı" (onay) da yumuşuyor. Ürün kınayanı
  susturmamayı onaylayanı kaçırmaya tercih eder (docs/22, D8 · İP-32 C: 0/10).
- **Kimlik terimi ile düşmanca yüklem arasına özne girince örüntü yanılıyor.**
  "Kürtlere yönelik hakaretler temizlenmeli" cümlesi nefret söylemi
  sayılıyor: düzenli ifade "temizlenmeli"nin öznesinin "hakaretler"
  olduğunu göremez (docs/22).
- **"dölü" epiteti kaldırıldı** — aksan katlaması onu "dolu" ile birebir
  aynı hâle getiriyor ve ayırt etmenin normalize metin üzerinde yolu yok.
- Öncülsüz gönderge **kasıtlı olarak** kaçırılır — hedefin kim olduğu metinden
  bilinemez ve zamirden kimlik uydurmak kesinlik iddiasını çürütür.
- Kimlik söz varlığı 104 terimdir (İP-17'de 35'ten 94'e, docs/26'da 104'e
  genişletildi); siyasi
  görüş **kasıtlı olarak** kapsam dışıdır — korunan nitelik değildir.
- Tüm veri sentetiktir; hiçbir örnek gerçek kullanıcıdan gelmemiştir.
- **Öneri çeşitliliği sınırlı.** 300 öneride 92 benzersiz metin var:
  **çeşitlilik oranı %30,7**, en sık önerinin payı **%15,7**
  ("Bu yaklaşımı doğru bulmuyorum", 47 kez). Ölçüm:
  `dart run bin/rewrite_audit.dart --hepsi`, 18 Eylül 2026. Daha ileri gitmek
  her örüntüye kendi nötr karşılığını yazmayı gerektirir — algoritma işi
  değil, veri işi.

  > Önceki sürümde bu madde "en sık öneri tüm önerilerin %30,8'ini kaplıyor"
  > diyordu; o sayı aracın **çeşitlilik oranıydı**, en sık önerinin payı
  > değil. İki metrik karıştırılmıştı ve ürünü olduğundan kötü gösteriyordu.
  > Düzeltildi (18 Eylül).
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
