# Feature Specification: Site Tutorial Acolhedor do Memora para Pessoas Idosas

**Feature Branch**: `feature/012-site-tutorial-idoso`  
**Created**: 2026-11-16  
**Status**: Draft  
**Input**: User description: "Criar um site tutorial e informativo em HTML estático (estilizado, responsivo e independente do aplicativo Android e do servidor), feito para acolher e ensinar pessoas idosas (60+) a conhecer e usar o Memora no dia a dia com tranquilidade, autonomia e segurança, tanto no computador quanto no celular."

## Clarifications

### Session 2026-11-16

- Q: Como a pessoa idosa deve navegar entre os diferentes assuntos do tutorial? → A: Página única contínua com barra/sumário de atalhos diretos no topo (com destaque de capítulo ativo e retorno fácil ao topo).
- Q: Como os passos do tutorial devem mostrar visualmente o que aparece dentro do aplicativo Memora? → A: Ilustrações da assistente Memora acompanhadas de mini-telas estilizadas com botões e rótulos adaptáveis ao zoom e ao contraste do site.
- Q: O site deve oferecer botões visíveis de "Ouvir explicação" ou depender apenas dos leitores de tela nativos? → A: Incluir botão opcional "Ouvir este trecho / Parar leitura" por capítulo, funcionando localmente pelo navegador e ocultado sem erros se indisponível.
- Q: O site tutorial deve manter zero links externos ou incluir algum link externo com aviso prévio? → A: Zero links externos nesta entrega; site 100% contido na própria página com orientação em texto de como encontrar o aplicativo no celular ou pedir ajuda a um familiar.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Conhecer o Memora e aprender sem medo no próprio ritmo (Priority: P1)

Como pessoa idosa (60+) que tem receio de "estragar o celular" ou "apertar o botão errado", quero abrir o site do Memora no celular ou no computador e encontrar uma página acolhedora, calma e visualmente organizada que me explique em português simples por que o Memora existe, qual é o seu lema (*"Eu mostro o caminho e você faz. E não faço nada sem te avisar antes."*) e como ele me ajuda a ter autonomia sem fazer coisas escondidas por mim.

**Why this priority**: A primeira impressão define se a pessoa idosa se sente acolhida ou intimidada. Sem clareza inicial, design sereno e ausência de jargão técnico, o visitante abandona o guia antes de ler os tutoriais.

**Independent Test**: Abrir o site em tela de celular (`320 px` e `390 px`) e computador (`1280 px`), verificar que a abertura comunica imediatamente o propósito do Memora, exibe cartões visuais acolhedores (sem aparência crua), apresenta sumário direto no topo para escolher qualquer assunto sem se perder e não exige cadastro nem login.

**Acceptance Scenarios**:

1. **Given** uma pessoa idosa acessa o site pela primeira vez pelo celular ou computador, **When** a página inicial carrega, **Then** ela vê imediatamente uma saudação acolhedora, a explicação simples do objetivo do Memora, o lema central e um sumário claro com atalhos diretos para cada parte do tutorial.
2. **Given** a pessoa toca ou clica em um item do sumário ou botão de navegação, **When** a página se desloca até a seção escolhida, **Then** o título da seção fica visível sem ser coberto pela barra superior e existe um meio claro de retornar ao início/topo a qualquer momento.
3. **Given** a página está aberta em tela estreita (`320 px`) ou larga (`1440 px`), **When** a pessoa lê e navega de cima a baixo, **Then** nenhum texto ou cartão vaza para fora da largura da tela e os cartões se organizam em coluna única no celular e em grade confortável de leitura no computador.

---

### User Story 2 - Seguir o tutorial passo a passo das funções reais do Memora (Priority: P1)

Como pessoa idosa que está começando a usar o aplicativo Memora (ou decidindo se quer usá-lo), quero consultar guias passo a passo ilustrados com linguagem do dia a dia para cada área do aplicativo — entrada com Frase Secreta e Modo Assistido, navegação em até 3 toques (`Ajustes`, `Início`, `Meu perfil`), conversa educativa e histórico *"O que eu fiz por você"*, abertura avisada de outros aplicativos (WhatsApp, Gov.br, telefone, fotos e saúde), personalização visual e foto de perfil/avatar local, e a pulseira de cuidado com detecção de quedas — para saber exatamente o que esperar em cada tela.

