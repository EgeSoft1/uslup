# Mentörlük Penceresi Sonuçları — İP-15, İP-17, İP-19, İP-20

**Tarih:** 24 Ağustos 2026 (rapor teslimi sonrası)
**Kapsam:** Teknik raporda 2–7 Eylül'e planlanan iş paketlerinin yürütülmesi
**Durum:** İP-15 ve İP-17 tamamlandı · İP-19 (planda yoktu) açıldı ve
tamamlandı · İP-20 tamamlandı · İP-16 ayrı belgede
([`13_ERISILEBILIRLIK_DENETIMI.md`](13_ERISILEBILIRLIK_DENETIMI.md))

> **Bu belge neden var.** Teknik rapor 24 Ağustos 17.00'de teslim edildi ve
> içeriği değiştirilmemiştir. Aşağıdaki ölçümler teslimden **sonra** alınmıştır;
> raporun sayılarını geçersiz kılmaz, üstüne yenilerini koyar. 14 Eylül final
> sunumunun sayısal dayanağı bu belgedir.

---

## 0. Yönetici özeti — üç cümle

1. **Örüntü katmanının ezberleme payı ilk kez ölçüldü.** Taze bir ayrık kümede
   örtük saldırı duyarlılığı %100'den **%12,0**'ye düştü; geliştirme
   kümesindeki başarı büyük ölçüde ezberdi.
2. **Onarıldı ve tekrar ölçüldü.** Kaçakların taksonomisinden 19 yeni
   edimbilimsel örüntü üretildi; onarım sonrası **taze üçüncü** kümede
   duyarlılık %50,0, F1 %66,7.
3. **Yüzey genişletme yetmedi, yapısal aile yetti.** İP-19 yüzey biçimlerini
   genişletti ve taze kümede duyarlılık %50,0'de kaldı. İP-21 bunun yerine
   deyimlerin dayandığı YAPIYI kapalı soyut ad sınıflarıyla modelledi;
   dördüncü kümede aynı yapının **hiç görülmemiş örneklerinin %90'ı**
   yakalandı.
4. **Kesinlik iddiası bir kez kırıldı — ve kırılması iyi oldu.** Dördüncü
   küme, ürünü bozan iki kusur buldu; en ağırı `"bardak dolu"` cümlesini
   **yüksek riskli nefret söylemi** ilan ediyordu. Dört ölçüm kümesinin
   hiçbiri bunu göremezdi, çünkü hiçbirinde "dolu" kelimesi geçmiyordu.

---

## 1. İP-15 · Bağımsız genelleme doğrulaması

### 1.1 Problem

Rapor §3.2, ayrık kümedeki F1 = %84,2'yi tek geçerli genelleme ölçümü olarak
bildiriyordu ve o kümenin sonradan **yandığını** (motor ona bakılarak
düzeltildiği için artık ayrık sayılmadığını) açıkça beyan ediyordu. Yani
teslim anında elde **güncel** bir genelleme sayısı yoktu.

### 1.2 Protokol

`packages/civility_core/lib/src/eval/generalization_dataset.dart` — 100 örnek,
beş dilim, yaklaşık dengeli (52 müdahale / 48 temiz).

| Kural | Uygulama |
|---|---|
| Küme, motor **dondurulduktan sonra** yazıldı | İP-17 söz varlığı genişletmesi tamamlandıktan sonra kuruldu; genişletmenin bu kümeye göre ayarlanmış olması **imkânsız** |
| Ölçüm **bir kez** alındı | Sonuç düzeltme yapılmadan kaydedildi |
| Küme **kör değildir** | Yazarı örüntüleri görmüştür; belge içinde bu açıkça beyan edilmiştir |

### 1.3 İlk ölçüm — 24 Ağustos 2026

```
dart run bin/evaluate.dart --genelleme
```

| Ölçüm | Geliştirme (256) | **İP-15 (100)** |
|---|:--:|:--:|
| Kesinlik | %100,0 | **%100,0** |
| Özgüllük | %100,0 | **%100,0** |
| Duyarlılık | %99,3 | **%38,5** |
| F1 | %99,6 | **%55,6** |
| F0.5 | %99,8 | **%75,8** |

**Dilim bazında duyarlılık:**

| Dilim | Geliştirme | İP-15 |
|---|:--:|:--:|
| Açık saldırı | %100,0 | %66,7 |
| **Örtük saldırı** | **%100,0** | **%12,0** |
| Nefret söylemi (F1) | %97,3 | %73,7 |
| Masum / tuzak (özgüllük) | %100,0 | %100,0 |
| Bağlam (özgüllük) | %100,0 | %100,0 |

### 1.4 Bulgunun anlamı

Tek bir satır, raporun en önemli dürüstlük iddiasını sayıya çevirir:

> Örtük saldırı diliminde duyarlılık %100 → %12,0

Geliştirme kümesindeki 57 örtük saldırı örneğinin tamamı yakalanıyordu. Taze
25 örnekten yalnızca 3'ü yakalandı. Aradaki fark **ezberdir** — örüntüler
kümedeki cümlelerin yüzey biçimine kilitlenmişti:

