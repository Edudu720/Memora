# Feature Specification: Redesenho final — a Memora ganha corpo, movimento e voz

**Feature Branch**: `feature/013-redesenho-final`

**Created**: 2026-11-15

**Status**: Aprovada pelo Henrique para implementar a Fase A até a T018 (2026-11-15); ratificação de Eduardo e Trevisan pendente

**Input**: Ideias do Henrique em 2026-11-15: "telas de blocos simples porém
sofisticados, com estética de software atual, UI/UX limpa e entendível. Os
tamanhos moldados conforme a escolha do usuário, porém evitando caixas de texto
longas — parecer um software dos anos 2000 é tudo o que não queremos. O sistema
padronizado, com estética moderna. Nunca telas dizendo que a pessoa é incapaz:
sempre que a Memora vai ajudar. Sem emoticons na interface; eles ficam para a
IA. Quando houver balões de fala da Memora, um robô em 2.5D com animações, para
deixar mais cinemático e interativo. A cada mudança de tela, animações fluidas,
como se estivesse arrastando, não jogada na tela. A tela da IA o mais limpa e
sólida possível, com ícones e vetores interativos, não PNGs soltos."

**Regras de UI/UX**: [`.claude/skills/memora-ux/SKILL.md`](../../.claude/skills/memora-ux/SKILL.md).
Esta spec as aplica; a skill é a fonte delas.

---

## Relação com a feature 007

