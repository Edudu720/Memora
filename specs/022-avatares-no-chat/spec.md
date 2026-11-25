# Feature Specification: Avatares da Memora e da Pessoa Usuária no Chat

**Feature Branch**: `feature/022-avatares-no-chat`  
**Created**: 2026-11-22  
**Status**: Draft  
**Input**: User description: "Vamos fazer um fix no Design do app. A parte do chat deveria estar como na primeira imagem, a que tem os icones de Memora e da foto de perfil do usuario, mas ela esta como na segunda, só com o texto escrito 'você' e 'Memora'. Lembrando que a foto de usuario no chat deve ser a mesma que ele selecionou para o perfil, prepare tudo para fazermos esse fix utilizando os comandos do speckit"

---

## Contexto e Alinhamento Visual *(Constituição — Princípio IV e memora-ux)*

Na versão atual da conversa com a assistente, apenas os rótulos escritos (`"Memora"` e `"Você"`) identificam os balões de diálogo, divergindo da referência visual da ajuda guiada (*Passo 2 de 5*), na qual cada fala da assistente traz o rosto da Memora à esquerda e cada fala da pessoa traz o retrato dela à direita.

Esta especificação registra também a revisão formal da regra visual anterior (`FR-042` / `FR-025` da entrega `013-redesenho-final`): a Memora pequena no cabeçalho da conversa permanece como a **única figura animada que reage e "fala"** durante a resposta, enquanto o rosto da Memora ao lado de cada balão de fala atua exclusivamente como **marcador visual estático de autoria** (sem animação nem reação ao toque), em paridade simétrica com o retrato circular da pessoa usuária do lado direito.

---

## Análise de Ameaças e Engenharia Social *(Constituição — Princípios I e II)*

Para responder *"Como um golpista tentaria explorar esta tela?"* ao adicionar retratos nos balões do chat:

1. **Vazamento ou exposição indevida da foto pessoal (`Princípio I — Privacidade Local`)**:
   - *Vetor de risco*: A foto própria selecionada em Meu Perfil poderia acidentalmente ser incluída em requisições enviadas ao servidor/provedor externo de IA junto com o histórico do chat, ou permanecer visível após troca de conta ou limpeza completa no aparelho.
   - *Mitigações obrigatórias*: O retrato exibido nos balões do chat provém **exclusivamente** do armazenamento local do aparelho vinculado à conta atualmente autenticada. Nenhuma imagem, metadado ou preferência de retrato é transmitida pela rede ou incluída em mensagens enviadas à assistente; ao encerrar a sessão com *"Esquecer este aparelho"* ou alternar para outra conta, o chat não exibe em hipótese alguma o retrato da conta anterior.

2. **Confusão de identidade nos balões quando a pessoa escolhe um avatar ilustrado da Memora (`Princípio II — Clareza Literal`)**:
   - *Vetor de risco*: Pessoas que preferem não usar foto real podem escolher um dos quatro avatares ilustrados da Memora em Meu Perfil; no chat, ver a Memora dos dois lados sem distinção clara poderia gerar dúvida sobre quem enviou qual mensagem ou distrair de avisos de segurança.
   - *Mitigações obrigatórias*: Cada fala preserva simultaneamente três sinais claros além da cor: **posição** (Memora sempre à esquerda; pessoa sempre à direita), **moldura visual** (rosto mini da Memora sem moldura circular à esquerda; retrato dentro do contorno circular de perfil à direita) e **rótulo textual explícito** (`"Memora"` e `"Você"`). Os avisos permanentes antigolpe e de privacidade continuam visíveis e inalterados no topo da conversa.

3. **Interferência visual ou sobrecarga de leitores de tela (`Princípio III — Acessibilidade`)**:
   - *Vetor de risco*: Rostos interativos próximos a botões ou anúncios falados de `"imagem da Memora"` / `"sua foto de perfil"` antes de cada balão prejudicariam a fluidez da conversa por TalkBack e ampliariam risco de estouro visual a 200%.
   - *Mitigações obrigatórias*: Os avatares laterais nos balões são estritamente decorativos (sem ação ao toque e ignorados pelo leitor de tela, pois o balão já anuncia `"Memora disse: …"` e `"Você disse: …"`) e recuam automaticamente em ampliações elevadas de texto (`>= 175%`) para proteger a legibilidade da conversa inteira.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identificação Visual nos Balões de Conversa (Priority: P1) 🎯 MVP

Ao conversar com a Memora na tela de conversa, a pessoa usuária deseja reconhecer imediatamente quem disse cada mensagem por meio dos ícones ao lado de cada balão — exatamente como apresentado na tela demonstrativa de exemplo (*Passo 2 de 5*) — com o rosto da Memora à esquerda das respostas dela e o retrato de usuário à direita das próprias perguntas.

