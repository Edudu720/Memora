# Research: Site Tutorial Acolhedor do Memora (`012`) — Rodada 2

**Branch**: `redesign/S01-S10-S11-site-base` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)

## Decisões Técnicas Consolidadas (Rodada 1 + S01/Rodada 2)

### 1. Stack Estática, Web Components e Política de Bibliotecas (`S01`, `S03`, `S13`, `FR-014`)

- **Decision**: Manter HTML5 semântico + CSS3 modular + JavaScript ES6+ sem framework nem *bundler*, estruturando o personagem da Memora como Custom Element nativo (`<memora-personagem>`) animado com **Web Animations API** como caminho padrão. Caso alguma sequência/boca mais complexa justifique biblioteca auxiliar, apenas bibliotecas enxutas **copiadas localmente em `site/vendor/` com versão fixa** são aceitas — jamais CDN ou importação remota — respeitando teto máximo aproximado de **`100 KB`** no total de JavaScript carregado pelo site em produção.
- **Rationale**:
  - Preserva abertura direta via `file://` e funcionamento integral offline (`SC-006`).
  - Zero superfície de ataque por scripts remotos (`Threat Model`).
  - Orçamento rígido protege aparelhos Android de entrada (Galaxy A/M), complementado por animações restritas a `transform` e `opacity` + pausa fora da viewport via `IntersectionObserver`.
- **Alternatives considered**:
  - Proibir qualquer biblioteca mesmo vendored: poderia dificultar sequências específicas caso Web Animations não baste.
  - Adotar framework SPA ou GSAP por padrão desde já: adicionaria peso e complexidade desnecessários antes de provar necessidade.

### 2. Fonte Única da Memora e Lista de Dicas via Exportador Dart (`S02`, `S04`, `FR-015`)

