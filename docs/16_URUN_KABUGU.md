# Ürün Kabuğu — Katmanın Yüzeyleri · İP-25

**Tarih:** 9 Eylül 2026
**Bağlam:** Teknik rapor 95 puanla geçti; 14 Eylül final sunumu teslimi,
20 Eylül canlı jüri sunumu.
**Kapsam:** Üslup katmanının, gerçek bir sosyal platform kabuğunun içine
yerleştirilmesi.

> **Bu belge neden var.** Teknik rapor 24 Ağustos'ta teslim edildi ve
> değiştirilmedi. Aşağıdaki değişiklikler teslimden **sonra** yapılmıştır.
> Raporun hiçbir sayısını geçersiz kılmaz; raporun bir CÜMLESİNİ ise ilk kez
> gerçekten doğru hâle getirir — "katman, Türkçe metin girişi olan herhangi
> bir yüzeye taşınabilir".

---

## 0. Yönetici özeti

1. **Katman artık tek bir demo ekranında değil, bir platformun içinde
   çalışıyor.** Akış, gönderi kutusu, yorum kutusu, keşfet, bildirimler ve
   profil ekranları eklendi. Katman bunların *her* metin giriş noktasında
   aynı bileşenle çalışıyor.
2. **"Her metin girişi katmandan geçer" artık bir iddia değil, bir test.**
   `mobile/test/kapsam_degismezi_test.dart`, `lib/` altındaki her ham
   `TextField` kullanımını sayar ve izinli listede olmayan bir tane bulursa
   kırılır.
3. **"Sıfır ağ çağrısı" da artık bir test.** Aynı dosya `Image.network`,
   `NetworkImage`, `HttpClient`, `WebSocket` ve `package:http` kalıplarını
   arar. Tek bir avatar görselini indirmek bu iddiayı çürütürdü.
4. **Raporun offset haritası gerekçesi ilk kez gerçekleşti.** Rapor §2.2,
   normalizasyonun her karakterin orijinal indeksini sakladığını ve bunun
   *tek* gerekçesinin "doğru karakterlerin altını çizebilmek" olduğunu
   söylüyordu. Önceki arayüz altını çizmiyordu — bulguları yalnızca aşağıda
   listeliyordu. Artık çiziyor.
5. **Bir içerik çelişkisi düzeltildi.** `about_screen.dart`, 4 gün sonra
   kasıtlı olarak kaldırılan bulut yeniden yazma servisinden söz etmeye devam
   ediyordu — üstelik hemen üstündeki listede aynı servis "kapsam dışı"
   yazarken.

---

## 1. Kapsam kararı — neden bu, 24 Ağustos kararıyla çelişmiyor

24 Ağustos'ta devralınan **mesajlaşma arayüzü** (sohbet, arama, kişiler,
kimlik doğrulama, ayarlar) üründen tamamen silindi. Rapor §1.2 bu kararı
"bir eksiklik değil, bir önceliklendirme" olarak kaydetti ve kapsamı bir
arayüz testiyle kilitledi.

9 Eylül'de eklenen şey farklıdır ve ayrım tek cümleyle yazılabilir:

> Silinen şey, ürünün **yerine geçmeye çalışan** bir uygulamaydı.
> Eklenen şey, ürünün **içine takıldığı** bir platform.

Gerekçe ürünseldir:

| Sorun | Kabuk olmadan | Kabuk ile |
|---|---|---|
| Katman nereye takılıyor? | Anlatılır | Gösterilir |
| Saldırgan dil nerede üretilir? | Boş bir kutuda (gerçekçi değil) | Bir gönderiye **yanıt** olarak |
| Katman kaç yüzeyde çalışıyor? | Bir | Gönderi, yanıt, biyografi |
| "Platforma taşınabilir" iddiası | Beyan | Uygulanmış |

İkinci satır en önemlisidir. İnsan boş bir kutuya oturup hakaret yazmaz;
birinin söylediği bir şeye sinirlenip yazar. Katman yalnızca gönderi
kutusunda çalışsaydı, hedeflediği anın büyük bölümünü ıskalardı.

**Kabuğun sınırı:** katmana yüzey olmayan hiçbir şey eklenmez. Mesajlaşma,
canlı yayın, ödeme, bildirim ayarları — hiçbiri yok ve bu, hem davranış
testiyle (`widget_test.dart`) hem kaynak testiyle (`kapsam_degismezi_test.dart`)
korunuyor.

