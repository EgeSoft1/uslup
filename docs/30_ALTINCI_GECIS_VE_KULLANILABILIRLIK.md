# Altıncı Geçiş ve Kullanılabilirlik Testi — 18 Eylül 2026

Bu belge iki şeyi kayda geçirir:

1. İP-29'un **altıncı geçişi** — ve o geçişin neden kör sayılamayacağı.
2. **Kullanılabilirlik testinin sonucu** — ve testin bulduğu kusur.

İkisi de rakamı yükselten değil, rakamın anlamını daraltan kayıtlardır. Bu
belgenin varlık sebebi budur: ölçüm iyileştiğinde değil, ölçümün geçerliliği
zayıfladığında yazmak.

---

## 1. Neyin ölçüldüğü

`packages/civility_core` çekirdeğinde bugünkü motorla İP-29 (6. ayrık küme,
90 örnek) yeniden ölçüldü:

```
dart run bin/evaluate.dart --genelleme5
```

| Ölçü | Değer |
|---|---|
| Kesinlik | **%100,0** — 30 masum cümlenin 30'u temiz |
| Duyarlılık | **%46,7** — 60 saldırı örneğinin 28'i yakalandı |
| Özgüllük | %100,0 |
| F1 | %63,6 |
| **F0.5** — ürünün hedef fonksiyonu | **%81,4** |
| Açık saldırı (12 örnek) | %83,3 |
| Örtük saldırı (34 örnek) | %32,4 |
| Nefret söylemi (20 örnek) | F1 %66,7 |
| Masum / tuzak (12) · Bağlam (12) | özgüllük %100,0 · %100,0 |

---

## 2. Bayat sayı bulgusu — dört yerde yanlış rakam duruyordu

Ölçüm, `mobile/test/olcum_tutarliligi_test.dart` **kırıldığı için** yapıldı.
O test, ekranda ve README'de elle yazılı İP-29 sayılarının motorun çalışma
anındaki ölçümüyle aynı olduğunu denetler. Dört yer bayattı:

| Yer | Yazan | Gerçek |
|---|---|---|
| `README.md` İP-29 tablosu | duyarlılık %45,0 · F0.5 %80,4 | %46,7 · %81,4 |
| `mobile/lib/core/civility/civility_runtime.dart` · `olcumOzeti` | %45,0 | %46,7 |
| `mobile/lib/presentation/settings/about_screen.dart` | %45,0 · F0.5 %80,4 | %46,7 · %81,4 |
| `mobile/lib/presentation/uslup/uslup_panel_screen.dart` | %45,0 · F1 %62,1 | %46,7 · %63,6 |

Dördü de düzeltildi. **Testin kendisi doğru çalıştı:** motor değişti, elle
yazılmış sayılar değişmedi, test bunu yakaladı. Jüriye bayat sayı gösterilmesi
bu sayede engellendi.

---

## 3. Duyarlılığı kim yükseltti — ve neden bu bir genelleme kanıtı değil

Son commit (`0d13176`, D8) ile bugünkü çalışma ağacı arasındaki fark ölçüldü.
Geçici bir çalışma ağacı (`git worktree`) kurulup iki durum aynı kümede
karşılaştırıldı:

| | `0d13176` (D8) | Bugün |
|---|---|---|
| Kesinlik | %96,2 | %100,0 |
| Duyarlılık | %41,7 | %46,7 |
| P1 · bilinen yeteneklerin yeni kuruluşları | 16/30 | 17/30 |
| P3 · serbest düşmanca ifadeler | 9/30 | 11/30 |

Değişen dört örnek:

| Örnek | Önce | Sonra | Kaynak |
|---|---|---|---|
| `Selin'e "senin gibilerden bu beklenirdi" demişler, çok ayıp` | yanlış pozitif | temiz | docs/23 · D9, kesme işareti |
| `ahmakk mısın nesin` | kaçak | yakalandı | docs/25, çift harfle uzatma |
| `engelliler evde otursun` | kaçak | yakalandı | docs/26, kimlik eksenleri |
| `karşıma çıkma, iyi olmaz` | kaçak | yakalandı | **kayıtsız — aşağıya bak** |

### 3.1. `karşıma çıkma, iyi olmaz` kör değildir

Bu örneği yakalayan örüntü `packages/civility_core/lib/src/detect/implicit_patterns.dart`
içindeki `tehdit.denk_gelme`. Kaynak kodundaki açıklaması şudur:

```dart
// "bana bir daha denk gelme" · "karşıma çıkma"
```

**Örüntünün açıklaması, ölçüm kümesinin kendi cümlesini alıntılıyor.** Yani
örüntü bu örneğe bakılarak yazılmıştır. Ayrık küme disiplininin tanımı gereği
bu örnek artık kör değildir ve duyarlılıktaki **+%1,7 bir genelleme kanıtı
sayılamaz.**

Üstelik bu değişiklik yazıldığı sırada **hiçbir belgeye geçirilmemişti**:
docs/18, 24, 25, 26 ve 27–29'da `denk_gelme` geçmiyor. Kayıt, sayı ölçülüp
kaynağı kaynak kodu okunarak bulunduktan sonra — yani olaydan sonra —
eklenmiştir. Bunu gizlemek yerine yazmak, kuralı bozmanın maliyetini
görünür kılar.

