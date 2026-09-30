# Feature Specification: Hub e a assistente que ensina

**Feature Branch**: `003-hub-e-assistente`

**Created**: 2026-08-29

**Status**: Draft

**Input**: Hub do Memora e o ambiente do chat da assistente. O Hub é a tela que conecta todas as partes do sistema depois que a pessoa entra na conta. A assistente **ensina primeiro** e só executa a ação pela pessoa se ela não conseguir ou pedir, sempre com confirmação explícita e registro.

---

## Contexto

As features 001 e 002 são fundação: identidade e vocabulário visual. Elas
respondem *"quem é você"* e *"como o Memora se parece"*. **Nenhuma das duas
responde para que o Memora serve.**

Hoje, quem termina o cadastro chega a uma tela provisória que diz *"Você está
dentro"* e oferece um único botão: sair. Esta feature é o que existe depois
dessa porta.

### A contradição que esta spec resolve

O Arquivo X descreve, na figura 11, um chatbot que **abre o aplicativo pela
pessoa**: *"Botão Sim: Acessa a segunda parte do Chat, aonde é redirecionado ao
instagram"*. As telas do protótipo confirmam — *"Quer que eu abra o Whatsapp
para o senhor?"* → **SIM** → *"Abrindo Instagram…"*.

Isso contraria o **Princípio VII — Ensinar, Não Substituir**. Se a Memora abre o
aplicativo, a pessoa não aprende o caminho, e na próxima vez precisa da Memora
de novo. O próprio protótipo percebe a tensão e não a resolve: numa tela a
assistente diz *"não quero que você fique dependente de mim"*, e na seguinte
abre o aplicativo mesmo assim.

**A decisão desta spec**: a assistente **ensina primeiro**. Ela mostra o caminho
passo a passo para a pessoa tocar sozinha. Só executa quando a pessoa **não
consegue** ou **pede explicitamente** — e aí com confirmação clara e registro
auditável, como o Princípio VI exige.

Isso não é rigor acadêmico. É o produto: se a Memora fizer tudo, ela vira mais
um aplicativo que a pessoa não sabe usar, operado por alguém que ela não vê.

---

## Clarifications

### Session 2026-09-30

- Q: O que o provedor de IA pode guardar da conversa que recebe a cada turno? → A: Proibido treinar com ela; retenção só para monitoramento de abuso, por no máximo 30 dias, documentada em contrato ou termos do provedor (FR-051).
- Q: Quanto tempo a espera pela resposta pode durar (SC-007)? → A: As primeiras palavras aparecem em até 5 s; sem resposta em 30 s, a espera é encerrada, a Memora explica que o problema é a conexão e oferece tentar de novo (FR-052).
- Q: Qual o limite diário de conversas por conta? → A: 20 por dia, ajustável na configuração do servidor sem nova versão do aplicativo, e revisto depois do teste com as 5 pessoas de 65+ (FR-053).
- Q: Por quanto tempo a conversa fica guardada no aparelho? → A: Mensagens com mais de 30 dias são apagadas sozinhas, sem ação da pessoa (FR-054).
- Q: Por quanto tempo o servidor guarda o registro de ações da assistente? → A: 12 meses para o registro; o resumo do pedido é apagado antes, aos 90 dias, e o fato de a ação ter acontecido permanece (FR-055).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Chegar ao Hub e saber o que fazer (Priority: P1)

Dona Ana termina de entrar na conta e chega ao Hub. Ela vê poucas portas, cada
uma com nome em linguagem comum e um desenho ao lado. Não há menu escondido,
não há gesto a descobrir, não há nada piscando pedindo atenção. Ela entende, sem
ajuda, o que cada porta abre — e reconhece o Hub como *o lugar para onde eu
sempre volto*.

**Why this priority**: sem o Hub não há produto. É a tela que a pessoa verá mais
vezes na vida do aplicativo, e é a que decide se ela se sente perdida ou em casa.

**Independent Test**: entregar o aparelho a uma pessoa de 65+ recém-cadastrada,
sem instrução, e pedir que ela diga em voz alta o que cada porta faz.

**Acceptance Scenarios**:

