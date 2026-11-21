---
description: "Lista de tarefas da funcionalidade 021 — Análise Antigolpes de Links e Mensagens Estranhas"
---

# Tasks: Análise Antigolpes de Links e Mensagens Estranhas

**Input**: Documentos de design em `/specs/021-analise-golpes/` (`spec.md`, `plan.md`)

**Prerequisites**: `plan.md` (obrigatório), `spec.md` (obrigatório para histórias de usuário)

**Tests**: Testes automatizados obrigatórios conforme critérios de aceite (cobertura de mensagens/links seguros e suspeitos nos modos online/IA e fallback local offline, segurança do endpoint e portões de UI/acessibilidade).

**Organization**: Tarefas agrupadas por fase e história de usuário para permitir implementação e validação independentes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos distintos, sem dependências bloqueantes)
- **[Story]**: História de usuário correspondente (`[US1]`, `[US2]`, `[US3]`)

---

## Phase 1: Setup & Artefatos SpecKit

**Purpose**: Estruturação da documentação SpecKit e organização dos pacotes da feature

- [X] T001 Criar especificação da funcionalidade com cenários de uso, requisitos funcionais e Threat Modeling em `specs/021-analise-golpes/spec.md`
- [X] T002 [P] Criar plano de implementação com arquitetura, contrato REST e Constitution Check em `specs/021-analise-golpes/plan.md`
- [X] T003 [P] Criar lista de tarefas rastreável por história de usuário em `specs/021-analise-golpes/tasks.md`

---

## Phase 2: Foundational (Domínio & Textos Base)

**Purpose**: Contratos de domínio e textos localizados compartilhados por todas as histórias de usuário

- [X] T004 [P] Criar textos localizados da interface antigolpe seguidos pelas regras `memora-ux` (`<= 2` frases, sem emojis, sem termos proibidos) em `app/lib/l10n/textos_antigolpe.dart` e registrar o arquivo em `app/test/design_system/texto_da_interface_test.dart`
- [X] T005 [P] Criar entidades de domínio `NivelRisco`, `OrigemAnalise` e `AnaliseGolpe` em `app/lib/features/antigolpe/domain/entidades/analise_golpe.dart`
- [X] T006 [P] Criar interface `RepositorioAnaliseGolpe` e exceções de domínio em `app/lib/features/antigolpe/domain/repositorios/repositorio_analise_golpe.dart`
- [X] T007 [P] Criar enum `NivelRiscoGolpe` e record `ResultadoAnaliseGolpe` no backend em `backend/src/main/java/br/fatec/memora/antigolpe/dominio/NivelRiscoGolpe.java` e `backend/src/main/java/br/fatec/memora/antigolpe/dominio/ResultadoAnaliseGolpe.java`

**Checkpoint**: Fundações de domínio e localização prontas no Flutter e no backend.

---

## Phase 3: User Story 1 - Tela Dedicada de Análise e Navegação Acessível (Priority: P1) 🎯 MVP

**Goal**: Permitir que a pessoa idosa acesse a tela "Verificar golpe" em até 3 toques a partir do Início, cole ou digite uma mensagem/link e receba orientação visual acessível sem links clicáveis.

**Independent Test**: Montar `TelaAnaliseGolpe` e `FluxoAutenticacao` em testes de widget (`tela_analise_golpe_test.dart` e `profundidade_test.dart`), validando colagem da área de transferência, estados da FR-006, ausência de links clicáveis, matriz 4×3×3 e navegação em 1 toque pelo Início e 3 toques pela Ajuda.

### Tests for User Story 1

- [X] T008 [P] [US1] Criar testes unitários do controlador de tela (validação, carregamento, colar, limpar, sessão expirada e descarte) em `app/test/features/antigolpe/controlador_analise_golpe_test.dart`
- [X] T009 [P] [US1] Criar testes de widget, segurança contra links clicáveis, FR-006, diretrizes WCAG/TalkBack e matriz 4×3×3 em `app/test/features/antigolpe/tela_analise_golpe_test.dart`
- [X] T010 [P] [US1] Atualizar teste de profundidade de navegação (`<= 3` toques a partir do Início pelo atalho direto e pela Ajuda, mantendo as 7 portas do Hub) em `app/test/features/casca/profundidade_test.dart`

### Implementation for User Story 1

