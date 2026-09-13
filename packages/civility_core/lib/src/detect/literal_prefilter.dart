// =============================================================================
// Değişmez parça ön filtresi
// Dosya: packages/civility_core/lib/src/detect/literal_prefilter.dart
//
// ── NEDEN VAR ─────────────────────────────────────────────────────────────
// Kapı kelimesi olmayan örüntüler (kuruluş katmanının ~130 ifadesi) her tuş
// vuruşunda metnin TAMAMI üzerinde çalışıyordu. Ölçüm: 4.800 karakterlik
// bir metinde motorun 29 ms'sinin ~18 ms'si buydu, oysa sıradan bir metinde
// bu ifadelerin hemen hiçbiri eşleşmez.
//
// Deyim katmanının kapı kelimeleri elle yazılır (`ImplicitPattern.gateWord`).
// Burada elle yazmak hem ~130 kez tekrar hem de sessiz bir hata kaynağı
// olurdu: bir kapı kelimesi yanlış seçilirse örüntü o cümlede hiç denenmez.
// Bu yüzden kapı İFADENİN KENDİSİNDEN türetilir.
//
// ── NE ÇIKARIR ────────────────────────────────────────────────────────────
// Bir düzenli ifade için öyle bir S kümesi ki: ifadenin HER eşleşmesi S'nin
// en az bir elemanını içerir. Metinde S'nin hiçbir elemanı yoksa ifade o
// metinde eşleşemez ve hiç çalıştırılmaz.
//
//   \b(senden|sizden) adam olmaz\b     →  {" adam olmaz"}  (en seçici parça)
//   \bkim sordu\b|\bsana mi sorduk\b   →  {"kim sordu", "sana mi sorduk"}
//   \b(sen )?once kendi(ne|nize) bak   →  {"once kendine bak", "once kendinize bak"}
//
// (RE2'nin ön filtre yöntemiyle aynı fikir; burada yalnızca ürünün kullandığı
// sözdizimi desteklenir.)
//
// ── GÜVENLİK İLKESİ ───────────────────────────────────────────────────────
// Çıkarıcının yanılabileceği tek yön "kısıt yok" demektir; o da yalnızca
// hızdan kaybettirir. Anlamadığı her yapıda (Unicode kipi, geri başvuru,
// tanımadığı kaçış) `null` döner ve örüntü eskisi gibi her zaman denenir.
// Buna rağmen kapı bir hızlandırmadır ve sonucu değiştirmesi bir hatadır:
// `test/detector_gate_test.dart` kapılı ve kapısız dedektörü karşılaştırır.
//
// ── BÜYÜK/KÜÇÜK HARF ──────────────────────────────────────────────────────
// Örüntüler `caseSensitive: false` ve Unicode kipi kapalı. Bu kipte bir ASCII
// harfi yalnızca kendi ASCII büyük/küçük karşılığıyla eşleşir (ECMAScript
// Canonicalize: ASCII olmayan bir karakter ASCII'ye katlanamaz). Bu yüzden
// parçalar küçük harfe indirilir ve KÜÇÜK HARFE İNDİRİLMİŞ metinde aranır.
// ASCII olmayan bir harf parçaya alınmaz; bilinmeyen karakter sayılır.
// =============================================================================

/// Bir düzenli ifadenin eşleşmelerinde zorunlu olarak geçen parçalar.
abstract final class LiteralPrefilter {
  /// [pattern]'in her eşleşmesinin içerdiği parçalardan oluşan küme — en az
  /// biri geçmek zorundadır. Parçalar küçük harftir.
  ///
  /// `null`: güvenli bir küme çıkarılamadı; örüntü her metinde denenmeli.
  static Set<String>? requiredAnyOf(RegExp pattern) {
    // Büyük/küçük harfe duyarlı ya da Unicode kipindeki ifadelerde katlama
    // kuralları farklıdır; ürün bunları kullanmıyor, desteklenmez.
    if (pattern.isCaseSensitive || pattern.isUnicode) return null;
    try {
      final parser = _Parser(pattern.pattern);
      final info = parser.parseAll();
      return _best(info.required, _fromExact(info.exact));
    } on _Unsupported {
      return null;
    }
  }

}

