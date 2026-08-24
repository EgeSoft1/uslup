// =============================================================================
// İP-24 · Yeniden Yazma Kalitesi — Regresyon
// Dosya: packages/civility_core/test/rewrite_quality_test.dart
//
// ── NEDEN AYRI BİR TEST DOSYASI ───────────────────────────────────────────
// `rewrite_test.dart` yeniden yazıcının MEKANİĞİNİ sınar: ünlü uyumu, ek
// aktarımı, mod seçimi. Bu dosya farklı bir soruyu sorar: üretilen cümle
// KULLANILABİLİR mi?
//
// Ayrım önemlidir çünkü ürünün doğrulama kapısı yalnızca toksisiteye bakar
// ve iki kusuru birden göremez:
//
//   1. KALIP ÇÖKÜŞÜ — her saldırı aynı cümleye çıkarsa toksisite yine
//      düşer, kapı yine "başarılı" der, ama kullanıcının niyeti silinmiştir.
//   2. BOZUK ÇIKTI — "Yanlış gibi davrandın" toksisitesi sıfırdır ve
//      kapıdan geçer, ama Türkçe değildir.
//
// Ölçüm (24 Ağustos 2026) ikisini de buldu; bu dosya geri gelmelerini
// engeller.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  late LexicalTurkishClassifier engine;
  late LocalRewriteSuggester suggester;

  setUp(() {
    engine = LexicalTurkishClassifier();
    suggester = LocalRewriteSuggester(engine);
  });

  Future<String?> rewrite(String text) async {
    final analysis = engine.analyze(text);
    final suggestion = await suggester.suggest(analysis);
    return suggestion?.text;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Bozuk çıktı üretilmiyor', () {
    // Hepsi ölçümde gerçekten üretilmiş bozuk çıktılardır.
    const bozukVakalar = <String, String>{
      'avanak gibi davrandın': 'Yanlış gibi davrandın',
      'sersem misin nesin': 'Yanlış mısın nesin',
      'salak mısın nesin': 'Hatalı mısın nesin',
      'embesil misin gerçekten': 'Yanlış mısın gerçekten',
      'a.p.t.a.l mısın': 'Yanlış.yanlış.yanlış.yanlış.yanlış mısın',
    };

    bozukVakalar.forEach((girdi, eskiBozukCikti) {
      test('"$girdi" artık bozuk çıktı vermiyor', () async {
        final sonuc = await rewrite(girdi);
        expect(sonuc, isNotNull, reason: 'Öneri üretilemedi.');
        expect(sonuc, isNot(eskiBozukCikti),
            reason: 'Bilinen bozuk çıktı geri geldi.');

        // Nötr karşılık bir benzetmenin ya da soru kuruluşunun içine
        // düşmemeli — kelime ikamesinin bu iki bağlamda işi yoktur.
        expect(sonuc!.toLowerCase(),
            isNot(matches(RegExp(r'\b(yanlış|yersiz|hatalı)\s+gibi\b'))));
        expect(
            sonuc.toLowerCase(),
            isNot(matches(
                RegExp(r'\b(yanlış|yersiz|hatalı)\s+m[iıuü](sin|sın|sun|sün)?\b'))));
      });
    });

    test('gizleme noktası yan cümle ayırıcısı sayılmaz', () async {
      // "a.p.t.a.l" beş yan cümleye bölünüyordu ve nötr karşılık her birine
      // ayrı ayrı yazılıyordu. Gerçek bir cümle sınırı, ayırıcıdan sonra
      // boşluk ya da metin sonu ister.
      final sonuc = await rewrite('a.p.t.a.l mısın');
      expect(sonuc, isNotNull);
      expect(sonuc!.split('.').length, lessThan(3),
          reason: 'Harf arası noktalar cümle sınırı sayılıyor: "$sonuc"');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Konuşma edimi korunuyor — kalıp çöküşüne karşı', () {
    // Kategori başına TEK kalıp vardı; farklı edimlerdeki saldırılar aynı
    // cümleye çöküyordu. Kullanıcı niyetini silen bir öneri kullanılmaz.
    test('soru, davranış ve ifade eleştirisi aynı cevabı almaz', () async {
      final soru = await rewrite('salak mısın nesin');
      final davranis = await rewrite('maymun gibi davranıyorsun');
      final ifade = await rewrite('kafasız bir öneri bu');

      expect(soru, isNotNull);
      expect(davranis, isNotNull);
      expect(ifade, isNotNull);

      final hepsi = {soru, davranis, ifade};
      expect(hepsi.length, greaterThanOrEqualTo(2),
          reason: 'Üç farklı konuşma edimi tek kalıba çöktü: '
              'soru="$soru" davranış="$davranis" ifade="$ifade"');
    });

    test('aynı girdi her zaman aynı öneriyi verir — rastgelelik yok', () async {
      // Kalıp seçimi belirlenimcidir. Rastgele seçim çeşitlilik üretirdi ama
      // yeniden üretilemez ve test edilemez olurdu.
      final a = await rewrite('sen tam bir aptalsın');
      final b = await rewrite('sen tam bir aptalsın');
      expect(a, b);
    });

    test('örüntünün kendi karşılığı kategori kalıbını ezer', () async {
      // Örüntü yazarı, o kuruluşun ne söylemeye çalıştığını bilerek özel bir
      // karşılık yazmıştır; genel kalıptan daha iyidir. Önceki hâlde öbek
      // modunda bu karşılıklar tamamen atılıyordu.
      final sonuc = await rewrite('Suriyeliler defolsun ülkelerine');
      expect(sonuc, isNotNull);
      expect(sonuc!.toLowerCase(), contains('göç politikası'),
          reason: 'nefret.dislama örüntüsünün kendi karşılığı kullanılmadı: '
              '"$sonuc"');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Çeşitlilik eşiği — bütün etiketli kümeler', () {
    test('tek bir öneri, önerilerin yarısından fazlasını kaplamıyor', () async {
      final tumCases = <GoldCase>[
        ...GoldDataset.cases,
        ...HoldoutDataset.cases,
        ...GeneralizationDataset.cases,
        ...Generalization2Dataset.cases,
        ...Generalization3Dataset.cases,
      ];

      final oneriler = <String>[];
      for (final c in tumCases) {
        if (!c.shouldFlag) continue;
        final analysis = engine.analyze(c.text);
        if (!analysis.hasFindings) continue;
        final s = await suggester.suggest(analysis);
        if (s != null) oneriler.add(s.text);
      }

      expect(oneriler.length, greaterThan(200),
          reason: 'Kapsam beklenenden düşük; ölçüm anlamsızlaşır.');

      final sayim = <String, int>{};
      for (final o in oneriler) {
        sayim[o] = (sayim[o] ?? 0) + 1;
      }
      final enSik =
          sayim.values.fold<int>(0, (a, b) => a > b ? a : b) / oneriler.length;

      expect(enSik, lessThan(0.5),
          reason: 'Kalıp çöküşü: önerilerin %${(enSik * 100).round()}\'i tek '
              'bir cümle. Kullanıcının niyeti siliniyor.');

      // Benzersiz öneri sayısı da bir alt sınır taşır. Bu eşik, ölçülen
      // değerin (80) altında ama anlamlı bir gerilemeyi yakalayacak kadar
      // yakın seçilmiştir.
      expect(sayim.length, greaterThanOrEqualTo(60),
          reason: 'Benzersiz öneri sayısı düştü: ${sayim.length}');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Değişmeyen sözleşme', () {
    test('her öneri orijinalden ölçülebilir biçimde daha temizdir', () async {
      const ornekler = [
        'sen tam bir aptalsın',
        'maymun gibi davranıyorsun',
        'Bütün Suriyeliler hırsızdır',
        'senin gibilerle tartışmak zaman kaybı',
        'sende akıl mı var',
      ];

      for (final metin in ornekler) {
        final analysis = engine.analyze(metin);
        final s = await suggester.suggest(analysis);
        expect(s, isNotNull, reason: '"$metin" için öneri üretilemedi.');
        final dogrulama = engine.analyze(s!.text);
        expect(dogrulama.toxicity, lessThan(analysis.toxicity),
            reason: '"$metin" → "${s.text}" daha temiz değil.');
      }
    });

    test('temiz metin için öneri üretilmez', () async {
      final analysis = engine.analyze('yarın buluşalım mı');
      expect(await suggester.suggest(analysis), isNull);
    });
  });
}