- [X] T011 [P] [US1] Implementar `RepositorioAnaliseGolpeSimulado` para modo demonstração e testes de widget em `app/lib/features/antigolpe/data/repositorios/repositorio_analise_golpe_simulado.dart`
- [X] T012 [US1] Implementar `ControladorAnaliseGolpe` em `app/lib/features/antigolpe/presentation/controladores/controlador_analise_golpe.dart`
- [X] T013 [US1] Implementar `TelaAnaliseGolpe` com componentes e tokens exclusivos do Design System, sem links clicáveis e com no máximo 1 Memora por tela em `app/lib/features/antigolpe/presentation/telas/tela_analise_golpe.dart`
- [X] T014 [US1] Expor atalho direto "Verificar golpe" na `TelaInicio` (`TelaInicio.chaveVerificarGolpe`) em `app/lib/features/inicio/presentation/tela_inicio.dart` e porta na `TelaAjuda` (`TelaAjuda.chaveVerificarGolpe`) em `app/lib/features/ajuda/presentation/tela_ajuda.dart`
- [X] T015 [US1] Integrar abertura da `TelaAnaliseGolpe` no `FluxoAutenticacao` (mantendo `TelaHub` com 7 portas para preservar `FR-017` em `Size(360, 880)`) em `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart` e `app/lib/main.dart`

**Checkpoint**: User Story 1 funcional, acessível em 1 toque no Início e aprovada na matriz 4×3×3.

---

## Phase 4: User Story 2 - Endpoint Backend `POST /v1/golpes/analisar` com IA e Motor Determinístico (Priority: P1)

**Goal**: Processar análises antigolpe autenticadas no backend combinando heurística determinística, integração Gemini REST sem envio de PII, sanitização pós-IA com piso monotônico e rate limiting por conta.

**Independent Test**: Executar `./mvnw.cmd test "-Dtest=TextoDaInterfaceTest,br.fatec.memora.antigolpe.**"` validando os 44 testes automatizados de heurística, sanitização, cliente Gemini, configuração de provedor, rate limit, controlador e segurança JWT.

### Tests for User Story 2

- [X] T016 [P] [US2] Criar testes do motor determinístico (mensagens seguras, links oficiais, IP direto, `@` userinfo, punycode, encurtador, impostor de marca, pedido de código/PIX e prompt injection) em `backend/src/test/java/br/fatec/memora/antigolpe/aplicacao/AnalisadorDeterministicoDeGolpesTest.java`
- [X] T017 [P] [US2] Criar testes do limitador de taxa por conta com `Clock` fixo em `backend/src/test/java/br/fatec/memora/antigolpe/seguranca/LimitadorAnaliseGolpeTest.java`
- [X] T018 [P] [US2] Criar testes do cliente Gemini REST sobre `HttpServer` local e testes de seleção condicional de provedor em `backend/src/test/java/br/fatec/memora/antigolpe/infra/ClienteAnaliseGolpeGeminiTest.java` e `backend/src/test/java/br/fatec/memora/antigolpe/infra/ConfiguracaoAnaliseGolpeIaTest.java`
- [X] T019 [P] [US2] Criar testes do serviço de aplicação (piso monotônico contra sub-classificação da IA, fallback determinístico em `AssistenteIndisponivel`, zero PII enviado) em `backend/src/test/java/br/fatec/memora/antigolpe/aplicacao/ServicoAnaliseGolpeTest.java`
- [X] T020 [P] [US2] Criar testes `MockMvc` e `@WebMvcTest` do controlador e da segurança JWT (`200`, `400`, `401`, `429`) em `backend/src/test/java/br/fatec/memora/antigolpe/api/ControladorAntigolpeTest.java` e `backend/src/test/java/br/fatec/memora/antigolpe/api/SegurancaAntigolpeWebMvcTest.java`

### Implementation for User Story 2

- [X] T021 [P] [US2] Implementar `AnalisadorDeterministicoDeGolpes` e `SanitizadorRespostaAntigolpe` em `backend/src/main/java/br/fatec/memora/antigolpe/aplicacao/AnalisadorDeterministicoDeGolpes.java` e `backend/src/main/java/br/fatec/memora/antigolpe/aplicacao/SanitizadorRespostaAntigolpe.java`
- [X] T022 [P] [US2] Implementar `LimitadorAnaliseGolpe` e `LimiteAnaliseGolpeExcedido` em `backend/src/main/java/br/fatec/memora/antigolpe/seguranca/LimitadorAnaliseGolpe.java` e `backend/src/main/java/br/fatec/memora/antigolpe/seguranca/LimiteAnaliseGolpeExcedido.java`
- [X] T023 [P] [US2] Implementar porta `ClienteAnaliseGolpe`, `PersonaAntigolpe`, `ClienteAnaliseGolpeGemini`, `ClienteAnaliseGolpeSimulado`, `CondicaoProvedorAntigolpe` e `ConfiguracaoAnaliseGolpeIa` em `backend/src/main/java/br/fatec/memora/antigolpe/infra/`
- [X] T024 [US2] Implementar `ServicoAnaliseGolpe` orquestrando rate limit, pré-check determinístico, chamada IA sem PII, fallback e sanitização em `backend/src/main/java/br/fatec/memora/antigolpe/aplicacao/ServicoAnaliseGolpe.java`
- [X] T025 [US2] Implementar DTOs `AnalisarGolpeRequest`, `AnalisarGolpeResponse` e endpoint `ControladorAnaliseGolpe` (`POST /v1/golpes/analisar`) em `backend/src/main/java/br/fatec/memora/antigolpe/api/`

