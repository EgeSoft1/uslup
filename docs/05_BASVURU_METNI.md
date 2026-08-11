# Başvuru Metni — KYS'ye kopyalanacak bloklar

**Hazırlanma tarihi:** 12 Ağustos 2026 · **Son başvuru:** 20 Ağustos 2026 (8 gün)
**Tema:** Sosyal Yapay Zekâ · **Kaynak:** `00_URUN_TANIMI.md` §1–3, `04_MODEL_DEGERLENDIRME.md`

> 🟢 **Takım şartı karşılandı (12 Ağustos):** 1 takım arkadaşı hazır → 2 kişi.
> Şartname V2 §3'ün alt sınırı sağlandı. ⬜ **Kalan:** üyenin KYS'de takıma
> eklenmesi ve en az bir üyenin Google Groups'a katılması (zorunlu).

> ✅ **Sayılar 12 Ağustos 2026'da tazelendi** (Flutter 3.44.9 / Dart 3.12.2
> kuruldu, `dart run bin/evaluate.dart --hepsi` çalıştırıldı). Motorda
> değişiklik yapılırsa yeniden çalıştır; sayı değişirse önce
> `04_MODEL_DEGERLENDIRME.md`, sonra bu belge, sonra başvuru güncellenir.

---

## 0. Karara bağlanacak alanlar

| Alan | Durum |
|---|---|
| **Proje adı** | Çalışma adı **"Nezaket Koçu"**. Başvuruda kesinleşmeli — KYS'ye girilen ad rapor ve sunumda da kullanılır. |
| **Takım adı** | ⬜ Belirlenmedi |
| **Takım kaptanı** | Tüm resmî bildirimler kaptana gider (şartname §3). |
| **Danışman** | Zorunlu değil, tavsiye ediliyor. NLP/dilbilim akademisyeni. |
| **Google Groups** | Her takımdan en az 1 kişinin katılması **zorunlu** (şartname §9). |

---

## 1. Tek cümlelik tanım (form: "Proje Adı / Sloganı")

> NSosyal kullanıcısı saldırgan bir gönderi yazarken, gönderi gönderilmeden
> önce, cihazın kendi içinde tespit edip daha yapıcı bir alternatif öneren
> Türkçe'ye özel yapay zekâ katmanı.

**Kısa slogan seçenekleri:**
- Zararı silmeden önce engelle.
- Ekran arkasında kaybolan duraksamayı geri koyar.
- Sansür değil, ayna.

---

## 2. Proje özeti — kısa sürüm (**619 karakter**)

Formda dar bir karakter sınırı varsa bunu kullan.

```
Sosyal medyada nefret ve hakaret bugün oluştuktan sonra yönetiliyor: içerik
yayınlanır, şikâyet edilir, silinir. Ama silmek, hedef kişinin onu görmüş
olmasını geri almaz. Nezaket Koçu zararı oluşmadan engeller: kullanıcı
cümleyi yazarken, tamamen cihaz üzerinde çalışan Türkçe'ye özel bir yapay
zekâ katmanı metni çözümler, saldırganlığı yalnızca yasaklı kelimelerde
değil kelimelerin dizilişinde de tespit eder ve daha yapıcı bir alternatif
önerir. Metin cihazdan hiç çıkmaz. Sistem engellemez, önerir; kararı
kullanıcı verir. Ölçülen doğruluk: ayrık kümede F1 %84,2; ölçülen gecikme:
çözümleme başına 323 mikrosaniye.
```

## 3. Proje özeti — uzun sürüm (**2.148 karakter**)

> KYS'nin özet alanı çoğu yarışmada 2.000 karakterle sınırlıdır. Sınır 2.000
> ise **son paragrafı (ölçüm sonuçları) çıkar → 1.795 karakter**; o sayılar
> zaten §8 "Mevcut Durum" alanında tekrar veriliyor.
> Paragraf uzunlukları: 729 / 613 / 449 / 351 karakter.

