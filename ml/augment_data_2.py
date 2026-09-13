import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
FILE_PATH = os.path.join(HERE, 'veri.json')

with open(FILE_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

new_data = [
    # TOXIC - Kategori: Çok İnce / Örtük Hakaret
    {"text": "zeka seviyen ancak buna yetmiş", "label": 1},
    {"text": "senin kapasiten bu kadar işte", "label": 1},
    {"text": "bu lafları nerenden uyduruyorsun", "label": 1},
    {"text": "IQ seviyen ayakkabı numaranla aynı galiba", "label": 1},
    {"text": "seninle muhatap olmak bile zaman kaybı", "label": 1},
    {"text": "sizi ciddiye alıp cevap vermemek lazım", "label": 1},
    {"text": "ne kadar zavallısın", "label": 1},
    {"text": "çöp fikirler", "label": 1},
    {"text": "beyin yoksulu", "label": 1},
    {"text": "zihniyetini seveyim", "label": 1}, # Sarcasm
    {"text": "vasıfsız eleman seni", "label": 1},
    {"text": "hadi oradan çapulcu", "label": 1},

    # TOXIC - Cinsiyetçi / Şiddet İması
    {"text": "senin ağzını yüzünü dağıtırım", "label": 1},
    {"text": "senin kemiklerini kırarım", "label": 1},
    {"text": "böylelerinin soyunu kurutacaksın", "label": 1},
    {"text": "erkek müsvettesi", "label": 1},
    {"text": "karı gibi ağlama", "label": 1},
    {"text": "adam ol azıcık", "label": 1},
    
    # TOXIC - Yazım Hileleri Çok İleri (Leet, Emoji)
    {"text": "0 r 0 5 p u", "label": 1},
    {"text": "y @ v ş @ k", "label": 1},
    {"text": "g er ! z e kal l l 1", "label": 1},
    {"text": "s_e_r_e_f_s_i_z", "label": 1},
    {"text": "a-m-ı-n-a", "label": 1},
    {"text": "d a l y a r a k", "label": 1},

    # CLEAN - Nötr Tartışma / Zıt Görüş
    {"text": "bu politikalara kesinlikle katılmıyorum", "label": 0},
    {"text": "yaptığınız analizde büyük hatalar var", "label": 0},
    {"text": "bu düşünce yapısı bana çok ters geliyor", "label": 0},
    {"text": "söylediklerinizin bilimsel bir dayanağı yok", "label": 0},
    {"text": "bu kadar eksik bir yaklaşım görmedim", "label": 0},
    {"text": "çok zayıf bir argüman", "label": 0},
    {"text": "kararınızın topluma zarar vereceğini düşünüyorum", "label": 0},
    
    # CLEAN - Yalan Pozitif Tuzağı
    {"text": "Zeka seviyenizi ölçen bir test yapın", "label": 0},
    {"text": "Zaman kaybını önlemek için yeni bir algoritma geliştirdik", "label": 0},
    {"text": "Çöp atık tesisinin açılışı yapıldı", "label": 0},
    {"text": "Zavallı kedi sokakta donmak üzereydi", "label": 0},
    {"text": "Adam gibi adam derler bizim orada iyi insanlara", "label": 0},
    {"text": "Ağlamamak için kendimi zor tuttum", "label": 0},
    {"text": "Soy ağacımızı çıkarttık", "label": 0},
    {"text": "Kurutulmuş meyveler çok sağlıklıdır", "label": 0},
    {"text": "Yüzüne bakmaya kıyamadım", "label": 0},
    {"text": "Ağzına kadar dolu bir bardak", "label": 0},
    {"text": "Derdi olan gelsin bana anlatsın", "label": 0},
]

print(f"Eski dev boyutu: {len(data['dev'])}")
for entry in new_data:
    if not any(d['text'] == entry['text'] for d in data['dev']):
        data['dev'].append(entry)

print(f"Yeni dev boyutu: {len(data['dev'])}")

with open(FILE_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("İleri seviye veriler başarıyla eklendi.")