**Why this priority**: É a função principal do site: servir como manual prático e tranquilizador das tarefas reais do usuário, reduzindo dúvidas e chamadas de ajuda a filhos e netos.

**Independent Test**: Percorrer todas as seções do tutorial verificando que cada tarefa do aplicativo está explicada em passos curtos e numerados, sem jargão técnico em inglês, com legendas em português para todos os ícones e exemplos visuais reconhecíveis.

**Acceptance Scenarios**:

1. **Given** a pessoa acessa a seção de primeiros passos, **When** lê sobre acesso à conta, **Then** compreende sem termos técnicos como funciona a entrada com **Frase Secreta**, o apoio opcional de um familiar na configuração inicial e a confirmação calma em duas etapas para sair do aparelho.
2. **Given** a pessoa consulta os guias das funções do aplicativo, **When** explora os blocos de **Barra Inferior (3 toques)**, **Conversar com a Memora e histórico**, **Aplicativos do dia a dia e serviços públicos**, **Ajustes e Foto/Avatar de Perfil local** e **Pulseira de cuidado**, **Then** encontra passos curtos em ordem numérica explicando o que aparece na tela, qual botão tocar e a confirmação recebida.
3. **Given** a pessoa lê sobre a pulseira de cuidado e detecção de quedas, **When** vê o funcionamento do alerta, **Then** entende claramente que existe uma checagem calma de 45 segundos com dois botões grandes — **"Estou bem"** (que silencia sem assustar a família) e **"Preciso de ajuda"** (que prepara o pedido de socorro ao contato de confiança).
4. **Given** qualquer ícone aparece para identificar uma função ou passo, **When** a pessoa observa o cartão ou o leitor de tela lê o elemento, **Then** o ícone está sempre acompanhado de texto explicativo claro em português.

---

### User Story 3 - Ajustar o conforto de leitura e contraste diretamente no site (Priority: P2)

Como pessoa idosa com baixa visão, vista cansada ou sensibilidade ao brilho da tela, quero poder aumentar ou diminuir o tamanho das letras e escolher entre leitura clara, escura ou alto contraste diretamente nos controles visíveis do site, mantendo todas as escolhas preservadas confortavelmente enquanto navego.

**Why this priority**: Acessibilidade real não pode depender de a pessoa saber configurar zoom no navegador ou sistema operacional; controles simples e sempre visíveis garantem leitura autônoma imediata.

**Independent Test**: Acionar os controles de tamanho de texto (Normal, Grande, Muito Grande / equivalente a 200%) e de aparência visual (Claro, Escuro, Alto Contraste) tanto no celular quanto no computador, verificando que nenhuma área quebra, corta texto ou reduz o contraste abaixo dos limites WCAG 2.2 AA/AAA.

**Acceptance Scenarios**:

1. **Given** a pessoa está com dificuldade para ler o texto no tamanho padrão, **When** aciona o controle visível para aumentar a letra (até nível equivalente a `200%`), **Then** todos os textos, títulos, cartões e botões aumentam proporcionalmente sem sobreposição, cortes ou rolagem horizontal.
2. **Given** a pessoa prefere fundo escuro ou contraste máximo, **When** alterna para o modo **Escuro** ou **Alto Contraste**, **Then** todo o site muda imediatamente preservando legibilidade, foco visível de teclado e distinção clara entre blocos, bordas e botões.
3. **Given** um familiar ou usuário navega pelo site usando apenas o teclado ou leitor de tela, **When** percorre os controles, links e cartões interativos, **Then** a ordem de foco é lógica, o contorno de foco é bem visível e há opção direta de pular para o conteúdo principal.

---

### User Story 4 - Aprender a se proteger de golpes e tirar dúvidas tranquilizadoras (Priority: P2)

