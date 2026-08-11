# NSosyal İnovasyon Yarışması 2026 — Ürün Tanımı

> Bu belge projenin **kuzey yıldızıdır**. Başvuru formu, teknik rapor ve final
> sunumu bu belgeden türetilir. Bir karar bu belgeyle çelişiyorsa, belge
> güncellenir — kod değil.

**Belge sürümü:** v2 · 12 Ağustos 2026
**Yarışma teması:** Sosyal Yapay Zekâ
**Durum:** Çekirdek motor çalışıyor ve test edilmiş, ürünleştirme sürüyor

---

## 1. Tek cümlelik tanım

> **NSosyal kullanıcısı saldırgan bir gönderi yazarken, gönderilmeden önce,
> cihazın kendi içinde tespit edip daha yapıcı bir alternatif öneren
> Türkçe'ye özel yapay zekâ katmanı.**

---

## 2. Çözülen problem

Sosyal medyada nefret ve hakaret bugün **oluştuktan sonra** yönetiliyor:
içerik yayınlanır → biri şikâyet eder → moderatör inceler → silinir.

Bu döngünün üç kırılgan noktası var:

| Sorun | Sonuç |
|---|---|
| **Zarar zaten oluşmuştur** | İçerik silinene kadar hedef kişi onu görmüştür. Silmek görmüş olmayı geri almaz. |
| **Yaptırım geri tepiyor** | Kullanıcı cezalandırıldığını hisseder, öfkelenir, davranışını değiştirmez. |
| **Türkçe'de doğruluk düşük** | Küresel modeller Türkçe'nin eklemeli yapısında, argosunda ve bağlamında zayıf. |

Ve en can yakıcı kırılma: **mağdur cezalandırılıyor.** Tacize uğrayan kişi
durumu anlatırken ("bana 'şerefsiz' dedi") mevcut filtreler onun mesajını da
işaretliyor. Şikâyet eden susturuluyor.

### Bizim yaklaşımımız

Zararı **oluşmadan** engelle. Kullanıcı cümleyi yazarken müdahale et — ceza
olarak değil, ayna olarak. İnsanlar yüz yüzeyken bu şeyleri söylemiyor;
ekran arkasında söylüyor. Kaybolan o anlık duraksamayı geri koyuyoruz.

> Şartname, hedeflerinin **birincisi** olarak şunu yazıyor:
> *"Kullanıcıların dijital ortamda yüz yüze bakar gibi etkileşim kurmasını
> sağlayan yenilikçi sosyal medya çözümlerinin geliştirilmesini teşvik etmek."*
> Ürünün varlık sebebi tam olarak bu cümledir.

---

## 3. Neden yenilikçi (Yenilikçilik ve Özgünlük — %20)

| Mevcut çözümler | Bizim farkımız |
|---|---|
| Yayın **sonrası** moderasyon | Yayın **öncesi** önleme |
| İçerik sunucuya gider, orada taranır | **Metin cihazdan hiç çıkmaz** |
| Kara kutu: "gönderin kaldırıldı" | Her karar açıklanır: hangi kelime, neden |
| Sadece engeller | Alternatif **önerir**, kararı kullanıcıya bırakır |
| İngilizce merkezli modeller | Türkçe morfolojisi + argosu + gizleme hileleri |
| Mağduru da işaretler | Alıntı/şikâyet/öz-ifade ayırt edilir |
| Yalnızca **yasaklı kelime** arar | **Küfürsüz düşmanlığı** da görür |
| Kimlik adını yasaklı kelime sayar | Kimlik adı **hiçbir zaman** tetikleyici değil |

Son üç satır teknik olarak en özgün kısımdır ve rakiplerin en zayıf noktası.

**Kimlik adı üzerine:** Nefret söylemi filtrelerinin yaygın kusuru, korunan
grubun adını yasaklı kelime listesine koymaktır. Sonuç ters teper — kendi
kimliğinden söz eden insan susturulur:

```
"Ben Kürtüm"                        → filtrelenmemeli   ama filtrelenir
"Eşcinsel hakları konferansı"       → filtrelenmemeli   ama filtrelenir
"Bütün Kürtler hırsızdır"           → filtrelenmeli
```

Bizim katmanımızda kimlik adı **yalnızca düşmanca bir kuruluşun içindeki
yuvayı doldurur**; tek başına hiçbir şey tetiklemez. Ölçüm bunu
doğruluyor: 20 masum kimlik cümlesinin hiçbiri işaretlenmiyor
(`04_MODEL_DEGERLENDIRME.md` §2, §3b).

**Küfürsüz düşmanlık** üzerine: sosyal medyadaki saldırganlığın büyük kısmı
tek bir yasaklı kelime içermez. Kelime listesine dayanan hiçbir sistem şunları
göremez:

