# Model Değerlendirme

**Son ölçüm:** 12 Ağustos 2026 · **Kod:** `packages/civility_core/`
**Ortam:** Dart 3.12.2 (Flutter 3.44.9), Windows 11
**Yeniden üretmek için:** `dart run bin/evaluate.dart --hepsi`

Bu belge teknik raporun "Doğrulama ve Metrikler" bölümüne kaynaklık eder.
Buradaki her sayı çalıştırılarak üretilmiştir ve komutu yukarıdadır.

---

## 1. Neden test yetmez, metrik gerekir

Projede 31 geçen birim testi vardı. Bu, motorun çalıştığını **kanıtlamaz**:
testler seçilmiş örneklerdir ve seçen kişi, motorun yakalayacağı örnekleri
seçmeye eğilimlidir.

Metrik farklıdır: dengeli bir küme üzerinde, **kaçırılanları da** sayar.

İlk ölçüm bunu doğruladı. 31 test geçerken motorun gerçek duyarlılığı
**%44,3** çıktı ve bir dilimde tamamen kördü.

### Hata maliyeti simetrik değildir

| Hata | Sonuç |
|---|---|
| **Yanlış pozitif** — masum metne müdahale | Kullanıcı güvenini kaybeder, özelliği kapatır. **Ürün ölür.** |
| **Yanlış negatif** — hakaret kaçar | Bir hakaret gönderilir. Kötü, ama ürün yaşar. |

Bu yüzden **kesinlik (precision), duyarlılıktan (recall) önemlidir** ve
raporlanan asıl hedef fonksiyon **F0.5**'tir (kesinliği iki kat ağırlıklandıran
F-ölçüsü). F1 de verilir ama tek başına yanıltıcıdır.

---

## 2. Veri kümeleri

| Küme | Örnek | Amaç |
|---|---|---|
| Geliştirme (`gold_dataset.dart`) | 256 | Geliştirme ve regresyon kalkanı |
| Ayrık (`holdout_dataset.dart`) | 80 | Genelleme ölçümü |

Beş dilim:

| Dilim | Geliştirme | Ne ölçer |
|---|---|---|
| Açık saldırı | 55 | Sözlük katmanının kapsamı |
| Örtük saldırı | 57 | Küfürsüz düşmanlık |
| **Nefret söylemi** | **45** | **Kimlik hedefli düşmanlık — ve masum kimlik beyanını rahat bırakma** |
| Masum / tuzak | 79 | **Kesinlik** — kümenin %31'i |
| Bağlam | 20 | Mağduru cezalandırmama |

Nefret dilimi 12 Ağustos'ta 39 → 45'e çıktı: gönderge (anafora) katmanının
3 yakalama ve 3 yakın-kaçış örneği eklendi (§3b).

### Nefret dilimi neden çift yönlü

Bu dilimin 39 örneğinin **23'ü müdahale beklemez.** Bu bir denge kusuru
değil, kasıtlı tasarımdır: nefret söylemi tespitinde asıl risk kaçırmak
değil, **yanlış hedefi vurmaktır.**

Kimlik adlarını ("Kürt", "Ermeni", "Alevi", "eşcinsel", "Suriyeli") yasaklı
kelime listesine koyan bir sistem, kendi kimliğinden söz eden insanı
işaretler — yani korumayı vaat ettiği grubu susturur. Dilim tam olarak bunu
ölçer:

| Yakalanmalı | Yakalanmamalı — aynı kimlik terimi |
|---|---|
| Bütün **Suriyeliler** hırsızdır | **Suriyeli** komşumuz çok yardımsever |
| **Kürtler** defolsun | Ben **Kürt**üm |
| **Eşcinseller** hastalıklı | **Eşcinsel** hakları konferansına katıldım |
| **Romanlar** hep dolandırıcı | **Romanlar** müzikte çok yetenekli |
| **Suriyeliler** hayvandır | **Suriyeli** gönüllüler **hayvan** haklarıyla ilgileniyor |

