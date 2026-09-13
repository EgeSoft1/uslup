# -*- coding: utf-8 -*-
"""
Üslup ML Modelini ONNX formatında dışa aktarma betiği.
Hedef Mimari: Deterministik Kural Motoru + ONNX Makine Öğrenimi (Hybrid)

ONNX'in `skl2onnx` paketi, karakter n-gram (char_wb) TF-IDF dönüşümlerini 
string tensörlerde desteklemediğinden, kelime bazlı (word) TF-IDF 
ve Lojistik Regresyon boru hattını (wordpipe) dışa aktaracağız. 
Melez mimaride (HybridClassifier), kelime bazlı model de yüksek hatırlama 
(recall) sağlayarak kural motorunun eksiklerini kapatmaya yeterlidir.
"""
import io, json, os
import numpy as np
import onnx
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from skl2onnx import to_onnx
from skl2onnx.common.data_types import StringTensorType

HERE = os.path.dirname(os.path.abspath(__file__))

def normalize(s):
    s = s.replace('I', 'ı').replace('İ', 'i').lower()
    return s

def get_wordpipe():
    return Pipeline([
        ('tf', TfidfVectorizer(
            analyzer='word',
            ngram_range=(1, 3), # Trigram desteği eklendi (bağlamı daha iyi kavrar)
            min_df=1, 
            max_df=0.9, # Çok sık geçen anlamsız kelimeleri filtrele
            sublinear_tf=True
        )),
        ('clf', LogisticRegression(
            C=2.5, # Aşırı uyarlamayı (overfitting) azaltmak için C=4.0'dan 2.5'e çekildi
            max_iter=5000, 
            class_weight='balanced', 
            random_state=20260823
        ))
    ])

def export_model():
    print("Veri yükleniyor...")
    with io.open(os.path.join(HERE, 'veri.json'), encoding='utf-8') as f:
        d = json.load(f)
    
    Xd = [normalize(r['text']) for r in d['dev']]
    yd = np.array([r['label'] for r in d['dev']])
    
    print("Model (Word TF-IDF + LR) eğitiliyor...")
    pipe = get_wordpipe()
    pipe.fit(Xd, yd)
    
    print("ONNX formatına çevriliyor...")
    initial_type = [('input_text', StringTensorType([None, 1]))]
    
    onx = to_onnx(pipe, initial_types=initial_type, target_opset=14, options={'zipmap': False})
    
    out_path = os.path.join(HERE, 'uslup_model.onnx')
    with open(out_path, "wb") as f:
        f.write(onx.SerializeToString())
    
    print(f"ONNX modeli başarıyla dışa aktarıldı: {out_path}")
    print(f"Boyut: {os.path.getsize(out_path) / 1024:.1f} KB")

if __name__ == '__main__':
    export_model()
