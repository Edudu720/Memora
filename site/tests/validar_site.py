"""Validador estrutural, WCAG 2.2, offline e anti-engenharia social para site/."""

from __future__ import annotations

import re
import sys
from html.parser import HTMLParser
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
DIR_SITE = RAIZ / "site"
HTML_PATH = DIR_SITE / "index.html"
TOKENS_PATH = DIR_SITE / "styles" / "tokens.css"
MAIN_CSS_PATH = DIR_SITE / "styles" / "main.css"
JS_PATH = DIR_SITE / "scripts" / "tutorial.js"
ORCAMENTO_JS_BYTES = 102_400

EXPRESSOES_MEMORA = (
    "neutra",
    "falando",
    "pensando",
    "comemorando",
    "preocupada",
    "acenando",
    "dica",
    "mini",
    "carregando",
)
GRUPOS_MEMORA = (
    "sombra",
    "corpo",
    "painel-peito",
    "antena",
    "cabeca",
    "visor",
    "rosto",
    "olhos",
    "boca",
    "braco-esquerdo",
    "braco-direito",
    "escudo",
    "livro",
    "barra",
)
ATIVOS_LEGADOS_MEMORA = (
    "memora_ajuda_robo.png",
    "memora_alerta_robo.png",
    "memora_dica_robo.png",
    "memora_perfil_robo.png",
    "memora_comemorando.svg",
    "memora_falando.svg",
    "memora_neutra.svg",
)

JARGOES_PROIBIDOS = [
    r"\biot\b",
    r"\bmqtt\b",
    r"\bbackend\b",
    r"\bfrontend\b",
    r"\btokens?\b",
    r"\blogin\b",
    r"\bphishing\b",
    r"\bapi\b",
    r"\bhtml\b",
    r"\bcss\b",
]

ABREVIACOES_NAO_TERMINAM = {"Sr", "Sra", "Dr", "Dra", "nº", "ex"}

PADROES_MEMORA_UX_PROIBIDOS = [
    r"idos[oa]s?",
    r"terceira idade",
    r"melhor idade",
    r"s[êe]nior(es)?",
    r"(?:é|e) dif[íi]cil para (?:voc[êe]|a senhora|o senhor)",
    r"n[ãa]o se preocupe se n[ãa]o entender",
    r"at[ée] voc[êe] consegue",
    r"modo simplificado",
]

TERMOS_DESALINHADOS_APP_PROIBIDOS = [
    r"frase secreta",
    r"mostrar frase",
    r"caf[ée] com bolo",
    r"lembran[çc]a de fam[íi]lia",
]

RE_EMOJI = re.compile(
    r"[\U0001F000-\U0001FAFF\u2600-\u27BF\uFE0F\u231A-\u231B\u23E9-\u23FA\u2B05-\u2B55]"
)


def contar_frases(texto: str) -> int:
    """Espelha a contagem de `texto_da_interface_test.dart`: no maximo 2 frases curtas por bloco."""
    limpo = re.sub(r"\s+", " ", texto).strip()
    if not limpo:
        return 0
    frases = 0
    inicio = 0
    for match in re.finditer(r"(\.\.\.|[.!?…]+)(?=\s|$)", limpo):
        antes = limpo[inicio : match.start()]
        palavras = re.split(r"\s+", antes.strip())
        ultima = palavras[-1] if palavras and palavras[-1] else ""
        if match.group(0) == "." and ultima in ABREVIACOES_NAO_TERMINAM:
            continue
        if antes.strip():
            frases += 1
        inicio = match.end()
    if limpo[inicio:].strip():
        frases += 1
    return frases


def palavras_proibidas_em(texto: str) -> list[str]:
    achadas: list[str] = []
    for padrao in PADROES_MEMORA_UX_PROIBIDOS:
        regex = re.compile(rf"(?<!\w)({padrao})(?!\w)", re.IGNORECASE)
        for match in regex.finditer(texto):
            achadas.append(match.group(0))
    return achadas