```
"senin gibilerden zaten bu beklenirdi"   → ötekileştirme
"sen ne anlarsın bu işlerden"            → yetkinlik reddi
"gününü göreceksin"                      → örtük tehdit
```

Ölçüm bunu sayısallaştırdı: sözlük katmanı bu dilimde **%0,0** duyarlılık
gösteriyordu. Eklenen edimbilimsel örüntü katmanı, saldırganlığı kelimelerde
değil **kelimelerin dizilişinde** arar — ve bunu **kesinlikten hiçbir şey
götürmeden** yapar (bkz. `04_MODEL_DEGERLENDIRME.md` §3.3).

---

## 4. Nasıl çalışıyor

```
Kullanıcı yazıyor (her tuş vuruşu)
   │
   ▼
┌─────────────────────────── CİHAZ ÜZERİNDE ────────────────────────────┐
│  1. Normalizasyon      Gizleme hilelerini geri çevir                  │
│                        "$3r3fsiz" → "serefsiz"                        │
│                        "a.p.t.a.l" → "aptal"                          │
│                        "aptaaaal" → "aptal"                           │
│                                                                        │
│  2a. Sözlük eşleştirme Türkçe eklemeli yapı: kök eşleşmesi            │
│                        "aptal" kökü → aptalsın/aptallar/aptallığın    │
│                                                                        │
│  2b. ÖRÜNTÜ KATMANI    Küfürsüz düşmanlık — kelimede değil, DİZİLİŞTE │
│                        "senin gibiler"    → ötekileştirme             │
│                        "sen ne anlarsın"  → yetkinlik reddi           │
│                        "gününü göreceksin"→ örtük tehdit              │
│                        8 edimbilimsel aile, 50 örüntü                 │
│                                                                        │
│  2c. NEFRET KATMANI    Kimlik hedefli düşmanlık — aynı fikrin kimlik  │
│                        eksenine taşınmış hâli.                        │
│                        "Bütün X'ler hırsızdır" → toplu suçlama        │
│                        "X'ler defolsun"        → dışlama              │
│                        "X'ler hayvandır"       → insanlıktan çıkarma  │
│                                                                        │
│                        ⚠ KİMLİK ADI YASAKLI KELİME DEĞİLDİR.          │
│                        "Kürt", "Ermeni", "eşcinsel" tek başına        │
│                        hiçbir şey tetiklemez; yalnızca düşmanca bir   │
│                        KURULUŞUN içindeki yuvayı doldurur.            │
│                        Aksi hâlde sistem, korumaya çalıştığı grubu    │
│                        susturur: "Ben Kürtüm" → temiz kalmalı.        │
│                        5 kuruluş ailesi, 40 kimlik terimi             │
│                                                                        │
│  2d. GÖNDERGE KATMANI  Kimlik önceki cümledeyse zamiri ona bağlar     │
│                        "Suriyeliler doldurdu. BUNLARIN soyunu         │
│                         kurutmak lazım"        → yakalanır            │
│                        "Bunların soyunu kurutmak lazım" (öncülsüz)    │
│                                                → yakalanMAZ           │
│                        Öncül yoksa hedefin kim olduğu bilinemez;      │
│                        zamirden kimlik uydurulmaz.                    │
│                                                                        │
│  3. BAĞLAM ÇÖZÜMLEME   ← projenin teknik kalbi                        │
│                        (her iki katman da buradan geçer)              │
│                        "aptalsın"          → saldırı    ×1,25         │
│                        "aptal değilsin"    → iltifat    ×0,15         │
│                        "bana aptal dedi"   → şikâyet    ×0,20         │
│                        "kendimi aptal..."  → öz-ifade   ×0,20         │
│                        "aptal değil misin" → RETORİK, saldırı sayılır │
│                                                                        │
│  4. Skor birleştirme   Noisy-OR: 1 − Π(1 − sᵢ)                        │
│                        → Nezaket puanı 0-100 + risk seviyesi          │
│                                                                        │
│  5. Öneri üretimi      Yerel, deterministik yeniden yazım             │
└────────────────────────────────────────────────────────────────────────┘
   │
   ▼
Kullanıcı seçer → gönderir → anonim sinyal → topluluk sağlığı paneli

        ⚠ SUNUCU ADIMI YOKTUR. Hattın tamamı cihazda biter.
        Bulut kademesi yazılmış, ölçülmüş ve 3 Ağustos'ta kasıtlı olarak
        kaldırılmıştır — gerekçe: `03_LLM_SERVISI.md`.
```

**Ölçülen performans:** ortalama **268 µs** / çözümleme (tüm katmanlar dahil,
soğuk ölçüm — 12 Ağustos 2026). 60 FPS kare bütçesinin (16 ms) **%2'sinden
azı**. Bu yüzden gecikmeli tetikleme (debounce) gerekmiyor — geri bildirim
gerçekten anlık. Ölçüm koşulları: `04_MODEL_DEGERLENDIRME.md` §3.4.

