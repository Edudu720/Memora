# Feature Specification: 005 — Monitoramento IoT e Alerta de Quedas

**Feature Branch**: `005-monitoramento-iot-quedas`  
**Created**: 2026-10-09  
**Status**: Draft  
**Input**: User description: "Preciso que você crie uma nova tela para a incersão da IOT, que se trata de um ESP32 junto de um MPU6050 e uma medidor de BPM, o objetivo dessa IOT é calcular se o idoso está ou não em movimento, se sofreu alguma queda e se está bem ou não, enviando uma mensagem para o celular do mesmo perguntando se ele está bem, em caso de uma resposta positiva ele cessa o alerta de queda e em caso de uma resposta negativa ou a falta de uma resposta, ele manda um alerta para um contato de emergencia cadastrado no celular do idoso. O Esp fisico ainda não está pronto, no entanto uma simulação no Wokwi foi feita, utilizando um potênciometro no lugar de um medidor de BPM, o código do ESP está feito e funcional, caso seja possível fazer a conexão do Memora com o Wokwi, enviarei o link ou o código para que possa ser simulado em tempo real."

---

## Contexto

O Memora é um companheiro digital dedicado à autonomia e segurança da pessoa idosa. Além do aprendizado digital guiado, a proteção física e o bem-estar cotidiano são pilares fundamentais para que a pessoa idosa viva com tranquilidade e independência.

Esta especificação introduz a integração com o **Dispositivo de Cuidado** (módulo vestível IoT com sensores de movimento/aceleração e monitoramento de frequência cardíaca). O objetivo é monitorar se a pessoa está em movimento, aferir batimentos cardíacos e detectar eventos críticos de **queda acidental**.

Ao detectar uma queda potencial, o sistema prioriza a verificação direta e imediata com o idoso através de uma tela e alerta sonoro/visual ("Você está bem?"):
1. Se a pessoa responder positivamente ("Estou bem"), o alarme cessa imediatamente, evitando pânico desnecessário e falsos socorros.
2. Se a pessoa responder negativamente ("Preciso de ajuda") ou se não houver resposta dentro da janela de tolerância (possível perda de consciência ou imobilidade), o sistema escala automaticamente para o **Contato de Emergência** previamente cadastrado.

### Alinhamento com a Constituição do Memora

- **Princípio I (Segurança Acima de Tudo)**: Dados de frequência cardíaca e eventos de queda são informações sensíveis de saúde (LGPD). O transporte e armazenamento exigem autenticação rigorosa e minimização de dados.
- **Princípio II (Proteção contra Engenharia Social)**: Telas de emergência e alertas são alvos clássicos de golpes de extorsão ("falso sequestro" ou "acidente falso"). O fluxo de emergência não pode permitir que terceiros não autenticados forjem quedas ou enviem mensagens fraudulentas em nome da família.
- **Princípio III (Acessibilidade WCAG 2.2 AA)**: Botões de resposta ("Estou bem" e "Preciso de ajuda") devem possuir alvos de toque generosos (≥ 48 dp), contraste visual extremo (3:1 a 4.5:1), suporte a ampliação até 200% sem perda de legibilidade, e feedback auditivo/tátil claro.
- **Princípio VI (A IA Nunca Age Sozinha)**: A IA Memora atua como mediadora didática e acolhedora, auxiliando na configuração e acalmando o usuário no pós-queda, sem tomar decisões médicas autônomas.
- **Princípio VII (Ensinar, Não Substituir)**: O aplicativo ensina o idoso e sua família como o dispositivo funciona, como testar o alarme e como cadastrar seu contato de confiança com transparência total.

---

## Threat Modeling (Princípio I)

