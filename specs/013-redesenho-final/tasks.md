# Tasks: Redesenho final — a Memora ganha corpo, movimento e voz

**Input**: `specs/013-redesenho-final/` — spec.md, plan.md, research.md,
data-model.md, contracts/componentes.md, quickstart.md
**Regras de UI**: `.claude/skills/memora-ux/SKILL.md` — leia antes de qualquer
tarefa de tela.

**Formato**: `[ID] [P?] [História] Descrição` — `[P]` pode rodar em paralelo
(arquivos diferentes, sem dependência).

**Duas fases** (research.md, R12):
- **Fase A (T001–T046)** — independe da #71.
- **Fase B (T047–T079)** — tocava arquivos que a #71 reescrevia.

> 🔄 **Revisão de 2026-11-16, depois do merge das #71, #73 e #74 na `develop`**
> (`c74da78`). As tarefas foram conferidas contra o código delas, e o que
> mudou está marcado com **(rev. 16/11)**. Consequências:
> - **A Fase B não espera mais nada**: tudo o que ela pressupunha está na
>   `develop`. A divisão A/B vira só **ordem de trabalho**, e qualquer tarefa
>   pode começar depois de a branch receber a `develop` (T080).
> - A "lista de arquivos intocados" da Fase A **deixou de valer**: a #73 e a
>   #71 mexeram em `dialogo.dart`, `folha_inferior.dart`, `main.dart`,
>   `textos_perfil.dart`, `tela_dispositivo_cuidado.dart` e
>   `secao_idade.dart`. As tarefas da Fase A que tocam neles seguem iguais,
>   mas sobre a versão nova desses arquivos.
> - A #73 (foto de perfil) trouxe telas novas, e a #74 (site) é artefato à
>   parte, fora do escopo desta feature (ver T082).

## 👥 Divisão e forma de trabalho (decisão do Henrique, 2026-11-16)

**Três frentes, numa branch comum**: quando a #76 entrar na `develop`, a
`develop` é trazida para cá (T080) e o resultado é publicado como
**`redesign-final`**. Cada pessoa trabalha numa branch própria saída dela e
abre PR **para a `redesign-final`**, revisada por outra pessoa da equipe
(nunca por quem escreveu). No fim, a `redesign-final` vai para a `develop`
numa PR só.

| Quem | Tarefas | Abertas (17/11) |
|---|---|---|
| **Henrique** | Já feitas: T001–T018 e T028. **A anfitriã**: T083–T090. **As animações**: transições T019–T027, abertura T035–T039, tema e login T049–T050. **A branch comum**: T080. **Memora e Início**: T047, T048, T051, T052, T053, T054, T093, barra inferior T055–T057, T059, T072, T073, T076, T092. **Fechamento**: T043–T046, T078. Parte da T091 | 15 |
| **Eduardo Juncker** | **Textos**: T029–T034, T066–T070. **Emoji na IA**: T040–T042. **Conversa**: T058, T060, T061, T062. **Ícones**: T063–T065. **Telas da 009 e da 011**: T071, T081. **Validação**: T074, T075, T077, T079. Parte da T091 | 14 |
| **Eduardo Trevisan** | **Todo o site** (spec 012): as tarefas S01–S13 de `specs/012-site-tutorial-idoso/tarefas-do-redesenho.md`, mais a T082 | site |

Por que essa divisão: o Henrique ficou com as mais pesadas (a Memora, a
anfitriã e todo o movimento), e o resto foi repartido **por área**, para que
duas pessoas não mexam nos mesmos arquivos ao mesmo tempo. O que é da Memora
e do Início fica com quem desenhou a Memora; o que é texto, conversa e as
telas da 009 e da 011 fica com o Eduardo, que redesenhou a conversa na 007 e
escreveu o Localizador.

**Pontos de contato** (combinar antes de começar):
- T053/T054 (Início) dependem da T090 (anfitriã aprovada) — Henrique.
- T059 (Memora na conversa, Henrique) e T058/T060 (conversa limpa e ícones,
  Eduardo) mexem na mesma tela: a T058 vem primeiro.
- T030/T031 (textos, Eduardo) e T036 (textos da abertura, Henrique) tocam
  `l10n/`, em arquivos diferentes.
- O site (Trevisan) usa a Memora exportada da `MemoraAnimada` (S02) e a lista
  de dicas da anfitriã (T086, Henrique).

