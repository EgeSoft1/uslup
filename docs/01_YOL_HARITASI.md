# Yol Haritası — Başvurudan Finale

**Son güncelleme:** 12 Ağustos 2026
**Kritik tarihler:** Başvuru 20 Ağustos (**8 gün**) · Teknik rapor 24 Ağustos
17:00 (12 gün) · Final sunumu 14 Eylül 17:00 · TEKNOFEST Şanlıurfa 30 Eylül – 4 Ekim

**Türetilen belgeler:** başvuru metni → `05_BASVURU_METNI.md` ·
teknik rapor planı → `06_TEKNIK_RAPOR_TASLAGI.md`

---

## 🔴 Faz 0 — Engeller (bu hafta, pazarlık yok)

Bunlar çözülmeden diğer her şey anlamsız.

| # | İş | Neden kritik | Süre |
|---|---|---|---|
| ~~0.1~~ | ~~**En az 1 takım arkadaşı bul**~~ | ✅ **Tamamlandı (12 Ağustos).** 1 takım arkadaşı hazır → takım 2 kişi, şartname §3'ün alt sınırı karşılandı. ⬜ Kalan: KYS'de takıma eklenmesi. | — |
| ~~0.2~~ | ~~**Git kur + repo başlat**~~ | ✅ **Tamamlandı (3 Ağustos).** Git 2.55.0.3 kuruldu, depo `main` dalında başlatıldı, ilk commit atıldı (276 dosya, 3,4 MB). Flutter sarmalayıcısı da artık geçici çözümsüz çalışıyor. | — |
| 0.3 | KYS'de takım oluştur, Google Groups'a katıl | Şartname: her takımdan en az 1 kişinin gruba katılması **zorunlu** | 1 saat |

### 0.1 hakkında — nerede aranır
Aranan profil (şartname farklı disiplinleri teşvik ediyor):
- **Veri bilimi / NLP** — model eğitimi ve metrikler için (en yüksek öncelik)
- **UI/UX veya tasarım** — teslimat listesinde 5 kalem tasarım çıktısı var
- İkinci bir yazılımcı da olur; asıl eksik NLP tarafı.

Kanallar: üniversite yapay zekâ/veri bilimi kulüpleri, T3 Vakfı Deneyap
toplulukları, bölüm hocaları üzerinden, TEKNOFEST takım arkadaşı arama grupları.

### 0.2 — yapıldı; kalan iş uzak depo

Yerel depo hazır (`a5eb597`, 276 dosya, 3,4 MB — öngörülen ~3 MB ile uyumlu).
`.gitignore` `target/`, `build/`, `.dart_tool/` dizinlerini dışlıyor;
`.gitattributes` satır sonlarını LF'e sabitliyor (işletim sistemi karışık
takımda sahte diff'leri önler).

Kaynak kodun teslim edilebilir olması için sıradaki adım uzak depo:

```powershell
# GitHub'da boş bir depo açtıktan sonra:
cd C:\TurkiyeMesajlasma
git remote add origin https://github.com/<kullanici>/<repo>.git
git push -u origin main
```

---

## 🟠 Faz 1 — Başvuru (2–20 Ağustos)

Başvuru formu kısa; asıl iş formu doldurmak değil, **rapora hazır olmak**.

| İş | Çıktı |
|---|---|
| Proje adı ve marka kimliği kesinleştir | Şu an çalışma adı "Nezaket Koçu" |
| Başvuru metnini yaz | `docs/00_URUN_TANIMI.md` §1–3'ten türetilir |
| ~~Etiketli veri kümesi oluştur~~ | ✅ 336 örnek + ölçüm altyapısı — `04_MODEL_DEGERLENDIRME.md` |
| ~~Araç zincirini kur, sayıları tazele~~ | ✅ 12 Ağustos: Flutter 3.44.9 + MinGit → D:; 132 test geçiyor, ölçüm yeniden alındı |
| ~~Gönderge çözümlemesi~~ | ✅ 12 Ağustos (`510a5ec`) — en büyük belgelenmiş kaçak kapatıldı |
| **Bağımsız ikinci küme** (takım arkadaşı) | 🔴 Metriklerin bağımsız olması için şart |
| Danışman ara (zorunlu değil, tavsiye ediliyor) | NLP/dilbilim alanından akademisyen |

### Veri kümesi — durum

