# Rapora Girecek Görseller — Yerleşim Planı

**Tarih:** 24 Ağustos 2026 · **Teslim:** bugün 17.00 (TSİ)
**Kaynak kural:** Şablonun puanlama tablosu ve genel format kuralları.

---

## 0. Ekran görüntüsü yasak mı? — Hayır, puan getiriyor

Şablonda ekran görüntüsünü yasaklayan **tek bir madde yok**. Tam tersine,
puanlama tablosu üç yerde doğrudan görsel istiyor:

| Rubrik maddesi | Bölüm | Puan | Görselsiz alınabilir mi |
|---|---|---|---|
| "Kullanıcı akışları (user flows) sunulmuş" | 3.3 | 0–2 | Zor |
| "Arayüz tasarım kararları gerekçelendirilmiş" | 3.3 | 0–2 | Zor |
| "Görsel bir şema/tablo ile sunulmuş" | 7.1 | 0–1 | Tablo yeterli (bizde var) |

Ayrıca genel değerlendirme kriterlerinde **"Teknik Dokümantasyon ve Prototip
Olgunluğu"** başlığı var ve ağırlık tablosunda **"Sunum ve Prototip Kalitesi
%15"** olarak geçiyor. Çalışan bir prototipin varlığını en ucuza kanıtlayan
şey ekran görüntüsüdür.

### Tek yasak

> "Değerlendirme esasları gereği takım üyelerinin isim ve fotoğraf gibi kişisel
> bilgilerine yer verilmemelidir."

Yani yasak olan **takım üyesinin kendisi**. Ürün ekranı serbest.

---

## 1. ⚠️ Önce elemeyi getirecek üç kontrol

Bunlar puan meselesi değil, **güvenilirlik** meselesi. Jüri bunlardan birini
görürse raporun geri kalanına da inanmaz.

### K1 — Telefon numarası sansürlenecek

SMS doğrulama ekranındaki **+90 507…** numarası açık görünüyor. Ayarlar
ekranında zaten XXX'lemişsin; aynısını her ekranda yap. Zaten bu ekranı rapora
koymamanı öneriyorum (bkz. §2 kara liste), ama koyacaksan numara kapatılmalı.

### K2 — Mesajlaşma uygulaması ekranları rapora girmeyecek

Elindeki görsellerin bir kısmı bir **mesajlaşma uygulamasına** ait: "Sohbetler",
"Aramalar", "Kişiler" sekmeleri ve "Türkiye Mesajlaşma — Güvenli / Yerli /
Milli" açılış ekranı.

Bu yarışma **NSosyal platformuna değer katan** bir çözüm istiyor; rakip bir
mesajlaşma uygulaması değil. Raporun kendisi de bunu söylüyor: devralınan
mesajlaşma altyapısı §1.2'de açıkça **kapsam dışı** ilan edilmiş ve depodan
çıkarılmış (`a054352`). Kapsam dışı ilan ettiğin şeyin ekran görüntüsünü rapora
koyarsan, jüri "proje aslında ne?" diye sorar.

**Rapora yalnızca Üslup / Nezaket Koçu ekranları girecek.**

### K3 — "Sunucuya gönder" içeren ekran varsa çıkarılacak

Raporun en güçlü iddiası: **metin cihazdan hiç çıkmaz.** Bulut kademesi
yazılmış, ölçülmüş ve kasıtlı olarak kaldırılmıştı (`2fe8d82`).

Ekranlarından birinde "sunucuya gönderilsin mi?" tarzı bir onay diyaloğu varsa,
o eski derlemeden kalmadır ve raporun merkezî iddiasıyla **doğrudan çelişir**.
Jüri bunu yakalarsa §2.2, §3.1 ve §6.1'in tamamı şüpheye düşer.

- Diyalog "Yine de gönder / Vazgeç" diyorsa → **sorun yok**, bu cihaz içi
  yüksek risk onayı, raporun §2.2'deki müdahale merdiveninde tanımlı.
- Diyalog "sunucu", "bulut", "internete gönder" diyorsa → **çıkar**, güncel
  derlemeden yeniden ekran al.

---

## 2. Kara liste — bu ekranlar rapora girmeyecek

| Ekran | Neden |
|---|---|
| Türkiye Mesajlaşma açılış / splash | Kapsam dışı ürün (K2) |
| Sohbetler / Aramalar / Kişiler sekmeleri | Kapsam dışı ürün (K2) |
| SMS doğrulama (telefon numaralı) | Kapsam dışı + kişisel veri (K1, K2) |
| Ayarlar ekranı | Kapsam dışı, rubrikte karşılığı yok |
| "Sunucuya gönder" onayı (varsa) | Merkezî iddiayla çelişir (K3) |

