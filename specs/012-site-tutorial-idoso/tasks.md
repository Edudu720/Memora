# Tasks: Site Tutorial Acolhedor do Memora para Pessoas Idosas (`012-site-tutorial-idoso`)

**Input**: Design documents from `specs/012-site-tutorial-idoso/`  
**Prerequisites**: `plan.md` (obrigatório), `spec.md` (obrigatório), `research.md`, `data-model.md`, `contracts/estrutura-e-acessibilidade.md`, `quickstart.md`  
**Tests**: Incluídos explicitamente conforme `plan.md` e `quickstart.md` (`site/tests/validar_site.py` e `site/tests/tutorial.test.mjs`).

**Organization**: Tarefas organizadas por fase e User Story (`US1`–`US5`) para permitir entrega incremental e validação independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos distintos, sem dependência de tarefa incompleta).
- **[Story]**: User Story atendida (`[US1]`–`[US5]`). Fases Setup, Foundational e Polish não recebem `[Story]`.

---

## Phase 1: Setup (Infraestrutura Compartilhada)

**Purpose**: Inicializar a estrutura isolada do site estático em `site/` e portar os ativos oficiais necessários sem alterar `app/` nem `backend/`.

- [X] T001 Criar a estrutura de diretórios `site/styles/`, `site/scripts/`, `site/assets/ilustracoes/` e `site/tests/` conforme `plan.md`
- [X] T002 [P] Copiar as 15 ilustrações próprias selecionadas de `app/assets/ilustracoes/` (`ajuste_aparencia.svg`, `casal_idoso.svg`, `memora_ajuda_robo.png`, `memora_alerta_robo.png`, `memora_comemorando.svg`, `memora_dica_robo.png`, `memora_falando.svg`, `memora_neutra.svg`, `memora_perfil_robo.png`, `pessoa_com_celular.svg`, `porta_ajuda.svg`, `porta_aplicativos.svg`, `porta_conversa.svg`, `porta_registro.svg`, `porta_servicos.svg`) para `site/assets/ilustracoes/` e registrar um resumo de origem/licença em `site/assets/ilustracoes/LICENCAS.md` referenciando `app/assets/ilustracoes/LICENCAS.md` (regra R4)
- [X] T003 [P] Criar os tokens CSS semânticos em `site/styles/tokens.css` espelhando exatamente `MemoraCores` (`claro`, `escuro`, `alto-contraste` em `data-tema="claro|escuro|alto-contraste"`), escalas de fonte (`data-escala="padrao|grande|muito-grande"` equivalendo a `1.125rem` / `1.45rem` / `2.0rem` sobre `16px`), raios suaves e espaçamentos mínimos (`>= 8px` entre alvos e altura mínima de toque `48px`)

---

## Phase 2: Foundational (Pré-Requisitos Bloqueantes)

**Purpose**: Base de estilos responsivos, acessibilidade estrutural, lógica pura cliente e arcabouço de testes antes dos capítulos de conteúdo.

**⚠️ CRITICAL**: Nenhuma User Story de conteúdo começa antes da conclusão desta fase.

- [X] T004 Criar a folha de estilos base responsiva e acolhedora em `site/styles/main.css` cobrindo *mobile-first* de `320px` a `1280px+`, largura máxima de leitura (`68ch` para texto e `1120px` para grade), link de salto inicial (`:focus-visible`), marcos `<header>`, `<nav>`, `<main>`, `<footer>`, cartões amplos, medalhões sempre claros (`var(--medalhao)`), foco visível de alto contraste, alvos interativos `>= 48x48 px` com `>= 8px` de folga, botão acessível de retorno ao topo e `@media (prefers-reduced-motion: reduce)` sem rolagem horizontal
- [X] T005 [P] Implementar a lógica pura e testável de preferências locais (`tamanhoFonte` permitido `'padrao'|'grande'|'muito-grande'`, `modoVisual` permitido `'claro'|'escuro'|'alto-contraste'`, chaves `memora.tutorial.escala_fonte` e `memora.tutorial.modo_visual` com fallback silencioso em memória se `localStorage` falhar) e controle de voz local (`speechSynthesis` `pt-BR`, extraindo exclusivamente o conteúdo pedagógico marcado em `[data-leitura-conteudo]` sem ler rótulos de botões nem elementos decorativos, garantindo exclusividade de 1 capítulo por vez via `speechSynthesis.cancel()`, ocultação silenciosa com `hidden` quando indisponível e retorno automático a `'ocioso'`) em `site/scripts/tutorial.js`
- [X] T006 [P] Criar a suíte unitária em `site/tests/tutorial.test.mjs` (`node:test`) cobrindo troca de escala/tema, validação de valores inválidos revertendo para `'padrao'`/`'claro'`, fallback sem `localStorage`, exclusividade de fala e degradação sem `speechSynthesis`
- [X] T007 [P] Criar o esqueleto semântico inicial de `site/index.html` com `<html lang="pt-BR" data-tema="claro" data-escala="padrao">`, `<meta charset="UTF-8">`, link `"Ir direto para o conteúdo principal"`, `<header>` com barra de conforto visual e `<nav>` do sumário, `<main id="conteudo-principal" tabindex="-1">`, `<footer>` com garantia informativa e botão `"Voltar para o início da página"`
- [X] T008 [P] Criar o validador automatizado em `site/tests/validar_site.py` para checar: `<html lang="pt-BR">`, marcos semânticos (`<header>`, `<nav>`, `<main>`, `<footer>`) e link de salto `#conteudo-principal`, validade de todas as âncoras `#id`, existência de todas as imagens citadas, presença obrigatória de `alt`, ausência de `<form>` / `<input>` / `<textarea>` / `<select>`, ausência de botões ou links ativos dentro de `.mini-tela` (`Contract §3`), ausência de links externos `http(s)://`, ausência de dependências externas em HTML/CSS/JS, varredura de jargões técnicos proibidos no texto visível (`IoT`, `MQTT`, `backend`, `tokens`, `login`, `phishing`, `API`), hierarquia de títulos (`h1` único seguido por `h2`/`h3` sem saltos) e razão de contraste WCAG 2.2 (`>= 4.5:1` / `>= 3.0:1` em Claro/Escuro e `>= 7.0:1` em Alto Contraste) diretamente a partir de `site/styles/tokens.css`

