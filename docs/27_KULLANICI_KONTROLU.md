# Kullanıcı Kontrolü — Ayarlar ve "Bu Uyarı Yanlış"

**Tarih:** 15 Eylül 2026 · **Kapsam:** `packages/civility_core`, `mobile`
**Davranış değişikliği:** motorda yok; kullanıcıya yansımada var (varsayılan ayarda yok)

## 1. Bulgu

Ürünün ilk ilkesi "karar kullanıcıda". Ölçülen hâliyle bu iddia yarımdı:
kullanıcı yalnızca **tek bir metnin** kararını verebiliyordu — öneriyi kabul
et, uyarıya rağmen gönder, vazgeç. Katmanın kendisi hakkında hiçbir sözü
yoktu.

İki somut sonucu vardı:

| Durum | Yaşanan |
|---|---|
| Arkadaşlarıyla argo konuşan kullanıcı | Her "lan"da uyarı; katmanı kapatmanın yolu yok |
| Kendi üslubunu sıkı denetlemek isteyen kullanıcı | "Dikkat" basamağında yalnızca kenar rengi; gerekçe göremiyor |
| Yanlış uyarı alan kullanıcı | İtiraz edecek yer yok; uyarı ekranda kalıyor |

Üçüncüsü ayrıca bir **ölçüm boşluğuydu**. Kesinlik iddiası (%100, İP-29)
laboratuvarda, etiketli kümelerde ölçülüyor. Sahada kaç uyarının yanlış
bulunduğunu söyleyen hiçbir sayı yoktu.

## 2. Üç kesin kural

Bu kurallar `packages/civility_core/lib/src/policy/uslup_ayarlari.dart`
dosyasının başında da yazılıdır ve testle kilitlenmiştir.

**1. Ayarlar motoru değiştirmez.** Çözümleme her zaman aynıdır; ayar yalnızca
çözümlemenin kullanıcıya nasıl yansıyacağını belirler. Raporlanan her ölçüm
bu yüzden geçerliliğini korur. Varsayılan ayarda `MudahalePolitikasi.uygula`
çözümlemenin **aynı örneğini** döndürür.

**2. Başkalarını koruyan uyarılar tek tek kapatılamaz.** Susturulabilir
kategoriler yalnızca `kufur` ve `asagilama`: bunlar çoğunlukla yazanın kendi
üslup tercihidir. `tehdit`, `nefretSoylemi`, `taciz` ve `hakaret` başka bir
insanı hedef alır; bunlara "sessize al" düğmesi koymak, ürünü hedef alınan
kişiye karşı çalışan bir araca çevirirdi.

Hiç uyarı istemeyen kullanıcı katmanı **bütünüyle** kapatabilir — seçim yine
onundur. Fark şudur: katmanı kapatmak bilinçli ve görünür bir karardır
(yazım kutusunda "Üslup kapalı" yazar), tek tek susturma ise zamanla
unutulan sessiz bir boşluk bırakırdı.

**3. Destek kartı bir uyarı değildir.** Kendine zarar ifadesinde gösterilen
destek kartı katman kapalıyken de görünür (docs/20, D4). Yargılamaz,
yalnızca yardım hattını hatırlatır.

## 3. Ayarlar

### Hassasiyet

Basamak eşikleri değil, **basamakların ne göstereceği** değişir. Motorun
toksisite skoru aynıdır.

| Ayar | Temiz | Dikkat | Riskli | Yüksek |
|---|---|---|---|---|
| Yalnızca ağır ifadeler | < 0,70 | — | — | ≥ 0,70 |
| **Dengeli** (varsayılan, ölçülen) | < 0,15 | 0,15–0,40 | 0,40–0,70 | ≥ 0,70 |
| Hassas | < 0,15 | — | 0,15–0,70 | ≥ 0,70 |

"Yalnızca ağır" ayarında Riskli bir metin temiz görünür. Bu durumda bulgular
da gizlenir: vurgulamayı ya da gerekçe panelini bırakmak ayarı delmek olurdu.

### Kategori susturma

`kufur` ve `asagilama` uyarıları tek tek kapatılabilir. Susturulan kategorinin
bulguları çıkarılır ve toksisite kalan bulgulardan **motorla aynı yöntemle**
(noisy-OR: 1 − Π(1 − sᵢ)) yeniden hesaplanır. Ayrı bir formül kullanmak, aynı
metnin iki farklı skor almasına yol açardı.

Depolamaya elle "tehdit" yazılsa bile etkisi olmaz: `UslupAyarlari.fromMap`
ve `gecerliSusturulanlar` susturulamayan adları ayıklar.

### Klavye ile ortak ayar

