# Tasks: Feature 010 — Correções da Revisão da PR #71 (Privacidade, Voz Local e Localizador Real)

**Input**: Design documents from `specs/010-revisao-pr71-localizador/`  
**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required), [research.md](research.md), [data-model.md](data-model.md), [localizador-e-privacidade.md](contracts/localizador-e-privacidade.md), [quickstart.md](quickstart.md), [pr71-revisao.md](checklists/pr71-revisao.md) (`30/30 [x]`)

**Tests**: As suítes unitárias, de widget e de contrato/controlador fazem parte explícita dos critérios de aceitação (`SC-001` a `SC-005`) e do `quickstart.md`, sendo incluídas antes/junto de cada história para validação independente.

**Organization**: Tarefas organizadas por fase e User Story (`US1`–`US4`) conforme prioridade em [spec.md](spec.md), permitindo implementação e validação incremental antes da consolidação final do histórico Git da PR #71.

## Format: `[ID] [P?] [Story?] Description with file path`

- **[P]**: Pode executar em paralelo (arquivos distintos, sem dependência de tarefa incompleta na mesma fase)
- **[Story]**: História de usuário associada (`[US1]`, `[US2]`, `[US3]`, `[US4]`) — ausente em Setup, Foundational e Polish

---

## Phase 1: Setup (Auditoria Inicial e Preservação de Ambiente)

**Purpose**: Confirmar estado atual da árvore de trabalho e mapear exata abrangência das alterações antes de editar arquivos.

- [X] T001 Atualizar referências remotas com `git fetch origin` e inventariar arquivos não rastreados pré-existentes (como `app/android/build/`) na raiz `c:\Users\Eduardo\Memora` para preservá-los intactos fora do stage Git
- [X] T002 [P] Mapear todas as ocorrências de CPF real, nomes pessoais de captura e referências a `Gemini` em `scripts/censurar_servicos_sociais.py`, `scripts/processar_guias_visuais.py`, `specs/006-guias-servicos-sociais/`, `specs/009-localizador-servicos/` e `backend/src/`

---

## Phase 2: Foundational (Contratos de Domínio, L10n e Exceções Compartilhadas)

**Purpose**: Infraestrutura compartilhada que desbloqueia as histórias de voz local (`US2`), integração real do Localizador (`US3`) e transparência/backend (`US4`).

**⚠️ CRITICAL**: Concluir esta fase antes de iniciar `US2`, `US3` e `US4`.

- [X] T003 [P] Adicionar `final bool ehDemonstracao` (padrão `false`) e coordenadas opcionais `final double? latitudeRegiao` / `final double? longitudeRegiao` (padrão `null`) em `ResultadoBuscaServicos` (`app/lib/features/localizador/domain/repositorios/repositorio_localizador.dart`), e adicionar constante acolhedora `vozOfflineIndisponivel` em `app/lib/l10n/textos_assistente.dart` orientando digitação pelo teclado ou download do pacote offline em português
- [X] T004 [P] Criar exceção `ProvedorGeograficoIndisponivelException.java` em `backend/src/main/java/br/fatec/memora/localizador/infra/ProvedorGeograficoIndisponivelException.java` para sinalizar indisponibilidade de Nominatim/Overpass (`503`) separadamente de entrada inválida/região não encontrada (`IllegalArgumentException` -> `400`)
- [X] T005 Atualizar `EstabelecimentoServicoDto.deJson` em `app/lib/features/localizador/data/modelos/estabelecimento_servico_dto.dart` para fixar `ehDemonstracao: false` e propagar `latitudeRegiao`/`longitudeRegiao` de `regiaoOrigem` para centralização do mapa sem fallback fixo (depends on T003)

**Checkpoint**: Entidades de domínio compartilhadas, mensagem `l10n` de voz offline e exceção geográfica do servidor prontas.

---

## Phase 3: User Story 1 — Garantir Ausência Total de CPF Real e Materiais Não Licenciados no Repositório e no Histórico (Priority: P1) 🎯 MVP

**Goal**: Expurgar todas as ocorrências do CPF real e nomes pessoais dos scripts e da spec `006`, e remover `Memora-Desing-Ideias/` do rastreamento Git via `.gitignore` + `git rm --cached`.