1. **Given** que acabei de entrar na conta, **When** o Hub aparece, **Then** vejo
   as portas disponíveis — conversar com a Memora, serviços do dia a dia, meus
   aplicativos e ajuda — com nome escrito e desenho, sem precisar rolar para
   descobrir que existem mais.
2. **Given** que estou em qualquer tela do aplicativo, **When** procuro como
   voltar, **Then** existe um caminho visível e sempre no mesmo lugar que me traz
   de volta ao Hub.
3. **Given** que uma parte do Memora ainda não foi construída, **When** o Hub
   aparece, **Then** ela **não** é mostrada — porta que não abre nada é pior do
   que porta que não existe.

---

### User Story 2 - Pedir ajuda e aprender o caminho (Priority: P1)

Dona Ana quer ver a foto que o neto publicou e não lembra como. Ela abre a
conversa com a Memora e escreve com as próprias palavras: *"como vejo a foto do
meu neto"*. A Memora responde com o caminho, **um passo de cada vez**, esperando
Dona Ana concluir cada um antes de mostrar o seguinte. Ao final, Dona Ana viu a
foto — e fez ela mesma cada toque.

**Why this priority**: é a razão de o Memora existir. Uma assistente que responde
bem mas faz pela pessoa entrega o mesmo resultado hoje e nenhuma autonomia
amanhã.

**Independent Test**: pedir a uma pessoa que nunca usou o aplicativo-alvo que
realize a tarefa guiada pela Memora, e depois pedir que a repita **sem** a
Memora. A segunda tentativa é o teste.

**Acceptance Scenarios**:

1. **Given** que pedi ajuda para uma tarefa, **When** a Memora responde,
   **Then** ela mostra **um passo por vez**, e não uma lista inteira de uma vez.
2. **Given** que estou no meio de um passo a passo, **When** digo que consegui,
   **Then** a Memora avança para o passo seguinte.
3. **Given** que terminei a tarefa com a Memora, **When** a conversa acaba,
   **Then** ela me diz que **eu** fiz, e não ela.
4. **Given** que escrevi com erro de digitação ou de forma confusa, **When** a
   Memora não entende, **Then** ela pergunta de volta em linguagem comum, sem
   dizer que eu escrevi errado.

---

### User Story 3 - Quando eu não consigo, a Memora faz por mim (Priority: P2)

Dona Ana tentou os passos e não conseguiu — o dedo não acerta, a tela mudou, o
dia está ruim. Ela diz à Memora que não está dando certo. A Memora **oferece**
fazer por ela, explica exatamente o que vai fazer, e espera uma confirmação
clara. Dona Ana confirma, a Memora executa, e depois mostra o que fez — para
que da próxima vez Dona Ana reconheça o caminho.

**Why this priority**: sem esta história o Princípio VII vira crueldade. Há dias
em que a pessoa não consegue, e um produto que responde *"tente de novo"* nesse
momento é abandonado. A dignidade de quem não conseguiu hoje importa tanto
quanto a autonomia de amanhã.

**Independent Test**: declarar dificuldade à Memora e verificar que ela oferece
executar, confirma antes, executa, e depois mostra o caminho percorrido.

**Acceptance Scenarios**:

1. **Given** que declarei que não consegui, **When** a Memora oferece fazer por
   mim, **Then** ela diz **exatamente** o que vai fazer, em linguagem comum,
   antes de qualquer coisa acontecer.
2. **Given** que a Memora ofereceu executar, **When** eu não confirmo, **Then**
   nada acontece — e ela não insiste nem repete a oferta na mesma conversa.
3. **Given** que confirmei, **When** a ação termina, **Then** a Memora me mostra
   o caminho que percorreu, para eu reconhecer da próxima vez.
4. **Given** que pedi algo que a Memora **não pode** executar, **When** ela
   responde, **Then** ela explica que não faz aquilo e **por quê**, sem me culpar
   e sem oferecer contorno.
5. **Given** que a ação leva para fora do Memora, **When** ela é executada,
   **Then** sou avisada de que estou saindo do aplicativo **antes** de sair.

---

### User Story 4 - Ver o que a Memora fez por mim (Priority: P3)

Dona Ana quer conferir o que a Memora fez em seu nome — ou o filho dela quer.
Existe um lugar onde toda ação executada pela assistente aparece: o que foi
feito, quando, e a partir de qual pedido.

