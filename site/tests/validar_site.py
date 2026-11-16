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
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.html_lang: str | None = None
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

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        mapa = dict(attrs)
        if tag == "html":
            self.html_lang = mapa.get("lang")
        if "id" in mapa and mapa["id"]:
            self.ids.add(mapa["id"])
        if tag in {"header", "nav", "main", "footer"}:
            self.marcos.add(tag)
        if tag in {"form", "input", "textarea", "select"}:
            self.forms_ou_inputs.append(tag)
        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"}:
            self.titulos.append(int(tag[1:]))

        classes = (mapa.get("class") or "").split()
        entrou_mini = "mini-tela" in classes
        if self.pilha_mini_tela or entrou_mini:
            self.pilha_mini_tela.append(tag)
            if not entrou_mini and tag in {"button", "a"}:
                self.interativos_em_mini_tela.append(tag)

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

        if tag in {"script", "style", "title"}:
            self.ignorar_texto_tags.append(tag)

    def handle_endtag(self, tag: str) -> None:
        if self.pilha_mini_tela:
            self.pilha_mini_tela.pop()
        if self.ignorar_texto_tags and self.ignorar_texto_tags[-1] == tag:
            self.ignorar_texto_tags.pop()

    def handle_data(self, data: str) -> None:
        if not self.ignorar_texto_tags:
            limpo = data.strip()
            if limpo:
                self.textos_visiveis.append(limpo)


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
    js_texto = JS_PATH.read_text(encoding="utf-8")

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

    if not inspetor.imagens:
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

    # 3. Rede externa ausente em CSS/JS e jargões ausentes no texto visível
    for nome_arq, conteudo in [("main.css", main_css_texto), ("tokens.css", tokens_texto), ("tutorial.js", js_texto)]:
        if re.search(r"https?://", conteudo, re.IGNORECASE):
            erros.append(f"Referência de rede externa encontrada em {nome_arq}.")
    if re.search(r"\b(fetch|XMLHttpRequest|sendBeacon)\b", js_texto):
        erros.append("Uso proibido de API de requisição de rede encontrado em tutorial.js.")

    texto_corrido = " ".join(inspetor.textos_visiveis)
    for padrao in JARGOES_PROIBIDOS:
        m = re.search(padrao, texto_corrido, re.IGNORECASE)
        if m:
            erros.append(f"Jargão técnico proibido encontrado no texto visível: '{m.group(0)}'")

    return erros


if __name__ == "__main__":
    falhas = validar()
    if falhas:
        print("FALHAS NA VALIDACAO DO SITE:")
        for item in falhas:
            print(f" - {item}")
        sys.exit(1)
    print("OK: Estrutura HTML, WCAG 2.2 AA/AAA, zero links/formularios externos e zero jargoes aprovados.")
