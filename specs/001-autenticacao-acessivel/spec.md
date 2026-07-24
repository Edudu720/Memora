# Especificação de Funcionalidade: Autenticação Acessível

**Feature Branch**: `feature/001-autenticacao-acessivel`

**Created**: 2026-07-24

**Status**: Draft — aguardando clarificações

**Input**: Cadastro de nova conta e login para usuário idoso, com base nas telas
Primária, Cadastro e Login do protótipo, sob os princípios da
[Constituição](../../.specify/memory/constitution.md).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Criar minha conta e começar a usar (Priority: P1)

Dona Ana, 72 anos, ganhou o Memora indicado pela filha. Ela abre o aplicativo pela
primeira vez, vê uma tela de boas-vindas que explica em poucas palavras o que o
Memora faz, e toca em um único botão para começar. O aplicativo pede o mínimo
possível de informação, um dado por vez, explicando para que serve cada um. Ao
terminar, ela **já está dentro do aplicativo** — não precisa fazer login em seguida.

**Why this priority**: Sem conta não existe produto. E é o momento de maior evasão:
se Dona Ana travar aqui, ela desinstala e não volta. Esta história sozinha já
entrega valor — o usuário sai dela dentro do app.

**Independent Test**: Entregar o app a uma pessoa com 65+ anos que nunca o viu,
sem qualquer instrução, e observar se ela conclui o cadastro sozinha.

**Acceptance Scenarios**:

1. **Given** que abro o aplicativo pela primeira vez, **When** vejo a tela inicial,
   **Then** existe exatamente **uma** ação principal visível e nenhuma decisão a tomar.
2. **Given** que estou no cadastro, **When** informo um dado inválido, **Then** o
   aplicativo explica o que fazer em linguagem comum, sem me culpar e sem apagar o
   que já preenchi.
3. **Given** que concluí o cadastro, **When** a conta é criada, **Then** entro
   direto no aplicativo, sem precisar digitar meus dados novamente.
4. **Given** que estou preenchendo a senha, **When** desejo conferir o que digitei,
   **Then** consigo revelar a senha com um controle claramente rotulado.
5. **Given** que já possuo conta, **When** tento me cadastrar com o mesmo
   identificador, **Then** sou levada ao login sem que o aplicativo revele se aquele
   identificador existe.

---

### User Story 2 - Voltar ao aplicativo depois (Priority: P2)

Dona Ana volta ao Memora no dia seguinte. O aplicativo a reconhece e ela entra
direto. Se o reconhecimento expirar, ela informa apenas seu identificador e sua
senha — nada além disso — e é recebida pelo nome.

**Why this priority**: É o caminho mais percorrido de todo o produto. Um login
difícil transforma cada uso em uma barreira e devolve a pessoa à dependência de
terceiros, contrariando o propósito do Memora.

**Independent Test**: Fechar e reabrir o aplicativo após um cadastro concluído, e
medir quantas ações são necessárias para voltar a usá-lo.

**Acceptance Scenarios**:

1. **Given** que entrei recentemente, **When** reabro o aplicativo, **Then** continuo
   conectada sem digitar nada.
2. **Given** que minha sessão expirou, **When** reabro o aplicativo, **Then** meu
   identificador já vem preenchido e só preciso da senha.
3. **Given** que errei a senha, **When** tento entrar, **Then** recebo uma mensagem
   que **não** informa se o erro foi no identificador ou na senha.
4. **Given** que errei a senha várias vezes seguidas, **When** insisto, **Then** o
   aplicativo me protege temporariamente e me oferece o caminho de recuperação em
   linguagem acolhedora, sem tom de punição.

---

### User Story 3 - Recuperar o acesso quando esqueço a senha (Priority: P3)

Dona Ana não lembra a senha. Ela toca em "Esqueci minha senha", recebe um código
ou link por um canal que ela controla, e define uma senha nova com o Memora
explicando cada passo.

**Why this priority**: Esquecer senha é o evento mais provável neste público. Sem
este caminho, o usuário perde a conta permanentemente — e recorre à família,
justamente o que o produto quer evitar. É também **o maior vetor de golpe do
aplicativo** e por isso exige desenho cuidadoso.

**Independent Test**: A partir de uma conta existente, concluir a troca de senha
sem apoio de nenhum outro fluxo.

**Acceptance Scenarios**:

1. **Given** que solicito recuperação, **When** informo meu identificador, **Then**
   o aplicativo confirma o envio **sem revelar** se aquele identificador existe.
