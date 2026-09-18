# İP-29 · Altıncı Ayrık Küme — İlk Geçiş Kaydı

**Tarih:** 13 Eylül 2026
**Küme:** `packages/civility_core/lib/src/eval/generalization5_dataset.dart`
**Küme commit'i (ölçümden önce):** `55881fb` — 2026-09-13 12:22 (+03:00)
**Komut:** `dart run bin/evaluate.dart --genelleme5`

Bu belge ölçümün **düzeltilmemiş** kaydıdır. Kümeye bakılarak motorda hiçbir
değişiklik yapılmamıştır. Yapılırsa küme yanar ve bu belgenin altına not
düşülür.

---

## 1. Neden bu ölçüm alındı

İP-27 kümesi yanmıştı: İP-28 deyim katmanı, onun ilk geçişte kaçırdığı 31
örneğe bakılarak yazıldı. Aynı dönemde sözlüğe gizleme varyantları ve yeni
girdiler eklendi. Bugünkü motorun **hiç görmediği** cümlelerdeki başarımını
ölçen geçerli bir sayı yoktu. Sunumda "raporlanan sayı" olarak gösterilen
İP-22 ölçümü, iki büyük genişletmeden önceki motora aitti.

## 2. Sonuç

| Ölçüt | Değer |
|---|---|
| Kesinlik | **%96,4** |
| Duyarlılık | **%45,0** |
| Özgüllük | %96,7 |
| F1 | %61,4 |
| **F0.5** (ürünün hedef fonksiyonu) | **%78,5** |
| Kategori doğruluğu | %85,2 (23/27) |
| Karışıklık | DP 27 · YP 1 · YN 33 · DN 29 |

### Parçalara göre

| Parça | Sonuç | Ölçüm öncesi beklenti |
|---|---|---|
| 1 · Bilinen yeteneklerin yeni örnekleri | 16/30 · duyarlılık **%53,3** | ~%80 — **tutmadı** |
| 2 · Yakın-kaçış ve bağlam tuzakları | 29/30 temiz · özgüllük **%96,7** | ≥ %95 — tuttu |
| 3 · Serbest düşmanca ifadeler | 11/30 · duyarlılık **%36,7** | %30–50 — tuttu |

### Dilimlere göre

| Dilim | Örnek | Sonuç |
|---|:--:|---|
| Açık saldırı | 12 | duyarlılık %83,3 |
| Örtük saldırı | 34 | duyarlılık %32,4 |
| Nefret söylemi | 20 | F1 %60,0 |
| Masum / tuzak | 12 | özgüllük %100,0 |
| Bağlam | 12 | özgüllük %91,7 |

## 3. Ne gösteriyor

**Kesinlik tuttu.** Otuz masum cümlenin — mağdur anlatıları, alıntılar,
kimliğin nötr anılışı, "ak/ağ", "şik", "göt", "mal" alt dizi tuzakları —
yirmi dokuzu temiz kaldı. Ürünün hedef fonksiyonu F0.5 olduğu için bu,
sayıların en önemlisidir.

**Tek yanlış pozitif bir bağlam hatasıdır:**

```
Selin'e "senin gibilerden bu beklenirdi" demişler, çok ayıp
  → riskli (0.50) · eşleşme: "senin gibiler"
```

Ötekileştirme kalıbı tırnak içinde, "demişler" aktarım fiiliyle ve kınama
ifadesiyle aktarılıyor. Bağlam katmanı sözlük bulgularında alıntıyı
yumuşatıyor; bu örüntü bulgusunda yumuşatma devreye girmedi. Yani mağdur
koruması **sözlük katmanında sağlam, örüntü katmanında bir boşluk taşıyor**.

**Açık saldırıda motor iyi (%83,3); örtük saldırıda zayıf (%32,4).**
Birinci parçadaki kaçaklar, ürünün "yapabildiğini" söylediği yeteneklerin
başka kuruluşlarıdır:

| Yetenek | Kaçan örnek |
|---|---|
| Susturma | "kes sesini artık" (devrik) · "sana soran oldu mu" |
| Nitelik reddi | "sende hiç utanma yok mu" |
| Örtük tehdit | "gününü sana göstereceğim" (araya zamir girince) · "bu yaptığını ödeyeceksin" · "evinin yolunu biliyorum" |
| Toplu suçlama | "Ermeniler hain bir millettir" (sıfat tamlaması) |
| Dışlama | "Aleviler bu mahalleye taşınmasın" (istek kipi) |
| Harf tekrarı | "ahmakk mısın nesin" |

Bu tablo, İP-22'de ölçülen "yazılmış ailenin yeni örneklerinde %90"
sayısının **genellenmediğini** gösteriyor: o sayı ailenin kendi kelime
sırasına yakın örneklerde ölçülmüştü. Devrik sıra, araya giren zamir ya da
farklı kip, düzenli ifadenin dışına düşüyor.

