---
description: "Task list for Feature 015 - Atalhos Rápidos para Aplicativos"
---

# Tasks: Feature 015 — Atalhos Rápidos para Aplicativos

**Input**: Design documents from `specs/015-atalhos-aplicativos/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)  
**Feature Branch**: `feature/015-atalhos-aplicativos`

**Tests**: Testes de widget e de unidade inclusos conforme diretriz do projeto para garantir conformidade com a Constituição e integridade de regressão.

**Organization**: Tarefas organizadas por fases e por User Story (US1, US2, US3) para implementação e validação independente.

---

## Phase 1: Setup (Infraestrutura Compartilhada)

**Purpose**: Criação da estrutura de pastas da feature e preparação dos mocks de teste.

- [X] T001 [P] Criar a estrutura de diretórios da feature em `app/lib/features/atalhos_aplicativos/` (subdiretórios `data/`, `domain/`, `presentation/`)
- [X] T002 [P] Criar a estrutura de diretórios para os testes em `app/test/features/atalhos_aplicativos/`

---

## Phase 2: Foundational (Pré-requisitos Bloqueantes)

**Purpose**: Entidades fundamentais, enumerações e catálogo imutável que todas as histórias utilizam.

- [X] T003 [P] Criar o enum `CategoriaAplicativo` em `app/lib/features/atalhos_aplicativos/domain/entidades/categoria_aplicativo.dart` com os valores `comunicacao`, `video`, `redesSociais` e `fotos`
- [X] T004 [P] Criar a entidade imutável `AtalhoAplicativo` em `app/lib/features/atalhos_aplicativos/domain/entidades/atalho_aplicativo.dart` com campos `chave`, `nomeExibido`, `pacoteAndroid`, `descricaoCurta`, `categoria`, `instalado` e `iconeBytes`
- [X] T005 [P] Criar o catálogo imutável dos 7 aplicativos comuns em `app/lib/features/atalhos_aplicativos/data/catalogo_aplicativos_comuns.dart` contendo WhatsApp, YouTube, Instagram, Facebook, Google Fotos, Telegram e TikTok
- [X] T006 [P] Criar a interface abstrata `IRepositorioAtalhos` em `app/lib/features/atalhos_aplicativos/domain/repositorios/i_repositorio_atalhos.dart` definindo `Future<List<AtalhoAplicativo>> obterAtalhos()`
- [X] T007 Implementar `RepositorioAtalhosAplicativos` em `app/lib/features/atalhos_aplicativos/data/repositorio_atalhos_aplicativos.dart` integrando com `ConsultaDeAplicativos` para checar `estaInstalado` e carregar `iconeDe`

**Checkpoint**: Fundação pronta — modelos e repositório testáveis de forma independente.

---

## Phase 3: User Story 1 — Visualizar Aplicativos Comuns e seus Status (Priority: P1) 🎯 MVP

**Goal**: Permitir que a pessoa idosa visualize todos os 7 aplicativos comuns em uma lista clara com cartões grandes, ícones legíveis e indicação de status (instalado ou disponível para baixar).

**Independent Test**: Montar a tela com `ConsultaDeAplicativosSimulada` contendo apenas WhatsApp e YouTube; verificar que os 7 cartões são exibidos e que os dois primeiros exibem status instalado enquanto os demais indicam não instalado.

### Tests for User Story 1
- [X] T008 [P] [US1] Criar teste unitário para o catálogo e repositório em `app/test/features/atalhos_aplicativos/repositorio_atalhos_test.dart`
- [X] T009 [P] [US1] Criar teste de widget para exibição da lista e cartões em `app/test/features/atalhos_aplicativos/tela_atalhos_exibicao_test.dart`

### Implementation for User Story 1
- [X] T010 [P] [US1] Criar a classe de estado `EstadoTelaAtalhos` em `app/lib/features/atalhos_aplicativos/presentation/controllers/estado_tela_atalhos.dart` com `carregando`, `aplicativos` e `mensagemAviso`
- [X] T011 [US1] Criar o controller `AtalhosAplicativosController` (ValueNotifier) em `app/lib/features/atalhos_aplicativos/presentation/controllers/atalhos_aplicativos_controller.dart` carregando dados do repositório
- [X] T012 [P] [US1] Criar o widget `CartaoAtalhoAplicativo` em `app/lib/features/atalhos_aplicativos/presentation/widgets/cartao_atalho_aplicativo.dart` utilizando `LinhaDeLista` e `BadgeDeStatus` do Design System, alvo amplo de toque, fonte Atkinson Hyperlegible Next e semântica completa
- [X] T013 [US1] Criar a tela principal `TelaAtalhosAplicativos` em `app/lib/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart` com barra superior de título *"Abrir aplicativos"*, estado de carregamento e lista de cartões

**Checkpoint**: User Story 1 completa e testável como MVP (visualização da lista com status).

---

## Phase 4: User Story 2 — Abrir Aplicativo Instalado com Confirmação Segura (Priority: P1)

**Goal**: Permitir que a pessoa idosa toque em um aplicativo instalado, visualize uma mensagem explicativa de confirmação e, ao confirmar, abra o aplicativo externo sem tutoriais.

**Independent Test**: Tocar no cartão do WhatsApp instalado; conferir exibição do diálogo *"Abrir o WhatsApp?"*; tocar em cancelar e verificar que não abriu; tocar em confirmar e verificar que `AbridorDeAplicativo` foi acionado com `'com.whatsapp'`.

### Tests for User Story 2
- [X] T014 [P] [US2] Criar teste de widget do fluxo de confirmação e abertura em `app/test/features/atalhos_aplicativos/dialogo_confirmacao_abertura_test.dart`

### Implementation for User Story 2
- [X] T015 [P] [US2] Criar o widget modal `DialogoConfirmacaoAbertura` em `app/lib/features/atalhos_aplicativos/presentation/widgets/dialogo_confirmacao_abertura.dart` com título claro, explicação pedagógica de como voltar e botões *"Sim, abrir agora"* e *"Não, continuar no Memora"*
- [X] T016 [US2] Integrar o toque no `CartaoAtalhoAplicativo` instalado com a exibição do `DialogoConfirmacaoAbertura` e disparo do `AbridorDeAplicativo` em `app/lib/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart`
- [X] T017 [US2] Adicionar tratamento de erro com `SnackBar` acessível caso o Android falhe ao abrir o aplicativo externo em `app/lib/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart`

**Checkpoint**: User Stories 1 e 2 funcionais — lista e abertura direta com confirmação protetiva.

---

## Phase 5: User Story 3 — Instalar Aplicativo Não Instalado via Google Play Store (Priority: P2)

**Goal**: Orientar a pessoa idosa com segurança quando ela toca em um aplicativo que ainda não está no celular, oferecendo diálogo de ida para a página oficial da Google Play Store.

**Independent Test**: Tocar em um aplicativo não instalado (ex.: Instagram); verificar aparição do diálogo *"Instalar o Instagram?"*; ao confirmar, validar que o intent ou URL da Play Store oficial (`market://details?id=com.instagram.android`) é invocado.