**Ölçülen doğruluk:** ayrık küme üzerinde **F1 = %84,2**
(kesinlik %88,9 / duyarlılık %80,0). Koşullar ve sınırlar:
`04_MODEL_DEGERLENDIRME.md` §5 — **bu koşullar rapora birlikte yazılmalıdır.**

Geliştirme kümesinde (256 örnek) kesinlik **%100**, F1 **%99,6** — ancak bu
sayı bir genelleme kanıtı değildir, çünkü küme ve örüntüler aynı kişi
tarafından yazılmıştır. Aynı belgenin §5'i bunu açıkça uyarır.

---

## 5. Şartname temalarına eşleme

Tek ürün, üç tema maddesi — dağınık özellik listesi değil, tek akış:

| Şartname örnek çözüm alanı | Bizdeki karşılığı | Durum |
|---|---|---|
| YZ destekli içerik moderasyonu | Cihaz-üstü Türkçe toksisite sınıflandırıcı | ✅ Çalışıyor |
| Duygu analizi | Bağlam/niyet çözümleme katmanı | ✅ Çalışıyor |
| **Nefret söylemi tespiti** | **Kimlik hedefli kuruluş katmanı** | ✅ **Çalışıyor** |
| Büyük Dil Modelleri (LLM) | — | ❌ **Kasıtlı olarak kapsam dışı** (`03_LLM_SERVISI.md`) |
| YZ destekli topluluk yönetimi | Topluluk sağlığı paneli | 🔜 Planlı |
| Spam/bot tespiti | — | ❌ Kapsam dışı (yol haritası) |
| YZ tabanlı arama | — | ❌ Kapsam dışı |

**Kapsam dışı bırakılanlar kasıtlıdır.** Değerlendirmede "Problemi Çözme
Başarısı" %20 ve "Teknik Yeterlilik" %35 ağırlıkta. Bir problemi derinlemesine
çözmek, altısına yüzeysel dokunmaktan daha yüksek puan getirir.

---

## 6. Etik ve mahremiyet duruşu

Bu bölüm teknik rapordaki **"Veri, model, etik ve performans dokümanı"**
teslimatının çekirdeğidir.

1. **Mahremiyet tasarımdan gelir.** Varsayılan akışta metin cihazdan çıkmaz.
   Bu bir gizlilik politikası maddesi değil, mimarinin kendisi.
2. **Sansür değil, farkındalık.** Sistem hiçbir metni kendiliğinden
   değiştirmez veya engellemez. Öneri sunar; kararı kullanıcı verir.
3. **Açıklanabilirlik zorunlu.** Her uyarı "hangi kelime" ve "neden"
   sorusuna cevap verir. Kara kutu moderasyon güveni yok eder.
4. **Yanlış pozitif, yanlış negatiften pahalıdır.** Masum bir cümleyi haksız
   yere işaretlemek, kullanıcının sistemi kapatmasına yol açar. Bu yüzden
   `requiresDirection` ve maskeleme listesi gibi kesinlik artırıcı
   mekanizmalar önceliklendirildi.
5. **Mağdur korunur.** Alıntı, aktarım ve öz-ifade ayırt edilir; taciz
   bildiren kullanıcı asla işaretlenmez.

---

## 7. Mevcut durum — dürüst envanter

### Çalışan ve doğrulanmış
- Türkçe normalizasyon (çift varyantlı, gizleme direnci) — **testli**
- Bağlam duyarlı toksisite motoru — sözlük + **edimbilimsel örüntü katmanı**
- **Nefret söylemi katmanı** — kimlik hedefli 5 kuruluş ailesi; kimlik
  adları yasaklı kelime DEĞİL, yalnızca düşmanca kuruluşun içinde yuva
  doldurur. Dilim F1 %96,8, **kesinlik %100** (20 masum kimlik cümlesinin
  hiçbiri işaretlenmiyor)
- **Gönderge (anafora) katmanı** — kimlik önceki cümledeyse çoğul işaret
  zamiri ona bağlanır; öncülsüz zamirden kimlik uydurulmaz
- **Ölçüm altyapısı**: 336 etiketli örnek, kesinlik/duyarlılık/F1/F0.5
- ~~LLM yeniden yazma servisi~~ — yazıldı, ölçüldü, **kasıtlı olarak
  kaldırıldı** (3 Ağustos). Gerekçe: `03_LLM_SERVISI.md`
- Yerel yeniden yazma önerisi — **iki mod** (öbek / yerinde), Türkçe
  morfoloji farkındalığıyla; ikame edilen kelime taşıdığı eki korur