def termos_desalinhados_em(texto: str) -> list[str]:
    achadas: list[str] = []
    for padrao in TERMOS_DESALINHADOS_APP_PROIBIDOS:
        regex = re.compile(rf"(?<!\w)({padrao})(?!\w)", re.IGNORECASE)
        for match in regex.finditer(texto):
            achadas.append(match.group(0))
    return achadas


def tem_emoji(texto: str) -> bool:
    return bool(RE_EMOJI.search(texto))


def _hex_para_rgb(hex_cor: str) -> tuple[int, int, int]:
    bruto = hex_cor.lstrip("#")
    return tuple(int(bruto[i : i + 2], 16) for i in (0, 2, 4))


def _luminancia_relativa(hex_cor: str) -> float:
    canais = []
    for valor in _hex_para_rgb(hex_cor):
        srgb = valor / 255.0
        canais.append(srgb / 12.92 if srgb <= 0.04045 else ((srgb + 0.055) / 1.055) ** 2.4)
    return 0.2126 * canais[0] + 0.7152 * canais[1] + 0.0722 * canais[2]


def _razoes_contraste(c1: str, c2: str) -> float:
    l1 = _luminancia_relativa(c1)
    l2 = _luminancia_relativa(c2)
    maior, menor = (l1, l2) if l1 >= l2 else (l2, l1)
    return (maior + 0.05) / (menor + 0.05)


def extrair_paletas_tokens(css_texto: str) -> dict[str, dict[str, str]]:
    blocos = {
        "claro": r':root,\s*:root\[data-tema="claro"\]\s*\{([^}]+)\}',
        "escuro": r':root\[data-tema="escuro"\]\s*\{([^}]+)\}',
        "alto-contraste": r':root\[data-tema="alto-contraste"\]\s*\{([^}]+)\}',
    }
    resultado: dict[str, dict[str, str]] = {}
    for nome, padrao in blocos.items():
        m = re.search(padrao, css_texto, re.DOTALL)
        if not m:
            raise AssertionError(f"Bloco de tokens ausente para o tema '{nome}'.")
        pares = re.findall(r"--([a-z-]+)\s*:\s*(#[0-9A-Fa-f]{6})\s*;", m.group(1))
        resultado[nome] = {chave: val.upper() for chave, val in pares}
    return resultado


