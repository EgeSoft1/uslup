# LLM Yeniden Yazma Servisi — Mimari

**Durum:** Çalışıyor · **Tarih:** 1 Ağustos 2026
**Kaynak:** `server/` · **Ortak çekirdek:** `packages/civility_core/`

Bu belge teknik raporun "Sistem Mimarisi" ve "Yöntem" bölümlerine kaynaklık
eder.

---

## 1. Depo yapısı — neden değişti

Nezaket motoru `mobile/lib/ai/` altındaydı. Saf Dart olduğu (tek bir Flutter
importu içermediği) doğrulandıktan sonra bağımsız bir pakete taşındı:

```
packages/civility_core/     ← saf Dart, sıfır bağımlılık, 101 test
        │
        ├──► mobile/        ← Flutter uygulaması (cihaz üstü, çevrimdışı)
        └──► server/        ← Dart HTTP servisi (LLM doğrulaması)
```

Bu bir düzenleme tercihi değil, **ürün gerekliliğidir**. Motorun iki yerde
çalışabilmesi, sonraki bölümdeki doğrulama katmanının ön koşuludur.

`civility_core`'un hiçbir bağımlılığı yoktur. "Cihaz üzerinde çalışır" ve
"denetlenebilir" iddialarının teknik dayanağı budur: motorun davranışını
etkileyen üçüncü taraf kod yoktur.

---

## 2. Üç kademeli yeniden yazma

| Kademe | Nerede | Gecikme | Ağ | Ne zaman |
|---|---|---|---|---|
| 1. Tespit | Cihaz | ~174 µs | Yok | Her tuş vuruşunda |
| 2. Yerel yeniden yazım | Cihaz | ~0 ms | Yok | Risk tespit edilince |
| 3. LLM yeniden yazım | Sunucu | ~1 sn | **Var** | **Yalnızca kullanıcı isterse** |

Kademe 3 isteğe bağlıdır. Sunucu kapalıyken, ağ yokken veya API kotası
bittiğinde 1. ve 2. kademe çalışmaya devam eder — ürün bozulmaz, sadece
öneri kalitesi düşer. Bu bir yedeklilik tasarımı değil, **varsayılan
tasarımdır**: bulut istisnadır.

> **3 Ağustos 2026 — kademe 3 artık üründe.** Servis yazılmıştı ama mobil
> uygulamadan erişilemiyordu; yalnızca `curl` ile gösterilebiliyordu. Nezaket
> Koçu ekranına "Daha iyi öneri iste" düğmesi, onay diyaloğu ve bulut önerisi
> kartları eklendi (`mobile/lib/core/network/rewrite_api_client.dart`).
> İstemci istisna fırlatmaz: ağ/sunucu sorunları `kullanilamadi` durumu
> olarak döner, yerel öneri yerinde kalır. Geçersiz anahtarla uçtan uca
> doğrulandı.

Yerel yeniden yazıcının sınırı bilinçlidir ve canlı çıktıda görülür:

```
girdi : "sen tam bir aptalsın, bu karar salakça"
yerel : "sen tam bir yanlış, bu karar hatalı"     ← akıcı değil
```

Yerel kademe bir **başlangıç noktası** verir; akıcı yeniden yazım LLM
kademesinin işidir. Kademelendirmenin var oluş sebebi tam olarak budur.

---

## 3. Doğrulama kapısı — servisin merkezi iddiası

Bir dil modeli akıcı ama işe yaramaz bir öneri üretebilir: eleştiriyi
buharlaştırabilir, hakareti başka bir hakaretle değiştirebilir, ya da istemi
görmezden gelebilir. **Bunu istemden rica ederek garanti edemezsiniz.**

Servis garanti eder:

```
kullanıcı metni ──► civility_core ──► LLM ──► civility_core ──► kullanıcı
                    (ölç: 0.87)              (DOĞRULA)
                                                  │
                                          geçemeyen ✗ atılır
```

Dört ret gerekçesi:

| # | Gerekçe | Yakaladığı hata |
|---|---|---|
| 1 | Boş veya sadece boşluk | Model hiçbir şey üretmedi |
| 2 | Orijinalle aynı | Model hiçbir şey değiştirmedi |
| 3 | **Motor daha temiz bulmuyor** | **Hakareti başka hakaretle değiştirdi** |
| 4 | Aşırı uzun (>2× + 40 karakter) | Model cümleyi şişirdi |

3 numara kritiktir ve testle kanıtlanmıştır: model `"sen tam bir aptalsın"`
(toksisite 0.55) yerine `"sen tam bir şerefsizsin"` (0.88) önerdiğinde öneri
kullanıcıya **ulaşmaz**.

**Sonuç:** LLM bir *öneri kaynağıdır*, bir *otorite değildir*. Karar mercii,
deterministik ve denetlenebilir olan motordur. Elenen öneri sayısı
(`rejectedByVerification`) API yanıtında raporlanır ve ölçülebilir bir kalite
metriğidir.

---

## 4. Model çağrısı — dört karar