**Independent Test**: Executar varredura `git grep` por padrão de CPF e nomes pessoais de captura na árvore de trabalho e `git ls-files Memora-Desing-Ideias/`, confirmando `0` ocorrências ativas no índice/arquivos rastreados *(a consolidação final de commits `FR-003` em 1 commit sobre `origin/develop` ocorre após todas as fases de código no Phase 7 para reescrever o histórico uma única vez)*.

### Implementation for User Story 1

- [X] T006 [P] [US1] Substituir CPF real e menções nominais pessoais por placeholders (`XXX.XXX.XXX-XX` e rótulo genérico de titular) preservando integralmente as coordenadas de desfoque em `scripts/censurar_servicos_sociais.py` e `scripts/processar_guias_visuais.py`
- [X] T007 [P] [US1] Substituir todas as ocorrências de CPF real e dados pessoais de captura por `XXX.XXX.XXX-XX` e `"Usuário Exemplo"` nos 6 arquivos afetados de `specs/006-guias-servicos-sociais/` (`spec.md`, `plan.md`, `research.md`, `quickstart.md`, `tasks.md` e `contracts/guias-com-secoes.md`)
- [X] T008 [P] [US1] Adicionar a entrada `Memora-Desing-Ideias/` ao arquivo `.gitignore` na raiz do repositório preservando regras existentes
- [X] T009 [US1] Remover a pasta `Memora-Desing-Ideias/` do índice do controle de versão executando `git rm -r --cached Memora-Desing-Ideias/` mantendo cópias locais ignoradas pelo `.gitignore` (depends on T008)
- [X] T010 [US1] Auditar todos os arquivos rastreados com `git grep -nE "[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}" -- scripts/ specs/006-guias-servicos-sociais/` e `git grep` para os nomes pessoais de captura inventariados em `T002`, além de `git ls-files Memora-Desing-Ideias/`, confirmando saída vazia (depends on T006, T007, T009)

**Checkpoint**: Árvore de trabalho e índice Git completamente limpos de CPF real, nomes pessoais de captura e arquivos de `Memora-Desing-Ideias/`.

---

## Phase 4: User Story 2 — Ditar Perguntas com Voz Processada Apenas no Aparelho (Priority: P1)

**Goal**: Garantir `onDevice: true` obrigatório no `LeitorDeVozSpeechToText`, proibindo qualquer envio de áudio à nuvem, preservando rascunho parcial e exibindo orientação clara quando o pacote offline `pt-BR` estiver indisponível.

**Independent Test**: Executar `flutter test test/features/assistente/ditado_por_voz_test.dart` em `app/` comprovando envio de `SpeechListenOptions(onDevice: true)`, ausência de segunda chamada com `onDevice: false` após erro/recusa e exibição de `TextosAssistente.vozOfflineIndisponivel` sem ocultar o botão *Falar*.

### Tests for User Story 2

- [X] T011 [P] [US2] Adicionar testes em `app/test/features/assistente/ditado_por_voz_test.dart` cobrindo `LeitorDeVozSpeechToText` com dublê de `SpeechToText`: exigir `onDevice: true` em `SpeechListenOptions`, proibir fallback com `onDevice: false` em exceção/falha, retornar `EstadoDitado.indisponivel` com `TextosAssistente.vozOfflineIndisponivel` mantendo o botão de microfone ativo e preservar eventual rascunho parcial (depends on T003)

### Implementation for User Story 2

- [X] T012 [US2] Atualizar `LeitorDeVozSpeechToText.iniciarEscuta(...)` em `app/lib/features/assistente/data/leitor_de_voz_nativo.dart` fixando `onDevice: true` em `SpeechListenOptions` (`partialResults: true`, `listenMode: ListenMode.dictation`, `cancelOnError: true`, `localeId: _localePreferido ?? 'pt_BR'`), bloqueando qualquer retry com `onDevice: false` e retornando `ResultadoDitado(estado: EstadoDitado.indisponivel, mensagem: TextosAssistente.vozOfflineIndisponivel)` diante de indisponibilidade ou exceção de modo offline (depends on T003, T011)
- [X] T013 [US2] Alinhar `_tratarErro` em `app/lib/features/assistente/data/leitor_de_voz_nativo.dart` e tratamento em `app/lib/features/assistente/presentation/controladores/controlador_conversa.dart` para emitir `TextosAssistente.vozOfflineIndisponivel` em erro permanente do motor offline mantendo o rascunho já transcrito no campo sem disparo automático (depends on T012)
- [X] T014 [US2] Executar `flutter test test/features/assistente/ditado_por_voz_test.dart` em `app/` validando `100%` dos cenários de ditado local sem fallback em nuvem (depends on T013)

