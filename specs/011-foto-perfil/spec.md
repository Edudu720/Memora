# Feature Specification: Foto de Perfil da Pessoa Usuária

**Feature Branch**: `feature/011-foto-perfil`  
**Created**: 2026-11-16  
**Status**: Draft  
**Input**: User description: "Certo, agora vamos voltar para a versão mais recente do projeto, foi-me alertado que atualmente é impossível colocar uma foto de perfil, vamos corrigir isso utilizando o Speckit"

---

## Contexto e Diagnóstico

Atualmente, na versão integrada mais recente do Memora (`develop`), é **impossível colocar, trocar ou remover uma foto de perfil**:

1. **Ausência total de interação no Perfil**: a tela de Perfil exibe apenas o título, um desenho estático da assistente Memora, campos informativos somente leitura (nome, e-mail/telefone e aplicativo mais aprendido) e a seção opcional de idade, sem nenhum ponto de entrada para escolher ou tirar uma foto de perfil.
2. **Ausência de fluxo de seleção e persistência**: não existe seletor de mídia/imagem nem armazenamento definido (local ou remoto) associado à conta da pessoa usuária para guardar, validar, sanitizar ou remover um retrato pessoal.
3. **Ausência de suporte no modelo da conta**: o perfil da pessoa não possui atributo nem ciclo de vida de imagem de retrato vinculado à conta autenticada.

O objetivo desta especificação é permitir que pessoas idosas (65+ anos) escolham, visualizem, troquem e removam sua foto de perfil (por foto da galeria, foto tirada na câmera ou avatar ilustrado da Memora) de maneira simples, acessível, segura, exclusivamente local no aparelho e livre de riscos de privacidade ou engenharia social.

---

## Clarifications

### Session 2026-11-16

- **Q1 (`FR-006`, armazenamento e sincronização)**: **A — Apenas local no aparelho (por conta)**. A foto ou avatar escolhido permanece guardado exclusivamente no aparelho atual, isolado por identificador de conta (mesma linha de privacidade da idade opcional no Perfil), sem tráfego de imagem para o servidor e sendo apagado ao acionar remoção explícita ou "Sair e esquecer este aparelho".
- **Q2 (`FR-003`, origens aceitas)**: **B — Galeria de fotos + Câmera no momento + Avatares ilustrados da Memora**. Permite tanto usar uma foto própria (galeria ou câmera) quanto escolher imediatamente um retrato ilustrado da Memora sem precisar conceder permissões nem expor foto pessoal.
- **Q3 (`FR-010`, locais de exibição)**: **A — Apenas na tela de Meu Perfil**. A foto ou avatar definido é exibido exclusivamente na tela de Meu Perfil, preservando intacto o cabeçalho da tela de Início.
- Q: Como a foto escolhida na galeria ou tirada na câmera deve ser enquadrada e confirmada antes de ser salva no perfil? (`FR-005`) → A: Enquadramento quadrado automático centralizado com tela simples de pré-visualização ("Ficou boa assim?" com botões grandes "Usar esta foto" e "Escolher outra") antes de persistir no aparelho.
- Q: O que deve ser exibido no espaço do retrato em "Meu perfil" quando ainda não houver foto nem avatar pessoal? (`FR-001`) → A: Substituir o desenho estático atual da assistente Memora por um espaço dedicado exclusivamente ao retrato da pessoa usuária, exibindo um retrato padrão neutro (silhueta ou iniciais do nome) enquanto não houver escolha salva.
- Q: Como a explicação de privacidade antes de abrir a câmera ou a galeria deve ser apresentada à pessoa usuária? (`FR-004`) → A: Integrada no cabeçalho da tela/folha de escolha de origem ("Galeria / Câmera / Avatar"), visível antes do toque e sem diálogo adicional bloqueando cada seleção.
- Q: Quais limites máximos devem ser aplicados ao arquivo original selecionado e à foto final salva no aparelho? (`FR-005`) → A: Aceitar arquivo de entrada de até 15 MB e salvar a imagem final normalizada em até 512×512 px após recorte quadrado centralizado e remoção completa de metadados EXIF.

---

## Threat Modeling (Princípio I)

