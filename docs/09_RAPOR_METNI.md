# Üslup — Proje Teknik Raporu (metin)

**Hazırlanma:** 20 Ağustos 2026 · **Teslim:** 24 Ağustos 2026, 17.00 (TSİ)
**Kullanım:** Aşağıdaki metinler `.docx` şablonundaki ilgili başlığın altına
girer. Şablonun açıklama paragrafları ("…ifade edilir", "…detaylandırılır")
**silinecektir**; onlar talimattır, içerik değildir.

> ⚠️ `[KÖŞELİ PARANTEZ]` içindeki her yer doldurulmak zorundadır.
> ⛔ işaretli maddeler bugün yazılamaz; gerekçesi yanında belirtilmiştir.

---

# 1. PROJE ÖZETİ

## 1.1. Proje Konusu ve Amacı

Bu projenin konusu, sosyal medya platformlarında üretilen saldırgan içeriğe
**yayımlandıktan sonra değil, yazılırken** müdahale eden, tamamen kullanıcının
cihazında çalışan, Türkçe'ye özgü bir yapay zekâ katmanının geliştirilmesidir.
Ürünün adı **Üslup**'tur.

Sosyal medya ekosisteminde nefret söylemi ve hakaret bugün ağırlıklı olarak
yayın sonrası yönetilmektedir: içerik yayımlanır, bir kullanıcı şikâyet eder,
moderatör inceler ve içerik kaldırılır. Bu döngü üç noktada kırılmaktadır.
Birincisi, içerik kaldırılana kadar hedef kişi onu görmüştür; kaldırma işlemi
görmüş olmayı geri almaz. İkincisi, yaptırım davranışı kalıcı olarak
değiştirmemekte, cezalandırıldığını hisseden kullanıcıda savunma tepkisi
oluşturmaktadır. Üçüncüsü, İngilizce merkezli sınıflandırıcılar Türkçe'nin
eklemeli biçimbilgisi, argosu ve bağlam yapısı karşısında yetersiz kalmaktadır.

Projenin nihai amacı, saldırgan ifadenin **oluşmasını** engellemek değil,
oluşmadan önce kullanıcının onu **görmesini** sağlamaktır. İnsanlar bu
cümleleri yüz yüzeyken kurmamaktadır; ekran arkasında kurmaktadır. Aradaki
fark bir yasak değil, bir **duraksama**dır ve dijital ortamda o duraksama
kaybolmuştur. Üslup, kaybolan bu duraksamayı geri koymayı amaçlar.

Proje, yarışmanın **Sosyal Yapay Zekâ** inovasyon dikeyine hitap etmektedir.
Şartnamenin örnek çözüm alanlarından yapay zekâ destekli içerik moderasyonu,
duygu analizi, nefret söylemi tespiti ve yapay zekâ destekli topluluk yönetimi
başlıkları doğrudan karşılanmaktadır.

Amaç, yarışmanın Bölüm 1'de tanımlanan genel hedefleriyle doğrudan
örtüşmektedir. Şartname, hedeflerinin ilk sırasında "kullanıcıların dijital
ortamda yüz yüze bakar gibi etkileşim kurmasını sağlayan yenilikçi sosyal medya
çözümlerinin geliştirilmesini teşvik etmek" ifadesine yer vermektedir. Ürünün
varlık sebebi tam olarak bu cümledir. Aynı şekilde "güvenli, etik, şeffaf ve
kullanıcı mahremiyetini ön planda tutan çözümler" hedefi, metnin cihazdan hiç
çıkmadığı bir mimariyle karşılanmaktadır.

## 1.2. Proje Kapsamı ve Yöntemi

**Kapsam.** Proje, Türkçe metin girişi yapılan herhangi bir yüzeyde çalışan,
bağımlılıksız bir çözümleme ve öneri katmanı ile bu katmanı gösteren çalışan
bir mobil istemciden oluşur. Kapsam bilinçli olarak dar tutulmuştur.

| Kapsam içi | Kapsam dışı (gerekçeli) |
|---|---|
| Türkçe normalizasyon ve biçimbilim | Türkçe dışı diller |
| Bağlam duyarlı toksisite çözümlemesi | Spam ve bot tespiti |
| Kimlik hedefli nefret söylemi tespiti | Yapay zekâ tabanlı arama |
| Cümleler arası gönderge çözümlemesi | Görsel/video içerik çözümlemesi |
| Yerel, deterministik yeniden yazma önerisi | Bulut tabanlı üretici model |
| Anonim topluluk sağlığı toplulaştırması | Sunucu tarafı içerik saklama |

Kapsam dışı bırakılanlar bir eksiklik değil, önceliklendirme kararıdır. Bir
problemi ölçülebilir biçimde derinlemesine çözmek, birkaç probleme yüzeysel
dokunmaktan daha yüksek teknik değer üretir. Bu kararın en belirgin örneği,
yazılmış ve çalışır durumdaki bulut tabanlı yeniden yazma servisinin
**kasıtlı olarak kaldırılmasıdır** (§2.2 ve §3.2).

**İzlenecek teknik yöntem.** Çözümleme, ardışık ve birbirinden bağımsız
ölçülebilir katmanlardan oluşan bir hat olarak kurgulanmıştır: normalizasyon →
kök eşleştirme → edimbilimsel örüntü → nefret söylemi örüntüsü → gönderge
çözümlemesi → bağlam ağırlıklandırma → skor birleştirme → öneri üretimi.
Katmanlar bağımsız olarak açılıp kapatılabilir ve her birinin katkısı aynı
veri kümesi üzerinde A/B karşılaştırmasıyla ayrı ayrı ölçülür.

**İzlenecek akademik yöntem.** Doğrulama, işlevsel test yaklaşımıyla
kurgulanmıştır: model bir bütün olarak değil, davranış sınıfları bazında
sınanır. Etiketli küme beş dilime ayrılmıştır (açık saldırı, örtük saldırı,
nefret söylemi, masum/tuzak, bağlam) ve kümenin üçte biri kasıtlı olarak
**yanlış pozitif tuzaklarından** oluşur. Raporlanan asıl hedef fonksiyon,
kesinliği iki kat ağırlıklandıran **F0.5**'tir; çünkü bu üründe masum bir
metne müdahale etmenin maliyeti, bir hakareti kaçırmanın maliyetinden yüksektir.

**Tema ile doğrudan ilişki.** Proje, Sosyal Yapay Zekâ dikeyinin tanımındaki
"içerik moderasyonu, öneri sistemleri ve topluluk yönetimi süreçlerinde yapay
zekânın güvenli, etik, ölçülebilir ve uygulanabilir biçimde kullanılması"
ifadesini birebir karşılar: moderasyon karar noktası kullanıcıya taşınmış,
her karar açıklanabilir kılınmış ve tüm iddialar sayısal olarak ölçülmüştür.

**Çalışan prototip.** Proje fikir düzeyinde değildir. Çekirdek motor
(`packages/civility_core`, 6.293 satır, harici bağımlılık yok) ve onu kullanan
Flutter istemcisi çalışır durumdadır; canlı yazım ekranı, sohbet mesaj kutusu
ve topluluk sağlığı paneli üzerinden uçtan uca gösterilebilir. Çekirdekte
**136 birim testi** geçmektedir.

**Yeni çalışmalara zemin.** Ortaya çıkan iki varlık, bu projenin ötesinde
kullanılabilir niteliktedir: (i) beş dilimli, yanlış pozitif tuzakları ve
yakın-kaçış çiftleri içeren Türkçe değerlendirme kümesi ve ölçüm altyapısı,
(ii) kimlik adlarını yasaklı kelime olarak ele almayan "yuva–kuruluş" nefret
söylemi modeli. Ölçüm altyapısı, ileride eğitilecek sinir ağı tabanlı bir
Türkçe sınıflandırıcının mevcut deterministik motorla **karşılaştırılabilmesini**
mümkün kılar; bu karşılaştırma olmadan "sinir ağı daha iyidir" iddiası
kanıtlanamaz.

---

# 2. KATMA DEĞER VE YENİLİKÇİLİK

## 2.1. Problem Tanımı ve Mevcut Çözümler

**Problem.** Sosyal medyada saldırgan dil, oluştuktan sonra yönetilmektedir ve
bu yaklaşımın üç yapısal kusuru vardır:

1. **Zarar geri alınamaz.** İçerik kaldırılana kadar hedef kişi onu görmüştür.
2. **Yaptırım davranışı değiştirmez.** Ceza, öfkeyi artırır; alışkanlığı değil.
3. **Türkçe'de doğruluk düşüktür.** İngilizce merkezli modeller Türkçe'nin
   eklemeli biçimbilgisinde, argosunda ve bağlamında zayıf kalmaktadır.