**Why this priority**: o Princípio VI exige log auditável de toda ação da IA.
Sem um lugar onde a pessoa **veja** esse registro, o log serve à equipe e não a
ela — e é justamente ela quem precisa poder desconfiar.

**Independent Test**: executar uma ação pela Memora e verificar que ela aparece
no registro, legível para quem não é técnico.

**Acceptance Scenarios**:

1. **Given** que a Memora executou algo por mim, **When** abro o registro,
   **Then** vejo o que foi feito e quando, em linguagem comum.
2. **Given** que a Memora **só ensinou**, sem executar, **When** abro o registro,
   **Then** aquilo não aparece como ação executada.

---

### User Story 5 - A Memora me ensina o banco, mas não entra nele (Priority: P2)

Dona Ana precisa consultar o benefício no aplicativo do governo. Ela pede ajuda
à Memora. A Memora ensina o caminho passo a passo — e quando Dona Ana pergunta
se ela não pode simplesmente abrir, a Memora explica que **não abre banco nem
governo**, e diz por quê: é assim que ela protege Dona Ana de quem ligar
dizendo ser do suporte.

**Why this priority**: é o inverso da conveniência, e é deliberado. Se a Memora
abrisse o aplicativo do banco, ela treinaria em Dona Ana exatamente o gesto que
o golpista precisa que ela tenha — o de deixar outra pessoa entrar na conta por
ela. A recusa aqui **é** a funcionalidade.

**Independent Test**: pedir à Memora que abra o aplicativo do banco, de várias
formas e insistindo, e verificar que ela ensina e nunca abre.

**Acceptance Scenarios**:

1. **Given** que pedi ajuda com um serviço sensível, **When** a Memora responde,
   **Then** ela ensina o caminho e **não** oferece abrir.
2. **Given** que pedi explicitamente para ela abrir o banco, **When** ela
   responde, **Then** recusa e explica que é para me proteger — sem me culpar.
3. **Given** que insisti várias vezes, **When** ela responde, **Then** a recusa é
   **a mesma**, e nenhuma insistência produz um caminho alternativo.
4. **Given** que estou na lista de serviços, **When** olho um item, **Then** sei
   antes de tocar se a Memora ensina ou se ela ensina e abre.

---

### Edge Cases

- **A pessoa pede algo perigoso.** *"Memora, transfere R$ 500 para o Carlos"* —
  a assistente recusa, explica que nunca mexe em dinheiro, e não oferece
  alternativa que contorne a recusa.
- **Alguém do outro lado da linha está ditando.** Uma pessoa ao telefone instrui
  Dona Ana a pedir algo à Memora. A assistente não tem como saber — por isso a
  lista de ações executáveis é fechada, e não depende do julgamento do modelo.
- **A conversa é interrompida no meio de um passo a passo.** A pessoa fecha o
  aplicativo e volta depois: precisa poder retomar ou recomeçar sem se sentir
  perdida.
- **A internet cai durante a conversa.** A assistente precisa de conexão; a
  pessoa precisa entender que o problema é a internet, e não ela. O mesmo vale
  para a resposta que não chega: depois de 30 segundos, a espera acaba (FR-052).
- **A assistente não sabe a resposta.** Dizer *"não sei"* com clareza é melhor do
  que inventar um caminho que não existe — um passo a passo errado faz a pessoa
  tocar em coisas que ela não pretendia.
- **A tela do outro aplicativo mudou.** O passo a passo descreve algo que não
  está mais lá. A pessoa precisa de uma saída que não a faça pensar que errou.
- **A pessoa acha que está falando com uma pessoa de verdade.** Precisa ficar
  claro, sem repetição cansativa, que a Memora é um programa.

---

## Requirements *(mandatory)*

### Requisitos Funcionais — Hub

- **FR-001**: O Hub MUST ser a primeira tela após a entrada na conta e o destino
  do caminho de volta a partir de qualquer tela do aplicativo.
- **FR-002**: Cada porta do Hub MUST ter nome escrito em linguagem comum **e**
  um elemento visual — nunca ícone isolado (Princípio III).
- **FR-003**: O Hub MUST exibir **apenas** portas que levam a funcionalidade
  existente. Porta para área não construída não é exibida.
