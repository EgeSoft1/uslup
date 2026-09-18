import itertools
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ml'))
import veri_deposu  # noqa: E402

data = veri_deposu.load()

existing_texts = set()
new_entries = []

roots = ["am", "amcık", "yarrak", "siktir", "göt", "orospu", "piç", "kahpe", "kaltak", "fahişe", "gavat", "ibne", "yavşak", "pezevenk"]
prefixes = ["", "senin ", "ananı ", "avradını ", "sülaleni ", "geçmişini ", "yedi sülaleni "]
suffixes = ["", " sikeyim", " sikecem", " sikicem", " sokam", " koyim", " koyayım", " yiyeyim"]

def add_entry(text, label=1):
    t = text.strip()
    if t and t.lower() not in existing_texts:
        new_entries.append({"text": t, "label": label})
        existing_texts.add(t.lower())


# Tekrarlanabilirlik: leet varyantları rastgele üretilir; tohum sabitlenmezse
# her çalıştırma farklı bir eğitim kümesi (ve farklı bir ONNX modeli) üretir.
random.seed(20260823)

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

# Protokolün geliştirme kümesine (dev) YAZILMAZ — gerekçe: ml/veri_deposu.py
added = veri_deposu.add_augmented(data, new_entries, source='augment_1000')
veri_deposu.save(data)

print(f"Eklenen artırılmış örnek: {added} · toplam artırılmış: {len(data['augmented'])}")