Como pessoa idosa que ouve falar de golpes pelo celular e tem receio de perder dinheiro ou apagar algo importante, quero ler um quadro bem destacado mostrando o que o Memora **nunca** faz, dicas práticas contra golpes comuns e respostas claras para dúvidas frequentes (como uso sem internet, câmera negada na foto de perfil e quem vê meus dados), para usar o aplicativo com confiança.

**Why this priority**: Pessoas idosas são o público mais visado por engenharia social; educar e estabelecer limites inequívocos de confiança evita que a pessoa caia em fraudes imitando o aplicativo.

**Independent Test**: Verificar a presença de seção destacada de proteção contra golpes ("O que o Memora NUNCA faz"), dicas de ação diante de contatos suspeitos e área expansível ou listada de perguntas frequentes cobrindo privacidade, acesso offline e reversibilidade de erros.

**Acceptance Scenarios**:

1. **Given** a pessoa abre a seção de segurança e proteção contra golpes, **When** lê os destaques, **Then** identifica de imediato que o Memora nunca pede senha de banco, código de SMS, número de cartão ou CPF por mensagem, nunca faz transferências nem age sem aviso explícito.
2. **Given** a pessoa abre a área de dúvidas frequentes, **When** interage com uma pergunta (por toque, clique ou teclado), **Then** a resposta é exibida em linguagem curta, calma e sem culpa, explicando inclusive que recusar câmera ou sair sem confirmar não quebra o aplicativo e que a foto de perfil e conversas privadas respeitam os limites explicados.

---

### User Story 5 - Acessar o site por um familiar/cuidador como apoio (Priority: P3)

Como filho, neto ou cuidador de uma pessoa idosa, quero encontrar uma orientação objetiva sobre o papel de apoio (Modo Assistido e revisão de dúvidas) sem que isso tire o protagonismo da leitura voltada ao usuário idoso.

**Why this priority**: Muitos idosos chegam ao aplicativo apresentados por familiares, que também precisam entender que a conta pertence ao idoso e que o papel do aplicativo é ensinar em vez de substituir.

**Independent Test**: Verificar que existe bloco claro de orientação rápida para familiares/cuidadores sem termos acadêmicos e mantendo o foco principal da página na pessoa idosa.

**Acceptance Scenarios**:

1. **Given** um familiar consulta o site para ajudar alguém da família, **When** lê o bloco dedicado a quem apoia nos primeiros passos, **Then** compreende como configurar junto com a pessoa idosa respeitando a autonomia dela e onde localizar a seção de ajustes e proteção contra golpes.

---

### Edge Cases & Estados