**Checkpoint**: Ditado por voz estritamente offline (`onDevice: true`) e testável de forma independente no assistente.

---

## Phase 5: User Story 3 — Consultar Serviços Reais no Localizador e Tornar Seguro o Modo Demonstração (Priority: P1)

**Goal**: Conectar o Localizador ao backend autenticado quando `usaServidorReal == true`, eliminar fallbacks silenciosos para Americana - SP nas camadas app e servidor, limpar lista anterior e evitar busca prematura na abertura, e blindar o modo simulado com `telefone: null` e banner explícito de demonstração.

**Independent Test**: Executar suíte backend do controlador/provedor (`LocalizadorControllerTest`, `ProvedorOpenStreetMapOverpassTest`) e suíte Flutter `flutter test test/features/localizador/` comprovando chamada real autenticada a `/v1/servicos/buscar` (com renovação `ChamadaComRenovacao`), falha transparente `503`/`400` sem lista falsa, e modo simulado seguro sem botões de ligação.

### Tests for User Story 3

- [X] T015 [P] [US3] Atualizar `backend/src/test/java/br/fatec/memora/localizador/api/LocalizadorControllerTest.java` cobrindo roteamento `/v1/servicos/buscar` e `/api/v1/servicos/buscar`, resposta `400 Bad Request` e resposta `503 Service Unavailable` diante de `ProvedorGeograficoIndisponivelException` (depends on T004)
- [X] T016 [P] [US3] Criar `backend/src/test/java/br/fatec/memora/localizador/infra/ProvedorOpenStreetMapOverpassTest.java` cobrindo ausência de base de contingência Americana - SP e lançamento de `ProvedorGeograficoIndisponivelException` ou retorno nulo/erro explícito quando Overpass/Nominatim falharem ou não encontrarem a região (depends on T004)
- [X] T017 [P] [US3] Atualizar `app/test/features/localizador/acoes_seguras_test.dart` para usar fixture explícita de `EstabelecimentoServico` com telefone no teste do diálogo de ligação, e criar `app/test/features/localizador/repositorio_localizador_test.dart` cobrindo `FonteLocalizadorApi` (path `/servicos/buscar` vs `/v1`, `Options(extra: {'secure': ...})` e `ChamadaComRenovacao`), `RepositorioLocalizadorApi` (propagação de erro sem fallback simulado), `Composicao.resolver` (`usaServidorReal` true/false) e invariante `telefone == null` + `ehDemonstracao == true` em `RepositorioLocalizadorSimulado` (depends on T003, T005)
- [X] T018 [P] [US3] Expandir `app/test/features/localizador/controlador_localizador_test.dart` e `app/test/features/localizador/tela_localizador_test.dart` cobrindo: ausência de chamada a `buscar()` antes de resposta ao diálogo inicial (`precisaExplicarPermissao == true`), limpeza de lista anterior ao falhar nova busca, ocultação de mensagem de lista vazia junto com erro, remoção do centro fixo de Americana - SP no modo mapa antes da busca, exibição do banner de demonstração em lista e mapa quando `ehDemonstracao == true` e ação *"Tentar novamente"* (depends on T003, T005)

### Backend Implementation for User Story 3

