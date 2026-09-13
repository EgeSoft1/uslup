# Jüri Sunumu — 15 Dakika, Yüz Yüze

**Biçim:** 15 dakika · 6–8 jüri üyesi ve diğer takımlar önünde · yüz yüze
**Son güncelleme:** 13 Eylül 2026 — arayüz yenilendi, bütün sayılar bugün
yeniden ölçüldü (§8).

Bu belge iki şeyi birlikte taşır: **slayt + canlı demo akışı** (dakika
dakika) ve **demo sırasında ekranda ne yapılacağı**. Slaytlara konacak ekran
görüntüleri hazır: `docs/gorseller/ekranlar/` (üretmek için §7).

---

## 0. Sunum günü — kontrol listesi

| # | Kontrol | Nasıl | Neden |
|---|---|---|---|
| 1 | Web sürümü derlenmiş | `cd mobile` → `flutter build web --release --no-web-resources-cdn` (bir kez, internet varken) | `--no-web-resources-cdn` olmadan çizim motoru Google sunucusundan iner; uçak modunda **boş ekran** kalır |
| 2 | Başlatıcı çalışıyor | Depo kökünde **`SUNUMU_BASLAT.bat`** çift tık | Yerel sunucu + adres çubuksuz Edge penceresi açar; **F11** tam ekran |
| 3 | **Uçak modu / Wi-Fi kapalı** | Dizüstünde ağı kapatın, uygulamayı öyle açın | Demonun en güçlü tek anı: "metin cihazdan çıkmaz"ı anlatmak değil göstermek |
| 4 | Açık tema | Sol menü → Karanlık mod kapalı | Projektörde koyu tema okunmuyor |
| 5 | Yakınlaştırma %100–110 | Edge'de Ctrl+0, gerekirse Ctrl++ | Salonun arkası kartları okuyabilmeli |
| 6 | Yedek video hazır | §6 — dört kısa klip slaytta gömülü | Bilgisayar/projektör sorununda demo videodan yürür |
| 7 | Yedek cihaz | `build/app/outputs/flutter-apk/app-release.apk` bir Android telefonda kurulu | Dizüstü tamamen çökerse |
| 8 | Testler yeşil | `cd packages/civility_core && dart test` · `cd mobile && flutter test` | Demoda kırılan şey testte de kırılıyordur |

> **Uygulamayı sunumdan ÖNCE bir kez açın ve Üslup Paneli'ne girin.** İlk
> açılışta tarayıcı çizim motorunu yükler (~2 sn); jürinin önünde bu bekleme
> olmasın.

---

## 1. Ağırlıklar — süreyi nereye harcıyoruz

Değerlendirme tablosundaki Sosyal YZ ağırlıkları süre dağılımının gerekçesidir:

| Kriter | Ağırlık | Sunumda karşılığı | Süre |
|---|:--:|---|:--:|
| Teknik yeterlilik ve uygulanabilirlik | **%30** | Canlı demo + ölçüm disiplini | ~6 dk |
| Yenilikçilik ve özgünlük | %20 | Bağlam ayrımı, kimlik adı yuvası, cihaz üstü | demo içinde |
| Problemi çözme başarısı | %20 | Problem + etki + düzeltme oranı | ~3 dk |
| Sunum ve prototip kalitesi | %15 | Akıcı demo, hazır görseller, zamanlama | tamamı |
| Kullanıcı deneyimi | %10 | Müdahale merdiveni, "karar senin" | demo içinde |
| İş modeli ve sürdürülebilirlik | %5 | Entegrasyon modeli | ~1 dk |

**Kural:** süre daralırsa demo kısılmaz. İş modeli ve yol haritası kısılır.

---

## 2. Akış — dakika dakika

### 00:00 – 01:30 · Açılış: problem (SLAYT 1–2)

**Slayt 1 — tek cümle, büyük punto:**
> "Silmek, görmüş olmayı geri almaz."

**Söylenecek:**
> "Bugün sosyal medyada hakaret şöyle yönetiliyor: yazılır, yayınlanır,
> biri şikâyet eder, bir moderatör bakar, silinir. Ama o sırada hedef kişi
> o cümleyi çoktan okumuştur."

