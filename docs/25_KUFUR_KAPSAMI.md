# Küfür Kapsamı — Bitişik, Çekimli ve Gizlenmiş Yazım

**Tarih:** 14 Eylül 2026 · **Durum:** ÖLÇÜMDEN SONRA YAZILDI — değişiklikler
çekişmeli tarama üzerinde yinelenerek geliştirildi; İP-29 bu süreçte açılmadı.
**Önceki tur:** docs/23 (kod denetimi), docs/24 (geliştirme listesi)

## 1. Bulgu

Kullanıcı geri bildirimi: "Bazı küfürler birleşik yazılınca veya normal
yazılınca algılanmıyor." Bunu ölçmek için 286 cümlelik bir çekişmeli tarama
yazıldı (küfür biçimleri + masum tuzaklar; sonradan 317'ye çıktı). İlk
geçişte **111 küfür/hakaret biçimi Temiz** döndü, **6 masum cümle** işaretlendi.

| Sınıf | Örnek (hepsi Temiz · 0,00) |
|---|---|
| En ağır küfrün sözlük biçimi | `sikerim` · `sikeyim` · `SİKERİM` · `s i k e r i m` · `yarrağım` |
| Bitişik yazım | `senisikerim` · `siktirgit` · `piçkurusu` · `yarrakkafa` · `salakherif` |
| Bitişik soru eki | `salakmısın` · `aptalmısın` · `gerizekalımısın` · `şerefsizmisin` |
| Öbek çekimi | `amına koydum` · `amına koyarım` · `amınakoydum` |
| Nesne + fiil | `götüne sokarım` · `ananı siktim` · `bacını sikerim` |
| Gizleme | `amkk` · `aqq` · `salakk` · `aptaal` · `s*kerim` · `s!kerim` |
| Söz varlığı | `sikiyim` · `hasiktir` · `kahbe` · `sıçarım` · `geberesice` · `it oğlu it` |

| Yanlış alarm | Sonuç | Sebep |
|---|---|---|
| `ananın yemekleri çok güzel` | Yüksek risk | `ananı` kök eşleşmesi |
| `ananı özledin mi` | Yüksek risk | aynı |
| `kuş bu dala kondu` | Riskli | komşu token birleştirmesi: `bu` + `dala` → `budala` |

## 2. Kök nedenler ve değişiklikler

**K1 · Ağır küfür öz-ifade sayılıyordu.** Öz-yönelim, birinci şahıs ekini
"konuşan kendinden bahsediyor" diye okur (`kendimi aptal hissettim`). En ağır
küfürlerin sözlük biçimi zaten birinci şahıs çekimlidir; `sikerim`
yumuşatılıp eleniyordu. `amk ben yoruldum` da yakındaki "ben" yüzünden
siliniyordu. Tehdit için bu istisna zaten vardı. **Değişiklik:** şiddeti
≥ 0,85 olan küfür girdilerinde öz-yönelim ve olumsuzlama uygulanmaz
(`sikimde değil` olumsuzlanmış küfür değil, deyimdir). Alıntı ve aktarım
yumuşatması **korunur**: `bana "amına koyayım" diye bağırdı` temiz kalır.
Hafif argo (`götüm donuyor`, 0,70) öz-ifade olarak yumuşamaya devam eder.

**K2 · Bitişik soru eki.** Ek listesinde yoktu. `misin/musun/misiniz/…`
eklendi. `it`, `kaz`, `sik` kısa köklerinde eklenmedi: ASCII'de "-mişsin"
ile aynı dizgi (`itmisin` = itmişsin).

**K3 · Birleşik yazım bölmesi.** Eşleşmeyen token iki TAM parçaya bölünür:
bir parça sözlük girdisi, öteki kısa bir yapıştırıcı kelime listesinden
(`seni`, `git`, `lan`, `herif`, `kurusu`…) ya da ikinci bir girdi olmalı.
Serbest alt dizgi araması **reddedildi**: `adamına` içinde `amına`, `şekerim`
benzeri kelimelerde küfür dizgileri geçer. Kelime listesi taramasıyla bulunan
üç çakışma kural olarak kapatıldı: soldaki yapıştırıcı ≥ 3 harf (`ya` +
`malak` → `yamalak`), `oğlu` yapıştırıcı değil (`Gavuroğlu`), kısa kök ancak
≥ 3 harfli yapıştırıcıyla (`piç` + `o` → `pico`).

**K4 · Bitişik öbek çekimi.** Boşluksuz öbek yalnızca birebir aranıyordu.
Boşluksuz uzunluğu ≥ 7 olan öbekler ön ek olarak da aranır
(`aminakoy` → `amınakoydum`). `amına koyayım` / `amına koyim` girdileri
fiil köküyle (`amına koy`, `amına kod`, `amına sok`) değiştirildi.

**K5 · Nesne + fiil.** `ananı` tek kelimelik girdisi kaldırıldı (yanlış
alarmın sebebi). Yerine kapalı listeler: nesneyi hemen izleyen fiil
(`ananı siktim`, `ananısiktim`, `götüne sokarım`, `ağzına sıçtı`) ve mesajın
tamamının küfür nesnesi olması (`ulan bacını`). Fiil listeleri **kök değil tam
biçimdir**: `ağzına sıcak çorba` (`sicak`), `kafanı sıkma` (`sikma`).

**K6 · Gizleme.**
- *Çift harf:* ünlü ikilisi her yerde, ünsüz ikilisi yalnızca kelime sonunda
  teke indirilir (`aptaal`, `amkk`). Kelime içi ünsüz ikilisi Türkçenin
  olağan yapısıdır: ilk sürüm `yıllanma` → `yılan`, `şallak` → `salak`
  üretti. Ağız yazımları (`eşşek`, `dalyarrak`) tek tek yazıldı.
- *Yıldız:* harf arasındaki `*` silindiği için `s*kerim` → `skerim`
  kalıyordu. Yuvaya sırayla ünlüler konup sözlükte aranır. Ünsüz denenmez
  (`a*k` hem `amk` hem `aşk`).
- *Ünlem:* `!` cümle sınırı sayıldığı için `s!kerim` ikiye bölünüyordu. İki
  parça arasında özgün metinde yalnızca tek `!` varsa `i` olarak da denenir.
- *Komşu token birleştirmesi:* parçalardan biri işlev kelimesiyse
  (`bu`, `ve`, `de`…) birleştirilmez — `kuş bu dala kondu` yanlış alarmı.

**K7 · Yüzey kanıtı.** `sıktım`, `sıkım`, `sıkık` normalize metinde `siktim`,
`sikim`, `sikik` ile aynıdır. Kullanıcı `ı` yazdıysa bu girdiler elenir (D1
kısa kök kuralının genişletilmesi). Ters yönde: `amı` ile başlayan hiçbir TDK
maddesi yoktur; `ı` ile yazılmış `amına`, `amın oğlu` yönelim şartı olmadan
yakalanır, ASCII `amina` (özel ad) ve `amin` (dua) etkilenmez.

**K8 · Söz varlığı.** 45 girdi eklendi (K4'ün 5 öbeği ayrıca; K4 ve K5'te 3
girdi kaldırıldı · sözlük 307 girdi): sik- ailesinin ince ünlülü çekimleri,
yazım varyantları (`kahbe`, `oruspu`, `kavat`), `deyyus`, `dürzü`,
`kerhaneci`, sıç- ailesinin tam biçimleri, ünsüz iskeletleri (`skm`, `skrm`,
`s2m`, `orsp`), soy küfürleri (`it oğlu it`…), kargış (`geber`,
`geberesice`, `kahrolasıca`). **Alınmayanlar:** `siktin`/`sikti` (ASCII
`canımı sıktın`), `sikiş` (`sıkış`), `taşaklı` (övgü kullanımı), `kahrol`
(`kahrolsun zulüm`), `ananın amı` (sağ sınır yok → `ananın amiri`).

## 3. Kesinlik güvencesi

Her değişiklik iki bağımsız masum kaynağa karşı denetlendi:

1. **91.861 biçimlik kelime listesi** — OpenSubtitles Türkçe sıklık listesi
   (50 bin çekimli biçim) + TDK madde başları; her biçim tek başına ve
   `sen X` kalıbında (yönelim şartlı girdilerin en kötü durumu). Önceki
   motorla fark: **61 yeni işaretleme, hepsi küfür/hakaret** (`sikerim`,
   `deyyus`, `geberesice`…); **0 masum biçim**. İşaretlenmeyi bırakan 3 biçim
   `ananı`, `ananın` (K5).
2. **Taramanın masum cümleleri** ve 10 etiketli ölçüm kümesi.

## 4. Sonuçlar

| Ölçüm | Önce | Sonra |
|---|:--:|:--:|
| Çekişmeli tarama — kaçan küfür | 111 | **5** |
| Çekişmeli tarama — yanlış alarm | 6 | **4** |
| Kelime listesi — yeni masum işaretleme | — | **0** |
| İP-29 kesinlik · duyarlılık · F0.5 | %100 · %41,7 · %78,1 | %100 · **%43,3** · **%79,3** |
| Diğer dokuz küme | — | tek örnek değişmedi |
| Test paketi | 428 | 592 (yeni: `test/kufur_kapsami_test.dart`) |

Kalan 4 yanlış alarmın üçü önceden vardı (`mk ultra projesi`, `ahmaklar
cenneti filmi`, `boktan bir gündü`); biri yeni ve bilinçli: `skm` kısaltması
"SKM" gibi bir kurum adıyla çakışır. Kelime listesinde `skm` hiç geçmez.

İP-29'da değişen tek örnek `ahmakk mısın nesin` (P1 · harf tekrarı + soru
kuruluşu): K6'nın kelime sonu kuralı ve K2 birlikte.

