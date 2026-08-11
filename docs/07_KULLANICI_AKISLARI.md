# Kullanıcı Senaryoları ve Akışları

**Tarih:** 12 Ağustos 2026
**Karşıladığı teslimatlar:** #3 Kullanıcı senaryoları · #11 Kullanıcı akışları

> Bu belgedeki her eşik ve her müdahale, koddaki gerçek değerlerden
> türetilmiştir — tasarım niyeti değil, çalışan davranıştır.
> Kaynak: `packages/civility_core/lib/src/civility_engine.dart`
> (`_riskFrom`, `RiskLevelInfo.intervention`).

---

## 1. Müdahale merdiveni — bütün akışların temeli

Ürünün tek bir davranış kuralı vardır ve bütün ekranlar onu uygular:
**müdahale şiddeti riskle orantılıdır ve hiçbir seviyede metin engellenmez.**

| Toksisite | Seviye | Kullanıcı ne görür | Kesinti |
|---|---|---|---|
| < 0,15 | **Temiz** | Hiçbir şey | Yok |
| 0,15 – 0,40 | **Dikkat** | Yalnızca kenarlık rengi değişir | Yok |
| 0,40 – 0,70 | **Riskli** | Gerekçe + yeniden yazma önerisi | Yok |
| ≥ 0,70 | **Yüksek** | Gönderim öncesi onay diyaloğu | Bir dokunuş |

**Neden merdiven:** kullanıcıyı her seferinde uyarmak, uyarıyı görünmez kılar.
"Dikkat" seviyesinde hiçbir kesinti olmaması bir eksiklik değil, uyarının
anlamını koruma kararıdır. Kullanıcı bir diyalog gördüğünde bunun gerçekten
ağır bir şey olduğunu bilmelidir.

**Hiçbir seviyede gönderim engellenmez.** En ağır seviyede bile sistem sorar,
karar kullanıcınındır (`00_URUN_TANIMI.md` §6.2).

---

## 2. Personalar

| # | Kim | İhtiyaç | Ürünün ona vaadi |
|---|---|---|---|
| **P1** | **Öfkeli Anıl** — tartışmada ilk tepkiyle yazan, sonra pişman olan kullanıcı | Gönderdikten sonra silmek zorunda kalmamak | Yazarken duraksama; ceza değil, ayna |
| **P2** | **Hedef Elif** — tacize uğrayan ve durumu anlatmak isteyen kullanıcı | Anlattığı için susturulmamak | Alıntı ve şikâyet ayırt edilir; asla işaretlenmez |
| **P3** | **Kimliğiyle konuşan Berivan** — kendi kimliğinden söz eden kullanıcı | Kimlik adı yüzünden filtrelenmemek | Kimlik adı hiçbir zaman tetikleyici değildir |
| **P4** | **Topluluk yöneticisi Deniz** | Topluluğun sağlığını görmek | Metni görmeden, davranıştan üretilen panel |

P2 ve P3, bu ürünün rakiplerinden ayrıldığı yerdir. Çoğu filtre bu iki kişiyi
**cezalandırır**; burada ikisi de birer kabul ölçütüdür ve testlerle korunur
(`hate_layer_test.dart` §1 ve §4).

---

## 3. Senaryolar

### S1 — Öfkeli Anıl bir tartışmada hakaret yazıyor  *(P1)*

> **Bağlam:** Anıl bir gönderiye kızmış, cevap yazıyor.
> **Yazdığı:** "sen tam bir aptalsın, bu karar salakça"

1. Anıl yazmaya başlar. İlk kelimelerde hiçbir şey olmaz.
2. "aptalsın" tamamlandığı anda mesaj kutusunun kenarlığı sarıya döner.
   Kesinti yok, diyalog yok. (~268 µs sonra — Anıl gecikme hissetmez.)
3. Kutunun altında gerekçe belirir: **"Kişiliğin bütününü reddediyor.
   Davranışı değil, kişiyi hedef alıyor."** Hangi kelimenin işaretlendiği
   vurgulanmıştır.
4. Altında öneri: **"Bu konuda sana katılmıyorum, bu karar hatalı"**
5. Anıl önerinin üstüne dokunur; metin değişir, kenarlık yeşile döner.
6. Gönderir.