- [X] T019 [US3] Remover `obterBaseDeContingencia(...)` e o retorno padrão `-22.7388, -47.3325` de `geocodificarRegiao(...)` em `backend/src/main/java/br/fatec/memora/localizador/infra/ProvedorOpenStreetMapOverpass.java`, lançando `ProvedorGeograficoIndisponivelException` em erros HTTP/I/O do Nominatim/Overpass e retornando `null` quando a região manual não tiver correspondência (depends on T004, T016)
- [X] T020 [US3] Atualizar `ServicoLocalizador.java` (`backend/src/main/java/br/fatec/memora/localizador/aplicacao/ServicoLocalizador.java`) propagando `IllegalArgumentException` clara quando região manual não puder ser geocodificada e `ProvedorGeograficoIndisponivelException` em indisponibilidade externa (depends on T019)
- [X] T021 [US3] Atualizar `LocalizadorController.java` (`backend/src/main/java/br/fatec/memora/localizador/api/LocalizadorController.java`) com `@RequestMapping({"/v1/servicos", "/api/v1/servicos"})` e mapeamento `HttpStatus.SERVICE_UNAVAILABLE` (`503`) para `ProvedorGeograficoIndisponivelException` (depends on T004, T015, T020)

### App Data & Composition for User Story 3

- [X] T022 [P] [US3] Atualizar `app/lib/features/localizador/data/fontes/fonte_localizador_api.dart` para normalizar path relativo (`/servicos/buscar` se `dio.options.baseUrl` terminar em `/v1` ou `/v1/`, senão `/api/v1/servicos/buscar`), enviar `Options(extra: {'secure': [{'type': 'http', 'scheme': 'bearer'}]})` e aceitar `ChamadaComRenovacao?` para execução autenticada com renovação de token (depends on T005)
- [X] T023 [P] [US3] Remover bloco `catch` com fallback para `RepositorioLocalizadorSimulado` em `app/lib/features/localizador/data/repositorios/repositorio_localizador_api.dart`, propagando falha explícita de comunicação para o controlador (depends on T003)
- [X] T024 [P] [US3] Atualizar `app/lib/features/localizador/data/repositorios/repositorio_localizador_simulado.dart` definindo `telefone: null` em todos os 5 estabelecimentos (incluindo categoria `emergencia`), retornando `ehDemonstracao: true`, e marcando `descricaoRegiao` e `avisoTransparencia` explicitamente como demonstração/exemplo ilustrativo (depends on T003)
- [X] T025 [US3] Expor `final RepositorioLocalizador localizador;` em `Composicao` (`app/lib/services/ambiente/composicao.dart`), instanciando `RepositorioLocalizadorApi` com `api.dio` e `ChamadaComRenovacao` compartilhada quando `ambiente.usaServidorReal == true` e `RepositorioLocalizadorSimulado` quando `false` (depends on T022, T023, T024)
- [X] T026 [US3] Adicionar parâmetro opcional `final RepositorioLocalizador? localizador;` em `FluxoAutenticacao` (`app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`, substituindo `RepositorioLocalizadorSimulado()` hardcoded quando fornecido) e passar `localizador: composicao.localizador` em `AplicativoMemora` (`app/lib/main.dart`) (depends on T025)

### App Presentation for User Story 3

- [X] T027 [US3] Atualizar `ControladorLocalizador` (`app/lib/features/localizador/presentation/controladores/controlador_localizador.dart`) para expor `ehDemonstracao`, limpar `_estabelecimentos` em erro dentro de `buscar()`, armazenar coordenadas da última região válida (`latitudeRegiao`/`longitudeRegiao`) e limpar erro ao iniciar nova busca (depends on T005)
- [X] T028 [US3] Atualizar `TelaLocalizador` (`app/lib/features/localizador/presentation/telas/tela_localizador.dart`) utilizando tokens do Design System 2.0 mantendo a camada agnóstica ao repositório concreto: não chamar `buscar()` em `initState()` enquanto `precisaExplicarPermissao == true` nem ao cancelar o diálogo sem região (acionando `buscar()` apenas após concessão do GPS, definição de região manual ou ação explícita de busca/filtro na tela); exibir banner destacado de modo demonstração acima do corpo em Lista e Mapa quando `c.ehDemonstracao == true`; ocultar texto de lista vazia quando `c.mensagemErro != null`; e remover coordenadas fixas de Americana - SP (`-22.7388, -47.3325`) do `centroInicial` do mapa quando não houver posição/região carregada (depends on T026, T027)
- [X] T029 [US3] Executar testes do Localizador no backend e Flutter (`./mvnw --batch-mode test -Dtest=LocalizadorControllerTest,ProvedorOpenStreetMapOverpassTest,ServicoLocalizadorTest` em `backend/` e `flutter test test/features/localizador/` em `app/`) (depends on T017, T018, T021, T028)

