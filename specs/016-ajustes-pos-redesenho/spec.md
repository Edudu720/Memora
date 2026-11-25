# Feature Specification: Ajustes Pós-Redesenho — Issue #106 (@Du3101)

**Feature Branch**: `feature/016-ajustes-pos-redesenho` (diretório `specs/016-ajustes-pos-redesenho`)  
**Created**: 2026-11-19  
**Status**: Draft  
**Input**: User description: "Ajustes pós-redesenho da Issue #106 (@Du3101): corrigir simularQuedaTeste no Dispositivo de Cuidado com ESP32/MQTT e remover menções ao Wokwi; remover os retratos casalIdoso e pessoaComCelular de Meu Perfil com fallback seguro; ligar capturas reais de Meu INSS, TikTok, CNH e demais guias ao app com SVGs dos apps em app/assets/icones_apps/; melhorar e otimizar Meu Perfil; prever botão seguro https para o site tutorial na Ajuda."

---

## Clarifications

### Session 2026-11-19

- **Q1 (`FR-015` — Melhorias e otimização em Meu Perfil / Item 10)**: O que entra concretamente nesta entrega além da reorganização visual e carregamento instantâneo?  
  **A (Opção A)**: Apenas reorganização visual em cartões mais claros, melhorias de legibilidade/hierarquia, otimização sem chamadas de rede na abertura e espaço reservado compatível com o futuro indicador de *"último módulo concluído"* (sem adicionar edição de nome nem novo contador de progresso nesta entrega).
- **Q2 (`FR-008` — Guias passo a passo e catálogo / Item 5)**: O escopo contempla apenas os 7 guias já sanitizados ou também novos serviços no catálogo?  
  **A (Opção A)**: Integrar exclusivamente os **7 guias já com capturas reais sanitizadas** atribuídos a esta frente (**Meu INSS**, **TikTok**, **Carteira Digital de Trânsito / CNH**, **Carteira de Trabalho Digital / CLT**, **Poupatempo**, **YouTube** e **Google Fotos**) junto com seus ícones vetoriais, preservando o catálogo atual sem adicionar novos aplicativos ou serviços externos.