**Checkpoint**: Fundação semântica, tokens, layout responsivo e testes de base prontos para receber as seções do tutorial.

---

## Phase 3: User Story 1 - Conhecer o Memora e Aprender sem Medo no Próprio Ritmo (Priority: P1) 🎯 MVP

**Goal**: Entregar a abertura acolhedora, apresentação do propósito do Memora com o lema central, sumário navegável no topo com destaque de capítulo ativo e retorno fácil ao topo.

**Independent Test**: Abrir `site/index.html` em `320px`, `390px` e `1280px`; validar que o capítulo `#boas-vindas` e o sumário funcionam em até 2 cliques sem rolagem horizontal, sem jargões técnicos e com design polido.

- [X] T009 [US1] Implementar a seção `#boas-vindas` em `site/index.html` com único `<h1>`, saudação acolhedora voltada à pessoa idosa, explicação simples do objetivo do Memora, destaque para o lema *"Eu mostro o caminho e você faz. E não faço nada sem te avisar antes."*, compromisso de não fazer nada escondido e ilustração `assets/ilustracoes/memora_falando.svg` dentro de medalhão acessível
- [X] T010 [US1] Preencher o sumário navegável `<nav>` em `site/index.html` com os 9 atalhos diretos (`#boas-vindas`, `#primeiros-passos`, `#navegacao-3-toques`, `#conversa-e-historico`, `#aplicativos-e-servicos`, `#ajustes-e-foto`, `#pulseira-cuidado`, `#protecao-golpes`, `#duvidas-frequentes`), legendas claras em português e integração em `site/scripts/tutorial.js` para destacar o capítulo ativo (`aria-current="true"`) sem quebrar âncoras nativas
- [X] T011 [P] [US1] Refinar em `site/styles/main.css` o layout da seção hero de `#boas-vindas`, pílulas do sumário (quebra limpa em `320px` e grade arejada no PC), espaçamento de `scroll-margin-top` para não cobrir títulos de capítulos e botão de retorno ao topo acessível (`>= 48x48 px`)

**Checkpoint**: MVP navegável pronto (US1 funcional e testável de forma independente).

---

## Phase 4: User Story 2 - Seguir o Tutorial Passo a Passo das Funções Reais do Memora (Priority: P1)

**Goal**: Construir os 6 capítulos práticos do tutorial passo a passo com ilustrações do acervo Memora e mini-telas estilizadas adaptáveis ao zoom e aos temas (marcadas claramente como exemplos ilustrativos sem simulação enganosa).

**Independent Test**: Percorrer os capítulos `#primeiros-passos`, `#navegacao-3-toques`, `#conversa-e-historico`, `#aplicativos-e-servicos`, `#ajustes-e-foto` e `#pulseira-cuidado`, validando passos numerados sem jargões, legendas em português em todo ícone e adaptação visual das mini-telas em Claro/Escuro/Alto Contraste e a `200%`.