| Elemento / Ativo | Ameaça Potencial | Impacto | Mitigação Obrigatória |
|---|---|---|---|
| **Arquivo de imagem selecionado pela pessoa** | Arquivo inválido, disfarçado (tipo MIME falsificado), corrompido ou excessivamente grande que causa travamento do aplicativo ou consumo abusivo de armazenamento local. | Negação de serviço local (app fecha por falta de memória) ou exploração de processador de imagem. | Validar o formato real do arquivo (apenas imagens JPEG/PNG/WebP válidas), impor limite máximo de tamanho e redimensionar/re-encodar a imagem antes de persistir no aparelho. |
| **Metadados ocultos da foto (EXIF)** | Fotos da câmera/galeria contêm coordenadas GPS exatas, modelo do aparelho e data/hora gravados no arquivo copiado para o armazenamento interno. | Exposição desnecessária de dados de localização e aparelho caso haja inspeção local ou compartilhamento futuro de backups. | Remover obrigatoriamente todos os metadados EXIF (especialmente localização e identificadores do dispositivo) no momento do processamento da imagem antes de salvar no armazenamento privado da conta. |
| **Vínculo da foto à conta (aparelho compartilhado)** | Outra pessoa que usa o mesmo celular vê a foto de outra conta, ou restos em cache/temporários de arquivos ficam acessíveis após sair ou esquecer o aparelho. | Violação de privacidade entre usuários do mesmo aparelho. | Armazenar a foto apenas no espaço privado do aplicativo (fora da galeria pública), isolada estritamente pelo identificador da conta ativa, preservando na saída comum da mesma pessoa e removendo de forma definitiva na ação "Sair e esquecer este aparelho" ou exclusão local da conta. |
| **Permissões do dispositivo (galeria / câmera)** | Solicitação de acesso amplo ou antecipado à câmera e a toda a biblioteca de mídia antes mesmo de a pessoa optar por uma foto real. | Desconfiança da pessoa idosa e exposição desnecessária de álbuns pessoais. | Permitir escolher avatares ilustrados da Memora sem nenhuma permissão de sistema; usar seleção restrita sob demanda para galeria (apenas o item escolhido) e solicitar acesso à câmera apenas no instante em que a pessoa escolher tirar uma nova foto. |

---

## Proteção contra Engenharia Social (Princípio II)

1. **Medo de espionagem ao pedir acesso à câmera ou às fotos**:
   - *Como a pessoa idosa pode interpretar ou ser enganada?* Pedidos secos do sistema operacional ("Permitir acesso às fotos/câmera?") geram desconfiança de invasão do celular ou levam a pessoa a recusar sem saber como reverter, ou a aceitar permissões em telas falsas.
   - *Mitigação*: Antes de abrir a seleção ou pedir permissão do sistema, o Memora explica em linguagem acolhedora e literal que verá **somente a foto escolhida** e que a foto serve apenas para o seu perfil dentro do Memora.
2. **Ação ambígua ou botão escondido sobre a foto**:
   - *Como prejudica?* Ícones pequenos de lápis/câmera soltos sobre um círculo sem texto deixam a pessoa idosa sem saber onde tocar para colocar ou mudar sua foto.
   - *Mitigação*: Toda ação de colocar, trocar ou remover a foto deve ter **rótulo textual explícito** acompanhado de ícone claro (ex.: "Colocar foto de perfil", "Trocar foto", "Remover foto"), nunca dependendo apenas de ícone solto ou texto minúsculo.
3. **Recusa de permissão sem bloqueio silencioso**:
   - *Como prejudica?* Se a pessoa negar a permissão de câmera ou galeria, uma tela muda ou mensagem técnica ("Permission denied") faz parecer erro grave ou quebra do celular.
   - *Mitigação*: Exibir orientação humana, calma e prática explicando como tentar novamente ou abrir os ajustes do aparelho em poucos passos, mantendo o Perfil 100% funcional mesmo sem foto.
4. **Remoção acidental da foto escolhida**:
   - *Mitigação*: A ação de remover a foto atual exige confirmação explícita em linguagem clara (com duas opções bem descritas), explicando que a foto voltará ao retrato padrão da Memora e pode ser colocada novamente quando quiser.