| Elemento / Ativo | Ameaça Potencial | Impacto | Mitigação Obrigatória |
|---|---|---|---|
| **Telemetria Cardíaca e Movimento** | Interceptação em trânsito ou vazamento de dados de saúde. | Violação de privacidade e LGPD. | Comunicação cifrada ponta a ponta; telemetria transitória não deve ser exposta publicamente. |
| **Gatilho de Queda** | Injeção de alertas falsos por agente malicioso externo. | Pânico familiar, acionamento indevido de socorro, erosão de confiança. | Autenticação do dispositivo/simulador vinculada exclusivamente à conta da pessoa idosa. |
| **Contato de Emergência** | Exposição ou alteração não autorizada do número do contato. | Desvio de pedidos de socorro para criminosos. | Cadastro exige confirmação do usuário; número protegido contra leitura não autenticada. |
| **Comunicação IoT / Simulador** | Exposição de chaves ou endpoints desprotegidos. | Sequestro da telemetria ou negação de serviço. | Chaves de sessão e tokens de telemetria efêmeros; sem credenciais fixas expostas. |

---

## Proteção contra Engenharia Social (Princípio II)

*Para cada tela e estado desta funcionalidade:*

1. **Tela de Gerenciamento do Dispositivo (IoT)**:
   - *Como um golpista tentaria explorar?* Simulando um alerta falso de "dispositivo desconectado" ou "bateria crítica" com link para ligar para um falso suporte técnico pago.
   - *Mitigação*: O aplicativo nunca exibe links externos ou números de telefone de suporte terceiros; o estado do dispositivo é claro, auditável e local.

2. **Tela de Alerta de Queda ("Você está bem?")**:
   - *Como um golpista tentaria explorar?* Forjando notificações de emergência para assustar o idoso e fazê-lo transferir dinheiro ou fornecer códigos SMS sob pretexto de "seguro saúde".
   - *Mitigação*: A tela de queda contém apenas dois botões deliberados ("Estou bem" e "Preciso de ajuda") e a contagem regressiva. Nenhuma solicitação de senha, código de acesso ou PIX pode ser inserida ou aceita nessa tela.

3. **Alerta Enviado ao Contato de Emergência**:
   - *Como um golpista tentaria explorar?* Golpe do "falso acidente": mandar mensagem para o filho fingindo ser o hospital cobrando taxa de internação.
   - *Mitigação*: O alerta do Memora é padronizado, informativo e orienta expressamente: *"O Memora nunca pede dinheiro ou transferências para prestar socorro. Ligue diretamente para o seu familiar para confirmar."*

---

## Clarifications

### Session 2026-10-09

- **Q: Como o dispositivo IoT (ou simulador Wokwi) deve transmitir a telemetria em tempo real para o ecossistema Memora?** → **A: MQTT direto via broker** (ex.: broker MQTT padrão configurável `broker.hivemq.com` ou broker local/privado). O ESP32 no Wokwi/físico publica leituras periódicas de BPM, status de movimento e evento de queda em tópicos dedicados, e o aplicativo Memora assina os eventos diretamente, garantindo latência inferior a 500 ms (FR-013, FR-019).
- **Q: Qual é o tempo de tolerância da contagem regressiva na tela de verificação ("Você está bem?") antes de disparar o alerta de emergência?** → **A: 45 segundos**. Tempo adequado para que uma pessoa idosa de 65+ anos ouça o alarme, pegue o celular e toque com calma em "Estou bem", prevenindo falso pânico sem retardar socorro em casos reais de imobilidade (FR-009, FR-010).
- **Q: Por qual canal o alerta de emergência deve ser disparado para o contato cadastrado caso o idoso não responda ou peça ajuda?** → **A: Ligação telefônica direta (discador) + Notificação/Mensagem**. O aplicativo aciona imediatamente a chamada nativa do celular para o contato de emergência e prepara/dispara a mensagem de texto com o relatório da ocorrência (horário, identificação e aviso preventivo contra golpes) (FR-012, FR-020).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Acompanhar o Dispositivo de Cuidado no Aplicativo (Priority: P1)

Dona Maria, 71 anos, usa sua pulseira inteligente com sensores. Ao abrir a nova seção do Memora no seu celular, ela vê com facilidade se o aparelho está conectado, sua frequência cardíaca atual em números grandes e legíveis, e uma indicação clara de que o sensor está monitorando seus movimentos com tranquilidade.

**Why this priority**: É a porta de entrada da funcionalidade. Sem visibilidade sobre o estado da conexão e dos sensores, o idoso e sua família não sabem se a proteção está ativa.

