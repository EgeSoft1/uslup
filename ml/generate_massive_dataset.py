import json
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
FILE_PATH = os.path.join(HERE, 'veri.json')

with open(FILE_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Toksik Kökler
toxic_roots = [
    "aptal", "salak", "gerizekalı", "ahmak", "manyak", "şerefsiz", "piç", "oç",
    "orospu", "yavşak", "pezevenk", "göt", "amk", "amına", "siktir", "sürtük",
    "kahpe", "bok", "it", "köpek", "mal", "dangalak", "embesil", "beyinsiz",
    "çapulcu", "zavallı", "ezik", "yobaz", "çomar", "ayyaş", "hıyar", "öküz",
    "hayvan", "zibidi", "züppe", "kaltak", "fahişe", "gavat", "ibne", "puşt",
    "dalyarak", "dürzü", "lavuk", "denyo", "keko", "kıro", "şıllık",
    "orrrrrrrospu", "yavvşak", "pezevenkk", "sıpa", "döl israfı", "götveren"
]

# Hedef Bildiren Şablonlar (Toksik)
toxic_templates = [
    "sen tam bir {w}sın", "senin gibi bir {w} görmedim", "ne kadar {w} birisin",
    "böyle {w}lık olmaz", "sus lan {w}", "seni gidi {w}", "bırak bu {w} ağızlarını",
    "hadi oradan {w}", "{w} herif", "kes sesini {w}", "senin ben {w} olduğunu biliyorum",
    "yemin ederim tam bir {w}", "ne boş bir {w}", "{w} gibi davranıyorsun",
    "iğrenç bir {w}sun", "bu kadar {w} olunmaz", "allahın cezası {w}",
    "defol git {w} seni", "{w} yüzünden mahvolduk", "o {w} ile muhatap olma",
    "şu {w} a bak ya", "sen harbiden {w} mısın", "bi {w} olup git"
]

# Tehdit & Şiddet (Toksik)
threat_templates = [
    "seni {w}", "ağzını yüzünü {w}", "kemiklerini {w}", "senin ecdadını {w}",
    "soyunu {w}", "sizi burada {w}", "geberteceğim seni", "sonun elimden olacak",
    "seni doğduğuna pişman ederim", "hayatını karartırım", "yaşatmam seni",
    "seni var ya lime lime {w}", "kafanı {w}", "boğazını {w}"
]
threat_actions = ["dağıtırım", "kırarım", "sikerim", "kuruturum", "mahvederim", "bitiririm", "yakalım", "keserim", "uçururum", "parçalarım"]

# Temiz / Nötr Kökler (Siyasiler, Gruplar, Eleştiri vb. False Positive önleme)
clean_roots = [
    "eleştiri", "karar", "politika", "yaklaşım", "düşünce", "uygulama", "yasa",
    "görüş", "fikir", "söylem", "açıklama", "analiz", "tasarı", "tartışma",
    "sorun", "çözüm", "öneri", "kanun", "strateji", "yöntem", "süreç", "plan"
]

clean_templates = [
    "bu {w} bana hiç mantıklı gelmiyor", "yaptığınız {w} baştan aşağı hatalı",
    "böyle bir {w} olamaz", "kesinlikle bu {w}e katılmıyorum", "bu {w} tamamen saçmalık",
    "ortada ciddi bir {w} eksikliği var", "hiçbir bilimsel dayanağı olmayan bir {w}",
    "çok zayıf ve sığ bir {w}", "{w} konusunda çok yanlış düşünüyorsunuz",
    "topluma zarar veren bir {w}", "bu kadar kötü bir {w} görmedim",
    "{w} hakkında derin şüphelerim var", "sizin {w}nizi reddediyorum",
    "bu {w} bizi çıkmaza sürüklüyor"
]

existing_texts = set(d['text'].lower() for d in data['dev'])
new_entries = []

for w in toxic_roots:
    for t in toxic_templates:
        text = t.replace("{w}", w)
        if text.lower() not in existing_texts:
            new_entries.append({"text": text, "label": 1})
            existing_texts.add(text.lower())
        if len(w) > 3:
            w_masked = w.replace("a", "@").replace("o", "0").replace("i", "1").replace("e", "3")
            text_masked = t.replace("{w}", w_masked)
            if text_masked.lower() not in existing_texts:
                new_entries.append({"text": text_masked, "label": 1})
                existing_texts.add(text_masked.lower())

for w in threat_actions:
    for t in threat_templates:
        text = t.replace("{w}", w) if "{w}" in t else t
        if text.lower() not in existing_texts:
            new_entries.append({"text": text, "label": 1})
            existing_texts.add(text.lower())

for w in clean_roots:
    for t in clean_templates:
        text = t.replace("{w}", w)
        if text.lower() not in existing_texts:
            new_entries.append({"text": text, "label": 0})
            existing_texts.add(text.lower())

random.seed(42)
for i in range(8000):
    if random.random() > 0.5:
        w = random.choice(toxic_roots)
        t = random.choice(toxic_templates)
        filler = random.choice(["gerçekten ", "ya ", "bence ", "açıkçası ", "ulan ", "be ", "valla ", "ulan yeminle ", "kardeşim sen "])
        text = filler + t.replace("{w}", w)
        if text.lower() not in existing_texts:
            new_entries.append({"text": text, "label": 1})
            existing_texts.add(text.lower())
    else:
        w = random.choice(clean_roots)
        t = random.choice(clean_templates)
        filler = random.choice(["gerçekten ", "sayın başkan ", "arkadaşlar ", "bana göre ", "objektif olarak ", "saygıdeğer üyeler "])
        text = filler + t.replace("{w}", w)
        if text.lower() not in existing_texts:
            new_entries.append({"text": text, "label": 0})
            existing_texts.add(text.lower())

print(f"Başlangıç boyutu: {len(data['dev'])}")
data['dev'].extend(new_entries)
print(f"Yeni eklenen veri: {len(new_entries)}")
print(f"Toplam boyut: {len(data['dev'])}")

with open(FILE_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Tamamlandı.")
