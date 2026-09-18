import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ml'))
import veri_deposu  # noqa: E402

data = veri_deposu.load()

threats = [
    "öldürürüm", "seni öldürürüm", "öldüreceğim", "seni öldüreceğim",
    "öldürücem", "seni öldürücem", "öldürürüz", "sizi öldürürüz",
    "öldür", "geber", "keseceğim", "seni keseceğim", "keserim", "seni keserim",
    "doğrarım", "seni doğrarım", "vururum", "seni vururum", "kafanıza sıkarım",
    "sıkacam", "seni gebertirim", "gebertecem", "yaşatmam", "seni yaşatmam"
]

new_entries = [{"text": t, "label": 1} for t in threats]

# Add variations
for t in threats:
    for v in (f"{t} lan", f"oğlum {t}", f"yarın {t}", f"hepinizi {t}", f"yemin ederim {t}"):
        new_entries.append({"text": v, "label": 1})

# Protokolün geliştirme kümesine (dev) YAZILMAZ — gerekçe: ml/veri_deposu.py
added = veri_deposu.add_augmented(data, new_entries, source='add_threats')
veri_deposu.save(data)

print(f"Added {added} threat entries to veri.json (augmented)")