**Why this priority**: É o núcleo visual do ajuste solicitado pelo usuário ("como na primeira imagem... os ícones de Memora e da foto de perfil do usuário"), corrigindo a aparência atual composta apenas pelos textos `"Você"` e `"Memora"`.

**Independent Test**: Pode ser testada isoladamente abrindo a tela de conversa (vazia com convite, com histórico salvo, durante o envio de uma pergunta, enquanto a Memora escreve e após receber a resposta) e verificando que cada balão exibe o ícone lateral correspondente ao seu autor, no lado correto, mantendo posição, canto pontudo e rótulo escrito.

**Acceptance Scenarios**:

1. **Given** que a pessoa abre a conversa sem histórico após aceitar o aviso, **When** o balão de convite da Memora aparece, **Then** o rosto mini da Memora é exibido à esquerda do balão, acompanhado do rótulo `"Memora"`.
2. **Given** que a pessoa envia uma pergunta e recebe resposta na conversa, **When** os balões de histórico ou de nova troca são exibidos (em escala de texto padrão), **Then** todo balão da pessoa traz o retrato circular à direita e todo balão da assistente (inclusive em andamento/`escrevendo…` e concluído) traz o rosto mini da Memora à esquerda.
3. **Given** que a Memora está escrevendo ou respondendo, **When** múltiplos balões aparecem na lista com o rosto mini estático à esquerda, **Then** apenas a Memora do cabeçalho superior realiza movimento de fala, mantendo zero concorrência visual de múltiplas animações na tela.

---

### User Story 2 - Sincronização Fiel com o Retrato Selecionado em Meu Perfil (Priority: P1)

A pessoa usuária espera que o ícone exibido ao lado dos seus próprios balões (`"Você"`) na conversa seja sempre o mesmo retrato selecionado por ela na tela **Meu Perfil** — seja uma foto própria escolhida da câmera ou galeria, um dos avatares ilustrados da Memora, ou o retrato padrão neutro com suas iniciais/silhueta — atualizando-se automaticamente caso ela altere ou remova a escolha no perfil.

**Why this priority**: Garante que a identidade pessoal configurada pela pessoa em Meu Perfil tenha consistência real em todo o aplicativo, conforme explicitamente exigido ("a foto de usuário no chat deve ser a mesma que ele selecionou para o perfil").

**Independent Test**: Pode ser testada alterando o retrato local de uma conta entre foto própria, avatar ilustrado e remoção (padrão neutro) e abrindo ou retornando a uma conversa ativa já montada na outra aba, verificando que o retrato exibido à direita dos balões `"Você"` reflete imediatamente cada escolha, sem misturar retratos de contas diferentes.

**Acceptance Scenarios**:

1. **Given** uma conta autenticada sem foto própria nem avatar selecionado, **When** a pessoa envia uma mensagem no chat, **Then** o retrato à direita do balão `"Você"` exibe o padrão neutro da conta (círculo de perfil com iniciais derivadas do nome de tratamento ou silhueta humana neutra quando não houver letras).
2. **Given** uma conta com foto própria sanitizada salva no aparelho em Meu Perfil, **When** a conversa é aberta ou novas mensagens são carregadas, **Then** o retrato à direita de cada balão `"Você"` exibe exatamente a foto própria recortada em círculo.
3. **Given** uma conta com um avatar ilustrado da Memora escolhido em Meu Perfil, **When** a conversa exibe balões `"Você"`, **Then** o lado direito mostra a ilustração correspondente em repouso dentro da moldura circular de retrato, visualmente distinta do ícone livre da assistente à esquerda.
4. **Given** que a conversa já está aberta na aba Início e a pessoa muda, substitui ou remove sua foto na aba Meu Perfil, **When** ela retorna à aba da conversa, **Then** todos os seus balões exibem imediatamente o retrato atualizado sem precisar reabrir o aplicativo nem recarregar mensagens da rede.
5. **Given** duas contas distintas usadas no mesmo aparelho (ou limpeza total do aparelho ao sair), **When** ocorre troca de conta, **Then** o chat exibe apenas o retrato da nova conta (ou padrão neutro), nunca reutilizando imagem em cache da conta anterior.

---

### User Story 3 - Acessibilidade, Ampliação até 200%, Movimento Reduzido e Desempenho (Priority: P2)

Pessoas com baixa visão, leitor de tela ativo, preferência por redução de movimento ou smartphones Android de entrada precisam que a presença dos avatares no chat não introduza estouros de layout, perda de contraste, anúncios repetitivos no TalkBack nem travamentos durante a digitação ou rolagem.

**Why this priority**: Assegura conformidade integral com o Princípio III da Constituição e a skill `memora-ux` em todos os temas, paletas e tamanhos de tela suportados.

