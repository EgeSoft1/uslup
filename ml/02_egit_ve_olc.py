# -*- coding: utf-8 -*-
"""
Denetimli taban cizgisi: Turkce saldirgan dil siniflandirmasi.

PROTOKOL (rapordaki kurala birebir uyar):
  1. Model secimi YALNIZCA gelistirme kumesinde (256), 5-kat capraz dogrulama.
  2. Ayrik kumeye (80) TEK BIR KEZ, secim bittikten sonra bakilir.
  3. Sonuc duzeltme yapilmadan raporlanir.

Birincil hedef fonksiyon F0.5 -- yanlis pozitif, yanlis negatiften pahalidir.
"""
import io, json, os, sys, re
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.svm import LinearSVC
from sklearn.naive_bayes import MultinomialNB
from sklearn.calibration import CalibratedClassifierCV
from sklearn.pipeline import Pipeline, FeatureUnion
from sklearn.model_selection import StratifiedKFold, cross_val_predict
from sklearn.metrics import precision_score, recall_score, f1_score, fbeta_score, confusion_matrix

HERE = os.path.dirname(os.path.abspath(__file__))
RNG = 20260823

# ---------------------------------------------------------------- normalizasyon
LEET = {'0':'o','1':'i','3':'e','4':'a','5':'s','7':'t','@':'a','$':'s','€':'e'}
FOLD = str.maketrans('çğışöüÇĞİŞÖÜâîû', 'cgisouCGISOUaiu')

def tr_lower(s):
    return s.replace('I', 'ı').replace('İ', 'i').lower()

def normalize(s):
    s = tr_lower(s)
    s = ''.join(LEET.get(ch, ch) for ch in s)
    s = re.sub(r'[.\-_*]+(?=\w)', '', s)          # a.p.t.a.l -> aptal
    s = re.sub(r'(.)\1{2,}', r'\1', s)            # aptaaaal  -> aptal
    s = re.sub(r'\s+', ' ', s).strip()
    return s

def fold(s):
    return normalize(s).translate(FOLD)

# ---------------------------------------------------------------- veri
d = json.load(io.open(os.path.join(HERE, 'veri.json'), encoding='utf-8'))
Xd = [r['text'] for r in d['dev']];      yd = np.array([r['label'] for r in d['dev']])
Xh = [r['text'] for r in d['holdout']];  yh = np.array([r['label'] for r in d['holdout']])
gh = [r['group'] for r in d['holdout']]

# ---------------------------------------------------------------- adaylar
def charpipe(prep, lo, hi, clf, mindf=1):
    return Pipeline([
        ('tf', TfidfVectorizer(preprocessor=prep, analyzer='char_wb',
                               ngram_range=(lo, hi), min_df=mindf, sublinear_tf=True)),
        ('clf', clf)])

def wordpipe(prep, clf):
    return Pipeline([
        ('tf', TfidfVectorizer(preprocessor=prep, analyzer='word',
                               ngram_range=(1, 2), min_df=1, sublinear_tf=True)),
        ('clf', clf)])

def unionpipe(prep, clf):
    return Pipeline([
        ('tf', FeatureUnion([
            ('c', TfidfVectorizer(preprocessor=prep, analyzer='char_wb',
                                  ngram_range=(2, 5), min_df=1, sublinear_tf=True)),
            ('w', TfidfVectorizer(preprocessor=prep, analyzer='word',
                                  ngram_range=(1, 2), min_df=1, sublinear_tf=True))])),
        ('clf', clf)])

LR = lambda C: LogisticRegression(C=C, max_iter=4000, class_weight='balanced', random_state=RNG)
SVC = lambda C: LinearSVC(C=C, class_weight='balanced', random_state=RNG, max_iter=8000)

