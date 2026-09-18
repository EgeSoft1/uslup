# 24 · Derin Geliştirme Listesi — 50 madde

13 Eylül 2026 kod denetiminden (docs/23) çıkan öneriler. Her madde **neden**
gerektiğini ve **nereye** dokunduğunu söyler. Sıra, final sunumuna etkiye ve
riske göre verilmiştir; ✅ işaretliler bu oturumda uygulanmıştır.

---

## A. Öneri kalitesi ve yazım deneyimi (final sunumunun yüzü)

1. ✅ **Cümleyle alakalı öneri.** Öbek modu kişiye yönelik hakarette yan cümlenin
   tamamını kategori kalıbıyla değiştiriyor; "maçtaki hakem kararı" konusu
   buharlaşıp "bu konuda sana katılmıyorum" kalıyor. Yan cümledeki içerik
   adları (karar, yorum, maç, proje…) ve eleştirilen fiil kalıba taşınmalı.
   → `rewrite_suggester.dart`
   **Yapıldı:** konu sözlüğü (21 ifade, 8 davranış, 17 konu adı, 4 fiil) +
   susturma/küçümseme örüntülerine özel karşılıklar + öfkeyi koruyan tehdit
   kalıpları. 299 önerilik denetimde en sık önerinin payı %29,8 → **%15,7**,
   benzersiz öneri 76 → **92**; tespit sonuçlarında tek örnek değişmedi.
   Örnek: "beyinsiz yorumlar yapıyorsun" → "Bu yorumlarına katılmıyorum";
   "kapa çeneni artık" → "Yersiz artık" (bozuk) yerine "Biraz dinler misin".
2. ✅ **Öneriye basınca animasyonlu düzeltme.** Metin anında yer değiştiriyor;
   işaretli ifadenin üstü çizilip solması, yerine yeni ifadenin yazılarak
   gelmesi, puan sayacının yükselmesi ve dokunsal geri bildirim.
   → `civility_composer.dart`, `suggestion_morph.dart`
   **Yapıldı:** 1,1 sn dönüşüm (silinme → yazılma → oturma), kutu görünür
   alana kaydırılır, puan sayarak yükselir; hareketi azaltma tercihine uyar.
3. ✅ **Geri al.** Öneri uygulandıktan sonra birkaç saniye "Geri al" imkânı; karar
   kullanıcınınsa geri dönüş de onun olmalı. **Yapıldı:** 6 sn, kalan süre
   çubuğu; kullanıcı metne dokunursa teklif düşer.
4. ✅ **Önce/sonra farkı.** Öneri kartında hangi kelimenin neyle değiştiğini
   gösteren fark. **Yapıldı:** kelime düzeyinde LCS; iki satır (− eski · + yeni).
   Testler: `mobile/test/oneri_deneyimi_test.dart` (8), ekran görüntüleri
   `masaustu_22`–`24`.
5. ✅ **Birden fazla öneri tonu.** "Nazik · Net · Kısa" gibi 2–3 deterministik
   alternatif; kullanıcının itiraz gücünü koruyan seçenek her zaman bulunmalı.
6. **Kısmi uygulama.** Yalnızca bir işaretli ifadeye dokunup onu değiştirmek
   (satır içi çip); uzun gönderinin tamamını yeniden yazdırmamak.
7. **Öneri kalitesi metriği.** `bin/rewrite_audit.dart`'a "içerik kelimesi
   koruma oranı" eklenmeli; sayısal kapı yalnızca toksisiteyi ölçüyor, anlamın
   korunup korunmadığını ölçmüyor.

## B. Motor doğruluğu

8. **Cinsiyet, yaş, engellilik, göç genellemeleri.** README'nin bilinen sınırı
   ("kızlar zaten mühendislikten anlamaz" kaçıyor). Kimlik söz varlığına
   tekil/çoğul cinsiyet ve yaş terimleri + kapasite reddi yüklemleri.