| Örüntü | Gördüğü tek biçim | Kaçırdığı |
|---|---|---|
| `kucumseme.seviye` | "seviyene in**ip**/in**erek**/in**mek**" | "seviyene in**meyeceğim**" |
| `kucumseme.zaman_kaybi` | "**seninle tartışmak** zaman kaybı" | "**sana anlatmak** zaman kaybı" |
| `otekilestirme.baska_ne_beklenir` | "başka ne beklen**ir**" | "başka ne beklen**irdi** ki" |
| `kucumseme.anlatmak_nafile` | "sana anlatmak nafile" | "sana **bir şey** anlatmak nafile" |

Türkçe eklemeli bir dildir; bir kalıbı tek çekimiyle yazmak, o kalıbın
onlarca biçimini kaçırmak demektir.

### 1.5 İkinci etiketleyici altyapısı

İP-15'in ikinci yarısı — hakemler arası uyum (Cohen's kappa) — **bir insan
gerektirir ve henüz yapılmamıştır.** Yapılabilmesi için gereken altyapı
tamamlandı:

```bash
dart run bin/annotate_export.dart --kume=ip20 > etiketleme.csv
# ikinci etiketleyici yalnızca `etiket` sütununu doldurur
dart run bin/kappa.dart etiketleme.csv
```

**Körlük nasıl korunuyor:** dışa aktarma dosyasına `shouldFlag`, kategori,
dilim adı ve not alanları **yazılmaz** (not alanları çoğu zaman doğru cevabı
söyler: *"BİLİNEN SINIR: örtülü hakaret"*). Sıra sabit tohumla (20260824)
karıştırılır — kaynak dosyalarda örnekler dilim dilim gruplandığı için sıra
korunsaydı etiketleyici blok blok işaretlerdi.

`bin/kappa.dart` gözlenen uyuşmayı (Po), rastlantısal beklentiyi (Pe),
κ'yı ve **uyuşmazlık listesini** basar. Araç boru hattı doğrulandı: rastgele
üretilmiş sentetik etiketlerle κ = −0,230 döndürdü ve bunu "uyuşmazlık"
olarak sınıfladı — beklenen davranış.

> ⚠ **Bu bir kappa ölçümü değildir.** Sentetik dosya yalnızca aracın
> doğruluğunu sınamak için üretildi ve depoya alınmadı. Gerçek κ, ikinci
> etiketleyici çalıştığında ölçülecektir. O ana kadar bütün metrikler
> **tek etiketleyicilidir** ve raporda böyle beyan edilmektedir.

---

## 2. İP-17 · Kimlik söz varlığının genişletilmesi

### 2.1 Kapsam

**35 → 94 terim.** Genişletme iki kuralla yapıldı:

**K1 — Korunan nitelik ekseni.** Etnik/ulusal köken, inanç, cinsel yönelim ve
cinsiyet kimliği, göç durumu, engellilik, yaş, sosyoekonomik durum.
**Siyasi görüş kasıtlı olarak dışarıdadır** — siyasi aidiyet uluslararası
nefret söylemi tanımlarının hiçbirinde korunan nitelik değildir ve listeye
girmesi siyasi eleştiriyi nefret söylemi saymak olurdu.

**K2 — Çakışan kökte tekil biçim kullanılmaz.** Aksan katlaması sonrası meşru
bir kelimeyle çakışan her kökte yalnızca grup göndergesi taşıyan çoğul biçim
alınır.

| Eksen | Önce | Sonra |
|---|:--:|:--:|
| Etnik / ulusal köken | 16 | 40 |
| İnanç / mezhep | 8 | 22 |
| Cinsel yönelim / cinsiyet kimliği | 5 | 14 |
| Göç, engellilik, yaş, sosyoekonomik | 6 | 20 |
| **Toplam** | **35** | **94** |

### 2.2 Denetlenip alınmayanlar

Yedi kök, meşru kullanımda düşmanca yüklem alabildiği için **bilinçli olarak**
dışarıda bırakıldı. Her biri için `test/lexicon_coverage_test.dart` §4'te bir
regresyon testi vardır:

| Alınmayan | Çakıştığı meşru kullanım |
|---|---|
| `kazaklar` | giysi çoğulu — *"kazaklar bozuk"* |
| `siyahlar` | renk çoğulu — *"siyahlar kirli"* |
| `sii` | *şiir* — *"şiirler kirli"* |
| `sih` | *sihir* |
| `kor` | *korku*, *koru*, *korkak* |
| `yasli` | *yaslı* (matem) |
| `rus` | *rustik* |

### 2.3 Beklenmeyen bulgu — sözlükte 35 hakaret kaçıyordu

Genişletme sırasında yapılan çekişmeli taramada, geliştirme kümesinde **hiç
geçmeyen** 35 yaygın Türkçe hakaretin tamamının motordan kaçtığı ölçüldü.
En çarpıcısı:

```
"sen geri zekalısın"  →  temiz (0.00)
```

