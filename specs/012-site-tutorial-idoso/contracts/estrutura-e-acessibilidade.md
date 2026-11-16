# Interface & Accessibility Contract: Site Tutorial Acolhedor (`012-site-tutorial-idoso`)

**Branch**: `feature/012-site-tutorial-idoso` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)

Este documento define os contratos de interface estrutural, acessibilidade, privacidade e comportamento cliente que o site em `site/` deve satisfazer integralmente.

---

## 1. Contrato de Marcos Semânticos e Hierarquia (`AC-005`)

1. **Idioma e codificação**: `<html lang="pt-BR" data-tema="claro" data-escala="padrao">` com `<meta charset="UTF-8">` e `<meta name="viewport" content="width=device-width, initial-scale=1.0">`.
2. **Atalho de teclado inicial**: O primeiro elemento focável dentro de `<body>` DEVE ser o link de salto `"Ir direto para o conteúdo principal"` apontando para `#conteudo-principal`, visível ao receber foco de teclado (`:focus-visible`).
3. **Marcos obrigatórios**:
   - `<header>`: título de identificação do guia, barra acessível de conforto visual (tamanho da letra + modo visual) e sumário de capítulos.
   - `<nav aria-label="...">`: navegação explícita do sumário direto para os 9 capítulos (`#boas-vindas` até `#duvidas-frequentes`).
   - `<main id="conteudo-principal" tabindex="-1">`: único `<h1>` no capítulo de abertura, seguido de `<section>` por capítulo usando `<h2>` e `<h3>` em ordem estrita sem pular níveis.
   - `<footer>`: fechamento acolhedor reafirmando que o site é apenas informativo, zero formulários e botão visível `"Voltar para o início da página"`.
4. **Botão persistente de retorno ao topo**: Controle acessível sempre disponível ou ao alcance fácil para voltar ao início (`#topo`) sem cansar o leitor em páginas longas.

---

## 2. Contrato de Controles de Conforto Visual (`FR-010`, `AC-001`, `AC-004`)

| Grupo de Controles | Rótulos Visíveis em PT-BR | Atributos ARIA Obrigatórios | Efeito Imediato na Raiz |
| :--- | :--- | :--- | :--- |
| Tamanho da letra | `Letra normal` · `Letra grande` · `Letra muito grande` | `role="group"`, `aria-label`, `aria-pressed="true\|false"` em cada `<button type="button">` | Atualiza `data-escala="padrao\|grande\|muito-grande"` em `<html>` |
| Aparência da tela | `Fundo claro` · `Fundo escuro` · `Alto contraste` | `role="group"`, `aria-label`, `aria-pressed="true\|false"` em cada `<button type="button">` | Atualiza `data-tema="claro\|escuro\|alto-contraste"` em `<html>` |

### Valores Oficiais dos Tokens CSS (`site/styles/tokens.css`)

Espelhados de [`cores.dart`](file:///c:/Users/Eduardo/Memora/app/lib/design_system/tokens/cores.dart):

- **Claro**: `--fundo: #F8F8F8`, `--superficie: #FFFFFF`, `--superficie-alt: #D8D8D8`, `--destaque: #E3EAFF`, `--medalhao: #E3EAFF`, `--primaria: #1040F8`, `--sobre-primaria: #FFFFFF`, `--texto: #111111`, `--texto-suave: #4A4A4A`, `--borda: #6B6B6B`, `--sucesso: #186A2E`, `--perigo: #B3231F`, `--sobre-perigo: #FFFFFF`.
- **Escuro**: `--fundo: #101216`, `--superficie: #1B1E24`, `--superficie-alt: #2A2E36`, `--destaque: #22305A`, `--medalhao: #DCE5FF`, `--primaria: #9CB8FF`, `--sobre-primaria: #06132E`, `--texto: #F2F4F8`, `--texto-suave: #C2C7D0`, `--borda: #8A909C`, `--sucesso: #7CD69A`, `--perigo: #FF9B95`, `--sobre-perigo: #3A0705`.
- **Alto Contraste**: `--fundo: #000000`, `--superficie: #000000`, `--superficie-alt: #1A1A1A`, `--destaque: #10245A`, `--medalhao: #DCE5FF`, `--primaria: #8FB4FF`, `--sobre-primaria: #000000`, `--texto: #FFFFFF`, `--texto-suave: #E8E8E8`, `--borda: #FFFFFF`, `--sucesso: #7BE49B`, `--perigo: #FF9E97`, `--sobre-perigo: #000000`.

---

## 3. Contrato das Mini-Telas Ilustrativas (`FR-003`, `FR-007`)

Toda mini-tela de demonstração visual dentro de um capítulo:
1. DEVE conter um selo/legenda visível de texto explícito: ex. `"Exemplo de como aparece no aplicativo"` (nunca induzir o visitante a achar que está numa conta ativa).
2. Se contiver representação de botões do aplicativo (ex.: `Ajustes`, `Início`, `Meu perfil`, `Estou bem`, `Preciso de ajuda`, `Usar esta foto`), eles DEVEM ser elementos visuais não clicáveis (`<div role="img" aria-label="...">` ou `<figure>` com `<figcaption>`) ou claramente inertes para não gerar frustração de "cliquei e não aconteceu nada" nem simular fluxos falsos.

---

## 4. Contrato Anti-Engenharia Social e Offline (`FR-011`, `FR-012`, `SC-006`)

1. Zero elementos `<form>`, zero `<input>`, zero `<textarea>`, zero `<select>`.
2. Zero links `<a href="http...">` ou `<a href="https...">` (todas as âncoras apontam exclusivamente para `#...` dentro da própria página).
3. Zero requisições de rede em runtime (`fetch`, `XMLHttpRequest`, `<script src="http...">`, `<link href="http...">`, `@import url("http...")`).
4. Alvos interativos (botões de ajuste visual, links do sumário, botões de ouvir em voz alta, `<summary>` das dúvidas, botão de voltar ao topo) devem cumprir `min-height: 48px` e `min-width: 48px` com espaçamento mínimo `>= 8px` (`gap: 0.75rem` / `12px`).
