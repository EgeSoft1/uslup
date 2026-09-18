# 23 · Kod Denetimi — 13 Eylül 2026

Depodaki bütün kaynak dosyalar (çekirdek motor, Flutter istemcisi, Android
klavye servisi, ML betikleri, kök dizindeki yardımcı betikler) tek tek okundu.
Her şüpheli davranış **gerçek motor üzerinde bir deneme cümlesiyle doğrulandıktan
sonra** düzeltildi; doğrulanamayan şüpheler geliştirme listesine (docs/24)
bırakıldı.

Bu belge, projenin ölçüm disiplinine uygun olarak düzeltmelerin **neyi
değiştirdiğini sayıyla** kaydeder.

---

## 1. Başlangıç durumu

| Denetim | Sonuç |
|---|---|
| `dart analyze` (civility_core) | temiz |
| `dart test` (civility_core) | 326/326 |
| `flutter analyze` (mobile) | temiz |
| `flutter test` (mobile) | 43/43 |

Testlerin hepsi yeşildi. Aşağıdaki hataların hiçbiri mevcut testlerde ya da
etiketli kümelerde görünmüyordu — bulunmalarının tek yolu kaynağı okumaktı.

---

## 2. Güvenlik

### G1 · Düz metin root şifresi — `deploy_to_vds.py`, `vds_monitor.py`

İki betikte bir VDS sunucusunun IP adresi, `root` kullanıcısı ve şifresi düz
metin olarak yazılıydı; sunucu anahtarı hiç doğrulanmıyordu
(`paramiko.AutoAddPolicy`).

- Git geçmişi tarandı: iki dosya **hiçbir commit'e girmemiş** (`.gitignore`
  içinde). Depo herkese açık olduğu için bu önemlidir.
- Kimlik bilgisi ortam değişkenine taşındı (`VDS_HOST`, `VDS_USER`,
  `VDS_KEY_FILE` ya da `VDS_PASSWORD`); sunucu anahtarı `known_hosts` ile
  doğrulanıyor (`RejectPolicy`).
- **Yapılması gereken (kodla çözülemez):** şifre bir dosyada açık durduğu için
  değiştirilmiş sayılmalı; sunucuda şifreli root girişi kapatılıp yalnızca SSH
  anahtarına izin verilmeli.
- `vds_monitor.py` günlük satırlarını "Edge AI Modeli İndiriliyor",
  "Federated Sync" diye süslüyordu; ürün bunların hiçbirini yapmaz. Satırlar
  artık olduğu gibi basılıyor.

---

## 3. Motor — kesinlik ve kaçış hataları

Her satır, düzeltmeden önce motorda çalıştırılan cümlenin **gerçek** çıktısıdır.

### D9 · Bağlam ve nefret yapısı

| # | Cümle | Önce | Sonra | Kök neden |
|---|---|---|---|---|
| D9.1 | `Ali'ye söyle sen şerefsizsin Veli'ye de` | **Temiz** | Yüksek risk | Kesme işareti (`'`) tırnak sayılıyordu; iki özel ad arası "alıntı" oluyordu |
| D9.2 | `ali@ornek.com adresine köpek fotoğrafı attım` | **Yüksek risk** | Temiz | Metinde herhangi bir `@` "kullanıcı etiketi" sayılıyordu |
| D9.3 | `gerizekalılar` · `sürtükler` · `siz zavallılarsınız` | **Temiz** | Yakalanıyor | Ünlü uyumu aksanı katlanmış kökten okunuyordu (`ı→i` ince, `ü→u` kalın sanılıyordu) |
| D9.4 | `Kadınlar tuvaleti çok kirli` · `Engelliler rampası bozuk` | **Yüksek risk · nefret** | Temiz | Kimlik adı tamlamada NİTELEYİCİ iken grubun kendisi yüklemin öznesi sayılıyordu |
| D9.5 | `sen zaten Uygursun` · `siz Hindusunuz` | **Temiz** | Yakalanıyor | Örüntüde `sin\|siniz\|siniz` yazım hatası — yuvarlak ünlülü çekim yoktu |

D9.4'ün denetimi yalnızca **yalın çoğul** kimlikte ve kimliğin hemen ardındaki
iki kelimede çalışır. İlk sürüm daha genişti ve üç yanmış kümede üç saldırıyı
kaçırttı (`bu Romanlarla aynı mahallede yaşanmaz`); ölçümle görüldü, daraltıldı.

### D10 · Kendine zarar ifadesi tehdit sayılıyordu

| Cümle | Önce | Sonra |
|---|---|---|
| `Kendimi öldüreceğim` | **Yüksek risk · tehdit** — gönderimde "TCK kapsamında suç oluşturabilir" onayı | Temiz · destek kartı |
| `intihar etmek istiyorum` | Temiz, destek kartı YOK | Temiz · destek kartı |
| `Seni ve kendimi öldüreceğim` | Yüksek risk | Yüksek risk + destek kartı (başkası da nesne) |

