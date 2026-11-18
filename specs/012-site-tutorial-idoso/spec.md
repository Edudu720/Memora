# Feature Specification: Site Tutorial Acolhedor do Memora para Pessoas Idosas

**Feature Branch**: `feature/012-site-tutorial-idoso`  
**Created**: 2026-11-16  
**Status**: Draft  
**Nota terminológica (`FR-002` / `memora-ux`)**: O nome histórico da pasta (`012-site-tutorial-idoso`) e menções internas a *"pessoa(s) idosa(s)"* nas histórias originais da Rodada 1 descrevem apenas contexto de especificação. Em **todo texto visível do site e no `<title>`**, vigora integralmente a proibição da `FR-002` (zero `"idoso"`, `"idosa"`, `"terceira idade"`, `"melhor idade"` ou `"sênior"`).  
**Input**: User description: "Criar um site tutorial e informativo em HTML estático (estilizado, responsivo e independente do aplicativo Android e do servidor), feito para acolher e ensinar pessoas idosas (60+) a conhecer e usar o Memora no dia a dia com tranquilidade, autonomia e segurança, tanto no computador quanto no celular."

## Clarifications

### Session 2026-11-16

- Q: Como a pessoa idosa deve navegar entre os diferentes assuntos do tutorial? → A: Página única contínua com barra/sumário de atalhos diretos no topo (com destaque de capítulo ativo e retorno fácil ao topo).
- Q: Como os passos do tutorial devem mostrar visualmente o que aparece dentro do aplicativo Memora? → A: Ilustrações da assistente Memora acompanhadas de mini-telas estilizadas com botões e rótulos adaptáveis ao zoom e ao contraste do site.
- Q: O site deve oferecer botões visíveis de "Ouvir explicação" ou depender apenas dos leitores de tela nativos? → A: Incluir botão opcional "Ouvir este trecho / Parar leitura" por capítulo, funcionando localmente pelo navegador e ocultado sem erros se indisponível.
- Q: O site tutorial deve manter zero links externos ou incluir algum link externo com aviso prévio? → A: Zero links externos nesta entrega; site 100% contido na própria página com orientação em texto de como encontrar o aplicativo no celular ou pedir ajuda a um familiar.
- Q: Como o site deve lidar com bibliotecas JavaScript de animação e Web Components para entregar a Memora animada sem violar o modelo de segurança nem o desempenho em aparelhos simples? → A: JavaScript sem framework com Web Components e Web Animations nativos como padrão, permitindo biblioteca enxuta copiada para dentro de `site/` (versão fixa, zero CDN ou rede externa) apenas se necessário e dentro do orçamento aproximado de 100 KB de JavaScript.
- Q: Como a Memora animada (`<memora-personagem>`) deve sincronizar a boca durante a leitura em voz alta ("Ouvir este trecho") nos navegadores em que a síntese de voz não dispara eventos de fronteira de palavra? → A: Usar os eventos `onboundary` da síntese de voz quando emitidos e cair para um ritmo calmo contínuo entre `onstart` e `onend` quando ausentes, mantendo a boca estática com "Reduzir movimento" ativo.
- Q: Como o controle visível "Reduzir movimento" no painel de conforto deve interagir com a preferência do sistema (`prefers-reduced-motion`) e com o armazenamento local do navegador? → A: Se não houver escolha salva no navegador, inicia ligado quando `prefers-reduced-motion: reduce` estiver ativo no sistema; ao alternar manualmente no painel, a escolha da pessoa prevalece e é salva localmente (com fallback limpo sem `localStorage`).
- Q: Quais regras da `memora-ux` devem passar a ser exigidas e validadas automaticamente no texto visível do site e no título da aba? → A: Aplicar integralmente a `memora-ux`: blocos visíveis com no máximo duas frases curtas, zero emojis na interface e zero ocorrência de "idoso", "pessoa(s) idosa(s)", "terceira idade", "melhor idade" ou "sênior" (inclusive no `<title>`), tudo validado pelo `validar_site.py`.
- Q: Como os recursos modernos de CSS (`light-dark()`, consultas de contêiner, View Transitions entre capítulos e animações ligadas à rolagem) devem conviver com o modo **Alto Contraste** e com navegadores mais antigos em celulares simples? → A: Melhoria progressiva protegida por `@supports` com fallback clássico para os modos Claro e Escuro, mantendo o modo Alto Contraste (`>= 7,0:1`) em regras explícitas independentes e desligando View Transitions e animações de rolagem sempre que "Reduzir movimento" estiver ativo.

