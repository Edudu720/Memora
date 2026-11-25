---

description: "Actionable, dependency-ordered tasks for feature 011-foto-perfil"
---

# Tasks: Foto de Perfil da Pessoa Usuária (`011-foto-perfil`)

**Input**: Design documents from `/specs/011-foto-perfil/`  
**Prerequisites**: [plan.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/plan.md), [spec.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md), [research.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/research.md), [data-model.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/data-model.md), [interfaces-foto-perfil.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/contracts/interfaces-foto-perfil.md)

**Tests**: Solicitados pela spec/plan (testes unitários de sanitização EXIF/limites, persistência/isolamento, limpeza na saída e testes de widget de `US1`–`US3`, acessibilidade `200%` e 3 temas).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos distintos, sem dependência de tarefa incompleta)
- **[Story]**: User Story correspondente (`[US1]`, `[US2]`, `[US3]`), obrigatória apenas nas fases de User Story (Phases 3–5)

---

## Phase 1: Setup (Infraestrutura Compartilhada)

**Purpose**: Dependências do app, permissões mínimas no Android e textos localizados em português acessível

- [X] T001 Adicionar dependências `image_picker` e `image` (para seleção nativa com Photo Picker e decodificação/sanitização em Dart puro) em `app/pubspec.yaml` e executar `flutter pub get` em `app/`
- [X] T002 [P] Declarar apenas `<uses-permission android:name="android.permission.CAMERA"/>` e `<uses-feature android:name="android.hardware.camera" android:required="false"/>` (sem `READ_MEDIA_IMAGES` nem `READ_EXTERNAL_STORAGE` para preservar acesso mínimo pelo Photo Picker) em `app/android/app/src/main/AndroidManifest.xml`
- [X] T003 [P] Adicionar todas as constantes textuais e semânticas da foto de perfil (títulos, explicação de privacidade FR-004, opções Galeria/Câmera/Avatares, rótulos dos 6 avatares, confirmação "Usar esta foto"/"Escolher outra", diálogo de remoção, mensagens calmas de permissão negada e arquivo inválido) em `app/lib/l10n/textos_perfil.dart`

---

## Phase 2: Foundational (Pré-requisitos Bloqueantes)

**Purpose**: Modelos de domínio, sanitizador de imagem sem EXIF, armazenamento local isolado por conta, integração no ciclo de limpeza da sessão e suíte de testes unitários de base

**⚠️ CRITICAL**: Nenhuma User Story começa antes de concluir esta fase

- [X] T004 Criar entidades `RetratoDePerfil` (`FotoPropriaDePerfil`, `AvatarIlustradoDePerfil`), enum `AvatarIlustrado` (6 valores mapeados para os ativos licenciados em `app/assets/ilustracoes/LICENCAS.md`) e constantes `PoliticaDeImagemDePerfil` (`tamanhoMaximoEntradaBytes = 15 * 1024 * 1024`, `dimensaoMaximaPx = 512`, `qualidadeJpegSaida = 88`) em `app/lib/features/perfil/domain/retrato_de_perfil.dart`
- [X] T005 [P] Implementar `ProcessadorDeImagemDePerfil` executando em `Isolate.run`: checagem prévia `<= 15 MB`, validação por assinatura binária real apenas para **JPEG (`FF D8 FF`), PNG (`89 50 4E 47`) e WebP estático (`RIFF....WEBP` quadro único)** rejeitando `HEIC`, `GIF`, SVG externo, animações multi-quadro e tipos disfarçados como `formatoNaoSuportado`, aplicação de `bakeOrientation`, recorte quadrado `1:1` centralizado redimensionado até `512×512 px` e re-encode JPEG limpo (qualidade `88`) com 0% de metadados EXIF/GPS/XMP em `app/lib/features/perfil/domain/processador_de_imagem.dart`
- [X] T006 [P] Implementar interfaces `ArmazenamentoDeFotoDePerfil` e `FotoDePerfilDoAparelho` (`implements DadoLocalDoAparelho`), `FotoDePerfilLocal` (índice em `SharedPreferences` sob prefixo `memora.foto_perfil.v1.` com identificador `contaSegura` estrito `[a-zA-Z0-9_-]` sem travessia de caminho, arquivo versionado `<contaSegura>_<timestampMs>.jpg` em `<appSupportDir>/fotos_perfil/`, remoção automática do arquivo anterior na troca, fallback seguro para `null` se arquivo sumiu/corrompeu, `apagar(idDaConta)` e `esquecerDoAparelho()` limpando todas as chaves e arquivos) e `FotoDePerfilEmMemoria` em `app/lib/features/perfil/data/foto_de_perfil_local.dart`
- [X] T007 Injetar `FotoDePerfilDoAparelho` na composição de dependências (`limpeza` em `dadosDoAparelho` para que saída comum preserve e `esquecerTudo` apague tudo), na raiz e no fluxo de autenticação passando até `TelaPerfil` em `app/lib/services/ambiente/composicao.dart`, `app/lib/main.dart` e `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`
- [X] T008 [P] Escrever testes unitários de processamento provando orientação EXIF aplicada (`bakeOrientation`), recorte `1:1 <= 512×512 px`, remoção comprovada byte-a-byte de bloco EXIF/GPS sintético, rejeição `> 15 MB`, rejeição de `HEIC`/`GIF`/WebP animado/arquivo corrompido/PDF renomeado em `app/test/features/perfil/processador_de_imagem_test.dart`
- [X] T009 [P] Escrever testes unitários de armazenamento provando isolamento entre contas, bloqueio de *path traversal* (`../`) e `idDaConta` vazio, remoção do arquivo antigo ao trocar, fallback para `null` quando arquivo some do disco e limpeza total por `esquecerDoAparelho()` em `app/test/features/perfil/foto_de_perfil_local_test.dart`
- [X] T010 [P] Atualizar teste de limpeza de saída para comprovar que `LimpezaDeSessao.executar(esquecerTudo: false)` mantém a foto local e `esquecerTudo: true` apaga tudo em `app/test/features/autenticacao/saida_limpa_armazenamento_test.dart`