- **FR-004**: O Hub MUST caber na tela sem rolagem no tamanho de texto padrão, e
  MUST permanecer utilizável com texto ampliado a 200%.
- **FR-005**: O caminho de volta ao Hub MUST estar sempre na mesma posição, em
  todas as telas que o oferecem.
- **FR-006**: O Hub MUST identificar a pessoa pelo nome de tratamento escolhido
  no cadastro.

### Requisitos Funcionais — A assistente ensina

- **FR-007**: A assistente MUST responder a pedidos escritos em linguagem comum,
  incluindo texto com erro de digitação.
- **FR-008**: A assistente MUST apresentar orientação **um passo por vez**,
  aguardando a pessoa concluir antes de mostrar o próximo.
- **FR-009**: A assistente MUST permitir que a pessoa peça para repetir o passo
  atual quantas vezes quiser, sem sinal de impaciência.
- **FR-010**: Ao concluir uma tarefa ensinada, a assistente MUST atribuir a
  realização **à pessoa**, e não a si mesma.
- **FR-011**: Quando não entender o pedido, a assistente MUST perguntar de volta
  em linguagem comum, **sem** atribuir o erro à pessoa.
- **FR-012**: Quando não souber a resposta, a assistente MUST dizer que não sabe.
  Ela MUST NOT inventar um caminho.
- **FR-013**: A assistente MUST deixar claro que é um programa, sem repetir o
  aviso a ponto de atrapalhar a conversa.
- **FR-052**: Se a resposta não começar a aparecer em **30 segundos**, a espera
  MUST ser encerrada: a Memora MUST dizer, em linguagem comum, que o problema é
  a conexão e não a pessoa, e MUST oferecer tentar de novo sem que a pessoa
  precise reescrever o pedido.
- **FR-053**: Cada conta MUST ter um limite de **20 conversas por dia**. O
  número MUST ser ajustável na configuração do servidor, sem nova versão do
  aplicativo, e MUST ser revisto depois do teste com as 5 pessoas de 65+. Ao
  atingir o limite, a Memora MUST avisar com gentileza, sem atribuir a causa à
  pessoa, e dizer que a conversa volta a ser possível no dia seguinte.

### Requisitos Funcionais — A assistente executa

- **FR-014**: A assistente MUST oferecer executar a ação **somente** quando a
  pessoa declarar dificuldade ou pedir explicitamente. Oferecer antes de ensinar
  é proibido.
- **FR-015**: Antes de executar, a assistente MUST declarar exatamente o que vai
  fazer, em linguagem comum, e MUST aguardar confirmação explícita (Princípio VI).
- **FR-016**: A recusa da oferta MUST encerrar o assunto. A assistente MUST NOT
  insistir nem repetir a oferta na mesma conversa.
- **FR-017**: A assistente MUST executar **apenas** uma ação: **abrir um
  aplicativo** classificado como *cotidiano* (ver FR-040). Ela MUST NOT tocar em
  nada dentro dele. Qualquer outro pedido é recusado.
- **FR-017a**: A lista de aplicativos que podem ser abertos MUST ser fechada e
  definida **fora do modelo de conversa**. Aplicativo que não esteja nela não é
  aberto, mesmo que a pessoa confirme.
- **FR-018**: Ao recusar, a assistente MUST explicar **por que** não faz aquilo,
  sem culpar a pessoa e sem oferecer contorno.
- **FR-019**: Após executar, a assistente MUST mostrar o caminho percorrido, para
  a pessoa reconhecê-lo depois.
- **FR-020**: Toda ação executada MUST gerar registro auditável (Princípio VI).
- **FR-021**: Antes de qualquer ação que leve para fora do Memora, a pessoa MUST
  ser avisada de que está saindo do aplicativo (Princípio II).
- **FR-022**: A validação do que pode ser executado MUST acontecer fora do modelo
  de conversa, de forma determinística. A saída do modelo MUST NOT ser a única
  autorização para agir.

### Requisitos Funcionais — As duas categorias de serviço

> **A regra que governa esta feature inteira**: *quanto mais sensível o serviço,
> menos a Memora toca nele.* É o inverso da conveniência, e é deliberado. Abrir
> o aplicativo do banco pela pessoa treina exatamente o gesto que o golpista
> precisa que ela tenha — o de deixar outra pessoa entrar na conta por ela.

