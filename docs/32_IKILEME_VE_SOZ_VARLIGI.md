# 32 · Harf İkilemesi ve Söz Varlığı Genişletmesi

**Tarih:** 19 Eylül 2026 · **Çekirdek sürüm:** 2.0.0 → 2.1.0
**Test:** `packages/civility_core/test/ikileme_test.dart`

## 1. Bildirim

Telefonda denenen cümle: **`sikerriimmo` → Temiz.**

Kaynak kod okunarak bulunan sebep: normalizasyon **3+** tekrarı tek harfe
indirir ("aptaaaal" → "aptal") ama **ikiliyi korur**, çünkü Türkçede ikili
anlamlıdır ("elli", "dikkat", "millet"). Motorun `_dedouble` yolu ikiliyi
yalnızca iki durumda indiriyordu: **ünlü** ikilisi ("aptaal") ve kelime
**sonundaki** ünsüz ikilisi ("salakk"). Kelime içindeki ünsüz ikilisi bilerek
dışarıda bırakılmıştı; kelime listesi taramasında "yıllanma" → "yılanma",
"şallak" → "salak" çakışmaları görülmüştü (docs/25 · K6).

`sikerriimmo` üç kuralın da dışına düşüyor: `rr` ve `mm` kelime içinde,
ardından tek harflik bir kuyruk (`o`) geliyor. Mevcut uzatma kuyruğu yolu
ancak özgün metinde **3+** tekrar varsa çalışıyordu.

Aynı taramada yakalanmayanlar: `şerrefsiz`, `orrospu`, `pezzevenk`,
`yavvşak`, `gerizekkalı`, `göttveren`, `sikttir`, `ssalak`, `sikkerim`,
`piiç`, `namusssuz`.

**Ölçek.** Sözlükteki yönelim şartı olmayan küfür/hakaret kök girdilerinden
otomatik üretilen ikileme varyantlarının (her harf tek tek, her harf çifti,
son harf + kuyruk, büyük harf) yalnızca **%34,4'ü** (3.636'da 1.251)
yakalanıyordu.

## 2. Düzeltme

Yeni yol, önceki yolların **hiçbiri** eşleşmediğinde çalışır:

| Aday | Örnek |
|---|---|
| Bütün ikililer teke indirilir | `şerrefsiz` → `şerefsiz` |
| İkiliden sonraki tek harf atılır (kök ≥ 4 harf) | `sikerriimmo` → `sikerim` |
| Özgün 3+ tekrar ikiye indirilir; yazılışında ikili olan girdi aranır | `namusssuz` → `namussuz` |
| İkilisi indirilmiş token, ikilisi indirilmiş girdiyle karşılaştırılır | `nnamussuz` → `namusuz` = `namussuz` |

**Kesinlik güvenceleri.** İlk sürüm kelime listesinde üç masum biçimi
işaretledi; her biri yapısal bir kuralla kapatıldı:

| Masum biçim | Neden işaretlendi | Kural |
|---|---|---|
| `sen yıllanma` | `yıllanma` → `yılanma` = yılan + ma | Yönelim şartlı girdiler ("yılan", "eşek") bu yoldan eşleşemez: belirsiz bir kelimenin üstüne belirsiz bir gizleme kanıtı yığılmaz |
| `şallak` | → `şalak` = salak | Yazılan Türkçe harf kökle çelişirse ("ş" ≠ "s") eşleşme reddedilir. Noktasız "ı" kanıt sayılmaz (`sıkerriim` bir gizlemedir) |
| `Şiilik` | → `silik` = `şıllık`ın ikilisi indirilmiş hâli | İkili taşıyan girdiye bu yoldan bağlanmak için token o ikiliyi (`ll`) fiilen taşımalı |

Kısa kökler (≤ 3 harf) bu yoldan eşleşemez; tek istisna, kökün Türkçeye özgü
harfinin özgün metinde yazılmış olmasıdır: `piiç`, `piçç` yakalanır; ASCII
`mall` (AVM), `itt` hiçbir şey tetiklemez.

**"sikke" maskesi.** Tek bir `sikke` ön eki, "sikkerim" ikilemesini sözlük
aramasından önce temizliyordu. Maske para anlamının çekimlerine daraltıldı
(`sikkel-`, `sikkes-`, `sikked-`, `sikken-`, `sikkem-`, `sikkeci`…);
`sikkeyi`, `sikkeye` zaten hiçbir girdiye bağlanmıyor ve maskelenmedi,
çünkü maskelenseydi `sikkeyim` ("sikeyim" ikilemesi) kaçardı.

## 3. Söz varlığı genişletmesi

Yaygın hakaret/küfür listesiyle yapılan taramada sözlükte **hiç
bulunmayan** 17 biçim eklendi; sözlük **310 → 327** girdi.

| Tür | Girdiler |
|---|---|
| Kök (yönelim şartsız) | `kevaşe`, `bok çuvalı`, `allahın belası`, `sik kafalı` |
| Tehdit | `ağzını burnunu kır` (öbek) · `bıçaklarım` (yalnızca yöneltilince — "bıçaklarım keskin") |
| Yönelim şartlı | `yosma`, `enayi`, `sapık`, `ucube`, `hanzo`, `tipsiz` |
| Yönelim şartlı + somut ad (yapısal yönelim, D7) | `kaşar` ("kaşar peyniri"), `angut` ("angut kuşu"), `sümsük` ("sümsük kuşu"), `kancık` ("kancık köpek"), `boynuzlu` ("boynuzlu geyik") |

