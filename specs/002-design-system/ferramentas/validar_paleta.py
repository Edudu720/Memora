"""
Valida a paleta do Design System do Memora contra a WCAG 2.2.

Regras aplicadas:
  - Texto normal ........ 4.5:1 (AA)   | 7:1 no tema de alto contraste (FR-035)
  - Texto grande e icone  3:1
  - Borda de componente   3:1

Uso: python validar_paleta.py
Sai com codigo 1 se qualquer par reprovar (serve de portao de build).
"""
import sys

def _lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def lum(h):
    h = h.lstrip("#")
    r, g, b = (int(h[i:i+2], 16) for i in (0, 2, 4))
    return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)

def contraste(a, b):
    l1, l2 = lum(a), lum(b)
    lo, hi = sorted((l1, l2))
    return (hi + 0.05) / (lo + 0.05)


TEMAS = {
    "claro": {
        "min_texto": 4.5,
        "cores": {
            "fundo":            "#F8F8F8",  # amostrado do prototipo
            "superficie":       "#FFFFFF",
            "superficie_alt":   "#D8D8D8",  # amostrado do prototipo
            "destaque":         "#E3EAFF",  # feature 004
            "medalhao":         "#E3EAFF",  # decorativo, sem par: nada se escreve sobre ele
            "primaria":         "#1040F8",  # amostrado do prototipo
            "sobre_primaria":   "#FFFFFF",
            "texto":            "#111111",
            "texto_suave":      "#4A4A4A",
            "borda":            "#6B6B6B",
            "sucesso":          "#186A2E",
            "perigo":           "#B3231F",
            "sobre_perigo":     "#FFFFFF",
        },
    },
    "escuro": {
        "min_texto": 4.5,
        "cores": {
            "fundo":            "#101216",
            "superficie":       "#1B1E24",
            "superficie_alt":   "#2A2E36",
            "destaque":         "#22305A",  # feature 004
            "medalhao":         "#DCE5FF",  # claro de proposito, ver cores.dart
            "primaria":         "#9CB8FF",
            "sobre_primaria":   "#06132E",
            "texto":            "#F2F4F8",
            "texto_suave":      "#C2C7D0",
            "borda":            "#8A909C",
            "sucesso":          "#7CD69A",
            "perigo":           "#FF9B95",
            "sobre_perigo":     "#3A0705",
        },
    },
    "alto_contraste": {
        "min_texto": 7.0,  # FR-035
        "cores": {
            "fundo":            "#000000",
            "superficie":       "#000000",
            "superficie_alt":   "#1A1A1A",
            "destaque":         "#10245A",  # feature 004
            "medalhao":         "#DCE5FF",
            "primaria":         "#8FB4FF",
            "sobre_primaria":   "#000000",
            "texto":            "#FFFFFF",
            "texto_suave":      "#E8E8E8",
            "borda":            "#FFFFFF",
            "sucesso":          "#7BE49B",
            "perigo":           "#FF9E97",
            "sobre_perigo":     "#000000",
        },
    },
}

# (frente, fundo, tipo)  -- tipo define o limiar exigido
PARES = [
    ("texto",          "fundo",          "texto"),
    ("texto",          "superficie",     "texto"),
    ("texto",          "superficie_alt", "texto"),
    ("texto_suave",    "fundo",          "texto"),
    ("texto_suave",    "superficie",     "texto"),
    ("texto_suave",    "superficie_alt", "texto"),  # estado desabilitado
    ("primaria",       "fundo",          "texto"),
    ("primaria",       "superficie",     "texto"),
    ("sobre_primaria", "primaria",       "texto"),
    ("sucesso",        "fundo",          "texto"),
    ("sucesso",        "superficie",     "texto"),
    ("perigo",         "fundo",          "texto"),
    ("perigo",         "superficie",     "texto"),
    ("sobre_perigo",   "perigo",         "texto"),
    ("borda",          "fundo",          "grafico"),
    ("borda",          "superficie",     "grafico"),
    ("primaria",       "superficie_alt", "grafico"),
    # feature 004: o tom suave da primaria. Ele NUNCA e o unico sinal de estado
    # (mede so 1,1 a 1,6:1 contra fundo e superficie); o que importa e o que
    # se escreve por cima dele.
    ("texto",          "destaque",       "texto"),
    ("texto_suave",    "destaque",       "texto"),
    ("primaria",       "destaque",       "texto"),
]

def main():
    falhas = 0
    for nome, tema in TEMAS.items():
        cores = tema["cores"]
        min_txt = tema["min_texto"]
        print(f"\n=== TEMA {nome.upper()}  (texto >= {min_txt}:1) ===")
        for frente, fundo, tipo in PARES:
            exigido = min_txt if tipo == "texto" else 3.0
            r = contraste(cores[frente], cores[fundo])
            ok = r >= exigido
            if not ok:
                falhas += 1
            print(f"  {'OK  ' if ok else 'FALHA'} {frente:>14s} sobre {fundo:<15s} "
                  f"{r:6.2f}:1  (exigido {exigido}:1)")

    print("\n" + "=" * 60)
    if falhas:
        print(f"{falhas} par(es) REPROVARAM. Corrija os tokens antes de prosseguir.")
        sys.exit(1)
    print("Todos os pares aprovados. Paleta em conformidade com a WCAG 2.2.")
    sys.exit(0)

if __name__ == "__main__":
    main()
