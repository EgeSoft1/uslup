// =============================================================================
// Örtük Saldırı Dedektörü
// Dosya: packages/civility_core/lib/src/detect/implicit_detector.dart
//
// Örüntü kataloğunu normalize metin üzerinde çalıştırır ve ham eşleşmeleri
// döndürür. Bağlam değerlendirmesi ve `ToxicityFinding` üretimi BURADA
// YAPILMAZ — o iş motorundur.
//
// Sebep: bu ayrım, dedektörün bağlam katmanına ve bulgu modeline bağımlı
// olmasını engeller. Dedektör "şurada şu kalıp var" der; ne anlama geldiğine
// motor karar verir. Böylece iki katman ayrı ayrı test edilebilir.
// =============================================================================

import 'implicit_patterns.dart';

/// Normalize metinde bulunan tek bir örüntü eşleşmesi.
class ImplicitMatch {
  final ImplicitPattern pattern;

  /// Normalize metindeki başlangıç indeksi (dâhil).
  final int start;

  /// Normalize metindeki bitiş indeksi (hariç).
  final int end;

  const ImplicitMatch({
    required this.pattern,
    required this.start,
    required this.end,
  });
}

class ImplicitDetector {
  final List<ImplicitPattern> patterns;

  ImplicitDetector({List<ImplicitPattern>? patterns})
      : patterns = patterns ?? ImplicitPatterns.all;

  /// Normalize metinde tüm örüntüleri arar.
  ///
  /// Çakışan eşleşmelerde en yüksek şiddetli olan tutulur; motorun genel
  /// tekilleştirmesi zaten çalışır ama burada erken elemek, aynı ifadenin
  /// iki farklı aileye atanmasını (ve kullanıcıya iki gerekçe gösterilmesini)
  /// engeller.
  List<ImplicitMatch> detect(String normalized) {
    if (normalized.trim().isEmpty) return const [];

    final matches = <ImplicitMatch>[];

    for (final pattern in patterns) {
      for (final match in pattern.pattern.allMatches(normalized)) {
        // Boş eşleşme üreten hatalı bir örüntü sonsuz bulgu üretmesin.
        if (match.end <= match.start) continue;
        matches.add(ImplicitMatch(
          pattern: pattern,
          start: match.start,
          end: match.end,
        ));
      }
    }

    if (matches.length < 2) return matches;

    matches.sort((a, b) {
      final bySeverity =
          b.pattern.severity.compareTo(a.pattern.severity);
      if (bySeverity != 0) return bySeverity;
      // Eşit şiddette daha uzun eşleşme daha belirgindir.
      return (b.end - b.start).compareTo(a.end - a.start);
    });

    final kept = <ImplicitMatch>[];
    for (final candidate in matches) {
      final overlaps = kept.any(
        (k) => candidate.start < k.end && candidate.end > k.start,
      );
      if (!overlaps) kept.add(candidate);
    }

    return kept;
  }
}