---

## 3. Şekil yerleşim planı — 8 görsel

Sayfa bütçesi uygun: metin ~23 sayfa, sınır **30**. 8 görsel ≈ 3–4 sayfa;
toplam ~27 sayfada kalırsın.

### Şekil 1 — Katmanlı çözümleme mimarisi → **§1.2 sonuna**

Ekran görüntüsü değil, **çizim**. README'deki hat şemasının Word'de kutu-ok
hâline getirilmiş biçimi:

```
Kullanıcı yazıyor
   ↓  ─── CİHAZ ÜZERİNDE ───────────────────────────────
   │  1. Normalizasyon      "$3r3fsiz" → "serefsiz"
   │  2. Sözlük eşleştirme  Türkçe kök eşleşmesi
   │  3. Örüntü katmanı     Küfürsüz düşmanlık
   │  4. Nefret katmanı     Kimlik hedefli düşmanlık
   │  5. Gönderge katmanı   Zamiri öncüle bağlar
   │  6. Bağlam çözümleme   saldırı/iltifat/şikâyet/öz-ifade
   │  7. Öneri üretimi      Yerel, deterministik
   ↓  ────────────────────────────────────────────────────
Kullanıcı seçer → gönderir          ⛔ Sunucu adımı yoktur
```

**Alt yazı:** *Şekil 1. Üslup'un cihaz üstü çözümleme hattı. Hattın hiçbir
adımında ağ çağrısı bulunmaz; çözümleme kullanıcının cihazında başlar ve biter.*

> Neden burada: 3.1'in "teknik altyapı eksiksiz tanımlanmış" maddesi (0–2 puan)
> ve 4.3'ün "teknolojik yenilik teknik detaylarla ortaya konmuş" maddesi
> (0–2 puan) için en güçlü tek görsel budur.

---

### Şekil 2 — Müdahale merdiveni, dört seviye yan yana → **§2.2'ye, merdiven tablosunun hemen altına**

Dört ekran görüntüsünü **tek satırda yan yana** yerleştir. En değerli görselin
budur; ürünün tezini tek bakışta anlatır.

| Panel | Hangi ekran | Ne göstermeli |
|---|---|---|
| (a) Temiz | "100 puan" / temiz metin ekranı | Hiçbir uyarı yok |
| (b) Dikkat | Yalnızca kenarlık rengi değişen ekran | Kesinti yok |
| (c) Riskli | Gerekçe + yeniden yazma önerisi | Kart açık |
| (d) Yüksek | "Yine de gönder / Vazgeç" onayı | Gönderim engellenmiyor |

**Alt yazı:** *Şekil 2. Müdahale merdiveni. (a) temiz metinde hiçbir kesinti
yoktur; (b) dikkat seviyesinde yalnızca kenarlık rengi değişir; (c) riskli
seviyede gerekçe ve alternatif sunulur; (d) yüksek riskte onay istenir — ancak
hiçbir seviyede gönderim engellenmez.*

> (b) elinde yoksa üç panelle yap ve alt yazıdan (b)'yi çıkar. Uydurma.

---

### Şekil 3 — "Neden uyarıldın?" gerekçe kartı → **§3.3, "Arayüz tasarım kararları" tablosunun altına**

Yakın plan (crop) al; kartın metni okunsun.

**Alt yazı:** *Şekil 3. Açıklanabilirlik. Her uyarı, hangi ifadenin neden
işaretlendiğini metin olarak bildirir; kullanıcı kararın gerekçesini görmeden
bir öneriyle karşılaşmaz.*

> Rubrik: "Arayüz tasarım kararları gerekçelendirilmiş" (0–2 puan). Tablodaki
> "Her uyarıda hangi kelime ve neden" satırının kanıtı bu görseldir.

---

### Şekil 4 — Mağdur akışı (A3): uyarı **çıkmıyor** → **§3.3, A3 anlatımının altına**

"Bana 'şerefsiz' dedi, çok üzüldüm" yazılmış ve **hiçbir uyarı çıkmamış** ekran.

**Alt yazı:** *Şekil 4. Mağdur akışı. Cümlede 0,88 taban şiddetinde bir terim
geçmesine rağmen uyarı üretilmez; bağlam katmanı ifadeyi aktarım olarak tanır
(×0,20) ve yumuşatma tavanı sonucu eşiğin altında tutar.*

