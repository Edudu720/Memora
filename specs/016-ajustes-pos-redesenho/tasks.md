# Tasks: Ajustes Pós-Redesenho — Issue #106 (@Du3101)

**Input**: Design documents from `/specs/016-ajustes-pos-redesenho/`  
**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required for user stories), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Regressões e validações de contrato fazem parte explícita dos requisitos da Issue #106 e de [spec.md](spec.md) (`SC-001`–`SC-008`, `checklists/revisao-pr.md` 24/24).

**Organization**: As tarefas estão organizadas por história de usuário para permitir implementação e validação independentes, em ordem de prioridade (`P1` -> `P2`).

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência em tarefa incompleta)
- **[Story]**: História de usuário correspondente (`US1`, `US2`, `US3`, `US4`, `US5`)
- Todos os caminhos são relativos à raiz do repositório (`c:\Users\Eduardo\Memora`)

## Path Conventions

- **Aplicativo móvel**: `app/lib/`, `app/assets/`, `app/android/`, `app/test/`, `app/pubspec.yaml`
- **Materiais de captura higienizados**: `apps/<Serviço>/`
- **Especificações e ferramentas**: `specs/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Conferir linha de base limpa na branch `feature/016-ajustes-pos-redesenho` e configurar declarações compartilhadas de assets e permissões de esquema no Android.

- [X] T001 Executar verificação de linha de base (`flutter analyze`, `flutter test` e `py specs/002-design-system/ferramentas/validar_tokens.py`) a partir de `app/` e da raiz do repositório na branch `feature/016-ajustes-pos-redesenho`
- [X] T002 [P] Criar `app/assets/icones_apps/.gitkeep`, declarar `- assets/icones_apps/` na seção `flutter.assets` e remover o comentário residual `"Wokwi"` (linha 74) em `app/pubspec.yaml` (garante diretório existente para os checkpoints anteriores a T028)
- [X] T003 [P] Adicionar `<intent>` com `android:name="android.intent.action.VIEW"` e `<data android:scheme="https"/>` dentro do bloco `<queries>` em `app/android/app/src/main/AndroidManifest.xml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Preparar a atualização do orçamento global de guias e a infraestrutura de URL oficial `https://` em `Ambiente` / `AbridorDeSiteTutorial` antes das histórias dependentes.

**⚠️ CRITICAL**: As tarefas bloqueantes desta fase liberam os contratos de guias (`US3`) e o acesso seguro ao site tutorial (`US5`).

- [X] T004 [P] Atualizar o teto global de `app/assets/guias/` de `8 MB` para `12 MB` (`12 * 1024 * 1024` bytes) em `app/test/features/aprendizado/catalogo_e_guias_test.dart`, `app/assets/guias/CAPTURAS.md` e `specs/004-redesenho-das-telas/contracts/guias.md` sem alterar ativos de outros colaboradores
- [X] T005 [P] Adicionar o campo imutável `final String? urlSiteTutorial;` lido via `const String.fromEnvironment('MEMORA_URL_SITE_TUTORIAL')` e filtrado por `Ambiente.enderecoOficial(...)` (somente `https://`, exige `host.isNotEmpty`, rejeita `userInfo.isNotEmpty`, espaços ou string vazia devolvendo `null`) em `app/lib/services/ambiente/ambiente.dart`
- [X] T006 Criar `AbridorDeSiteTutorial` (`String get endereco; Future<bool> abrir(); static AbridorDeSiteTutorial? doAmbiente(Ambiente ambiente)`), `AbridorDeSiteTutorialUrlLauncher` (`LaunchMode.externalApplication`, revalidação defensiva via `Ambiente.enderecoOficial` e retorno `false` em exceção) e `AbridorDeSiteTutorialSimulado` (`abertos`, `falharNoProximo`) em `app/lib/features/ajuda/data/abridor_site_tutorial.dart` (depende de T005)

**Checkpoint**: Fundações prontas — `US1`, `US2`, `US3`, `US4` e `US5` podem avançar conforme suas dependências.

---

## Phase 3: User Story 1 - Testar o alerta de queda com o dispositivo físico e remover referências ao Wokwi (Priority: P1) 🎯 MVP

**Goal**: Fazer o botão *"Simular queda"* iniciar localmente e em menos de 1 segundo o fluxo completo e cancelável de verificação de queda também com `ProvedorDeTelemetriaMqtt` (ESP32 físico conectado ou desconectado), protegido contra duplo toque, e eliminar todas as menções residuais ao Wokwi.

