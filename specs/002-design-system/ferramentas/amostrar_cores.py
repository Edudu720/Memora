"""Amostra as cores dominantes das telas do protótipo Memora e calcula contraste WCAG."""
import os, glob
from collections import Counter
from PIL import Image

DIR = r"C:\Users\Edu\Documents\Memora\docs\design\prototipo"

def srgb_to_lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def luminance(rgb):
    r, g, b = (srgb_to_lin(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(c1, c2):
    l1, l2 = luminance(c1), luminance(c2)
    lo, hi = sorted((l1, l2))
    return (hi + 0.05) / (lo + 0.05)

def hexs(rgb):
    return "#{:02X}{:02X}{:02X}".format(*rgb)

# quantiza para agrupar tons quase iguais (compressão JPEG/PNG gera ruído)
def quant(rgb, step=8):
    return tuple((v // step) * step for v in rgb)

counter = Counter()
files = sorted(glob.glob(os.path.join(DIR, "*.png")))
# ignora as duas primeiras (logo da FATEC) e o diagrama de estados
telas = [f for f in files if not os.path.basename(f).startswith(("01_", "02_", "03_"))]

for f in telas:
    im = Image.open(f).convert("RGB")
    im = im.resize((im.width // 2, im.height // 2))
    for px in im.getdata():
        counter[quant(px)] += 1

total = sum(counter.values())
print(f"Telas analisadas: {len(telas)}  |  pixels: {total:,}\n")
print("=== CORES DOMINANTES ===")
dominantes = []
for rgb, n in counter.most_common(14):
    pct = 100 * n / total
    print(f"  {hexs(rgb):9s}  {pct:5.2f}%   L={luminance(rgb):.3f}")
    dominantes.append(rgb)

print("\n=== CONTRASTE DE PARES CRÍTICOS ===")
BRANCO = (255, 255, 255)
PRETO = (0, 0, 0)

# candidatos a cor primária: azuis saturados
azuis = [rgb for rgb in counter
         if rgb[2] > 150 and rgb[2] - rgb[0] > 60 and rgb[2] - rgb[1] > 60]
azuis.sort(key=lambda c: -counter[c])
print("\nAzuis dominantes (candidatos a cor primária):")
for rgb in azuis[:6]:
    cb = contrast(rgb, BRANCO)
    cp = contrast(rgb, PRETO)
    print(f"  {hexs(rgb):9s} {100*counter[rgb]/total:5.2f}%  "
          f"vs branco={cb:5.2f}:1 {'OK' if cb >= 4.5 else 'REPROVA'}   "
          f"vs preto={cp:5.2f}:1 {'OK' if cp >= 4.5 else 'REPROVA'}")

# cinzas usados como superfície
cinzas = [rgb for rgb in counter
          if max(rgb) - min(rgb) < 16 and 180 < rgb[0] < 245]
cinzas.sort(key=lambda c: -counter[c])
print("\nCinzas de superfície:")
for rgb in cinzas[:5]:
    cp = contrast(rgb, PRETO)
    print(f"  {hexs(rgb):9s} {100*counter[rgb]/total:5.2f}%  "
          f"texto preto={cp:5.2f}:1 {'OK' if cp >= 4.5 else 'REPROVA'}")
