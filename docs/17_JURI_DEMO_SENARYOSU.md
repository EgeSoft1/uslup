# Jüri Demo Senaryosu — 20 Eylül 2026, canlı sunum

**Süre hedefi:** 6–7 dakika demo (sunumun tamamı değil)
**Ortam:** Uygulama telefonda ya da masaüstünde çalışır; ağ bağlantısı
**gerekmez** ve bu, demonun kendisinde gösterilecek bir noktadır.

---

## 0. Demodan önce — kontrol listesi

| Kontrol | Komut / eylem | Neden |
|---|---|---|
| Uygulama derleniyor | `cd mobile && flutter run` | 25 Ağustos'ta tek satırlık bir sözdizim hatası uygulamayı açılmaz hâle getirmişti |
| Testler yeşil | `flutter test` ve `cd packages/civility_core && dart test` | Demoda kırılan bir şey, testte de kırılıyordur |
| **Uçak modu açık** | Telefon ayarları | Demonun en güçlü tek anı bu |
| Tema açık modda | Profil → kapak sağ üst | Projektörde koyu tema okunmuyor |
| Yazı tipi ölçeği normal | Sistem ayarı | Kartlar 1,3×'e kadar taşmıyor ama emin olalım |

> **Uçak modunu açın ve açık bırakın.** "Metin cihazdan çıkmaz" cümlesini
> anlatmak yerine göstermek, demonun en ucuz ve en ikna edici hamlesidir.
> Uygulama tam işlevsel çalışmaya devam eder.

---

## 1. Açılış — problem, 40 saniye

**Ekran:** Akış sekmesi. Aşağı kaydırın, Selin Korkmaz'ın gönderisine gelin.

> *"Dün bir gönderimin altına gelen yorumlar yüzünden uygulamayı sildim…
> Şikâyet ettim ama 'inceleniyor' yazısından öteye geçmedi. Yorum silinene
> kadar ben o cümleleri zaten okumuştum."*

**Söylenecek:**
> "Bugünün moderasyonu yayın sonrası çalışıyor. İçerik yayımlanır, şikâyet
> edilir, silinir. Ama silmek, hedef kişinin onu görmüş olmasını geri
> almıyor. Biz müdahaleyi yazma anına taşıyoruz."

---

## 2. Ana gösteri — kışkırtılmış yanıt, 90 saniye

**Ekran:** Gündem Notu'nun tartışmalı maç gönderisine dokunun → yanıtlar
açılır. Yanıt kutusuna gidin.

**Yazın (elle, canlı):**

```
sen tam bir aptalsın
```

**Jüri ne görecek:**
1. Kelimenin altı **yazarken** dalgalı çiziliyor.
2. Kenarlık renk değiştiriyor.
3. "Neden uyarıldın?" paneli açılıyor: hangi ifade, hangi katman, neden.
4. Yeniden yazma önerisi çıkıyor, yanında öngörülen nezaket puanı.
5. Risk şeridinin yanında **çözümleme süresi** yazıyor: ~200 µs.

**Söylenecek:**
> "Bu çözümleme telefonun içinde yapıldı. Süreye bakın — 60 FPS'te bir kare
> 16 milisaniye; biz mikrosaniye ölçeğindeyiz. Bu yüzden her tuş vuruşunda
> çalıştırabiliyoruz, gecikmeli tetikleme bile gerekmiyor."

**"Bunu kullan"a basın.** Öneri metne geçer, uyarı kaybolur.

> "Sistem metni kendisi değiştirmedi. Önerdi, gerekçesini yazdı, kararı bana
> bıraktı. İstersem uyarıyı yok sayıp gönderebilirim — hiçbir şey
> engellenmiyor."

---

## 3. Ayrışma noktası — bağlam, 2 dakika

**Ekran:** Alt çubuktan **Üslup** sekmesi → "Canlı deneme" kutusu, altındaki
**bağlam testleri** çipleri.

Dört çipe sırayla dokunun. Her birinde beklenen sonuç ekranda yazılı:

| Çip | Cümle | Sonuç |
|---|---|---|
| Doğrudan saldırı | "Sen tam bir aptalsın" | **işaretlenir** |
| Olumsuzlama | "Sen hiç aptal değilsin" | temiz |
| **Mağdur anlatısı** | "Bana 'aptal' dedi, çok üzüldüm" | **temiz** |
| Öz-ifade | "Kendimi çok aptal hissettim" | temiz |

**Burada durun. Bu, sunumun en önemli 20 saniyesi.**

> "Dördünde de aynı kelime var. Bir kelime listesi dördünü de işaretler.
> Üçüncüsüne dikkat edin: bu, tacize uğradığını **anlatan** kişi. Mevcut
> filtreler onu susturuyor — hakaret sözcüğü geçtiği için şikâyet edeni
> cezalandırıyorlar. Bizde bu yapısal olarak imkânsız: yumuşatma bir çarpan
> değil, bir **tavan**. Terimin şiddeti ne olursa olsun eşiğin altında
> kalıyor."