**Denetlenip alınmayanlar:**

| Biçim | Sebep |
|---|---|
| `sg`, `s.g` | Altyazı listesinde `SG-1` (dizi adı) işaretlendi |
| `bok ye` | Öbek sağ sınır denetlemez: "sınavda bok yedim" (öz-ifade) Yüksek risk aldı |
| `siktiğimin` | ASCII "sıktığımın" ile aynı dizgi |
| `vururum` | "topa vururum"; yakınlık yönelimi "sana pas ver, vururum"da yanılır |
| `top` | "top oynadık"; ayırt edecek yapı yok |
| `lan`, `ulan`, `çüş` | Ünlem; tek başına hakaret değil |

Ayrıca `kasara` (gemi terimi, ASCII "kaşara" ile aynı dizgi) maskelendi.

## 4. Ölçüm

| Ölçüm | 2.0.0 | 2.1.0 |
|---|:--:|:--:|
| **13 etiketli küme, 1.115 cümle — değişen karar** | — | **0** — toksisite değerleri dahil birebir aynı |
| İP-29 kesinlik · duyarlılık · F0.5 | %100 · %46,7 · %81,4 | %100 · %46,7 · %81,4 |
| Kelime listesi (91.861 biçim) — tek başına yeni masum işaretleme | — | **0** |
| Kelime listesi — "sen X" kalıbında yeni işaretleme | — | 30; hepsi eklenen hakaretlerin kendi çekimleri ya da `sen kaşar` (yönelim şartlı somut ad; `sen eşek`, `sen köpek` ile aynı sınıf) |
| Kelime listesi — kaybolan işaretleme | — | 0 |
| İkileme varyantları — yakalanan | **%34,4** (1.251 / 3.636) | **%99,2** (3.639 / 3.668) |
| Mesaj ≤ 200 kr · p50 (AOT) | 70 µs | 72 µs (+%3) |
| Uzun gönderi · p50 (AOT) | 1.070 µs | 1.128 µs (+%5) |
| 2.400 kr · p99 (AOT) | 1.446–1.486 µs | 1.586–1.628 µs (≈ +%9 · kare bütçesinin ~%10'u) |
| Çekirdek test | 765 | 839 |

Gecikme aynı makinede, iki motor dönüşümlü çalıştırılarak ölçüldü (iki tur).
Mutlak sayılar README'deki 15 Eylül ölçümüyle (2,7 ms) karşılaştırılamaz —
makine yükü farklı; README'deki sayı muhafazakâr üst sınır olarak geçerli.
İlk sürüm uzun gönderide p50'yi ~%25 artırmıştı; yol, ikili taşımayan
token'da hiç dizgi üretmeyen iki ön kapıyla (`_hasDouble`, `_originalLonger`)
yeniden yazıldı ve sonuç değişmedi (kelime listesi ve küme dökümü birebir).

**Kalan kaçaklar (%0,8):** `eşşoğlu`'nun ikilemeleri (21) — girdi kendi
içinde `şş` taşıyor ve varyantları ikinci bir girdiye ("eşek") kayıyor;
`sixiym` (7) ve `yrrk` (1) — ünsüz iskeletleri. Kapsam testi bu üçünü açıkça
dışarıda tutar.

## 5. Bu ölçüm neyi söylemez

- İkileme oranı **mekanizma kapsamıdır**, gerçek dünya duyarlılığı değildir.
  Varyantlar sözlüğün kendi girdilerinden üretildi; sözlükte olmayan bir
  hakaretin ikilemesi yine kaçar.
- Söz varlığı genişletmesinin **kör bir ölçümü yoktur.** Girdiler tarafımızdan
  derlenen bir yaygın hakaret listesinden seçildi; bu liste bir ölçüm kümesi
  değildir ve hiçbir kümeye eklenmedi. Kanıtlanan tek şey: 13 kümede karar
  değişmedi ve kelime listesinde tek başına masum biçim işaretlenmedi.
- Raporlanan hiçbir kör küme sayısı bu çalışmadan etkilenmedi — etkilenseydi
  bu belgede yazardı.

## 6. Sunuma etkisi

Değişen tek sunum sayısı **sözlük girdisi: 310 → 327**. Örüntü (221),
kimlik terimi (104), etiketli cümle (1.115), küme (13) ve bütün ölçüm
sayıları aynı. Uygulamadaki panel sayıyı motordan okuduğu için demoda
**327** görünür. Jüri "slaytta 310 yazıyor" derse:

> "Sunumu hazırladıktan sonra bir kullanıcı 'sikerriimmo' yazınca kaçtığını
> gördük. Düzelttik, 17 girdi ekledik; 91.861 kelimelik listede yeni yanlış
> alarm çıkmadığını ve 13 ölçüm kümesinde tek kararın değişmediğini ölçtük.
> Panel sayıyı motordan okuduğu için 327 görüyorsunuz."