2. **Given** que recebi o código, **When** ele expira, **Then** sou informada com
   clareza e consigo solicitar outro.
3. **Given** que defini uma senha nova, **When** ela é aceita, **Then** todas as
   outras sessões da minha conta são encerradas.
4. **Given** que estou nesta tela, **When** leio as instruções, **Then** o
   aplicativo me avisa explicitamente que **nunca** pedirá minha senha por telefone,
   mensagem ou e-mail.

---

### User Story 4 - Sair da conta com segurança (Priority: P4)

Dona Ana quer sair da conta — por exemplo, ao emprestar o aparelho. Ela encontra a
opção sem procurar, confirma de forma consciente, e o aplicativo garante que nada
dela permanece acessível.

**Why this priority**: Ausente do diagrama de estados original. É requisito de
segurança e de dignidade: sem ele, o usuário não tem controle sobre a própria conta.

**Independent Test**: Sair da conta e verificar que nenhum dado pessoal permanece
visível ou acessível sem nova autenticação.

**Acceptance Scenarios**:

1. **Given** que quero sair, **When** aciono a opção, **Then** o aplicativo pergunta
   se tenho certeza, explicando em linguagem comum o que vai acontecer.
2. **Given** que confirmei a saída, **When** o processo termina, **Then** nenhum
   dado meu permanece acessível no aparelho.

---

### Edge Cases

- **Sem internet durante o cadastro**: o aplicativo informa a falta de conexão,
  preserva o que já foi digitado e permite tentar novamente sem recomeçar.
- **Conexão cai no meio do envio**: nenhuma conta parcial ou duplicada é criada.
- **Usuário fecha o app no meio do cadastro**: ao voltar, retoma de onde parou ou
  recomeça de forma limpa — nunca em estado inconsistente.
- **Tela girada ou fonte aumentada em 200%**: nenhum campo, rótulo ou botão é
  cortado, sobreposto ou perdido.
- **Toque acidental duplo no botão de envio**: apenas uma conta é criada.
- **Senha colada da área de transferência**: aceita normalmente.
- **Usuário digita o identificador com espaços ou letras maiúsculas**: normalizado
  automaticamente, sem erro.
- **Sessão expira durante o uso**: o usuário é avisado com antecedência e não perde
  o que estava fazendo.
- **Muitas tentativas de recuperação seguidas**: protegido, sem revelar existência
  de conta.
- **Aparelho compartilhado com familiar**: sair da conta é sempre possível e
  descoberto sem ajuda.

---

## Requirements *(mandatory)*

### Requisitos Funcionais — Cadastro

- **FR-001**: O sistema MUST solicitar o **menor conjunto possível** de dados para
  criar uma conta. Todo campo adicional exige justificativa registrada nesta spec.
- **FR-002**: O sistema MUST NOT solicitar "nome de usuário" separado do
  identificador de login. *(Resolve a inconsistência do protótipo, onde o cadastro
  pedia e-mail, nome e nome de usuário, mas o login pedia apenas "Usuário".)*
- **FR-003**: O sistema MUST usar o nome informado **exclusivamente** para se
  dirigir à pessoa, nunca como credencial.
- **FR-004**: O sistema MUST explicar, ao lado de cada campo, **para que aquele dado
  serve**, em linguagem comum.
- **FR-005**: O sistema MUST validar cada campo assim que o usuário termina de
  preenchê-lo, e não apenas ao final.
- **FR-006**: O sistema MUST preservar todos os dados já digitados quando ocorrer
  qualquer erro.
- **FR-007**: O sistema MUST permitir revelar a senha digitada, por meio de controle
  com rótulo textual visível.
- **FR-008**: O sistema MUST informar as regras da senha **antes** que o usuário
  comece a digitá-la, e indicar o atendimento de cada regra em tempo real.
- **FR-009**: O sistema MUST autenticar o usuário automaticamente ao concluir o
  cadastro, sem exigir login em seguida.
- **FR-010**: O sistema MUST NOT revelar, em nenhuma mensagem, se um identificador
  já possui conta.

### Requisitos Funcionais — Login

- **FR-011**: Usuários MUST conseguir entrar informando apenas identificador e senha.
- **FR-012**: O sistema MUST preencher previamente o identificador do último acesso
  bem-sucedido neste aparelho.
- **FR-013**: O sistema MUST exibir mensagem de erro **genérica**, que não distinga
  identificador inexistente de senha incorreta.
- **FR-014**: O sistema MUST limitar tentativas consecutivas de login e aplicar
  bloqueio temporário progressivo.
