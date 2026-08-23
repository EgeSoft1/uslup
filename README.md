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

| Ölçüm | Değer |
|---|---|
| Genelleme (ayrık küme) F1 | **%84,2** (kesinlik %88,9 / duyarlılık %80,0) |
| Nefret söylemi dilimi F1 | %97,3 (kesinlik %100) |
| Örüntü katmanının duyarlılık katkısı | +55,2 puan, **kesinlik kaybı 0** |
| Ortalama çözümleme süresi | 193 µs (AOT; 16 ms kare bütçesinin %1,2'si) |

**Dürüstlük notu.** Geliştirme kümesinde F1 %99,6'dır ve bu bir genelleme kanıtı
**değildir** — kümeyi de örüntüleri de aynı kişi yazmıştır. Raporlanan sayı, tek
geçerli genelleme ölçümü olan **ayrık kümedeki %84,2**'dir. Aradaki ~16 puanlık
fark, ezberleme payının büyüklüğüdür. Ayrıntı: [`docs/04_MODEL_DEGERLENDIRME.md`](docs/04_MODEL_DEGERLENDIRME.md)

---

## Çalıştırma

Çekirdek motor **saf Dart**'tır; Flutter gerektirmez.

```bash
cd packages/civility_core
dart pub get
dart test                          # çekirdek testler
dart run bin/evaluate.dart --hepsi # tüm metrikler
dart run bin/evaluate.dart --karsilastir  # katman katkısı A/B
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
| `docs/` | Ürün tanımı, model değerlendirme, kullanıcı akışları, teknik rapor taslağı |
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
└── eval/            336 etiketli örnek + kesinlik/duyarlılık/F1/F0.5
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
- Öncülsüz gönderge **kasıtlı olarak** kaçırılır — hedefin kim olduğu metinden
  bilinemez ve zamirden kimlik uydurmak kesinlik iddiasını çürütür.
- Kimlik söz varlığı 40 terimle sınırlıdır.
- Tüm veri sentetiktir; hiçbir örnek gerçek kullanıcıdan gelmemiştir.
- Yalnızca Türkçe desteklenmektedir.
- Bir Büyük Dil Modeli **kullanılmamaktadır** — yazılmış, ölçülmüş ve kasıtlı
  olarak kaldırılmıştır. Gerekçe: [`docs/03_LLM_SERVISI.md`](docs/03_LLM_SERVISI.md)
