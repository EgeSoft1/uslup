// =============================================================================
// Bulguları metnin içinde işaretleyen metin denetleyicisi
// Dosya: mobile/lib/core/civility/civility_text_controller.dart
//
// ── NEDEN VAR ─────────────────────────────────────────────────────────────
// Teknik rapor §2.2, normalizasyon katmanının her karakterin ORİJİNAL
// metindeki indeksini bir offset haritasında sakladığını ve bunun tek
// gerekçesinin "kullanıcıya doğru karakterlerin altını çizebilmek" olduğunu
// söylüyordu.
//
// O gerekçe, altı çizilmediği sürece bir gerekçe değildir. Önceki arayüz
// bulguları yalnızca AŞAĞIDA bir listede sayıyordu; kullanıcı hangi kelimeyi
// yazdığını listeden geri bulmak zorundaydı. Bu sınıf, motorun ürettiği
// [ToxicityFinding.start] / [ToxicityFinding.end] aralıklarını yazarken
// metnin üstünde gösterir.
//
// ── NEDEN buildTextSpan ───────────────────────────────────────────────────
// Flutter'da bir `TextField`'ın içindeki metni parça parça biçimlendirmenin
// desteklenen tek yolu budur. Üstüne katman çizmek (`Stack` + görünmez
// `TextField`) kaydırma, imleç konumu ve seçim davranışını bozar.
// =============================================================================

import 'package:civility_core/civility_core.dart';
import 'package:flutter/material.dart';

/// Şiddet aralığına göre işaretleme rengi seçen geri çağrı.
typedef SeverityColorResolver = Color Function(double adjustedSeverity);

class CivilityTextEditingController extends TextEditingController {
  CivilityTextEditingController({
    super.text,
    required this.resolveColor,
  });

  /// Bulgunun şiddetini renge çevirir. Palet burada okunamaz (widget
  /// bağlamı yok), bu yüzden dışarıdan verilir.
  final SeverityColorResolver resolveColor;

  List<ToxicityFinding> _findings = const [];

  /// İşaretleme açık mı? Kullanıcı kapatabilir — bazı insanlar yazarken
  /// altı çizili metinden rahatsız olur ve bu, özelliği tümden kapatmaktan
  /// iyidir.
  bool _highlightEnabled = true;

  set findings(List<ToxicityFinding> value) {
    if (_sameRanges(_findings, value)) return;
    _findings = value;
    notifyListeners();
  }

  List<ToxicityFinding> get findings => _findings;

  bool get highlightEnabled => _highlightEnabled;

  set highlightEnabled(bool value) {
    if (_highlightEnabled == value) return;
    _highlightEnabled = value;
    notifyListeners();
  }

  /// Aynı aralıklar ve aynı renk basamağı mı? Her tuş vuruşunda
  /// `notifyListeners` çağırmak, zaten `TextField`'ın kendi bildirimiyle
  /// birleşip iki kez yeniden çizime yol açardı.
  ///
  /// Şiddet de karşılaştırılır: aralık aynı kalıp şiddet değiştiğinde
  /// ("aptal" → "aptal!!!" bağırma çarpanı) önceki sürüm eski rengi
  /// göstermeye devam ediyordu.
  static bool _sameRanges(List<ToxicityFinding> a, List<ToxicityFinding> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].start != b[i].start ||
          a[i].end != b[i].end ||
          a[i].adjustedSeverity != b[i].adjustedSeverity) {
        return false;
      }
    }
    return true;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;

    // IME birleştirme (composing) sürerken Flutter'ın kendi altı çizili
    // gösterimi devreye girer. İki işaretlemeyi üst üste bindirmek imleç
    // konumunu bozuyordu; birleştirme sırasında varsayılana bırakılır.
    final composing = value.composing;
    final composingActive =
        withComposing && composing.isValid && !composing.isCollapsed;

    if (!_highlightEnabled || _findings.isEmpty || composingActive) {
      return super
          .buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final ranges = _normalizedRanges(source.length);
    if (ranges.isEmpty) {
      return super
          .buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    final base = style ?? const TextStyle();
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, range.start), style: base));
      }
      final color = resolveColor(range.severity);
      spans.add(TextSpan(
        text: source.substring(range.start, range.end),
        style: base.copyWith(
          // Dalgalı alt çizgi, yazım denetleyicilerinin evrensel dilidir:
          // kullanıcı bunun bir hata değil bir uyarı olduğunu öğrenmek
          // zorunda kalmaz.
          decoration: TextDecoration.underline,
          decorationColor: color,
          decorationStyle: TextDecorationStyle.wavy,
          decorationThickness: 1.6,
          backgroundColor: color.withValues(alpha: 0.12),
        ),
      ));
      cursor = range.end;
    }

    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor), style: base));
    }

    return TextSpan(style: base, children: spans);
  }

  /// Bulguları konuma göre sıralar, metin sınırlarına kırpar ve çakışanları
  /// eler.
  ///
  /// Motor çakışmaları zaten temizliyor (`_deduplicate`) ama sonucu ŞİDDETE
  /// göre sıralı veriyor. Buradaki `substring` çağrıları artan konum ister;
  /// sıralamayı çağıran tarafın hatırlamasına bırakmak, bir gün birinin
  /// aralık dışı hata almasıyla biterdi.
  List<({int start, int end, double severity})> _normalizedRanges(int length) {
    final out = <({int start, int end, double severity})>[];

    for (final f in _findings) {
      final start = f.start.clamp(0, length);
      final end = f.end.clamp(start, length);
      if (end > start) {
        out.add((start: start, end: end, severity: f.adjustedSeverity));
      }
    }

    out.sort((a, b) => a.start.compareTo(b.start));

    final merged = <({int start, int end, double severity})>[];
    for (final r in out) {
      if (merged.isNotEmpty && r.start < merged.last.end) continue;
      merged.add(r);
    }
    return merged;
  }
}