Bunlara dördüncü ve en az fark edilen kusur eklenir: **mevcut filtreler sıklıkla
mağduru cezalandırır.** Tacize uğradığını anlatan kullanıcının mesajı, içinde
geçen hakaret sözcüğü nedeniyle işaretlenir; şikâyet eden susturulur. Aynı
mekanizma, kendi kimliğinden söz eden kullanıcıyı da vurur: kimlik adlarını
yasaklı kelime listesine koyan bir sistem, korumayı vaat ettiği grubu susturur.

> `[İSTATİSTİK — DOLDURULACAK]` Türkiye'de sosyal medya kullanıcı sayısı ve
> çevrim içi taciz/nefret söylemine maruz kalma oranı, §9'daki kaynaklardan
> [1] ve [2] ile birlikte buraya yazılacaktır. Rubrik bu maddeye 1 puan,
> resmî/akademik kaynakla desteklenmesine 2 puan vermektedir.

**Mevcut çözümler ve yetersizlikleri.**

| Çözüm | Yaklaşım | Bu problemde neden yetersiz |
|---|---|---|
| **Google Jigsaw – Perspective API** | Bulut tabanlı toksisite skoru | Metin sunucuya gider; Türkçe desteği İngilizce'ye kıyasla sınırlı; skor üretir ama **gerekçe ve alternatif üretmez**; çağrı başına ücretlendirme |
| **OpenAI Moderation API** | Bulut tabanlı çok sınıflı sınıflandırma | Aynı mahremiyet sorunu; yayın sonrası kullanım için tasarlanmış; kararlar açıklanabilir değil |
| **Platform içi kelime listeleri** | Yasaklı kelime eşleştirme | Küfürsüz düşmanlığı göremez; Türkçe çekim ve gizleme hilelerinde kırılır; kimlik adlarını yasaklayarak mağduru susturur |
| **Yayın sonrası insan moderasyonu** | Şikâyet → inceleme → kaldırma | Zarar oluştuktan sonra devreye girer; ölçeklenmez; moderatör üzerinde psikolojik yük oluşturur |

Ortak eksiklik nettir: **hepsi yayımlanmış içeriği değerlendirir.** Hiçbiri
yazma anında devreye girmez, hiçbiri kararını kullanıcıya açıklamaz, hiçbiri
alternatif önermez ve hiçbiri metni cihazda tutmaz.

## 2.2. Çözüm Fikri, Özgünlük ve Yerlilik

**Çözüm fikri.** Üslup, müdahaleyi yayın sonrasından yayın öncesine taşır.
Kullanıcı cümleyi yazarken, her tuş vuruşunda, cihaz üzerinde çalışan katman
metni çözümler; risk seviyesine göre orantılı bir müdahale uygular ve daha
yapıcı bir alternatif önerir. Sistem hiçbir metni kendiliğinden değiştirmez
veya engellemez.

**Müdahale merdiveni.** Ürünün tek davranış kuralı, müdahale şiddetinin riskle
orantılı olması ve hiçbir seviyede gönderimin engellenmemesidir:

| Toksisite | Seviye | Kullanıcı ne görür | Kesinti |
|---|---|---|---|
| < 0,15 | Temiz | Hiçbir şey | Yok |
| 0,15 – 0,40 | Dikkat | Yalnızca kenarlık rengi değişir | Yok |
| 0,40 – 0,70 | Riskli | Gerekçe + yeniden yazma önerisi | Yok |
| ≥ 0,70 | Yüksek | Gönderim öncesi onay diyaloğu | Bir dokunuş |

Kullanıcıyı her seferinde uyarmak, uyarıyı görünmez kılar. "Dikkat"
seviyesinde hiçbir kesinti olmaması bir eksiklik değil, uyarının anlamını
koruma kararıdır.

**Somut piyasa kıyası.**

| Ölçüt | Perspective API | OpenAI Moderation | Kelime listeleri | **Üslup** |
|---|---|---|---|---|
| Müdahale anı | Yayın sonrası | Yayın sonrası | Yayın anı | **Yazma anı** |
| Metin nerede işlenir | Bulut | Bulut | Cihaz/sunucu | **Yalnızca cihaz** |
| Kararın açıklanması | Skor | Etiket | Eşleşen kelime | **Gerekçe + hangi kelime + neden** |
| Alternatif önerisi | Yok | Yok | Yok | **Var** |
| Küfürsüz düşmanlık | Kısmi | Kısmi | **Yok** | **Var (8 aile, 50 örüntü)** |
| Kimlik adı muamelesi | Model belirler | Model belirler | Yasaklı kelime | **Hiçbir zaman tetikleyici değil** |
| Mağduru ayırt etme | Sınırlı | Sınırlı | Yok | **Alıntı/şikâyet/öz-ifade ayrımı** |
| Marjinal maliyet | Çağrı başına | Çağrı başına | Düşük | **Sıfır** |
| Ağ bağımlılığı | Var | Var | Değişken | **Yok** |

**Özgün yön 1 — Küfürsüz düşmanlığın tespiti.** Sosyal medyadaki saldırganlığın
büyük kısmı tek bir yasaklı kelime içermez: "senin gibilerden zaten bu
beklenirdi" (ötekileştirme), "sen ne anlarsın bu işlerden" (yetkinlik reddi),
"gününü göreceksin" (örtük tehdit). Edimbilimsel örüntü katmanı saldırganlığı
kelimelerde değil, **kelimelerin dizilişinde** arar. Ölçüm bu katkıyı
sayısallaştırmıştır: bu dilimde yalnız sözlük katmanı **%1,8** duyarlılık
gösterirken, örüntü katmanıyla **%100,0**'a çıkmakta ve bu kazanç
**kesinlikten hiçbir şey götürmeden** sağlanmaktadır (her iki ölçümde de
kesinlik %100,0).

**Özgün yön 2 — Kimlik adı tetikleyici değildir.** Nefret söylemi
filtrelerinin yaygın kusuru, korunan grubun adını yasaklı kelime listesine
koymaktır. Sonuç ters teper:

```
"Ben Kürtüm"                   → filtrelenmemeli, ama yaygın olarak filtrelenir
"Eşcinsel hakları konferansı"  → filtrelenmemeli, ama yaygın olarak filtrelenir
"Bütün Kürtler hırsızdır"      → filtrelenmeli
```

Bu katmanda kimlik adı yalnızca düşmanca bir **kuruluşun** içindeki yuvayı
doldurur; tek başına asla bulgu üretmez. Sözlükte tek bir kimlik adı yoktur ve
bu, `hate_layer_test.dart` içinde **yapısal bir testle** korunmaktadır —
sözlüğe bir kimlik adı sızarsa test kırılır. Ölçüm doğrulamaktadır: 20 masum
kimlik cümlesinin hiçbiri işaretlenmemektedir.

Kesinliği ayakta tutan iki mekanizma vardır. **Yüklem eki şartı:** düşmanca
sözcüğün gerçekten yüklem konumunda olması gerekir; çoğul eki `-lar` kasıtlı
olarak yüklem sayılmaz. Böylece "Suriyeliler hayvandır" yakalanırken
"Suriyeli gönüllüler hayvan haklarıyla ilgileniyor" yakalanmaz. **Ambigü
köklerde yalnızca çoğul biçim:** aksan katlaması bazı kimlik adlarını meşru
kelimelerle çakıştırdığı için (Kürt→kurt, Laz→lazım, Roman→roman) tekil biçim
hiç kullanılmaz. Bedeli bir miktar duyarlılıktır ve bilinçli bir seçimdir.

**Özgün yön 3 — Mağdurun korunması.** Bağlam çözümleme katmanı aynı kelimeyi
niyete göre yeniden ağırlıklandırır: "aptalsın" saldırı (×1,25), "aptal
değilsin" iltifat (×0,15), "bana aptal dedi" şikâyet (×0,20), "kendimi
aptal hissettim" öz-ifade (×0,20). "aptal değil misin" ise retorik
olumsuzlama olarak saldırı sayılır. Yumuşatmanın yalnızca çarpan değil aynı
zamanda **tavan** olması, tacize uğrayan kullanıcının uyarı almasını yapısal
olarak engeller.

**Özgün mimari kararı — bulut kademesinin kaldırılması.** Sunucu tarafında
çalışan, kullanıcı onaylı bir dil modeli yeniden yazma servisi yazılmış, 50
testle doğrulanmış ve uçtan uca sınanmıştır. Sonra **kasıtlı olarak
kaldırılmıştır.** Üç gerekçe: (a) "metin cihazdan çıkmaz" iddiasına
açıklanması gereken bir istisna ekliyordu, (b) jürinin çalıştıramayacağı
üçüncü taraf API bağımlılığı getiriyordu, (c) katkısı yalnızca öneri
akıcılığıydı; tespit, bağlam çözümleme ve müdahale onsuz da çalışıyordu.
Karardan korunan ilke rapora ayrıca girmektedir: **model bir öneri kaynağıdır,
bir otorite değildir.** Bir dil modeli akıcı ama işe yaramaz bir öneri
üretebilir; bunu istemden rica ederek değil, deterministik bir motorla ölçüp
geçemeyeni atarak garanti edersiniz.

