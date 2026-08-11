# Teknik Rapor Taslağı

**Hazırlanma tarihi:** 12 Ağustos 2026
**Teslim:** 24 Ağustos 2026 17:00 (TSİ) · **Hedef bitiş: 22 Ağustos**
**Tema:** Sosyal Yapay Zekâ

> 🔴 **ÖNCE ŞABLONU İNDİR.** Şartname V2 §7.1:
> *"Belirlenen tarih ve saat sonrasında yapılan yüklemeler ile şablona uygun
> olmayan, eksik veya hatalı yüklenen raporlar değerlendirmeye alınmaz ve
> ilgili takımlar yarışmadan elenir."*
>
> Bu belge **içeriktir, format değildir.** KYS'den indirilen güncel resmî
> şablonun bölüm başlıkları esastır; aşağıdaki bölümler o başlıklara
> yerleştirilir. Şablonun başlıkları buradakilerden farklıysa **şablon
> kazanır** ve bu belge ona göre yeniden eşlenir.

---

## 0. Yazım planı — 12–22 Ağustos

| Gün | İş | Bağımlılık |
|---|---|---|
| 12–13 Ağu | KYS'den şablonu indir, bölüm başlıklarını bu belgeye eşle | KYS erişimi |
| 12–14 Ağu | §2 Problem, §3 Çözüm, §5 Yenilikçilik — metin hazır, aktarılacak | — |
| 14–16 Ağu | §4 Yöntem — mimari şemaları ve kod referansları | — |
| 16–18 Ağu | §6 Doğrulama — **ölçümü yeniden çalıştır**, tabloları tazele | `dart` kurulu olmalı |
| 18–19 Ağu | §7 Etik/mahremiyet, §8 Uygulanabilirlik, §9 Riskler | — |
| 19–20 Ağu | Görseller: mimari diyagram, ekran görüntüleri, ölçüm grafikleri | Prototip çalışır durumda |
| 20–21 Ağu | Kaynakça, biçim denetimi, şablon uyum kontrolü | — |
| **22 Ağu** | **Yükle** — 24'ü tampon bırak (son gün KYS yavaşlar) | — |

---

## 1. Bölüm eşlemesi ve kaynaklar

| Rapor bölümü | Kaynak | Durum |
|---|---|---|
| Proje Özeti | `05_BASVURU_METNI.md` §3 | 🟩 Metin hazır |
| Problem / Sorun | `00_URUN_TANIMI.md` §2 | 🟩 Metin hazır |
| Çözüm | `00_URUN_TANIMI.md` §4 | 🟩 Metin hazır |
| Yöntem / Sistem Mimarisi | `packages/civility_core/` kaynak kod | 🟨 Diyagram çizilecek |
| Yenilikçi Yön | `00_URUN_TANIMI.md` §3 | 🟩 Metin hazır |
| Doğrulama ve Metrikler | `04_MODEL_DEGERLENDIRME.md` | 🟨 Ölçüm tazelenecek |
| Katman Karşılaştırması (A/B) | `04_MODEL_DEGERLENDIRME.md` §3.3 | 🟩 Tablo hazır |
| Yapay Zekâ Mimarisi | `00_URUN_TANIMI.md` §4 + `03_LLM_SERVISI.md` | 🟩 |
| Etik ve Mahremiyet | `00_URUN_TANIMI.md` §6 + `03_LLM_SERVISI.md` §2 | 🟩 |
| Performans | `04_MODEL_DEGERLENDIRME.md` §3.4 | 🟩 |
| LLM Kullanımı — neden yok | `03_LLM_SERVISI.md` | 🟩 |
| Uygulanabilirlik / Ölçeklenebilirlik | — | ⬜ Yazılacak |
| Riskler ve Bilinen Sınırlar | `04_MODEL_DEGERLENDIRME.md` §5, §6 | 🟩 |
| Zaman Planı ve Maliyet | Bu belge §10 | 🟨 |
| Hedef Kitle | `05_BASVURU_METNI.md` §9 | 🟩 |
| Kaynakça | ⬜ | ⬜ Toplanacak |

---

## 2. Puanlama ağırlıklarına göre yazım stratejisi

Sosyal Yapay Zekâ dikeyinde ağırlıklar (şartname V2 §5 — **PDF'den doğrula**,
web sayfasındaki tablo düzensiz aktarılmış):