Sözlükte yalnızca **bitişik** yazım (`gerizekalı`) vardı; Türkçe'de standart
olan **boşluklu** yazım hiçbir katmana takılmıyordu. Aynı taramada `kaltak`,
`puşt`, `şıllık`, `ipne`, `yobaz`, `soysuz`, `karaktersiz`, `terbiyesiz`,
`ahlaksız`, `nankör`, `ruh hastası` gibi terimlerin de hiç bulunmadığı görüldü.

**Sonuç:** 35/35 yakalanır hâle geldi, iki etiketli kümede **kesinlik kaybı
sıfır**, 35 çekişmeli masum cümlenin 34'ü temiz kaldı (kalan 1, önceden
belgelenmiş `inkar.demiyorum_ama` sınırı).

Bu bulgu, geliştirme kümesindeki %99,6'nın neden bir genelleme kanıtı
olmadığının **doğrudan kanıtıdır**: küme sözlüğe bakılarak yazıldığı için
sözlüğün kör noktasını göremiyordu.

### 2.4 Çokanlamlılık disiplini

Yeni sözlük girdilerinin 15'i `requiresDirection: true` ile eklendi — yalnızca
ikinci şahsa yöneltildiğinde hakaret sayılırlar:

```
"asalak canlılar üzerine ders çalıştım"  → temiz
"asalak herif"                            → işaretlenir
```

İki sıfat — **"çirkin"** ve **"iğrenç"** — bilerek alınMADI. *"Çirkin bir
davranış sergiledin"* meşru bir eleştiridir; ikinci şahıs yönelimi bu ikisini
kurtarmaya yetmiyor. Eleştiriyi hakaret sayan bir katman, ürünün "sansür
değil" iddiasını çürütür. Bedeli İP-20 ölçümünde görünür durumda
(*"iğrenç bir insansın gerçekten"* kaçıyor) ve gizlenmiyor.

---

## 3. İP-19 · Genelleme onarımı (planda yoktu)

İP-15 kaçaklarının taksonomisinden üretilen üç ayrı onarım.

### 3.1 Bağlam katmanı — varlık olumsuzlaması hatası

Ölçüm, bir **kaçış yolu** ortaya çıkardı:

```
"burada senin gibilere yer yok"      →  temiz (0.00)   ✗
"senin gibilere tahammülüm yok"      →  temiz (0.00)   ✗
```

`yok` olumsuzlayıcı listesindeydi ve iki token ileriye kadar taranıyordu.
Ama bu cümlelerde "yok" saldırıyı değil, **aradaki başka bir adı** olumsuzluyor
("yer", "tahammülüm").

**Onarım:** `değil` ve `yok` ayrıldı. "Değil" yüklem olumsuzlayıcısıdır ve
araya kelime alabilir (*"aptal da değilsin"*); "yok" varlık olumsuzlayıcısıdır
ve kendi adına bitişir. Penceresi tek token'a indirildi:

```
"burada aptal yok"      → olumsuzlama geçerli   (bitişik)
"aptalsın, param yok"   → olumsuzlama geçersiz  (araya ad girmiş)
```

### 3.2 Nefret katmanı — ünlü uyumu eksiği

Bildirme eki listesi **yuvarlak ünlülü** çekimleri içermiyordu:

```
"Katolikler bozuk"     → yakalanıyordu
"Katolikler bozuktur"  → temiz (0.00)      ✗
```

Yani **ek eklendiğinde saldırı görünmez oluyordu** — ekin varlığı bir kaçış
yoluna dönüşmüştü. `tur`, `turlar`, `sun`, `sunuz` eklendi.

Ayrıca:
- **Gereklilik kipi** eklendi (*"Kürtler bu ülkeden gitmeli"*) — gereklilik
  kipi bir çağrıdır, bildirme kipinden ayrıdır.
- **Patolojileştirme** kuruluşu eklendi (*"translar hasta insanlar"*). Tek
  başına "hasta" alınMADI: *"Suriyeli komşum hasta"* masum bir cümledir.
- **İki cümlecikli toplu suçlama** için niceleyici çapası eklendi. *"Bu
  Suriyeliler yüzünden mahalle battı, hepsi hırsız"* cümlesinde kimlik ile
  yüklem arası dört kelimeydi; boşluğu büyütmek kesinliği düşürürdü. Bunun
  yerine "hepsi/tümü" bir çapa olarak kullanıldı ve kimlik önceli **gönderge
  kapısıyla** arandı — böylece "hepsi hırsız" tek başına hiçbir şey üretmez.

### 3.3 Örüntü katmanı — çekim toleransı + 19 yeni kuruluş

Dört ezberlenmiş örüntü genelleştirildi, 19 yeni edimbilimsel kuruluş eklendi
(`kucumseme.kafan_basmaz`, `yoksayma.kim_sordu`, `susturma.sus_da`,
`karakter.adam_gibi`, `tehdit.kafani_kirarim` …).

**Tasarım kuralı:** her örüntü tek bir cümleyi değil, o cümlenin temsil ettiği
**edimbilimsel kuruluşu** hedefler. Aksi hâlde katman yeniden ezberlemeye
döner ve bir sonraki ayrık kümede yine kaçırır.

### 3.4 Onarım sonrası — ve maliyet beyanı

