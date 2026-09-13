import json
import os
import random

FILE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ml', 'veri.json')

with open(FILE_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

existing_texts = {d['text'].lower() for d in data['dev']}

threats = [
    "öldürürüm", "seni öldürürüm", "öldüreceğim", "seni öldüreceğim", 
    "öldürücem", "seni öldürücem", "öldürürüz", "sizi öldürürüz",
    "öldür", "geber", "keseceğim", "seni keseceğim", "keserim", "seni keserim",
    "doğrarım", "seni doğrarım", "vururum", "seni vururum", "kafanıza sıkarım",
    "sıkacam", "seni gebertirim", "gebertecem", "yaşatmam", "seni yaşatmam"
]

new_entries = []
for t in threats:
    if t not in existing_texts:
        new_entries.append({"text": t, "label": 1})
        existing_texts.add(t)

# Add variations
for t in threats:
    variations = [
        f"{t} lan", f"oğlum {t}", f"yarın {t}", f"hepinizi {t}", f"yemin ederim {t}"
    ]
    for v in variations:
        if v not in existing_texts:
            new_entries.append({"text": v, "label": 1})
            existing_texts.add(v)

data['dev'].extend(new_entries)

with open(FILE_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Added {len(new_entries)} threat entries to veri.json")