- **Estado Carregando**: Sendo uma página estática leve, o conteúdo principal deve ficar legível imediatamente ao abrir sem telas longas de carregamento ou bloqueios de conteúdo por scripts externos.
- **Estado Vazio**: Como todo o conteúdo educativo é embutido e pré-definido no site, não há estado vazio de banco de dados; caso exista algum filtro ou busca opcional futura, deve mostrar aviso amigável em português oferecendo mostrar todos os assuntos novamente.
- **Estado de Erro**: Caso alguma imagem ilustrativa falhe ao carregar no navegador, o espaço nunca deve quebrar o layout nem ficar apenas um ícone quebrado — deve exibir descrição alternativa clara em português ou cartão textual equivalente.
- **Estado Offline**: Após aberto (ou baixado em pasta local no computador/celular), toda a leitura, navegação interna, controles de letra/contraste e dúvidas frequentes devem funcionar sem depender de conexão ativa à internet nem de serviços externos para exibir o conteúdo principal.
- **Zoom extremo e telas pequenas (`320 px` com ampliação de `200%`)**: Cartões, barra superior, controles de acessibilidade, quadros comparativos e passos numerados não podem cortar texto, sobrepor botões ou exigir rolagem lateral.
- **Navegador com preferência de movimento reduzido**: Caso a pessoa tenha configurado redução de movimento no celular/computador, transições visuais (como rolagem suave ou abertura de respostas) devem ocorrer de forma instantânea e serena, sem animações bruscas ou piscantes.
- **Clique em âncora interna**: Todo atalho do sumário ou botão de retorno ao topo deve levar suavemente (ou instantaneamente quando houver movimento reduzido) até uma seção existente na própria página, sem nunca sair do site para endereços externos.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O site DEVE ser uma experiência web estática, puramente informativa e educativa, totalmente independente do aplicativo móvel e sem comunicação com banco de dados ou servidor de contas.
- **FR-002**: Todo o conteúdo visível DEVE ser redigido em português brasileiro claro, acolhedor, direto e sem jargões técnicos ou termos em inglês (proibindo siglas ou expressões como "IoT", "MQTT", "backend", "tokens", "login" sem tradução ou explicação cotidiana).
- **FR-003**: A página inicial DEVE apresentar design acolhedor e visualmente estruturado (cartões amplos, cantos suaves, tipografia altamente legível, espaçamento generoso, ilustrações da assistente Memora e mini-telas estilizadas adaptáveis ao zoom e ao contraste escolhido para ilustrar exemplos reais de telas), evitando aparência crua ou técnica e identificando claramente os exemplos visuais como ilustrativos (sem simular coleta de dados reais).
- **FR-004**: O layout DEVE ser totalmente responsivo em computadores (de notebooks a monitores largos), tablets e celulares (a partir de `320 px` de largura), adaptando colunas e controles sem gerar rolagem horizontal nem cortes de texto.
- **FR-005**: O site DEVE operar como **página única contínua** com navegação clara no topo, sumário com atalhos diretos que destacam o capítulo ativo conforme a leitura e botão acessível visível para retornar ao topo sem exigir longa rolagem manual.
- **FR-006**: O site DEVE explicar de forma simples o propósito do Memora, o compromisso de ensinar em vez de substituir e o lema *"Eu mostro o caminho e você faz. E não faço nada sem te avisar antes."*
- **FR-007**: O site DEVE conter tutoriais passo a passo ilustrados/visuais para todas as funções centrais do usuário no Memora:
  1. Acesso seguro com **Frase Secreta**, apoio opcional de um familiar (**Modo Assistido**) e saída segura em duas etapas;
  2. Navegação em até **3 toques** pelos três destinos principais (`Ajustes`, `Início` e `Meu perfil`);
  3. Conversa com a assistente (**Conversar com a Memora**) e conferência transparente no histórico (**O que eu fiz por você**);
  4. Abertura assistida de outros aplicativos (como WhatsApp, Gov.br, Telefone, Fotos e Saúde) com tela prévia de aviso;
  5. Personalização em `Ajustes` (tamanho de letra, cores e alto contraste) e gestão da **foto de perfil ou avatar da Memora** guardados somente no aparelho em `Meu perfil`;
  6. Funcionamento da pulseira de cuidado físico (batimentos, detecção de quedas e tela calma de 45 segundos com **"Estou bem"** e **"Preciso de ajuda"**).
- **FR-008**: O site DEVE apresentar seção destacada de proteção contra golpes listando explicitamente o que o Memora **nunca faz** (nunca pede senha bancária, código de verificação SMS, cartão ou CPF por mensagem; nunca realiza pagamentos nem toma ações sem confirmação) e orientações simples de reação a abordagens suspeitas.
- **FR-009**: O site DEVE oferecer seção de Dúvidas Frequentes com respostas curtas, pacientes e sem culpabilização cobrindo ao menos: medo de apagar algo sem querer, funcionamento sem internet, recusa de permissão de câmera na foto de perfil, privacidade de fotos/conversas e como um familiar pode ajudar.
- **FR-010**: O site DEVE disponibilizar controles integrados e sempre compreensíveis para a própria pessoa ajustar o **tamanho da letra** (ao menos padrão, grande e extra grande) e o **modo de leitura visual** (claro, escuro e alto contraste), persistindo a preferência apenas no navegador local se permitido, com fallback limpo caso o armazenamento local do navegador esteja bloqueado.
- **FR-011**: O site NÃO PODE exigir ou conter formulários de cadastro, campos de senha, coleta de telefone, e-mail, CPF ou qualquer dado pessoal do visitante.
- **FR-012**: O site DEVE manter **zero links externos** (100% contido na própria página), orientando em texto claro como abrir o aplicativo Memora no celular ou contar com a ajuda de um familiar quando desejar instalá-lo.
- **FR-013**: Cada capítulo principal do tutorial DEVE oferecer controle acessível opcional para leitura em voz alta em português brasileiro (**"Ouvir este trecho"** / **"Parar leitura"**) executada exclusivamente pela voz local do dispositivo/navegador (sem envio de dados à rede), garantindo que apenas um capítulo fale por vez e que o controle seja ocultado silenciosamente, sem mensagens assustadoras, caso o dispositivo não ofereça síntese de voz.