---

## Acessibilidade como Requisito (Princípio III)

- **Área de toque e espaçamento**: Todos os controles para colocar, trocar, escolher origem ou remover a foto devem ter área mínima de toque de 48×48 dp e espaçamento mínimo de 8 dp entre ações adjacentes.
- **Contraste e temas**: Contornos do retrato circular, botões e textos orientativos devem atender ao contraste mínimo WCAG 2.2 AA em todos os temas do aplicativo (claro, escuro e alto contraste), mantendo borda de destaque visível no retrato sobre qualquer fundo.
- **Escala de texto até 200%**: Textos de botões, opções de escolha, mensagens de erro e confirmações devem expandir sem corte nem sobreposição até 200% de escala de fonte.
- **Leitores de tela**: Quando não houver foto pessoal, o espaço do retrato padrão não deve gerar ruído redundante se for puramente decorativo ou deve anunciar claramente "Nenhuma foto de perfil escolhida"; quando houver foto pessoal, deve possuir descrição semântica clara ("Sua foto de perfil"), e todos os botões devem anunciar sua ação completa.
- **Duplo sinal visual**: Botões de escolha e remoção devem sinalizar foco e toque além da variação simples de cor, respeitando a preferência de redução de movimento do sistema.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Colocar uma foto de perfil ou avatar pela primeira vez (Priority: P1)

Dona Maria, 71 anos, abre a tela de "Meu perfil" e percebe que ainda não personalizou seu retrato. Ela vê o retrato padrão acompanhado de um botão legível e acolhedor ("Colocar foto de perfil"), escolhe entre usar uma foto da galeria, tirar uma foto com a câmera na hora ou selecionar um dos avatares ilustrados da Memora, e passa a ver sua escolha exibida com nitidez na própria tela de Perfil.

**Why this priority**: Resolve diretamente o problema relatado pelo usuário ("atualmente é impossível colocar uma foto de perfil") e entrega o fluxo principal completo de ponta a ponta, incluindo uma opção acolhedora de avatar que não depende de permissões.

**Independent Test**: Abrir a tela de Perfil em uma conta sem foto, acionar o botão explícito de colocar foto, testar a seleção de uma imagem da galeria e a escolha de um avatar ilustrado, e confirmar que a escolha aparece no retrato do Perfil e permanece após navegar para outra aba e reabrir o aplicativo (offline inclusive).

**Acceptance Scenarios**:

1. **Given** que a pessoa usuária está autenticada e ainda não definiu foto nem avatar pessoal, **When** abre a tela de "Meu perfil", **Then** visualiza o retrato padrão acolhedor acompanhado de uma ação clara com ícone e texto para colocar sua foto de perfil.
2. **Given** que a pessoa tocou para colocar uma foto de perfil, **When** visualiza as opções de origem, **Then** encontra claramente rotuladas as três opções: escolher da galeria, tirar foto com a câmera ou escolher um avatar ilustrado da Memora.
3. **Given** que a pessoa escolheu galeria ou câmera e selecionou/capturou uma imagem válida, **When** a imagem é processada, **Then** o sistema aplica enquadramento quadrado automático centralizado e exibe uma tela simples de pré-visualização com duas ações claras ("Usar esta foto" e "Escolher outra"); ao confirmar o uso, remove metadados EXIF, guarda localmente vinculada à conta e exibe imediatamente a foto no retrato de perfil.
4. **Given** que a pessoa escolheu um dos avatares ilustrados da Memora, **When** confirma a escolha, **Then** o avatar é exibido imediatamente no retrato de perfil e salvo localmente para a conta, sem solicitar permissão de câmera nem de fotos.
5. **Given** que a pessoa abriu a escolha ou o seletor nativo, **When** desiste ou fecha sem escolher nada, **Then** o aplicativo retorna tranquilamente à tela de Perfil mantendo o estado anterior, sem exibir mensagem de erro.

---

### User Story 2 - Trocar ou remover a foto de perfil existente (Priority: P2)

