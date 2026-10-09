# Research: 005 — Monitoramento IoT e Alerta de Quedas

Decisões de arquitetura e viabilidade técnica para a integração do dispositivo de cuidado (ESP32 + MPU6050 + BPM simulado) e a experiência de proteção física no aplicativo Memora.

---

## R1 — Arquitetura de Comunicação IoT: Protocolo MQTT

### Contexto
O hardware vestível (ESP32 com acelerômetro/giroscópio MPU6050 e potenciômetro simulando o medidor de batimentos cardíacos) precisa enviar dados para o aplicativo do idoso em tempo real. O ESP32 está simulado no Wokwi (`https://wokwi.com/projects/477262321619688449`).

### Decisão
Utilizar o protocolo **MQTT** (Message Queuing Telemetry Transport) sobre TCP/WebSockets:
1. **Baixa latência**: Mensagens publicadas chegam aos assinantes em menos de 200 ms.
2. **Compatibilidade nativa com ESP32**: Biblioteca padrão `PubSubClient` conecta-se perfeitamente via Wi-Fi do Wokwi (`Wokwi-GUEST`).
3. **Desacoplamento por tópicos**:
   - `memora/iot/{dispositivoId}/telemetria`: Publicação contínua a cada 500 ms com BPM, nível de movimento e estado.
   - `memora/iot/{dispositivoId}/alerta`: Publicação imediata no evento de queda confirmada pelo algoritmo do MPU6050.
   - `memora/iot/{dispositivoId}/comando`: O aplicativo pode enviar comando de "cessar alarme" (desligar buzzer/LED no ESP32).
4. **Broker público padrão com suporte a broker próprio**: Por padrão em desenvolvimento/testes, utilizar `broker.hivemq.com` (porta 1883 TCP ou porta 8000/8884 WebSocket) com prefixo UUID exclusivo para isolamento, permitindo configuração personalizada na tela do dispositivo.

---

## R2 — Máquina de Estados da Detecção e Verificação de Bem-Estar

### Contexto
Uma queda física pode ter duas consequências:
1. O idoso apenas tropeçou ou sentou rápido (falso positivo ou queda sem lesão).
2. O idoso caiu com impacto e ficou imóvel ou inconsciente (emergência médica crítica).

### Decisão
O aplicativo gerencia a seguinte máquina de estados determinística:

```
[Monitoramento Ativo] 
         │
         │ (Evento de Queda recebido do ESP32 / Simulação)
         ▼
[Verificação: "Você está bem?"] ── (Temporizador: 45 segundos)
         │
         ├── [Toque em "Estou bem"] ──► [Cessar Alarme] ──► Retorna ao [Monitoramento Ativo]
         │                              (Notifica ESP32 para silenciar buzzer)
         │
         ├── [Toque em "Preciso de ajuda"] ──► [Acionar Emergência Imediata]
         │
         └── [Tempo Expirado (45s)] ──────────► [Acionar Emergência Automática]
```

- **Alarme visual e sonoro**: A tela "Você está bem?" utiliza contraste máximo, aviso sonoro alto repetitivo e vibração contínua do celular.
- **Cancelamento**: O botão "Estou bem" cessa imediatamente som e vibração (< 300 ms) e envia comando MQTT para silenciar o buzzer do ESP32.

---

## R3 — Acessibilidade e Design Visual (WCAG 2.2 AA)

### Contexto
Em uma situação de queda ou susto, a acuidade visual e a precisão motora da pessoa idosa diminuem consideravelmente. A tela de verificação precisa ser extremamente legível e fácil de operar mesmo sob estresse físico.

### Decisão
1. **Hierarquia e clareza extrema**:
   - Pergunta central em fonte Atkinson Hyperlegible Next destacada: *"Você está bem?"*.
   - Temporizador em algarismos grandes com texto de apoio: *"Se não responder em 45 segundos, chamaremos ajuda para você."*
