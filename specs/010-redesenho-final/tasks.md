# Tasks: Redesenho final — a Memora ganha corpo, movimento e voz

**Input**: `specs/010-redesenho-final/` — spec.md, plan.md, research.md,
data-model.md, contracts/componentes.md, quickstart.md
**Regras de UI**: `.claude/skills/memora-ux/SKILL.md` — leia antes de qualquer
tarefa de tela.

**Formato**: `[ID] [P?] [História] Descrição` — `[P]` pode rodar em paralelo
(arquivos diferentes, sem dependência).

**Duas fases** (research.md, R12):
- **Fase A (T001–T046)** — independe da #71. Pode ir para a `develop` já.
- **Fase B (T047–T079)** — **só depois que a #71 entrar na `develop`**. Toca
  arquivos que a #71 reescreve. Quando a #71 entrar, **revisar estas tarefas
  contra o código dela antes de começar** (decisão do Henrique, 2026-11-15).

**Regra de todo portão novo**: commitar, quebrar de propósito, ver reprovar,
desfazer (CLAUDE.md, seção 8). Cada tarefa de teste diz o que quebrar.

**Verificação ao fim de cada fase do tasks**: `flutter analyze`, `flutter test`,
`validar_paleta.py`, `validar_tokens.py` — e reverter `pubspec.lock` e
`android/gradle.properties` se o Flutter da máquina os reescrever.

---

# FASE A — independe da #71

## Phase 1: Setup

- [ ] T001 Conferir que a branch `feature/010-redesenho-final` está atualizada com a `develop` e que os quatro portões passam antes de começar (linha de base: 2448 testes em 2026-11-15)
- [ ] T002 [P] Acrescentar a `memora-ux` ao CLAUDE.md (seção 3 ou 9) como leitura obrigatória antes de tarefa de tela

---

## Phase 2: Fundação (bloqueia as histórias da Fase A)

