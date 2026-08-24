# -*- coding: utf-8 -*-
"""Şekil 5 — Ana kullanıcı akışı A1 (§3.3).

Yazma anından anonim sinyale kadar olan yolu tek karede verir. Akışın iki
kritik özelliği görsel olarak da okunur: hiçbir dal gönderimi engellemez ve
hattın sonunda platforma giden şey metin değildir.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ortak import *  # noqa

SEVIYE = [
    ("TEMİZ",  "Hiçbir kesinti yok",           GREEN,  GREEN_BG),
    ("DİKKAT", "Kenarlık rengi değişir",       AMBER,  AMBER_BG),
    ("RİSKLİ", "Gerekçe + öneri gösterilir",   ORANGE, ORANGE_BG),
    ("YÜKSEK", "Gönderim öncesi onay istenir", BRAND,  RED_BG),
]

SECIM = ["Öneriyi uygular", "Kendi düzeltir", "Görmezden gelir"]

SINYAL = ["temizGönderim", "uyarıyaRağmenGönderdi",
          "öneriyiKabulEtti", "kendiDüzeltti"]

KOL_X0, KOL_EN, KOL_ARA = 32, 200, 212
MERKEZ = [KOL_X0 + i * KOL_ARA + KOL_EN / 2 for i in range(4)]
H = 648


def ciz(hedef):
    t = Tuval(H)

    # 1 — girdi
    t.kutu((330, 16, 570, 62), 10, dolgu=WHITE, cerceve=LINE, kalinlik=1.6)
    t.yazi(450, 39, "Kullanıcı yazar", 16, INK, True, "mm")
    t.ok_asagi(450, 62, 92)

    # 2 — çözümleme
    t.kutu((190, 92, 710, 148), 10, dolgu=PAPER, cerceve=BRAND, kalinlik=1.8)
    t.yazi(450, 112, "Cihaz üstü çözümleme", 16, BRAND, True, "mm")
    t.yazi(450, 133, "87–193 µs  ·  gecikmeli tetikleme yok  ·  ağ çağrısı yok",
           12.5, MUTED, False, "mm")

    # dağıtım
    t.cizgi(450, 148, 450, 176, FAINT, 1.4)
    t.cizgi(MERKEZ[0], 176, MERKEZ[3], 176, FAINT, 1.4)
    for cx in MERKEZ:
        t.ok_asagi(cx, 176, 200, FAINT)

    # 3 — dört seviye
    for i, (ad, aciklama, renk, yumusak) in enumerate(SEVIYE):
        x0 = KOL_X0 + i * KOL_ARA
        x1 = x0 + KOL_EN
        t.kutu((x0, 200, x1, 306), 8, dolgu=yumusak, cerceve=renk, kalinlik=1.4)
        t.kutu((x0, 200, x1, 234), 8, dolgu=renk)
        t.d.rectangle([t.s(x0), t.s(226), t.s(x1), t.s(234)], fill=renk)
        t.yazi((x0 + x1) / 2, 217, ad, 14, WHITE, True, "mm")
        t.paragraf(x0 + 14, 258, aciklama, 13.5, KOL_EN - 28, INK)

    # toplama
    for cx in MERKEZ:
        t.cizgi(cx, 306, cx, 330, FAINT, 1.4)
    t.cizgi(MERKEZ[0], 330, MERKEZ[3], 330, FAINT, 1.4)
    t.ok_asagi(450, 330, 358, FAINT)

    # 4 — kullanıcı kararı
    t.kutu((130, 358, 770, 448), 10, dolgu=WHITE, cerceve=LINE, kalinlik=1.6)
    t.yazi(450, 380, "Kararı kullanıcı verir", 15.5, INK, True, "mm")
    pw, pa = 186, 14
    px = 450 - (3 * pw + 2 * pa) / 2
    for i, s_ in enumerate(SECIM):
        x0 = px + i * (pw + pa)
        t.kutu((x0, 400, x0 + pw, 428), 14, dolgu=PAPER, cerceve=LINE, kalinlik=1.2)
        t.yazi(x0 + pw / 2, 414, s_, 13, MUTED, False, "mm")
    t.ok_asagi(450, 448, 476, FAINT)

    # 5 — gönderim
    t.kutu((310, 476, 590, 522), 10, dolgu=GREEN_BG, cerceve=GREEN, kalinlik=1.6)
    t.yazi(450, 499, "Gönderilir", 16, (27, 94, 67), True, "mm")
    t.ok_asagi(450, 522, 548, FAINT)

    # 6 — anonim sinyal
    t.kutu((32, 548, 868, 632), 10, dolgu=PAPER, cerceve=BRAND, kalinlik=1.6)
    t.yazi(52, 570, "ANONİM SİNYAL — METİN İÇERMEZ", 11.5, BRAND, True)
    t.yazi(848, 570, "Sinyal sınıfı yapısal olarak metin taşıyamaz",
           12, MUTED, False, "rm")
    sw, sa = 196, 12
    sx = 450 - (4 * sw + 3 * sa) / 2
    for i, s_ in enumerate(SINYAL):
        x0 = sx + i * (sw + sa)
        t.kutu((x0, 592, x0 + sw, 620), 14, dolgu=WHITE, cerceve=LINE, kalinlik=1.2)
        t.yazi(x0 + sw / 2, 606, s_, 12, INK, False, "mm")

    t.kaydet(hedef)


if __name__ == "__main__":
    ciz(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sekil5_akis.png"))