**Independent Test**: Abrir a tela do Dispositivo de Cuidado com o sensor ativo (ou simulado) e verificar se o status de conexão, batimentos por minuto (BPM) e indicação de movimento são exibidos com clareza sem necessidade de rolagem.

**Acceptance Scenarios**:

1. **Given** que o dispositivo de cuidado está conectado e transmitindo, **When** a pessoa acessa a tela do dispositivo, **Then** visualiza o status "Dispositivo Conectado", a frequência cardíaca atual em BPM e o indicador de movimento ativo.
2. **Given** que o sinal do dispositivo é interrompido, **When** passam mais de 15 segundos sem sinal, **Then** o aplicativo exibe o estado "Desconectado" de forma serena e orienta a verificar a proximidade ou bateria.
3. **Given** que o usuário está visualizando a tela com fonte ampliada a 200%, **When** as informações são apresentadas, **Then** nenhum texto é cortado e o alvo de toque de retorno ao início respeita a área mínima de 48x48 dp.

---

### User Story 2 - Verificação Imediata de Queda ("Você está bem?") (Priority: P1)

Seu Antônio, 74 anos, sofre uma queda na sala. O acelerômetro da pulseira detecta a desaceleração brusca de impacto e ausência de movimento regular. Imediatamente, o celular emite um aviso sonoro e visual vibrante e acolhedor, exibindo a pergunta *"Você está bem?"* com dois botões grandes: *"Estou bem"* e *"Preciso de ajuda"*, acompanhados de uma contagem regressiva audível e visível. Seu Antônio apenas tropeçou e não se machucou; ele toca em *"Estou bem"*, o alarme cessa na hora e nenhum susto é transmitido aos seus filhos.

**Why this priority**: É a essência de salvar vidas sem gerar o caos de falsos positivos. A verificação humana em duas vias é mandatória.

**Independent Test**: Simular um evento de queda a partir da telemetria e verificar a abertura imediata da tela de alerta, o cancelamento imediato ao tocar em "Estou bem", e o encerramento do alarme sem disparo externo.

**Acceptance Scenarios**:

1. **Given** que uma queda foi detectada pelos sensores, **When** o evento é recebido, **Then** o aplicativo assume a tela de alerta com destaque máximo, vibração e aviso auditivo claro, perguntando *"Você está bem?"*.
2. **Given** que a tela de alerta de queda está ativa, **When** a pessoa toca no botão *"Estou bem"*, **Then** o alarme cessa imediatamente, a tela fecha e um registro de evento seguro é gravado no histórico local.
3. **Given** que a tela de alerta de queda está ativa, **When** a pessoa toca no botão *"Preciso de ajuda"*, **Then** o sistema escala imediatamente para o disparo de emergência sem aguardar o fim do cronômetro.
4. **Given** que a pessoa não respondeu e o cronômetro zerou, **When** a tolerância expira, **Then** o sistema escala automaticamente para o acionamento do contato de emergência.

---

### User Story 3 - Cadastro e Disparo para Contato de Emergência (Priority: P2)

Dona Francisca cadastra o número de sua filha como contato de emergência no Memora. Durante o cadastro, ela é informada exatamente sobre quais mensagens e avisos serão enviados em caso de queda sem resposta. Quando um alerta não é respondido a tempo, a filha recebe o aviso de urgência com horário e estado do alerta.

**Why this priority**: O sistema de segurança é inócuo se não houver um destinatário de confiança preparado para prestar socorro.

**Independent Test**: Configurar um contato de emergência, simular o estouro do tempo de confirmação de queda e validar o acionamento do mecanismo de contato com os dados corretos.

**Acceptance Scenarios**:

1. **Given** que o idoso acessa a configuração de segurança, **When** insere o nome e número do contato de emergência, **Then** o contato é validado e salvo com confirmação explícita.
2. **Given** que um alerta de queda expirou ou foi respondido com *"Preciso de ajuda"*, **When** o disparo é acionado, **Then** o contato de emergência recebe a notificação/mensagem com horário da ocorrência e orientação de ligar para o idoso.
3. **Given** que nenhum contato de emergência foi cadastrado previamente, **When** o idoso tenta ativar o monitoramento de quedas, **Then** o aplicativo orienta afetuosamente a cadastrar alguém de confiança antes de iniciar.