**Üçüncü parça tavanı doğruluyor.** Cinsiyet, yaş, engellilik ve göç
statüsü hedefli genellemelerin tamamı kaçtı ("kadınlar direksiyona
geçmesin", "engelliler evde otursun"). Kimlik söz varlığı etnik köken,
inanç ve yönelim ağırlıklıdır; bu eksenler yazılmamıştır.

## 4. Raporlama kararı

- **Raporlanan genelleme sayısı bundan sonra budur:** kesinlik %96,4 ·
  duyarlılık %45,0 · F0.5 %78,5 (İP-29, ilk geçiş).
- İP-22 sayısı (%90,5 / %54,3) geçmiş kayıt olarak kalır.
- Bu kaçaklardan **hiçbiri bu kümeye bakılarak düzeltilmeyecek**. Düzeltme
  yapılacaksa önce yeni bir ayrık küme yazılır; bu küme o anda yanar.

## 5. Sunumda nasıl söylenir

> "Bugünkü motoru, hiç görmediği 90 cümlede ölçtük ve kümeyi ölçümden önce
> depoya kilitledik. Kesinlik %96: masum cümlelerin 30'da 29'unu rahat
> bıraktı. Duyarlılık %45: açık saldırının %83'ünü, örtük saldırının ise
> yalnızca üçte birini yakaladı. Kural tabanlı bir katmanın tavanı bu —
> ve yol haritamızdaki öğrenen modelin gerekçesi de bu ölçüm."

## 6. Ham çıktı

```
İP-29 · ALTINCI AYRIK KÜME — 90 örnek

GENEL
  Örnek sayısı        : 90
  Kesinlik (precision):  96.4 %
  Duyarlılık (recall) :  45.0 %
  Özgüllük            :  96.7 %
  F1                  :  61.4 %
  F0.5 (kesinlik ağır):  78.5 %
  Doğruluk (accuracy) :  62.2 %
  Kategori doğruluğu  :  85.2 % (23/27)

KARIŞIKLIK MATRİSİ
  gerçek saldırgan│ 27 (DP) │ 33 (YN)
  gerçek temiz    │  1 (YP) │ 29 (DN)

DİLİM BAZINDA
  Açık saldırı      12 örnek · duyarlılık  83.3 %
  Örtük saldırı     34 örnek · duyarlılık  32.4 %
  Nefret söylemi    20 örnek · F1          60.0 %
  Masum / tuzak     12 örnek · özgüllük   100.0 %
  Bağlam            12 örnek · özgüllük    91.7 %

PARÇALARA GÖRE
  1. bilinen yeteneklerin yeni örnekleri : 16/30 yakalandı · duyarlılık %53,3
  2. yakın-kaçış ve bağlam tuzakları    : 29/30 temiz kaldı · özgüllük %96,7
  3. serbest düşmanca ifadeler          : 11/30 yakalandı · duyarlılık %36,7
```

Kaçan 33 örneğin tam listesi: aynı komutun çıktısında.

## 7. İkinci geçiş — 13 Eylül 2026, küme dışı kesinlik onarımlarından sonra

İlk geçişten sonra motor iki turda değişti. İkisinin de gerekçesi bu
kümenin DIŞINDA bulundu, değişiklik listeleri ölçümden önce kayda geçti ve
bu kümeye bakılarak hiçbir kural yazılmadı:

| Tur | Kayıt | İP-29 etkisi |
|---|---|---|
| D1–D6 · kısa kök, kinaye, kendine zarar | docs/20 | **tek örnek değişmedi** |
| D7 · somut adlarda yapısal yönelim | docs/21 | 2 saldırı örneği kaçtı |

D7 sonrası ölçüm (`--genelleme5`):

| Metrik | İlk geçiş | **İkinci geçiş** |
|---|--:|--:|
| Kesinlik | %96,4 | **%96,2** |
| Duyarlılık | %45,0 | **%41,7** |
| F1 | %61,4 | %58,1 |
| F0.5 | %78,5 | **%76,2** |
| Açık saldırı (duyarlılık) | %83,3 | %75,0 |
| Örtük saldırı (duyarlılık) | %32,4 | %29,4 |
| Parça 3 · serbest düşmanca | 11/30 | 9/30 |

Kaçan iki örnek, D7'nin tanıdığı yapıların dışında kalan kuruluşlardır: bir
bileşik yüklem ("… kaz kafalısın": ek "kafalı"ya gelir, "kaz"a değil) ve bir
lanet kalıbı ("… eşek arısı soksun": "soksun" üçüncü şahıs isteğidir; eski
yakınlık kuralı onu ikinci şahıs eki sanıyordu). **Bu iki örneğe bakılarak
kural eklenmeyecek** — eklenirse küme yanar.

Karşılığında, bu kümenin ölçmediği bir hata sınıfı kapandı: ikinci şahıs
geçen gündelik cümlelerde somut adlar ("Sana köpeğimin fotoğrafını atayım")
30 cümlenin 29'unda işaretleniyordu, şimdi 2'sinde (İP-31, docs/21).

**Raporlama:** İki sayı yan yana verilir. İlk geçiş, motorun kümeyi ilk
gördüğü andır; ikinci geçiş, bugünkü motorun aynı kümedeki başarımıdır ve
küme yanmamıştır.