Klavye servisi kendi Flutter motorunda çalışır; Dart tarafındaki bellek
paylaşılamaz. Ayar, uygulama ile klavyenin ortak kullandığı yerel
`SharedPreferences` dosyasına yazılır (`MainActivity`, kanal `uslup/ayarlar`)
ve her çözümleme isteğinde klavyeden geri taşınır. Yazılan şey yalnızca üç
alanlık ayardır: metin, geçmiş ya da kullanım kaydı değil.

### Ayarın uygulanmadığı tek yer

Üslup panelindeki **deneme kutusu** ayarı izlemez. O kutu motorun ölçülen
davranışını gösterir; jüriye ve kullanıcıya "katman ne yapıyor" sorusunun
cevabıdır. Kişisel ayar oraya karışsaydı, kullanıcının kendi tercihi ürünün
kanıtını bozardı. Yayın yüzeyleri (gönderi, yanıt, biyografi) ayarı izler.

## 4. "Bu uyarı yanlış"

### Ne olur

Kullanıcı gerekçe panelindeki düğmeye basar. Uyarı **o metin için** gizlenir:
vurgu kalkar, öneri kapanır, yüksek riskte onay diyaloğu ve düşünme payı
devreye girmez — sistem zaten hiçbir basamakta göndermeyi engellemiyordu,
itirazdan sonra sürtünme de anlamsızdır.

Metin değişirse katman normal çalışmasına döner: itiraz, itiraz edilen
metne aittir.

### Ne kaydedilir

Gönderim anında topluluk sinyaline **tek bir evet/hayır** girer:
`CommunitySignal.yanlisAlarmBildirildi`.

Hangi kelimenin yanlış işaretlendiğini bilmek onarım için çok değerli
olurdu — ve tam da bu yüzden yazılmadı. O kelime kullanıcının **metninden**
bir parçadır. Sözlük teriminin ya da eşleşen aralığın taşınması, "metin
cihazdan çıkmaz" iddiasını parça parça delerdi. Kategori zaten sinyalin
`category` alanındadır; daha fazlası taşınmaz.

Uyarı olmayan bir çözümlemeye yanlış alarm işareti konamaz
(`CommunitySignal.fromAnalysis` çağıranın hatasını sessizce düzeltir).

### Panelde nasıl görünür

| Alan | Kural |
|---|---|
| `falseAlarmReports` | k-anonimlik altında (k = 5); eşiğin altındaysa `null` |
| `falseAlarmByCategory` | kategori başına ayrı eşik |
| `falseAlarmRate` | bildirim / müdahale |
| `validInterventions` | müdahale − bildirim |
| `revisionRate` | davranış değişikliği / **validInterventions** |

Son satır bu işin özüdür: yanlış bulunan bir uyarıyı dikkate almadan
göndermek "uyarıyı görmezden gelmek" değildir. Paydada bırakmak, katmanın
kendi hatasını kullanıcının inadı gibi göstermesi olurdu.

Eşiğin altındaki bildirimler paydadan da çıkarılmaz — çıkarılsaydı
`interventions`, `behaviourChanges` ve `revisionRate` üzerinden gizlenen
sayı geri hesaplanabilirdi.

### Katman kapalıyken ölçüm

Katman kapalıyken gönderim topluluk ölçümüne **hiç girmez**. Girseydi her
gönderim "temiz" görünür ve paneldeki müdahale oranını sahte biçimde
düşürürdü (`ComposerResult.olcumeDahil`).

## 5. Ne sınanıyor

| Test | İddia |
|---|---|
| `civility_core/test/uslup_ayarlari_test.dart` | Varsayılan ayar bütün etiketli kümelerde çözümlemenin aynı örneğini döndürür |
| ” | Susturulamayan kategoriler hiçbir yoldan susturulamaz (kurucu, `fromMap`, `copyWith`) |
| ” | Her hassasiyet ayarı söylediği şeyi yapar |
| `civility_core/test/community_health_test.dart` | Eşik altındaki bildirim açılmaz ve geri hesaplanamaz |
| ” | Eşiği geçen bildirim düzeltme oranının paydasından çıkar |
| ” | Uyarısız çözümlemeye yanlış alarm işareti konamaz |
| `mobile/test/uslup_ayarlari_test.dart` | Ayar ekranındaki seçim yazım kutusunda uygulanır |
| ” | İtiraz uyarıyı gizler, metin değişince katman geri döner |
| ” | Kapalı katmanda gönderim ölçüme girmez |

## 6. Bilinen sınır

Yanlış alarm bildirimi **yalnızca sayıdır**. Hangi ifadenin yanlış
işaretlendiği bilinmediği için bu veri doğrudan bir onarıma dönüşemez;
yalnızca "hangi katman sahada gürültü yapıyor" sorusuna kategori düzeyinde
cevap verir. Onarım yine etiketli küme toplamayı gerektirir.

Bu bilinçli bir takas: cihazdan metin çıkarmamak, onarımı hızlandırmaktan
önemli sayıldı.
