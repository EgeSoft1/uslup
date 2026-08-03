// =============================================================================
// Yeniden Yazma Servisi — orkestrasyon ve DOĞRULAMA
// Dosya: server/lib/src/rewrite_service.dart
//
// ── SERVİSİN ASIL İDDİASI ─────────────────────────────────────────────────
// Bir dil modeli akıcı ama işe yaramaz bir öneri üretebilir: eleştiriyi
// buharlaştırabilir, farklı bir hakarete çevirebilir, ya da istemi görmezden
// gelebilir. Bunu istemden RİCA ederek garanti edemezsiniz.
//
// Bu servis garanti eder: modelin ürettiği HER öneri, mobil uygulamadakiyle
// BİREBİR AYNI nezaket motorundan tekrar geçirilir. Motorun orijinalden daha
// temiz bulmadığı hiçbir öneri kullanıcıya ulaşmaz. Doğrulama sunucu
// tarafında yapılır çünkü `civility_core` saf Dart'tır ve burada da çalışır.
//
// Sonuç: LLM bir ÖNERİ KAYNAĞIDIR, bir OTORİTE DEĞİLDİR. Karar mercii,
// denetlenebilir ve deterministik olan motordur.
//
// ── AYRICA: SERVİS ASLA METİN LOGLAMAZ ────────────────────────────────────
// Ürünün temel iddiası "metin cihazdan çıkmaz"dır. Kullanıcı açıkça onay
// verdiğinde bu istisnaya girilir; o durumda bile metin diske yazılmaz.
// Log satırlarında uzunluk ve sonuç vardır, içerik yoktur.
// =============================================================================

import 'package:civility_core/civility_core.dart';

import 'claude_client.dart';

// ─── SONUÇ MODELLERİ ─────────────────────────────────────────────────────────

/// Kullanıcıya sunulan, DOĞRULANMIŞ bir öneri.
class VerifiedSuggestion {
  final String text;

  /// Öneriyi üreten kaynak: `cihaz` veya `bulut`.
  final String source;

  /// Neden bu öneri.
  final String rationale;

  /// Motorun öneri üzerinde ölçtüğü nezaket puanı [0–100].
  /// Tahmin değil, ölçüm.
  final int civilityScore;

  const VerifiedSuggestion({
    required this.text,
    required this.source,
    required this.rationale,
    required this.civilityScore,
  });

  Map<String, Object?> toJson() => {
        'text': text,
        'source': source,
        'rationale': rationale,
        'civilityScore': civilityScore,
      };
}

/// Bulut kademesinin ne olduğu — şeffaflık için istemciye aynen döner.
enum CloudStatus {
  /// Bulut çağrıldı ve doğrulanmış öneri üretti.
  basarili,

  /// Metin zaten temizdi; bulut hiç çağrılmadı.
  gereksiz,

  /// Model isteği reddetti.
  reddedildi,

  /// Model ulaşılamadı veya hata verdi.
  kullanilamadi,

  /// Model yanıt verdi ama HİÇBİR öneri doğrulamayı geçemedi.
  dogrulamadaElendi,
}

class RewriteResult {
  /// Girdi metninin çözümlemesi.
  final CivilityAnalysis analysis;

  /// Doğrulanmış öneriler, nezaket puanına göre azalan sırada.
  final List<VerifiedSuggestion> suggestions;

  final CloudStatus cloudStatus;

  /// Bulut kademesi hakkında insan-okunur açıklama.
  final String? cloudDetail;

  /// Yanıtı fiilen üreten model — geri düşme olduysa istenenden farklıdır.
  final String? servedBy;

  /// Modelin ürettiği ama doğrulamayı geçemeyen öneri sayısı.
  /// Bu sayı raporlanabilir bir kalite metriğidir.
  final int rejectedByVerification;

  final Duration elapsed;

  const RewriteResult({
    required this.analysis,
    required this.suggestions,
    required this.cloudStatus,
    required this.elapsed,
    this.cloudDetail,
    this.servedBy,
    this.rejectedByVerification = 0,
  });

  Map<String, Object?> toJson() => {
        'analysis': {
          'civilityScore': analysis.civilityScore,
          'toxicity': double.parse(analysis.toxicity.toStringAsFixed(4)),
          'risk': analysis.risk.name,
          'intervention': analysis.risk.intervention,
          'containsThreat': analysis.containsThreat,
          'findings': analysis.findings
              .map((f) => {
                    'matchedText': f.matchedText,
                    'category': f.category.name,
                    'severity':
                        double.parse(f.adjustedSeverity.toStringAsFixed(4)),
                    'explanation': f.explanation,
                    'start': f.start,
                    'end': f.end,
                  })
              .toList(),
        },
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        'cloud': {
          'status': cloudStatus.name,
          'detail': cloudDetail,
          'servedBy': servedBy,
          'rejectedByVerification': rejectedByVerification,
        },
        'elapsedMs': elapsed.inMilliseconds,
      };
}

// ─── SERVİS ──────────────────────────────────────────────────────────────────

class RewriteService {
  final ToxicityClassifier _engine;
  final LocalRewriteSuggester _local;
  final RewriteModel _cloud;

