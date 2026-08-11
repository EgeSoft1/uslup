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

import 'hate_patterns.dart';
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

  /// Bir göndergenin öncülüne uzanabileceği en fazla karakter mesafesi.
  ///
  /// Yaklaşık bir-iki cümle. Sınırsız olsaydı, uzun bir metnin başındaki
  /// kimlik terimi sonundaki her zamiri "kimlik göndergesi" yapardı; oysa
  /// gönderge yakınlıkla çalışır. Türkçe ortalama cümle uzunluğu göz önüne
  /// alınarak seçilmiştir ve bir kesinlik mekanizmasıdır.
  static const int _antecedentWindow = 160;

  /// Metindeki kimlik terimlerinin başlangıç konumları (artan sırada).
  List<int> _identityMentions(String normalized) {
    final positions = <int>[];
    for (final m in IdentityTerms.mention.allMatches(normalized)) {
      positions.add(m.start);
    }
    return positions;
  }

  /// [matchStart] konumundan önce, pencere içinde bir kimlik terimi var mı?
  bool _hasAntecedentBefore(List<int> antecedents, int matchStart) {
    for (final position in antecedents) {
      if (position >= matchStart) break; // liste sıralı: gerisi hep ileride
      if (matchStart - position <= _antecedentWindow) return true;
    }
    return false;
  }

  /// Normalize metinde tüm örüntüleri arar.
  ///
  /// Çakışan eşleşmelerde en yüksek şiddetli olan tutulur; motorun genel
  /// tekilleştirmesi zaten çalışır ama burada erken elemek, aynı ifadenin
  /// iki farklı aileye atanmasını (ve kullanıcıya iki gerekçe gösterilmesini)
  /// engeller.
  List<ImplicitMatch> detect(String normalized) {
    if (normalized.trim().isEmpty) return const [];

    final matches = <ImplicitMatch>[];

    // Gönderge yuvalı eşleşmeler burada bekletilir. Öncül taraması ANCAK
    // buraya bir şey düşerse yapılır.
    //
    // Sıcak yol maliyeti sıfır olmalıdır: kimlik söz varlığı ~45 terimlik
    // bir almaşıktır ve her tuş vuruşunda metnin tamamını taramak, hiçbir
    // zamir geçmeyen cümlelerin ezici çoğunluğu için saf israftır.
    List<ImplicitMatch>? pendingAnaphoric;

    for (final pattern in patterns) {
      for (final match in pattern.pattern.allMatches(normalized)) {
        // Boş eşleşme üreten hatalı bir örüntü sonsuz bulgu üretmesin.
        if (match.end <= match.start) continue;

        final candidate = ImplicitMatch(
          pattern: pattern,
          start: match.start,
          end: match.end,
        );

        if (pattern.requiresIdentityAntecedent) {
          (pendingAnaphoric ??= <ImplicitMatch>[]).add(candidate);
        } else {
          matches.add(candidate);
        }
      }
    }

    // ── GÖNDERGE KAPISI ──────────────────────────────────────────────────────
    // Zamir yuvalı örüntü, ancak eşleşmenin ÖNÜNDE ve erişim penceresi içinde
    // gerçek bir kimlik terimi varsa geçer. Öncül yoksa cümle kimin hedef
    // alındığını söylemiyor demektir; çıkarım için dayanak yoktur.
    if (pendingAnaphoric != null) {
      final antecedents = _identityMentions(normalized);
      for (final candidate in pendingAnaphoric) {
        if (_hasAntecedentBefore(antecedents, candidate.start)) {
          matches.add(candidate);
        }
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