**Slayt 2 — üç sayı** (kaynaklar raporda: [1] TÜİK, [3] UNFPA–KONDA, [4] LREC):
- Türkiye'de 16–74 yaş internet kullanımı **%92,3**
- Her **5 kişiden 1'i** dijital şiddete maruz kaldığını söylüyor — 18–32 yaşta **3'te 1**
- Türkçe tweet örnekleminde içeriğin yaklaşık **%19'u** saldırgan dil

> "Ve en acı kısmı: tacize uğradığını anlatan kişi — 'bana şerefsiz dedi' —
> mevcut filtrelere takılıyor. Şikâyet eden susturuluyor."

### 01:30 – 02:30 · Çözüm tek cümlede (SLAYT 3)

**Slayt 3 — mimari şeması:** `docs/gorseller/sekil1_mimari.png`

> "Üslup, müdahaleyi yayından SONRAYA değil, yazma ANINA taşıyor. Kullanıcı
> yazarken, telefonun ya da bilgisayarın içinde, internete çıkmadan
> çözümlüyor. Hiçbir şeyi engellemiyor: gerekçesini söylüyor, daha yapıcı
> bir cümle öneriyor, kararı kullanıcıya bırakıyor."

**Burada ağın kapalı olduğunu söyleyin:** "Bu bilgisayarın interneti şu an
kapalı. Göreceğiniz her şey burada, yerelde çalışıyor."

### 02:30 – 07:30 · CANLI DEMO (5 dakika — sunumun kalbi)

Uygulamaya geçin. Sol menü → **Üslup Paneli**.

**① Başlık kartı (10 sn)** — işaret edin:
> "256 sözlük girdisi, 209 örüntü, 671 etiketli örnek. Bu sayılar bir
> slayttan değil, motorun kendisinden sayılıyor."

**② Doğrudan saldırı (60 sn)** — `Doğrudan saldırı` çipine dokunun.
Jüri şunları görecek:
1. "aptalsın" kelimesinin altı dalgalı çizilir, kutu turuncuya döner
2. "Neden uyarıldın?" → hangi ifade, hangi katman, neden
3. "Böyle mi demek istedin?" → **"Bu konuda sana katılmıyorum"**
4. Kutunun altında süre: **birkaç yüz mikrosaniye**
5. Senaryo kartında: **Beklenen: saldırı sayılır · Sonuç: Riskli ✓**

> "Süreye bakın: mikrosaniye. Bir ekran karesi 16 milisaniye; biz onun
> yüzde birkaçını kullanıyoruz. Bu yüzden her tuş vuruşunda çalışıyor."

**"Bunu kullan"a basın.** Öneri kutuya geçer, uyarı kaybolur.

> "Sistem metni kendisi değiştirmedi. Önerdi, gerekçesini yazdı, kararı bana
> bıraktı. Fikir aynı — itiraz duruyor — saldırı gitti."

**③ AYNI KELİME, DÖRT BAĞLAM (90 sn) — sunumun en önemli anı**

Sırayla dokunun: `Olumsuzlama` → `Mağdur anlatısı` → `Öz-ifade`.
Üçünde de sonuç **Temiz ✓**.

> "Dördünde de aynı kelime var: aptal. Bir kelime listesi dördünü de
> işaretler. Üçüncüsüne dikkat: 'Bana aptal dedi, çok üzüldüm.' Bu, tacize
> uğradığını ANLATAN kişi. Bizde bu kişinin uyarı alması yapısal olarak
> imkânsız — yumuşatma bir çarpan değil, bir tavan."

**④ Kimlik adı tetikleyici değil (45 sn)** — `Kimlik beyanı` → Temiz ✓,
sonra `Nefret söylemi` → **Yüksek risk ✓**.

> "'Ben Kürtüm ve bununla gurur duyuyorum' temiz. 'Bütün Suriyeliler
> hırsızdır' yüksek risk. Nefret filtrelerinin en yaygın kusuru korunan
> grubun adını yasaklı kelime yapmaktır — ve korumaya çalıştığı grubu
> susturur. Bizim sözlüğümüzde tek bir kimlik adı yok ve bunu bir test
> koruyor."

