#!/usr/bin/env python3
# =============================================================================
# Uygulama ikonu üreteci
# Dosya: mobile/tool/ikon_uret.py
#
# Kullanım:
#     cd mobile && python tool/ikon_uret.py
#     dart run flutter_launcher_icons          # mipmap'leri yeniden üretir
#
# ── NEDEN BU ARAÇ VAR ─────────────────────────────────────────────────────
# Önceki ikon devralınan mesajlaşma uygulamasından kalmıştı: kırmızı zemin,
# ay-yıldız, sohbet balonu ve bir ASMA KİLİT. Kilit, uçtan uca şifreleme
# imasıydı — teknik borç belgesinin (docs/02 §1) "ölçülmemiş, doğru değil"
# diye kaldırdığı iddianın ta kendisi. Yani ikon, ürünün artık yapmadığı bir
# şeyi telefonun ana ekranında ilan ediyordu.
#
# Yeni ikon uygulamadaki `BrandMark` bileşeninin birebir karşılığıdır:
# camgöbeği→mavi gradyan üzerine beyaz "Ü". Elle çizilmek yerine ÜRETİLİR,
# çünkü marka renkleri değiştiğinde ikonun da değişmesi gerekir ve elle
# çizilmiş bir dosya sessizce eskir.
#
# Renkler `lib/core/theme/app_palette.dart` içindeki AppColors.brandCyan ve
# brandIndigo ile aynıdır; yazı tipi `assets/fonts/Outfit-Variable.ttf`.
# =============================================================================

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BOYUT = 1024

# app_palette.dart · AppColors.brandCyan / brandIndigo
CAMGOBEGI = (0x35, 0xC6, 0xEA)
INDIGO = (0x4A, 0x6C, 0xF7)

KOK = Path(__file__).resolve().parent.parent
YAZI_TIPI = KOK / "assets" / "fonts" / "Outfit-Variable.ttf"
CIKTI = KOK / "assets" / "images" / "app_icon.png"


def gradyan(boyut: int) -> Image.Image:
    """Sol üstten sağ alta çapraz gradyan.

    Dikey bir gradyanı 45 derece döndürmek yerine her piksel tek tek
    hesaplanıyor; döndürme kenarlarda saydam üçgenler bırakıyordu.
    """
    img = Image.new("RGB", (boyut, boyut))
    pikseller = img.load()
    for y in range(boyut):
        for x in range(boyut):
            # Çapraz eksende 0..1 arası konum.
            t = (x + y) / (2 * (boyut - 1))
            pikseller[x, y] = (
                round(CAMGOBEGI[0] + (INDIGO[0] - CAMGOBEGI[0]) * t),
                round(CAMGOBEGI[1] + (INDIGO[1] - CAMGOBEGI[1]) * t),
                round(CAMGOBEGI[2] + (INDIGO[2] - CAMGOBEGI[2]) * t),
            )
    return img


def hale(img: Image.Image) -> None:
    """Sol üstte yumuşak beyaz ışık halesi — yüzeyi düz olmaktan çıkarır."""
    katman = Image.new("RGBA", img.size, (255, 255, 255, 0))
    ciz = ImageDraw.Draw(katman)
    merkez = (BOYUT * 0.30, BOYUT * 0.24)
    en_buyuk = BOYUT * 0.62
    # İç içe daireler: dıştan içe artan opaklık, yumuşak geçiş verir.
    adim = 90
    for i in range(adim, 0, -1):
        r = en_buyuk * i / adim
        alfa = round(26 * (1 - i / adim) ** 2)
        if alfa <= 0:
            continue
        ciz.ellipse(
            [merkez[0] - r, merkez[1] - r, merkez[0] + r, merkez[1] + r],
            fill=(255, 255, 255, alfa),
        )
    img.paste(Image.alpha_composite(img.convert("RGBA"), katman).convert("RGB"))


def yazi_tipi_yukle(punto: int) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(YAZI_TIPI), punto)
    # Değişken yazı tipi: ağırlık `wght` ekseninden gelir. Eksen
    # ayarlanmazsa varsayılan (400) çizilir ve marka harfi cılız kalır.
    try:
        font.set_variation_by_axes([800])
    except (AttributeError, OSError):
        # FreeType değişken eksen desteği yoksa 400 ağırlıkla devam edilir;
        # ikon üretilir ama daha ince görünür.
        print("UYARI: değişken eksen ayarlanamadı, varsayılan ağırlık kullanılıyor")
    return font


def main() -> None:
    if not YAZI_TIPI.exists():
        raise SystemExit(f"Yazı tipi bulunamadı: {YAZI_TIPI}")

    img = gradyan(BOYUT)
    hale(img)

    ciz = ImageDraw.Draw(img)
    font = yazi_tipi_yukle(round(BOYUT * 0.58))

    # Harfi gerçek sınırlayıcı kutusuna göre ortala. "Ü" iki noktası
    # yüzünden asimetriktir; `anchor="mm"` tek başına onu optik merkeze
    # oturtmuyor, bu yüzden kutu ölçülüp elle kaydırılıyor.
    kutu = ciz.textbbox((0, 0), "Ü", font=font)
    genislik = kutu[2] - kutu[0]
    yukseklik = kutu[3] - kutu[1]
    x = (BOYUT - genislik) / 2 - kutu[0]
    y = (BOYUT - yukseklik) / 2 - kutu[1]

    ciz.text((x, y), "Ü", font=font, fill=(255, 255, 255))

    CIKTI.parent.mkdir(parents=True, exist_ok=True)
    img.save(CIKTI, "PNG")
    print(f"Yazıldı: {CIKTI}  ({BOYUT}x{BOYUT})")


if __name__ == "__main__":
    main()