**Gecikme.** Yeni yollar eşleşmeyen her token'da çalışır. İlk sürüm 4.800
karakterde süreyi ~2 katına çıkardı; birleşik yazım bölmesi kopya üretmeyen
ön koşullarla (ilk/son harf kovaları) yeniden yazıldı. Aynı makinede, yeni
yolları kapatılmış kopyayla dönüşümlü AOT ölçümü (5 tur × 40 çözümlemenin en
iyisi; makine yük altındaydı, mutlak sayılar README'deki 13 Eylül ölçümüyle
karşılaştırılamaz):

| Metin | Yeni yollar kapalı | Bugünkü motor |
|---|:--:|:--:|
| 129 kr mesaj | 177 µs | 197 µs |
| 600 kr | 661 µs | 646 µs |
| 2.400 kr gündelik | 3.215 µs | 3.547 µs |
| 4.800 kr | 4.986 µs | 5.445 µs |

## 5. Ek tarama — "amına koy-" kısaltmaları

İlk turdan sonra telefonda bildirilen cümle: **`Senin ben amkoyayim` → Temiz.**
Motor yalnızca tam `amına koy-` biçimini tanıyordu. Bu kısaltma ailesi için
52 cümlelik ikinci bir tarama yazıldı; ilk geçişte **26'sı** kaçtı:
`amkoyayım`, `amkoydum`, `amkoyucam`, `am koyayım`, `amna koyayım`,
`amnakoyim`, `ananıskm`, `senin ben ananı`…