- **FR-040**: Todo serviço conhecido pelo Memora MUST pertencer a uma de duas
  categorias, e a categoria MUST ser definida fora do modelo de conversa:
  - **Serviço sensível** — governo, banco, saúde, previdência, imposto. A Memora
    **só ensina** o caminho.
  - **Aplicativo cotidiano** — redes sociais, vídeo, mensagens, câmera, mapas.
    A Memora pode **abrir**, e nada mais.
- **FR-041**: Para serviço sensível, a Memora MUST NOT abrir o aplicativo nem o
  site, **mesmo que a pessoa peça e confirme**. A recusa é estrutural, não uma
  preferência.
- **FR-042**: Ao recusar abrir um serviço sensível, a Memora MUST explicar o
  motivo em linguagem comum — que é justamente **para proteger a pessoa** — e
  MUST oferecer ensinar o caminho.
- **FR-043**: A porta **Serviços do dia a dia** MUST listar os serviços sensíveis
  que a Memora sabe ensinar, com nome pelo qual a pessoa os conhece.
- **FR-044**: A porta **Meus aplicativos** MUST listar os aplicativos cotidianos
  que a Memora sabe ensinar e abrir.
- **FR-045**: Cada item das duas listas MUST deixar claro, antes do toque, se a
  Memora **ensina** ou **ensina e abre** — a pessoa não deve descobrir a
  diferença só ao chegar lá.
- **FR-046**: Um aplicativo que não está instalado no aparelho MUST ser tratado
  como ensinável, nunca como abrível, e a pessoa MUST ser informada de que ele
  não está no celular.

### Requisitos Funcionais — Histórico da conversa

- **FR-047**: A conversa MUST ser guardada **apenas no aparelho**. O conteúdo
  MUST NOT ser mantido no servidor.
- **FR-048**: Ao sair da conta, a conversa guardada MUST ser apagada do aparelho,
  junto com o restante dos dados pessoais (FR-026 da feature 001).
- **FR-049**: A pessoa MUST conseguir retomar um passo a passo interrompido, ou
  recomeçá-lo, ao reabrir o aplicativo.
- **FR-050**: A pessoa MUST conseguir apagar a conversa quando quiser.
- **FR-054**: Mensagens guardadas há mais de **30 dias** MUST ser apagadas do
  aparelho automaticamente, sem depender de ação da pessoa. Um passo a passo
  interrompido nesse intervalo continua podendo ser retomado (FR-049).

### Requisitos Funcionais — Registro visível

- **FR-023**: A pessoa MUST conseguir ver o que a assistente executou em seu
  nome: o quê e quando, e — nos primeiros 90 dias — a partir de qual pedido
  (FR-055).
- **FR-024**: O registro MUST estar em linguagem comum, legível por quem não é
  técnico.
- **FR-025**: Orientação apenas ensinada MUST NOT aparecer como ação executada.
- **FR-055**: O registro de ações MUST ser guardado por **12 meses** e então
  expurgado — o mesmo prazo da trilha de autenticação da feature 001. O resumo
  do pedido que originou a ação MUST ser apagado antes, aos **90 dias**; o fato
  de a ação ter acontecido, e quando, permanece até o fim dos 12 meses. Depois
  dos 90 dias, o registro visível mostra a ação sem o pedido, e diz isso em
  linguagem comum em vez de deixar um espaço vazio.

### Requisitos de Acessibilidade *(obrigatórios — Princípio III)*

- **FR-026**: Todo elemento interativo MUST ter alvo de toque de no mínimo
  48×48 dp, com 8 dp de separação.
- **FR-027**: Todo texto MUST permanecer legível e o layout utilizável com
  ampliação de até 200%.
- **FR-028**: Toda mensagem da conversa MUST ser alcançável por leitor de tela,
  na ordem em que foi dita.
- **FR-029**: O estado *"a Memora está respondendo"* MUST ser perceptível sem
  depender de animação sutil ou de cor isolada.
- **FR-030**: A conversa MUST NOT depender de gesto que não seja o toque simples
  e a rolagem vertical.

### Requisitos de Segurança *(obrigatórios — Princípios I e II)*