- **Decision**: Implementar ferramenta Dart (`app/tool/exportar_memora_site.dart`) que lê diretamente as poses e camadas de [`PintorDaMemora`](file:///c:/Users/Eduardo/Memora/app/lib/design_system/componentes/ilustracao/memora_animada/pintores/pintor_da_memora.dart) / [`poses.dart`](file:///c:/Users/Eduardo/Memora/app/lib/design_system/componentes/ilustracao/memora_animada/poses.dart) e a lista fixa de dicas da anfitriã (`T086` da 013) para gravar em `site/assets/memora/`:
  - Um SVG por expressão (`neutra`, `falando`, `pensando`, `comemorando`, `preocupada`, `acenando`, `dica`, `mini`, `carregando`) contendo grupos `<g id="...">` nomeados por peça anatômica (`sombra`, `corpo`, `painel-peito`, `antena`, `cabeca`, `visor`, `rosto`, `olhos`, `boca`, `braco-esquerdo`, `braco-direito`, `escudo`, `livro`, `barra`);
  - Um JSON consolidado (`memora.json`) com metadados das poses, paletas por tema (`claro`, `escuro`, `alto-contraste`) e array ordenado de dicas da anfitriã.
- **Rationale**:
  - Garante que a Memora do site seja **idêntica** à do aplicativo (`memora-ux`, `FR-015`) e evita divergência editorial ou de segurança nas dicas da anfitriã (que são revisadas no código, nunca vindas da IA em runtime).
  - Permite remover os 7 arquivos antigos de ilustração da Memora (`memora_ajuda_robo.png`, `memora_alerta_robo.png`, `memora_dica_robo.png`, `memora_perfil_robo.png`, `memora_comemorando.svg`, `memora_falando.svg`, `memora_neutra.svg`) e manter `LICENCAS.md` atualizado (`S04`).
- **Alternatives considered**:
  - Redesenhar a Memora manualmente em SVG separado dentro de `site/`: violaria a regra de fonte única entre app e site.

### 3. Anfitriã do Site e Sincronização Vocal (`S05`, `S06`, `FR-013`, `FR-015`)

- **Decision**:
  - **Anfitriã (`S05`)**: exibe balão com as dicas de `memora.json`, oferece botão acessível **"Outra dica da Memora"** (`>= 48×48 px`), e cicla automaticamente a cada `20 s` **somente** quando: (1) `"Reduzir movimento"` está desligado, (2) nenhuma interação manual ocorreu no botão `"Outra dica da Memora"` (`WCAG 2.2.2`), e (3) sem sinalização ativa de foco contínuo/leitor de tela sobre o bloco da anfitriã.
  - **Sincronização de fala (`S06`)**: ao acionar `"Ouvir este trecho"` (`window.speechSynthesis`), eventos `onboundary` disparam pulsos de fala no `<memora-personagem>` associado; se o navegador/voz Android não emitir eventos `onboundary` entre `onstart` e `onend`, um oscilador leve temporal mantém ritmo calmo de fala enquanto `falando="true"`, sendo integralmente desativado sob `"Reduzir movimento"`.
- **Rationale**:
  - Evita que a Memora pareça quebrada em Android Chrome / WebViews onde vozes locais frequentemente omitem `SpeechSynthesisUtterance.onboundary`.
  - Cumpre rigorosamente `WCAG 2.2.2` (Pause, Stop, Hide) e as regras da `US8` da spec `013`.
- **Alternatives considered**:
  - Animar apenas via `onboundary`: falharia silenciosamente em diversos aparelhos Android.

### 4. Painel de Conforto com "Reduzir movimento" e CSS Moderno Progressivo (`S08`–`S10`, `FR-010`, `FR-016`)

- **Decision**:
  - Adicionar controle explícito **"Reduzir movimento"** persistido em `memora.tutorial.reduzir_movimento` (com fallback em memória). Na ausência de escolha prévia salva, o controle inicializa ligado se `window.matchMedia('(prefers-reduced-motion: reduce)').matches` for `true`; qualquer clique manual do visitante grava sua preferência e passa a prevalecer. O estado reflete em `<html data-movimento="normal|reduzido">`.
  - Aplicar recursos CSS modernos (`light-dark()`, `@container`, `text-wrap: pretty`, `@view-transition`, `animation-timeline: view()`) apenas dentro de blocos `@supports` preservando variáveis e layout clássicos como base, e mantendo `[data-tema="alto-contraste"]` (`>= 7,0:1`) definido por regras explícitas independentes de `light-dark()`.
- **Rationale**:
  - `light-dark()` só alterna dois polos (`color-scheme: light | dark`), portanto não substitui sozinho o terceiro modo obrigatório (`alto-contraste`).
  - Manter fallback clássico garante legibilidade e operação em aparelhos antigos dos usuários.

### 5. Portão `memora-ux` no Texto do Site e CI com Playwright/axe-core (`S11`, `S12`, `FR-002`, `SC-001`)

- **Decision**:
  - Reescrever título da página e blocos visíveis para obedecer estritamente à `memora-ux` (`<= 2` frases curtas por bloco, zero emojis na UI, remoção total de termos proibidos como `"idoso"`, `"pessoas idosas"`, `"terceira idade"`, `"melhor idade"`, `"sênior"`).
  - Estender `site/tests/validar_site.py` com varredura lexical de frases/termos proibidos/emojis (seguindo a mesma lógica de terminadores e abreviações do `app/test/design_system/texto_da_interface_test.dart`), verificação de remoção das 7 imagens antigas e checagem do orçamento JS (`<= 100 KB`).
  - Criar job `site` em `.github/workflows/verificacao.yml` executando `validar_site.py`, `node --test site/tests/tutorial.test.mjs`, e testes Playwright + `@axe-core/playwright` (instalados apenas em contexto de dev/CI, fora dos arquivos publicados de `site/`).
- **Rationale**: Mantém o portão do site com o mesmo rigor já adotado no aplicativo (`app/`) e evita que regressões de texto, contraste ou overflow em `320 px` a `200%` voltem a passar despercebidas.

### 6. Acompanhante Global Flutuante fora dos Capítulos (`Session 2026-11-17`, `FR-003`, `FR-013`, `FR-015`)

- **Decision**:
  - Mover a anfitriã (`[data-anfitria-bloco]`) de dentro de `#boas-vindas` para um marco `<aside class="anfitria-flutuante" aria-label="Dicas da Memora">` fora das seções, fixado no canto inferior esquerdo (oposto ao `.atalho-topo-fixo`).
  - Manter `#boas-vindas` com abertura limpa focada nos parágrafos e no lema, preservando o selo `mini` no `<header>` e as ilustrações decorativas `<memora-personagem>` nos cartões dos capítulos 6, 8 e 9.
  - Em desktop largo (`>= 64rem` fora de `data-escala="muito-grande"`), flutua fixa na faixa esquerda dedicada (iniciando expandida com botão `Recolher dicas` / `Ver dicas` >= `48×48 px`), mantendo distância segura do conteúdo; em telas compactas (`< 64rem`: `320 px`, `390 px`, `768 px`) ou escala `200%`, opera no fluxo normal da página (`position: static` logo abaixo do cabeçalho) com `.atalho-topo-fixo` oculto — evitando que qualquer botão fixo cubra links do sumário, passos ou FAQs (validado via `document.elementFromPoint`).
  - A anfitriã global passa a ser a falante única de `"Ouvir este trecho"` em todos os 9 capítulos (inclusive animando a boca dentro da cápsula compacta quando recolhida) e altera dinamicamente seu atributo `expressao` conforme o capítulo ativo na rolagem ou leitura (`boas-vindas` → `acenando`, `conversa-e-historico` → `pensando`, `aplicativos-e-servicos`/`pulseira-cuidado` → `dica`, `protecao-golpes` → `preocupada`, `duvidas-frequentes` → `comemorando`, demais → `neutra`).
- **Rationale**:
  - Permite acompanhar visualmente a Memora falando em voz alta em qualquer capítulo no desktop sem perder acesso ao botão `"Outra dica da Memora"` e garante zero cobertura de botões ou texto em `320×568` e `390×844` mesmo durante zoom `200%`.
  - Ao atualizar `expressao` somente quando muda de capítulo (`novo !== atual`), evita reconstruir o Shadow DOM durante pulsos de boca de fala.
- **Alternatives considered**:
  - Manter a anfitriã estática no Capítulo 1: deixava a personagem fora da tela durante a maioria das ativações de `"Ouvir este trecho"`.
  - Manter cápsula `position: fixed` também no celular (`320 px` / `390 px`): mesmo compacta com `48 px`, cobria links do sumário e perguntas da página durante a rolagem.