### Session 2026-11-17

- Q: Como o painel da Memora anfitriã deve acompanhar o scroll fora dos capítulos em telas grandes e em telas pequenas (`320 px` ou letra a `200%`) sem cobrir o texto nem colidir com o botão de voltar ao topo? → A: Painel acompanhante global fora das `<section>`, ancorado no canto inferior esquerdo (lado oposto ao `↑ Topo`), expandido por padrão em telas largas (`>= 64rem` fora de `200%`) com botão acessível de recolher/expandir (`>= 48×48 px`), e iniciado recolhido em telas compactas ou `200%` como cápsula com o `<memora-personagem>` animado visível e botão para abrir/fechar o balão de dicas.
- Q: Como a expressão facial e a sincronia da boca da Memora anfitriã flutuante devem responder ao scroll pelos capítulos e à leitura em voz alta ("Ouvir este trecho")? → A: A anfitriã acompanhante global sincroniza a boca com `"Ouvir este trecho"` em todos os 9 capítulos (inclusive visível na cápsula compacta) e adapta sua expressão ao capítulo ativo na leitura/scroll.
- Q: Como devem ficar a abertura do Capítulo 1 (`#boas-vindas`) e os `<memora-personagem>` ilustrativos nos cartões dos capítulos 6, 8 e 9 depois que a anfitriã passar a acompanhar a página inteira fora dos capítulos? → A: O Capítulo 1 usa layout limpo focado no texto introdutório e no lema (sem painel duplicado da anfitriã), enquanto o selo `mini` no cabeçalho e os `<memora-personagem>` dos capítulos 6, 8 e 9 permanecem decorativos dentro dos cartões.

### Session 2026-11-18 (Revisão PR #93)

- Q: Como devem ser corrigidos os termos e orientações de acesso/senha e Modo Assistido após a revisão da PR #93? → A: Substituir "Frase Secreta" e "Mostrar frase" pelos rótulos reais do app ("senha", "Sua senha" e "Mostrar senha"); explicar que no Modo Assistido o acompanhante **para na hora da senha**, devolve o celular e deixa a pessoa criar a senha sozinha, sem olhar; remover exemplos copiáveis ("cafe com bolo da tarde") e o conselho fraco ("lembrança de família"), orientando a criar "uma frase que só você sabe e que ninguém adivinharia"; corrigir saída de conta para "uma confirmação calma".
- Q: Como impedir que elementos flutuantes (`anfitriã` e `↑ Topo`) cubram botões do sumário ou textos em celulares (`320×568` e `390×844`) ou escala `200%`? → A: Restringir a flutuação fixa em faixa dedicada ao desktop largo (`>= 64rem` fora de `200%`); abaixo de `64rem` ou em `200%`, embutir a anfitriã no fluxo normal da página e ocultar `.atalho-topo-fixo` (mantendo o botão de retorno ao topo no rodapé), garantindo zero interceptação de toque via `elementFromPoint`.
- Q: O que fazer com SVGs não utilizados em `site/assets/ilustracoes/` (`porta_ajuda.svg`)? → A: Remover `porta_ajuda.svg` órfão e validar em `validar_site.py` que todo arquivo em `site/assets/ilustracoes/` esteja referenciado em `site/index.html`.

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

Como pessoa idosa que está começando a usar o aplicativo Memora (ou decidindo se quer usá-lo), quero consultar guias passo a passo ilustrados com linguagem do dia a dia para cada área do aplicativo — entrada com senha e Modo Assistido, navegação em até 3 toques (`Ajustes`, `Início`, `Meu perfil`), conversa educativa e histórico *"O que eu fiz por você"*, abertura avisada de outros aplicativos (WhatsApp, Gov.br, telefone, fotos e saúde), personalização visual e foto de perfil/avatar local, e a pulseira de cuidado com detecção de quedas — para saber exatamente o que esperar em cada tela.