**Independent Test**: Pode ser testada executando inspeção semântica e verificando os balões na matriz de telas (de `320×568` a `412×915`), nas escalas `100%`, `150%` e `200%`, nos três temas (claro, escuro e alto contraste) e com redução de movimento ligada.

**Acceptance Scenarios**:

1. **Given** o aplicativo configurado nos temas claro, escuro ou alto contraste (em qualquer paleta), **When** o chat exibe avatares de usuário e Memora nos balões, **Then** bordas, fundos neutros, iniciais e ícones mantêm contraste mínimo exigido (WCAG 2.2 AA/AAA) sem usar cor como único sinal.
2. **Given** que o leitor de tela está ativo, **When** o foco de leitura passa por um balão de conversa, **Then** os avatares laterais são ignorados como elementos decorativos e apenas a fala completa com sua autoria (`"Memora disse: ..."` ou `"Você disse: ..."`) é anunciada.
3. **Given** que o sistema ou aplicativo está com ampliação tipográfica elevada (`>= 175%`, chegando a `200%`), **When** a conversa exibe balões em telas compactas (como `320×568`), **Then** os avatares laterais dos balões cedem espaço automaticamente para que todo o texto caiba em largura plena, sem cortes nem estouro horizontal.
4. **Given** que a opção de reduzir movimento está ativada, **When** qualquer balão com avatar é exibido, **Then** todas as ilustrações permanecem estáticas sem animação de entrada, respiração ou resposta ao toque.

---

### Edge Cases

- **Pessoa sem foto e sem nome com letras**: Quando o nome de tratamento não contiver letras utilizáveis para gerar iniciais (ou estiver ausente em contexto de demonstração isolado), o retrato à direita recua com segurança para o ícone neutro padrão dentro do círculo de perfil.
- **Arquivo de foto própria removido ou corrompido no disco**: Se o registro apontar para arquivo ausente ou ilegível, o retrato no balão recua silenciosamente para as iniciais/ícone padrão sem erro visual nem travamento da lista de mensagens.
- **Muitas mensagens no histórico**: A presença do retrato do usuário e do rosto mini estático da Memora em conversas longas não pode instanciar múltiplos controladores de animação por item da lista; todos os avatares de balão devem permanecer estáticos e leves para aparelhos de entrada.
- **Erro ou alteração rápida de retrato em sequência**: Leituras assíncronas locais que terminarem fora de ordem após troca rápida de conta ou de foto no perfil devem descartar resultados obsoletos e respeitar apenas a carga mais recente da conta ativa.
- **Tela compacta a 200% com teclado aberto**: Os avatares laterais cedem espaço quando a escala atingir o limiar de ampliação alta, mantendo o botão de envio, o campo de texto e o balão atual utilizáveis.
- **Contextos fora do chat (apresentação e ajuda guiada)**: O balão da ajuda guiada (*Passo 2 de 5*) e da apresentação preservam seu funcionamento atual normalmente; caso recebam retrato personalizado opcional no futuro, o padrão neutro de pessoa continua funcionando sem quebra de compatibilidade.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tela de conversa com a assistente MUST exibir o rosto da Memora à esquerda de todo balão atribuído à assistente (incluindo convite inicial, mensagens antigas carregadas do aparelho, balão de espera *"escrevendo…"* e resposta em andamento) quando a ampliação de texto estiver abaixo do limiar de alta ampliação.
- **FR-002**: A tela de conversa MUST exibir um retrato circular de identificação à direita de todo balão atribuído à pessoa usuária (`"Você"`) quando a ampliação de texto estiver abaixo do limiar de alta ampliação.
- **FR-003**: O rosto da Memora e os avatares ilustrados exibidos nos balões da lista de conversa MUST permanecer **estáticos e não interativos ao toque**, garantindo que apenas a Memora do cabeçalho da conversa faça o gesto de falar durante as respostas e que nenhum elemento decorativo concorra com o alvo de rolagem ou toque.
- **FR-004**: O retrato exibido ao lado dos balões da pessoa usuária MUST refletir fielmente a escolha salva em Meu Perfil para a conta atualmente autenticada:
  - Foto própria recortada e sanitizada localmente, quando escolhida;
  - Avatar ilustrado da Memora correspondente em repouso, quando escolhido;
  - Retrato padrão neutro (iniciais do nome de tratamento da pessoa ou silhueta humana neutra na ausência de iniciais), quando nenhuma foto nem avatar estiver salvo.
