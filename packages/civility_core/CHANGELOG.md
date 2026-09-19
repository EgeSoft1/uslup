# civility_core — Sürüm Notları

Biçim: her sürüm **Kırıcı**, **Eklenen**, **Değişen davranış**, **Ölçüm**
başlıklarıyla yazılır. Sürüm numarası [anlamsal sürümlemeye](https://semver.org/lang/tr/)
uyar ve üç yerde aynı olmak zorundadır: `pubspec.yaml`, `lib/src/surum.dart`
ve bu dosyanın ilk başlığı — `test/surum_test.dart` üçünü karşılaştırır.

Bir sınıflandırıcıda "davranış değişikliği" API değişikliği kadar önemlidir:
aynı cümle yeni sürümde farklı karar alabilir. Bu yüzden her sürüm, ölçüm
kümelerindeki farkı da yazar. Ölçüm farkı olmayan sürüm "ölçüm farkı yok"
diye yazılır; boş bırakılmaz.

---

## 2.1.0 — 19 Eylül 2026

Taban: 2.0.0. Ayrıntı ve ölçüm kaydı: `docs/32_IKILEME_VE_SOZ_VARLIGI.md`.

### Kırıcı

Yok. Genel API değişmedi.

### Değişen davranış

- **Kelime içi harf ikilemesi** (docs/32): "sikerriimmo", "şerrefsiz",
  "pezzevenk", "orrospu", "ssalak" artık işaretlenir. Önceki yollar
  (`_dedouble`, uzatma kuyruğu) eşleşmediğinde bütün ikililer teke indirilir;
  ikiliden sonra düşen tek harflik kuyruk ("…mm-o") atılır; özgün metindeki
  3+ tekrar ikiye indirilerek yazılışında ikili olan girdiler ("namusssuz")
  bulunur. Yönelim şartlı girdiler bu yoldan eşleşemez; yazılan Türkçe harf
  kökle çelişirse ("şallak" ≠ "salak") eşleşme reddedilir.
- **"sikke" maskesi daraltıldı**: tek bir `sikke` ön eki "sikkerim"
  ikilemesini de temizliyordu. Yerine para anlamının çekimleri yazıldı.
- **Söz varlığı**: sözlük 310 → 327 girdi (17 yeni: `kevaşe`, `kaşar`,
  `kancık`, `yosma`, `boynuzlu`, `enayi`, `angut`, `sümsük`, `sapık`,
  `ucube`, `hanzo`, `tipsiz`, `bok çuvalı`, `allahın belası`, `sik kafalı`,
  `ağzını burnunu kır`, `bıçaklarım`). Gündelik somut anlamı olanlar
  yönelim şartlıdır ("kaşar peyniri", "angut kuşu"). Denetlenip alınmayanlar
  docs/32 §3'te.
- Üslup Asistanı'nın "Nasıl çalışıyor?" cevabındaki sayılar artık motordan
  sayılır; önceden elle yazılmış "310 girdi" bayatlamıştı.

### Ölçüm (2.0.0 → 2.1.0)

| Ölçüm | 2.0.0 | 2.1.0 |
|---|:--:|:--:|
| 13 etiketli küme (1.115 cümle) — değişen karar | — | **0** (toksisite değerleri dahil) |
| Kelime listesi (91.861 biçim) — tek başına yeni masum işaretleme | — | **0** |
| Sözlük girdilerinin ikileme varyantları — yakalanan | %34,4 (3.636) | **%99,2** (3.668) |
| Mesaj p50 · uzun gönderi p50 (AOT, aynı makine, dönüşümlü) | 70 µs · 1.070 µs | 72 µs · 1.128 µs |
| Çekirdek test sayısı | 765 | 839 |

---

## 2.0.0 — 15 Eylül 2026

Taban: 1.0.0 (`0d13176`, 13 Eylül 2026). Bu sürüm henüz commit edilmedi;
çalışma kopyasındadır.

### Kırıcı

- `ImplicitFamily` iki değer kazandı: `kalipYargi`, `hakReddi`. Bu enum
  üzerinde kapsamlı `switch` yazan tüketici kod derlenmez; iki dalı eklemesi
  gerekir. Paket içindeki `label` ve `explanation` güncellendi. Bu tek
  değişiklik sürümü 2.0.0 yapar.

### Eklenen

- **Kullanıcı ayarları ve müdahale politikası** (docs/27):
  `UslupAyarlari`, `Hassasiyet`, `MudahalePolitikasi`. Motor değişmez; ayar
  yalnızca çözümlemenin kullanıcıya yansımasını belirler. Varsayılan ayarda
  politika çözümlemenin kendisini döndürür. Tehdit, nefret söylemi, taciz ve
  hakaret uyarıları tek tek susturulamaz.
- **"Bu uyarı yanlış" bildirimi** (docs/27): `CommunitySignal
  .yanlisAlarmBildirildi` (bool — metin ya da terim taşımaz),
  `CommunityHealthReport.falseAlarmReports`, `falseAlarmRate`,
  `falseAlarmByCategory`, `validInterventions`. Hepsi k-anonimlik altında;
  eşik altındaki bildirim düzeltme oranının paydasından da çıkarılmaz ki geri
  hesaplanamasın.
- **Kimlik eksenleri** (docs/26): cinsiyet, yaş, engellilik ve göç için 12
  nefret kuruluşu; `ImplicitPattern.suppressedBy` (koşul/gerekçe tümleci);
  `HatePatterns.groupIsNotSubject` (ilgeç tümleci ve "X değil" öznesi);
  `IdentityTerms.slotExceptMigration`, `genericAblative`, 6 yeni kimlik adı.
- **Ölçüm kümeleri**: `IdentityAxesDataset` (İP-33), `IdentityAxesBlindDataset`
  (İP-34), `IdentityAxesBlind2Dataset` (İP-35); `bin/evaluate.dart --eksenler`.
- **Üslup Asistanı** (docs/29): `UslupAsistani`, `AsistanNiyeti`, `IcerikKonusu`,
  `AsistanCevabi`, `AsistanOrnegi`. Türkçe niyet çözümleyici — kullanıcının
  isteğinden niyeti çıkarır ve içeriği getirir ("bana nefret söylemi örnekleri
  sun"). **Dil modeli yoktur, ağ çağrısı yoktur**; motorun kendi normalizasyon
  ve biçimbilim katmanlarını kullanır. Sunduğu her örnek cümle
  `test/asistan_test.dart` içinde gerçek motordan geçirilir: "işaretlenir"
  iddiası motorun kararıyla uyuşmazsa test kırılır.
- **Sürüm sabiti**: `CivilityCoreSurum.surum`.
- Küfür kapsamı (docs/25): nesne + fiil çiftleri, bitişik yazım bölme,
  yıldızla sansür, ünlem işaretiyle "i" gizlemesi; sözlük 256 → 308 girdi.

### Hızlandırma — davranış değişikliği yok (docs/28)

Uzun gönderide çözümleme ~3 kat hızlandı. Dördü de aynı hatanın yüzleriydi:
karakter başına String ayırmak.

- **Normalizasyon karakter planı**: dönüşüm zinciri karakterin yalnızca
  kendisine bağlı olduğu için önceden hesaplanır; sıcak döngü ara String
  üretmez. Sıfır genişlikli karakter ve harf tekrarı ön geçişleri, böyle bir
  karakter yoksa ara yapı kurmaz.
- **Öbek katmanı ön filtresi**: `LiteralIndex.literals` — çok kelimeli
  öbekler tek Aho–Corasick taramasıyla elenir, `indexOf` yalnızca metinde
  geçebilecek öbekler için çalışır.
- **Bağlam harf tablosu**: büyük harf oranı, tırnak, noktalama ve cümle
  sınırı taramaları kod birimi üzerinde çalışır. Harf/büyük tanımı birebir
  korundu.
- **Birleştirme kapıları**: komşu kelimelerin birleşimi, uzunluk ve ilk harf
  kapılarını geçmiyorsa hiç kurulmaz.

Aynı makinede, aynı ölçüm aracıyla (AOT, 11 senaryo × 2.000 tekrar):

| | Önce | Sonra |
|---|--:|--:|
| Mesaj ≤200 kr · p50 | 169 µs | **84 µs** |
| Uzun gönderi · p50 | 3.057 µs | **1.027 µs** |
| ~2.400 kr · p99 | 8.798 µs (kare bütçesinin %55'i) | **2.720 µs (%17)** |
| Genel p99 | 6.156 µs | **1.840 µs** |

Denklik kanıtı: `test/normalizer_plan_test.dart` hızlandırmadan önceki
uygulamayı referans olarak tutar ve BMP'nin bütün kod noktalarında, vekil
yarılarında, 60.000 rastgele birleşimde ve 13 etiketli kümenin bütün
cümlelerinde çıktıyı karşılaştırır. `bin/evaluate.dart --hepsi` sayılarının
hiçbiri değişmedi.

### Değişen davranış

- **D9 kod denetimi** (docs/23): kesme işareti artık tırnak sayılmaz; kimlik
  adı belirtisiz tamlamanın niteleyicisiyse ("Kadınlar tuvaleti kirli") nefret
  söylemi üretmez; kendine zarar ifadesi tehdit değil destek işaretidir.
- **"ülkelerine dön"** kalıbı mastarı almaz: "Mülteciler ülkelerine dönmek
  istiyor" artık temiz.
- **Tamlama denetimi** iyelik ekine benzeyen sıfatları (`yeni`, `eski`,
  `doğru`, `kendi`…) tamlama başı saymaz.
- **İki ölü kimlik terimi onarıldı**: `queer`, `down sendromlu` normalize
  metinde hiç geçemiyordu (q → k, w → v). Örüntü kaynaklarında q/w/x artık
  testle yasak.
- **Uzatma kuyruğu kapatıldı**: tuş basılı tutulurken uzatmanın ardından
  düşen bir iki karakter kaçış sağlıyordu. Normalizasyon uzatmayı daraltıyor
  ama artığı bırakıyor, kalan biçim geçerli bir Türkçe çekim olmadığı için
  sözlükte bulunamıyordu:

  | Yazılan | Normalize | Önce | Sonra |
  |---|---|---|---|
  | `sikerimmmmmmmmo` | `sikerimo` | Temiz | Yüksek |
  | `siktirrrrrrrra` | `siktira` | Temiz | Yüksek |
  | `salakkkkkkko` | `salako` | Temiz | Riskli |
  | `aptalllllllx` | `aptalks` | Temiz | Riskli |

  Kuyruksuz uzatma (`sikerimmmmm`) zaten yakalanıyordu; kaçan yalnızca
  kuyruklu biçimdi. Deneme yalnızca sözlükte hiçbir eşleşme bulunamadığında
  yapılır ve üç kapıdan geçer: özgün metinde gerçekten 3+ tekrar olacak,
  kuyruk en fazla iki karakter olacak, kalan kök en az üç harf olacak. Kısa
  kökler (D1) bu yoldan eşleşemez. Uzatma yoksa hiç denenmez: `sikerimo`
  kendi başına temiz kalır. Kuyruk yalnızca sondan kesildiği için kökün harf
  konumları kaymaz ve yüzey kanıtı denetimi bu yolda da uygulanır.

### Ölçüm (1.0.0 → 2.0.0)

| Küme | 1.0.0 | 2.0.0 |
|---|---|---|
| İP-29 (geçerli ayrık) kesinlik · duyarlılık · F0.5 | %96,2 · %41,7 · %76,2 (D7 sonrası) | %100 · **%45,0** · **%80,4** (D9, docs/25, docs/26 sonrası; yarı-kör) |
| İP-35 kimlik eksenleri (tek geçiş) | — | %100 · %15,0 · özgüllük %100 |
| İP-30 gündelik metin yanlış alarm | 0 / 120 | 0 / 120 |
| Geliştirme kümesi kesinlik · duyarlılık | kayıt bu dosyada yok | %100 · %97,0 |
| Uzun gönderi gecikmesi · p50 (AOT) | 3.057 µs | **1.027 µs** (docs/28) |
| Çekirdek test sayısı | 320 | 765 |
| Arayüz test sayısı | — | 79 |

Geçmiş geçişlerin ayrıntısı: README "Ölçülen sonuçlar" tablosu ve docs/18 §7.

---

## 1.0.0 — 13 Eylül 2026

İlk sürümlü taban (`0d13176`). İçerik: normalizasyon ve gizleme direnci,
Türkçe biçimbilim, 256 girdilik sözlük, edimbilimsel örüntü ve deyim
katmanları, 17 nefret kuruluşu, gönderge çözümleme, tavanlı bağlam, yerel
yeniden yazıcı (Net · Nazik · Diyalog), topluluk sağlığı toplulaştırıcısı
(k = 5), İP-15 … İP-32 ölçüm kümeleri. Ayrıntı: `docs/14` … `docs/22`.