/// Bir örüntü listesinin bütün zorunlu parçalarını TEK geçişte arayan dizin.
///
/// ── NEDEN TEK GEÇİŞ ───────────────────────────────────────────────────────
/// İlk sürüm her parçayı `String.contains` ile ayrı ayrı arıyordu: yüzlerce
/// parça × metnin tamamı. Sonuç ölçüldü ve hızlandırma YAVAŞLATMA çıktı
/// (kısa cümlede 273 µs → 975 µs). Aho–Corasick otomatı bütün parçaları
/// metnin tek bir taramasında bulur; maliyet parça sayısından bağımsızdır.
///
/// Parçalar yalnızca ASCII'dir (bkz. `_Parser._literal`). Tarama ASCII
/// harfleri yerinde küçültür; büyük/küçük karşılığı ASCII olan dört Unicode
/// harfi (İ ı ſ K) ASCII'ye indirir — düzenli ifade motoru bunları eşlese de
/// eşlemese de kapı açık kalır, yani fazladan denemek güvenli taraftır.
/// Diğer her ASCII dışı karakter hiçbir parçada geçmediği için otomatı başa
/// döndürür.
class LiteralIndex {
  LiteralIndex(List<RegExp> patterns) {
    final partIds = <String, int>{};
    for (final p in patterns) {
      final required = LiteralPrefilter.requiredAnyOf(p);
      _patternParts.add(required == null
          ? null
          : [for (final s in required) partIds.putIfAbsent(s, () => partIds.length)]);
    }
    _partCount = partIds.length;
    partIds.forEach(_insert);
    _buildFailureLinks();
  }

  /// Örüntü sırasıyla, her örüntünün parça kimlikleri; kısıt yoksa null.
  final List<List<int>?> _patternParts = [];
  late final int _partCount;

  // Otomat: düğüm başına geçişler, başarısızlık bağı ve çıktılar.
  final List<Map<int, int>> _goto = [<int, int>{}];
  final List<int> _fail = [0];
  final List<List<int>?> _out = [null];

  /// Kökten ASCII geçişleri — sıcak yol, harita araması yok.
  final List<int> _rootAscii = List<int>.filled(128, 0);

  void _insert(String part, int id) {
    var node = 0;
    for (final c in part.codeUnits) {
      final next = _goto[node][c];
      if (next != null) {
        node = next;
        continue;
      }
      _goto.add(<int, int>{});
      _fail.add(0);
      _out.add(null);
      final created = _goto.length - 1;
      _goto[node][c] = created;
      node = created;
    }
    (_out[node] ??= <int>[]).add(id);
  }

  void _buildFailureLinks() {
    final queue = <int>[];
    _goto[0].forEach((c, child) {
      _fail[child] = 0;
      queue.add(child);
      if (c < 128) _rootAscii[c] = child;
    });
    for (var head = 0; head < queue.length; head++) {
      final node = queue[head];
      _goto[node].forEach((c, child) {
        queue.add(child);
        var f = _fail[node];
        while (f != 0 && !_goto[f].containsKey(c)) {
          f = _fail[f];
        }
        final target = _goto[f][c];
        _fail[child] = (target != null && target != child) ? target : 0;
        final inherited = _out[_fail[child]];
        if (inherited != null) {
          (_out[child] ??= <int>[]).addAll(inherited);
        }
      });
    }
  }

  static int _fold(int c) {
    if (c >= 0x41 && c <= 0x5A) return c + 0x20; // A-Z
    if (c < 0x80) return c;
    switch (c) {
      case 0x0130: // İ
      case 0x0131: // ı
        return 0x69; // i
      case 0x017F: // ſ
        return 0x73; // s
      case 0x212A: // K (Kelvin)
        return 0x6B; // k
    }
    return -1;
  }

  /// [text]'i tarar; dönen nesne hangi örüntünün DENENMESİ gerektiğini söyler.
  LiteralHits scan(String text) {
    final present = List<bool>.filled(_partCount, false);
    var state = 0;
    for (var i = 0; i < text.length; i++) {
      final c = _fold(text.codeUnitAt(i));
      if (c < 0) {
        state = 0;
        continue;
      }
      if (state == 0) {
        state = _rootAscii[c];
      } else {
        var next = _goto[state][c];
        while (next == null && state != 0) {
          state = _fail[state];
          next = state == 0 ? _rootAscii[c] : _goto[state][c];
        }
        state = next ?? 0;
      }
      final out = _out[state];
      if (out != null) {
        for (final id in out) {
          present[id] = true;
        }
      }
    }
    return LiteralHits._(this, present);
  }
}

/// Tek bir metnin taraması.
class LiteralHits {
  LiteralHits._(this._index, this._present);

  final LiteralIndex _index;
  final List<bool> _present;

  /// [patternIndex] sıradaki örüntü bu metinde eşleşebilir mi?
  /// `false` kesindir; `true` yalnızca "denenmeli" demektir.
  bool mayMatch(int patternIndex) {
    final parts = _index._patternParts[patternIndex];
    if (parts == null) return true;
    for (final id in parts) {
      if (_present[id]) return true;
    }
    return false;
  }
}

/// Bir kesin kümenin (cross product) büyüyebileceği en fazla eleman.
const int _maxExact = 64;