- [ ] T003 [P] Criar `app/lib/design_system/tokens/cores_da_memora.dart` com os tokens da Memora (`memoraCorpo`, `memoraCorpoSombra`, `memoraVisor`, `memoraOlho`, `memoraDetalhe`, `memoraEscudo`, `memoraSombraChao`) nos temas claro, escuro e alto contraste, exposto pela `ThemeExtension` (R1, R12: arquivo separado até a #71 entrar)
- [ ] T004 Acrescentar os pares da Memora ao `specs/002-design-system/ferramentas/validar_paleta.py` (contorno ≥ 3:1 com o fundo, nos 3 temas) e provar quebrando com uma cor de corpo igual ao fundo (FR-007)
- [ ] T005 [P] Acrescentar a `app/lib/design_system/tokens/movimento.dart` as durações de gesto (`aceno`, `piscada`, `comemoracao`) e de transição de tela, todas consumidas via `MemoraMovimento.efetiva` (V9)
- [ ] T006 [P] Criar `DirecaoDaTransicao` e `GestoDaMemora` (data-model.md) em `app/lib/design_system/navegacao/` e `app/lib/design_system/componentes/ilustracao/memora_animada/`
- [ ] T007 Criar o leitor único de "reduzir movimento" (preferência do aplicativo **ou** do sistema) que a Memora, a rota e a troca de destino vão usar, em `app/lib/design_system/preferencias/`, reaproveitando o que `escopo_aparencia.dart` já expõe

**Checkpoint**: tokens, durações e o leitor de movimento prontos.

---

## Phase 3: User Story 1 — A Memora ganha corpo (P1) 🎯 MVP visual

**Goal**: A `MemoraAnimada` existe, com todas as poses, gestos e garantias, e
aparece na galeria. Ela **ainda não substitui** as imagens nas telas (isso é a
T047, Fase B).

**Independent Test**: galeria em depuração mostra a Memora em cada expressão,
nos 3 temas, animando; com "reduzir movimento", parada.

### Testes da US1 (escrever antes e ver falhar)

- [ ] T008 [P] [US1] `app/test/design_system/memora_animada_test.dart`: cada `ExpressaoDaMemora` monta sem exceção nos 3 temas e na matriz de tamanhos; quebrar trocando uma pose por `null`
- [ ] T009 [P] [US1] No mesmo arquivo: a Memora não aparece na árvore de semântica, nem com toque (V3, FR-005/005b); quebrar tirando o `ExcludeSemantics`
- [ ] T010 [P] [US1] No mesmo arquivo: com "reduzir movimento", nenhum `Ticker` ativo e toque não gera gesto (V2, FR-004/005d); quebrar ignorando a preferência
- [ ] T011 [P] [US1] No mesmo arquivo: toque dispara aceno/piscada alternados, toques durante o gesto são ignorados, nada navega (V4, FR-005a); quebrar acumulando gestos

### Implementação da US1

- [ ] T012 [US1] Definir as poses (`neutra`, `falando`, `pensando`, `comemorando`, `preocupada`, `acenando`, `dica`, `mini`) em `memora_animada/poses.dart`: valores-alvo de olhos, braços, cabeça, escudo e inclinação (data-model.md)
- [ ] T013 [P] [US1] Pintores das camadas em `memora_animada/pintores/` — sombra no chão, corpo, cabeça, visor, olhos, antena, braços, escudo — com gradientes de luz de cima à esquerda e cores só de `cores_da_memora.dart`, a partir da folha de expressões de `Memora-Desing-Ideias/` (R1)
- [ ] T014 [US1] `memora_animada/memora_animada.dart`: monta as camadas, interpola entre poses, ciclo de "respiração" e de fala (`falando`), leve perspectiva e paralaxe; camada de repintura própria e relógio parado fora da tela (R11, contrato)
- [ ] T015 [US1] Gestos de toque (aceno/piscada alternados), com a máquina de estados `ocioso → emGesto → ocioso` (FR-005a, data-model.md)
- [ ] T016 [US1] Gesto único `comemoracao` e entrada animada por expressão (FR-003)
- [ ] T017 [US1] Pôr a `MemoraAnimada` na `GaleriaMemora` em todas as expressões e gestos, e no teste de completude da galeria (V10 da 002)
- [ ] T018 [US1] Conferência visual: gerar capturas da galeria nos 3 temas e **mostrar ao Henrique** antes de seguir para a Fase B (risco do plano: o desenho em código precisa ficar à altura da referência)

**Checkpoint**: a Memora vetorial está pronta e aprovada na galeria.

---

## Phase 4: User Story 2 — Transições que mostram o caminho (P1)

**Goal**: `RotaMemora`, `TrocaDeDestino` e as transições de diálogo e folha
existem e estão ligadas onde a #71 não interfere (casca, diálogos).

**Independent Test**: navegar pela casca e abrir diálogos; tudo desliza na
direção certa; com "reduzir movimento", instantâneo.

### Testes da US2

- [ ] T019 [P] [US2] `app/test/design_system/rota_memora_test.dart`: avançar entra pela direita, voltar pela esquerda, duração ≤ 500 ms, a tela que sai não recebe toque, o gesto de voltar faz a mesma animação (V6); quebrar deixando a tela de saída aceitar toque
- [ ] T020 [P] [US2] No mesmo arquivo e em `app/test/design_system/dialogo_test.dart` e `folha_inferior_test.dart` (novos): com "reduzir movimento", troca instantânea; diálogo e folha não movem a tela de trás (V7, V9)
- [ ] T021 [P] [US2] Em `app/test/features/casca/casca_interna_test.dart`: trocar de destino preserva a pilha de cada um e desliza pela posição relativa (V8); quebrar trocando por um `AnimatedSwitcher` que recria os filhos

### Implementação da US2

- [ ] T022 [US2] `app/lib/design_system/navegacao/rota_memora.dart`: `RotaMemora<T>` com deslizamento e paralaxe, duração por `MemoraMovimento.efetiva`, bloqueio de toque na tela de saída, e o `TransicaoMemora` para o tema (contrato; o registro no tema é a T049)
- [ ] T023 [US2] `app/lib/design_system/navegacao/troca_de_destino.dart`: filhos vivos, deslizamento pela posição, fora da tela sem animar e sem foco (R3)
- [ ] T024 [US2] `app/lib/features/casca/casca_interna.dart`: trocar o `IndexedStack` pela `TrocaDeDestino` e o `MaterialPageRoute` da raiz pela `RotaMemora`
- [ ] T025 [P] [US2] `app/lib/design_system/componentes/dialogos/dialogo.dart` e `folha_inferior.dart`: transições de sobreposição (centro e de baixo) com `MemoraMovimento.efetiva` (R4)
- [ ] T026 [P] [US2] Trocar os `MaterialPageRoute` de `tela_dispositivo_cuidado.dart` e `secao_idade.dart` pela `RotaMemora` (o de `fluxo_autenticacao.dart` é a T050, Fase B)
- [ ] T027 [US2] Rodar a suíte inteira: testes que dependiam do zoom do Android ou de `pumpAndSettle` com duração fixa são ajustados na mesma tarefa (não afrouxar asserção)

**Checkpoint**: navegação com direção onde a #71 não interfere.

---

## Phase 5: User Story 3 — Texto curto, que ajuda e não diminui (P1) — parte A

**Goal**: o portão de texto existe e passa nos arquivos que a #71 não toca; o
servidor não manda mais emoji em mensagem de tela.

**Independent Test**: `texto_da_interface_test.dart` passa sobre `textos_ajuda`,
`textos_apresentacao`, `textos_autenticacao`, `textos_configuracoes` e
`textos_perfil`; o teste do backend passa.

- [ ] T028 [US3] `app/test/design_system/texto_da_interface_test.dart`: varredura lexical (R6) — mais de 2 frases, palavras/frases proibidas da memora-ux, emoji fora da fala da IA — sobre a **lista de arquivos da Fase A** (a lista cresce na T068); provar quebrando com um bloco de 3 frases, um "idoso" e um emoji
- [ ] T029 [US3] Rodar o portão e listar os blocos reprovados em `textos_ajuda.dart`, `textos_apresentacao.dart`, `textos_autenticacao.dart`, `textos_configuracoes.dart` e `textos_perfil.dart`
- [ ] T030 [P] [US3] Reescrever os reprovados de `textos_autenticacao.dart` e `textos_perfil.dart` (duas frases, voz da Memora; excedente vira etapa ou "Saber mais"; o necessário para decidir continua visível — FR-017)
- [ ] T031 [P] [US3] Reescrever os reprovados de `textos_ajuda.dart`, `textos_apresentacao.dart` e `textos_configuracoes.dart` (mesmas regras)
- [ ] T032 [US3] Onde um texto virou "Saber mais" ou etapa, ajustar a tela correspondente (só telas que a #71 não altera; as outras vão para a T069) e os testes que procuravam a frase antiga
- [ ] T033 [P] [US3] Backend: `TextoDaInterfaceTest` varrendo `CodigoDeErro` e as mensagens dos controladores atrás de emoji; provar quebrando
- [ ] T034 [US3] Backend: tirar o "😊" de `ControladorCanais`, `ControladorRecuperacao` e `ControladorRegistro` (FR-020) e conferir as duas frases dessas mensagens

**Checkpoint**: o portão de texto existe e protege o que já foi revisto.

---

## Phase 6: User Story 7 — A abertura com a Memora acenando (P1) — parte A

**Goal**: o aplicativo abre com a Memora acenando enquanto carrega.

**Independent Test**: abrir a frio no celular: Memora parada (nativo) → Memora
acenando → fluxo de entrada, sem pulo.

- [ ] T035 [P] [US7] `app/test/features/abertura/abertura_memora_test.dart`: sai só quando carregou **e** o aceno completou; frase de "quase pronta" aos 4 s; falha leva à tela de erro; com "reduzir movimento" do sistema, pose parada (V12); quebrar saindo antes do carregamento terminar
- [ ] T036 [US7] `app/lib/features/abertura/presentation/abertura_memora.dart` conforme o contrato, com textos novos em `app/lib/l10n/` (duas frases, voz da Memora)
- [ ] T037 [US7] `app/lib/main.dart`: chamar o `runApp` com a `AberturaMemora` **antes** de carregar preferências e composição; o carregamento atual passa para dentro dela, sem mudar a ordem nem o que é carregado
- [ ] T038 [P] [US7] Abertura nativa: `android/app/src/main/res/drawable/launch_background.xml` (e `drawable-v21`, `values-night`) com o fundo do tema e a Memora parada como desenho vetorial do Android, na mesma posição do aceno; Android 12+ com `windowSplashScreen*` sobre o mesmo fundo (FR-037, R9)
- [ ] T039 [US7] Medir no celular (APK de release) o tempo até a tela de entrada, antes e depois, e registrar no `quickstart.md` (SC-009)

**Checkpoint**: abertura pronta.

---

## Phase 7: User Story 4 — Conversa — parte A (emoji)

- [ ] T040 [P] [US4] `app/test/features/assistente/limitar_emoji_test.dart`: zero, um e vários emojis; emoji composto (com modificador de tom e com junção) conta como um; sem espaço duplo (V11); quebrar devolvendo o texto sem filtro
- [ ] T041 [US4] `app/lib/features/assistente/domain/limitar_emoji.dart` (contrato) e aplicá-lo no texto exibido da resposta em `texto_da_fala.dart` (FR-024)
- [ ] T042 [P] [US4] Backend: regra "no máximo um emoji por mensagem, nunca no lugar de uma palavra" em `PersonaDaMemora.java`, com teste em `PersonaDaMemoraTest`; conferir que as falas do `ClienteDaAssistenteSimulado` obedecem (FR-023)

---

## Phase 8: Fechamento da Fase A

- [ ] T043 Rodar os quatro portões e a suíte do backend (`mvnw clean test`, com Docker de pé)
- [ ] T044 Gerar o álbum de telas e conferir as telas tocadas na Fase A contra a checagem da memora-ux (seção 5)
- [ ] T045 APK de release no S20 FE: abertura, transições da casca, diálogos e a Memora na galeria; registrar em `revisao-de-design.md` da 004 ou num arquivo da 010
- [ ] T046 PR da Fase A para a `develop`, com a descrição dizendo que a Fase B espera a #71

---

# FASE B — depois que a #71 entrar na `develop`

> **Antes de começar**: trazer a `develop` com a #71, rodar os portões, e
> **revisar T047–T079 contra o código da #71** (nomes de componentes, telas,
> chaves). Ajustar este arquivo antes de implementar.

## Phase 9: Integração com a 007

- [ ] T047 [US1] `memora_personagem.dart`: a `MemoraPersonagem` passa a montar uma `MemoraAnimada`, com a mesma assinatura e o mesmo enum (inclusive `dica` e `mini` da #71); o leitor de tela continua igual
- [ ] T048 [US1] Mover os tokens de `cores_da_memora.dart` para o esquema de cores da #71 (`cores.dart`) e apagar o arquivo separado; `validar_paleta.py` continua passando
- [ ] T049 [US2] Registrar a `TransicaoMemora` como transição de página padrão em `temas_memora.dart` (cobre toda rota de página que restar, inclusive as da #71)
- [ ] T050 [US2] Trocar o `MaterialPageRoute` de `fluxo_autenticacao.dart` pela `RotaMemora`
- [ ] T051 [US1] Remover os PNGs da Memora de `app/assets/ilustracoes/` que não forem mais usados, e o registro deles no `pubspec.yaml` (o ícone do aplicativo continua); conferir que nenhum teste os carrega
- [ ] T052 [US1] `memora_distancia_test.dart`: em cada tela em que a Memora aparece, a área dela fica a ≥ 8 dp de qualquer alvo de toque, na matriz de aparelhos (V5, FR-005c); quebrar encostando a Memora num botão

## Phase 10: User Story 7 — Início e barra inferior (P1) — parte B

- [ ] T053 [US7] Início: a Memora em 2.5D no terço superior com a saudação, sobre a estrutura da 007 (cartão herói e atalhos abaixo) (FR-040)
- [ ] T054 [US7] Início: com letra ampliada, a área da Memora encolhe antes de qualquer texto ou ação sair do alcance; atualizar `inicio_ocupa_a_altura_test.dart` e a matriz (FR-041, V13); quebrar fixando a altura da Memora
- [ ] T055 [P] [US7] `app/test/design_system/navegacao_inferior_test.dart` (novo): ícone + rótulo juntos, alvo ≥ 48 dp, indicador desliza até o destino tocado, sem deslizar com "reduzir movimento" (V15); quebrar tirando o rótulo
- [ ] T056 [US7] `navegacao_inferior.dart`: barra refeita no acabamento da 007 (superfície, sombra, cantos), ícones arredondados da família única no lugar dos SVG de `assets/icones/navegacao/`, indicador deslizante e resposta ao toque (FR-044 a FR-047, R5)
- [ ] T057 [US7] Apagar `assets/icones/navegacao/` e ajustar `icones_de_navegacao_test.dart` (o teste passa a conferir a família, não os arquivos)

## Phase 11: User Story 4 — Conversa limpa (P2)

- [ ] T058 [US4] `tela_conversa.dart`: só o essencial — cabeçalho, aviso compacto, mensagens, campo; sugestões só antes da primeira mensagem; nenhum elemento decorativo (FR-043)
- [ ] T059 [US4] A Memora pequena no topo da conversa, `falando` enquanto a resposta aparece letra a letra, sem rosto ao lado de cada balão (FR-025, FR-042); ajustar `balao_de_fala.dart`
- [ ] T060 [US4] Ícones da conversa (enviar, ditar, sugestões, aviso) da família única, com texto e resposta ao toque (FR-029)
- [ ] T061 [US4] Atualizar `conversa_acessibilidade_test.dart` e a matriz: o aviso continua encolhendo e não sumindo (FR-026), a lista de mensagens mantém a altura mínima (V14)
- [ ] T062 [US4] Voz: `onDevice: true` no leitor de voz da #71; sem suporte no aparelho, botão indisponível com o motivo em uma frase; digitar continua (FR-034, V16); teste que reprova se o ditado for chamado sem `onDevice`

## Phase 12: User Story 5 — Ícones e toque (P2)

- [ ] T063 [P] [US5] Teste lexical: nenhum `Icons.` fora da variante arredondada em `app/lib/` e nenhum `Image.asset` de ícone ou ilustração fora das capturas dos guias (FR-027, FR-030); quebrar com um `Icons.home`
- [ ] T064 [US5] Trocar os ícones restantes para a variante arredondada e os SVG antigos de ilustração (`porta_*.svg`, `casal_idoso.svg`, `memora_*.svg`) por desenhos da família ou pela `MemoraAnimada`
- [ ] T065 [US5] `superficie_tocavel.dart` (versão da #71): resposta ao toque também com "reduzir movimento" (realce sem afundar), e teste que reprova sem resposta (FR-028)

## Phase 13: User Story 3 — Texto — parte B

- [ ] T066 [P] [US3] Reescrever os reprovados de `textos_assistente.dart` e `textos_casca.dart` (versões da #71)
- [ ] T067 [US3] Reescrever os passos dos guias em `textos_guias.dart` e em `features/aprendizado/data/guias/*.dart` que passarem de duas frases, dividindo em passos quando preciso (FR-022); a captura de cada passo continua batendo com o texto
- [ ] T068 [US3] Estender a lista de arquivos do `texto_da_interface_test.dart` para **todos** os arquivos de `l10n/` e de `guias/`; o portão passa sobre o aplicativo inteiro (SC-002)
- [ ] T069 [US3] Ajustar as telas que a #71 alterou onde texto virou "Saber mais" ou etapa
- [ ] T070 [US3] FR-035: frase na apresentação ("a Memora só fala com você dentro do aplicativo") em `textos_apresentacao.dart` e `fluxo_apresentacao.dart`, com teste (V17)

## Phase 14: User Story 6 — Nenhuma tela fica de fora (P3)

- [ ] T071 [P] [US6] Localizador (`tela_localizador.dart`) e os diálogos de permissão de localização, rota e ligação na linguagem da 010: Memora, transições, ícones, texto; sem mudar o comportamento da 009 (FR-031, FR-032)
- [ ] T072 [P] [US6] Seletor de seções e passo a passo: Memora `comemorando` na conclusão (FR-003), transição de avançar/voltar entre passos com a `RotaMemora` ou equivalente
- [ ] T073 [US6] Estados de carregando, vazio e erro de todas as telas com a Memora na expressão certa (FR-001)
- [ ] T074 [US6] Percorrer o álbum inteiro contra a checagem da memora-ux (seção 5) e corrigir o que reprovar (V18, SC-001)

## Phase 15: Validação final

- [ ] T075 Rodar os quatro portões, a suíte do backend, e regenerar o álbum nos 3 temas
- [ ] T076 Medir desempenho em perfil (abertura, trocas, gestos) no S20 FE e, se houver, num Galaxy A/M ou no emulador com CPU limitada; registrar no `quickstart.md` (V19, SC-005)
- [ ] T077 Conferir 50 respostas seguidas da IA real: nenhuma com mais de um emoji (SC-008)
- [ ] T078 APK de release no celular e revisão do Henrique, registrada (portão da T116 da 004 para tela nova na `master`)
- [ ] T079 Preparar o roteiro do teste com 5 pessoas de 65+ para o SC-007 (V20), junto do portão pendente das features 001 e 002

---

## Dependencies & Execution Order

- **Fase A**: Setup (T001–T002) → Fundação (T003–T007) → US1 (T008–T018), US2
  (T019–T027), US3-A (T028–T034), US7-A (T035–T039) e US4-A (T040–T042) podem
  andar em paralelo depois da Fundação → Fechamento A (T043–T046).
  - A US2 não depende da US1; a US7-A (abertura) depende da US1 (usa a
    `MemoraAnimada`).
  - A T018 (aprovação visual da Memora) é **portão** para a Fase B.
- **Fase B**: só depois da #71 na `develop` **e** da revisão destas tarefas.
  Integração (T047–T052) primeiro; depois US7-B, US4-B, US5, US3-B e US6 em
  paralelo; validação final por último.

## Parallel Opportunities

- T003, T005 e T006 (arquivos diferentes).
- Os testes de cada história (T008–T011, T019–T021, T033, T035, T040).
- Os pintores das camadas da Memora (T013), um arquivo por camada.
- Na Fase B: T055, T063, T066, T071 e T072.

## Implementation Strategy

1. **MVP visual**: Fundação + US1 até a T018. Mostrar a Memora ao Henrique
   antes de qualquer outra coisa: é o maior risco do plano.
2. Fase A completa → PR para a `develop` sem esperar a #71.
3. Quando a #71 entrar: revisar a Fase B, depois implementar por história,
   uma PR por fase do tasks (regra do projeto).
