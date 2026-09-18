# Gecikme — İkinci Geçiş: Karakter Başına Ayırma

**Tarih:** 15 Eylül 2026 · **Kapsam:** `packages/civility_core` · **Davranış değişikliği:** yok

## 1. Neden yeniden

docs/19 birinci geçişi anlatıyor ve §6'da kalan işi adıyla bırakmıştı:

> "4.800 karakterde kalan ~17 ms'nin yarısı sözlük yolunda, dörtte biri
> normalizasyonda (karakter başına alt dizi ayırma). Bir sonraki adım
> normalizasyonu kod birimi düzeyine indirmek olur; bugünkü sayılar bütçenin
> içinde olduğu için yapılmadı."

O gün ertelenmesi doğruydu: bütçe korunuyordu. Bugün yapılmasının nedeni,
sayıların bu arada kötüleşmiş olması: sözlük 256 → 308 girdiye, nefret
kuruluşu 17 → 29'a, kimlik söz varlığı 94 → 104 terime çıktı. Aynı ölçüm
aracında uzun gönderi p99'u **8,8 ms**, yani 16 ms'lik kare bütçesinin
%55'i olmuştu. Bütçe hâlâ aşılmıyordu ama pay erimişti.

## 2. Nerede harcanıyordu

2.115 karakterlik sıradan bir topluluk duyurusu, JIT, aşama aşama ölçüldü
(geçici bir sayaçla; sayaç ölçüm bitince kaldırıldı):

| Aşama | Süre | Pay |
|---|--:|--:|
| Normalizasyon | 1.267 µs | %31 |
| Öbek eşleştirme | 1.070 µs | %26 |
| Bağlam sinyalleri | 608 µs | %15 |
| Birleştirme (kaçınma) | 334 µs | %8 |
| Örtük örüntüler | 266 µs | %7 |
| Diğer | 538 µs | %13 |
| **Toplam** | **4.083 µs** | |

Dördü de aynı hatanın farklı yüzleriydi: **karakter başına String ayırmak**.

## 3. Dört onarım

### 3.1 Normalizasyon — karakter planı

Eski sıcak döngü her karakter için `substring`, `toLowerCase`, `trim` ve
`runes.first` çağırıyordu; karakter başına 4-6 ayırma.

Oysa dönüşüm zinciri (küçük harf → eşyazımlı → leet → aksan → q/w/x) bir
karakterin **yalnızca kendisine** bağlıdır. Tek koşullu adım leet ikamesidir
("komşusu harf mi?") ve o da iki olası sonuç verir. Yani sonuç önceden
hesaplanabilir: `_CharPlan`.

Tablo Latin bloklarını (0x000–0x2FF) açılışta doldurur — Türkçe metnin
karakterlerinin tamamına yakını buraya düşer; üstü ilk görüldüğünde
hesaplanıp belleğe alınır. Sıcak döngü artık tablodan okur ve hiçbir ara
String üretmez.

İki ön geçiş de kısaldı: sıfır genişlikli karakter ve 3+ harf tekrarı
sıradan metinde yoktur, önce **varlığı** sorulur; yoksa N elemanlı kimlik
dizisi hiç kurulmaz.

`1.267 → 202 µs`

### 3.2 Öbek eşleştirme — Aho–Corasick kapısı

Sözlüğün çok kelimeli öbekleri (`kapa çeneni`) normalize metinde tek tek
`indexOf` ile aranıyordu: öbek sayısı × metin uzunluğu. Sıradan bir metinde
bunların hiçbiri geçmez, yani iş tamamen boşa gidiyordu.

Çözüm birinci geçişte **zaten yazılmıştı**: `LiteralIndex`, örüntü katmanı
için kurulmuş tek geçişli Aho–Corasick otomatı. Düz metin parçaları için bir
kurucu eklendi (`LiteralIndex.literals`); tek tarama hangi öbeklerin
geçebileceğini söyler, `indexOf` yalnızca onlar için çalışır.

"Geçemez" kesindir, "geçebilir" yalnızca aramaya değer demektir. ASCII dışı
karakter taşıyan parça taranamadığı için kısıtsız bırakılır, yani her metinde
denenir — güvenli taraf budur.

`1.070 → 73 µs`

### 3.3 Bağlam — harf tablosu

Büyük harf oranı, tırnak aralıkları, noktalama patlaması ve cümle sınırları
ham metnin tamamını dolaşıyor ve her karakterde `text[i]`, `toLowerCase()`,
`toUpperCase()` çağırıyordu.

Harflik ve büyüklük de karakterin kendisine bağlıdır: aynı yöntemle tablo.
Tanım eski sürümle birebir korundu — "büyük/küçük hâli farklı olan karakter
harftir", "kendi büyük hâline eşit olan harf büyüktür". Böylece büyük hâli
iki karaktere açılan `ß` gibi harfler harf sayılır ama büyük sayılmaz;
eski davranış buydu.

