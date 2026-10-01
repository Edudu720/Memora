"""
Detecta valor visual literal fora dos tokens do Design System (FR-032, T046).

Sem isto, valores literais reaparecem na terceira tela e a consistencia se
perde em silencio. E nao e hipotese: quando esta ferramenta foi escrita, ela
encontrou **sete** tamanhos de icone diferentes espalhados pelo aplicativo
(18, 20, 22, 24, 28, 56 e 72), nenhum declarado em lugar nenhum, quatro deles
para a mesma coisa - "icone ao lado de texto", escritos por pessoas diferentes
em dias diferentes.

O que e procurado, e onde:

  - cor literal ........ Color(0x...) e Colors.<nome>
  - espacamento ........ EdgeInsets.<algo>(<numero>)
  - tamanho ............ size:, width:, height:, fontSize:, strokeWidth:,
                         maxHeight:, maxWidth:, minHeight:, minWidth:,
                         elevation:, blurRadius:, letterSpacing: com numero
  - raio ............... BorderRadius.circular(<numero>)

Uso: py specs/002-design-system/ferramentas/validar_tokens.py
Sai com codigo 1 se qualquer literal aparecer (serve de portao de build).
"""
import os
import re
import sys

RAIZ = os.path.join("app", "lib")

# A pasta dos tokens e o unico lugar onde valor literal PODE existir: e ali que
# ele deixa de ser literal e vira nome.
ISENTAS = (
    os.path.join("app", "lib", "design_system", "tokens"),
)

# `Colors.transparent` e a AUSENCIA de cor, nao uma escolha de cor: ele nao
# pode divergir do sistema porque nao tem valor que possa divergir. O Material
# exige um `Color` em lugares onde a resposta certa e "nenhuma" (o fundo de um
# `Material` que so existe para dar o efeito de toque, por exemplo).
#
# Esta lista e curta de proposito. Cada item novo aqui e um buraco no portao,
# e precisa vir com a razao escrita ao lado.
PERMITIDOS = {
    "Colors.transparent",
}

REGRAS = [
    ("cor", re.compile(r"Color\(0x[0-9a-fA-F]+\)|Colors\.[a-zA-Z]+")),
    ("espacamento",
     re.compile(r"EdgeInsets\.[a-zA-Z]+\(\s*-?\d+(?:\.\d+)?")),
    ("raio", re.compile(r"BorderRadius\.circular\(\s*-?\d+(?:\.\d+)?")),
    ("tamanho", re.compile(
        r"\b(size|width|height|fontSize|strokeWidth|maxHeight|maxWidth"
        r"|minHeight|minWidth|elevation|blurRadius|letterSpacing)"
        r":\s*-?\d+(?:\.\d+)?")),
]


def isenta(caminho):
    return any(caminho.startswith(p) for p in ISENTAS)


def varrer():
    achados = []
    for pasta, _, arquivos in os.walk(RAIZ):
        if isenta(pasta):
            continue
        for arquivo in arquivos:
            if not arquivo.endswith(".dart"):
                continue
            caminho = os.path.join(pasta, arquivo)
            with open(caminho, encoding="utf-8") as f:
                for n, linha in enumerate(f, 1):
                    codigo = linha.split("//")[0]
                    for tipo, regra in REGRAS:
                        for m in regra.finditer(codigo):
                            if m.group(0) in PERMITIDOS:
                                continue
                            achados.append(
                                (caminho, n, tipo, m.group(0), linha.strip()))
    return achados


def main():
    if not os.path.isdir(RAIZ):
        print(f"ERRO: rode da raiz do repositorio (nao encontrei {RAIZ}).")
        sys.exit(2)

    achados = varrer()

    print("=" * 70)
    print("FR-032 - valor visual literal fora dos tokens")
    print("=" * 70)

    if not achados:
        print("\nNenhum literal encontrado. O Design System e a unica fonte de")
        print("cor, espacamento e tamanho no aplicativo.")
        sys.exit(0)

    por_tipo = {}
    for caminho, n, tipo, trecho, linha in achados:
        por_tipo.setdefault(tipo, []).append((caminho, n, trecho, linha))

    for tipo in sorted(por_tipo):
        itens = por_tipo[tipo]
        print(f"\n--- {tipo.upper()} ({len(itens)}) ---")
        for caminho, n, trecho, linha in itens:
            print(f"  {caminho}:{n}")
            print(f"      {trecho}   ->   {linha[:90]}")

    print("\n" + "=" * 70)
    print(f"{len(achados)} literal(is) encontrado(s).")
    print("Use um token de `app/lib/design_system/tokens/`, ou crie um la se o")
    print("valor for novo. Literal solto e como a consistencia se perde.")
    sys.exit(1)


if __name__ == "__main__":
    main()
