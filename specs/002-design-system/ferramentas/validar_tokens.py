"""
Detecta valor visual literal fora dos tokens do Design System (FR-032, T046).

Sem isto, valores literais reaparecem na terceira tela e a consistencia se
perde em silencio. E nao e hipotese: quando esta ferramenta foi escrita, ela
encontrou **sete** tamanhos de icone diferentes espalhados pelo aplicativo
(18, 20, 22, 24, 28, 56 e 72), nenhum declarado em lugar nenhum, quatro deles
para a mesma coisa - "icone ao lado de texto", escritos por pessoas diferentes
em dias diferentes.

O que e procurado, e onde:

  - cor literal ........ Color(0x...), Color(<numero>), Color.fromARGB(...),
                         Color.fromRGBO(...) e Colors.<nome>
  - espacamento ........ EdgeInsets[Directional].<algo>(<numero>) em qualquer
                         argumento, e horizontal:/vertical:/left:/right:/
                         top:/bottom:/start:/end: com numero
  - tamanho ............ size:, width:, height:, fontSize:, strokeWidth:,
                         maxHeight:, maxWidth:, minHeight:, minWidth:,
                         elevation:, blurRadius:, letterSpacing: com numero
  - raio ............... BorderRadius.circular(<numero>) e
                         Radius.circular(<numero>)

Comentarios (`//`, `///`, `/* */`) sao ignorados, mas so FORA de string: um
`'http://...'` nao esconde o que vem depois dele na linha.

Uso: py specs/002-design-system/ferramentas/validar_tokens.py [pasta]

Sem argumento, varre `app/lib` (e isenta `tokens/`). Com `pasta`, varre so ela,
sem isencao nenhuma. O autoteste - que prova que o portao reprova o que deve e
aprova o que nao deve, contra as amostras de `amostras_tokens/` - roda assim:

    py specs/002-design-system/ferramentas/validar_tokens.py --autoteste

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

_NUM = r"-?\d+(?:\.\d+)?"

REGRAS = [
    ("cor", re.compile(
        r"\bColor\(\s*(?:0x[0-9a-fA-F]+|\d+)\s*\)"
        r"|\bColor\.from(?:ARGB|RGBO)\("
        # \b: `MemoraColors.x` (se um dia existir) nao e `Colors.x` do Material
        r"|\bColors\.[a-zA-Z]+")),
    ("espacamento", re.compile(
        # primeiro argumento posicional: EdgeInsets.all(8)
        r"\bEdgeInsets(?:Directional)?\.[a-zA-Z]+\(\s*" + _NUM
        # qualquer argumento depois de virgula: fromLTRB(a, 8, ...)
        + r"|\bEdgeInsets(?:Directional)?\.[a-zA-Z]+\([^)]*,\s*" + _NUM
        # argumento nomeado: symmetric(horizontal: 12), only(left: 8)
        + r"|\b(?:horizontal|vertical|left|right|top|bottom|start|end)"
        r"\s*:\s*" + _NUM)),
    ("raio", re.compile(
        r"\b(?:BorderRadius|Radius)\.circular\(\s*" + _NUM)),
    ("tamanho", re.compile(
        r"\b(size|width|height|fontSize|strokeWidth|maxHeight|maxWidth"
        r"|minHeight|minWidth|elevation|blurRadius|letterSpacing)"
        r":\s*" + _NUM)),
]


def isenta(caminho):
    return any(caminho.startswith(p) for p in ISENTAS)


def sem_comentario(linha, em_bloco):
    """Tira comentario da linha, mas so o que esta fora de string.

    Devolve (codigo, em_bloco): `em_bloco` carrega de uma linha para a outra o
    estado de um `/* ... */` que ainda nao fechou. Nao entende string tripla
    nem string crua - suficiente para o codigo do app, e o erro possivel aqui
    e MOSTRAR literal a mais, nunca esconder.
    """
    saida = []
    aspas = None
    i = 0
    n = len(linha)
    while i < n:
        c = linha[i]
        if em_bloco:
            if linha.startswith("*/", i):
                em_bloco = False
                i += 2
            else:
                i += 1
            continue
        if aspas:
            saida.append(c)
            if c == "\\" and i + 1 < n:
                saida.append(linha[i + 1])
                i += 2
                continue
            if c == aspas:
                aspas = None
            i += 1
            continue
        if c in ("'", '"'):
            aspas = c
            saida.append(c)
        elif linha.startswith("//", i):
            break
        elif linha.startswith("/*", i):
            em_bloco = True
            i += 2
            continue
        else:
            saida.append(c)
        i += 1
    return "".join(saida), em_bloco


def varrer(raiz=RAIZ, com_isencao=True):
    achados = []
    for pasta, _, arquivos in os.walk(raiz):
        if com_isencao and isenta(pasta):
            continue
        for arquivo in sorted(arquivos):
            if not arquivo.endswith(".dart"):
                continue
            caminho = os.path.join(pasta, arquivo)
            em_bloco = False
            with open(caminho, encoding="utf-8") as f:
                for n, linha in enumerate(f, 1):
                    codigo, em_bloco = sem_comentario(linha, em_bloco)
                    for tipo, regra in REGRAS:
                        for m in regra.finditer(codigo):
                            if m.group(0) in PERMITIDOS:
                                continue
                            achados.append(
                                (caminho, n, tipo, m.group(0), linha.strip()))
    return achados


AMOSTRAS = os.path.join(
    "specs", "002-design-system", "ferramentas", "amostras_tokens")


def autoteste():
    """O portao tem que reprovar o que deve e aprovar o que nao deve.

    `reprova.dart` traz um literal por linha, marcado com `// ESPERA: <tipo>`
    no fim da linha; cada marca precisa gerar achado daquele tipo naquela
    linha. `aprova.dart` nao pode gerar nenhum.
    """
    reprova = os.path.join(AMOSTRAS, "reprova.dart")
    aprova = os.path.join(AMOSTRAS, "aprova.dart")
    falhas = []

    esperados = {}
    with open(reprova, encoding="utf-8") as f:
        for n, linha in enumerate(f, 1):
            m = re.search(r"//\s*ESPERA:\s*(\w+)\s*$", linha)
            if m:
                esperados[n] = m.group(1)
    if not esperados:
        falhas.append("reprova.dart nao tem nenhuma marca ESPERA")

    por_linha = {}
    for caminho, n, tipo, _, _ in varrer(AMOSTRAS, com_isencao=False):
        if caminho == reprova:
            por_linha.setdefault(n, set()).add(tipo)
        elif caminho == aprova:
            falhas.append(f"aprova.dart:{n} reprovou ({tipo}) e nao devia")

    for n, tipo in sorted(esperados.items()):
        if tipo not in por_linha.get(n, set()):
            falhas.append(f"reprova.dart:{n} devia reprovar como {tipo}")

    print(f"autoteste: {len(esperados)} amostras que devem reprovar, "
          f"{len(falhas)} falha(s)")
    for falha in falhas:
        print("  FALHOU:", falha)
    sys.exit(1 if falhas else 0)


def main():
    if "--autoteste" in sys.argv[1:]:
        autoteste()

    argumentos = [a for a in sys.argv[1:] if not a.startswith("--")]
    raiz = argumentos[0] if argumentos else RAIZ

    if not os.path.isdir(raiz):
        print(f"ERRO: rode da raiz do repositorio (nao encontrei {raiz}).")
        sys.exit(2)

    achados = varrer(raiz, com_isencao=not argumentos)

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
