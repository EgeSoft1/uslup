# -*- coding: utf-8 -*-
"""EK-1 resmi ek belgesi gorseli — itiraz formunun 'Gorsel' alanina yuklenir."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
import textwrap

LACI, SIYAH, GRI, KIRMIZI = "#1a3054", "#101010", "#555555", "#8f2020"
W = 13.4                      # inc
SOL, SAG = 0.55, 0.55
IC = W - SOL - SAG

SATIR = [
    ("7.1  İş Paketleri ve Zamanlama", "4 / 5",
     "s.30 — Şekil 9 zaman çizelgesi: on bir tamamlanan iş paketinin yanı sıra planlanan beş iş "
     "paketi (İP-14…İP-18) ve dört kilometre taşı, 20 Eylül 2026'ya kadar tarihleriyle birlikte "
     "gösterilmiştir."),
    ("4.1  Verimlilik ve Etkinlik", "4 / 5",
     "s.25-26 — Ölçülen çözümleme süresi 87-193 µs (60 FPS kare bütçesinin %1,2'si); sıfır marjinal "
     "çıkarım maliyeti; varsayımları açıkça yazılmış dört senaryoluk duyarlılık modeli."),
    ("4.2  Hedef Kitle", "4 / 5",
     "s.26-27 — Birincil ve beş ikincil hedef kitle; büyüklük üç resmî kaynakla (TÜİK, DataReportal, "
     "UNFPA-KONDA). s.24'te dört persona; ikisi kabul testiyle korunmaktadır."),
    ("2.2  Çözüm Fikri, Özgünlük ve Yerlilik", "7 / 8",
     "s.13-17 — Şekil 7'deki A/B ölçümünde duyarlılık %44,0'ten %99,3'e çıkarken kesinlik %100,0'de "
     "sabit kalmıştır. s.17: bağımlılık listesi boş, çalışma zamanında ağ çağrısı yok."),
    ("1.2  Proje Kapsamı ve Yöntemi", "7 / 8",
     "s.4 — Tablo 3 kapsam sınırlarını gerekçeleriyle, Tablo 2 şartname hedefleriyle eşlemeyi verir. "
     "Teknik yöntem s.8'deki Şekil 1; akademik yöntem beş dilimli işlevsel test ve F0.5."),
    ("6.1  Ticarileştirme ve İş Modeli", "4 / 5",
     "s.28 — Dört gelir kanalı, her biri müşteri segmenti ve gelir modeliyle tanımlı. Pazar penceresi "
     "kaynağa bağlı: Perspective API'nin 31.12.2026 kapanışı."),
    ("6.2  Finansal, Teknik ve Sosyal Sürdürülebilirlik", "3 / 5",
     "s.29 — Sıfır altyapı gideri; bağımlılıksız çekirdek ve 136 test + 336 örneklik regresyon "
     "kalkanı. Sosyal boyut s.27-28'de, yapısal testlerle kod düzeyinde kilitli."),
]

C1, C2 = 4.30, 1.05                    # kriter ve puan sutun genislikleri
C3 = IC - C1 - C2
SARMA = 96
yuk = [max(2, len(textwrap.wrap(k, SARMA))) * 0.205 + 0.20 for _, _, k in SATIR]
BAS_Y, TABLO_BAS = 1.52, 0.40
H = BAS_Y + TABLO_BAS + sum(yuk) + 0.92

fig = plt.figure(figsize=(W, H), dpi=185)
fig.patch.set_facecolor("white")
ax = fig.add_axes([0, 0, 1, 1]); ax.set_xlim(0, W); ax.set_ylim(0, H); ax.axis("off")

# --- ust bilgi -------------------------------------------------------------
ax.text(SOL, H - 0.34, "EK-1", fontsize=10.5, color=KIRMIZI, fontweight="bold", va="center")
ax.text(SOL, H - 0.68, "PUAN KIRILAN ALT KRİTERLERİN RAPORDAKİ KARŞILIKLARI",
        fontsize=16.5, fontweight="bold", color=LACI, va="center")
ax.text(SOL, H - 1.00,
        "2026 NSosyal İnovasyon Yarışması  ·  Takım: Aliz AI (#1004097)  ·  Başvuru: #5394579  ·  "
        "Toplam puan: 92,00",
        fontsize=10.2, color=SIYAH, va="center")
ax.text(SOL, H - 1.24,
        "Sayfa numaraları, 24.08.2026 tarihinde başvuru sistemine yüklenen Teknik Tasarım "
        "Raporu'nun PDF sayfa numaralarıdır.",
        fontsize=9.3, color=GRI, style="italic", va="center")

# --- tablo basligi ---------------------------------------------------------
y = H - BAS_Y
ax.add_patch(Rectangle((SOL, y - TABLO_BAS), IC, TABLO_BAS, facecolor=LACI, edgecolor=LACI))
ax.text(SOL + 0.12, y - TABLO_BAS / 2, "Alt kriter", fontsize=10, fontweight="bold",
        color="white", va="center")
ax.text(SOL + C1 + C2 / 2, y - TABLO_BAS / 2, "Puan", fontsize=10, fontweight="bold",
        color="white", ha="center", va="center")
ax.text(SOL + C1 + C2 + 0.12, y - TABLO_BAS / 2, "Kriterin aradığı unsurun rapordaki karşılığı",
        fontsize=10, fontweight="bold", color="white", va="center")
y -= TABLO_BAS

# --- satirlar --------------------------------------------------------------
for i, ((kriter, puan, kanit), h) in enumerate(zip(SATIR, yuk)):
    if i % 2 == 1:
        ax.add_patch(Rectangle((SOL, y - h), IC, h, facecolor="#f2f5fa", edgecolor="none"))
    ax.add_patch(Rectangle((SOL, y - h), IC, h, facecolor="none", edgecolor="#9aa4b4", lw=0.7))
    ax.plot([SOL + C1] * 2, [y - h, y], color="#9aa4b4", lw=0.7)
    ax.plot([SOL + C1 + C2] * 2, [y - h, y], color="#9aa4b4", lw=0.7)
    ax.text(SOL + 0.12, y - 0.20, "\n".join(textwrap.wrap(kriter, 34)), fontsize=10.2,
            fontweight="bold", color=SIYAH, va="top", linespacing=1.45)
    ax.text(SOL + C1 + C2 / 2, y - h / 2, puan, fontsize=11, fontweight="bold",
            color=KIRMIZI, ha="center", va="center")
    ax.text(SOL + C1 + C2 + 0.12, y - 0.20, "\n".join(textwrap.wrap(kanit, SARMA)),
            fontsize=9.1, color="#1c2635", va="top", linespacing=1.5)
    y -= h

# --- dipnot ----------------------------------------------------------------
ax.text(SOL, y - 0.34,
        "Raporun bütün sayısal sonuçları MIT lisanslı açık depoda tek komutla yeniden "
        "üretilebilir:  github.com/EgeSoft1/uslup",
        fontsize=9.4, color=LACI, fontweight="bold", va="top")
ax.text(SOL, y - 0.60,
        "İtirazımız, raporda bulunmayan bir içeriğin sonradan eklenmesi talebi değildir; teslim "
        "edilen raporda hâlihazırda bulunan unsurların yeniden değerlendirilmesi talebidir.",
        fontsize=9.0, color=GRI, va="top")

fig.savefig("itiraz_gorseli.png", facecolor="white", bbox_inches="tight", pad_inches=0.26)
print("yazildi: itiraz_gorseli.png")