**Independent Test**: Executar `flutter test test/features/cuidado/presentation/tela_dispositivo_cuidado_test.dart` em `app/` (com a suíte comprovando que o teste de regressão falha quando a guarda antiga `is ProvedorDeTelemetriaSimulado` é restaurada) e rodar `git grep -in "wokwi" -- app/` retornando zero ocorrências.

### Tests for User Story 1

> **NOTE: Escrever estes testes PRIMEIRO garantindo que o cenário do provedor MQTT REPROVE antes da correção**

- [X] T007 [P] [US1] Adicionar testes de regressão em `app/test/features/cuidado/presentation/tela_dispositivo_cuidado_test.dart` cobrindo: `simularQuedaTeste()` com `ProvedorDeTelemetriaMqtt` conectado e desconectado abrindo `TelaVerificacaoQueda` (< 1 s, sem falha silenciosa), toque duplo rápido sem empilhar duas telas de verificação, cancelamento em *"Estou bem"* sem disparar emergência e preservação do modo `ProvedorDeTelemetriaSimulado`

### Implementation for User Story 1

- [X] T008 [P] [US1] Remover os comentários residuais `"Wokwi"` deixando explícito apenas ESP32 físico via MQTT e simulador local em `app/lib/features/cuidado/domain/entidades/enums_cuidado.dart` (linha 33) e `app/lib/features/cuidado/domain/repositorios/provedor_telemetria.dart` (linha 6)
- [X] T009 [US1] Corrigir `ControladorDispositivoCuidado.simularQuedaTeste()` em `app/lib/features/cuidado/presentation/controladores/controlador_dispositivo_cuidado.dart` mantendo delegação a `ProvedorDeTelemetriaSimulado.simularQueda()`, emitindo `EventoQueda.novo(bpm: _dispositivo.ultimaTelemetria?.bpm ?? 72, aceleracao: 2.8)` em `_quedaAtiva` + `notifyListeners()` para `ProvedorDeTelemetriaMqtt` e demais provedores, adicionando guarda `if (_quedaAtiva != null) return;` contra reentrância e removendo `"Wokwi"` da linha 93 (depende de T007)
- [X] T010 [US1] Adicionar trava `_verificacaoQuedaAberta` ao empilhar `TelaVerificacaoQueda` via `Navigator.of(context).push<void>(...).whenComplete(...)` evitando modais duplicados em `app/lib/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart` (depende de T009)
- [X] T011 [US1] Validar a história executando `flutter test test/features/cuidado/` em `app/` e `git grep -in "wokwi" -- app/` (zero ocorrências)

**Checkpoint**: User Story 1 completa, testada com regressão comprovada e 100% livre de referências ao Wokwi.

---

## Phase 4: User Story 2 - Remover retratos indesejados de Meu Perfil com retorno seguro ao padrão (Priority: P1)

**Goal**: Remover os dois retratos descontinuados (`casalIdoso` e `pessoaComCelular`) da escolha de retrato em Meu Perfil, garantindo retorno transparente ao retrato padrão neutro quando o armazenamento local possuir qualquer uma das chaves antigas.

**Independent Test**: Executar `flutter test test/features/perfil/foto_de_perfil_local_test.dart test/features/perfil/foto_perfil_widget_test.dart test/features/autenticacao/saida_limpa_armazenamento_test.dart` em `app/` verificando grade com exatamente 4 avatares, leitura de JSON legado `"casal_idoso"` / `"pessoa_com_celular"` retornando `null` (retrato padrão neutro) e nova seleção funcionando sem erros.

### Tests for User Story 2

- [X] T012 [P] [US2] Atualizar fixtures de avatar e adicionar casos explícitos injetando JSON legado `{"tipo":"avatar","avatar":"casal_idoso"}` e `{"tipo":"avatar","avatar":"pessoa_com_celular"}` no `SharedPreferences` (confirmando retorno `null` em `ler()`, exibição do retrato padrão neutro sem erro e possibilidade de escolher novo retrato) e assertiva de exatamente 4 avatares na folha em `app/test/features/perfil/foto_de_perfil_local_test.dart`, `app/test/features/perfil/foto_perfil_widget_test.dart` e `app/test/features/autenticacao/saida_limpa_armazenamento_test.dart`

### Implementation for User Story 2