**Pazarda uygulanabilirlik.** Katman platforma bağlı değildir; Türkçe metin
girişi olan herhangi bir yüzeye (mesajlaşma, forum, yorum alanı, kurumsal
iletişim aracı, e-posta) taşınabilir. Harici bağımlılığı, API anahtarı ve
sunucu maliyeti bulunmadığından entegrasyon yükü bir kütüphane bağımlılığı
eklemekten ibarettir.

**Yerlilik.** Çözümün tamamı yerli olarak geliştirilmiştir ve hiçbir yabancı
yapay zekâ servisine bağımlı değildir. Türkçe normalizasyon, ünlü uyumu ve
ek çözümlemesi yapan biçimbilim modülü, toksisite sözlüğü, edimbilimsel örüntü
ailesi, nefret söylemi kuruluş ailesi, gönderge çözümleyici ve değerlendirme
kümesinin tamamı proje kapsamında sıfırdan üretilmiştir. Ürün, çalışması için
hiçbir dış servise çağrı yapmaz; ağ bağlantısı olmadan tam işlevlidir.

---

# 3. TEKNOLOJİ KULLANIMI

## 3.1. İzlenecek Yöntem, Altyapı ve Sürüm Kontrolü

**Yazılım dilleri ve teknolojiler.**

| Bileşen | Teknoloji | Not |
|---|---|---|
| Çekirdek motor | **Dart 3.13** (saf Dart) | Harici paket bağımlılığı **yok** |
| Mobil istemci | **Flutter 3.x** | Android / iOS / masaüstü tek kaynak |
| Test ve ölçüm | `package:test`, özel değerlendirme aracı | 136 çekirdek testi |
| Sürüm kontrolü | **Git** | `[DEPO BAĞLANTISI]` |

Çekirdek motorun saf Dart olması bilinçli bir mimari karardır: aynı motor
mobil istemcide, komut satırı değerlendirme aracında ve gerekirse sunucu
tarafında **birebir aynı kodla** çalışır. Farklı ortamların farklı karar
vermesi mümkün değildir, çünkü hepsi aynı paketi çağırır.

**Veri setleri.** Toplam **336 etiketli örnek**, beş dilim:

| Küme | Örnek | Amaç |
|---|---|---|
| Geliştirme (`gold_dataset.dart`) | 256 | Geliştirme ve regresyon kalkanı |
| Ayrık (`holdout_dataset.dart`) | 80 | Genelleme ölçümü |

| Dilim | Geliştirme | Ne ölçer |
|---|---|---|
| Açık saldırı | 55 | Sözlük katmanının kapsamı |
| Örtük saldırı | 57 | Küfürsüz düşmanlık |
| Nefret söylemi | 45 | Kimlik hedefli düşmanlık **ve** masum kimlik beyanını rahat bırakma |
| Masum / tuzak | 79 | Kesinlik — kümenin %31'i |
| Bağlam | 20 | Mağduru cezalandırmama |

Kümenin en değerli kısmı **yakın-kaçış çiftleridir**: saldırgan kalıplara
kelime düzeyinde benzeyen ama düşmanca olmayan cümleler. "senin gibilerden bu
beklenirdi" ↔ "senin gibi düşünenler haklı", "sana ne" ↔ "sana ne
getireyim marketten", "sus artık" ↔ "sus payı vermişler". Bu çiftler
olmadan ölçülen kesinlik şişkin çıkar.

**Analiz yöntemleri.** Her çalıştırmada kesinlik, duyarlılık, özgüllük, F1,
F0.5, doğruluk ve kategori doğruluğu; karışıklık matrisi; dilim bazında
ayrıştırılmış sonuçlar; ve katman izolasyonu için A/B karşılaştırması
üretilir. Yanlış pozitif ve yanlış negatiflerin tamamı, gerekçe notlarıyla
birlikte listelenir.

```
dart test                                  # 136 test
dart run bin/evaluate.dart --hepsi         # tüm metrikler
dart run bin/evaluate.dart --karsilastir   # katman katkısı A/B
dart compile exe bin/evaluate.dart         # AOT (cihazdaki biçim) ölçümü
```

**Teknik altyapı.** Ürün, çalışma zamanında hiçbir sunucu bileşenine ihtiyaç
duymaz. Çözümlemenin tamamı istemci sürecinde, bellekte gerçekleşir; ağ
çağrısı, veri tabanı ve kalıcı depolama yoktur. Topluluk sağlığı
toplulaştırması da cihazda yapılır; platforma gönderilmesi hâlinde giden şey
yalnızca k-anonimlik uygulanmış sayılardır. Bu, ürünün mahremiyet iddiasının
mimari karşılığıdır: gizlilik politikası maddesi değil, çıkarılmış bir
yüzeydir.

**Kod reposu ve sürüm kontrolü.**

> ⛔ `[DEPO BAĞLANTISI]` — Depo bugün oluşturulacaktır. Rubrik bu maddeye
> 1 puan, commit geçmişiyle takip edilebilirliğe 1 puan vermektedir.

Geliştirme süreci Git ile, aşamalı ve gerekçeli commit'lerle yürütülmüştür.
Commit geçmişi yalnızca "ne yapıldığını" değil, **kararların neden
değiştiğini** de kaydeder; örneğin bulut kademesinin ürüne bağlanması
(`7601d6f`) ve dört gün sonra kasıtlı olarak kaldırılması (`2fe8d82`), gerekçe
belgesiyle birlikte (`5f281db`) geçmişte izlenebilir durumdadır. Aynı şekilde
devralınan altyapıdan gelen ve ölçülmemiş olduğu için kaldırılan "uçtan uca
şifreleme" iddiaları da geçmişte açıkça düzeltilmiştir (`8e45d75`).

## 3.2. Model ve Veri Doğrulama

**Veri ön işleme.** Girdi metni, çözümlemeden önce çok aşamalı bir
normalizasyondan geçer:

| Aşama | Örnek |
|---|---|
| Karakter ikamesi (leet/gizleme) | `$3r3fsiz` → `serefsiz` |
| Ayırıcı temizleme | `a.p.t.a.l` → `aptal` |
| Ünlü tekrarı daraltma | `aptaaaal` → `aptal` |
| Aksan katlama (çift varyant) | `şerefsiz` → `serefsiz` (ikisi de saklanır) |
| Simgeleştirme ve kök eşleştirme | `aptallığın` → kök: `aptal` |

Aksan katlamasının **çift varyantlı** yapılması kritiktir: katlanmış biçim
gizleme hilelerine direnç sağlar, katlanmamış biçim ise meşru kelimelerle
çakışmayı önler. Türkçe'nin ünlü uyumu bu ayrımı katlamadan sonra da
koruduğundan, ambigü köklerde yalnızca çoğul biçim kullanılır.

**Model geliştirme süreci.** Sistemde eğitilmiş bir sinir ağı ağırlığı
bulunmamaktadır; sınıflandırıcı **deterministik ve denetlenebilir** bir örüntü
motorudur. Bu bilinçli bir seçimdir: bu problemde en pahalı hata yanlış
pozitiftir ve deterministik bir motorda her kararın hangi kurala dayandığı
gösterilebilir, kara kutu bir modelde gösterilemez. Açıklanabilirlik burada
bir özellik değil, ürünün temel vaadidir.

Örüntülerin türetilmesi, denetimli bir modelin eğitimiyle aynı disiplini
izlemiştir:

1. **Etiketleme.** Beş dilimli küme, davranış sınıfları hedeflenerek yazıldı.
2. **Taban ölçüm.** Devralınan motor kümeye karşı ölçüldü: duyarlılık %44,3.
3. **Hata çözümlemesi.** Her yanlış negatif, dilbilimsel aile olarak
   sınıflandırıldı (yetkinlik reddi, ötekileştirme, örtük tehdit, alaycı övgü…).
4. **Örüntü türetme.** Her aile için, çekim varyantlarını kapsayan örüntüler
   yazıldı.
5. **Regresyon kilidi.** Her düzeltme bir testle sabitlendi; testler çözümü
   değil **hatayı** anlatacak biçimde adlandırıldı.
6. **Kabul koşulu.** Bir katman ancak duyarlılığı artırırken **kesinliği
   düşürmüyorsa** kabul edildi.

