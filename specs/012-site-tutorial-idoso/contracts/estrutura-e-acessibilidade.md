# Interface & Accessibility Contract: Site Tutorial Acolhedor (`012`) — Rodada 2

**Branch**: `redesign/S01-S10-S11-site-base` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)

Este documento define os contratos de estrutura HTML, controles de conforto, componente `<memora-personagem>`, CSS progressivo, regras de texto `memora-ux`, privacidade e orçamento de desempenho em `site/`.

---

## 1. Contrato de Marcos Semânticos e Título (`FR-002`, `AC-005`)

1. **Raiz HTML**: `<html lang="pt-BR" data-tema="claro" data-escala="padrao" data-movimento="normal">` com `<meta charset="UTF-8">` e `<meta name="viewport" content="width=device-width, initial-scale=1.0">`.
2. **Título da aba (`<title>`)**: DEVE cumprir a `memora-ux`, sendo estritamente livre de palavras proibidas (`idoso`, `idosa`, `idosos`, `idosas`, `terceira idade`, `melhor idade`, `sênior`) e de emojis (ex.: `"Guia do Memora — passo a passo, no seu ritmo"`).
3. **Atalho de teclado inicial**: O primeiro elemento focável dentro de `<body>` DEVE ser `"Ir direto para o conteúdo principal"` apontando para `#conteudo-principal`, visível ao receber `:focus-visible`.
4. **Marcos obrigatórios**: `<header>`, `<nav aria-label="...">` com atalhos para os 9 capítulos (`#boas-vindas` até `#duvidas-frequentes`), `<main id="conteudo-principal" tabindex="-1">` com um único `<h1>` e hierarquia `h2`/`h3` sem saltos, e `<footer>` informativo com botão visível de retorno ao início.

---

## 2. Contrato do Painel de Conforto Visual (`FR-010`, `S10`, `AC-001`–`AC-004`)

| Grupo de Controles | Rótulos Visíveis em PT-BR | Atributos ARIA Obrigatórios | Efeito na Raiz `<html>` |
| :--- | :--- | :--- | :--- |
| Tamanho da letra | `Letra normal` · `Letra grande` · `Letra muito grande` | `role="group"`, `aria-label`, `aria-pressed="true\|false"` em `<button type="button">` | Atualiza `data-escala="padrao\|grande\|muito-grande"` |
| Aparência da tela | `Fundo claro` · `Fundo escuro` · `Alto contraste` | `role="group"`, `aria-label`, `aria-pressed="true\|false"` em `<button type="button">` | Atualiza `data-tema="claro\|escuro\|alto-contraste"` |
| Movimento na página | `Reduzir movimento` (botão alternador com rótulo visível) | `aria-pressed="true\|false"` em `<button type="button">` com área `>= 48×48 px` | Atualiza `data-movimento="normal\|reduzido"` |

### Regras de Fallback e Precedência para Movimento Reduzido

1. Sem chave `memora.tutorial.reduzir_movimento` no `localStorage`, o site lê `window.matchMedia('(prefers-reduced-motion: reduce)').matches` e aplica `'reduzido'` se verdadeiro.
2. Após alternância manual no botão `Reduzir movimento`, o valor escolhido pelo visitante é salvo em `localStorage` (com fallback em memória) e passa a prevalecer sobre o estado inicial do sistema.
3. CSS também respeita `@media (prefers-reduced-motion: reduce)` quando `[data-movimento]` não for explicitamente `'normal'` por decisão manual, garantindo que animações e View Transitions fiquem desligadas sem perder conteúdo (`SC-003`).

### Tokens Oficiais e CSS Moderno Progressivo (`FR-016`, `S08`, `S09`)