- **FR-031**: A assistente MUST NOT executar ação financeira de qualquer
  natureza — transferência, pagamento, compra ou consulta a conta bancária.
- **FR-032**: A assistente MUST NOT solicitar senha, código de verificação, dado
  bancário ou documento, em nenhuma circunstância.
- **FR-033**: A conversa MUST exibir aviso permanente de que a Memora nunca pede
  senha nem código, no mesmo idioma da tela de recuperação de acesso (FR-023 da
  feature 001).
- **FR-034**: Conteúdo vindo de fora do Memora — mensagens, telas de outros
  aplicativos, textos lidos — MUST ser tratado como dado, nunca como instrução
  para a assistente.
- **FR-035**: A assistente MUST NOT ter permissão administrativa sobre o aparelho
  nem sobre a conta da pessoa (Princípio VI).
- **FR-036**: O registro de ações MUST NOT conter senha, código, token nem
  conteúdo de mensagem privada.
- **FR-051**: O serviço externo que gera as respostas da assistente MUST NOT
  usar o conteúdo das conversas para treinar modelos. Ele MAY retê-lo apenas
  para monitoramento de abuso, por **no máximo 30 dias**, e essas duas
  garantias MUST estar documentadas no contrato ou nos termos publicados do
  serviço **antes** de ele receber a primeira conversa real. Sem isso, a FR-047
  seria cumprida no nosso servidor e desfeita no dele.

### Requisitos Contra Engenharia Social *(obrigatórios — Princípio II)*

- **FR-037**: A assistente MUST NOT executar ação irreversível — apagar dados,
  enviar dinheiro, encerrar conta — mesmo com confirmação.
- **FR-038**: Quando a pessoa pedir algo que a assistente não pode fazer, a
  recusa MUST ser idêntica independentemente de quem pediu ou de como o pedido
  foi formulado.
- **FR-039**: A assistente MUST NOT afirmar ser uma pessoa, um funcionário ou um
  representante de qualquer empresa.

---

### Key Entities

- **Porta do Hub**: um destino do aplicativo. Tem nome em linguagem comum,
  elemento visual e o estado de existir ou não.
- **Conversa**: a sequência de mensagens entre a pessoa e a assistente.
- **Mensagem**: um turno da conversa. Tem autor (pessoa ou assistente),
  conteúdo e momento.
- **Orientação**: um caminho ensinado, composto de passos ordenados. Sabe em
  qual passo a pessoa está.
- **Serviço**: algo que a pessoa quer usar. Tem nome pelo qual ela o conhece e
  pertence a uma **categoria**, que decide o que a Memora pode fazer com ele.
- **Categoria do serviço**: *sensível* (a Memora só ensina) ou *cotidiano* (a
  Memora ensina e pode abrir). Definida fora do modelo de conversa.
- **Ação executável**: abrir um aplicativo cotidiano. É a única, e pertence a
  uma lista fechada definida fora do modelo de conversa.
- **Registro de ação**: o que a assistente executou, quando, a partir de qual
  pedido e com qual confirmação. Não se altera depois de escrito, com uma
  única exceção: o resumo do pedido é apagado aos 90 dias (FR-055). O registro
  inteiro é expurgado aos 12 meses.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 4 de 5 pessoas de 65+ anos, sem instrução prévia, descrevem
  corretamente o que cada porta do Hub abre.
- **SC-002**: 4 de 5 pessoas conseguem voltar ao Hub a partir de qualquer tela,
  na primeira tentativa.
- **SC-003**: Depois de uma tarefa ensinada pela Memora, ao menos 3 de 5 pessoas
  conseguem repeti-la **sozinhas**, sem a assistente. Esta é a medida do
  Princípio VII, e é a mais importante desta feature.
- **SC-004**: Nenhuma pessoa, em nenhum teste, consegue fazer a assistente
  executar ação fora da lista fechada.
- **SC-005**: Em 100% das execuções, a pessoa vê a declaração do que será feito
  **antes** de confirmar.
- **SC-006**: Nenhuma ação executada deixa de aparecer no registro visível.
- **SC-007**: Em ao menos 95% das respostas, as primeiras palavras da
  assistente aparecem em até **5 segundos** depois do envio; enquanto não
  aparecem, o estado de espera é perceptível (FR-029). Nenhuma espera passa de
  **30 segundos** sem que a pessoa receba a explicação da FR-052.