Son satır katmanın en zor ayrımıdır: aynı iki kelime yan yana, biri yüklem
biri nesne konumunda. İlk sürüm bu cümlede **yanlış pozitif üretiyordu**;
yüklem eki şartı bu ölçüm sayesinde eklendi.

### Masum dilim neden en kalabalık

Yanlış pozitif en pahalı hata olduğu için kümenin üçte biri masum metindir ve
çoğu **kasıtlı tuzaktır** — naif filtreleri düşüren gerçek Türkçe kelimeler:

```
"şikayetimi ilettim"        normalize → sikayet     (müstehcen alt dizi)
"kargoyu götürdü"                    → goturdu
"malzeme listesi"                    → mal ile başlar
"sikke koleksiyonu"                  → sik ile başlar
"köpeğim hasta"                      → hayvan adı, yönelim yok
"hıyar salatası yaptım"              → sebze
"susadım"                            → sus ile başlar
```

### Yakın-kaçış çiftleri

Kümenin en değerli kısmı, saldırgan kalıplara **kelime düzeyinde benzeyen**
ama düşmanca olmayan cümlelerdir. Bu çiftler olmadan ölçülen kesinlik
şişkindir:

| Saldırgan | Masum — aynı kelimeler |
|---|---|
| senin **gibilerden** bu beklenirdi | senin **gibi** düşünenler haklı |
| **sana ne** | **sana ne** getireyim marketten |
| görüşürüz **seninle** | görüşürüz, iyi akşamlar |
| çok başarılısın gerçekten, **bravo** | gerçekten çok başarılısın, tebrikler |
| **sus** artık | **sus** payı vermişler |
| hiçbir **işe yaramazsın** | bu çözüm **işe yaramaz** çünkü bellek sızıntısı var |

---

## 3. Sonuçlar

### 3.1 Gelişim — üç ölçüm noktası

| | Örnek | Kesinlik | Duyarlılık | F1 | F0.5 |
|---|---|---|---|---|---|
| **T0** Devralınan motor | 211 | 94,4 % | 44,3 % | 60,4 % | 77,0 % |
| **T1** + motor düzeltmeleri | 211 | 100,0 % | 49,6 % | 66,3 % | 83,1 % |
| **T2** + örtük saldırı katmanı | 211 | 100,0 % | 100,0 % | 100,0 % | 100,0 % |
| **T3** + nefret söylemi katmanı | **250** | **100,0 %** | **99,2 %** | **99,6 %** | **99,8 %** |
| **T4** + gönderge katmanı | **256** | **100,0 %** | **99,3 %** | **99,6 %** | **99,8 %** |