Seu Antônio já colocou uma foto há algumas semanas, mas tirou um retrato melhor hoje — ou decidiu que prefere voltar a não mostrar foto pessoal no Perfil. Na tela de "Meu perfil", ele encontra facilmente ações distintas e com texto claro para trocar a foto atual ou removê-la após confirmação.

**Why this priority**: Dar controle reversível sobre dados pessoais é essencial para autonomia, privacidade e correção de escolhas erradas (frequente entre usuários 65+).

**Independent Test**: Com uma conta que já possui foto de perfil, acessar "Meu perfil", trocar a foto por outra válida (verificando substituição) e, em seguida, acionar "Remover foto", confirmar no diálogo de dois botões e comprovar retorno imediato ao retrato padrão sem sobrar a foto antiga.

**Acceptance Scenarios**:

1. **Given** que a pessoa usuária já possui uma foto de perfil definida, **When** visualiza a tela de "Meu perfil", **Then** vê sua foto atual e ações rotuladas com clareza para trocar a foto ou remover a foto.
2. **Given** que a pessoa toca em trocar foto e escolhe uma nova imagem válida, **When** o processamento termina, **Then** a foto anterior é substituída pela nova foto sem manter resíduos antigos visíveis.
3. **Given** que a pessoa toca em remover foto, **When** confirma a remoção na caixa de confirmação explícita, **Then** a foto é excluída de forma definitiva e o retrato volta ao estado padrão inicial.
4. **Given** que a pessoa toca em remover foto, **When** opta por cancelar na confirmação, **Then** a foto atual permanece intacta.

---

### User Story 3 - Lidar com permissões negadas e imagens inválidas sem sustos (Priority: P3)

Dona Lúcia tenta colocar uma foto, mas nega sem querer a permissão solicitada pelo celular ou escolhe um arquivo corrompido/muito grande. Em vez de fechar o app ou mostrar erro técnico em inglês, o Memora explica com calma o que aconteceu e oferece um caminho claro para tentar de novo ou ajustar a permissão.

**Why this priority**: Pessoas idosas frequentemente recusam permissões de sistema por receio; sem tratamento empático e robusto de falhas, a funcionalidade torna-se inutilizável na vida real.

**Independent Test**: Simular recusa permanente de permissão de câmera/mídia e simular seleção de arquivo corrompido ou acima do tamanho permitido; verificar mensagens em português claro, sem travamentos, preservando o estado anterior do perfil.

**Acceptance Scenarios**:

1. **Given** que a permissão necessária do aparelho foi negada pela pessoa usuária, **When** ela tenta escolher ou tirar foto, **Then** o aplicativo exibe uma orientação em linguagem simples explicando por que precisa daquela permissão e oferece botão claro para abrir as configurações do aparelho ou continuar sem foto.
2. **Given** que o arquivo selecionado está corrompido, não é uma imagem suportada ou excede o limite aceito, **When** o aplicativo tenta processá-lo, **Then** rejeita o arquivo com segurança, mantém o retrato anterior inalterado e informa em linguagem simples que não foi possível usar aquele arquivo, sugerindo escolher outra imagem.

---

### Edge Cases