- [X] T012 [P] [US2] Criar os estilos das mini-telas ilustrativas inertes (`role="img"`, selo explícito `"Exemplo de como aparece no aplicativo"`, barras inferiores simuladas, cartões de conversa e botões ilustrativos `"Estou bem"` / `"Preciso de ajuda"`) e listas de passos numerados acolhedores em `site/styles/main.css`
- [X] T013 [US2] Implementar o capítulo `#primeiros-passos` em `site/index.html` explicando em passos numerados a entrada com **Frase Secreta**, o apoio opcional de um familiar (**Modo Assistido** sem perder a autonomia da conta) e a saída em duas confirmações, com `assets/ilustracoes/pessoa_com_celular.svg` e mini-tela ilustrativa da Frase Secreta
- [X] T014 [US2] Implementar o capítulo `#navegacao-3-toques` em `site/index.html` mostrando a regra de até **3 toques** e explicando visualmente os três destinos da barra inferior (**Ajustes**, **Início**, **Meu perfil**) com mini-tela adaptativa
- [X] T015 [US2] Implementar os capítulos `#conversa-e-historico` e `#aplicativos-e-servicos` em `site/index.html` usando `assets/ilustracoes/porta_conversa.svg`, `porta_registro.svg`, `porta_aplicativos.svg` e `porta_servicos.svg`, ensinando a tirar dúvidas sem termos técnicos, conferir *"O que eu fiz por você"* e usar WhatsApp, Telefone, Fotos, Gov.br e Saúde com mini-tela do aviso amigável antes de sair do Memora
- [X] T016 [US2] Implementar o capítulo `#ajustes-e-foto` em `site/index.html` usando `assets/ilustracoes/ajuste_aparencia.svg` e `memora_perfil_robo.png`, ensinando a aumentar letras/ativar alto contraste em `Ajustes` e a escolher foto da galeria, câmera ou avatar da Memora em `Meu perfil` (explicando de forma simples que a foto fica guardada só no aparelho)
- [X] T017 [US2] Implementar o capítulo `#pulseira-cuidado` em `site/index.html` usando `assets/ilustracoes/casal_idoso.svg` e `memora_ajuda_robo.png`, explicando em linguagem cotidiana (sem siglas técnicas como "IoT" ou "MQTT") o acompanhamento de batimentos, a detecção de quedas e a checagem calma de **45 segundos** com os botões grandes **"Estou bem"** e **"Preciso de ajuda"**

**Checkpoint**: Todos os fluxos reais do usuário dentro do aplicativo explicados visualmente em português simples.

---

## Phase 5: User Story 3 - Ajustar o Conforto de Leitura e Voz Local Diretamente no Site (Priority: P2)

**Goal**: Conectar plenamente a barra interativa de conforto visual (tamanho de letra até `200%` + Claro/Escuro/Alto Contraste) e os controles opcionais **"Ouvir este trecho / Parar leitura"** em cada capítulo.

**Independent Test**: Alternar os 3 tamanhos de letra e os 3 temas visuais em desktop e mobile `320px`, testar navegação inteira por teclado (`Tab`/`Enter`/`Espaço`) e acionar os botões `"Ouvir este trecho"` confirmando troca de estado (`aria-pressed`), fala única por vez e ausência de erros quando `speechSynthesis` não existe.

- [X] T018 [US3] Ligar os controles visíveis da barra de conforto (`Letra normal`, `Letra grande`, `Letra muito grande`, `Fundo claro`, `Fundo escuro`, `Alto contraste`) em `site/index.html` e `site/scripts/tutorial.js` atualizando `data-escala`, `data-tema`, `aria-pressed` e gravação resiliente em `localStorage`
- [X] T019 [US3] Adicionar os controles opcionais `"Ouvir este trecho"` (com `hidden` inicial seguro e texto alternando para `"Parar leitura"` com `aria-pressed`) e demarcar com `data-leitura-conteudo` o texto pedagógico dos 9 capítulos em `site/index.html`, conectando a leitura sequencial/exclusiva `pt-BR` em `site/scripts/tutorial.js`
- [X] T020 [P] [US3] Validar e ajustar em `site/styles/main.css` o comportamento de todos os blocos, controles e mini-telas quando `data-escala="muito-grande"` (`>= 32px`) e em `data-tema="alto-contraste"`, garantindo `>= 48x48 px` nos botões de ouvir/ajustar, bordas bem definidas e zero estouro em `320px`

**Checkpoint**: Controles de leitura visual e sonora totalmente operacionais e acessíveis.

---

## Phase 6: User Story 4 & User Story 5 - Proteção contra Golpes, Dúvidas Frequentes e Apoio para Familiares (Priority: P2 & P3)

**Goal**: Entregar o quadro destacado anti-golpes (**"O que o Memora NUNCA faz"**), respostas tranquilizadoras às dúvidas frequentes (incluindo recusa de câmera e uso sem internet) e orientação objetiva para familiares/cuidadores sem tirar o protagonismo do idoso.

**Independent Test**: Inspecionar `#protecao-golpes` e `#duvidas-frequentes`, testar abertura por clique e teclado de todas as perguntas e validar ausência absoluta de formulários, coleta de dados ou linguagem culpabilizadora.

- [X] T021 [US4] Implementar o capítulo `#protecao-golpes` em `site/index.html` com `assets/ilustracoes/memora_alerta_robo.png` e `memora_dica_robo.png`, destacando em linguagem clara e não alarmista o que o Memora **NUNCA faz** (nunca pede senha bancária, código SMS, cartão ou CPF por mensagem/site e nunca transfere dinheiro) e passos simples ao receber ligações ou links suspeitos
- [X] T022 [US4] Implementar o capítulo `#duvidas-frequentes` em `site/index.html` com blocos nativos `<details>`/`<summary>` estilizados com alvo `>= 48px` e foco visível, respondendo em tom calmo às dúvidas sobre medo de apagar algo sem querer, funcionamento sem internet, recusa da câmera na foto de perfil, privacidade de fotos/conversas e como localizar o app no celular sem sair para links externos (`FR-012`)
- [X] T023 [US5] Adicionar ao final de `#duvidas-frequentes` (ou bloco dedicado claramente marcado `"Para familiares e cuidadores"`) e no `<footer>` de `site/index.html` orientação breve para quem apoia a configuração inicial respeitando a autonomia do idoso, mantendo `assets/ilustracoes/memora_comemorando.svg` em destaque de incentivo e zero jargões acadêmicos