- **Q3 (`FR-018` — Botão seguro do site de tutoriais na Ajuda / Item 11)**: Como tratar o endereço oficial enquanto o deploy externo do site (Item 14 da Issue #106) ainda não tem URL publicada?  
  **A (Opção A)**: Implementar integralmente o botão na tela Ajuda, a restrição estrita a endereço fixo `https://` e o diálogo de confirmação prévia antes da saída do aplicativo, mantendo o botão oculto automaticamente enquanto nenhuma URL oficial `https://` estiver configurada.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Testar o alerta de queda com o dispositivo físico e remover referências ao Wokwi (Priority: P1)

Uma pessoa idosa ou seu familiar acompanhante abre a tela **Dispositivo de Cuidado**, com o modo de dispositivo físico ativo, e toca no botão para testar uma simulação de queda, esperando ver na hora o fluxo real de verificação ("Você está bem?") sem depender do antigo simulador virtual **Wokwi** (que foi aposentado pelo projeto após a adoção do aparelho físico).

**Why this priority**: Um botão visível de simulação de queda que não reage nem explica o motivo quebra a confiança da pessoa usuária e de quem a auxilia ao testar se a proteção contra quedas realmente funciona em um momento real. Além disso, citações residuais ao simulador aposentado confundem quem lê os textos da tela.

**Independent Test**: Pode ser testada isoladamente na tela **Dispositivo de Cuidado**, alternando entre o modo de dispositivo físico e o modo de demonstração local, acionando o teste de queda em ambos os modos, confirmando ou cancelando na verificação de queda e verificando a ausência completa de menções ao Wokwi.

**Acceptance Scenarios**:

1. **Given** a tela Dispositivo de Cuidado está aberta com o modo de dispositivo físico selecionado e conectado, **When** a pessoa toca em *"Simular queda"* para testar o alerta, **Then** o sistema abre imediatamente a tela de verificação de queda com contagem regressiva acessível e opção clara *"Estou bem"*, permitindo validar o comportamento completo sem acionar o antigo simulador virtual.
2. **Given** o fluxo de verificação de queda foi iniciado pelo botão de teste, **When** a pessoa toca em *"Estou bem"* antes do fim da contagem, **Then** o sistema encerra o teste, retorna à tela do Dispositivo de Cuidado e não envia alerta nem mensagem aos contatos de emergência.
3. **Given** a tela Dispositivo de Cuidado está com o modo de dispositivo físico selecionado mesmo sem conexão ativa com o aparelho físico ou com a rede no momento, **When** a pessoa toca no botão de teste de queda, **Then** o sistema inicia localmente o mesmo fluxo completo e cancelável de verificação de queda, nunca permanecendo mudo sem reação.
4. **Given** qualquer tela, diálogo, etiqueta de status ou texto explicativo ligado ao Dispositivo de Cuidado, **When** a pessoa lê ou navega com leitor de tela, **Then** não existe qualquer referência residual ao termo "Wokwi", exibindo apenas termos claros sobre o dispositivo físico de cuidado ou a demonstração local.

---

### User Story 2 - Remover retratos indesejados de Meu Perfil com retorno seguro ao padrão (Priority: P1)

Uma pessoa usuária acessa **Meu Perfil** para escolher ou revisar seu retrato. Os dois retratos descontinuados (*"casal acolhedor"* e *"pessoa com celular"*) não aparecem mais entre as opções, enquanto qualquer conta que tenha salvo um desses dois retratos anteriormente continua abrindo normalmente com o retrato padrão neutro da plataforma.

**Why this priority**: Evita que um ajuste visual quebre contas existentes em dispositivos reais que já persistiram uma preferência antiga, garantindo zero erros e continuidade imediata sem exigir intervenção manual ou perda de outros dados da conta.

**Independent Test**: Pode ser testada isoladamente abrindo **Meu Perfil** em dois cenários: (a) escolhendo retrato em conta nova (verificando que apenas os 4 retratos permitidos + foto própria + iniciais aparecem) e (b) simulando um aparelho cujo armazenamento local guarda uma das chaves antigas removidas.

**Acceptance Scenarios**:

1. **Given** a pessoa abre o seletor de retrato em Meu Perfil, **When** visualiza todas as opções disponíveis, **Then** os dois retratos removidos (*"casal acolhedor"* e *"pessoa com celular"*) não são exibidos, permanecendo apenas os quatro retratos ilustrados da Memora, o padrão neutro com iniciais e a escolha de foto pessoal.
2. **Given** um aparelho já possui salva localmente a preferência por um dos dois retratos descontinuados (ou uma chave antiga desconhecida), **When** a pessoa abre Meu Perfil ou qualquer área que exiba seu retrato, **Then** o sistema exibe automaticamente o retrato padrão neutro sem travamentos, falhas visuais ou perda dos demais dados do perfil.
3. **Given** a conta voltou ao retrato padrão neutro após a remoção, **When** a pessoa decide escolher um novo retrato disponível, **Then** ela consegue selecionar qualquer ilustração restante ou foto própria normalmente e salvar a nova escolha.

---

### User Story 3 - Exibir capturas reais nos guias passo a passo e ícones vetoriais dos aplicativos (Priority: P1)

Uma pessoa idosa que precisa aprender a usar serviços essenciais como **Meu INSS**, **TikTok**, **Carteira Digital de Trânsito (CNH)**, **Carteira de Trabalho Digital (CLT)**, **Poupatempo**, **YouTube** ou **Google Fotos** abre o guia passo a passo dentro do Memora e enxerga telas reais, limpas e fáceis de identificar, com o destaque desenhado pelo próprio Memora apontando o botão certo e ícones nítidos dos aplicativos em todo o catálogo.

**Why this priority**: Capturas genéricas ou provisórias e ícones desenhados à mão dificultam o reconhecimento imediato pela pessoa idosa na hora de reproduzir o passo no aparelho real. Ligar as capturas reais sanitizadas e os ícones vetoriais oficiais resolve a utilidade central dos guias atribuídos a esta frente.

**Independent Test**: Pode ser testada abrindo o catálogo de aplicativos/serviços e percorrendo cada guia atualizado do início ao fim, conferindo imagens reais sem dados pessoais, alinhamento do anel de destaque no controle descrito no texto, integridade do registro de capturas e nitidez dos ícones em escalas maiores.

**Acceptance Scenarios**:

1. **Given** a pessoa escolhe um dos guias atualizados nesta entrega no catálogo do aplicativo, **When** percorre cada passo do tutorial (ou escolhe uma seção em guias divididos por seção), **Then** visualiza capturas reais e limpas daquele serviço no lugar das imagens provisórias anteriores, sem círculos pintados na imagem original e com o destaque desenhado pelo aplicativo sobre o elemento certo.
2. **Given** um passo mostra uma tela de acesso sensível ou formulário de entrada, **When** a pessoa observa e amplia a imagem para ler melhor, **Then** todos os campos de senha aparecem vazios, não há nenhum dado pessoal real (nome, rosto real, telefone, CPF ou e-mail) exposto e o texto da tela continua nítido sem borrões.
3. **Given** a pessoa navega pelas listas, cartões de guias e atalhos de aplicativos do Memora, **When** observa os símbolos dos aplicativos cobertos nesta entrega, **Then** cada aplicativo exibe seu ícone vetorial nítido e reconhecível em qualquer tamanho de tela ou ampliação, em contraste acessível tanto no tema claro quanto no tema escuro.

---

### User Story 4 - Melhorar e otimizar a tela Meu Perfil (Priority: P2)

Uma pessoa idosa abre **Meu Perfil** pelo menu ou pela tela inicial para conferir rapidamente seus dados de acesso, seu retrato, o canal de contato usado no cadastro e seus detalhes opcionais salvos apenas no celular, encontrando organização mais limpa, leitura direta e resposta instantânea sem carregamentos demorados.

**Why this priority**: **Meu Perfil** é o ponto onde a pessoa confere quem está conectado e garante que está no ambiente certo e seguro, além de preparar a estrutura visual para exibir futuramente o último módulo concluído (frente complementar da equipe) sem conflito nem poluição visual.

**Independent Test**: Pode ser testada navegando para **Meu Perfil** offline e online, medindo ausência de chamadas externas na abertura, clareza de agrupamento em cartões, atualização imediata de idade/data local e estabilidade visual em zoom de 200%.

**Acceptance Scenarios**:

1. **Given** a pessoa abre a tela Meu Perfil com ou sem conexão com a internet, **When** a tela é apresentada, **Then** todos os blocos e informações locais aparecem de forma imediata, sem espera de rede e sem disparar tráfego externo apenas por abrir a tela.
2. **Given** a pessoa lê suas informações pessoais em Meu Perfil, **When** percorre os cartões da tela do topo ao rodapé, **Then** a hierarquia visual separa claramente retrato, identidade da conta, informações de aprendizado/uso e preferência local opcional (como data de nascimento), com textos curtos, diretos e fáceis de escanear.
3. **Given** a futura integração do indicador de *"último módulo concluído"* em desenvolvimento paralelo pela equipe, **When** a estrutura de Meu Perfil for exibida com ou sem módulo concluído registrado no aparelho, **Then** o layout se adapta harmonicamente sem quebras nem retrabalho na organização dos cartões.

---

### User Story 5 - Abrir o site oficial de tutoriais pela tela Ajuda com aviso contra golpes (Priority: P2)

Uma pessoa idosa (ou um familiar que a acompanha) acessa a tela **Ajuda** buscando material complementar e encontra, quando o endereço oficial em `https://` estiver habilitado e configurado, um botão claro para visitar o site oficial de tutoriais da Memora, precedido sempre por uma confirmação explícita antes de deixar o aplicativo.

**Why this priority**: O projeto ensina continuamente a pessoa idosa a desconfiar de links desconhecidos; portanto, qualquer saída do aplicativo para o navegador externo precisa dar o exemplo máximo de segurança: destino fixo oficial em `https://`, explicação calma antes de sair e controle total para desistir e permanecer dentro do Memora.

**Independent Test**: Pode ser testada na tela **Ajuda** verificando dois estados: (a) quando há um endereço oficial `https://` configurado (confirmando diálogo de aviso, cancelamento seguro e abertura ou falha tratada do navegador) e (b) quando nenhum endereço válido está configurado (confirmando que o botão permanece oculto sem prometer ação quebrada).

**Acceptance Scenarios**:

1. **Given** um endereço oficial `https://` do site de tutoriais está configurado no aplicativo, **When** a pessoa abre a tela Ajuda e toca no botão para acessar o site oficial, **Then** o aplicativo **não** abre o navegador imediatamente e exibe primeiro um diálogo de confirmação explicando em linguagem simples que ela sairá do Memora para o navegador oficial no site da Memora.
2. **Given** o diálogo de confirmação para sair rumo ao site oficial está aberto, **When** a pessoa toca em cancelar (*"Agora não"*), **Then** o diálogo fecha imediatamente e a pessoa continua na tela Ajuda sem nenhuma abertura de navegador ou troca de tela.
3. **Given** o diálogo de confirmação está aberto, **When** a pessoa confirma que deseja abrir o site (*"Sim, abrir o site"*), **Then** o aplicativo solicita a abertura do endereço oficial fixo em `https://` no navegador do aparelho, ou mostra aviso calmo caso nenhum navegador consiga abrir a página.
4. **Given** o site oficial ainda não teve seu endereço definitivo `https://` configurado para o aplicativo (ou está vazio/inválido), **When** a pessoa abre a tela Ajuda, **Then** nenhum botão quebrado ou inseguro para link externo é exibido na tela.

---

### Edge Cases

- **Toques repetidos durante teste de queda**: Se a pessoa tocar mais de uma vez rapidamente em *"Simular queda"* — com o dispositivo físico conectado ou desconectado —, o sistema inicia apenas uma verificação cancelável por vez, sem abrir múltiplas contagens sobrepostas nem disparar alerta de emergência indevido.
- **Leitura inicial local e troca rápida de conta em Meu Perfil**: Durante a leitura local instantânea ao abrir Meu Perfil (ou em uma troca rápida entre contas no mesmo aparelho), o sistema não pode exibir marcadores provisórios ruidosos nem dados residuais pertencentes à conta anterior.
- **Identificador de retrato legado corrompido ou desconhecido**: Se o armazenamento local contiver qualquer valor fora da lista atual (incluindo os dois retratos removidos ou texto vazio/inválido), o sistema não pode falhar ao exibir o retrato nem bloquear a navegação, retornando ao retrato padrão neutro imediatamente.
- **Limite de peso total dos recursos embarcados vs. 66 capturas reais**: O conjunto prévio de guias já somava quase todo o antigo limite de 8 MB antes da troca de dezenas de telas provisórias pelas capturas reais; para preservar textos legíveis ao ampliar sem modificar ativos de outros colaboradores, o orçamento total das capturas embarcadas foi revisado para 12 MB.
- **Capturas de telas com senha ou dados pessoais**: Qualquer captura trazida de diretórios de preparo que contenha imagem real de pessoa, número real, nome real ou senha preenchida deve ser substituída ou higienizada antes de entrar no aplicativo; nenhuma captura pode conter marcações pintadas sobre a imagem junto ao destaque dinâmico.
- **Aparelho sem navegador compatível ou offline ao confirmar abertura do site**: Se a pessoa confirmar ir ao site na Ajuda em um aparelho restrito/sem navegador para links `https://`, o aplicativo captura a falha de abertura e exibe uma mensagem acolhedora sem fechar nem travar.
- **Ampliação de texto em até 200%, movimento reduzido e alto contraste**: Em todas as telas alteradas (Dispositivo de Cuidado, Meu Perfil, Catálogo/Guias e Ajuda), textos longos, botões de ação e cartões devem quebrar linha sem corte nem sobreposição e sem animações abruptas quando o aparelho preferir movimento reduzido.

---

## Análise de Ameaças e Engenharia Social *(Constituição — Princípios I e II)*

Para cada ponto tocado por esta especificação, avaliou-se *"Como um golpista tentaria explorar esta tela?"* e definiram-se contramedidas obrigatórias:

1. **Tela Ajuda — Acesso ao site oficial de tutoriais (Phishing e falsificação de links)**:
   - *Vetor de risco*: Golpistas enviam links parecidos por mensagens falsas se passando pelo suporte da Memora, ou induzem a pessoa a confiar cegamente ao tocar qualquer botão que leve à web. Além disso, links dinâmicos não validados ou sem `https://` poderiam sofrer interceptação ou redirecionamento.
   - *Mitigações obrigatórias*: (a) Endereço estritamente fixo no código em protocolo `https://`, sem parâmetros vindos de texto externo, rede não confiável ou entrada do usuário; (b) Proibição total de abrir navegador no primeiro toque — confirmação modal obrigatória avisando que a pessoa está saindo do Memora; (c) Botão ocultado automaticamente se nenhum endereço oficial válido `https://` estiver definido.
2. **Dispositivo de Cuidado — Simulação de queda (Pânico e disparo acidental de SOS)**:
   - *Vetor de risco*: Teste que dispara alerta real silenciosamente assusta familiares/contatos de emergência; inversamente, botão mudo cria falsa sensação de segurança em quem testa para conferir o funcionamento antes de precisar dele de verdade.
   - *Mitigações obrigatórias*: Separação explícita entre estado de teste cancelável (*"Estou bem"*) e envio real; ensaio local imediato e cancelável mesmo quando o aparelho físico estiver desconectado; remoção de nomes técnicos obscuros ou do antigo simulador Wokwi que confundem a pessoa quanto ao dispositivo real monitorado.
3. **Guias Passo a Passo — Capturas reais de serviços públicos e redes sociais (Vazamento de PII e confusão com tela real)**:
   - *Vetor de risco*: Captura com CPF, nome, número de telefone ou foto real expõe privacidade ou facilita engenharia social; tela de senha preenchida induz maus hábitos; imagem confundida com o aplicativo real frustra a tentativa de toque.
   - *Mitigações obrigatórias*: Higienização integral de dados pessoais, campos de senha sempre vazios, destaque desenhado pelo próprio aplicativo com selo visual claro diferenciando tela de exemplo educativa do aplicativo real em uso.
4. **Meu Perfil — Dados locais da conta (Exposição de dados e coleta silenciosa)**:
   - *Vetor de risco*: Telas de perfil que disparam consultas desnecessárias ou guardam dados pessoais sensíveis fora do controle da pessoa elevam superfície de exposição.
   - *Mitigações obrigatórias*: Abertura estritamente local sem chamadas de rede; limpeza de preferências pessoais locais ao sair da conta mantida intacta; retorno seguro ao retrato padrão sem expor erro técnico nem identificadores internos.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Dispositivo de Cuidado e Retirada do Wokwi (Itens 7 e 8)
- **FR-001**: O sistema MUST permitir acionar o teste de simulação de queda na tela do Dispositivo de Cuidado tanto no modo de demonstração local quanto no modo conectado ao dispositivo físico de cuidado.
- **FR-002**: Ao acionar o teste de simulação de queda com o modo de dispositivo físico ativo (conectado ou desconectado), o sistema MUST iniciar localmente o fluxo completo e cancelável de verificação de queda (contagem regressiva acessível com opção clara informando estar bem), sem falhas silenciosas e sem exigir ida e volta na rede externa para o ensaio.
- **FR-003**: Ao cancelar a verificação de queda iniciada pelo teste tocando na confirmação de bem-estar, o sistema MUST retornar normalmente ao painel do Dispositivo de Cuidado sem disparar alerta nem notificação externa de emergência.
- **FR-004**: O sistema MUST eliminar todas as menções textuais e explicativas residuais ao antigo simulador Wokwi ligadas ao Dispositivo de Cuidado no aplicativo, substituindo qualquer referência necessária pela identificação clara do dispositivo físico de cuidado ou da demonstração local.

#### Retratos de Meu Perfil e Fallback Seguro (Item 9)
- **FR-005**: O sistema MUST remover os dois retratos ilustrados descontinuados (*"casal acolhedor"* e *"pessoa com celular"*) das opções exibidas ao escolher retrato em Meu Perfil, preservando as demais ilustrações da Memora, a foto pessoal e o padrão neutro por iniciais.
- **FR-006**: Ao carregar uma conta cujo armazenamento local contenha um identificador de retrato descontinuado ou desconhecido, o sistema MUST aplicar automaticamente o retrato padrão neutro em todos os pontos onde o retrato é exibido, sem erros, mensagens técnicas nem perda dos demais dados do perfil.
- **FR-007**: Uma pessoa cujo perfil tenha voltado automaticamente ao retrato padrão neutro MUST conseguir selecionar e salvar qualquer outro retrato válido normalmente.

#### Guias Passo a Passo, Capturas Reais e Ícones dos Aplicativos (Itens 5 e 6)
- **FR-008**: O catálogo educativo e os guias passo a passo MUST substituir integralmente as imagens provisórias pelas capturas reais sanitizadas exclusivamente nos **7 guias atribuídos a esta entrega** (**Meu INSS**, **TikTok**, **Carteira Digital de Trânsito / CNH**, **Carteira de Trabalho Digital / CLT**, **Poupatempo**, **YouTube** e **Google Fotos**), preservando inalterada a lista atual de serviços do catálogo conectado e de demonstração.
- **FR-009**: Cada captura real exibida nos 7 guias atualizados nesta entrega MUST estar livre de dados pessoais reais (nomes, fotos identificáveis, documentos, telefones ou e-mails), apresentar eventuais campos de senha sempre vazios, não conter marcações pintadas diretamente na imagem e receber o destaque visual posicionado sobre o controle exato indicado pelo texto do passo.
- **FR-010**: Guias com fluxos longos ou múltiplas tarefas distintas MUST organizar seus passos em seções temáticas claras quando necessário para manter cada jornada curta, navegável e compreensível pela pessoa idosa.
- **FR-011**: Todos os 7 guias atualizados nesta entrega MUST ter seu histórico de captura devidamente registrado (identificador do guia, data, versão do aplicativo e aparelho de referência) e manter o tamanho total das imagens embarcadas dentro do limite acordado para o aplicativo, preservando legibilidade de textos ao ampliar.
- **FR-012**: Cada um dos 7 aplicativos correspondentes aos guias cobertos por esta entrega MUST exibir um ícone vetorial nítido e fiel à identidade reconhecível do serviço em cartões, catálogo e visualizações do aplicativo, substituindo desenhos manuais imprecisos sem depender de formatos pixelados.
- **FR-013**: Para os aplicativos do catálogo já habilitados para abertura direta ou verificação de instalação entre os guias atualizados nesta entrega (como **YouTube**, **TikTok** e **Google Fotos**), o sistema MUST preservar o reconhecimento autorizado pelo aparelho, a orientação segura para a loja oficial quando ausente e a paridade exata entre o catálogo conectado e a demonstração offline, sem adicionar novos aplicativos externos ao catálogo.

#### Melhoria e Otimização de Meu Perfil (Item 10)
- **FR-014**: A abertura da tela Meu Perfil MUST utilizar exclusivamente os dados de sessão e armazenamento local já disponíveis, garantindo resposta imediata e zero requisições de rede ao abrir a tela.
- **FR-015**: A tela Meu Perfil MUST ser reorganizada visualmente em cartões mais claros e otimizada em hierarquia, legibilidade, espaçamento e fluidez de abertura usando apenas os dados locais existentes, reservando área estrutural harmoniosa para a exibição futura do *"último módulo concluído"*, sem adicionar edição direta de nome nem novos contadores de progresso nesta entrega.
- **FR-016**: Todas as melhorias em Meu Perfil MUST manter o armazenamento estritamente local para informações opcionais sensíveis (como data de nascimento), garantir sua limpeza ao encerrar a conta e preservar total compatibilidade com a exibição do último módulo de aprendizado concluído desenvolvida em paralelo pela equipe.

#### Acesso Seguro ao Site Oficial de Tutoriais na Ajuda (Item 11)
- **FR-017**: A tela Ajuda MUST prever botão dedicado para acesso ao site oficial de tutoriais da Memora apontando exclusivamente para endereço fixo em protocolo seguro `https://`, bloqueando qualquer URL dinâmica, editável ou fora desse padrão.
- **FR-018**: Quando um endereço oficial `https://` definitivo estiver configurado para o site de tutoriais (padrão oficial publicado em produção: `https://memora-site-thf2.onrender.com/`, com possibilidade de sobrescrita ou ocultação por variável de build `MEMORA_URL_SITE_TUTORIAL`), o botão MUST aparecer normalmente na tela Ajuda; se explicitamente configurado como vazio ou inválido, o botão MUST permanecer oculto automaticamente sem exibir placeholder, link quebrado ou aviso de recurso indisponível.
- **FR-019**: Sempre que o botão do site oficial estiver visível e for acionado na tela Ajuda, o sistema MUST exibir antes um diálogo modal de confirmação clara explicando que a pessoa está saindo do Memora rumo ao navegador externo no site oficial da Memora e exibindo visivelmente o endereço oficial de destino, com botão de confirmação (*"Sim, abrir o site"*) e botão de recusa (*"Agora não"*).
- **FR-020**: Ao cancelar o diálogo, a pessoa MUST permanecer exatamente na tela Ajuda sem saída do aplicativo; ao confirmar, caso o aparelho falhe em abrir o navegador externo, o sistema MUST informar o ocorrido com calma em linguagem simples sem travar o aplicativo.

#### Padrões Transversais de Linguagem e Segurança
- **FR-021**: Todos os textos adicionados ou revisados nas telas modificadas MUST usar português brasileiro simples e neutro em gênero, limitar blocos informativos a no máximo duas frases curtas, não conter emojis no texto de interface e manter o botão persistente de emergência acessível conforme a tela.

---

### Requisitos de Acessibilidade e Experiência *(Constituição — Princípio III)*

- **AC-001**: Todos os botões, seletores de retrato, cartões tocáveis e ações de confirmação devem possuir área mínima de toque de `48×48 dp` (e pelo menos `56 dp` de altura em botões de ação primária e cartões principais), com espaçamento mínimo de `8 dp` entre controles adjacentes.
- **AC-002**: Todo texto normal e texto de rótulo deve atingir razão mínima de contraste de `4,5:1` (visando `7:1` quando possível nos textos principais), e ícones vetoriais e elementos gráficos informativos devem atingir contraste mínimo de `3:1` em relação ao fundo nos temas claro, escuro e alto contraste.
- **AC-003**: Todas as telas afetadas (Dispositivo de Cuidado, Meu Perfil, Guias/Catálogo e Ajuda) devem suportar escala de fonte do sistema de até `200%` sem truncamento indesejado, corte vertical/horizontal ou sobreposição de elementos.
- **AC-004**: Elementos interativos, cabeçalhos das seções de Meu Perfil, ícones de aplicativos, indicadores de estado do dispositivo e controles de simulação/confirmação devem fornecer descrições e papéis claros para leitores de tela, anunciando alterações de estado relevantes (incluindo erro amigável ao tentar abrir o site oficial na Ajuda, estado de carregamento/erro ou alteração de retrato).
- **AC-005**: Nenhuma funcionalidade nova ou revisada pode depender exclusivamente da cor para comunicar estado (como conectado/desconectado no dispositivo de cuidado ou conclusão/alerta).
- **AC-006**: Transições e feedbacks visuais relacionados às telas alteradas devem respeitar a preferência do sistema por redução de movimento.

---

### Key Entities *(include if feature involves data)*

- **Teste de Verificação de Queda**: Ação sob demanda na área de cuidado que dispara o fluxo temporizado de confirmação de bem-estar independentemente do modo de monitoramento ativo, sem persistir evento de emergência quando cancelado.
- **Retrato de Perfil**: Identificador de aparência visual associado localmente à conta (retrato ilustrado ativo, retrato padrão neutro por iniciais ou imagem escolhida pela pessoa), com regra de substituição transparente para identificadores aposentados ou inválidos.
- **Guia Passo a Passo e Captura Sanitizada**: Unidade educativa estruturada por passos (e seções quando necessário) composta por imagem real da interface sem dados pessoais ou marcações desenhadas, região relativa de destaque controlada pelo sistema, descrição para leitor de tela e registro de auditoria de versão e aparelho.
- **Ícone Vetorial do Aplicativo**: Representação gráfica escalável oficial associada à chave única de cada serviço no catálogo, utilizada com legibilidade e contraste em cartões e listas.
- **Perfil Local da Pessoa**: Visão resumida da conta autenticada e de preferências pessoais armazenadas exclusivamente no aparelho (retrato selecionado, canal de acesso, aplicativo mais estudado e data de nascimento opcional), pronta para acomodar indicadores locais de aprendizado concluído.
- **Link Oficial do Site Tutorial**: Referência única, imutável e estrita em protocolo `https://` ao site oficial de tutoriais da Memora, vinculada a confirmação explícita de saída antes do redirecionamento ao navegador.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% dos acionamentos do botão de simulação de queda com o modo de dispositivo físico selecionado (tanto em verificação controlada quanto no aparelho real, conectado ou desconectado), o fluxo cancelável de verificação de queda é iniciado localmente em menos de 1 segundo, resultando em **zero falhas silenciosas**.
- **SC-002**: 0 ocorrências residuais do termo "Wokwi" permanecem nos textos de interface, estados de dispositivo e descrições funcionais ligadas ao Dispositivo de Cuidado dentro do aplicativo.
- **SC-003**: 100% das contas que carregarem qualquer identificador de retrato descontinuado ou desconhecido exibem o retrato padrão neutro sem erros na tela **Meu Perfil**, enquanto o seletor de retratos exibe exatamente os 4 retratos ilustrados válidos (além de iniciais e foto própria).
- **SC-004**: 100% dos 7 guias incluídos nesta entrega (**Meu INSS**, **TikTok**, **CNH / Carteira Digital**, **Carteira de Trabalho**, **Poupatempo**, **YouTube** e **Google Fotos**) exibem capturas reais sanitizadas (0 imagens provisórias genéricas restantes), 0 exposições de dados pessoais, 0 marcações pintadas junto ao destaque dinâmico, 100% de registros atualizados no controle de capturas e 7 ícones vetoriais nítidos para os respectivos aplicativos.
- **SC-005**: A tela **Meu Perfil** realiza exatamente 0 chamadas de rede durante sua abertura e mantém leitura fluida sem quebras visuais ou estouros de layout com escala de texto em 100% e 200%.
- **SC-006**: 100% das tentativas de abrir o site oficial a partir da tela **Ajuda** (quando habilitado) exigem confirmação explícita antes de deixar o aplicativo, com taxa de **0% de aberturas diretas ao primeiro toque** e **0% de links aceitos fora do protocolo fixo `https://`**.
- **SC-007**: 100% dos controles interativos e textos nas telas modificadas cumprem contraste mínimo (4,5:1 para texto e 3:1 para elementos gráficos), alvos de toque mínimos (48×48 dp, e 56 dp em ações principais) e legibilidade integral sem cortes nem sobreposição até 200% de ampliação de texto.
- **SC-008**: 100% dos fluxos modificados e dos guias integrados mantêm conformidade plena com prevenção de regressões (incluindo detecção da falha anterior de simulação de queda), paridade entre catálogo conectado e demonstração offline, e linguagem clara livre de termos técnicos ou emojis para a pessoa idosa.

---

## Assumptions

- **Aposentadoria oficial do Wokwi**: Conforme decisão registrada do projeto na Issue #106, o uso de simulador Wokwi foi encerrado em definitivo devido à disponibilidade do dispositivo físico; apenas o modo físico conectado e o modo de demonstração local permanecem suportados.
- **Fronteira de responsabilidade com os demais colaboradores**:
  - Os ícones vetoriais dos aplicativos **e-Título**, **FGTS** e **Instagram**, bem como a lógica de progresso/sinalização de *"último módulo concluído"* em Meu Perfil e a publicação em produção do site de tutoriais estão atribuídos a outro integrante da equipe na Issue #106 e serão integrados por convenção compatível de identificadores e símbolos visuais dos aplicativos.
  - A revisão de marcações e capturas de guias específicos de outro colaborador (como WhatsApp, Facebook, Telegram, Gov.br, Serasa e Correios), a chave do mapa do Localizador, a troca autenticada de senha e a eventual função de análise de links suspeitos permanecem fora desta especificação por pertencerem a outro responsável na Issue #106.
- **Orçamento de tamanho das capturas embarcadas**: Como o conjunto prévio de guias já se aproxima de 8 MB, o limite acordado para o total de imagens embarcadas dos guias passa de 8 MB para 12 MB para acomodar as 66 capturas reais com alta legibilidade sem recomprimir nem alterar capturas mantidas por outros colaboradores.
- **Preservação da arquitetura existente**: O mecanismo de encerramento de sessão limpa os dados locais sensíveis conforme especificado anteriormente e o botão de emergência (SOS) permanece inalterado em funcionamento.
