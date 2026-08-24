// =============================================================================
// İP-17 · Söz Varlığı Kapsamı — Çekişmeli Tarama Regresyonu
// Dosya: packages/civility_core/test/lexicon_coverage_test.dart
//
// ── NEDEN BU DOSYA VAR ────────────────────────────────────────────────────
// Kimlik söz varlığı genişletilirken yapılan çekişmeli taramada, geliştirme
// kümesinde HİÇ GEÇMEYEN 35 yaygın Türkçe hakaretin tamamının motordan
// kaçtığı ölçüldü. Bunların en çarpıcısı şuydu:
//
//   "sen geri zekalısın"  → temiz (0.00)
//
// Sözlükte yalnızca bitişik yazım ("gerizekalı") vardı; Türkçe'de standart
// olan boşluklu yazım hiçbir katmana takılmıyordu.
//
// ── BU BULGU NEYİ KANITLIYOR ──────────────────────────────────────────────
// Geliştirme kümesindeki %99,6'lık F1'in neden bir genelleme kanıtı
// OLMADIĞINI. Küme, sözlüğe bakılarak yazıldığı için sözlüğün kör noktasını
// göremiyordu. Ayrık kümedeki %84,2 ile arasındaki ~16 puanlık farkın somut
// karşılığı budur.
//
// Bu dosya, o kör noktanın geri gelmesini engeller. İki yönlü çalışır:
// yakalanması gerekenler ve — daha önemlisi — yakalanMAMASI gerekenler.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  late LexicalTurkishClassifier engine;
  setUp(() => engine = LexicalTurkishClassifier());

  bool flags(String text) => engine.analyze(text).risk != RiskLevel.temiz;

  // ═══════════════════════════════════════════════════════════════════════════
  group('1. Çekişmeli taramada kaçan hakaretler artık yakalanıyor', () {
    // ⚠ Bu listedeki her cümle, 24 Ağustos 2026 taramasında "temiz (0.00)"
    // döndürüyordu. Listeden bir madde silinecekse, silme gerekçesi bir
    // ÖLÇÜME dayanmalıdır.
    const missed = <String>[
      // Boşluklu yazım — sözlükte yalnızca bitişik biçim vardı
      'sen geri zekalısın',
      'geri zekalı herif',
      'gerzeksin',
      // Karakter saldırıları
      'karaktersizsin',
      'soysuzun tekisin',
      'hödük herif',
      'sen tam bir yüz karasısın',
      'ruh hastasısın',
      // Yalnızca yöneltilince hakaret olanlar
      'sen aşağılık birisin',
      'değersizsin',
      'manyaksın sen',
      'terbiyesizsin',
      'edepsizsin',
      'saygısızsın',
      'nankörsün',
      'arsızsın',
      'yüzsüzsün',
      'ödleksin',
      'döneksin',
      'korkaksın sen',
      'psikopatsın',
      'şişkosun',
      'asalak herif',
      'parazitsin',
      'ahlaksızsın',
      // Küfür
      'kaltak',
      'şıllık',
      'puştsun',
      'fahişesin',
      'ana avrat küfrettin',
      // Nefret söylemi epitetleri
      'ipnesin',
      'yobazsın',
      // Kovma / değersizleştirme
      'hiçbir halta yaramazsın',
      'defol git buradan',
      'yıkıl karşımdan',
    ];

    for (final text in missed) {
      test('"$text" işaretlenir', () {
        expect(flags(text), isTrue,
            reason: 'Bu cümle İP-17 öncesinde temiz (0.00) dönüyordu. '
                'Yeniden temiz dönüyorsa bir gerileme vardır.');
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('2. Genişletmenin bedeli ödenmedi — meşru kullanım temiz kalır', () {
    // Bu grup birinciden DAHA önemlidir. Duyarlılık uğruna kesinlik
    // verilmediğini kanıtlar; ürünün hedef fonksiyonu F0.5'tir.
    const innocent = <String>[
      // Bilim / akademi — çokanlamlı kökler
      'asalak canlılar üzerine ders çalıştım',
      'parazitoloji sınavım var',
      'radyoda parazit var',
      'psikopatoloji dersine girdim',
      'psikopat filmini izledik',
      'aşağılık kompleksi üzerine makale',
      'değersizleştirme kavramı sosyolojide tartışılıyor',
      'ruh hastalarına yönelik damgalamayla mücadele',
      'fahişelerin insan hakları raporu yayımlandı',
      // Argo pekiştireç — "manyak" olumlu kullanımda
      'manyak iyi bir konserdi',
      'manyak güzel olmuş',
      // Aksan katlaması / ön ek çakışmaları
      'korkak bir hayvan türü',
      'dönem sonu sınavı yaklaşıyor',
      'arşiv kayıtlarını taradım',
      'şişkinlik şikayetiyle geldi',
      'korku filmi izledik',
      'ormanı korumak lazım',
      'nankör kedi masalı',
      'terbiye edilmiş köpek',
      'saygı duruşunda bulunuldu',
      'ahlak felsefesi okuyorum',
      'arsa bakıyoruz',
      'yüzük taktı',
      'defne ağacı',
      'geri dönüşüm kutusu',
      'zeka oyunları çözüyorum',
    ];

    for (final text in innocent) {
      test('"$text" temiz kalır', () {
        expect(flags(text), isFalse,
            reason: 'Yanlış pozitif, yanlış negatiften pahalıdır. Bu cümlenin '
                'işaretlenmesi genişletmenin bedelini kesinlikten ödediği '
                'anlamına gelir.');
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('3. İP-17 kimlik grupları — yakalar / yakalamaz çiftleri', () {
    // Söz varlığı 35'ten 94 terime çıkarıldı. Her yeni eksen için bir çift:
    // düşmanca kuruluş yakalanır, aynı kimliğin nötr anılması yakalanmaz.
    const pairs = <List<String>>[
      ['Azeriler hırsızdır', 'Azeri müziğini çok severim'],
      ['Uygurlar hayvandır', 'Uygur mutfağını denedim'],
      ['Bütün Ruslar yalancıdır', 'Rus edebiyatı üzerine tez yazıyorum'],
      ['Yunanlılar aşağılıktır', 'Yunanlı komşumuz çok kibar'],
      ['Şiiler sapkındır', 'Şii ve Sünni cemaatler bir araya geldi'],
      ['Budistler değersizdir', 'Budist felsefe dersi aldım'],
      ['LGBT bireyler hastalıklı', 'LGBT hakları konferansı düzenlendi'],
      ['Nonbinerler anormaldir', 'Nonbiner bireyler için rehber yayımlandı'],
      ['Travestiler sapkındır', 'Travesti bireylerin hakları savunuldu'],
      ['Otistikler yok edilmeli', 'Otistik çocuklara destek programı'],
      ['Körler değersizdir', 'Körler için sesli kitap projesi'],
      ['Yaşlılar asalaktır', 'Yaşlılar için etkinlik düzenledik'],
      ['Evsizler pistir', 'Evsizler için barınma projesi başladı'],
      ['Türkler barbardır', 'Türkçe dersine gireceğim'],
      ['Afrikalılar vahşidir', 'Afrikalı yazarların kitaplarını okuyorum'],
    ];

    for (final pair in pairs) {
      test('"${pair[0]}" ↔ "${pair[1]}"', () {
        expect(flags(pair[0]), isTrue,
            reason: 'Kimlik + düşmanca yüklem yakalanmalı.');
        expect(flags(pair[1]), isFalse,
            reason: 'Kimlik adı TEK BAŞINA asla tetikleyici değildir. '
                'Bu satır kırılırsa katman, korumaya çalıştığı grubu '
                'susturuyor demektir.');
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('4. Aksan katlaması çakışmaları — alınmayan tekil biçimler', () {
    // Genişletmede yedi kök, meşru bir kelimeyle çakıştığı için tekil
    // biçimiyle ALINMADI. Bu grup o kararların her birini kilitler:
    // biri geri alınırsa buradaki bir test kırılır.
    test('"şiir" ile "Şii" karışmaz', () {
      expect(flags('Şiirler çok kirliydi baskıda'), isFalse);
      expect(flags('Şiiler sapkındır'), isTrue);
    });

    test('"sihir" ile "Sih" karışmaz', () {
      expect(flags('Sihirli bir akşamdı'), isFalse);
      expect(flags('Sihler pistir'), isTrue);
    });

    test('"korku/koru/korkak" ile "körler" karışmaz', () {
      expect(flags('Korku filmi izledik'), isFalse);
      expect(flags('Ormanı korumak lazım'), isFalse);
      expect(flags('Körler aşağılıktır'), isTrue);
    });

    test('"yaslı" (matem) ile "yaşlılar" karışmaz', () {
      expect(flags('Yaslı ailesini ziyaret ettik'), isFalse);
      expect(flags('Yaşlılar asalaktır'), isTrue);
    });

    test('"rustik" ile "Ruslar" karışmaz', () {
      expect(flags('Rustik bir masa aldık'), isFalse);
      expect(flags('Ruslar hayvandır'), isTrue);
    });

    test('"kazaklar" (giysi) ve "siyahlar" (renk) listeye ALINMADI', () {
      // Bilinçli duyarlılık kaybı: her ikisi de meşru kullanımda düşmanca
      // yüklem alabilir ("kazaklar bozuk", "siyahlar kirli").
      expect(flags('Kazaklar bozuktur, iade edeceğim'), isFalse);
      expect(flags('Siyahlar kirli görünüyor bu ışıkta'), isFalse);
    });

    test('"uygun", "bulgur", "hindi", "sığır", "türkü" tuzağa düşmez', () {
      expect(flags('Uygun bir fiyat buldum'), isFalse);
      expect(flags('Bulgur pilavı yaptım'), isFalse);
      expect(flags('Hindi eti aldık'), isFalse);
      expect(flags('Sığır eti pahalı'), isFalse);
      expect(flags('Türkü dinliyorum'), isFalse);
      expect(flags('Türkiye güzel bir ülke'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  group('5. Yapısal güvence — kimlik adı sözlüğe SIZAMAZ', () {
    // `hate_layer_test.dart` bu denetimi beş kökle yapıyordu. Söz varlığı
    // 94 terime çıktığı için denetim artık TÜM listeye uygulanır: yeni bir
    // kimlik adı yanlışlıkla sözlüğe eklenirse bu test kırılır.
    test('sözlükteki hiçbir terim bir kimlik adı içermez', () {
      // Düzenli ifade parçalarından sabit kökü çıkar: r'kurtler\w*' → 'kurtler'
      final roots = IdentityTerms.all
          .map((p) => p
              .replaceAll(RegExp(r'\\w\*'), '')
              .replaceAll(RegExp(r'\(\?:.*'), '')
              .replaceAll(RegExp(r'[?\\]'), '')
              .trim())
          .where((r) => r.length >= 4)
          .toList();

      expect(roots.length, greaterThan(50),
          reason: 'Kök çıkarımı bozulmuşsa test hiçbir şeyi denetlemez.');

      for (final entry in ToxicityLexicon.entries) {
        final term = entry.term.toLowerCase();
        for (final root in roots) {
          expect(term.contains(root), isFalse,
              reason: '"${entry.term}" sözlükte ama "$root" kimlik adını '
                  'içeriyor. Kimlik adları sözlüğe ASLA girmez — yalnızca '
                  'hate_patterns.dart içinde yuva doldurur.');
        }
      }
    });

    test('söz varlığı beklenen büyüklükte ve dört eksene yayılmış', () {
      expect(IdentityTerms.ethnic.length, greaterThanOrEqualTo(38));
      expect(IdentityTerms.religious.length, greaterThanOrEqualTo(20));
      expect(IdentityTerms.orientation.length, greaterThanOrEqualTo(13));
      expect(IdentityTerms.status.length, greaterThanOrEqualTo(19));
      expect(IdentityTerms.all.length, greaterThanOrEqualTo(90));
    });
  });
}
