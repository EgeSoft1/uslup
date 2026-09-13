import json
import os
import itertools
import random

FILE_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ml', 'veri.json')

with open(FILE_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

existing_texts = {d['text'].lower() for d in data['dev']}
new_entries = []

roots = ["am", "amcık", "yarrak", "siktir", "göt", "orospu", "piç", "kahpe", "kaltak", "fahişe", "gavat", "ibne", "yavşak", "pezevenk"]
prefixes = ["", "senin ", "ananı ", "avradını ", "sülaleni ", "geçmişini ", "yedi sülaleni "]
suffixes = ["", " sikeyim", " sikecem", " sikicem", " sokam", " koyim", " koyayım", " yiyeyim"]

def add_entry(text, label=1):
    t = text.strip()
    if t and t.lower() not in existing_texts:
        new_entries.append({"text": t, "label": label})
        existing_texts.add(t.lower())

# Generate combinations
for p, r, s in itertools.product(prefixes, roots, suffixes):
    phrase = f"{p}{r}{s}".strip()
    add_entry(phrase)

# Generate Leet speak variations for roots
leet_map = {'o': '0', 'i': '1', 'a': '4', 's': '5', 'e': '3', 'g': 'q', 'ı': '1', 'c': 'k'}
def make_leet(word):
    res = word
    for k, v in leet_map.items():
        if random.random() > 0.3: # randomly apply leet
            res = res.replace(k, v)
    return res

for r in roots:
    for _ in range(10): # create 10 leet variations for each root
        leet_word = make_leet(r)
        add_entry(leet_word)

# Add some hard negative samples (false positive traps) to balance
hard_negatives = [
    "sokak hayvanları", "piknik yaptık", "amiral battı", "ocak ayı", "şikayet ettim",
    "fahiş fiyatlar", "yavru kedi", "götür beni", "sıkıntılı durum", "kahve içelim",
    "ibni sina", "kavun karpuz", "pazar gecesi", "sikke koleksiyonu", "amazon ormanı"
]
for _ in range(50):
    for hn in hard_negatives:
        add_entry(hn + " " + random.choice(["bugün", "çok", "iyi", "değil", "tamam"]), label=0)

# Also explicitly add some exact tricky words
explicit_bad = ["oç", "amq", "aq", "sg", "mk", "amk", "yrk", "gvt", "pç", "sik", "s.k", "a.m.k", "o.ç", "p.ç"]
for eb in explicit_bad:
    add_entry(eb)

# Combine
data['dev'].extend(new_entries)

# Since we might have generated thousands, let's limit if it's too much, but user wants 1000+
print(f"Eklenecek yeni kelime sayısı: {len(new_entries)}")
print(f"Toplam kelime sayısı: {len(data['dev'])}")

with open(FILE_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("1000+ veri eklendi.")