**Checkpoint**: Localizador conectado ao backend real autenticado em `usaServidorReal == true`, zero dados fictícios de contingência e modo simulado seguro sem telefones discáveis.

---

## Phase 6: User Story 4 — Transparência OpenStreetMap, Nomenclatura Honesta e Alinhamento Specs/CI (Priority: P2)

**Goal**: Garantir transparência explícita do uso público do OpenStreetMap no diálogo de permissão e busca manual, cabeçalho `User-Agent` legítimo e fila `<= 1 req/s` no Nominatim com timeouts explícitos (`5s`/`6s`), renomear honestamente `InterpretadorDeIntencaoComGemini` para `InterpretadorDeIntencaoPorPalavrasChave`, atualizar status das specs `006`/`007`/`009` e manter CI Flutter `3.47.7` sem `--no-fatal-infos`.

**Independent Test**: Executar `./mvnw --batch-mode test` validando fila `>= 1000 ms`, `User-Agent` e ausência de referências a Gemini no backend, rodar `flutter test test/features/localizador/tela_localizador_test.dart` conferindo transparência OSM em ambos os modais, e inspecionar `.github/workflows/verificacao.yml` e status em `006`/`007`/`009`.

### Tests for User Story 4

- [X] T030 [P] [US4] Renomear `backend/src/test/java/br/fatec/memora/localizador/aplicacao/InterpretadorDeIntencaoComGeminiTest.java` para `backend/src/test/java/br/fatec/memora/localizador/aplicacao/InterpretadorDeIntencaoPorPalavrasChaveTest.java` e atualizar referências em `backend/src/test/java/br/fatec/memora/localizador/aplicacao/ServicoLocalizadorTest.java`
- [X] T031 [P] [US4] Expandir `backend/src/test/java/br/fatec/memora/localizador/infra/ProvedorOpenStreetMapOverpassTest.java` validando header `User-Agent` `Memora-Fatec/1.0 (+https://github.com/Edudu720/Memora)`, enfileiramento sincronizado garantindo intervalo mínimo `>= 1000 ms` no Nominatim via relógio/limitador injetável (incluindo chamadas concorrentes) e respeito aos timeouts (`5s` Nominatim/conexão; `6s` Overpass HTTP) (depends on T016)
- [X] T032 [P] [US4] Expandir `app/test/features/localizador/tela_localizador_test.dart` validando menção explícita à consulta pública no OpenStreetMap (sem envio de dados pessoais da conta nem histórico) tanto no `DialogoPermissaoLocalizacao` quanto no modal `_solicitarRegiaoManual` (depends on T018)

### Implementation for User Story 4

- [X] T033 [US4] Renomear `InterpretadorDeIntencaoComGemini.java` para `InterpretadorDeIntencaoPorPalavrasChave.java` em `backend/src/main/java/br/fatec/memora/localizador/aplicacao/` e atualizar sua injeção e imports em `backend/src/main/java/br/fatec/memora/localizador/aplicacao/ServicoLocalizador.java` (depends on T020, T030)
- [X] T034 [US4] Atualizar `backend/src/main/java/br/fatec/memora/localizador/infra/ProvedorOpenStreetMapOverpass.java` configurando `User-Agent: Memora-Fatec/1.0 (+https://github.com/Edudu720/Memora)`, limitador de frequência sincronizado por processo garantindo espera mínima de `1000 ms` entre chamadas sequenciais/concorrentes ao Nominatim (`Clock`/controlador e URLs base injetáveis para teste), além dos timeouts explícitos (`5s` `connectTimeout`/Nominatim; `6s` Overpass HTTP e `[timeout:5]` na query) (depends on T019, T031)
- [X] T035 [US4] Atualizar texto de `DialogoPermissaoLocalizacao` (`app/lib/features/localizador/presentation/widgets/dialogo_permissao_localizacao.dart`) e texto orientativo no modal `_solicitarRegiaoManual` (`app/lib/features/localizador/presentation/telas/tela_localizador.dart`) declarando consulta pontual à base pública OpenStreetMap sem envio de dados pessoais da conta nem registro de histórico (depends on T028, T032)
- [X] T036 [P] [US4] Atualizar metadados de `Status` em `specs/006-guias-servicos-sociais/spec.md` (`Implementado — mesclado em develop`), `specs/007-redesenho-visual-profissional/spec.md` (`Implementado — mesclado em develop`), `specs/009-localizador-servicos/spec.md` (`Em Revisão — PR #71`, acrescentando nota de reconciliação declarando substituição de `InterpretadorDeIntencaoComGemini` por `InterpretadorDeIntencaoPorPalavrasChave` sem uso do Gemini) e `specs/010-revisao-pr71-localizador/spec.md` (`Implementado — pronto para revisão final na PR #71`)
- [X] T037 [P] [US4] Atualizar `.github/workflows/verificacao.yml` mantendo `flutter-version: '3.47.7'` (sem chaves duplicadas) nos jobs `app` e `cliente-gerado`, removendo `--no-fatal-infos` do comando `flutter analyze` e preservando `dart analyze` + `dart test` no job `cliente-gerado`
- [X] T038 [US4] Executar verificação da US4: `./mvnw --batch-mode test` em `backend/`, `flutter test test/features/localizador/tela_localizador_test.dart` em `app/` e `git grep InterpretadorDeIntencaoComGemini -- backend/` garantindo retorno vazio (depends on T033, T034, T035)

