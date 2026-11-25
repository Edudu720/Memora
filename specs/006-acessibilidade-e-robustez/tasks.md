---
description: "Lista de tarefas para implementação da Feature 006 — Polimento de Acessibilidade, Robustez de Conta e Rastreabilidade"
---

# Tasks: Polimento de Acessibilidade, Robustez de Conta e Rastreabilidade

**Input**: Documentos de design em `/specs/006-acessibilidade-e-robustez/`
**Prerequisites**: [plan.md](plan.md) (obrigatório), [spec.md](spec.md) (obrigatório), [research.md](research.md), [data-model.md](data-model.md), [contracts/componentes-e-servicos.md](contracts/componentes-e-servicos.md), [quickstart.md](quickstart.md)

**Tests**: Incluídos conforme especificado nos critérios de sucesso (`SC-001` a `SC-004`) e cenários de verificação (`V1` a `V5`).

**Organization**: As tarefas estão agrupadas por história de usuário (`US1` a `US4`) para permitir implementação, teste e validação independentes de cada entrega.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode ser executada em paralelo (arquivos distintos, sem dependências de tarefas incompletas)
- **[Story]**: Rótulo da história de usuário correspondente (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Caminhos exatos de arquivos incluídos em todas as descrições

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Configuração de dependências e propriedades base do backend para suporte a SMTP e agendamento de expurgo.

- [X] T001 Adicionar dependência `spring-boot-starter-mail` em `backend/pom.xml`
- [X] T002 [P] Configurar propriedades padrão de e-mail e expurgo (`memora.conta.expiracao-pendente=24h`, `memora.conta.expurgo-intervalo-ms=3600000`, `memora.conta.expurgo-atraso-inicial-ms=60000`, `memora.email.remetente` e variáveis `SPRING_MAIL_*`) em `backend/src/main/resources/application.properties`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infraestrutura de agendamento e consultas de repositório no backend necessárias antes da implementação das histórias de usuário de backend (`US2` e `US3`).

**⚠️ CRITICAL**: As histórias de backend (`US2`) dependem da conclusão desta fase; `US1` e `US4` (Flutter/Docs) são independentes.

- [X] T003 Habilitar agendamento de tarefas (`@EnableScheduling`) em `backend/src/main/java/br/fatec/memora/MemoraApplication.java`
- [X] T004 [P] Adicionar método `deletarPorPessoaId(@Param("pessoaId") UUID pessoaId)` com `@Modifying @Query("DELETE FROM EventoAutenticacao e WHERE e.pessoaId = :pessoaId")` (necessário porque `fk_evento_pessoa` não possui `ON DELETE CASCADE`) em `backend/src/main/java/br/fatec/memora/autenticacao/infra/RepositorioEventoAutenticacao.java`
- [X] T005 [P] Adicionar consulta `buscarContasPorEstadoAnterioresA(@Param("estado") EstadoDaConta estado, @Param("limite") Instant limite)` filtrando `p.estado = :estado AND p.criadoEm < :limite` em `backend/src/main/java/br/fatec/memora/autenticacao/infra/RepositorioPessoaUsuaria.java`

**Checkpoint**: Infraestrutura de banco e agendamento pronta — histórias de usuário podem ser implementadas.

---

## Phase 3: User Story 1 - Botões com Duplo Sinal Visual de Foco e Toque (Priority: P1) 🎯 MVP

**Goal**: Garantir que todas as variantes de `BotaoBase` (`primario`, `secundario`, `terciario`, `perigo`) apresentem um segundo sinal visual de foco e toque além da cor (anel externo de foco + escala tátil) reutilizando `SuperficieTocavel`, mantendo semântica, altura mínima (`56dp`) e tokens do Design System.

**Independent Test**: Executar `flutter test test/design_system/decisao_e_entrada_test.dart test/design_system/reducao_de_movimento_test.dart` em `app/` e verificar anel de foco externo (`MemoraDimensoes.bordaSelecao` com `BorderSide.strokeAlignOutside`) e escala de toque (`MemoraMovimento.escalaPressionado`) nas 4 variantes.

### Implementation & Tests for User Story 1

- [X] T006 [US1] Refatorar `BotaoBase` para delegar a superfície interativa de foco, toque, escala (`MemoraMovimento.escalaPressionado`) e anel de foco externo (`MemoraDimensoes.bordaSelecao` com `BorderSide.strokeAlignOutside`) à `SuperficieTocavel` nas 4 variantes (`primario`, `secundario`, `terciario`, `perigo`), preservando `Semantics(button: true, enabled: habilitado)`, altura mínima (`MemoraDimensoes.alturaMinimaToque`), preenchimento `cores.destaque` ao pressionar variantes sem fundo e inativação quando `carregando == true` ou `aoPressionar == null` em `app/lib/design_system/componentes/botoes/botao_base.dart`
- [X] T007 [P] [US1] Adicionar testes de widget verificando anel de foco externo e escala de toque nas 4 variantes de `BotaoBase` (e ausência de reação visual nos estados desabilitado e carregando) em `app/test/design_system/decisao_e_entrada_test.dart`
- [X] T008 [P] [US1] Adicionar teste de widget verificando que `BotaoBase` suprime a animação de escala (`1.0`) mantendo o anel de foco externo quando `MediaQueryData.disableAnimations == true` em `app/test/design_system/reducao_de_movimento_test.dart`

**Checkpoint**: User Story 1 concluída e testável de forma independente no Design System.

---

## Phase 4: User Story 2 - Liberação Segura de Contas Assistidas Abandonadas (Priority: P1)

**Goal**: Impedir que contas assistidas abandonadas em `PENDENTE_VERIFICACAO` por mais de 24 horas bloqueiem permanentemente o e-mail/telefone da pessoa usuária, expurgando-as tanto sob demanda (após hash Argon2id em tempo constante no cadastro) quanto via rotina agendada em background, preservando o chamariz anti-enumeração (`FR-010`) para contas `ATIVA` ou pendentes recentes (`<= 24h`).

**Independent Test**: Executar `./mvnw test -Dtest=ExpurgoDeContaPendenteTest,NaoRevelaExistenciaTest,CanalNaoVerificadoTest` em `backend/`.

### Implementation & Tests for User Story 2

- [X] T009 [US2] Criar `ServicoDeExpurgoDeContaPendente` com `expurgarSeExpirada(PessoaUsuaria, Instant)`, `expurgarContaPendente(UUID)` (executando `deletarPorPessoaId` em `evento_autenticacao` antes de deletar `pessoa_usuaria` com `estado == EstadoDaConta.PENDENTE_VERIFICACAO`) e rotina `@Scheduled` `expurgarContasPendentesVencidas()` para contas com `criadoEm < Instant.now(relogio).minus(Duration.ofHours(24))` em `backend/src/main/java/br/fatec/memora/autenticacao/aplicacao/ServicoDeExpurgoDeContaPendente.java`
- [X] T010 [US2] Atualizar `ServicoDeCadastro.cadastrar` para verificar, estritamente após o cálculo em tempo constante do hash Argon2id da senha (`FR-010`), se o canal existente pertence a conta em `PENDENTE_VERIFICACAO` expirada (`> 24h`), expurgando-a sob demanda e prosseguindo com o novo cadastro real (mantendo a resposta chamariz para contas `ATIVA` ou `PENDENTE_VERIFICACAO` com `<= 24h`) em `backend/src/main/java/br/fatec/memora/autenticacao/aplicacao/ServicoDeCadastro.java`
- [X] T011 [US2] Criar suíte de testes de integração validando expurgo sob demanda de conta `PENDENTE_VERIFICACAO` com `> 24h` (novo cadastro cria conta real e emite código), preservação da resposta chamariz para conta `PENDENTE_VERIFICACAO` recente (`<= 24h`) ou `ATIVA`, e expurgo agendado em lote removendo `evento_autenticacao`, `canal_contato`, `sessao`, `codigo_verificacao` e `pessoa_usuaria` em `backend/src/test/java/br/fatec/memora/autenticacao/api/ExpurgoDeContaPendenteTest.java`

**Checkpoint**: User Story 2 concluída (`T065b` fechada) sem regressão nos testes anti-enumeração.

---

## Phase 5: User Story 3 - Envio Real de Código de Verificação e Notificação em Produção (Priority: P2)

**Goal**: Fornecer adaptadores reais de produção (`@Profile("producao")`) para `EnviadorDeCodigo` e `NotificadorDeConta` via SMTP padrão (`JavaMailSender`), com validação *fail-fast* na subida caso `spring.mail.host` ou `memora.email.remetente` estejam ausentes, mensagens acolhedoras sem links na voz da Memora, contorno seguro para `TELEFONE` e proibição absoluta de logar `codigoEmClaro`.

**Independent Test**: Executar `./mvnw test -Dtest=EnvioRealDeEmailTest` em `backend/`.

### Implementation & Tests for User Story 3

- [X] T012 [P] [US3] Implementar `EnviadorDeCodigoPorEmail` anotado com `@Component @Profile("producao")` usando `JavaMailSender`, validação *fail-fast* em `@PostConstruct` exigindo `spring.mail.host` e `memora.email.remetente` não vazios, corpo de e-mail sem links na voz da Memora (diferenciando `FinalidadeCodigo.VERIFICACAO_CANAL` e `FinalidadeCodigo.RECUPERACAO_SENHA`), contorno seguro para `TipoDeCanal.TELEFONE` e zero registro de `codigoEmClaro` em logs em `backend/src/main/java/br/fatec/memora/autenticacao/infra/EnviadorDeCodigoPorEmail.java`
- [X] T013 [P] [US3] Implementar `NotificadorDeContaPorEmail` anotado com `@Component @Profile("producao")` usando `JavaMailSender`, validação *fail-fast* em `@PostConstruct` exigindo `spring.mail.host` e `memora.email.remetente` não vazios, aviso de senha trocada sem links na voz da Memora e contorno seguro para `TipoDeCanal.TELEFONE` em `backend/src/main/java/br/fatec/memora/autenticacao/infra/NotificadorDeContaPorEmail.java`
- [X] T014 [US3] Criar suíte de testes unitários verificando envio SMTP com texto sem links para `EnviadorDeCodigoPorEmail` e `NotificadorDeContaPorEmail`, ausência total de `codigoEmClaro` nas mensagens de log e exceções, falha rápida (`IllegalStateException`) em `@PostConstruct` quando `spring.mail.host` ou `memora.email.remetente` estão em branco e tratamento seguro de `TipoDeCanal.TELEFONE` em `backend/src/test/java/br/fatec/memora/autenticacao/infra/EnvioRealDeEmailTest.java`

**Checkpoint**: User Story 3 concluída (`T065a` e `T068` fechadas) mantendo `@Profile("!producao")` intacto para desenvolvimento e testes.

---

## Phase 6: User Story 4 - Higiene de Testes de Escala de Texto e Rastreabilidade Documental (Priority: P3)

**Goal**: Eliminar a construção de `MediaQueryData` com dimensões zeradas em `cartao_de_porta_test.dart` e atualizar a documentação viva (`o-que-falta.md` e `specs/001-autenticacao-acessivel/tasks.md`) para refletir com exatidão o estado atual do repositório.

**Independent Test**: Executar `flutter test test/design_system/cartao_de_porta_test.dart` em `app/` e inspecionar `docs/relatorios/o-que-falta.md` e `specs/001-autenticacao-acessivel/tasks.md`.

### Implementation & Tests for User Story 4

- [X] T015 [P] [US4] Corrigir o helper `envolver()` para usar `Builder` e `MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala))` preservando as dimensões reais da janela de teste em `app/test/design_system/cartao_de_porta_test.dart`
- [X] T016 [P] [US4] Marcar `T065a` e `T065b` como concluídas (`[X]`) e atualizar a observação de `T068` referenciando os adaptadores SMTP de produção e o expurgo de 24h em `specs/001-autenticacao-acessivel/tasks.md`
- [X] T017 [P] [US4] Atualizar o relatório vivo reconciliando PRs já mescladas (`#44`–`#58`, Fase 11 da 003), permissão `INTERNET` no `AndroidManifest.xml`, infraestrutura Docker/Render, fechamento de `BotaoBase`/`T065a`/`T065b`/`T068` e contagens atualizadas de testes em `docs/relatorios/o-que-falta.md`

**Checkpoint**: Todas as 4 histórias de usuário concluídas e independentemente verificadas.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Execução completa dos portões de qualidade (`V1` a `V5` do `quickstart.md`) e fechamento do checklist técnico.

- [X] T018 Executar validações `V1`, `V2`, `V4` e `V5` de frontend (`flutter analyze`, `flutter test` completo e auditoria de literais fora de `tokens/`) em `app/` conforme `specs/006-acessibilidade-e-robustez/quickstart.md`
- [X] T019 Executar validação `V3` de backend (`./mvnw test` completo incluindo `NaoRevelaExistenciaTest`, `CanalNaoVerificadoTest`, `ExpurgoDeContaPendenteTest` e `EnvioRealDeEmailTest`) em `backend/` conforme `specs/006-acessibilidade-e-robustez/quickstart.md`
- [X] T020 Marcar os itens validados (`CHK001`–`CHK015`) no checklist de fechamento técnico em `specs/006-acessibilidade-e-robustez/checklists/fechamento-tecnico.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — pode iniciar imediatamente (`T001`, `T002`).
- **Foundational (Phase 2)**: Depende da Phase 1 — bloqueia a `User Story 2` (`T003`, `T004`, `T005`).
- **User Story 1 (Phase 3 - P1)**: Independente do backend — pode iniciar imediatamente em paralelo com Setup/Foundational (`T006` → `T007`, `T008`).
- **User Story 2 (Phase 4 - P1)**: Depende da Phase 2 (`T003`–`T005`) — segue a ordem `T009` → `T010` → `T011`.
- **User Story 3 (Phase 5 - P2)**: Depende da Phase 1 (`T001`, `T002`) — `T012` e `T013` em paralelo, seguidas por `T014`.
- **User Story 4 (Phase 6 - P3)**: `T015` pode rodar a qualquer momento; `T016` e `T017` consolidam a documentação após `US1`–`US3`.
- **Polish (Phase 7)**: Depende da conclusão das Phases 3, 4, 5 e 6 (`T018`–`T020`).

### Parallel Opportunities

- **Frontend vs Backend**: Toda a `US1` (`T006`–`T008`) e `T015` (`US4`) operam em `app/` e podem rodar em paralelo com as fases de `backend/` (`Phase 1`, `Phase 2`, `US2`, `US3`).
- **Dentro da Phase 2**: `T004` (`RepositorioEventoAutenticacao.java`) e `T005` (`RepositorioPessoaUsuaria.java`) podem rodar em paralelo.
- **Dentro da US1**: `T007` (`decisao_e_entrada_test.dart`) e `T008` (`reducao_de_movimento_test.dart`) podem ser escritos em paralelo após `T006`.
- **Dentro da US3**: `T012` (`EnviadorDeCodigoPorEmail.java`) e `T013` (`NotificadorDeContaPorEmail.java`) podem ser implementados em paralelo.
- **Dentro da US4**: `T015`, `T016` e `T017` editam arquivos distintos e são paralelizáveis.

---

## Parallel Example: User Story 1 & User Story 3

```bash
# US1 - Testes em paralelo após refatorar BotaoBase (T006):
Task T007: "Adicionar testes de widget verificando anel de foco externo e escala de toque nas 4 variantes de BotaoBase em app/test/design_system/decisao_e_entrada_test.dart"
Task T008: "Adicionar teste de widget verificando que BotaoBase suprime a animação de escala mantendo o anel de foco externo em app/test/design_system/reducao_de_movimento_test.dart"

# US3 - Adaptadores SMTP em paralelo após Setup (T001, T002):
Task T012: "Implementar EnviadorDeCodigoPorEmail em backend/src/main/java/br/fatec/memora/autenticacao/infra/EnviadorDeCodigoPorEmail.java"
Task T013: "Implementar NotificadorDeContaPorEmail em backend/src/main/java/br/fatec/memora/autenticacao/infra/NotificadorDeContaPorEmail.java"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2 — Prioridades P1)

1. Concluir **Phase 1 (Setup)** e **Phase 2 (Foundational)**.
2. Concluir **Phase 3 (US1)**: `BotaoBase` com duplo sinal visual via `SuperficieTocavel` e validar `V1`.
3. Concluir **Phase 4 (US2)**: Expurgo de contas assistidas abandonadas (`> 24h`) e validar `V3`.

### Incremental Delivery

1. **Incremento 1 (P1 - Acessibilidade)**: `US1` (`T006`–`T008`) → fecha pendência do Design System (Feature 002).
2. **Incremento 2 (P1 - Robustez de Cadastro)**: `Phase 1` + `Phase 2` + `US2` (`T001`–`T005`, `T009`–`T011`) → fecha `T065b` da Feature 001.
3. **Incremento 3 (P2 - Entrega em Produção)**: `US3` (`T012`–`T014`) → fecha `T065a` e `T068` da Feature 001.
4. **Incremento 4 (P3 - Higiene e Rastreabilidade)**: `US4` + `Phase 7` (`T015`–`T020`) → fecha dívidas de teste e documentação viva com 100% das suítes verdes.
