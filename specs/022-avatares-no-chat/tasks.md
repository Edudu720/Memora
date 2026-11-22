---

description: "Lista de tarefas ordenada para implementação da correção visual de avatares da Memora e do usuário no chat"
---

# Tasks: Avatares da Memora e da Pessoa Usuária no Chat

**Input**: Design documents from `/specs/022-avatares-no-chat/`  
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/avatares-conversa-ui.md, quickstart.md

**Tests**: As tarefas de testes automatizados garantem cobertura da sincronização de retrato local, contrato de design system (`BalaoDeFala`), reconciliação da regra de única Memora animada no topo (`BarraSuperior`) e matriz `4 × 3` até `200%`.

**Organization**: Tarefas agrupadas por história de usuário (US1 → US2 → US3) para permitir implementação incremental e verificação independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos distintos, sem dependência de tarefa incompleta)
- **[Story]**: História de usuário correspondente (`[US1]`, `[US2]`, `[US3]`)

---

## Phase 1: Setup (Preparação e Baseline)

**Purpose**: Validar o estado inicial da branch, revisar regras visuais e confirmar portões verdes antes de modificar código.

- [X] T001 Revisar a skill `.claude/skills/memora-ux/SKILL.md`, confirmar o contrato `specs/022-avatares-no-chat/contracts/avatares-conversa-ui.md` e executar linha de base com `python specs/002-design-system/ferramentas/validar_tokens.py` e `flutter analyze` em `app/`.

---

## Phase 2: Foundational (Infraestrutura Compartilhada — Design System e Canal Reativo)

**Purpose**: Preparar `BalaoDeFala` para aceitar slot desacoplado de retrato e controle estático de animação, e expor fluxo reativo local em `ArmazenamentoDeFotoDePerfil`.

**⚠️ CRITICAL**: Nenhuma história de usuário do chat pode ser concluída antes desta fase.

- [X] T002 Adicionar `Stream<void> get alteracoes` (broadcast) em `ArmazenamentoDeFotoDePerfil`, emitindo notificações protegidas por `!_alteracoes.isClosed` após conclusão em `salvarFoto`, `salvarAvatar`, `apagar` e `esquecerDoAparelho` tanto em `FotoDePerfilLocal` quanto em `FotoDePerfilEmMemoria` no arquivo `app/lib/features/perfil/data/foto_de_perfil_local.dart`.
- [X] T003 [P] Estender `BalaoDeFala` e `BalaoDeFala.escrevendo` com os parâmetros opcionais `final Widget? avatarPessoa;` e `final bool rostoAnimado = true;`, preservando o fallback `_RostoDaPessoa`, mantendo isolamento de `design_system/` sem importar `features/`, e desativando toque (`reageAoToque: false`) e animações (`MediaQuery(disableAnimations: true)`) quando `rostoAnimado == false` em `app/lib/design_system/componentes/conversa/balao_de_fala.dart`.
- [X] T004 [P] Cobrir `ArmazenamentoDeFotoDePerfil.alteracoes` em `app/test/features/perfil/foto_de_perfil_local_test.dart` (`salvarFoto`, `salvarAvatar`, `apagar`, `esquecerDoAparelho`) e adicionar cenários de `avatarPessoa` customizado e `rostoAnimado: false` em `app/test/design_system/balao_de_fala_test.dart`.

**Checkpoint**: Design System desacoplado pronto e fluxo reativo de foto local validado em testes unitários.

---

## Phase 3: User Story 1 - Identificação Visual nos Balões de Conversa (Priority: P1) 🎯 MVP

**Goal**: Exibir o rosto mini estático da Memora à esquerda de cada balão dela e o retrato circular à direita de cada balão `"Você"` na tela de conversa, reproduzindo o padrão visual da tela modelo (*Passo 2 de 5*).

**Independent Test**: Abrir `TelaConversa` vazia (convite), com histórico salvo, durante envio/escrita (`escrevendo…`) e após resposta, confirmando que todos os balões exibem seus respectivos ícones laterais nos lados corretos enquanto apenas a `BarraSuperior` mantém a Memora animada/falando.