| Kriter | Ağırlık | Raporun hangi bölümü kazandırır |
|---|---|---|
| **Teknik Yeterlilik ve Uygulanabilirlik** | **%35** | Yöntem + Doğrulama + Mimari — raporun en uzun ve en somut kısmı buraya gitmeli |
| Yenilikçilik ve Özgünlük | %20 | Yenilikçi Yön — özellikle küfürsüz düşmanlık ve kimlik-yuvası tasarımı |
| Problemi Çözme Başarısı | %20 | Problem + ölçülmüş öncesi/sonrası karşılaştırma (T0→T3) |
| Kullanıcı Deneyimi (UI/UX) | %10 | Ekran görüntüleri, kullanıcı akışları |
| Sunum ve Prototip Kalitesi | %15 | Demo videosu, çalışan prototip |
| İş Modeli ve Sürdürülebilirlik | %0 | **Kısa tut.** Bu dikeyde puan getirmiyor. |

**Sonuç:** rapor hacminin yaklaşık yarısı Yöntem + Doğrulama bölümlerine
ayrılmalı. Gelir modeli bir paragrafı geçmemeli.

---

## 3. Bölüm taslakları

### 3.1 Problem tanımı

Kaynak: `00_URUN_TANIMI.md` §2 — metin olduğu gibi aktarılabilir.

Rapora eklenecek, başvuruda olmayan derinlik:

- **Sayısal bağlam.** Türkiye'de sosyal medya kullanım oranı, moderasyon
  kuyruğu gecikmeleri, nefret söylemi raporlama istatistikleri.
  → ⬜ **Kaynak bulunacak** (TÜİK hane halkı BT kullanımı, Medya ve Hukuk
  Çalışmaları Derneği nefret söylemi raporları). Kaynakçaya girecek.
- **Mevcut çözümlerin ölçülmüş kusuru.** Devralınan motorun T0 ölçümü, bu
  iddianın kendi verimizle kanıtı: örtük saldırı diliminde **duyarlılık
  %0,0**. "Kelime listesi yetmez" cümlesi burada bir görüş değil, bir ölçüm.

### 3.2 Sistem mimarisi ve yöntem — **raporun ağırlık merkezi**

Anlatım sırası, `00_URUN_TANIMI.md` §4'teki hattı izler. Her adım için
rapora girmesi gerekenler:

| Adım | Kaynak dosya | Rapora ne yazılacak |
|---|---|---|
| Normalizasyon | `normalization/turkish_normalizer.dart` | Çift varyant üretimi, gizleme hilelerine direnç, aksan katlamanın yan etkileri |
| Morfoloji | `normalization/turkish_morphology.dart` | Eklemeli yapıda kök eşleşmesi, bildirme eki tespiti |
| Sözlük | `lexicon/toxicity_lexicon.dart` | Kategori yapısı; **kimlik adı içermediği ve bunun testle korunduğu** |
| Örtük katman | `detect/implicit_patterns.dart` | 8 edimbilimsel aile, 50 örüntü — örneklerle |
| Nefret katmanı | `detect/hate_patterns.dart` | Yuva–kuruluş ayrımı, 5 aile, şiddet katsayıları |
| Bağlam | `context/context_analyzer.dart` | Saldırı/iltifat/şikâyet/öz-ifade çarpanları, retorik olumsuzlama |
| Skor | `civility_engine.dart` | Noisy-OR birleştirme, eşik seçimi |
| Yeniden yazma | `rewrite/rewrite_suggester.dart` | İki mod (öbek / yerinde), ek koruması |

**Çizilecek görseller** (⬜):
1. Uçtan uca hat diyagramı — cihaz sınırı **kalın çizgiyle** işaretlenmiş,
   sunucu adımının yokluğu görsel olarak vurgulu.
2. Yuva–kuruluş şeması: `[kimlik terimi] + [düşmanca kuruluş] → nefret`,
   `[kimlik terimi] yalnız → hiçbir şey`.
3. Bağlam çarpanı örneği: tek kelime "aptal", beş cümle, beş farklı sonuç.

**Bu bölümün en güçlü tek anlatısı** — yüklem eki şartı:

```
"Suriyeliler hayvandır"                   → yakalanır
"Suriyeli gönüllüler hayvan haklarıyla…"  → yakalanmaz  (nesne konumu)
"Suriyeliler hayvanları sever"            → yakalanmaz  (çoğul ≠ yüklem)
```

Aynı iki kelime yan yana; ayrımı yapan şey Türkçe'nin ek yapısı. İlk sürüm
burada yanlış pozitif üretiyordu ve şart **ölçüm sayesinde** eklendi. Bu,
"ölçüm altyapısı gerçekten işe yarıyor" iddiasının somut kanıtıdır — jüriye
anlatılacak hikâye budur.

### 3.3 Doğrulama ve metrikler

Kaynak: `04_MODEL_DEGERLENDIRME.md` — tablolar doğrudan aktarılabilir.

