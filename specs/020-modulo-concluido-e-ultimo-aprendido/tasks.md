# Tasks: Módulo Concluído, Checkbox de Seção e Último Módulo Concluído

**Input**: Design documents from `/specs/020-modulo-concluido-e-ultimo-aprendido/`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/progresso-e-modulos.md`, `quickstart.md`

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode ser executada em paralelo (arquivos independentes)
- **[Story]**: `US1` (catálogo concluído), `US2` (checkbox verde por seção), `US3` (último módulo concluído no perfil)

---

## Phase 1: Setup & Verificação Prévia

- [X] T001 Confirmar `.specify/feature.json` apontando para `specs/020-modulo-concluido-e-ultimo-aprendido` e revisar contratos existentes de `ProgressoDeAprendizado`, `TelaCatalogo`, `TelaSeletorDeSecao` e `TelaPerfil`

---

## Phase 2: Foundational (Domínio, Persistência Local e Copy em `l10n`)

**Purpose**: Infraestrutura compartilhada pelas 3 User Stories (zero dependências entre US1, US2 e US3 após esta fase).

- [X] T002 Estender `app/lib/features/aprendizado/data/progresso_de_aprendizado.dart` com `Stream<void> get alteracoes` (broadcast emitida após gravação em `registrarConclusao` e deleção em `apagar`), `ordensDeConclusao(String idDaConta)` e `ultimoConcluido(String idDaConta)` sem alterar `FR-042a/b`
- [X] T003 [P] Criar `app/lib/features/aprendizado/domain/estado_do_modulo.dart` com funções puras `moduloConcluido(Guia guia, Map<String, int> concluidos)` e `chaveDoUltimoModuloConcluido(Map<String, int> ordens, Iterable<Guia> guias)` (exigindo todas as seções em guias seccionados)
- [X] T004 [P] Adicionar constantes e helpers em `app/lib/l10n/textos_guias.dart` (`moduloConcluido`, `secaoConcluidaDescrita`) e `app/lib/l10n/textos_perfil.dart` (`rotuloUltimoAprendido`, `ultimoAprendidoVazio`) aderentes a `texto_da_interface_test.dart` e `sem_planos_test.dart`
- [X] T005 Ampliar `app/test/features/aprendizado/progresso_de_aprendizado_test.dart` cobrindo `alteracoes` (em gravação e `apagar`), `ordensDeConclusao`, `ultimoConcluido`, `moduloConcluido` (parcial vs total vs direto) e `chaveDoUltimoModuloConcluido`

**Checkpoint**: Domínio e dados validados de forma independente antes das telas.

---

## Phase 3: User Story 1 — Módulo marcado como concluído na lista do Catálogo (Priority: P1) 🎯 MVP

**Goal**: Exibir selo informativo `"Concluído"` nos módulos totalmente concluídos do catálogo e reagir ao vivo às mudanças de progresso.

**Independent Test**: `catalogo_modulo_concluido_test.dart` cobrindo guia direto, guia seccionado parcial/completo, atualização ao vivo via `alteracoes`, TalkBack `readOnly` e matriz `4 × 3` a 200%.

- [X] T006 [US1] Atualizar `app/lib/features/assistente/presentation/telas/tela_catalogo.dart` adicionando `progresso`, `idDaConta`, `chaveConcluidoDoItem`, carregamento/assinatura de `alteracoes` com descarte em `dispose` e renderização do `BadgeDeStatus` `"Concluído"` dentro de `Wrap` quando `moduloConcluido(guia, _concluidos)` for verdadeiro
- [X] T007 [P] [US1] Atualizar `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart` (`_abrirCatalogo`) para repassar `progresso: widget.progresso` e `idDaConta: _pessoa?.id` para `TelaCatalogo`
- [X] T008 [US1] Criar `app/test/features/assistente/catalogo_modulo_concluido_test.dart` validando selo `"Concluído"`, exclusão de módulos parcialmente concluídos, atualização ao vivo, semântica não-clicável, matriz `4 × 3` a 200% e integração via `FluxoAutenticacao`

**Checkpoint**: User Story 1 funcional e verificável de forma independente.

---

## Phase 4: User Story 2 — Checkbox verde arredondado ao lado de cada seção concluída (Priority: P1)

**Goal**: Renderizar checkbox verde arredondado com tokens do Design System ao lado das seções concluídas em `TelaSeletorDeSecao`, mantendo texto `Já aprendeu`, anúncio TalkBack `"Concluído."` e atualização ao vivo.

**Independent Test**: `tela_seletor_de_secao_test.dart` com verificação de chave `chaveCheckDaSecao`, tema/alto contraste, TalkBack `"Concluído."`, stream `alteracoes`/`apagar` e matriz `4 × 3`.

- [X] T009 [US2] Atualizar `app/lib/features/aprendizado/presentation/tela_seletor_de_secao.dart` com `chaveCheckDaSecao`, assinatura/limpeza de `alteracoes` em `_TelaSeletorDeSecaoState`, `rotuloDoLeitor` via `secaoConcluidaDescrita` quando concluída e widget `_CheckboxVerdeConcluido` em `LinhaDeLista(direita: ...)` usando apenas tokens
- [X] T010 [US2] Ampliar `app/test/features/aprendizado/tela_seletor_de_secao_test.dart` cobrindo presença exclusiva do checkbox verde arredondado nas seções concluídas, tema claro/escuro/alto contraste, anúncio `"Concluído."` no TalkBack, atualização ao vivo ao concluir nova seção, limpeza em `apagar()` e matriz `4 × 3` com seções concluídas

**Checkpoint**: User Stories 1 e 2 funcionais de forma independente.

---

## Phase 5: User Story 3 — Campo "Último módulo concluído" em Meu Perfil (Priority: P2)

**Goal**: Exibir campo puramente informativo `"Último módulo concluído"` em `TelaPerfil`, mantendo `chaveMaisAprendido`, privacidade local (`FR-042a/b`) e atualização ao vivo dentro da `CascaInterna`.

**Independent Test**: `tela_perfil_test.dart` cobrindo vazio acolhedor, distinção entre mais aprendido e último concluído, guia seccionado parcial vs completo, semântica não-clicável e atualização ao vivo.

- [X] T011 [US3] Atualizar `app/lib/features/perfil/presentation/tela_perfil.dart` com `chaveUltimoAprendido`, assinatura/cancelamento de `alteracoes`, leitura combinada com `chaveDoUltimoModuloConcluido(ordens, todosOsGuias)`, helper compartilhado de nome exibido e `CampoInformacao` puramente informativo
- [X] T012 [US3] Atualizar `app/test/features/perfil/tela_perfil_test.dart` (`_ProgressoEmMemoria` com `ordem` e `alteracoes`, ajuste da asserção em `WhatsApp` usando `find.descendant`, cobertura de `chaveUltimoAprendido` não-clicável, vazio acolhedor, mais aprendido ≠ último concluído, seção parcial vs completa e limpeza após `apagar()`)

**Checkpoint**: Todas as User Stories (US1, US2, US3) implementadas e testadas.

---

## Phase 6: Polish, Documentação & Portões Completos

- [X] T013 [P] Atualizar `CHANGELOG.md` na seção `[Unreleased]` documentando a feature `020-modulo-concluido-e-ultimo-aprendido`
- [X] T014 Executar portão de tokens (`py specs/002-design-system/ferramentas/validar_tokens.py`), `flutter analyze` e `flutter test` completo em `app/` após a última edição e rodar `/speckit-converge`

---

## Dependencies & Execution Order

- **Phase 1 (T001)** -> **Phase 2 (T002, T003 [P], T004 [P] -> T005)**
- Após **Phase 2**, as histórias **US1 (T006–T008)**, **US2 (T009–T010)** e **US3 (T011–T012)** podem avançar em paralelo ou em sequência sem conflito entre si.
- **Phase 6 (T013–T014)** executa estritamente após todas as edições estarem concluídas.