| Ölçüm | İP-15 önce | İP-15 sonra |
|---|:--:|:--:|
| Kesinlik | %100,0 | %100,0 |
| Özgüllük | %100,0 | %100,0 |
| Duyarlılık | %38,5 | %96,2 |
| F1 | %55,6 | %98,0 |

> ⚠ **Bu %98,0 bir genelleme kanıtı DEĞİLDİR.** Onarım bu kümeye bakılarak
> yapıldığı için küme **yanmıştır** — birinci ayrık kümenin başına gelenin
> birebir aynısı. Kayıt altına alınmıştır ve bir daha "ayrık" olarak
> raporlanmayacaktır.

Geliştirme kümesinde ve birinci ayrık kümede **hiçbir gerileme yok**:
sırasıyla F1 %99,6 ve %99,0, kesinlik %100,0 ve %98,0 — onarım öncesiyle
birebir aynı.

---

## 4. İP-20 · Onarım sonrası dürüst ölçüm

### 4.1 Protokol farkı

`generalization2_dataset.dart` — 80 örnek. İP-15'ten üç farkı var:

1. **İP-19 onarımı bittikten sonra** yazıldı.
2. Cümleler İP-15'tekilerin başka çekimi değil, **başka kuruluşlar**.
3. Kümenin **üçte biri, İP-19'da eklenen örüntülerin yakın-kaçışıdır** —
   onarımın kesinliği bozup bozmadığını doğrudan ölçmek için:

| Saldırı | Yakın-kaçış (aynı harf dizisi, masum) |
|---|---|
| "sus da adam konuşsun" | "sustu da öyle başladı anlatmaya" |
| "acıdım sana gerçekten" | "acıdım ona, çok zor durumda" |
| "kim sordu ki senin fikrini" | "kim sordu bunu acaba, ben de merak ettim" |
| "sen önce kendine bak" | "önce kendine iyi bak, sağlığın önemli" |
| "adam gibi konuşmayı öğren" | "adam gibi bir iş buldu sonunda" |
| "Suriyeliler hasta insanlar" | "Suriyeli doktorlar hasta insanlar için gönüllü çalışıyor" |
| "hepsi hırsız" (kimlik önceli var) | "market soyulmuş, hepsi hırsız çıkmış" (öncül yok) |

### 4.2 Ölçümden ÖNCE yazılan beklenti

Küme dosyasının başlığında, ölçüm alınmadan önce şu kayıt düşüldü:

> *"Bu kümede F1'in %98'e yakın çıkması BEKLENMİYOR. Küme kasıtlı olarak,
> hiçbir örüntü ailesinde karşılığı olmayan deyimsel saldırılar içeriyor.
> Beklenen: kesinlik yüksek kalır, duyarlılık İP-15'in onarım sonrası
> değerinin altında çıkar."*

### 4.3 Sonuç

```
dart run bin/evaluate.dart --genelleme2
```

| Ölçüm | Değer |
|---|:--:|
| **Kesinlik** | **%100,0** |
| **Özgüllük** | **%100,0** |
| Duyarlılık | %50,0 |
| F1 | %66,7 |
| F0.5 (hedef fonksiyon) | **%83,3** |
| Kategori doğruluğu | %100,0 (19/19) |

| Dilim | Değer |
|---|:--:|
| Açık saldırı · duyarlılık | %70,0 |
| Örtük saldırı · duyarlılık | %40,0 |
| Nefret söylemi · F1 | %66,7 |
| Masum / tuzak · **özgüllük** | **%100,0** |
| Bağlam · **özgüllük** | **%100,0** |

Beklenti tuttu.

### 4.4 Yorum — iki ayrı sonuç

**Kesinlik genelleşiyor.** Üç bağımsız kümede de %100. Daha önemlisi: İP-19'da
eklenen 19 yeni örüntünün **kendi yakın-kaçışlarında** bile tek bir yanlış
pozitif yok. Yeni örüntüler duyarlılığı kesinlikten satın almadı.

**Duyarlılık genelleşmiyor.** 19 kaçağın 12'si, hiçbir örüntü ailesinde
karşılığı olmayan **deyimlerdir**:

> "iki çift laf edemiyorsun" · "senin çapın bu kadar" · "boyunu aşan işlere
> karışma" · "sende akıl mı var" · "sen ne ayaksın" · "gözüm görmesin seni" ·
> "hava atma bize" · "engelliler topluma yük"

Bu, kural tabanlı katmanın **tavanıdır** ve gizlenmemelidir. Türkçe deyim
uzayı sonlu bir örüntü kataloğuyla kapatılamaz. Buradan sonra örüntü eklemek
İP-20'yi de yakardı; ölçüm bilinçli olarak durduruldu.

### 4.5 Bu, raporun mimari kararını doğruluyor

Rapor §3.2, denetimli bir taban çizgisinin (`ml/`) kural motorunun kaçırdığı
hiçbir örneği yakalayamadığını, buna karşılık altı yanlış pozitif ürettiğini
bildiriyordu. İP-20 aynı tabloyu tamamlıyor:

| Yaklaşım | Kesinlik | Duyarlılık | Kaynak |
|---|:--:|:--:|---|
| Kural motoru (bu ürün) | **%100** | %50 | İP-20 |
| Doğrusal denetimli taban çizgisi | düşük | düşük | `ml/`, rapor §3.2 |

Deyim kapsamı bir **veri** problemidir, bir kural problemi değil — ve bu
ürünün sunucusuz, LLM'siz mimarisinde çözümü ölçekli etiketli Türkçe veridir.
Rapor §7.1'deki "sinir ağı katmanı" adımının gerekçesi artık bir öngörü değil,
bir ölçümdür.

---

## 5. Ölçüm geçmişi — tek tablo

| # | Küme | Boyut | Kesinlik | Duyarlılık | F1 | Durum |
|:--:|---|:--:|:--:|:--:|:--:|---|
| 1 | Geliştirme | 256 | %100,0 | %99,3 | %99,6 | Ezberleme payı içerir — genelleme kanıtı **değildir** |
| 2 | 1. ayrık | 80 | %98,0 | %100,0 | %99,0 | **Yanmış.** İlk ölçüm: F1 %84,2 |
| 3 | 2. ayrık (İP-15) | 100 | %100,0 | %38,5 | %55,6 | İlk ölçüm |
| 3b | 2. ayrık, İP-19 sonrası | 100 | %100,0 | %96,2 | %98,0 | **Yanmış.** Onarımda kullanıldı |
| 4 | 3. ayrık (İP-20) | 80 | %100,0 | %50,0 | %66,7 | İlk ölçüm |
| 4b | 3. ayrık, İP-21 sonrası | 80 | %100,0 | %94,7 | %97,3 | **Yanmış.** Onarımda kullanıldı |
| **5** | **4. ayrık (İP-22)** | **65** | **%90,5** | **%54,3** | **%67,9** | **Geçerli — ilk geçiş** |
| 5b | 4. ayrık, kusur düzeltmesi sonrası | 65 | %100,0 | %54,3 | %70,4 | Duyarlılık geçerli, kesinlik yanmış |

**Raporlanacak sayı: F1 = %67,9 · kesinlik %90,5 · duyarlılık %54,3 · F0.5 %79,8 (İP-22, ilk geçiş).**

> **5 ve 5b neden ayrı satır.** İP-22 ölçümü iki *yanlış pozitif* buldu ve
> ikisi de **ürünü bozan gerçek kusurlardı** (aşağıda §9.3). Düzeltildiler.
> Düzeltme yalnızca kesinliği etkiler; **hiçbir yanlış negatife dokunulmadı**,
> bu yüzden duyarlılık sayısı (%54,3) her iki satırda da geçerlidir. Kesinlik
> için taze bir sayı beşinci küme ister.

Ürünün hedef fonksiyonu F0.5'tir (kesinlik ağırlıklı), çünkü yanlış pozitif
yanlış negatiften pahalıdır: kaçan bir hakaret bugünkü durumdur, yanlış
işaretlenen masum bir cümle ise ürünün etik iddiasını çürütür.

---

## 6. Yeniden üretme

```bash
cd packages/civility_core
dart pub get
dart test                                  # 221 test
dart run bin/evaluate.dart --hepsi         # dört kümenin tamamı
dart run bin/evaluate.dart --genelleme2    # İP-20, geçerli genelleme ölçümü
dart run bin/annotate_export.dart --kume=ip20 > etiketleme.csv
dart run bin/kappa.dart etiketleme.csv     # ikinci etiketleyici geldiğinde

cd ../../mobile
dart run tool/erisilebilirlik_denetimi.dart   # İP-16, Flutter gerektirmez
```

---

## 7. Açık kalanlar

| İş | Durum | Engel |
|---|---|---|
| İP-14 · Kullanılabilirlik testi (5 katılımcı) | Yapılmadı | İnsan katılımcı gerekiyor; protokol hazır (`docs/10`) |
| İP-15 · Cohen's kappa | Yapılmadı | İkinci etiketleyici gerekiyor; **araçlar hazır** |
| İP-16 · Cihaz üstü ekran okuyucu denetimi | Yapılmadı | Flutter SDK bu makinede kurulu değil |
| Demo videosu / canlı demo derlemesi | Yapılmadı | Flutter SDK bu makinede kurulu değil |

> 🔴 **Kritik uyarı.** Flutter SDK bu makineden kaldırılmış durumda
> (`flutter_windows_3.38.5-stable` klasörü artık yok). Çekirdek motor saf
> Dart olduğu için ölçümler ve testler etkilenmedi, ancak **mobil uygulama
> derlenemiyor**. 14 Eylül final teslimi ve 20 Eylül canlı demo için Flutter
> yeniden kurulmalıdır. Bu belgedeki `mobile/` değişiklikleri (İP-16 palet ve
> ekran okuyucu düzenlemeleri) **derleyiciyle doğrulanmamıştır.**


---

## 8. İP-21 · Deyim kapsamı — yüzey listesi yerine yapısal aile

### 8.1 Soru

İP-20 ölçümü, kaçakların çoğunun **deyim** olduğunu gösterdi. İlk refleks 19
deyimi tek tek yazmaktır. Ama bu, ezberlemenin üçüncü turu olurdu: İP-19 tam
olarak bunu yapmış ve taze kümede %50,0'de kalmıştı.