/// Zorunlu parça kümesinin büyüyebileceği en fazla eleman.
const int _maxRequired = 128;

class _Unsupported implements Exception {
  const _Unsupported();
}

/// Bir alt ifadenin bilgisi.
class _Info {
  const _Info(this.exact, this.required);

  /// Alt ifadenin eşleşebileceği BÜTÜN dizgiler; bilinmiyorsa null.
  final Set<String>? exact;

  /// Alt ifadenin her eşleşmesinin içerdiği parçalar; kısıt yoksa null.
  final Set<String>? required;

  static const _Info empty = _Info({''}, null);
  static const _Info unknown = _Info(null, null);
}

/// Kesin küme zorunlu parça kümesine çevrilir: boş dizgi içeriyorsa kısıt
/// yoktur (alt ifade hiçbir şey tüketmeden eşleşebilir).
Set<String>? _fromExact(Set<String>? exact) {
  if (exact == null || exact.contains('')) return null;
  return _minimize(exact);
}

/// Başka bir elemanı içeren eleman gereksizdir: "capiniz" geçiyorsa "capin"
/// de geçer, "en az biri" koşulu için kısa olan yeter.
Set<String> _minimize(Set<String> parts) {
  final sorted = parts.toList()..sort((a, b) => a.length.compareTo(b.length));
  final kept = <String>[];
  for (final p in sorted) {
    if (!kept.any(p.contains)) kept.add(p);
  }
  return kept.toSet();
}

/// İki kısıttan daha seçici olanı: en kısa parçası daha uzun olan;
/// eşitlikte daha az parçalı olan.
Set<String>? _best(Set<String>? a, Set<String>? b) {
  if (a == null) return b;
  if (b == null) return a;
  int shortest(Set<String> s) =>
      s.fold(1 << 30, (m, e) => e.length < m ? e.length : m);
  final sa = shortest(a), sb = shortest(b);
  if (sa != sb) return sa > sb ? a : b;
  return a.length <= b.length ? a : b;
}

Set<String>? _cross(Set<String>? a, Set<String>? b) {
  if (a == null || b == null) return null;
  if (a.length * b.length > _maxExact) return null;
  return {
    for (final x in a)
      for (final y in b) '$x$y',
  };
}

/// ECMAScript düzenli ifade sözdiziminin ürünün kullandığı alt kümesi için
/// özyinelemeli iniş ayrıştırıcısı.
class _Parser {
  _Parser(this.src);

  final String src;
  int pos = 0;

  bool get _done => pos >= src.length;
  String get _peek => src[pos];

  _Info parseAll() {
    final info = _alternation();
    if (!_done) throw const _Unsupported(); // eşleşmeyen ')'
    return info;
  }

  // alternation := sequence ('|' sequence)*
  _Info _alternation() {
    final branches = <_Info>[_sequence()];
    while (!_done && _peek == '|') {
      pos++;
      branches.add(_sequence());
    }
    if (branches.length == 1) return branches.first;

    Set<String>? exact = <String>{};
    Set<String>? required = <String>{};
    for (final b in branches) {
      exact = (exact == null || b.exact == null) ? null : {...exact, ...b.exact!};
      if (exact != null && exact.length > _maxExact) exact = null;

      final effective = _best(b.required, _fromExact(b.exact));
      required = (required == null || effective == null)
          ? null
          : {...required, ...effective};
      if (required != null && required.length > _maxRequired) required = null;
    }
    return _Info(exact, required == null ? null : _minimize(required));
  }

  // sequence := (atom quantifier?)*
  _Info _sequence() {
    Set<String>? run = {''};
    var allExact = true;
    Set<String>? best;

    while (!_done && _peek != '|' && _peek != ')') {
      final item = _quantified(_atom());
      best = _best(best, item.required);

      final joined = _cross(run, item.exact);
      if (joined != null) {
        run = joined;
      } else {
        // Kesin parça zinciri koptu: şimdiye kadarki zincir bir aday.
        allExact = false;
        best = _best(best, _fromExact(run));
        run = item.exact;
      }
    }
    best = _best(best, _fromExact(run));
    return _Info(allExact ? run : null, best);
  }

  _Info _quantified(_Info atom) {
    if (_done) return atom;
    final c = _peek;

    int? min;
    if (c == '?' || c == '*') {
      pos++;
      min = 0;
    } else if (c == '+') {
      pos++;
      min = 1;
    } else if (c == '{') {
      final m = RegExp(r'\{(\d+)(,(\d*))?\}').matchAsPrefix(src, pos);
      if (m == null) return atom; // düz '{' karakteri — atom olarak işlendi
      pos = m.end;
      min = int.parse(m.group(1)!);
      final exactCount = m.group(2) == null;
      if (min == 1 && exactCount) {
        _skipLazy();
        return atom;
      }
    } else {
      return atom;
    }
    _skipLazy();

    if (min == 0) {
      // Hiç tekrarlanmayabilir: kısıt yok. '?' için kesin küme korunabilir.
      final optionalExact =
          (c == '?' && atom.exact != null) ? {...atom.exact!, ''} : null;
      return _Info(optionalExact, null);
    }
    // En az bir kez: atomun kısıtı geçerli, kesin küme artık bilinmez.
    return _Info(null, _best(atom.required, _fromExact(atom.exact)));
  }