- O que acontece quando a conta sai normalmente ("Sair da conta") versus quando aciona "Sair e esquecer este aparelho" (`esquecerTudo`)? Na saída normal, a foto local vinculada à conta permanece preservada no aparelho para quando a mesma pessoa voltar a entrar; ao acionar "Sair e esquecer este aparelho" (ou remoção explícita pelo armazenamento por conta), os arquivos e registros locais devem ser apagados de imediato.
- O que acontece quando duas contas diferentes são usadas no mesmo aparelho em sessões distintas? A conta B jamais deve enxergar a foto da conta A.
- O que acontece ao tentar selecionar uma imagem acima de 15 MB ou em formato inválido/não suportado (ex.: `HEIC`, `GIF`, `WebP` animado com múltiplos quadros, arquivo falso renomeado para `.jpg`, PDF renomeado ou imagem corrompida)? Deve ser recusada antes do salvamento com mensagem simples em português, mantendo o retrato atual intacto.
- O que acontece se a pessoa tocar repetidamente no botão de colocar/trocar foto enquanto o seletor ou processamento já está em andamento? (Evitar múltiplos diálogos simultâneos ou condição de corrida.)
- O que acontece se a sessão expirar por inatividade enquanto a pessoa está escolhendo ou tirando a foto no seletor externo do aparelho? Ao retornar para o aplicativo bloqueado ou em outra etapa de autenticação, nenhuma imagem pendente deve ser gravada ou exibida, descartando-se a seleção com segurança.
- O que acontece se o arquivo local salvo anteriormente estiver ausente ou corrompido ao abrir "Meu perfil" (ex.: limpeza manual pelo sistema operacional)? Deve retornar ao retrato padrão sem quebrar a tela nem exibir erro assustador.
- O que acontece se o aparelho estiver sem conexão com a internet ao colocar, trocar, visualizar ou remover a foto/avatar? Tudo deve funcionar 100% normalmente por ser armazenamento local no aparelho.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tela de "Meu perfil" MUST dedicar seu destaque circular de retrato exclusivamente à pessoa usuária (em substituição ao desenho estático anterior da assistente), exibindo sua foto pessoal ou avatar ilustrado escolhido quando definido, ou um retrato padrão neutro (silhueta acolhedora ou iniciais do nome) quando ausente, sempre acompanhado de controle explícito e rotulado por texto para colocar ou alterar a escolha.
- **FR-002**: Todos os botões de ação relacionados à foto de perfil (colocar, trocar, escolher entre galeria/câmera/avatares, remover) MUST exibir ícone + rótulo textual visível, atender à área mínima de toque (≥ 48×48 dp) e ao contraste WCAG 2.2 AA em todos os temas, com layout íntegro em texto escalado até 200%.
- **FR-003**: O sistema MUST permitir à pessoa usuária definir seu retrato de perfil a partir de três origens claramente identificadas: (1) foto da galeria do aparelho, (2) nova foto tirada pela câmera no momento e (3) coleção de avatares ilustrados pré-definidos da Memora.
- **FR-004**: Na própria tela/folha de escolha de origem (antes de a pessoa tocar em Galeria, Câmera ou Avatares), o sistema MUST exibir de forma integrada, clara e sem jargões que o Memora verá apenas a foto escolhida, que a foto permanece somente neste aparelho e que escolher um avatar da Memora não exige permissões de câmera ou fotos — evitando diálogos repetitivos adicionais antes de abrir o seletor nativo.
- **FR-005**: Ao receber uma imagem da galeria ou câmera, o sistema MUST validar a assinatura binária real da imagem (apenas **JPEG, PNG ou WebP estático**, recusando arquivos `HEIC`, imagens animadas multi-quadro e tipos disfarçados), rejeitar arquivos maiores que 15 MB antes da persistência, preservar a orientação visual antes de descartar metadados, aplicar enquadramento quadrado automático centralizado normalizado para no máximo 512×512 px, apresentar pré-visualização simples com confirmação explícita ("Usar esta foto" e "Escolher outra") antes de salvar e remover obrigatoriamente todos os metadados EXIF (incluindo GPS, dispositivo e carimbos ocultos) antes de persistir no armazenamento local.
- **FR-006**: A foto de perfil (imagem processada ou identificador do avatar ilustrado escolhido) MUST ser persistida **exclusivamente no armazenamento privado local do aparelho**, indexada por identificador de conta, sem envio para o servidor e funcionando integralmente sem conexão com a internet.
- **FR-007**: A foto de perfil MUST ser estritamente isolada por conta autenticada no aparelho, garantindo que nenhuma outra conta em sessão posterior visualize, sobrescreva ou herde o retrato de outro titular; se o arquivo referenciado estiver ausente ou ilegível, o sistema MUST recuar com segurança para o retrato padrão.
- **FR-008**: A pessoa usuária MUST poder remover sua foto ou avatar atual por meio de ação explícita protegida por diálogo de confirmação em linguagem simples; confirmada a remoção, o arquivo/registro local armazenado deve ser apagado definitivamente e o Perfil deve retornar ao retrato padrão.
- **FR-009**: Quando a pessoa acionar "Sair e esquecer este aparelho" (fluxo existente em Conta), todos os dados e arquivos locais de foto de perfil armazenados no aparelho MUST ser apagados de forma definitiva (e a camada de armazenamento também MUST expor remoção isolada por conta para reutilização em eventual fluxo futuro de exclusão local de conta); na saída comum da sessão, a escolha permanece salva localmente associada apenas àquela conta.
- **FR-010**: A foto de perfil ou avatar escolhido MUST ser exibido exclusivamente na tela de "Meu perfil", preservando inalterado o cabeçalho da tela de Início e das demais abas.
- **FR-011**: O sistema MUST tratar recusas de permissão (oferecendo orientação calma e opção para abrir ajustes do aparelho ou escolher um avatar da Memora como alternativa imediata), cancelamentos pelo usuário e falhas de leitura/arquivo inválido de forma resiliente, preservando o retrato anterior sem mensagens técnicas nem travamentos.
- **FR-012**: O sistema MUST impedir seleções, aberturas de câmera/galeria ou remoções concorrentes duplicadas enquanto uma operação de foto ainda estiver em andamento.