### Critérios de Acessibilidade (Obrigatórios — Constituição III)

- **AC-001**: Todos os modos visuais (claro, escuro e alto contraste) DEVEM atender no mínimo ao padrão **WCAG 2.2 AA** (`>= 4.5:1` para texto normal e `>= 3:1` para texto grande, bordas e componentes visuais), sendo o modo de Alto Contraste compatível com razão aprimorada (`>= 7.0:1` para texto).
- **AC-002**: Todo elemento interativo (botões do sumário, controles de fonte/contraste, perguntas expansíveis, links, botão de voltar ao topo) DEVE ter área de toque mínima de `48 x 48 px/dp` equivalente e espaçamento mínimo de `8 px` entre alvos adjacentes.
- **AC-003**: Nenhum ícone pode aparecer isolado sem legenda textual clara em português ao lado ou rótulo semântico completo; a cor nunca pode ser o único meio de transmitir aviso, sucesso ou perigo.
- **AC-004**: Todo o conteúdo deve suportar ampliação até **`200%`** sem sobreposição, truncamento ou rolagem horizontal — tanto ao selecionar o nível máximo interno (**`Letra muito grande`**, equivalente a `200%` sobre a base padrão `16 px`, isto é, `>= 32 px` no texto corrido) quanto ao aplicar zoom de `200%` do navegador sobre o nível **`Letra normal`**.
- **AC-005**: A página deve ter estrutura semântica clara por marcos (`cabeçalho`, `navegação`, `conteúdo principal`, `rodapé`), hierarquia sequencial de títulos (título principal único seguido de seções e subseções ordenadas sem saltos de nível), atalho de "Ir direto para o conteúdo" ao navegar por teclado, foco visível de alto contraste e descrições alternativas em todas as imagens e ilustrações.

### Papel e Limites da Assistente (Constituição VI)

- Este site é estritamente educativo e **não executa** inteligência artificial nem toma decisões automáticas no lugar da pessoa. Quando descrever a assistente do aplicativo Memora, o texto DEVE deixar explícito o que ela explica, que ela sempre pede confirmação antes de ações sensíveis e que ela nunca acessa contas bancárias, nunca envia mensagens escondidas e nunca substitui decisões da pessoa idosa.

---

## Segurança e Análise Anti-Engenharia Social *(Constituição I e II)*

### Threat Model

| Aspecto | Análise |
| :--- | :--- |
| **Dados sensíveis envolvidos** | Nenhum dado pessoal, credencial ou registro clínico é coletado ou armazenado pelo site. Apenas preferência local não sensível de tamanho de letra e tema visual no navegador do usuário (quando disponível). |
| **Quem acessa** | Visitantes públicos (pessoas idosas, familiares e avaliadores). |
| **Ameaças possíveis** | 1. Clones ou páginas falsas tentando imitar o visual do Memora para pedir CPF, telefone ou senha em formulários injetados.<br>2. Scripts de terceiros ou fontes externas indisponíveis/comprometidas quebrando a página offline ou rastreando o visitante.<br>3. Redirecionamento silencioso por links enganosos disfarçados de botões de ação.<br>4. Confusão entre o site informativo e o aplicativo real levando alguém a tentar digitar senha bancária ou dados pessoais no navegador. |
| **Impacto potencial** | Perda de confiança do público idoso, exposição a phishing caso links ou formulários enganosos existam, ou impossibilidade de leitura por falha de carregamento. |
| **Mitigação obrigatória** | Ausência total de formulários de captura de dados ou entrada de conta; zero dependências externas obrigatórias em tempo de execução para leitura e estilo; zero links externos (100% autônomo); zero rastreadores de terceiros; quadro permanente educando que o Memora nunca pede dados financeiros ou códigos por mensagem/navegador. |
| **Monitoramento / Verificação** | Inspeção automatizada/revisão garantindo ausência de campos de coleta sensível, ausência de requisições externas ocultas e conformidade de contraste e responsividade. |

