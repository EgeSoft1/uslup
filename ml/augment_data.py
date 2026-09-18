import veri_deposu

data = veri_deposu.load()

new_data = [
    # TOXIC - Gizlenmiş Küfürler / Argo
    {"text": "a m c i k s i n s e n", "label": 1},
    {"text": "şeref$iz herif", "label": 1},
    {"text": "s.i.k.t.i.r git burdan", "label": 1},
    {"text": "serefszzzz", "label": 1},
    {"text": "0r0spu cocugu", "label": 1},
    {"text": "k4hpe", "label": 1},
    {"text": "b0k gibi olmuş", "label": 1},
    {"text": "amk salağı", "label": 1},
    {"text": "aq delisi", "label": 1},
    {"text": "manyak mısın oç", "label": 1},
    {"text": "s1k1k fikirler", "label": 1},
    {"text": "p1c kurusu", "label": 1},
    
    # TOXIC - Edimbilimsel (Beddua/Susturma/Aşağılama)
    {"text": "allah belanı versin senin", "label": 1},
    {"text": "cehennemin dibine kadar yolun var", "label": 1},
    {"text": "iki paralık adam gelmiş konuşuyor", "label": 1},
    {"text": "yüzüne tüküreyim senin", "label": 1},
    {"text": "aklını peynir ekmekle mi yedin sen", "label": 1},
    {"text": "sana ne oluyor lan", "label": 1},
    {"text": "senin derdin ne ki", "label": 1},
    {"text": "terbiyeni takın hadsiz", "label": 1},
    {"text": "ağzını topla", "label": 1},
    {"text": "ne ayıp utanmıyor musun", "label": 1},
    {"text": "kes sesini", "label": 1},
    {"text": "sus lan", "label": 1},
    {"text": "kapa çeneni", "label": 1},

    # CLEAN - Aldatıcı Temiz (False Positive Tuzağı)
    {"text": "şalgam suyu çok güzel", "label": 0},
    {"text": "sıkıntı yok hallederiz", "label": 0},
    {"text": "sikke koleksiyonum var", "label": 0},
    {"text": "şikayet dilekçesi yazdım", "label": 0},
    {"text": "siklona yakalandık", "label": 0},
    {"text": "boks maçı izliyorum", "label": 0},
    {"text": "boka isimli köy", "label": 0},
    {"text": "amazon ormanları", "label": 0},
    {"text": "amiral gemisi model", "label": 0},
    {"text": "amortisör patlamış", "label": 0},
    {"text": "puştun biri demiyorum, arkadaşım diyorum", "label": 0}, # negation context (not implemented well in word n-grams, but good for test)
    {"text": "yarasa çok ilginç bir hayvan", "label": 0},
    {"text": "yara bandı var mı", "label": 0},
    {"text": "yararlı bilgiler", "label": 0},
    {"text": "orospu çocuğu demek hakarettir", "label": 0}, # quotation context (often hard for ML, but good to have)
    {"text": "salaksın demek istemiyorum ama hatalısın", "label": 0},
    {"text": "sere serpe uzandım", "label": 0},
    {"text": "serenat yaptı", "label": 0},
    {"text": "aptallar gibi bekledim", "label": 0}, # self-deprecating

    # NEUTRAL / EVERYDAY
    {"text": "bugün hava çok güzel", "label": 0},
    {"text": "projeyi yarına yetiştirmemiz lazım", "label": 0},
    {"text": "yarışmada birinci olacağız", "label": 0},
    {"text": "NSosyal için yeni özellikler eklendi", "label": 0},
    {"text": "arayüz çok modern olmuş", "label": 0},
    {"text": "otobüsü kaçırdım", "label": 0},
    {"text": "kahve içelim mi", "label": 0},
    {"text": "sunum harika geçti", "label": 0},
]

# Protokolün geliştirme kümesine (dev) YAZILMAZ — gerekçe: veri_deposu.py
added = veri_deposu.add_augmented(data, new_data, source='augment_data')
veri_deposu.save(data)

print(f"Eklenen artırılmış örnek: {added} · toplam artırılmış: {len(data['augmented'])}")