**Checkpoint**: Conteúdo completo das 5 User Stories concluído com privacidade total e foco no usuário idoso.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verificação automatizada completa, inspeção visual responsiva em navegador real e garantia de zero regressão nos fluxos do aplicativo e backend.

- [X] T024 [P] Executar `python site/tests/validar_site.py` e corrigir qualquer alerta estrutural, de contraste WCAG 2.2, legenda `alt`, hierarquia de títulos, formulário indevido ou referência externa em `site/`
- [X] T025 [P] Executar `node --test site/tests/tutorial.test.mjs` garantindo 100% de aprovação na lógica cliente de preferências, fallbacks e voz local
- [X] T026 Inspecionar visualmente o site servido localmente (`python -m http.server 8080 --directory site`) e via arquivo direto (`file://`) em larguras `320×568`, `390×844`, `768×1024` e `1280×800` nos modos `Padrao`/`Muito grande (200%)` e `Claro`/`Escuro`/`Alto contraste`, validando `scrollWidth <= clientWidth`, ausência de sobreposições e navegação completa por teclado
- [X] T027 [P] Executar os portões já existentes do repositório (`python specs/002-design-system/ferramentas/validar_paleta.py` e `python specs/002-design-system/ferramentas/validar_tokens.py`) e validar `git status` confirmando zero modificação em `app/` e `backend/`

---

## Phase 8: Rodada 2 — Clarificação, Conforto de Movimento e Texto `memora-ux` (US1 & US3 — Independentes da 013)

**Purpose**: Entregar imediatamente na `redesign-final` os controles de movimento reduzido e o portão editorial da `memora-ux` sem depender do exportador da frente `013`.

**Independent Test**: Alternar **"Reduzir movimento"** no painel (`normal`/`reduzido`), checar precedência com `prefers-reduced-motion`, rodar `node --test site/tests/tutorial.test.mjs` e confirmar aprovação de `python site/tests/validar_site.py` no `<title>`, textos em <= 2 frases e teto de JS `<= 102.400 bytes`.

- [X] T028 Clarificar requisitos da Rodada 2 (`<memora-personagem>`, botão `"Reduzir movimento"`, bibliotecas locais vendored/teto 100 KB, sincronia `onboundary`+fallback, `memora-ux` e CSS progressivo `@supports`) em `specs/012-site-tutorial-idoso/spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md` e `contracts/estrutura-e-acessibilidade.md` [S01]
- [X] T029 [P] [US3] Adicionar testes unitários do controle `"Reduzir movimento"` (`reduzirMovimento` `'normal'|'reduzido'`, chave `memora.tutorial.reduzir_movimento`, fallback em memória sem `localStorage`, inicialização por `prefers-reduced-motion: reduce` quando ausente e prevalência manual em `<html data-movimento>`) em `site/tests/tutorial.test.mjs` [S10]
- [X] T030 [US3] Adicionar o botão `"Reduzir movimento"` (`aria-pressed`, área `>= 48x48 px`) ao painel de conforto em `site/index.html`, implementar persistência/precedência (`memora.tutorial.reduzir_movimento`, `<html data-movimento="normal|reduzido">`) em `site/scripts/tutorial.js` e aplicar supressão de transições/animações sob `[data-movimento="reduzido"]` em `site/styles/main.css` [S10]
- [X] T031 [P] [US1] Estender `site/tests/validar_site.py` com o portão textual `memora-ux` (bloco de texto visível em `<title>`, `<p>`, `<figcaption>`, `<li>`, `<summary>`, botões, avisos e balões com no máximo 2 frases curtas seguindo segmentação de `texto_da_interface_test.dart`, zero emojis e zero termos `idoso|idosa|idosos|idosas|terceira idade|melhor idade|sênior`) e verificação do orçamento JS (`site/scripts/` + `site/vendor/` + `site/assets/memora/memora-dados.js` <= `102.400 bytes`) [S11, S13]
- [X] T032 [US1] Atualizar o `<title>` (sem `"Pessoas Idosas"`, ex.: `"Guia do Memora — passo a passo, no seu ritmo"`) e reescrever todos os textos visíveis de `site/index.html` e mensagens em `site/scripts/tutorial.js` respeitando <= 2 frases curtas por bloco, zero emojis e zero termos proibidos pela `memora-ux` [S11]

**Checkpoint**: Lote inicial independente (`S01`, `S10`, `S11`) pronto para revisão de PR na `redesign-final`.