Ölçüm altyapısı, ilk çalıştırmasında mevcut 31 birim testinin göremediği beş
gerçek motor hatası ortaya çıkarmıştır: yönelimin yalnızca eşleşen kelimenin
kendi ekinden okunması, öz-yönelimin yalnızca zamirden okunması, yumuşatmanın
tavansız çarpan olması, tam eşleşmeli terimlerin çekimlenememesi ve retorik
olumsuzlamanın kaçış yolu oluşturması. Bu, **test geçmenin doğruluk anlamına
gelmediğinin** doğrudan kanıtıdır ve raporun metodolojik omurgasıdır.

**Aşırı öğrenme (overfitting) önlemleri.** Bu başlık, projenin en titiz
davrandığı noktadır.

*Önlem 1 — Ayrık küme.* Geliştirme kümesinden bağımsız 80 örneklik bir küme
kuruldu. Kural: cümleler örüntülerin düzenli ifadelerine **bakılmadan** yazıldı
(çekim değiştirildi, kelime sırası bozuldu, eşanlamlı kullanıldı), ölçüm **bir
kez** alındı ve sonuç **düzeltme yapılmadan** kaydedildi.

*Önlem 2 — Yanlış pozitif tuzakları.* Kümenin %31'i masum metinden oluşur ve
çoğu, naif filtreleri düşürmek üzere seçilmiş gerçek Türkçe kelimelerdir:
"şikayetimi ilettim", "kargoyu götürdü", "malzeme listesi", "sikke
koleksiyonu", "hıyar salatası", "susadım".

*Önlem 3 — Yapısal testler.* Kimlik adlarının sözlüğe sızmasını engelleyen test
ve sinyal sınıfının metin taşımasını engelleyen test, ihlal edildiğinde
derleme/test kırar.

*Önlem 4 — Kesinlik öncelikli hedef fonksiyon.* Raporlanan asıl ölçüt F0.5'tir.

**Ölçüm sonuçları (20 Ağustos 2026, Dart 3.13.1).**

| Ölçüm | Geliştirme kümesi (256) |
|---|---|
| Kesinlik | %100,0 |
| Duyarlılık | %99,3 |
| Özgüllük | %100,0 |
| F1 | %99,6 |
| **F0.5** | **%99,8** |

Dilim bazında: açık saldırı duyarlılık %100,0 · örtük saldırı duyarlılık
%100,0 · nefret söylemi F1 %97,3 · masum/tuzak özgüllük %100,0 · bağlam F1
%100,0.

**Katman katkısının izolasyonu.**

| Metrik | Yalnız sözlük | + Örüntü katmanları | Değişim |
|---|---|---|---|
| Kesinlik | %100,0 | %100,0 | **0,0 puan** |
| Duyarlılık | %44,0 | %99,3 | **+55,2 puan** |
| Özgüllük | %100,0 | %100,0 | **0,0 puan** |
| F1 | %61,1 | %99,6 | +38,5 puan |

Dilim bazında duyarlılık: açık saldırı %98,2 → %100,0 · **örtük saldırı %1,8 →
%100,0** · **nefret söylemi %10,5 → %94,7** · bağlam %66,7 → %100,0.

Bu tablo, "yasaklı kelime listesi yetmez" cümlesini bir görüşten bir ölçüme
dönüştürür: kimlik hedefli düşmanlığın yedide altısı tek bir hakaret sözcüğü
içermez.

**⚠️ Genelleme başarımı ve veri sızıntısı üzerine dürüstlük beyanı.**
Geliştirme kümesindeki %99,6 bir genelleme kanıtı **değildir**; kümeyi de
örüntüleri de aynı kişi yazmıştır. Ayrık küme üzerinde alınan ilk ve tek
geçerli genelleme ölçümü **F1 = %84,2**'dir (kesinlik %88,9, duyarlılık
%80,0). Aradaki yaklaşık 16 puanlık fark, ezberleme payının büyüklüğüdür ve
ölçüm altyapısının en değerli çıktısıdır.

Bu ölçümün ardından ayrık kümede görülen üç motor hatası düzeltilmiştir.
Düzeltmeden sonra **aynı küme üzerinde ölçülen sonuç artık genelleme
ölçmemektedir**; küme, motorun görüp uyum sağladığı bir geliştirme kümesine
dönüşmüştür. Bugün aynı küme %99,0 vermektedir ve değerlendirme aracı bunu
kendisi uyarmaktadır. Bu nedenle raporlanan genelleme sayısı **%84,2** olarak
korunmuştur.

