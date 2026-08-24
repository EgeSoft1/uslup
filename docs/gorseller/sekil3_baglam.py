# -*- coding: utf-8 -*-
"""Şekil 3 — Bağlam ağırlıklandırma (§2.2).

Aynı sözcüğün dört bağlamda nasıl farklı ağırlık aldığını gösterir. Çarpanlar
`context_analyzer.dart` içindeki değerlerin aynısıdır; sonuç skorları
taban şiddet 0,55 üzerinden hesaplanmıştır ve `civility_engine.dart`
eşikleriyle (temiz < 0,15) karşılaştırılmıştır.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ortak import *  # noqa

TABAN = 0.55

SATIRLAR = [
    ("“sen tam bir aptalsın”",      "Doğrudan saldırı", "×1,25", 0.69, True),
    ("“aptal değilsin”",            "Olumsuzlama / iltifat", "×0,15", 0.08, False),
    ("“bana aptal dedi”",           "Alıntı / şikâyet", "×0,20", 0.11, False),
    ("“kendimi aptal hissettim”",   "Öz-ifade", "×0,20", 0.11, False),
]

Y0, SH, SARA = 108, 84, 12
H = 108 + 4 * (84 + 12) + 78


def ciz(hedef):
    t = Tuval(H)

    # başlık şeridi
    t.kutu((32, 22, 868, 84), 10, dolgu=PAPER, cerceve=LINE, kalinlik=1.4)
    t.yazi(52, 42, "AYNI SÖZCÜK, DÖRT FARKLI BAĞLAM", 11, FAINT, True)
    t.yazi(52, 66, "Taban şiddet:  aptal = 0,55", 15.5, INK, True)
    t.yazi(848, 54, "Eşik:  toksisite < 0,15 → uyarı üretilmez", 13, MUTED, False, "rm")

    for i, (cumle, baglam, carpan, sonuc, uyari) in enumerate(SATIRLAR):
        y = Y0 + i * (SH + SARA)
        renk   = BRAND if uyari else GREEN
        yumusak= RED_BG if uyari else GREEN_BG
        orta   = y + SH / 2

        t.kutu((32, y, 868, y + SH), 8, dolgu=WHITE, cerceve=LINE, kalinlik=1.2)
        t.d.rounded_rectangle(
            [t.s(32), t.s(y), t.s(38), t.s(y + SH)], radius=t.s(3), fill=renk)

        t.yazi(56, orta, cumle, 16, INK, True)
        t.yazi(330, orta, baglam, 14, MUTED)

        t.rozet(524, orta, carpan, 12.5, dolgu=yumusak, renk=renk, dolgu_px=12)
        t.ok_saga(596, 646, orta)

        t.yazi(660, orta, ("%.2f" % sonuc).replace(".", ","), 17, renk, True)
        t.rozet(716, orta, "UYARI" if uyari else "uyarı yok", 11.5,
                dolgu=renk if uyari else GREEN_BG,
                renk=WHITE if uyari else GREEN, dolgu_px=13)

    # tavan notu
    ny = Y0 + 4 * (SH + SARA) + 8
    t.kutu((32, ny, 868, ny + 52), 10, dolgu=BRAND_SOFT, cerceve=BRAND, kalinlik=1.4)
    t.yazi(450, ny + 26,
           "Yumuşatma yalnızca bir çarpan değil, aynı zamanda TAVANDIR: "
           "mağdurun anlatısı eşiğin üstüne çıkamaz.",
           14, BRAND, True, "mm")

    t.kaydet(hedef)


if __name__ == "__main__":
    ciz(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sekil3_baglam.png"))
