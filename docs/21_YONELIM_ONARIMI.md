# Yönelim Onarımı — Somut Adlar ve İkinci Şahıs

**Tarih:** 13 Eylül 2026 · **Durum:** ÖLÇÜMDEN ÖNCE YAZILDI (bölüm 1–3) · sonuçlar bölüm 4'e eklenecek
**Önceki tur:** docs/20 (kısa kök, kinaye, kendine zarar)

## 1. Bulgu (küme dışı tarama)

Sözlükte ~100 girdi `requiresDirection` taşır: yalnızca muhataba
yöneltildiğinde saldırı sayılır ("köpeğim hasta" temiz, "köpeksin"
hakaret). Yönelim `ContextAnalyzer` içinde **yakınlıkla** belirlenir:
dört kelimelik pencerede herhangi bir ikinci şahıs zamiri ("sana",
"senin", "sen"…) ya da ikinci şahıs ekli bir kelime ("gördün") yeterlidir.

Depodaki ~12 bin kelime "sana …" bağlamında tarandığında fare, hıyar,
köpeğim, hayvanları, domuz, maymun gibi somut adlar işaretlendi. Bunun
üzerine yazılan 13 gündelik cümlenin **12'si** işaretlendi:

| Cümle | Sonuç |
|---|---|
| Sana köpeğimin fotoğrafını atayım | **Yüksek risk** |
| Senin için domuz eti yok, merak etme | **Yüksek risk** |
| Sen hiç maymun gördün mü hayvanat bahçesinde? | **Yüksek risk** |
| Senin köpek havlıyor, sesini duyuyor musun? | **Yüksek risk** |
| Sana yeni bir fare aldım, eskisi bozulmuştu | Riskli |
| Sana hıyar turşusu getirdim | Riskli |
| Sana inek sütü mü keçi sütü mü alayım? | Riskli |

Aynı taramada gerçek hakaretler (eşeksin, seni gidi maymun, köpek herif
sen, hıyarın tekisin, domuzsun) doğru yakalandı.

## 2. Önceden kayıtlı değişiklik

**D7 · Somut anlamı yaygın adlarda yönelim yapıyla belirlenir.**

Kapsam (sözlük girdisinde ayrı bir işaretle):
eşek, öküz, domuz, maymun, köpek, hayvan, it, kaz, ayı, keçi, katır,
manda, fare, sıçan, solucan, böcek, hamamböceği, kurbağa, karga, akbaba,
çakal, yılan, sırtlan, kene, sülük, hıyar, parazit, asalak, mal, kof,
komedi, trajikomik, saçmalık, palavra, zırva, gevezelik.

Bu girdiler için yönelim, aşağıdakilerden BİRİ varsa kabul edilir:

1. Terimin kendi kelimesi ikinci şahıs bildirme ekiyle biter
   (-sın/-sin/-sun/-sün, -sınız…): *öküzsün*.
2. Hemen önünde "sen" ya da "seni" vardır; araya yalnızca *tam, bir,
   gidi, resmen, koca, ne, biçim* girebilir: *sen tam bir öküz*,
   *seni gidi domuz*.
3. Hemen ardından "sen", "seni" ya da soru eki (*misin, mısın, musun,
   müsün, misiniz…*) gelir: *köpek misin*.
4. İki kelimelik pencerede aşağılayıcı baş kelime vardır (mevcut
   `_pejorativeHeads`: herif, teki, tekisin, önde, gideni, daniskası…).
5. Hemen ardından "gibi"/"gibisin"/"gibisiniz" gelir ve "gibi"den sonraki
   iki kelime içinde ikinci şahıs eki (bildirme ya da görülen geçmiş)
   taşıyan bir kelime vardır: *maymun gibi davranıyorsun*, *kene gibi
   yapıştın*.
6. Metinde @bahsetme vardır (mevcut kural).

Kapsam dışındaki girdiler (sıfatlar, taciz ve tehdit öbekleri) ve
`requiresDirection` dışındaki her şey **değişmez**. Yönelimin şiddet
çarpanı (×1,25) ve öz-yönelim hesabı da değişmez; D7 yalnızca bu
girdilerin elenip elenmeyeceğine karar verir.