**Üretilen anonim sinyal:** `oneriyiKabulEtti` → panelde düzeltme oranına
katkı. Metin hiçbir yere gitmez.

**Kritik tasarım noktası:** Anıl'a "yapamazsın" denmedi. Alternatif gösterildi
ve seçim onda kaldı. Ürünün tezi budur: yaptırım davranışı değiştirmez,
duraksama değiştirir.

---

### S2 — Hedef Elif tacizi anlatıyor  *(P2)*

> **Yazdığı:** "Bana 'şerefsiz' dedi, çok üzüldüm"

1. Elif yazar.
2. **Hiçbir şey olmaz.** Kenarlık yeşil kalır, uyarı çıkmaz.

Metinde 0,88 taban şiddetli bir terim geçmesine rağmen bağlam katmanı bunu
**aktarım** olarak tanır (×0,20 çarpanı) ve yumuşatma tavanı devreye girer;
sonuç eleme eşiğinin altına düşer.

> ⚠️ **Bu akış bir özellik değil, bir borçtur.** Mevcut filtrelerin en yaygın
> kusuru tam olarak burada mağduru işaretlemektir. Ölçüm bunu ayrı bir dilimle
> takip eder (`04_MODEL_DEGERLENDIRME.md`, Bağlam dilimi — F1 %100).

---

### S3 — Berivan kimliğinden söz ediyor  *(P3)*

> **Yazdığı:** "Ben Kürtüm ve bu ülkede yaşıyorum"

1. Berivan yazar.
2. **Hiçbir şey olmaz.**

Kimlik adı, nefret söylemi katmanında yalnızca bir *yuvayı* doldurur; tek
başına asla bulgu üretmez. Sözlükte tek bir kimlik adı yoktur ve bu, yapısal
bir testle korunur — sözlüğe kimlik adı sızarsa test kırılır.

**Karşı örnek, aynı kelimeyle:** "Bütün Kürtler hırsızdır" → yakalanır,
kategori *nefret*, seviye *yüksek*, onay diyaloğu çıkar.

---

### S4 — Yüksek riskli gönderim: onay kapısı  *(P1)*

> **Yazdığı:** "Suriyeliler her yeri doldurdu. Bunların soyunu kurutmak lazım"

1. İlk cümle tek başına temizdir; hiçbir şey olmaz.
2. İkinci cümledeki zamir, gönderge katmanı tarafından önceki cümledeki
   kimliğe bağlanır. Kenarlık kırmızıya döner.
3. Gerekçe: **"Bir grubun var olma hakkını reddediyor. Bu ifade Türk Ceza
   Kanunu 216. madde kapsamına girebilir."**
4. Kullanıcı gönder'e basar → **onay diyaloğu** açılır. Diyalogda gerekçe
   tekrar yazılıdır; seçenekler "Vazgeç" ve "Yine de gönder".
5. "Yine de gönder" seçilirse metin gider ve aynı metin için bir daha
   sorulmaz.

**Üretilen sinyal:** `uyariyaRagmenGonderdi`.

> Sistem burada da engellemez. Engellemek, kullanıcıyı başka bir kanala
> iter ve ürün onu bir daha hiç göremez. Sorulan soru, kaydedilen tereddüt
> ve panelde görünen sayı, engellemekten daha çok şey değiştirir.

---

### S5 — Deniz topluluk sağlığına bakıyor  *(P4)*

1. Deniz Nezaket sekmesindeki grafik simgesine dokunur.
2. Panel açılır. En üstte, herhangi bir sayıdan önce: **"Bu paneldeki hiçbir
   sayı mesaj içeriğinden üretilmez."**
3. Sağlık puanı, düzeltme oranı, müdahale oranı, günlük eğilim ve uyarı
   türleri görünür.
4. Uyarı türleri listesinin altında: **"1 tür gizlendi: 5 gözlemin altındaki
   sayılar tek bir kişiyi işaret edebileceği için açılmıyor."**
5. En altta **"Dışarı ne gider"** kartı, platforma gönderilmesi hâlinde giden
   veriyi harfi harfine gösterir — yalnızca sayılar.