Soru şuydu: *bir deyim ailesi, ait olduğu YAPI üzerinden modellenirse, o
yapının hiç görülmemiş örneklerini de görür mü?*

### 8.2 Yöntem

Her aile, bir sözdizimsel yapı + o yapıyı dolduran **kapalı bir soyut ad
sınıfı** olarak kuruldu:

| Yapı | Sözvarlığı (kapalı sınıf) | Örnek |
|---|---|---|
| `[2.şahıs]da [nitelik] mı var` | akıl, vicdan, insaf, izan, edep, ar, haya, terbiye, onur… | "sende akıl mı var" |
| `[kapasite adı] bu kadar` | çap, kapasite, seviye, had, ayar, tip | "senin çapın bu kadar" |
| `[kapasite adı]nı aşan` | boy, had, çap | "boyunu aşan işlere karışma" |
| `[değerlendirme nesnesi] + yetersizlik çekimi` | laf, kelam, cümle, iş, bir yere, hiçbir şey | "iki çift laf edemiyorsun" |
| `[kimlik] + [yük tamlaması]` | topluma/ülkeye/devlete/ekonomiye yük | "engelliler topluma yük" |

**Sınıfın kapalı olması kesinliğin kaynağıdır.** "sende akıl mı var" saldırıdır,
"sende kalem mi var" gerçek bir sorudur — farkı yaratan yapı değil, yuvayı
dolduran adın SINIFIDIR. Somut ad sınıfa girmez, kalıp düşmez.

Ayrıca iki yapısal kaçış yolu kapatıldı:

- **Cümle sonu belirteçleri.** `_yuklem`in ikinci kolu "metin sonu" idi;
  yüklemden sonra tek bir zarf gelse kalıp kırılıyordu:
  *"Yunanlılara güvenilmez"* yakalanıyor, *"Yunanlılara güvenilmez hiçbir
  zaman"* kaçıyordu. Yani **pekiştireç eklemek bir kaçış yoluydu** — üstelik
  pekiştireç saldırıyı sertleştiriyor.
- **Pekiştireç adları.** "daniskası", "âlâsı", "kralı" kendileri hakaret
  değildir; önlerine geldikleri sözcüğü bir **epitete** çevirir ve yönelimi
  kesinleştirirler. Bağlam katmanının aşağılayıcı ad başları listesine
  eklendiler; *"terbiyesizliğin daniskası bu"* yönelim bulunamadığı için
  kaçıyordu.

**Toplam:** 11 yeni yapısal aile, 2 kaçış yolu kapatması, 2 sözlük girdisi.

### 8.3 İP-20 üzerindeki etkisi (küme yandı)

| Ölçüm | İP-21 önce | İP-21 sonra |
|---|:--:|:--:|
| Kesinlik | %100,0 | %100,0 |
| Özgüllük | %100,0 | %100,0 |
| Duyarlılık | %50,0 | %94,7 |
| F1 | %66,7 | %97,3 |

Diğer üç kümede **gerileme yok**.

---

## 9. İP-22 · Dördüncü ayrık küme — yapısal aile iddiasının sınavı

### 9.1 Küme, iddiayı çürütecek biçimde kuruldu

65 örnek, üç eşit parça:

| Parça | İçerik | Neyi ölçer |
|:--:|---|---|
| 1 | İP-21 ailelerinin **başka örnekleri** — aynı yapı, sınıftaki başka ad, başka çekim | Aile genelleşiyor mu |
| 2 | Aynı ailelerin **yakın-kaçışları** — somut ad, üçüncü şahıs, olumsuzlama | Aile fazla geniş mi |
| 3 | Hiçbir ailede karşılığı **olmayan** deyimler | Tavan nerede |

Beklenti ölçümden önce yazıldı: *"Kesinlik %100 kalmalı… Duyarlılık %60–75
bandı bekleniyor."*

### 9.2 Sonuç — parça parça

| Parça | Örnek | Sonuç |
|---|:--:|:--:|
| **1 · Ailelerin başka örnekleri** | 20 | **18 yakalandı — %90,0** |
| **2 · Yakın-kaçışlar** | 20 | **11 yeni ailenin hiçbirinden yanlış pozitif YOK** |
| **3 · Ailesiz deyimler (tavan)** | 15 | 1 yakalandı — %6,7 |

**Toplam ilk geçiş:** kesinlik %90,5 · duyarlılık %54,3 · F1 %67,9 · F0.5 %79,8.

**İddia doğrulandı.** Yapısal aile, aynı yapının hiç görülmemiş örneklerini
%90 oranında görüyor; İP-19'un yüzey genişletmesi taze veride %50'de
kalmıştı. Toplam duyarlılığın yine de %54,3'te kalmasının sebebi kümenin
kompozisyonudur: saldırı örneklerinin 15'i **bilerek** hiçbir ailenin
kapsamadığı deyimlerdir.