9. **Tekil niteleyici tamlama.** "Ermeni mahallesi kirli" D9.4 denetiminin
   dışında kaldı; tekil kimlik + iyelikli ad kuruluşu için ayrı kural ve
   yakın-kaçış kümesi.
10. **Noktalamayla bitişen kelimeler.** Normalizasyon harf arasındaki her
    ayırıcıyı siliyor: "Tamam,ama" → "tamamama", "neden?Sen" → "nedensen".
    Virgül, soru ve ünlem cümle sınırı olarak korunmalı; yalnızca `. * - _`
    gibi gizleme karakterleri silinmeli (ölçümle).
11. ✅ **Emoji aralıkları eksik.** `_isEmoji` 1FA70–1FAFF (yeni emojiler),
    bayraklar (1F1E6–1F1FF) ve anahtar başlıklarını kapsamıyor; bunlar harf
    arasında gizleme için kullanılabiliyor.
12. ✅ **Büyük/küçük karışık tekrar.** Tekrar daraltma küçültmeden ÖNCE çalışıyor:
    "AAAptal" ya da "aptAAAl" daralmıyor.
13. **Aktarma penceresi sözdizimsel olmalı.** Tırnaksız aktarımda kınama 4
    kelimelik pencereye bağlı; "…demişler" uzakta kalınca mağdur korunmuyor.
14. **Kip/şahıs çözümleyicisi.** D11 düzeltmeleri tek tek örüntülerde yapıldı;
    tehdit ailesinin tamamı için "geçmiş zaman anlatı ≠ tehdit" kuralı ortak
    bir yardımcıdan gelmeli.
15. **Somut adlarda özne tespiti.** D7'nin kalan yanlış alarmı: "Sen maymunlar
    hakkında ödev hazırlıyordun". Adın öznenin tümleci mi, konu mu olduğunu
    ayıran hafif bir bağlılık kuralı.
16. **Gönderge penceresi cümleyle.** Öncül araması 160 karakterle sınırlı;
    uzun cümlede kaçıyor, kısa cümlelerde bir önceki paragrafa taşıyor.
17. ✅ **Kapı tutarlılığı yapısal testi.** D12'deki altı ölü dal bir testle
    otomatik yakalanmalı: her deyimin kapı kelimesi, ifadenin
    `LiteralPrefilter` ile çıkarılan her zorunlu parçasında geçmeli.
18. **Deyim yakın-kaçış kümesi.** Deyim katmanında her girdi için en az bir
    masum cümle etiketli kümede bulunmalı (D11'deki 8 yanlış alarmın hiçbiri
    kümede yoktu).
19. **Risk eşiklerinin kalibrasyonu.** 0,15 / 0,40 / 0,70 elle seçildi;
    kümeler üzerinde kesinlik–duyarlılık eğrisiyle seçilip raporlanmalı.
20. **İkinci etiketleyici ve kappa.** Altyapı (`annotate_export`, `kappa`)
    hazır; eksik olan ikinci insan. Tek etiketleyici en büyük ölçüm riski.
21. **İP-33: gerçekçi dağılımda kör küme.** Mevcut kümeler dengeli; gerçek
    akışta saldırı oranı düşük. %5 saldırı oranlı 500 cümlelik küme kesinliğin
    ürün koşulundaki değerini gösterir.

## C. Hibrit model

22. **Uygulamadaki ONNX modeli ölçülmemiş.** README'de ölçülen model karakter
    n-gram; paketlenen model kelime n-gram ve artırılmış veriyle eğitiliyor.
    Ya paketlenen model aynı protokolle ölçülmeli ya da ölçülen model ONNX'e
    özel tokenizer ile aktarılmalı.
23. **ONNX çıkarımı ana iş parçacığında.** İşaretlenmiş her tuş vuruşunda
    FFI çağrısı UI thread'de çalışıyor; isolate + son metin kuralı.
