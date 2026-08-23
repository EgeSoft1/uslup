# Üslup — Proje Teknik Raporu (metin)

**Hazırlanma:** 20–23 Ağustos 2026 · **Teslim:** 24 Ağustos 2026, 17.00 (TSİ)
**Kullanım:** Aşağıdaki metinler `.docx` şablonundaki ilgili başlığın altına
girer. Şablonun açıklama paragrafları ("…ifade edilir", "…detaylandırılır")
**silinecektir**; onlar talimattır, içerik değildir. Biçimlendirme (Arial 12,
başlık Arial Black 14, satır aralığı 1.15, iki yana yaslı, 2,5 cm kenar
boşluğu) Word'de yapılacaktır.

> ⚠️ Kalan yer tutucular: `[DEPO BAĞLANTISI]` (depo açıldığında §3.1 tablosu ve
> §3.1 metni olmak üzere iki yerde), `[TAKIM ID]` ve `[BAŞVURU ID]` (kapakta,
> KYS'den alınacak).
> Metin içi atıflar `[1]`–`[14]` biçimindedir ve §9'daki kaynakçaya karşılık
> gelir; bunlar yer tutucu **değildir**, olduğu gibi kalacaktır.

---

# KAPAK SAYFASI

> Şablonun kapak sayfasına girilecek bilgiler. Ayrı sayfa olacaktır.

| Alan | Değer |
|---|---|
| **Proje Adı** | Üslup |
| **Takım Adı** | Aliz AI |
| **Takım ID** | `[TAKIM ID]` |
| **Başvuru ID** | `[BAŞVURU ID]` |
| **Tematik Alan** | Sosyal Yapay Zekâ |

---

# İÇİNDEKİLER

> Ayrı sayfa olacaktır. Sayfa numaraları Word'de kesinleştikten sonra yazılır.

1. PROJE ÖZETİ
   1.1. Proje Konusu ve Amacı
   1.2. Proje Kapsamı ve Yöntemi
2. KATMA DEĞER VE YENİLİKÇİLİK
   2.1. Problem Tanımı ve Mevcut Çözümler
   2.2. Çözüm Fikri, Özgünlük ve Yerlilik
3. TEKNOLOJİ KULLANIMI
   3.1. İzlenecek Yöntem, Altyapı ve Sürüm Kontrolü
   3.2. Model ve Veri Doğrulama
   3.3. Kullanıcı Deneyimi (UI/UX) Tasarımı
4. UYGULANABİLİRLİK
   4.1. Verimlilik ve Etkinlik
   4.2. Hedef Kitle
   4.3. Teknolojik Yenilik ve Uygulanabilirlik
5. YAYGIN ETKİ
   5.1. Toplumsal Fayda ve Erişim Potansiyeli
6. SÜRDÜRÜLEBİLİRLİK
   6.1. Ticarileştirme Potansiyeli ve İş Modeli
   6.2. Finansal, Teknik ve Sosyal Sürdürülebilirlik
7. PROJE TAKVİMİ
   7.1. İş Paketleri ve Zamanlama
8. TAKIM YAPISI
   8.1. Takım Organizasyonu ve Roller
9. KAYNAKÇA


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
söylemi modeli. Ölçüm altyapısı, öğrenen bir sınıflandırıcının mevcut
deterministik motorla **aynı küme üzerinde karşılaştırılabilmesini** mümkün
kılar; bu karşılaştırma bu proje kapsamında yapılmış ve sonucu §3.2'de
raporlanmıştır.

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

**Problemin büyüklüğü.** Türkiye'de 16-74 yaş grubunda internet kullanım oranı
2026 yılında **%92,3**'e ulaşmıştır; aynı araştırmada en çok kullanılan
uygulamalar WhatsApp (%90,0), YouTube (%77,6) ve Instagram (%71,1) olarak
ölçülmüştür [1]. Bağımsız bir ölçümde Türkiye'deki sosyal medya kullanıcı
kimliği sayısı **62,3 milyon**, yani toplam nüfusun **%70,9**'u olarak
raporlanmaktadır [2]. Bu iki ölçüm farklı tabanlara dayanır — [1] 16-74 yaş
bireyleri, [2] toplam nüfusu esas alır — ve birbirini dışlamaz; ikisi birlikte
okunduğunda Türkçe yazan kullanıcı kütlesinin onlarca milyon ölçeğinde olduğu
görülmektedir.

Bu kütlenin maruz kaldığı zarar da ölçülmüştür. UNFPA Türkiye ve KONDA'nın
3.346 katılımcıyla yürüttüğü saha araştırmasına göre Türkiye'de **her beş
kişiden biri** dijital şiddete maruz kaldığını beyan etmektedir; oran gençlerde
daha yüksektir: 15-17 yaş grubunda her beş gençten biri, **18-32 yaş grubunda
her üç gençten biri** [3]. Türkçe içeriğin kendisi üzerinde yapılan tek
büyük ölçekli akademik ölçüm ise, 36.232 tweetlik bir örneklemde içeriğin
yaklaşık **%19'unun saldırgan dil içerdiğini** göstermektedir [4].

Bu üç sayı birlikte problemin ölçeğini verir: onlarca milyon kullanıcı, beşte
bir oranında maruziyet ve yaklaşık her beş gönderiden biri saldırgan içerik.

**Mevcut çözümler ve yetersizlikleri.**

| Çözüm | Yaklaşım | Bu problemde neden yetersiz |
|---|---|---|
| **Google Jigsaw – Perspective API** | Bulut tabanlı toksisite skoru | Metin sunucuya gider; **Türkçe desteklenen diller arasında değildir** [9]; skor üretir ama **gerekçe ve alternatif üretmez**; **31 Aralık 2026'da hizmete kapanmaktadır** [14] |
| **OpenAI Moderation API** [12] | Bulut tabanlı çok sınıflı sınıflandırma | Aynı mahremiyet sorunu; yayın sonrası kullanım için tasarlanmış; kararlar açıklanabilir değil |
| **Platform içi kelime listeleri** | Yasaklı kelime eşleştirme | Küfürsüz düşmanlığı göremez; Türkçe çekim ve gizleme hilelerinde kırılır; kimlik adlarını yasaklayarak mağduru susturur |
| **Yayın sonrası insan moderasyonu** | Şikâyet → inceleme → kaldırma | Zarar oluştuktan sonra devreye girer; ölçeklenmez; moderatör üzerinde psikolojik yük oluşturur |

Ortak eksiklik nettir: **hepsi yayımlanmış içeriği değerlendirir.** Hiçbiri
yazma anında devreye girmez, hiçbiri kararını kullanıcıya açıklamaz, hiçbiri
alternatif önermez ve hiçbiri metni cihazda tutmaz.

**Maliyet bir ayrışma noktası değildir; süreklilik ve mahremiyet öyledir.**
Bu iki servisin ikisi de bugün ücretsizdir: OpenAI'ın moderasyon uç noktası
resmî dokümantasyonunda "free to use" olarak tanımlanmaktadır [12] ve
Perspective API hiçbir zaman çağrı başına ücretlendirilmemiştir [14]. Rapor bu
nedenle bir maliyet üstünlüğü iddiasında bulunmamaktadır. Buna karşılık iki
yapısal risk ölçülebilir durumdadır. Birincisi süreklilik: Perspective API
kendi duyurusuna göre **31 Aralık 2026'da hizmete kapanmaktadır**; kota artışı
talepleri Şubat 2026'da sona ermiştir ve doğrudan göç desteği verilmeyecektir
[14]. Bir moderasyon yeteneğini üçüncü tarafın ürün yol haritasına bağlamanın
maliyeti, çağrı ücreti değil, servisin kapanmasıdır. İkincisi mahremiyet: her
iki serviste de değerlendirilecek metin kullanıcının cihazından çıkıp üçüncü
taraf sunucusuna gitmek zorundadır. Cihaz üstü çözümlemede bu iki riskin ikisi
de yapısal olarak bulunmamaktadır.

**Çok dilli bulut modellerinin dil önyargısı.** Bu tablodaki ilk iki çözümün
Türkçe için taşıdığı risk, yalnızca kapsam eksikliği değildir. Perspective
API'yi geliştiren ekibin kendi yayını, sistemin desteklediği diller arasında
Türkçe'nin **bulunmadığını** açıkça belirtmektedir [9]. Desteklenen diller
arasında bile başarımın dile göre kaydığı ölçülmüştür: bağımsız bir çalışma,
aynı içeriğin Almanca hâlinin İngilizce çevirisine kıyasla **dört kat daha
fazla** moderasyon kararı ürettiğini göstermektedir [10]. Türkçe'nin eklemeli
yapısı, ünlü uyumu ve yüklem eki davranışı düşünüldüğünde, İngilizce merkezli
bir modelin Türkçe'de aynı kayması yaşamayacağını varsaymak için bir sebep
yoktur. Bu, dile özel ve ölçülebilir bir çözümü zorunlu kılmaktadır.

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
| Karşılaştırma hattı | **Python 3 · scikit-learn** | Yalnızca ölçüm aracı; üründe **çalışmaz** (`ml/`) |
| Sürüm kontrolü | **Git** | `[DEPO BAĞLANTISI]` |

Çekirdek motorun saf Dart olması bilinçli bir mimari karardır: aynı motor
mobil istemcide, komut satırı değerlendirme aracında ve gerekirse sunucu
tarafında **birebir aynı kodla** çalışır. Farklı ortamların farklı karar
vermesi mümkün değildir, çünkü hepsi aynı paketi çağırır. Tablodaki Python hattı bu
kuralın istisnası değildir: ürünün çalışma zamanına dâhil değildir, yalnızca
§3.2'deki denetimli model karşılaştırmasını üretir ve çekirdek paket ona
bağımlı değildir.

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

> ⛔ İÇ NOT — RAPORA GİRMEYECEK. `[DEPO BAĞLANTISI]` alanı, depo açıldıktan
> sonra §3.1 tablosunda ve aşağıdaki paragrafta gerçek URL ile değiştirilecek;
> bu uyarı kutusu Word'e **kopyalanmayacaktır**.

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

**Denetimli model eğitimi ve karşılaştırma.** "Öğrenen bir model daha iyi
sonuç verir miydi?" sorusu bu projede varsayımla değil, **eğitilerek**
yanıtlanmıştır. Aynı etiketli küme üzerinde denetimli bir sınıflandırıcı
eğitilmiş ve kural motoruyla aynı ayrık küme üzerinde ölçülmüştür. Bütün hat
depoda `ml/` dizinindedir ve yeniden çalıştırılabilir.

Protokol, motorunkiyle aynı kuralı izler — model seçimi ayrık kümeye
**bakılmadan** yapılır:

1. **Aday havuzu.** 45 yapılandırma: karakter n-gram, kelime n-gram ve birleşik
   öznitelik uzayları; üç ön işleme varyantı (ham, normalize, aksan katlanmış);
   lojistik regresyon, doğrusal destek vektör makinesi ve naif Bayes.
2. **Seçim.** Yalnızca geliştirme kümesinde (n=256), 5 katlı çapraz doğrulama.
   Sıralama ölçütü F0.5'tir; yanlış pozitif bu üründe daha pahalıdır.
3. **Ölçüm.** Ayrık kümeye (n=80) seçim tamamlandıktan sonra **tek bir kez**
   bakılmış, sonuç düzeltme yapılmadan kaydedilmiştir.

Seçilen model: aksan katlanmış karakter n-gram (2–4) TF-IDF öznitelikleri
üzerinde lojistik regresyon (C=10); çapraz doğrulama F0.5 = %85,7.

| Yaklaşım | Kesinlik | Duyarlılık | F1 | Yanlış pozitif | Yanlış negatif |
|---|---|---|---|---|---|
| Denetimli model | %87,3 | %96,0 | %91,4 | 7 | 2 |
| Kural motoru (bugünkü sürüm) | %98,0 | %100,0 | %99,0 | 1 | 0 |
| Melez — kesişim (VE) | %98,0 | %96,0 | %97,0 | 1 | 2 |
| Melez — birleşim (VEYA) | %87,7 | %100,0 | %93,5 | 7 | 0 |

**Ölçümün asimetrisi açıkça beyan edilmelidir.** Bu küme model için gerçekten
ayrıktır: model yalnızca 256 örneklik geliştirme kümesinde eğitilmiştir ve iki
küme arasında sıfır ortak metin bulunduğu programla doğrulanmıştır. Kural
motoru için ise ayrık **değildir**; motor, ilk ölçümden sonra bu kümenin
gösterdiği üç hata düzeltilerek güncellenmiştir. Motorun dürüst genelleme
sayısı, bu raporun her yerinde olduğu gibi **F1 = %84,2**'dir. Dolayısıyla
%91,4 ile %99,0'ı yan yana koyup "motor kazandı" demek geçersizdir; %91,4 ile
%84,2'yi yan yana koyup "model kazandı" demek de geçersizdir. Simetrik kıyas
ancak ikisinin de görmediği yeni bir küme üzerinde mümkündür ve İP-15 olarak
planlanmıştır.

Asimetriden **etkilenmeyen** iki bulgu vardır ve karar bunlara dayanmaktadır.

*Birincisi:* model, kural motorunun kaçırdığı **hiçbir örneği yakalamamıştır**.
Beklenen kazanç — "öğrenen model, elle yazılmış örüntülerin göremediğini
görür" — bu kümede gerçekleşmemiştir.

*İkincisi:* model, motorun yapmadığı **altı yanlış pozitif** üretmiştir ve
bunların tamamı, ürünün önlemek için var olduğu hata türüdür:

```
"aferin sana, gerçekten hak ettin"      → iltifat, işaretlendi
"senin gibi birini tanımak güzel"       → iltifat, işaretlendi
"seni aptal sanmıyorum"                 → olumsuzlama, işaretlendi
"sana salak diyen haksız"               → mağduru savunuyor, işaretlendi
"hepimiz insanız sonuçta"               → nötr ifade, işaretlendi
"hiçbir işe yaramayan bir uygulama bu"  → nesneye eleştiri, işaretlendi
```

Dilim bazında bakıldığında fark tek bir yerde toplanmaktadır: **bağlam
diliminde özgüllük, modelde %50,0; kural motorunda %83,3**. Model, "salak",
"aptal", "şerefsiz" karakter dizilerinin varlığını öğrenmiş; olumsuzlamanın,
alıntının ve mağdur anlatısının bu dizilerin anlamını tersine çevirdiğini
öğrenememiştir. Nedeni ölçülebilir durumdadır: 256 örnekten 3.864 öznitelik
türetilmektedir, yani örnek başına on beş öznitelik. Bu oranda model, kararı
veren dilbilimsel yapıyı değil, yüzeydeki karakter dizisini ezberlemektedir.

**Bu bulgunun sınırı.** Ölçüm, doğrusal bir taban çizgisinin **bu veri
hacminde** yetersiz kaldığını göstermektedir. Önceden eğitilmiş bir Türkçe dil
modelinin ince ayarının da başarısız olacağını **göstermez** ve rapor böyle bir
iddiada bulunmamaktadır. Nitekim öğrenme eğrisi modelin hâlâ veriye aç
olduğunu ortaya koymaktadır: eğitim kümesi 64 örnekten 256'ya çıkarıldığında
F1 %81,1'den %91,4'e yükselmektedir. Daha büyük ve gerçek bir külliyat sonucu
değiştirebilir; bu, İP-15'in ve gerçek külliyat üzerinde bağımsız ölçüm
planının gerekçesidir.

**Karara etkisi.** Ürünün bugün sevk edilen sınıflandırıcısı deterministik
motor olmaya devam etmektedir; gerekçesi artık bir tercih beyanı değil, bir
ölçüm sonucudur. Kıyas tablosundaki en güçlü satır ise melez kesişimdir
(kesinlik %98,0, F1 %97,0): öğrenen bileşen duyarlılık için, bağlam katmanı
ise kesinlik vetosu olarak kullanıldığında iki yaklaşımın güçlü yanları
birleşmektedir. Yol haritasındaki hedef mimari budur.

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

**Literatürle kıyas.** Türkçe saldırgan dil tespitinde kamuya açık en geniş
akademik referans, 36.232 tweetlik Türkçe külliyattır; bu külliyatta saldırgan
içerik oranı yaklaşık %19'dur ve saldırgan/saldırgan değil ayrımında bildirilen
en iyi başarım **F1 = %77,3**, hedefli/hedefsiz ayrımında %77,9, alt kategori
sınıflandırmasında ise %53,0'tür [4]. Bu projenin ayrık kümede ölçtüğü
**%84,2**, sayısal olarak bu değerin üzerindedir.

Ancak bu iki sayı **doğrudan kıyaslanabilir değildir** ve raporda kıyaslanabilir
gibi sunulmamaktadır. Farklar üç noktadadır: (i) veri kaynağı — [4] gerçek
Twitter akışından örneklenmiştir, bu projenin kümesi sentetik ve tek
etiketleyicilidir; (ii) küme büyüklüğü — 36.232'ye karşı 80; (iii) görev tanımı
— [4] ikili saldırganlık etiketi ölçerken bu proje beş dilimli davranış
sınıflandırması yapmaktadır. Sayı, bir üstünlük iddiası olarak değil,
**büyüklük mertebesinin makul olduğunun** göstergesi olarak verilmektedir:
kural tabanlı bir motorun bu problemde literatürdeki denetimli modellerle aynı
mertebede sonuç üretebildiği görülmektedir. Gerçek külliyat üzerinde bağımsız
ölçüm, §7.1'deki iş paketlerinde planlanmıştır.

**Yöntemin literatürdeki dayanağı.** Ölçümün dilim bazında (açık saldırı,
örtük saldırı, nefret söylemi, bağlam, masum metin) raporlanması, toplam
başarım skorlarının model zayıflıklarını gizlediğini gösteren ve bunun yerine
işlevsel testler öneren çalışmayla aynı yaklaşımdır [7]. Kimlik adlarının
tetikleyici olmaması kararının dayanağı ise, nefret söylemi kümelerinde
korunan grupların dil özelliklerinin toksisiteyle ilişkilendirilmesinin
modelleri o gruplar aleyhine önyargılı hâle getirdiğini gösteren
çalışmalardır [5][6]. Alan taraması, sözcük tabanlı yaklaşımların örtük
saldırganlıkta yetersiz kaldığını da doğrulamaktadır [8]; bu projede o
yetersizlik ölçülmüş ve sayısallaştırılmıştır (yalnız sözlük katmanı örtük
saldırı diliminde %1,8 duyarlılık).

**Planlanan doğrulama (İP-15).** İkinci etiketleyici tarafından, koda ve
mevcut kümelere bakılmadan üretilecek bağımsız bir küme ile yeni genelleme
ölçümü yapılacak; hakemler arası uyum (Cohen's kappa) da bu ölçümle birlikte
raporlanacaktır. Bu çalışma mentörlük penceresine (2–7 Eylül) planlanmıştır ve
bu raporda **henüz yapılmamıştır**. Mevcut %84,2, bu doğrulama tamamlanana
kadar tek geçerli genelleme ölçümüdür.

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

Kararlar, WCAG 2.1 başarı ölçütlerine aşağıdaki gibi eşlenmektedir:

| WCAG 2.1 ölçütü | Seviye | Üründeki karşılığı |
|---|---|---|
| 1.4.1 Rengin Kullanımı | A | Risk seviyesi yalnızca kenarlık rengiyle değil, metin gerekçesiyle de anlatılır |
| 1.1.1 Metin Olmayan İçerik | A | Panel grafiklerinin tamamı `Semantics` etiketi taşır; çubuk yüksekliği tek başına bilgi taşımaz |
| 1.4.3 Kontrast (Asgari) | AA | Metin/zemin kontrastı 4.5:1 eşiğinin altına inmez; marka kırmızısı bu nedenle değiştirilmiştir |
| 1.4.11 Metin Olmayan Kontrast | AA | Kenarlık ve durum göstergeleri 3:1 eşiğini sağlar |
| 2.5.5 Hedef Boyutu | AAA | Dokunma hedefleri 48 × 48 px altına inmez |
| 3.3.1 Hata Tanımlama | A | Uyarı, hangi ifadenin neden işaretlendiğini metin olarak bildirir |
| 3.3.3 Hata Önerisi | AA | Her uyarı, uygulanabilir bir yeniden yazma önerisiyle birlikte gelir |

Bu eşleme bir **tasarım denetimi**dir; ölçüm aletiyle yapılmış bir uygunluk
testi değildir. Kontrast oranlarının araçla ölçülmesi ve ekran okuyucuyla
uçtan uca denetim İP-16'da planlanmıştır. Rapor, tasarım kararı ile ölçülmüş
uygunluk arasındaki farkı kapatmamaktadır.

**Kullanılabilirlik testi protokolü.** Görev tabanlı bir kullanılabilirlik
testi, sesli düşünme (think-aloud) yöntemiyle ve beş katılımcıyla yürütülmek
üzere tanımlanmıştır. Protokolün tamamı — görev metinleri, ölçüm aracı ve kayıt
formu — depoda `docs/10_KULLANILABILIRLIK_TESTI.md` dosyasındadır. Beş görev,
bu bölümde tanımlı A1–A4 akışlarına birebir karşılık gelecek biçimde
kurgulanmıştır:

| # | Görev | Ölçtüğü akış | Kabul ölçütü |
|---|---|---|---|
| G1 | Kızdıran bir gönderiye cevap yaz ve gönder | A1 — müdahale merdiveni | Uyarı fark edilir, gönderim engellenmez |
| G2 | Sana hakaret edildiğini arkadaşına anlat | A3 — mağdur akışı | **Hiçbir uyarı çıkmamalı** |
| G3 | Kendi kimliğinden söz eden bir cümle yaz | Kimlik adı tetikleyici değil | **Hiçbir uyarı çıkmamalı** |
| G4 | Topluluk panelini aç, ne bildiğini anlat | A4 — mahremiyet iletişimi | "Mesajlarımı okumuyor" diyebilmeli |
| G5 | Uyarı aldığın mesajı yine de göndermeyi dene | A1 — engellenmezlik | Gönderebildiğini keşfeder |

Ölçüm aracı, her görev sonrası sorulan tek soruluk SEQ (Single Ease Question,
1–7) ölçeği ile görev tamamlama durumudur. Yöntemin iki kuralı vardır:
katılımcıya ürünün ne yaptığı **anlatılmaz** (yönlendirilmiş bir test, hiç test
yapmamaktan kötüdür) ve katılımcının yazdığı metin **kaydedilmez**; yalnızca
davranış notu ve puan tutulur — ürünün mahremiyet duruşu test yönteminde de
geçerlidir. G2 ve G3 kritik kabul ölçütleridir: bu ikisinde uyarı çıkarsa
ürünün en ayırt edici iddiası gerçek kullanıcıda kırılmış demektir ve sonuç
**olduğu gibi raporlanacaktır**.

Beş katılımcının istatistiksel genelleme sağlamadığı burada açıkça belirtilir;
küçük örneklem kullanılabilirlik sorunlarını **bulmak** için yeterlidir, oran
iddiasında bulunmak için değildir. Oturumun uygulanması ve tam erişilebilirlik
değerlendirmesi (ekran okuyucu denetimi, kontrast ölçümü, dokunma hedefi
denetimi) mentörlük penceresine (2–7 Eylül, İP-16) planlanmıştır; bu raporda
**henüz uygulanmamıştır** ve sonuç bildirilmemektedir.

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

**Sıfır çıkarım maliyeti.** Bu başlık, hazır bulut servislerine karşı bir
fiyat iddiası **değildir**: §2.1'de belirtildiği gibi Perspective API ve OpenAI
moderasyon uç noktası bugün ücretsizdir [12][14]. İddia, platformun kendi
moderasyon yeteneğini işlettiği durumu kapsar. Bir platform, kapanan veya kota
sınırlı bir dış servise bağlı kalmak istemediğinde önündeki seçenek kendi
çıkarım altyapısını kurmaktır ve bu altyapının maliyeti işlenen gönderi
hacmiyle doğru orantılı büyür. Üslup'ta çözümleme kullanıcının cihazında
yapıldığından platformun **marjinal çıkarım maliyeti sıfırdır** ve kullanıcı
sayısıyla artmaz; ölçeklenme maliyeti sunucu kapasitesinden bağımsızdır.

**Moderasyon yükündeki azalmanın büyüklüğü.** Aşağıdaki model, varsayımları
açıkça yazılmış bir duyarlılık hesabıdır; ölçülmüş bir saha sonucu değildir ve
öyle sunulmamaktadır. İki girdisi kaynaklıdır, üçüncüsü ürünün ölçeceği
bilinmeyendir:

- Türkçe sosyal medya içeriğinde saldırgan dil oranı: **%19** [4]
- Motorun ayrık kümede ölçülen duyarlılığı: **%80,0** (raporun her yerinde
  kullanılan dürüst genelleme sayısı)
- Uyarı gören kullanıcının metnini düzeltme oranı: **r** — bilinmemektedir

Yayımlanmayan saldırgan içeriğin, toplam saldırgan içeriğe oranı `0,80 × r`
olur. Bir milyon gönderilik hacim için:

| Düzeltme oranı r | Yayımlanmayan saldırgan içerik | 1 milyon gönderide adet |
|---|---|---|
| %10 | %8,0 | 15.200 |
| %20 | %16,0 | 30.400 |
| %30 | %24,0 | 45.600 |
| %50 | %40,0 | 76.000 |

Modelin değeri tahmininde değil, **r'nin ürünün kendisi tarafından
ölçülebilir olmasındadır.** Topluluk sağlığı katmanının birincil göstergesi
olan düzeltme oranı tam olarak bu r'dir; yani bu tablo, ürün sahaya çıktığı
anda varsayım olmaktan çıkıp ölçüme dönüşen bir hesaptır. Moderasyon
kuyruğuna hiç girmeyen her gönderi, hem moderatör zamanı hem de hedef kişinin
maruz kalmadığı zarar anlamına gelir.

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

**Hedef kitlenin büyüklüğü.** Türkiye'de sosyal medya kullanıcı kimliği sayısı
**62,3 milyon**, yani toplam nüfusun **%70,9**'udur [2]; 16-74 yaş grubunda
internet kullanım oranı **%92,3**'tür ve bu grubun **%90,0**'ı en az bir
mesajlaşma/sosyal medya uygulaması kullanmaktadır [1]. Ürünün birincil hedef
kitlesi bu kütlenin Türkçe yazan kısmıdır ve pratikte tamamına yakınını
kapsamaktadır: müdahale platforma değil, **klavyeye** bağlıdır; kullanıcının
hangi uygulamada yazdığından bağımsız olarak çalışabilecek biçimde
tasarlanmıştır.

İkincil kitlelerin büyüklüğü de ölçülüdür. Dijital şiddete maruz kaldığını
beyan edenlerin oranı Türkiye genelinde beşte bir, 18-32 yaş grubunda ise üçte
birdir [3]; yani "taciz hedefi olan kullanıcılar" başlığı, on milyonlarca
kullanıcılık bir kütlenin en az beşte birine karşılık gelmektedir.

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
216. madde kapsamına girebileceğini belirtir [13]. Bu, cezalandırma değil
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
gözlemin altındaki kategoriler k-anonimlik [11] gereği açılmaz. Böylece topluluk
yönetimi ile bireysel mahremiyet arasındaki geleneksel ödünleşim ortadan kalkar.

**Dijital yaşam kalitesine etkisi.** Ürünün hedeflediği değişim, kaldırılan
içerik sayısı değil, hiç yazılmayan hakaretlerdir. İnsanlar bu cümleleri yüz
yüzeyken kurmaz; ekran arkasında kurar. Kaybolan duraksamanın geri konması,
şartnamenin ilk hedefi olan "dijital ortamda yüz yüze bakar gibi etkileşim"
tanımının doğrudan karşılığıdır. Bunun bireysel karşılığı, kullanıcının
gönderdikten sonra pişman olacağı bir mesajı hiç göndermemesi; toplumsal
karşılığı ise tartışma ortamının, katılmak isteyen ama hedef olmaktan çekinen
kullanıcılar için yaşanabilir kalmasıdır. Bu kitlenin büyüklüğü ölçülüdür:
dijital şiddete maruz kaldığını beyan edenlerin oranı Türkiye genelinde beşte
bir, 18-32 yaş grubunda üçte birdir [3].

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
ihtiyacı büyük ölçüde yabancı bulut servisleriyle karşılanmaktadır; bu, Türkçe
verinin yurt dışına çıkması ve moderasyon yeteneğinin üçüncü tarafın ürün yol
haritasına bağlanması anlamına gelir. İkinci riskin somut örneği bu raporun
yazıldığı sırada gerçekleşmektedir: alanın en yaygın servisi olan Perspective
API **31 Aralık 2026'da kapanmaktadır** [14]. Üslup, çıkarımı cihaza taşıyarak
her iki bağımlılığı da ortadan kaldırır. Bunun üç somut karşılığı vardır:
(i) moderasyon yeteneğinin kapanabilir bir dış servise değil, platformun kendi
dağıttığı istemciye ait olması, (ii) Türkçe metnin yurt dışındaki sunuculara
gönderilmemesi sayesinde veri egemenliği ve KVKK uyumunun kolaylaşması,
(iii) Türkçe doğal dil işleme alanında ülke içinde kalan bir bilgi birikimi ve
yeniden kullanılabilir bir değerlendirme kümesi.

Maliyet yapısı da ayrışmaktadır. Ücretsiz hazır servislerle kıyaslandığında
bir fiyat üstünlüğü iddia edilmemektedir; ancak platform kendi çıkarım
altyapısını işlettiğinde birim maliyet hacimle doğru orantılı artarken, cihaz
üstü mimaride **marjinal maliyet sıfırdır**. Ürünün lisans modeli de bu yapının
üzerine kurulur: gelir aktif kullanıcı bandına göre alınırken hizmet maliyeti
sabit kaldığı için, ölçek büyüdükçe marj genişler.

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
| İP-11 | Denetimli taban çizgisi | 45 aday, çapraz doğrulamayla seçim, ayrık ölçüm, dilim kıyası, öğrenme eğrisi | Tamamlandı |

**Kilometre taşları ve kalan plan**

| Tarih | Kilometre taşı | İçerik |
|---|---|---|
| **20 Ağu 2026** | Ön başvuru | KYS başvurusu tamamlandı |
| **20 Ağu 2026** | İP-12 · Ölçüm doğrulaması | Bütün metriklerin AOT derlenmiş ikili üzerinde yeniden ölçülmesi; 136 test |
| **23 Ağu 2026** | İP-13 · Literatür ve kaynak doğrulaması | Kaynakçadaki 14 künyenin yayıncı sayfasından teyidi; problem büyüklüğü istatistiklerinin resmî kaynaklara bağlanması |
| **24 Ağu 2026, 17.00** | **Teknik rapor teslimi** | KYS yüklemesi |
| 2 Eyl 2026 | Rapor sonuçları | — |
| **2–7 Eyl 2026** | İP-15 · Bağımsız genelleme doğrulaması | İkinci etiketleyici ile yeni ayrık küme; hakemler arası uyum (Cohen's kappa) ölçümü |
| **2–7 Eyl 2026** | İP-14 · Kullanılabilirlik testi | 5 katılımcılı, görev tabanlı oturum; 5 görev, SEQ ölçeği, sesli düşünme (protokol hazır: `docs/10`) |
| **2–7 Eyl 2026** | İP-16 · Tam erişilebilirlik değerlendirmesi | Ekran okuyucu denetimi, kontrast ölçümü, dokunma hedefi denetimi |
| **2–7 Eyl 2026** | İP-17 · Kimlik söz varlığının genişletilmesi | Kapsanmayan grupların eklenmesi, kesinlik regresyon kontrolü |
| **8–13 Eyl 2026** | İP-18 · Sunum ve demo videosu | Final teslimatı hazırlığı |
| **14 Eyl 2026, 17.00** | Final sunumu teslimi | KYS yüklemesi |
| **20 Eyl 2026** | Jüriye canlı sunum | Canlı demo |

**Görsel zaman çizelgesi.** Dolu hücre çalışmanın sürdüğü dönemi, ◆ yarışma
teslim tarihini, ◇ duyuru tarihini gösterir.

| İş paketi | ≤20 Ağu | 23 Ağu | 24 Ağu | 2 Eyl | 2–7 Eyl | 8–13 Eyl | 14 Eyl | 20 Eyl |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| İP-1…İP-10 · Motor, ölçüm, arayüz | ███ | | | | | | | |
| İP-11 · Denetimli taban çizgisi | ███ | | | | | | | |
| İP-12 · Ölçüm doğrulaması | ███ | | | | | | | |
| İP-13 · Literatür ve kaynak doğrulaması | | ███ | | | | | | |
| İP-14 · Kullanılabilirlik testi | | | | | ███ | | | |
| **Teknik rapor teslimi** | | | **◆** | | | | | |
| Rapor sonuçlarının duyurulması | | | | ◇ | | | | |
| İP-15 · Bağımsız genelleme doğrulaması | | | | | ███ | | | |
| İP-16 · Erişilebilirlik değerlendirmesi | | | | | ███ | | | |
| İP-17 · Kimlik söz varlığının genişletilmesi | | | | | ███ | | | |
| İP-18 · Sunum ve demo videosu | | | | | | ███ | | |
| **Final sunumu teslimi** | | | | | | | **◆** | |
| **Jüriye canlı sunum** | | | | | | | | **◆** |

**Planlamanın gerçekçiliği üzerine not.** Yukarıdaki takvim yarışma takvimiyle
(24 Ağustos teslim · 2–7 Eylül mentörlük · 14 Eylül final teslimi · 20 Eylül
canlı sunum) çelişmeyecek biçimde kurulmuştur. Rapor teslimine kadar olan
pencerede yalnızca doğrulama ve derleme işi planlanmıştır; yeni motor
geliştirme planlanmamıştır. Bunun nedeni, ölçülmemiş bir özelliğin rapora
girmesindense hiç girmemesinin tercih edilmesidir. Bağımsız genelleme
doğrulaması (İP-15) rapor teslimine yetiştirilemediği için bilinçli olarak
mentörlük penceresine alınmıştır; §3.2'de bu ölçümün henüz yapılmadığı açıkça
beyan edilmektedir.

---

# 8. TAKIM YAPISI

## 8.1. Takım Organizasyonu ve Roller

Takım **2 kişiden** oluşmaktadır ve şartnamenin "en az 2, en fazla 5 kişi"
şartını karşılamaktadır. Takımın ayrıca **bir danışmanı** bulunmaktadır;
şartname gereği danışman takım üye sayısına dâhil değildir.

| Rol | Sorumluluk alanı | Projeye katkısı |
|---|---|---|
| **Takım Kaptanı — Yazılım Mimarisi ve Mobil Geliştirme** | Sistem tasarımı, çekirdek motor, mobil istemci, sürüm kontrolü | Katmanlı çözümleme mimarisinin kurgusu; `civility_core` paketinin bağımlılıksız (saf Dart) tasarımı; Flutter istemcisi, canlı yazım ekranı ve topluluk sağlığı paneli; bulut kademesinin ölçüm sonrası kaldırılması kararının uygulanması |
| **Doğal Dil İşleme, Veri Bilimi ve Ürün/UX** | Türkçe biçimbilim, örüntü türetme, değerlendirme altyapısı, kullanıcı akışları ve erişilebilirlik | Normalizasyon ve kök eşleştirme; edimbilimsel ve nefret söylemi örüntü aileleri; beş dilimli etiketli kümenin tasarımı; kesinlik/duyarlılık/F1/F0.5 ölçüm altyapısı ve ayrık küme protokolü; müdahale merdiveninin eşik tasarımı; erişilebilirlik kararları |
| **Danışman** *(takım üyesi değildir)* | Akademik ve teknik yönlendirme | Değerlendirme metodolojisinin ve ayrık küme protokolünün gözden geçirilmesi; literatürle hizalama |

**Ekip büyüklüğünün proje ihtiyaçlarına uygunluğu.** İki kişilik yapı, bu
projenin kapsamı için bilinçli bir tercihtir. Ürünün çalışma zamanında sunucu
bileşeni, harici servis bağımlılığı ve eğitilmiş model altyapısı
bulunmamaktadır; dolayısıyla ayrı bir altyapı/DevOps veya ML operasyonları
rolüne ihtiyaç duyulmamıştır. Kapsam, tek bir bağımsız Dart paketi ve onu
tüketen bir Flutter istemcisi olarak sınırlandırılmıştır. Devralınan
mesajlaşma altyapısının kapsam dışı bırakılması da (bkz. §1.2) aynı kararın
parçasıdır: iki kişinin ölçebileceğinden fazlasını vaat etmemek.

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

Değerlendirme esasları gereği takım üyelerinin isim, fotoğraf ve diğer kişisel
bilgilerine bu bölümde yer verilmemiştir.

---

# 9. KAYNAKÇA

> Künyelerin tamamı yayıncı sayfasından teyit edilmiştir. Biçim, şablonun
> tanımladığı iki kalıba göre verilmiştir: **Dijital/Web** kaynaklar
> "Yazar, Başlık, Tarih, Erişim Tarihi, Erişim adresi"; **Akademik** kaynaklar
> "Yazar, (Basım Tarihi) Başlık, Dergi/Konferans, Sayı, Sayfa, DOI".
> Metin içi atıflar köşeli parantezle verilmiştir.

**[1]** Türkiye İstatistik Kurumu (TÜİK), *Hanehalkı Bilişim Teknolojileri (BT)
Kullanım Araştırması, 2026*, 5 Ağustos 2026, Erişim Tarihi: 23 Ağustos 2026,
https://data.tuik.gov.tr/Bulten/Index?p=Hanehalki-Bilisim-Teknolojileri-(BT)-Kullanim-Arastirmasi-2026-58006

**[2]** DataReportal (Kepios), *Digital 2026: Turkey*, 8 Kasım 2025,
Erişim Tarihi: 23 Ağustos 2026,
https://datareportal.com/reports/digital-2026-turkey

**[3]** UNFPA Türkiye ve KONDA Araştırma ve Danışmanlık, *Türkiye'de Dijital
Şiddet Araştırması 2021*, Eylül 2021, Erişim Tarihi: 23 Ağustos 2026,
https://turkiye.unfpa.org/sites/default/files/pub-pdf/digital_violence_report.pdf

**[4]** Çöltekin, Ç., (2020) *A Corpus of Turkish Offensive Language on Social
Media*, Proceedings of the Twelfth Language Resources and Evaluation Conference
(LREC 2020), s. 6174–6184, European Language Resources Association,
https://aclanthology.org/2020.lrec-1.758/

**[5]** Sap, M., Card, D., Gabriel, S., Choi, Y., Smith, N. A., (2019) *The Risk
of Racial Bias in Hate Speech Detection*, Proceedings of the 57th Annual Meeting
of the Association for Computational Linguistics (ACL 2019), s. 1668–1678,
DOI: 10.18653/v1/P19-1163

**[6]** Davidson, T., Bhattacharya, D., Weber, I., (2019) *Racial Bias in Hate
Speech and Abusive Language Detection Datasets*, Proceedings of the Third
Workshop on Abusive Language Online, s. 25–35, DOI: 10.18653/v1/W19-3504

**[7]** Röttger, P., Vidgen, B., Nguyen, D., Waseem, Z., Margetts, H.,
Pierrehumbert, J., (2021) *HateCheck: Functional Tests for Hate Speech Detection
Models*, Proceedings of the 59th Annual Meeting of the Association for
Computational Linguistics and the 11th International Joint Conference on Natural
Language Processing (Cilt 1: Uzun Bildiriler), s. 41–58,
DOI: 10.18653/v1/2021.acl-long.4

**[8]** Schmidt, A., Wiegand, M., (2017) *A Survey on Hate Speech Detection using
Natural Language Processing*, Proceedings of the Fifth International Workshop on
Natural Language Processing for Social Media (SocialNLP), s. 1–10,
DOI: 10.18653/v1/W17-1101

**[9]** Lees, A., Tran, V. Q., Tay, Y., Sorensen, J., Gupta, J., Metzler, D.,
Vasserman, L., (2022) *A New Generation of Perspective API: Efficient
Multilingual Character-level Transformers*, Proceedings of the 28th ACM SIGKDD
Conference on Knowledge Discovery and Data Mining (KDD '22), arXiv:2202.11176,
DOI: 10.48550/arXiv.2202.11176

**[10]** Nogara, G., Pierri, F., Cresci, S., Luceri, L., Törnberg, P.,
Giordano, S., (2024) *Toxic Bias: Perspective API Misreads German as More
Toxic*, arXiv:2312.12651, DOI: 10.48550/arXiv.2312.12651

**[11]** Sweeney, L., (2002) *k-anonymity: A Model for Protecting Privacy*,
International Journal of Uncertainty, Fuzziness and Knowledge-Based Systems,
Cilt 10, Sayı 5, s. 557–570

**[12]** OpenAI, *Moderation — API Documentation (omni-moderation-latest)*
("The moderation endpoint is free to use"), Erişim Tarihi: 23 Ağustos 2026,
https://developers.openai.com/api/docs/guides/moderation

**[13]** T.C. Resmî Gazete, *5237 sayılı Türk Ceza Kanunu, madde 216 — Halkı kin
ve düşmanlığa tahrik veya aşağılama*, 12 Ekim 2004, Sayı 25611,
Erişim Tarihi: 23 Ağustos 2026,
https://www.mevzuat.gov.tr/mevzuatmetin/1.5.5237.pdf

**[14]** Google Jigsaw, *Perspective API — Sunset Announcement*
("Perspective API is sunsetting and service is officially ending after 2026";
"The service will remain active until December 31, 2026"),
Erişim Tarihi: 23 Ağustos 2026, https://www.perspectiveapi.com/

---

## Rapor öncesi son kontrol — 24 Ağustos 2026

> Bu bölüm iç kontrol listesidir; **Word'e kopyalanmayacaktır.**

### Tamamlanan

| # | İş | Durum |
|---|---|---|
| 1 | Problem büyüklüğü istatistikleri (2.1, 4.2) resmî kaynaklarla | ✅ [1][2][3][4] |
| 2 | Kaynakça: 14 künye, yayıncı sayfasından teyitli, şablon formatında | ✅ |
| 3 | Metin içi köşeli parantez atıflar — 14 künyenin tamamı gövdede kullanılıyor | ✅ |
| 4 | Kaynakça numara sırası ([13] → [14]) düzeltildi | ✅ |
| 5 | Perspective API Türkçe iddiası + 31 Aralık 2026 kapanışı | ✅ [9][14] |
| 6 | Yanlış "çağrı başına ücret" iddiasının düzeltilmesi | ✅ [12][14] |
| 7 | Denetimli model eğitimi, ayrık ölçüm ve kural motoruyla kıyas (3.2) | ✅ `ml/` |
| 8 | Literatürle kıyas + kıyaslanabilirlik uyarısı | ✅ [4] |
| 9 | 4.1 verimlilik artışının duyarlılık modeliyle sayısallaştırılması | ✅ |
| 10 | 3.3 WCAG 2.1 başarı ölçütü eşlemesi | ✅ |
| 11 | 7.1 görsel zaman çizelgesi | ✅ |
| 12 | Takım rol tablosu (2 kişi + 1 danışman), isim/fotoğraf yok | ✅ |
| 13 | Gecikme sayısının AOT değerine (193 µs) çekilmesi | ✅ |
| 14 | **Kullanılabilirlik testi**: yapılmamış testin "yürütülmüştür" iddiası kaldırıldı; protokol tablosu eklendi, sonuç bildirilmiyor | ✅ |
| 15 | İP-14 kilometre taşı ve Gantt satırı 2–7 Eylül'e taşındı | ✅ |
| 16 | Görsel yerleşim planı (8 şekil, alt yazılar, kara liste) | ✅ `docs/11` |

### Bugün yapılacak — sıraya göre

| Sıra | İş | Puan etkisi | Süre |
|---|---|---|---|
| **1** | **GitHub deposu aç + push** → `[DEPO BAĞLANTISI]` iki yerde doldurulacak (§3.1 tablosu ve §3.1 metni) | **2 puan** + tüm teknik iddiaların doğrulanabilirliği | 15 dk |
| **2** | Şablonun **son iki sayfasını sil** ("PUANLAMA VE DEĞERLENDİRME ESASLARI" ve "RAPOR ŞABLONU İLE İLGİLİ NOT") — ikisinde de "Bu sayfaya raporlarda yer verilmeyecektir" yazıyor | Eleme riski | 2 dk |
| **3** | Şablonun **talimat paragraflarını sil** ("…net bir dille ifade edilir" tarzı) — onlar talimat, içerik değil | Eleme riski | 10 dk |
| **4** | Bu dosyadaki **⛔ ve ⚠️ kutularını, başlık bloğunu ve bu kontrol listesini kopyalama** | Kritik | — |
| **5** | Kapak: `[TAKIM ID]` + `[BAŞVURU ID]` KYS'den | Format | 5 dk |
| **6** | 8 şekli yerleştir (`docs/11_GORSEL_PLANI.md`) — telefon numarası sansürü, mesajlaşma ekranları hariç | **3–4 puan** (3.3) | 60 dk |
| **7** | Biçim: Arial 12 / başlık Arial Black 14 / 1.15 / iki yana yaslı / 2,5 cm | Eleme riski | 15 dk |
| **8** | İçindekiler sayfa numaralarını güncelle (Word: Başvurular → İçindekiler tablosunu güncelle) | Format | 5 dk |
| **9** | **Sayfa sayısını kontrol et — sınır 30.** Metin ~22–25 sayfa + 8 şekil ≈ 27–28 | Eleme riski | 5 dk |
| **10** | PDF/DOCX olarak KYS'ye yükle — **son saati bekleme** | — | 10 dk |

### Yapılırsa artı puan (opsiyonel, süre varsa)

| İş | Puan | Süre |
|---|---|---|
| Kullanılabilirlik testini bugün gerçekten uygula (5 kişi × 15 dk), sonucu §3.3'e yaz | **+1 puan** ve jüri sunumunda güçlü malzeme | ~90 dk |