adaylar = {}
for pname, prep in (('ham', None), ('norm', normalize), ('katla', fold)):
    for lo, hi in ((2, 4), (2, 5), (3, 5)):
        for C in (1.0, 4.0, 10.0):
            adaylar['char%d-%d %s LR C=%g' % (lo, hi, pname, C)] = charpipe(prep, lo, hi, LR(C))
    for C in (0.5, 1.0):
        adaylar['char2-5 %s SVC C=%g' % (pname, C)] = charpipe(prep, 2, 5, SVC(C))
    adaylar['word %s LR C=4' % pname] = wordpipe(prep, LR(4.0))
    adaylar['birlesik %s LR C=4' % pname] = unionpipe(prep, LR(4.0))
    adaylar['char2-5 %s NB' % pname] = charpipe(prep, 2, 5, MultinomialNB(alpha=0.2))

# ---------------------------------------------------------------- 1) CV secimi
cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=RNG)
sonuc = []
for ad, pipe in adaylar.items():
    try:
        pred = cross_val_predict(pipe, Xd, yd, cv=cv, n_jobs=1)
    except Exception as e:
        continue
    sonuc.append((
        fbeta_score(yd, pred, beta=0.5, zero_division=0),
        f1_score(yd, pred, zero_division=0),
        precision_score(yd, pred, zero_division=0),
        recall_score(yd, pred, zero_division=0),
        ad))
sonuc.sort(reverse=True)

print('=' * 78)
print('1) MODEL SECIMI — gelistirme kumesi (n=256), 5-kat capraz dogrulama')
print('   siralama: F0.5 (birincil hedef fonksiyon)')
print('=' * 78)
print('%-30s %7s %7s %7s %7s' % ('aday', 'F0.5', 'F1', 'kesin', 'duyar'))
for f05, f1, p, r, ad in sonuc[:12]:
    print('%-30s %6.1f%% %6.1f%% %6.1f%% %6.1f%%' % (ad, f05*100, f1*100, p*100, r*100))

best_name = sonuc[0][4]
best = adaylar[best_name]
print('\nSECILEN: %s   (CV F0.5=%.1f%%, F1=%.1f%%)' % (best_name, sonuc[0][0]*100, sonuc[0][1]*100))

# ---------------------------------------------------------------- 2) ayrik olcum
print('\n' + '=' * 78)
print('2) AYRIK KUME OLCUMU (n=80) — tek sefer, duzeltme yok')
print('=' * 78)
best.fit(Xd, yd)
ph = best.predict(Xh)

P = precision_score(yh, ph, zero_division=0)
R = recall_score(yh, ph, zero_division=0)
F1 = f1_score(yh, ph, zero_division=0)
F05 = fbeta_score(yh, ph, beta=0.5, zero_division=0)
tn, fp, fn, tp = confusion_matrix(yh, ph, labels=[0, 1]).ravel()

print('kesinlik  %.1f%%   duyarlilik %.1f%%   F1 %.1f%%   F0.5 %.1f%%'
      % (P*100, R*100, F1*100, F05*100))
print('karisiklik: TP=%d  FP=%d  FN=%d  TN=%d' % (tp, fp, fn, tn))

print('\nKURAL MOTORU (ayni kume, rapordaki sayi):')
print('kesinlik  88.9%   duyarlilik 80.0%   F1 84.2%')
print('fark      %+.1f pt kesinlik   %+.1f pt duyarlilik   %+.1f pt F1'
      % (P*100-88.9, R*100-80.0, F1*100-84.2))

# ---------------------------------------------------------------- dilim
print('\nDILIM BAZINDA (model):')
print('%-14s %5s %8s %8s' % ('dilim', 'n', 'dogru', 'duyar'))
for g in sorted(set(gh)):
    idx = [i for i, x in enumerate(gh) if x == g]
    yy, pp = yh[idx], ph[idx]
    acc = (yy == pp).mean()
    pos = yy.sum()
    rec = (pp[yy == 1].sum() / pos) if pos else float('nan')
    print('%-14s %5d %7.1f%% %8s' % (g, len(idx), acc*100,
          ('%.1f%%' % (rec*100)) if pos else '—'))

