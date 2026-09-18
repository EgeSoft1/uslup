# -*- coding: utf-8 -*-
"""Uygulamaya PAKETLENEN ONNX modelinin ölçümü (docs/24 · madde 22).

README ve 02_egit_ve_olc.py karakter n-gram modelini ölçer. Uygulamada duran
model ise export_onnx.py ile üretilen kelime n-gram modelidir ve hiç
ölçülmemişti. Bu betik iki soruyu cevaplar:

  1. BAĞIMSIZ: model tek başına karar verseydi etiketli kümelerde ne yapardı?
  2. MELEZ SÖZLEŞME: uygulamadaki kural — model yalnızca motorun ZATEN
     işaretlediği bir metnin skorunu yükseltebilir, ortalama (motor + model)/2
     motorun skorundan yüksekse kullanılır — risk BASAMAĞINI kaç cümlede
     değiştiriyor? Basamak ürün davranışıdır: Yüksek risk onay diyaloğu açar.

Çalıştırma:
  cd packages/civility_core
  dart run bin/hibrit_disa_aktar.dart > ../../ml/motor_ciktisi.json
  cd ../../ml
  python 04_paket_modeli_olc.py
"""
import io
import json
import os
from collections import Counter, defaultdict

import numpy as np
import onnxruntime as ort

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(HERE, '..', 'mobile', 'assets', 'models', 'uslup_model.onnx')
MOTOR = os.path.join(HERE, 'motor_ciktisi.json')

ESIK = 0.5  # onnx_classifier_io.dart · _modelThreshold


def basamak(t):
    # civility_engine.dart · _riskFrom ile aynı eşikler
    if t < 0.15:
        return 'temiz'
    if t < 0.40:
        return 'dikkat'
    if t < 0.70:
        return 'riskli'
    return 'yuksek'


def main():
    satirlar = json.load(io.open(MOTOR, encoding='utf-8-sig'))
    oturum = ort.InferenceSession(MODEL, providers=['CPUExecutionProvider'])
    girdi = oturum.get_inputs()[0].name

    # Uygulama modeli HAM metinle çağırır (onnx_classifier_io.dart).
    metinler = np.array([[s['text']] for s in satirlar], dtype=object)
    ciktilar = oturum.run(None, {girdi: metinler})
    olasilik = ciktilar[1][:, 1]

    print('=' * 78)
    print('PAKETLENEN ONNX MODELİ — %d etiketli cümle, %d küme'
          % (len(satirlar), len({s['kume'] for s in satirlar})))
    print('=' * 78)

    # ── 1. Bağımsız ölçüm ────────────────────────────────────────────────────
    print('\n1) BAĞIMSIZ — model tek başına karar verseydi (eşik %.1f)' % ESIK)
    print('%-12s %5s %9s %9s %6s %6s' % ('küme', 'n', 'kesinlik', 'duyarlılık', 'YP', 'YN'))
    kume_satir = defaultdict(list)
    for s, p in zip(satirlar, olasilik):
        kume_satir[s['kume']].append((s, p))
    for kume, liste in kume_satir.items():
        tp = sum(1 for s, p in liste if s['label'] == 1 and p > ESIK)
        fp = sum(1 for s, p in liste if s['label'] == 0 and p > ESIK)
        fn = sum(1 for s, p in liste if s['label'] == 1 and p <= ESIK)
        kes = tp / (tp + fp) if tp + fp else float('nan')
        duy = tp / (tp + fn) if tp + fn else float('nan')
        print('%-12s %5d %8.1f%% %8.1f%% %6d %6d'
              % (kume, len(liste), kes * 100, duy * 100, fp, fn))

    # ── 2. Melez sözleşme ────────────────────────────────────────────────────
    print('\n2) MELEZ SÖZLEŞME — uygulamadaki kural')
    degisim = Counter()
    ornekler = []
    for s, p in zip(satirlar, olasilik):
        once = s['risk']
        if once == 'temiz' or p <= ESIK:
            continue
        karisim = (s['toxicity'] + p) / 2
        if karisim <= s['toxicity']:
            continue
        sonra = basamak(karisim)
        if sonra != once:
            degisim[(once, sonra, s['label'])] += 1
            if len(ornekler) < 12:
                ornekler.append((once, sonra, s['label'], p, s['text']))

    toplam = sum(degisim.values())
    print('  Basamağı değişen cümle: %d / %d' % (toplam, len(satirlar)))
    for (once, sonra, etiket), n in sorted(degisim.items()):
        print('    %-7s → %-7s  %s  %d' % (once, sonra,
              'saldırgan' if etiket else 'MASUM    ', n))
    masum_yuksek = sum(n for (o, s, e), n in degisim.items() if e == 0 and s == 'yuksek')
    print('  Masum cümlede onay diyaloğu açtıran yükseltme: %d' % masum_yuksek)
    if ornekler:
        print('\n  Örnekler:')
        for once, sonra, etiket, p, metin in ornekler:
            print('    [%s %s→%s p=%.2f] %s' % ('S' if etiket else 'M', once, sonra, p, metin))

    json.dump({
        'basamak_degisen': toplam,
        'masum_yuksek': masum_yuksek,
        'degisim': {'%s>%s:%d' % k: v for k, v in degisim.items()},
    }, io.open(os.path.join(HERE, 'paket_modeli_sonuc.json'), 'w', encoding='utf-8'),
        ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
