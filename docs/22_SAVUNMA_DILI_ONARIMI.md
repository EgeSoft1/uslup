# Savunma Dili Onarımı — Aktarılan Düşmanca Görüş

**Tarih:** 13 Eylül 2026 · **Durum:** ÖLÇÜMDEN ÖNCE YAZILDI (bölüm 1–3) · sonuçlar bölüm 4'e eklenecek
**Önceki turlar:** docs/20 (D1–D6), docs/21 (D7)

## 1. Bulgu (küme dışı tarama)

Kimlikten nötr söz eden 10 cümlenin 10'u temiz kaldı, gerçek nefret söylemi
örneklerinin 4'ü de yakalandı. Ancak düşmanca bir görüşü **başkasına
atfederek kınayan** 10 cümlenin 4'ü Yüksek risk (nefret) aldı:

| Cümle | Örüntü |
|---|---|
| Ermenilerin yok edilmesini **savunanlar** yargılanmalı | nefret.varlik_reddi |
| Mültecilerin ülkesine dönmesini **isteyen** pankartlar kaldırılsın | nefret.dislama |
| Romanların bu mahallede yaşanmaz **dendiği** için dışlanması ayıp | nefret.dolayli_dislama |
| Kürtlere yönelik hakaretler temizlenmeli, bu dil kabul edilemez | nefret.varlik_reddi |

İlk üçü aynı kökten: aktarım fiillerinin sıfat-fiil biçimleri bağlam
katmanının aktarım listesinde yok. Liste "diyen/diyenler/dediği" içeriyor
("sana salak diyen haksız" yumuşatılır) ama "isteyen", "savunan",
"söyleyen", "dendiği" içermiyor. Dördüncüsü farklıdır: kimlik terimi ile
düşmanca yüklem arasına ÖZNE giriyor ("hakaretler temizlenmeli");
bu, düzenli ifade düzeyinde çözülebilir bir ayrım değildir.

## 2. Önceden kayıtlı değişiklik

**D8 · Aktarım listesi sıfat-fiil ve ad-fiil biçimleriyle genişletilir.**

`ContextAnalyzer._reportedSpeech` listesine eklenecekler (normalize):

- isteyen, isteyenler, isteyenlere, isteyenleri
- savunan, savunanlar, savunanlara, savunanlari
- soyleyen, soyleyenler, soyleyenlere, soyleyenleri
- iddia (iddia eden, iddia etmek, iddiası)
- dendigi, dendiginde, denmesi
- yazan, yazanlar
- bagiran, bagiranlar

Mekanizma değişmez: aktarım penceresi (4 geri · 3 ileri) içinde bu
kelimelerden biri varsa eşleşme "aktarılmış" sayılır ve yumuşatma tavanı
(0,10) uygulanır. Bu, "diyen" için bugün geçerli olan kuralın aynısıdır.

Dördüncü bulgu ("hakaretler temizlenmeli") D8 kapsamında DEĞİLDİR; bilinen
sınır olarak README'ye yazılır.

## 3. Nasıl raporlanacak

- **İP-32 savunma dili kümesi** (`--savunma`) değişiklikten ÖNCE commit
  edilir; önce ve sonra ölçülür:
  - A · aktarıp kınayan 20 masum cümle
  - B · konuşanın kendi görüşü, 10 saldırı (etkilenmemesi beklenir)
  - C · aktarıp ONAYLAYAN 10 saldırı — D8 bunları da yumuşatır. Bu parça
    bedeli ölçmek için bilerek yazıldı; düzeltmeden sonra kaçmaları beklenir
    ve öyle raporlanır.
- İP-29, İP-30, İP-31 ve bütün etiketli kümeler sonra ölçülür; değişen her
  örnek listelenir. İP-29 değişirse üçüncü geçiş olarak raporlanır.
- Karar ölçütü önceden yazılıyor: A'da kazanılan masum cümle sayısı, C'de
  kaybedilen saldırı sayısından büyük değilse D8 GERİ ALINIR. (Kınama ve
  onaylama aynı yapıyı paylaşır; kural ikisini ayıramaz. Takas ancak masum
  tarafta net kazanç varsa kabul edilir.)

## 4. Sonuçlar

Kayıt `2df4b82` ile girdi; D8 ondan sonraki commit'tedir. Kelime listesi
kayıttakiyle birebir aynıdır.

### İP-32 · savunma dili kümesi

| Parça | Önce | Sonra |
|---|--:|--:|
| A · aktarıp kınayan (20 masum) | 13 temiz (7 Yüksek risk) | **20 temiz** |
| B · konuşanın kendi görüşü (10 saldırı) | 10 yakalandı | **10 yakalandı** |
| C · aktarıp onaylayan (10 saldırı) | 4 yakalandı | **0 yakalandı** |

C parçasında önceden de 6 örnek kaçıyordu: "…olduğunu söyleyen" gibi yan
cümleli kuruluşlar örüntülere hiç uymuyor. D8 kalan 4'ünü de yumuşattı.

### Karar

Kayıtlı ölçüt: A'daki kazanç (**+7**) C'deki kayıptan (**−4**) büyük değilse
geri al. 7 > 4 — **D8 korunur.**

Bu takasın anlamı açıkça yazılmalı: kural, düşmanca bir görüşü aktaran
cümlenin onu kınadığını mı yoksa onayladığını mı ayırt edemez. Ürün,
kınayan kullanıcıyı susturmamayı, onaylayan kullanıcıyı kaçırmaya tercih
eder. Bu, "diyen" için zaten verilmiş kararın aynısıdır.

### Diğer kümeler

**Hiçbir etiketli kümede tek örnek değişmedi.** İP-29 %96,2 · %41,7
(ikinci geçiş, D7 sonrası) olarak durur; İP-30 120/120; İP-31 28/30 ·
20/20; geliştirme kümesi %100 · %97,0.

### Kapsam dışı kalan

"Kürtlere yönelik hakaretler temizlenmeli" hâlâ nefret söylemi sayılıyor
(araya giren özne). README'de bilinen sınır olarak yazılı.

### Test

`civility_engine_test` · "düşmanca görüşü başkasına atfedip kınayan cümle
nefret sayılmaz (D8)": üç kınama cümlesi temiz, üç düz nefret söylemi
yakalanıyor; onaylama bedeli test yorumunda kayıtlı.
