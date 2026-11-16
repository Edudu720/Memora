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

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sem dependências — inicia imediatamente.
- **Phase 2 (Foundational)**: Depende da Phase 1 (tokens, assets e pastas). Bloqueia `US1`–`US5`.
- **Phase 3 (`US1` - MVP)**: Depende da Phase 2. Pode ser validada de forma autônoma ao final.
- **Phase 4 (`US2` - Tutoriais)**: Depende da Phase 2 e encaixa no esqueleto e estilos criados em `US1` (ou pode evoluir capítulos em sequência após `T007`).
- **Phase 5 (`US3` - Conforto e Voz)**: Depende de `T005`, `T007` e capítulos presentes para testar alternância de voz em múltiplos capítulos.
- **Phase 6 (`US4` e `US5` - Segurança, FAQ e Familiares)**: Depende de `T007` e `T004`.
- **Phase 7 (Polish)**: Depende de todas as fases anteriores concluídas.

### Parallel Opportunities

- Em **Phase 1**: `T002` e `T003` em paralelo após `T001`.
- Em **Phase 2**: `T005`, `T006`, `T007` e `T008` podem avançar em paralelo após ou junto de `T004`.
- Em **Phase 4 (`US2`)**: `T012` (CSS de mini-telas) pode ocorrer em paralelo com redação inicial de `T013`; os capítulos dentro de `site/index.html` (`T013`–`T017`) seguem edição ordenada no mesmo arquivo para evitar conflitos.
- Em **Phase 7**: `T024`, `T025` e `T027` executam em paralelo antes da inspeção visual final (`T026`).

---

## Parallel Example: Foundational Phase (Phase 2)

```bash
# Após T001–T003 concluídos, disparar em paralelo os módulos independentes:
Task: "Criar folha de estilos base em site/styles/main.css" (T004)
Task: "Implementar lógica pura cliente em site/scripts/tutorial.js" (T005)
Task: "Criar suíte unitária em site/tests/tutorial.test.mjs" (T006)
Task: "Criar validador estrutural e WCAG em site/tests/validar_site.py" (T008)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Concluir Phase 1 (`T001`–`T003`) + Phase 2 (`T004`–`T008`).
2. Concluir Phase 3 (`T009`–`T011` — Abertura + Sumário + Retorno ao topo).
3. **STOP and VALIDATE**: Confirmar design acolhedor e responsividade em `320px` e `1280px`.

### Incremental Delivery

1. Setup + Foundational → base responsiva, tokens e validadores operacionais.
2. `+ US1` → página inicial acolhedora e navegação previsível (MVP).
3. `+ US2` → 6 capítulos passo a passo com ilustrações e mini-telas adaptáveis.
4. `+ US3` → controles interativos de tamanho de letra (`200%`), temas e voz local `pt-BR`.
5. `+ US4 / US5` → proteção contra golpes, dúvidas frequentes e orientação para familiares.
6. `Polish` → execução de `validar_site.py`, `node --test`, portões do repo e inspeção visual multidevice.
