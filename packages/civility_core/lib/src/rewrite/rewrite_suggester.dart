// =============================================================================
// NSosyal Sosyal YZ — Yeniden Yazma Önerisi
// Dosya: packages/civility_core/lib/src/rewrite/rewrite_suggester.dart
//
// Tespit tek başına yetmez. Kullanıcıya "bu mesaj saldırgan" demek,
// onu susturmaktan ibarettir — söylemek istediği şey hâlâ orada durur.
// Ürünün amacı SUSTURMAK değil, AYNI FİKRİ SALDIRMADAN söyletmektir.
//
//   "sen tam bir aptalsın"  →  "bu konuda sana katılmıyorum"
//
// TEK KADEMELİ TASARIM — CİHAZ ÜSTÜ:
//   • `LocalRewriteSuggester` — cihazda, deterministik, çevrimdışı, 0 ms.
//     Metin telefondan HİÇ çıkmaz. Her zaman çalışır.
//
// ── NEDEN BULUT KADEMESİ YOK (3 Ağustos 2026 kararı) ──────────────────────
// Önceki sürümde ikinci bir kademe vardı: metni bir dil modeline gönderip
// daha akıcı bir alternatif isteyen sunucu tarafı yeniden yazıcı. Kaldırıldı.
//
// Gerekçe ürünün kendi tezidir. "Metin cihazdan çıkmaz" iddiası, istisnası
// olan bir iddiadan çok daha güçlüdür — onay diyaloğuyla korunan bir istisna
// bile açıklanması gereken bir yüzey yaratır. Üçüncü taraf bir API'ye
// bağımlı olmamak ayrıca maliyeti, anahtar yönetimini ve kota riskini
// tamamen ortadan kaldırır.
//
// Bunun bedeli akıcılıktır ve bilinçli olarak kabul edilmiştir: yeniden
// yazma kalitesini bir dil modelinden değil, BU DOSYADAKİ Türkçe'ye özel
// dönüşümlerden almak gerekiyor. Sınır burada görünür kalsın diye ölçüm
// altyapısı (`bin/evaluate.dart`) korunmuştur.
// =============================================================================

import '../civility_engine.dart';
import '../lexicon/toxicity_lexicon.dart';

/// Yeniden yazma önerisi.
class RewriteSuggestion {
  /// Önerilen yeni metin.
  final String text;

  /// Öneriyi üreten kaynak — kullanıcıya şeffaflık için gösterilir.
  final String source;

  /// Önerinin uygulanmasıyla beklenen nezaket puanı.
  final int projectedCivilityScore;

  const RewriteSuggestion({
    required this.text,
    required this.source,
    required this.projectedCivilityScore,
  });
}

/// Yeniden yazma sağlayıcı sözleşmesi.
abstract class RewriteSuggester {
  /// Çözümleme sonucuna göre daha nazik bir alternatif üretir.
  /// Öneri üretilemiyorsa `null` döner.
  Future<RewriteSuggestion?> suggest(CivilityAnalysis analysis);
}

/// Cihaz üzerinde çalışan deterministik yeniden yazıcı.
///
/// Yaklaşım — üç dönüşüm:
///   1. Saldırgan ifadeyi nötr karşılığıyla değiştir ya da tamamen çıkar.
///   2. Bağırmayı (tümü büyük harf) normal yazıma indir.
///   3. Noktalama patlamasını ("!!!") tek işarete indir.
///
/// Sonuç her zaman akıcı olmayabilir; bilinen sınır budur ve iyileştirme
/// yönü morfoloji farkındalığıdır (bkz. dosya başlığı).
class LocalRewriteSuggester implements RewriteSuggester {
  final ToxicityClassifier _classifier;

  const LocalRewriteSuggester(this._classifier);

  /// Kategori bazlı genel yumuşatıcılar — sözlükte özel karşılık
  /// tanımlanmamış terimler için kullanılır.
  static const Map<ToxicityCategory, String> _categoryFallback = {
    ToxicityCategory.hakaret: 'katılmıyorum',
    ToxicityCategory.asagilama: 'farklı düşünüyorum',
    ToxicityCategory.kufur: '',
    ToxicityCategory.tehdit: '',
    ToxicityCategory.nefret: '',
    ToxicityCategory.taciz: '',
  };

  @override
  Future<RewriteSuggestion?> suggest(CivilityAnalysis analysis) async {
    if (!analysis.hasFindings) return null;

    // Bulguları konuma göre TERSTEN sırala. Metni sondan başa doğru
    // değiştirmek, henüz işlenmemiş bulguların indekslerinin kaymasını önler.
    final ordered = List<ToxicityFinding>.from(analysis.findings)
      ..sort((a, b) => b.start.compareTo(a.start));

    var rewritten = analysis.text;

    for (final finding in ordered) {
      // Bulgu kendi nötr karşılığını taşır. Sözlüğe geri dönmeye gerek yok —
      // bu sayede edimbilimsel örüntü bulguları ("senin gibiler" → "sen") de
      // sözlük bulguları kadar düzgün yeniden yazılır.
      final replacement = finding.neutralAlternative ??
          _categoryFallback[finding.category] ??
          '';

      rewritten = rewritten.replaceRange(finding.start, finding.end, replacement);
    }

    rewritten = _normalizeShouting(rewritten);
    rewritten = _collapsePunctuation(rewritten);
    rewritten = _tidyWhitespace(rewritten);

    // Öneri, orijinalle aynıysa veya boşaldıysa değersizdir.
    if (rewritten.trim().isEmpty) return null;
    if (rewritten.trim() == analysis.text.trim()) return null;

    // Önerinin gerçekten daha iyi olduğunu DOĞRULA. Motoru öneri üzerinde
    // tekrar çalıştırmak, kötü bir önerinin kullanıcıya gitmesini engeller.
    final verification = _classifier.analyze(rewritten);
    if (verification.toxicity >= analysis.toxicity) return null;

    return RewriteSuggestion(
      text: rewritten,
      source: 'Cihaz üzerinde (çevrimdışı)',
      projectedCivilityScore: verification.civilityScore,
    );
  }

  /// Tümü büyük harfle yazılmış metni normal yazıma indirir.
  /// Kısa metinler ("OK", "TAMAM") bağırma sayılmaz.
  String _normalizeShouting(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-ZçğıöşüÇĞİÖŞÜ]'), '');
    if (letters.length < 8) return text;

    final upperCount =
        letters.split('').where((c) => c == _turkishUpper(c)).length;
    if (upperCount / letters.length < 0.7) return text;

    // Türkçe farkındalıklı küçültme: 'I' → 'ı', 'İ' → 'i'
    final lowered = text
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase();

    if (lowered.isEmpty) return lowered;
    return lowered[0].toUpperCase() + lowered.substring(1);
  }

  String _turkishUpper(String ch) {
    if (ch == 'i') return 'İ';
    if (ch == 'ı') return 'I';
    return ch.toUpperCase();
  }

  /// "!!!" → "!",  "???" → "?"
  String _collapsePunctuation(String text) {
    return text
        .replaceAll(RegExp(r'!{2,}'), '!')
        .replaceAll(RegExp(r'\?{2,}'), '?');
  }

  /// Kelime çıkarılınca oluşan çift boşluk ve sarkan noktalamayı temizler.
  String _tidyWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'\s+([,.!?])'), r'$1')
        .trim();
  }
}