**Panelde OLMAYAN şey:** ihlal eden mesajların listesi. Alışıldık moderasyon
panellerinin ana ekranı budur; burada yoktur ve olamaz.

---

## 4. Akış diyagramları

### A1 — Ana akış: yazma → müdahale → karar

```
┌──────────────┐
│ Kullanıcı    │
│ yazıyor      │
└──────┬───────┘
       │ her tuş vuruşu
       ▼
┌──────────────────────────┐
│ Cihaz üstü çözümleme     │  ~268 µs
│ (normalizasyon → sözlük  │  debounce YOK
│  → örüntü → nefret →     │
│  gönderge → bağlam)      │
└──────┬───────────────────┘
       ▼
   ┌───────────┐
   │ risk?     │
   └─┬───┬───┬─┘
     │   │   │
 temiz│  │dikkat    riskli / yüksek
     │   │   │
     ▼   ▼   ▼
   ┌───┐┌────────┐┌──────────────────────┐
   │yok││kenarlık││ kenarlık + GEREKÇE   │
   │   ││ rengi  ││ + yeniden yazma      │
   └─┬─┘└───┬────┘│ önerisi              │
     │      │     └────┬─────────────────┘
     │      │          │
     │      │     ┌────┴──────┬───────────┐
     │      │     ▼           ▼           ▼
     │      │  öneriyi    kendi      görmezden
     │      │  uygula     düzelt     gel
     │      │     │           │           │
     └──────┴─────┴─────┬─────┘           │
                        ▼                 ▼
                   ┌─────────┐    ┌───────────────┐
                   │ GÖNDER  │    │ risk yüksek?  │
                   └────┬────┘    └──┬─────────┬──┘
                        │        hayır│      evet│
                        │            │          ▼
                        │◄───────────┘   ┌──────────────┐
                        │                │ ONAY DİYALOĞU│
                        │                │ vazgeç /     │
                        │                │ yine de gönder│
                        │                └──────┬───────┘
                        ▼                       │
              ┌────────────────────┐            │
              │ Anonim sinyal      │◄───────────┘
              │ (metin YOK)        │
              └─────────┬──────────┘
                        ▼
              ┌────────────────────┐
              │ Topluluk sağlığı   │
              │ paneli             │
              └────────────────────┘
```

### A2 — Sinyal sonucu nasıl belirlenir

Panelin ölçtüğü şey uyarı sayısı değil, uyarının **işe yarayıp yaramadığıdır**.
Bu yüzden gönderim anındaki duruma değil, yazım boyunca görülen **en yüksek
riske** bakılır — kullanıcı düzeltmişse metin artık temizdir ve müdahale hiç
olmamış gibi görünürdü.

```
                    yazım boyunca görülen EN YÜKSEK risk
                                   │
                    ┌──────────────┴──────────────┐
                 temiz                        riskli/yüksek
                    │                              │
                    ▼                              ▼
            temizGonderim              gönderim anında hâlâ riskli mi?
                                          │                   │
                                       evet                 hayır
                                          │                   │
                                          ▼          ┌────────┴────────┐
                              uyariyaRagmenGonderdi  │ öneri uygulandı?│
                                                     └───┬─────────┬───┘
                                                      evet│      hayır│
                                                         ▼          ▼
                                              oneriyiKabulEtti  kendiDuzeltti
```

`kendiDuzeltti` ayrı bir sonuçtur ve **başarı sayılır**: ürün öneriyi
dayatmaz; kullanıcının kendi bulduğu ifade de amaca hizmet eder.

### A3 — Mağdur akışı (S2) — neden hiçbir şey olmuyor

```
"Bana 'şerefsiz' dedi, çok üzüldüm"
        │
        ▼
  sözlük eşleşmesi: "şerefsiz" (taban şiddet 0,88)
        │
        ▼
  bağlam çözümleme
    • alıntı işareti var
    • aktarma fiili var ("dedi")
    • yönelim ikinci şahsa DEĞİL
        │
        ▼
  çarpan ×0,20  →  0,176
        │
        ▼
  YUMUŞATMA TAVANI (0,10) uygulanır  →  0,10
        │
        ▼
  eleme eşiği 0,12'nin ALTINDA  →  bulgu üretilmez
        │
        ▼
      TEMİZ
```