**Checkpoint**: Endpoint `POST /v1/golpes/analisar` completo e validado por 44 testes no backend.

---

## Phase 5: User Story 3 - Fallback Local Offline e Integração Remota no Flutter (Priority: P2)

**Goal**: Integrar o aplicativo ao endpoint `POST /v1/golpes/analisar` com renovação silenciosa de token e fallback automático para `AnalisadorLocalDeGolpes` quando sem internet, *timeout* ou erro `5xx`.

**Independent Test**: Executar `analisador_local_de_golpes_test.dart`, `repositorio_analise_golpe_api_test.dart` e `ambiente_test.dart`.

### Tests for User Story 3

- [X] T026 [P] [US3] Criar testes unitários do motor heurístico offline cobrindo validações, mensagens seguras, domínios `.gov.br` e vetores de golpe em `app/test/features/antigolpe/analisador_local_de_golpes_test.dart`
- [X] T027 [P] [US3] Criar testes do `RepositorioAnaliseGolpeApi` (mapeamento online, renovação 401 com sucesso, propagação de `sessaoExpirada` quando renovação falha e fallback local em erro de conexão/timeout/500/503) em `app/test/features/antigolpe/repositorio_analise_golpe_api_test.dart`
- [X] T028 [P] [US3] Adicionar teste de resolução de `RepositorioAnaliseGolpeApi` vs `RepositorioAnaliseGolpeSimulado` na `Composicao` em `app/test/services/ambiente_test.dart`

### Implementation for User Story 3

- [X] T029 [P] [US3] Implementar motor determinístico puro em Dart `AnalisadorLocalDeGolpes` em `app/lib/features/antigolpe/domain/servicos/analisador_local_de_golpes.dart`
- [X] T030 [US3] Implementar `RepositorioAnaliseGolpeApi` integrado a `Dio`, `ChamadaComRenovacao` e fallback automático para `AnalisadorLocalDeGolpes` em `app/lib/features/antigolpe/data/repositorios/repositorio_analise_golpe_api.dart`
- [X] T031 [US3] Registrar `analiseGolpe` em `Composicao.resolver()` em `app/lib/services/ambiente/composicao.dart`

**Checkpoint**: Todas as histórias de usuário (US1, US2 e US3) integradas ponta a ponta nos modos online e offline.

---

## Phase 6: Polish & Portões de Qualidade Transversais

**Purpose**: Verificação completa dos portões de tokens, linguagem da interface, acessibilidade do Hub e análise estática

- [X] T032 Executar portão de tokens visuais `py specs/002-design-system/ferramentas/validar_tokens.py` (0 literais fora dos tokens)
- [X] T033 [P] Executar análise estática `flutter analyze` em `app/` (0 avisos/erros)
- [X] T034 [P] Executar suíte backend `./mvnw.cmd test "-Dtest=TextoDaInterfaceTest,br.fatec.memora.antigolpe.**"` (44/44 testes aprovados)
- [X] T035 Executar suíte de portões Flutter (`test/features/antigolpe/`, `texto_da_interface_test.dart`, `profundidade_test.dart`, `hub_cabe_sem_rolar_test.dart`, `desenhos_das_portas_test.dart`, `ambiente_test.dart`, `sem_planos_test.dart`, `matriz_dentro_da_conta_test.dart`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup & SpecKit)**: Sem dependências prévias.
- **Phase 2 (Foundational)**: Define entidades de domínio e textos `TextosAntigolpe` usados pelas Fases 3, 4 e 5.
- **Phase 3 (US1 - UI & Navegação)**, **Phase 4 (US2 - Backend API & IA)** e **Phase 5 (US3 - Fallback Local & Repositório API)**: Podem avançar em paralelo após a Fase 2 graças ao contrato REST travado em `plan.md`.
- **Phase 6 (Polish & Gates)**: Depende da conclusão das Fases 3, 4 e 5.