**Checkpoint**: Fundação pronta — validação binária/EXIF, armazenamento isolado por conta e ciclo de sessão testados

---

## Phase 3: User Story 1 — Colocar uma foto de perfil ou avatar pela primeira vez (Priority: P1) 🎯 MVP

**Goal**: Permitir que a pessoa usuária visualize seu retrato dedicado no Perfil (Retrato Padrão neutro quando vazio) e defina uma foto própria (Galeria/Câmera com pré-visualização `1:1`) ou um avatar ilustrado da Memora (sem permissões), persistido localmente por conta

**Independent Test**: Abrir `TelaPerfil` sem retrato salvo, confirmar o Retrato Padrão neutro, testar seleção via galeria/câmera passando pela pré-visualização ("Usar esta foto") e seleção de avatar ilustrado sem pedir permissão nativa, verificando persistência após recriar a tela e inalterabilidade da `TelaInicio`

### Implementation for User Story 1

- [X] T011 [P] [US1] Implementar interface `SeletorDeImagemDoAparelho`, sealed class `ResultadoDaSelecao` (`SelecaoConfirmada`, `SelecaoCancelada`, `SelecaoSemPermissao`, `SelecaoExcedeuLimite`, `SelecaoComFalha`) e `SeletorDeImagemDoAparelhoReal` encapsulando `ImagePicker` (checagem prévia `XFile.length() <= 15 MB`, limpeza best-effort do arquivo temporário bruto do `XFile` em cache logo após ler os bytes em memória para não reter EXIF em cache, tratamento de `camera_access_denied` / `photo_access_denied` e `abrirConfiguracoesDoAparelho` via `android_intent_plus` com `try/catch` retornando `false` fora do Android ou sem handler) em `app/lib/features/perfil/data/seletor_de_imagem.dart`
- [X] T012 [P] [US1] Criar widget circular `RetratoDoPerfil` (recebendo `Key? chaveDoRetrato` / usando `TelaPerfil.chaveDesenho` como chave única) renderizando `FotoPropriaDePerfil`, `AvatarIlustradoDePerfil` ou `RetratoPadrao` neutro (iniciais 1–2 letras maiúsculas quando `nome` válido ou `Icons.person_outline` quando vazio/sem letras, borda `MemoraDimensoes.bordaAvatar`, contraste WCAG 2.2 AA nos 3 temas e `Semantics` distinta para cada estado) em `app/lib/features/perfil/presentation/widgets/retrato_do_perfil.dart`
- [X] T013 [P] [US1] Criar `TelaPreVisualizacaoFoto` exibindo recorte circular em pré-visualização (`"Ficou boa assim?"`) e botões explícitos com ícone + texto `"Usar esta foto"` (`BotaoPrimario`) e `"Escolher outra"` (`BotaoSecundario`) com `>= 48×48 dp`, `>= 8 dp` de espaçamento, respeito a `reduzirMovimento` (`disableAnimations`) e suporte até `200%` em `app/lib/features/perfil/presentation/tela_pre_visualizacao_foto.dart`
- [X] T014 [US1] Criar `SecaoFotoPerfil` (repassando `TelaPerfil.chaveDesenho` para `RetratoDoPerfil`) com leitura/recarregamento por `idDaConta` (`didUpdateWidget`), botão `"Colocar foto de perfil"`, abertura de `FolhaInferior` com explicação de privacidade integrada (`FR-004`) e 3 opções (`Galeria`, `Câmera`, `Avatares da Memora`), grade acessível de avatares ilustrados sem permissões, navegação para `TelaPreVisualizacaoFoto`, guarda de concorrência (`_ocupado`), respeito a `reduzirMovimento` e descarte seguro se `mounted` ou `idDaConta` mudarem durante seleção externa (expiração por inatividade) em `app/lib/features/perfil/presentation/secao_foto_perfil.dart`
- [X] T015 [US1] Substituir `MemoraPersonagem` do cabeçalho pelo bloco de retrato da pessoa usuária (`SecaoFotoPerfil` mantendo `TelaPerfil.chaveDesenho` no `RetratoDoPerfil` e preservando `TelaInicio` inalterada) em `app/lib/features/perfil/presentation/tela_perfil.dart`
- [X] T016 [US1] Atualizar testes existentes de Perfil para o novo retrato neutro/chave (`RetratoPadrao`) e adicionar testes de widget cobrindo o fluxo feliz de US1 (galeria + pré-visualização `"Usar esta foto"`, câmera, avatar da Memora sem chamar seletor nativo, cancelamento silencioso no seletor e verificação de que `TelaInicio` não é alterada) em `app/test/features/perfil/tela_perfil_test.dart` e `app/test/features/perfil/foto_perfil_widget_test.dart`