```
Sosyal medya platformlarında nefret söylemi ve hakaret, bugün ağırlıklı
olarak yayın sonrası yönetiliyor: içerik yayınlanır, bir kullanıcı şikâyet
eder, moderatör inceler, içerik silinir. Bu döngünün üç kırılgan noktası
vardır. Birincisi, zarar zaten oluşmuştur; içerik silinene kadar hedef kişi
onu görmüştür ve silmek görmüş olmayı geri almaz. İkincisi, yaptırım geri
teper; cezalandırıldığını hisseden kullanıcı öfkelenir, davranışını
değiştirmez. Üçüncüsü, küresel modellerin Türkçe'deki doğruluğu düşüktür;
eklemeli yapı, argo ve bağlam yeterince modellenmemiştir. Dahası mevcut
filtreler sıklıkla mağduru cezalandırır: tacize uğradığını anlatan kullanıcı
("bana 'şerefsiz' dedi") kendi mesajı işaretlendiği için susturulur.

Nezaket Koçu, müdahaleyi yayın sonrasından yayın öncesine taşır. Kullanıcı
cümleyi yazarken, tamamen cihaz üzerinde çalışan Türkçe'ye özel bir katman
metni çözümler ve daha yapıcı bir alternatif önerir. Hat beş adımdan oluşur:
gizleme hilelerini geri çeviren normalizasyon ("$3r3fsiz" → "serefsiz"),
Türkçe eklemeli yapıya duyarlı kök eşleştirme, saldırganlığı kelimelerde
değil kelimelerin dizilişinde arayan edimbilimsel örüntü katmanı, kimlik
hedefli düşmanlığı yakalayan nefret söylemi katmanı ve tüm bulguları
saldırı / iltifat / şikâyet / öz-ifade ekseninde yeniden ağırlıklandıran
bağlam çözümleme katmanı.

Projenin üç özgün yönü vardır. Metin cihazdan hiç çıkmaz; bu bir gizlilik
politikası maddesi değil, mimarinin kendisidir. Kimlik adları hiçbir zaman
yasaklı kelime değildir; yalnızca düşmanca bir kuruluşun içindeki yuvayı
doldururlar, böylece "Ben Kürtüm" gibi cümleler işaretlenmez. Ve sistem
hiçbir metni kendiliğinden engellemez veya değiştirmez; öneri sunar, kararı
kullanıcıya bırakır, her uyarıda hangi kelimenin neden işaretlendiğini
açıklar.

Doğrulama, 330 etiketli örnekten oluşan beş dilimli bir küme ve
kesinlik/duyarlılık/F1/F0.5 ölçen bir değerlendirme altyapısıyla
yapılmıştır. Ayrık küme üzerinde ölçülen genelleme başarımı F1 %84,2
(kesinlik %88,9, duyarlılık %80,0). Ortalama çözümleme süresi 323
mikrosaniyedir — 60 FPS kare bütçesinin %2'si — bu nedenle geri bildirim
gecikmesizdir.
```

---

## 4. Çözülen problem (form: "Problem / Sorun")

```
Sosyal medyada saldırgan içerik, oluştuktan sonra yönetiliyor. Bu yaklaşımın
üç yapısal kusuru var:

1. Zarar geri alınamaz. İçerik silinene kadar hedef kişi onu görmüştür.
2. Yaptırım davranışı değiştirmez. Ceza, öfkeyi artırır; alışkanlığı değil.
3. Türkçe'de doğruluk düşük. İngilizce merkezli modeller Türkçe'nin eklemeli
   morfolojisinde, argosunda ve bağlamında zayıf kalıyor.

Ve en can yakıcı kırılma: mağdur cezalandırılıyor. Tacize uğradığını
anlatan kullanıcının mesajı, içinde geçen hakaret sözcüğü nedeniyle mevcut
filtreler tarafından işaretleniyor. Şikâyet eden susturuluyor.

Bunun altında yatan davranışsal gerçek şudur: insanlar bu cümleleri yüz
yüzeyken kurmuyor, ekran arkasında kuruyor. Aradaki fark bir yasak değil,
bir duraksamadır — ve dijital ortamda o duraksama kaybolmuştur.
```