Dart için resmî Anthropic SDK'sı bulunmadığından Messages API'ye ham HTTP
ile gidilir (`POST /v1/messages`).

**a) Yapılandırılmış çıktı.** Model serbest metin değil, şemaya uymak zorunda
olduğu JSON döndürür (`output_config.format`). Metin ayrıştırma hatası sınıfı
tamamen ortadan kalkar.

**b) Düşünme kapalı, efor düşük.** Bu bir muhakeme görevi değil, kısıtlı bir
yeniden yazma görevidir. Kullanıcı gönder tuşuna basmadan önce bekliyor;
gecikme ürünün kendisidir.

**c) Sistem istemi önbelleğe alınır.** İstem her istekte aynı olduğundan
`cache_control` ile işaretlenir; ilk istekten sonra bu bölüm belirgin biçimde
ucuzlar.

**d) Geri düşme açık.** Bu servise **tanımı gereği** saldırgan metin gider.
Güvenlik sınıflandırıcısının reddetmesi olasıdır ve reddedilen istek
`HTTP 200` + `stop_reason: "refusal"` olarak döner — **hata olarak değil**.
`content` dizisi boş olduğu için doğrudan `content[0]` okuyan kod burada
çöker; servis önce `stop_reason` kontrol eder. Geri düşme açıkken istek aynı
çağrı içinde başka bir modele yönlendirilir.

---

## 5. Sistem istemi — ürünün fikrî değeri

İstemin tamamı `server/lib/src/claude_client.dart` içindedir. Merkezî kural:

> Model bir **sansürcü değildir**. Kullanıcının eleştirisi, öfkesi ve niyeti
> korunur; yalnızca **saldırı** çıkarılır.

Yasaklar açıkça yazılmıştır: ahlak dersi verme, "sakin ol" deme, eleştiriyi
övgüye çevirme, özür diletme, söylenmemiş iddia ekleme.

```
Girdi        : "bu ne biçim aptalca bir karar, salaklar"
İyi öneri    : "Bu karar bence yanlış ve nedenini anlamıyorum."
Kötü öneri   : "Bu karara katılmıyorum."          ← eleştiri buharlaştı
Kötü öneri   : "Farklı düşünenler olabilir."      ← kullanıcı bunu demedi
```

"Sakin ol" diyen bir çıktı ürünün başarısızlığıdır — kullanıcı böyle bir
aracı ikinci kez kullanmaz.

---

## 6. Mahremiyet — sözleşmeye yazılmış

| Önlem | Nerede uygulanır |
|---|---|
| Onay olmadan istek kabul edilmez | `consent: true` yoksa `403` |
| Temiz metin buluta **hiç** gitmez | Bulut çağrısından önce motor kontrolü |
| Metin diske yazılmaz, loglanmaz | Log satırında yalnızca ölçüm |
| API anahtarı kodda yok | Yalnızca ortam değişkeni |
| Hız sınırı | IP başına dakikalık kayan pencere |

Log satırı örneği — içerik yok, ölçüm var:

```
[2026-08-01T02:28:46] rewrite chars=20 risk=riskli cloud=basarili accepted=2 rejected=0 ms=12
```

Onay kapısı bir formalite değildir: bir istemci hatası yüzünden kullanıcı
metni farkında olmadan buluta gidemez, çünkü sunucu onaysız isteği kabul
etmiyor.

---

## 7. Ölçümler

| Ölçüm | Değer |
|---|---|
| `civility_core` testleri | 101/101 geçiyor |
| `server` testleri | 50/50 geçiyor |
| `mobile` testleri | 21/21 geçiyor |
| Analiz uyarısı (her iki paket) | 0 |
| Ortalama çözümleme süresi | ~174 µs (16 ms bütçesinin %1'i) |
| Mobil derleme | 0 hata, 0 uyarı |

Sunucu testlerinde dil modeli sahtedir (`FakeRewriteModel`). Bu bir kısıt
değil, tasarım tercihidir: modelin "kötü davrandığı" senaryolar gerçek API'de
güvenilir biçimde tetiklenemez. Enjeksiyon, doğrulama kapısının hem iyi hem
kötü model çıktısına karşı deterministik olarak sınanmasını sağlar.

**Doğrulanmamış olan:** gerçek Anthropic API'sine karşı uçtan uca çağrı.
Bu makinede API anahtarı bulunmadığından yapılamadı. HTTP katmanı `MockClient`
ile, sunucunun tamamı ise geçersiz anahtarla canlı olarak sınandı — ikincisi
bulut çöktüğünde ürünün ayakta kaldığını doğruladı (aşağıdaki çıktı gerçektir):

```json
{ "analysis": { "civilityScore": 13, "risk": "yuksek" },
  "suggestions": [ { "source": "cihaz", "civilityScore": 100 } ],
  "cloud": { "status": "kullanilamadi",
             "detail": "API anahtarı geçersiz veya yetkisiz." } }
```

Anahtar sağlandığında yapılacak tek doğrulama: `cloud.status` alanının
`basarili` dönmesi ve `servedBy` alanının dolması.