**K9 · Kök eşleşen nesne + fiil grubu.** Nesnesi tek başına müstehcen olan
`am / amn / amna` için fiilin tam biçimi yerine KÖKÜ (`koy`, `kod`, `sok`)
aranır; ayrı ve bitişik yazımda, kelime sonu uzatmasıyla (`amkoyayımm`).
Kelime listesinde bu köklerle başlayan tek bir masum biçim yoktur.
Nesne + fiil yolunda fiilin Türkçe yazılışı özgün metinle çelişirse
eşleşme yok sayılır (`anneni sıktım`). `senin ben ananı` için `ben`
tek başına küfür nesnesi kuralında dolgu kelimesi oldu.

**`anneni` ayrı tutuldu.** Altyazı listesinde 8.140 kez geçen gündelik bir
kelime. İlk denemede ASCII `anneni siktim mi hiç` (sıktım mı) işaretlendi;
bu nesne yalnızca ASCII'de `sık-` okuması taşımayan fiillerle eşleşir
(`anneni sikerim`, `annenisikerim`). Bedel: `anneni siktim` kaçar.

Sonuç: 52 cümlede kaçak **26 → 3**, yanlış alarm **0**; kelime listesi
farkı **0**; ölçüm kümelerinde değişiklik yok.

## 6. Bilinen sınırlar

- **ASCII'de `ı`/`i` ayrımı yapılamaz.** `siktin`, `sikti` alınmadı;
  `siktim` yalnızca yöneltilince (`siktim seni`) ya da küfür nesnesiyle
  (`ananı siktim`) yakalanır. ASCII `seni siktim mi` (sıktım mı) bu yüzden
  işaretlenir.
- **Kelime başındaki `!`** (`!bne`) ve **ünsüz yerine yıldız** (`a*k`)
  çözülmez.
- **Yönelim şartlı kökler birleşik yazımda parça olamaz:** `bokkafa`,
  `eşşoğlueşşek` kaçar.
- **Ağır küfürde olumsuzlama artık yumuşatmaz.** `ben asla amk demem`
  işaretlenir; kelimeyi kullanan cümle kelimeyi taşır.
- Birleşik yazım bölmesi en fazla iki parçaya böler.
