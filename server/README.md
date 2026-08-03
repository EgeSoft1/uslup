# Nezaket Yeniden Yazma Servisi

NSosyal Nezaket Koçu'nun **isteğe bağlı** bulut kademesi. Kullanıcı cihaz
üzerindeki öneriyi yetersiz bulup açıkça "daha iyi öneri" derse devreye girer.

> **Bu servis olmadan da ürün tam çalışır.** Cihaz üstü motor ve yerel yeniden
> yazıcı çevrimdışı, sunucusuz ve sıfır maliyetle çalışmaya devam eder. Buradaki
> her şey bir *iyileştirme*dir, bir *bağımlılık* değil.

---

## Çalıştırma

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."
cd server
dart pub get
dart run bin/server.dart
```

Ortam değişkenleri:

| Değişken | Varsayılan | Açıklama |
|---|---|---|
| `ANTHROPIC_API_KEY` | — | **Zorunlu.** Yoksa servis 78 (EX_CONFIG) ile çıkar. |
| `NEZAKET_MODEL` | `claude-opus-5` | Model kimliği |
| `PORT` | `8080` | Dinlenen port |
| `NEZAKET_HOST` | `127.0.0.1` | Yalnızca yerel. Dağıtımda açıkça `0.0.0.0` verilmeli. |
| `NEZAKET_RPM` | `20` | IP başına dakikalık istek sınırı |
| `NEZAKET_MAX_TEXT` | `1000` | Kabul edilen en uzun metin (karakter) |

---

## Uç noktalar

### `GET /health`

```json
{ "status": "ok", "model": "claude-opus-5", "engine": "civility_core" }
```

### `POST /v1/rewrite`

```json
{ "text": "sen tam bir aptalsın", "consent": true, "maxSuggestions": 3 }
```

`consent` alanı **zorunludur**. `true` değilse istek `403 consent_required`
ile reddedilir — mahremiyet vaadi belgede değil, sunucunun kabul kuralında.

Yanıt (kısaltılmış):

```json
{
  "analysis": {
    "civilityScore": 13,
    "toxicity": 0.8688,
    "risk": "yuksek",
    "intervention": "Gönderim öncesi onay",
    "findings": [
      { "matchedText": "aptalsin", "category": "hakaret",
        "severity": 0.6875, "start": 12, "end": 20,
        "explanation": "Doğrudan kişiye yönelik hakaret içeriyor. (Doğrudan karşı tarafa yöneltilmiş)" }
    ]
  },
  "suggestions": [
    { "text": "...", "source": "bulut", "rationale": "...", "civilityScore": 96 },
    { "text": "...", "source": "cihaz", "rationale": "...", "civilityScore": 100 }
  ],
  "cloud": {
    "status": "basarili",
    "detail": null,
    "servedBy": "claude-opus-5",
    "rejectedByVerification": 1
  },
  "elapsedMs": 812
}
```

`cloud.status` değerleri: `basarili`, `gereksiz` (metin zaten temizdi, bulut
hiç çağrılmadı), `reddedildi`, `kullanilamadi`, `dogrulamadaElendi`.

---

## Mimari — üç karar

### 1. Doğrulama kapısı: LLM bir öneri kaynağıdır, otorite değildir

Modelin ürettiği **her** öneri, mobil uygulamadakiyle **birebir aynı** nezaket
motorundan tekrar geçirilir. Motorun orijinalden daha temiz bulmadığı hiçbir
öneri kullanıcıya ulaşmaz.

```
kullanıcı metni ──► civility_core ──► LLM ──► civility_core ──► kullanıcı
                    (ölç)                     (DOĞRULA)
                                                  │
                                          geçemeyen ✗ atılır
```

Dört ret gerekçesi: boş, orijinalle aynı, motorun daha temiz bulmadığı, aşırı
şişirilmiş. Kritik olan üçüncüsü — hakareti başka bir hakaretle değiştiren
öneriyi yakalar. Bunu istemden *rica ederek* garanti edemezsiniz.

Bu ancak `civility_core` saf Dart olduğu için mümkündür: sunucu ile istemcinin
farklı karar vermesi teknik olarak imkânsızdır, çünkü ikisi de aynı kodu çağırır.

Elenen öneri sayısı (`rejectedByVerification`) raporlanabilir bir kalite
metriğidir.

### 2. Yapılandırılmış çıktı

Model serbest metin değil, şemaya uymak zorunda olduğu JSON döndürür
(`output_config.format`). "İşte önerileriniz:" gibi giriş cümlelerini ayıklama
ve kırılgan metin ayrıştırma sınıfı tamamen ortadan kalkar.

### 3. Geri düşme (`fallbacks: "default"`)

Bu servise **tanımı gereği** saldırgan metin gider. Güvenlik sınıflandırıcısının
böyle bir isteği reddetmesi olasıdır ve reddedilen istek `HTTP 200` +
`stop_reason: "refusal"` olarak döner — hata olarak değil. Geri düşme açık
olduğunda istek aynı çağrı içinde başka bir modele yönlendirilir.

Reddedilme **hata değil, beklenen bir sonuçtur**: kullanıcıya "bulut önerisi
üretilemedi" olarak yansır, cihaz üzerindeki öneri geçerliliğini korur.

---

## Mahremiyet

- **Metin diske yazılmaz ve loglanmaz.** Log satırlarında yalnızca ölçüm vardır:
  `rewrite chars=20 risk=riskli cloud=basarili accepted=2 rejected=0 ms=12`
- Temiz metin için bulut **hiç çağrılmaz** — gereksiz yere hiçbir metin
  cihazdan çıkmaz.
- `consent: true` olmadan istek kabul edilmez.
- API anahtarı yalnızca ortam değişkeninden okunur; kaynak kodda yoktur.

---

## Testler

```powershell
cd server
dart test
```

48 test: doğrulama kapısı, API sözleşmesi (istek gövdesinin şekli), yanıt
yorumu (özellikle `refusal`), hata sınıflandırması, onay kapısı, hız sınırı.

Dil modeli testlerde sahtedir (`FakeRewriteModel`) — testler ağ, API anahtarı
ve maliyet olmadan, tamamen deterministik çalışır. Modelin "kötü davrandığı"
senaryolar gerçek API'de güvenilir biçimde tetiklenemez; enjeksiyon bunu
mümkün kılar.