### Análise de Engenharia Social — *"Como um golpista exploraria esta tela?"*

- Um golpista poderia enviar um link semelhante ao site dizendo *"Seu Memora precisa atualizar seu cadastro — clique aqui e confirme sua senha ou CPF"*.
- **Proteção embutida no site**: O próprio site deixa visível logo na abertura e na seção de segurança que esta página **só serve para ensinar e ler**, **nunca pede senha, telefone, CPF ou número de cartão** e não permite entrar em nenhuma conta bancária nem do aplicativo por aqui. Qualquer tela ou pessoa pedindo esses dados em nome do Memora é golpe.
- Além disso, nenhum botão do tutorial simula falso envio de pagamento, falso prêmio ou alerta urgente alarmista ("Sua conta será bloqueada hoje").

---

## Key Entities *(não há persistência de contas)*

- **Seção do Tutorial**: Bloco temático independente (ex.: Boas-vindas, Primeiros Passos, Conversa com a Memora, Outros Aplicativos, Ajustes e Foto de Perfil, Pulseira de Cuidado, Proteção contra Golpes, Dúvidas Frequentes) contendo título claro, identificador de âncora, resumo em uma frase e lista ordenada de passos ou cartões explicativos.
- **Preferência de Leitura Local**: Par de escolhas de conforto do visitante (`tamanhoDaLetra`: padrão / grande / extra grande; `modoVisual`: claro / escuro / alto contraste) aplicado imediatamente à visualização da página.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `100%` das seções do tutorial são compreensíveis sem termos técnicos em inglês sem tradução cotidiana, verificável por revisão de texto completo da página.
- **SC-002**: O site renderiza sem rolagem horizontal e sem cortes/sobreposições em todas as larguras principais de teste (`320 px` celular compacto, `390 px` celular padrão, `768 px` tablet e `1280 px+` computador), inclusive com a letra no ajuste máximo (`200%`).
- **SC-003**: `100%` das combinações de texto, títulos, bordas e botões atendem às razões mínimas de contraste WCAG 2.2 (`>= 4.5:1` nos modos Claro e Escuro; `>= 7.0:1` em texto no modo Alto Contraste).
- **SC-004**: `100%` dos elementos interativos possuem área clicável/tocável mínima de `48 x 48 px`, legenda textual visível em português e ordem lógica de navegação completa usando apenas teclado.
- **SC-005**: Uma pessoa idosa ou avaliador consegue localizar qualquer tutorial específico (como "colocar foto de perfil" ou "o que fazer em caso de golpe") em no máximo **2 cliques ou toques** a partir do topo da página, utilizando o sumário direto.
- **SC-006**: O site funciona integralmente após o carregamento inicial ou abertura local sem acesso à internet (`offline`) e registra **zero** links externos, **zero** formulários de login/cadastro e **zero** requisições de coleta de dados pessoais.

---

## Assumptions

- **Estrutura de navegação**: Confirmada como página única contínua com sumário direto, indicação de capítulo ativo e retorno fácil ao topo (ver Clarifications).
- **Autonomia frente ao aplicativo principal**: O site viverá em diretório próprio separado do aplicativo móvel e do servidor, sem alterar contratos ou pipelines existentes do aplicativo principal.
- **Ilustrações e exemplos visuais**: As ilustrações oficiais do projeto Memora serão combinadas com mini-telas estilizadas adaptáveis ao tamanho de letra e ao modo visual (claro/escuro/alto contraste), identificadas claramente como demonstrações visuais para não gerar confusão com telas ativas de conta.
- **Leitura em voz alta**: Confirmado controle opcional **"Ouvir este trecho / Parar leitura"** por capítulo usando apenas capacidade local do aparelho (ocultado graciosamente quando indisponível), em complemento ao suporte integral a leitores de tela nativos (ver Clarifications).
