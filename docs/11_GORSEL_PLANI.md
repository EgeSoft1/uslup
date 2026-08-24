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

## 3. Şekil yerleşim planı — 10 görsel

> **Çapalar rapora yerleştirilmiştir.** `docs/09_RAPOR_METNI.md` içinde her
> şeklin geleceği noktada `**[ŞEKİL N BURAYA — …]**` satırı, hemen altında da
> italik *Şekil N. …* alt yazısı hazır durumdadır ve gövde metninden
> "(Şekil N)" atıfları yapılmıştır. Word'de yapılacak iş: görseli çapanın
> yerine koymak ve **yalnızca köşeli parantezli satırı silmek**.

**Beş şekil çizim olarak üretilmiştir ve ekran görüntüsüne bağlı değildir.**
Dosyalar `docs/gorseller/` altındadır; Flutter kurulumu olmasa bile rapor
görselsiz kalmaz.

| # | Bölüm | İçerik | Tür | Kaynak |
|:--:|---|---|---|---|
| **1** | §1.2 sonu | Cihaz üstü çözümleme hattı | Çizim | `gorseller/sekil1_mimari.png` ✅ |
| **2** | §2.2, merdiven tablosunun altı | Müdahale merdiveni, dört seviye | Çizim | `gorseller/sekil2_merdiven.png` ✅ |
| **3** | §2.2, bağlam ağırlıklandırma tablosunun altı | Aynı sözcük, dört bağlam | Çizim | `gorseller/sekil3_baglam.png` ✅ |
| **4** | §3.2, katman izolasyonu tablosunun altı | Katman katkısının izolasyonu | Grafik | `gorseller/sekil4_katman.png` ✅ |
| **5** | §3.3, A1 anlatımının altı | Ana kullanıcı akışı (A1) | Diyagram | `gorseller/sekil5_akis.png` ✅ |
| **6** | §3.3, A3 anlatımının altı | Mağdur akışı — uyarı **çıkmıyor** | Ekran | Derleme gerekli |
| **7** | §3.3, arayüz kararları tablosunun altı | "Neden uyarıldın?" gerekçe kartı | Ekran (kırpma) | Elimizde |
| **8** | §5.1 başı | NSosyal gönderi kutusu | Ekran | Elimizde |
| **9** | §5.1, Örnek 2'nin altı | Kimlik beyanı işaretlenmiyor | Ekran | Derleme gerekli |
| **10** | §5.1, Örnek 5'in altı | Topluluk paneli + "Dışarı ne gider" | Ekran | Derleme gerekli |

Sayfa bütçesi uygun: metin ~24 sayfa, sınır **30**. 10 görsel ≈ 4 sayfa;
toplam ~28–29 sayfada kalırsın.

---

### Çizim olarak hazır olan beş şekil

**Şekil 1 — Katmanlı çözümleme mimarisi → §1.2 sonuna.** Ham metinden anonim
sinyale kadar olan yedi adımlı hat. Kritik mesaj: hattın hiçbir adımında ağ
çağrısı yoktur. Jürinin "bu gerçekten cihazda mı çalışıyor?" sorusunun görsel
cevabı budur.

**Şekil 2 — Müdahale merdiveni → §2.2, merdiven tablosunun hemen altına.**
Dört seviye yan yana: temiz · dikkat · riskli · yüksek. Kritik mesaj: hiçbir
seviyede gönderim engellenmiyor. Alt panel harfleri (a) (b) (c) (d) alt yazıyla
eşleşmelidir.

**Şekil 3 — Bağlam ağırlıklandırma → §2.2, katsayı tablosunun altına.** Aynı
sözcüğün saldırı / iltifat / şikâyet / öz-ifade bağlamlarında aldığı ağırlık.
Rubrik 2.2'nin "özgün algoritma" maddesinin doğrudan kanıtı: projenin teknik
kalbi tek karede görülür.

**Şekil 4 — Katman katkısının izolasyonu → §3.2, izolasyon tablosunun altına.**
Raporun en güçlü sayısal iddiası. "Yasaklı kelime listesi yetmez" cümlesini bir
görüşten bir ölçüme dönüştürür: örtük saldırıda %1,8 → %100,0, nefret
söyleminde %10,5 → %94,7 — kesinlikten hiçbir şey götürmeden.

**Şekil 5 — Ana kullanıcı akışı (A1) → §3.3, A1 anlatımının altına.** Rubrik
3.3'ün "Kullanıcı akışları sunulmuş" maddesi (0–2 puan) doğrudan bunu istiyor.
Akışın iki kritik özelliği görsel olarak da okunur: hiçbir dal gönderimi
engellemez ve hiçbir dalda metin cihazdan çıkmaz.

---

### Ekran görüntüsü gereken beş şekil

**Şekil 6 — Mağdur akışı → §3.3, A3 anlatımının altına.** "Bana 'şerefsiz'
dedi, çok üzüldüm" yazılmış ve **hiçbir uyarı çıkmamış** hâlin ekran
görüntüsü. Bu görselin gücü, gösterdiği şeyin **yokluğu** olmasıdır: 0,88 taban
şiddetli bir terim var, uyarı yok. Ekranda nezaket puanının 100 göründüğünden
emin ol.

**Şekil 7 — Gerekçe kartı → §3.3, arayüz kararları tablosunun altına.** Yakın
plan (crop). Kartta hangi ifadenin neden işaretlendiği metin olarak
görünmelidir — rubrik 3.3'ün açıklanabilirlik beklentisinin kanıtı.

**Şekil 8 — NSosyal gönderi kutusu → §5.1 başına.** Jürinin ilk sorusu "bu
NSosyal'e ne katıyor?" olacak; bu görsel soruyu ekranla cevaplıyor. **Öne çıkar,
mümkünse büyük bas.**

**Şekil 9 — Kimlik beyanı işaretlenmiyor → §5.1, Örnek 2'nin altına.** "Ben
Kürtüm" gibi bir cümlenin uyarısız geçtiği ekran. Rakiplerden ayrışmanın en
somut tek karesi.

**Şekil 10 — Topluluk paneli + "Dışarı ne gider" kartı → §5.1, Örnek 5'in
altına.** İki panel yan yana: (a) panelin üstü ve mahremiyet ifadesi, (b)
"Dışarı ne gider" kartı. Kartın platforma gidecek veriyi harfi harfine
gösterdiği okunabilir olmalı.

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
| Gövde (§1–§8) | ~22 |
| 10 şekil | ~4 |
| Kaynakça | 1,5 |
| **Toplam** | **~28** |
| **Sınır** | **30** |

Payın ~1 sayfa. Sınırı aşarsan **önce Şekil 8'i**, sonra Şekil 10'u çıkar;
ikisi de rubrikte doğrudan karşılığı olmayan destekleyici görsellerdir.
Şekil 1, 2, 3, 4, 5, 7 ve 9 **çıkarılmaz** — her biri bir rubrik maddesinin
kanıtıdır.