- **SC-008**: Todas as telas desta feature passam nas verificações automatizadas
  de contraste, alvo de toque e ampliação a 200%.
- **SC-009**: Em 100% das tentativas, incluindo pedido explícito e insistência
  repetida, a assistente **recusa** abrir serviço sensível — banco, governo,
  saúde — e oferece ensinar.
- **SC-010**: Nenhum conteúdo de conversa é encontrado no servidor em auditoria,
  e nada resta no aparelho depois de sair da conta.

---

## Assumptions

- **A conversa exige conexão.** Uso offline está fora de escopo, conforme a
  contradição 2 já registrada em
  [requisitos-atualizados.md](../../docs/referencia/requisitos-atualizados.md).
- **A conversa é escrita.** Comandos por voz estão fora de escopo (contradição 1
  do mesmo documento).
- **A tela de Planos fica para depois.** O Arquivo X prevê planos Básico e
  Premium; monetização nunca foi discutida pela equipe, e a decisão desta
  sessão é marcá-la como **Futuro**, fora do escopo desta feature.
- **A pessoa já está autenticada.** Esta feature começa onde a 001 termina.
- **O vocabulário visual já existe.** Os componentes vêm da feature 002; esta
  feature não cria linguagem visual nova.
- **A assistente abre aplicativo, e nada mais.** Ela não toca em nada dentro
  dele: navegar por dentro de outro aplicativo está fora desta entrega.
- **"Serviços Sociais" e "Apps Atuais" foram definidos nesta sessão.** O Arquivo
  X os lista sem descrever. Serviços do dia a dia são os serviços recorrentes do
  Brasil — Gov.br, banco, saúde —, e a Memora **só ensina**. Meus aplicativos
  são os cotidianos e populares — Instagram, YouTube, WhatsApp —, que ela pode
  abrir. Decisão de 2026-08-29.

---

## Threat Model *(obrigatório — Princípio I)*

### Dados sensíveis envolvidos

| Dado | Classificação | Por quê |
|---|---|---|
| Conteúdo das conversas | **Confidencial** | Revela rotina, relações e dificuldades da pessoa |
| Registro de ações executadas | **Interno** | Mostra o que foi feito em nome da pessoa |
| Nome de tratamento | **Interno** | Já existe desde a feature 001 |

### Quem pode acessar

Somente a pessoa dona da conta. A assistente não tem permissão administrativa, e
o acompanhante do modo assistido (US5 da feature 001) **não** ganha acesso à
conversa — o vínculo que a FR-064 daquela feature nega continua negado aqui.

### Ataques previstos e mitigação

| Ataque | Impacto | Mitigação |
|---|---|---|
| Instrução escondida em conteúdo externo faz a assistente agir | Ação não pedida, em nome da pessoa | FR-034 e FR-022: conteúdo externo é dado, e a autorização é determinística, fora do modelo |
| Golpista ao telefone usa a pessoa como intermediária | Ação prejudicial com confirmação legítima | FR-017 e FR-031: lista fechada; nada financeiro, com ou sem confirmação |
| Pedido de senha ou código pela conversa | Tomada de conta | FR-032 e FR-033: a assistente nunca pede, e o aviso é permanente |
| Ação irreversível executada por engano | Perda de dados ou de dinheiro | FR-037: irreversível não entra na lista, nem com confirmação |
| Vazamento do conteúdo da conversa | Exposição da intimidade da pessoa | Classificação Confidencial; FR-036 mantém segredo fora do registro |
| Aparelho perdido, emprestado ou vendido com a pessoa ainda conectada | Meses de conversa expostos a quem pegar o celular | FR-054: nada com mais de 30 dias fica no aparelho |
| A pessoa acredita falar com um humano | Confiança indevida em orientação errada | FR-013 e FR-039 |
| A Memora abre o aplicativo do banco e treina o gesto de deixar outro entrar | Tomada de conta bancária por terceiro | FR-041: recusa estrutural, mesmo com pedido e confirmação |
| Conversa guardada no servidor vira acervo sobre pessoa idosa | Perfil detalhado de alvo preferencial de golpe | FR-047: conteúdo só no aparelho |
| Conta comprometida dispara conversas sem parar | Custo em reais e assistente fora do ar para todas as pessoas | FR-053: limite diário por conta |
| O serviço externo que gera as respostas guarda ou treina com as conversas | O mesmo acervo, fora do nosso controle e sem aparecer no nosso código | FR-051: treino proibido; retenção de no máximo 30 dias, só para abuso, documentada antes da primeira conversa real |