- **FR-015**: A mensagem de bloqueio MUST ser acolhedora, explicar o motivo, informar
  quando será possível tentar de novo e oferecer o caminho de recuperação.
- **FR-016**: O sistema MUST manter o usuário conectado entre usos, sem exigir
  autenticação a cada abertura.
- **FR-017**: O sistema MUST encerrar a sessão automaticamente após período
  prolongado de inatividade, avisando o usuário antes.

### Requisitos Funcionais — Recuperação de Acesso

- **FR-018**: Usuários MUST conseguir recuperar o acesso sem contato humano.
- **FR-019**: O sistema MUST confirmar a solicitação com mensagem idêntica,
  independentemente de a conta existir.
- **FR-020**: O código ou link de recuperação MUST expirar em prazo curto e ser de
  uso único.
- **FR-021**: O sistema MUST encerrar todas as sessões ativas após a troca de senha.
- **FR-022**: O sistema MUST notificar o usuário, pelo canal cadastrado, sempre que a
  senha for alterada.
- **FR-023**: A tela de recuperação MUST exibir aviso permanente de que o Memora
  **nunca** solicita senha por telefone, mensagem ou e-mail.

### Requisitos Funcionais — Encerramento de Sessão

- **FR-024**: Usuários MUST conseguir sair da conta a partir de local previsível e
  alcançável em no máximo dois toques a partir da tela de perfil.
- **FR-025**: O sistema MUST exigir confirmação explícita antes de encerrar a sessão.
- **FR-026**: O sistema MUST remover do aparelho todo dado pessoal e toda credencial
  ao encerrar a sessão.

### Requisitos de Acessibilidade *(obrigatórios — Princípio III)*

- **FR-027**: Todo elemento interativo MUST ter área de toque mínima de 48x48 dp,
  com no mínimo 8 dp de separação entre alvos.
- **FR-028**: Todo texto MUST atender contraste mínimo de 4.5:1 (3:1 para texto
  grande e ícones).
- **FR-029**: A interface MUST permanecer integralmente utilizável com texto
  ampliado até 200%.
- **FR-030**: Todo campo e botão MUST possuir rótulo textual visível — rótulo
  apenas dentro do campo (*placeholder*) é insuficiente.
- **FR-031**: Todo elemento interativo MUST expor rótulo e estado a leitores de tela.
- **FR-032**: Erros MUST ser comunicados por texto e ícone, nunca apenas por cor.
- **FR-033**: Todo processo que demore mais de um instante MUST exibir indicação
  visível de andamento.
- **FR-034**: Nenhuma ação MUST depender de gesto complexo (arrastar, pressionar e
  segurar, deslizar). Toque simples é sempre suficiente.

### Requisitos de Segurança *(obrigatórios — Princípios I e II)*

- **FR-035**: Senhas MUST NOT ser armazenadas de forma reversível.
- **FR-036**: Credenciais MUST NOT ser gravadas em armazenamento comum do aparelho,
  em registros de diagnóstico ou em cópias de tela.
- **FR-037**: Toda comunicação MUST ocorrer por canal criptografado.
- **FR-038**: Toda validação feita na interface MUST ser repetida de forma
  autoritativa no servidor.
- **FR-039**: O sistema MUST registrar, para auditoria, todo evento de autenticação:
  cadastro, entrada, falha, bloqueio, recuperação e saída.
- **FR-040**: Registros de auditoria MUST NOT conter senhas, códigos ou dados
  sensíveis em texto legível.
- **FR-041**: Mensagens de erro MUST NOT expor detalhes internos do sistema.
- **FR-042**: A política de senha MUST priorizar **comprimento** sobre complexidade
  simbólica, e MUST recusar senhas notoriamente comprometidas.

### Requisitos Contra Engenharia Social *(obrigatórios — Princípio II)*

- **FR-043**: O aplicativo MUST NOT solicitar dados não essenciais no cadastro —
  em especial CPF, dados bancários, número de documento ou dados de saúde.
- **FR-044**: O aplicativo MUST avisar de forma explícita, antes de qualquer
  redirecionamento, que o usuário está saindo do Memora.
- **FR-045**: Toda tela de autenticação MUST exibir sinal de identidade consistente
  que ajude o usuário a reconhecer que está no Memora legítimo.
- **FR-046**: O aplicativo MUST NOT enviar mensagens ao usuário contendo links
  clicáveis de autenticação em canais passíveis de imitação, salvo no fluxo de
  recuperação que ele mesmo iniciou.
- **FR-047**: A assistente Memora MUST NOT solicitar, exibir, repetir ou armazenar a
  senha do usuário em nenhuma circunstância.