class InspetorHtml(HTMLParser):
    BLOCOS_TAG = {"title", "p", "li", "figcaption", "summary", "blockquote", "h1", "h2", "h3", "h4", "h5", "h6", "button", "a"}
    CLASSES_BLOCO = {
        "mini-tela-balao",
        "mini-botao-simulado",
        "mini-tela-selo",
        "capitulo-etiqueta",
        "grupo-legenda",
        "duvida-indicador",
    }

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.html_lang: str | None = None
        self.html_movimento: str | None = None
        self.tem_botao_movimento: bool = False
        self.tem_botao_outra_dica: bool = False
        self.tem_botao_alternar_anfitria: bool = False
        self.tem_balao_anfitria: bool = False
        self.tem_anfitria_flutuante: bool = False
        self.anfitria_dentro_de_main: bool = False
        self.main_profundidade: int = 0
        self.personagens_memora: list[dict[str, str | None]] = []
        self.titulo_pagina: str = ""
        self.ids: set[str] = set()
        self.ancoras_href: list[str] = []
        self.links_externos: list[str] = []
        self.imagens: list[tuple[str | None, str | None]] = []
        self.forms_ou_inputs: list[str] = []
        self.titulos: list[int] = []
        self.marcos: set[str] = set()
        self.primeiro_link_href: str | None = None
        self.pilha_mini_tela: list[str] = []
        self.interativos_em_mini_tela: list[str] = []
        self.ignorar_texto_tags: list[str] = []
        self.textos_visiveis: list[str] = []
        self.rotulos_acessibilidade: list[str] = []
        self.pilha_blocos: list[tuple[str, str, list[str]]] = []
        self.blocos_texto: list[tuple[str, str]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        mapa = dict(attrs)
        if tag == "html":
            self.html_lang = mapa.get("lang")
            self.html_movimento = mapa.get("data-movimento")
        if tag == "main":
            self.main_profundidade += 1
        if "data-acao-movimento" in mapa:
            self.tem_botao_movimento = True
        if "data-acao-outra-dica" in mapa:
            self.tem_botao_outra_dica = True
        if "data-acao-alternar-anfitria" in mapa:
            self.tem_botao_alternar_anfitria = True
        if "data-anfitria-bloco" in mapa:
            if self.main_profundidade > 0:
                self.anfitria_dentro_de_main = True
            if tag == "aside":
                self.tem_anfitria_flutuante = True
        if "data-anfitria-balao" in mapa:
            self.tem_balao_anfitria = True
        if tag == "memora-personagem":
            self.personagens_memora.append(
                {
                    "expressao": mapa.get("expressao"),
                    "aria_hidden": mapa.get("aria-hidden"),
                }
            )
        if "id" in mapa and mapa["id"]:
            self.ids.add(mapa["id"])
        if tag in {"header", "nav", "main", "footer"}:
            self.marcos.add(tag)
        if tag in {"form", "input", "textarea", "select"}:
            self.forms_ou_inputs.append(tag)
        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"}:
            self.titulos.append(int(tag[1:]))

        for chave_a11y in ("alt", "aria-label"):
            val = mapa.get(chave_a11y)
            if val and val.strip():
                self.rotulos_acessibilidade.append(val.strip())

        classes = set((mapa.get("class") or "").split())
        entrou_mini = "mini-tela" in classes
        if self.pilha_mini_tela or entrou_mini:
            self.pilha_mini_tela.append(tag)
            if not entrou_mini and tag in {"button", "a"}:
                self.interativos_em_mini_tela.append(tag)

        eh_bloco = tag in self.BLOCOS_TAG or bool(classes & self.CLASSES_BLOCO)
        if eh_bloco:
            nome_bloco = next(iter(sorted(classes & self.CLASSES_BLOCO)), tag)
            self.pilha_blocos.append((tag, nome_bloco, []))

        if tag == "a":
            href = mapa.get("href") or ""
            if self.primeiro_link_href is None:
                self.primeiro_link_href = href
            if href.startswith("#"):
                self.ancoras_href.append(href[1:])
            elif href.startswith("http://") or href.startswith("https://"):
                self.links_externos.append(href)
        if tag == "link":
            href = mapa.get("href") or ""
            if href.startswith("http://") or href.startswith("https://"):
                self.links_externos.append(href)
        if tag == "script":
            src = mapa.get("src") or ""
            if src.startswith("http://") or src.startswith("https://"):
                self.links_externos.append(src)
        if tag == "img":
            self.imagens.append((mapa.get("src"), mapa.get("alt")))

        if tag in {"script", "style"}:
            self.ignorar_texto_tags.append(tag)

    def handle_endtag(self, tag: str) -> None:
        if tag == "main" and self.main_profundidade > 0:
            self.main_profundidade -= 1
        if self.pilha_mini_tela:
            self.pilha_mini_tela.pop()
        if self.ignorar_texto_tags and self.ignorar_texto_tags[-1] == tag:
            self.ignorar_texto_tags.pop()
        if self.pilha_blocos and self.pilha_blocos[-1][0] == tag:
            _, nome_bloco, partes = self.pilha_blocos.pop()
            texto = re.sub(r"\s+", " ", "".join(partes)).strip()
            if texto:
                if nome_bloco == "title":
                    self.titulo_pagina = texto
                else:
                    self.blocos_texto.append((nome_bloco, texto))

    def handle_data(self, data: str) -> None:
        if self.ignorar_texto_tags:
            return
        if self.pilha_blocos:
            self.pilha_blocos[-1][2].append(data)
        limpo = data.strip()
        if limpo and not (self.pilha_blocos and self.pilha_blocos[-1][0] == "title"):
            self.textos_visiveis.append(limpo)


def _checar_bloco_memora_ux(origem: str, texto: str, checar_jargoes: bool = False) -> list[str]:
    erros: list[str] = []
    frases = contar_frases(texto)
    if frases > 2:
        erros.append(f"Bloco {origem} excede 2 frases ({frases}): {texto!r}")
    if tem_emoji(texto):
        erros.append(f"Emoji encontrado em {origem}: {texto!r}")
    for proibida in palavras_proibidas_em(texto):
        erros.append(f"Expressao proibida ({proibida!r}) em {origem}: {texto!r}")
    for termo in termos_desalinhados_em(texto):
        erros.append(f"Termo divergente ou exemplo de senha proibido ({termo!r}) em {origem}: {texto!r}")
    if checar_jargoes:
        for padrao in JARGOES_PROIBIDOS:
            m = re.search(padrao, texto, re.IGNORECASE)
            if m:
                erros.append(f"Jargao tecnico proibido ({m.group(0)!r}) em {origem}: {texto!r}")
    return erros


def extrair_mensagens_usuario_js(js_texto: str) -> list[str]:
    """Extrai strings voltadas a pessoa usuaria em tutorial.js (anuncios, rotulos e botoes)."""
    mensagens: list[str] = []
    for bloco_match in re.finditer(
        r"var\s+ROTULOS_(?:ESCALA|TEMA|MOVIMENTO)\s*=\s*\{([^}]+)\}",
        js_texto,
        re.DOTALL,
    ):
        for str_match in re.finditer(r":\s*'([^']*)'", bloco_match.group(1)):
            if str_match.group(1).strip():
                mensagens.append(str_match.group(1).strip())

    for fn_match in re.finditer(r"anunciar\(([^)]+)\)", js_texto):
        partes = re.findall(r"'([^']*)'", fn_match.group(1))
        junto = "".join(partes).strip()
        if junto:
            mensagens.append(junto)

    for tern_match in re.finditer(
        r"(?:textContent|alternar)\s*=\s*[^;]*(?:\?\s*'([^']+)'\s*:\s*'([^']+)')",
        js_texto,
    ):
        mensagens.extend([tern_match.group(1), tern_match.group(2)])
    return mensagens


def extrair_dicas_anfitria() -> list[str]:
    """Le `dicasDaAnfitria` de site/assets/memora/memora.json ou memora-dados.js quando existir."""
    json_path = DIR_SITE / "assets" / "memora" / "memora.json"
    if json_path.is_file():
        import json

        dados = json.loads(json_path.read_text(encoding="utf-8"))
        dicas = dados.get("dicasDaAnfitria") or []
        return [str(d) for d in dicas if isinstance(d, str)]

    dados_js_path = DIR_SITE / "assets" / "memora" / "memora-dados.js"
    if dados_js_path.is_file():
        conteudo = dados_js_path.read_text(encoding="utf-8")
        bloco = re.search(r'"?dicasDaAnfitria"?\s*:\s*\[([^\]]*)\]', conteudo, re.DOTALL)
        if bloco:
            return [m.group(1) or m.group(2) for m in re.finditer(r'"([^"]+)"|\'([^\']+)\'', bloco.group(1))]
    return []


def validar_memora_ux_e_orcamento(
    inspetor: InspetorHtml,
    arquivos_js: list[Path],
    orcamento_bytes: int = ORCAMENTO_JS_BYTES,
    mensagens_js: list[str] | None = None,
    dicas_anfitria: list[str] | None = None,
) -> list[str]:
    erros: list[str] = []

    if not inspetor.titulo_pagina:
        erros.append("Tag <title> ausente ou vazia em index.html.")
    else:
        if tem_emoji(inspetor.titulo_pagina):
            erros.append(f"Emoji encontrado em <title>: {inspetor.titulo_pagina!r}")
        for proibida in palavras_proibidas_em(inspetor.titulo_pagina):
            erros.append(f"Palavra proibida ({proibida!r}) em <title>: {inspetor.titulo_pagina!r}")
        for termo in termos_desalinhados_em(inspetor.titulo_pagina):
            erros.append(f"Termo divergente ({termo!r}) em <title>: {inspetor.titulo_pagina!r}")

    for origem, texto in inspetor.blocos_texto:
        erros.extend(_checar_bloco_memora_ux(f"<{origem}>", texto))

    for texto in inspetor.textos_visiveis:
        if tem_emoji(texto):
            erros.append(f"Emoji encontrado em texto visivel: {texto!r}")
        for proibida in palavras_proibidas_em(texto):
            erros.append(f"Expressao proibida ({proibida!r}) em texto visivel: {texto!r}")
        for termo in termos_desalinhados_em(texto):
            erros.append(f"Termo divergente ou exemplo de senha proibido ({termo!r}) em texto visivel: {texto!r}")

    for rotulo in inspetor.rotulos_acessibilidade:
        if tem_emoji(rotulo):
            erros.append(f"Emoji encontrado em atributo alt/aria-label: {rotulo!r}")
        for proibida in palavras_proibidas_em(rotulo):
            erros.append(f"Expressao proibida ({proibida!r}) em alt/aria-label: {rotulo!r}")
        for termo in termos_desalinhados_em(rotulo):
            erros.append(f"Termo divergente ({termo!r}) em alt/aria-label: {rotulo!r}")

    for msg in mensagens_js or []:
        erros.extend(_checar_bloco_memora_ux("tutorial.js", msg, checar_jargoes=True))

    for dica in dicas_anfitria or []:
        erros.extend(_checar_bloco_memora_ux("dicasDaAnfitria", dica, checar_jargoes=True))

    total_js_bytes = sum(arq.stat().st_size for arq in arquivos_js if arq.is_file())
    if total_js_bytes > orcamento_bytes:
        erros.append(
            f"Orcamento de JavaScript excedido: {total_js_bytes} bytes > {orcamento_bytes} bytes."
        )

    return erros


def listar_js_runtime() -> list[Path]:
    arquivos: list[Path] = []
    for pasta in (DIR_SITE / "scripts", DIR_SITE / "vendor"):
        if pasta.is_dir():
            arquivos.extend(sorted(pasta.glob("*.js")))
    dados_memora = DIR_SITE / "assets" / "memora" / "memora-dados.js"
    if dados_memora.is_file():
        arquivos.append(dados_memora)
    return arquivos


def validar() -> list[str]:
    erros: list[str] = []

    for arq in [HTML_PATH, TOKENS_PATH, MAIN_CSS_PATH, JS_PATH]:
        if not arq.is_file():
            erros.append(f"Arquivo obrigatório não encontrado: {arq.relative_to(RAIZ)}")
    if erros:
        return erros

    html_texto = HTML_PATH.read_text(encoding="utf-8")
    tokens_texto = TOKENS_PATH.read_text(encoding="utf-8")
    main_css_texto = MAIN_CSS_PATH.read_text(encoding="utf-8")
    arquivos_js = listar_js_runtime()

    # 1. Contraste WCAG 2.2 em todas as paletas
    paletas = extrair_paletas_tokens(tokens_texto)
    pares_texto = [
        ("texto", "fundo"),
        ("texto", "superficie"),
        ("texto", "destaque"),
        ("texto-suave", "fundo"),
        ("texto-suave", "superficie"),
        ("texto-suave", "destaque"),
        ("primaria", "fundo"),
        ("primaria", "superficie"),
        ("primaria", "destaque"),
        ("sobre-primaria", "primaria"),
        ("sobre-primaria", "sucesso"),
        ("sobre-perigo", "perigo"),
    ]
    pares_grandes = [
        ("borda", "fundo"),
        ("borda", "superficie"),
    ]

    for tema, cores in paletas.items():
        minimo_texto = 7.0 if tema == "alto-contraste" else 4.5
        for fg, bg in pares_texto:
            ratio = _razoes_contraste(cores[fg], cores[bg])
            alvo = minimo_texto if fg != "primaria" else (minimo_texto if bg != "destaque" else 4.5)
            if ratio < alvo:
                erros.append(
                    f"Contraste insuficiente no tema '{tema}': {fg} ({cores[fg]}) sobre {bg} ({cores[bg]}) = {ratio:.2f}:1 (< {alvo}:1)"
                )
        for fg, bg in pares_grandes:
            ratio = _razoes_contraste(cores[fg], cores[bg])
            if ratio < 3.0:
                erros.append(
                    f"Contraste de borda insuficiente no tema '{tema}': {fg} sobre {bg} = {ratio:.2f}:1 (< 3.0:1)"
                )

    # 2. Inspeção HTML estrutural e de segurança
    inspetor = InspetorHtml()
    inspetor.feed(html_texto)

    if inspetor.html_lang != "pt-BR":
        erros.append(f"<html lang> esperado 'pt-BR', encontrado {inspetor.html_lang!r}")
    if inspetor.html_movimento not in {"normal", "reduzido"}:
        erros.append(
            f"<html data-movimento> esperado 'normal' ou 'reduzido', encontrado {inspetor.html_movimento!r}"
        )
    if not inspetor.tem_botao_movimento:
        erros.append("Controle visível 'Reduzir movimento' ([data-acao-movimento]) ausente em index.html.")

    for marco in ["header", "nav", "main", "footer"]:
        if marco not in inspetor.marcos:
            erros.append(f"Marco semântico ausente: <{marco}>")

    if "conteudo-principal" not in inspetor.ids:
        erros.append("ID 'conteudo-principal' ausente no documento.")
    if inspetor.primeiro_link_href != "#conteudo-principal":
        erros.append(
            f"O primeiro link de salto deve apontar para '#conteudo-principal', encontrado {inspetor.primeiro_link_href!r}"
        )

    for destino in inspetor.ancoras_href:
        if destino not in inspetor.ids:
            erros.append(f"Âncora quebrada: href='#{destino}' sem elemento com id correspondente.")

    if inspetor.forms_ou_inputs:
        erros.append(f"Elementos de coleta proibidos encontrados: {inspetor.forms_ou_inputs}")

    if inspetor.links_externos:
        erros.append(f"Links ou recursos externos proibidos encontrados: {inspetor.links_externos}")

    if inspetor.interativos_em_mini_tela:
        erros.append(
            f"Mini-telas ilustrativas devem ser inertes (sem <button>/<a>): encontrado {inspetor.interativos_em_mini_tela}"
        )

    if inspetor.titulos.count(1) != 1 or inspetor.titulos[0] != 1:
        erros.append(f"Deve haver exatamente um <h1> abrindo os títulos: {inspetor.titulos}")
    for anterior, atual in zip(inspetor.titulos, inspetor.titulos[1:]):
        if atual - anterior > 1:
            erros.append(f"Salto inválido na hierarquia de títulos: h{anterior} -> h{atual}")

    if not inspetor.imagens and not inspetor.personagens_memora:
        erros.append("Nenhuma ilustração encontrada em index.html.")
    for src, alt in inspetor.imagens:
        if not src:
            erros.append("Tag <img> sem atributo src.")
            continue
        caminho_img = DIR_SITE / src
        if not caminho_img.is_file():
            erros.append(f"Imagem referenciada não existe: {src}")
        if not alt or not alt.strip():
            erros.append(f"Imagem sem texto alternativo (alt) em português: {src}")

    if not inspetor.personagens_memora:
        erros.append("Nenhum componente <memora-personagem> encontrado em index.html.")
    for idx_p, personagem in enumerate(inspetor.personagens_memora, start=1):
        expr = personagem.get("expressao")
        if expr not in EXPRESSOES_MEMORA:
            erros.append(
                f"<memora-personagem> #{idx_p} com expressao invalida: {expr!r}"
            )
        if personagem.get("aria_hidden") != "true":
            erros.append(
                f"<memora-personagem> #{idx_p} deve possuir aria-hidden='true'."
            )

    if not inspetor.tem_botao_outra_dica:
        erros.append("Controle [data-acao-outra-dica] ausente em index.html.")
    if not inspetor.tem_botao_alternar_anfitria:
        erros.append("Controle [data-acao-alternar-anfitria] ausente em index.html.")
    if not inspetor.tem_anfitria_flutuante:
        erros.append("Painel <aside class='anfitria-flutuante' data-anfitria-bloco> ausente fora de <main>.")
    if inspetor.anfitria_dentro_de_main:
        erros.append("O painel da anfitria [data-anfitria-bloco] deve ficar fora de <main> e dos capitulos.")
    if not inspetor.tem_balao_anfitria:
        erros.append("Elemento [data-anfitria-balao] ausente em index.html.")

    dir_ilustracoes = DIR_SITE / "assets" / "ilustracoes"
    for legado in ATIVOS_LEGADOS_MEMORA:
        if (dir_ilustracoes / legado).exists():
            erros.append(f"Ativo legado nao removido de site/assets/ilustracoes: {legado}")
        if legado in html_texto:
            erros.append(f"Referencia legada ainda presente em index.html: {legado}")

    imagens_referenciadas = {
        (DIR_SITE / src).resolve()
        for src, _alt in inspetor.imagens
        if src
    }
    for arq_ilustracao in sorted(dir_ilustracoes.iterdir()):
        if arq_ilustracao.is_file() and arq_ilustracao.suffix.lower() in {".svg", ".png"}:
            if arq_ilustracao.resolve() not in imagens_referenciadas:
                erros.append(f"Ativo orfao nao referenciado em index.html: {arq_ilustracao.name}")

    dir_memora = DIR_SITE / "assets" / "memora"
    memora_json_path = dir_memora / "memora.json"
    memora_dados_js_path = dir_memora / "memora-dados.js"
    if not memora_json_path.is_file():
        erros.append("Arquivo exportado ausente: site/assets/memora/memora.json")
    else:
        import json

        dados_memora = json.loads(memora_json_path.read_text(encoding="utf-8"))
        expressoes_json = set(dados_memora.get("expressoes") or [])
        faltando_expr = sorted(set(EXPRESSOES_MEMORA) - expressoes_json)
        if faltando_expr:
            erros.append(f"Expressoes ausentes em memora.json: {faltando_expr}")
        if len(dados_memora.get("dicasDaAnfitria") or []) < 14:
            erros.append("memora.json deve conter pelo menos 14 dicas da anfitria.")
        paletas_memora = set((dados_memora.get("paletas") or {}).keys())
        if not {"claro", "escuro", "alto-contraste"} <= paletas_memora:
            erros.append(f"Paletas incompletas em memora.json: {sorted(paletas_memora)}")

    if not memora_dados_js_path.is_file():
        erros.append("Arquivo exportado ausente: site/assets/memora/memora-dados.js")

    for expr in EXPRESSOES_MEMORA:
        svg_path = dir_memora / f"{expr}.svg"
        if not svg_path.is_file():
            erros.append(f"SVG exportado ausente: site/assets/memora/{expr}.svg")
            continue
        svg_texto = svg_path.read_text(encoding="utf-8")
        for grupo in GRUPOS_MEMORA:
            if f'id="{grupo}"' not in svg_texto:
                erros.append(
                    f"SVG site/assets/memora/{expr}.svg sem grupo semantico id='{grupo}'."
                )

    # 3. Rede externa ausente em CSS/JS, jargões ausentes e portão memora-ux + orçamento JS
    alvos_rede: list[tuple[str, str]] = [
        ("main.css", main_css_texto),
        ("tokens.css", tokens_texto),
    ]
    for arq_js in arquivos_js:
        conteudo_js = arq_js.read_text(encoding="utf-8")
        alvos_rede.append((arq_js.name, conteudo_js))
        if re.search(r"\b(fetch|XMLHttpRequest|sendBeacon)\b", conteudo_js):
            erros.append(f"Uso proibido de API de requisição de rede encontrado em {arq_js.name}.")

    for nome_arq, conteudo in alvos_rede:
        if re.search(r"https?://", conteudo, re.IGNORECASE):
            erros.append(f"Referência de rede externa encontrada em {nome_arq}.")

    texto_corrido = f"{inspetor.titulo_pagina} " + " ".join(inspetor.textos_visiveis)
    for padrao in JARGOES_PROIBIDOS:
        m = re.search(padrao, texto_corrido, re.IGNORECASE)
        if m:
            erros.append(f"Jargão técnico proibido encontrado no texto visível: '{m.group(0)}'")

    mensagens_js = extrair_mensagens_usuario_js(JS_PATH.read_text(encoding="utf-8"))
    dicas_anfitria = extrair_dicas_anfitria()
    erros.extend(
        validar_memora_ux_e_orcamento(
            inspetor,
            arquivos_js,
            mensagens_js=mensagens_js,
            dicas_anfitria=dicas_anfitria,
        )
    )
    return erros


def executar_autoteste() -> None:
    assert contar_frases("Fica só aqui. Você não precisa informar.") == 2
    assert contar_frases("Uma. Duas! Três?") == 3
    assert contar_frases("Abra o gov.br hoje. Veja 1.000 dicas do Dr. João.") == 2
    assert tem_emoji("Texto seguro 🔒") is True
    assert tem_emoji("Voltar ↑") is False
    assert palavras_proibidas_em("Guia para Pessoas Idosas") != []
    assert palavras_proibidas_em("Guia do Memora — passo a passo") == []
    assert termos_desalinhados_em("Use sua Frase Secreta") != []
    assert termos_desalinhados_em("Toque em Mostrar frase") != []
    assert termos_desalinhados_em("Exemplo: cafe com bolo da tarde") != []
    assert termos_desalinhados_em("Use sua senha e toque em Mostrar senha") == []

    insp_ruim = InspetorHtml()
    insp_ruim.feed(
        """<!DOCTYPE html><html lang="pt-BR" data-movimento="normal">
        <head><title>Guia para Pessoas Idosas</title></head>
        <body><span class="grupo-legenda">Uma. Duas. Tres.</span>
        <div>Selo para terceira idade 🔒</div>
        <p>Use Frase Secreta com cafe com bolo da tarde. Toque em Mostrar frase.</p>
        <p>Primeira frase. Segunda frase. Terceira frase.</p>
        <p>Pronto 🔒</p></body></html>"""
    )
    falhas_ux = validar_memora_ux_e_orcamento(
        insp_ruim,
        [],
        orcamento_bytes=10,
        mensagens_js=["Feito para idoso 😊"],
        dicas_anfitria=["Dica com API."],
    )
    assert any("Pessoas Idosas" in f or "Idosas" in f for f in falhas_ux), falhas_ux
    assert any("Frase Secreta" in f for f in falhas_ux), falhas_ux
    assert any("Mostrar frase" in f for f in falhas_ux), falhas_ux
    assert any("cafe com bolo" in f for f in falhas_ux), falhas_ux
    assert any("grupo-legenda" in f for f in falhas_ux), falhas_ux
    assert any("texto visivel" in f for f in falhas_ux), falhas_ux
    assert any("tutorial.js" in f for f in falhas_ux), falhas_ux
    assert any("dicasDaAnfitria" in f for f in falhas_ux), falhas_ux
    assert any("excede 2 frases" in f for f in falhas_ux), falhas_ux
    assert any("Emoji" in f for f in falhas_ux), falhas_ux

    insp_grande = InspetorHtml()
    insp_grande.feed(
        '<html lang="pt-BR" data-movimento="normal"><head><title>Guia do Memora</title></head><body></body></html>'
    )
    falhas_orc = validar_memora_ux_e_orcamento(insp_grande, [JS_PATH], orcamento_bytes=10)
    assert any("Orcamento de JavaScript excedido" in f for f in falhas_orc), falhas_orc


if __name__ == "__main__":
    if "--autoteste" in sys.argv:
        executar_autoteste()
        print("OK: Autoteste do validador memora-ux e orcamento aprovado.")
        sys.exit(0)
    falhas = validar()
    if falhas:
        print("FALHAS NA VALIDACAO DO SITE:")
        for item in falhas:
            print(f" - {item}")
        sys.exit(1)
    print(
        "OK: Estrutura HTML, WCAG 2.2 AA/AAA, zero links/formularios externos, "
        "zero jargoes, memora-ux e orcamento JS aprovados."
    )
