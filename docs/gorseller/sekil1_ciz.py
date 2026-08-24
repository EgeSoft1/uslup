# -*- coding: utf-8 -*-
"""
Şekil 1 — Üslup'un cihaz üstü çözümleme hattı.

Rapora girecek mimari çizimi. Ekran görüntüsü DEĞİLDİR; §1.2'nin sonundaki
`[ŞEKİL 1 BURAYA]` çapasının yerine konur.

Tek kaynaktan hem PNG (Word'e gömmek için, ~370 dpi) hem SVG (vektör) üretir;
ikisi aynı yerleşim verisinden çizildiği için birbirinden ayrışamaz.

Çalıştırma:  python docs/gorseller/sekil1_ciz.py
"""
import io, os
from PIL import Image, ImageDraw, ImageFont

# ── Yerleşim (tasarım birimi: 900 × 700) ────────────────────────────────────
W, H = 900, 700
S = 2.6                                   # ölçek → 2340 × 1820 px

BRAND      = (196, 18, 48)                # marka kırmızısı
INK        = (26, 26, 26)
MUTED      = (110, 104, 100)
LINE       = (228, 220, 214)
DEVICE_BG  = (252, 248, 244)
WHITE      = (255, 255, 255)
OK_BG      = (233, 246, 238)
OK_BORDER  = (46, 125, 91)
OK_INK     = (27, 94, 67)

ADIMLAR = [
    ("Normalizasyon",        "$3r3fsiz → serefsiz  ·  aptaaaal → aptal"),
    ("Sözlük eşleştirme",    "Eklemeli yapıda kök eşleşmesi: aptallığın → aptal"),
    ("Edimbilimsel örüntü",  "Küfürsüz düşmanlık — kelimede değil, dizilişte"),
    ("Nefret söylemi",       "Kimlik hedefli düşmanlık; kimlik adı tetikleyici değil"),
    ("Gönderge (anafora)",   "Zamiri önceki cümledeki öncüle bağlar"),
    ("Bağlam çözümleme",     "saldırı / iltifat / şikâyet / öz-ifade ayrımı"),
    ("Öneri üretimi",        "Yerel, deterministik yeniden yazım"),
]

GIRDI  = "Kullanıcı cümleyi yazıyor"
CIKTI  = "Kullanıcı seçer ve gönderir"
BASLIK = "CİHAZ ÜZERİNDE"
ROZET  = "SUNUCU ADIMI YOKTUR"
DIPNOT = "Toplam çözümleme: 87–193 µs (AOT) — 16 ms kare bütçesinin %1,2'si"

# kutu geometrisi
IN_BOX   = (270, 8, 630, 54)
DEV_BOX  = (30, 82, 870, 600)
HDR_H    = 48
ROW_X0, ROW_X1 = 54, 846
ROW_Y0, ROW_H, ROW_GAP = 138, 56, 6
OUT_BOX  = (250, 628, 650, 680)


def _rows():
    for i, (bas, org) in enumerate(ADIMLAR):
        y = ROW_Y0 + i * (ROW_H + ROW_GAP)
        yield i + 1, bas, org, y


# ── PNG ─────────────────────────────────────────────────────────────────────
def ciz_png(hedef):
    def s(v):
        return int(round(v * S))

    img = Image.new("RGB", (s(W), s(H)), WHITE)
    d = ImageDraw.Draw(img)
    ar = lambda p: ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", s(p))
    ab = lambda p: ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", s(p))

    def rrect(box, r, fill=None, outline=None, w=1):
        d.rounded_rectangle([s(box[0]), s(box[1]), s(box[2]), s(box[3])],
                            radius=s(r), fill=fill, outline=outline, width=s(w))

    def ok(x, y0, y1):                       # aşağı ok
        d.line([(s(x), s(y0)), (s(x), s(y1) - s(7))], fill=MUTED, width=s(1.6))
        d.polygon([(s(x) - s(6), s(y1) - s(8)), (s(x) + s(6), s(y1) - s(8)),
                   (s(x), s(y1))], fill=MUTED)

    # girdi
    rrect(IN_BOX, 10, fill=WHITE, outline=LINE, w=1.6)
    d.text((s(450), s((IN_BOX[1] + IN_BOX[3]) / 2)), GIRDI,
           font=ab(16), fill=INK, anchor="mm")
    ok(450, IN_BOX[3], DEV_BOX[1])

    # cihaz kabı
    rrect(DEV_BOX, 16, fill=DEVICE_BG, outline=BRAND, w=2)
    d.line([(s(DEV_BOX[0]), s(DEV_BOX[1] + HDR_H)),
            (s(DEV_BOX[2]), s(DEV_BOX[1] + HDR_H))], fill=LINE, width=s(1.2))
    hy = DEV_BOX[1] + HDR_H / 2
    d.text((s(54), s(hy)), BASLIK, font=ab(16), fill=BRAND, anchor="lm")

    # "sunucu yok" rozeti
    rf = ab(11.5)
    rw = d.textlength(ROZET, font=rf) / S + 30
    rrect((846 - rw, hy - 13, 846, hy + 13), 13, fill=BRAND)
    d.text((s(846 - rw / 2), s(hy)), ROZET, font=rf, fill=WHITE, anchor="mm")

    # adımlar
    for n, bas, org, y in _rows():
        rrect((ROW_X0, y, ROW_X1, y + ROW_H), 8, fill=WHITE, outline=LINE, w=1.2)
        cy = y + ROW_H / 2
        d.ellipse([s(69), s(cy - 15), s(99), s(cy + 15)], fill=BRAND)
        d.text((s(84), s(cy)), str(n), font=ab(15), fill=WHITE, anchor="mm")
        d.text((s(118), s(cy)), bas, font=ab(16), fill=INK, anchor="lm")
        d.text((s(396), s(cy)), org, font=ar(14.5), fill=MUTED, anchor="lm")

    d.text((s(450), s(DEV_BOX[3] - 16)), DIPNOT,
           font=ar(12.5), fill=MUTED, anchor="mm")

    # çıktı
    ok(450, DEV_BOX[3], OUT_BOX[1])
    rrect(OUT_BOX, 10, fill=OK_BG, outline=OK_BORDER, w=1.6)
    d.text((s(450), s((OUT_BOX[1] + OUT_BOX[3]) / 2)), CIKTI,
           font=ab(16), fill=OK_INK, anchor="mm")

    img.save(hedef, "PNG", dpi=(370, 370))
    return img.size