---

### Key Entities

- **Pessoa Usuária**: quem usa o Memora. Atributos essenciais: identificador de
  acesso, nome de tratamento, segredo de acesso (não reversível), estado da conta,
  momento de criação, momento do último acesso.
- **Sessão**: período em que a pessoa permanece reconhecida no aparelho. Atributos:
  a quem pertence, aparelho associado, momento de início, momento de expiração,
  estado (ativa ou revogada).
- **Solicitação de Recuperação**: pedido de redefinição de acesso. Atributos: a quem
  se refere, momento de criação, prazo de validade, se já foi utilizada.
- **Evento de Autenticação**: registro auditável. Atributos: tipo do evento,
  momento, resultado, origem. **Nunca** contém credenciais.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% das pessoas com 65 anos ou mais concluem o cadastro **sem ajuda de
  terceiros**, em até 4 minutos.
- **SC-002**: 95% das pessoas conseguem retornar ao aplicativo em até 15 segundos a
  partir da abertura.
- **SC-003**: Nenhuma pessoa em teste de usabilidade precisa perguntar o significado
  de um campo do cadastro.
- **SC-004**: 85% das pessoas que esquecem a senha recuperam o acesso sozinhas, na
  primeira tentativa.
- **SC-005**: 100% das telas desta funcionalidade passam em verificação automatizada
  de contraste e área de toque.
- **SC-006**: 100% das telas permanecem integralmente utilizáveis com texto a 200%.
- **SC-007**: Um leitor de tela consegue percorrer e concluir cadastro, login,
  recuperação e saída sem impedimento.
- **SC-008**: Nenhuma mensagem do sistema permite deduzir se um identificador possui
  conta cadastrada.
- **SC-009**: Zero credenciais localizáveis em armazenamento do aparelho ou em
  registros de diagnóstico, verificado por inspeção.
- **SC-010**: A taxa de abandono na tela de cadastro fica abaixo de 25%.

---

## Assumptions

- O aparelho é Android, com conexão de internet disponível na maior parte do tempo.
  Uso totalmente offline está **fora de escopo** desta funcionalidade.
- A pessoa usuária opera o aparelho sozinha no momento do cadastro; cenários de
  cadastro assistido dependem da clarificação **Q3**.
- Cada pessoa possui uma conta individual. Contas compartilhadas ou perfis múltiplos
  estão fora de escopo.
- Autenticação por biometria está **fora de escopo** nesta fase, mas a modelagem não
  deve impedir sua adição futura.
- Verificação obrigatória do identificador **antes** do primeiro acesso está fora de
  escopo: exigi-la bloquearia o usuário logo na entrada, contrariando a User Story 1.
  A verificação é solicitada de forma não bloqueante após o primeiro acesso.
- Os textos da assistente Memora seguem a persona definida na Constituição.
- As telas do protótipo em `docs/design/prototipo/` são referência de intenção, não
  contrato visual. As inconsistências apontadas na análise inicial serão resolvidas
  na fase de plano.

---

## Threat Model *(obrigatório — Princípio I)*

### Dados sensíveis envolvidos

| Dado | Classificação | Observação |
|---|---|---|
| Segredo de acesso (senha) | **Sensível** | Nunca reversível, nunca registrado |
| Identificador de acesso | **Confidencial** | Permite enumeração se mal tratado |
| Nome de tratamento | **Interno** | Baixo impacto isolado |
| Referência de sessão | **Sensível** | Equivale à identidade enquanto válida |
| Código de recuperação | **Sensível** | Concede tomada de conta |

### Quem pode acessar

A própria pessoa usuária. Nenhum outro papel — inclusive a assistente Memora e a
equipe de desenvolvimento — acessa credenciais.

### Ataques previstos e mitigação

| Ameaça | Impacto | Mitigação |
|---|---|---|
| Força bruta na senha | Tomada de conta | FR-014, FR-042 |
| Enumeração de contas | Alvo para golpe direcionado | FR-010, FR-013, FR-019 |
| Roubo de referência de sessão | Acesso completo | FR-036, FR-017, FR-026 |
| Interceptação de rede | Vazamento de credencial | FR-037 |
| Reuso de código de recuperação | Tomada de conta | FR-020 |
| Injeção via campos do formulário | Comprometimento do servidor | FR-038 |
| Credencial em registro de diagnóstico | Vazamento amplo | FR-036, FR-040 |
| Aparelho compartilhado ou perdido | Acesso indevido | FR-024, FR-026 |
| Aplicativo falso imitando o Memora | Roubo de credencial | FR-045 |