- [X] T013 [P] [US2] Remover `casalIdoso` e `pessoaComCelular` do enum `AvatarIlustrado` mantendo apenas `memoraAcenando`, `memoraPensando`, `memoraComemorando` e `memoraProtegendo` com retorno `null` para chaves desconhecidas em `AvatarIlustrado.porChave(...)` em `app/lib/features/perfil/domain/retrato_de_perfil.dart`
- [X] T014 [P] [US2] Remover as constantes não utilizadas `TextosPerfil.avatarCasalIdoso` e `TextosPerfil.avatarPessoaComCelular` em `app/lib/l10n/textos_perfil.dart`
- [X] T015 [US2] Atualizar `DesenhoAvatarIlustrado` para switch exaustivo sobre as 4 poses de `MemoraAnimada` em `app/lib/features/perfil/presentation/widgets/retrato_do_perfil.dart`, preservando intactos `Ilustracao.casalIdoso`, `Ilustracao.pessoaComCelular` e `app/assets/ilustracoes/` (depende de T013, T014)
- [X] T016 [US2] Validar a história executando `flutter test test/features/perfil/foto_de_perfil_local_test.dart test/features/perfil/foto_perfil_widget_test.dart test/features/autenticacao/saida_limpa_armazenamento_test.dart test/design_system/ilustracao_e_destaque_test.dart` em `app/`

**Checkpoint**: User Story 2 completa e testada — retratos aposentados removidos com fallback seguro validado para contas legadas.

---

## Phase 5: User Story 3 - Exibir capturas reais nos guias passo a passo e ícones vetoriais dos aplicativos (Priority: P1)

**Goal**: Substituir os 7 guias provisórios pelas 66 capturas reais higienizadas de `apps/` em WebP qualidade 92, com destaques medidos com grade visual sobre as imagens limpas, seções `SecaoDoGuia` nos guias > 7 passos, `CAPTURAS.md` atualizado e 7 ícones vetoriais autocontidos em `app/assets/icones_apps/<chave>.svg`.

**Independent Test**: Executar `flutter test test/features/aprendizado/ test/design_system/icone_do_aplicativo_test.dart` em `app/`, confirmando 0 capturas pendentes/órfãs, <= 12 MB em `assets/guias/`, seções válidas (3–7 passos), `CAPTURAS.md` atualizado, catálogo espelhado intacto e renderização dos 7 SVGs nos temas claro, escuro e alto contraste.

### Conversão das Capturas, Contratos de Guia e Textos (Item 5)