---

## Phase 9: Rodada 2 — CSS Moderno Progressivo & Ícones Vetoriais (US1, US2 & US3 — Independentes da 013)

**Purpose**: Modernizar a tipografia, contêineres, transições progressivas e ícones arredondados mantendo fallback completo e contraste `alto-contraste` >= `7,0:1`.

**Independent Test**: Validar `site/tests/validar_site.py`, inspecionar `Claro`, `Escuro` e `Alto contraste` (verificando preservação independente do alto contraste fora de `light-dark()`) e confirmar navegação entre capítulos com e sem `"Reduzir movimento"`.

- [X] T033 [P] [US3] Atualizar `site/styles/tokens.css` com melhoria progressiva `light-dark()` dentro de `@supports (color: light-dark(#000, #fff))` apenas para `claro`/`escuro`, mantendo os tokens clássicos de fallback e mantendo `[data-tema="alto-contraste"]` (`>= 7,0:1`) em regras explícitas independentes [S09]
- [X] T034 [P] [US1] Adicionar consultas de contêiner (`@container`), `text-wrap: pretty`, transição suave entre capítulos (`@view-transition` / `document.startViewTransition`) e revelação na rolagem (`animation-timeline: view()`) em `site/styles/main.css` e `site/scripts/tutorial.js` dentro de `@supports` e desligados sob `[data-movimento="reduzido"]` e `@media (prefers-reduced-motion: reduce)` [S08, S09]
- [X] T035 [P] [US2] Substituir os ícones das portas e das pessoas em `site/assets/ilustracoes/` (`porta_ajuda.svg`, `porta_aplicativos.svg`, `porta_conversa.svg`, `porta_registro.svg`, `porta_servicos.svg`, `casal_idoso.svg`, `pessoa_com_celular.svg`, `ajuste_aparencia.svg`) por vetores locais da família **Material Rounded** (consistente com `Icons.*_rounded` do app), adicionar feedback visível ao toque e foco em `site/styles/main.css` e atualizar `site/assets/ilustracoes/LICENCAS.md` [S07]

**Checkpoint**: Camada visual moderna (`S07`, `S08`, `S09`) validada com fallback clássico e sem regressão de acessibilidade.

---

## Phase 10: Rodada 2 — Memora 2.5D Exportada, Anfitriã e Sincronismo Vocal (US1 & US3 — Desbloqueada pela PR #87)

**Purpose**: Substituir as 7 imagens antigas da Memora pela personagem vetorial 2.5D única exportada do app, ativar a anfitriã com a lista fixa de dicas e sincronizar a boca com `"Ouvir este trecho"`.

**Independent Test**: Rodar `dart run tool/exportar_memora_site.dart` em `app/`, testar `<memora-personagem>`, anfitriã (`20.000 ms`, pausa no botão `"Outra dica da Memora"` e em movimento reduzido) e sincronia de fala em `site/tests/tutorial.test.mjs`, e validar via `file://` e `site/tests/validar_site.py` ausência dos 7 arquivos legados.