24. **Ön işleme eşitliği.** Model ham metinle çağrılıyor, eğitimde küçük harfe
    indiriliyor; Türkçe `I/İ` farkı ve leet çözümü Dart normalleştiricisiyle
    aynı olmalı.
25. **Küçük Türkçe dönüştürücü (İP-14).** DistilBERTurk + INT8 kuantizasyon,
    yalnızca ikinci görüş sözleşmesiyle; ölçüm protokolü baştan yazılmalı.

## D. Mobil ürün

26. ✅ **Türkçe klavye düzeni.** Klavyede ç ğ ı ö ş ü yok, sayı/sembol katmanı
    yok, büyük harf kalıcı kilit gibi davranıyor. "Türkçeye özel" bir katmanın
    klavyesi Türkçe yazamıyor.
27. ✅ **Klavye için ayrı giriş noktası.** IME servisi `main()`'i çalıştırıyor:
    bütün uygulama arayüzü görünmez bir motorda kuruluyor. `@pragma
    ('vm:entry-point') imeMain()` yalnızca motoru ve kanalı kurmalı.
28. **`KeyboardView` kullanım dışı.** API 29'dan beri deprecated; özel görünüm
    ya da Compose tabanlı klavye.
29. **Uzun metinde artımlı çözümleme.** 5.000+ karakterde her tuş vuruşunda
    metnin tamamı çözümleniyor; değişen cümle yeniden çözümlenmeli.
30. **Hassasiyet ayarı.** "Yalnızca yüksek risk" / "hepsi" ve kategori bazlı
    kapatma; kullanıcının katmanı tümden kapatmasının alternatifi.
31. **İlk açılış turu.** Üç adımda "yazarken çözümler · öneri sunar · karar
    senin"; jüri demosunda da ilk 10 saniyeyi taşır.
32. **Erişilebilirlik.** Dalgalı alt çizgi yalnızca renkle ayrışıyor; desen/
    ikon ekle. Öneri uygulandığında ekran okuyucuya duyuru.
33. **Kontrast denetimi CI'da.** `tool/erisilebilirlik_denetimi.dart` elle
    çalıştırılıyor; teste bağlanmalı.
34. **NSosyal görsel dili için tasarım tokenları.** Renk, yarıçap, gölge ve
    hareket süreleri tek kaynaktan; golden testlerle görsel regresyon.
35. ✅ **Topluluk trendinde k-anonimlik.** Kategori sayıları k=5 eşiğiyle
    gizleniyor ama günlük trend gizlenmiyor: tek gönderimli bir gün o kişinin
    davranışını açığa çıkarır.
36. **Web sunumu çevrimdışı PWA.** Sunum sunucusu yerine service worker ile
    tamamen tarayıcıdan çevrimdışı çalışma; Wasm derlemesi.

## E. Başarım

37. **Öbek eşleştirmesi Aho–Corasick ile.** `_matchPhrases` her öbek için
    metnin tamamında `indexOf` yapıyor; `LiteralIndex` zaten var, yeniden
    kullanılmalı.
38. ✅ **Soğuk başlangıç ölçümü.** Sözlük dizini ve regex derlemesinin ilk
    çözümleme gecikmesi ölçülmemiş; açılışta isolate'te ısıtma.
39. **Benchmark CI kapısı.** p99 bütçesi (2.400 karakter < 16 ms) her PR'da
    ölçülüp aşılırsa kırılmalı.

## F. Güvenlik ve dağıtım

40. **VDS erişimi.** Şifre değiştirilmeli, root şifre girişi kapatılmalı,
    betikler ayrı özel depoya taşınmalı (docs/23 G1).
41. **Release imzası.** Sürüm derlemesi debug anahtarıyla imzalanıyor;
    `key.properties` + Play App Signing.