**Why this priority**: É a função principal do site: servir como manual prático e tranquilizador das tarefas reais do usuário, reduzindo dúvidas e chamadas de ajuda a filhos e netos.

**Independent Test**: Percorrer todas as seções do tutorial verificando que cada tarefa do aplicativo está explicada em passos curtos e numerados, sem jargão técnico em inglês, com legendas em português para todos os ícones e exemplos visuais reconhecíveis.

**Acceptance Scenarios**:

1. **Given** a pessoa acessa a seção de primeiros passos, **When** lê sobre acesso à conta, **Then** compreende sem termos técnicos como funciona a entrada com **senha** (com botão **"Mostrar senha"** e orientação para usar *"uma frase que só você sabe e que ninguém adivinharia"*, sem exemplos copiáveis nem lembranças de família), o **Modo Assistido** (no qual o familiar devolve o aparelho na hora da senha e não olha a digitação) e a confirmação calma em uma etapa para sair do aparelho.
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

1. **Given** um familiar consulta o site para ajudar alguém da família, **When** lê o bloco dedicado a quem apoia nos primeiros passos, **Then** compreende como configurar respeitando a autonomia da pessoa — parando na hora da senha e devolvendo o celular para ela criar a senha sozinha, sem ninguém olhar — e onde localizar a seção de ajustes e proteção contra golpes.

---

### Edge Cases & Estados

- **Estado Carregando**: Sendo uma página estática leve, o conteúdo principal deve ficar legível imediatamente ao abrir sem telas longas de carregamento ou bloqueios de conteúdo por scripts externos.
- **Estado Vazio**: Como todo o conteúdo educativo é embutido e pré-definido no site, não há estado vazio de banco de dados; caso exista algum filtro ou busca opcional futura, deve mostrar aviso amigável em português oferecendo mostrar todos os assuntos novamente.
- **Estado de Erro**: Caso alguma imagem ilustrativa falhe ao carregar no navegador, o espaço nunca deve quebrar o layout nem ficar apenas um ícone quebrado — deve exibir descrição alternativa clara em português ou cartão textual equivalente.
- **Estado Offline**: Após aberto (ou baixado em pasta local no computador/celular), toda a leitura, navegação interna, controles de letra/contraste e dúvidas frequentes devem funcionar sem depender de conexão ativa à internet nem de serviços externos para exibir o conteúdo principal.
- **Zoom extremo e telas pequenas (`320 px` e `390 px`, inclusive com ampliação de `200%`)**: Cartões, barra superior, controles de acessibilidade, painel da anfitriã embutido no fluxo da página (sem sobrepor links ou botões via posicionamento fixo em `< 64rem` ou `200%`), quadros comparativos e passos numerados não podem cortar texto, interceptar botões tocáveis (`elementFromPoint`) ou exigir rolagem lateral.
- **Navegador ou controle com movimento reduzido**: Caso a pessoa tenha configurado `prefers-reduced-motion: reduce` no aparelho ou ativado **"Reduzir movimento"** no painel de conforto, animações da Memora (inclusive na cápsula recolhida), troca automática de dicas e transições visuais devem cessar de imediato ou ocorrer de forma instantânea, sem perda de conteúdo nem remoção das dicas acessíveis pelo botão manual.
- **Clique em âncora interna**: Todo atalho do sumário ou botão de retorno ao topo deve levar suavemente (ou instantaneamente quando houver movimento reduzido) até uma seção existente na própria página, sem nunca sair do site para endereços externos.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O site DEVE ser uma experiência web estática, puramente informativa e educativa, totalmente independente do aplicativo móvel e sem comunicação com banco de dados ou servidor de contas.
- **FR-002**: Todo o conteúdo visível e o título da aba (`<title>`) DEVEM seguir a `memora-ux`: redação em português brasileiro claro, na voz acolhedora da Memora, sem jargões técnicos ou termos em inglês sem tradução cotidiana, blocos de leitura com no máximo **duas frases curtas**, zero emojis na interface e ausência total de termos proibidos (`idoso`, `idosa`, `idosos`, `idosas`, `terceira idade`, `melhor idade`, `sênior`) ou frases que sugiram incapacidade — tudo verificado automaticamente pelo portão de texto do `validar_site.py`.
- **FR-003**: A página inicial DEVE apresentar design acolhedor e visualmente estruturado (cartões amplos, cantos suaves, tipografia altamente legível, espaçamento generoso, abertura limpa no Capítulo 1 focada na apresentação e no lema, personagem vetorial 2.5D animada da Memora em `<memora-personagem>` nos cartões ilustrativos dos capítulos e no cabeçalho com selo `mini`, além da acompanhante global posicionada fora dos capítulos sem jamais cobrir textos ou alvos tocáveis, e mini-telas estilizadas adaptáveis ao zoom e ao contraste escolhido para ilustrar exemplos reais de telas), evitando aparência crua ou técnica, marcando o personagem como decorativo para leitores de tela (`aria-hidden`) e identificando claramente os exemplos visuais como ilustrativos (sem simular coleta de dados reais).
- **FR-004**: O layout DEVE ser totalmente responsivo em computadores (de notebooks a monitores largos), tablets e celulares (a partir de `320 px` de largura), adaptando colunas e controles sem gerar rolagem horizontal nem cortes de texto.
- **FR-005**: O site DEVE operar como **página única contínua** com navegação clara no topo, sumário com atalhos diretos que destacam o capítulo ativo conforme a leitura e botão acessível visível para retornar ao topo sem exigir longa rolagem manual.
- **FR-006**: O site DEVE explicar de forma simples o propósito do Memora, o compromisso de ensinar em vez de substituir e o lema *"Eu mostro o caminho e você faz. E não faço nada sem te avisar antes."*
- **FR-007**: O site DEVE conter tutoriais passo a passo ilustrados/visuais para todas as funções centrais do usuário no Memora:
  1. Acesso seguro com **senha** usando os mesmos rótulos do aplicativo (**"Sua senha"** e **"Mostrar senha"**), com orientação de segurança sem exemplos copiáveis nem lembranças de família (*"uma frase que só você sabe e que ninguém adivinharia"*), **Modo Assistido** deixando explícito que o familiar para na etapa da senha e devolve o celular sem olhar, e saída segura em **uma confirmação calma**;
  2. Navegação em até **3 toques** pelos três destinos principais (`Ajustes`, `Início` e `Meu perfil`);
  3. Conversa com a assistente (**Conversar com a Memora**) e conferência transparente no histórico (**O que eu fiz por você**);
  4. Abertura assistida de outros aplicativos (como WhatsApp, Gov.br, Telefone, Fotos e Saúde) com tela prévia de aviso;
  5. Personalização em `Ajustes` (tamanho de letra, cores e alto contraste) e gestão da **foto de perfil ou avatar da Memora** guardados somente no aparelho em `Meu perfil`;
  6. Funcionamento da pulseira de cuidado físico (batimentos, detecção de quedas e tela calma de 45 segundos com **"Estou bem"** e **"Preciso de ajuda"**).
