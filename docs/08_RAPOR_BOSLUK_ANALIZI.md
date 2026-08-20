# Teknik Rapor — Şablon Analizi ve Boşluk Haritası

**Tarih:** 20 Ağustos 2026 · **Teslim:** 24 Ağustos 2026, 17.00 (TSİ) → **4 gün**
**Kaynak:** `NSosyal_Inovasyon_2026_-_Proje_Teknik_Raporu_1_u6IVb.docx`
**Durum:** Başvuru gönderildi. Sıradaki kapı teknik rapor (sonuç: 2 Eylül).

---

## 1. ⚠️ AĞIRLIK TABLOSU DEĞİŞTİ — eski planlama geçersiz

Şablonun sonundaki resmî tablo, şartname PDF'inden **farklı**. Sosyal Yapay
Zekâ sütunu:

| Kriter | Bizim varsaydığımız | **Şablondaki gerçek** | Fark |
|---|---|---|---|
| Yenilikçilik ve Özgünlük | %20 | %20 | — |
| Teknik Yeterlilik ve Uygulanabilirlik | %35 | **%30** | −5 |
| Problemi Çözme Başarısı | %20 | %20 | — |
| Kullanıcı Deneyimi (UI/UX) | %10 | %10 | — |
| Sunum ve Prototip Kalitesi | %15 | %15 | — |
| **İş Modeli ve Sürdürülebilirlik** | **%0** | **%5** | **+5** |

Şablon bunu açıkça not ediyor: *"Yeşil vurgulu hücreler: orijinal şartnamede
%0 olan, bu düzeltmede asgari %5'e çekilen alanlardır."*

### Bunun iki sonucu var

1. `06_TEKNIK_RAPOR_TASLAGI.md` §2'deki *"İş Modeli %0 → kısa tut, bu dikeyde
   puan getirmiyor"* stratejisi **artık yanlış** ve rapor rubriğinde
   6.1 + 6.2 = **10 puan** demek. Aynı hata `01_YOL_HARITASI.md` §172'de de var.
2. `00_URUN_TANIMI.md` §5'teki *"Teknik Yeterlilik %35"* cümlesi **%30** olmalı.

---

## 2. Şablonun dayattığı yapı — mevcut taslak buna uymuyor

Şablon 9 zorunlu ana bölüm dayatıyor. `06_TEKNIK_RAPOR_TASLAGI.md` kendi
şemasıyla yazılmış (3.1 Problem, 3.2 Mimari, 3.3 Doğrulama…) ve bu şema
şablonla **eşleşmiyor.** Şablon kuralı net: *"şablona uymayan/eksik/geç
raporlar değerlendirmeye alınmaz."* → İçerik iyi, **kap yanlış.**

| # | Şablon bölümü | Puan | Bizdeki kaynak |
|---|---|---|---|
| 1.1 | Proje Konusu ve Amacı | 7 | `00` §1, §2 |
| 1.2 | Proje Kapsamı ve Yöntemi | 8 | `00` §4, §5, §7 |
| 2.1 | Problem Tanımı ve Mevcut Çözümler | 7 | `00` §2 |
| 2.2 | Çözüm Fikri, Özgünlük ve **Yerlilik** | 8 | `00` §3 |
| 3.1 | Yöntem, Altyapı ve **Sürüm Kontrolü** | 7 | `05` §7 |
| 3.2 | Model ve Veri Doğrulama | 6 | `04` tamamı |
| 3.3 | Kullanıcı Deneyimi (UI/UX) | 7 | `07` tamamı |
| 4.1 | Verimlilik ve Etkinlik | 5 | `04` §3.4 |
| 4.2 | Hedef Kitle | 5 | `05` §9, `07` §2 |
| 4.3 | Teknolojik Yenilik ve Uygulanabilirlik | 5 | `00` §3, §4 |
| 5.1 | **Toplumsal Fayda ve Erişim Potansiyeli** | **10** | `00` §6, `05` §9 |
| 6.1 | Ticarileştirme Potansiyeli ve İş Modeli | 5 | ❌ yok |
| 6.2 | Finansal, Teknik ve Sosyal Sürdürülebilirlik | 5 | ❌ yok |
| 7.1 | İş Paketleri ve Zamanlama | 5 | `01` (biçim değişmeli) |
| 8.1 | Takım Organizasyonu ve Roller | 5 | ❌ yok |
| 9 | Kaynakça — formata uygunluk | 5 | ❌ yok |
| | **TOPLAM** | **100** | |

5.1 tek başına 10 puan — rubriğin en ağır tek maddesi. Mevcut taslakta
"Yaygın Etki" diye ayrı bir bölüm **yok**.

---

## 3. Boşluk haritası — puan riskiyle sıralı

### 🔴 Kritik (toplam ~25 puan elde edilemez durumda)

| Boşluk | Nerede | Puan | Neden kritik |
|---|---|---|---|
| **Kaynakça ve atıf yok** | 9 + 2.1 | **8** | Rubrik "en az bir resmî kaynak veya akademik veri" (2p), "problemin büyüklüğünü gösteren istatistik" (1p) ve Kaynakça formatı (5p) istiyor. Dokümanlarda **tek atıf yok.** |
| **İş modeli / sürdürülebilirlik yok** | 6.1 + 6.2 | **10** | Artık %0 değil. Gelir modeli, katma değer, iş ortaklıkları, finansal/teknik/sosyal sürdürülebilirlik — hepsi ayrı kontrol maddesi. |
| **GitHub deposu yok** | 3.1 | **2** | `git remote -v` boş. "Repo bağlantısı paylaşılmış" (1p) + "commit geçmişiyle takip edilebilir süreç" (1p). Dolaylı etkisi çok daha büyük: jüri kodu göremezse bütün teknik iddialar doğrulanamaz. |
| **Erişilebilirlik + kullanılabilirlik testi yok** | 3.3 | **3** | "Erişilebilirlik yaklaşımı belirtilmiş" (2p), "kullanılabilirlik testi sonucu" (1p). |
| **Takım bölümü yok** | 8.1 | **2-3** | Görev dağılımı tablosu + disiplin çeşitliliği. 2 kişiyiz; "ekip yapısı ihtiyaçları karşılıyor" maddesi zorlanır. **İsim ve fotoğraf yasak.** |