42. ✅ **Manifest sertleştirme.** `android:allowBackup="false"`, R8 küçültme;
    `kapsam_degismezi_test` bu öznitelikleri de denetlemeli.
43. **Bağımlılık güncelliği.** `lints 3 → 6`, `flutter_lints 3 → 6`; yeni
    kurallar yakalanmamış hataları görünür kılar.

## G. Mühendislik süreci

44. ✅ **CI hattı.** GitHub Actions: analyze + test (iki paket), evaluate farkı
    (ölçüm değişirse PR yorumu), benchmark.
45. **Ölçüm çıktısı JSON.** `evaluate.dart --json`; önce/sonra farkı bu
    denetimde elle çıkarıldı, otomatik olmalı.
46. ✅ **Belgelerdeki sayılar tek kaynaktan.** README, docs/17, uygulama künyesi
    ve panel aynı sayıyı elle yazıyor (bu denetimde dört yerde güncellendi);
    JSON'dan üretilmeli ya da bir testle eşitliği denetlenmeli.
47. **Kök dizin düzeni.** Artırma ve dağıtım betikleri `tools/` altına;
    `requirements.txt`; `veri.json` üretim adımları tek komutta.
48. **Bulanık test (fuzz).** Normalleştirici (indeks haritası) ve düzenli
    ifadeler (geri izleme) için rastgele girdiyle çökme/zaman aşımı testi.
49. **Genel API yüzeyi.** `civility_core.dart` bütün etiketli kümeleri dışa
    aktarıyor ve uygulama ikili dosyasına giriyor; değerlendirme verisi ayrı
    bir `eval` kütüphanesine alınmalı.
50. **Sürümleme.** `civility_core` için semver + CHANGELOG; sözlük ve örüntü
    kataloğu değişiklikleri ölçüm kaydıyla birlikte sürüm notuna girmeli.

---

## Bu oturumda uygulananlar — kayıt

| Madde | Ne yapıldı | Doğrulama |
|---|---|---|
| 1–4 | Konu taşıyan öneri, animasyonlu dönüşüm, önce/sonra farkı, geri al | Denetim: en sık öneri %29,8 → %15,7; mobile/test/oneri_deneyimi_test.dart; ekran görüntüleri 22–24 |
| 5 | Net · Nazik · Diyalog tonları; her ton motordan ayrıca geçer, temiz olmayan sunulmaz | Widget testi: seçilen ton uygulanır |
| 11–12 | Eksik emoji blokları; büyük/küçük karışık tekrar daraltma | 🫠p🫠t🫠a🫠l, şerefsiz⭐sin, ptAaAlsın yakalanıyor; 10 kümede ölçüm farkı **0** |
| 17 | Deyim kapı kelimesinin bütün almaşıklarda zorunlu olduğunu denetleyen yapısal test | D12'deki altı ölü dalı yakalardı |
| 26 | Türkçe Q klavye (ç ğ ı ö ş ü, ! ?, ↵), tek seferlik Shift, Türkçe büyük harf | lutter build apk --debug başarılı |
| 27 | Klavye servisi imeMain giriş noktasıyla yalnızca motoru ve kanalı kurar | APK derlemesi |
| 35 | Günlük trend de k-anonimliğe tabi; gizlenen gün sayısı panelde yazılır | community_health_test.dart |
| 38 | Motor ısıtma: ilk çözümleme 55,9 ms → ~0,1 ms (AOT); ilk kareden sonra çalışır | Isıtılmış/soğuk motor bütün kümelerde birebir aynı |
| 42 | ndroid:allowBackup="false" | kapsam_degismezi_test.dart |
| 44 | GitHub Actions: motor (analiz, test, öneri kalite kapısı), ölçüm artefaktı, Flutter | .github/workflows/ci.yml |
| 46 | Arayüzdeki İP-29 sayıları çalışma anındaki ölçümle karşılaştırılır | mobile/test/olcum_tutarliligi_test.dart |
