# Tasks: Estabilidade da API do Gemini (Item 12)

**Input**: Design documents from `/specs/018-estabilidade-gemini/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/configuracao-gemini.md, quickstart.md

**Tests**: Testes unitários automatizados em `ClienteDaAssistenteGeminiTest.java` e `ConfiguracaoDoProvedorDeIaTest.java`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User Story (`US1`, `US2`, `US3`)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Preparar contexto de propriedades e confirmar baseline verde dos testes do adaptador Gemini.

- [X] T001 Confirmar passagem prévia de `ClienteDaAssistenteGeminiTest` e `ConfiguracaoDoProvedorDeIaTest` no backend

---

## Phase 2: User Story 1 — Retentativa curta antes do primeiro trecho (Priority: P1) 🎯 MVP

**Goal**: Recuperar falhas transitórias (`5xx`, `REDE`, `PRAZO`) no modelo principal antes do envio do primeiro trecho sem duplicar texto após streaming iniciado.

**Independent Test**: Executar testes de `503` recuperado na 2ª tentativa e erro após o 1º trecho em `ClienteDaAssistenteGeminiTest.java`.

- [X] T002 [US1] Refatorar `backend/src/main/java/br/fatec/memora/assistente/infra/ClienteDaAssistenteGemini.java` mantendo o construtor de 5 argumentos compatível (`tentativasPrimario=1`, `modeloReserva=""`) e adicionando o construtor completo validando `tentativasPrimario >= 1` e `esperaEntreTentativas >= 0`
- [X] T003 [US1] Implementar em `ClienteDaAssistenteGemini.java` o loop de retentativa com espera (`Thread.sleep` tratando `InterruptedException`) apenas quando `enviouTrecho == false` e o motivo for `FALHA_DO_PROVEDOR`, `REDE` ou `PRAZO`
- [X] T004 [P] [US1] Adicionar testes em `backend/src/test/java/br/fatec/memora/assistente/infra/ClienteDaAssistenteGeminiTest.java` cobrindo recuperação em `503` transitório, não retentativa após entrega do 1º trecho e interrupção durante espera

---

## Phase 3: User Story 2 — Modelo reserva automático `gemini-3.5-flash-lite` (Priority: P1)

**Goal**: Acionar automaticamente o modelo reserva em `429` imediato ou após esgotar retentativas de `5xx`/`REDE`/`PRAZO` no principal, mantendo os mesmos invariantes de segurança (`x-goog-api-key`, `systemInstruction`, `tools`, sem corpo de erro externo) e bloqueando reserva em `4xx != 429`, `RESPOSTA_VAZIA` e `RESPOSTA_ILEGIVEL`.

**Independent Test**: Simular `429` e `503` persistente no caminho do modelo principal roteando para `/models/gemini-3.5-flash-lite:streamGenerateContent?alt=sse`.

- [X] T005 [US2] Implementar validação de `modeloReserva` (`[A-Za-z0-9._-]+`, ignorando vazio ou igual ao principal) e construção de `enderecoReserva` + `LOG.warn` seguro em `ClienteDaAssistenteGemini.java`
- [X] T006 [US2] Integrar fallback para `enderecoReserva` em `ClienteDaAssistenteGemini.java`: imediato em `COTA_ESGOTADA` (`429`), após tentativas em `FALHA_DO_PROVEDOR`/`REDE`/`PRAZO`, e bloqueado em `PEDIDO_RECUSADO`/`RESPOSTA_VAZIA`/`RESPOSTA_ILEGIVEL` ou pós-1º-trecho
- [X] T007 [P] [US2] Adicionar testes em `ClienteDaAssistenteGeminiTest.java` para `429` indo direto ao reserva (2 requisições), `503` persistente acionando reserva com `systemInstruction`/`tools`/`x-goog-api-key`, `400` sem retry/reserva, reserva desabilitado quando vazio/igual, falha dupla sem vazamento e `modeloReserva` malformado

---

## Phase 4: User Story 3 — Alinhar defaults e configurar parâmetros em Spring e Blueprint (Priority: P2)

**Goal**: Alinhar modelo padrão para `gemini-3.6-flash` em todo o backend e expor `modelo-reserva`, `tentativas-primario` e `espera-retentativa-ms` em `application.properties`, `ConfiguracaoDoProvedorDeIa.java` e `render.yaml`.

**Independent Test**: Rodar `ConfiguracaoDoProvedorDeIaTest` verificando padrão `3.6-flash` + `3.5-flash-lite`, customização via propriedades e falha no boot para valores inválidos sem vazar chave.

- [X] T008 [P] [US3] Atualizar `backend/src/main/resources/application.properties` com padrão `gemini-3.6-flash` e propriedades `memora.assistente.gemini.modelo-reserva`, `tentativas-primario` e `espera-retentativa-ms`
- [X] T009 [US3] Atualizar `backend/src/main/java/br/fatec/memora/assistente/infra/ConfiguracaoDoProvedorDeIa.java` com os novos `@Value`, defaults alinhados e log informativo dos modelos principal e reserva
- [X] T010 [P] [US3] Atualizar `render.yaml` adicionando `MEMORA_ASSISTENTE_GEMINI_MODELO_RESERVA=gemini-3.5-flash-lite` no serviço `memora-backend`
- [X] T011 [P] [US3] Expandir `backend/src/test/java/br/fatec/memora/assistente/infra/ConfiguracaoDoProvedorDeIaTest.java` validando subida com reserva padrão/vazia e recusa no boot para `modelo-reserva` ou `tentativas-primario` inválidos sem vazar `GEMINI_API_KEY`

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Atualizar documentação viva e validar suíte completa sem regressões.

- [X] T012 [P] Atualizar `docs/architecture/adr-002-provedor-de-ia.md`, `docs/deploy/render.md` e `CHANGELOG.md` documentando o padrão `gemini-3.6-flash` e a política de retry + reserva `gemini-3.5-flash-lite`
- [X] T013 Executar suíte de testes do backend (`mvnw.cmd test` nos testes unitários sem banco) e validar `quickstart.md`

---

## Dependencies & Execution Order

- **Phase 1 (T001)** → **Phase 2 (T002, T003, T004)** → **Phase 3 (T005, T006, T007)** → **Phase 4 (T008..T011)** → **Phase 5 (T012, T013)**.

---

## Phase 6: Convergence

- [X] T014 [US1] Adicionar teste unitário em `backend/src/test/java/br/fatec/memora/assistente/infra/ClienteDaAssistenteGeminiTest.java` provando que interrupção durante a espera entre retentativas aborta imediatamente sem segunda requisição HTTP per T004 (`partial`)
- [X] T015 [US2] Ajustar logs de fallback em `backend/src/main/java/br/fatec/memora/assistente/infra/ClienteDaAssistenteGemini.java` para mencionar acionamento de reserva apenas quando `enderecoReserva != null` e alinhar o teste opcional `backend/src/test/java/br/fatec/memora/assistente/infra/ClienteDaAssistenteGeminiRealTest.java` para `gemini-3.6-flash` com reserva `gemini-3.5-flash-lite` per FR-001 (`partial`)

---

## Phase 7: Review Follow-up

- [X] T016 [US1/US3] Incluir `Thread.currentThread().isInterrupted()` na guarda de saída de `ClienteDaAssistenteGemini.conversar()`, registrar `(reserva: nenhum)` em `ConfiguracaoDoProvedorDeIa` quando `modeloReserva` coincidir com `modelo` e ampliar testes unitários de regressão