Sonra iki çipe daha dokunun:

| Çip | Cümle | Sonuç |
|---|---|---|
| **Kimlik beyanı** | "Ben Kürtüm ve bununla gurur duyuyorum" | **temiz** |
| Nefret söylemi | "Bütün Suriyeliler hırsızdır" | **işaretlenir** |

> "Nefret söylemi filtrelerinin en yaygın kusuru, korunan grubun adını
> yasaklı kelime listesine koymaktır — ve sonuç, korumaya çalıştıkları grubu
> susturmaktır. Bizim sözlüğümüzde tek bir kimlik adı yok. Kimlik adı
> yalnızca düşmanca bir kuruluşun içindeki yuvayı dolduruyor. Bu davranış
> bir belgeyle değil, sözlüğe kimlik adı sızarsa kırılan bir testle
> korunuyor."

**Son iki çip — sansür değiliz:**

| Çip | Cümle | Sonuç |
|---|---|---|
| Sert ama meşru | "Bu karar bence tamamen hatalı ve geri alınmalı" | temiz |
| Küfürsüz düşmanlık | "Senin gibilerden zaten bu beklenirdi" | **işaretlenir** |

> "Sert eleştiri sansürlenmiyor. Buna karşılık ikinci cümlede tek bir yasaklı
> kelime yok — saldırganlık kelimelerde değil, kelimelerin dizilişinde. Onu
> gören şey edimbilimsel örüntü katmanı ve katkısı ölçülü: duyarlılıkta
> +55,2 puan, kesinlikten sıfır kayıp."

---

## 4. Dürüstlük — 90 saniye

**Ekran:** Aynı sekmede aşağı kaydırın → **Ölçüm geçmişi** tablosu.

> "Burada beş küme var ve üçünün yanında 'yanmış' yazıyor. Bunu gizlemedik.
> Geliştirme kümesinde F1 %99,6 — ama o bir genelleme kanıtı değil, çünkü
> kümeyi de örüntüleri de biz yazdık. Taze bir kümede duyarlılık %100'den
> %12'ye düştü. Bu, projenin en değerli ölçümü: ezberin büyüklüğünü sayıya
> çevirdi."
>
> "Raporladığımız sayı en iyisi değil, geçerli olanı: **kesinlik %90,5,
> duyarlılık %54,3, F1 %67,9.**"
>
> "Dördüncü küme bize bir kesinlik felaketi de buldu: 'bardak dolu' cümlesi
> yüksek riskli nefret söylemi sayılıyordu. Sebep, aksan katlamasının 'dölü'
> ile 'dolu'yu birebir aynı hâle getirmesiydi. Önceki 521 örneğin hiçbirinde
> 'dolu' kelimesi geçmiyordu. Kusuru bulan şey, kümenin saldırganlıkla hiç
> ilgisi olmayan kısmıydı."

*(Jüri bu bölümü sevecektir. Ölçmeyi bilen bir ekip olduğunuzu gösteren tek
şey, kötü sayıyı da göstermenizdir.)*

---

## 5. Mahremiyet ve topluluk — 60 saniye

**Ekran:** **Topluluk** sekmesi.

> "Panel metinden değil davranıştan besleniyor: kullanıcı uyarı karşısında ne
> yaptı — gönderdi mi, öneriyi kabul etti mi, kendi düzeltti mi, vazgeçti mi.
> Sinyal sınıfının tek bir metin alanı yok ve bu da bir testle korunuyor."
>
> "Toplulaştırma cihazda yapılıyor ve k-anonimlik uygulanıyor: bir kategori
> en az 5 gözlem yoksa sayı olarak açılmıyor. Eşiği arayüz değil katmanın
> kendisi uyguluyor — arayüzün unutması mümkün olmasın diye."

**"Dışarı ne gider" kartını gösterin.** Yalnızca `anahtar: sayı` satırları.

> "Platforma giden şey bu. Metin değil, sayı."

**Sonra telefonu kaldırıp uçak modunu gösterin:**

> "Bu demonun tamamı uçak modunda yapıldı."

---

## 6. Kapanış — 30 saniye

**Ekran:** Profil sekmesi → **Üslup özeti** kartı.

> "Kullanıcı kendi davranışını burada görüyor: bu oturumda kaç gönderi, kaçında
> uyarı, kaçını düzeltti. Bu sayı akışta rozet olarak gösterilmiyor ve
> gösterilmeyecek — çünkü müdahale bir ceza değil, bir duraksama. Rozetlenen
> kullanıcı bir daha uyarılmamak için özelliği kapatır ve korumayı en çok
> gereken kişiyi kaybederiz."