---

### User Story 4 - Modo de Teste e Simulação em Tempo Real (Priority: P2)

O estudante, desenvolvedor ou cuidador deseja validar o funcionamento com o simulador Wokwi (ou dados simulados) antes de ter o circuito físico montado. Na tela do dispositivo, existe um modo de teste que permite conectar a uma simulação em tempo real ou injetar eventos de teste (teste de batimentos, teste de movimento e teste de queda) com segurança.

**Why this priority**: O hardware físico está em prototipação no Wokwi com potenciômetro simulando o sensor cardíaco. Sem uma ponte de simulação testável, não há como validar a experiência em sala de aula ou no aparelho antes da montagem final.

**Independent Test**: Acionar o modo de simulação no aplicativo ou conectar ao feed do Wokwi e verificar os medidores respondendo em tempo real às alterações do potenciômetro e acelerômetro simulados.

**Acceptance Scenarios**:

1. **Given** que o usuário está no modo de simulação/teste, **When** o simulador envia nova leitura de batimentos, **Then** a interface do Memora atualiza o valor visualmente em menos de 1 segundo.
2. **Given** que o usuário aciona o botão de teste de queda no simulador, **When** a telemetria de queda chega ao app, **Then** o fluxo de verificação de queda é disparado exatamente como no cenário real.

---

## Edge Cases

- **Queda com celular longe do alcance**: O idoso cai no banheiro e o celular está no quarto. O alarme toca alto; ao expirar o tempo limite, o contato de emergência é acionado automaticamente.
- **Batimentos cardíacos anômalos (taquicardia/bradicardia severa)**: Quando os batimentos ultrapassam limites seguros por período sustentado sem queda, o app exibe uma advertência suave sugerindo repouso, sem disparar pânico de queda.
- **Oscilação ou perda de internet no momento da queda**: O alarme sonoro e visual local do aparelho continua funcionando integralmente. Se o disparo externo depender de rede e falhar, o app utiliza fallback para ligação telefônica direta ou SMS nativo.
- **Toques involuntários na tela durante a queda**: Os botões de confirmação possuem confirmação direta com clara distinção espacial e visual, impedindo toques acidentais mútuos.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE fornecer uma tela dedicada ao Dispositivo de Cuidado acessível a partir do Hub e da área de segurança/configurações do Memora.
- **FR-002**: A tela do dispositivo DEVE exibir o estado de conectividade atual: "Conectado", "Aguardando conexão" ou "Desconectado".
- **FR-003**: A tela do dispositivo DEVE exibir a frequência cardíaca atualizada em batimentos por minuto (BPM) com indicador visual de normalidade.
- **FR-004**: A tela do dispositivo DEVE exibir o status de movimentação ("Em movimento", "Em repouso").
- **FR-005**: O sistema DEVE detectar o evento de queda emitido pelo módulo de sensores.
- **FR-006**: Ao detectar um evento de queda, o sistema DEVE abrir imediatamente a tela de verificação de bem-estar com alerta sonoro e vibração contínua.
- **FR-007**: A tela de verificação de bem-estar DEVE apresentar a pergunta explícita *"Você está bem?"* e dois botões de ação principal: *"Estou bem"* e *"Preciso de ajuda"*.
- **FR-008**: Ao selecionar *"Estou bem"*, o sistema DEVE cessar imediatamente o alerta sonoro e vibratório, retornando o aplicativo ao estado normal e registrando o cancelamento no histórico.
- **FR-009**: A tela de verificação de bem-estar DEVE exibir um temporizador regressivo de **45 segundos**, visível e audível com contagem de segundos restante.
- **FR-010**: Se o temporizador de 45 segundos atingir zero sem interação, ou se a pessoa selecionar *"Preciso de ajuda"*, o sistema DEVE escalar imediatamente para o acionamento do contato de emergência.
- **FR-011**: O sistema DEVE permitir o cadastro e edição de pelo menos um Contato de Emergência com nome e número de telefone.
- **FR-012**: O alerta enviado ao contato de emergência DEVE conter a data, o horário da ocorrência, a identificação do idoso e orientações claras de confirmação de segurança contra golpes.
- **FR-013**: O sistema DEVE disponibilizar conexão de telemetria via **protocolo MQTT** (com broker configurável e tópico exclusivo) para recepção em tempo real dos dados do ESP32/Wokwi.
- **FR-014**: Todos os elementos interativos desta funcionalidade DEVEM ter área de toque mínima de 48x48 dp e espaçamento mínimo de 8 dp entre si.
- **FR-015**: Toda a interface DEVE suportar ampliação de texto de até 200% sem perda de conteúdo, sobreposição de textos ou quebra de layout.
- **FR-016**: Toda a interface DEVE cumprir os contrastes mínimos do WCAG 2.2 AA (4.5:1 para texto normal, 3:1 para botões e textos destacados).
- **FR-017**: Todo elemento interativo DEVE conter rótulos semânticos para leitores de tela (TalkBack).
- **FR-018**: O sistema NUNCA deve solicitar transferências financeiras, PIX, senhas ou códigos de verificação durante ou após o fluxo de alerta de emergência.
- **FR-019**: O sistema DEVE disponibilizar um provedor de telemetria simulado embutido no aplicativo para testes de desenvolvimento e demonstração independente de rede externa.
- **FR-020**: O disparo de emergência DEVE acionar a **ligação telefônica direta** (discador nativo do aparelho com o número do contato) e preparar/disparar o envio de **mensagem/notificação de texto** (SMS/WhatsApp) com o relatório da ocorrência.

