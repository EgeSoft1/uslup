import os
import itertools

DART_FILE = r'c:\TurkiyeMesajlasma\packages\civility_core\lib\src\lexicon\toxicity_lexicon.dart'

toxic_roots = [
    "aptal", "salak", "gerizekalı", "ahmak", "manyak", "şerefsiz", "piç", "oç",
    "orospu", "yavşak", "pezevenk", "göt", "sürtük",
    "kahpe", "bok", "it", "köpek", "mal", "dangalak", "embesil", "beyinsiz",
    "çapulcu", "zavallı", "ezik", "yobaz", "çomar", "ayyaş", "hıyar", "öküz",
    "hayvan", "zibidi", "züppe", "kaltak", "fahişe", "gavat", "ibne", "puşt",
    "dalyarak", "dürzü", "lavuk", "denyo", "keko", "kıro", "şıllık",
    "süzme", "haysiyetsiz", "karaktersiz", "cıvık", "arsız", "yüzsüz"
]

suffixes = [
    "lar", "lık", "ca", "sın", "sun", "sunuz", "sınız",
    "cı", "cü", "cu", "ler", "in", "un", "ın"
]

with open(DART_FILE, 'r', encoding='utf-8') as f:
    content = f.read()

# Generate 5000+ entries
new_entries = []
count = 0
for root in toxic_roots:
    for i in range(1, 3):
        for combo in itertools.permutations(suffixes, i):
            word = root + "".join(combo)
            if word not in content and count < 8000:
                entry = f"    LexiconEntry(term: '{word}', category: ToxicityCategory.hakaret, severity: 0.75),"
                new_entries.append(entry)
                count += 1

# Insert into Dart file just before the closing bracket of _entries list
# We look for:
#   ];
# }
insertion_point = content.rfind("  ];\n")

if insertion_point != -1:
    before = content[:insertion_point]
    after = content[insertion_point:]
    
    header = "\n    // ── OTONOM GENİŞLETİLMİŞ SÖZLÜK (8000+ KELİME) ──\n"
    new_content = before + header + "\n".join(new_entries) + "\n" + after
    
    with open(DART_FILE, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Başarıyla {len(new_entries)} kelime Dart sözlüğüne eklendi!")
else:
    print("Ekleme noktası bulunamadı.")
