# Üslup

**Cihaz üzerinde çalışan, Türkçe'ye özel nezaket katmanı.**
Saldırgan bir gönderi *gönderilmeden önce*, cihazın kendi içinde tespit edilir
ve daha yapıcı bir alternatif önerilir. Metin cihazdan hiç çıkmaz.

> NSosyal İnovasyon Yarışması 2026 · Tematik alan: **Sosyal Yapay Zekâ**

---

## Problem

Sosyal medyada nefret söylemi ve hakaret bugün **yayın sonrasında** yönetiliyor:
içerik yayınlanır → şikâyet edilir → moderatör inceler → silinir. Üç kırılgan
nokta var:

- **Zarar çoktan oluşmuştur.** Silmek, hedef kişinin onu görmüş olmasını geri almaz.
- **Yaptırım davranışı değiştirmez.** Cezalandırıldığını hisseden kullanıcı öfkelenir.
- **Mağdur cezalandırılır.** Tacize uğradığını anlatan kullanıcı ("bana 'şerefsiz'
  dedi") kendi mesajı işaretlendiği için susturulur.

## Yaklaşım

Müdahale, yayın sonrasından **yayın öncesine** taşınır. Kullanıcı cümleyi
yazarken çözümleme yapılır; sistem hiçbir metni engellemez veya değiştirmez —
öneri sunar, kararı kullanıcı verir.

```
Kullanıcı yazıyor
   │
   ▼  ── CİHAZ ÜZERİNDE ──────────────────────────────────────────────
   │  1. Normalizasyon      "$3r3fsiz" → "serefsiz", "aptaaaal" → "aptal"
   │  2. Sözlük eşleştirme  Türkçe eklemeli yapı: kök eşleşmesi
   │  3. Örüntü katmanı     Küfürsüz düşmanlık — kelimede değil, DİZİLİŞTE
   │  4. Nefret katmanı     Kimlik hedefli düşmanlık (kimlik adı ≠ yasaklı kelime)
   │  5. Gönderge katmanı   Kimlik önceki cümledeyse zamiri ona bağlar
   │  6. Bağlam çözümleme   saldırı / iltifat / şikâyet / öz-ifade ayrımı
   │  7. Öneri üretimi      Yerel, deterministik yeniden yazım
   ▼  ─────────────────────────────────────────────────────────────────
Kullanıcı seçer → gönderir

Sunucu adımı yoktur. Hattın tamamı cihazda biter.
```

### Kimlik adı yasaklı kelime değildir

Nefret söylemi filtrelerinin yaygın kusuru, korunan grubun adını yasaklı kelime
listesine koymaktır — sonuç ters teper ve korumaya çalıştığı grubu susturur.

```
"Ben Kürtüm"                   → işaretlenmez
"Eşcinsel hakları konferansı"  → işaretlenmez
"Bütün Kürtler hırsızdır"      → işaretlenir
```

Kimlik adları yalnızca düşmanca bir **kuruluşun** içindeki yuvayı doldurur;
tek başlarına hiçbir şey tetiklemez. Sözlükte tek bir kimlik adı yoktur ve bu,
`test/hate_layer_test.dart` içinde **yapısal bir testle** korunur — sözlüğe
kimlik adı sızarsa test kırılır.

---

## Ölçülen sonuçlar

Geçerli genelleme ölçümü, **üçüncü ayrık kümedir** (İP-20, 24 Ağustos 2026).
Önceki iki ayrık küme yanmıştır — motor onlara bakılarak düzeltildiği için
artık genelleme ölçemezler. Gerekçe ve tam geçmiş:
[`docs/14_MENTORLUK_PENCERESI_SONUCLARI.md`](docs/14_MENTORLUK_PENCERESI_SONUCLARI.md)

| Ölçüm | Değer |
|---|---|
| Kesinlik (İP-22 ilk geçiş) | %90,5 → **%100,0** (iki kusur düzeltildikten sonra) |
| F0.5 — ürünün hedef fonksiyonu | %79,8 → **%85,6** |
| F1 | %67,9 → %70,4 |
| Duyarlılık | **%54,3** |
| **Yapısal ailenin genelleme oranı** | **%90,0** — aynı yapının hiç görülmemiş örneklerinde |
| Çözümleme süresi | **p50 159 µs · p99 1459 µs** (AOT; p99'da 16 ms kare bütçesinin %9,1'i) |

### Ölçüm geçmişi — neden tek bir sayı yok

| Küme | Boyut | Kesinlik | Duyarlılık | F1 | Durum |
|---|:--:|:--:|:--:|:--:|---|
| Geliştirme | 256 | %100 | %99,3 | %99,6 | Ezberleme payı içerir |
| 1. ayrık | 80 | %98,0 | %100 | %99,0 | Yanmış (ilk ölçüm F1 %84,2) |
| 2. ayrık (İP-15) | 100 | %100 | %38,5 | %55,6 | Yanmış (İP-19 onarımında kullanıldı) |
| 3. ayrık (İP-20) | 80 | %100 | %50,0 | %66,7 | Yanmış (İP-21 onarımında kullanıldı) |
| **4. ayrık (İP-22)** | **65** | **%90,5** | **%54,3** | **%67,9** | **Geçerli — ilk geçiş** |

### Duyarlılık sayısı neyin cevabı

İP-22 üç eşit parçadan kuruldu ve toplam duyarlılığı ayrıştırdı:

| Parça | Örnek | Sonuç |
|---|:--:|:--:|
| Yapısal ailelerin **hiç görülmemiş örnekleri** | 20 | **%90,0** |
| Aynı ailelerin **yakın-kaçışları** (masum) | 20 | **11 yeni ailenin hiçbirinden yanlış pozitif yok** |
| Hiçbir ailede karşılığı **olmayan** deyimler | 15 | %6,7 |

Yani %54,3, "motor ne kadar iyi" sorusunun değil, **"kaç yapı ailesi
yazıldı"** sorusunun cevabıdır. Yazılmış bir ailenin yeni örneklerini motor
%90 görüyor; yazılmamış bir aileyi göremiyor. Türkçe deyim uzayı sonlu bir
örüntü kataloğuyla kapatılamaz — bu, kural tabanlı katmanın tavanıdır ve
gizlenmemektedir.

**Dürüstlük notu.** Geliştirme kümesindeki %99,6 bir genelleme kanıtı
**değildir** — kümeyi de örüntüleri de aynı kişi yazmıştır. Ayrık kümeler bunu
sayıya çevirdi: örtük saldırı diliminde duyarlılık %100'den %12,0'ye düştü.

**Dördüncü küme bir kesinlik felaketi buldu.** `"bardak dolu"` cümlesi yüksek
riskli **nefret söylemi** sayılıyordu. Sebep: `dölü` epiteti aksan
katlamasından sonra (`ö→o`, `ü→u`) `dolu` ile birebir aynı hâle geliyor ve tam
eşleşme modundaki girdi Türkçe'nin en sık kelimelerinden birini yakalıyordu.
Önceki 521 örneğin hiçbirinde "dolu" geçmediği için kusur görünmemişti.
Girdi kaldırıldı; ayrıntı [`docs/14`](docs/14_MENTORLUK_PENCERESI_SONUCLARI.md) §9.3.

Bu, ayrık küme disiplininin neden vazgeçilmez olduğunun kanıtıdır: kusuru
bulan şey, kümenin **saldırganlıkla hiç ilgisi olmayan** kısmıydı.

---

## Çalıştırma

Çekirdek motor **saf Dart**'tır; Flutter gerektirmez.

```bash
cd packages/civility_core
dart pub get
dart test                          # çekirdek testler
dart run bin/evaluate.dart --hepsi # tüm metrikler
dart run bin/evaluate.dart --karsilastir  # katman katkısı A/B
dart run bin/evaluate.dart --genelleme3   # geçerli genelleme ölçümü (İP-22)
dart run bin/rewrite_audit.dart --hepsi   # öneri kalitesi: çeşitlilik + dilbilgisi

# Gecikme ölçümü — ÜRÜN sayısı için AOT derleyin
dart compile exe bin/benchmark.dart -o benchmark.exe && ./benchmark.exe

# İkinci etiketleyici için kör etiketleme dosyası + hakemler arası uyum
dart run bin/annotate_export.dart --kume=ip20 > etiketleme.csv
dart run bin/kappa.dart etiketleme.csv
```

Erişilebilirlik denetimi (Flutter gerektirmez):

```bash
cd mobile
dart run tool/erisilebilirlik_denetimi.dart   # WCAG 2.1 AA kontrast oranları
```

Mobil uygulama (Flutter):

```bash
cd mobile
flutter pub get
flutter run
```

---

## Depo yapısı

| Dizin | İçerik |
|---|---|
| `packages/civility_core/` | **Nezaket motoru** — saf Dart, bağımlılıksız. Projenin çekirdeği. |
| `mobile/` | Flutter istemci; canlı yazım ekranı ve topluluk sağlığı paneli |
| `ml/` | **Denetimli taban çizgisi** — Python/scikit-learn ile eğitilen karşılaştırma modeli. Üründe çalışmaz; mimari kararı ölçmek içindir. |
| `docs/` | Ürün tanımı, model değerlendirme, kullanıcı akışları, teknik rapor, erişilebilirlik denetimi |
> **Not.** Bu depo, devralınan bir mesajlaşma platformu iskeletinin üzerine
> kurulmuştur. Devralınan sunucu altyapısı (`crates/`, `db/`, `devops/`)
> **üründe kullanılmamaktadır** ve depodan çıkarılmıştır; gerekçesi
> [`docs/02_TEKNIK_BORC.md`](docs/02_TEKNIK_BORC.md) §5'te kayıtlıdır. Üslup'un
> çalışma zamanında hiçbir sunucu bileşeni yoktur.

### Motorun içi

```
packages/civility_core/lib/src/
├── normalization/   tokenizer, Türkçe morfoloji, gizleme direnci
├── lexicon/         toksisite sözlüğü (kimlik adı İÇERMEZ)
├── detect/          edimbilimsel örüntüler + nefret söylemi örüntüleri
├── context/         bağlam çözümleyici — saldırı/iltifat/şikâyet/öz-ifade
├── rewrite/         iki modlu yerel yeniden yazıcı
├── community/       anonim topluluk sağlığı sinyalleri (k-anonimlik)
└── eval/            581 etiketli örnek (5 küme) + kesinlik/duyarlılık/F1/F0.5
```

---

## Etik duruş

1. **Mahremiyet tasarımdan gelir.** Metin cihazdan çıkmaz — gizlilik politikası
   maddesi değil, mimarinin kendisi.
2. **Sansür değil, farkındalık.** Sistem hiçbir metni kendiliğinden değiştirmez
   veya engellemez.
3. **Açıklanabilirlik zorunlu.** Her uyarı "hangi kelime" ve "neden" sorusuna
   cevap verir.
4. **Yanlış pozitif, yanlış negatiften pahalıdır.** Bu yüzden raporlanan asıl
   hedef fonksiyon F0.5'tir.
5. **Mağdur korunur.** Alıntı, aktarım ve öz-ifade ayırt edilir.

## Bilinen sınırlar

- Metrikler **tek etiketleyicilidir**; hakemler arası uyum (kappa) ölçülmemiştir.
  Ölçüm altyapısı hazırdır — `bin/annotate_export.dart` kör etiketleme dosyası
  üretir, `bin/kappa.dart` Cohen's kappa'yı hesaplar; eksik olan ikinci insandır.
- **Duyarlılık, yazılmış yapı ailesi sayısıyla sınırlıdır.** Taze ayrık
  kümede toplam %54,3; ama yazılmış bir ailenin hiç görülmemiş örneklerinde
  %90,0. Yazılmamış ailelerde ~%7. Kural tabanlı bir katman Türkçe deyim
  uzayını kapsayamaz.
- **"dölü" epiteti kaldırıldı** — aksan katlaması onu "dolu" ile birebir
  aynı hâle getiriyor ve ayırt etmenin normalize metin üzerinde yolu yok.
- Öncülsüz gönderge **kasıtlı olarak** kaçırılır — hedefin kim olduğu metinden
  bilinemez ve zamirden kimlik uydurmak kesinlik iddiasını çürütür.
- Kimlik söz varlığı 94 terimdir (İP-17'de 35'ten genişletildi); siyasi
  görüş **kasıtlı olarak** kapsam dışıdır — korunan nitelik değildir.
- Tüm veri sentetiktir; hiçbir örnek gerçek kullanıcıdan gelmemiştir.
- **Öneri çeşitliliği sınırlı.** En sık öneri, üretilen tüm önerilerin
  %28,9'unu kaplıyor. Daha ileri gitmek her örüntüye kendi nötr karşılığını
  yazmayı gerektirir — algoritma işi değil, veri işi.
- Yalnızca Türkçe desteklenmektedir.
- Bir Büyük Dil Modeli **kullanılmamaktadır** — yazılmış, ölçülmüş ve kasıtlı
  olarak kaldırılmıştır. Gerekçe: [`docs/03_LLM_SERVISI.md`](docs/03_LLM_SERVISI.md)
- Denetimli bir model de eğitilip ölçülmüştür ([`ml/`](ml/)). Aynı ayrık kümede
  kural motorunun kaçırdığı **hiçbir örneği yakalamamış**, buna karşılık motorun
  yapmadığı altı yanlış pozitif üretmiştir — hepsi iltifat, olumsuzlama ya da
  mağduru savunan cümle. Bu, doğrusal bir taban çizgisinin **bu veri hacmindeki**
  sınırıdır; önceden eğitilmiş bir Türkçe modelin de başarısız olacağı
  **iddia edilmemektedir**.

---

## Lisans

MIT — ayrıntı: [`LICENSE`](LICENSE).
Kod, veri kümesi ve ölçüm araçları serbestçe kullanılabilir; tek koşul telif
notunun korunmasıdır.
