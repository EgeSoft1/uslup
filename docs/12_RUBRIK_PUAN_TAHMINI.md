# Rubrik Puan Tahmini — Üslup Teknik Raporu

**Tarih:** 24 Ağustos 2026 · **Kaynak:** Şablonun "Puanlama ve Değerlendirme
Esasları" sayfası (100 puan, 16 alt kriter)
**Yöntem:** Her kontrol maddesi, `docs/09_RAPOR_METNI.md`'nin bugünkü hâline
karşı tek tek denetlendi. "Tam" = maddenin istediği şey metinde açıkça var.

---

## 1. Madde madde denetim

| Alt kriter | Tavan | Tahmin | Not |
|---|:--:|:--:|---|
| 1.1 Proje konusu ve amacı | 7 | **7** | Konu, amaç, dikey (Sosyal YZ) ve şartname Bölüm 1 hedefiyle bağ ayrı ayrı yazılı |
| 1.2 Kapsam ve yöntem | 8 | **8** | Kapsam içi/dışı tablosu; teknik + akademik yöntem ayrı; çalışan prototip; zemin hazırlama |
| 2.1 Problem ve mevcut çözümler | 7 | **7** | TÜİK [1], DataReportal [2], UNFPA-KONDA [3], LREC [4]; 4 alternatif ve eksikleri tablosu |
| 2.2 Çözüm, özgünlük, yerlilik | 8 | **8** | 9 satırlık piyasa kıyas tablosu; 3 özgün yön; yerlilik paragrafı |
| 3.1 Yöntem, altyapı, sürüm kontrolü | 7 | **7** | Depo bağlantısı ve commit izlenebilirliği **bugün kazanıldı** |
| 3.2 Model ve veri doğrulama | 6 | **6** | Ön işleme, denetimli model eğitimi (`ml/`), overfitting önlemleri, metrikler |
| 3.3 Kullanıcı deneyimi (UI/UX) | 7 | **6** | Akış + karar + erişilebilirlik tam; **kullanılabilirlik testi sonucu yok → −1** |
| 4.1 Verimlilik ve etkinlik | 5 | **5** | Duyarlılık modeli tablosu + ölçülebilir etkinlik göstergesi (düzeltme oranı) |
| 4.2 Hedef kitle | 5 | **5** | Tanım, büyüklük (62,3 mn / %92,3), üç eksende uyum kanıtı |
| 4.3 Teknolojik yenilik | 5 | **5** | Üç bileşenin teknik detayı; çalışan prototip; üç eksenli ölçeklenme |
| 5.1 Toplumsal fayda | 10 | **10** | Erişim, ekosistem katkısı, 5 somut örnek, yaşam kalitesi |
| 6.1 Ticarileştirme ve iş modeli | 5 | **5** | 4 gelir kanalı tablosu, katma değer, ortaklıklar |
| 6.2 Sürdürülebilirlik | 5 | **5** | Finansal, teknik (3 disiplin), uyum mekanizmaları |
| 7.1 İş paketleri ve zamanlama | 5 | **5** | 11 tamamlanan İP + kilometre taşları + Gantt + yarışma takvimiyle uyum |
| 8.1 Takım organizasyonu | 5 | **5** | Rol tablosu, disiplin katkıları, 2 kişi + danışman |
| 9 Kaynakça | 5 | **5** | 14 künye, yayıncı teyitli, iki kalıp, köşeli parantez atıflar |
| **TOPLAM** | **100** | **99** | |

---

## 2. Bu 99 ne demek, ne demek değil

**Demek olan:** rubrikte istenen her kontrol maddesinin metinde bir karşılığı
var. Yapısal olarak kaybedilen tek madde, yapılmamış kullanılabilirlik
testidir (3.3, −1 puan) ve bu **bilinçli bir dürüstlük tercihidir**:
yapılmamış testi "yürütülmüştür" diye yazmak 1 puan kazandırır, yakalanırsa
raporun tamamının güvenilirliğini götürür.

**Demek olmayan:** jürinin 99 vereceği. Şablon "alt maddeler kısmi/tam
karşılanma oranına göre puanlanıp toplanır" diyor; "kısmi" takdiri jürinindir.
Aynı metne iki jüri farklı puan verir.

| Senaryo | Bant | Koşul |
|---|:--:|---|
| Rubrik-mekanik tavan | **99** | Her madde "tam" sayılırsa |
| **Gerçekçi beklenti** | **84 – 92** | Görseller yerleştirilmiş, biçim kuralları uygulanmış |
| Kötü senaryo | 70 – 78 | Görseller eksik veya kara listedeki ekranlar girmiş |
| Eleme | — | Şablon dışı biçim, 30 sayfa aşımı, şablonun son iki sayfası silinmemiş |

---

## 3. Kalan puanı belirleyen dört şey

| # | İş | Etkilediği madde | Kaybedilebilecek |
|---|---|---|---|
| 1 | **10 şekli yerleştir.** Çapalar ve alt yazılar metinde hazır; beşi çizim olarak üretildi, yalnızca görseli koy | 3.3 (akış + arayüz kararı), 7.1 (görsel şema) | **3–4 puan** |
| 2 | **Kara listeye uy.** Mesajlaşma uygulaması ekranları ve telefon numaralı SMS ekranı rapora girmeyecek | 1.2, 2.2, 4.3 — "proje aslında ne?" karışıklığı | **2–5 puan** |
| 3 | **Biçim kuralları.** Arial 12 / Arial Black 14 / 1.15 / iki yana yaslı / 2,5 cm / ≤30 sayfa | Tümü | **Eleme riski** |
| 4 | **Şablonun son iki sayfasını ve talimat paragraflarını sil** | Tümü | **Eleme riski** |

**Opsiyonel +1:** kullanılabilirlik testini bugün 5 kişiyle gerçekten uygula
(~90 dk) ve sonucu §3.3'e yaz. Protokol `docs/10_KULLANILABILIRLIK_TESTI.md`
içinde hazır. Sonuç kötü çıksa bile yazılır — rapor zaten bu duruşun üzerine
kurulu.

---

## 4. Ağırlıklı değerlendirme (Sosyal Yapay Zekâ dikeyi)

Şablonun ikinci tablosu, alt kriter puanlarının üstüne bir de ağırlık koyuyor.
Sosyal YZ sütununda ağırlıklar şöyle:

| Değerlendirme kriteri | Ağırlık | Raporun bu alandaki dayanağı |
|---|:--:|---|
| **Teknik Yeterlilik ve Uygulanabilirlik** | **%30** | En yüksek ağırlık — §3.1/§3.2/§4.3: ölçüm altyapısı, denetimli model kıyası, ayrık küme protokolü, yeniden üretilebilir komutlar |
| Yenilikçilik ve Özgünlük | %20 | §2.2: yuva–kuruluş modeli, edimbilimsel örüntüler, bağlam tavanı |
| Problemi Çözme Başarısı | %20 | §4.1: duyarlılık modeli + ölçülebilir etkinlik göstergesi |
| Sunum ve Prototip Kalitesi | %15 | **Görsellerin yerleştirilmesi doğrudan bu kalemi besliyor** |
| Kullanıcı Deneyimi (UI/UX) | %10 | §3.3: akışlar, WCAG eşlemesi, erişilebilirlik |
| İş Modeli ve Sürdürülebilirlik | %5 | §6.1/§6.2 |

Ağırlık dağılımı raporun güçlü olduğu yere denk geliyor: en ağır kalem (%30)
teknik yeterlilik ve raporun en fazla kanıt taşıdığı bölüm de orası.