---

## 2. Eklenen yüzeyler

| Ekran | Dosya | Katman burada çalışıyor mu |
|---|---|---|
| Akış (Akış / Medya sekmeleri) | `presentation/feed/feed_screen.dart` | — (okuma yüzeyi) |
| Gönderi kartı | `presentation/feed/post_card.dart` | — |
| Gönderi ayrıntısı + yanıtlar | `presentation/feed/post_detail_screen.dart` | **Evet** (yanıt kutusu) |
| Yeni gönderi | `presentation/compose/compose_screen.dart` | **Evet** |
| **Yazım kutusu (ortak bileşen)** | `presentation/compose/civility_composer.dart` | **Katmanın kendisi** |
| Keşfet (arama + gündem) | `presentation/explore/explore_screen.dart` | Hayır — gerekçe §4 |
| Bildirimler | `presentation/notifications/notifications_screen.dart` | — |
| Profil + Üslup özeti | `presentation/profile/profile_screen.dart` | — |
| Üslup paneli (ölçüm vitrini) | `presentation/uslup/uslup_panel_screen.dart` | **Evet** (deneme kutusu) |
| Topluluk sağlığı | `presentation/community/community_health_screen.dart` | — (mevcuttu) |

Veri katmanı: `core/social/social_models.dart`, `social_store.dart`,
`seed_data.dart`. Ağ yok, veri tabanı yok, disk yok — bellekte durur ve
uygulama kapanınca kaybolur.

### Kaldırılanlar

- `presentation/civility/civility_composer_screen.dart` — rolü ikiye
  ayrıldı: canlı çözümleme `CivilityComposer` bileşenine, ölçüm vitrini
  `UslupPanelScreen`e geçti. Aynı işi yapan iki kod yolu bırakmak, birinin
  test edilmediği için sessizce eskimesiyle biterdi.
- `AppTheme` içindeki 22 sabit (`primaryRed`, `splashGradient`,
  `surfaceMid`…) — devralınan giriş akışından kalmıştı, uygulama genelinde
  tek bir çağrı yeri yoktu.
- `main.dart` içindeki `@Deprecated typedef MyApp`.

---

## 3. Tek bileşen ilkesi

Gönderi kutusu, yorum kutusu ve Üslup panelindeki deneme kutusu **aynı**
`CivilityComposer` bileşenidir. Aralarındaki fark yalnızca yerleşimdir
(avatar var/yok, araç çubuğu var/yok, satır sayısı) ve `onSubmit`
geri çağrısının verilip verilmediğidir.

Çözümleme, müdahale merdiveni, gerekçe paneli, yeniden yazma önerisi ve
ölçüm sinyali **birebir aynı koddan** geçer. Yorum kutusuna ayrı bir kod
yolu yazılsaydı, o yol test edilmediği için bir sonraki değişiklikte
sessizce eskirdi.

### Müdahale merdiveni

| Seviye | Ne olur |
|---|---|
| `temiz` | Hiçbir şey. Kesinti yok. |
| `dikkat` | Yalnızca kenarlık rengi değişir. Metin, panel, ses yok. |
| `riskli` | Gerekçe paneli + yeniden yazma önerisi açılır. |
| `yüksek` | Ek olarak gönderim öncesi onay diyaloğu. |

Hiçbir basamakta gönderim engellenmez. Onay diyaloğunda "Yine de gönder"
seçeneği vardır ve **vurgulanmaz**; birincil düğme "Vazgeç, düzelteyim"dir.
Sistem yönlendirir, karar vermez.

### Ölçüm sinyali

Kutu gönderim anında dört sonuçtan birini üretir:

```
temiz gönderim · öneriyi kabul etti · kendi düzeltti · uyarıya rağmen gönderdi
```

Bu dörtlü, topluluk sağlığı panelinin birincil göstergesi olan **düzeltme
oranını** doğrudan besler. Rapor §4.1'deki duyarlılık modelinin bilinmeyen
girdisi (`r`) tam olarak budur; ürün sahaya çıktığında varsayım olmaktan
çıkıp ölçüme dönüşür.