**Checkpoint**: User Story 1 (MVP) completa e testável de forma independente

---

## Phase 4: User Story 2 — Trocar ou remover a foto de perfil existente (Priority: P2)

**Goal**: Dar controle reversível à pessoa usuária que já tem foto ou avatar, permitindo substituir por outro item ou remover definitivamente após diálogo explícito de confirmação

**Independent Test**: A partir de uma conta já com foto ou avatar salvo, trocar por outra imagem/avatar verificando substituição sem resíduo anterior, acionar `"Remover foto"` testando o cancelamento (mantém retrato) e a confirmação (apaga armazenamento local e restaura Retrato Padrão)

### Implementation for User Story 2

- [X] T017 [US2] Implementar em `SecaoFotoPerfil` as ações visíveis quando já há retrato salvo (`"Trocar foto"` reabrindo escolha de origem, retorno imediato à escolha ao tocar em `"Escolher outra"` na pré-visualização sem sobrescrever a foto anterior, e `"Remover foto"` abrindo `ConfirmacaoMemora` inline com dois botões descritivos apagando via `ArmazenamentoDeFotoDePerfil.apagar` e restaurando o Retrato Padrão) em `app/lib/features/perfil/presentation/secao_foto_perfil.dart`
- [X] T018 [US2] Adicionar testes de widget de US2 cobrindo troca entre foto e avatar, retorno via `"Escolher outra"` preservando foto anterior, cancelamento e confirmação de remoção no `ConfirmacaoMemora`, troca de `idDaConta` em memória na árvore e bloqueio contra toques concorrentes (`FR-012`) em `app/test/features/perfil/foto_perfil_widget_test.dart`

**Checkpoint**: User Stories 1 e 2 funcionais e testadas independentemente

---

## Phase 5: User Story 3 — Lidar com permissões negadas e imagens inválidas sem sustos (Priority: P3)

**Goal**: Tratar recusas de permissão, arquivos inválidos/corrompidos e limites excedidos com mensagens acolhedoras em português e recuperação imediata

**Independent Test**: Simular recusa de permissão de câmera e galeria comprovando exibição do quadro orientativo com botão para abrir configurações do aparelho e atalho para escolher avatar da Memora; simular seleção de arquivo `> 15 MB` ou inválido preservando o retrato anterior e exibindo aviso acessível em português, nos 3 temas e `200%` de escala de fonte

### Implementation for User Story 3

- [X] T019 [US3] Implementar quadro de aviso acessível em `SecaoFotoPerfil` para `SelecaoSemPermissao` (mensagem calma explicando o motivo + botão `"Abrir ajustes do aparelho"` invocando `abrirConfiguracoesDoAparelho` + botão `"Escolher avatar da Memora"` como alternativa imediata) e mensagens claras em português para `ImagemRejeitada` / `SelecaoExcedeuLimite` / `SelecaoComFalha` preservando o retrato anterior em `app/lib/features/perfil/presentation/secao_foto_perfil.dart`
- [X] T020 [US3] Adicionar testes de widget e acessibilidade de US3 cobrindo negação de permissão de câmera/galeria, abertura simulada dos ajustes do aparelho, desvio imediato para avatar da Memora, rejeição amigável de arquivo `> 15 MB`/inválido mantendo retrato anterior, expiração de conta durante seleção externa (`idDaConta` alterado) e varredura nos 3 temas (`claro`, `escuro`, `altoContraste`), `disableAnimations` (`reduzirMovimento`) e `textScaler` `2.0` (`>= 48×48 dp`, contraste semântico e zero overflow) em `app/test/features/perfil/foto_perfil_widget_test.dart`