- **FR-008**: O site DEVE apresentar seção destacada de proteção contra golpes listando explicitamente o que o Memora **nunca faz** (nunca pede senha bancária, código de verificação SMS, cartão ou CPF por mensagem; nunca realiza pagamentos nem toma ações sem confirmação) e orientações simples de reação a abordagens suspeitas.
- **FR-009**: O site DEVE oferecer seção de Dúvidas Frequentes com respostas curtas, pacientes e sem culpabilização cobrindo ao menos: medo de apagar algo sem querer, funcionamento sem internet, recusa de permissão de câmera na foto de perfil, privacidade de fotos/conversas e como um familiar pode ajudar.
- **FR-010**: O site DEVE disponibilizar controles integrados e sempre compreensíveis para a própria pessoa ajustar o **tamanho da letra** (ao menos padrão, grande e extra grande), o **modo de leitura visual** (claro, escuro e alto contraste) e a opção **"Reduzir movimento"** (iniciando ativa se não houver escolha salva quando `prefers-reduced-motion: reduce` estiver ligado no sistema, prevalecendo sempre a alternância manual do usuário), persistindo todas as preferências apenas no navegador local se permitido, com fallback limpo caso o armazenamento local do navegador esteja bloqueado.
- **FR-011**: O site NÃO PODE exigir ou conter formulários de cadastro, campos de senha, coleta de telefone, e-mail, CPF ou qualquer dado pessoal do visitante.
- **FR-012**: O site DEVE manter **zero links externos** (100% contido na própria página), orientando em texto claro como abrir o aplicativo Memora no celular ou contar com a ajuda de um familiar quando desejar instalá-lo.
- **FR-013**: Cada capítulo principal do tutorial DEVE oferecer controle acessível opcional para leitura em voz alta em português brasileiro (**"Ouvir este trecho"** / **"Parar leitura"**) executada exclusivamente pela voz local do dispositivo/navegador (sem envio de dados à rede), garantindo que apenas um capítulo fale por vez, sincronizando a boca da Memora acompanhante global em todos os 9 capítulos pelos eventos `onboundary` (com fallback calmo contínuo entre `onstart` e `onend` quando o navegador não emitir fronteiras de palavra, visível também na cápsula recolhida e desativado em "Reduzir movimento") e ocultando o controle silenciosamente, sem mensagens assustadoras, caso o dispositivo não ofereça síntese de voz.
- **FR-014**: Os componentes interativos e animações do site DEVEM usar JavaScript sem framework (Web Components + Web Animations nativos por padrão), podendo usar biblioteca enxuta **copiada para dentro de `site/`** com versão fixa (nunca via CDN ou requisição externa) apenas quando necessário para sequências complexas, respeitando orçamento máximo aproximado de `100 KB` de JavaScript e animando preferencialmente posição, escala e transparência (parando animações quando o componente sai da tela).
- **FR-015**: Toda aparição da Memora no site DEVE ser gerada a partir da exportação oficial dos mesmos pintores, paletas e lista fixa de dicas do aplicativo (nunca imagem antiga nem segunda versão redesenhada à parte). A anfitriã atua fora dos capítulos em `<aside>`: em telas largas de desktop (`>= 64rem` fora de escala `200%`), acompanha a rolagem em faixa lateral dedicada à esquerda (oposta ao botão fixo de retorno ao topo) sem sobrepor o conteúdo; em telas menores (`< 64rem`) ou escala `200%`, integra-se no fluxo normal da página sem flutuar sobre textos nem sobre botões do sumário ou leitura, mantendo visível o `<memora-personagem>` animado (cuja expressão acompanha o capítulo ativo na rolagem/leitura e cuja boca sincroniza com `"Ouvir este trecho"`), o balão com a lista fixa e os botões acessíveis **"Outra dica da Memora"** e **"Recolher dicas" / "Ver dicas"** (`>= 48×48 px`), alternando dicas a cada `20 s` apenas com o painel expandido, sem leitor de tela, sem "Reduzir movimento" e antes de interação manual.
- **FR-016**: Recursos modernos de CSS e navegação (`light-dark()`, consultas de contêiner, `text-wrap: pretty`, View Transitions entre capítulos e animações ligadas à rolagem) DEVEM entrar apenas como melhoria progressiva protegida por `@supports` e com fallback clássico funcional em navegadores antigos, preservando regras explícitas para o modo Alto Contraste (`>= 7,0:1`) e desligando qualquer transição/animação quando **"Reduzir movimento"** estiver ativo.

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
| **Mitigação obrigatória** | Ausência total de formulários de captura de dados ou entrada de conta; zero dependências carregadas via CDN ou rede externa em tempo de execução (qualquer biblioteca enxuta necessária vive copiada localmente em `site/` com versão fixa); zero links externos (100% autônomo); zero rastreadores de terceiros; quadro permanente educando que o Memora nunca pede dados financeiros ou códigos por mensagem/navegador. |
| **Monitoramento / Verificação** | Inspeção automatizada/revisão garantindo ausência de campos de coleta sensível, ausência de requisições externas ocultas e conformidade de contraste e responsividade. |