### Tests for User Story 3
- [X] T018 [P] [US3] Criar teste de widget para o diálogo de instalação na Play Store em `app/test/features/atalhos_aplicativos/dialogo_instalacao_test.dart`

### Implementation for User Story 3
- [X] T019 [P] [US3] Criar o widget modal `DialogoInstalacaoPlayStore` em `app/lib/features/atalhos_aplicativos/presentation/widgets/dialogo_instalacao_play_store.dart` com botões *"Ir para a Play Store"* e *"Agora não"*
- [X] T020 [US3] Integrar o toque em aplicativo não instalado para abrir o `DialogoInstalacaoPlayStore` e acionar `url_launcher` com URL oficial da loja em `app/lib/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart`

**Checkpoint**: Todas as user stories completas e integradas.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Acessibilidade, rotas e integração com as demais áreas do Memora.

- [X] T021 [P] Adicionar ponto de entrada e atalho para a tela *"Abrir aplicativos"* no Início (`app/lib/features/inicio/presentation/tela_inicio.dart` e `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`)
- [X] T022 [P] Validar rótulos semânticos (`Semantics`) para leitores de tela TalkBack em todos os cartões e diálogos em `app/lib/features/atalhos_aplicativos/presentation/widgets/cartao_atalho_aplicativo.dart`
- [X] T023 Validar ampliação de texto até 200% sem estouro de layout (overflow) na tela e nos modais (`app/test/acessibilidade/atalhos_aplicativos_acessibilidade_test.dart`)
- [X] T024 Executar toda a suíte de testes de validação conforme `quickstart.md` (`flutter test test/features/atalhos_aplicativos/`)

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 (Setup)**: Sem dependências — execução imediata.
- **Phase 2 (Foundational)**: Depende da Phase 1 — BLOQUEIA as histórias de usuário.
- **Phase 3 (User Story 1 - MVP)**: Depende da Phase 2.
- **Phase 4 (User Story 2)**: Depende da Phase 3 (US1).
- **Phase 5 (User Story 3)**: Depende da Phase 3 (US1).
- **Phase 6 (Polish)**: Depende da conclusão das User Stories.

### Parallel Opportunities
- Tarefas marcadas com **[P]** podem ser executadas em paralelo por trabalharem em arquivos isolados.
- Testes unitários e de widget dentro de cada história podem ser criados antes ou em paralelo aos componentes.

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)
1. Concluir Setup e Fundação (T001 a T007);
2. Concluir US1 (T008 a T013) — Tela com lista e status dos apps;
3. Concluir US2 (T014 a T017) — Abertura com diálogo de confirmação (essência do pedido do usuário);
4. Concluir US3 (T018 a T020) — Encaminhamento para a Play Store;
5. Polish e acessibilidade (T021 a T024).
