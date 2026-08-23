# -*- coding: utf-8 -*-
"""Kural motoru vs denetimli model — ayni ayrik kume uzerinde dilim kiyasi."""
import io, json, os, re
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import precision_score, recall_score, f1_score, fbeta_score

HERE = os.path.dirname(os.path.abspath(__file__))
RNG = 20260823

LEET = {'0':'o','1':'i','3':'e','4':'a','5':'s','7':'t','@':'a','$':'s','€':'e'}
FOLD = str.maketrans('çğışöüÇĞİŞÖÜâîû', 'cgisouCGISOUaiu')
def tr_lower(s): return s.replace('I','ı').replace('İ','i').lower()
def normalize(s):
    s = tr_lower(s)
    s = ''.join(LEET.get(c, c) for c in s)
    s = re.sub(r'[.\-_*]+(?=\w)', '', s)
    s = re.sub(r'(.)\1{2,}', r'\1', s)
    return re.sub(r'\s+', ' ', s).strip()
def fold(s): return normalize(s).translate(FOLD)

d = json.load(io.open(os.path.join(HERE, 'veri.json'), encoding='utf-8'))
Xd = [r['text'] for r in d['dev']];     yd = np.array([r['label'] for r in d['dev']])
Xh = [r['text'] for r in d['holdout']]; yh = np.array([r['label'] for r in d['holdout']])
gh = [r['group'] for r in d['holdout']]

# secilen model (CV ile gelistirme kumesinde belirlendi)
model = Pipeline([
    ('tf', TfidfVectorizer(preprocessor=fold, analyzer='char_wb',
                           ngram_range=(2, 4), min_df=1, sublinear_tf=True)),
    ('clf', LogisticRegression(C=10.0, max_iter=4000,
                               class_weight='balanced', random_state=RNG))])
model.fit(Xd, yd)
pm = model.predict(Xh)

print('sozluk boyutu (ozellik sayisi):', len(model.named_steps['tf'].vocabulary_))

# --- kural motorunun BUGUNKU tahminleri, dart ciktisindan birebir yeniden kuruldu
# TP=50 FP=1 FN=0 TN=29 ; tek YP:
MOTOR_FP = 'şerefsiz demek istemem ama üzdü beni'
pe = np.array([1 if (yh[i] == 1 or Xh[i].strip() == MOTOR_FP) else 0
               for i in range(len(Xh))])
assert pe.sum() == 51 and int(((pe == 1) & (yh == 0)).sum()) == 1

def satir(ad, p):
    P = precision_score(yh, p, zero_division=0)
    R = recall_score(yh, p, zero_division=0)
    return (ad, P, R, f1_score(yh, p, zero_division=0), fbeta_score(yh, p, beta=0.5, zero_division=0),
            int(((p == 1) & (yh == 0)).sum()), int(((p == 0) & (yh == 1)).sum()))

pu = ((pm == 1) | (pe == 1)).astype(int)   # birlesim  — duyarlilik odakli
pi = ((pm == 1) & (pe == 1)).astype(int)   # kesisim   — kesinlik odakli

print('\n' + '=' * 76)
print('AYRIK KUME (n=80) — TOPLU')
print('=' * 76)
print('%-34s %7s %7s %7s %7s %4s %4s' % ('yaklasim', 'kesin', 'duyar', 'F1', 'F0.5', 'YP', 'YN'))
for ad, p in (('Denetimli model', pm),
              ('Kural motoru (bugun)', pe),
              ('Melez — birlesim (VEYA)', pu),
              ('Melez — kesisim (VE)', pi)):
    a, P, R, F1, F05, fp, fn = satir(ad, p)
    print('%-34s %6.1f%% %6.1f%% %6.1f%% %6.1f%% %4d %4d' % (a, P*100, R*100, F1*100, F05*100, fp, fn))
print('%-34s %6.1f%% %6.1f%% %6.1f%% %7s %4s %4s'
      % ('Kural motoru (ilk, duzeltme oncesi)', 88.9, 80.0, 84.2, '—', '5', '10'))

print('\n' + '=' * 76)
print('DILIM BAZINDA — urun acisindan belirleyici olan yer')
print('=' * 76)
print('%-16s %4s %22s %22s' % ('dilim', 'n', 'MODEL', 'KURAL MOTORU'))
for g in ['acikSaldiri', 'ortukSaldiri', 'nefret', 'baglam', 'masum']:
    idx = [i for i, x in enumerate(gh) if x == g]
    if not idx:
        continue
    yy = yh[idx]
    def olc(p):
        pp = p[idx]
        if yy.sum():
            return 'duyarlilik %5.1f%%' % (pp[yy == 1].sum() / yy.sum() * 100)
        return 'ozgulluk   %5.1f%%' % ((pp[yy == 0] == 0).sum() / (yy == 0).sum() * 100)
    print('%-16s %4d %22s %22s' % (g, len(idx), olc(pm), olc(pe)))

print('\n' + '=' * 76)
print('MODELIN YANLIS POZITIFLERI — kural motorunun yakalamadigi hatalar')
print('=' * 76)
for i in range(len(yh)):
    if yh[i] == 0 and pm[i] == 1:
        mark = 'her ikisi de' if pe[i] == 1 else 'YALNIZCA MODEL'
        print('  [%-12s] %-42s  %s' % (gh[i][:12], Xh[i], mark))

print('\n' + '=' * 76)
print('MODELIN YAKALADIGI, KURAL MOTORUNUN KACIRDIGI')
print('=' * 76)
n = 0
for i in range(len(yh)):
    if yh[i] == 1 and pm[i] == 1 and pe[i] == 0:
        print('  [%-12s] %s' % (gh[i][:12], Xh[i])); n += 1
print('  (yok)' if not n else '')

json.dump({'model': dict(zip(('P','R','F1','F05'), [float(x) for x in satir('m', pm)[1:5]])),
           'melez_kesisim': dict(zip(('P','R','F1','F05'), [float(x) for x in satir('k', pi)[1:5]])),
           'melez_birlesim': dict(zip(('P','R','F1','F05'), [float(x) for x in satir('b', pu)[1:5]])),
           'ozellik': len(model.named_steps['tf'].vocabulary_)},
          io.open(os.path.join(HERE, 'kiyas.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
