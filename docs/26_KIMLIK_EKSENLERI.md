# Kimlik Eksenleri — Cinsiyet, Yaş, Engellilik, Göç

**Tarih:** 15 Eylül 2026 · **Durum:** ÖLÇÜM ÖNCESİ KAYIT + İKİ AYRIK GEÇİŞ.
İP-33 düzeltmeden önce yazıldı; İP-34 birinci turdan, İP-35 ikinci turdan
sonra yazıldı ve birer kez ölçüldü. **Geçerli sayı İP-35'tir.**
**Önceki tur:** docs/25 (küfür kapsamı)

## 1. Bulgu

README'nin "Bilinen sınırlar" bölümü açıkça yazıyordu: *cinsiyet, yaş,
engellilik ve göç statüsü hedefli genellemeler yakalanmıyor.* Kimlik söz
varlığı bu grupları (kadınlar, yaşlılar, engelliler, göçmenler…) zaten
kapsıyordu; eksik olan **yüklemdi**. Nefret katmanının yüklemleri etnik ve inanç
eksenindeki düşmanlık için yazılmıştı — "hırsız", "hain", "defolsun". Bu dört
eksendeki düşmanlık çoğunlukla başka bir kılıkta gelir: grubun neyi
yapabileceğini ve hangi haklara sahip olduğunu reddeder.

Sunumda "dört eksen kapsanıyor" demeden önce ölçüldü.

## 2. İP-33 · düzeltme öncesi kayıt