**⑤ Küfürsüz düşmanlık + gizleme (40 sn)** — `Küfürsüz düşmanlık`
("Senin gibilerden zaten bu beklenirdi") → işaretlenir; `Gizleme denemesi`
("sen $3r3fsizsin") → işaretlenir.

> "İlkinde tek bir yasaklı kelime yok — saldırı kelimelerde değil,
> dizilişte. İkincisinde kullanıcı filtreden kaçmaya çalışıyor; motor
> rakamları harfe geri çeviriyor."

**⑥ Bağlam karnesi (30 sn)** — aşağı kaydırın → **"12/12 beklendiği gibi"**.

> "On iki senaryonun hepsi burada, her satırda beklenti ve gerçek sonuç yan
> yana. Beklentiyi motoru çalıştırmadan önce yazdık."

**⑦ Canlı gecikme (15 sn)** — altındaki siyah kart:

> "Bu grafik bir animasyon değil: motor şu an bu bilgisayarda elli kez
> çalıştırılıp ölçülüyor."

*(Zaman kalırsa: sol menü → Ana Sayfa → "Gündem Notu" maç gönderisi →
yanıt kutusuna **elle** "sen tam bir aptalsın" yazın — katmanın gerçek bir
yanıt kutusunda da aynı çalıştığını gösterir.)*

### 07:30 – 09:30 · Teknik derinlik ve dürüstlük (SLAYT 4–5)

**Slayt 4 — işlem hattı** (Sistem detayları ekranının görüntüsü:
`masaustu_11_sistem_detaylari.png`): normalizasyon → sözlük → örüntü →
nefret → gönderge → bağlam → öneri.

**Slayt 5 — ölçüm tablosu.** Söylenecek:
> "Geliştirme kümesinde kesinlik %100, duyarlılık %99. Bu bir genelleme
> kanıtı DEĞİL — kümeyi de örüntüleri de biz yazdık. Bu yüzden her
> onarımdan sonra motora hiç göstermediğimiz yeni bir küme yazdık. Beş ayrık
> kümenin beşi de 'yandı': motor her birine bakılarak düzeltildi. Raporladığımız
> sayı en iyisi değil, son tam ilk geçiş: **kesinlik %90,5, duyarlılık %54,3.**"
>
> "Duyarlılık düşük görünüyor, çünkü ölçümü ayrıştırdık: yazdığımız bir
> yapının hiç görülmemiş örneklerinde %90 yakalıyoruz; hiç yazmadığımız
> deyimlerde yakalayamıyoruz. Bu, kural tabanlı bir katmanın tavanı ve yol
> haritamızın gerekçesi."

> *Jüri bu bölümü sever. Ölçmeyi bilen bir ekip olduğunuzu gösteren tek şey,
> kötü sayıyı da göstermenizdir.*

### 09:30 – 11:00 · Etki ve mahremiyet (SLAYT 6 + uygulama)

Uygulamada sol menü → **Topluluk Sağlığı**.

> "Platform metni değil davranışı görüyor: uyarı karşısında kullanıcı ne
> yaptı — öneriyi kabul etti mi, kendi düzeltti mi, yine de gönderdi mi.
> Ürünün başarı ölçütü bu: **düzeltme oranı**. Sinyalde tek bir metin alanı
> yok ve bir kategoride 5'ten az gözlem varsa sayı hiç gösterilmiyor."

### 11:00 – 12:30 · Model, iş modeli, yol haritası (SLAYT 7)

- **Neden LLM yok:** yazıldı, ölçüldü, kaldırıldı — metni cihazdan çıkarıyordu.
- **Neden sadece kural değil:** denetimli bir model eğittik; kural motorunun
  kaçırdığı hiçbir örneği yakalamadı, altı yanlış pozitif üretti. Uygulamada
  yalnızca "ikinci görüş" olarak duruyor — temiz/işaretli kararına dokunamaz.
- **İş modeli:** katman bir kütüphane; mesajlaşma, forum, yorum alanı,
  kurum içi iletişim — Türkçe metin girişi olan her yüzeye takılır. Sunucu yok,
  API anahtarı yok, çıkarım maliyeti yok.
