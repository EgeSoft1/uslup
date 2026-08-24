# -*- coding: utf-8 -*-
"""Şekil 2 — Müdahale merdiveni (§2.2).

Ürünün tek davranış kuralını tek karede anlatır: müdahale şiddeti riskle
orantılıdır ve hiçbir seviyede gönderim engellenmez. Eşikler
`civility_engine.dart` içindeki `RiskLevel` sınırlarıyla birebir aynıdır.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ortak import *  # noqa

SEVIYELER = [
    ("< 0,15",      "TEMİZ",  "Hiçbir şey",                      "Yok",           64, GREEN,  GREEN_BG),
    ("0,15 – 0,40", "DİKKAT", "Yalnızca kenarlık rengi değişir",  "Yok",          148, AMBER,  AMBER_BG),
    ("0,40 – 0,70", "RİSKLİ", "Gerekçe + yeniden yazma önerisi",  "Yok",          236, ORANGE, ORANGE_BG),
    ("≥ 0,70",      "YÜKSEK", "Gönderim öncesi onay diyaloğu",    "Bir dokunuş",  330, BRAND,  RED_BG),
]

TABAN, KART_Y0, KART_Y1 = 424, 442, 596
KOL_X0, KOL_EN, KOL_ARA = 32, 200, 212
H = 672


def ciz(hedef):
    t = Tuval(H)

    t.yazi(32, 26, "TOKSİSİTE SKORU", 11.5, FAINT, True)
    t.cizgi(32, 40, 868, 40)

    for i, (aralik, ad, gorur, kesinti, yuk, renk, yumusak) in enumerate(SEVIYELER):
        x0 = KOL_X0 + i * KOL_ARA
        x1 = x0 + KOL_EN
        orta = (x0 + x1) / 2

        # merdiven basamağı
        ust = TABAN - yuk
        t.kutu((x0, ust, x1, TABAN), 8, dolgu=renk)
        t.yazi(orta, TABAN - 22, ad, 17, WHITE, True, "mm")
        t.yazi(orta, ust - 18, aralik, 14, MUTED, True, "mm")

        # bilgi kartı
        t.kutu((x0, KART_Y0, x1, KART_Y1), 8, dolgu=yumusak, cerceve=renk, kalinlik=1.2)
        t.yazi(x0 + 14, KART_Y0 + 20, "KULLANICI NE GÖRÜR", 9.5, renk, True)
        t.paragraf(x0 + 14, KART_Y0 + 44, gorur, 13.5, KOL_EN - 28, INK)
        t.cizgi(x0 + 14, KART_Y1 - 42, x1 - 14, KART_Y1 - 42, renk)
        t.yazi(x0 + 14, KART_Y1 - 22, "Kesinti", 11.5, MUTED)
        t.yazi(x1 - 14, KART_Y1 - 22, kesinti, 12.5, renk, True, "rm")

    # değişmez
    t.kutu((32, 616, 868, 660), 10, dolgu=BRAND_SOFT, cerceve=BRAND, kalinlik=1.4)
    t.yazi(450, 638,
           "Hiçbir seviyede gönderim engellenmez — karar her zaman kullanıcınındır.",
           15, BRAND, True, "mm")

    t.kaydet(hedef)


if __name__ == "__main__":
    ciz(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sekil2_merdiven.png"))
