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

  /// Nefret örüntülerinin ucuz ön kapılardan geçirilip geçirilmeyeceği.
  ///
  /// Üründe her zaman açıktır. Kapalı hâli YALNIZCA doğrulama içindir:
  /// `test/detector_gate_test.dart`, kapılı ve kapısız dedektörün bütün
  /// etiketli örneklerde aynı bulguları ürettiğini kanıtlar. Kapı bir
  /// hızlandırmadır; davranışı değiştirmesi bir hatadır.
  final bool fastGate;

  ImplicitDetector({List<ImplicitPattern>? patterns, this.fastGate = true})
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

    // ── KİMLİK KAPISI (İP-23 · gecikme optimizasyonu) ───────────────────────
    // Nefret örüntülerinin TAMAMI kimlik yuvası ya da gönderge yuvası taşır ve
    // ikisi de metinde en az bir kimlik teriminin geçmesini şart koşar. Yuva
    // `(?:t1|t2|…|t94)` biçiminde 94 almaşıktır ve her örüntüde `_gap(3)` gibi
    // geri izleme üretebilen bir boşlukla birleşir.
    //
    // Kapı olmadan, kimlik terimi HİÇ GEÇMEYEN bir cümlede bile bu maliyet
    // on beş kez ödeniyordu. Ölçüm (İP-23) bunu sayıya çevirdi: söz varlığı
    // 35'ten 94 terime çıkınca p99 gecikmesi 193 µs'den 1260 µs'ye tırmandı.
    //
    // Kapı, aynı almaşığı TEK BİR düz taramayla önceden çalıştırır. Kimlik
    // yoksa on beş örüntü hiç denenmez. Sonuç kümesi DEĞİŞMEZ — atlanan
    // örüntülerin hiçbiri kimliksiz metinde zaten eşleşemezdi.
    //
    // Değişmez: her nefret örüntüsünün kimliği `HatePatterns.idPrefix` ile
    // başlar. `test/hate_layer_test.dart` bunu yapısal olarak denetler; yeni
    // bir nefret örüntüsü başka bir önekle eklenirse test kırılır ve kapı
    // sessizce onu atlamaz.
    //
    // İkinci kapı düşmanca sözcük kapısıdır: kimlik terimi geçse bile
    // düşmanca hiçbir sözcük yoksa örüntüler yine atlanır. Gerçek hayatta
    // insanlar kimliklerden çoğunlukla nötr bağlamda söz ettiği için en çok
    // kazandıran kapı budur. Gerekçe: `HatePatterns.hostileGate`.
    List<int>? identityMentions;
    bool? hostilePresent;

    for (final pattern in patterns) {
      if (fastGate && pattern.id.startsWith(HatePatterns.idPrefix)) {
        identityMentions ??= _identityMentions(normalized);
        if (identityMentions.isEmpty) continue;

        hostilePresent ??= HatePatterns.hostileGate.hasMatch(normalized);
        if (!hostilePresent) continue;
      }

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
      // Kimlik kapısı bu taramayı zaten yapmış olabilir; iki kez taramak
      // gereksizdir. Kapıya hiç girilmediyse (nefret örüntüsü yoksa) burada
      // hesaplanır.
      final antecedents = identityMentions ??= _identityMentions(normalized);
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