> "Katman platforma bağlı değil. Türkçe metin girişi olan herhangi bir yüzeye
> taşınabilir: mesajlaşma, forum, yorum alanı, kurum içi iletişim. Entegrasyon
> yükü bir kütüphane bağımlılığı eklemekten ibaret — API anahtarı yok, sunucu
> yok, çıkarım maliyeti yok."

---

## 7. Beklenen sorular ve hazır cevaplar

**"Duyarlılık %54, bu düşük değil mi?"**
> Evet ve gizlemiyoruz. Ama o sayı "motor ne kadar iyi" sorusunun cevabı
> değil, "kaç yapı ailesi yazdık" sorusunun cevabı. Ölçümü ayrıştırdık:
> yazdığımız bir ailenin hiç görülmemiş örneklerinde %90, yazmadığımız
> ailelerde %7. Kural tabanlı bir katman Türkçe deyim uzayını kapatamaz —
> bu bir veri problemi ve yol haritamızın gerekçesi bu ölçüm.

**"Neden bir dil modeli kullanmıyorsunuz?"**
> Kullandık, ölçtük, kaldırdık. Bulut yeniden yazma servisi yazılmış, 50
> testle doğrulanmış, uçtan uca sınanmıştı. Üç sebeple kaldırdık: "metin
> cihazdan çıkmaz" iddiasına açıklanması gereken bir istisna ekliyordu,
> jürinin çalıştıramayacağı bir üçüncü taraf bağımlılığı getiriyordu ve
> katkısı yalnızca öneri akıcılığıydı. Commit geçmişinde ikisi de duruyor:
> eklenmesi ve dört gün sonra kaldırılması.

**"Denetimli bir model daha iyi olmaz mıydı?"**
> Eğittik. Aynı geliştirme kümesinde 45 aday yapılandırma, çapraz doğrulama
> ile seçim. Sonuç: kural motorunun kaçırdığı **hiçbir örneği yakalamadı**,
> buna karşılık motorun yapmadığı altı yanlış pozitif üretti — hepsi iltifat,
> olumsuzlama ya da mağduru savunan cümle. Bu, doğrusal bir taban çizgisinin
> bu veri hacmindeki sınırı; önceden eğitilmiş bir Türkçe modelin de
> başarısız olacağını iddia etmiyoruz.

**"Bu arayüz NSosyal'in kopyası mı?"**
> Hayır. Logo, işaret ve tipografi kopyalanmadı. Aldığımız şey yerleşim ve
> Türkçe terminoloji düzeyinde tasarım dili — katmanın sizin ürününüze
> düştüğünde nasıl duracağını göstermek için. Katman zaten platforma bağlı
> değil; kabuk bir entegrasyon önerisi.

**"Kaç kişi denedi?"**
> Kullanılabilirlik testi henüz yapılmadı ve bunu açıkça yazıyoruz. Protokol
> hazır (`docs/10`), 5 katılımcılık plan var. Aynı şekilde hakemler arası
> uyum (Cohen's kappa) da ölçülmedi; araçlar hazır, eksik olan ikinci insan.
> Bütün metrikler şu an tek etiketleyicili ve raporda böyle beyan ediliyor.

---

## 8. Riskler ve kaçış yolları

| Risk | Kaçış |
|---|---|
| Uygulama demo sırasında çöker | Ekran kaydı yedeği hazır bulundurun (İP-18) |
| Klavye açılmıyor / yazamıyorsunuz | Bağlam testi **çipleri** tek dokunuşla metni yükler — elle yazmaya gerek yok |
| Süre daralıyor | §3'ü kısaltmayın; §4 ve §5'ten kısın. Bağlam ayrımı ürünün ayrıştığı yerdir |
| Jüri kodu görmek isterse | `github.com/EgeSoft1/uslup` — herkese açık, kayıt gerektirmez |
| Jüri sayıyı yeniden üretmek isterse | `dart run bin/evaluate.dart --genelleme3` tek komut |

---

## 9. Demoda SÖYLENMEYECEKLER

- "Yapay zekâmız %99 doğrulukla çalışıyor." — Geliştirme kümesindeki sayıdır
  ve genelleme kanıtı değildir. Bu cümle, raporun en güçlü bölümünü
  (dürüstlük beyanını) tek hamlede çürütür.
- "Nefret söylemini engelliyoruz." — Sistem hiçbir şeyi engellemiyor. Öneriyor.
- "Akıştaki veriler gerçek." — Kurgudur ve öyle etiketlidir.
- Ölçülmemiş bir şeyi ölçülmüş gibi anlatmak. Kullanılabilirlik testi,
  kappa ve cihaz üstü ekran okuyucu denetimi **yapılmadı**; sorulursa
  olduğu gibi söyleyin. Bu projede güvenilirliğin kaynağı, neyi bilmediğini
  söyleyebilmesidir.