- [X] T017 [US3] Auditar visualmente todas as 66 imagens de `apps/` (`INSS`: 19, `TikTok`: 6, `CNH`: 10, `CLT`: 10, `Poupatempo`: 10, `YouTube`: 7, `GoogleFotos`: 4) quanto a PII, rostos reais, senhas em branco e ausência de marcações pintadas, e convertê-las via Pillow para WebP (`quality=92`, `method=6`, largura máxima `1080 px` sem *upscale*) gravando `passo_1..N.webp` (sem arquivos sobrando) em `app/assets/guias/meu-inss/`, `app/assets/guias/tiktok/`, `app/assets/guias/carteira-digital/`, `app/assets/guias/carteira-de-trabalho/`, `app/assets/guias/poupatempo/`, `app/assets/guias/youtube/` e `app/assets/guias/google-fotos/` (depende de T004)
- [X] T018 [US3] Declarar todas as constantes estáticas nomeadas em `CapturaDoGuia` (`meuInss1..19`, `tiktok1..6`, `carteiraDigital1..10`, `carteiraDeTrabalho1..10`, `poupatempo1..10`, `youtube1..7`, `googleFotos1..4`, todas `FormatoDaCaptura.webp`) em `app/lib/features/aprendizado/domain/guia.dart` (depende de T017)
- [X] T019 [US3] Definir todos os títulos de seções, subtítulos, textos de passo (`<= 2` frases curtas no imperativo gentil dizendo **onde** tocar, zero emojis, gênero neutro, aviso oficial de senha para passos com `temCampoDeSenha: true`) e `descricaoDaCaptura` não vazia dos 7 guias em `app/lib/l10n/textos_guias.dart` (depende de T017)
- [X] T020 [P] [US3] Medir `RegiaoRelativa` sobre imagem limpa com grade visual e atualizar os `6` passos lineares do **TikTok** em `app/lib/features/aprendizado/data/guias/tiktok.dart` (depende de T018, T019)
- [X] T021 [P] [US3] Medir `RegiaoRelativa` sobre imagem limpa com grade visual e atualizar os `7` passos lineares do **YouTube** em `app/lib/features/aprendizado/data/guias/youtube.dart` (depende de T018, T019)
- [X] T022 [P] [US3] Medir `RegiaoRelativa` sobre imagem limpa com grade visual e atualizar os `4` passos lineares do **Google Fotos** em `app/lib/features/aprendizado/data/guias/google_fotos.dart` (depende de T018, T019)
- [X] T023 [P] [US3] Medir `RegiaoRelativa` sobre imagem limpa com grade visual e reestruturar **Meu INSS** (`19` capturas organizadas em `4` `SecaoDoGuia` com `3`–`7` passos por seção, `chave` única por seção, `passos` raiz vazio e `precisaTerEmMaos` preservado) em `app/lib/features/aprendizado/data/guias/meu_inss.dart` (depende de T018, T019)
- [X] T024 [P] [US3] Medir `RegiaoRelativa` sobre imagem limpa com grade visual e reestruturar **Carteira Digital de Trânsito / CNH** (`10` capturas organizadas em `2` `SecaoDoGuia` com `3`–`7` passos por seção, `chave` única por seção, `passos` raiz vazio e `precisaTerEmMaos` preservado) em `app/lib/features/aprendizado/data/guias/carteira_digital.dart` (depende de T018, T019)
- [X] T025 [P] [US3] Medir `RegiaoRelativa` sobre imagem limpa com grade visual e reestruturar **Carteira de Trabalho Digital / CLT** (`10` capturas organizadas em `2` `SecaoDoGuia` com `3`–`7` passos por seção, `chave` única por seção, `passos` raiz vazio e `precisaTerEmMaos` preservado) em `app/lib/features/aprendizado/data/guias/carteira_de_trabalho.dart` (depende de T018, T019)
- [X] T026 [P] [US3] Medir `RegiaoRelativa` sobre imagem limpa com grade visual e reestruturar **Poupatempo** (`10` capturas organizadas em `2` `SecaoDoGuia` com `3`–`7` passos por seção, `chave` única por seção, `passos` raiz vazio, `precisaTerEmMaos` preservado e passo da tela de senha marcada com `temCampoDeSenha: true`) em `app/lib/features/aprendizado/data/guias/poupatempo.dart` (depende de T018, T019)
- [X] T027 [US3] Atualizar as 7 linhas (`meu-inss`, `tiktok`, `carteira-digital`, `carteira-de-trabalho`, `poupatempo`, `youtube`, `google-fotos`) na tabela de registro (data, versão do app e origem/aparelho real das capturas) em `app/assets/guias/CAPTURAS.md` (depende de T020–T026)

### Ícones Vetoriais SVG Compartilhados e Validação (Item 6)

- [X] T028 [P] [US3] Criar os 7 SVGs autocontidos (`viewBox="0 0 48 48"`, contraste `>= 3:1`, sem `<script>`, sem `<image>`/`http`, sem `<text>` dependente de fonte do aparelho) em `app/assets/icones_apps/meu-inss.svg`, `app/assets/icones_apps/tiktok.svg`, `app/assets/icones_apps/carteira-digital.svg`, `app/assets/icones_apps/carteira-de-trabalho.svg`, `app/assets/icones_apps/poupatempo.svg`, `app/assets/icones_apps/youtube.svg` e `app/assets/icones_apps/google-fotos.svg`, e atualizar `app/lib/design_system/componentes/ilustracao/icone_do_aplicativo.dart` com mapa constante `_iconesSvgPorChave` + `SvgPicture.asset`, removendo `_TrianguloBrancoPainter` e mantendo intactos os 6 PNGs e os 3 ramos de `@Henrique-Sandrini` (`instagram`, `e-titulo`, `fgts`) (depende de T002)
- [X] T029 [US3] Criar testes de renderização e fallback em `app/test/design_system/icone_do_aplicativo_test.dart` (os 7 SVGs carregam sem erro em tema claro, escuro e alto contraste) e validar `flutter test test/features/aprendizado/ test/design_system/icone_do_aplicativo_test.dart` em `app/` (depende de T027, T028)

**Checkpoint**: User Story 3 completa — todas as 66 capturas reais, destaques, registros e 7 SVGs oficiais integrados e aprovados nos portões de contrato.

---

## Phase 6: User Story 4 - Melhorar e otimizar a tela Meu Perfil (Priority: P2)