- [X] T005 [US1] Atualizar `TelaConversa` (`_fala`, `BalaoDeFala.escrevendo`, balão em streaming e `TelaConversa.chaveConvite`) para usar `comRosto: true` e `rostoAnimado: false` em todos os balões da conversa em `app/lib/features/assistente/presentation/telas/tela_conversa.dart`.
- [X] T006 [US1] Reconciliar asserções em `app/test/features/assistente/memora_no_topo_da_conversa_test.dart` e `app/test/features/assistente/tela_conversa_test.dart` (`L227–242`) para verificar que fora de `BalaoDeFala` existe no máximo 1 `MemoraAnimada` viva/falando (na `BarraSuperior`), enquanto dentro dos balões de conversa os rostos permanecem estáticos (`reageAoToque: false` e ancestral `MediaQuery.disableAnimations == true`) e recuam acima de `175%`.
- [X] T007 [P] [US1] Reconciliar a contagem de `MemoraAnimada` viva em `TelaConversa` em `app/test/design_system/icones_e_toque_test.dart`, diferenciando a `MemoraAnimada` única fora de `BalaoDeFala` (na `BarraSuperior`) dos marcadores estáticos nos balões.

**Checkpoint**: MVP visual funcional — todo balão do chat exibe autoria por posição, rosto/retrato e nome escrito, alinhado à ajuda guiada.

---

## Phase 4: User Story 2 - Sincronização Fiel com o Retrato Selecionado em Meu Perfil (Priority: P1)

**Goal**: Fazer com que o avatar à direita nos balões `"Você"` do chat exiba exatamente o retrato salvo em Meu Perfil para a conta ativa (foto própria sanitizada, avatar ilustrado da Memora ou padrão neutro com iniciais/silhueta), atualizando em tempo real quando modificado em Meu Perfil e isolado por conta.

**Independent Test**: Alterar o retrato da conta entre foto própria, cada um dos 4 avatares ilustrados e remoção (padrão neutro) e confirmar atualização imediata em conversa já montada, fallback seguro em erro de arquivo e ausência de vazamento ao trocar de conta ou limpar o aparelho.

- [X] T008 [US2] Atualizar `_abrirConversa` e `_DonaDaConversa` para repassar `fotoDePerfil: _fotos`, `idDaConta: _pessoa?.id` e `nomeDaPessoa: _pessoa?.nomeTratamento` para `TelaConversa` em `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`.
- [X] T009 [US2] Adicionar parâmetros opcionais `fotoDePerfil`, `idDaConta` e `nomeDaPessoa` em `TelaConversa`, implementar leitura local assíncrona com guarda de corrida (`_versaoRetrato`) e `try/catch`, assinar `fotoDePerfil.alteracoes` em `initState`/`didUpdateWidget`/`dispose` e construir `avatarPessoa` via `ExcludeSemantics(child: RetratoDoPerfil(nome: ..., retrato: ..., tamanho: MemoraDimensoes.pisoDeIlustracao))` nos balões `"Você"` em `app/lib/features/assistente/presentation/telas/tela_conversa.dart`.
- [X] T010 [US2] Criar a suíte `app/test/features/assistente/avatares_da_conversa_test.dart` validando foto própria (`FotoPropriaDePerfil`), os 4 avatares ilustrados (`AvatarIlustrado`), retrato padrão com iniciais e sem letras, fallback silencioso para padrão neutro em arquivo ausente, atualização ao vivo via `alteracoes`, descarte de retrato ao trocar de conta / `esquecerDoAparelho()` e zero chamadas de rede extras.

**Checkpoint**: Integração completa entre Perfil e Chat — retrato sincronizado localmente em tempo real e isolado por conta.

---

## Phase 5: User Story 3 - Acessibilidade, Ampliação 200%, Movimento Reduzido e Desempenho (Priority: P2)

**Goal**: Garantir legibilidade plena em ampliações até `200%`, contraste nos três temas (claro, escuro e alto contraste), silêncio semântico dos avatares decorativos para TalkBack/VoiceOver e comportamento estático sob redução de movimento.

**Independent Test**: Executar testes de matriz de aparelhos (`320×568` a `412×915`) nas escalas `100%`, `150%` e `200%`, nos três temas e com `disableAnimations: true`, confirmando zero estouro de layout e zero nós semânticos duplicados.

- [X] T011 [US3] Garantir em `TelaConversa` (`app/lib/features/assistente/presentation/telas/tela_conversa.dart`) que `mostrarRosto = escala < MemoraDimensoes.escalaTextoAlta` (`1.75`) oculte avatares laterais sob alta ampliação, aplicar proteção de ajuste proporcional nas iniciais decorativas de `RetratoDoPerfil._padraoNeutro` (`FittedBox(fit: BoxFit.scaleDown)` em `app/lib/features/perfil/presentation/widgets/retrato_do_perfil.dart`) para `tamanho = 40 dp` sem literais visuais e preservar `ExcludeSemantics`.
- [X] T012 [US3] Ampliar `app/test/features/assistente/avatares_da_conversa_test.dart` (e revisar `app/test/acessibilidade/conversa_acessibilidade_test.dart` / executar `test/design_system/memora_distancia_test.dart`) cobrindo a matriz `4 × 3` até `200%` (com `320×568` e foto/avatar ativo), iniciais largas (`"WM"`) a `150%` em `40 dp`, os 3 temas (`claro`, `escuro`, `altoContraste`), `disableAnimations: true` e árvore `Semantics` sem anúncios duplicados.

