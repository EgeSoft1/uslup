# Gecikme Optimizasyonu — Uzun Gönderi Açığı

**Tarih:** 13 Eylül 2026 · **Kapsam:** `packages/civility_core` · **Davranış değişikliği:** yok

## 1. Bulgu

Motor her tuş vuruşunda metnin **tamamını** çözümlüyor ve gönderi kutusunda
karakter sınırı yok. Buna rağmen ölçüm aracının en uzun senaryosu 170
karakterdi; raporlanan gecikme (p50 357 µs · p99 2.212 µs) yalnızca kısa
mesajlar içindi.

Açık, kırılgan bir birim testinden fark edildi: "uzun metinde doğrusal
ölçeklenir" testi 4.800 karakterde 100 ms sınırını 102 ms ile aşıyordu.
Süre doğrusaldı ama karakter başına ~15 µs (JIT) idi. Ölçüm aracına iki
gerçekçi senaryo eklendi (~600 ve ~2.400 karakterlik topluluk duyurusu) ve
sonuç:

| Senaryo (AOT, eski motor) | p50 | p99 | Kare bütçesi (16 ms) |
|---|--:|--:|---|
| Uzun gönderi · ~600 kr | 9,5 ms | **16,5 ms** | **aşılıyor** |
| Çok uzun · ~2.400 kr | 36 ms | 58 ms | %360+ |

## 2. Nedenler (katman katman ölçüldü)

4.800 karakterlik metinde 69 ms'nin dağılımı (JIT):

| Katman | Süre | Neden |
|---|--:|---|
| Sözlük eşleştirme | ~58 ms | Her token 256 girdinin hepsine sırayla deneniyordu; ters okuma denemesi aynı taramayı ikinci kez yapıyordu |
| Örtük örüntüler | ~18 ms | Kapı kelimesi olmayan ~130 düzenli ifade her tuş vuruşunda metnin tamamında çalışıyordu |
| Normalizasyon | ~4 ms | — |
| Bağlam | ~0,7 ms | — |

## 3. Çözümler

**Sözlük — ilk harf kovaları** (`LexicalTurkishClassifier.fastLookup`).
Bir token bir köke ancak kökle ya da yumuşamış kökle başlıyorsa
bağlanabilir; yumuşama yalnızca son harfi değiştirir. Adaylar ilk harfe
göre kovalandı, kova içi sıra korundu — "ilk eşleşen aday" değişmez.

**Örüntüler — değişmez parça ön filtresi** (`LiteralPrefilter`,
`LiteralIndex`). Her düzenli ifadeden, her eşleşmesinde mutlaka geçen
parçalar **otomatik** çıkarılır (RE2 ön filtre yöntemi):

```
\b(senden|sizden) adam olmaz\b   →  {"senden adam olmaz", "sizden adam olmaz"}
\bhad(dini|dinizi)? bildir\w+    →  {"had bildir", "haddini bildir", "haddinizi bildir"}
```

Bütün parçalar tek bir Aho–Corasick taramasıyla aranır; parçası geçmeyen
ifade çalıştırılmaz. İlk sürüm parçaları `String.contains` ile tek tek
arıyordu ve **yavaşlattı** (kısa cümlede 273 → 975 µs); tek geçişli
otomatla değiştirildi.

Çıkarıcı anlamadığı her yapıda (geri başvuru, Unicode kipi, tanımadığı
kaçış) "kısıt yok" der; yanılabileceği tek yön hız kaybıdır. Üründeki 209
örüntünün 209'undan parça çıkarılabiliyor.

## 4. Davranışın değişmediğinin kanıtı

| Denetim | Sonuç |
|---|---|
| Önce/sonra anlık görüntü: 30.106 metin (7 etiketli küme · her sözlük girdisinin ek/ters/bölme/leet varyantları · 6.000 sözde rastgele cümle · küme çiftleri) — risk, skor, bulgu, konum, bağlam gerekçesi | **karakteri karakterine aynı** |
| Örüntü × metin: 6,29 milyon çift, 1.453 gerçek eşleşme | kapının kapattığı eşleşme: **0** |
| `test/lookup_index_test.dart` — kovalı / kovasız motor | aynı |
| `test/detector_gate_test.dart` — kapılı / kapısız dedektör, artık 7 kümenin tamamı | aynı |
| `test/literal_prefilter_test.dart` — çıkarıcı, otomat (3.000 rastgele metinde naif aramayla), katalog | geçiyor |
| Mutasyon: yumuşama dalı ve isteğe bağlı parça kuralı bilerek bozuldu | ilki 1, ikincisi **7** testi kırdı |

İP-29 ölçümü (kesinlik %96,4 · duyarlılık %45,0) bu yüzden **geçerliliğini
korur**: motorun hiçbir kararı değişmedi, ayrık kümeye bakılmadı.

## 5. Sonuç — aynı makine, aynı gün, aynı araç

`dart compile exe bin/benchmark.dart` · 11 senaryo × 2.000 tekrar · üç
turun ortancası. "Önce" ikilisi `d0058c6` commit'inden, aynı ölçüm
dosyasıyla derlendi.

| | Önce | Sonra | Kat |
|---|--:|--:|--:|
| Mesaj ≤200 kr · p50 | 1.104 µs | **206 µs** | ~5,4× |
| Mesaj ≤200 kr · p99 | 8.034 µs | **2.519 µs** | ~3,2× |
| Uzun gönderi · p50 | 22,7 ms | **2,76 ms** | ~8,2× |
| En pahalı (2.400 kr) · p99 | 75,9 ms (%475) | **10,2 ms (%64)** | ~7,4× |
| Bütçe denetimi | ✗ | ✓ | |

**Makine notu.** Eski motor bu oturumda mesajda p50 1.104 µs verdi; aynı
gün sabah 357 µs ölçülmüştü. Makinenin anlık durumu (güç kipi, ısı) mutlak
sayıyı üç kat oynatıyor. Bu yüzden karşılaştırma aynı turda, dönüşümlü
yapıldı ve ekranda bu turun (yavaş makinenin) sayıları gösteriliyor —
hızlı makinede sayılar daha iyi çıkar, daha kötü değil.

## 6. Kalan maliyet

4.800 karakterde (JIT) kalan ~17 ms'nin yarısı sözlük yolunda, dörtte biri
normalizasyonda (karakter başına alt dizi ayırma). Bir sonraki adım
normalizasyonu kod birimi düzeyine indirmek olur; bugünkü sayılar bütçenin
içinde olduğu için yapılmadı.