### Análise de Engenharia Social — *"Como um golpista exploraria esta tela?"*

- Um golpista poderia enviar um link semelhante ao site dizendo *"Seu Memora precisa atualizar seu cadastro — clique aqui e confirme sua senha ou CPF"*.
- **Proteção embutida no site**: O próprio site deixa visível logo na abertura e na seção de segurança que esta página **só serve para ensinar e ler**, **nunca pede senha, telefone, CPF ou número de cartão** e não permite entrar em nenhuma conta bancária nem do aplicativo por aqui. Qualquer tela ou pessoa pedindo esses dados em nome do Memora é golpe.
- Além disso, nenhum botão do tutorial simula falso envio de pagamento, falso prêmio ou alerta urgente alarmista ("Sua conta será bloqueada hoje").

---

## Key Entities *(não há persistência de contas)*

- **Seção do Tutorial**: Bloco temático independente (ex.: Boas-vindas, Primeiros Passos, Conversa com a Memora, Outros Aplicativos, Ajustes e Foto de Perfil, Pulseira de Cuidado, Proteção contra Golpes, Dúvidas Frequentes) contendo título claro, identificador de âncora, resumo em uma frase e lista ordenada de passos ou cartões explicativos.
- **Preferência de Leitura Local**: Conjunto de escolhas de conforto do visitante (`tamanhoDaLetra`: padrão / grande / extra grande; `modoVisual`: claro / escuro / alto contraste; `reduzirMovimento`: ligado / desligado) aplicado imediatamente à visualização da página.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `100%` das seções e título do site passam no portão automatizado do `validar_site.py` com zero blocos acima de duas frases curtas, zero termos em inglês técnico sem tradução cotidiana, zero emojis na interface e zero ocorrências dos termos proibidos pela `memora-ux`.
- **SC-002**: O site renderiza sem rolagem horizontal e sem cortes/sobreposições em todas as larguras principais de teste (`320 px` celular compacto, `390 px` celular padrão, `768 px` tablet e `1280 px+` computador), inclusive com a letra no ajuste máximo (`200%`).
- **SC-003**: `100%` das combinações de texto, títulos, bordas e botões atendem às razões mínimas de contraste WCAG 2.2 (`>= 4.5:1` nos modos Claro e Escuro; `>= 7.0:1` em texto no modo Alto Contraste).
- **SC-004**: `100%` dos elementos interativos possuem área clicável/tocável mínima de `48 x 48 px`, legenda textual visível em português e ordem lógica de navegação completa usando apenas teclado.
- **SC-005**: Uma pessoa idosa ou avaliador consegue localizar qualquer tutorial específico (como "colocar foto de perfil" ou "o que fazer em caso de golpe") em no máximo **2 cliques ou toques** a partir do topo da página, utilizando o sumário direto.
- **SC-006**: O site funciona integralmente após o carregamento inicial ou abertura local sem acesso à internet (`offline`) e registra **zero** links externos, **zero** formulários de login/cadastro e **zero** requisições de coleta de dados pessoais.

