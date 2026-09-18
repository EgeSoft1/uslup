"""SÖZLÜĞE OTOMATİK GİRDİ ÜRETEN BETİK — DEVRE DIŞI (kod denetimi · docs/23)

Bu betik 50 kök × 14 ekin permütasyonlarından 8.000'e kadar girdiyi
`toxicity_lexicon.dart` dosyasına, hepsini `hakaret · 0.75` olarak ve TAM
EŞLEŞME kipinde ekliyordu. Çalıştırılsaydı:

  • "it" + "in"  → "itin"   · "mal" + "ın" → "malın"  · "hayvan" + "lar"
    gibi Türkçenin en sık kelimeleri hakaret olurdu ("malın fiyatı",
    "hayvanlar alemi"). Sözlüğün `requiresDirection`, `maskedPrefixes` ve
    kısa kök çakışma listesi korumalarının HİÇBİRİ bu girdilere uygulanmazdı.
  • Motor zaten kök + ek çözümlemesini `TurkishMorphology` ile yapıyor;
    çekimli biçimleri tek tek yazmak gereksizdir ve ünlü uyumunu da
    denetlemez ("aptalsın" ile birlikte "aptalsun" da girer).
  • Mutlak yol (c:\\TurkiyeMesajlasma\\...) başka bir makinede çalışmaz.

Her sözlük girdisi bir kesinlik kararıdır ve bir ölçümle birlikte eklenir
(README · "Ölçüm geçmişi"). Toplu ekleme o disiplini atlar. Betik bu yüzden
hiçbir şey yazmadan çıkar; tarihsel kayıt için depoda bırakılmıştır.
"""
import sys

sys.exit(
    "expand_dart_lexicon.py devre dışı: sözlüğe toplu, ölçümsüz girdi eklemek "
    "kesinlik iddiasını bozar. Gerekçe bu dosyanın başında ve docs/23'te."
)