> Tavan olmasaydı 0,176 eşiği aşardı ve **tacize uğrayan kişi uyarı alırdı.**
> Bu hata gerçekten yaşandı ve ölçümle bulundu
> (`04_MODEL_DEGERLENDIRME.md` §4, hata #3).

### A4 — Topluluk paneli akışı

```
Nezaket sekmesi ──[grafik simgesi]──► Topluluk Sağlığı
                                            │
        ┌───────────────────────────────────┤
        ▼                                   ▼
  MAHREMİYET ŞERİDİ                   Sağlık puanı
  "hiçbir sayı mesaj                  (temizlik %60 +
   içeriğinden üretilmez"              düzeltme %40)
        │                                   │
        ▼                                   ▼
  Düzeltme / müdahale oranı           Günlük eğilim
        │                                   │
        ▼                                   ▼
  Uyarı türleri  ──►  k < 5 olanlar GİZLENİR
        │              ve gizlendiği YAZILIR
        ▼
  "Dışarı ne gider" — giden verinin tamamı, olduğu gibi
```

---

## 5. Erişilebilirlik kararları (akışlara gömülü)

Ayrıntılı değerlendirme ayrı bir teslimattır (#14); burada yalnızca
akışları doğrudan etkileyen kararlar var.

| Karar | Gerekçe |
|---|---|
| Risk **yalnızca renkle** anlatılmaz | Renk körlüğünde kenarlık rengi tek başına okunamaz; her seviyede metin gerekçe de vardır |
| Grafik çubukları `Semantics` etiketi taşır | Ekran okuyucu "3 gün önce, müdahale oranı yüzde 18" der; çubuk yüksekliği erişilebilir değildir |
| Kategori çubukları sayıyı **metin olarak** da yazar | Aynı sebep |
| Dokunma hedefleri 48 px altına inmez | Alt gezinme çubuğunda uygulanıyor (`home_shell.dart`) |
| Onay diyaloğunda yıkıcı eylem varsayılan **değildir** | "Yine de gönder" ikincil konumda; yanlışlıkla onaylanması zorlaştırılır |

---

## 6. Bu akışların test karşılıkları

Her akış bir testle korunuyor — belge ile ürünün ayrışmasını engellemek için.

| Akış | Test |
|---|---|
| S1 öneri üretimi | `rewrite_test.dart` §4 ÖBEK MODU |
| S2 mağdur korunur | `hate_layer_test.dart` §4 |
| S3 kimlik beyanı | `hate_layer_test.dart` §1 (15 cümle) |
| S4 gönderge çözümlemesi | `hate_layer_test.dart` §6 |
| S4 onay kapısı | `widget_test.dart` — "yüksek riskli metinde gönder düğmesi kalkana döner" |
| S5 panel sözleşmesi | `community_health_screen_test.dart` |
| A2 sinyal sonucu | `community_health_test.dart` §2 |
| A3 yumuşatma tavanı | `implicit_layer_test.dart` §3 |

---

## 7. Henüz akışa girmemiş olanlar

Dürüstlük gereği: aşağıdakiler tasarlanmadı, çünkü gerçek kullanıcı verisi
olmadan tasarlanamaz.

- **İlk kullanım (onboarding).** Kullanıcı özelliği ilk gördüğünde ne
  düşünüyor? Kullanıcı testi olmadan yazılacak akış, tahminden ibaret olur.
- **Özelliği kapatma akışı.** Kapatılabilir olmalı — sansür olmadığı iddiası
  ancak kapatılabiliyorsa doğrudur. Ayarlar ekranında yeri hazır değil.
- **Yanlış pozitif bildirimi.** Kullanıcı "bu uyarı yanlıştı" diyebilmeli;
  bu, hem etik bir gereklilik hem de kümenin bağımsız büyümesi için tek
  gerçekçi yol.

Bu üçü, kullanıcı testi (teslimat #12–#13) yapıldıktan sonra yazılmalıdır.