- **Yol haritası:** ikinci etiketleyici (kappa), kullanılabilirlik testi,
  Türkçe önceden eğitilmiş model ile deyim uzayı.

### 12:30 – 13:30 · Kapanış (SLAYT 8)

**Slayt 8 — tek cümle:**
> "Ceza değil, ayna. Yazılmadan önce, cihazın içinde, kararı sana bırakarak."

> "Bu sunumun tamamı internetsiz yapıldı."

### 13:30 – 15:00 · Tampon / soru

Soru-cevap ayrıysa bu 90 saniye gecikmelere karşı tampondur. Sunumu **13:30'da
bitirmeyi** hedefleyin.

---

## 3. Beklenen sorular — hazır cevaplar

**"Duyarlılık %54 düşük değil mi?"**
> Evet, gizlemiyoruz. O sayı "motor ne kadar iyi" değil, "kaç yapı ailesi
> yazıldı" sorusunun cevabı. Yazılmış bir ailenin yeni örneklerinde %90;
> hiç yazılmamış deyimlerde çok düşük. Ürünün hedefi F0.5 — yanlış pozitif,
> yanlış negatiften pahalı: mağduru susturmaktansa bir hakareti kaçırmayı
> tercih ediyoruz.

**"Bu bir yapay zekâ mı, yoksa kelime listesi mi?"**
> Kelime listesi değil: aynı kelime dört bağlamda dört farklı sonuç veriyor
> (demodaki dörtlü). Türkçe biçimbilim, bağlam çözümleme, edimbilimsel
> örüntüler ve gönderge çözümlemesi var. Denetimli bir model de eğitip
> ölçtük; kural motorunu geçemedi. Veri büyüdükçe öğrenen model yol
> haritamızda.

**"Neden bir dil modeli (ChatGPT vb.) kullanmıyorsunuz?"**
> Kullandık, ölçtük, kaldırdık. Metni cihazdan çıkarıyordu, jürinin
> çalıştıramayacağı bir bağımlılık getiriyordu ve katkısı yalnızca öneri
> akıcılığıydı.

**"Kullanıcı uyarıyı görmezden gönderirse?"**
> Gönderebilir — sistem hiçbir şeyi engellemez. Uyarıya rağmen gönderimde
> 1,5 saniyelik, nedeni yazılı bir düşünme payı var; en yüksek basamakta
> (tehdit gibi) ayrıca bir onay istenir. Rozetleme ya da ceza yok;
> cezalandırılan kullanıcı özelliği kapatır.

**"Kaç kişi denedi? Hakemler arası uyum?"**
> Kullanılabilirlik testi ve kappa henüz yapılmadı; açıkça yazıyoruz.
> Protokol ve araçlar hazır (`docs/10`, `bin/kappa.dart`), eksik olan
> katılımcı ve ikinci etiketleyici.

**"Sayıyı yeniden üretebilir miyiz?"**
> `cd packages/civility_core && dart run bin/evaluate.dart --hepsi` — tek komut.

**"Bu arayüz NSosyal'in kopyası mı?"**
> Hayır. Logo, işaret ve tipografi kopyalanmadı. Katmanın bir platforma
> düştüğünde nasıl duracağını göstermek için yerleşim düzeyinde bir kabuk;
> katman platformdan bağımsız.

---

## 4. Riskler ve kaçış yolları

| Risk | Kaçış |
|---|---|
| Projektör/dizüstü bağlanmıyor | Slayttaki yedek videolar (§6) demoyu taşır |
| Uygulama açılmıyor | `SUNUMU_BASLAT.bat` penceresindeki hatayı okuyun; derleme yoksa yedek telefondaki APK |
| Klavyede yazamıyorsunuz | Senaryo **çipleri** tek dokunuşla metni yükler — elle yazmak gerekmez |
| Süre daralıyor | §2 sırasına göre 11:00–12:30 bloğunu tek slayta indirin; demo kısılmaz |
| Jüri kodu görmek isterse | Depo bağlantısı rapordadır; motor saf Dart, tek komutla test edilir |

---

## 5. SÖYLENMEYECEKLER