# ---------------------------------------------------------------- 3) guven araligi
print('\n' + '=' * 78)
print('3) BOOTSTRAP %95 GUVEN ARALIGI (n=80, 5000 yeniden ornekleme)')
print('=' * 78)
rs = np.random.RandomState(RNG)
f1s, f05s = [], []
for _ in range(5000):
    idx = rs.randint(0, len(yh), len(yh))
    if len(set(yh[idx])) < 2:
        continue
    f1s.append(f1_score(yh[idx], ph[idx], zero_division=0))
    f05s.append(fbeta_score(yh[idx], ph[idx], beta=0.5, zero_division=0))
f1s, f05s = np.array(f1s), np.array(f05s)
print('model F1   %.1f%%  [%.1f%% – %.1f%%]'
      % (F1*100, np.percentile(f1s, 2.5)*100, np.percentile(f1s, 97.5)*100))
print('model F0.5 %.1f%%  [%.1f%% – %.1f%%]'
      % (F05*100, np.percentile(f05s, 2.5)*100, np.percentile(f05s, 97.5)*100))
print('\nNot: n=80 icin aralik genistir. Kural motorunun %84,2 degeri bu araligin')
print('     icindeyse iki yaklasim arasindaki fark ISTATISTIKSEL OLARAK ANLAMLI DEGILDIR.')

# ---------------------------------------------------------------- 4) ogrenme egrisi
print('\n' + '=' * 78)
print('4) OGRENME EGRISI — "daha fazla veri ise yarar mi?"')
print('=' * 78)
print('%8s %8s %8s' % ('egitim n', 'F1', 'kesin'))
for frac in (0.25, 0.5, 0.75, 1.0):
    n = int(len(Xd) * frac)
    f1acc, pacc = [], []
    for seed in range(5):
        r2 = np.random.RandomState(RNG + seed)
        idx = r2.permutation(len(Xd))[:n]
        if len(set(yd[idx])) < 2:
            continue
        m = adaylar[best_name]
        m.fit([Xd[i] for i in idx], yd[idx])
        pp = m.predict(Xh)
        f1acc.append(f1_score(yh, pp, zero_division=0))
        pacc.append(precision_score(yh, pp, zero_division=0))
    print('%8d %7.1f%% %7.1f%%' % (n, np.mean(f1acc)*100, np.mean(pacc)*100))

# ---------------------------------------------------------------- 5) hatalar
best.fit(Xd, yd)
ph = best.predict(Xh)
print('\n' + '=' * 78)
print('5) MODELIN HATALARI (ayrik kume)')
print('=' * 78)
print('\nYANLIS POZITIF (masum metni isaretledi) — en pahali hata:')
nfp = 0
for i in range(len(yh)):
    if yh[i] == 0 and ph[i] == 1:
        nfp += 1
        print('  [%s] %s' % (gh[i][:12], Xh[i]))
if not nfp:
    print('  (yok)')
print('\nYANLIS NEGATIF (saldirgani kacirdi):')
nfn = 0
for i in range(len(yh)):
    if yh[i] == 1 and ph[i] == 0:
        nfn += 1
        print('  [%s] %s' % (gh[i][:12], Xh[i]))
if not nfn:
    print('  (yok)')

json.dump({'best': best_name,
           'holdout': {'precision': P, 'recall': R, 'f1': F1, 'f05': F05,
                       'tp': int(tp), 'fp': int(fp), 'fn': int(fn), 'tn': int(tn)},
           'ci_f1': [float(np.percentile(f1s, 2.5)), float(np.percentile(f1s, 97.5))],
           'cv_top': [(a, float(x)) for x, _, _, _, a in sonuc[:5]]},
          io.open(os.path.join(HERE, 'model_sonuc.json'), 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)
print('\nyazildi: model_sonuc.json')
