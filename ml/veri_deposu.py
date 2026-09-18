# -*- coding: utf-8 -*-
"""veri.json erişimi — artırılmış veri protokol kümelerinden AYRI tutulur.

── NEDEN (kod denetimi · docs/23) ───────────────────────────────────────────
Artırma betikleri (augment_*.py, add_threats.py, generate_massive_dataset.py)
ürettikleri şablon cümleleri doğrudan ``dev`` listesine ekliyordu. ``dev``,
02_egit_ve_olc.py protokolünün n=256'lık GELİŞTİRME KÜMESİDİR:

  • README'deki ölçümler (CV F0.5 %85,7; ayrık küme karşılaştırması) artık
    yeniden üretilemiyordu — küme ~10 bin şablon cümleye şişmişti.
  • Artırmalar ayrık kümeyle karşılaştırılmadığı için ayrık metinlerin
    eğitime sızması engellenmiyordu.

Artık artırmalar ``augmented`` anahtarına yazılır; protokol betikleri yalnızca
``dev``/``holdout`` okur, ``export_onnx.py`` ise açıkça ``dev + augmented``
ile eğitir. Ayrık kümede geçen hiçbir metin artırmaya giremez.
"""
import io
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PATH = os.path.join(HERE, 'veri.json')


def _key(text):
    return text.strip().lower()


def load():
    with io.open(PATH, encoding='utf-8') as f:
        data = json.load(f)
    data.setdefault('augmented', [])
    return data


def save(data):
    with io.open(PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=1)


def add_augmented(data, entries, source):
    """Artırılmış örnekleri ekler; dev/holdout/augmented ile çakışanları atar.

    Dönen değer eklenen örnek sayısıdır.
    """
    seen = {_key(r['text']) for split in ('dev', 'holdout', 'augmented')
            for r in data.get(split, [])}
    added = 0
    for entry in entries:
        text = entry['text'].strip()
        if not text or _key(text) in seen:
            continue
        seen.add(_key(text))
        data['augmented'].append({
            'text': text,
            'label': int(entry['label']),
            'group': entry.get('group', ''),
            'source': source,
        })
        added += 1
    return added
