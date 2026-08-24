# -*- coding: utf-8 -*-
"""Şekil 4 — Katman katkısının izolasyonu (§3.2).

"Yasaklı kelime listesi yetmez" cümlesini bir görüşten bir ölçüme dönüştürür.
Değerler `dart run bin/evaluate.dart --karsilastir` çıktısından alınmıştır;
geliştirme kümesi (n=256), dilim bazında duyarlılık.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ortak import *  # noqa

# (dilim, yalnız sözlük, tam hat, vurgulansın mı)
VERI = [
    ("Açık saldırı",    98.2, 100.0, False),
    ("Örtük saldırı",    1.8, 100.0, True),
    ("Nefret söylemi",  10.5,  94.7, True),
    ("Bağlam",          66.7, 100.0, False),
    ("GENEL",           44.0,  99.3, False),
]

ETK_X, BAR_X0, BAR_EN = 236, 258, 552
Y0, BAR_H, BAR_ARA, GRUP_ARA = 118, 24, 9, 28
GRUP = BAR_H * 2 + BAR_ARA + GRUP_ARA
H = Y0 + len(VERI) * GRUP + 96


def ciz(hedef):
    t = Tuval(H)

    t.yazi(32, 30, "DİLİM BAZINDA DUYARLILIK (%)", 11.5, FAINT, True)
    t.cizgi(32, 44, 868, 44)

    # gösterge
    for i, (renk, ad) in enumerate([(SLATE, "Yalnız sözlük katmanı"),
                                    (BRAND, "+ Örüntü katmanları")]):
        lx = 32 + i * 250
        t.kutu((lx, 62, lx + 16, 78), 3, dolgu=renk)
        t.yazi(lx + 26, 70, ad, 13, MUTED)

    # ızgara çizgileri
    for pct in (25, 50, 75, 100):
        gx = BAR_X0 + BAR_EN * pct / 100
        t.cizgi(gx, Y0 - 12, gx, Y0 + len(VERI) * GRUP - GRUP_ARA + 4,
                (240, 236, 232), 1)
        t.yazi(gx, Y0 - 22, str(pct), 11, FAINT, False, "mm")

    for i, (ad, once, sonra, vurgu) in enumerate(VERI):
        gy = Y0 + i * GRUP
        genel = ad == "GENEL"

        if vurgu:
            t.kutu((28, gy - 10, 868, gy + BAR_H * 2 + BAR_ARA + 10), 8,
                   dolgu=(253, 246, 242))
        if genel:
            t.cizgi(32, gy - 14, 868, gy - 14, LINE)

        # dilim adi gri cubukla, kazanc etiketi kirmizi cubukla hizali
        t.yazi(ETK_X, gy + BAR_H / 2, ad, 14.5,
               INK if genel else MUTED, genel, "rm")
        fark = sonra - once
        if fark >= 20:
            t.yazi(ETK_X, gy + BAR_H + BAR_ARA + BAR_H / 2,
                   ("+%.1f puan" % fark).replace(".", ","), 13, GREEN, True, "rm")

        for j, (deger, renk) in enumerate([(once, SLATE), (sonra, BRAND)]):
            by = gy + j * (BAR_H + BAR_ARA)
            en = max(BAR_EN * deger / 100, 1.5)
            t.kutu((BAR_X0, by, BAR_X0 + en, by + BAR_H), 4, dolgu=renk)
            t.yazi(BAR_X0 + en + 10, by + BAR_H / 2,
                   ("%.1f" % deger).replace(".", ","), 13, renk, True)

    ny = Y0 + len(VERI) * GRUP - GRUP_ARA + 22
    t.kutu((32, ny, 868, ny + 52), 10, dolgu=BRAND_SOFT, cerceve=BRAND, kalinlik=1.4)
    t.yazi(450, ny + 26,
           "Kesinlik her iki yapılandırmada da %100,0 — kazanç kesinlikten "
           "hiçbir şey götürmedi.",
           14.5, BRAND, True, "mm")

    t.kaydet(hedef)


if __name__ == "__main__":
    ciz(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sekil4_katman.png"))