  /// Bir öneri, orijinalin bu katından uzunsa reddedilir. Modeller
  /// "yardımcı olmaya çalışırken" metni şişirmeye eğilimlidir; kullanıcı
  /// kendi cümlesinin iki katı uzunlukta bir metni göndermez.
  static const double _maxLengthRatio = 2.0;
  static const int _lengthGrace = 40;

  RewriteService({
    required ToxicityClassifier engine,
    required RewriteModel cloud,
  })  : _engine = engine,
        _local = LocalRewriteSuggester(engine),
        _cloud = cloud;

  Future<RewriteResult> rewrite(
    String text, {
    int maxSuggestions = 3,
  }) async {
    final stopwatch = Stopwatch()..start();
    final analysis = _engine.analyze(text);

    // Temiz metin için bulut çağrılmaz. Hem maliyet hem mahremiyet kararı:
    // gereksiz yere hiçbir metin cihazdan çıkmaz.
    if (!analysis.hasFindings) {
      stopwatch.stop();
      return RewriteResult(
        analysis: analysis,
        suggestions: const [],
        cloudStatus: CloudStatus.gereksiz,
        cloudDetail: 'Metin zaten temiz; yeniden yazmaya gerek yok.',
        elapsed: stopwatch.elapsed,
      );
    }

    // Yerel öneri her zaman üretilir. Bulut başarısız olsa bile kullanıcı
    // elleri boş kalmaz — çevrimdışı kademe ürünün tabanıdır.
    final suggestions = <VerifiedSuggestion>[];
    final localSuggestion = await _local.suggest(analysis);
    if (localSuggestion != null) {
      suggestions.add(VerifiedSuggestion(
        text: localSuggestion.text,
        source: 'cihaz',
        rationale: 'Saldırgan ifade nötr karşılığıyla değiştirildi.',
        civilityScore: localSuggestion.projectedCivilityScore,
      ));
    }

    final outcome = await _cloud.propose(text, maxSuggestions: maxSuggestions);

    CloudStatus status;
    String? detail;
    String? servedBy;
    var rejected = 0;

    switch (outcome) {
      case LlmProposed(suggestions: final proposals, servedBy: final served):
        servedBy = served;
        final accepted = <VerifiedSuggestion>[];
        for (final proposal in proposals.take(maxSuggestions)) {
          final verified = _verify(proposal, analysis);
          if (verified == null) {
            rejected++;
          } else {
            accepted.add(verified);
          }
        }
        suggestions.addAll(accepted);
        if (accepted.isEmpty) {
          status = CloudStatus.dogrulamadaElendi;
          detail = 'Model $rejected öneri üretti; hiçbiri doğrulamayı '
              'geçemedi. Yalnızca cihaz üzerindeki öneri sunuluyor.';
        } else {
          status = CloudStatus.basarili;
          if (rejected > 0) {
            detail = '$rejected öneri doğrulamada elendi.';
          }
        }

      case LlmRefused(:final category):
        status = CloudStatus.reddedildi;
        detail = 'Model güvenlik nedeniyle yanıt vermedi'
            '${category != null ? ' ($category)' : ''}. '
            'Cihaz üzerindeki öneri geçerliliğini koruyor.';

      case LlmUnavailable(:final reason):
        status = CloudStatus.kullanilamadi;
        detail = reason;
    }

    // En temiz öneri başa. Kullanıcı listeyi baştan okur.
    suggestions.sort((a, b) => b.civilityScore.compareTo(a.civilityScore));

    stopwatch.stop();
    return RewriteResult(
      analysis: analysis,
      suggestions: suggestions,
      cloudStatus: status,
      cloudDetail: detail,
      servedBy: servedBy,
      rejectedByVerification: rejected,
      elapsed: stopwatch.elapsed,
    );
  }

  /// DOĞRULAMA KAPISI.
  ///
  /// Modelin önerisi burada aynı motordan geçer. Geçemezse kullanıcıya
  /// ulaşmaz. Dört ret gerekçesi:
  ///
  ///   1. Boş veya sadece boşluk.
  ///   2. Orijinalle aynı — model hiçbir şey yapmamış.
  ///   3. Motor onu orijinalden daha temiz bulmuyor. En önemli kural:
  ///      hakareti başka bir hakaretle değiştiren öneriyi yakalar.
  ///   4. Aşırı uzun — model cümleyi şişirmiş.
  ///
  /// `null` dönerse öneri reddedilmiştir.
  VerifiedSuggestion? _verify(
    LlmSuggestion proposal,
    CivilityAnalysis original,
  ) {
    final candidate = proposal.text.trim();
    if (candidate.isEmpty) return null;
    if (candidate == original.text.trim()) return null;

    final maxLength = (original.text.length * _maxLengthRatio).round() + _lengthGrace;
    if (candidate.length > maxLength) return null;

    final verification = _engine.analyze(candidate);
    if (verification.toxicity >= original.toxicity) return null;

    return VerifiedSuggestion(
      text: candidate,
      source: 'bulut',
      rationale: proposal.rationale,
      civilityScore: verification.civilityScore,
    );
  }
}
