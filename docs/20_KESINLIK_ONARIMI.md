# Kesinlik Onarımı — Gündelik Metinde Yanlış Alarmlar

**Tarih:** 13 Eylül 2026 · **Durum:** ÖLÇÜMDEN ÖNCE YAZILDI (bölüm 1–3) · sonuçlar bölüm 4'e eklenecek

## 1. Bulgu (küme dışı tarama)

İP-29'un masum dilimi 30 cümledir ve ağırlıkla bağlam tuzağıdır (alıntı,
olumsuzlama, alt dizi). Gündelik metni temsil etmez. 13 Eylül'de, hiçbir
etiketli kümeye bakılmadan üç tarama yapıldı:

1. Depodaki belgelerden çıkarılan ~10 bin kelime, "sen/sana …" bağlamında.
2. Sözlükteki her kısa kökün (≤ 3 harf) kabul edilen bütün çekimleri, gözle.
3. Bu oturumda yazılmış 79 masum cümle (övgü, taziye, gündelik konuşma).

79 masum cümlenin **34'ü** işaretlendi. En ağır örnekler:

| Cümle | Sonuç | Neden |
|---|---|---|
| Sana katılıyorum ama bence yanlış | **Yüksek risk** | "ama" = am + a (kısa kök + ek) |
| Sana sıkı sıkı sarılıyorum | **Yüksek risk** | "sıkı" → siki = sik + i |
| Allah razı olsun senden, amin | **Yüksek risk** | "amin" = am + in |
| Sen boğa burcusun değil mi | **Yüksek risk** | "boğa" → boga = bok (yumuşama) + a |
| Artık yaşamaya dayanamıyorum | **Yüksek risk · tehdit** | kendine zarar örüntüsü `tehdit` kategorisinde; onay diyaloğu "suç oluşturabilir" diyor, öneri "Bu söylediğinden çok rahatsızım" |
| Çok yazık oldu, geçmiş olsun | Riskli | kinaye.zavalli |
| aferin sana, sınavı geçmişsin | Riskli | kinaye.sahte_alkis |
| Kaza mı geçirdin sen? | Riskli | "kaza" = kaz + a |
| Sen o zaman haklı idin | Riskli | "idin" = it (yumuşama) + in |

Kök neden iki yerde: (a) kısa köklere tanınan ortak çekim listesi, bu
köklerle başlayan en sık Türkçe kelimeleri kapsıyor; (b) bağlamsız "ironi"
örüntüleri gerçek övgü ve taziyeyi ayırt edemiyor. İkisi de 9a3f7b8 ara
commit'iyle gelmiş ve ayrıca ölçülmemişti.

## 2. Önceden kayıtlı değişiklikler

Aşağıdaki liste ölçümden önce yazıldı. Ölçüm sonucuna bakılarak bu listeye
ekleme yapılmayacak; yapılırsa bu belgeye ayrıca ve gerekçesiyle yazılacak.

| # | Değişiklik | Kapsam |
|---|---|---|
| D1 | **Kısa kökte yüzey harf kanıtı.** Normalize uzunluğu ≤ 3 olan terimlerde, kökün harf konumlarında özgün metinde FARKLI bir Türkçe harf (ı ğ ş ç ö ü) yazılmışsa eşleşme yok sayılır. İstisna: kökün son harfinde k→ğ yumuşaması. Büyük "I" belirsizdir, kanıt sayılmaz. | sıkı, sığın, sıkın, boğa, boğum, adı |
| D2 | **ASCII'de ayırt edilemeyen gündelik kelimeler** tam kelime olarak kısa kök çekiminden çıkarılır: ama, amin, kaza, kazi, kazim, idi, idin, idim, idiniz, adile, boga, siki, mala, mallar, mallari. | "ama", "kaza", "idi" … |
| D3 | **Kinaye ailesinin altı örüntüsü kaldırılır:** zeka_seviyesi, zavalli, zeka_fiskiriyor, cok_zekisin_ya, dahi_benzetmesi, sahte_alkis. | övgü, taziye, betimleme |
| D4 | **Kendine zarar toksisite değildir.** Bu örüntüler bulgu üretmez, skoru ve risk basamağını değiştirmez, tehdit akışını tetiklemez. Motor ayrı bir destek sinyali verir; arayüz uyarı ve öneri yerine destek kartı gösterir. | 2 örüntü |
| D5 | **Samimi övgüyle ayırt edilemeyen alay örüntüleri kaldırılır:** alayci.helal_olsun_valla, alayci.aferin_valla, alayci.bravo, alayci.tam_senlik. | "helal olsun valla", "bravo valla" |
| D6 | **Tekil örüntü daraltmaları:** otekilestirme.hepiniz_aynisiniz'den çıplak "ayni" almaşığı çıkar ("hepiniz aynı fikirde misiniz"); yoksayma.yine_mi_sen cümle sonuna bağlanır ("yine mi sen kazandın"); tehdit.beni_tanimiyorsun'dan "tanıyor musun" çıkar. | 3 örüntü |

## 3. Nasıl raporlanacak

- **İP-30 gündelik küme** (`--gundelik`, 120 masum cümle) değişikliklerden
  ÖNCE commit edilir; önce ve sonra ölçülür. Sınırı: hata sınıfları
  bilindikten sonra yazıldı, o sınıflar için kör değildir.
- **İP-29** değişikliklerden sonra bir kez yeniden ölçülür. Sayı değişirse
  **ikinci geçiş** olarak, ilk geçişin (%96,4 · %45,0) yanında raporlanır;
  ilk geçiş silinmez. Değişiklikler İP-29'a bakılarak yapılmadı ve
  sonucuna göre motora ek değişiklik yapılmaz.
- Değişikliklerin etiketli kümelerdeki etkisi örnek düzeyinde listelenir
  (kazanılan ve kaybedilen her örnek).
- Duyarlılık kaybı beklenir (D3 ve D5 gerçek alayları da kaçıracak).
  Ürünün hedef fonksiyonu F0.5'tir: yanlış alarm, kaçırılan saldırıdan
  daha pahalıdır — mağduru ya da övgü yazanı cezalandıran bir katmanı
  kullanıcı kapatır.

## 4. Sonuçlar

*(Ölçümden sonra eklenecek.)*