> Bu, raporun rakiplerden ayrıldığı yer. "Bizde uyarı çıkmıyor" cümlesini
> yazmak kolay; **göstermek** ikna edicidir.

---

### Şekil 5 — Kimlik beyanı işaretlenmiyor → **§3.3 veya §5.1 Örnek 2'nin altına**

"Ben Kürtüm" ya da benzeri bir kimlik cümlesinin uyarısız geçtiği ekran.

**Alt yazı:** *Şekil 5. Kimlik adı hiçbir zaman tek başına tetikleyici değildir.
Sözlükte kimlik adı bulunmaz; bu davranış yapısal bir testle korunur.*

---

### Şekil 6 — Bağlam testleri ekranı → **§3.2, bağlam ağırlıklandırma anlatımının altına**

Aynı kelimenin dört bağlamda farklı sonuç verdiğini gösteren test/demo ekranı
("aptalsın" ×1,25 · "aptal değilsin" ×0,15 · "bana aptal dedi" ×0,20 ·
"kendimi aptal hissettim" ×0,20).

**Alt yazı:** *Şekil 6. Bağlam ağırlıklandırma. Aynı sözcük, saldırı / iltifat /
şikâyet / öz-ifade bağlamlarında farklı ağırlık alır; yumuşatma yalnızca çarpan
değil aynı zamanda tavandır.*

---

### Şekil 7 — Topluluk sağlığı paneli + "Dışarı ne gider" kartı → **§5.1 Örnek 5'in altına**

İki panel: (a) panelin üstü, "Bu paneldeki hiçbir sayı mesaj içeriğinden
üretilmez" ifadesi görünecek şekilde; (b) "Dışarı ne gider" kartı.

**Alt yazı:** *Şekil 7. Mahremiyetten ödün vermeyen topluluk yönetimi. Panel
davranıştan beslenir, mesaj listesi içermez; 5 gözlemin altındaki kategoriler
k-anonimlik gereği açılmaz ve "Dışarı ne gider" kartı platforma gidecek veriyi
harfi harfine gösterir.*

---

### Şekil 8 — NSosyal gönderi kutusu → **§4.3 veya §5.1'in başına**

"NSosyal'e bir gönderi yaz…" yazan ekran. **Bu senin en stratejik görselin.**

**Alt yazı:** *Şekil 8. Katman platforma bağlı değildir; Türkçe metin girişi
yapılan herhangi bir yüzeye — burada NSosyal gönderi kutusuna — kütüphane
bağımlılığı olarak eklenebilir.*

> Neden kritik: jürinin ilk sorusu "bu NSosyal'e ne katıyor?" olacak. Bu görsel
> soruyu ekranla cevaplıyor. **Öne çıkar, mümkünse büyük bas.**

---

## 4. Word'de biçim kuralları

- Her şeklin **altına** numaralı alt yazı: *Şekil N. …* — Arial, 10–11 punto,
  italik, **ortalanmış**. (Gövde metni Arial 12 kalır.)
- Görsel genişliği sayfa genişliğini aşmasın; kenar boşlukları **2,5 cm** sabit.
- Yan yana panellerde alt panel harfleri **(a) (b) (c) (d)** görselin üstüne
  ya da altına yazılsın; alt yazıda aynı harflerle atıf yapılsın.
- Her şekle gövde metninden **en az bir kez atıf** yap: "(Şekil 2)". Atıfsız
  görsel dekorasyon sayılır; atıflı görsel kanıt sayılır.
- Ekran görüntülerini **PNG** olarak ekle, JPEG değil — metin keskin kalsın.
- Görselleri "Metinle Aynı Hizada" (in line with text) yerleştir; kayan görsel
  şablonun sayfa düzenini bozar.

---

## 5. Sayfa bütçesi

| Kalem | Tahmini sayfa |
|---|---|
| Kapak | 1 |
| İçindekiler | 1 |
| Gövde (§1–§8) | ~21 |
| 8 şekil | ~3,5 |
| Kaynakça | 1,5 |
| **Toplam** | **~28** |
| **Sınır** | **30** |

Payın ~2 sayfa. Sınırı aşarsan **önce Şekil 6'yı**, sonra Şekil 5'i çıkar;
ikisi de rubrikte doğrudan karşılığı olmayan destekleyici görsellerdir.
Şekil 1, 2, 3, 4 ve 8 **çıkarılmaz** — her biri bir rubrik maddesinin kanıtıdır.