**Goal**: Reorganizar `TelaPerfil` em cartões claros e acessíveis (*Seu retrato*, *Sua conta*, *Seu aprendizado*, além de `SecaoIdade`), otimizar a resolução de nomes (`O(1)`) e proteção contra leitura obsoleta em troca de conta, mantendo 0 chamadas de rede e slot opcional compatível para `ultimoModuloConcluido` (Item 14).

**Independent Test**: Executar `flutter test test/features/perfil/` em `app/` e `py specs/002-design-system/ferramentas/validar_tokens.py`, validando 0 chamadas de rede, unicidade de `widget.nome`, semântica `isButton: false` nos campos informativos, slot `ultimoModuloConcluido` oculto quando nulo e visível quando preenchido, e zero overflow a `200%` em `320×568`.

### Implementation & Tests for User Story 4

- [X] T030 [P] [US4] Adicionar os títulos e apoios curtos das seções de Meu Perfil (*Seu retrato*, *Sua conta*, *Seu aprendizado* e rótulo reservado *Último módulo concluído*, `<= 2` frases curtas, zero emojis, gênero neutro e sem termos proibidos) em `app/lib/l10n/textos_perfil.dart`
- [X] T031 [US4] Reorganizar e otimizar `TelaPerfil` em `app/lib/features/perfil/presentation/tela_perfil.dart` conforme `contracts/ajuda-e-perfil.md §2`: agrupar em cartões temáticos com `Semantics(header: true)`, manter todas as chaves existentes (`chaveLista`, `chaveNome`, `chaveCanal`, `chaveMaisAprendido`, `chaveDesenho`), adicionar `chaveSecaoAprendizado`, `chaveUltimoModulo` e `final String? ultimoModuloConcluido;` (renderizando `chaveUltimoModulo` somente quando não nulo/vazio), indexar catálogo em mapa estático `O(1)`, descartar leituras assíncronas se `idDaConta` mudou, eliminar `'...'` ruidoso na carga inicial, manter `widget.nome` em **apenas um** `Text` visível e preservar `CampoInformacao` com `isButton: false` / sem `InkWell` e 0 requisições de rede (depende de T030)
- [X] T032 [US4] Expandir `app/test/features/perfil/tela_perfil_test.dart` cobrindo organização em cartões com `Semantics(header: true)`, `0` chamadas no `_RepositorioEspiao`, `ultimoModuloConcluido` oculto quando nulo e exibido como informação não clicável quando fornecido, descarte seguro em troca rápida de `idDaConta` e layout em `320×568` com ampliação de `200%` sem overflow (depende de T031)
- [X] T033 [US4] Validar a história executando `flutter test test/features/perfil/` em `app/` e `py specs/002-design-system/ferramentas/validar_tokens.py`

**Checkpoint**: User Story 4 completa — Meu Perfil otimizado, acessível a 200%, 100% local e pronto para encaixe do Item 14.

---

## Phase 7: User Story 5 - Abrir o site oficial de tutoriais pela tela Ajuda com aviso contra golpes (Priority: P2)

**Goal**: Disponibilizar na Ajuda o acesso ao site oficial de tutoriais restrito a URL fixa `https://` (`MEMORA_URL_SITE_TUTORIAL`), exigindo diálogo modal rolável de confirmação exibindo o endereço oficial antes de sair do app e mantendo o botão oculto automaticamente enquanto nenhuma URL oficial válida estiver configurada (`Q3: A`).

**Independent Test**: Executar `flutter test test/features/ajuda/tela_ajuda_test.dart` em `app/` comprovando botão oculto por padrão e quando URL for inválida (`http://`, `user@host`, espaços), exibição do diálogo modal rolável com a URL oficial quando configurado, `0` chamadas ao cancelar, `1` chamada ao confirmar e aviso acessível `liveRegion: true` ao falhar a abertura.

### Implementation & Tests for User Story 5