Giden sinyalde **metin yoktur** — `CommunitySignal` sınıfının tek bir metin
alanı bulunmaz ve bu, çekirdek pakette yapısal bir testle korunur.

---

## 4. Arama kutusu neden katmandan geçmiyor

`explore_screen.dart` ham bir `TextField` kullanır ve bu, kapsam testinde
**gerekçesiyle** izinli listededir.

Arama kutusuna yazılan metin yayımlanmaz, kimseye ulaşmaz ve bir başkasına
zarar veremez. Oraya müdahale etmek, kullanıcıyı hiçbir koruma sağlamadan
kısıtlamak olurdu — ürünün "sansür değil" iddiasıyla çelişirdi.

Ayrım kuralı şudur: **katman, kullanıcının başkalarına ulaşacak metin
yazdığı her yüzeyde çalışır.** Kendine yazdığı yerlerde çalışmaz.

---

## 5. Marka değişikliği ve kontrast borcu

Palet, devralınan "Türkiye Mesajlaşma" kırmızısından (#C8102E) ev sahibi
platformun görsel diline taşındı: soğuk nötr griler, mavi aksan (#2A63E8),
camgöbeği→mavi gradyan.

**Ev sahibi platformun logosu, işaretleri ve tipografisi kopyalanmamıştır.**
Alınan şey yerleşim ve renk ailesi düzeyindeki tasarım dilidir. Kopyalansaydı
prototip bir entegrasyon önerisi değil, bir taklit olurdu.

Renk değiştirmenin bir bedeli var ve o bedel ödenmek zorunda:
`tool/erisilebilirlik_denetimi.dart` paleti **kaynak olarak** okur ve WCAG
2.1 eşiklerine karşı ölçer. Yeni değerler elle hesaplanarak seçildi
(brandOn/brand 5,19:1 · inkSecondary/zemin 5,48:1 · inkTertiary/yüzey
4,57:1 · borderStrong/yüzey 3,61:1), ama **elle hesap bir ölçüm değildir**.

→ Doğrulama durumu §7'de.

---

## 6. Bulguların metin içinde işaretlenmesi

`core/civility/civility_text_controller.dart`, `TextEditingController`ı
genişletir ve `buildTextSpan` içinde motorun ürettiği
`ToxicityFinding.start` / `.end` aralıklarını dalgalı alt çizgiyle işaretler.
Renk şiddete göre seçilir (bilgi / uyarı / tehlike).

Bu, raporun bir gerekçesini kapatır. Rapor §2.2:

> "Her normalize karakterin orijinal metindeki indeksi bir offset haritasında
> saklanır ve kullanıcıya *şu ifade sorunlu* diye doğru karakterlerin altını
> çizebilmenin tek yolu budur."

Önceki arayüzde o harita hiçbir yerde kullanılmıyordu; bulgular yalnızca
kutunun altında listeleniyordu. Gerekçe doğruydu, karşılığı yoktu.

İki ayrıntı:

- **IME birleştirmesi sırasında işaretleme kapanır.** Flutter'ın kendi
  altı çizili gösterimiyle üst üste binince imleç konumu bozuluyordu.
- **Aralıklar konuma göre sıralanır ve çakışanlar elenir.** Motor
  çakışmaları zaten temizliyor ama sonucu ŞİDDETE göre sıralı veriyor;
  `substring` çağrıları artan konum ister.

---

## 7. Doğrulama — 9 Eylül 2026, Flutter 3.47.2 · Dart 3.13.2

Projenin kendi dersi burada geçerli — 25 Ağustos kaydı: *"Beş ayrık küme ve
258 saf Dart testi, mobil katmandaki tek satırlık bir sözdizim hatasını
göremez."* Bu yüzden aşağıdakiler yazıldıktan sonra değil, **yazılırken**
çalıştırıldı ve sonuçları buraya olduğu gibi geçirildi.

| Denetim | Sonuç |
|---|---|
| `dart test` (çekirdek) | **258 test geçti** — gerileme yok |
| `dart run bin/evaluate.dart --genelleme3` | Kesinlik %100,0 · duyarlılık %54,3 · F1 %70,4 · F0.5 %85,6 — **değişmedi** |
| `dart run tool/erisilebilirlik_denetimi.dart` | **30/30 çift** WCAG 2.1 AA eşiğini geçti |
| `flutter analyze` | **Temiz** — "No issues found" |
| `flutter test` | **20 test geçti** |

Motor sayılarının değişmemesi beklenen sonuçtu: bu iş paketinde
`packages/civility_core` içinde tek satır kod değiştirilmedi (yalnızca
`bin/evaluate.dart`ın ekrana yazdığı üç bayat cümle düzeltildi — §7.2).

### 7.1 Yeni paletin kontrast borcu kapandı

§5'te elle hesaplanan değerler ölçümle doğrulandı:

| Çift | Hesaplanan | Ölçülen | Eşik |
|---|:--:|:--:|:--:|
| Marka üstü metin (beyaz / #2A63E8) | 5,19 | **5,19** | 4,5 |
| İkincil metin / zemin | 5,48 | **5,48** | 4,5 |
| Üçüncül metin / yüzey | 4,57 | **4,57** | 4,5 |
| Etkileşimli kenarlık / yüzey | 3,61 | **3,61** | 3,0 |

En dar geçen çift: **uyarı rengi / yüzey, 3,19:1** (eşik 3,0). Bu, marka
değişikliğinden önce de böyleydi — turuncu uyarı rengi beyaz üzerinde
zaten sınıra yakındır. Kayıt altındadır; daha koyu bir turuncu, uyarı ile
tehlike arasındaki görsel ayrımı zayıflatırdı.

### 7.2 Ölçüm aracında bulunan üç bayat cümle

`bin/evaluate.dart`, üç ayrı yerde "tek geçerli genelleme ölçümü budur"
yazıyordu — üçünde de farklı kümeyi kastederek. İkisi bayattı: o kümeler
sonradan onarımlarda kullanılıp **yanmıştı**. Jüri bu aracı çalıştırdığında
birbiriyle çelişen üç cümle okuyacaktı. Düzeltildi; her yanmış küme artık
kendi ilk (ve tek geçerli) ölçümünü ve neden yandığını yazıyor.

### 7.3 Arayüz testinin ürün değeri

`flutter test` yalnızca "ekran açılıyor mu" demiyor. Dört testi ürünün
merkezî vaadini **gerçek arayüz üzerinden** sınıyor:

| Girdi | Beklenen | Sonuç |
|---|---|---|
| "sen tam bir aptalsın" | gerekçeli uyarı | geçti |
| "Bana 'aptal' dedi, çok üzüldüm" | **uyarı YOK** | geçti |
| "Ben Kürtüm ve bununla gurur duyuyorum" | **uyarı YOK** | geçti |
| "Bu karar bence tamamen hatalı ve geri alınmalı" | **uyarı YOK** | geçti |

Çekirdek motor bunları zaten 258 testle koruyor. Buradaki fark şu: bu
testler motoru değil, **motorun arayüze bağlı olduğunu** sınar. Katmanın
bağlantısı koparsa çekirdek testleri yeşil kalır ve kimse fark etmez.

---

## 8. Açık kalanlar

| İş | Durum | Engel |
|---|---|---|
| İP-14 · Kullanılabilirlik testi (5 katılımcı) | Yapılmadı | İnsan katılımcı; protokol hazır (`docs/10`) |
| İP-15 · Cohen's kappa | Yapılmadı | İkinci etiketleyici; araçlar hazır |
| İP-16 · Ekran okuyucu denetimi | Yapılmadı | Gerçek cihazda TalkBack/VoiceOver oturumu |
| İP-18 · Demo videosu | Yapılmadı | Kabuk hazır; derleme engeli kalkınca çekilebilir |
| İP-25 · Kabuk doğrulaması | **Bu belgenin §7'si** | Flutter kurulumu |

### Ölçülmemiş olan ne

Kabuk **ölçülmemiştir ve ölçülmüş gibi sunulmamalıdır**. Akıştaki hesaplar,
gönderiler ve etkileşim sayıları kurgudur; hiçbiri bir iddia taşımaz.
Ölçülen, test edilen ve raporlanan tek şey `civility_core`tur:

**İP-22 ayrık küme · 65 örnek · kesinlik %90,5 · duyarlılık %54,3 ·
F1 %67,9 · F0.5 %79,8.**

Kabuğun işi bu sayıyı büyütmek değil, katmanın nereye takıldığını
göstermektir.
