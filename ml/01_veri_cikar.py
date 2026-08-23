# -*- coding: utf-8 -*-
"""Dart eval kumelerinden (text, label, group) cikar."""
import io, re, json, os

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    '..', 'packages', 'civility_core', 'lib', 'src', 'eval')

CASE = re.compile(
    r"GoldCase\.(flag|clean)\s*\((.*?)\)\s*,\s*(?=GoldCase\.|\]|//|$)",
    re.S)

def field(body, name):
    # tek veya cift tirnak, kacisli tirnak destekli
    m = re.search(r"\b%s\s*:\s*'((?:[^'\\]|\\.)*)'" % name, body, re.S)
    if not m:
        m = re.search(r'\b%s\s*:\s*"((?:[^"\\]|\\.)*)"' % name, body, re.S)
    if m:
        return m.group(1).replace("\\'", "'").replace('\\"', '"').replace('\\\\', '\\')
    m = re.search(r"\b%s\s*:\s*([A-Za-z][\w.]*)" % name, body)
    return m.group(1) if m else None

def extract(path):
    src = io.open(path, encoding='utf-8').read()
    # yorum satirlarini at (string icindeki // korunsun diye satir basi kontrolu)
    rows, seen = [], set()
    for m in CASE.finditer(src):
        kind, body = m.group(1), m.group(2)
        txt = field(body, 'text')
        if not txt:
            continue
        grp = field(body, 'group') or ''
        grp = grp.split('.')[-1]
        key = txt.strip().lower()
        if key in seen:
            continue
        seen.add(key)
        rows.append({'text': txt.strip(), 'label': 1 if kind == 'flag' else 0, 'group': grp})
    return rows

dev = extract(os.path.join(BASE, 'gold_dataset.dart'))
hold = extract(os.path.join(BASE, 'holdout_dataset.dart'))

# kesisim kontrolu — sizinti olmamali
dset = {r['text'].strip().lower() for r in dev}
hset = {r['text'].strip().lower() for r in hold}
overlap = sorted(dset & hset)

print('gelistirme :', len(dev), ' flag=%d clean=%d' % (sum(r['label'] for r in dev), sum(1 - r['label'] for r in dev)))
print('ayrik      :', len(hold), ' flag=%d clean=%d' % (sum(r['label'] for r in hold), sum(1 - r['label'] for r in hold)))
print('ORTAK METIN:', len(overlap))
for o in overlap[:10]:
    print('   !', o)

print('\ndilim dagilimi (ayrik):')
from collections import Counter
for g, c in Counter(r['group'] for r in hold).most_common():
    print('  %-14s %d' % (g, c))

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'veri.json')
io.open(out, 'w', encoding='utf-8').write(
    json.dumps({'dev': dev, 'holdout': hold}, ensure_ascii=False, indent=1))
print('\nyazildi:', out)
print('\nornekler:')
for r in dev[:3] + hold[:3]:
    print('  [%d] %-10s %s' % (r['label'], r['group'][:10], r['text'][:60]))