- [X] T034 [P] [US5] Adicionar em `app/lib/l10n/textos_ajuda.dart` os textos do cartão/botão do site oficial de tutoriais, título e mensagem do diálogo modal exibindo visivelmente o endereço oficial (`"Sim, abrir o site"`, `"Agora não"`) e aviso calmo de erro (`<= 2` frases curtas, zero emojis, gênero neutro, sem `www.`)
- [X] T035 [US5] Instanciar `AbridorDeSiteTutorial.doAmbiente(ambiente)` em `app/lib/services/ambiente/composicao.dart` e repassar `abridorSiteTutorial` através de `app/lib/main.dart` -> `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart` -> `TelaAjuda` (depende de T006)
- [X] T036 [US5] Implementar `_CartaoSiteTutorial` e as chaves `TelaAjuda.chaveAbrirSiteTutorial`, `chaveConfirmarSiteTutorial`, `chaveCancelarSiteTutorial` e `chaveErroSiteTutorial` em `app/lib/features/ajuda/presentation/tela_ajuda.dart`, preservando o único `CaixaDeEtapa`, ocultando totalmente quando `abridorSiteTutorial == null`, abrindo `AlertDialog(scrollable: true)` exibindo `abridor.endereco` antes de chamar `abrir()`, e mostrando erro com `Semantics(liveRegion: true)` caso `abrir()` retorne `false` (depende de T034, T035)
- [X] T037 [US5] Adicionar testes unitários de `Ambiente.urlSiteTutorial` / `AbridorDeSiteTutorial.doAmbiente` (verificando antes se já existe arquivo dedicado em `app/test/services/ambiente/`, ou mantendo junto em `app/test/features/ajuda/tela_ajuda_test.dart`) e testes de widget em `app/test/features/ajuda/tela_ajuda_test.dart` (oculto por padrão, recusa a `http://` / `user@host` / espaços, altura de toque `>= 56 dp` em `TelaAjuda.chaveAbrirSiteTutorial`, diálogo modal a `200%` em `320×568` e sob `disableAnimations: true`, cancelamento com 0 chamadas, confirmação com 1 chamada e falha com anúncio `liveRegion`) (depende de T036)
- [X] T038 [US5] Validar a história executando `flutter test test/features/ajuda/` em `app/`

**Checkpoint**: User Story 5 completa — proteção anti-phishing verificada com URL oculta até configuração oficial `https://`.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Verificação transversal de textos (`memora-ux`), execução integral dos portões de qualidade de `quickstart.md` e auditoria de isolamento do diff antes de abrir PR para `develop`.

- [X] T039 [P] Auditar todas as frases adicionadas ou alteradas em `app/lib/l10n/textos_ajuda.dart`, `app/lib/l10n/textos_perfil.dart` e `app/lib/l10n/textos_guias.dart` conforme `.claude/skills/memora-ux/SKILL.md` (`<= 2` frases curtas, zero emojis, gênero neutro) e executar `flutter test test/design_system/texto_da_interface_test.dart` em `app/`
- [X] T040 Executar todos os portões obrigatórios de `specs/016-ajustes-pos-redesenho/quickstart.md`: `flutter analyze` e `flutter test` em `app/`, `py specs/002-design-system/ferramentas/validar_tokens.py` e `git grep -in "wokwi" -- app/`
- [X] T041 Conferir `git status` e `git diff --stat` na raiz confirmando preservação integral de arquivos atribuídos a `@Edudu720` e `@Henrique-Sandrini` (`app/assets/guias/e-titulo/`, `fgts/`, `instagram/`, `whatsapp/`, `facebook/`, `telegram/`, `gov-br/`, `serasa/`, `correios/` e `app/lib/features/aprendizado/data/guias/` correspondentes), além de revisar se `CHANGELOG.md` ou documentação viva ativa em `docs/` necessita registro da retirada do Wokwi/capturas antes do commit e abertura da PR para `develop`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências prévias — inicia imediatamente (`T002` e `T003` em paralelo após `T001`).
- **Foundational (Phase 2)**: Depende de `T001`; `T004` libera conversão em `US3`, enquanto `T005 -> T006` liberam a injeção de `US5`. `US1`, `US2` e `US4` não dependem de `T004`–`T006` e podem rodar assim que `T001` concluir.
- **User Stories (Phases 3–7)**:
  - **US1 (P1 🎯 MVP)** — Independente após `T001`.
  - **US2 (P1)** — Independente após `T001` (apenas evite editar `textos_perfil.dart` junto com `T030` da `US4`).
  - **US3 (P1)** — Depende de `T002` (declaração `assets/icones_apps/`) e `T004` (teto `12 MB`); guias em `T020`–`T026` e SVGs em `T028` são paralelizáveis entre si.
  - **US4 (P2)** — Independente para layout/otimização em `TelaPerfil`; sequenciar `T030` após `T014` evita conflito de edição em `textos_perfil.dart`.
  - **US5 (P2)** — Depende de `T003` (`<queries>` https), `T005` e `T006` (`AbridorDeSiteTutorial`).
- **Polish (Phase 8)**: Depende da conclusão de todas as fases `US1`–`US5`.

### User Story Dependency Graph