### Monitoramento e registro

Toda ação executada gera registro auditável (FR-020), sem segredo (FR-036),
visível para a própria pessoa (FR-023), e guardado por 12 meses — com o resumo
do pedido, que é Confidencial, apagado aos 90 (FR-055).

---

## Análise de Engenharia Social *(obrigatório — Princípio II)*

| Golpe plausível | Por que funciona com este público | Requisito que mitiga |
|---|---|---|
| *"Sou do suporte do Memora, peça para a assistente abrir seu banco"* | Confiança em autoridade; a pessoa não sabe o que a assistente pode fazer | FR-031, FR-017 |
| *"A Memora vai pedir seu código, pode falar"* | A pessoa já confia na assistente | FR-032, FR-033 |
| Mensagem recebida contendo texto que instrui a assistente | A pessoa não distingue conteúdo de comando | FR-034 |
| *"Pede para ela apagar sua conta, é rápido"* | Pressa e autoridade | FR-037 |
| *"Peça para a Memora abrir seu banco, eu te guio a partir daí"* | A pessoa já confia na assistente para abrir aplicativos | FR-041: banco e governo nunca são abertos, e a recusa não tem exceção |
| A assistente diz *"eu fiz para você"* e a pessoa para de aprender | Comodidade imediata vence o benefício futuro | FR-010, FR-014, FR-019 |

---

## Decisões de Clarificação

Tomadas em 2026-08-29, com o Eduardo, e incorporadas aos requisitos acima.

### D1 — A assistente só abre aplicativo cotidiano

A lista fechada da FR-017 tem **uma** ação: abrir um aplicativo classificado
como cotidiano. Ela não toca em nada dentro dele.

Foi escolhida a lista mínima porque abrir é **reversível** — a pessoa fecha e
nada aconteceu — e não produz efeito no mundo. Navegar dentro de outro
aplicativo exigiria controlá-lo, o que amplia a superfície de ataque sem
resolver o problema que o produto tem hoje. Enviar mensagem e ligar ficaram de
fora por serem irreversíveis, e por serem exatamente o que um golpista pediria.

### D2 — Duas categorias, e a sensível é a que a Memora não toca

O Arquivo X lista "Serviços Sociais" e "Apps Atuais" sem definir nenhum dos
dois. Ficou assim:

| Categoria | O que é | O que a Memora faz |
|---|---|---|
| **Serviços do dia a dia** | Serviços recorrentes do Brasil: Gov.br, banco, saúde, previdência | **Só ensina.** Nunca abre |
| **Meus aplicativos** | Cotidianos e populares: Instagram, YouTube, WhatsApp, câmera | Ensina **e** pode abrir |

O critério é o dado sensível envolvido, e a regra que sai daí é *quanto mais
sensível o serviço, menos a Memora toca nele*. É o inverso da conveniência, e
é o ponto: abrir o banco pela pessoa treina nela o gesto que o golpista precisa
que ela tenha.

### D3 — A conversa fica só no aparelho

Guardar no servidor daria continuidade entre aparelhos e mostraria à equipe o
que as pessoas mais pedem. Também criaria um acervo Confidencial sobre a
intimidade de pessoas idosas — que são o alvo preferencial de golpe no Brasil.

No aparelho, a conversa permite retomar um passo a passo interrompido, e o
cenário V8 da feature 001 já garante que nada sobra depois de sair da conta.

## Dependências

- **Feature 001 — Autenticação Acessível**: a pessoa chega ao Hub autenticada. A
  US4 (sair da conta) ainda está pendente e é onde o Hub ganha a porta de saída.
- **Feature 002 — Design System**: todos os componentes visuais vêm de lá.
- A tela provisória `_TelaDentro`, hoje em `fluxo_autenticacao.dart`, é
  substituída pelo Hub desta feature.