Toplam duyarlılık sayısı, "motor ne kadar iyi" sorusunun cevabı değildir;
**"kaç yapı ailesi yazıldı"** sorusunun cevabıdır. Ölçüm bunu ayrıştırdığı
için ikisi karışmıyor.

### 9.3 Ölçümün bulduğu iki kusur — ve ikisi de İP-21'den DEĞİL

Beklenti tutmadı: kesinlik %100 kalmadı, %90,5'e düştü. İki yanlış pozitifin
**hiçbiri yeni ailelerden gelmedi**; ikisi de önceden var olan kusurlardı ve
dört ölçüm kümesinin hiçbirinde görünmemişlerdi.

#### 🔴 Kusur 1 — `"bardak dolu"` yüksek riskli nefret söylemi sayılıyordu

Sözlükte `dölü` epiteti vardı ("X dölü" — kimliği kalıtsal bir kusur gibi
kuran gerçek bir nefret epiteti), **tam eşleşme** modunda, şiddet 0,85.

Normalizasyon aksanları katlar: `ö → o`, `ü → u`. Yani:

```
"dölü"  →  "dolu"        ve        "dolu"  →  "dolu"
```

Katlamadan sonra iki kelime **birebir aynıdır**. Sonuç:

```
"bardak dolu"     → yüksek risk · nefret · 0,85   ✗
"programın dolu"  → yüksek risk · nefret · 0,85   ✗
"dolu yağdı"      → yüksek risk · nefret · 0,85   ✗
"salon dolu"      → yüksek risk · nefret · 0,85   ✗
```

Bu, ürünün kendi etik iddiasını en ağır biçimde çiğneyen bir davranıştır:
sıradan bir cümle yazan kullanıcıya nefret söylemi uyarısı çıkarıyordu.

**Neden hiçbir küme görmedi:** dört kümenin 521 örneğinin hiçbirinde "dolu"
kelimesi geçmiyordu. Kusur, dördüncü kümede bambaşka bir örüntüyü sınamak
için yazılmış bir cümlede ortaya çıktı: *"yarın gelemezsin galiba,
programın dolu"*.

**Karar:** girdi **kaldırıldı**. Kimlik yuvasıyla kurtarmak da çalışmaz —
katlamadan sonra "Suriyeli dölü" ile "Suriyeli dolu" da ayırt edilemez.
Epiteti güvenilir görmenin tek yolu ham metne bakmaktır ve bu, tüm hattın
normalize metin üzerinde çalışması ilkesini tek bir terim için delerdi.
Duyarlılık kaybı kabul edildi.

#### 🟡 Kusur 2 — `"haddini bilen insanlara saygı duyarım"` işaretleniyordu

Sözlükte `haddini bil` bir **ifade** girdisiydi. İfade eşleşmesi kasıtlı
olarak **sağ sınır aramaz** — Türkçe eklemeli olduğu için "işe yaramaz"
girdisinin "işe yaramazsın"ı da görmesi gerekir. Ama bu terimde ek anlamı
**tersine çeviriyordu**:

```
"haddini bil"             → susturma emri          ✓
"haddini bilen insanlar"  → ÖVGÜ, işaretleniyordu  ✗
```

**Karar:** girdi sözlükten çıkarıldı, `susturma.haddini_bil` örüntüsüne
taşındı. Düzenli ifade sağ sınırı ifade edebilir, sözlük edemez.

#### Düzeltme sonrası

| | İlk geçiş | Düzeltme sonrası |
|---|:--:|:--:|
| Kesinlik | %90,5 | **%100,0** |
| Özgüllük | %93,3 | **%100,0** |
| Duyarlılık | %54,3 | %54,3 *(dokunulmadı)* |
| F1 | %67,9 | %70,4 |
| F0.5 | %79,8 | %85,6 |

### 9.4 Bu bölümün asıl dersi

Dört ayrık küme, motorun **duyarlılığını** ölçmek için yazılmıştı. Dördüncüsü
bunun yerine bir **kesinlik felaketi** buldu — hem de saldırganlıkla hiç
ilgisi olmayan bir kelimede.

Bu, ayrık küme disiplininin neden pahalı ama vazgeçilmez olduğunun kanıtıdır.
Geliştirme kümesindeki %99,6, İP-15'teki %98,0, İP-20'deki %97,3 — hiçbiri
`"bardak dolu"`yu göremezdi, çünkü hepsi *saldırganlık* etrafında yazılmıştı.
Kusuru bulan şey, **kümenin saldırganlıkla ilgisi olmayan bir kısmıydı.**

Sonraki kümelerde kural: örneklerin belirli bir oranı, ölçülen yetenekle
**hiç ilgisi olmayan sıradan Türkçe** olmalıdır.


---

## 10. İP-23 · Gecikme — büyüyen motorun bedeli ölçüldü ve geri alındı

### 10.1 Neden yeniden ölçüldü

Rapor §3.1, çözümlemenin **87–193 µs (AOT)** sürdüğünü ve 16 ms'lik kare
bütçesinin %1,2'sini geçmediğini bildiriyordu. O ölçüm, motorun teslim
günündeki hâli içindi. Sonrasında:

