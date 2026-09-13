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

*(Ölçümden sonra eklenecek.)*
