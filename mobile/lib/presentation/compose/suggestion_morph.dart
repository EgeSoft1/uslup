// =============================================================================
// Öneri dönüşümü — kelime farkı, önizleme ve animasyonlu düzeltme
// Dosya: mobile/lib/presentation/compose/suggestion_morph.dart
//
// ── NEDEN (docs/24 · madde 2 ve 4) ────────────────────────────────────────
// "Bunu kullan"a basınca metin tek karede yer değiştiriyordu. Kullanıcı neyin
// değiştiğini göremiyordu; değişen şeyi okumak için iki metni kafasında
// karşılaştırmak zorundaydı. Oysa ürünün söylediği tek cümle "fikir yerinde
// kaldı, saldırı çıktı"dır ve bunun GÖRÜLMESİ gerekir:
//
//   1. Önizleme: öneri kartında silinecek kelimeler üstü çizili, eklenecekler
//      vurgulu gösterilir.
//   2. Dönüşüm: uygulama anında silinen kelimeler kızarıp solar, yenileri
//      harf harf yazılarak gelir. Aynı kalan kelimeler hiç kıpırdamaz — göz
//      yalnızca değişen yere gider.
//
// Fark hesabı kelime düzeyinde en uzun ortak alt dizidir (LCS). Büyük/küçük
// harf farkı DEĞİŞİKLİK sayılmaz: öneri cümle başını büyütür ve "sen" →
// "Sen" farkını silinip eklenmiş göstermek gürültüdür.
//
// Hareketi azaltma tercihi (`MediaQuery.disableAnimations`) açıksa dönüşüm
// atlanır ve metin doğrudan değişir.
// =============================================================================

import 'package:flutter/material.dart';

/// Farkın tek bir parçası.
enum DiffOp { ayni, silinen, eklenen }

@immutable
class DiffToken {
  const DiffToken(this.op, this.text);

  final DiffOp op;
  final String text;

  @override
  String toString() => '${op.name}("$text")';
}

/// İki metnin kelime düzeyinde farkı. Boşluklar ayrı token olarak korunur,
/// böylece parçalar birleştirildiğinde özgün boşluk düzeni geri gelir.
List<DiffToken> kelimeFarki(String eski, String yeni) {
  final a = _parcala(eski);
  final b = _parcala(yeni);

  // LCS tablosu — kelime sayısı küçük (gönderi), O(n·m) yeterli.
  final n = a.length, m = b.length;
  final tablo = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      tablo[i][j] = _esit(a[i], b[j])
          ? tablo[i + 1][j + 1] + 1
          : (tablo[i + 1][j] >= tablo[i][j + 1]
              ? tablo[i + 1][j]
              : tablo[i][j + 1]);
    }
  }

  final sonuc = <DiffToken>[];
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (_esit(a[i], b[j])) {
      sonuc.add(DiffToken(DiffOp.ayni, b[j]));
      i++;
      j++;
    } else if (tablo[i + 1][j] >= tablo[i][j + 1]) {
      sonuc.add(DiffToken(DiffOp.silinen, a[i++]));
    } else {
      sonuc.add(DiffToken(DiffOp.eklenen, b[j++]));
    }
  }
  while (i < n) {
    sonuc.add(DiffToken(DiffOp.silinen, a[i++]));
  }
  while (j < m) {
    sonuc.add(DiffToken(DiffOp.eklenen, b[j++]));
  }
  return _birlestir(sonuc);
}

List<String> _parcala(String metin) => RegExp(r'\s+|[^\s]+')
    .allMatches(metin)
    .map((m) => m.group(0)!)
    .toList();

bool _esit(String x, String y) => _kucuk(x) == _kucuk(y);