- kimlik söz varlığı **35 → 94 terime** çıktı (İP-17)
- örüntü kataloğuna **30'dan fazla** yeni kalıp eklendi (İP-19, İP-21)

Kimlik yuvası `(?:t1|t2|…|t94)` biçiminde **on beş ayrı örüntünün** içine
gömülüdür ve her birinde `_gap(3)` gibi geri izleme üretebilen bir boşlukla
birleşir. Söz varlığını üçe katlamak, en kötü durumda maliyeti de üçe
katlayabilir. **Ölçülmeyen bir gecikme iddiası, motor büyüdükçe bayatlar.**

### 10.2 İlk ölçüm — iddia gerçekten bayatlamıştı

`bin/benchmark.dart` yazıldı (AOT derlenir, p50/p95/p99 ve en kötü durumu
senaryo bazında raporlar). İlk sonuç:

| | Rapordaki iddia | Ölçülen (İP-23 öncesi) |
|---|:--:|:--:|
| Tipik | 87–193 µs | **p50 219 µs** |
| p99 | — | **1260 µs** |
| En pahalı senaryo p99 | — | **1526 µs** |

Ürün iddiası (*"kare bütçesinin altında kalır"*) **ayakta**: p99, 16 ms'nin
%7,9'u. Ama **rapordaki sayı artık doğru değildi** — 2 ila 8 kat aşılmıştı.

### 10.3 Onarım — iki ucuz ön kapı

Sıcak yol şuydu: kimlik terimi **hiç geçmeyen** bir cümlede bile on beş
nefret örüntüsü, 94 almaşıklı yuvayla birlikte çalışıyordu.

**Kapı 1 — kimlik kapısı.** Nefret örüntülerinin tamamı kimlik yuvası ya da
gönderge yuvası taşır; ikisi de metinde en az bir kimlik terimi ister. Aynı
almaşık **tek bir düz taramayla** önceden çalıştırılır; kimlik yoksa on beş
örüntü hiç denenmez.

**Kapı 2 — düşmanca sözcük kapısı.** Gerçek hayatta insanlar kimliklerden
çoğunlukla nötr bağlamda söz eder: *"Suriyeli komşumuz çok yardımsever"*,
*"Alevi kültürü üzerine tez yazıyorum"*. Kimlik kapısı bu cümlelerde açılır
ve örüntüler yine boşuna çalışır. İkinci kapı, örüntülerin gerektirdiği
sözvarlıklarının **birleşimini** arar; hiçbiri yoksa yine atlanır.

### 10.4 Sonuç

| Senaryo (p99) | Kapı öncesi | Kapı sonrası | Kazanç |
|---|:--:|:--:|:--:|
| Kısa · temiz | 176 µs | **96 µs** | −45% |
| Orta · temiz | 287 µs | **161 µs** | −44% |
| Kısa · sözlük eşleşmesi | 83 µs | **79 µs** | −5% |
| Orta · örüntü eşleşmesi | 279 µs | **148 µs** | −47% |
| Kimlik yuvası · temiz | 391 µs | **268 µs** | −31% |
| Uzun · karışık | 969 µs | **456 µs** | −53% |
| **Genel p50** | **219 µs** | **159 µs** | **−27%** |

Kalan en pahalı senaryo, on kimlik terimini tek cümleye dizen yapay bir
sınır durumudur (p99 1794 µs — bütçenin %11'i). Gerçek kullanımda karşılığı
yoktur ama ölçümde bırakıldı: en kötü durumu gizlemek, ortalamayı raporlayıp
kullanıcının hissettiğini saklamak olurdu.

### 10.5 Kapı bir hızlandırmadır — bunu KANITLAMAK zorundaydı

Ön kapının tehlikesi sessizliğidir: kapı fazla dar olursa gerçek bir nefret
söylemi kaçar, **hiçbir test kırılmaz, hiçbir metrik değişmez** — çünkü kaçan
örnek kümede yoksa kimse fark etmez.

`test/detector_gate_test.dart` bu sessizliği kaldırır: kapılı ve kapısız
dedektör, **beş kümenin 581 cümlesinin tamamında** karşılaştırılır. Karşılaştırma
risk seviyesi üzerinden değil, **bulgu kimlikleri** üzerinden yapılır — iki
motor aynı seviyeye farklı örüntülerle çıkarsa kullanıcıya gösterilen gerekçe
değişmiş olur ve bu da bir gerilemedir.

Ayrıca iki yapısal değişmez kilitlendi:
- Her nefret örüntüsünün kimliği `nefret.` önekiyle başlar (kapı buna dayanır).
- Her nefret ailesinin bir temsilci cümlesi kapıdan geçebilmelidir (kapının
  daralmadığını kanıtlar).

**Sonuç: 246 test yeşil** (İP-23 öncesi 221).

### 10.6 Raporlanacak yeni gecikme sayısı

| Ölçüm | Değer |
|---|:--:|
| Tipik (p50) | **159 µs** |
| p95 | 1344 µs |
| p99 | 1459 µs |
| Kare bütçesinin p99'da kullanılan oranı | **%9,1** |

Yeniden üretme: `dart compile exe bin/benchmark.dart -o benchmark.exe && ./benchmark.exe`