**Checkpoint**: Todas as histórias (US1, US2 e US3) implementadas e verificadas quanto à acessibilidade e fluidez.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Atualizar documentação viva da especificação anterior e executar todos os portões finais antes da PR.

- [X] T013 [P] Registrar nota de revisão da `FR-042` / `FR-025` em `specs/013-redesenho-final/spec.md` apontando para `specs/022-avatares-no-chat/spec.md`, e documentar a entrega da feature `022-avatares-no-chat` em `CHANGELOG.md`.
- [X] T014 Executar todos os portões automatizados (`python specs/002-design-system/ferramentas/validar_tokens.py`, `python specs/002-design-system/ferramentas/validar_paleta.py`, `flutter analyze` e `flutter test` completo em `app/`).
- [X] T015 Conferir integralmente todos os critérios e checklist visual definidos em `specs/022-avatares-no-chat/quickstart.md` antes de abrir a Pull Request para `develop`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Início imediato (`T001`).
- **Phase 2 (Foundational)**: Depende de `T001`; `T002` e `T003` podem ocorrer em paralelo (`[P]`), seguidas por `T004`. Bloqueia US1 e US2.
- **Phase 3 (US1 — MVP)**: Depende de `T003`. `T005` atualiza `tela_conversa.dart`, desbloqueando `T006` e `T007`.
- **Phase 4 (US2 — Retrato do Perfil)**: Depende de `T002` e `T005` (para integrar no mesmo arquivo `tela_conversa.dart` sem conflito). `T008` conecta `fluxo_autenticacao.dart`, `T009` conecta leitura/stream na `tela_conversa.dart`, e `T010` cria `avatares_da_conversa_test.dart`.
- **Phase 5 (US3 — Acessibilidade)**: Depende de `T009` (`T011` e `T012`).
- **Phase 6 (Polish)**: Depende da conclusão de todas as histórias (`T013` paralela, seguida de `T014` e `T015`).

### Parallel Opportunities

- Na Fase 2: `T002` (`foto_de_perfil_local.dart`) e `T003` (`balao_de_fala.dart`) são arquivos totalmente independentes.
- Na Fase 3: `T006` e `T007` atualizam arquivos de teste distintos em paralelo após `T005`.
- Na Fase 6: `T013` (`specs/013-redesenho-final/spec.md` e `CHANGELOG.md`) roda em paralelo aos testes finais antes de `T014`.

---

## Implementation Strategy

1. **MVP First (`T001`–`T007`)**: Habilitar os rostos estáticos nos balões da conversa (`comRosto: true`, `rostoAnimado: false`) e validar com os testes de topo/ícones reconciliados.
2. **Identidade Pessoal em Tempo Real (`T008`–`T010`)**: Injetar o repositório local de foto e a assinatura reativa `alteracoes` para garantir paridade exata entre Meu Perfil e Chat.
3. **Resiliência e Acessibilidade (`T011`–`T015`)**: Garantir recuo em ampliações altas (`>= 175%`), contraste, TalkBack limpo e execução verde de toda a suíte.

---

## Phase 7: Convergence

- [X] T016 [CRITICAL] Envolver o ícone neutro `Icons.person_outline_rounded` em `Container(color: cores.primaria, alignment: Alignment.center)` dentro de `RetratoDoPerfil._padraoNeutro` (`app/lib/features/perfil/presentation/widgets/retrato_do_perfil.dart`) e cobrir o fallback `errorBuilder` sem iniciais nos três temas em `app/test/features/assistente/avatares_da_conversa_test.dart` para garantir contraste WCAG 2.2 (`cores.sobrePrimaria` sobre `cores.primaria`) per Constitution III, FR-008, FR-011 (partial)
- [X] T017 Adicionar testes automatizados em `app/test/features/assistente/avatares_da_conversa_test.dart` cobrindo o limiar exato de ocultamento em `175%` (`1.75`) e tela `412×915`, além de leituras assíncronas fora de ordem com `Completer` validando descarte pela guarda `_versaoRetrato` per FR-009, Edge Case 4, SC-004 (partial)