**Regra de todo portão novo**: commitar, quebrar de propósito, ver reprovar,
desfazer (CLAUDE.md, seção 8). Cada tarefa de teste diz o que quebrar.

**Verificação ao fim de cada fase do tasks**: `flutter analyze`, `flutter test`,
`validar_paleta.py`, `validar_tokens.py` — e reverter `pubspec.lock` e
`android/gradle.properties` se o Flutter da máquina os reescrever.

---

# FASE A — independe da #71

## Phase 1: Setup

- [X] T001 Conferir que a branch `feature/013-redesenho-final` está atualizada com a `develop` e que os quatro portões passam antes de começar (linha de base: 2448 testes em 2026-11-15)
- [X] T002 [P] Acrescentar a `memora-ux` ao CLAUDE.md (seção 3 ou 9) como leitura obrigatória antes de tarefa de tela

---

## Phase 2: Fundação (bloqueia as histórias da Fase A)

- [X] T003 [P] Criar `app/lib/design_system/tokens/cores_da_memora.dart` com os tokens da Memora (`memoraCorpo`, `memoraCorpoSombra`, `memoraVisor`, `memoraOlho`, `memoraDetalhe`, `memoraEscudo`, `memoraSombraChao`) nos temas claro, escuro e alto contraste, exposto pela `ThemeExtension` (R1, R12: arquivo separado até a #71 entrar)
- [X] T004 Acrescentar os pares da Memora ao `specs/002-design-system/ferramentas/validar_paleta.py` (contorno ≥ 3:1 com o fundo, nos 3 temas) e provar quebrando com uma cor de corpo igual ao fundo (FR-007)
- [X] T005 [P] Acrescentar a `app/lib/design_system/tokens/movimento.dart` as durações de gesto (`aceno`, `piscada`, `comemoracao`) e de transição de tela, todas consumidas via `MemoraMovimento.efetiva` (V9)
- [X] T006 [P] Criar `DirecaoDaTransicao` e `GestoDaMemora` (data-model.md) em `app/lib/design_system/navegacao/` e `app/lib/design_system/componentes/ilustracao/memora_animada/`
- [X] T007 Criar o leitor único de "reduzir movimento" (preferência do aplicativo **ou** do sistema) que a Memora, a rota e a troca de destino vão usar, em `app/lib/design_system/preferencias/`, reaproveitando o que `escopo_aparencia.dart` já expõe

**Checkpoint**: tokens, durações e o leitor de movimento prontos.

---

## Phase 3: User Story 1 — A Memora ganha corpo (P1) 🎯 MVP visual

**Goal**: A `MemoraAnimada` existe, com todas as poses, gestos e garantias, e
aparece na galeria. Ela **ainda não substitui** as imagens nas telas (isso é a
T047, Fase B).

**Independent Test**: galeria em depuração mostra a Memora em cada expressão,
nos 3 temas, animando; com "reduzir movimento", parada.

### Testes da US1 (escrever antes e ver falhar)

- [X] T008 [P] [US1] `app/test/design_system/memora_animada_test.dart`: cada `ExpressaoDaMemora` monta sem exceção nos 3 temas e na matriz de tamanhos; quebrar trocando uma pose por `null`
- [X] T009 [P] [US1] No mesmo arquivo: a Memora não aparece na árvore de semântica, nem com toque (V3, FR-005/005b); quebrar tirando o `ExcludeSemantics`
- [X] T010 [P] [US1] No mesmo arquivo: com "reduzir movimento", nenhum `Ticker` ativo e toque não gera gesto (V2, FR-004/005d); quebrar ignorando a preferência
- [X] T011 [P] [US1] No mesmo arquivo: toque dispara aceno/piscada alternados, toques durante o gesto são ignorados, nada navega (V4, FR-005a); quebrar acumulando gestos

### Implementação da US1

- [X] T012 [US1] Definir as poses (`neutra`, `falando`, `pensando`, `comemorando`, `preocupada`, `acenando`, `dica`, `mini`) em `memora_animada/poses.dart`: valores-alvo de olhos, braços, cabeça, escudo e inclinação (data-model.md)
- [X] T013 [P] [US1] Pintores das camadas em `memora_animada/pintores/` — sombra no chão, corpo, cabeça, visor, olhos, antena, braços, escudo — com gradientes de luz de cima à esquerda e cores só de `cores_da_memora.dart`, a partir da folha de expressões de `Memora-Desing-Ideias/` (R1)
- [X] T014 [US1] `memora_animada/memora_animada.dart`: monta as camadas, interpola entre poses, ciclo de "respiração" e de fala (`falando`), leve perspectiva e paralaxe; camada de repintura própria e relógio parado fora da tela (R11, contrato)
- [X] T015 [US1] Gestos de toque (aceno/piscada alternados), com a máquina de estados `ocioso → emGesto → ocioso` (FR-005a, data-model.md)
- [X] T016 [US1] Gesto único `comemoracao` e entrada animada por expressão (FR-003)
- [X] T017 [US1] Pôr a `MemoraAnimada` na `GaleriaMemora` em todas as expressões e gestos, e no teste de completude da galeria (V10 da 002)
- [X] T018 [US1] Conferência visual: gerar capturas da galeria nos 3 temas e **mostrar ao Henrique** antes de seguir para a Fase B (risco do plano: o desenho em código precisa ficar à altura da referência). **Aprovada pelo Henrique em 2026-11-16**, depois do vídeo para a equipe, pedindo **mais animação** (T083) e a anfitriã do Início (fase 3b)

- [X] T083 [US1] **(2026-11-16)** Mais animação em todas as expressões (FR-003a): pequenos movimentos próprios de cada uma — olhar em volta, balançar a antena, piscar, ajeitar o corpo —, sem competir com o texto da tela; nenhum com "reduzir movimento". Teste: com a preferência, nenhum `Ticker` ativo; sem ela, cada expressão tem movimento além da respiração. Conferir no celular

**Checkpoint**: a Memora vetorial está pronta e aprovada na galeria.

---

## Phase 3b: User Story 8 — A anfitriã do Início (P1) — sessão de 2026-11-16

**Goal**: a `MemoraAnfitria`, a Memora do topo do Início: mais detalhada,
mais animada, se mexe sozinha, conta dicas num balão com a boca mexendo,
interativa (FR-048 a FR-058). Componente novo do Design System: **não depende
da `develop`**. Pô-la no Início é a T053.

**Independent Test**: na galeria, a anfitriã se mexe sozinha, troca a dica
depois de 20 s e ao toque; com o leitor de tela, é "Outra dica da Memora" e
nada troca sozinho; com "reduzir movimento", parada.

### Testes da US8 (escrever antes e ver falhar)

- [X] T084 [P] [US8] `app/test/design_system/memora_anfitria_test.dart`: troca a dica aos 20 s (FR-052); **não** troca com leitor de tela, com "reduzir movimento", nem depois de um toque (FR-053); toque mostra a próxima (FR-054); semântica de botão "Outra dica da Memora" com área ≥ 48 dp (FR-055); toque nunca navega (FR-056); boca anima só enquanto o texto aparece (FR-051); nenhum `Ticker` com "reduzir movimento" (FR-057). Quebrar: troca automática ignorando o leitor de tela; tirar o rótulo
- [X] T085 [P] [US8] O portão de texto (`texto_da_interface_test.dart`) passa a cobrir o arquivo das dicas: duas frases, sem palavra proibida, sem emoji; e um teste confere que há pelo menos 3 dicas antigolpe (FR-050)

### Implementação da US8

- [X] T086 [P] [US8] `app/lib/l10n/textos_anfitria.dart`: lista fixa de 12 a 16 dicas na voz da Memora (uso do celular, do Memora e lembretes antigolpe), no máximo duas frases cada, revistas na PR (FR-050)
- [X] T087 [US8] Desenho aprimorado da anfitriã (FR-048) sobre os pintores da `MemoraAnimada`: brilho especular, luz de contorno, sombra de contato, giro de cabeça com o rosto deslizando no visor, corpo que estica e encolhe no pulo; cores só de tokens; mais detalhe sem perder a mesma personagem
- [X] T088 [US8] Comportamento autônomo (FR-049): agenda de comportamentos que se alternam sem padrão óbvio (flutuar, olhar em volta, acenar de vez em quando, inclinar a cabeça, pulinho); parada fora da tela (FR-058); nada com "reduzir movimento"
- [X] T089 [US8] `app/lib/design_system/componentes/ilustracao/memora_anfitria.dart`: anfitriã + balão de dica + boca sincronizada com o texto (FR-051) + troca a cada 20 s com as regras de parada (FR-052, FR-053) + toque como ação acessível que faz um gesto e mostra a próxima (FR-054, FR-055); o leitor de tela anuncia a dica nova só quando a pessoa pediu
- [X] T090 [US8] Galeria e renders da anfitriã; **mostrar ao Henrique no celular** (APK "Memora (teste)") antes da T053 — mesmo portão da T018

**Checkpoint**: a anfitriã aprovada; a T053 a coloca no Início.

---

## Phase 4: User Story 2 — Transições que mostram o caminho (P1)

**Goal**: `RotaMemora`, `TrocaDeDestino` e as transições de diálogo e folha
existem e estão ligadas onde a #71 não interfere (casca, diálogos).

**Independent Test**: navegar pela casca e abrir diálogos; tudo desliza na
direção certa; com "reduzir movimento", instantâneo.

### Testes da US2

- [X] T019 [P] [US2] `app/test/design_system/rota_memora_test.dart`: avançar entra pela direita, voltar pela esquerda, duração ≤ 500 ms, a tela que sai não recebe toque, o gesto de voltar faz a mesma animação (V6); quebrar deixando a tela de saída aceitar toque
- [X] T020 [P] [US2] No mesmo arquivo e em `app/test/design_system/dialogo_test.dart` e `folha_inferior_test.dart` (novos): com "reduzir movimento", troca instantânea; diálogo e folha não movem a tela de trás (V7, V9)
- [X] T021 [P] [US2] Em `app/test/features/casca/casca_interna_test.dart`: trocar de destino preserva a pilha de cada um e desliza pela posição relativa (V8); quebrar trocando por um `AnimatedSwitcher` que recria os filhos

### Implementação da US2

- [X] T022 [US2] `app/lib/design_system/navegacao/rota_memora.dart`: `RotaMemora<T>` com deslizamento e paralaxe, duração por `MemoraMovimento.efetiva`, bloqueio de toque na tela de saída, e o `TransicaoMemora` para o tema (contrato; o registro no tema é a T049)
- [X] T023 [US2] `app/lib/design_system/navegacao/troca_de_destino.dart`: filhos vivos, deslizamento pela posição, fora da tela sem animar e sem foco (R3)
- [X] T024 [US2] `app/lib/features/casca/casca_interna.dart`: trocar o `IndexedStack` pela `TrocaDeDestino` e o `MaterialPageRoute` da raiz pela `RotaMemora`
- [X] T025 [P] [US2] `app/lib/design_system/componentes/dialogos/dialogo.dart` e `folha_inferior.dart`: transições de sobreposição (centro e de baixo) com `MemoraMovimento.efetiva` (R4)
- [X] T026 [P] [US2] Trocar os `MaterialPageRoute` de `tela_dispositivo_cuidado.dart`, `secao_idade.dart` e **`secao_foto_perfil.dart`** (pré-visualização da foto, #73) pela `RotaMemora` (o de `fluxo_autenticacao.dart` é a T050) **(rev. 16/11)**
- [X] T027 [US2] Rodar a suíte inteira: testes que dependiam do zoom do Android ou de `pumpAndSettle` com duração fixa são ajustados na mesma tarefa (não afrouxar asserção)

**Checkpoint**: navegação com direção onde a #71 não interfere.

---

## Phase 5: User Story 3 — Texto curto, que ajuda e não diminui (P1) — parte A

**Goal**: o portão de texto existe e passa nos arquivos que a #71 não toca; o
servidor não manda mais emoji em mensagem de tela.

**Independent Test**: `texto_da_interface_test.dart` passa sobre `textos_ajuda`,
`textos_apresentacao`, `textos_autenticacao`, `textos_configuracoes` e
`textos_perfil`; o teste do backend passa.

- [X] T028 [US3] `app/test/design_system/texto_da_interface_test.dart`: varredura lexical (R6) — mais de 2 frases, palavras/frases proibidas da memora-ux, emoji fora da fala da IA — sobre a **lista de arquivos da Fase A** (a lista cresce na T068); provar quebrando com um bloco de 3 frases, um "idoso" e um emoji
- [X] T029 [US3] Rodar o portão e listar os blocos reprovados em `textos_ajuda.dart`, `textos_apresentacao.dart`, `textos_autenticacao.dart`, `textos_configuracoes.dart` e `textos_perfil.dart`
- [X] T030 [P] [US3] Reescrever os reprovados de `textos_autenticacao.dart` e `textos_perfil.dart` (duas frases, voz da Memora; excedente vira etapa ou "Saber mais"; o necessário para decidir continua visível — FR-017)
- [X] T031 [P] [US3] Reescrever os reprovados de `textos_ajuda.dart`, `textos_apresentacao.dart` e `textos_configuracoes.dart` (mesmas regras)
- [X] T032 [US3] Onde um texto virou "Saber mais" ou etapa, ajustar a tela correspondente (só telas que a #71 não altera; as outras vão para a T069) e os testes que procuravam a frase antiga
- [X] T033 [P] [US3] Backend: `TextoDaInterfaceTest` varrendo `CodigoDeErro` e as mensagens dos controladores atrás de emoji; provar quebrando
- [X] T034 [US3] Backend: tirar o "😊" das mensagens que chegam à tela (FR-020) e conferir as duas frases delas. **(rev. 16/11)** Na `develop` são 6 arquivos: `CodigoDeErro` (6 ocorrências), `ControladorRecuperacao` (4), `ServicoDeCadastro` (2), `ControladorCanais` (1), `ControladorRegistro` (1); as 2 do `ClienteDaAssistenteSimulado` são fala da IA e ficam (no máximo uma por mensagem, T042)

**Checkpoint**: o portão de texto existe e protege o que já foi revisto.

---

## Phase 6: User Story 7 — A abertura com a Memora acenando (P1) — parte A

**Goal**: o aplicativo abre com a Memora acenando enquanto carrega.

**Independent Test**: abrir a frio no celular: Memora parada (nativo) → Memora
acenando → fluxo de entrada, sem pulo.

- [X] T035 [P] [US7] `app/test/features/abertura/abertura_memora_test.dart`: sai só quando carregou **e** o aceno completou; frase de "quase pronta" aos 4 s; falha leva à tela de erro; com "reduzir movimento" do sistema, pose parada (V12); quebrar saindo antes do carregamento terminar
- [X] T036 [US7] `app/lib/features/abertura/presentation/abertura_memora.dart` conforme o contrato, com textos novos em `app/lib/l10n/` (duas frases, voz da Memora)
- [X] T037 [US7] `app/lib/main.dart`: chamar o `runApp` com a `AberturaMemora` **antes** de carregar preferências e composição; o carregamento atual passa para dentro dela, sem mudar a ordem nem o que é carregado
- [X] T038 [P] [US7] Abertura nativa: `android/app/src/main/res/drawable/launch_background.xml` (e `drawable-v21`, `values-night`) com o fundo do tema e a Memora parada como desenho vetorial do Android, na mesma posição do aceno; Android 12+ com `windowSplashScreen*` sobre o mesmo fundo (FR-037, R9)
- [ ] T039 [US7] Medir no celular (APK de release) o tempo até a tela de entrada, antes e depois, e registrar no `quickstart.md` (SC-009)

**Checkpoint**: abertura pronta.

---

## Phase 7: User Story 4 — Conversa — parte A (emoji)

- [X] T040 [P] [US4] `app/test/features/assistente/limitar_emoji_test.dart`: zero, um e vários emojis; emoji composto (com modificador de tom e com junção) conta como um; sem espaço duplo (V11); quebrar devolvendo o texto sem filtro
- [X] T041 [US4] `app/lib/features/assistente/domain/limitar_emoji.dart` (contrato) e aplicá-lo no texto exibido da resposta em `texto_da_fala.dart` (FR-024)
- [X] T042 [P] [US4] Backend: regra "no máximo um emoji por mensagem, nunca no lugar de uma palavra" em `PersonaDaMemora.java`, com teste em `PersonaDaMemoraTest`; conferir que as falas do `ClienteDaAssistenteSimulado` obedecem (FR-023)

---

## Phase 8: Fechamento da Fase A

- [ ] T043 Rodar os quatro portões e a suíte do backend (`mvnw clean test`, com Docker de pé)
- [ ] T044 Gerar o álbum de telas e conferir as telas tocadas na Fase A contra a checagem da memora-ux (seção 5)
- [ ] T045 APK de release no S20 FE: abertura, transições da casca, diálogos e a Memora na galeria; registrar em `revisao-de-design.md` da 004 ou num arquivo da 013
- [X] T046 ~~PR da Fase A para a `develop`~~ **Substituída (2026-11-17, decisão do Henrique)**: com a branch comum `redesign-final`, as fases A e B vão juntas para a `develop` numa PR só, ao fim do redesenho; cada frente entra antes na `redesign-final` por PR revisada por outra pessoa

---

# FASE B — tocava o que a #71 reescrevia (já na `develop`)

> **Revisada em 2026-11-16** contra a `develop` `c74da78`: os nomes e as
> premissas abaixo foram conferidos no código. Antes de começar, a branch
> precisa ter recebido a `develop` (T080).

- [X] T080 Trazer a `develop` para a `feature/013-redesenho-final` **depois** que a `feature/004-prints-e-zoom` (com os guias integrados ao modelo da 004) entrar nela; rodar os quatro portões. Conflito esperado em `validar_paleta.py` (os pares da Memora daqui × os tokens da 007): somar os dois **(rev. 16/11)**

## Phase 9: Integração com a 007

- [X] T047 [US1] `memora_personagem.dart`: a `MemoraPersonagem` passa a montar uma `MemoraAnimada`, com a mesma assinatura e o mesmo enum (inclusive `dica` e `mini` da #71); o leitor de tela continua igual
- [X] T048 [US1] Mover os tokens de `cores_da_memora.dart` para o esquema de cores da #71 (`cores.dart`) e apagar o arquivo separado; `validar_paleta.py` continua passando. **(rev. 16/11)** O `MemoraTheme.comPaleta(nome)` recebe o nome da paleta mas não o guarda: guardar o nome no tema e trocar a descoberta da paleta "pela cor primária" (frágil) por ele
- [X] T049 [US2] Registrar a `TransicaoMemora` como transição de página padrão em `temas_memora.dart` (cobre toda rota de página que restar, inclusive as da #71)
- [X] T050 [US2] Trocar o `MaterialPageRoute` de `fluxo_autenticacao.dart` pela `RotaMemora`
- [X] T051 [US1] Remover os PNGs da Memora de `app/assets/ilustracoes/` que não forem mais usados, e o registro deles no `pubspec.yaml` (o ícone do aplicativo continua); conferir que nenhum teste os carrega
- [X] T052 [US1] `memora_distancia_test.dart`: em cada tela em que a Memora aparece, a área dela fica a ≥ 8 dp de qualquer alvo de toque, na matriz de aparelhos (V5, FR-005c); quebrar encostando a Memora num botão

## Phase 10: User Story 7 — Início e barra inferior (P1) — parte B

- [X] T053 [US7] Início: a Memora em 2.5D no terço superior com a saudação, sobre a estrutura da 007 (cartão herói e atalhos abaixo) (FR-040). **(rev. 16/11)** Na `develop`, o cabeçalho da `tela_inicio.dart` tem uma `MemoraPersonagem` **`mini`** ao lado da saudação, depois o `CartaoHeroi` e a grade 2×2 de `TileAcaoRapida`: a Memora grande **substitui** a `mini` (uma Memora por tela, FR-006). **(2026-11-16)** A anfitriã só segura a dica quando o toque é nela ou no balão: a T053 precisa passar a ela um sinal de atividade do Início, para a FR-052 valer para toques em qualquer lugar da tela. **(2026-11-16)** A Memora do topo é a **`MemoraAnfitria`** (fase 3b, T089), não a `MemoraAnimada` comum
- [X] T054 [US7] Com a anfitriã (balão de ~134 dp, medido pela dica mais longa) o Início passou a rolar no aparelho de referência; o `inicio_ocupa_a_altura_test` trocou a asserção "sobra ≥ 0" por "se rola, tudo alcançável". **(2026-11-17) O Henrique aceitou a rolagem**: FR-040 revista e registrada no clarify. Início: com letra ampliada, a área da Memora encolhe antes de qualquer texto ou ação sair do alcance (FR-041, V13). **Provado quebrando** em 2026-11-17: com a altura da anfitriã fixa (sem dividir pela ampliação), 12 casos reprovam ("o desenho dela não é a fração da altura", 85,2 dp contra 56,8 a 150%). As duas Memoras das boas-vindas saíram daqui para a T093
- [X] T093 [US7] **(2026-11-17, separada da T054)** As boas-vindas mostram duas Memoras, contra a FR-006: deixar uma só, com teste que reprove se aparecer a segunda. **Feita em 2026-11-17**: ficou a do cabeçalho; saiu a `dica` do bloco "o que vou ensinar". Provado quebrando (com a segunda de volta, `Found 2 widgets with type "MemoraAnimada"`)
- [X] T055 [P] [US7] `app/test/design_system/navegacao_inferior_test.dart` (novo): ícone + rótulo juntos, alvo ≥ 48 dp, indicador desliza até o destino tocado, sem deslizar com "reduzir movimento" (V15); quebrar tirando o rótulo
- [X] T056 [US7] `navegacao_inferior.dart`: barra refeita no acabamento da 007 (superfície, sombra, cantos), ícones arredondados da família única no lugar dos SVG de `assets/icones/navegacao/`, indicador deslizante e resposta ao toque (FR-044 a FR-047, R5)
- [X] T057 [US7] Apagar `assets/icones/navegacao/` e ajustar `icones_de_navegacao_test.dart` (o teste passa a conferir a família, não os arquivos). **Feitas em 2026-11-17 (T055–T057)**: traço e pílula andam juntos (`AnimatedPositioned`), itens com `SuperficieTocavel`, sombra e cantos de cima; provado quebrando (sem rótulo, sem deslizar, deslizando com "reduzir movimento"). O ícone preenchido deixou de ser sinal do destino atual (a família `_rounded` não tem contorno para estes três): restam o traço, a pílula, o rótulo em negrito e o `selected` do leitor de tela

## Phase 11: User Story 4 — Conversa limpa (P2)

- [X] T058 [US4] `tela_conversa.dart`: só o essencial — cabeçalho, aviso compacto, mensagens, campo; sugestões só antes da primeira mensagem; nenhum elemento decorativo (FR-043)
- [ ] T059 [US4] A Memora pequena no topo da conversa, `falando` enquanto a resposta aparece letra a letra, sem rosto ao lado de cada balão (FR-025, FR-042); ajustar `balao_de_fala.dart`
- [X] T060 [US4] Ícones da conversa (enviar, ditar, sugestões, aviso) da família única, com texto e resposta ao toque (FR-029)
- [X] T061 [US4] Atualizar `conversa_acessibilidade_test.dart` e a matriz: o aviso continua encolhendo e não sumindo (FR-026), a lista de mensagens mantém a altura mínima (V14)
- [X] T062 [US4] Voz: **(rev. 16/11) já implementada na #71** — `leitor_de_voz_nativo.dart` usa `onDevice: true` e não repete pela nuvem, com `ditado_por_voz_test.dart`. Falta: **provar o teste quebrando** (tirar o `onDevice` e ver reprovar) e conferir no aparelho sem reconhecimento local que o botão fica indisponível com o motivo em uma frase e que digitar continua (FR-034, V16)

## Phase 12: User Story 5 — Ícones e toque (P2)

- [ ] T063 [P] [US5] Teste lexical: nenhum `Icons.` fora da variante arredondada em `app/lib/` e nenhum `Image.asset` de ícone ou ilustração fora das capturas dos guias (FR-027, FR-030); quebrar com um `Icons.home`
- [ ] T064 [US5] Trocar os ícones restantes para a variante arredondada e os SVG antigos de ilustração (`porta_*.svg`, `casal_idoso.svg`, `memora_*.svg`) por desenhos da família ou pela `MemoraAnimada`. **(rev. 16/11)** Volume medido na `develop`: **128 usos** de `Icons.` fora da variante arredondada (os mais comuns: `arrow_forward`, `shield_outlined`, `check`, `check_circle_outline`, `chat_bubble_outline`) — tarefa mecânica, boa para agente
- [ ] T065 [US5] `superficie_tocavel.dart` (versão da #71): resposta ao toque também com "reduzir movimento" (realce sem afundar), e teste que reprova sem resposta (FR-028)

## Phase 13: User Story 3 — Texto — parte B

- [ ] T066 [P] [US3] Reescrever os reprovados de `textos_assistente.dart` e `textos_casca.dart` (versões da #71)
- [ ] T067 [US3] Reescrever os passos dos guias em `textos_guias.dart` e em `features/aprendizado/data/guias/*.dart` que passarem de duas frases, dividindo em passos quando preciso (FR-022); a captura de cada passo continua batendo com o texto
- [ ] T068 [US3] Estender a lista de arquivos do `texto_da_interface_test.dart` para **todos** os arquivos de `l10n/` e de `guias/`; o portão passa sobre o aplicativo inteiro (SC-002)
- [ ] T069 [US3] Ajustar as telas que a #71 alterou onde texto virou "Saber mais" ou etapa
- [ ] T070 [US3] FR-035: frase na apresentação ("a Memora só fala com você dentro do aplicativo") em `textos_apresentacao.dart` e `fluxo_apresentacao.dart`, com teste (V17)

## Phase 14: User Story 6 — Nenhuma tela fica de fora (P3)

- [ ] T071 [P] [US6] Localizador (`tela_localizador.dart`) e os diálogos de permissão de localização, rota e ligação na linguagem da 013: Memora, transições, ícones, texto; sem mudar o comportamento da 009 (FR-031, FR-032)
- [ ] T072 [P] [US6] Seletor de seções e passo a passo: Memora `comemorando` na conclusão (FR-003), transição de avançar/voltar entre passos com a `RotaMemora` ou equivalente
- [ ] T092 [US7] **(2026-11-16, pedido do Henrique)** A `AberturaMemora` passa a usar o desenho da **anfitriã** (FR-048) **segurando a barra de carregamento** entre as mãos, no lugar da Memora comum só acenando. A barra é indeterminada enquanto carrega; com "reduzir movimento" fica parada e a Memora também; o leitor de tela ouve "Abrindo o Memora." (já existe). A saída continua "carregou e completou o gesto", sem prolongar de propósito (FR-038). A abertura nativa do Android (`memora_abertura*.xml`) **fica como está**. Testes da abertura atualizados (com `movimentoLiberado()`) e prova quebrando
- [ ] T091 [US2] **(2026-11-16, achado na T025)** Os `showDialog` crus de `dialogo_contato_emergencia.dart` (Cuidado — Henrique) e de `tela_localizador.dart` (Eduardo, junto da T071) passam a abrir pela transição de sobreposição do `Dialogo`: hoje ficam sem a animação nova e com 150 ms fixos mesmo com "reduzir movimento" (contra a FR-013). Se o conteúdo deles for mais rico que o do `DialogoMemora`, dar a ele um construtor de conteúdo livre. **(2026-11-17) Parte do Henrique feita**: `DialogoMemora.mostrarConteudo<T>(context, construtor:)` para conteúdo livre (o `mostrar` passa por ele), e o `dialogo_contato_emergencia` abre por ele; provado quebrando. **Falta a parte do Eduardo** (`tela_localizador.dart`, junto da T071), que já pode usar o `mostrarConteudo`
- [ ] T081 [P] [US6] **(rev. 16/11)** Telas da foto de perfil (#73) — `SecaoFotoPerfil`, `TelaPreVisualizacaoFoto`, `RetratoDoPerfil` e os textos novos de `textos_perfil.dart` — na linguagem da 013 (transições, ícones, duas frases), sem mudar o comportamento da spec 011. No Perfil, o topo é o **retrato da pessoa** (decisão da integração das #71 e #73): a Memora não aparece ali
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
  - A T018 (aprovação visual da Memora) é **portão** para a Fase B. ✅ aprovada em 2026-11-16.
  - A fase 3b (anfitriã, T083–T090) é componente novo e pode andar já; a
    T090 (aprovação dela no celular) é portão da T053.
- **Fase B** (revisada em 2026-11-16): T080 (receber a `develop`, depois da
  PR da `feature/004-prints-e-zoom`) → integração (T047–T052) → US7-B, US4-B,
  US5, US3-B e US6 (inclui T081) em paralelo → validação final.
- **T082 — fora do escopo, registrado para não perder** (rev. 16/11): o site
  da #74 (`site/`, spec 012) usa os PNGs antigos da Memora e diz "Pessoas
  Idosas" no título. Quando a Memora vetorial for aprovada (T018), o site
  precisa de imagens novas e do texto revisto — trabalho da spec 012, não
  desta.

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