- [X] T036 [US1] Criar o exportador Dart puro em `app/tool/exportar_memora_site.dart` (rodando via `dart run` sem depender de `dart:ui`, lendo geometria e constantes diretamente dos fontes de `app/lib/`) para `PintorDaMemora`/`poses.dart` (`9` expressões de `PoseDaMemora`: `neutra|falando|pensando|comemorando|preocupada|acenando|dica|mini|carregando`, grupos `<g id="...">` nomeados `sombra`, `corpo`, `painel-peito`, `antena`, `cabeca`, `visor`, `rosto`, `olhos`, `boca`, `braco-esquerdo`, `braco-direito`, `escudo`, `livro`, `barra`), `CoresDaMemora` (`app/lib/design_system/tokens/cores_da_memora.dart`) e `TextosAnfitria.dicas` (`app/lib/l10n/textos_anfitria.dart`, `T086` já na branch) gerando `site/assets/memora/<expressao>.svg`, `site/assets/memora/memora.json` e o módulo JS local compatível com `file://` `site/assets/memora/memora-dados.js` (`T083` e `T086` integrados via PR #87) [S02]
- [X] T037 [P] [US1] Implementar o Web Component `<memora-personagem expressao="neutra|falando|pensando|comemorando|preocupada|acenando|dica|mini|carregando" falando="true|false">` com `aria-hidden="true"`, animações compositoras (`transform`, `opacity`) via Web Animations API (ou biblioteca enxuta copiada em `site/vendor/` dentro do teto `<= 102.400 bytes`), pausa fora da viewport via `IntersectionObserver` e parada em `[data-movimento="reduzido"]` em `site/scripts/memora-personagem.js`, adicionando testes em `site/tests/tutorial.test.mjs` [S03, S13]
- [X] T038 [US1] Trocar todas as referências às 7 imagens antigas da Memora em `site/index.html` por `<memora-personagem>`, remover `memora_ajuda_robo.png`, `memora_alerta_robo.png`, `memora_dica_robo.png`, `memora_perfil_robo.png`, `memora_comemorando.svg`, `memora_falando.svg` e `memora_neutra.svg` de `site/assets/ilustracoes/`, atualizar `site/assets/ilustracoes/LICENCAS.md` e validar remoção/zero órfãos em `site/tests/validar_site.py` [S04, T082 da 013]
- [X] T039 [US1] Implementar a anfitriã no topo de `site/index.html` e `site/scripts/tutorial.js` consumindo `dicasDaAnfitria` de `site/assets/memora/memora-dados.js` (com fallback textual se ausente), rotação automática de `20.000 ms` desativada sob leitor de tela/foco ou `[data-movimento="reduzido"]`, e botão **"Outra dica da Memora"** (`>= 48x48 px`) que interrompe definitivamente a troca automática na sessão (`WCAG 2.2.2`), com testes em `site/tests/tutorial.test.mjs` [S05]
- [X] T040 [US3] Sincronizar `"Ouvir este trecho"` em `site/scripts/tutorial.js` com `falando="true"` no `<memora-personagem>` do capítulo ativo entre `onstart` e `onend`/`onerror`, usando eventos `onboundary` com fallback temporal rítmico calmo quando `onboundary` não for emitido pela voz e mantendo boca estática sob `[data-movimento="reduzido"]`, com testes em `site/tests/tutorial.test.mjs` [S06]

**Checkpoint**: Site 100% unificado com a Memora 2.5D do aplicativo e sincronia vocal acessível.

---

## Phase 11: Rodada 2 — Qualidade no CI, Desempenho e Fechamento (Polish)

**Purpose**: Automatizar auditoria WCAG (`axe-core`), orçamento de desempenho e testes end-to-end no CI sem contaminar os artefatos estáticos do site.

- [X] T041 [P] Configurar Playwright + `@axe-core/playwright` apenas como ferramenta dev-only em `site/tests/e2e/package.json` e criar a suíte `site/tests/e2e/site.spec.mjs` validando 0 violações `axe-core`, 0 overflow em `320x568` a `200%`, interação da anfitriã/`"Reduzir movimento"`, compatibilidade `file://` e simulação `CPU 4x` dentro do orçamento de JS `<= 102.400 bytes` [S12, S13]
- [X] T042 Adicionar o job `site` em `.github/workflows/verificacao.yml` executando `python site/tests/validar_site.py`, `node --test site/tests/tutorial.test.mjs`, a suíte `site/tests/e2e/` e preservando os validadores `validar_paleta.py` e `validar_tokens.py` [S12]
- [X] T043 Executar validação final completa de `specs/012-site-tutorial-idoso/quickstart.md` (`validar_site.py`, `node --test`, `site/tests/e2e/`, conferência `file://` e HTTP estático de `320×568` a `1280×800`) confirmando orçamento JS total `<= 102.400 bytes` [S12, S13]
- [X] T044 [P] Marcar conclusões espelhadas em `specs/012-site-tutorial-idoso/tarefas-do-redesenho.md` e na tarefa `T082` de `specs/013-redesenho-final/tasks.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phases 1–7 (Rodada 1 `T001`–`T027`)**: Concluídas (`[X]`).
- **Phase 8 (`S01`, `S10`, `S11`)**: `T028` concluída (`[X]`); `T029`–`T032` sem bloqueio externo — podem começar imediatamente.
- **Phase 9 (`S07`, `S08`, `S09`)**: `T033`–`T035` sem bloqueio da `013`; `T034` aproveita o atributo `data-movimento` criado em `T030`.
- **Phase 10 (`S02`–`S06`, `T082`)**: `T036` depende da entrega de `T083` e `T086` (Henrique na `013`); `T037` pode iniciar em paralelo com estrutura mockada e conectar ao bundle real de `T036`; `T038`, `T039` e `T040` dependem de `T036` e `T037`.
- **Phase 11 (`S12`, `S13`)**: `T041` e `T042` podem correr em paralelo desde já sobre os critérios de acessibilidade/orçamento existentes, fechando com `T043` e `T044` ao final da Phase 10.
- **Phase 14 (`Session 2026-11-17` — Acompanhante Global)**: depende da conclusão da Phase 10 (`T036`–`T040`, já `[X]`); `T051` (`index.html`) e `T052` (`main.css`) preparam a base estrutural e visual fora dos capítulos, seguidas de `T053`–`T054` (`tutorial.js`) e encerrando com as verificações `T055`–`T056`.

### Parallel Opportunities

- **Phase 8**: `T029` e `T031` podem ser implementadas em paralelo (`site/tests/tutorial.test.mjs` e `site/tests/validar_site.py`); `T030` e `T032` editam `site/index.html` e `site/scripts/tutorial.js` em sequência limpa.
- **Phase 9**: `T033` (`tokens.css`), `T034` (`main.css`/`tutorial.js`) e `T035` (`assets/ilustracoes/`) podem rodar em paralelo.
- **Phase 10**: `T037` (`<memora-personagem>` em `site/scripts/memora-personagem.js`) pode avançar enquanto `T036` finaliza o exportador Dart; em seguida `T038`, `T039` e `T040` integram em `site/index.html` e `site/scripts/tutorial.js`.
- **Phase 11**: `T041` (`site/tests/e2e/`) e `T042` (`.github/workflows/verificacao.yml`) podem ser preparadas em paralelo.
- **Phase 14**: `T052` (`main.css`) pode correr em paralelo com `T051` (`index.html`), e `T055` (`validar_site.py` / `tutorial.test.mjs`) pode correr em paralelo com `T056` (`site.spec.mjs`).

---

## Parallel Example: Lote Inicial Independente (Phases 8 & 11)

```bash
# Após T028 (S01) concluída, disparar em paralelo o próximo lote:
Task: "Testes unitários de Reduzir movimento em site/tests/tutorial.test.mjs" (T029 - S10)
Task: "Portão textual memora-ux e orçamento JS em site/tests/validar_site.py" (T031 - S11/S13)
Task: "Suíte Playwright + axe-core dev-only em site/tests/e2e/site.spec.mjs" (T041 - S12)
```

---

## Implementation Strategy

### Incremental Delivery na `redesign-final`

1. **Lote 1 (Imediato — Independente)**: `T029`–`T032` (`S10`, `S11`) + opcionalmente `T041`–`T042` (`S12`).
2. **Lote 2 (CSS & Ícones — Independente)**: `T033`–`T035` (`S07`, `S08`, `S09`).
3. **Lote 3 (Após `T083`/`T086` do Henrique)**: `T036` -> `T037` -> `T038`, `T039`, `T040` (`S02`–`S06`, `T082`).
4. **Lote 4 (Acompanhante Global `Session 2026-11-17`)**: `T051`, `T052` -> `T053`, `T054` -> `T055`, `T056`.
5. **Fechamento**: `T043`–`T044` validando quickstart, orçamento `<= 102.400 bytes`, Playwright/`axe-core` e abrindo PR final para `redesign-final`.


---

## Phase 12: Convergence

> Achados incrementais identificados sobre os trechos já implementados (`T029`–`T035`, `T041`–`T042`); os itens pendentes das tarefas ainda abertas (`T036`–`T040`, `T043`–`T044` — `FR-003`, `FR-013`, `FR-015`, `S02`–`S06`, `T082`) permanecem rastreados na **Phase 10** e **Phase 11** aguardando `T083`/`T086` da feature `013`.

- [X] T045 Estender `site/tests/validar_site.py` para validar também `.grupo-legenda` / `.duvida-indicador`, literais de texto voltados ao leitor em `site/scripts/tutorial.js` e `dicasDaAnfitria` em `site/assets/memora/memora-dados.js` (quando presente) contra as regras da `memora-ux` (`<= 2` frases, zero emoji, zero termos proibidos) per FR-002, SC-001, Contract §4 (partial)
- [X] T046 Ampliar `site/tests/e2e/site.spec.mjs` para cobrir as larguras `390x844` e `768x1024`, navegação por teclado no link de salto (`Tab` -> `#conteudo-principal`) e abertura via `Enter`/`Espaço` nos `<details>` das Dúvidas Frequentes per SC-002, AC-005 (partial)
- [X] T047 Escopar `:root` em `site/styles/tokens.css` dentro de `@supports (color: light-dark(#000, #fff))` para `:root:not([data-tema]), :root[data-tema="claro"], :root[data-tema="escuro"]` (evitando casar quando `data-tema="alto-contraste"` sem depender de especificidade) per FR-016, Contract §2 (partial)


---

## Phase 13: Convergence

> Novos achados identificados sobre o código e testes já implementados (`T001`–`T035`, `T041`–`T042`, `T045`–`T047`); os itens aguardando `T083`/`T086` da feature `013` (`T036`–`T040`, `T043`–`T044` — `FR-003`, `FR-013`, `FR-015`, `S02`–`S06`, `T082`) permanecem rastreados na **Phase 10** e **Phase 11**.

- [X] T048 CRITICAL: Preservar `background-color: var(--primaria)` e `color: var(--sobre-primaria)` no estado `:focus-visible` dos controles ativos (`.botao-controle[aria-pressed="true"]`, `.botao-ouvir[aria-pressed="true"]` e `.link-sumario[aria-current="true"]`) em `site/styles/main.css` evitando sobrescrita de contraste pela regra genérica `:focus-visible` (`var(--destaque)`) per Constitution III, AC-001, SC-003 (partial)
- [X] T049 Ampliar `site/tests/e2e/site.spec.mjs` para verificar contraste WCAG `axe-core` com `:focus-visible` em controle ativo (`[aria-pressed="true"]`/`[aria-current="true"]`), dimensões de `.atalho-topo-fixo .botao-topo` (`>= 48x48 px`) e espaçamento mínimo `>= 8 px` entre controles adjacentes per AC-002, SC-003, SC-004 (partial)
- [X] T050 Estender `validar_memora_ux_e_orcamento` em `site/tests/validar_site.py` para varrer `tem_emoji` e `palavras_proibidas_em` também em `inspetor.textos_visiveis` (cobrindo textos fora de `BLOCOS_TAG`/`CLASSES_BLOCO`, como badges `.marca-texto` e cabeçalhos `<div>`) per FR-002, SC-001 (partial)

---

## Phase 14: Rodada 2 — Acompanhante Global Flutuante fora dos Capítulos (US1 & US3 — Session 2026-11-17)

**Purpose**: Mover a Memora anfitriã de dentro do Capítulo 1 (`#boas-vindas`) para uma acompanhante global flutuante fora dos capítulos (canto inferior esquerdo, oposto a `↑ Topo`), iniciando expandida em desktop e recolhida em cápsula compacta com personagem visível em telas `< 64rem` ou `200%`, sincronizando expressão e fala (`"Ouvir este trecho"`) em todos os 9 capítulos.

**Independent Test**: Verificar em desktop (`1280×800`) e mobile (`320×568` e `data-escala="muito-grande"`) que `<aside class="anfitria-flutuante">` acompanha o scroll fora das `<section>`, inicia recolhida em cápsula compacta em telas estreitas/`200%` sem sobrepor texto nem `↑ Topo` (`>= 8 px` de folga), alterna `aria-expanded` pelo botão `[data-acao-alternar-anfitria]` (`>= 48×48 px`), adapta `expressao` ao capítulo ativo e anima a boca em `"Ouvir este trecho"` em qualquer capítulo.

- [X] T051 [US1] Mover o bloco da anfitriã de dentro de `#boas-vindas` para `<aside class="anfitria-flutuante" data-anfitria-bloco data-anfitria-estado="expandida" aria-label="Dicas da Memora">` fora de `<main>` em `site/index.html`, deixando `#boas-vindas` com abertura limpa sem painel lateral duplicado, mantendo o selo `mini` no cabeçalho e os `<memora-personagem>` decorativos nos cartões dos capítulos 6, 8 e 9, e adicionando o botão acessível de recolher/expandir (`[data-acao-alternar-anfitria]`, rótulos `"Recolher dicas"` / `"Ver dicas"`, `aria-expanded="true|false"`, `aria-controls="anfitria-conteudo"`, área `>= 48x48 px`)
- [X] T052 [P] [US1] Estilizar `.anfitria-flutuante` em `site/styles/main.css` ancorada no canto inferior esquerdo (lado oposto ao `.atalho-topo-fixo` no canto inferior direito, com folga `>= 8 px`), iniciando expandida em telas `>= 64rem` fora de `data-escala="muito-grande"` e recolhida em cápsula compacta com `<memora-personagem data-memora-anfitria>` visível em telas `< 64rem` ou `data-escala="muito-grande"` (`200%`), sem gerar `scrollWidth > clientWidth` nem encobrir o rodapé
- [X] T053 [US1] Estender `criarControladorDaAnfitria` e `inicializarPagina` em `site/scripts/tutorial.js` com os campos `expandida` (`boolean`: `true` em `>= 64rem` e `tamanhoFonte !== 'muito-grande'`, `false` em `< 64rem` ou `'muito-grande'`) e `expressaoAtual` (`acenando | neutra | pensando | dica | preocupada | comemorando`), pausando `rotacaoAutomaticaAtiva` quando `expandida === false`, conectando o botão `[data-acao-alternar-anfitria]` (`"Recolher dicas"` quando expandida e `"Ver dicas"` quando recolhida) e atualizando a expressão do `<memora-personagem data-memora-anfitria>` conforme o capítulo ativo na rolagem (somente quando o valor de `expressao` mudar)
- [X] T054 [US3] Atualizar a sincronização de `"Ouvir este trecho"` em `site/scripts/tutorial.js` para que o `<memora-personagem data-memora-anfitria>` acompanhante global seja a falante principal em todos os 9 capítulos (inclusive visível na cápsula recolhida), assumindo `falando="true"` e a expressão do capítulo lido entre `onstart` e `onend`/`onerror` e restaurando a expressão do capítulo visível na rolagem ao concluir
- [X] T055 [P] [US1] Atualizar `site/tests/validar_site.py` e `site/tests/tutorial.test.mjs` para validar a presença de `<aside class="anfitria-flutuante">` e `[data-acao-alternar-anfitria]` em `site/index.html`, a pausa da rotação automática quando recolhida (`expandida: false`), a troca dinâmica de expressão por capítulo e a sincronia vocal na acompanhante global
- [X] T056 [P] [US3] Atualizar `site/tests/e2e/site.spec.mjs` para verificar que `.anfitria-flutuante` inicia expandida em desktop (`1280x800`) e recolhida em cápsula compacta em `320x568` ou `data-escala="muito-grande"` sem colidir com `.atalho-topo-fixo` (`>= 8 px` de folga) nem gerar overflow horizontal, que `[data-acao-alternar-anfitria]` possui área `>= 48x48 px` e alterna `aria-expanded`, e que zero violações `axe-core` ocorrem nos 3 temas