docs/20 D4 kendine zarar ifadelerini destek sinyaline çevirmişti ama yalnızca
iki kuruluşu görüyordu; en açık ifade sözlükteki tehdit fiiline düşüyordu.

### D11 · Gündelik metinde yanlış alarm

| Cümle | Önce | Kaynak |
|---|---|---|
| `Diş hekimi çürük dişini söktü` | **Yüksek risk · tehdit** | `deyim.disini_sokmek` — geçmiş zaman |
| `Banka müdürüne kredi kartı hesabını sordum` | Riskli · tehdit | `tehdit.hesabini_sorarim` |
| `Annem torununun düğün gününü gördü` | Riskli · tehdit | `tehdit.gununu_goreceksin` |
| `Çorbaya ekmek doğradım` | Riskli · tehdit | `deyim.kanina_ekmek` — "kan" şartı yoktu |
| `Ciltte kaşınma ve kızarıklık var` | Riskli · tehdit | `deyim.kasiniyorsun` — ad biçimi |
| `Barajlardaki su normal seviyesine indi` | Riskli | `kucumseme.seviye` |
| `Vücudun ihtiyacı olan vitaminleri almalısın` | Riskli · taciz | sözlük `vücudun` — kendi eki yönelim sayılıyordu |
| `Sana yatağa gitmeden önce yazarım` | Riskli · taciz | sözlük `yatağa` |
| `Yeni maskaramı denedim` | Riskli | `deyim.maskara_oldun` — makyaj malzemesi |
| `Anadolu kuzu tandır yedik` | Riskli | `deyim.anasinin_kuzusu` — "ana"+"dolu" |
| `Tırnağı olmayan kediler` | Riskli | `deyim.tirnagi_olamazsin` — ortaç |
| `Bu güzelliği anlatmaya kelime yetmez` | Riskli | `deyim.kalem_yetmez` — içten övgü (D5 ilkesi) |
| `Kırk yılda bir yemek yaptık` | Riskli | `deyim.kirk_yilda_bir` — birinci şahıs |
| `iki liralık adam` | Temiz (**kaçış**) | `liralık` almaşığı normalize metinde asla eşleşemezdi |

Her örüntü, etiketli kümelerdeki saldırgan örneklerini koruyacak biçimde
daraltıldı (`hesabını sorarım`, `gününü görürsün`, `seviyene inmeyeceğim`,
`sen benim tırnağım bile olamazsın`, `seni anlatmaya kalem yetmez` hâlâ
yakalanıyor).

### D12 · Kapı kelimesi ve kimlik tutarlılığı

Deyim katmanında `gateWord`, örüntünün BÜTÜN almaşıklarında geçmek zorundadır;
geçmezse o dal hiçbir cümlede denenmez (sessiz kaçak). Altı örüntüde tutmuyordu:

| Örüntü | Kapı | Hiç çalışmayan dal |
|---|---|---|
| `bu_kafayla_varamazsin` | `kafayla` | "bu akılla", "bu zihniyetle", "bu kafanla" |
| `sana_mi_soracagiz` | `soracag` | "sana mı danışacağız" |
| `haddini_bildiririm` | `bildirir` | "haddini bildireceğim" |
| `ne_buyuk_basari` | `buyuk basari` | "ne büyük iş", "ne muhteşem marifet" |
| `disini_sokmek` | `disini` | "dişlerini" |
| `attigin_tas_kurbaga` | `kurbaga` | "attığın taş" |

Ayrıca `bu_kafayla` kalıbı yalnızca `-la` ekini alıyordu: "zihniyet**le**" kapı
düzeltilse bile eşleşmezdi (yeni regresyon testi yakaladı).

Açılması övgüyü işaretleyecek dallar (`ne büyük iş başardın`, `sana mı sorayım`)
açılmadı; ölçülen davranış korunarak kalıp kapıyla hizalandı. İki örüntü
kimliği yineleniyordu (`yoksayma.bos_yapma`, `karakter.adam_olmaz`);
benzersizleştirildi ve bir yapısal testle kilitlendi.

---

## 4. Ölçüm — düzeltmeler neyi değiştirdi

`dart run bin/evaluate.dart --hepsi`, düzeltmelerden önce ve sonra, satır satır
karşılaştırıldı (süre satırları hariç).

| Küme | Değişen örnek | Sonuç |
|---|---|---|
| Geliştirme · 1. ayrık · İP-15 · İP-20 · İP-22 · İP-27 | **0** | birebir aynı |
| İP-30 gündelik (120 masum) | **0** | 120/120 temiz |
| İP-31 yönelim · İP-32 savunma dili | **0** | birebir aynı |
| **İP-29 (geçerli ayrık küme)** | **1** | tek yanlış pozitif temizlendi |

İP-29'daki değişim:

| | İkinci geçiş (D7) | Üçüncü geçiş (D9) |
|---|---|---|
| Kesinlik | %96,2 | **%100,0** |
| Duyarlılık | %41,7 | %41,7 |
| F1 | %58,1 | %58,8 |
| F0.5 | %76,2 | **%78,1** |
| Masum dilim | 29/30 | **30/30** |

Temizlenen cümle: `Selin'e "senin gibilerden bu beklenirdi" demişler, çok ayıp`.
Sebep D9.1'dir: "Selin'e"deki kesme işareti bir tırnak açıyor, cümledeki gerçek
çift tırnaklar yanlış eşleşiyor ve alıntı görülmüyordu.

**Kör olma durumu.** D9.1 bu cümleye bakılarak değil, `context_analyzer.dart`
okunurken ve "Ali'ye söyle sen şerefsizsin Veli'ye de" kaçışı denenirken
bulundu. Ancak bu yanlış pozitif README'nin "Bilinen sınırlar" bölümünde
önceden yazılıydı; düzeltmeyi yapan kişi onu biliyordu. Sayı bu yüzden
**yarı-kör** kabul edilmelidir. İlk geçiş (%96,4 · %45,0) raporlanan
genelleme sayısı olmaya devam eder.

---

## 5. İstemci ve araçlar

| # | Dosya | Hata | Düzeltme |
|---|---|---|---|
| M1 | `civility_composer.dart` | İmleç/seçim değişince motor yeniden çalışıyor, hazır öneri silinip yeniden isteniyordu (kart titremesi) | Yalnızca metin değişince çözümle |
| M2 | `civility_composer.dart` | Öneri üretimi hata verirse bekleme kartı sonsuza dek dönüyordu | `onError` ile kart kapanır |
| M3 | `civility_text_controller.dart` | Aralık aynı, şiddet farklıyken işaretleme rengi güncellenmiyordu | Şiddet de karşılaştırılır |
| M4 | `main.dart` | Klavye kanalı ONNX kurulumu BEKLENDİKTEN sonra bağlanıyordu; ilk tuş vuruşları düşüyordu | Kanal önce bağlanır |
| M5 | `CivilityInputMethodService.kt` | Eşzamansız eski sonuç şeride düşüyor; dokununca alanın TAMAMI eski metnin önerisiyle değişiyor, yeni yazılanlar **siliniyordu** | `sourceText` ile eski sonuç yok sayılır |
| M6 | `CivilityInputMethodService.kt` | Büyük harf kipinde `i → I` (Türkçede `İ`) | Türkçe büyük harf |
| M7 | `mobile/assets/models/` | Model `.gitignore`'da; taze klonda dizin yok ve `pubspec.yaml` varlık dizini bulunamadığı için derleme **kırılıyordu** | `.gitkeep` |
| M8 | `tool/sunum_sunucusu.dart` | Bozuk yüzde-kodlaması ya da sekme kapatma sunucuyu **sunum ortasında** kapatıyordu | İstek başına hata yakalama |

## 6. ML tekrarlanabilirliği

- Artırma betikleri (`augment_*.py`, `add_threats.py`,
  `generate_massive_dataset.py`) şablon cümleleri doğrudan protokolün n=256'lık
  **geliştirme kümesine** yazıyordu: yerel `veri.json` ~10 bin satıra
  şişmişti, README'deki model ölçümleri yeniden üretilemiyordu ve ayrık küme
  metinlerinin eğitime sızması engellenmiyordu. Artırmalar artık ayrı bir
  `augmented` anahtarına, ayrık kümeye karşı ayıklanarak yazılıyor
  (`ml/veri_deposu.py`); `02_egit_ve_olc.py` geliştirme kümesi 256 değilse
  çalışmayı reddediyor.
- `export_onnx.py` açıkça `dev + augmented` ile eğitiyor ve uygulamadaki ONNX
  modelinin README'de ölçülen karakter n-gram modeli **olmadığını** yazıyor.
- `expand_dart_lexicon.py` sözlüğe 8.000 ölçümsüz girdi (`malın`, `itin`,
  `hayvanlar`…) ekleyebiliyordu; devre dışı bırakıldı.

**Yapılması gereken:** yerel `veri.json` kirli durumda. `python ml/01_veri_cikar.py`
ile yeniden üretilmeli, ardından istenirse artırma betikleri ve `export_onnx.py`
yeniden çalıştırılmalı.

---

## 7. Son durum

| Denetim | Sonuç |
|---|---|
| `dart analyze` (civility_core) | temiz |
| `dart test` (civility_core) | **406/406** (denetim regresyonları: `test/denetim_d9_d12_test.dart`) |
| `flutter analyze` (mobile) | temiz |
| `flutter test` (mobile) | **56/56** (öneri deneyimi ve ölçüm tutarlılığı testleri dâhil) |
| `flutter build apk --debug` | başarılı (Kotlin klavye servisi değişiklikleri derleniyor) |

Denetimden sonra uygulanan geliştirmeler `docs/24_GELISTIRME_LISTESI.md` sonundaki
kayıttadır.
