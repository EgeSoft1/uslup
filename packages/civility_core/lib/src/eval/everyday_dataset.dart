// =============================================================================
// İP-30 · GÜNDELİK METİN KÜMESİ — yanlış alarm oranının ölçüsü
// Dosya: packages/civility_core/lib/src/eval/everyday_dataset.dart
//
// ── NEDEN YENİ BİR KÜME GEREKTİ ───────────────────────────────────────────
// Önceki kümelerin masum dilimi ağırlıkla "tuzak" cümlelerdir: alt dizi
// çakışmaları, olumsuzlama, alıntı, mağdur anlatısı. Bunlar bağlam katmanını
// sınar ama insanların GÜN İÇİNDE yazdığı sıradan metni temsil etmez.
//
// 13 Eylül 2026'da küme dışı bir tarama bunun bedelini gösterdi:
//
//   "Sana katılıyorum ama bence yanlış"   → Yüksek risk (am + a)
//   "Sana sıkı sıkı sarılıyorum"          → Yüksek risk (sik + i)
//   "Çok yazık oldu, geçmiş olsun"        → Riskli (kinaye örüntüsü)
//
// İP-29'un 30 masum cümlesinin hiçbiri bu kalıplara denk gelmediği için
// raporlanan %96,4 kesinlik gündelik kullanımı temsil etmiyordu.
//
// ── PROTOKOL VE SINIRI (açıkça) ───────────────────────────────────────────
// Bu küme, yukarıdaki hata SINIFLARI fark edildikten SONRA ama düzeltmeler
// yazılmadan ÖNCE yazıldı ve düzeltmelerden önce ayrı bir commit olarak
// depoya girdi. Yazar hata sınıflarını biliyordu; bu yüzden küme o sınıflar
// için KÖR DEĞİLDİR. Bunu dengelemek için cümleler tek tek kelime avlanarak
// değil, sekiz gündelik alanda "bu alanda insanlar ne yazar" sorusuyla
// yazıldı. Kümenin iddiası dar tutulmalıdır: "genelleme" değil, "sıradan
// metinde yanlış alarm oranı".
//
// Tüm örnekler MÜDAHALE BEKLENMEYEN örneklerdir. Tek anlamlı metrik
// özgüllüktür (temiz kalan / toplam).
//
// Tek etiketleyicilidir.
// =============================================================================

import 'gold_case.dart';