### 3.2. Geriye ne kalıyor

Kesinlik tarafı sağlamdır: 30 masum cümlenin 30'u temiz ve masum dilime
bakılarak yapılan hiçbir düzeltme yok. **İP-29'un bugün geçerli olan iddiası
kesinliktir, duyarlılık değil.** Duyarlılık için kör bir ölçüm isteniyorsa
yeni bir küme yazılmalıdır.

Ayrıca hatırlatma: İP-29'un 60 saldırı örneğinden **32'si hâlâ kaçıyor** ve
kaçakların 23'ü örtük dilimde. Bu, kural tabanlı katmanın tavanıdır ve
gizlenmiyor.

---

## 4. Kullanılabilirlik testi — uygulandı

Protokol ve ham sonuç formu: [`docs/10_KULLANILABILIRLIK_TESTI.md`](10_KULLANILABILIRLIK_TESTI.md).

**Yöntem:** görev tabanlı, sesli düşünme, 5 katılımcı × 5 görev, katılımcı
başına ~15 dk. Katılımcıya ürünün ne yaptığı anlatılmadı. Yazdığı metin
kaydedilmedi.

| Ölçü | Değer |
|---|---|
| Yardımsız görev başarı oranı | **%72,7 (16/22)** |
| Yardımla tamamlanan | 6/22 |
| Tamamlama notu tutulmayan | 3/25 (Katılımcı 1 · G3–G5) |
| Ortalama SEQ | **6,6 / 7** (payda 25) |
| En düşük SEQ | 4/7 (Katılımcı 3 · G1) |
| **G2+G3'te beklenmedik uyarı** | **0/10** |

### 4.1. Kritik ölçüt tutdu

G2 (mağdur anlatısı) ve G3 (kimlik beyanı) görevlerinde **hiçbir uyarı
çıkmaması** gerekiyordu. On denemenin hiçbirinde çıkmadı. Ürünün en ayırt
edici iddiası bu oturumda kırılmadı.

**Bu satırın ağırlığı sınırlıdır ve öyle sunulmalıdır.** On deneme bir oranı
doğrulamaz. Söylediği şey "yanlış uyarı oranı sıfırdır" değil, "on denemede
kusur görülmedi"dir. İddianın asıl dayanağı ölçülmüş motor davranışıdır:
İP-29'da 30 masumun 30'u temiz, İP-35'te 20 masumun 20'si temiz, ve iki
yapısal test (sözlüğe kimlik adı giremez; mağdur/kimlik cümlesi uyarı almaz).
Oturum bunları çürütmedi; tek başına kanıtlamaz.

### 4.2. Testin asıl değeri — dört bulgu

Sayılar değil, bulgular kıymetli:

1. **G1 oturumun en zor göreviydi.** Beş katılımcının ikisi yardımla
   tamamladı; iki en düşük SEQ puanı (4 ve 5) buradan geldi. Uyarı kartından
   sonraki adım yeterince net değil.
2. **G3'ün görev metni belirsiz.** İki katılımcı ne yazacağını kestiremedi —
   protokol kusuru, ürün kusuru değil.
3. **Tamamlama notu üç görevde tutulmadı** ve iki ayrı payda doğurdu
   (başarı 22, SEQ 25).
4. **Uyarı çıksaydı elde cümle olmayacaktı.** Mahremiyet kuralı gereği metin
   kaydedilmiyor; protokolde izinli not alma adımı yok. Bu turda kusur
   çıkmadığı için maliyeti görünmedi, ama açık bir tasarım boşluğu.

G4 (topluluk paneli) ve G5'te (uyarıya rağmen gönderme) beş katılımcının beşi
7/7 verdi: **mahremiyet iletişimi ve engellenmezlik anlaşılıyor.** Zorlanılan
yer uyarıdan sonraki adım.

---

## 5. Bu belgenin raporda karşılığı

- `docs/09_RAPOR_METNI.md` §3.3 — kullanılabilirlik testi artık "planlandı"
  değil "uygulandı"; sonuç ve bulunan kusur yazılı.
- `README.md` — İP-29 tablosuna altıncı geçiş sütunu ve körlük uyarısı.
- Sunum — slayt 10'daki "kullanılabilirlik testi henüz yapılmadı" satırı
  kaldırıldı; slayt 11'deki boş alanlar dolduruldu.

---

## 6. Açık kalan işler

| # | İş | Neden |
|---|---|---|
| 1 | Duyarlılık için yeni kör küme (İP-36) | İP-29'un duyarlılık tarafı artık kör değil |
| 2 | `tehdit.denk_gelme` gibi örüntülerde kaynak disiplini | Ölçüm kümesinin cümlesi örüntü açıklamasına yazılmamalı |
| 3 | Uyarı sonrası adımın netleştirilmesi | G1 oturumun en zor göreviydi (docs/10 §7 · 1) |
| 4 | Protokole izinli cümle notu adımı | Kusur çıksaydı yeniden üretilemezdi (docs/10 §8 · 1) |
| 5 | İkinci etiketleyici ve Cohen's kappa | Metrikler hâlâ tek etiketleyicili |
