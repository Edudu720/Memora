# Feature Specification: Redesenho das telas — o Memora inteiro, e bonito

**Feature Branch**: `004-redesenho-das-telas`

**Created**: 2026-10-01

**Status**: Approved (Aprovada por Eduardo Juncker em 2026-10-13; ratificada por Henrique Sandrini em 2026-10-14 via APK físico — T116, e merge da PR #58)

**Input**: User description: "O front deve ser com um design prático, intuitivo, profissional e moderno. Não estamos satisfeito com a maneira que foi realizada. Deve conter todas as telas do wireframe e melhorar drasticamente na parte de design e acessibilidade para o idoso. Foi focado muito na segurança do projeto e não em sua aparencia e funcionalidades."

---

## Contexto

As features 001, 002 e 003 construíram a fundação: identidade, vocabulário
visual, Hub e a assistente. Cada uma passou por portões de segurança provados
quebrando de propósito. **Nenhuma delas entregou um aplicativo que pareça
pronto**, e a equipe não está satisfeita com o resultado.

O diagnóstico, levantado em 2026-10-01 contra o wireframe do Arquivo X:

1. **Faltam telas.** O wireframe tem 35 telas, e o aplicativo mostra cerca de
   dez. Não existem a apresentação inicial, o Início, a Ajuda, as
   Configurações, o Perfil visível, os passo a passo nem a barra inferior.
2. **A pessoa vê o andaime.** O aplicativo abre numa casca de demonstração, com
   abas de desenvolvimento ("Componentes", "Aparência") que não fazem sentido
   para quem usa o aplicativo.
3. **A segurança ocupa o lugar da tarefa.** Os avisos existem e estão certos,
   mas foram desenhados como o centro da tela. Na conversa, por exemplo, as
   faixas de aviso podem tomar quase 90% da altura disponível com o texto
   ampliado, e a conversa fica espremida no que sobra.
4. **O visual é correto, e não convida.** Contraste, toque e ampliação passam
   nos portões, mas as telas são listas de botões sobre fundo liso. Faltam
   hierarquia, ilustração e a personalidade que o wireframe já tinha: a Memora
   como personagem, os balões de fala, as ilustrações de pessoas.

### O que esta spec muda, e o que ela não muda

**Muda** a aparência e a completude: todas as telas do wireframe passam a
existir, numa linguagem visual nova, prática, moderna e profissional, que um
idoso use sozinho.

**Não muda** os princípios. A constituição põe segurança acima de prazo e de
conveniência, e isso continua valendo: nenhuma proteção existente é retirada.
O que esta spec exige é que a proteção **caiba no desenho** em vez de
substituí-lo. Segurança que a pessoa não consegue usar não protege ninguém, e
um aviso que ocupa a tela inteira deixa de ser lido na terceira vez.

### Inventário: o wireframe contra o aplicativo de hoje

| Figura | Tela do wireframe | Hoje | Nesta spec |
|---|---|---|---|
| 2 | Primária ("Começar jornada") | Existe | Redesenhar (US1) |
| 3 | Cadastro | Existe, com nome e um canal (decisão da 001) | Redesenhar, mantendo os campos decididos (US1) |
| 4 | Login | Existe; Google e Facebook dependem da fase 8 da 001 | Redesenhar (US1) |
| 5 | Olá | **Não existe** | Nova (US1) |
| 6 | Apresentação | **Não existe** | Nova (US1) |
| 7 | Exemplo da conversa | **Não existe** | Nova (US1) |
| 8 | Início | **Não existe** | Nova (US2) |
| 9 | Hub | Existe, como lista de botões | Redesenhar (US2) |
| 10 | Planos | Marcada como Futuro na 003 | **Fica fora** — ver US9 e Clarifications |
| 11-13 | Conversa, resposta "Sim", resposta "Não" | Existe | Redesenhar (US3) |
| 14 | Ajuda | **Não existe** (registrado na T095 da 003) | Nova (US6) |
| 15-19 | Ajuda guiada sobre a conversa | **Não existe** | Nova (US6) |
| 20 | Apps atuais | Existe, como lista | Redesenhar, com busca e ícones (US4) |
| 21-24 | Passo a passo de um aplicativo (TikTok) | **Não existe** — fora de escopo na 003 | Nova, mostrada dentro do Memora (US4) |
| 25 | Configurações | Só a parte de aparência | Nova (US7) |
| 26 | Configurações de acessibilidade | Existe como "Aparência" | Redesenhar (US7) |
| 27 | Perfil | Existe, mas não é mostrada | Redesenhar, com idade opcional e sem plano (US8, revisão da T044) |
| 28 | Serviços sociais | Existe com Gov.br e Meu INSS | Redesenhar, com os serviços do wireframe (US5) |
| 29-36 | Passo a passo do gov.br (4 telas e 4 explicações) | **Não existe** | Nova, mostrada dentro do Memora (US5) |

Telas que **não estão no wireframe** e existem por decisão das features
anteriores também entram no redesenho, na mesma linguagem: recuperar o acesso,
confirmar o canal, entregar o aparelho no cadastro assistido, primeira entrada
sozinha, confirmação de ação e "O que eu fiz por você". Deixá-las no visual
antigo criaria dois aplicativos dentro de um.

⚠️ **Os textos de exemplo do protótipo não são conteúdo do produto.** Alguns
são inadequados para um aplicativo que trata a pessoa idosa com respeito. Toda
frase segue a voz da Memora já definida nas features 001 e 003.

---

## Clarifications

### Session 2026-10-01

- Q: O passo a passo de outro aplicativo aparece dentro do Memora ou por cima do aplicativo real, como no wireframe? → A: **Dentro do Memora**, com a imagem de exemplo de cada tela. Aparecer por cima exigiria a permissão de sobreposição, a mais usada por vírus bancários no Brasil, e treinaria na pessoa o gesto de concedê-la (FR-029).
- Q: O que o Perfil mostra além de nome e canal? → A: **Só o que o Memora já sabe**: nome, desenho, canal de contato e o aplicativo mais aprendido, calculado no aparelho. A idade não é pedida, porque nenhuma tarefa depende dela (FR-042). ⚠️ *Substituída na revisão da T044*: a idade passa a ser opcional, informada no Perfil e guardada só no aparelho (ver a sessão abaixo).
- Q: Sem internet, como ficam "Meus aplicativos" e "Serviços sociais", que vêm do servidor? → A: **O aparelho guarda o último catálogo recebido**, e os guias, que já são locais, funcionam offline. Um item retirado do ar some na primeira atualização com conexão (FR-024a). Decisão tomada na análise de 2026-10-01.
- Q: A tela de Planos entra nesta feature? → A: **Não.** Continua valendo a decisão da 003, que a marcou como Futuro: monetização nunca foi discutida, e uma tela de plano no Memora prepara a pessoa para o golpe "seu plano venceu" (US9).

### Session 2026-10-01 — revisão de design da T044 (Henrique)

A revisão do Início e do Hub pediu mudanças, e quatro delas esbarravam numa
decisão já escrita. As respostas abaixo substituem o que estava antes; o
veredito completo está em [revisao-de-design.md](revisao-de-design.md).

- Q: O aviso "a Memora nunca pede senha ou código" pode ser removível e sumir depois que a pessoa manda uma mensagem? → A: **Encolhe, não some.** Fica aberto até a primeira mensagem da conversa; depois vira uma linha fina, com escudo e o núcleo do aviso, que a pessoa toca para ler inteiro. Sumir de vez deixaria a pessoa sem aviso justamente no meio da conversa, que é onde o golpista a pressiona (FR-022, R5).
- Q: O Perfil mostra o plano? → A: **Não, por ora.** Mantém-se a resposta sobre Planos acima.
- Q: O Perfil mostra a idade? → A: **Sim, se a pessoa quiser informar.** A data de nascimento é **opcional**, informada no próprio Perfil, nunca no cadastro, e **fica só no aparelho** — não vai para o servidor. Substitui a resposta anterior, que dizia que a idade não seria pedida (FR-042).
- Q: Aparência deixa escolher cores? → A: **Sim, entre paletas prontas.** Cinco ou seis cores de destaque, combináveis com os temas claro e escuro (não com o alto contraste; ver a sessão de 2026-10-13), cada combinação validada por contraste antes de existir. Cor livre está fora: não há como garantir contraste, e o prejuízo cairia em quem enxerga pior (FR-039).
- Q: Qual "Carteira Digital" o wireframe quis dizer? → A: **O documento digital do gov.br**, e não a Carteira Digital de Trânsito (T080).

### Session 2026-10-13 — bloqueios do `/speckit-analyze` (Eduardo)

- Q: Como classificar e guardar a data de nascimento no aparelho? → A: **Confidencial, sem cifra**, como o canal de contato. A constituição só exige cifra em repouso para dado Sensível. Fora da tela em que é informada, nenhuma tela mostra a data, só a idade (FR-042c, Threat Model, Análise de Engenharia Social).
- Q: Como registrar a aprovação desta spec, que estava em `Draft` com a implementação já avançada (Princípio IV)? → A: **Aprovada agora pelo Eduardo, com estas clarificações; Henrique e Du3101 ratificam na revisão da #58** (Status). A implementação nova segue a partir desta aprovação.
- Q: Que confirmação "Sair e esquecer este aparelho" exige? → A: **A irreversível, em duas etapas**, a mesma de apagar a conversa (FR-040). Ela apaga sem volta o que o aparelho guarda de todas as contas (FR-041).
- Q: As paletas prontas valem no tema de alto contraste? → A: **Não.** A paleta vale no claro e no escuro; o alto contraste existe para o máximo contraste, e qualquer cor de destaque seria concessão (FR-039, R15).
- Q: A segunda rodada da revisão de design no celular (T116) é portão para as próximas telas? → A: **É portão do merge, não do código.** As telas novas podem ser implementadas, mas nenhuma PR de tela nova entra na `master` antes da T116. Vale para o que for implementado a partir de agora (fase 7, Perfil, T099, T117, T125); as PRs de tela já abertas em 2026-10-13 (#45, #46, #47, #55, #56) seguem a ordem de merge, porque a própria T116 precisa delas no aparelho (Assumptions).

### Session 2026-10-21 — a conversa no celular, com a assistente real (Henrique)

- Q: Depois da primeira pergunta, como fica o aviso da conversa? → A: **Só o escudo vermelho, num canto**, que a pessoa toca para ler os avisos inteiros (o do golpe e o de privacidade). A linha com o núcleo ("senha" e "código") tomava espaço demais na tela pequena. O núcleo continua **para o leitor de tela**, no rótulo do escudo, e o aviso continua sem poder sumir. Risco aceito, decisão do Henrique: quem enxerga e está sob pressão ao telefone deixa de ver a frase sem tocar. Mudam FR-022 e FR-049.
- Q: Uma falha do serviço de fora reabre o aviso? → A: **Não.** Aberto só até a primeira pergunta, mesmo que a falha devolva a pergunta ao campo (FR-022). Era defeito: o aviso se recriava aberto a cada erro.
- Q: A resposta da Memora pode ter negrito? → A: **Sim, só negrito** (`**assim**`), para destacar o nome de aplicativo ou botão. Nenhum asterisco aparece na tela nem chega ao leitor de tela (FR-020a).
- Q: Como a espera e a resposta aparecem? → A: **Só o balão da Memora se formando**, sem a frase "Estou pensando..." embaixo do campo; e a resposta **vai aparecendo aos poucos**, letra a letra, como quem escreve. Com "reduzir movimento", aparece de uma vez (FR-020b).

### Session 2026-11-12 — as capturas reais e o zoom (Henrique)

- Q: Quais guias recebem captura real primeiro? → A: **FGTS, Meu INSS, e-Título, TikTok e Instagram.** As imagens vêm da equipe, numa pasta à parte, e entram pelo formato do contrato ([contracts/guias.md](contracts/guias.md)).
- Q: A pessoa pode ampliar a captura? → A: **Sim.** Com a captura real, a imagem dentro da moldura fica estreita demais para quem enxerga pouco. Tocar nela, ou num botão visível logo abaixo, abre a imagem em tela cheia, **dentro do Memora** (FR-028b).
- Q: Ampliar com dois dedos basta? → A: **Não.** O gesto de pinça é difícil para muitas pessoas idosas e não pode ser o único caminho (WCAG 2.2, critérios 2.5.1 e 2.5.7). Há botões **"Aproximar"** e **"Afastar"**, e aproximar leva direto ao destaque, para que ninguém precise arrastar a imagem até achar o ponto (FR-028b).
- Q: A imagem ampliada continua marcada como exemplo? → A: **Sim, com o selo e com o destaque.** Uma captura do gov.br em tela cheia, sem marca, é o modelo de tela falsa que a FR-028 existe para evitar.
- Q: O destaque acompanha a imagem? → A: **Sim, sempre sobre a imagem, e não sobre a moldura** (FR-028c). Era defeito latente: os desenhos provisórios tinham quase a proporção da moldura e escondiam o desalinhamento, que aparece com qualquer captura real.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - O primeiro contato: do convite à primeira conversa (Priority: P1)

Seu Antônio, 72 anos, ganhou o celular do neto e abre o Memora pela primeira
vez. Ele vê uma tela acolhedora, com ilustração e uma frase que diz para que o
aplicativo serve. Cria a conta, e a Memora se apresenta como personagem: diz
quem é, mostra para que serve a conversa e dá um exemplo de como ela funciona.
Ao fim, ele chega ao Início sabendo o que fazer.

**Why this priority**: é a primeira impressão. Quem se sente perdido nos dois
primeiros minutos não volta, e a equipe não está satisfeita justamente com o
que a pessoa vê primeiro.

**Independent Test**: entregar o aparelho, sem conta, a uma pessoa de 65+ e
pedir que chegue até a primeira conversa sem ajuda. Cronometrar e anotar onde
ela hesita.

**Acceptance Scenarios**:

1. **Given** que abro o Memora sem conta, **When** a primeira tela aparece,
   **Then** vejo a ilustração, uma frase curta dizendo para que o aplicativo
   serve e **um** botão principal para começar.
2. **Given** que acabei de criar a conta, **When** entro pela primeira vez,
   **Then** a Memora se apresenta em até três telas curtas — quem ela é, para
   que serve a conversa e um exemplo — cada uma com "Continuar".
3. **Given** que estou na apresentação, **When** quero pular, **Then** existe
   uma opção visível de pular, e ela me leva ao Início.
4. **Given** que já vi a apresentação, **When** entro de novo, **Then** ela não
   aparece outra vez, mas posso revê-la pela Ajuda.
5. **Given** que estou no login, **When** a tela aparece, **Then** os caminhos
   "Esqueci minha senha" e "Primeiro acesso" estão visíveis sem rolar, e só
   aparece botão de entrar com outra conta (Google, Facebook) se esse caminho
   de fato funcionar.

---

### User Story 2 - O Início, o Hub e o caminho de volta (Priority: P1)

Depois de entrar, Dona Ana chega ao Início: a Memora a cumprimenta pelo nome e
mostra o caminho para o que ela mais faz. Embaixo, sempre no mesmo lugar, há
três destinos com desenho e nome escrito: Configurações, Início e Perfil. Do
Início ela vai para o Hub, onde estão todas as partes do Memora, cada uma com
ilustração e uma linha explicando o que faz.

**Why this priority**: é a tela que a pessoa verá mais vezes na vida do
aplicativo. Hoje ela é uma lista de botões iguais com um "Sair" no meio.

**Independent Test**: pedir a uma pessoa de 65+ que, a partir de qualquer tela,
volte ao Início, e depois que diga em voz alta o que cada parte do Hub faz.

**Acceptance Scenarios**:

1. **Given** que entrei na conta, **When** o Início aparece, **Then** sou
   cumprimentada pelo nome de tratamento e vejo um atalho para conversar com a
   Memora e um para ver todas as partes do aplicativo.
2. **Given** que estou em qualquer tela interna, **When** olho para a parte de
   baixo, **Then** vejo os três destinos fixos, cada um com desenho **e** nome
   escrito, e o destino em que estou aparece marcado por mais de um sinal além
   da cor.
3. **Given** que abri o Hub, **When** ele aparece, **Then** vejo todas as
   partes disponíveis sem rolar, cada uma com ilustração, nome em linguagem
   comum e uma linha de explicação.
4. **Given** que uma parte ainda não funciona, **When** o Hub aparece, **Then**
   ela não é mostrada.
5. **Given** que estou numa tela aberta pelo Hub, **When** procuro voltar,
   **Then** o "Voltar" está no mesmo lugar em todas elas.

---

### User Story 3 - Conversar com a Memora numa tela agradável (Priority: P1)

Seu Antônio quer abrir o Instagram e não sabe como. Na conversa, ele vê o rosto
da Memora ao lado das respostas dela e o próprio desenho ao lado das
mensagens dele. As respostas chegam em balões fáceis de ler. Quando a Memora
oferece fazer algo, as duas opções aparecem como frases completas e grandes. O
aviso de segurança continua ali, mas compacto, e a conversa ocupa a maior parte
da tela.

**Why this priority**: a conversa é a razão de o Memora existir. É também a
tela em que o excesso de aviso mais apertou o conteúdo.

**Independent Test**: conduzir uma conversa de cinco turnos com uma pessoa de
65+ e verificar se ela distingue, sem ajuda, quem disse cada coisa e quais são
as opções de resposta.

**Acceptance Scenarios**:

1. **Given** que estou conversando, **When** olho a conversa, **Then** distingo
   a fala da Memora e a minha por posição, por desenho e por nome — nunca só
   pela cor.
2. **Given** que a Memora oferece fazer algo, **When** as opções aparecem,
   **Then** cada uma é uma frase completa, com toque grande, e as duas estão
   afastadas o bastante para não serem tocadas por engano.
3. **Given** que a conversa tem um aviso de segurança, **When** a tela
   aparece, **Then** o aviso está visível e legível, e a conversa com o campo de
   escrever ocupa a maior parte da altura.
4. **Given** que estou escrevendo, **When** o teclado abre, **Then** a última
   mensagem e o campo de escrever continuam visíveis.

---

### User Story 4 - Aprender um aplicativo do dia a dia, passo a passo (Priority: P1)

Dona Ana quer aprender a usar o TikTok que a neta mostrou. Em "Meus
aplicativos" ela vê os ícones conhecidos com o nome escrito embaixo, e uma
busca para quando não acha. Ao tocar no TikTok, a Memora mostra o caminho
**um passo por vez**: o que aparece na tela, onde tocar e o que acontece
depois. No fim, a Memora a parabeniza e oferece voltar ao Hub.

**Why this priority**: é o Princípio VII em forma de tela. Ensinar, e não
fazer pela pessoa, é a diferença do Memora para qualquer outro assistente.

**Independent Test**: pedir a uma pessoa de 65+ que aprenda pelo Memora a
encontrar um vídeo num aplicativo que ela não conhece, e depois que repita
sozinha, sem o Memora.

**Acceptance Scenarios**:

1. **Given** que abri "Meus aplicativos", **When** a tela aparece, **Then** vejo
   cada aplicativo com o ícone e o nome escrito, e uma busca no topo.
2. **Given** que procuro um aplicativo, **When** escrevo parte do nome, mesmo
   sem acento, **Then** a lista se reduz aos que combinam.
3. **Given** que toquei num aplicativo, **When** o passo a passo começa,
   **Then** vejo um passo por tela, com a imagem do que vou encontrar, o ponto a
   tocar destacado, uma frase curta e a indicação de em que passo estou e
   quantos faltam.
4. **Given** que estou num passo, **When** quero rever o anterior, **Then**
   posso voltar sem perder o lugar.
5. **Given** que terminei o passo a passo, **When** a última tela aparece,
   **Then** a Memora me parabeniza e oferece voltar ao Hub e, se for um
   aplicativo que ela pode abrir e houver conexão, oferece pedir a ela que o
   abra — pela conversa, com a confirmação e o aviso de saída de sempre
   (FR-027).
6. **Given** que o passo a passo ensina telas de outro aplicativo, **When**
   ele começa, **Then** a explicação inteira acontece dentro do Memora, com a
   imagem de exemplo da tela do outro aplicativo, e o Memora nunca pede
   permissão para aparecer por cima de outro aplicativo.

---

### User Story 5 - Serviços do governo, com a Memora ensinando (Priority: P2)

Seu Antônio precisa entrar no gov.br e nunca conseguiu. Em "Serviços sociais"
ele vê os serviços do wireframe, cada um com o nome e o símbolo reconhecível.
Ao escolher o gov.br, a Memora diz o que ele vai precisar ter em mãos e mostra
cada tela do caminho, avisando em cada uma que a senha só é digitada no
aplicativo oficial. No fim, ela o parabeniza.

**Why this priority**: é onde o idoso mais precisa de ajuda e onde o golpe mais
acontece. Vem depois da US4 porque a regra da 003 já impede a Memora de abrir
esses serviços, e o passo a passo aqui é ensino puro.

**Independent Test**: pedir a uma pessoa de 65+ que diga, depois do passo a
passo, onde se digita a senha do gov.br e onde nunca se digita.

**Acceptance Scenarios**:

1. **Given** que abri "Serviços sociais", **When** a tela aparece, **Then** vejo
   os serviços com nome e símbolo e uma frase explicando que ali eu aprendo a
   acessá-los.
2. **Given** que escolhi um serviço, **When** o passo a passo começa, **Then** a
   primeira tela diz o que vou precisar ter em mãos.
3. **Given** que estou num passo que mostra uma tela de entrada com senha,
   **When** o passo aparece, **Then** a imagem está marcada como exemplo, e o
   texto diz que a senha só se digita no aplicativo oficial, nunca no Memora.
4. **Given** que um serviço é sensível, **When** procuro um botão para a Memora
   abri-lo, **Then** ele não existe — a Memora ensina e não entra.

---

### User Story 6 - Pedir ajuda sobre o próprio Memora (Priority: P2)

Dona Ana não lembra para que serve uma das partes do Hub. Ela toca em "Ajuda" e
vê os assuntos do wireframe, cada um com desenho e nome: o aplicativo, a
Memora, a conversa, os serviços, como baixar um aplicativo, como compartilhar o
Memora e dicas de segurança contra golpes. Em "A conversa", a Memora mostra,
passo a passo, como pedir ajuda a ela.

**Why this priority**: sem ajuda, a pessoa depende de um familiar para lembrar
do que já aprendeu — a dependência que o produto existe para quebrar.

**Independent Test**: pedir a uma pessoa de 65+ que encontre, pela Ajuda, como
se proteger de um golpe por telefone.

**Acceptance Scenarios**:

1. **Given** que abri a Ajuda, **When** ela aparece, **Then** vejo os assuntos
   com desenho e nome, e cada um abre uma explicação curta.
2. **Given** que escolhi "A conversa", **When** a explicação começa, **Then** a
   Memora mostra um exemplo de conversa passo a passo, com "Continuar" e uma
   saída direta para conversar de verdade.
3. **Given** que escolhi "Segurança", **When** a explicação aparece, **Then**
   vejo as dicas contra golpe em linguagem comum, uma por vez.
4. **Given** que escolhi "Compartilhar", **When** compartilho, **Then** só o
   endereço oficial de download do Memora é enviado, e sou avisado de que estou
   mandando uma mensagem para fora do aplicativo.
5. **Given** que quero rever a apresentação inicial, **When** procuro na Ajuda,
   **Then** encontro como vê-la de novo.

---

### User Story 7 - Ajustar o Memora ao meu jeito (Priority: P2)

Seu Antônio enxerga pouco à noite. Em Configurações ele vê os grupos com nome
claro — Aparência, Acessibilidade, Privacidade e Conta. Em Acessibilidade,
cada opção diz para quem ela serve; ele aumenta o texto e liga o alto
contraste, vendo o resultado antes de confirmar. Em Aparência, escolhe uma das
cores prontas. Em Conta, ele sai do
aplicativo e entende o que acontece quando sai.

**Why this priority**: ajuste de aparência já existe; o que falta é ele estar
num lugar que a pessoa encontre, junto com o resto do que se configura.

**Independent Test**: pedir a uma pessoa de 65+ que deixe o texto maior e
depois saia da conta, sem ajuda.

**Acceptance Scenarios**:

1. **Given** que abri Configurações, **When** a tela aparece, **Then** vejo só os
   grupos que de fato funcionam, cada um com desenho, nome e uma linha de
   explicação.
2. **Given** que estou em Aparência, **When** troco tema ou tamanho do texto,
   **Then** vejo o efeito antes de confirmar e posso desfazer.
3. **Given** que estou em Privacidade, **When** a tela aparece, **Then** vejo em
   linguagem comum o que fica guardado no aparelho, e posso apagar a conversa.
4. **Given** que estou em Conta, **When** escolho sair, **Then** o aplicativo
   pergunta antes, explica que vou precisar da senha para voltar, e oferece a
   opção de esquecer também o e-mail lembrado, para aparelho compartilhado.

---

### User Story 8 - Meu perfil (Priority: P3)

Dona Ana toca em Perfil e vê o próprio nome, um desenho que a representa e as
informações da conta, apresentadas como **informação** — nunca parecendo
botão.

**Why this priority**: dá à pessoa a sensação de que o aplicativo é dela, mas
nenhuma tarefa depende dele.

**Independent Test**: pedir a uma pessoa de 65+ que diga, olhando o Perfil, qual
e-mail ou telefone está ligado à conta.

**Acceptance Scenarios**:

1. **Given** que abri o Perfil, **When** ele aparece, **Then** vejo nome, desenho
   e o canal de contato da conta, e nenhum desses dados parece tocável.
2. **Given** que já aprendi aplicativos pelo passo a passo, **When** abro o
   Perfil, **Then** vejo qual aplicativo eu mais aprendi a usar.
3. **Given** que ainda não aprendi nenhum, **When** abro o Perfil, **Then** essa
   linha diz, na voz da Memora, que ainda vamos aprender juntos, em vez de
   aparecer vazia.
4. **Given** que estou no Perfil, **When** procuro plano, como no wireframe,
   **Then** ele não aparece: o Memora não tem planos.
5. **Given** que estou no Perfil e nunca informei a idade, **When** a tela
   aparece, **Then** vejo um convite opcional para informar a data de
   nascimento, que fica só neste aparelho; informada, a idade aparece como
   informação (FR-042c).

---

### User Story 9 - Planos: fora desta feature (Priority: —)

O wireframe tem uma tela que compara o plano básico e o premium, com botão
"Melhorar" (Figura 10). **Ela não entra nesta feature**, por decisão de
2026-10-01 que confirma a da 003.

**Why**: monetização nunca foi discutida pela equipe. Uma tela de plano, mesmo
só informativa, ensina a pessoa a esperar que o Memora fale de plano e de
pagamento — e "seu plano venceu, pague por este link" é golpe conhecido.
Entrar com cobrança de verdade exigiria provedor de pagamento e ação crítica
com confirmação e registro: é uma feature própria.

**Independent Test**: procurar, em todo o aplicativo, qualquer menção a plano,
assinatura ou pagamento, e não encontrar nenhuma.

**Acceptance Scenarios**:

1. **Given** que estou em qualquer tela, **When** procuro planos, assinatura ou
   pagamento, **Then** não encontro, nem no Hub, nem na Ajuda, nem no Perfil.

---

### Edge Cases

- **Texto ampliado a 200% no aparelho menor.** Toda tela nova cabe e continua
  utilizável no menor aparelho suportado: nada estoura, e a ação principal fica
  alcançável. Vale também para o Hub, onde vale a regra da FR-017: a porta
  principal sempre à vista e a indicação de que há mais abaixo; o Hub inteiro
  sem rolar só no 360×800 em 100%; e, no 320×568 a 200%, basta o alvo de
  toque da principal à vista.
- **Tema escuro e alto contraste.** As ilustrações continuam legíveis e com
  contraste nos três temas; nenhuma informação depende só da ilustração.
- **"Reduzir movimento" ligado.** As transições e animações novas respeitam a
  preferência, e nenhuma informação depende só do movimento.
- **Leitor de tela.** Cada ilustração decorativa é ignorada pelo leitor, e cada
  ilustração que informa algo tem descrição. A ordem de leitura acompanha a
  ordem visual.
- **Aplicativo não instalado.** No passo a passo de um aplicativo que não está
  no aparelho, a Memora começa ensinando a baixá-lo da loja oficial, em vez de
  oferecer abrir algo que não existe.
- **Passo a passo desatualizado.** O outro aplicativo mudou e a tela não é mais
  igual à imagem. Existe em todo passo uma saída "A minha tela está diferente",
  que leva à conversa com a Memora.
- **Sem conexão.** As telas de ajuda, passo a passo e configurações continuam
  abrindo, porque não dependem do servidor. "Meus aplicativos" e "Serviços
  sociais" mostram o último catálogo recebido (FR-024a). A conversa, que
  depende do servidor, diz em linguagem comum que precisa de internet.
- **Apresentação interrompida.** Quem fecha o aplicativo no meio da
  apresentação inicial a vê do começo na próxima entrada, porque não chegou ao
  fim.
- **Saída por inatividade em tela aberta.** Quando a sessão expira, nenhuma
  tela interna fica por cima do login, inclusive as novas.

---

## Requirements *(mandatory)*

### Requisitos Funcionais — Linguagem visual

- **FR-001**: Todas as telas do aplicativo MUST seguir uma única linguagem
  visual: mesma estrutura de cabeçalho, mesma posição de "Voltar", mesma
  hierarquia de título, texto e ação, mesmo tratamento de ilustração.
- **FR-002**: Cada tela MUST ter **uma** ação principal visualmente destacada.
  As demais ações são visivelmente secundárias. Verificado na revisão de
  design; automaticamente, só no limite de um cartão principal por tela.
- **FR-002a**: Tela que pede ação MUST separar cada etapa ou grupo numa
  **caixa própria**, com uma frase dizendo o que fazer ali, em vez de juntar
  campos, explicação e botões num bloco só. Quem usa é uma pessoa idosa: a
  instrução vem escrita ao lado do que ela vai tocar (revisão da T044).
- **FR-003**: A Memora MUST aparecer como personagem com rosto reconhecível nas
  telas em que fala com a pessoa: apresentação, conversa, ajuda e passo a passo.
- **FR-004**: As telas de entrada, apresentação, Início, Hub, Ajuda e passo a
  passo MUST usar ilustração, além de texto, para dizer do que se trata.
- **FR-005**: A identidade visual que o protótipo acertou MUST ser preservada:
  a paleta azul medida e aprovada, a Memora como personagem e os balões de fala.
- **FR-006**: Toda tela MUST ter desenho próprio para os estados carregando,
  vazio e erro, com frase na voz da Memora. Nenhuma tela mostra área em branco
  enquanto espera.
- **FR-007**: Nenhum elemento de desenvolvimento ou demonstração MUST estar
  visível para a pessoa: abas de teste, vitrine de componentes, textos
  provisórios.
- **FR-008**: Rótulos visíveis MUST estar em linguagem comum. Termos técnicos
  como "Hub", "Chatbot" e "App" não aparecem para a pessoa; o wireframe os usa
  como nome de trabalho. "Aplicativo", por extenso, é linguagem comum.

### Requisitos Funcionais — Primeiro contato

- **FR-009**: A primeira tela, para quem não tem sessão **e nunca entrou neste
  aparelho**, MUST mostrar ilustração, uma frase dizendo para que o Memora serve
  e uma ação principal para começar, mais o caminho para quem já tem conta. O
  conteúdo MUST ocupar a altura da tela, sem um vazio embaixo (revisão da T044).
- **FR-009a**: Quem já entrou neste aparelho antes (há identificador do último
  acesso) MUST ver outra tela, de **volta**: ilustração de fundo (a Memora ou
  uma pessoa idosa), uma frase de boas-vindas de volta, "Entrar" como ação
  principal e o caminho para criar outra conta (revisão da T044).
- **FR-009b**: O ícone do aplicativo no celular MUST ser a Memora (o robô), no
  mesmo estilo das ilustrações de pessoas, e o nome sob o ícone MUST ser
  **"Memora"**, com maiúscula (revisão da T044).
- **FR-010**: Cadastro e login MUST ser redesenhados na nova linguagem sem mudar
  os campos e regras decididos na feature 001.
- **FR-011**: Botões de entrar com Google ou Facebook MUST aparecer só quando
  esse caminho funcionar de ponta a ponta.
- **FR-012**: Na primeira entrada depois do cadastro, a Memora MUST se
  apresentar em no máximo três telas — quem ela é, para que serve a conversa, um
  exemplo de conversa — cada uma com "Continuar" e uma opção visível de pular.
- **FR-013**: A apresentação MUST aparecer uma vez por aparelho e por conta, só
  contar como vista quando chegar ao fim ou for pulada, e poder ser revista pela
  Ajuda.

### Requisitos Funcionais — Início, Hub e navegação

- **FR-014**: Depois de entrar, a pessoa MUST chegar ao Início, que a cumprimenta
  pelo nome de tratamento e oferece um atalho para conversar com a Memora e um
  para ver todas as partes do aplicativo.
- **FR-015**: Todas as telas internas MUST ter uma barra inferior fixa com três
  destinos — Configurações, Início e Perfil —, cada um com desenho e nome
  escrito. **O rótulo visível do destino de configurações é "Ajustes"**
  (decisão de implementação de 2026-10-01, a confirmar pela equipe): a 200%
  num 320×568, "Configurações" quebrava em três a cinco linhas na barra, e é o
  nome do aplicativo de configurações do próprio Android. Nesta spec,
  "Configurações" continua sendo o nome do destino; o texto que a pessoa lê é
  "Ajustes". Os ícones MUST ser desenhados para a barra — reconhecíveis sem o
  rótulo e com peso visual igual entre os três (revisão da T044). O destino
  atual é marcado por mais de um sinal além da cor. A única
  exceção é o teclado aberto: a barra se esconde e volta quando ele fecha, para
  o campo de escrever não ficar espremido.
- **FR-016**: O Hub MUST mostrar as partes do wireframe — conversar com a
  Memora, serviços sociais, meus aplicativos e ajuda —, além de "O que eu fiz
  por você", que vem da 003. Planos não entra (US9). Cada parte tem
  ilustração, nome e uma linha de explicação. O Hub continua simples, mas cada
  porta MUST ter acabamento de botão refinado — profundidade, contorno e
  estado pressionado visíveis —, e não a aparência de uma faixa chapada
  (revisão da T044).
- **FR-017**: Em qualquer aparelho suportado e em qualquer ampliação, a porta
  principal do Hub (conversar com a Memora) MUST aparecer sem rolar, e o Hub
  MUST mostrar que há mais portas abaixo quando houver. O Hub inteiro MUST
  caber sem rolagem no aparelho mais comum (360×800) em 100%. **Uma exceção
  medida**: no menor aparelho (320×568) a 200%, basta a porta principal
  começar à vista com o alvo de toque dela inteiro acima da barra — o
  cabeçalho sozinho toma 326 dos 421 px disponíveis, e a porta tem 220.
  (Antes: sem rolagem em 100% e 150% no **menor** aparelho, 320×568. Inviável a
  150% junto com a FR-016 — a barra inferior sozinha toma 123 dos 568 px —, e
  a 100% só cabia apertando as portas, o oposto do "junto demais" da revisão da
  T044. Decisão do Henrique, 2026-10-02. **Revista no mesmo dia**, depois de
  a T113 medir: o 360×800 a 150% também não cabia — o cabeçalho toma 200 px,
  cada explicação quebra em duas ou três linhas e a última porta termina ~170
  px abaixo da barra, 138 mesmo com o respiro no piso. O que sobra é a
  explicação que a FR-016 exige. O Hub inteiro ficou só a 100%; a 150%, a
  faixa "há mais" e a principal à vista cumprem a regra geral.)
- **FR-018**: Uma parte que ainda não funciona MUST NOT ser mostrada no Hub, nas
  Configurações nem na Ajuda.
- **FR-019**: Sair da conta MUST ficar em Configurações → Conta, e não no Hub nem
  no Início, com a confirmação que a feature 001 exige.

### Requisitos Funcionais — Conversa

- **FR-020**: A conversa MUST distinguir a fala da Memora e a da pessoa por
  posição, desenho e nome, nunca só pela cor.
- **FR-020a**: A fala da Memora MUST mostrar em negrito o trecho entre `**` e
  MUST NOT mostrar os asteriscos. O leitor de tela MUST receber o texto sem
  marca nenhuma. Nenhuma outra formatação é interpretada; marca sem par fica
  como texto comum (clarificação de 2026-10-21).
- **FR-020b**: Enquanto a Memora prepara a resposta, a espera MUST aparecer
  **só** como o balão dela se formando, sem frase de espera embaixo do campo.
  A resposta MUST ir aparecendo aos poucos, como quem escreve, e, com "reduzir
  movimento", MUST aparecer de uma vez. O leitor de tela MUST anunciar a fala
  inteira, e não letra a letra (clarificação de 2026-10-21).
- **FR-021**: Quando a Memora oferece executar algo, as opções MUST aparecer
  como frases completas, com toque grande e afastadas uma da outra, mantendo as
  regras de confirmação da 003.
- **FR-022**: Os avisos de segurança da conversa MUST continuar presentes e
  legíveis, e a conversa com o campo de escrever MUST ocupar pelo menos metade
  da altura disponível em 100% e 150% de ampliação, no menor aparelho
  suportado. O aviso de que a Memora nunca pede senha nem código MUST ficar
  aberto até a pessoa mandar a primeira pergunta da conversa — e só até ela,
  mesmo que uma falha devolva a pergunta ao campo — e, a partir dela, encolher
  para **o escudo**, num canto, que a pessoa toca para ler os avisos inteiros.
  O escudo MUST ter alvo de toque de 48 dp e MUST levar ao leitor de tela o
  núcleo do aviso ("senha" e "código"). Ele MUST NOT sumir, nem por gesto da
  pessoa (revisão da T044; escudo na clarificação de 2026-10-21).

### Requisitos Funcionais — Aplicativos e passo a passo

- **FR-023**: "Meus aplicativos" MUST mostrar cada aplicativo numa **lista**,
  com o ícone reconhecível **à esquerda** e o nome escrito ao lado, com busca
  no topo. (Antes: numa grade. Mudado na revisão da T044: o ícone à esquerda
  com o nome na mesma linha é o que se lê de relance.)
- **FR-024**: A busca MUST encontrar por parte do nome, sem diferenciar
  maiúsculas e acentos.
- **FR-024a**: O aparelho MUST guardar o último catálogo recebido, para "Meus
  aplicativos", "Serviços sociais" e os passo a passo funcionarem sem internet.
  Com conexão, o catálogo é atualizado, e um item retirado do ar some na
  primeira atualização. O catálogo guardado não é dado da pessoa e não sai ao
  sair da conta.
- **FR-025**: Cada aplicativo e cada serviço do catálogo MUST ter um passo a
  passo de aprendizado: um passo por tela, com imagem do que a pessoa vai
  encontrar, o ponto a tocar destacado, uma frase curta e a indicação "passo N
  de M".
- **FR-026**: Todo passo MUST permitir voltar ao anterior, sair do passo a passo
  e dizer "a minha tela está diferente". Esse caminho MUST mostrar **primeiro,
  no próprio guia e sem depender de internet**, que uma tela diferente que
  peça senha ou código sem a pessoa esperar pode ser golpe, e que nesse caso é
  para parar; **depois**, oferece a conversa com a Memora. (Revisão da #36: o
  aviso morava só na conversa, que precisa de internet e de um provedor que
  ainda não foi escolhido — offline, a pessoa nunca o via.)
- **FR-027**: O último passo MUST parabenizar a pessoa e oferecer voltar ao Hub.
  Para aplicativo que a Memora pode abrir (regra D1 da 003), oferece também
  pedir à Memora que o abra — **pelo mesmo caminho de qualquer abertura**: a
  conversa leva o pedido ao servidor, o `AutorizadorDeAcao` decide, e só então
  vêm a confirmação, o registro e o aviso de saída da 003. O passo a passo
  **não abre nada sozinho**. Sem conexão, ou com o catálogo vindo do que o
  aparelho guardou, essa oferta não aparece — o guia continua ensinando.
  (Revisão da #36: a versão anterior criava uma segunda forma de abrir
  aplicativo, sem passar pelo autorizador, e com o catálogo guardado a decisão
  sairia de um arquivo local sem prazo de validade.)
- **FR-028**: Toda imagem de tela de outro aplicativo, no passo a passo, MUST
  estar marcada visivelmente como exemplo e MUST NOT conter dado pessoal real.
- **FR-028a**: Enquanto a captura de um passo não existir, o passo MUST mostrar
  no lugar dela um aviso visível de **captura pendente**, com a chave do guia e
  o número do passo, e o texto do passo continua funcionando. Um teste lista
  as capturas pendentes; a lista MUST chegar a zero antes da revisão de design final. É o aviso ao
  desenvolvimento que a revisão da T044 pediu, porque as capturas dependem da
  equipe.
- **FR-028b**: A captura de cada passo MUST poder ser ampliada: tocar nela, ou
  num botão visível logo abaixo dela, abre a imagem em tela cheia, dentro do
  Memora. A ampliação MUST oferecer, além do gesto de dois dedos, botões de
  **aproximar** e **afastar** — o primeiro leva ao destaque do passo — e um
  botão de **fechar** sempre à vista, todos com alvo de 48 dp. A imagem
  ampliada MUST continuar com o selo de exemplo e o destaque (FR-028), MUST ter
  a descrição da captura para o leitor de tela (FR-045) e, com "reduzir
  movimento", MUST NOT animar a aproximação.
- **FR-028c**: O destaque do passo MUST cair sobre a região da **imagem** que
  ele aponta, qualquer que seja a proporção da captura e o tamanho da tela —
  na moldura e na ampliação.
- **FR-029**: O passo a passo MUST acontecer inteiro dentro do Memora. O Memora
  MUST NOT pedir permissão para aparecer por cima de outro aplicativo.

### Requisitos Funcionais — Serviços sociais

- **FR-030**: "Serviços sociais" MUST oferecer os serviços do wireframe: Gov.br,
  e-Título, Serasa, FGTS, Poupatempo, Carteira Digital, Correios e Carteira de
  Trabalho, além do Meu INSS, que já está no catálogo.
- **FR-031**: Todo serviço de "Serviços sociais" MUST ser só ensinado, nunca
  aberto pela Memora, conforme a decisão D2 da 003.
- **FR-032**: O passo a passo de um serviço MUST começar pelo que a pessoa
  precisa ter em mãos e, em todo passo com campo de senha, MUST dizer que a
  senha só é digitada no aplicativo oficial.

### Requisitos Funcionais — Ajuda

- **FR-033**: A Ajuda MUST oferecer os assuntos do wireframe que funcionam: o
  aplicativo, a Memora, a conversa, os serviços, como baixar um aplicativo, como
  compartilhar o Memora e segurança contra golpes. O assunto "Planos" do
  wireframe não entra (US9).
- **FR-034**: O assunto "A conversa" MUST mostrar um exemplo guiado de conversa,
  passo a passo, com saída direta para a conversa de verdade.
- **FR-035**: O assunto "Compartilhar" MUST enviar só o endereço oficial de
  download do Memora, avisando antes que a pessoa vai mandar algo para fora do
  aplicativo.
- **FR-036**: O assunto "Como baixar um aplicativo" MUST ensinar a usar só a loja
  oficial do aparelho, e dizer por quê.
- **FR-036a**: A apresentação inicial, o assunto "Segurança" da Ajuda e a tela
  de Conta MUST dizer, em linguagem comum, o que **ninguém do Memora** faz:
  pedir senha ou código **por telefone, mensagem ou e-mail**, ligar para a
  pessoa, pedir para instalar aplicativo **fora da loja oficial** ou "para o
  Memora funcionar", ou cobrar qualquer valor. (Revisão da #36: a versão
  anterior dizia que o Memora "nunca pede senha nem código" — e ele pede, no
  login, na recuperação e na confirmação do canal. Literal é o que o Princípio
  II exige; a ressalva do canal é a mesma da FR-023 da 001.)
- **FR-037**: Link para fora do Memora MUST levar só a endereço oficial, ser
  anunciado antes de abrir e dizer para onde leva. Nesta feature, o único é o
  endereço de download do "Compartilhar"; um link novo exige voltar a esta spec.

### Requisitos Funcionais — Configurações e Perfil

- **FR-038**: Configurações MUST ter os grupos Aparência, **Acessibilidade**,
  Privacidade e Conta. (Antes: "Tela" e "Acessibilidade" juntos em Aparência.
  Separados na revisão da T044: acessibilidade é foco do produto, e escondê-la
  dentro de "Aparência" a trata como gosto.) "Notificações" e "Idiomas" só
  aparecem quando existirem.
- **FR-039**: Aparência MUST permitir escolher entre os temas validados e entre
  **paletas prontas de cor de destaque** — de cinco a seis —, com
  pré-visualização antes de confirmar. A paleta vale nos temas claro e escuro;
  no **alto contraste ela não se aplica**, porque ele existe para o máximo
  contraste. Toda combinação de tema claro ou escuro com paleta MUST passar no
  validador de contraste antes de existir; cor livre MUST NOT ser oferecida
  (revisão da T044).
- **FR-039a**: Acessibilidade MUST reunir o tamanho do texto, reduzir movimento
  e o tema de alto contraste, cada opção com uma frase dizendo **para quem ela
  serve** ("Se as letras parecem pequenas…"), e com pré-visualização antes de
  confirmar.
- **FR-040**: Privacidade MUST dizer em linguagem comum o que fica guardado no
  aparelho e permitir apagar a conversa. Apagar é irreversível, e por isso MUST
  usar a confirmação irreversível da feature 002, em duas etapas e sem o botão
  de apagar ao lado do de cancelar (Princípio II).
- **FR-041**: Conta MUST mostrar o canal de contato da conta e oferecer sair, e
  sair esquecendo também o identificador lembrado. A segunda é a mais
  destrutiva das duas e MUST NOT ficar adjacente à primeira (Princípio II):
  fica separada, abaixo, com uma frase dizendo para que serve — aparelho
  compartilhado ou que vai ser vendido. Como apaga sem volta o que o aparelho
  guarda de todas as contas, MUST usar a confirmação irreversível da FR-040, em
  duas etapas e sem o botão de esquecer ao lado do de cancelar.
- **FR-042**: O Perfil MUST mostrar nome, desenho, canal de contato, o
  aplicativo mais aprendido e, se a pessoa a tiver informado, a **idade**, como
  informação e nunca como botão. MUST NOT mostrar plano.
- **FR-042c**: A data de nascimento MUST ser **opcional**, informada só no
  Perfil (nunca no cadastro), e MUST ficar **só no aparelho**, por conta, sem ir
  ao servidor. Sai com `esquecerTudo`, como o identificador do último acesso;
  não sai na saída comum, para a pessoa não precisar digitá-la de novo a cada
  entrada (revisão da T044). É dado **Confidencial** e fica no aparelho sem
  cifra, como o canal de contato. Fora da tela em que é informada, nenhuma
  tela MUST mostrar a data: o Perfil mostra só a idade.
- **FR-042a**: O aplicativo mais aprendido MUST ser calculado no aparelho, a
  partir dos passo a passo concluídos, e MUST NOT ser enviado ao servidor.
- **FR-042b**: O progresso de aprendizado MUST ser apagado do aparelho quando a
  pessoa sai da conta, junto com a conversa (FR-048 da 003).

### Requisitos de Acessibilidade *(obrigatórios — Princípio III)*

- **FR-043**: Toda tela nova ou redesenhada MUST cumprir o que a constituição
  exige: contraste WCAG 2.2 AA, toque de 48 dp com 8 dp entre alvos, texto
  ampliado até 200% sem perda de conteúdo, rótulo para leitor de tela em todo
  elemento interativo, ícone sempre com texto, cor nunca como único sinal e
  **feedback visual para cada estado** que o elemento tem — normal, foco,
  pressionado, carregando, erro, sucesso e desabilitado.
- **FR-044**: Toda tela MUST ser verificada em todos os aparelhos suportados, nas
  três escalas de texto e nos três temas, sem estouro e com a ação principal
  alcançável.
- **FR-045**: Ilustração decorativa MUST ser ignorada pelo leitor de tela, e
  ilustração que informa MUST ter descrição.
- **FR-046**: Toda animação nova MUST respeitar "reduzir movimento".

### Requisitos de Segurança *(obrigatórios — Princípios I e II)*

- **FR-047**: O redesenho MUST NOT retirar nenhuma proteção existente. Todos os
  portões de segurança das features 001 e 003 continuam passando.
- **FR-048**: Nenhuma tela nova MUST pedir senha, código, documento ou dado
  bancário. O passo a passo ensina onde digitá-los; ele não os recebe.
- **FR-049**: Os avisos de segurança MUST continuar existindo onde as features
  anteriores os exigem, no tamanho necessário para serem lidos e não maior: o
  aviso compacto pode se expandir quando a pessoa toca nele. **O aviso
  compacto é só da conversa**, onde a falta de espaço foi medida. Na
  recuperação de acesso o aviso continua inteiro: o golpe daquela tela pede o
  número de 6 dígitos, e esconder o "número" atrás de um toque enfraqueceria a
  FR-023 da 001 sem resolver problema nenhum (revisão da #36). O resumo
  sempre visível de qualquer aviso compacto MUST conter o núcleo do aviso —
  exceto o da conversa depois da primeira pergunta, que é só o escudo e leva o
  núcleo ("senha" e "código") no rótulo para o leitor de tela (FR-022,
  clarificação de 2026-10-21).
- **FR-050**: Os dados mostrados no Perfil e em Conta MUST ser só os da própria
  conta, e MUST sumir da tela quando a sessão expira.

### Key Entities

- **Passo a passo**: o caminho de aprendizado de um aplicativo ou serviço.
  Pertence a um item do catálogo, tem uma lista ordenada de passos e diz o que
  a pessoa precisa ter em mãos.
- **Passo**: uma tela do passo a passo. Tem a imagem de exemplo, o ponto a tocar
  destacado, a frase curta e a posição no caminho.
- **Assunto de ajuda**: um tema da Ajuda, com nome, desenho e uma explicação em
  uma ou mais telas.
- **Apresentação vista**: a marca, no aparelho, de que a pessoa já viu a
  apresentação inicial. Não sai do aparelho.
- **Progresso de aprendizado**: quais passo a passo a pessoa concluiu. Vive só
  no aparelho, sai junto com a conta, e é a origem do "aplicativo mais
  aprendido".
- **Catálogo guardado**: a última lista de aplicativos e serviços recebida do
  servidor. Fica no aparelho para o uso sem internet (FR-024a); não é dado da
  pessoa.
- **Data de nascimento**: opcional, por conta, só no aparelho. Confidencial.
  Sai só com `esquecerTudo` (FR-042c).
- **Perfil exibido**: os dados que o Perfil mostra. Não cria dado novo no
  servidor.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cada uma das 35 telas do wireframe existe no aplicativo ou tem a
  decisão de não existir registrada nesta spec, com o motivo.
- **SC-002**: No teste com 5 pessoas de 65+, pelo menos 4 vão da primeira tela à
  primeira conversa sem ajuda, em até 5 minutos.
- **SC-003**: No mesmo teste, pelo menos 4 de 5 completam sozinhas: aprender um
  aplicativo pelo passo a passo, achar uma dica de segurança na Ajuda e aumentar
  o texto.
- **SC-004**: No mesmo teste, a nota média é de pelo menos 4 de 5 para "é fácil
  de usar", "parece confiável" e "é bonito", em perguntas lidas em voz alta.
- **SC-005**: Os três integrantes da equipe aprovam a nova versão em revisão de
  design, comparando-a, tela a tela, com a de hoje e com o wireframe.
- **SC-006**: Qualquer parte do aplicativo é alcançada em até 3 toques a partir
  do Início.
- **SC-007**: Nenhuma tela estoura nem perde a ação principal, em nenhuma
  combinação de aparelho suportado, escala de texto e tema.
- **SC-008**: Todos os portões de segurança e cenários automatizados existentes
  continuam passando ao fim da feature.
- **SC-009**: Nenhum elemento de desenvolvimento aparece no aplicativo que a
  pessoa recebe.

---

## Assumptions

- **A revisão de design no aparelho é portão do merge.** Depois da reprovação
  do acabamento na T044, nenhuma tela nova entra na `master` antes da segunda
  rodada (T116). Implementar antes é permitido; mesclar, não. As PRs de tela
  abertas até 2026-10-13 ficam de fora, porque a T116 as revisa no aparelho.
- **"Profissional e moderno" é verificado por gente, não por máquina.** O SC-004
  e o SC-005 são as medidas; não existe teste automatizado de beleza.
- **A linguagem visual nova nasce do Design System, e não ao lado dele.** Se o
  redesenho exigir componentes ou tokens novos, eles entram no sistema da
  feature 002, com os portões de contraste e de tokens que ela já tem.
- **A paleta fica.** A medição da 002 mostrou que o protótipo acertou a paleta e
  errou o tamanho. O redesenho mexe em hierarquia, ilustração e composição, e
  não na cor base.
- **"Início" e "Hub" continuam duas telas**, como no wireframe. O Início
  cumprimenta e leva ao que a pessoa mais faz; o Hub mostra tudo.
- **"Tela" e "Acessibilidade" ficaram juntas em "Aparência" no wireframe**, que
  as trata como cor, tema e fonte. A revisão da T044 as separou: Acessibilidade
  é grupo próprio (FR-038).
- **"Idiomas" e "Notificações" ficam fora** enquanto não houver segundo idioma
  nem notificação, pela regra de não mostrar porta que não abre (D3 da 002 e
  US1 da 003).
- **Os serviços sociais são todos sensíveis**, incluindo Correios e Serasa:
  pedem documento ou tratam de crédito, e a D2 da 003 vale para eles.
- **O passo a passo é conteúdo do Memora, preparado pela equipe**, e não gerado
  pela assistente na hora. Isso permite revisá-lo, e não depende do provedor de
  IA, que ainda não foi escolhido.
- **O menor aparelho suportado é o de 320×568**, como na matriz de aparelhos que
  as features anteriores já usam.
- **Voz continua fora de escopo** (contradição 1 de `requisitos-atualizados.md`).
  **Uso offline é parcial, e só isto:** os guias e o último catálogo recebido
  funcionam sem internet (FR-024a); a conversa continua exigindo conexão
  (contradição 2). Não é suporte offline do produto inteiro.

---

## Threat Model *(obrigatório — Princípio I)*

### Dados sensíveis envolvidos

| Dado | Classificação | Onde aparece |
|---|---|---|
| Nome de tratamento | Interno | Início, Perfil |
| Canal de contato (e-mail ou telefone) | Confidencial | Perfil, Conta |
| Marca de apresentação vista | Público | Só no aparelho |
| Progresso de aprendizado | Interno | Perfil; só no aparelho |
| Data de nascimento | Confidencial | Perfil, só como idade; a data, só na tela de informar; só no aparelho |
| Imagens de exemplo de outros aplicativos | Público | Passo a passo; não podem conter dado real |

### Quem pode acessar

- A pessoa dona da conta, com sessão válida, vê os próprios dados.
- Quem pega o aparelho desbloqueado com sessão aberta vê o mesmo, até a
  inatividade encerrar a sessão (FR-017 da 001).
- Nenhuma tela desta feature envia dado novo ao servidor. Os dois dados novos
  ficam no aparelho e nunca vão para a cópia de segurança fora dele: o
  progresso de aprendizado sai junto com a conta, e a data de nascimento sai só
  com `esquecerTudo` (FR-042c).

### Ataques previstos e mitigação

| Ataque | Como | Mitigação |
|---|---|---|
| A pessoa aprende a digitar senha na tela errada | O passo a passo mostra a tela de entrada do gov.br; um golpista depois mostra uma tela parecida | FR-028 e FR-032: imagem marcada como exemplo, e a frase de que a senha só vai no aplicativo oficial |
| Treinar o gesto de conceder permissão perigosa | Para aparecer por cima de outro aplicativo, o Memora pediria a permissão que os vírus bancários mais usam no Brasil | FR-029: o passo a passo fica dentro do Memora, e essa permissão nunca é pedida |
| Aparelho compartilhado revela o que a pessoa não sabe fazer | Outra pessoa abre o Perfil e vê o progresso de aprendizado | FR-042b: o progresso sai do aparelho junto com a conta |
| Link falso compartilhado em nome do Memora | "Compartilhar" vira canal para mandar endereço malicioso | FR-035: só o endereço oficial, fixo |
| Aplicativo falso na loja | A pessoa procura o aplicativo pelo nome e instala uma cópia | FR-036: ensinar a conferir o desenvolvedor na loja oficial |
| Dados do Perfil expostos no aparelho esquecido | Alguém abre o Perfil com a sessão aberta | FR-050 e a inatividade da 001 |
| Golpe "seu plano venceu" | Com uma tela de plano no Memora, a cobrança falsa por link fica crível | US9: não existe plano, assinatura nem pagamento em lugar nenhum do aplicativo |

### Monitoramento e registro

Esta feature não cria ação crítica nova. Abrir aplicativo continua passando pela
confirmação e pelo registro da 003. Pagamento, se um dia existir, será ação
crítica, com confirmação e registro (Princípio VI), e chegará em feature
própria.

---

## Análise de Engenharia Social *(obrigatório — Princípio II)*

*"Como um golpista tentaria explorar esta tela?"*

| Tela | Exploração possível | Resposta da spec |
|---|---|---|
| Apresentação inicial | Golpista se passa pela Memora ("a Memora pediu seu código") | FR-036a: a apresentação diz o que a Memora nunca faz |
| Passo a passo do gov.br | Tela de exemplo vira modelo para tela falsa | FR-028, FR-032 |
| Ajuda → Compartilhar | Mensagem "do Memora" com link trocado | FR-035 |
| Ajuda → Baixar aplicativo | "Baixe este aplicativo para o Memora funcionar" | FR-036 e FR-036a: o Memora nunca pede para instalar outro aplicativo |
| Perfil / Conta | Ligação "do suporte do Memora" pede para ler o e-mail da tela | FR-036a: a Conta diz que o Memora não liga para ninguém |
| Perfil → informar a data de nascimento | Ligação "do INSS" ou "do banco" pede a data "para confirmar o cadastro", ou alguém lê a data na tela do aparelho | FR-042c: a data só aparece na tela em que é informada, e o Perfil mostra só a idade. Ela nunca é pedida fora do Perfil nem no cadastro, e a FR-036a diz que o Memora não liga para ninguém |
| Planos (ausente) | "Seu plano do Memora venceu, pague por este link" | US9: o Memora não tem plano; FR-036a: o Memora diz que nunca cobra |
| Conversa redesenhada | Aviso compacto deixa de ser notado | FR-049: compacto, mas sempre visível, e expansível |
| Boas-vindas, cadastro e login | As explorações já analisadas na 001 | O redesenho muda a aparência, não o comportamento (FR-010); a análise da 001 continua valendo |
| Início | Ligação: "abra o Memora e toque em tal lugar" | O Início só leva a partes do próprio Memora; nenhum atalho abre outro aplicativo nem link |
| Hub | Porta falsa inserida por fora | As portas são fixas no aplicativo, como já são hoje: o servidor não acrescenta porta |
| Meus aplicativos (busca) | Aplicativo falso instalado com o mesmo nome do verdadeiro | O item é ligado ao **pacote**, não ao nome, e o aparelho só enxerga os pacotes declarados (R7 do plano). A cópia não aparece na lista e não pode ser aberta pelo Memora |
| Serviços sociais | Tela que imita o Memora com um "Entrar no gov.br" | Nenhum item abre nada (FR-031), e não há logotipo oficial na tela para imitar |
| Fim do passo a passo → "Peça à Memora para abrir" | Fazer o Memora abrir o aplicativo errado, ou um que saiu do catálogo | FR-027: o guia não abre nada; o pedido vai pela conversa, e quem decide é o `AutorizadorDeAcao` no servidor. Offline, a oferta não aparece |
| Passo → "A minha tela está diferente" | A tela "diferente" é um site falso pedindo senha | FR-026: o próprio guia, antes da conversa e sem internet, diz que tela diferente pedindo senha ou código pode ser golpe |
| Configurações → Aparência | — | Não guarda dado da pessoa nem leva para fora do Memora: nenhuma exploração identificada |
| Configurações → Privacidade | "Apague a conversa para liberar espaço" | FR-040: confirmação irreversível em duas etapas |
| Ajuda → a conversa guiada | O exemplo vira roteiro ("a Memora disse para me passar…") | O exemplo nunca contém pedido de dado, e vem marcado como exemplo, como as capturas (FR-028) |

---

## Dependências

- **Feature 001**: regras de cadastro, login, recuperação, saída e inatividade.
  Esta feature muda a aparência dessas telas, não as regras.
- **Feature 002**: Design System, temas, matriz de aparelhos e portões de
  contraste e de tokens.
- **Feature 003**: Hub, conversa, catálogos, regras D1, D2 e D3, registro.
- **Wireframe**: `docs/design/prototipo/` e as Figuras 1 a 36 do Arquivo X.
- **Teste com 5 pessoas de 65+**: os SC-002 a SC-004 só se verificam com ele,
  como já acontece nas features 001 e 002.