## 5. Çözüm (form: "Çözüm / Yöntem")

```
Nezaket Koçu, kaybolan o duraksamayı geri koyar. Kullanıcı yazarken, her tuş
vuruşunda, cihaz üzerinde çalışan bir katman metni çözümler:

1. NORMALİZASYON — gizleme hilelerini geri çevirir:
   "$3r3fsiz" → "serefsiz", "a.p.t.a.l" → "aptal", "aptaaaal" → "aptal"
2. SÖZLÜK EŞLEŞTİRME — Türkçe eklemeli yapıya duyarlı kök eşleşmesi:
   "aptal" kökü → aptalsın / aptallar / aptallığın
3. EDİMBİLİMSEL ÖRÜNTÜ KATMANI — küfürsüz düşmanlık; saldırganlığı
   kelimelerde değil kelimelerin DİZİLİŞİNDE arar. 8 aile, 50 örüntü:
   "senin gibilerden zaten bu beklenirdi" → ötekileştirme
   "sen ne anlarsın bu işlerden"          → yetkinlik reddi
   "gününü göreceksin"                    → örtük tehdit
4. NEFRET SÖYLEMİ KATMANI — kimlik hedefli düşmanlık. 5 kuruluş ailesi,
   40 kimlik terimi. Kimlik adı yasaklı kelime DEĞİLDİR; yalnızca düşmanca
   bir kuruluşun içindeki yuvayı doldurur.
5. BAĞLAM ÇÖZÜMLEME — projenin teknik kalbi. Aynı kelime, farklı niyet:
   "aptalsın"          → saldırı   ×1,25
   "aptal değilsin"    → iltifat   ×0,15
   "bana aptal dedi"   → şikâyet   ×0,20
   "kendimi aptal ..." → öz-ifade  ×0,20
   "aptal değil misin" → retorik olumsuzlama, saldırı sayılır
6. SKOR BİRLEŞTİRME — Noisy-OR (1 − Π(1 − sᵢ)) ile 0-100 nezaket puanı
7. ÖNERİ ÜRETİMİ — yerel, deterministik yeniden yazım

Hattın tamamı cihazda biter. Sunucu adımı yoktur.
```

---

## 6. Yenilikçi yön (form: "Özgün Değer / İnovatif Yönü")

```
| Mevcut çözümler                     | Nezaket Koçu                        |
|-------------------------------------|-------------------------------------|
| Yayın SONRASI moderasyon            | Yayın ÖNCESİ önleme                 |
| Metin sunucuya gider, orada taranır | Metin cihazdan hiç çıkmaz           |
| Kara kutu: "gönderin kaldırıldı"    | Her karar açıklanır: hangi kelime,  |
|                                     | neden                               |
| Sadece engeller                     | Alternatif önerir, kararı kullanıcı |
|                                     | verir                               |
| İngilizce merkezli modeller         | Türkçe morfolojisi + argosu +       |
|                                     | gizleme hileleri                    |
| Mağduru da işaretler                | Alıntı / şikâyet / öz-ifade ayırt   |
|                                     | edilir                              |
| Yalnızca yasaklı KELİME arar        | Küfürsüz DÜŞMANLIĞI da görür        |
| Kimlik adını yasaklı kelime sayar   | Kimlik adı hiçbir zaman tetikleyici |
|                                     | değildir                            |

Son üç satır teknik olarak en özgün kısımdır.

KÜFÜRSÜZ DÜŞMANLIK. Sosyal medyadaki saldırganlığın büyük kısmı tek bir
yasaklı kelime içermez. Ölçüm bunu sayısallaştırdı: yalnız sözlük katmanı bu
dilimde %1,8 duyarlılık gösteriyordu; edimbilimsel örüntü katmanı eklendikten
sonra %100. Kritik olan, bu kazancın KESİNLİKTEN HİÇBİR ŞEY GÖTÜRMEDEN
sağlanmasıdır (her iki ölçümde de kesinlik %100).

KİMLİK ADI TETİKLEYİCİ DEĞİLDİR. Nefret söylemi filtrelerinin yaygın kusuru,
korunan grubun adını yasaklı kelime listesine koymaktır. Sonuç ters teper:
kendi kimliğinden söz eden insan susturulur.
    "Ben Kürtüm"                   → filtrelenmemeli, ama filtrelenir
    "Eşcinsel hakları konferansı"  → filtrelenmemeli, ama filtrelenir
    "Bütün Kürtler hırsızdır"      → filtrelenmeli
Bizim katmanımızda kimlik adı yalnızca düşmanca bir kuruluşun içindeki yuvayı
doldurur. Sözlükte tek bir kimlik adı yoktur ve bu, yapısal bir testle
korunmaktadır: sözlüğe kimlik adı sızarsa test kırılır. Ölçüm doğruluyor —
20 masum kimlik cümlesinin hiçbiri işaretlenmiyor.
```

