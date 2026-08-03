// =============================================================================
// NSosyal Sosyal YZ — Konum Korumalı Tokenizer
// Dosya: packages/civility_core/lib/src/normalization/tokenizer.dart
//
// Basit bir `split(' ')` yeterli DEĞİLDİR: kullanıcıya hangi kelimenin
// sorunlu olduğunu göstermek için her token'ın metin içindeki konumunu
// bilmemiz gerekir. Bu tokenizer konum bilgisini korur.
// =============================================================================

/// Metin içindeki konumu bilinen tek bir kelime.
class Token {
  /// Token'ın kanonik (normalize edilmiş) metni.
  final String text;

  /// Normalize metin içindeki başlangıç indeksi (dâhil).
  final int start;

  /// Normalize metin içindeki bitiş indeksi (hariç).
  final int end;

  /// Token'ın cümledeki sırası (0 tabanlı).
  final int position;

  const Token({
    required this.text,
    required this.start,
    required this.end,
    required this.position,
  });

  int get length => text.length;

  @override
  String toString() => 'Token("$text" @$start-$end)';
}

/// Boşluk sınırlarına göre bölen, konum koruyan tokenizer.
///
/// Normalizasyon katmanı noktalama işaretlerini zaten boşluğa indirgediği
/// için burada ek bir noktalama kuralına gerek yoktur.
class Tokenizer {
  const Tokenizer();

  List<Token> tokenize(String normalized) {
    final tokens = <Token>[];
    int i = 0;
    int position = 0;

    while (i < normalized.length) {
      // Boşlukları atla
      while (i < normalized.length && normalized[i] == ' ') {
        i++;
      }
      if (i >= normalized.length) break;

      final start = i;
      while (i < normalized.length && normalized[i] != ' ') {
        i++;
      }

      tokens.add(Token(
        text: normalized.substring(start, i),
        start: start,
        end: i,
        position: position++,
      ));
    }

    return tokens;
  }
}