*(geliştirme kümesi — genelleme için §5'e bakınız)*

T4'te küme 6 yeni örnekle büyüdü (3'ü yakalama, 3'ü yakın-kaçış) ve
**kesinlik ile özgüllük %100'de kaldı**: üç yakın-kaçışın hiçbiri
işaretlenmedi. Katmanın kabul koşulu buydu.

T3'te duyarlılık 100'ün altına indi. Bu bir gerileme değil: küme 39 yeni ve
daha zor örnekle büyüdü ve tek kaçan örnek, kümeye **bilinen sınır olarak
etiketlenerek** kondu (§6). Kesinlik 100 % kaldı — yeni katman tek bir
masum cümleyi bile işaretlemedi.

### 3.2 Dilim bazında

| Dilim | T0 | T4 |
|---|---|---|
| Açık saldırı (duyarlılık) | 89,1 % | 100,0 % |
| **Örtük saldırı (duyarlılık)** | **0,0 %** | **100,0 %** |
| **Nefret söylemi (F1)** | — (kategori boştu) | **97,3 %** |
| Masum / tuzak (özgüllük) | 100,0 % | 100,0 % |
| Bağlam (F1) | 50,0 % | 100,0 % |

Devralınan motorun örtük saldırıya karşı **tamamen kör** olduğu bu ölçümle
ortaya çıktı. Sosyal medyadaki düşmanlığın büyük kısmı bu dilimdedir.

Nefret kategorisi ise T2'ye kadar **hiç doldurulmamıştı** — `ToxicityCategory`
içinde `nefret` tanımlıydı ama sözlükte sıfır girdi vardı. Şartnamenin
doğrudan bir maddesi karşılanmıyordu.

### 3.3 Katman katkısının izolasyonu

`dart run bin/evaluate.dart --karsilastir`

| Metrik | Yalnız sözlük | + Örüntü katmanları | Değişim |
|---|---|---|---|
| Kesinlik | 100,0 % | 100,0 % | **0,0 puan** |
| Duyarlılık | 44,0 % | 99,3 % | **+55,2 puan** |
| Özgüllük | 100,0 % | 100,0 % | **0,0 puan** |
| F1 | 61,1 % | 99,6 % | +38,5 puan |
| F0.5 | 79,7 % | 99,8 % | +20,1 puan |

Dilim bazında duyarlılık:

| Dilim | Yalnız sözlük | + Örüntü katmanları | Değişim |
|---|---|---|---|
| Açık saldırı | 98,2 % | 100,0 % | +1,8 puan |
| **Örtük saldırı** | **1,8 %** | **100,0 %** | **+98,2 puan** |
| **Nefret söylemi** | **10,5 %** | **94,7 %** | **+84,2 puan** |
| Bağlam | 66,7 % | 100,0 % | +33,3 puan |

**Kritik sonuç:** her iki örüntü katmanı da duyarlılığı büyük ölçüde
artırırken **kesinlikten hiçbir şey götürmedi.** Bu, katmanların kabul
koşuluydu ve `evaluator_test.dart` ile `hate_layer_test.dart` içinde test
olarak kilitlenmiştir.

Nefret dilimindeki sözlük-tek-başına %12,5 rakamı, "yasaklı kelime listesi"
yaklaşımının bu problemde neden yetersiz kaldığının doğrudan ölçümüdür:
kimlik hedefli düşmanlığın yedide altısı tek bir hakaret sözcüğü içermez.

### 3.4 Performans

**12 Ağustos 2026 ölçümü** (Dart 3.12.2, 256 örnek, `--hepsi`):

| Yapılandırma | Ortalama çözümleme | Koşul |
|---|---|---|
| Tam hat (sözlük + örtük + nefret + gönderge) | **268,4 µs** | süreçteki **ilk** çalıştırma |
| Yalnız sözlük | 48,2 µs | ısınmış |
| Sözlük + tüm örüntü katmanları | 103,9 µs | ısınmış |

⚠ **Bu üç sayı birbiriyle doğrudan karşılaştırılamaz.** Üçü de aynı Dart
sürecinde arka arkaya çalışır; ilki JIT ısınmasını da üstlenir. Aynı
yapılandırma (tam hat) ısınmış hâlde 103,9 µs, soğuk hâlde 268,4 µs
ölçülüyor — aradaki 2,6 kat fark katman maliyeti değil, ısınmadır.
**Raporlanacak sayı, kullanıcının gerçekten yaşadığı en kötü hâl olan
soğuk ölçümdür: 268,4 µs.**

Önceki kayıt (1 Ağustos, T3): 322,7 µs. Aradaki düşüş bir iyileştirme
iddiası olarak sunulmamalıdır — Dart sürümü ve makine durumu değişti.

**Gönderge katmanının maliyeti ölçülerek sıfıra indirildi.** İlk sürümde
kimlik söz varlığı (~45 terimlik almaşık) her çözümlemede taranıyordu ve
ortalama **440,2 µs**'ye çıkmıştı. Tarama tembelleştirildi: öncül araması
ancak bir gönderge örüntüsü gerçekten eşleştiyse çalışır — yani cümlelerin
ezici çoğunluğunda hiç çalışmaz. Sonuç 268,4 µs.

Her hâlükârda 16 ms'lik 60 FPS bütçesinin **%2'sinden azı**. Gecikmeli
tetikleme (debounce) gerekmiyor.

---

## 3b. Nefret söylemi katmanının tasarımı

Bu katman mimari olarak sözlük **değildir** ve bu kasıtlıdır.

### Kimlik = yuva, saldırı = kuruluş

```
[kimlik terimi]  +  [düşmanca kuruluş]   →  nefret söylemi
[kimlik terimi]  yalnız başına           →  hiçbir şey
```

Kimlik adları `hate_patterns.dart` içinde yalnızca bir **yuvayı** (slot)
doldurur; tek başlarına asla bulgu üretmezler. Sözlükte (`toxicity_lexicon`)
tek bir kimlik adı yoktur ve bu, `hate_layer_test.dart` içinde **yapısal bir
testle** korunur: sözlüğe kimlik adı sızarsa test kırılır.

### Beş kuruluş ailesi

| Aile | Örnek | Şiddet |
|---|---|---|
| Varlık reddi / şiddete çağrı | "… yok edilmeli" | 0,98 |
| İnsanlıktan çıkarma | "… hayvandır" | 0,92 |
| Dışlama / sürgün | "… defolsun ülkelerine" | 0,88 |
| Kimlik aşağılama | "… hastalıklı" | 0,86 |
| Toplu suçlama | "Bütün … hırsızdır" | 0,85 |

### Kesinliği ayakta tutan iki mekanizma

**1. Yüklem eki şartı.** Düşmanca sözcüğün gerçekten yüklem konumunda
olması gerekir — bildirme eki (`-dır`, `-sın`) ya da metin sonu. Çoğul eki
(`-lar`) kasıtlı olarak kabul edilmez:

```
"Suriyeliler hayvandır"                        → yakalanır
"Suriyeli gönüllüler hayvan haklarıyla …"      → yakalanmaz  (nesne konumu)
"Suriyeliler hayvanları sever"                 → yakalanmaz  (çoğul ≠ yüklem)
```

**2. Ambigü köklerde yalnızca çoğul biçim.** Aksan katlaması bazı kimlik
adlarını meşru kelimelerle çakıştırır. Türkçe ünlü uyumu bu ayrımı
katlamadan **sonra** da koruduğu için tekil biçim hiç kullanılmaz:

| Kimlik | Katlanmış | Çakıştığı meşru kelime | Kullanılan biçim |
|---|---|---|---|
| Kürt | `kurt` | kurt (hayvan), kurtarmak | `kurtler…` |
| Laz | `laz` | lazım | `lazlar…` |
| Roman | `roman` | roman (kitap) | `romanlar…` |
| trans | `trans` | transfer, transit | `translar…` |
| gey | `gey` | geyik | `geyler…` |

Bedeli bir miktar duyarlılıktır ve bilinçli bir seçimdir: yanlış pozitif,
yanlış negatiften pahalıdır.

---

## 4. Ölçümün bulduğu motor hataları

Değerlendirme altyapısı, ilk çalıştırmasında beş gerçek hata ortaya çıkardı.
Hiçbiri mevcut 31 testin görebileceği türden değildi.

| # | Hata | Belirti |
|---|---|---|
| 1 | Yönelim yalnızca eşleşen kelimenin **kendi** ekinden okunuyordu | "alçak herifsin", "öküz gibisin", "hayvan gibi konuşuyorsun" tamamen kaçıyordu |
| 2 | Öz-yönelim yalnızca **zamirden** okunuyordu | "aptalca bir hata **yaptım**" yanlış pozitif — özne düşünce kişi bilgisi fiil ekinde kalır |
| 3 | Yumuşatma yalnızca **çarpan**dı, tavan yoktu | `0,88 × 0,20 = 0,176` eşiği aşıyordu → tacize **uğrayan** kişi uyarı alıyordu |
| 4 | Tam eşleşmeli terimler **çekimlenemiyordu** | "sen tam bir **malsın**" hiç yakalanmıyordu |
| 5 | Retorik olumsuzlama bir **kaçış yolu**ydu | "sen aptal **değil misin** zaten" olumsuzlama sanılıp temizleniyordu |

Sonradan, ayrık küme üç hata daha gösterdi:

| # | Hata | Belirti |
|---|---|---|
| 6 | Örüntüler Türkçe çekime karşı **fazla katı** | "sesini kes" yakalanıyor, "sesiniz**i** kes**in**" kaçıyordu |
| 7 | Fiil olumsuzluğu (`-mıyorum`) görülmüyordu | "seni aptal **sanmıyorum**" yanlış pozitif |
| 8 | Yeterlilik olumsuzu (`-amam`) olumsuzlama sayılıyordu | "senin gibi tiplerle **uğraşamam**" kendi eliyle temizleniyordu |

Her biri `test/implicit_layer_test.dart` içinde regresyon testiyle kilitlendi.
Testlerin adı **hatayı** anlatır, çözümü değil — böylece çözüm değişse de
test anlamını korur.

---

## 5. ⚠ Dürüstlük: %100 ne anlama gelir, ne anlama gelmez

**Geliştirme kümesindeki %100 bir genelleme kanıtı DEĞİLDİR.**

Kümeyi de örüntüleri de aynı kişi yazdı ve örüntüler **küme görüldükten
sonra** yazıldı. Bu koşullarda %100, büyük ölçüde ezberleme olabilir.

Bunu ölçmek için ayrık bir küme kuruldu. Kural: cümleler örüntülerin düzenli
ifadelerine **bakılmadan** yazıldı (çekim değiştirildi, kelime sırası
bozuldu, eşanlamlı kullanıldı), ölçüm **bir kez** alındı, sonuç
**düzeltme yapılmadan** kaydedildi.

### İlk ve tek geçerli genelleme ölçümü

| Metrik | Değer |
|---|---|
| Kesinlik | 88,9 % |
| Duyarlılık | 80,0 % |
| **F1** | **84,2 %** |
| Açık saldırı (duyarlılık) | 100,0 % |
| Örtük saldırı (duyarlılık) | 75,0 % |
| Masum (özgüllük) | 91,7 % |

**Rapora yazılacak sayı budur: F1 = %84,2.**

Geliştirme kümesindeki 100 ile arasındaki ~16 puanlık fark, ezberleme payının
büyüklüğüdür. Bu farkı görmek, ölçüm altyapısının en değerli çıktısıdır.

### Sonrası

Ayrık kümenin gösterdiği 15 hata kök nedene indirgendi (§4, 6–8) ve
düzeltildi. Düzeltme sonrası ayrık kümede F1 %99,0 ölçülüyor —
**ama bu sayı artık ayrık değildir ve genelleme olarak raporlanamaz.**
Kümeye bakılarak düzeltme yapıldığı anda küme yanmıştır.

### Bunun için gereken

Rapordaki metriklerin bağımsız olması için:

1. **İkinci bir etiketleyici** (takım arkadaşı) tamamen bağımsız bir küme
   üretmeli — mevcut kümeleri veya kodu görmeden.
2. **Hakemler arası uyum** ölçülmeli (Cohen's kappa). Şu an tek etiketleyici
   var ve bu ölçülmemiştir.
3. Mümkünse **gerçek kullanıcı verisi** — sentetik cümleler, gerçek
   kullanıcının yazdığından her zaman daha düzenlidir.

Bu üçü yapılmadan raporda "F1 = %84,2" yazarken **koşulları da yazılmalıdır.**
Koşulsuz bir metrik, jüri tarafından haklı olarak sorgulanır.

---

## 6. Bilinen sınırlar

| Sınır | Durum |
|---|---|
| ~~Nefret söylemi kategorisi boş~~ | ✅ **Kapatıldı.** 5 kuruluş ailesi + 8 hakaret sözcüğü, 39 örneklik ölçüm dilimiyle. Dilim F1 %96,8, kesinlik %100. |
| ~~Gönderge çözümlemesi yok~~ | ✅ **Kapatıldı (12 Ağustos, `510a5ec`).** Kimlik önceki cümledeyse çoğul işaret zamiri ona bağlanıyor; 160 karakterlik erişim penceresi var. Kalan sınır **ilkeseldir**: öncülsüz zamir (*"bunların soyunu kurutmak lazım"* tek başına) kasıtlı olarak kaçırılır — hedefin kim olduğu metinden bilinemez. Küme etiketinde "müdahale" olarak bırakıldı ki bu kararın duyarlılık maliyeti ölçümde görünsün. |
| **Gönderge yalnızca en ağır üç sözvarlığında** | Toplu suçlama (`hirsiz`, `pis`) ve değersizleştirme (`bozuk`, `kirli`) sözvarlıklarının gönderge sürümü yoktur: bu kelimeler nesneler için de olağandır ve *"bunlar çok pis oldu"* yemeğe gönderebilir. Kesinlik uğruna kabul edilmiş bir duyarlılık kaybıdır. |
| **Nefret dilimi bağımsız değil** | Bu 39 örneği de örüntüleri de aynı kişi yazdı, üstelik örüntüler kümeyle **birlikte** yazıldı. §5'teki uyarı bu dilim için bir kat daha geçerlidir; ayrık bir kümede yeniden ölçülmelidir. |
| **Kimlik söz varlığı eksik** | 40 kimlik terimi kapsanıyor. Türkçe'deki tüm etnik/inanç/yönelim adlandırmaları değil; özellikle bölgesel ve argo adlandırmalar eksik. |
| Alaycılık kırılgan | Alay, alay parçacığı ("valla", "gerçekten") olmadan yakalanamıyor. "vay be" gibi tek başına belirsiz kalıplar yanlış pozitif ürettiği için çıkarıldı. |
| İnkâr kalıbı aşırı geniş | "şerefsiz demek istemem ama üzdü beni" — gerçek bir sitem, ama kalıp tetikleniyor. Etiketin kendisi tartışmaya açık. |
| Sentetik veri | Hiçbir örnek gerçek kullanıcıdan gelmedi. |
| Tek dil | Yalnızca Türkçe. |
| Örüntü sayısı sınırlı | 50 edimbilimsel örüntü. Türkçe'deki örtük saldırı repertuvarı çok daha geniştir. |

---

## 7. Sonraki adım: sinir ağı katmanı

Örüntü katmanı, örtük saldırı sorununun **tamamını çözmez** — yalnızca
kataloglanmış kalıpları çözer. Genel çözüm ince ayarlı bir dil modelidir
(BERTurk + ONNX).

Mevcut mimari buna hazırdır: `ToxicityClassifier` arayüzü değişmeden
`OnnxTurkishClassifier` eklenebilir. Deterministik katman **yok olmaz** —
yüksek kesinlikli ön filtre olarak kalır ve modelin kararını açıklanabilir
kılar.

**Bu belgedeki değerlendirme altyapısı, o modelin de aynı kümede ölçülmesini
sağlar.** Sinir ağının deterministik katmandan daha iyi olduğu iddiası, ancak
aynı kümede karşılaştırmalı ölçümle kanıtlanabilir — ve altyapı artık hazır.

---

## Ek: yeniden üretme

```powershell
cd packages/civility_core
dart run bin/evaluate.dart               # geliştirme kümesi
dart run bin/evaluate.dart --ayrik       # ayrık küme
dart run bin/evaluate.dart --karsilastir # katman katkısı (A/B)
dart run bin/evaluate.dart --hepsi       # üçü birden
dart test                                # 136 test
```

Mobil taraf (`mobile/`): `flutter test` → 17 test, `flutter analyze` → temiz.
**Toplam 153 test, 0 analiz uyarısı** (12 Ağustos 2026).

Araç zinciri bu makinede `D:\flutter` (3.44.9 · Dart 3.12.2) ve `D:\git`
(MinGit 2.55.0.4) altındadır; `PUB_CACHE=D:\pub-cache`. C: sürücüsünde yer
kalmadığı için D:'ye kuruldu — ayrıntı `02_TEKNIK_BORC.md`.