# ── SVG ─────────────────────────────────────────────────────────────────────
def ciz_svg(hedef):
    hex_ = lambda c: "#%02x%02x%02x" % c
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
         f'width="{W}" height="{H}" font-family="Arial, Helvetica, sans-serif">',
         f'<rect width="{W}" height="{H}" fill="#fff"/>']

    def rect(b, r, fill, stroke=None, sw=1):
        st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
        o.append(f'<rect x="{b[0]}" y="{b[1]}" width="{b[2]-b[0]}" '
                 f'height="{b[3]-b[1]}" rx="{r}" fill="{fill}"{st}/>')

    def txt(x, y, t, size, fill, bold=False, anchor="start"):
        t = (t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))
        fw = ' font-weight="bold"' if bold else ""
        o.append(f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}"'
                 f'{fw} text-anchor="{anchor}" dominant-baseline="central">{t}</text>')

    def ok(x, y0, y1):
        o.append(f'<line x1="{x}" y1="{y0}" x2="{x}" y2="{y1-7}" '
                 f'stroke="{hex_(MUTED)}" stroke-width="1.6"/>')
        o.append(f'<polygon points="{x-6},{y1-8} {x+6},{y1-8} {x},{y1}" '
                 f'fill="{hex_(MUTED)}"/>')

    rect(IN_BOX, 10, "#fff", hex_(LINE), 1.6)
    txt(450, (IN_BOX[1] + IN_BOX[3]) / 2, GIRDI, 16, hex_(INK), True, "middle")
    ok(450, IN_BOX[3], DEV_BOX[1])

    rect(DEV_BOX, 16, hex_(DEVICE_BG), hex_(BRAND), 2)
    o.append(f'<line x1="{DEV_BOX[0]}" y1="{DEV_BOX[1]+HDR_H}" x2="{DEV_BOX[2]}" '
             f'y2="{DEV_BOX[1]+HDR_H}" stroke="{hex_(LINE)}" stroke-width="1.2"/>')
    hy = DEV_BOX[1] + HDR_H / 2
    txt(54, hy, BASLIK, 16, hex_(BRAND), True)
    rw = len(ROZET) * 7.0 + 30
    rect((846 - rw, hy - 13, 846, hy + 13), 13, hex_(BRAND))
    txt(846 - rw / 2, hy, ROZET, 11.5, "#fff", True, "middle")

    for n, bas, org, y in _rows():
        rect((ROW_X0, y, ROW_X1, y + ROW_H), 8, "#fff", hex_(LINE), 1.2)
        cy = y + ROW_H / 2
        o.append(f'<circle cx="84" cy="{cy}" r="15" fill="{hex_(BRAND)}"/>')
        txt(84, cy, str(n), 15, "#fff", True, "middle")
        txt(118, cy, bas, 16, hex_(INK), True)
        txt(396, cy, org, 14.5, hex_(MUTED))

    txt(450, DEV_BOX[3] - 16, DIPNOT, 12.5, hex_(MUTED), False, "middle")
    ok(450, DEV_BOX[3], OUT_BOX[1])
    rect(OUT_BOX, 10, hex_(OK_BG), hex_(OK_BORDER), 1.6)
    txt(450, (OUT_BOX[1] + OUT_BOX[3]) / 2, CIKTI, 16, hex_(OK_INK), True, "middle")

    o.append("</svg>")
    io.open(hedef, "w", encoding="utf-8").write("\n".join(o))


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    png = os.path.join(here, "sekil1_mimari.png")
    svg = os.path.join(here, "sekil1_mimari.svg")
    boyut = ciz_png(png)
    ciz_svg(svg)
    print("PNG:", png, boyut)
    print("SVG:", svg)