**Checkpoint**: Todas as 3 User Stories (`US1`, `US2`, `US3`) completas e testadas

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validação estática, execução integral da suíte e revisão de higiene/segurança

- [X] T021 Executar `flutter analyze` e `flutter test` em `app/` validando todos os cenários `V1`–`V6` descritos em [quickstart.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/quickstart.md) (`SC-001` a `SC-006`) e conferir `git diff` contra critérios de acessibilidade e segurança da Constituição

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sem dependências; inicia imediatamente (`T001` deve rodar antes de usar os pacotes na Phase 2; `T002` e `T003` em paralelo).
- **Phase 2 (Foundational)**: Depende de `T001` (pacotes instalados) e `T003` (textos); **bloqueia** todas as User Stories (`US1`, `US2`, `US3`).
- **Phase 3 (US1 - P1 MVP)**: Depende de Phase 2 (`T004`–`T010`).
- **Phase 4 (US2 - P2)**: Depende de `T014` (`SecaoFotoPerfil` criada em US1).
- **Phase 5 (US3 - P3)**: Depende de `T011` (`SeletorDeImagemDoAparelho`) e `T014` (`SecaoFotoPerfil`).
- **Phase 6 (Polish)**: Depende de todas as User Stories concluídas.

### Parallel Opportunities

- **Setup**: `T002` (`AndroidManifest.xml`) e `T003` (`textos_perfil.dart`) em paralelo com `T001`.
- **Foundational**: Após `T004`, executar `T005` (`processador_de_imagem.dart`) e `T006` (`foto_de_perfil_local.dart`) em paralelo; em seguida `T008`, `T009` e `T010` (suítes de teste unitário) em paralelo com `T007` (ligação em `Composicao`/`main`/`fluxo_autenticacao`).
- **User Story 1**: `T011` (`seletor_de_imagem.dart`), `T012` (`retrato_do_perfil.dart`) e `T013` (`tela_pre_visualizacao_foto.dart`) podem ser desenvolvidos simultaneamente antes de `T014` (`secao_foto_perfil.dart`).

### Parallel Example: User Story 1

```text
Task: "T011 [P] [US1] Implementar SeletorDeImagemDoAparelho em app/lib/features/perfil/data/seletor_de_imagem.dart"
Task: "T012 [P] [US1] Criar RetratoDoPerfil em app/lib/features/perfil/presentation/widgets/retrato_do_perfil.dart"
Task: "T013 [P] [US1] Criar TelaPreVisualizacaoFoto em app/lib/features/perfil/presentation/tela_pre_visualizacao_foto.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Concluir Phase 1 (`T001`–`T003`) e Phase 2 (`T004`–`T010`).
2. Concluir Phase 3 (`US1`, `T011`–`T016`).
3. **PARAR e VALIDAR**: rodar `flutter test test/features/perfil/` e verificar o fluxo completo de colocar foto (Galeria/Câmera + pré-visualização + Avatar) de forma isolada.

### Incremental Delivery

1. Setup + Foundational → Motor seguro sem EXIF + persistência local isolada por conta prontos.
2. **US1** → Colocar foto ou avatar pela primeira vez (`MVP`).
3. **US2** → Troca limpa (sem resíduo antigo) e remoção segura com `ConfirmacaoMemora`.
4. **US3** → Resiliência a permissões negadas e arquivos inválidos + validação nos 3 temas e `200%`.
5. **Polish** → `flutter analyze` + `flutter test` completo e conferência manual no dispositivo quando disponível.

---

## Phase 7: Convergence

- [X] T022 CRITICAL: Refatorar os itens de `_ListaAvataresMemora` em `app/lib/features/perfil/presentation/secao_foto_perfil.dart` para usar componente do Design System baseado em `SuperficieTocavel` (estendendo `OpcaoSelecionavel` em `app/lib/design_system/componentes/selecao/opcao_selecionavel.dart` com `lider` opcional e `SuperficieTocavel`), garantindo anel externo de foco (`bordaSelecao`), escala no toque (`escalaPressionado`) com respeito a `reduzirMovimento` e cobertura em `app/test/features/perfil/foto_perfil_widget_test.dart` per Constitution III (partial)
- [X] T023 Adicionar teste de integração sobre `Composicao.resolver` em `app/test/features/perfil/foto_de_perfil_local_test.dart` comprovando que a instância `composicao.fotoDePerfil` é preservada na saída comum e apagada por `composicao.limpeza.executar(esquecerTudo: true)` per FR-009 (partial)
