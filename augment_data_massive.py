import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ml'))
import veri_deposu  # noqa: E402

data = veri_deposu.load()

# The user explicitly asked for "bütün küfürlerle sözlerle eğitilsin"
# Adding an extreme dataset augmentation of permutations.
massive_data = [
    {"text": "o.ç", "label": 1},
    {"text": "oç", "label": 1},
    {"text": "oc", "label": 1},
    {"text": "orospu", "label": 1},
    {"text": "kaltak", "label": 1},
    {"text": "sürtük", "label": 1},
    {"text": "piç", "label": 1},
    {"text": "p1ç", "label": 1},
    {"text": "p!ç", "label": 1},
    {"text": "pezevenk", "label": 1},
    {"text": "pzevenk", "label": 1},
    {"text": "gavat", "label": 1},
    {"text": "gvt", "label": 1},
    {"text": "yavşak", "label": 1},
    {"text": "yvsak", "label": 1},
    {"text": "ibne", "label": 1},
    {"text": "1bne", "label": 1},
    {"text": "göt veren", "label": 1},
    {"text": "götveren", "label": 1},
    {"text": "siktir git", "label": 1},
    {"text": "sg", "label": 1},
    {"text": "siktir", "label": 1},
    {"text": "ananı sikeyim", "label": 1},
    {"text": "amk", "label": 1},
    {"text": "aq", "label": 1},
    {"text": "amq", "label": 1},
    {"text": "amcık", "label": 1},
    {"text": "a.m.k", "label": 1},
    {"text": "yarrak", "label": 1},
    {"text": "yarak", "label": 1},
    {"text": "yrrk", "label": 1},
    {"text": "sokuk", "label": 1},
    {"text": "amına koyduğum", "label": 1},
    {"text": "amina kodumun", "label": 1},
    {"text": "göt lalesi", "label": 1},
    {"text": "fahişe", "label": 1},
    {"text": "kahpe", "label": 1},
    {"text": "veledi zina", "label": 1},
    {"text": "ananın amı", "label": 1},
    {"text": "babayı alırsın", "label": 1},
    {"text": "bok ye", "label": 1},
    {"text": "ezik herif", "label": 1},
    
    # Kapsamlı False Positive Korumaları
    {"text": "ocak ayında", "label": 0},
    {"text": "piknik yaptık", "label": 0},
    {"text": "yavru kedi", "label": 0},
    {"text": "götür beni gittiğin yere", "label": 0},
    {"text": "sıkıntı yok", "label": 0},
    {"text": "amiral gemisi", "label": 0},
    {"text": "sokak hayvanları", "label": 0},
    {"text": "fahiş fiyat", "label": 0},
    {"text": "kahverengi", "label": 0},
]

# Protokolün geliştirme kümesine (dev) YAZILMAZ — gerekçe: ml/veri_deposu.py
added = veri_deposu.add_augmented(data, massive_data, source='augment_data_massive')
veri_deposu.save(data)

print(f"Eklenen artırılmış örnek: {added} · toplam artırılmış: {len(data['augmented'])}")