2. **Dois botões primários com contraste diferenciado**:
   - **"Estou bem"**: Botão de grande área, verde/neutro escuro, ícone de confirmação clara.
   - **"Preciso de ajuda"**: Botão de perigo destacado com ícone de socorro, área separada por pelo menos 16 dp para evitar toque acidental.
3. **Área de toque e ampliação**:
   - Alvos de toque com altura mínima de 56 dp (acima do mínimo de 48 dp).
   - Suporte a 200% de ampliação com layout flexível baseado em fração de tela (`LayoutBuilder` ou `SingleChildScrollView`), garantindo zero estouro de layout em 320x568 até 390x844.
4. **Semântica e áudio**:
   - Avisos audíveis de contagem a cada 10 segundos para usuários com baixa visão ou cujo celular tenha caído no chão a curta distância.

---

## R4 — Acionamento do Contato de Emergência (Telefonia + Mensagem)

### Contexto
Quando o tempo esgota ou a pessoa clica em "Preciso de ajuda", a ajuda deve ser acionada de forma confiável no Android.

### Decisão
1. **Ligação direta (Discador Nativo)**:
   - Utilização do pacote já existente no projeto `android_intent_plus`.
   - Disparo da Intent `android.intent.action.DIAL` com `tel:<numero_de_emergencia>`, abrindo o discador com o número preenchido pronto para chamar, garantindo confiabilidade mesmo sem permissão perigosa de chamada direta de background em versões recentes do Android.
2. **Mensagem de Texto (SMS / WhatsApp)**:
   - Preparação de texto pré-formatado seguro:
     > *"ALERTA MEMORA: O sensor de cuidado de [Nome do Idoso] detectou uma possível queda em [Data/Hora] e não houve confirmação de bem-estar. Por favor, entre em contato imediatamente. (Aviso de segurança: O Memora nunca pede senhas ou transferências financeiras)."*
   - O disparo de SMS nativo ou compartilhamento direto é iniciado de forma visível ao cuidador/contato.

---

## R5 — Arquitetura de Provedor de Telemetria (Repository / Service Pattern)

### Contexto
O aplicativo precisa ser testável e utilizável tanto na presença do hardware físico, quanto na simulação Wokwi, quanto em testes automatizados (`flutter test`) e demonstrações locais offline.

### Decisão
Definir a interface `ProvedorDeTelemetria` no domínio:
- `ProvedorDeTelemetriaMqtt`: Conecta-se ao broker MQTT real, processa payloads JSON recebidos do ESP32/Wokwi e emite um `Stream<TelemetriaIot>` e `Stream<EventoQueda>`.
- `ProvedorDeTelemetriaSimulado`: Gera leituras realistas em memória e oferece controles manuais no app para desenvolvedores/testadores (injetar queda, variar BPM, alternar movimento).

A troca de provedor é transparente e configurável via tela de configurações do dispositivo.

---

## R6 — Complemento do Código ESP32 no Wokwi

### Contexto
O código atual do ESP32 (`specs/005-monitoramento-iot-quedas/codigo.md`) possui toda a lógica de sensores, máquina de estados de queda, LEDs e buzzer, mas emite apenas via `Serial.print`.

### Decisão
Criar o arquivo complementar com as rotinas de conectividade para o Wokwi:
- Inclusão de `#include <WiFi.h>` e `#include <PubSubClient.h>`.
- Conexão com SSID `"Wokwi-GUEST"` e senha `""`.
- Conexão com broker MQTT público (`broker.hivemq.com` na porta 1883).
- Publicação no tópico `memora/iot/<id>/telemetria` a cada 500 ms com o payload:
  `{"bpm": 72, "movimento": 14.5, "aceleracao": 1.02, "estado": "INERTE"}`
- Publicação no tópico `memora/iot/<id>/alerta` no evento de queda confirmada:
  `{"tipo": "QUEDA", "bpm": 85, "horario": 123456}`
- Assinatura do tópico `memora/iot/<id>/comando` para desligar o alarme quando o app responder `{"comando": "CESSAR_ALARME"}`.