**Checkpoint**: Transparência OpenStreetMap, compliance Nominatim/Overpass, nomenclatura honesta no backend e alinhamento specs/CI concluídos e testados.

---

## Phase 7: Polish, Cross-Cutting Gates, Git History Rewrite & PR #71 Update

**Purpose**: Executar todos os portões automatizados do projeto, consolidar o histórico Git em 1 commit limpo sobre `origin/develop` (`FR-003`) erradicando definitivamente qualquer PII de histórico, reauditar e atualizar a PR #71.

- [X] T039 [P] Executar validadores do Design System na raiz `c:\Users\Eduardo\Memora`: `python specs/002-design-system/ferramentas/validar_paleta.py --autoteste`, `python specs/002-design-system/ferramentas/validar_paleta.py`, `python specs/002-design-system/ferramentas/validar_tokens.py --autoteste` e `python specs/002-design-system/ferramentas/validar_tokens.py` (depends on T028, T035)
- [X] T040 [P] Executar `flutter analyze` estrito e `flutter test` completo em `app/`, além de `dart analyze` e `dart test` em `app/pacotes/memora_api/` (depends on T014, T029, T038)
- [X] T041 [P] Executar suíte backend completa `./mvnw --batch-mode test` em `backend/` seguindo integralmente as checagens de `specs/010-revisao-pr71-localizador/quickstart.md` (depends on T038)
- [X] T042 Consolidar (`squash`) o estado limpo e aprovado da branch `feature/009-localizador-servicos` em **1 único commit limpo diretamente sobre `origin/develop`** usando formato **Conventional Commits** conforme Constituição (`fix(localizador,assistente): ...`: `git fetch origin`, `git reset --soft origin/develop`, revisar `git status` garantindo exclusão de `Memora-Desing-Ideias/` e de diretórios não rastreados como `app/android/build/`, e criar o commit consolidado) (depends on T010, T036, T037, T039, T040, T041)
- [X] T043 Executar auditoria pós-squash conforme `quickstart.md §V1`: confirmar `0` ocorrências em `git grep -nE "[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}"`, `0` ocorrências do CPF real e nomes pessoais de captura em `git log origin/develop..feature/009-localizador-servicos -G ...` (e `git grep` nos arquivos ativos), `0` itens de `Memora-Desing-Ideias/` em `git ls-files` e `git rev-list --objects origin/develop..feature/009-localizador-servicos`, e contagem exata `1` em `git rev-list --count origin/develop..feature/009-localizador-servicos` (depends on T042)
- [X] T044 Revalidar suítes completas pós-commit final (`flutter analyze`, `flutter test`, `dart analyze`/`dart test`, `./mvnw --batch-mode test`, `validar_paleta.py` e `validar_tokens.py`) e atualizar a PR #71 remotamente via `git push --force-with-lease origin feature/009-localizador-servicos` (depends on T043)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sem dependências — inicia imediatamente.
- **Phase 2 (Foundational)**: Depende da Phase 1 — **bloqueia `US2`, `US3` e `US4`**.
- **Phase 3 (`US1` — P1 MVP Privacidade)**: Pode rodar em paralelo com Phase 2 (arquivos de scripts, `specs/006`, `.gitignore` não colidem com `T003`–`T005`).
- **Phase 4 (`US2` — P1 Voz Local)**: Depende de `T003` (Phase 2); independente de `US1`, `US3` e `US4`.
- **Phase 5 (`US3` — P1 Localizador Real & Demo Seguro)**: Depende de `T003`, `T004`, `T005` (Phase 2); independente de `US2`.
- **Phase 6 (`US4` — P2 OpenStreetMap, Nomenclatura, Specs & CI)**: Depende de `T016`/`T018`/`T019`/`T020`/`T028` nos pontos compartilhados (`ProvedorOpenStreetMapOverpass`, `ServicoLocalizador`, `TelaLocalizador`), enquanto `T030`, `T036` e `T037` são paralelizáveis desde cedo.
- **Phase 7 (Polish & Squash Git)**: Depende da conclusão integral de todas as histórias (`US1`–`US4`) antes de reescrever o histórico com `squash` único sobre `origin/develop`.