**Yapıldı:** 330 etiketli örnek (250 geliştirme + 80 ayrık), beş dilimli,
kesinlik/duyarlılık/F1/F0.5 ölçen değerlendirme altyapısıyla birlikte.
Ölçülen genelleme: **F1 = %84,2** (ayrık küme, tek çalıştırma).

> ⚠️ Ayrık küme o ölçümden sonra motor düzeltmeleri için kullanıldı ve
> **yanmıştır**; bugün aynı kümede F1 %99,0 çıkıyor ama bu sayı genelleme
> olarak raporlanamaz. Raporlanacak sayı %84,2'dir.
> Gerekçe: `04_MODEL_DEGERLENDIRME.md` §5.

**Eksik olan ve takım arkadaşının yapması gereken:**

1. **Bağımsız küme.** Mevcut iki küme de aynı kişi tarafından yazıldı ve
   örüntüler kümeler görüldükten sonra yazıldı. Bu, metriği zayıflatır.
   İkinci etiketleyici, kodu ve mevcut kümeleri **görmeden** kendi kümesini
   üretmeli.
2. **Hakemler arası uyum (Cohen's kappa).** Şu an tek etiketleyici var; kappa
   ölçülemedi. İki kişi aynı 300 cümleyi bağımsız etiketleyip uyumu
   hesaplamalı — rapora çok güçlü malzeme olur.
3. **Açık veri kümeleri.** Türkçe saldırgan dil için akademik kümeler mevcut
   (OffensEval Türkçe alt görevi gibi). Lisans şartları kontrol edilmeli;
   uygunsa mevcut küme bunlarla genişletilir.

Bu üçü yapılmadan raporda metrik yazılabilir, ama **koşulları da
yazılmalıdır**. Koşulsuz bir F1 değeri jüri tarafından haklı olarak
sorgulanır.

---

## 🟡 Faz 2 — Teknik rapor (20–24 Ağustos)

⚠️ **Sert kural:** *"Belirlenen tarih ve saat sonrasında yapılan yüklemeler ile
şablona uygun olmayan, eksik veya hatalı yüklenen raporlar değerlendirmeye
alınmaz ve ilgili takımlar yarışmadan elenir."*

- TEKNOFEST'in **güncel rapor şablonunu** KYS'den indir. Kendi formatını
  kullanma — şablon dışı rapor doğrudan elenir.
- **22 Ağustos'a kadar bitir**, 24'ü tampon olarak bırak. Son gün KYS
  yoğunluğundan yavaşlar.

Raporun ana bölümleri ve kaynakları:

| Rapor bölümü | Kaynak |
|---|---|
| Problem tanımı | `00_URUN_TANIMI.md` §2 |
| Yenilikçi yön | `00_URUN_TANIMI.md` §3 |
| Sistem mimarisi | `00_URUN_TANIMI.md` §4 (tamamı cihaz üstü) |
| Yöntem | `packages/civility_core/` kaynak kodu ve yorumları |
| Doğrulama / metrikler | **`04_MODEL_DEGERLENDIRME.md`** — kesinlik/duyarlılık/F1 |
| Model karşılaştırması | `04_MODEL_DEGERLENDIRME.md` §3.3 (katman A/B) |
| Etik ve mahremiyet | `00_URUN_TANIMI.md` §6 + `03_LLM_SERVISI.md` §2 |
| Performans | `04_MODEL_DEGERLENDIRME.md` §3.4 — **322,7 µs** (T3, her iki örüntü katmanı dahil) |
| Büyük dil modeli kullanımı | `03_LLM_SERVISI.md` — **neden kullanmadığımız** |

---

## 🟢 Faz 3 — Ürün derinleştirme (Ağustos–Eylül)

Rapor teslim edildikten sonra, sonuçlar açıklanana kadar (2 Eylül) boş
durulmaz. Öncelik sırası:

1. **BERTurk + ONNX kademesi** — sinir ağı sınıflandırıcısı.
   `ToxicityClassifier` arayüzü hazır; `OnnxTurkishClassifier` yazılacak.
   Deterministik katman kalır, ön filtre olur.
   **Artık ölçülebilir:** aynı kümede karşılaştırmalı ölçüm altyapısı hazır
   (`bin/evaluate.dart --karsilastir`). Sinir ağının deterministik katmandan
   daha iyi olduğu iddiası ancak bu karşılaştırmayla kanıtlanabilir.
2. ~~**LLM yeniden yazma** — sunucu tarafı, kullanıcı onaylı.~~
   ❌ **Kaldırıldı (3 Ağustos).** Yazıldı ve ölçüldü (50 test, doğrulama
   kapısı dahil), sonra kasıtlı olarak kapsam dışına alındı: üçüncü taraf
   API bağımlılığı ve "metin cihazdan çıkmaz" iddiasına eklediği istisna
   nedeniyle. Gerekçe: `03_LLM_SERVISI.md`.
   **Yerine:** yerel yeniden yazıcıya morfoloji farkındalığı.
   ✅ **Yapıldı (3 Ağustos, `185efab`).** İki mod, yan cümle düzeyinde
   seçiliyor: kişiye yöneltilmiş saldırıda **öbek modu** (yan cümlenin tamamı
   nötr kalıpla değişir), nesneyi niteleyen sıfatta **yerinde mod** (kelime
   yerinde değişir ve taşıdığı ek korunur: "bu karar salakça" → "bu karar
   hatalı"). Ölçüm, önceki durumda 130 vakanın 119'unun "öneri üretti"
   göründüğü hâlde çoğunun anlamsız olduğunu göstermişti.
   ⬜ **Kalan:** düzeltme sonrası akıcılık ölçümü (`bin/rewrite_audit.dart`)
   rapora sayı olarak girmeli.
3. ~~**Topluluk sağlığı paneli**~~ ✅ **Yapıldı (12 Ağustos).** Anonim
   toplulaştırma `civility_core` içinde (saf Dart, 14 test); panel
   `mobile/lib/presentation/community/`. Sinyal sınıfı metin taşıyamaz ve
   bu yapısal bir testle korunuyor; 5 gözlemin altındaki kategoriler
   k-anonimlik gereği açılmıyor. Panelde ihlal eden mesajların listesi
   **yoktur ve olamaz** — ürünün tezi budur.
   ⬜ **Kalan:** kalıcılık yok (kasıtlı), gerçek kullanıcıyla doğrulanmadı.
4. **Kullanıcı testi** — 5–8 kişi, görev tabanlı. Teslimat listesindeki
   *"kullanılabilirlik testi sonuçları"* ve *"kullanıcı araştırması özeti"*
   bundan çıkar.
5. **Erişilebilirlik değerlendirmesi** — ekran okuyucu, kontrast oranları,
   dokunma hedefi boyutları. Ayrı bir teslimat kalemi.

---

## Teslimat kontrol listesi

Şartname 14 kalem istiyor. Mevcut durum:

| # | Teslimat | Durum |
|---|---|---|
| 1 | Teknik rapor | 🟨 Plan hazır: `06_TEKNIK_RAPOR_TASLAGI.md`; şablon KYS'den indirilecek |
| 2 | Sunum dosyası | ⬜ |
| 3 | Kullanıcı senaryoları | 🟩 `07_KULLANICI_AKISLARI.md` §3 — 5 senaryo, 4 persona |
| 4 | Çalışan prototip | 🟩 Nezaket Koçu ekranı + sohbet kutusu + topluluk paneli, tamamen cihaz üstü |
| 5 | Kaynak kod | 🔴 Git deposu yerel hazır; **uzak depoya push kaldı** |
| 6 | Proje / demo videosu | ⬜ |
| 7 | İş modeli ve gelir modeli | 🔴 **Ağırlık %0 DEĞİL, %5** (rapor şablonu 20 Ağustos). Rapor rubriğinde 6.1+6.2 = 10 puan. Bkz. `08_RAPOR_BOSLUK_ANALIZI.md` §1 |
| 8 | Yapay zekâ mimarisi dokümanı | 🟩 `00_URUN_TANIMI.md` §4 + `03_LLM_SERVISI.md` |
| 9 | Veri, model, etik ve performans | 🟩 `04_MODEL_DEGERLENDIRME.md` — 336 etiketli örnek, F1 ölçüldü |
| 10 | UI/UX tasarımları | 🟩 30 ekran + topluluk sağlığı paneli |
| 11 | Kullanıcı akışları | 🟩 `07_KULLANICI_AKISLARI.md` §4 — 4 akış diyagramı |
| 12 | Kullanıcı araştırması özeti | ⬜ Gerçek kullanıcı gerekiyor |
| 13 | Kullanılabilirlik testi sonuçları | ⬜ Gerçek kullanıcı gerekiyor |
| 14 | Erişilebilirlik değerlendirmesi | 🟨 Akışa gömülü kararlar yazıldı (`07` §5); tam değerlendirme kaldı |

🟩 hazır · 🟨 kısmen · ⬜ yapılmadı