### Key Entities

- **Retrato de Perfil**: Personalização opcional escolhida pela pessoa usuária para a tela de Meu Perfil, mantida localmente no aparelho por conta. Pode assumir dois tipos:
  - *Foto própria*: arquivo local privado já validado, redimensionado e sem metadados EXIF, associado ao identificador da conta.
  - *Avatar ilustrado*: referência a um dos retratos pré-definidos do acervo da Memora escolhida pela pessoa sem uso de câmera ou galeria.
- **Retrato Padrão**: Representação neutra acolhedora (silhueta humana ou iniciais do nome da pessoa) exibida automaticamente no espaço de retrato de Meu Perfil sempre que a conta não possuir um Retrato de Perfil salvo ou após sua remoção, sem se confundir com a assistente Memora.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das pessoas usuárias autenticadas que acessam "Meu perfil" conseguem localizar e acionar a opção de colocar, trocar ou remover a foto de perfil em até 1 toque a partir da tela principal do perfil, sem depender de gestos ocultos.
- **SC-002**: Pessoas usuárias conseguem selecionar e visualizar uma nova foto de perfil no aplicativo em menos de 30 segundos em fluxo feliz, com persistência confirmada após sair e retornar à tela de Perfil e após reiniciar o aplicativo.
- **SC-003**: 100% das imagens processadas para uso como foto de perfil respeitam entrada máxima de 15 MB, saída máxima de 512×512 px após recorte quadrado centralizado e têm todos os metadados EXIF de localização e dispositivo removidos antes do armazenamento, sem degradação de memória.
- **SC-004**: 100% dos fluxos de erro (cancelamento do seletor, recusa de permissão, arquivo inválido ou acima do limite) encerram sem travamento do aplicativo, mantêm o estado anterior íntegro e exibem orientação compreensível em português.
- **SC-005**: 100% dos controles e estados da funcionalidade (sem foto, com foto, confirmação de remoção e avisos de permissão) passam na verificação de acessibilidade (área ≥ 48×48 dp, contraste WCAG 2.2 AA nos 3 temas e fonte até 200%).
- **SC-006**: Em cenários de múltiplas contas no mesmo aparelho e de limpeza total ("Sair e esquecer este aparelho"), 0% das imagens de uma conta ficam visíveis para outra conta ou permanecem acessíveis após a limpeza total.

---

## Assumptions

- A foto de perfil permanece **100% opcional**: nenhuma funcionalidade essencial do Memora (assistente, guias, monitoramento IoT, configurações ou perfil) exige que a pessoa coloque uma foto.
- O retrato padrão neutro (silhueta/iniciais do nome) é exibido automaticamente sempre que nenhuma foto pessoal ou avatar tiver sido escolhido, mantendo os desenhos existentes da Memora disponíveis como opção na coleção de avatares ilustrados (ou sem confundir a assistente com o usuário).
- Por ser armazenamento exclusivamente local no aparelho (Q1: A), não há sincronização automática da foto caso a pessoa troque de celular nem alteração em contratos de API/banco do servidor.
- As capturas de tela e revisões visuais finais seguirão o padrão do Design System existente (tokens de cor, espaçamento, tipografia, borda e componentes reutilizáveis).