- **FR-005**: Quando o usuário alterar, substituir ou remover sua foto/avatar de perfil enquanto houver conversa aberta na sessão (por exemplo, alternando entre abas), a conversa MUST atualizar automaticamente os balões para exibir o novo retrato sem exigir saída da tela nem reinício do aplicativo.
- **FR-006**: A leitura e a exibição do retrato da pessoa no chat MUST ocorrer estritamente no aparelho, sem chamadas de rede e sem nunca transmitir imagens, caminhos locais ou identificadores de retrato para fora do dispositivo ou para a assistente.
- **FR-007**: Na troca de conta no mesmo aparelho ou após limpeza de sessão com esquecimento do dispositivo, os balões de conversa MUST descartar imediatamente qualquer retrato da conta anterior, carregando exclusivamente o estado da nova conta ou voltando ao padrão neutro.
- **FR-008**: Caso o arquivo de foto própria salvo localmente falhe ao carregar ou não exista mais, o retrato no balão MUST recuar silenciosamente para o padrão neutro sem exibir mensagens técnicas de erro nem comprometer a leitura do balão.
- **FR-009**: Quando a ampliação de texto do sistema/aplicativo atingir ou ultrapassar o limiar configurado para alta ampliação (`>= 175%`, incluindo `200%`), os avatares laterais dos balões MUST ceder espaço e ficar ocultos, mantendo posição, ponta do balão, rótulos escritos (`"Memora"`, `"Você"`) e largura plena para leitura sem cortes nem estouro em telas de `320×568` a `412×915`.
- **FR-010**: Todos os avatares nos balões de conversa MUST ser marcados como puramente decorativos para leitores de tela, preservando intacta a leitura semântica única do balão (`"Memora disse: ..."` / `"Você disse: ..."` / `"Memora está escrevendo…"`).
- **FR-011**: O tamanho, espaçamento, moldura e cores dos avatares nos balões MUST respeitar exclusivamente os valores centralizados de design e suportar todos os temas (claro, escuro e alto contraste) e todas as paletas com contraste mínimo WCAG 2.2 AA/AAA.
- **FR-012**: A inclusão dos avatares nos balões da conversa MUST manter inalterados o aviso permanente antigolpe/privacidade no topo, os textos curtos de interface e o comportamento existente dos balões fora da conversa (como a ajuda guiada passo a passo e a apresentação).

### Key Entities

- **Retrato da Pessoa no Chat**: Representação visual local associada à conta autenticada, derivada do retrato escolhido em Meu Perfil (foto própria local sem metadados, avatar ilustrado selecionado ou padrão neutro por iniciais/silhueta).
- **Marcador de Autoria do Balão**: Elemento visual estático e decorativo acoplado à lateral esquerda (assistente) ou direita (pessoa usuária) de cada fala na conversa, subordinado à ampliação de texto e isolado de leitores de tela.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos balões de conversa em escala padrão exibem simultaneamente o ícone lateral de autoria (rosto mini estático da Memora à esquerda nos balões dela e retrato circular selecionado à direita nos balões `"Você"`), reproduzindo a identidade visual da tela modelo (*Passo 2 de 5*).
- **SC-002**: 100% dos estados possíveis de retrato em Meu Perfil (foto própria local, cada um dos 4 avatares ilustrados, padrão neutro com iniciais, padrão neutro sem iniciais e fallback de arquivo ausente) são refletidos corretamente nos balões `"Você"` da conversa com 0 requisições de rede adicionais.
- **SC-003**: 100% das atualizações ou remoções de foto/avatar realizadas em Meu Perfil passam a ser exibidas automaticamente em conversas já abertas na mesma sessão, sem necessidade de reiniciar o aplicativo.
- **SC-004**: 0 exposições de retrato da conta anterior ao trocar de conta ou limpar dados do dispositivo, e 0 bytes de imagem enviados ao servidor ou provedor externo de IA.
- **SC-005**: 100% de aprovação na matriz de responsividade e acessibilidade (tamanhos de tela de referência em `100%`, `150%` e `200%`, três temas visuais e preferência por movimento reduzido), com 0 estouros de layout e 0 anúncios duplicados em leitor de tela.
- **SC-006**: 0 violações nos portões automatizados de design, contraste e análise estática do aplicativo após as alterações.

---

## Assumptions

- O mecanismo oficial de escolha, sanitização 1:1 (sem EXIF/GPS) e persistência local da foto de perfil ou avatar ilustrado já entregue em Meu Perfil permanece como fonte única da verdade, sem alterações de formato de arquivo nem permissões novas do sistema operacional.
- O tamanho padrão dos avatares laterais nos balões acompanha a referência visual consolidada dos balões da ajuda guiada (altura de referência de 40 dp para caber proporcionalmente ao lado da primeira linha sem inflar balões curtos), sujeita ao ocultamento acima de `175%`.
- Não há alterações no backend, banco de dados relacional nem contrato OpenAPI, pois retrato e histórico da conversa são dados estritamente locais do aparelho.
