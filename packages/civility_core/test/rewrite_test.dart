// =============================================================================
// Yeniden Yazma Testleri — iki mod ve Türkçe biçimbilim
// Dosya: packages/civility_core/test/rewrite_test.dart
//
// Bu testler, ölçümün ortaya çıkardığı somut bozukluklara karşı yazıldı.
// İlk sürümde yeniden yazıcı kategori varsayılanını ("katılmıyorum") kelime
// yuvasına sokuyordu ve çıktının çoğu bozuktu:
//
//   "gerizekalı herif"  →  "katılmıyorum herif"
//
// Test adları HATAYI anlatır, çözümü değil — çözüm değişse de test anlamını
// korur.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  final engine = LexicalTurkishClassifier();
  final suggester = LocalRewriteSuggester(engine);

  Future<String?> rewrite(String text) async {
    final analysis = engine.analyze(text);
    final suggestion = await suggester.suggest(analysis);
    return suggestion?.text;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Türkçe ünlü uyumu', () {
    test('dört biçimli ek ünlüsü kalın/ince ve düz/yuvarlak ayırır', () {
      expect(TurkishMorphology.vowelFour('aptal'), 'ı'); // kalın düz
      expect(TurkishMorphology.vowelFour('sersem'), 'i'); // ince düz
      expect(TurkishMorphology.vowelFour('yorgun'), 'u'); // kalın yuvarlak
      expect(TurkishMorphology.vowelFour('gözlük'), 'ü'); // ince yuvarlak
    });

    test('iki biçimli ek ünlüsü yalnızca kalın/ince ayırır', () {
      expect(TurkishMorphology.vowelTwo('kitap'), 'a');
      expect(TurkishMorphology.vowelTwo('ev'), 'e');
    });

    test('ikinci tekil şahıs eki köke göre değişir', () {
      expect(TurkishMorphology.copulaSecondSingular('haksız'), 'sın');
      expect(TurkishMorphology.copulaSecondSingular('sersem'), 'sin');
      expect(TurkishMorphology.copulaSecondSingular('yorgun'), 'sun');
    });

    test('üçüncü şahıs ekinde ünsüz benzeşmesi uygulanır', () {
      // Sert ünsüzden sonra "d" değil "t": "hatalıdır" ama "yanlıştır".
      expect(TurkishMorphology.copulaThird('yanlış'), 'tır');
      expect(TurkishMorphology.copulaThird('hatalı'), 'dır');
    });

    test("Türkçe'ye özel küçültme: I → ı, İ → i", () {
      // toLowerCase() tek başına 'I' harfini 'i' yapar ve uyum hesabını bozar.
      expect(TurkishMorphology.toLowerTr('IŞIK'), 'ışık');
      expect(TurkishMorphology.toLowerTr('İSTANBUL'), 'istanbul');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Soru eki uyumu — ikame sonrası bozulan uyum', () {
    test('soru eki önceki kelimeye göre yeniden uyumlanır', () {
      // "embesil misin" → "yanlış misin" olurdu; doğrusu "yanlış mısın".
      expect(TurkishMorphology.fixQuestionParticles('yanlış misin'),
          'yanlış mısın');
      expect(TurkishMorphology.fixQuestionParticles('yorgun misin'),
          'yorgun musun');
    });

    test('soru eki olmayan kelimeye dokunulmaz', () {
      expect(TurkishMorphology.fixQuestionParticles('güzel bir gün'),
          'güzel bir gün');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. YERİNDE MOD — nesneyi niteleyen sıfat', () {
    test('kişiye yönelmeyen sıfat yerinde değiştirilir', () async {
      final result = await rewrite('bu karar salakça');
      expect(result, isNotNull);
      // Kullanıcının eleştirisi ("bu karar") korunmalı.
      expect(result!.toLowerCase(), contains('bu karar'));
      expect(result.toLowerCase(), isNot(contains('salak')));
    });

    test('taşınan ek karşılığa aktarılır', () async {
      // "kafasız bir öneri bu" — sıfat, kişiye yönelik değil.
      final result = await rewrite('kafasız bir öneri bu');
      expect(result, isNotNull);
      expect(result!.toLowerCase(), contains('bir öneri bu'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. ÖBEK MODU — kişiye yönelik hakaret', () {
    // Kelime ikamesi burada İLKESEL olarak çalışamaz: "sen tam bir ___sın"
    // kalıbına ne konursa konsun saldırı çerçevesi ayakta kalır.
    test('doğrudan hakaret nötr kalıpla değiştirilir', () async {
      final result = await rewrite('sen tam bir aptalsın');
      expect(result, isNotNull);
      expect(result!.toLowerCase(), contains('katılmıyorum'));
      expect(result.toLowerCase(), isNot(contains('aptal')));
    });

    test('REGRESYON: cümle karşılığı kelime yuvasına sokulmaz', () async {
      // Eski hata: "gerizekalı herif" → "katılmıyorum herif"
      for (final girdi in const [
        'gerizekalı herif',
        'şerefsizsin sen',
        'ne ahmak adamsın',
        'dangalak gibi konuşuyorsun',
      ]) {
        final result = await rewrite(girdi);
        expect(result, isNotNull, reason: girdi);
        // Bozuk çıktının imzası: kalıp, cümlenin ORTASINDA kalan
        // artık kelimelerle birlikte duruyordu.
        expect(result!.toLowerCase(), isNot(matches(r'katılmıyorum \w')),
            reason: 'bozuk çıktı: "$girdi" → "$result"');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('5. Karma metin — iki mod aynı cümlede', () {
    test('yan cümleler ayrı ayrı ele alınır', () async {
      final result = await rewrite('sen tam bir aptalsın, bu karar salakça');
      expect(result, isNotNull);

      // Birinci yan cümle öbek moduyla, ikincisi yerinde modla işlenmeli:
      // eleştirinin konusu ("bu karar") buharlaşmamalı.
      expect(result!.toLowerCase(), contains('katılmıyorum'));
      expect(result.toLowerCase(), contains('bu karar'));
      expect(result.toLowerCase(), isNot(contains('aptal')));
      expect(result.toLowerCase(), isNot(contains('salak')));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('6. Sözleşme — her öneri motordan geçer', () {
    test('öneri her zaman orijinalden daha temiz ölçülür', () async {
      for (final girdi in const [
        'sen tam bir aptalsın',
        'bu karar salakça',
        'gerizekalı herif',
        'salak mısın nesin',
      ]) {
        final analysis = engine.analyze(girdi);
        final suggestion = await suggester.suggest(analysis);
        if (suggestion == null) continue;

        final verification = engine.analyze(suggestion.text);
        expect(verification.toxicity, lessThan(analysis.toxicity),
            reason: '"$girdi" → "${suggestion.text}"');
        expect(suggestion.projectedCivilityScore,
            verification.civilityScore);
      }
    });

    test('temiz metin için öneri üretilmez', () async {
      expect(await rewrite('bu konuda farklı düşünüyorum'), isNull);
    });
  });
}