---

## Assumptions

- **Estrutura de navegação**: Confirmada como página única contínua com sumário direto, indicação de capítulo ativo e retorno fácil ao topo (ver Clarifications).
- **Autonomia frente ao aplicativo principal**: O runtime de `site/` permanece 100% autônomo (sem servidor, sem banco, sem alterar os jobs existentes de `app/` e `backend/` no CI). O exportador CLI em `app/tool/` roda em tempo de desenvolvimento/build para gerar estaticamente os ativos da Memora e dicas dentro de `site/` (incluindo bundle JS local compatível com abertura via `file://` sem `fetch`), e o CI ganha um job paralelo dedicado `site`.
- **Ilustrações e exemplos visuais**: As aparições da Memora serão geradas exclusivamente por exportação vetorial da `MemoraAnimada` do aplicativo em `<memora-personagem>` (substituindo integralmente as 7 imagens antigas da Memora). Os ícones das portas e das pessoas usam SVGs vetoriais locais da mesma família **Material Rounded** do aplicativo (`porta_*.svg`, `casal_idoso.svg`, `pessoa_com_celular.svg`, `ajuste_aparencia.svg`), acompanhados de mini-telas estilizadas adaptáveis ao tamanho de letra e ao modo visual (`claro`, `escuro`, `alto-contraste`), identificadas claramente como demonstrações visuais para não gerar confusão com telas ativas de conta.
- **Leitura em voz alta**: Confirmado controle opcional **"Ouvir este trecho / Parar leitura"** por capítulo usando apenas capacidade local do aparelho (ocultado graciosamente quando indisponível), em complemento ao suporte integral a leitores de tela nativos (ver Clarifications).
