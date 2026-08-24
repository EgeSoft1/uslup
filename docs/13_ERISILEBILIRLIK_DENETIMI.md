# İP-16 — Erişilebilirlik Denetimi

**Tarih:** 24 Ağustos 2026 · **Kapsam:** WCAG 2.1 AA
**Araç:** [`mobile/tool/erisilebilirlik_denetimi.dart`](../mobile/tool/erisilebilirlik_denetimi.dart)
**Durum:** kontrast denetimi tamamlandı ve **5 ihlal düzeltildi** · cihaz üstü
denetim Flutter kurulumu bekliyor

---

## 1. Neden ölçüldü

Teknik rapor §3.3, arayüzün WCAG 2.1 başarı ölçütlerini karşıladığını
bildiriyordu. Bu bir **iddiaydı** — hiçbir kontrast oranı hesaplanmamıştı.

Bir erişilebilirlik iddiası, ölçülmedikçe iddiadır. Bu belge iddianın sayısal
karşılığını üretir; jüri tek komutla yeniden üretebilir:

```bash
cd mobile
dart run tool/erisilebilirlik_denetimi.dart
```

Araç **Flutter gerektirmez** — saf Dart'tır. Paleti kaynak dosyadan okur, yani
renk değişirse denetim kendiliğinden yeni değerlerle çalışır; elle güncellenen
bir tablo bayatlayamaz.

---

## 2. Ölçüt

WCAG 2.1 bağıl parlaklık ve kontrast oranı:

```
L = 0,2126·R + 0,7152·G + 0,0722·B        (doğrusallaştırılmış sRGB kanalları)
C = (L_açık + 0,05) / (L_koyu + 0,05)
```

| Başarı ölçütü | Eşik |
|---|---|
| **1.4.3** Kontrast (Minimum), AA | normal metin **4,5:1** · büyük metin **3,0:1** |
| **1.4.6** Kontrast (Gelişmiş), AAA | normal metin 7,0:1 · büyük metin 4,5:1 |
| **1.4.11** Metin Dışı Kontrast, AA | arayüz bileşeni / grafik **3,0:1** |

Büyük metin: ≥18,66 px kalın ya da ≥24 px normal.

---

## 3. İlk ölçüm — 5 ihlal

30 ön plan/arka plan çiftinin 25'i eşiği geçti, **5'i kaldı**:

| Tema | Çift | Ölçülen | Gerekli | Ölçüt |
|---|---|:--:|:--:|---|
| Açık | İkincil metin / zemin | 4,46:1 | 4,5:1 | 1.4.3 AA |
| Açık | Üçüncül metin / yüzey | 2,52:1 | 4,5:1 | 1.4.3 AA |
| Açık | Başarı rengi / yüzey | 2,54:1 | 3,0:1 | 1.4.11 AA |
| Açık | Kenarlık / yüzey | 1,28:1 | 3,0:1 | 1.4.11 AA |
| Koyu | Kenarlık / yüzey | 1,30:1 | 3,0:1 | 1.4.11 AA |

**İkincil metin 4,46:1** — eşiğin 0,04 altında. Bu tür ihlaller gözle
yakalanamaz; ölçüm olmadan raporda "WCAG uyumlu" yazmak yanlış beyan olurdu.

---

## 4. Düzeltmeler

### 4.1 Üç renk eşiğe çekildi

| Belirteç | Önce | Sonra | Yeni oran |
|---|---|---|:--:|
| `inkSecondary` | `#77726E` | `#706B67` | 4,94:1 |
| `inkTertiary` | `#A9A29C` | `#767068` | 4,90:1 |
| `success` (açık tema) | `#10B981` | `#0B8258` | 4,83:1 |

**`inkTertiary` neden bu kadar koyulaştı.** Bu renk, nezaket motoru bilgi
satırında **11,5 px** metinde kullanılıyor. 11,5 px "büyük metin" değildir;
dolayısıyla 3,0:1 istisnası geçersizdir ve eşik 4,5:1'dir. Görsel hiyerarşi
korunuyor: ana metin 17:1, üçüncül metin 4,9:1 — aradaki fark hâlâ üç kattan
fazla.

**`success` neden değişti.** Durum renkleri bu üründe **bilgi taşıyıcıdır**:
yeşil halka "gönderilebilir", turuncu "dikkat", kırmızı "yüksek risk" demektir.
Ayırt edilemeyen bir durum rengi, renk körü ya da düşük görüşlü kullanıcı için
sinyalin tamamen kaybolması anlamına gelir. `#10B981` beyaz yüzeyde 2,54:1
veriyordu.

### 4.2 Kenarlık — belirteç ayrımı, renk değişimi değil

WCAG 1.4.11 yalnızca *"bir arayüz bileşenini tanımak için gerekli görsel
bilgiyi"* kapsar; **süslemeyi kapsamaz.** Kart ayracı ve liste çizgisi
dekoratiftir. Ama **metin girdisinin sınırı dekoratif değildir** — kullanıcı
yazma alanının nerede başladığını oradan anlar.

Bu yüzden renk değiştirilmedi, belirteç **ikiye ayrıldı**:

| Belirteç | Kullanım | Ölçüt |
|---|---|---|
| `border` (`#EBE2D6` / `#352E2B`) | kart ayracı, liste çizgisi | dekoratif — muaf |
| `borderStrong` (`#8F8271` / `#7A7167`) | metin girdisi, seçilebilir çip | **3,75:1 / 3,60:1** |

`InputDecorationTheme`'in `border` ve `enabledBorder` alanları
`borderStrong`'a bağlandı. Görsel dil bozulmadı: kartlar hâlâ yumuşak
ayraçlı, girdi alanları görünür sınırlı.

---

## 5. Son durum — 30/30

```
Denetlenen çift : 30
Eşiği geçen     : 30
Eşiğin altında  : 0
```

| Tema | Çift | Oran | Sonuç |
|---|---|:--:|---|
| Açık | Ana metin / zemin | 15,95:1 | AA + **AAA** |
| Açık | Ana metin / yüzey | 17,01:1 | AA + **AAA** |
| Açık | İkincil metin / zemin | 4,94:1 | AA |
| Açık | Üçüncül metin / yüzey | 4,90:1 | AA |
| Açık | Marka üstü metin | 5,88:1 | AA |
| Açık | Marka / zemin (bileşen) | 5,52:1 | AA |
| Açık | Başarı / yüzey (bileşen) | 4,83:1 | AA |
| Açık | Uyarı / yüzey (bileşen) | 3,19:1 | AA |
| Açık | Tehlike / yüzey (bileşen) | 4,83:1 | AA |
| Açık | Etkileşimli kenarlık | 3,75:1 | AA |
| Koyu | Ana metin / zemin | 16,74:1 | AA + **AAA** |
| Koyu | İkincil metin / zemin | 7,37:1 | AA + **AAA** |
| Koyu | Üçüncül metin / yüzey | 3,25:1 | AA (büyük) |
| Koyu | Başarı / yüzey (bileşen) | 8,98:1 | AA |
| Koyu | Etkileşimli kenarlık | 3,60:1 | AA |

*(Tam tablo için aracı çalıştırın; burada temsilî satırlar var.)*

---

## 6. Ekran okuyucu — nezaket puanı halkası

Kontrast, erişilebilirliğin ölçülebilir parçasıdır; tamamı değildir.

Denetim sırasında çekirdek ekranda (`civility_composer_screen.dart`) **hiç
`Semantics` düğümü olmadığı** görüldü. En kritik bileşen nezaket puanı
halkasıydı: üç görsel parçadan (ilerleme halkası, sayı, seviye etiketi) tek bir
anlam kuruyor ama ekran okuyucuya üç kopuk parça olarak gidiyordu:

> *"belirsiz ilerleme çubuğu"* … *"72"* … *"Riskli"*

**Düzeltme:**

```dart
Semantics(
  container: true,
  liveRegion: true,
  label: 'Nezaket puanı $score, yüz üzerinden. Durum: $label',
  child: ExcludeSemantics(child: /* görsel parçalar */),
)
```

`liveRegion: true` burada **işlevsel bir zorunluluktur**, kozmetik değil. Puan
kullanıcı yazarken değişir. Canlı bölge olmadan görme engelli kullanıcı
uyarının oluştuğunu ancak odağı halkaya taşırsa fark eder — yani ürünün
"müdahale gönderim öncesindedir" iddiası o kullanıcı için geçersiz olur.

---

## 7. Kapsam beyanı — ölçülmeyenler

Bu denetim **statik**tir. Aşağıdakiler ölçülMEMİŞTİR ve rapor bunları
karşılandı diye sunmamalıdır:

| Ölçüt | Durum | Neden |
|---|---|---|
| 1.4.4 Metin Yeniden Boyutlandırma (%200) | Ölçülmedi | Cihaz üstü çalıştırma gerekir |
| 2.4.3 Odak Sırası | Ölçülmedi | Klavye/anahtar denetimi gerekir |
| 2.5.5 Hedef Boyutu (44×44) | Kısmen | Tema düğmeleri 52 px; alt gezinme ölçülmedi |
| 4.1.2 Ad, Rol, Değer | Kısmen | Puan halkası düzeltildi; diğer bileşenler denetlenmedi |
| Ekran okuyucu ile uçtan uca oturum | Yapılmadı | TalkBack/VoiceOver ile cihazda test gerekir |

> ✅ **Engel kalktı (25 Ağustos 2026).** Flutter 3.47.1 kuruldu; bu belgedeki
> palet ve `Semantics` değişiklikleri artık **derleyiciyle doğrulanmıştır**:
> `flutter analyze` temiz, 12 arayüz testi geçiyor.
>
> Doğrulama boşuna değildi — derleyici, elle yapılan bir düzenlemede oluşan
> kapanmamış dize hatasını (`civility_composer_screen.dart:561`) yakaladı.
> Statik ölçüm o hatayı göremezdi; uygulama hiç açılmayacaktı.
>
> Cihaz üstü ekran okuyucu denetimi (TalkBack/VoiceOver) **hâlâ yapılmadı**:
> gerçek bir cihazda oturum gerektirir.
