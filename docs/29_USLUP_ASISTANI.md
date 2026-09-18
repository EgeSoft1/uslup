# Üslup Asistanı — Cihaz Üstü Türkçe Niyet Çözümleyici

**Tarih:** 15 Eylül 2026 · **Kapsam:** `packages/civility_core`, `mobile`
**Davranış değişikliği:** motorda yok — asistan motoru çağırır, değiştirmez

## 1. Ne yapar

Kullanıcı Türkçe bir istek yazar, asistan **niyeti** çıkarır ve karşılığını
getirir:

| Kullanıcı yazar | Asistan getirir |
|---|---|
| "Bana nefret söylemi örnekleri sun" | O başlıktaki örnek cümleler, her birinin beklenen sonucu ve gerekçesiyle |
| "Ölçüm sonuçlarınız ne?" | Kör küme sayıları, ezber ölçüsü ayrımıyla birlikte |
| "Nasıl çalışıyor?" | Yedi katman |
| "Yazdıklarım nereye gidiyor?" | Mahremiyet değişmezleri |
| "Uyarıları kapatabilir miyim?" | Ayar seçenekleri ve neyin kapatılamayacağı |
| "Sen tam bir aptalsın" | Cümleyi motora verir, gerekçeli sonucu gösterir |

Örnek kartına dokunmak o cümleyi gerçekten çözümletir: kullanıcı asistanın
iddiasını yerinde sınayabilir.

## 2. Neden LLM değil

Bu ürünün iki temel iddiası var: **metin cihazdan çıkmaz** ve **her karar
açıklanabilir**. Bir dil modeli koymak ikisini birden götürürdü — model ya
sunucuda çalışır (metin çıkar) ya da cihazda çalışıp neden öyle cevap
verdiğini söyleyemez.

Projede bir LLM zaten ölçülüp kasıtlı olarak kaldırıldı (docs/03) ve
motorla soru-cevap ekranı da aynı sebeple yeniden adlandırılmıştı: önceki adı
"Üslup Yapay Zekâ Sohbeti (LLM)" idi, oysa arkasında model yoktu. Jüriye
yanlış bir etiket göstermek, doğru olan her şeyin güvenilirliğini düşürür.

Asistan bu yüzden **kural tabanlıdır** ve ekranın üstünde bunu yazar:
`kural tabanlı · cihaz üstü · dil modeli yok · ağ çağrısı yok`.

## 3. Nasıl çalışır

Niyet çözümleme, motorun **aynı** Türkçe katmanlarını kullanır:

1. Soru `TurkishNormalizer`'dan geçer — aksan, büyük harf ve gizleme çözülür.
   Böylece "NEFRET SÖYLEMİ", "nefret soylemi" ve "nefrét söylemi" aynı yere
   düşer.
2. Niyet kalıpları **kök** biçiminde aranır. Türkçede ek kökün sonuna geldiği
   için "ölçüm", "ölçümünüz" ve "ölçümleriniz" hepsi `olcum` kökünü taşır;
   ayrı bir çekim tablosu gerekmez.
3. Konu adları **belirliden genele** sıralıdır ve ilk eşleşen kazanır.

### Sıra neden önemli

"En uzun eşleşme kazansın" kuralı denendi ve yanlış cevap verdi:

```
"deyimle aşağılama örnekleri"
  → "asagilama" (9 harf) > "deyim" (5 harf)  →  Hakaret  ✗
```

Kullanıcının kastettiği deyimdi. Açık sıra hem doğru hem okunur, ve
`test/asistan_test.dart` bu satırları tek tek koruyor.

### Tırnak neden yalnızca mesajın tamamını kaplıyorsa alıntıdır

İlk sürüm mesajın herhangi bir yerindeki tırnağı "şunu çözümle" sayıyordu ve
ürünün en ayırt edici cümlesini bozuyordu:

```
Bana "aptal" dedi, çok üzüldüm   →  yalnızca «aptal» çözümlenir  →  Riskli ✗
```

Oysa o cümle bir şikâyettir ve temiz kalmalıdır. Tırnak artık ancak mesajın
tamamını kaplıyorsa ya da önünde "çözümle / analiz et" gibi bir komut varsa
alıntı sayılır. Bu davranış testle kilitli.

## 4. Doğruluk — ekrandaki iddia testlidir

Asistan bir örnek gösterirken "bu cümle işaretlenir" ya da "temiz" diye bir
**iddiada** bulunur. `test/asistan_test.dart` her örneği gerçek motordan
geçirir ve iddiayı doğrular. Motor bir gün farklı karar verirse test kırılır
ve yanlış iddia yayına çıkmadan yakalanır.

| Test | İddia |
|---|---|
| `civility_core/test/asistan_test.dart` | Sunulan her örnek, motorun gerçek kararıyla aynı |
| ” | Aynı niyetin farklı söylenişleri aynı yere düşer (12 konu × çeşitli yazım) |
| ” | Her bilgi cevabı dolu ve markdown kaçağı taşımıyor |
| ” | Cümle içindeki tırnak alıntı sayılmaz — mağdur temiz kalır |
| ” | Her devam önerisi tanınan bir niyete gider (çıkmaz sokak çipi yok) |
| ” | Hiçbir girdi çökertmez: boş, 5.000 karakter, emoji, sıfır genişlikli |
| ” | Asistan kendini dil modeli diye tanıtmaz |
| `mobile/test/asistan_ekrani_test.dart` | Arayüz çekirdeğe gerçekten bağlı; kart dokunuşu çözümlemeye gider |

Toplam: çekirdek 765 test, arayüz 79 test.

## 5. Bilinen sınır

Asistan **tanıdığı konularla sınırlıdır** ve bunu saklamaz: anlamadığı soruda
"Bunu anlamadım, kural tabanlı bir asistanım" der ve ne sorulabileceğini
gösterir. Serbest sohbet etmez, bilmediği bir şeyi uydurmaz.

Bu bir kısıt değil, tercihtir: uyduran bir asistan, ölçüm disiplini üzerine
kurulmuş bir ürüne en çok zarar veren şey olurdu.