> `[GÜNCELLENECEK — YENİ AYRIK KÜME]` İkinci etiketleyici tarafından, koda ve
> mevcut kümelere bakılmadan üretilecek bağımsız küme ile yeni genelleme
> ölçümü buraya girecektir. Hakemler arası uyum (Cohen's kappa) da bu ölçümle
> birlikte raporlanacaktır.

**Performans.** Ölçüm, ürünün cihazda çalıştığı biçim olan **AOT derlenmiş**
ikili üzerinde alınmıştır; JIT yalnızca geliştirme biçimidir.

| Yapılandırma | Ortalama çözümleme |
|---|---|
| Tam hat (sözlük + örüntü + nefret + gönderge) | **193,3 µs** |
| Yalnız sözlük | 47,3 µs |

193 µs, 60 FPS kare bütçesinin (16 ms) **%1,2'sidir**. Bu nedenle gecikmeli
tetikleme (debounce) gerekmemekte, geri bildirim gerçekten anlık olmaktadır.
Gönderge katmanının maliyeti ölçülerek sıfıra indirilmiştir: kimlik söz
varlığı taraması tembelleştirilmiş, öncül araması ancak bir gönderge örüntüsü
eşleştiğinde çalışır hâle getirilmiştir.

**Bilinen sınır.** Öncülü olmayan gönderge kasıtlı olarak kaçırılmaktadır:
"bunların soyunu kurutmak lazım" tek başına işaretlenmez, çünkü zamirin kime
gönderdiği metinden bilinemez. Zamirden kimlik uydurmak, katmanın kesinlik
iddiasını çürütürdü. Bu örnek kümede "müdahale" etiketiyle bırakılmıştır ki
kararın maliyeti ölçümde görünsün.

## 3.3. Kullanıcı Deneyimi (UI/UX) Tasarımı

**Personalar.**

| # | Kim | İhtiyaç | Ürünün vaadi |
|---|---|---|---|
| P1 | Tartışmada ilk tepkiyle yazan, sonra pişman olan kullanıcı | Gönderdikten sonra silmek zorunda kalmamak | Yazarken duraksama |
| P2 | Tacize uğrayan ve durumu anlatmak isteyen kullanıcı | Anlattığı için susturulmamak | Alıntı ve şikâyet ayırt edilir |
| P3 | Kendi kimliğinden söz eden kullanıcı | Kimlik adı yüzünden filtrelenmemek | Kimlik adı hiçbir zaman tetikleyici değildir |
| P4 | Topluluk yöneticisi | Topluluğun sağlığını görmek | Metni görmeden, davranıştan üretilen panel |

P2 ve P3, ürünün rakiplerinden ayrıldığı yerdir: çoğu filtre bu iki kişiyi
cezalandırır; burada ikisi de birer kabul ölçütüdür ve testlerle korunur.

**Kullanıcı akışları.**

*A1 — Ana akış.* Kullanıcı yazar → cihaz üstü çözümleme (~193 µs, debounce
yok) → risk seviyesine göre üç yol: temiz ise hiçbir şey; dikkat ise yalnızca
kenarlık rengi; riskli/yüksek ise kenarlık + gerekçe + yeniden yazma önerisi.
Kullanıcı öneriyi uygulayabilir, kendi düzeltebilir veya görmezden gelebilir.
Risk yüksekse gönderim öncesi onay diyaloğu açılır; "Vazgeç" ve "Yine de
gönder" seçenekleri sunulur. Gönderim sonrası **metin içermeyen** anonim bir
sinyal üretilir.

*A2 — Sinyal sonucu.* Panelin ölçtüğü şey uyarı sayısı değil, uyarının işe
yarayıp yaramadığıdır. Bu nedenle gönderim anındaki duruma değil, yazım boyunca
görülen **en yüksek riske** bakılır; aksi hâlde kullanıcı düzelttiğinde
müdahale hiç olmamış gibi görünürdü. Dört sonuç ayırt edilir: `temizGonderim`,
`uyariyaRagmenGonderdi`, `oneriyiKabulEtti`, `kendiDuzeltti`. Sonuncusu da
**başarı sayılır** — ürün öneriyi dayatmaz.

*A3 — Mağdur akışı.* "Bana 'şerefsiz' dedi, çok üzüldüm" cümlesinde 0,88
taban şiddetli bir terim geçmesine rağmen hiçbir şey olmaz: bağlam katmanı bunu
aktarım olarak tanır (×0,20) ve yumuşatma tavanı devreye girerek sonucu eşiğin
altına indirir.

*A4 — Topluluk paneli akışı.* Panel açıldığında, herhangi bir sayıdan önce
"Bu paneldeki hiçbir sayı mesaj içeriğinden üretilmez" ifadesi görünür.
Sağlık puanı, düzeltme oranı, müdahale oranı, günlük eğilim ve uyarı türleri
listelenir; 5 gözlemin altındaki kategoriler k-anonimlik gereği açılmaz ve bu
kullanıcıya açıkça söylenir. En altta "Dışarı ne gider" kartı, platforma
gönderilmesi hâlinde giden veriyi harfi harfine gösterir. Panelde **ihlal eden
mesajların listesi yoktur ve olamaz** — alışıldık moderasyon panellerinin ana
ekranı budur; ürünün tezi tam olarak bunun reddidir.

**Arayüz tasarım kararları ve gerekçeleri.**

| Karar | Gerekçe |
|---|---|
| Müdahale şiddeti riskle orantılı | Kullanıcıyı her seferinde uyarmak uyarıyı görünmez kılar |
| Hiçbir seviyede gönderim engellenmez | Engellemek kullanıcıyı başka kanala iter; ürün onu bir daha göremez |
| Her uyarıda "hangi kelime" ve "neden" | Kara kutu moderasyon güveni yok eder |
| Öneri dayatılmaz, seçim kullanıcıda | Ürünün tezi: yaptırım değil, duraksama davranışı değiştirir |
| Yüksek riskte onay diyaloğu, engel değil | Sorulan soru ve kaydedilen tereddüt, engellemekten çok şey değiştirir |
| Panelde mesaj listesi yok | "Metin cihazdan çıkmaz" iddiasıyla tutarlılık |

**Erişilebilirlik yaklaşımı.**

| Karar | Gerekçe |
|---|---|
| Risk yalnızca renkle anlatılmaz | Renk körlüğünde kenarlık rengi tek başına okunamaz; her seviyede metin gerekçe de bulunur |
| Grafik çubukları `Semantics` etiketi taşır | Ekran okuyucu "3 gün önce, müdahale oranı yüzde 18" der; çubuk yüksekliği erişilebilir değildir |
| Kategori çubukları sayıyı metin olarak da yazar | Aynı gerekçe |
| Dokunma hedefleri 48 px altına inmez | Material asgari hedef boyutu |
| Renk paleti WCAG AA kontrastını sağlar | Koyu zeminde okunmayan marka kırmızısı bu nedenle değiştirildi |
| Onay diyaloğunda yıkıcı eylem varsayılan değildir | "Yine de gönder" ikincil konumdadır |

> ⛔ **Kullanılabilirlik testi.** Bu aşamada gerçek kullanıcıyla görev tabanlı
> test yapılmamıştır. 5–8 katılımcılı, görev tabanlı bir oturum ve tam
> erişilebilirlik değerlendirmesi (ekran okuyucu, kontrast ölçümü, dokunma
> hedefi denetimi) mentörlük sürecinde (2–7 Eylül) planlanmıştır. Sonuçlar
> final sunumu teslimatına girecektir. Rubrik bu maddeye 1 puan vermektedir;
> uydurulmuş test sonucu yazmak yerine planın beyan edilmesi tercih edilmiştir.

**Henüz tasarlanmamış akışlar (dürüstlük beyanı).** İlk kullanım
(onboarding), özelliği kapatma akışı ve yanlış pozitif bildirimi henüz
tasarlanmamıştır; çünkü gerçek kullanıcı verisi olmadan yazılacak akış
tahminden ibaret olur. Özelliğin kapatılabilir olması ayrıca etik bir
gerekliliktir: "sansür değil" iddiası ancak kapatılabiliyorsa doğrudur.

---

# 4. UYGULANABİLİRLİK

## 4.1. Verimlilik ve Etkinlik

**Moderasyon yükünde kaynağında azalma.** Mevcut moderasyon zinciri
şikâyet → inceleme → karar → kaldırma adımlarından oluşur ve her adım insan
emeği gerektirir. Üslup, zincirin **girdisini** azaltır: hakaret içeren metnin
bir kısmı hiç gönderilmez. Kaldırılan her içerik için harcanan moderatör
zamanı, şikâyet eden kullanıcının maruz kaldığı zarar ve platformun itibar
maliyeti, o içerik hiç yayımlanmadığında tümüyle ortadan kalkar.

**Sıfır çıkarım maliyeti.** Bulut tabanlı moderasyon çözümleri çağrı başına
ücretlendirilir; günde milyonlarca gönderi işleyen bir platformda bu, doğrudan
işletme maliyetidir. Üslup'ta çözümleme kullanıcının cihazında yapıldığından
platformun **marjinal çıkarım maliyeti sıfırdır** ve kullanıcı sayısıyla
birlikte artmaz. Ölçeklenme maliyeti, sunucu kapasitesinden bağımsızdır.

**Gecikme bütçesi.** 193 µs'lik çözümleme süresi, 60 FPS kare bütçesinin
%1,2'sidir. Bu, geri bildirimin gecikmeli tetikleme olmadan, her tuş vuruşunda
verilebilmesini sağlar — kullanıcı deneyimi açısından belirleyici olan budur.

**Ölçülebilir etkinlik.** Ürünün başarısı, ürettiği uyarı sayısıyla değil,
uyarıların **davranışı değiştirme oranıyla** ölçülür. Topluluk sağlığı katmanı
tam olarak bunu ölçer ve dört sonucu ayırt eder: temiz gönderim, uyarıya rağmen
gönderim, önerinin kabulü, kullanıcının kendi düzeltmesi. Buradan türetilen
**düzeltme oranı** —(öneriyi kabul + kendi düzeltti) / toplam müdahale— ürünün
birincil etkinlik göstergesidir ve gerçek kullanımda doğrudan izlenebilir.
Ölçüm metin içermediği için bu izleme mahremiyeti ihlal etmez.

İkinci ölçülebilir gösterge, sınıflandırıcının kendi başarımıdır: ayrık küme
üzerinde F1 %84,2, geliştirme kümesinde kesinlik %100,0 ve masum dilimde
özgüllük %100,0. Yanlış pozitif oranının düşük tutulması, kullanıcının özelliği
kapatmamasının ön koşuludur.

## 4.2. Hedef Kitle

**Birincil hedef kitle.** Türkçe yazan tüm sosyal medya kullanıcıları; özellikle
tartışmalı konularda ilk tepkiyle yazan ve sonradan pişmanlık duyan kullanıcı
profili.

**İkincil hedef kitleler.**
- **Taciz hedefi olan kullanıcılar** — mevcut filtrelerin yanlışlıkla
  susturduğu grup. Bu üründe alıntı, aktarım ve şikâyet ayırt edilir.
- **Kimliğinden söz eden kullanıcılar** — kimlik adı hiçbir zaman tetikleyici
  değildir; "Ben Kürtüm" gibi cümleler işaretlenmez.
- **Platform moderasyon ekipleri** — kaynağında azalan ihlal, azalan kuyruk.
- **İçerik üreticileri** — yorum alanının yaşanabilir kalması.
- **Kurumsal ve eğitim kullanıcıları** — kurum içi iletişim araçları ve
  dijital vatandaşlık eğitimi bağlamı.

> `[İSTATİSTİK — DOLDURULACAK]` Türkiye'deki sosyal medya kullanıcı sayısı ve
> Türkçe içerik hacmi, §9'daki kaynak [1] ile birlikte buraya yazılacaktır.
> Rubrik "hedef kitlenin genişliği/büyüklüğü" maddesine 1 puan vermektedir.

**Hedef kitleyle uyum kanıtı.** Ürünün hedef kitleye uygunluğu üç noktada
gösterilebilir. Birincisi, dil uyumu: çözüm Türkçe'ye özgü olarak
geliştirilmiştir ve eklemeli yapı, argo, gizleme hileleri ile aksan kullanımı
doğrudan modellenmiştir; İngilizce merkezli çözümlerin bu kitlede yetersiz
kalmasının nedeni budur. İkincisi, davranış uyumu: müdahale merdiveni,
kullanıcıyı cezalandırmadığı ve gönderimi engellemediği için özelliğin
kapatılma olasılığını azaltır. Üçüncüsü, mahremiyet uyumu: metnin cihazdan
çıkmaması, mahremiyet hassasiyeti yüksek kullanıcıların benimseme önündeki en
büyük engelini ortadan kaldırır.

## 4.3. Teknolojik Yenilik ve Uygulanabilirlik

**Yeniliğin teknik düzeyi.** Üç bileşen literatürdeki yaygın yaklaşımlardan
ayrışır:

1. **Yuva–kuruluş nefret söylemi modeli.** Kimlik adı bir yasaklı kelime değil,
   düşmanca bir sözdizimsel kuruluşun içindeki bir yuvadır. Bu, nefret söylemi
   tespitindeki en yaygın yanlış pozitif kaynağını —korunan grubun adının
   kendisini— yapısal olarak ortadan kaldırır. Kesinliği ayakta tutan yüklem
   eki şartı ve ambigü köklerde yalnızca çoğul biçim kullanımı, Türkçe'nin
   biçimbilgisine özgü çözümlerdir.
2. **Edimbilimsel örüntü katmanı.** Saldırganlığı sözcük dağarcığında değil,
   sözcüklerin dizilişinde arar. Sekiz edimbilimsel aile ve 50 örüntü ile
   küfürsüz düşmanlığı yakalar; ölçülen katkısı duyarlılıkta +55,2 puan,
   kesinlikte 0,0 puan kayıptır.
3. **Bağlam ağırlıklandırma.** Aynı sözcüğün saldırı, iltifat, şikâyet ve
   öz-ifade bağlamlarında yeniden ağırlıklandırılması, yumuşatmanın tavanlı
   olması ve retorik olumsuzlamanın kaçış yolu olmaktan çıkarılması.

**Teknik olarak hayata geçirilebilirlik.** Fikir hâlihazırda hayata
geçirilmiştir. Çekirdek motor çalışmakta, 136 test geçmekte, metrikler
yeniden üretilebilir komutlarla ölçülmekte ve mobil istemci üzerinden uçtan uca
gösterilebilmektedir. Çekirdeğin harici bağımlılığının bulunmaması, entegrasyon
riskini asgariye indirir.

**Ölçeklenebilirlik.** Ölçeklenme bu mimaride sunucu kapasitesi sorunu
değildir: çözümleme kullanıcının cihazında yapıldığı için sistem, kullanıcı
sayısıyla **doğrusal ek maliyet olmadan** büyür. Ürün ölçeklenmesi üç eksende
tanımlıdır: (i) yüzey ekseni — mesajlaşma, forum, yorum alanı, kurumsal araç;
(ii) dil ekseni — mimari dile bağımlı değildir, sözlük ve örüntü aileleri
değiştirilerek başka dillere taşınabilir; (iii) yetenek ekseni —
`ToxicityClassifier` arayüzü hazırdır, sinir ağı tabanlı bir sınıflandırıcı
ikinci bir uygulama olarak eklenebilir ve mevcut altyapıyla karşılaştırılabilir.

---

# 5. YAYGIN ETKİ

## 5.1. Toplumsal Fayda ve Erişim Potansiyeli

**Geniş kullanıcı kitlelerine ulaşma potansiyeli.** Çözüm tek bir platforma
bağlı değildir. Cihaz üstü bir Türkçe katman olarak, Türkçe metin girişi
yapılan herhangi bir yüzeye taşınabilir: sosyal medya uygulamaları, mesajlaşma
uygulamaları, forumlar, haber sitelerinin yorum alanları, kurumsal iletişim
araçları ve e-posta istemcileri. Entegrasyon yükü bir kütüphane bağımlılığı
eklemekten ibarettir; sunucu kurulumu, API anahtarı ve altyapı maliyeti
gerektirmez. Ağ bağlantısı olmadan çalışması, düşük bağlantı kalitesine sahip
bölgelerde de tam işlevsellik anlamına gelir.

Erişimi hızlandıran ikinci etken, ürünün platforma değil **kullanıcıya** ait
olabilmesidir: katman bir klavye uygulaması veya sistem düzeyinde bir metin
giriş yüzeyi olarak paketlendiğinde, platformların benimsemesini beklemeden
doğrudan kullanıcıya ulaşabilir.

**Sosyal medya ekosistemine katkı.** Ekosistemin bugünkü moderasyon modeli,
zararı oluştuktan sonra onarmaya çalışır ve bu onarım hiçbir zaman tam
değildir. Üslup, moderasyon karar noktasını platformdan kullanıcıya taşıyarak
modeli değiştirir. Platform açısından ihlal hacminin kaynağında azalması,
moderasyon kuyruğunun kısalması ve moderatörlerin maruz kaldığı psikolojik
yükün hafiflemesi anlamına gelir. Ayrıca ürün, moderasyonun **açıklanabilir**
yapılabileceğini gösterir: bugün kullanıcıların en büyük şikâyetlerinden biri,
içeriklerinin gerekçesiz kaldırılmasıdır. Her uyarıda hangi ifadenin neden
işaretlendiğinin söylenmesi, moderasyona duyulan güveni doğrudan artırır.

**Toplumsal fayda kapasitesi — somut örnekler.**

*Örnek 1 — Mağdurun susturulmaması.* Tacize uğradığını anlatan kullanıcının
mesajı, içindeki hakaret sözcüğü nedeniyle mevcut filtreler tarafından
işaretlenir. Üslup'ta bu mesaj işaretlenmez; bağlam katmanı aktarımı tanır ve
yumuşatma tavanı sonucu eşiğin altında tutar. Bu, şikâyet mekanizmasının
işlemesinin ön koşuludur.

*Örnek 2 — Kimlik beyanının serbest kalması.* "Ben Kürtüm", "Eşcinsel hakları
konferansına katıldım" gibi cümleler, kimlik adlarını yasaklayan sistemlerde
filtrelenir ve sonuç, korunmak istenen grubun susturulması olur. Üslup'ta
kimlik adı hiçbir zaman tek başına bulgu üretmez; bu davranış yapısal bir
testle korunur ve 20 masum kimlik cümlesinin hiçbiri işaretlenmez.

*Örnek 3 — Yasal riskin kullanıcıya hatırlatılması.* Bir grubun varlık hakkını
reddeden ifadelerde kullanıcıya gösterilen gerekçe, ifadenin Türk Ceza Kanunu
216. madde kapsamına girebileceğini belirtir. Bu, cezalandırma değil
bilgilendirmedir ve kullanıcıyı farkında olmadan suç oluşturabilecek bir
paylaşımdan koruma işlevi görür.

*Örnek 4 — Gençlerde dijital okuryazarlık.* Ürün, saldırgan ifadenin neden
saldırgan olduğunu her seferinde açıklar: "Kişiliğin bütününü reddediyor.
Davranışı değil, kişiyi hedef alıyor." Bu açıklamalar, tekrarlandıkça bir
farkındalık aracına dönüşür ve özellikle genç kullanıcılarda dijital
vatandaşlık eğitiminin doğal bir uzantısı hâline gelir.

*Örnek 5 — Mahremiyetten ödün vermeyen topluluk yönetimi.* Topluluk sağlığı
paneli, bir topluluğun iletişim iklimini metin okumadan görünür kılar. Panel
davranıştan beslenir, sinyal sınıfı yapısal olarak metin taşıyamaz ve 5
gözlemin altındaki kategoriler k-anonimlik gereği açılmaz. Böylece topluluk
yönetimi ile bireysel mahremiyet arasındaki geleneksel ödünleşim ortadan kalkar.

**Dijital yaşam kalitesine etkisi.** Ürünün hedeflediği değişim, kaldırılan
içerik sayısı değil, hiç yazılmayan hakaretlerdir. İnsanlar bu cümleleri yüz
yüzeyken kurmaz; ekran arkasında kurar. Kaybolan duraksamanın geri konması,
şartnamenin ilk hedefi olan "dijital ortamda yüz yüze bakar gibi etkileşim"
tanımının doğrudan karşılığıdır. Bunun bireysel karşılığı, kullanıcının
gönderdikten sonra pişman olacağı bir mesajı hiç göndermemesi; toplumsal
karşılığı ise tartışma ortamının, katılmak isteyen ama hedef olmaktan çekinen
kullanıcılar için yaşanabilir kalmasıdır.

---

# 6. SÜRDÜRÜLEBİLİRLİK

## 6.1. Ticarileştirme Potansiyeli ve İş Modeli

**Gelir modeli.** Ürün, uçtan uca bir sosyal medya uygulaması olarak değil,
**gömülebilir bir katman (SDK)** olarak konumlanır. Dört gelir kanalı tanımlıdır:

| # | Kanal | Müşteri | Modeli |
|---|---|---|---|
| 1 | **Platform lisansı** | Sosyal medya ve mesajlaşma platformları | Yıllık kurumsal lisans; aktif kullanıcı bandına göre kademeli |
| 2 | **Kurumsal iletişim** | Kurum içi iletişim araçları, müşteri hizmetleri | Koltuk başına yıllık abonelik |
| 3 | **Eğitim** | Okullar, dijital vatandaşlık programları | Kurum lisansı; kâr amacı gütmeyen kullanımda indirimli |
| 4 | **Kamu ve yerel yönetim** | Şikâyet/ihbar hatları, vatandaş geri bildirim kanalları | Proje bazlı entegrasyon + bakım |

**Sektöre ve ülke ekonomisine katma değer.** Bugün Türkçe içerik moderasyonu
ihtiyacı büyük ölçüde yabancı bulut servisleriyle karşılanmaktadır; bu hem
döviz cinsinden dışa bağımlılık hem de Türkçe verinin yurt dışına çıkması
anlamına gelir. Üslup, çıkarımı cihaza taşıyarak bu bağımlılığın ikisini birden
ortadan kaldırır. Bunun üç somut karşılığı vardır: (i) platformlar için çağrı
başına ödenen moderasyon maliyetinin sıfırlanması, (ii) Türkçe metnin yurt
dışındaki sunuculara gönderilmemesi sayesinde veri egemenliği ve KVKK uyumunun
kolaylaşması, (iii) Türkçe doğal dil işleme alanında ülke içinde kalan bir
bilgi birikimi ve yeniden kullanılabilir bir değerlendirme kümesi.

Maliyet yapısı da ayrışmaktadır: bulut tabanlı rakiplerde birim maliyet kullanım
hacmiyle doğru orantılı artarken, cihaz üstü mimaride **marjinal maliyet
sıfırdır**. Bu, ölçek büyüdükçe genişleyen bir kâr marjı anlamına gelir ve
fiyatlandırmada rekabet üstünlüğü sağlar.

**Stratejik iş ortaklıkları.** Kısa vadede yerli sosyal medya ve mesajlaşma
platformları ile entegrasyon; orta vadede klavye uygulamaları ve mobil işletim
sistemi metin giriş yüzeyleri; ayrıca Türkçe doğal dil işleme alanında çalışan
üniversite grupları ile ortak veri kümesi üretimi ve akademik doğrulama. Kamu
tarafında dijital okuryazarlık ve çocuk güvenliği programları, ürünün eğitim
kanalı için doğal ortaklardır.

**Mevcut pazar şartlarında üretilebilirlik.** Ürünün üretilebilirliği zaten
kanıtlanmıştır: çalışan bir prototip, ölçülmüş metrikler ve harici
bağımlılığı olmayan bir çekirdek mevcuttur. Sunucu altyapısı gerektirmediği
için işletme maliyeti geliştirme ve bakım emeğinden ibarettir; bu, erken
aşamadaki bir ekip için taşınabilir bir yüktür.

## 6.2. Finansal, Teknik ve Sosyal Sürdürülebilirlik

**Finansal sürdürülebilirlik.** Ürünün işletme gideri yapısal olarak düşüktür:
çıkarım cihazda yapıldığı için sunucu, GPU ve API kotası maliyeti yoktur;
kullanıcı sayısının artması altyapı gideri doğurmaz. Bu, gelir gelmeden önce
bile ürünün ayakta kalabilmesi anlamına gelir ve erken aşama girişimlerinde en
sık görülen başarısızlık nedenini — ölçekle birlikte artan altyapı maliyeti —
ortadan kaldırır. Gelirin dört kanala (platform, kurumsal, eğitim, kamu)
dağıtılması tek müşteriye bağımlılığı azaltır.

**Teknik sürdürülebilirlik.** Sürdürülebilirliğin teknik dayanağı, projenin
başından beri uygulanan üç disiplindir:

1. **Bağımlılıksız çekirdek.** `civility_core` hiçbir harici pakete bağlı
   değildir; üçüncü taraf bir kütüphanenin bakımsız kalması, sürüm kırması veya
   lisans değiştirmesi ürünü etkilemez.
2. **Regresyon kalkanı.** 136 test ve 336 örneklik ölçüm altyapısı, her
   değişikliğin etkisini ölçülebilir kılar. Bir katman eklendiğinde kesinliğin
   düşüp düşmediği tahmin edilmez, ölçülür. Testler çözümü değil **hatayı**
   anlatacak biçimde adlandırılmıştır; böylece çözüm değişse de test anlamını
   korur.
3. **Yapısal değişmezler.** Kimlik adlarının sözlüğe girmesini ve anonim
   sinyalin metin taşımasını engelleyen testler, ürünün etik vaatlerini kod
   düzeyinde kilitler. Bu vaatler bir belgede değil, derleme/test hattında
   korunur.

Bakım yükü, sözlük ve örüntü ailelerinin güncellenmesinde yoğunlaşır; her ikisi
de veri niteliğindedir ve kod değişikliği gerektirmez. Ölçeklenme, 4.3'te
tanımlanan üç eksende (yüzey, dil, yetenek) mimariyi değiştirmeden mümkündür.

**Sosyal sürdürülebilirlik.** Ürünün toplumsal kabulü, kullanıcının onu bir
sansür aracı olarak görmemesine bağlıdır. Bunu koruyan üç ilke vardır: sistem
hiçbir metni engellemez veya kendiliğinden değiştirmez; her kararını açıklar;
ve özellik kapatılabilir olmalıdır. Ayrıca ürün, korumayı vaat ettiği grupları
susturmadığını ölçümle göstermek zorundadır — kimlik dilimindeki %100 kesinlik
bu nedenle bir performans rakamı değil, bir meşruiyet koşuludur.

**Değişen kullanıcı ihtiyaçlarına uyum.** Dil hızla değişir; yeni argo, yeni
gizleme hileleri ve yeni düşmanlık kalıpları sürekli üretilir. Ürün buna üç
mekanizmayla uyum sağlar: (i) sözlük ve örüntü aileleri veri olarak
güncellenebilir, (ii) ölçüm altyapısı her güncellemenin kesinliğe etkisini
anında görünür kılar, (iii) planlanan "yanlış pozitif bildirimi" akışı,
kullanıcıların hatalı uyarıları işaretlemesine olanak tanıyarak kümenin
bağımsız biçimde büyümesini sağlar. Sinir ağı tabanlı bir sınıflandırıcının
ikinci bir uygulama olarak eklenebilmesi, mimarinin gelecekteki yaklaşımlara
kapalı olmadığını gösterir.

---

# 7. PROJE TAKVİMİ

## 7.1. İş Paketleri ve Zamanlama

**Tamamlanan iş paketleri**

| İP | İş paketi | Alt faaliyetler | Durum |
|---|---|---|---|
| İP-1 | Türkçe normalizasyon | Gizleme direnci, aksan katlama, biçimbilim, kök eşleştirme | Tamamlandı |
| İP-2 | Sözlük tabanlı tespit | Toksisite sözlüğü, çekim farkındalığı | Tamamlandı |
| İP-3 | Ölçüm altyapısı | Beş dilimli küme, kesinlik/duyarlılık/F1/F0.5, A/B karşılaştırma | Tamamlandı |
| İP-4 | Edimbilimsel örüntü katmanı | 8 aile, 50 örüntü, regresyon testleri | Tamamlandı |
| İP-5 | Nefret söylemi katmanı | 5 kuruluş ailesi, 40 kimlik terimi, yapısal test | Tamamlandı |
| İP-6 | Bağlam çözümleme | Saldırı/iltifat/şikâyet/öz-ifade, yumuşatma tavanı | Tamamlandı |
| İP-7 | Gönderge (anafora) katmanı | Cümleler arası zamir bağlama, tembel tarama | Tamamlandı |
| İP-8 | Yerel yeniden yazıcı | İki mod, Türkçe biçimbilim farkındalığı | Tamamlandı |
| İP-9 | Mobil arayüz | Canlı yazım ekranı, sohbet kutusu, müdahale merdiveni | Tamamlandı |
| İP-10 | Topluluk sağlığı katmanı | Anonim sinyal, k-anonimlik, panel | Tamamlandı |

**Kilometre taşları ve kalan plan**

| Tarih | Kilometre taşı | İçerik |
|---|---|---|
| **20 Ağu 2026** | Ön başvuru | KYS başvurusu tamamlandı |
| **21–23 Ağu 2026** | İP-11 · Bağımsız doğrulama | İkinci etiketleyici ile yeni ayrık küme; hakemler arası uyum (kappa) ölçümü |
| **21–23 Ağu 2026** | İP-12 · Rapor derlemesi | Şablona aktarım, mimari diyagramlar, kaynakça |
| **24 Ağu 2026, 17.00** | **Teknik rapor teslimi** | KYS yüklemesi |
| 2 Eyl 2026 | Rapor sonuçları | — |
| **2–7 Eyl 2026** | İP-13 · Mentörlük ve kullanıcı doğrulama | 5–8 katılımcılı görev tabanlı kullanılabilirlik testi; tam erişilebilirlik değerlendirmesi (ekran okuyucu, kontrast, dokunma hedefi) |
| **2–7 Eyl 2026** | İP-14 · Kimlik söz varlığının genişletilmesi | Kapsanmayan grupların eklenmesi, kesinlik regresyon kontrolü |
| **8–13 Eyl 2026** | İP-15 · Sunum ve demo videosu | Final teslimatı hazırlığı |
| **14 Eyl 2026, 17.00** | **Final sunumu teslimi** | KYS yüklemesi |
| 20 Eyl 2026 | Jüriye canlı sunum | Canlı demo |
| 30 Eyl – 4 Eki 2026 | TEKNOFEST Şanlıurfa | — |

**Rapor sonrası teknik yol haritası (final aşamasına paralel).**
BERTurk tabanlı sinir ağı sınıflandırıcısının ONNX ile cihaza taşınması ve
mevcut deterministik motorla aynı küme üzerinde karşılaştırılması; deterministik
katmanın kesinlik kalkanı olarak korunması; yerel yeniden yazıcının akıcılık
ölçümünün (`bin/rewrite_audit.dart`) sayısallaştırılması.

---

# 8. TAKIM YAPISI

## 8.1. Takım Organizasyonu ve Roller

Takım `[TAKIM ÜYE SAYISI]` kişiden oluşmaktadır ve şartnamenin 2–5 kişilik
takım şartını karşılamaktadır.

| Rol | Sorumluluk alanı | Projeye katkısı |
|---|---|---|
| **Takım Kaptanı / Yazılım Mimarisi** | Sistem tasarımı, çekirdek motor, sürüm kontrolü | Katmanlı çözümleme mimarisinin kurgusu; `civility_core` paketinin bağımlılıksız tasarımı; mobil istemci entegrasyonu |
| **Doğal Dil İşleme / Veri Bilimi** | Türkçe biçimbilim, örüntü türetme, değerlendirme | Normalizasyon ve kök eşleştirme; edimbilimsel ve nefret söylemi örüntü aileleri; beş dilimli kümenin tasarımı; kesinlik/duyarlılık/F1/F0.5 ölçüm altyapısı |
| `[EKLENECEKSE]` **Ürün / UI-UX** | Kullanıcı akışları, arayüz kararları, erişilebilirlik | Müdahale merdiveni; personalar ve senaryolar; erişilebilirlik kararları |
| `[EKLENECEKSE]` **Girişimcilik / İş Geliştirme** | İş modeli, pazar analizi, ortaklıklar | Gelir kanalları; rakip kıyaslaması; ticarileştirme planı |

**Disiplinlerin projeye katkısı.** Proje, tek bir disiplinle çözülemeyecek bir
kesişim alanındadır. Yazılım mühendisliği tarafı, çözümlemenin 16 ms'lik kare
bütçesinin %1,2'sinde tamamlanmasını ve motorun harici bağımlılık olmadan
çalışmasını sağlamıştır. Dilbilim ve doğal dil işleme tarafı, Türkçe'nin
eklemeli yapısının, ünlü uyumunun ve yüklem eki davranışının modellenmesini
mümkün kılmıştır; kimlik adlarının ambigü köklerde yalnızca çoğul biçimde
kullanılması kararı doğrudan bu disiplinin ürünüdür. Veri bilimi tarafı,
ölçümün testten farklı olduğunu ve %100 test başarısının %44 duyarlılığı
gizleyebileceğini ortaya çıkarmıştır. Ürün ve etik tarafı ise, sistemin
korumayı vaat ettiği grupları susturmamasını bir kabul ölçütüne dönüştürmüştür.

> **Not:** Şablon kuralı gereği takım üyelerinin isim, fotoğraf ve diğer
> kişisel bilgilerine bu bölümde yer verilmemiştir.

---

# 9. KAYNAKÇA

> **DOĞRULANMADAN KULLANMAYIN.** Aşağıdaki liste, projenin iddialarıyla
> doğrudan ilgili gerçek çalışmaların adaylarıdır. Her birinin künyesi,
> yayın yılı ve DOI/erişim adresi **yayınevi sayfasından teyit edilmeden**
> rapora girmemelidir. Hatalı künye, kaynaksızlıktan daha kötüdür.
> Rubrik bu bölüme 5 puan vermektedir ve format uyumu ayrıca puanlanmaktadır.

**Problemin büyüklüğü ve istatistik (2.1 ve 4.2 için gerekli)**

- `[1]` DataReportal / We Are Social — *Digital 2026: Turkey* raporu.
  Türkiye sosyal medya kullanıcı sayısı ve kullanım süresi verisi.
- `[2]` Türkiye İstatistik Kurumu (TÜİK) — *Hanehalkı Bilişim Teknolojileri
  Kullanım Araştırması*. İnternet ve sosyal medya kullanım oranları.
- `[3]` `[EKLENECEK]` Çevrim içi taciz / nefret söylemine maruz kalma oranına
  ilişkin resmî veya akademik bir kaynak.

**Nefret söylemi tespitinde önyargı — projenin kimlik yaklaşımının dayanağı**

- `[4]` Sap, M., Card, D., Gabriel, S., Choi, Y., Smith, N. A. — *The Risk of
  Racial Bias in Hate Speech Detection*, ACL 2019.
- `[5]` Davidson, T., Bhattacharya, D., Weber, I. — *Racial Bias in Hate Speech
  and Abusive Language Detection Datasets*, ACL Workshop on Abusive Language
  Online, 2019.

**Değerlendirme yöntemi — işlevsel test yaklaşımının dayanağı**

- `[6]` Röttger, P., Vidgen, B., Nguyen, D., Waseem, Z., Margetts, H.,
  Pierrehumbert, J. — *HateCheck: Functional Tests for Hate Speech Detection
  Models*, ACL 2021.
- `[7]` Schmidt, A., Wiegand, M. — *A Survey on Hate Speech Detection using
  Natural Language Processing*, SocialNLP Workshop, 2017.

**Türkçe saldırgan dil ve nefret söylemi**

- `[8]` Çöltekin, Ç. — *A Corpus of Turkish Offensive Language on Social
  Media*, LREC 2020.
- `[9]` `[DOĞRULA]` SemEval-2020 Task 12 (OffensEval) Türkçe alt görevi genel
  değerlendirme makalesi.
- `[10]` `[DOĞRULA]` BERTurk / Türkçe önceden eğitilmiş dil modeli künyesi —
  yol haritasındaki karşılaştırma için atıf verilecekse.

**Mevcut çözümler (2.1 kıyas tablosu için)**

- `[11]` Google Jigsaw — *Perspective API* teknik dokümantasyonu ve
  desteklenen diller listesi. Erişim adresi ve erişim tarihi yazılacaktır.
- `[12]` OpenAI — *Moderation API* dokümantasyonu. Erişim adresi ve erişim
  tarihi yazılacaktır.

**Mahremiyet ve k-anonimlik**

- `[13]` Sweeney, L. — *k-anonymity: A Model for Protecting Privacy*,
  International Journal of Uncertainty, Fuzziness and Knowledge-Based
  Systems, 2002. (Panelde uygulanan k=5 eşiğinin dayanağı.)

**Mevzuat**

- `[14]` 5237 sayılı Türk Ceza Kanunu, madde 216 — *Halkı kin ve düşmanlığa
  tahrik veya aşağılama*. (5.1 örnek 3'ün dayanağı; mevzuat.gov.tr.)

---

## Rapor öncesi son kontrol

| # | İş | Durum |
|---|---|---|
| 1 | `[DEPO BAĞLANTISI]` — GitHub deposu açılıp push edilecek | Bekliyor |
| 2 | `[İSTATİSTİK]` — 2.1 ve 4.2 sayıları kaynakla birlikte | Bekliyor |
| 3 | Kaynakça künyelerinin tamamı doğrulanacak | Bekliyor |
| 4 | `[TAKIM ÜYE SAYISI]` ve rol tablosu netleştirilecek | Bekliyor |
| 5 | Yeni bağımsız ayrık küme + kappa (mümkünse) | İsteğe bağlı |
| 6 | Mimari diyagramların görsel hâli | İsteğe bağlı |
| 7 | Şablona aktarım: Arial 12 / Arial Black 14, 1.15, iki yana yaslı, 2.5 cm | Bekliyor |
| 8 | Kapak: Proje Adı, Takım Adı, Takım ID, Başvuru ID, Tematik Alan | Bekliyor |
| 9 | 30 sayfa sınırı kontrolü | Bekliyor |
| 10 | Şablonun açıklama paragraflarının silindiği doğrulanacak | Bekliyor |