  void _skipLazy() {
    if (!_done && _peek == '?') pos++;
  }

  _Info _atom() {
    final c = _peek;
    switch (c) {
      case '(':
        return _group();
      case '[':
        return _charClass();
      case '.':
        pos++;
        return _Info.unknown;
      case '^':
      case r'$':
        pos++;
        return _Info.empty;
      case r'\':
        return _escape();
      case '*':
      case '+':
      case '?':
        throw const _Unsupported(); // başıboş niceleyici
      default:
        pos++;
        return _literal(c);
    }
  }

  _Info _literal(String c) {
    final code = c.codeUnitAt(0);
    if (code >= 0x80) return _Info.unknown; // ASCII dışı: katlama belirsiz
    return _Info({c.toLowerCase()}, null);
  }

  _Info _group() {
    pos++; // '('
    var lookaround = false;
    if (src.startsWith('?:', pos)) {
      pos += 2;
    } else if (src.startsWith('?=', pos) || src.startsWith('?!', pos)) {
      pos += 2;
      lookaround = true;
    } else if (src.startsWith('?<=', pos) || src.startsWith('?<!', pos)) {
      pos += 3;
      lookaround = true;
    } else if (src.startsWith('?<', pos)) {
      final close = src.indexOf('>', pos);
      if (close < 0) throw const _Unsupported();
      pos = close + 1; // adlandırılmış grup
    } else if (!_done && _peek == '?') {
      throw const _Unsupported();
    }

    final inner = _alternation();
    if (_done || _peek != ')') throw const _Unsupported();
    pos++;
    // Bakış grupları hiçbir şey tüketmez. İçerikleri metinde geçmek zorunda
    // olsa da (olumlu bakışta) olumsuz bakışla ayırmamak için kısıt sayılmaz.
    return lookaround ? _Info.empty : inner;
  }

  _Info _charClass() {
    pos++; // '['
    final negated = !_done && _peek == '^';
    if (negated) pos++;

    final chars = <String>{};
    var simple = !negated;
    var first = true;
    while (true) {
      if (_done) throw const _Unsupported();
      final c = _peek;
      if (c == ']') {
        // ECMAScript'te `[]` boş sınıftır (PCRE'deki gibi düz ']' değil).
        if (first) throw const _Unsupported();
        pos++;
        break;
      }
      first = false;
      if (c == r'\') {
        pos++;
        if (_done) throw const _Unsupported();
        final e = _peek;
        pos++;
        if (RegExp(r'[A-Za-z0-9]').hasMatch(e)) {
          simple = false; // \w, \d, \s, \uXXXX … — sınıfı genişletir
          if (e == 'u') pos = (pos + 4).clamp(0, src.length);
          if (e == 'x') pos = (pos + 2).clamp(0, src.length);
        } else {
          chars.add(e);
        }
      } else {
        pos++;
        if (!_done && _peek == '-' && pos + 1 < src.length && src[pos + 1] != ']') {
          pos += 2; // aralık: a-z
          simple = false;
        } else {
          chars.add(c);
        }
      }
    }

    if (!simple || chars.isEmpty || chars.length > 8) return _Info.unknown;
    if (chars.any((ch) => ch.codeUnitAt(0) >= 0x80)) return _Info.unknown;
    return _Info({for (final ch in chars) ch.toLowerCase()}, null);
  }

  _Info _escape() {
    pos++; // '\'
    if (_done) throw const _Unsupported();
    final e = _peek;
    pos++;
    switch (e) {
      case 'b':
      case 'B':
        return _Info.empty;
      case 'w':
      case 'W':
      case 's':
      case 'S':
      case 'd':
      case 'D':
        return _Info.unknown;
      case 'n':
      case 't':
      case 'r':
      case 'f':
      case 'v':
        return _Info.unknown; // metinde normalize sonrası geçmez; kısıt sayma
    }
    if (RegExp(r'[A-Za-z0-9]').hasMatch(e)) {
      // Geri başvuru (\1), \uXXXX, \p{…}, \k<ad> … — desteklenmez.
      throw const _Unsupported();
    }
    return _literal(e); // kaçışlı noktalama: \. \- \( …
  }
}