---

## 7. Kullanılan teknolojiler (form: "Kullanılacak Yöntem ve Teknolojiler")

```
- Dart / Flutter — çapraz platform mobil istemci ve çekirdek motor
- civility_core — projeye özel, bağımlılıksız Türkçe nezaket motoru:
  normalizasyon, morfoloji, sözlük, edimbilimsel örüntüler, nefret söylemi
  örüntüleri, bağlam çözümleyici, yeniden yazma önerici
- Değerlendirme altyapısı — 330 etiketli örnek, beş dilim,
  kesinlik/duyarlılık/F1/F0.5, katman izolasyonu için A/B karşılaştırma
- Cihaz üstü çalışma — ağ bağımlılığı, API anahtarı veya bulut kotası yok

BÜYÜK DİL MODELİ KULLANILMAMAKTADIR — ve bu bir eksiklik değil, kayıtlı bir
tasarım kararıdır. Sunucu tarafı bir LLM yeniden yazma servisi yazıldı,
50 testle doğrulandı, kullanıcı onay kapısı uçtan uca sınandı; sonra kasıtlı
olarak kaldırıldı. Üç gerekçe: (a) "metin cihazdan çıkmaz" iddiasına
açıklanması gereken bir istisna ekliyordu, (b) jürinin çalıştıramayacağı bir
üçüncü taraf API bağımlılığı getiriyordu, (c) katkısı yalnızca öneri
akıcılığıydı; tespit, bağlam çözümleme ve müdahale zaten onsuz çalışıyordu.
Karar kaydı: docs/03_LLM_SERVISI.md

Karardan korunan fikir raporda ayrıca anlatılmaktadır: bir dil modeli akıcı
ama işe yaramaz bir öneri üretebilir — eleştiriyi buharlaştırabilir, hakareti
başka bir hakaretle değiştirebilir. Bunu istemden rica ederek garanti
edemezsiniz; deterministik bir motorla ölçüp geçemeyeni atarak garanti
edersiniz. Model bir öneri kaynağıdır, bir otorite değildir.
```

---

## 8. Mevcut durum ve ölçülen sonuçlar (form: "Projenin Mevcut Durumu")