## 3. Nasıl raporlanacak

- **İP-31 yönelim kümesi** (`--yonelim`, 30 masum + 20 saldırı)
  değişiklikten ÖNCE commit edilir; önce ve sonra ölçülür. Sınırı:
  hata sınıfı bilindikten sonra yazıldı; taramadaki 18 cümle kümeye alınmadı.
- İP-29, İP-30 ve bütün etiketli kümeler değişiklikten sonra ölçülür;
  değişen her örnek listelenir. İP-29 değişirse ilk geçişin yanında ikinci
  geçiş olarak raporlanır.
- Beklenen bedel: "senin gibi köpekler", "sana köpek gibi davranırım" gibi
  yakınlıkla yakalanan ama D7'nin yapılarından hiçbirine uymayan saldırılar
  kaçabilir.

## 4. Sonuçlar

Kayıt `2ad41d5` ile girdi; D7 ondan sonraki commit'tedir. Kural listesi
değiştirilmedi.

### İP-31 · yönelim kümesi

| | Önce | Sonra |
|---|--:|--:|
| A · masum, somut anlam (30) | **1** temiz (29 yanlış alarm, 7'si Yüksek risk) | **28** temiz |
| B · yüklem/hitap saldırısı (20) | 20 yakalandı | **20** yakalandı |

Kalan iki yanlış alarm, önceden kaydedilen kural 2'den ("sen" + ad)
gelir: "Sen maymunlar hakkında ödev hazırlıyordun…", "Sen sülük
tedavisine inanıyor musun?". Ad burada yüklem değil, özne ya da tamlayandır;
kural bunu ayırt etmez. Ölçüme bakılarak kural değiştirilmedi.

### İP-29 · ikinci geçiş

| Metrik | İlk geçiş | D7 sonrası |
|---|--:|--:|
| Kesinlik | %96,4 | %96,2 |
| Duyarlılık | %45,0 | **%41,7** |
| F0.5 | %78,5 | %76,2 |

Değişen üç örnek (başka hiçbir etiketli kümede değişiklik yok):

| Örnek | Önce → sonra | Neden |
|---|---|---|
| "tam bir kaz kafalısın" | Riskli → **Temiz** (kaçtı) | Ek bileşik yükleme ("kafalı-sın") gelir; D7 yapılarında yok |
| "dilini eşek arısı soksun" | Riskli → **Temiz** (kaçtı) | "soksun" 3. şahıs isteği; eski yakınlık kuralı 2. şahıs sanıyordu |
| "eşek hoşaftan ne anlar, sen de bundan anlamazsın" | Yüksek risk → Riskli | Bayrak aynı; "eşek" bulgusu düştü, örüntü bulgusu kaldı |

Bu örneklere bakılarak kural eklenmeyecek (docs/18 §7).

### Diğer ölçümler

- İP-30 gündelik: 120/120 temiz (değişmedi).
- Geliştirme kümesi: kesinlik %100 · duyarlılık %97,0 (değişmedi).
- Birim testi bedeli: "senin gibi bir köpeği kimse istemez" artık
  yakalanmıyor (kayıtta öngörülen "senin gibi X" kaybı). Testin amacı k→ğ
  yumuşamasıydı; aynı biçimbilim "köpeğin tekisin sen" ile sınanıyor.

### Değerlendirme

D7, bir geçerli ölçümde 2 saldırı örneği (duyarlılık −3,3 puan) karşılığında
ikinci şahıs geçen gündelik cümlelerde yanlış alarmı 29/30'dan 2/30'a indirdi.
Ürünün hedef fonksiyonu F0.5'tir ve yanlış alarmın bedeli kullanıcının
katmanı kapatmasıdır; takas bu yüzden kabul edildi. Kaçan kuruluşlar
("X kafalısın", "senin gibi X") ancak yeni bir ayrık kümeyle ölçülerek
eklenebilir.