```text
T001 ──┬──> Phase 2 (T004 [12MB], T005 -> T006 [AbridorSite])
       ├──> US1 (P1): T007..T011 (independente)
       ├──> US2 (P1): T012..T016 (independente; libera textos_perfil.dart para T030)
       │
T002 + T004 ──> US3 (P1): T017 -> T018 + T019 -> T020..T026 [P] -> T027 ──┐
                                              └── T028 [P] ───────────────┴─> T029
T014 (ou pós-T016) ──> US4 (P2): T030 -> T031 -> T032 -> T033
T003 + T006 ──> US5 (P2): T034 [P] + T035 -> T036 -> T037 -> T038
                                                                      │
All US1..US5 + T039 ──> T040 ──> T041 ────────────────────────────────┘
```

### Parallel Opportunities

- **Setup**: `T002` (`pubspec.yaml`) e `T003` (`AndroidManifest.xml`) rodam em paralelo.
- **Foundational**: `T004` (`12 MB`) e `T005` (`Ambiente`) rodam em paralelo.
- **Dentro da US1**: `T007` (testes MQTT) e `T008` (limpeza comentários `enums`/`provedor`) rodam em paralelo.
- **Dentro da US2**: `T012` (testes fallback), `T013` (`AvatarIlustrado`) e `T014` (`textos_perfil.dart`) rodam em paralelo.
- **Dentro da US3**: após `T018` + `T019`, todos os 7 arquivos de guias (`T020`–`T026`) e os 7 SVGs + `IconeDoAplicativo` (`T028`) podem rodar integralmente em paralelo.
- **Entre Stories**: `US1`, `US2`, `US3` (`T017`+) e `US5` (`T034` após `T006`) tocam conjuntos disjuntos de arquivos (exceção apenas para `textos_perfil.dart` entre `T014` e `T030`).

---

## Parallel Example: User Story 3 (Guias e SVGs)

```text
# Após T018 (CapturaDoGuia) e T019 (textos_guias.dart), disparar em paralelo:
Task: "T020 [P] [US3] Atualizar app/lib/features/aprendizado/data/guias/tiktok.dart (6 passos)"
Task: "T021 [P] [US3] Atualizar app/lib/features/aprendizado/data/guias/youtube.dart (7 passos)"
Task: "T022 [P] [US3] Atualizar app/lib/features/aprendizado/data/guias/google_fotos.dart (4 passos)"
Task: "T023 [P] [US3] Reestruturar app/lib/features/aprendizado/data/guias/meu_inss.dart (4 seções, 19 capturas)"
Task: "T024 [P] [US3] Reestruturar app/lib/features/aprendizado/data/guias/carteira_digital.dart (2 seções, 10 capturas)"
Task: "T025 [P] [US3] Reestruturar app/lib/features/aprendizado/data/guias/carteira_de_trabalho.dart (2 seções, 10 capturas)"
Task: "T026 [P] [US3] Reestruturar app/lib/features/aprendizado/data/guias/poupatempo.dart (2 seções, 10 capturas)"
Task: "T028 [P] [US3] Criar 7 SVGs em app/assets/icones_apps/ e atualizar app/lib/design_system/componentes/ilustracao/icone_do_aplicativo.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Concluir Phase 1 (`T001`–`T003` — foco `T001` e `T002`)
2. Executar **Phase 3: User Story 1 (`T007`–`T011`)**
3. **STOP & VALIDATE**: confirmar que `simularQuedaTeste()` reprovava com o defeito antigo e passa após `T009`–`T010`, com zero ocorrências de `"wokwi"` em `app/`
4. Se necessário, já entrega correção crítica do dispositivo de cuidado de forma isolada

### Incremental Delivery (P1 -> P2)

1. **Setup + Foundational (`T001`–`T006`)**: fundação pronta (`12 MB`, `MEMORA_URL_SITE_TUTORIAL`, `assets/icones_apps/`, `<queries>`)
2. **US1 (`T007`–`T011`)**: simulação de queda funcionando no ESP32/MQTT e zero Wokwi
3. **US2 (`T012`–`T016`)**: remoção de `casalIdoso` e `pessoaComCelular` com fallback seguro comprovado
4. **US3 (`T017`–`T029`)**: 66 capturas reais nos 7 guias + 7 SVGs em `app/assets/icones_apps/`
5. **US4 (`T030`–`T033`)**: melhoria e otimização de `TelaPerfil` compatível com o Item 14
6. **US5 (`T034`–`T038`)**: botão seguro `https://` na Ajuda oculto até deploy da URL oficial
7. **Polish (`T039`–`T041`)**: portão final completo antes de commitar e abrir PR para `develop`

