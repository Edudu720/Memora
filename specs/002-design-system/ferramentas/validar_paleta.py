"""
Valida a paleta do Design System do Memora contra a WCAG 2.2.

Regras aplicadas:
  - Texto normal ........ 4.5:1 (AA)   | 7:1 no tema de alto contraste (FR-035)
  - Texto grande e icone  3:1
  - Borda de componente   3:1

Paletas prontas de cor de destaque (feature 004, FR-039, R15): cada paleta
troca so a `primaria` e os tons derivados dela (`sobre_primaria`, `destaque`,
`medalhao`), e e validada em CADA tema claro e escuro, contra TODOS os pares
abaixo -- antes de existir. No tema de alto contraste a paleta nao se aplica.
Uma paleta que reprova em algum tema simplesmente nao entra: nao ganha excecao.

Uso: python validar_paleta.py
     python validar_paleta.py --autoteste   (prova que o portao reprova)
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

# Paletas prontas (R15). "azul" e a do prototipo e o padrao: nao sobrescreve
# nada, ou seja, e exatamente o que ja esta em TEMAS. As demais (verde, roxo,
# laranja-terra, rosa, grafite) so entram AQUI depois de medidas -- e o valor
# que passar aqui e o que vai para `app/lib/design_system/tokens/cores.dart`
# (T122). Formato: {tema: {nome_da_cor: "#RRGGBB"}}, so `claro` e `escuro`.
PALETAS = {
    "azul": {},
    "verde": {
        "claro": {
            "primaria": "#12632B",
            "sobre_primaria": "#FFFFFF",
            "destaque": "#E0F2E5",
            "medalhao": "#E0F2E5",
        },
        "escuro": {
            "primaria": "#8FE2A5",
            "sobre_primaria": "#062A12",
            "destaque": "#143D22",
            "medalhao": "#D2F5DC",
        },
    },
    "roxo": {
        "claro": {
            "primaria": "#5D28A6",
            "sobre_primaria": "#FFFFFF",
            "destaque": "#EFE6FD",
            "medalhao": "#EFE6FD",
        },
        "escuro": {
            "primaria": "#CDAFFF",
            "sobre_primaria": "#230A47",
            "destaque": "#351B5C",
            "medalhao": "#ECDEFF",
        },
    },
    "laranja-terra": {
        "claro": {
            "primaria": "#93370D",
            "sobre_primaria": "#FFFFFF",
            "destaque": "#FCE9DF",
            "medalhao": "#FCE9DF",
        },
        "escuro": {
            "primaria": "#FFB188",
            "sobre_primaria": "#381002",
            "destaque": "#4E210D",
            "medalhao": "#FFE2D3",
        },
    },
    "rosa": {
        "claro": {
            "primaria": "#941B55",
            "sobre_primaria": "#FFFFFF",
            "destaque": "#FDE6F0",
            "medalhao": "#FDE6F0",
        },
        "escuro": {
            "primaria": "#FFAECB",
            "sobre_primaria": "#38041B",
            "destaque": "#541233",
            "medalhao": "#FFE0EC",
        },
    },
    "grafite": {
        "claro": {
            "primaria": "#344154",
            "sobre_primaria": "#FFFFFF",
            "destaque": "#E7ECF2",
            "medalhao": "#E7ECF2",
        },
        "escuro": {
            "primaria": "#B7C6DE",
            "sobre_primaria": "#0E1826",
            "destaque": "#232D3B",
            "medalhao": "#E2EAF5",
        },
    },
}

# Os temas em que a paleta se aplica (R15): alto contraste fica de fora.
TEMAS_COM_PALETA = ("claro", "escuro")

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
    # revisao da #38: pares que a interface ja usava sem validacao. O "Ler o
    # aviso inteiro" escreve primaria como TEXTO sobre superficie_alt (antes so
    # validada como grafico), e a borda e o escudo do aviso usam perigo sobre ela.
    ("primaria",       "superficie_alt", "texto"),
    ("perigo",         "superficie_alt", "grafico"),
]

def cores_da(tema_nome, paleta):
    """As cores do tema com a paleta aplicada por cima (so claro/escuro)."""
    cores = dict(TEMAS[tema_nome]["cores"])
    if tema_nome in TEMAS_COM_PALETA:
        cores.update(paleta.get(tema_nome, {}))
    return cores


def validar(tema_nome, paleta, rotulo):
    """Valida todos os pares de uma combinacao. Devolve quantas falharam."""
    min_txt = TEMAS[tema_nome]["min_texto"]
    cores = cores_da(tema_nome, paleta)
    print(f"\n=== TEMA {tema_nome.upper()} - {rotulo}  (texto >= {min_txt}:1) ===")
    falhas = 0
    for frente, fundo, tipo in PARES:
        exigido = min_txt if tipo == "texto" else 3.0
        r = contraste(cores[frente], cores[fundo])
        ok = r >= exigido
        if not ok:
            falhas += 1
        print(f"  {'OK  ' if ok else 'FALHA'} {frente:>14s} sobre {fundo:<15s} "
              f"{r:6.2f}:1  (exigido {exigido}:1)")
    return falhas


def combinacoes(paletas):
    """Toda combinacao a validar: cada tema com cada paleta, onde ela vale."""
    for tema_nome in TEMAS:
        if tema_nome in TEMAS_COM_PALETA:
            for nome, paleta in paletas.items():
                yield tema_nome, paleta, f"paleta {nome}"
        else:
            yield tema_nome, {}, "sem paleta (nao se aplica)"


def rodar(paletas):
    """Roda TODAS as combinacoes de `combinacoes()`.

    Devolve `{(tema, rotulo): falhas}`. E o que `main` e o autoteste usam, para
    que o autoteste exercite o MESMO laco que o portao: uma regressao em
    `combinacoes()` (um tema que deixa de receber a paleta) precisa reprovar
    o autoteste, e nao so o caminho que chama `validar()` direto.
    """
    resultado = {}
    for tema_nome, paleta, rotulo in combinacoes(paletas):
        resultado[(tema_nome, rotulo)] = validar(tema_nome, paleta, rotulo)
    return resultado


# Os temas em que a paleta TEM de valer, escritos aqui de novo e de proposito:
# a conta do autoteste nao pode depender da constante que ele fiscaliza, senao
# encolher `TEMAS_COM_PALETA` encolheria junto o que se espera.
TEMAS_ONDE_A_PALETA_VALE = ("claro", "escuro")


def combinacoes_esperadas(paletas):
    """Quantas combinacoes `combinacoes()` deve gerar, contada de outro jeito."""
    return (len(TEMAS_ONDE_A_PALETA_VALE) * len(paletas)
            + len([t for t in TEMAS if t not in TEMAS_ONDE_A_PALETA_VALE]))


def main():
    resultado = rodar(PALETAS)
    total = len(resultado)
    falhas = sum(resultado.values())
    if total != combinacoes_esperadas(PALETAS):
        print(f"\nFALHA: {total} combinacoes validadas, esperadas "
              f"{combinacoes_esperadas(PALETAS)}.")
        sys.exit(1)

    print("\n" + "=" * 60)
    if falhas:
        print(f"{falhas} par(es) REPROVARAM. Corrija os tokens antes de prosseguir.")
        sys.exit(1)
    print(f"Todos os pares aprovados em {total} combinacoes de tema e paleta. "
          "Paleta em conformidade com a WCAG 2.2.")
    sys.exit(0)


def autoteste():
    """Prova que o portao reprova uma paleta ruim, em CADA tema onde vale.

    Um validador que nunca reprova nada nao protege nada. Passa pelo mesmo
    laco do `main` (`rodar`/`combinacoes`) paletas ruins de proposito -- uma
    que so estraga o claro, outra que so estraga o escuro -- e exige que cada
    uma reprove no tema dela e em mais nenhum, que o numero de combinacoes
    bata com a conta `temas_com_paleta x paletas + temas_sem_paleta`, e que
    uma paleta boa continue passando nos dois.
    """
    ruim_claro = {"claro": {"primaria": "#B8C7FF"}}   # ~1,6:1 sobre #F8F8F8
    ruim_escuro = {"escuro": {"primaria": "#2A3A6A"}}  # ~1,5:1 sobre #101216
    boa = {"claro": {"primaria": "#0B3BD0"}, "escuro": {"primaria": "#A8C0FF"}}
    paletas = {"ruim_claro": ruim_claro, "ruim_escuro": ruim_escuro, "boa": boa}

    resultado = rodar(paletas)
    esperado = combinacoes_esperadas(paletas)
    erros = []
    if len(resultado) != esperado:
        erros.append(f"{len(resultado)} combinacoes rodaram, esperadas {esperado}")

    for tema, rotulo in (("claro", "paleta ruim_claro"),
                         ("escuro", "paleta ruim_escuro")):
        if (tema, rotulo) not in resultado:
            erros.append(f"{rotulo} nem chegou a ser validada no tema {tema}")

    for (tema, rotulo), falhas in resultado.items():
        deve_falhar = ((tema == "claro" and rotulo == "paleta ruim_claro")
                       or (tema == "escuro" and rotulo == "paleta ruim_escuro"))
        if deve_falhar and falhas == 0:
            erros.append(f"{rotulo} NAO reprovou no tema {tema}")
        if not deve_falhar and falhas != 0:
            erros.append(f"{rotulo} reprovou no tema {tema}, e nao devia")
        if tema not in TEMAS_COM_PALETA and rotulo.startswith("paleta "):
            erros.append(f"o tema {tema} recebeu paleta, e nao devia")

    print("\n" + "=" * 60)
    if erros:
        for erro in erros:
            print(f"AUTOTESTE FALHOU: {erro}.")
        sys.exit(1)
    print(f"Autoteste ok: {len(resultado)} combinacoes pelo laco do portao; as "
          "paletas ruins reprovaram so no tema delas e a boa passou.")
    sys.exit(0)


if __name__ == "__main__":
    if "--autoteste" in sys.argv[1:]:
        autoteste()
    main()