**Rapora giren dört tablo:**

1. **Gelişim (T0→T3)** — §3.1. Devralınan motordan bugüne.
2. **Dilim bazında** — §3.2. Örtük saldırıda %0,0 → %100,0.
3. **Katman izolasyonu (A/B)** — §3.3. Duyarlılık +54,2 puan, **kesinlik
   kaybı 0,0 puan.** Bu tablo tek başına "Teknik Yeterlilik" kriterinin en
   iyi kanıtıdır.
4. **Genelleme (ayrık küme)** — §5. **F1 %84,2.**

⚠️ **Metodolojik dürüstlük paragrafı — atlanamaz.** Rapora aynen şu anlamda
bir metin girmeli:

```
Geliştirme kümesinde ölçülen F1 %99,6 bir genelleme kanıtı değildir: kümeyi
de örüntüleri de aynı kişi yazmıştır ve örüntüler küme görüldükten sonra
yazılmıştır. Bu nedenle ayrık bir küme kurulmuş, cümleler örüntülerin düzenli
ifadelerine bakılmadan yazılmış, ölçüm bir kez alınmış ve sonuç düzeltme
yapılmadan kaydedilmiştir. Raporlanan genelleme başarımı bu ölçümdür:
F1 %84,2 (kesinlik %88,9, duyarlılık %80,0). Ayrık küme bu ölçümden sonra
motor düzeltmeleri için kullanıldığından yanmıştır; aynı kümede bugün
ölçülen %99,0 değeri genelleme olarak raporlanamaz. Metriklerin tam
bağımsızlığı için ikinci bir etiketleyicinin kodu ve mevcut kümeleri
görmeden üreteceği bağımsız bir küme ve hakemler arası uyum (Cohen's kappa)
ölçümü gerekmektedir; bu, projenin bilinen ve açıkça beyan edilen sınırıdır.
```

Bu paragraf **puan kaybettirmez, kazandırır.** Koşulsuz bir %99, jürinin ilk
soracağı yerdir; koşullarını kendi yazan bir rapor o soruyu kapatır.

### 3.4 Yapay zekâ mimarisi ve LLM kullanılmama gerekçesi

Kaynak: `03_LLM_SERVISI.md` — tamamı bir mimari karar kaydıdır.

Rapora giren çerçeve: *servis yazıldı, 50 testle doğrulandı, onay kapısı
uçtan uca sınandı, sonra kasıtlı olarak kaldırıldı.* Üç gerekçe (tez
zayıflaması, üçüncü taraf bağımlılığı, kritik olmayan katkı) ve kabul edilen
bedel (yeniden yazma akıcılığı) açıkça yazılır.

**Korunan ilke — raporun en alıntılanabilir cümlesi:**

> Model bir öneri kaynağıdır, bir otorite değildir. Karar mercii
> deterministik ve denetlenebilir olan motordur.

Testle kanıtlanmış örnek: model `"sen tam bir aptalsın"` (0,55) yerine
`"sen tam bir şerefsizsin"` (0,88) önerdiğinde öneri kullanıcıya ulaşmadı.

### 3.5 Etik ve mahremiyet

Kaynak: `00_URUN_TANIMI.md` §6 — beş madde olduğu gibi.

Şartnamenin **"Veri, model, etik ve performans dokümanı"** teslimatı bu
bölümden türer. Eklenecekler:

- **Veri beyanı:** 330 örneğin tamamı sentetiktir, hiçbiri gerçek kullanıcı
  verisi değildir, kişisel veri işlenmemiştir. KVKK açısından: varsayılan
  akışta kişisel veri **hiç toplanmaz**, çünkü metin cihazdan çıkmaz.
- **Model beyanı:** üçüncü taraf model, API veya telemetri yoktur.
- **Yanlılık beyanı:** kimlik söz varlığı 40 terimle sınırlıdır; kapsanmayan
  gruplar için sistem sessizdir ve bu, o grupları korumasız bırakır. Bilinen
  ve beyan edilen bir yanlılıktır.

### 3.6 Uygulanabilirlik ve ölçeklenebilirlik ⬜

Henüz yazılmadı. Yazılacaklar:

- **Ölçeklenebilirlik sunucu maliyeti değildir.** Cihaz üstü çalıştığı için
  kullanıcı başına marjinal sunucu maliyeti sıfırdır; 1 kullanıcı ile 10
  milyon kullanıcı arasında altyapı farkı yoktur. Bu, mimarinin doğrudan
  sonucudur ve rakiplerin sunucu tabanlı moderasyonuna karşı somut bir
  üstünlüktür.