### 🟡 Kısmi (iyileştirilebilir)

| Boşluk | Nerede | Puan riski | Ne gerekiyor |
|---|---|---|---|
| **"Model eğitimi süreci"** | 3.2 | 2 | Eğitilmiş model yok; kural/örüntü motoru var. Bu bir eksiklik değil ama rubrik "model eğitimi" diyor. Karşılığı: örüntülerin etiketli kümeden türetilme süreci + **aşırı öğrenme önlemi olarak ayrık küme** (bu maddede güçlüyüz: rubrik tam olarak bunu soruyor). |
| **Somut piyasa kıyası yok** | 2.2 | 2 | Karşılaştırma tablosu var ama **isim yok**. Perspective API, OpenAI Moderation gibi gerçek ürünler adıyla kıyaslanmalı. |
| **Verimlilik ölçülebilir değil** | 4.1 | 2 | 268 µs var ama "verimlilik artışı" argümanı sayıya bağlanmamış (ör. moderasyon kuyruğunda beklenen azalma). |
| **Hedef kitle büyüklüğü** | 4.2 | 1 | Türkiye sosyal medya kullanıcı sayısı → yine kaynak gerekiyor. |
| **İş paketleri görseli** | 7.1 | 2 | `01_YOL_HARITASI.md` var ama Gantt/tablo biçiminde değil ve yarışma tarihleriyle (24 Ağu / 2-7 Eyl / 14 Eyl) hizalanmamış. |

### 🟢 Hazır ve güçlü

- **2.2 Yerlilik (1p):** motor tamamen özgün, Türkçe'ye özel, sıfır yabancı
  API bağımlılığı. Bu maddede tam puan alınmaması için sebep yok.
- **3.2 Aşırı öğrenme önlemi + metrikler (2p):** ayrık küme ve dürüst
  %99,6 → %84,2 farkının raporlanması, rubriğin tam istediği şey.
- **4.3 Teknolojik yenilik (5p):** katman mimarisi, kimlik-yuva tasarımı.
- **3.3 Kullanıcı akışları (2p):** `07_KULLANICI_AKISLARI.md` hazır.

---

## 4. Format kuralları — uyulmazsa eleme

- En fazla **30 sayfa** (kapak, içindekiler, kaynakça, ekler dahil)
- Kapak, İçindekiler, Kaynakça için **3 ayrı sayfa**
- Yazı tipi **Arial 12**; başlık **Arial Black 14**
- Satır aralığı **1.15**, **iki tarafa yaslı**, kenar boşlukları **2.5 cm**
- Metin içi atıf **köşeli parantez**: [1], [4,7,21], [5-11]
- Cümleler birbirinin tekrarı olmamalı
- **Tanıtım videosu bu aşamada İSTENMİYOR** (final teslimatı)
- Kapakta: Proje Adı, Takım Adı, Takım ID, Başvuru ID, Tematik Alan

---

## 5. Tahmini puan

Kaba tahmindir, garanti değildir.

| Senaryo | Tahmin |
|---|---|
| Bugünkü malzemeyle yazılırsa | **~68 / 100** |
| Aşağıdaki 4 günlük plan uygulanırsa | **~88 / 100** |

Aradaki ~20 puanın tamamı **yazı işi ve kurulum**, yeni motor geliştirme değil.

---

## 6. 4 günlük plan

### 20 Ağustos (bugün) — engelleri kaldır
1. **GitHub deposu aç, push et.** Tek teknik engel; 3.1'i açar ve tek-kopya
   riskini bitirir.
2. **Dart SDK kur** (C:'de 26,9 GB boş var). `dart run bin/evaluate.dart --hepsi`
   → rapordaki her sayı yeniden doğrulanır.

### 21 Ağustos — eksik bölümleri yaz
3. **Kaynakça + atıflar** (8 puan): Türkiye sosyal medya kullanım
   istatistikleri, siber zorbalık yaygınlığı, Türkçe NLP / nefret söylemi
   tespiti akademik kaynakları, Perspective API dokümantasyonu.
4. **6.1 + 6.2 İş modeli ve sürdürülebilirlik** (10 puan): platform içi
   katman lisanslama, kurumsal/eğitim kullanımı, cihaz üstü çalışmanın
   sıfır çıkarım maliyeti = finansal sürdürülebilirlik argümanı.

### 22 Ağustos — kalan boşluklar
5. **8.1 Takım tablosu** (isimsiz, rollerle)
6. **3.3 Erişilebilirlik bölümü** + küçük ölçekli kullanılabilirlik testi
7. **7.1 İş paketleri tablosu**, yarışma tarihleriyle hizalı
8. **2.2 İsimli piyasa kıyası**

### 23 Ağustos — şablona dök
9. İçeriği **.docx şablonuna** taşı, format kurallarını uygula, 30 sayfa
   sınırını kontrol et, mimari diyagramları ekle.

### 24 Ağustos — 17.00'den önce yükle
10. Erken yükle. Son saat sistem yoğunluğu risklidir.