String _kucuk(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// Aynı türden ardışık parçaları tek parçada toplar; boşluk tek başına
/// silinen/eklenen olarak kalmaz, komşusuna katılır.
List<DiffToken> _birlestir(List<DiffToken> ham) {
  final out = <DiffToken>[];
  for (final t in ham) {
    if (out.isNotEmpty && out.last.op == t.op) {
      out[out.length - 1] = DiffToken(t.op, out.last.text + t.text);
    } else {
      out.add(t);
    }
  }
  return out;
}

// ─── Önizleme ────────────────────────────────────────────────────────────────

/// Öneri kartında gösterilen fark: üstte eski metin (silinecekler üstü
/// çizili), altta yeni metin (eklenenler vurgulu).
///
/// Tek satırlık iç içe gösterim denendi ve ekran görüntüsünde okunaksız çıktı:
/// silinen ve eklenen kelimeler arada boşluk olmadan yapışıyordu
/// ("beyinsizBu yorumlaryorumlarına"). İki satır, gözün önce neyin gittiğini
/// sonra neyin geldiğini okumasını sağlar.
class SuggestionDiffPreview extends StatelessWidget {
  const SuggestionDiffPreview({
    super.key,
    required this.original,
    required this.suggestion,
    required this.style,
    required this.removedColor,
    required this.addedColor,
    required this.addedBackground,
  });

  final String original;
  final String suggestion;
  final TextStyle style;
  final Color removedColor;
  final Color addedColor;
  final Color addedBackground;

  @override
  Widget build(BuildContext context) {
    final fark = kelimeFarki(original, suggestion);
    final ikincil = style.copyWith(
      fontSize: (style.fontSize ?? 15) - 2,
      color: style.color?.withValues(alpha: 0.62),
    );

    return Semantics(
      label: 'Önerilen metin: $suggestion',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3, right: 6),
                  child: Icon(Icons.remove_rounded, size: 14, color: removedColor),
                ),
                Expanded(
                  child: Text.rich(TextSpan(style: ikincil, children: [
                    for (final t in fark)
                      if (t.op == DiffOp.ayni)
                        TextSpan(text: t.text)
                      else if (t.op == DiffOp.silinen)
                        TextSpan(
                          text: t.text,
                          style: TextStyle(
                            color: removedColor,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: removedColor,
                            decorationThickness: 2,
                          ),
                        ),
                  ])),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 6),
                  child: Icon(Icons.add_rounded, size: 14, color: addedColor),
                ),
                Expanded(
                  child: Text.rich(TextSpan(style: style, children: [
                    for (final t in fark)
                      if (t.op == DiffOp.ayni)
                        TextSpan(text: t.text)
                      else if (t.op == DiffOp.eklenen)
                        TextSpan(
                          text: t.text,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            backgroundColor: addedBackground,
                          ),
                        ),
                  ])),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dönüşüm animasyonu ──────────────────────────────────────────────────────

/// Metin kutusunun yerine kısa süreliğine çizilen dönüşüm.
///
/// Zaman çizelgesi (0 → 1):
///   0,00–0,45  silinen kelimeler kırmızılaşır, üstü çizilir, solar
///   0,45       silinenler akıştan çıkar
///   0,35–0,90  eklenen kelimeler harf harf yazılır (vurgulu zemin)
///   0,90–1,00  vurgu söner, metin son hâline oturur
class SuggestionMorphText extends StatefulWidget {
  const SuggestionMorphText({
    super.key,
    required this.from,
    required this.to,
    required this.style,
    required this.removedColor,
    required this.addedColor,
    required this.addedBackground,
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 1100),
  });

  final String from;
  final String to;
  final TextStyle style;
  final Color removedColor;
  final Color addedColor;
  final Color addedBackground;
  final VoidCallback onCompleted;
  final Duration duration;

  @override
  State<SuggestionMorphText> createState() => _SuggestionMorphTextState();
}

class _SuggestionMorphTextState extends State<SuggestionMorphText>
    with SingleTickerProviderStateMixin {
  late final List<DiffToken> _fark = kelimeFarki(widget.from, widget.to);
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _bitir();
        });

  bool _bildirildi = false;

  /// Tamamlanma TEK kez ve çizim bittikten sonra bildirilir: çağıran taraf
  /// `setState` yapar ve bu, kurulum sırasında yapılamaz.
  void _bitir() {
    if (_bildirildi) return;
    _bildirildi = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCompleted();
    });
  }

  /// Eklenecek toplam harf — yazılma ilerlemesi bunun üzerinden dağıtılır.
  late final int _eklenenHarf = _fark
      .where((t) => t.op == DiffOp.eklenen)
      .fold(0, (sum, t) => sum + t.text.length);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    final azHareket = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (azHareket) {
      _controller.value = 1; // durum dinleyicisi `_bitir` çağırır
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _aralik(double t, double bas, double son) =>
      ((t - bas) / (son - bas)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final silme = Curves.easeIn.transform(_aralik(t, 0.0, 0.45));
        final yazma = Curves.easeOut.transform(_aralik(t, 0.35, 0.90));
        final sonme = _aralik(t, 0.90, 1.0);

        var yazilacak = (_eklenenHarf * yazma).ceil();
        final parcalar = <InlineSpan>[];

        for (final token in _fark) {
          switch (token.op) {
            case DiffOp.ayni:
              parcalar.add(TextSpan(text: token.text));
            case DiffOp.silinen:
              if (t >= 0.45) continue;
              parcalar.add(TextSpan(
                text: token.text,
                style: TextStyle(
                  color: Color.lerp(widget.style.color, widget.removedColor,
                          (silme * 2).clamp(0.0, 1.0))!
                      .withValues(alpha: 1 - silme * 0.8),
                  decoration: TextDecoration.lineThrough,
                  decorationColor:
                      widget.removedColor.withValues(alpha: silme),
                  decorationThickness: 2,
                ),
              ));
            case DiffOp.eklenen:
              if (yazilacak <= 0) continue;
              final gorunen = token.text
                  .substring(0, yazilacak.clamp(0, token.text.length));
              yazilacak -= token.text.length;
              parcalar.add(TextSpan(
                text: gorunen,
                style: TextStyle(
                  color: Color.lerp(
                      widget.addedColor, widget.style.color, sonme),
                  backgroundColor: widget.addedBackground
                      .withValues(alpha: (1 - sonme) * 0.9),
                ),
              ));
          }
        }

        return Semantics(
          liveRegion: true,
          label: 'Öneri uygulanıyor',
          child: ExcludeSemantics(
            child: Text.rich(TextSpan(style: widget.style, children: parcalar)),
          ),
        );
      },
    );
  }
}