- **Entegrasyon yüzeyi.** `civility_core` bağımsız bir Dart paketidir;
  NSosyal istemcisine bir metin giriş alanı sarmalayıcısı olarak eklenir.
- **Cihaz bütçesi.** 323 µs / çözümleme, 16 ms kare bütçesinin %2'si;
  debounce gerekmez. Paket boyutu ve bellek ayak izi ⬜ **ölçülecek**.
- **Taşınabilirlik.** Motor saf Dart'tır, platform kanalı kullanmaz.

### 3.7 Riskler ve bilinen sınırlar

Kaynak: `04_MODEL_DEGERLENDIRME.md` §6 — tablo olduğu gibi aktarılır.
Gizlenmez; her sınırın yanına **kapatma yolu** yazılır.

### 3.8 İş modeli — bir paragraf, fazlası değil

Bu dikeyde ağırlık %0. Yazılacak tek şey: platform içi bir güvenlik/refah
özelliği olarak konumlanır; gelir modeli doğrudan değil, kullanıcı elde
tutma ve moderasyon maliyeti düşüşü üzerinden dolaylıdır.

---

## 4. Rapordan önce kapatılması gereken boşluklar

| # | Boşluk | Neden rapora etki eder | Sorumlu |
|---|---|---|---|
| 1 | **Ölçüm yeniden çalıştırılmadı** — `dart` bu makinede PATH'te yok | Rapordaki her sayı 1 Ağustos tarihli; 3 Ağustos'taki yeniden yazıcı değişikliği (`185efab`) sonrası tazelenmedi | 🔴 |
| 2 | **Uzak git deposu yok** | "Kaynak kod" teslimatı verilemez | 🔴 |
| 3 | **Git kalıcı kurulu değil** — yalnızca bir runtime önbelleğinde | Önbellek temizlenirse depoya erişim kaybolur | 🔴 |
| 4 | Mimari diyagramlar çizilmedi | Teknik Yeterlilik %35 — görselsiz anlatım zayıf | ⬜ |
| 5 | Bağımsız etiketleyici / kappa yok | Metrik koşullu kalır (§3.3'teki paragraf bunu dürüstçe karşılıyor) | 🟡 |
| 6 | Kaynakça toplanmadı | Akademik zemin eksik görünür | ⬜ |
| 7 | Test sayısı doğrulanmadı | Statik sayım 97 çekirdek + 10 mobil; belgelerde 101 + 10 yazıyor. Fark döngüyle üretilen testlerden olabilir — `dart test` ile kesinleştir | 🟡 |

---

## 5. Kaynakça — toplanacak ⬜

Aranacak başlıklar:

- Türkçe saldırgan dil tespiti: OffensEval 2020 Türkçe alt görevi
  (Çöltekin'in Türkçe offensive language corpus'u), BERTurk
- Nefret söylemi tespitinde kimlik terimi yanlılığı — İngilizce yazında
  "identity term bias" / "false positive bias" çalışmaları. **Projenin
  kimlik-yuvası tasarımı doğrudan bu literatüre cevap veriyor; atıf
  vermek raporun akademik ağırlığını ciddi biçimde artırır.**
- Cihaz üstü çıkarım ve mahremiyet: federated / on-device NLP
- Davranış değişikliği: yayın öncesi uyarıların etkisi üzerine platform
  çalışmaları (Twitter/X'in "are you sure you want to post this" denemeleri
  bu ürünün en yakın ampirik dayanağıdır — mutlaka bulunup atıf verilmeli)

---

## 6. Teslimat listesi — rapor dışı kalemler

Şartname 14 kalem istiyor. Rapor bunlardan yalnızca biri.

| # | Teslimat | Durum |
|---|---|---|
| 1 | Teknik rapor | 🟨 Bu belge |
| 2 | Sunum dosyası | ⬜ |
| 3 | Kullanıcı senaryoları | ⬜ |
| 4 | Çalışan prototip | 🟩 |
| 5 | Kaynak kod | 🔴 Uzak depo yok |
| 6 | Proje / demo videosu | ⬜ |
| 7 | İş modeli | 🟨 Bir paragraf yeter (%0 ağırlık) |
| 8 | Yapay zekâ mimarisi dokümanı | 🟩 |
| 9 | Veri, model, etik ve performans | 🟩 |
| 10 | UI/UX tasarımları | 🟩 30 ekran |
| 11 | Kullanıcı akışları | ⬜ |
| 12 | Kullanıcı araştırması özeti | ⬜ Gerçek kullanıcı gerekiyor |
| 13 | Kullanılabilirlik testi sonuçları | ⬜ Gerçek kullanıcı gerekiyor |
| 14 | Erişilebilirlik değerlendirmesi | ⬜ |