`lib/src/eval/identity_axes_dataset.dart` — 64 cümle, eksen başına 8 saldırı
ve 8 masum. Masum parça aynı fiilleri taşır: durum bildiren engeller ("rampa
bozuk olduğu için binemiyor"), kamu uyarıları ("yaşlılar öğle saatlerinde
dışarı çıkmasın"), iş hukuku ("doğum sonrası ağır işte çalışmamalı"),
önyargıyı çürüten cümleler ve politika eleştirisi. Motor yazım sırasında
çalıştırılmadı; yazan kişi örüntü kataloğunu bildiği için küme **kör değildir**.

| İP-33 · önce | Sonuç |
|---|---|
| Saldırı (32) | **0 / 32** yakalandı — dört eksenin dördünde de %0 |
| Masum (32) | 31 / 32 temiz |
| Tek yanlış alarm | `Mülteciler ülkelerine dönmek istiyor ama savaş hâlâ bitmedi` · Yüksek risk (dışlama) |

## 3. Birinci tur — değişiklikler

**E0 · İki ölü kimlik terimi.** Normalleştirici `q → k`, `w → v` çevirir.
`queer` ve `down sendromlu` terimleri hiçbir normalize metinde geçemezdi;
İP-17'den beri (24 Ağustos) hiçbir cümlede eşleşmediler ve hiçbir test bunu
görmedi. **Değişiklik:** `kueer`, `dovn sendromlu`; yeni test bütün örüntü
kaynaklarında q/w/x harfini yapısal olarak yasaklar.

**E1 · Tamlama denetimi sıfatı iyelik eki sanıyordu.** D9 kuralı ("Kadınlar
tuvaleti kirli" → tamlama) `Yaşlılar YENİ bir şey öğrenemez` cümlesinde "yeni"
kelimesini `-(s)I` iyelikli bir tamlama başı sandı ve saldırıyı eledi.
**Değişiklik:** iyelik ekine benzeyen sıfat ve zarflar (`yeni`, `eski`,
`doğru`, `farklı`, `kendi`, `böyle` …) dışarıda.

**E2 · Yeni kuruluşlar** (`hate_patterns.dart`, İP-33 bölümü). Hepsi kimlik
yuvasını yüklemden önce ister; hiçbirinde kimlik adı tek başına tetikleyici
değildir.

| Kuruluş | Örnek | Şiddet |
|---|---|:--:|
| Yetersizlik atfı (geniş zaman) | `Kadınlar siyasetten anlamaz` | 0,62 |
| İşe yaramazlık · katkı reddi | `Engelliler hiçbir işe yaramaz` | 0,82 |
| Tekil genelleme (çıkma hâli) | `Kadından mühendis olmaz` | 0,66 |
| Hak reddi (gereklilik/istek) | `Engelliler evden çıkmamalı` | 0,80 |
| Yer biçme | `Kadınların yeri evidir` | 0,74 |
| Suç / istila / asalaklık atfı | `Göçmenler işimizi çalıyor` | 0,84 |
| Maliyet söylemi | `Sağırlarla uğraşmak zaman kaybı` | 0,78 |
| İnsan değil | `Otistikler normal insan değildir` | 0,90 |
| Nedensel suçlama | `Göçmenler geldi geleli huzur kalmadı` | 0,74 |

İki yeni aile kullanıcıya ayrı gerekçe gösterir: **Kalıp yargı** ("Bir grubun
bütün üyelerine yetersizlik yüklüyor…") ve **Hak reddi** ("…kamusal hayata
katılma hakkını kim olduklarına göre kısıtlıyor").

**E3 · Susturmama mekanizmaları.** Kuruluşların kendisi kadar önemli:

1. **Şimdiki zaman alınmaz.** `beceremez` bir hükümdür, `yürüyemiyor` bir
   durumdur. Genel fiiller (`yapamaz`, `kullanamaz`) yalnızca nesnesi bir beceri
   adıysa alınır — "engelliler bu binaya giremez, asansör yok" bir
   erişilebilirlik şikâyetidir.
2. **İlgeç tümleci.** `Engelliler İÇİN yapılan rampa hiçbir işe yaramıyor` —
   yaramayan rampadır. Kimlik adının ardından ilgeç (`için`, `yönelik`,
   `hakkında`…) ya da `değil` geliyorsa grup yüklemin öznesi sayılmaz.
3. **Koşul tümleci** (`ImplicitPattern.suppressedBy`, yeni alan). Kısıtlama
   cümlesi bir kamu uyarısı olabilir: `Kar yağışı NEDENİYLE engelliler zorunlu
   OLMADIKÇA evden çıkmamalı`. Koşul, gerekçe ve mevzuat tümleci metnin
   herhangi bir yerindeyse hak reddi ve yetersizlik kuruluşları bulgu üretmez.
   `-dıktan sonra` kasıtlı olarak listede yok: `kadınlar evlendikten sonra
   çalışmamalı` bir uyarı değil, hak reddidir.
4. **Anma.** Yüklemin hemen ardından aktarma fiili (`diye`, `diyen`), soru
   edatı, inanç fiili (`sanıyorlardı`) ya da yargıyı ad olarak anan kelime
   (`önyargısı`, `söylemi`, `gibi cümleler`) geliyorsa cümle o yargıyı kurmuyor,
   anıyordur.
5. **Politika görüşü nefret değildir.** Vatandaşlık, çalışma izni, oy hakkı gibi
   vatandaşlığa bağlı haklar göç statüsündeki gruplar için bir politika
   tartışmasıdır (IdentityTerms K1): `Sığınmacılar oy kullanmamalı` temiz,
   `Yaşlıların oy hakkı alınmalı` hak reddi. `Mültecilere hiçbir hak
   tanınmamalı` ise politika değil, insan haklarının reddidir.
6. **"Ülkelerine dön" düzeltmesi.** Kalıp mastarı da alıyordu; grubun kendi
   isteği bir çağrı değildir. Yalnızca istek, gereklilik ve ettirgen biçimler
   alınır; olumsuzlanmış gereklilik ("dönmek zorunda kalmamalı") alınmaz.

## 4. Birinci tur sonucu ve ek tarama

| Küme | Önce | Sonra |
|---|---|---|
| İP-33 saldırı | 0 / 32 | **31 / 32** |
| İP-33 masum | 31 / 32 | **32 / 32** |
| Ek tarama · 25 saldırı varyantı | — | 25 / 25 |
| Ek tarama · 60 masum | — | 3 yanlış alarm → **0** |

Ek tarama (kümede olmayan 85 cümle) üç yanlış alarm buldu: `Kızdan şoför
olmaz sanıyorlardı`, `Mülteciler ülkelerine dönmek zorunda kalmamalı`,
`Göçmenler kanını emiyor gibi cümleler nefret söylemidir`. Üçü de 3. bölümdeki
anma ilkesinin eksik kalmış hâliydi ve düzeltildi. Kalan tek İP-33 kaçağı
bilinçlidir: `Engelli çalıştırmak şirkete zarar` — "zarar" alınmadı, çünkü
`Göçmenleri sigortasız çalıştırmak devlete zarar` bir hak savunusudur ve aynı
kalıpla yazılır.

## 5. İP-34 · birinci ayrık geçiş

`identity_axes_blind_dataset.dart` — 40 cümle, birinci tur bittikten sonra
yazıldı, bir kez ölçüldü. Saldırı parçasına kuruluşların bilerek kapsamadığı
biçimler de yazıldı.

| İP-34 · ilk geçiş | Değer |
|---|---|
| Kesinlik | **%100,0** |
| Duyarlılık | **%15,0** (3 / 20) |
| Masum | **20 / 20** temiz |

Yeni kuruluşlar yanlış alarm üretmedi ama hiç görülmemiş ifadelerin çoğunu
kaçırdı.

## 6. İkinci tur — İP-34'ün hata sınıfları (İP-34 YANDI)

İP-34'ün 17 kaçağı cümle cümle değil, sınıf sınıf onarıldı. Bu, kümeyi yaktı.

| Sınıf | Örnek kaçak | Genel çözüm |
|---|---|---|
| E1 yuva dışı ad | `Emekliler bir işe yaramaz` | `emekliler`, `ihtiyarlar`, `yaşlı insanlar`, `sakatlar`, `özürlüler`, `kadın milleti` |
| E2 yetkinlik fiilinin şimdiki zamanı | `beceremiyor` | yalnızca `becer-` şimdiki zamanda da alınır |
| E3 beceri nesneli genel fiil | `liderlik yapamaz` · `para yönetmeyi bilmez` | `-lIk yapamaz`, `-mAyI bilmez`, `uyum sağlayamaz` |
| E4 retorik soru | `Kadınların futbolla ne işi var` | `ne işi var/olur` kuruluşu |
| E5 istek kipli yer biçme | `evde otursunlar` · `ortalıkta dolaşmasın` | koşul tümeci denetimli istek kuruluşu |
| E6 hak nesnesi | `ehliyet verilmemeli` · `oy hakları alınmalı` | belge listesi; oy hakkı göç statüsü dışında |
| E7 katkı reddi | `topluma bir şey katmaz` | işe yaramazlık kuruluşuna eklendi |
| E8 dilek eğretilemesi | `ölüp gitse` | varlık reddi fiillerine eklendi |
| E9 suç/istila biçimleri | `istila etti` · `akın ediyor` · `hepsi suçlu` | geçmiş zaman, "akın", "sırtında yaşıyor", `suçlu` |

Sonuç: İP-34 19/20 · 20/20 — **yanmış sayıdır, genelleme değildir.**

**Diğer kümelere etkisi** (iki tur birlikte, `evaluate --hepsi` farkı):

- **İP-29 (geçerli genelleme kümesi):** duyarlılık **%43,3 → %45,0**, F0.5
  %79,3 → %80,4, kesinlik %100 korundu. Değişen tek örnek `engelliler evde
  otursun` (üçüncü parça, 9/30 → 10/30) — E5 onarımı İP-34'ün sınıfından geldi,
  İP-29'a bakılmadı. İP-29'un kaçak listesi README'de yazılı olduğu için bu
  sayı **yarı-kör** kabul edilmelidir.
- **İP-27 (yanmış):** `bu Suriyeliler yüzünden mahallede huzur kalmadı` —
  kümede "TAVAN" notuyla duran örnek artık yakalanıyor (nedensel suçlama).
- Geliştirme, ilk ayrık, İP-15, İP-20, İP-22, İP-30 (gündelik · 0 yanlış alarm),
  İP-31, İP-32: **tek bir örnek değişmedi.**

## 7. İP-35 · ikinci ayrık geçiş — GEÇERLİ SAYI

`identity_axes_blind2_dataset.dart` — 40 cümle, ikinci tur bittikten sonra
yazıldı, bir kez ölçüldü. **Motor bu kümeye bakılarak değiştirilmedi.**

| İP-35 · tek geçiş | Değer |
|---|---|
| Kesinlik | **%100,0** |
| Duyarlılık | **%15,0** (3 / 20) |
| Özgüllük | **%100,0** (20 / 20) |
| F0.5 | %46,9 |

Kaçanlar: `Kadınlar mantıklı düşünemez` · `yine sollamayı beceremedi` (geçmiş
zaman, tekil ad) · `hepsi hayvan` · `Kızların mühendislikte işi yok` ·
`ehliyetleri alınmalı` · `Bu moruklar yüzünden ülke batıyor` · `vergimizi
yiyor` · `fikri sorulmamalı` · `kimseye faydası olmaz` · `vaktini çalıyor` ·
`işe alınmamalı, iletişim kuramazlar` · `kısırlaştırılmalı` · `Tekerlekli
sandalyeli biri bu işi asla yapamaz` · `sokaklar güvensiz` · `hepsini gönderin`
· `bu ülkeye yük, bir an önce gitsinler` · `tehdit oluşturuyor`.

## 8. Ne söylenebilir, ne söylenemez

**Söylenebilir:**
- Dört eksende de yazılmış kuruluşlar çalışıyor ve **iki ayrık kümede de bu
  gruplardan söz eden 40 masum cümlenin 40'ı temiz kaldı** (İP-34 ilk geçiş +
  İP-35). Ek taramanın 60 masum cümlesiyle birlikte 132 masum cümlede sıfır
  yanlış alarm; bunların 60'ı geliştirme verisidir.
- Çalışma iki gerçek hatayı ortaya çıkardı: iki ölü kimlik terimi ve sıfatı
  iyelik sanan tamlama denetimi.
- İP-29 yarı-kör olarak %45,0'e çıktı.

**Söylenemez:**
- "Cinsiyet, yaş, engellilik ve göç hedefli nefret söylemini yakalıyor."
  **Hiç görülmemiş ifadelerde duyarlılık %15'tir** ve iki ayrık kümede aynı
  çıktı. Bu eksenlerdeki düşmanlığın yüzey çeşitliliği — geçmiş zaman, tekil
  genel ad, eğretileme, iki cümlecikli yapı — kuruluş listesiyle kapsanamıyor.

**Sonuç:** Kural katmanı bu eksende **kesinlik bekçisi** olarak iş görüyor,
duyarlılık kaynağı olarak görmüyor. Duyarlılık için anlam düzeyinde bir model
gerekiyor — ikinci görüş modeli (DistilBERTurk) planı bu ölçümle gerekçelidir.
Model yalnızca bilgi verir; kararı değiştirmez (docs/24 · 22).

## 9. Sayılar

| | Önce | Sonra |
|---|---|---|
| Nefret kuruluşu | 17 | **29** |
| Kimlik terimi | 98 (2'si ölü) | **104** |
| Örtük katman toplamı (örüntü + deyim + kuruluş) | 202 | **214** |
| Etiketli küme · örnek | 10 · 971 | **13 · 1.115** |
| Çekirdek test | 592 | **667** |