`608 → 234 µs`

### 3.4 Birleştirme — kurulmadan elenen birleşim

Kaçınma birleştirmesi, 1-3 komşu kelimenin her penceresi için bir
`StringBuffer` kurup birleştiriyordu. 400 token'lık bir metinde 1.200
birleşim — neredeyse hiçbiri sözlükte yok.

Birleşimin **uzunluğu** parçalardan toplanabilir, **ilk harfi** ilk
parçadan okunabilir. Çok token'lı birleşimler yalnızca birebir tablolarda
arandığı için, tablodaki en uzun anahtardan uzun ya da hiçbir anahtarın
başlamadığı bir harfle başlayan birleşim kurulmadan elenir. Tek token'lı
durumda birleşim zaten token'ın kendisidir; orada hiç kurulmaz.

`334 → 176 µs`

## 4. Davranışın değişmediğinin kanıtı

Bir hızlandırmanın çıktıyı değiştirmesi hatadır. Normalize metin motorun her
katmanının girdisi olduğu için tek karakterlik bir sapma bütün ölçümleri
geçersiz kılardı.

| Denetim | Sonuç |
|---|---|
| `test/normalizer_plan_test.dart` — hızlandırmadan önceki uygulama referans (oracle) olarak testte durur; BMP'nin **bütün** kod noktaları (yalnız · harf arasında · üç tekrar · kenarda), vekil çiftleri, eşi olmayan vekil yarılarının tamamı, 60.000 rastgele birleşim, 300 uzun metin, 13 etiketli kümenin bütün cümleleri | `value`, `aggressive`, `sourceIndices` **birebir aynı** |
| `test/detector_gate_test.dart` — kapılı / kapısız dedektör | aynı |
| `test/literal_prefilter_test.dart` — çıkarıcı ve otomat | geçiyor |
| Çekirdek test paketi (696 test) | geçiyor |
| `bin/evaluate.dart --hepsi` — 13 etiketli küme | **her sayı aynı** |

Ölçüm kümelerinin sayıları onarımdan önce ve sonra karşılaştırıldı; İP-29
(%100 · %45,0 · F0.5 %80,4), İP-30 (0/120), İP-35 (%100 · %15,0) ve
geliştirme kümesi (%100 · %97,0) dâhil hiçbiri kıpırdamadı.

## 5. Sonuç — aynı makine, aynı araç, aynı tur

`dart compile exe bin/benchmark.dart` · 11 senaryo × 2.000 tekrar. "Önce"
ikilisi, yalnızca bu dört onarımın geri alındığı bir kopyadan derlendi;
başka hiçbir fark yok.

| | Önce | Sonra | Kat |
|---|--:|--:|--:|
| Mesaj ≤200 kr · p50 | 169 µs | **84 µs** | ~2,0× |
| Mesaj ≤200 kr · p99 | 1.303 µs | **1.219 µs** | ~1,1× |
| Uzun gönderi · p50 | 3.057 µs | **1.027 µs** | ~3,0× |
| Uzun gönderi · p99 | 7.940 µs | **2.564 µs** | ~3,1× |
| ~600 kr · p50 | 840 µs | **293 µs** | ~2,9× |
| ~2.400 kr · p50 | 3.475 µs | **1.097 µs** | ~3,2× |
| ~2.400 kr · p99 | 8.798 µs (%55) | **2.720 µs (%17)** | ~3,2× |
| Genel p99 | 6.156 µs (%38,5) | **1.840 µs (%11,5)** | ~3,3× |

Kare bütçesinin p99'da kullanılan payı %38,5'ten %11,5'e indi.

**Makine notu.** docs/19'daki gibi: mutlak sayı makinenin anlık durumuna
(güç kipi, ısı) göre kat kat oynar. Bu yüzden iki ikili aynı oturumda, aynı
araçla ölçüldü; karşılaştırılabilir olan orandır.

## 6. Kalan maliyet

En pahalı senaryo artık ~2.400 karakterlik gönderi (p99 2,7 ms). Kalanın
dağılımı: bağlam %19, normalizasyon %17, birleştirme %15, örtük örüntüler
%14, token eşleştirme %13.

Tek bir büyük kalem kalmadı; bundan sonraki kazanç ancak metnin tamamını
her tuş vuruşunda çözümlemekten vazgeçmekle (değişen bölgeyi çözümlemek)
gelir. Bu, bağlam pencereleri cümle sınırlarını aştığı için doğruluğu
etkileyebilecek bir değişikliktir ve bütçe rahat olduğu sürece yapılmamalıdır.