A 007 (Design System 2.0, do Eduardo, na PR #71) redesenha superfícies,
cartões, barra inferior, Início, Hub, Conversa, catálogos, Cuidado e as telas de
conta. **Esta feature continua a 007, não a refaz.** O que a 007 decide sobre
superfícies, componentes e estrutura das telas vale aqui sem repetição.

Esta feature **substitui** dois pontos da 007 e **acrescenta** o resto:

| Ponto da 007 | Aqui | Por quê |
|---|---|---|
| FR-006: a Memora em imagens paradas (6 expressões) | **Substituído** pela FR-001 a FR-008: a Memora em 2.5D, animada | Pedido do Henrique; imagem parada é o "PNG solto" que ele quer eliminar |
| FR-013: ditado por voz, sem exigir processamento no aparelho | **Restringido** pela FR-034 | Decisão de 2026-10-03: a voz é processada no aparelho; áudio não sai para terceiros |
| — | **Acrescentado**: transições (US2), regras de texto (US3), ícones vetoriais interativos (US5), Localizador e telas novas na mesma linguagem (US6) | A 007 não trata de movimento, de texto nem das telas da 009 |

## Clarifications

> **Renumerada de 010 para 013 em 2026-11-16**: a PR #71 trouxe para a
> `develop` a `specs/010-revisao-pr71-localizador`, e 011 e 012 já eram a foto
> de perfil e o site. Os commits anteriores a esta data dizem "010".

### Session 2026-11-15

- Q: Como a Memora em 2.5D animada vai ser produzida? → A: Redesenhada como
  desenho vetorial com volume (camadas de luz e sombra), animada pelo próprio
  aplicativo, a partir da folha de expressões de referência; sem depender de
  artista externo e sem imagem solta (FR-001, FR-027).
- Q: A Memora reage quando a pessoa toca nela? → A: Sim, com um gesto curto
  (aceno ou piscada), sem abrir nada nem mudar de tela (FR-005a a FR-005d).
- Q: A regra das duas frases vale para os textos dos guias? → A: Vale; os
  passos que passarem de duas frases são reescritos ou divididos (FR-022).
- Q: A apresentação diz que a Memora só fala dentro do aplicativo? → A: Sim,
  incluir (FR-035).
- Pedido do Henrique durante o plano: ao abrir o aplicativo, uma tela de
  carregamento com a Memora acenando (FR-036 a FR-039). Ela é animada em vetor,
  como o resto da Memora, e não um GIF — que seria imagem solta e não
  respeitaria "reduzir movimento".
- Pedido do Henrique: no Início, a Memora em 2.5D cobre a parte superior da
  tela (FR-040, FR-041).
- Pedido do Henrique: a tela da conversa mais limpa, para preservar a
  interface (FR-042, FR-043).
- Pedido do Henrique: a barra inferior (Ajustes, Início, Meu perfil) refeita no
  padrão estético do resto (FR-044 a FR-047).
- Q (resolvida sem pergunta, pela decisão de 2026-10-03): o ditado por voz pode
  usar reconhecimento fora do aparelho? → A: Não; só no aparelho, senão o
  ditado fica indisponível (FR-034).

### Session 2026-11-16

- T018: o Henrique **aprovou** a Memora vetorial (as expressões), pedindo
  **mais animação** em todas (FR-003a).
- Pedido do Henrique: no Início, logo depois de entrar, a Memora é a
  **anfitriã** — mais bem desenhada, "3D", bem mais animada que as outras, se
  mexendo sozinha, com balões de dicas que mudam ao longo do tempo, a boca
  animada enquanto fala, e interativa (tocar muda a fala ou faz um gesto).
  "Se ficar pesado e ir contra a constituição, pode ser 2.5D." → **Decisão:
  2.5D aprimorada** (FR-048). 3D de verdade exigiria motor 3D experimental ou
  visualizador web com biblioteca de fora (peso no aparelho de entrada, rede,
  privacidade) e um modelo 3D da Memora que a equipe não tem; o 2.5D com luz,
  brilho, sombra de contato e giro de cabeça entrega a sensação de volume sem
  dependência nova (FR-048 a FR-058).
- Consequências que a constituição impõe ao pedido: a dica que troca sozinha
  precisa poder parar (WCAG 2.2.2, FR-052/053); o toque na anfitriã vira uma
  **ação** ("outra dica") e por isso ganha rótulo e área de toque (FR-055),
  diferente das outras Memoras; as dicas vêm de lista fixa no aplicativo,
  nunca da IA nem do servidor (FR-050).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — A Memora ganha corpo (Priority: P1)

A pessoa abre o Memora e é recebida pela Memora — o robô que já é a identidade
do aplicativo — agora em 2.5D, viva: ela acena ao chegar, mexe-se enquanto o
balão de fala aparece, comemora quando a pessoa termina um passo a passo e fica
atenta, com o escudo, ao lado de um aviso de segurança. A pessoa sente que tem
companhia, e não que está lendo um manual.

**Why this priority**: É a mudança que mais transforma a percepção do
aplicativo, e a Memora aparece em quase todas as telas em que o Memora fala com
a pessoa. Sem ela, o redesenho fica só em superfície.

**Independent Test**: Abrir a apresentação, a conversa e o fim de um passo a
passo; em cada uma, a Memora aparece animada com a expressão que combina com o
texto. Com "reduzir movimento" ligado no aparelho, ela aparece parada na mesma
expressão, e nenhuma informação se perde.

**Acceptance Scenarios**:

1. **Given** uma tela em que a Memora fala (balão), **When** a tela abre,
   **Then** a Memora aparece em 2.5D, com uma animação de entrada curta e a
   expressão correspondente ao momento (repouso, falando, pensando, comemorando,
   preocupada).
2. **Given** um balão de fala que aparece aos poucos, **When** o texto está
   sendo mostrado, **Then** a Memora "fala" junto e para quando o texto termina.
3. **Given** a pessoa terminou um passo a passo, **When** a tela de conclusão
   abre, **Then** a Memora comemora uma vez e volta ao repouso.
4. **Given** "reduzir movimento" ligado no aparelho, **When** qualquer tela com a
   Memora abre, **Then** ela aparece parada na expressão certa, sem nenhum
   movimento.
5. **Given** o leitor de tela ligado, **When** a pessoa passa pela Memora,
   **Then** o leitor não repete o que o balão já diz e não anuncia a animação.
6. **Given** a Memora em repouso, **When** a pessoa toca nela, **Then** ela
   acena ou pisca e volta ao que estava, sem abrir nada nem mudar de tela.

---

### User Story 2 — Transições que mostram o caminho (Priority: P1)

Cada mudança de tela acontece como se a pessoa arrastasse uma folha: a tela
nova desliza para dentro, e a direção diz o que aconteceu. Avançar vem da
direita, voltar vem da esquerda, uma pergunta ou aviso sobe de baixo. A pessoa
nunca é "teletransportada" para outro lugar sem entender como chegou ali.

**Why this priority**: Para quem tem dificuldade de se orientar no celular, a
troca brusca de tela é uma das maiores fontes de "onde eu estou?". A direção
do movimento é uma pista de navegação que não exige leitura.

**Independent Test**: Navegar do Início até um passo a passo e voltar; abrir e
fechar uma confirmação. Cada troca desliza na direção certa. Com "reduzir
movimento" ligado, as trocas viram troca suave ou instantânea, e a navegação
continua igual.

**Acceptance Scenarios**:

1. **Given** a pessoa toca numa ação que leva adiante, **When** a tela nova
   abre, **Then** ela entra deslizando da direita, e a anterior sai pela
   esquerda, num movimento contínuo.
2. **Given** a pessoa toca em "Voltar" (ou usa o gesto de voltar do aparelho),
   **When** a tela anterior volta, **Then** o movimento é o inverso.
3. **Given** um diálogo, confirmação ou folha de opções, **When** abre, **Then**
   sobe de baixo (ou surge no centro) por cima da tela atual, sem que a tela de
   trás deslize.
4. **Given** a troca de destino na barra inferior, **When** a pessoa toca noutro
   destino, **Then** a transição respeita a posição relativa (o destino à
   direita entra pela direita).
5. **Given** "reduzir movimento" ligado, **When** qualquer troca acontece,
   **Then** não há deslizamento; a troca é suave ou instantânea.
6. **Given** um aparelho de entrada, **When** as transições acontecem, **Then**
   não há engasgo perceptível, e um toque durante a transição não se perde nem
   é aplicado à tela errada.

---

### User Story 3 — Texto curto, que ajuda e não diminui (Priority: P1)

Todo texto que a pessoa lê é curto, em blocos de no máximo duas frases, na voz
da Memora: "Eu te mostro", "Vamos ver juntos". Nenhuma frase sugere que a
pessoa não consegue. Quem escolhe letra grande vê os mesmos blocos curtos, só
maiores. Explicação longa vira etapa ou fica em "Saber mais".

**Why this priority**: As "caixas de texto longas" são o principal traço de
"software dos anos 2000" que o Henrique quer eliminar, e a frase que diminui a
pessoa é o que faz alguém fechar o aplicativo e não voltar.

**Independent Test**: Varrer todos os textos visíveis do aplicativo. Nenhum
bloco tem mais de duas frases; nenhum contém as palavras e expressões proibidas
pela memora-ux; nenhum título, botão, rótulo ou aviso tem emoji.

**Acceptance Scenarios**:

1. **Given** qualquer bloco de texto da interface, **When** exibido, **Then**
   tem no máximo duas frases curtas.
2. **Given** um conteúdo que precisa de mais explicação, **When** a tela é
   desenhada, **Then** o excedente fica numa etapa seguinte ou num "Saber mais"
   que a pessoa abre se quiser — e o essencial para decidir nunca fica escondido.
3. **Given** qualquer texto visível, **When** revisado, **Then** não contém
   "idoso", "terceira idade", "melhor idade", "sênior" nem frase que sugira
   incapacidade.
4. **Given** um aviso de segurança, **When** exibido, **Then** também respeita
   as duas frases — o aviso curto é o que é lido.
5. **Given** a letra ampliada a 200%, **When** a tela é exibida, **Then** os
   blocos crescem sem cortar texto, e a tela continua utilizável.

---

### User Story 4 — A conversa com a Memora, limpa e sólida (Priority: P2)

A tela de conversa fica limpa: só o essencial, balões bem espaçados, a Memora
pequena no topo — falando enquanto a resposta aparece —, ícones vetoriais que
respondem ao toque, nenhuma imagem solta. A Memora pode usar um emoji de vez em quando, nunca mais de um por
mensagem e nunca no lugar de uma palavra.

**Why this priority**: A conversa é a tela mais usada e a que o Henrique citou
nominalmente. Fica em P2 porque a estrutura dela já é redesenhada pela 007;
aqui entra o acabamento.

**Independent Test**: Conversar com a Memora; conferir que as respostas trazem
no máximo um emoji, que todo controle tem ícone vetorial com texto e resposta
ao toque, e que o aviso antigolpe continua visível e não dispensável.

**Acceptance Scenarios**:

1. **Given** uma resposta da Memora, **When** exibida, **Then** tem no máximo um
   emoji, e nenhuma informação depende dele.
2. **Given** qualquer controle da conversa (enviar, ditar, sugestões, aviso),
   **When** tocado, **Then** dá resposta visual imediata e tem ícone vetorial
   acompanhado de texto.
3. **Given** a conversa aberta, **When** a pessoa rola, **Then** o aviso
   antigolpe continua disponível como hoje (encolhe, não some).
4. **Given** o ditado por voz, **When** o aparelho não tem reconhecimento de voz
   no próprio aparelho, **Then** o botão de ditar não aparece (ou aparece
   desabilitado com o motivo), e o áudio nunca é enviado para fora do aparelho.

---

### User Story 5 — Ícones e ilustrações vetoriais, vivos ao toque (Priority: P2)

Em todo o aplicativo, ícones e ilustrações são desenhos vetoriais da mesma
família, nítidos em qualquer tamanho, e respondem quando a pessoa toca — um
leve afundar, um brilho, um movimento curto. Nada de imagem recortada colada
na tela.

**Why this priority**: É o acabamento que separa "aplicativo atual" de
"protótipo". Fica em P2 porque depende do sistema visual da 007 estar no lugar.

**Independent Test**: Percorrer as telas principais; nenhuma mostra imagem
solta no lugar de ícone ou ilustração (exceto as capturas dos guias), e todo
elemento tocável reage ao toque.

**Acceptance Scenarios**:

1. **Given** qualquer tela, **When** exibida, **Then** ícones e ilustrações são
   vetoriais e da mesma família visual.
2. **Given** qualquer elemento tocável, **When** a pessoa toca, **Then** há
   resposta visual imediata, também com "reduzir movimento" ligado (resposta
   sem movimento: mudança de cor ou de sombra).
3. **Given** os guias passo a passo, **When** exibidos, **Then** as capturas de
   tela continuam fotos reais da tela (não são vetorizadas).

---

### User Story 6 — Nenhuma tela fica de fora (Priority: P3)

Todas as telas do aplicativo — as que existem hoje e as que chegam com a #71
(Localizador, seus diálogos e o seletor de seções dos guias) — usam a mesma
linguagem: mesmos blocos, mesma Memora, mesmas transições, mesma voz.

**Why this priority**: Um sistema só (memora-ux, princípio 3). Fica em P3
porque depende de as outras histórias estarem prontas para ser aplicadas.

**Independent Test**: Percorrer o álbum de telas do aplicativo inteiro e
conferir cada tela contra a lista de checagem da memora-ux.

**Acceptance Scenarios**:

1. **Given** o álbum de todas as telas, **When** revisado, **Then** cada uma
   passa nos 7 itens da checagem da memora-ux.
2. **Given** o Localizador e seus diálogos, **When** exibidos, **Then** seguem a
   mesma linguagem, sem alterar o comportamento definido na feature 009.

---

### User Story 7 — A Memora recebe a pessoa e mora no topo do Início (Priority: P1)

Ao abrir o aplicativo, a primeira coisa que a pessoa vê é a Memora acenando,
enquanto o Memora termina de carregar. Ao chegar no Início, a Memora em 2.5D
ocupa a parte de cima da tela, grande e presente, com a saudação; os atalhos
ficam logo abaixo. A barra inferior, com Ajustes, Início e Meu perfil, tem o
mesmo acabamento do resto: ícones da mesma família, o item ativo bem marcado e
uma resposta suave ao toque.

**Why this priority**: É a primeira impressão e a tela mais vista. O Henrique
pediu os três pontos nominalmente.

**Independent Test**: Abrir o aplicativo a frio: aparece a Memora acenando até
o aplicativo estar pronto, e em seguida o Início com a Memora no topo. Trocar
de destino na barra inferior: o item ativo muda com movimento e o rótulo
continua escrito.

**Acceptance Scenarios**:

1. **Given** o aplicativo fechado, **When** a pessoa o abre, **Then** vê a
   Memora acenando, sem texto técnico nem barra de progresso numérica, até o
   aplicativo estar pronto.
2. **Given** o aplicativo pronto antes de o aceno terminar, **When** o aceno
   completa, **Then** a tela de carregamento sai com uma transição suave — sem
   esperar além de um aceno completo.
3. **Given** "reduzir movimento" ligado, **When** o aplicativo abre, **Then** a
   Memora aparece parada, acenando em pose fixa.
4. **Given** o Início em 100% de letra, **When** abre, **Then** a Memora em 2.5D
   ocupa a parte superior da tela, com a saudação, e os atalhos ficam abaixo
   sem rolagem no aparelho de referência.
5. **Given** o Início com letra a 200%, **When** abre, **Then** a Memora
   encolhe para dar lugar ao texto, e nenhuma ação some.
6. **Given** a barra inferior, **When** a pessoa toca noutro destino, **Then** o
   indicador do item ativo desliza até ele, o ícone responde ao toque, e ícone
   e rótulo continuam juntos.

---

### User Story 8 — A anfitriã do Início (Priority: P1)

Logo depois de entrar, a pessoa encontra a Memora no topo do Início, viva: ela
flutua, olha em volta, acena de vez em quando e conta uma dica num balão,
mexendo a boca enquanto fala. De tempos em tempos a dica muda. Se a pessoa
tocar nela, a Memora faz um gesto e conta outra. A pessoa sente que tem
companhia, e aprende alguma coisa só de abrir o aplicativo.

**Why this priority**: É a tela mais vista e o primeiro contato depois de
entrar; o Henrique pediu nominalmente (sessão de 2026-11-16).

**Independent Test**: Entrar e ficar no Início: a anfitriã se mexe sozinha e
troca a dica depois de 20 s; tocar nela troca na hora. Com o leitor de tela,
ela é anunciada como "Outra dica da Memora" e a dica não troca sozinha. Com
"reduzir movimento", ela fica parada e as dicas só trocam ao toque.

**Acceptance Scenarios**:

1. **Given** o Início aberto, **When** passam 20 s sem toque, **Then** o balão
   troca de dica com transição suave, e a boca da anfitriã se mexe enquanto o
   texto novo aparece.
2. **Given** a pessoa tocou na anfitriã, **When** ela toca, **Then** a
   anfitriã faz um gesto e mostra outra dica, e dali em diante só troca quando
   a pessoa pedir.
3. **Given** o leitor de tela ligado, **When** a pessoa chega à anfitriã,
   **Then** ouve a dica e a ação "Outra dica da Memora", e nada troca sozinho.
4. **Given** "reduzir movimento" ligado, **When** o Início abre, **Then** a
   anfitriã aparece parada, e as dicas continuam disponíveis pelo toque.
5. **Given** qualquer dica, **When** exibida, **Then** tem no máximo duas
   frases e vem da lista fixa do aplicativo.

---

### Edge Cases

- **Carregamento demorado** (aparelho lento): a Memora continua acenando de
  forma calma (sem acelerar nem piscar), e se passar de alguns segundos uma
  frase curta diz que está quase pronto.
- **Falha ao carregar**: a tela de carregamento não prende a pessoa; ela sai
  para a tela de erro com a Memora, como qualquer outro erro.

- **"Reduzir movimento" ligado ou animações desligadas pelo sistema**: nenhuma
  informação, aviso ou confirmação pode depender de animação; tudo aparece
  parado e completo.
- **Aparelho de entrada sobrecarregado**: se a animação não puder rodar
  fluida, a Memora e as transições caem para a versão parada/suave, em vez de
  travar a tela.
- **Toques repetidos na Memora**: ela não acumula gestos; um toque durante o
  gesto é ignorado, e nada além do gesto acontece.
- **Toque durante uma transição**: o toque vale para a tela que ficará visível,
  nunca para a que está saindo; toque duplo acidental não dispara duas ações.
- **Gesto de voltar do sistema no meio de uma animação**: a navegação volta
  corretamente, sem tela pela metade.
- **Leitor de tela ligado**: o foco vai para o conteúdo da tela nova ao fim da
  transição; a Memora não rouba o foco nem é anunciada como "imagem".
- **Letra a 200% com a Memora na tela**: a Memora encolhe ou sai do caminho
  antes de o texto ser cortado; o texto sempre vence.
- **Texto da IA com mais de um emoji** (o modelo não obedeceu): o excedente não
  aparece na tela.
- **Tema de alto contraste**: a Memora e os ícones continuam reconhecíveis e
  com contraste mínimo de 3:1 com o fundo.
- **Aparelho sem reconhecimento de voz local**: ditado indisponível com o
  motivo em uma frase; digitar continua funcionando.

---

## Requirements *(mandatory)*

### Functional Requirements

**A Memora (US1)**

- **FR-001**: A Memora MUST aparecer em 2.5D (volume e profundidade, não
  desenho plano) em toda tela em que fala com a pessoa: apresentação, Início,
  conversa, ajuda, passo a passo, conclusões, estados de vazio/erro e avisos
  de segurança. Ela MUST ser um desenho vetorial, nítido em qualquer tamanho,
  redesenhado a partir da folha de expressões de referência — não uma imagem
  recortada.
- **FR-002**: A Memora MUST ter, no mínimo, as expressões **repouso**,
  **falando**, **pensando**, **comemorando** e **preocupada (com escudo)**, e
  cada tela MUST usar a que combina com o texto exibido.
- **FR-003**: A Memora MUST ter animações curtas de **entrada** (aceno ou
  surgimento), de **fala** (enquanto o balão aparece) e de **comemoração** (uma
  vez, ao concluir), e voltar ao repouso depois de cada uma.
- **FR-004**: Com "reduzir movimento" ligado no aparelho, a Memora MUST aparecer
  parada na expressão correta, sem nenhuma animação.
- **FR-005**: A Memora MUST ser tratada como decorativa pelo leitor de tela
  quando o balão já diz tudo; ela MUST NOT ser a única portadora de nenhuma
  informação.
- **FR-003a**: Todas as expressões MUST ter mais vida que uma pose parada com
  respiração: pequenos movimentos próprios de cada uma (olhar em volta,
  balançar a antena, piscar, ajeitar o corpo), sem nunca competir com o texto
  da tela, e nenhum com "reduzir movimento" (FR-004).
- **FR-005a**: Quando a pessoa toca na Memora, ela MUST responder com um gesto
  curto (aceno ou piscada) e voltar à expressão em que estava. O toque MUST NOT
  abrir nada, mudar de tela, falar nem disparar ação alguma. **Exceção: a
  anfitriã do Início** (FR-055), cujo toque mostra outra dica.
- **FR-005b**: O gesto de toque MUST NOT aparecer para o leitor de tela: a
  Memora continua decorativa (FR-005), sem ser anunciada como botão.
- **FR-005c**: A área de toque da Memora MUST NOT ficar a menos de 8 dp de um
  alvo de toque de verdade, para que um toque destinado a um botão não caia
  nela.
- **FR-005d**: Com "reduzir movimento" ligado, o toque na Memora MUST NOT gerar
  movimento; no máximo uma troca de expressão sem animação.
- **FR-006**: A Memora MUST aparecer no máximo uma vez por tela.
- **FR-007**: A Memora MUST continuar reconhecível nos três temas (claro,
  escuro, alto contraste), com contraste mínimo de 3:1 com o fundo.
- **FR-008**: O ícone do aplicativo no celular MUST continuar sendo a Memora
  (FR-009b da 004), no mesmo estilo 2.5D.

**Transições (US2)**

- **FR-009**: Toda troca de tela MUST ser um deslizamento contínuo, com direção
  significativa: avançar entra pela direita; voltar, pela esquerda.
- **FR-010**: Diálogos, confirmações e folhas de opções MUST surgir por cima da
  tela atual (de baixo ou no centro), sem deslizar a tela de trás.
- **FR-011**: A troca entre destinos da barra inferior MUST respeitar a posição
  relativa dos destinos.
- **FR-012**: Elementos que entram numa tela MUST entrar com movimento curto e
  coordenado (um momento só), nunca com efeitos espalhados e independentes.
- **FR-013**: Com "reduzir movimento" ligado, toda transição MUST virar troca
  suave ou instantânea, sem deslizamento.
- **FR-014**: Toda transição MUST terminar rápido o bastante para não atrasar a
  pessoa (ver SC-004) e MUST NOT engolir nem desviar um toque feito durante ela.
- **FR-015**: O gesto de voltar do aparelho MUST produzir a mesma transição que
  o botão "Voltar" da tela.

**Texto (US3)**

- **FR-016**: Todo bloco de texto da interface MUST ter no máximo duas frases
  curtas. Conteúdo que exceder MUST virar etapa seguinte ou "Saber mais".
- **FR-017**: O que a pessoa precisa para **decidir** (aviso, consequência,
  confirmação) MUST estar visível sem abrir "Saber mais".
- **FR-018**: Nenhum texto visível MUST conter "idoso", "terceira idade",
  "melhor idade", "sênior" ou frase que sugira incapacidade da pessoa.
- **FR-019**: Os textos MUST estar na voz da Memora: primeira pessoa, convite a
  fazer junto, sem jargão, sem culpar a pessoa.
- **FR-020**: Títulos, botões, rótulos, avisos e mensagens de erro MUST NOT
  conter emoji.
- **FR-021**: O tamanho do texto MUST seguir a escolha da pessoa em Aparência;
  nenhuma tela fixa tamanho contra essa escolha.
- **FR-022**: A regra de duas frases MUST valer também para os textos dos guias
  passo a passo e da ajuda.

**Conversa (US4)**

- **FR-023**: Cada mensagem da Memora na conversa MUST ter no máximo um emoji, e
  nenhum emoji MUST substituir uma palavra ou carregar informação.
- **FR-024**: Se uma resposta da IA chegar com mais de um emoji, o aplicativo
  MUST exibir no máximo o primeiro.
- **FR-025**: A Memora animada MUST aparecer uma vez na conversa, pequena e no
  topo (FR-042), e reagir às respostas dela (falando enquanto a resposta
  aparece) sem se repetir a cada balão (FR-006).
- **FR-026**: O aviso antigolpe da conversa MUST manter o comportamento atual:
  encolhe, não some, e não é dispensável.

**Ícones e ilustrações (US5)**

- **FR-027**: Ícones e ilustrações MUST ser vetoriais e de uma única família
  visual em todo o aplicativo.
- **FR-028**: Todo elemento tocável MUST dar resposta visual imediata ao toque,
  inclusive com "reduzir movimento" ligado (resposta sem movimento).
- **FR-029**: Todo ícone interativo MUST vir acompanhado de texto.
- **FR-030**: As capturas de tela dos guias MUST continuar como fotos reais da
  tela (fora da regra do vetor).

**Abrangência (US6)**

- **FR-031**: Todas as telas do aplicativo MUST seguir esta spec e a memora-ux,
  incluindo as que chegam com a #71: Localizador, diálogo de permissão de
  localização, confirmações de rota e de ligação, e seletor de seções.
- **FR-032**: O redesenho MUST NOT mudar regra de negócio, campo, fluxo de
  segurança ou comportamento já especificado nas features 001 a 009.

**Segurança (Princípios I e II)**

- **FR-033**: Nenhuma animação MUST esconder, atrasar ou tornar menos legível um
  aviso de segurança, a origem de um link, a saída do Memora ou uma
  confirmação.
- **FR-034**: O ditado por voz (FR-013 da 007) MUST processar o áudio só no
  aparelho; quando o aparelho não oferecer isso, o ditado MUST ficar
  indisponível, e o áudio nunca é enviado para fora do aparelho.
- **FR-035**: A apresentação MUST dizer, em uma frase, que a Memora só fala com
  a pessoa **dentro do aplicativo** — nunca por mensagem, ligação ou rede
  social.

**Abertura, Início, conversa e barra inferior (US7 e US4)**

- **FR-036**: Ao abrir o aplicativo, MUST aparecer uma tela de carregamento com
  a Memora acenando, animada (não imagem solta), sobre o fundo do tema.
- **FR-037**: O primeiro instante da abertura, controlado pelo sistema antes de
  o aplicativo existir, MUST mostrar a Memora parada no mesmo fundo, para que a
  passagem para o aceno seja contínua.
- **FR-038**: A tela de carregamento MUST durar o tempo de carregar e no máximo
  o de um aceno completo além disso; ela MUST NOT ser prolongada de propósito.
  Se o carregamento passar de 4 segundos, MUST aparecer uma frase curta dizendo
  que está quase pronto.
- **FR-039**: Com "reduzir movimento" ligado, a Memora da tela de carregamento
  MUST aparecer parada, em pose de aceno.
- **FR-040**: No Início, a Memora em 2.5D MUST ocupar a parte superior da tela
  (cerca de um terço da altura, com letra a 100%), junto da saudação.
- **FR-041**: Com letra ampliada, a área da Memora no Início MUST encolher antes
  de qualquer texto ser cortado ou de qualquer ação sair do alcance; o Início
  MUST continuar passando nas matrizes de acessibilidade.
- **FR-042**: Na conversa, a Memora MUST aparecer pequena, no topo da tela, e
  MUST NOT ocupar o espaço das mensagens; as respostas dela não levam o rosto
  dela ao lado de cada balão.
- **FR-043**: A conversa MUST mostrar só o essencial: cabeçalho, aviso
  antigolpe compacto, mensagens e o campo de escrever. Sugestões aparecem só
  antes da primeira mensagem; nenhum elemento decorativo além da Memora.
- **FR-044**: A barra inferior MUST manter os 3 destinos (Ajustes, Início, Meu
  perfil), com ícone e rótulo escrito juntos, alvo ≥ 48 dp.
- **FR-045**: Os ícones da barra inferior MUST ser da mesma família vetorial do
  resto do aplicativo (FR-027).
- **FR-046**: O item ativo MUST ter um indicador que desliza até o destino
  tocado; com "reduzir movimento", o indicador muda de lugar sem deslizar.
- **FR-047**: A barra inferior MUST ter o mesmo acabamento dos demais blocos
  (superfície, sombra, cantos) e resposta visual ao toque em cada item.

**A anfitriã do Início (US8, sessão de 2026-11-16)**

- **FR-048**: No Início, a Memora MUST ser a **anfitriã**: desenhada com mais
  detalhe e profundidade que as outras (luz, brilho especular, luz de
  contorno, sombra de contato, giro de cabeça com o rosto deslizando no
  visor), em 2.5D, sem dependência de motor 3D nem de biblioteca externa.
- **FR-049**: A anfitriã MUST se mexer sozinha, com um repertório de
  comportamentos que se alternam sem padrão óbvio (flutuar, olhar em volta,
  acenar de vez em quando, inclinar a cabeça, pular de leve), mais animada que
  as Memoras das outras telas, sem nunca cobrir texto nem ação.
- **FR-050**: A anfitriã MUST falar por um balão com **dicas** curtas (no
  máximo duas frases, FR-016), tiradas de uma **lista fixa escrita pela
  equipe dentro do aplicativo** — nunca geradas pela IA nem vindas do
  servidor. Parte das dicas MUST ser lembrete antigolpe ("Eu nunca peço sua
  senha nem código").
- **FR-051**: Enquanto o texto do balão aparece, a **boca** da anfitriã MUST
  se mexer como se falasse, e parar quando o texto termina.
- **FR-052**: A dica MUST trocar sozinha a cada **20 segundos**, no mínimo,
  com transição suave do balão; nunca no meio da leitura de quem tocou na
  tela há menos de 20 segundos.
- **FR-053**: A troca automática MUST parar (WCAG 2.2.2) quando: o leitor de
  tela estiver ligado; "reduzir movimento" estiver ligado; ou a pessoa tocar
  na anfitriã ou no balão (a partir daí, só troca quando ela pedir).
- **FR-054**: MUST existir sempre um jeito manual de ver a próxima dica: tocar
  na anfitriã ou no balão.
- **FR-055**: Na anfitriã, o toque MUST ser uma **ação acessível**: rótulo
  para o leitor de tela ("Outra dica da Memora"), área de toque ≥ 48 dp e
  8 dp de distância de qualquer outro alvo; ao tocar, ela faz um gesto e
  mostra a próxima dica. Com o leitor de tela, o balão é lido como texto, e a
  troca é anunciada só quando a pessoa pede.
- **FR-056**: A anfitriã MUST NOT levar a lugar nenhum: tocar nela nunca abre
  tela, aplicativo nem link (o caminho para conversar é o cartão principal,
  como na 007).
- **FR-057**: Com "reduzir movimento", a anfitriã MUST ficar parada em pose de
  repouso, sem troca automática; as dicas continuam disponíveis pelo toque.
- **FR-058**: A anfitriã MUST NOT pesar no aparelho de entrada: parada fora da
  tela, sem atrasar o toque nas ações do Início (SC-005).

### Key Entities

- **Expressão da Memora**: o estado visual dela num momento (repouso, falando,
  pensando, comemorando, preocupada); tem uma versão animada e uma parada.
- **Transição**: a forma de entrar e sair de uma tela; tem uma direção
  (avançar, voltar, sobrepor) e uma versão para "reduzir movimento".
- **Bloco de texto**: unidade de leitura da tela, com no máximo duas frases, e
  um eventual "Saber mais" associado.

---

## Como um golpista exploraria isto? (Princípio II)

| Superfície nova | Exploração possível | Impacto | Mitigação |
|---|---|---|---|
| **A Memora reconhecível** | Golpista usa a imagem da Memora num perfil de WhatsApp ou numa mensagem: "Sou a Memora, me passa o código" | Alto | FR-035 (a Memora só fala dentro do aplicativo) e o aviso antigolpe permanente da conversa (FR-026) |
| **Transições e animações** | Animação que dura demais ou distrai faz a pessoa tocar sem ler uma confirmação | Alto | FR-014 (toque não se perde nem se desvia), FR-033 (animação nunca esconde aviso ou confirmação), confirmações continuam em duas etapas |
| **Texto curto** | Encurtar um aviso a ponto de ele perder o sentido | Médio | FR-017: o necessário para decidir fica visível; "Saber mais" só para o que é complementar |
| **Emoji na IA** | Modelo induzido a trocar palavras por emoji ambíguo ("👍" como "pode passar o código") | Médio | FR-023 e FR-024: no máximo um emoji, nunca no lugar de palavra |
| **Ditado por voz** | Pessoa dita senha ou código em voz alta; áudio enviado a terceiros | Crítico | FR-034 (só no aparelho) e o aviso antigolpe |
| **Dicas da anfitriã** | Fazer a Memora "dizer" algo falso ("toque aqui para atualizar seu cadastro") por injeção na IA ou no servidor | Alto | FR-050: lista fixa no aplicativo, revisada na PR; FR-056: tocar nela nunca leva a lugar nenhum |

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das telas do aplicativo passam nos 7 itens da checagem da
  memora-ux, conferidos no álbum de telas nos três temas.
- **SC-002**: Zero blocos de texto com mais de duas frases, zero ocorrências das
  palavras proibidas e zero emojis na interface, em varredura de todos os
  textos visíveis.
- **SC-003**: Com "reduzir movimento" ligado, 100% das telas exibem o mesmo
  conteúdo e as mesmas ações que com o movimento ligado.
- **SC-004**: Toda transição de tela termina em até meio segundo, e nenhuma
  animação atrasa a resposta a um toque.
- **SC-005**: Num aparelho de entrada de referência, as telas com a Memora
  animada e as transições rodam sem engasgo perceptível para a pessoa.
- **SC-006**: As matrizes de acessibilidade existentes (4 aparelhos × 3 escalas
  de texto) continuam passando em todas as telas, sem estouro e com as ações
  alcançáveis.
- **SC-007**: Em teste com pessoas de 65 anos ou mais (o portão das features 001
  e 002), ao menos 4 de 5 conseguem dizer onde estão e como voltar depois de
  três trocas de tela, e nenhuma relata desconforto com as animações.
- **SC-008**: Em 50 respostas seguidas da IA, nenhuma exibe mais de um emoji.
- **SC-009**: No aparelho de teste, a tela de carregamento não acrescenta mais
  que um aceno completo (cerca de 1,5 s) ao tempo que o aplicativo já leva para
  abrir.

---

## Assumptions

- **A 007 entra antes da implementação desta.** O plano e as tarefas da 013
  partem do Design System 2.0 da #71; se a #71 mudar, as tarefas são
  atualizadas (decisão do Henrique, 2026-11-15).
- **A Memora já é um robô** (FR-009b da 004; expressões existentes em PNG). O
  redesenho dá volume e movimento ao mesmo personagem, não cria outro.
- **A folha de expressões da Memora** que está em `Memora-Desing-Ideias/`
  (gerada por IA, na #71) é a referência de aparência do personagem. A equipe
  a redesenha como vetor; a imagem de referência não vai para o aplicativo.
- **"Aparelho de entrada de referência"** é um celular da faixa Galaxy A/M, o
  mais comum no público; o S20 FE do Henrique é o aparelho de teste, mas é
  mais rápido que a média.
- **As capturas dos guias** seguem o contrato da 004 (WebP, destaque desenhado
  pelo aplicativo); esta feature não as altera.
- **O comportamento das features 001 a 009 não muda**: só a apresentação.
- **Os textos da IA** são controlados pelas instruções da persona no servidor;
  a FR-024 é a rede de segurança no aplicativo.
- **Fora de escopo**: novas funcionalidades, novos destinos na barra inferior,
  som e vibração (podem virar feature própria), a arte dos logotipos dos
  aplicativos de terceiros.
