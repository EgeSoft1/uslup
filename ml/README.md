# Denetimli Taban Çizgisi — Eğitilmiş Model Karşılaştırması

Bu dizin, ürünün **kullanmadığı** yolu ölçer: aynı etiketli küme üzerinde
denetimli bir sınıflandırıcı eğitir ve kural tabanlı motorla karşılaştırır.

Amaç bir model teslim etmek değil, **mimari kararı ölçüme dayandırmaktır.**
Projenin çekirdeği (`packages/civility_core`) saf Dart'tır ve bu dizindeki
hiçbir şeye bağımlı değildir; buradaki Python yalnızca ölçüm aracıdır.

---

## Protokol

Rapordaki kuralın aynısı uygulanır — model seçimi ayrık kümeye **bakılmadan**
yapılır:

1. **Model seçimi**, yalnızca geliştirme kümesinde (n=256), 5 katlı çapraz
   doğrulama ile. 45 aday: karakter n-gram / kelime n-gram / birleşik öznitelik,
   üç ön işleme varyantı (ham · normalize · aksan katlanmış), lojistik
   regresyon / doğrusal DVM / naif Bayes.
2. Sıralama ölçütü **F0.5**'tir — bu üründe yanlış pozitif, yanlış negatiften
   pahalıdır.
3. Ayrık kümeye (n=80) **tek bir kez**, seçim bittikten sonra bakılır.
4. Sonuç **düzeltme yapılmadan** raporlanır.

Kümeler arasında metin sızıntısı olmadığı `01_veri_cikar.py` tarafından
doğrulanır (ortak metin: 0).

---

## Çalıştırma

```bash
pip install scikit-learn numpy
cd ml
python 01_veri_cikar.py    # Dart kümelerinden veriyi çıkarır, sızıntıyı denetler
python 02_egit_ve_olc.py   # CV ile seçim + ayrık ölçüm + öğrenme eğrisi + hatalar
python 03_kiyasla.py       # kural motoru ile dilim bazında kıyas ve melez senaryolar
```

---

## Bulgu

Seçilen model: **karakter n-gram (2–4), aksan katlanmış, TF-IDF + lojistik
regresyon (C=10)**. Çapraz doğrulama F0.5 = %85,7.

Ayrık kümede (n=80):

| Yaklaşım | Kesinlik | Duyarlılık | F1 | YP | YN |
|---|---|---|---|---|---|
| Denetimli model | %87,3 | %96,0 | %91,4 | 7 | 2 |
| Kural motoru (bugün) | %98,0 | %100,0 | %99,0 | 1 | 0 |
| Melez — kesişim (VE) | %98,0 | %96,0 | %97,0 | 1 | 2 |
| Melez — birleşim (VEYA) | %87,7 | %100,0 | %93,5 | 7 | 0 |

**Ölçüm asimetriktir ve bu gizlenmemelidir.** Ayrık küme model için gerçekten
ayrıktır; kural motoru için değildir, çünkü motor ilk ölçümden sonra düzeltilmiştir
(bkz. `docs/04_MODEL_DEGERLENDIRME.md` §5). Motorun dürüst ayrık sayısı
**F1 = %84,2**'dir. Simetrik kıyas ancak ikisinin de görmediği yeni bir küme
üzerinde mümkündür; bu İP-14 olarak planlanmıştır.

Asimetriden **etkilenmeyen** bulgu şudur:

- Model, kural motorunun kaçırdığı **hiçbir örneği yakalamamaktadır**.
- Model, motorun yapmadığı **altı yanlış pozitif** üretmektedir ve bunların
  tamamı ürünün önlemek için var olduğu hata türüdür:

```
"aferin sana, gerçekten hak ettin"      → iltifat, işaretlendi
"senin gibi birini tanımak güzel"       → iltifat, işaretlendi
"seni aptal sanmıyorum"                 → olumsuzlama, işaretlendi
"sana salak diyen haksız"               → mağduru savunuyor, işaretlendi
"hepimiz insanız sonuçta"               → nötr, işaretlendi
"hiçbir işe yaramayan bir uygulama bu"  → nesneye eleştiri, işaretlendi
```

Dilim bazında bağlam özgüllüğü: **model %50,0 · kural motoru %83,3**.

256 örnekten 3.864 öznitelik türetilmektedir; örnek başına on beş öznitelik.
Yanlış pozitiflerin karakteri bu oranın doğrudan sonucudur — model
"salak"/"aptal"/"şerefsiz" karakter dizilerinin varlığını öğrenmekte,
olumsuzlama ve aktarımın bu dizileri tersine çevirdiğini öğrenememektedir.

## Bu bulgunun sınırı

Bu ölçüm, **doğrusal bir taban çizgisinin bu veri hacminde** yetersiz kaldığını
gösterir. Şunu **göstermez**: önceden eğitilmiş bir Türkçe dil modelinin
(ör. BERTurk) ince ayarının da başarısız olacağı. Öğrenme eğrisi modelin hâlâ
veriye aç olduğunu göstermektedir (n=64'te F1 %81,1 → n=256'da %91,4), yani
daha büyük ve gerçek bir külliyat sonucu değiştirebilir. Bu, İP-14'ün
gerekçesidir.