### User Story Independence

- **US1 (P1)**: Entregue e verificável na árvore de trabalho e índice Git sem depender de `US2`, `US3` ou `US4`.
- **US2 (P1)**: Entregue e verificável de forma isolada em `test/features/assistente/ditado_por_voz_test.dart`.
- **US3 (P1)**: Entregue e verificável de forma isolada em backend (`LocalizadorControllerTest`, `ProvedorOpenStreetMapOverpassTest`) e app (`test/features/localizador/`).
- **US4 (P2)**: Completa conformidade OpenStreetMap, nomenclatura e governança CI/specs sobre o módulo Localizador sem alterar regras de negócio de `US1`/`US2`.

### Parallel Opportunities per User Story

```text
# US1 (após T002): executar em paralelo expurgo de scripts, expurgo de spec 006 e edição do .gitignore
Task: T006 [P] [US1] -> scripts/censurar_servicos_sociais.py & scripts/processar_guias_visuais.py
Task: T007 [P] [US1] -> specs/006-guias-servicos-sociais/*
Task: T008 [P] [US1] -> .gitignore

# US3 (após Phase 2): lançar os 4 blocos de teste em paralelo antes da implementação
Task: T015 [P] [US3] -> backend/.../LocalizadorControllerTest.java
Task: T016 [P] [US3] -> backend/.../ProvedorOpenStreetMapOverpassTest.java
Task: T017 [P] [US3] -> app/test/features/localizador/acoes_seguras_test.dart & repositorio_localizador_test.dart
Task: T018 [P] [US3] -> app/test/features/localizador/controlador_localizador_test.dart & tela_localizador_test.dart

# US3 App Data (após T003/T005): paralelo nos arquivos distintos de dados
Task: T022 [P] [US3] -> fonte_localizador_api.dart
Task: T023 [P] [US3] -> repositorio_localizador_api.dart
Task: T024 [P] [US3] -> repositorio_localizador_simulado.dart

# US4 governança & renomeação de testes (paralelo)
Task: T030 [P] [US4] -> InterpretadorDeIntencaoPorPalavrasChaveTest.java & ServicoLocalizadorTest.java
Task: T036 [P] [US4] -> specs/006, 007, 009 status + reconciliação
Task: T037 [P] [US4] -> .github/workflows/verificacao.yml
```

---

## Implementation Strategy

### MVP First (Bloqueadores P1 em ordem de risco)

1. Concluir Phase 1 + Phase 2 (`T001`–`T005`).
2. Concluir **US1 (`T006`–`T010`)** eliminando PII ativo e `Memora-Desing-Ideias/` do controle de versão.
3. Concluir **US2 (`T011`–`T014`)** garantindo ditado estritamente `onDevice: true`.
4. Concluir **US3 (`T015`–`T029`)** conectando o Localizador real e blindando o modo simulado (`telefone: null`, sem fallback fake).
5. **STOP & VALIDATE**: Validar todos os 3 bloqueadores P1 via suítes locais.