- Canlı yazım arayüzü (Nezaket Koçu ekranı) **+ sohbet mesaj kutusu**
- **132 test geçiyor** (122 çekirdek + 10 mobil), 0 analiz uyarısı
  — 12 Ağustos 2026'da `dart test` + `flutter test` ile doğrulandı
- Ölçülen performans: 268 µs / çözümleme · doğruluk: F1 %84,2 (ayrık küme)

### Devralınan varlıklar (önceki mesajlaşma projesinden)
- 30 ekranlık Flutter arayüz kütüphanesi ve tasarım sistemi
- Rust WebSocket gateway mimarisi (bağlantı yönetimi, pub/sub yönlendirme)
- Veritabanı şemaları, k8s manifestleri

### Henüz yapılmamış — açıkça
- BERTurk tabanlı sinir ağı modeli (veri kümesi + eğitim + ONNX dönüşümü)
  → *ölçüm altyapısı hazır; karşılaştırmalı değerlendirme yapılabilir*
- **Bağımsız etiketlenmiş veri kümesi** — mevcut kümeleri tek kişi yazdı,
  hakem uyumu (kappa) ölçülmedi. Nefret dilimi için bu bir kat daha kritik.
- ~~**Cümleler arası gönderge çözümlemesi**~~ — ✅ **eklendi (12 Ağustos,
  `510a5ec`).** Kimlik önceki cümledeyse çoğul işaret zamiri ona bağlanır.
  Kalan sınır ilkeseldir: öncülsüz zamir (*"bunların soyunu kurutmak lazım"*
  tek başına) kasıtlı olarak kaçırılır — hedefin kim olduğu metinden
  bilinemez ve zamirden kimlik uydurmak kesinlik iddiasını çürütür
- ~~**Yerel yeniden yazıcının akıcılığı**~~ — ✅ büyük ölçüde kapatıldı
  (3 Ağustos, `185efab`): iki mod + Türkçe morfoloji farkındalığı.
  ⬜ **Kalan:** düzeltme sonrası akıcılık `bin/rewrite_audit.dart` ile
  yeniden ölçülüp sayı olarak rapora girmeli
- Topluluk sağlığı paneli
- Rust backend **derlenmiyor** — kapsam dışı bırakıldı (`02_TEKNIK_BORC.md` §5)
- Kullanıcı testi, erişilebilirlik değerlendirmesi

---

## 8. Açık riskler

| Risk | Etki | Durum |
|---|---|---|
| **Takım tek kişi** | Başvuru geçersiz — şartname en az 2 kişi şartı koyuyor | 🔴 **20 Ağustos'a kadar çözülmeli** |
| ~~Git kalıcı kurulu değil~~ | ~~Çalışan tek kopya bir runtime önbelleğindeydi~~ | 🟢 **Çözüldü (12 Ağustos).** MinGit 2.55.0.4 → `D:\git`, kullanıcı PATH'ine eklendi |
| ~~Dart/Flutter kurulu değil~~ | ~~Testler ve ölçüm çalıştırılamıyordu; rapordaki her sayı doğrulanamaz durumdaydı~~ | 🟢 **Çözüldü (12 Ağustos).** Flutter 3.44.9 / Dart 3.12.2 → `D:\flutter`, `PUB_CACHE=D:\pub-cache` |
| **C: sürücüsü dolu** | 143 GB'ın yalnızca ~3 GB'ı boş (12 Ağustos'ta `mobile/build` temizlendikten sonra). Android derlemesi ve Gradle önbelleği bunu hızla yiyebilir. Araç zinciri bu yüzden D:'ye kuruldu. | 🟡 İzlenmeli |
| **Uzak depo yok** | `git remote -v` boş. Şartnamenin "kaynak kod" teslimatı bugün verilemez; ayrıca tek kopya bu diskte — donanım arızası projeyi silip götürür. | 🔴 **Başvurudan önce** |
| Rust backend derlenmiyor | Backend iddiaları kanıtlanamaz | 🟢 Kapsam dışı bırakıldı |
| ~~Etiketli veri kümesi yok~~ | ~~Metrikler raporlanamaz~~ | 🟢 330 örnek + ölçüm altyapısı |
| **Metrikler bağımsız değil** | Kümeyi ve örüntüleri aynı kişi yazdı; jüri sorgulayabilir | 🟡 İkinci etiketleyici gerekiyor |
| ~~Nefret söylemi kapsanmıyor~~ | ~~Sözlükte 0 girdi~~ | 🟢 5 kuruluş ailesi + ölçüm dilimi eklendi |
| **Kimlik söz varlığı eksik kalabilir** | 40 terim kapsanıyor; kapsanmayan bir grup hedef alındığında sistem sessiz kalır — ve bu, o grubu korumasız bırakır | 🟡 Genişletme sürüyor |
| Kullanıcı testi yapılmadı | 3 teslimat kalemi eksik kalır | 🟡 Eylül başına planlanmalı |
