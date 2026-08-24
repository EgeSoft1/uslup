# -*- coding: utf-8 -*-
"""
Rapor görselleri için ortak tasarım sistemi.

Bütün şekiller aynı paletten, aynı yazı tipinden (rapor gövdesiyle birebir:
Arial) ve aynı ölçekten çizilir. Amaç, sekiz-on görselin tek bir elden
çıkmış gibi durmasıdır; jüri için bu, içeriğin kendisi kadar okunur bir
sinyaldir.

Tasarım birimi 900 birim genişliktir; S katsayısı ile ~370 dpi'ye ölçeklenir.
"""
import sys
from PIL import Image, ImageDraw, ImageFont

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

W = 900
S = 2.6

BRAND     = (196, 18, 48)
BRAND_SOFT= (250, 232, 235)
INK       = (26, 26, 26)
MUTED     = (110, 104, 100)
FAINT     = (150, 145, 141)
LINE      = (228, 220, 214)
PAPER     = (252, 248, 244)
WHITE     = (255, 255, 255)

GREEN     = (46, 125, 91)
GREEN_BG  = (233, 246, 238)
AMBER     = (196, 138, 12)
AMBER_BG  = (253, 244, 224)
ORANGE    = (200, 92, 12)
ORANGE_BG = (253, 237, 226)
RED_BG    = (250, 232, 235)
SLATE     = (150, 145, 141)

_ARIAL   = r"C:\Windows\Fonts\arial.ttf"
_ARIAL_B = r"C:\Windows\Fonts\arialbd.ttf"


class Tuval:
    """Tasarım biriminde çizim yapılan, PNG'ye ölçekleyerek yazan yüzey."""

    def __init__(self, yukseklik, genislik=W, zemin=WHITE):
        self.h = yukseklik
        self.w = genislik
        self.img = Image.new("RGB", (self.s(genislik), self.s(yukseklik)), zemin)
        self.d = ImageDraw.Draw(self.img)

    def s(self, v):
        return int(round(v * S))

    def ar(self, p):
        return ImageFont.truetype(_ARIAL, self.s(p))

    def ab(self, p):
        return ImageFont.truetype(_ARIAL_B, self.s(p))

    # ── ilkel çizimler ──────────────────────────────────────────────────────
    def kutu(self, box, r=8, dolgu=None, cerceve=None, kalinlik=1.2):
        self.d.rounded_rectangle(
            [self.s(box[0]), self.s(box[1]), self.s(box[2]), self.s(box[3])],
            radius=self.s(r), fill=dolgu, outline=cerceve,
            width=max(1, self.s(kalinlik)))

    def yazi(self, x, y, t, punto, renk=INK, kalin=False, hiza="lm"):
        f = self.ab(punto) if kalin else self.ar(punto)
        self.d.text((self.s(x), self.s(y)), t, font=f, fill=renk, anchor=hiza)

    def genislik_of(self, t, punto, kalin=False):
        f = self.ab(punto) if kalin else self.ar(punto)
        return self.d.textlength(t, font=f) / S

    def rozet(self, x, y, t, punto=11.5, dolgu=BRAND, renk=WHITE, dolgu_px=14):
        g = self.genislik_of(t, punto, True) + dolgu_px * 2
        yuk = punto + 11
        self.kutu((x, y - yuk / 2, x + g, y + yuk / 2), yuk / 2, dolgu=dolgu)
        self.yazi(x + g / 2, y, t, punto, renk, True, "mm")
        return g

    def cizgi(self, x0, y0, x1, y1, renk=LINE, kalinlik=1.2):
        self.d.line([(self.s(x0), self.s(y0)), (self.s(x1), self.s(y1))],
                    fill=renk, width=max(1, self.s(kalinlik)))

    def ok_asagi(self, x, y0, y1, renk=MUTED):
        self.d.line([(self.s(x), self.s(y0)), (self.s(x), self.s(y1) - self.s(7))],
                    fill=renk, width=max(1, self.s(1.6)))
        self.d.polygon([(self.s(x) - self.s(6), self.s(y1) - self.s(8)),
                        (self.s(x) + self.s(6), self.s(y1) - self.s(8)),
                        (self.s(x), self.s(y1))], fill=renk)

    def ok_saga(self, x0, x1, y, renk=FAINT):
        self.d.line([(self.s(x0), self.s(y)), (self.s(x1) - self.s(7), self.s(y))],
                    fill=renk, width=max(1, self.s(1.4)))
        self.d.polygon([(self.s(x1) - self.s(8), self.s(y) - self.s(5)),
                        (self.s(x1) - self.s(8), self.s(y) + self.s(5)),
                        (self.s(x1), self.s(y))], fill=renk)

    def sar(self, t, punto, en, kalin=False):
        """Metni verilen genişliğe göre satırlara böler."""
        kelimeler, satirlar, kur = t.split(), [], ""
        for k in kelimeler:
            deneme = (kur + " " + k).strip()
            if self.genislik_of(deneme, punto, kalin) <= en:
                kur = deneme
            else:
                if kur:
                    satirlar.append(kur)
                kur = k
        if kur:
            satirlar.append(kur)
        return satirlar

    def paragraf(self, x, y, t, punto, en, renk=MUTED, kalin=False,
                 satir_araligi=1.45, hiza="lm"):
        sat = self.sar(t, punto, en, kalin)
        adim = punto * satir_araligi
        for i, s_ in enumerate(sat):
            self.yazi(x, y + i * adim, s_, punto, renk, kalin, hiza)
        return len(sat) * adim

    def kaydet(self, yol):
        self.img.save(yol, "PNG", dpi=(370, 370))
        print("yazildi:", yol, self.img.size)