1. Valores hexadecimais oficiais de [`cores.dart`](file:///c:/Users/Eduardo/Memora/app/lib/design_system/tokens/cores.dart) permanecem em `site/styles/tokens.css` para `[data-tema="claro"]`, `[data-tema="escuro"]` e `[data-tema="alto-contraste"]` (`>= 7,0:1` em Alto Contraste).
2. `light-dark()` só PODE ser aplicado para o par `claro` / `escuro` dentro de `@supports (color: light-dark(#000, #fff))`, mantendo as definições clássicas como base e mantendo `[data-tema="alto-contraste"]` em regras explícitas independentes.
3. Consultas de contêiner (`@container`), `text-wrap: pretty`, View Transitions (`@view-transition` / `document.startViewTransition`) e revelação por rolagem (`animation-timeline: view()`) DEVEM ser encapsulados em `@supports`, desativados em `[data-movimento="reduzido"]`, e nunca impedir navegação ou leitura em navegadores sem suporte.

---

## 3. Contrato do Web Component `<memora-personagem>` e da Anfitriã (`FR-003`, `FR-013`, `FR-015`)

1. **Tag & Atributos observados**: `<memora-personagem expressao="neutra|falando|pensando|comemorando|preocupada|acenando|dica|mini" falando="true|false">`
2. **Acessibilidade e autonomia offline (`FR-003`, `SC-006`)**:
   - Deve carregar `aria-hidden="true"` (decorativo; o texto/balão já comunica toda a informação).
   - Deve pausar loops de animação (`respirar`, `piscar`, `falar`) automaticamente quando `data-movimento="reduzido"` estiver ativo ou quando o elemento sair da área visível (`IntersectionObserver`).
   - Os dados das expressões, paletas e dicas da anfitriã DEVEM poder ser carregados localmente via módulo JS gerado (`site/assets/memora/memora-dados.js`) sem exigir `fetch()` (que navegadores bloqueiam em `file://` por CORS); caso o payload falhe ou esteja ausente, a página continua legível e exibe o texto das dicas sem erros visíveis.
3. **Anfitriã no topo (`S05`, `WCAG 2.2.2`)**:
   - Exibe balão alimentado exclusivamente por `dicasDaAnfitria` exportadas de `site/assets/memora/`.
   - Contém botão explícito e acessível **"Outra dica da Memora"** (`>= 48×48 px`, foco visível de alto contraste, nenhuma navegação externa ou alteração de estado de conta).
   - Alterna automaticamente a cada `20.000 ms` **somente** enquanto: `reduzirMovimento === 'normal'`, o botão **"Outra dica da Memora"** ainda não tiver sido acionado manualmente na sessão e não houver foco ativo por teclado/leitor dentro do bloco da anfitriã.
4. **Sincronia com leitura em voz alta (`S06`)**:
   - Enquanto `"Ouvir este trecho"` está ativo para um capítulo, o `<memora-personagem>` ligado ao capítulo assume `falando="true"`.
   - Eventos `onboundary` animam a boca de acordo com as palavras; na ausência de eventos `onboundary` após `onstart`, mantém ritmo calmo contínuo até `onend`/`onerror`. Sob `data-movimento="reduzido"`, a boca permanece parada sem ocultar o botão `"Ouvir este trecho"`.

---

## 4. Contrato `memora-ux`, Anti-Engenharia Social e Orçamento (`FR-002`, `FR-011`–`FR-014`)

1. **Texto (`S11`, `SC-001`)**: Todo bloco de texto visível no HTML (`<title>`, `<p>`, `<figcaption>`, `<li>`, `<summary>`, botões, avisos e balões exportados) DEVE conter no máximo **2 frases curtas**, zero emojis e zero termos proibidos (`idoso`, `idosa`, `idosos`, `idosas`, `terceira idade`, `melhor idade`, `sênior` e expressões de incapacidade). A segmentação de frases segue a mesma disciplina do `texto_da_interface_test.dart` (terminadores `.`, `!`, `?`, `…` seguidos de espaço/fim, preservando endereços como `gov.br`, numerais decimais/milhares e abreviações como `ex.` ou `Dr.`).
2. **Ativos (`S04`, `S07`)**: Zero referências às 7 imagens legadas removidas da Memora (`memora_ajuda_robo.png`, `memora_alerta_robo.png`, `memora_dica_robo.png`, `memora_perfil_robo.png`, `memora_comemorando.svg`, `memora_falando.svg`, `memora_neutra.svg`); os ícones de portas e pessoas (`porta_*.svg`, `casal_idoso.svg`, `pessoa_com_celular.svg`, `ajuste_aparencia.svg`) usam exclusivamente vetores locais da família **Material Rounded** (consistente com `Icons.*_rounded` do app) e todas as ilustrações referenciadas existem em `site/assets/`.
3. **Segurança e Offline**: Zero `<form>`, `<input>`, `<textarea>`, `<select>`, zero links `http(s)://`, zero requisições de rede ou CDN em runtime (`fetch`, `XMLHttpRequest`, `@import url("http...")`).
4. **Alvos e Espaçamento**: Todos os controles interativos cumprem `min-height: 48px`, `min-width: 48px` e espaçamento `>= 8px`.
5. **Orçamento JS e Desempenho (`S12`, `S13`)**: Soma de todos os scripts carregados no site em produção (`site/scripts/`, `site/vendor/` e eventuais dados JS em `site/assets/memora/memora-dados.js`) **<= `102.400 bytes` (`100 KiB`)**, animando somente `transform` e `opacity`, e passando no Playwright sob throttling `CPU 4x` sem violações `axe-core` nem `scrollWidth > clientWidth`.