---

## Notes

- Tarefas `[P]` operam em arquivos distintos sem dependências pendentes.
- Nomes de constantes, chaves e limites citados nas tarefas seguem literalmente [data-model.md](data-model.md) e [contracts/](contracts/).
- Não alterar capturas de `@Henrique-Sandrini` (`e-titulo`, `fgts`, `instagram`) nem de `@Edudu720` (`whatsapp`, `facebook`, `telegram`, `gov-br`, `serasa`, `correios`).
- Checklists aprovados: [requirements.md](checklists/requirements.md) (`16/16`) e [revisao-pr.md](checklists/revisao-pr.md) (`24/24`).

---

## Phase 9: Convergence

- [X] T042 [CRITICAL] Ajustar o preenchimento âmbar (`#D98200`, contraste `2,94:1 < 3,0:1` sobre `#FFFFFF`) em `app/assets/icones_apps/google-fotos.svg` e `app/assets/icones_apps/carteira-digital.svg` para tom com contraste WCAG 2.2 `>= 3,0:1` (ex.: `#C97600` com `3,46:1` ou `#B86B00` com `4,08:1`) e adicionar verificação automática de razão de contraste luminância `>= 3,0:1` para os 7 SVGs em `app/test/design_system/icone_do_aplicativo_test.dart` per Constitution III / AC-002 / SC-007 / contracts/icones-e-guias.md §1.3 (contradicts)

---

## Phase 10: PR #107 Review Adjustments (`@Henrique-Sandrini`)

- [X] T043 Envolver `TelaDispositivoCuidado` no `StatefulWidget` proprietário `_DonoDoDispositivoCuidado` em `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart` e adicionar guarda `_descartado` pós-`await` e em callbacks/métodos de `app/lib/features/cuidado/presentation/controladores/controlador_dispositivo_cuidado.dart`, cobrindo logout/expiração e descarte assíncrono com testes de regressão em `app/test/features/cuidado/presentation/tela_dispositivo_cuidado_test.dart` (Ponto #1 da revisão da PR #107)
- [X] T044 Adicionar tratamento `try/catch` em `TelaPerfil._carregarMaisAprendido()` em `app/lib/features/perfil/presentation/tela_perfil.dart` com teste de erro em `app/test/features/perfil/tela_perfil_test.dart` (Ponto #2 da revisão da PR #107)
- [X] T045 [P] Adicionar `excludeFromSemantics: true` no `SvgPicture.asset` de `app/lib/design_system/componentes/ilustracao/icone_do_aplicativo.dart`, registrar os 7 SVGs em `app/assets/ilustracoes/LICENCAS.md` e validar em `app/test/design_system/icone_do_aplicativo_test.dart` (Ponto #3 da revisão da PR #107)
- [X] T046 [P] Converter os 14 caminhos absolutos locais (`file` URI com prefixo absoluto do workspace) para caminhos relativos nos docs de `specs/016-ajustes-pos-redesenho/` e sincronizar `contracts/`, `plan.md` e `tasks.md` (Ponto #4 da revisão da PR #107)
- [X] T047 [P] Atualizar o comentário Dartdoc desatualizado em `app/lib/features/ajuda/presentation/tela_ajuda.dart` para controle estrito do site oficial em `https://` (Ponto #5 da revisão da PR #107)
- [X] T048 [P] Corrigir os números dos itens da Issue #106 em `CHANGELOG.md` (Itens 7–8 no Cuidado, Item 9 em Retratos e Item 10 em Meu Perfil) e preparar nota de correção das seções de `carteira-digital`/`carteira-de-trabalho` (`2` seções de `6 + 4` passos) para a descrição da PR #107 (Ponto #6 da revisão da PR #107)
- [X] T049 [P] Reforçar `Ambiente.enderecoOficial` em `app/lib/services/ambiente/ambiente.dart` rejeitando `@` na autoridade (`https://@host`) e cobrir o caso em `app/test/services/ambiente_test.dart` (Ponto #7 da revisão da PR #107)
- [X] T050 Executar todos os portões obrigatórios após as alterações finais (verificação sem URIs absolutas locais na spec 016, `git grep` de `wokwi` em `app/`, `validar_tokens.py`, `flutter analyze` e `flutter test` completo) e marcar `T043`–`T050` como `[X]`