- **"Yapay zekâmız %99 doğrulukla çalışıyor."** Geliştirme kümesi sayısıdır,
  genelleme kanıtı değildir. Raporun en güçlü bölümünü tek cümlede çürütür.
- **"Nefret söylemini engelliyoruz."** Sistem hiçbir şeyi engellemez; önerir.
- **"Federated learning / sunucuda eğitim yapıyoruz."** Yapmıyoruz. Önceki bir
  sürümdeki sahte gradyan gönderen düğme 13 Eylül'de kaldırıldı.
- **"Akıştaki veriler gerçek."** Kurgudur.
- Ölçülmemiş bir şeyi ölçülmüş gibi anlatmak. Kullanılabilirlik testi ve
  kappa **yapılmadı**; sorulursa olduğu gibi söyleyin.

---

## 6. Yedek videolar — nasıl çekilir

Windows'ta ek program gerekmez: uygulama penceresi açıkken **Win + Alt + R**
kaydı başlatır/durdurur (Xbox Game Bar). Kayıtlar `Videolar\Yakalamalar`
klasörüne düşer.

Dört kısa klip yeterli (her biri ≤ 20 sn, sessiz):

| Klip | İçerik | Slayt |
|---|---|---|
| 1 | Yanıt kutusuna elle "sen tam bir aptalsın" yazmak → uyarı → "Bunu kullan" | Demo yedeği ② |
| 2 | Dört çip sırayla: Doğrudan → Olumsuzlama → Mağdur → Öz-ifade | Demo yedeği ③ |
| 3 | Kimlik beyanı → Nefret söylemi | Demo yedeği ④ |
| 4 | Bağlam karnesine kaydırma, "12/12" | Demo yedeği ⑥ |

Çekimden önce: açık tema, Edge yakınlaştırma %110, fare imleci görünür.

---

## 7. Ekran görüntüleri — nasıl üretilir

```bash
cd mobile
flutter test tool/ekran_goruntusu_test.dart
```

`docs/gorseller/ekranlar/` altına 17 kare üretir (2× çözünürlük, gerçek
yazı tipleri, motorun gerçek çıktısı). Slaytlar için önerilenler:

| Dosya | Nerede |
|---|---|
| `masaustu_03_dogrudan_saldiri.png` | Demo özeti / kapak |
| `masaustu_04_magdur_anlatisi.png` + `_05_olumsuzlama` | "Aynı kelime, farklı bağlam" |
| `masaustu_07_kimlik_beyani.png` + `_08_nefret_soylemi` | Nefret söylemi slaytı |
| `masaustu_10_panel_tam_sayfa.png` | Bağlam karnesi (uzun görüntü, kırpın) |
| `masaustu_11_sistem_detaylari.png` | Teknik slayt |
| `masaustu_12_topluluk.png` | Etki slaytı |
| `telefon_03_canli_uyari.png` | "Telefonda da aynı katman" |

---

## 8. Sayı kartı — bugün doğrulandı (13 Eylül 2026)

| Sayı | Değer | Kaynak |
|---|---|---|
| Sözlük girdisi | 256 | çalışma anında sayılır |
| Örüntü ve deyim | 209 | çalışma anında sayılır |
| Etiketli örnek | 671 (6 küme) | çalışma anında sayılır |
| Tipik çözümleme (p50) | 357 µs | `bin/benchmark.dart`, AOT |
| En kötü %1 (p99) | 2.212 µs · kare bütçesinin %13,8'i | aynı |
| Son tam ilk geçiş (İP-22) | kesinlik %90,5 · duyarlılık %54,3 · F1 %67,9 | docs/14 §5 |
| İP-27 ilk geçiş | 60 saldırgan örnekten 31 kaçak — sonra yandı | idiom_patterns.dart |
| Geliştirme kümesi | kesinlik %100 · duyarlılık %99,2 | `evaluate.dart` |
| Katman katkısı | duyarlılık %45,1 → %99,2, kesinlik kaybı 0 | `evaluate.dart --karsilastir` |
| Demo senaryoları | 12/12 beklendiği gibi | Üslup Paneli → Bağlam karnesi |
| Otomatik testler | 294 (motor) + 21 (arayüz) | `dart test`, `flutter test` |
