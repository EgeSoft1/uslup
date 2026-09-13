// =============================================================================
// Kelime listesi filtresi — YALNIZCA KARŞILAŞTIRMA İÇİN
// Dosya: mobile/lib/core/civility/naive_wordlist_filter.dart
//
// Bu sınıf üründe hiçbir karar vermez. Üslup panelindeki bağlam karnesinde,
// "yaygın yaklaşım olsaydı ne olurdu?" sorusunu aynı cümleler üzerinde
// canlı cevaplamak için vardır.
//
// ── ADİL KARŞILAŞTIRMA ŞARTI ──────────────────────────────────────────────
// Karşılaştırma bir saman adam olmamalı. Bu yüzden filtre, Üslup'un
// kendisine verilen avantajların hepsini alır:
//
//   • AYNI sözlük (`ToxicityLexicon.entries`) — kendi kelime listesi değil
//   • AYNI normalizasyon — "$3r3fsiz" → "serefsiz" onda da çözülür
//   • Kısa terimler (≤ 3 harf: "mal", "it", "am") yalnızca TAM eşleşir;
//     "malzeme" ve "itibar" kör bir alt dizi aramasına feda edilmez
//
// Eksik olan tek şey, ürünün katkısının kendisidir: bağlam (olumsuzlama,
// alıntı, öz-ifade), cümle kuruluşu (küfürsüz düşmanlık, nefret yuvası) ve
// Türkçe biçimbilim denetimi. Fark ne çıkarsa, o farkın sebebi budur.
// =============================================================================

import 'package:civility_core/civility_core.dart';

class NaiveWordlistFilter {
  NaiveWordlistFilter._(this._words, this._shortWords, this._phrases);

  factory NaiveWordlistFilter.fromLexicon() {
    const normalizer = TurkishNormalizer();
    final words = <String>{};
    final shortWords = <String>{};
    final phrases = <String>{};

    for (final entry in ToxicityLexicon.entries) {
      final term = normalizer.normalize(entry.term).value.trim();
      if (term.isEmpty) continue;
      if (term.contains(' ')) {
        phrases.add(term);
      } else if (term.length <= 3) {
        shortWords.add(term);
      } else {
        words.add(term);
      }
    }
    return NaiveWordlistFilter._(words, shortWords, phrases);
  }

  static final NaiveWordlistFilter instance = NaiveWordlistFilter.fromLexicon();

  static const _normalizer = TurkishNormalizer();

  final Set<String> _words;
  final Set<String> _shortWords;
  final Set<String> _phrases;

  /// Metinde listedeki bir kelime ya da öbek geçiyor mu?
  bool flags(String text) => match(text) != null;

  /// İlk eşleşen liste terimi; yoksa `null`.
  String? match(String text) {
    final normalized = _normalizer.normalize(text);

    // Motorun kullandığı İKİ varyant da denenir: `value` tekrarları ve
    // aksanları çözer, `aggressive` ek olarak leet karakterlerini ("$3r3f")
    // harfe çevirir. Filtre yalnızca birini görseydi Üslup'a haksız bir
    // gizleme avantajı tanınmış olurdu.
    for (final variant in {normalized.value, normalized.aggressive}) {
      for (final phrase in _phrases) {
        if (variant.contains(phrase)) return phrase;
      }

      final tokens =
          variant.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty);
      for (final token in tokens) {
        if (_shortWords.contains(token)) return token;
        for (final word in _words) {
          // Kök + ek: "aptal" → "aptalsın". Yaygın filtrelerin yaptığı budur.
          if (token.startsWith(word)) return word;
        }
      }
    }
    return null;
  }
}