```
Çekirdek motor çalışıyor, testli ve ölçülmüş durumdadır.

ÇALIŞAN:
- Türkçe normalizasyon (çift varyantlı, gizleme direnci)
- Bağlam duyarlı toksisite motoru: sözlük + edimbilimsel örüntü katmanı
- Nefret söylemi katmanı: 5 kuruluş ailesi, 40 kimlik terimi
- Gönderge (anafora) katmanı: kimlik önceki cümledeyse zamir ona bağlanır
- İki modlu yerel yeniden yazıcı (öbek modu / yerinde mod), Türkçe
  morfoloji farkındalığıyla
- Değerlendirme altyapısı: 336 etiketli örnek, beş dilim
- Topluluk sağlığı paneli: anonim sinyallerden üretilir, k-anonimlik uygular
- 153 test geçiyor (136 çekirdek + 17 mobil), 0 analiz uyarısı
- Canlı yazım arayüzü (Nezaket Koçu ekranı) + sohbet mesaj kutusu
- Devralınan 30 ekranlık Flutter arayüz kütüphanesi ve tasarım sistemi

ÖLÇÜLEN BAŞARIM:
| Ölçüm                                  | Değer                        |
|----------------------------------------|------------------------------|
| Genelleme (ayrık küme) F1              | %84,2                        |
|   kesinlik / duyarlılık                | %88,9 / %80,0                |
| Nefret söylemi dilimi F1               | %97,3 (kesinlik %100)        |
| Örüntü katmanının duyarlılık katkısı   | +55,2 puan, kesinlik kaybı 0 |
| Ortalama çözümleme süresi              | 268 µs (16 ms bütçenin %2'si)|

ÖLÇÜMÜN KOŞULLARI (raporda birlikte verilecektir): geliştirme kümesinde
ölçülen F1 %99,6'dır, ancak bu bir genelleme kanıtı DEĞİLDİR — kümeyi de
örüntüleri de aynı kişi yazmıştır. Raporlanan sayı, tek geçerli genelleme
ölçümü olan ayrık kümedeki %84,2'dir.
```

---

## 9. Hedef kitle ve yaygın etki

```
BİRİNCİL: NSosyal platformunun tüm yazan kullanıcıları — özellikle
tartışmalı konularda ilk tepkiyle yazan, sonra pişman olan kullanıcı.

İKİNCİL:
- Taciz hedefi olan kullanıcılar — mevcut filtrelerin yanlışlıkla
  susturduğu grup. Bu üründe alıntı ve şikâyet ayırt edilir.
- Platform moderasyon ekibi — kaynağında azalan ihlal, azalan kuyruk.
- İçerik üreticileri — yorum alanının yaşanabilir kalması.

YAYGIN ETKİ: Çözüm platforma özel değildir; cihaz üstü bir Türkçe katman
olarak herhangi bir Türkçe metin giriş yüzeyine (mesajlaşma, forum, yorum
alanı, e-posta) taşınabilir. Türkçe için cihaz üstü, açıklanabilir ve
mağduru cezalandırmayan bir nezaket katmanı bugün mevcut değildir.
```

---

## 10. Riskler ve sınırlar — başvuruda kısaca, raporda ayrıntılı

Jüri karşısında zayıflık değil güç sayılan kısım; **gizleme.**

```
- Metrikler henüz bağımsız değildir. Kümeleri ve örüntüleri aynı kişi
  yazmıştır; hakemler arası uyum (Cohen's kappa) ölçülmemiştir. İkinci
  etiketleyiciyle bağımsız küme üretimi planlanmıştır.
- Cümleler arası gönderge çözümlemesi yoktur: "bunların soyunu kurutmak
  lazım" gibi kimliğin önceki cümlede geçtiği durumlar kaçmaktadır.
- Kimlik söz varlığı 40 terimle sınırlıdır; kapsanmayan bir grup hedef
  alındığında sistem sessiz kalır.
- Tüm veri sentetiktir; hiçbir örnek gerçek kullanıcıdan gelmemiştir.
- Yalnızca Türkçe desteklenmektedir.
```

---

## 11. Başvuru öncesi kontrol listesi

| # | İş | Durum |
|---|---|---|
| 1 | ~~En az 1 takım arkadaşı~~ | 🟢 12 Ağustos — KYS'ye eklenmesi kaldı |
| 2 | Proje adı ve takım adı kesinleştir | ⬜ |
| 3 | KYS'de takım oluştur, üyeleri ekle | ⬜ |
| 4 | Google Groups'a en az 1 üye katılsın (zorunlu) | ⬜ |
| 5 | ~~Sayıları tazele~~ | 🟢 12 Ağustos |
| 6 | Uzak git deposu + push (kaynak kod teslimatı) | 🔴 **Kalan tek teknik engel** |
| 7 | Danışman (tavsiye) | ⬜ |
| 8 | Yukarıdaki blokları KYS form alanlarına yerleştir | ⬜ |