### Full PR #71 Delivery (`P1 + P2 + Squash Limpo`)

6. Concluir **US4 (`T030`–`T038`)** (OpenStreetMap `User-Agent`/rate limit, `InterpretadorDeIntencaoPorPalavrasChave`, specs `006`/`007`/`009`, CI `3.47.7`).
7. Concluir **Phase 7 (`T039`–`T044`)**: portões Python/Dart/Maven -> **1 commit limpo sobre `origin/develop`** -> auditoria de histórico zero-PII -> `--force-with-lease` para atualizar a PR #71.

---

## Summary Metadata

- **Total de tarefas**: **44** (`T001`–`T044`)
- **Distribuição por fase/história**:
  - Setup (Phase 1): `2` tarefas (`T001`–`T002`)
  - Foundational (Phase 2): `3` tarefas (`T003`–`T005`)
  - US1 — Privacidade PII & Desing-Ideias (P1 MVP): `5` tarefas (`T006`–`T010`)
  - US2 — Voz Estritamente Local (P1): `4` tarefas (`T011`–`T014`)
  - US3 — Localizador Real & Demo Seguro (P1): `15` tarefas (`T015`–`T029`)
  - US4 — OpenStreetMap, Nomenclatura, Specs & CI (P2): `9` tarefas (`T030`–`T038`)
  - Polish, Git Squash & Push Seguro (Phase 7): `6` tarefas (`T039`–`T044`)


---

## Phase 8: Convergence

- [X] T045 [CRITICAL] Corrigir violações de acessibilidade no módulo Localizador: adicionar texto visível acompanhando o ícone de alternância Mapa/Lista na `BarraSuperior` (`app/lib/features/localizador/presentation/telas/tela_localizador.dart`) e nos botões de zoom (`app/lib/features/localizador/presentation/widgets/mapa_servicos_acessivel.dart`), além de elevar o espaçamento entre alvos de toque adjacentes de `MemoraEspacamento.xs` (`4 dp`) para `>= MemoraEspacamento.sm` (`8 dp`) em `_solicitarRegiaoManual` (`tela_localizador.dart`), `CartaoEstabelecimento` (`app/lib/features/localizador/presentation/widgets/cartao_estabelecimento.dart`) e `MapaServicosAcessivel`, cobrindo a conformidade em testes de widget (`app/test/features/localizador/tela_localizador_test.dart`) per Constitution III (contradicts)
- [X] T046 Expandir `backend/src/test/java/br/fatec/memora/localizador/infra/ProvedorOpenStreetMapOverpassTest.java` cobrindo chamadas concorrentes ao Nominatim com espaçamento sincronizado `>= 1000 ms`, presença de `[timeout:5]` na query Overpass e conversão de expiração de timeout HTTP (`5s`/`6s`) em `ProvedorGeograficoIndisponivelException` per FR-010 (partial)
- [X] T047 Extrair `tags.path("addr:state").asText(null)` em vez do literal fixo `"SP"` ao montar `Endereco` em `ProvedorOpenStreetMapOverpass.parsearElementosOverpass` (`backend/src/main/java/br/fatec/memora/localizador/infra/ProvedorOpenStreetMapOverpass.java`) e validar endereços fora de SP em `backend/src/test/java/br/fatec/memora/localizador/infra/ProvedorOpenStreetMapOverpassTest.java` per FR-007 (contradicts)
- [X] T048 Evitar chamada imediata a `buscar()` em `ControladorLocalizador.autorizarPermissaoEBuscar()` (`app/lib/features/localizador/presentation/controladores/controlador_localizador.dart`) quando a permissão for negada/indisponível e não houver coordenadas nem `regiaoManual`, apenas notificando a tela para convidar a busca manual, com teste unitário em `app/test/features/localizador/controlador_localizador_test.dart` per FR-007 (partial)
- [X] T049 Adicionar cobertura HTTP/Segurança via `MockMvc` em `backend/src/test/java/br/fatec/memora/localizador/api/LocalizadorControllerTest.java` validando exigência de token Bearer (`401 Unauthorized`), despacho nas rotas `/v1/servicos/buscar` e `/api/v1/servicos/buscar` e serialização JSON para retornos `200`, `400` e `503` per Constitution I (partial)
