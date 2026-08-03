# Yol Haritası — Başvurudan Finale

**Bugün:** 1 Ağustos 2026
**Kritik tarihler:** Başvuru 20 Ağustos · Teknik rapor 24 Ağustos 17:00 ·
Final sunumu 14 Eylül 17:00 · TEKNOFEST Şanlıurfa 30 Eylül – 4 Ekim

---

## 🔴 Faz 0 — Engeller (bu hafta, pazarlık yok)

Bunlar çözülmeden diğer her şey anlamsız.

| # | İş | Neden kritik | Süre |
|---|---|---|---|
| 0.1 | **En az 1 takım arkadaşı bul** | Şartname: *"bireysel başvuru kabul edilmemektedir, en az 2 en fazla 5 kişi"*. Tek kişiyle başvuru **geçersiz**. | Acil |
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
| ~~Etiketli veri kümesi oluştur~~ | ✅ 330 örnek + ölçüm altyapısı — `04_MODEL_DEGERLENDIRME.md` |
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
| Sistem mimarisi | `00_URUN_TANIMI.md` §4 + `03_LLM_SERVISI.md` §1–2 |
| Yöntem | `packages/civility_core/` kaynak kodu ve yorumları |
| Doğrulama / metrikler | **`04_MODEL_DEGERLENDIRME.md`** — kesinlik/duyarlılık/F1 |
| Model karşılaştırması | `04_MODEL_DEGERLENDIRME.md` §3.3 (katman A/B) |
| Etik ve mahremiyet | `00_URUN_TANIMI.md` §6 + `03_LLM_SERVISI.md` §6 |
| Performans | ~174 µs ölçümü |
| Büyük dil modeli kullanımı | `03_LLM_SERVISI.md` §3–5 |

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
   ✅ **Tamamlandı (1 Ağustos).** `server/` — 48 test, doğrulama kapısı
   dahil. Bkz. `03_LLM_SERVISI.md`. Kalan tek iş: gerçek API anahtarıyla
   uçtan uca duman testi.
3. **Topluluk sağlığı paneli** — anonim toplulaştırılmış sinyaller.
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
| 1 | Teknik rapor | ⬜ Şablon indirilecek |
| 2 | Sunum dosyası | ⬜ |
| 3 | Kullanıcı senaryoları | ⬜ |
| 4 | Çalışan prototip | 🟩 Nezaket Koçu ekranı + çalışan LLM servisi |
| 5 | Kaynak kod | 🟩 Git deposu kuruldu (`main`, 276 dosya); uzak depoya push kaldı |
| 6 | Proje / demo videosu | ⬜ |
| 7 | İş modeli ve gelir modeli | ⬜ (bu temada ağırlık %0 — kısa tutulabilir) |
| 8 | Yapay zekâ mimarisi dokümanı | 🟩 `00_URUN_TANIMI.md` §4 + `03_LLM_SERVISI.md` |
| 9 | Veri, model, etik ve performans | 🟩 `04_MODEL_DEGERLENDIRME.md` — 330 etiketli örnek, F1 ölçüldü |
| 10 | UI/UX tasarımları | 🟩 30 ekran mevcut |
| 11 | Kullanıcı akışları | ⬜ |
| 12 | Kullanıcı araştırması özeti | ⬜ Gerçek kullanıcı gerekiyor |
| 13 | Kullanılabilirlik testi sonuçları | ⬜ Gerçek kullanıcı gerekiyor |
| 14 | Erişilebilirlik değerlendirmesi | ⬜ |

🟩 hazır · 🟨 kısmen · ⬜ yapılmadı
