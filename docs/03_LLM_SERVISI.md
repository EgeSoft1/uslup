# LLM Yeniden Yazma Servisi — Karar Kaydı

**Durum:** ❌ **Kaldırıldı (3 Ağustos 2026)** · **Önceki durum:** Çalışıyordu
**Kaldırılan kod:** `server/` — git geçmişinde `e98882b` öncesinde

> Bu belge bir mimari karar kaydıdır. Servis yazıldı, ölçüldü ve **kasıtlı
> olarak kaldırıldı.** Teknik raporda "neden bulut kullanmıyoruz" sorusunun
> cevabı budur; bir eksiklik değil, bir tasarım kararıdır.

---

## 1. Ne yapılmıştı

Cihaz üstü nezaket motorunun üçüncü kademesi olarak, kullanıcı "daha akıcı
bir alternatif" istediğinde devreye giren bir sunucu tarafı servis yazıldı:

```
kullanıcı metni ──► civility_core ──► LLM ──► civility_core ──► kullanıcı
                    (ölç: 0.87)              (DOĞRULA)
                                                  │
                                          geçemeyen ✗ atılır
```

Servis Dart ile yazılmıştı ve nezaket motorunun **aynı kopyasını** çalıştırıyordu:
modelin ürettiği her öneri, kullanıcıya ulaşmadan önce mobil uygulamadakiyle
birebir aynı sınıflandırıcıdan geçiyordu. Dört ret gerekçesi vardı: boş çıktı,
değişmemiş metin, **motorun daha temiz bulmaması**, aşırı uzunluk.

Ölçülen durum: 50 test geçiyordu, onay kapısı (`consent: true` yoksa 403)
uçtan uca doğrulanmıştı, hız sınırlayıcı çalışıyordu.

---

## 2. Neden kaldırıldı

**a) Ürünün tezini zayıflatıyordu.** Temel iddia *"metin cihazdan çıkmaz"*.
Bulut kademesi bu iddiaya bir istisna ekliyordu. Onay diyaloğuyla korunan,
kullanıcıya açıkça anlatılan bir istisna bile — açıklanması gereken bir yüzey
yaratır. İstisnasız bir iddia, iyi savunulan bir istisnadan güçlüdür.

**b) Üçüncü taraf bağımlılığı.** Ücretli bir API anahtarı, kota riski, anahtar
yönetimi ve dışarıdan gelen fiyat/erişim değişikliklerine açıklık. Yarışma
teslimatı olan bir üründe, jürinin çalıştıramayacağı bir bağımlılık.

**c) Katkısı kritik değildi.** Bulut kademesi öneri **akıcılığını**
artırıyordu; tespit, bağlam çözümleme ve müdahale — yani ürünün asıl fikrî
değeri — zaten cihazda ve onsuz çalışıyordu.

---

## 3. Kabul edilen bedel

Yeniden yazma akıcılığı. Yerel yeniden yazıcı kelime ikamesi yapıyor ve
çıktısı her zaman akıcı değil:

```
girdi : "sen tam bir aptalsın, bu karar salakça"
yerel : "sen tam bir yanlış, bu karar hatalı"     ← akıcı değil
```

Bu sınır gizlenmiyor. Kapatma yönü bir dil modeli değil, **Türkçe'ye özel
morfoloji farkındalığı**: yukarıdaki örnekte sorun, "aptalsın" kelimesinin
taşıdığı ikinci şahıs bildirme ekinin ("-sın") karşılığa taşınmamasıdır.
Doğru çıktı "sen tam bir haksızsın" olmalıydı.

---

## 4. Korunan fikir: doğrulama kapısı

Servis kaldırıldı ama arkasındaki fikir kayda değer ve raporda anlatılabilir:

> Bir dil modeli akıcı ama işe yaramaz bir öneri üretebilir — eleştiriyi
> buharlaştırabilir, hakareti başka bir hakaretle değiştirebilir. **Bunu
> istemden rica ederek garanti edemezsiniz.** Deterministik bir motorla
> ölçüp geçemeyeni atarak garanti edersiniz.

Testle kanıtlanmıştı: model `"sen tam bir aptalsın"` (toksisite 0,55) yerine
`"sen tam bir şerefsizsin"` (0,88) önerdiğinde öneri kullanıcıya **ulaşmıyordu.**

Bu ilke, ileride herhangi bir üretici model (kendi eğittiğimiz dahil)
eklenirse aynen geçerlidir: **model bir öneri kaynağıdır, bir otorite
değildir.** Karar mercii deterministik ve denetlenebilir olan motordur.

---

## 5. Bu karar geri alınabilir mi

Evet, ve maliyeti düşüktür. `RewriteSuggester` soyut arayüzü
(`packages/civility_core/lib/src/rewrite/rewrite_suggester.dart`) yerinde
duruyor; ikinci bir uygulama eklemek mimariyi değiştirmez. Silinen sunucu
kodu git geçmişinde tam hâliyle mevcut.

Geri alınması anlamlı olan tek senaryo: **kendi eğittiğimiz** bir Türkçe
yeniden yazma modeli. O durumda da üçüncü taraf bağımlılığı doğmaz ve
yukarıdaki (a) ve (b) gerekçeleri ortadan kalkar.