abstract final class EverydayDataset {
  static const List<GoldCase> cases = [
    // ── 1. Aile ve arkadaş sohbeti (15) ───────────────────────────────────
    GoldCase.clean(text: 'Anneciğim akşam yemeğe ne yapalım, sen karar ver', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Seni çok özledim, ne zaman geliyorsun?', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Kardeşim sana bir şey soracağım ama kızma', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Babam sana selam söyledi, bayramda bekliyor', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Sen olmasaydın bu taşınmayı bitiremezdik', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Dün gece çok güldük, sen de gelseydin keşke', group: GoldGroup.masum, note: 'arkadaş'),
    GoldCase.clean(text: 'Sana sıkı sıkı sarılmak istiyorum', group: GoldGroup.masum, note: 'arkadaş'),
    GoldCase.clean(text: 'Senin doğum gününü unutmuşum, çok özür dilerim', group: GoldGroup.masum, note: 'arkadaş'),
    GoldCase.clean(text: 'Kızımız bugün ilk adımını attı', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Sen yorulmuşsundur, biraz uzan istersen', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Dedem eskiden çok sıkı bir öğretmendi', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Sana söylemiştim ama unutmuşsun galiba', group: GoldGroup.masum, note: 'arkadaş'),
    GoldCase.clean(text: 'Senin kedi yine balkona çıkmış', group: GoldGroup.masum, note: 'arkadaş'),
    GoldCase.clean(text: 'Hafta sonu köye gidiyoruz, sen de gel', group: GoldGroup.masum, note: 'aile'),
    GoldCase.clean(text: 'Canım benim, sen hiç dert etme', group: GoldGroup.masum, note: 'arkadaş'),

    // ── 2. İş ve okul (15) ────────────────────────────────────────────────
    GoldCase.clean(text: 'Raporu sana e-postayla gönderdim, bakar mısın?', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Toplantı saat üçte, sen sunumu hazırla', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Hocam ödevi yetiştiremedim ama yarın teslim ederim', group: GoldGroup.masum, note: 'okul'),
    GoldCase.clean(text: 'Sen bu projede çok emek verdin, teşekkürler', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Malları depoya sen mi indireceksin?', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Sınav çok zordu ama geçtiğimi düşünüyorum', group: GoldGroup.masum, note: 'okul'),
    GoldCase.clean(text: 'Müşteri sana dönüş yaptı mı?', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Sen o zaman stajyer idin, şimdi müdür oldun', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Kazı ekibi yarın sahaya çıkıyor', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Sana bu hafta fazla mesai yazdım', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Tezimi bitirdim ama savunma tarihi belli değil', group: GoldGroup.masum, note: 'okul'),
    GoldCase.clean(text: 'Sen matematikte çok iyisin, bana da anlatır mısın?', group: GoldGroup.masum, note: 'okul'),
    GoldCase.clean(text: 'Yeni gelen arkadaşın adı ne?', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Maaşlar ayın on beşinde yatacak', group: GoldGroup.masum, note: 'iş'),
    GoldCase.clean(text: 'Sen dersi kaçırdın, notları sana atayım', group: GoldGroup.masum, note: 'okul'),

    // ── 3. Övgü ve tebrik (15) ────────────────────────────────────────────
    GoldCase.clean(text: 'Helal olsun sana, çok güzel bir iş çıkarmışsın', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Tebrikler, bu başarıyı sonuna kadar hak ettin', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Aferin oğlum, karnen çok güzel', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Bravo, konser muhteşemdi', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Çok akıllı bir çocuksun sen', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Eline sağlık, yemek harika olmuş', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Sen gerçekten çok yeteneklisin', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Büyük iş başardınız, hepinizi kutlarım', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Maşallah ne kadar da büyümüşsün', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Harika bir fikir, bence hemen başlayalım', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Seninle gurur duyuyorum', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Valla çok yakışmış sana bu ceket', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Zekana hayranım, bu bulmacayı nasıl çözdün?', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Takım olarak müthiş oynadınız', group: GoldGroup.masum, note: 'övgü'),
    GoldCase.clean(text: 'Kutlarım, yeni işin hayırlı olsun', group: GoldGroup.masum, note: 'övgü'),

    // ── 4. Taziye, geçmiş olsun, destek (15) ──────────────────────────────
    GoldCase.clean(text: 'Başınız sağ olsun, Allah rahmet eylesin', group: GoldGroup.masum, note: 'taziye'),
    GoldCase.clean(text: 'Çok yazık olmuş, geçmiş olsun', group: GoldGroup.masum, note: 'taziye'),
    GoldCase.clean(text: 'Kaza haberini duydum, iyi misin?', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Sana bir şey olursa hemen ara beni', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Üzülme, her şey düzelecek', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Allah şifa versin, çabucak iyileş', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Ne kadar üzücü, ailesine sabır diliyorum', group: GoldGroup.masum, note: 'taziye'),
    GoldCase.clean(text: 'Sen güçlüsün, bunu da atlatırsın', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Yanındayım, ne gerekirse söyle', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Allah razı olsun senden, amin', group: GoldGroup.masum, note: 'dua'),
    GoldCase.clean(text: 'Kötü bir gün geçirdin biliyorum, sana çay yapayım', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Evin su basmış, çok geçmiş olsun', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Hayvancağız çok zayıflamış, veterinere götürelim', group: GoldGroup.masum, note: 'destek'),
    GoldCase.clean(text: 'Senin için dua ediyoruz', group: GoldGroup.masum, note: 'dua'),
    GoldCase.clean(text: 'Merak etme, sonuçlar temiz çıkacak', group: GoldGroup.masum, note: 'destek'),

    // ── 5. Spor, oyun, eğlence (15) ───────────────────────────────────────
    GoldCase.clean(text: 'Dünkü maçta hakem çok kötüydü ama kazandık', group: GoldGroup.masum, note: 'spor'),
    GoldCase.clean(text: 'Sen hangi takımı tutuyorsun?', group: GoldGroup.masum, note: 'spor'),
    GoldCase.clean(text: 'Bu oyunda sen beni hep yeniyorsun', group: GoldGroup.masum, note: 'oyun'),
    GoldCase.clean(text: 'Film çok uzundu ama sonu güzeldi', group: GoldGroup.masum, note: 'eğlence'),
    GoldCase.clean(text: 'Boğa burcu olanlar inatçı olurmuş', group: GoldGroup.masum, note: 'eğlence'),
    GoldCase.clean(text: 'Kaleci son dakikada müthiş kurtardı', group: GoldGroup.masum, note: 'spor'),
    GoldCase.clean(text: 'Sana konser bileti aldım', group: GoldGroup.masum, note: 'eğlence'),
    GoldCase.clean(text: 'Yarın sabah koşuya çıkalım mı?', group: GoldGroup.masum, note: 'spor'),
    GoldCase.clean(text: 'Satranç turnuvasında ikinci oldum', group: GoldGroup.masum, note: 'oyun'),
    GoldCase.clean(text: 'Sen bu diziyi izledin mi, çok sarıyor', group: GoldGroup.masum, note: 'eğlence'),
    GoldCase.clean(text: 'Takım kaptanı sakatlandı, çok yazık', group: GoldGroup.masum, note: 'spor'),
    GoldCase.clean(text: 'Basketbolda sen pivot oyna, ben oyun kurarım', group: GoldGroup.masum, note: 'spor'),
    GoldCase.clean(text: 'Kitabı bitirdim, sana da ödünç veririm', group: GoldGroup.masum, note: 'eğlence'),
    GoldCase.clean(text: 'Maç berabere bitti ama oyun güzeldi', group: GoldGroup.masum, note: 'spor'),
    GoldCase.clean(text: 'Tatilde çok boş vaktimiz oldu, bol bol yüzdük', group: GoldGroup.masum, note: 'eğlence'),

    // ── 6. Ev, yemek, alışveriş (15) ──────────────────────────────────────
    GoldCase.clean(text: 'Markete gidiyorum, sana bir şey lazım mı?', group: GoldGroup.masum, note: 'alışveriş'),
    GoldCase.clean(text: 'Buzdolabı bomboş, sipariş verelim', group: GoldGroup.masum, note: 'ev'),
    GoldCase.clean(text: 'Kurabiyeler biraz yandı ama yine de lezzetli', group: GoldGroup.masum, note: 'yemek'),
    GoldCase.clean(text: 'Kapıyı sıkı kapat, rüzgar çok', group: GoldGroup.masum, note: 'ev'),
    GoldCase.clean(text: 'Sen salatayı yap, ben pilavı hallederim', group: GoldGroup.masum, note: 'yemek'),
    GoldCase.clean(text: 'Kargo sana ulaştı mı?', group: GoldGroup.masum, note: 'alışveriş'),
    GoldCase.clean(text: 'Bu ayakkabı güzel ama biraz pahalı', group: GoldGroup.masum, note: 'alışveriş'),
    GoldCase.clean(text: 'Bahçeye yeni fide diktik', group: GoldGroup.masum, note: 'ev'),
    GoldCase.clean(text: 'Çamaşırları sen asar mısın?', group: GoldGroup.masum, note: 'ev'),
    GoldCase.clean(text: 'Kasaptan kıyma aldım, köfte yapacağım', group: GoldGroup.masum, note: 'yemek'),
    GoldCase.clean(text: 'Kiracı yarın evi boşaltıyor', group: GoldGroup.masum, note: 'ev'),
    GoldCase.clean(text: 'İndirim bitmeden sana da bir mont alalım', group: GoldGroup.masum, note: 'alışveriş'),
    GoldCase.clean(text: 'Musluk yine damlatıyor, tamirci çağıralım', group: GoldGroup.masum, note: 'ev'),
    GoldCase.clean(text: 'Çorbanın tuzu az olmuş ama olsun', group: GoldGroup.masum, note: 'yemek'),
    GoldCase.clean(text: 'Sen hiç mantı yaptın mı?', group: GoldGroup.masum, note: 'yemek'),

    // ── 7. Kibar ya da sert ama meşru görüş ayrılığı (15) ─────────────────
    GoldCase.clean(text: 'Sana katılıyorum ama bir noktada farklı düşünüyorum', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Seni anlıyorum ama bu karar bence yanlış', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Sen haklı olabilirsin ama verilere bakmak lazım', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Bu yazına tamamen katılmıyorum', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Belediyenin bu uygulaması kabul edilemez', group: GoldGroup.masum, note: 'eleştiri'),
    GoldCase.clean(text: 'Sen öyle diyorsun ama rakamlar başka şey söylüyor', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Bence bu konuda acele ediyorsun', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Kusura bakma ama bu sefer sana hak veremeyeceğim', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Hizmet çok yavaştı, bir daha gelmem', group: GoldGroup.masum, note: 'eleştiri'),
    GoldCase.clean(text: 'Sen bu işi hafife alıyorsun gibi geliyor', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Yönetimin açıklaması tatmin edici değil', group: GoldGroup.masum, note: 'eleştiri'),
    GoldCase.clean(text: 'Seninle aynı fikirde değilim ama saygı duyuyorum', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Bu fiyatlar gerçekten fahiş', group: GoldGroup.masum, note: 'eleştiri'),
    GoldCase.clean(text: 'Haklısın ama zamanlama kötü oldu', group: GoldGroup.masum, note: 'görüş'),
    GoldCase.clean(text: 'Sen bu maddeyi yanlış okumuş olabilirsin', group: GoldGroup.masum, note: 'görüş'),

    // ── 8. Planlama, soru, yol tarifi (15) ────────────────────────────────
    GoldCase.clean(text: 'Kaçta buluşuyoruz, sen mi geleceksin ben mi?', group: GoldGroup.masum, note: 'plan'),
    GoldCase.clean(text: 'Sağdan ikinci sokağa girince sola dön', group: GoldGroup.masum, note: 'yol'),
    GoldCase.clean(text: 'Otobüs gecikti, beş dakika sonra oradayım', group: GoldGroup.masum, note: 'plan'),
    GoldCase.clean(text: 'Sana konum atıyorum, oradan gel', group: GoldGroup.masum, note: 'yol'),
    GoldCase.clean(text: 'Yarın hava yağışlıymış, şemsiye al', group: GoldGroup.masum, note: 'plan'),
    GoldCase.clean(text: 'Uçak kaçta iniyor, seni havalimanından alırım', group: GoldGroup.masum, note: 'plan'),
    GoldCase.clean(text: 'Randevu cuma günü saat ikide', group: GoldGroup.masum, note: 'plan'),
    GoldCase.clean(text: 'Sen önden git, ben arkadan yetişirim', group: GoldGroup.masum, note: 'plan'),
    GoldCase.clean(text: 'Köprü trafiği çok sıkışık, başka yoldan gidelim', group: GoldGroup.masum, note: 'yol'),
    GoldCase.clean(text: 'Bilet fiyatı ne kadar biliyor musun?', group: GoldGroup.masum, note: 'soru'),
    GoldCase.clean(text: 'Sen kaç yaşındasın?', group: GoldGroup.masum, note: 'soru'),
    GoldCase.clean(text: 'Toplantıyı haftaya erteleyelim mi?', group: GoldGroup.masum, note: 'plan'),
    GoldCase.clean(text: 'Eczane nöbetçi mi, sen biliyor musun?', group: GoldGroup.masum, note: 'soru'),
    GoldCase.clean(text: 'Sana uyarsa pazartesi başlayalım', group: GoldGroup.masum, note: 'plan'),
    GoldCase.clean(text: 'Arabayı sen mi alacaksın yarın?', group: GoldGroup.masum, note: 'plan'),
  ];
}