---

### Key Entities

- **DispositivoCuidado**: Representa o hardware vestível vinculado à conta. Atributos: identificador, apelido, status de conexão, última telemetria recebida, nível de bateria.
- **TelemetriaIot**: Amostra periódica transmitida pelos sensores. Atributos: registro de data/hora, batimentos por minuto (BPM), indicador de aceleração/movimento, integridade do sinal.
- **EventoQueda**: Registro de ocorrência de queda detectada. Atributos: identificador, data/hora do impacto, estado da confirmação ("Pendente", "CanceladoPeloUsuario", "EscaladoParaEmergencia", "TempoExpirado"), tempo de resposta.
- **ContatoEmergencia**: Contato de confiança cadastrado pelo usuário. Atributos: nome de tratamento, parentesco/vínculo, número de telefone para contato, ativo/inativo.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O tempo entre o recebimento da telemetria de queda e a exibição da tela de verificação "Você está bem?" no celular deve ser inferior a 1,5 segundo.
- **SC-002**: O tempo para cessar o alerta sonoro e vibratório após o toque em "Estou bem" deve ser inferior a 300 milissegundos.
- **SC-003**: 100% dos testes na matriz de aparelhos (320x568 até 390x844 em escalas de 100% a 200%) devem apresentar zero estouro de layout (overflow) na tela de alerta de queda e na tela do dispositivo.
- **SC-004**: Em testes de usabilidade com pessoas de 65+ anos, 90% ou mais dos participantes devem conseguir identificar e acionar o botão "Estou bem" sem hesitação em menos de 10 segundos após a exibição do alerta.
- **SC-005**: 100% dos eventos de queda sem resposta devem disparar a notificação para o contato de emergência imediatamente após o fim da janela de tolerância.
- **SC-006**: Zero incidentes de segurança ou vazamento de números de telefone e telemetria de saúde em canais desprotegidos.

---

## Assumptions

- O usuário possui ou simula um dispositivo vestível (ESP32 com MPU6050 e sensor de BPM / potenciômetro no Wokwi) capaz de enviar dados para uma rede local, broker ou API.
- O aparelho celular possui capacidade de emissão sonora e vibração funcional.
- O contato de emergência cadastrado possui número de telefone apto a receber ligações ou mensagens de texto no Brasil (+55).
- A simulação no Wokwi pode comunicar com a máquina local ou serviços na nuvem via Wi-Fi simulado ("Wokwi-GUEST").