### Monitoramento e registro

Todos os eventos de FR-039 são registrados com resultado e origem, sem conteúdo
sensível (FR-040). Picos de falha e de solicitações de recuperação devem ser
observáveis.

---

## Análise de Engenharia Social *(obrigatório — Princípio II)*

> **"Como um golpista tentaria explorar estas telas?"**

| Vetor de golpe | Por que funciona com este público | Contramedida |
|---|---|---|
| Ligar dizendo ser "suporte do Memora" e pedir a senha | Confiança em autoridade; o idoso não sabe que suporte legítimo nunca pede senha | FR-023, FR-047 — aviso permanente e regra absoluta para a assistente |
| Enviar mensagem com link falso de "recuperação de senha" | O link chega em canal familiar e cria urgência | FR-046 — o Memora não envia links fora do fluxo iniciado pelo usuário |
| Aplicativo clonado com tela de login idêntica | O idoso não distingue aplicativo legítimo de cópia | FR-045 — sinal de identidade consistente |
| Familiar ou cuidador cadastra e retém a senha | Dependência disfarçada de ajuda | FR-024 — sair da conta sempre acessível; ver **Q3** |
| Induzir o cadastro de CPF ou dado bancário "para validar" | Formulários longos normalizam pedir dados demais | FR-043 — o app nunca pede esses dados, tornando o pedido um sinal de alerta |
| Pressa e ameaça ("sua conta será excluída") | Medo de perder acesso | Nenhuma mensagem do Memora usa urgência ou ameaça |

---

## Perguntas em Aberto

> A especificação **não avança para o plano** com estas questões abertas.
> Serão resolvidas em `/speckit-clarify`.

### Q1: Qual será o identificador de acesso?

**Contexto**: FR-002 elimina o "nome de usuário", mas resta definir o que a pessoa
digita para entrar. Esta decisão condiciona o cadastro, o login **e** todo o fluxo
de recuperação.

| Opção | Resposta | Implicações |
|---|---|---|
| A | **E-mail** | Recuperação por e-mail, sem custo. Risco: parte do público não tem e-mail, não lembra qual é, ou não sabe acessá-lo — e a recuperação vira beco sem saída |
| B | **Telefone celular** | O idoso costuma saber seu número de cor. Recuperação por SMS. Risco: custo por mensagem e o SMS é canal saturado de golpes, o que tensiona a FR-046 |
| C | **Ambos**, com um obrigatório | Maior flexibilidade e recuperação redundante. Custo: cadastro mais longo, contrariando a FR-001 |

### Q2: Manteremos login social (Google / Facebook)?

**Contexto**: O protótipo exibe ambos. A favor: o usuário não cria nem memoriza
senha — o que remove a causa nº 1 de perda de acesso neste público. Contra:
adiciona uma tela de terceiro que o idoso não sabe validar.

| Opção | Resposta | Implicações |
|---|---|---|
| A | **Apenas Google** | A conta já existe no aparelho Android. Reduz senhas e nenhuma senha é digitada dentro do Memora. Recomendado |
| B | **Google e Facebook** | Fiel ao protótipo. Porém o Facebook é vetor recorrente de golpe com este público e agrega pouco em aparelho Android |
| C | **Nenhum** | Fluxo mais simples e sob controle total. Porém joga 100% do público na memorização de senha |

### Q3: O cadastro assistido por familiar entra no escopo agora?

**Contexto**: Na prática, boa parte dos idosos terá o aplicativo instalado e
configurado por um filho ou neto. Se não desenharmos esse caminho, ele acontecerá
mesmo assim — com o familiar **conhecendo a senha**, o que cria dependência
permanente e mina o propósito do produto.

| Opção | Resposta | Implicações |
|---|---|---|
| A | **Fora de escopo agora** | Mantém a feature enxuta. Aceita-se que o cenário ocorra sem apoio do produto |
| B | **Modo assistido explícito** | O familiar ajuda no preenchimento, mas a senha é definida em etapa privada pelo próprio idoso. Protege a autonomia. Aumenta o escopo |
| C | **Convite por familiar** | O familiar inicia a conta e o idoso a conclui no próprio aparelho. Mais seguro, porém bem mais complexo |

---

## Dependências

- Canal de envio para recuperação de acesso — **depende de Q1**.
- Provedor de identidade externo — **depende de Q2**.
- Design System com tokens de cor, tipografia e espaçamento validados em contraste:
  ainda não existe. Bloqueia a implementação, não a especificação.
