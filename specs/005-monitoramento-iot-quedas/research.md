# Research: 005 — Monitoramento IoT e Alerta de Quedas (ESP32 Físico)

Decisões de arquitetura e engenharia embarcada/mobile para a migração do Dispositivo de Cuidado do simulador Wokwi para o **hardware ESP32 físico definitivo** (`ESP32 DevKit` + `MPU6050/MPU9250/MPU9255` + `PulseSensorPlayground`).

---

## R1 — Transição de Sensores: De Wokwi Simulado para MPU Autocalibrado e Pulse Sensor PPG Real

### Contexto
Na fase inicial de prototipação no Wokwi, o batimento cardíaco era simulado por um potenciômetro linear e o acelerômetro MPU6050 operava sem rotina de calibração de offset. No hardware físico real montado em protoboard/case vestível, módulos inerciais reais apresentam erro de escala em repouso (ex.: `~1.10 g` parado) e deriva (drift) nos três eixos do giroscópio, além de o sensor cardíaco ser óptico fotopletismográfico (**Pulse Sensor** no `GPIO 34`).

### Decisão
1. **Autodetecção e Calibração Inicial do MPU (`I2C` a `100 kHz` nos pinos `SDA=21`, `SCL=22`)**:
   - Varredura automática nos endereços `0x68` e `0x69` validando o registrador `WHO_AM_I (0x75)` para compatibilidade com **MPU6050 (`0x68`)**, **MPU9250 (`0x71`)** e **MPU9255 (`0x73`)**.
   - Configuração do acelerômetro em `±8 g` (`ACCEL_SCALE = 4096.0 LSB/g`) para evitar saturação durante picos de impacto, e giroscópio em `±250 graus/s` (`GYRO_SCALE = 131.0 LSB/(grau/s)`), com filtro passa-baixas digital (`DLPF = 0x03`) e taxa nominal de `100 Hz` (`SMPLRT_DIV = 9`).
   - Execução de `calibrarMPU()` no boot com **300 amostras** em repouso (exigindo ao menos 90% de leituras válidas e magnitude média entre `0.5 g` e `1.8 g`), calculando `fatorCorrecaoAceleracao = 1.0f / mediaG` e os offsets médios `gyroOffsetX/Y/Z`.
2. **Aferição Cardíaca Óptica com `PulseSensorPlayground`**:
   - Utilização do pino `GPIO 34` (`ADC1`, compatível com uso simultâneo do Wi-Fi no ESP32) com resolução analógica de `10 bits` (`analogReadResolution(10)`) e limiar `PULSE_THRESHOLD = 550`.
   - Validação de janela fisiológica (`35 <= bpm <= 200`) e janela temporal de batida recente (`TIMEOUT_BPM_MS = 8000 ms`), expondo a flag booleana `bpm_valido` no JSON MQTT.
   - Se o sensor óptico não iniciar ou o dedo não estiver posicionado, o sistema reporta `bpm = 0` e `bpm_valido = false` sem interromper o monitoramento de quedas do MPU.

### Alternativas Consideradas
- *Manter leitura analógica bruta sem biblioteca PPG*: Descartado, pois o sinal óptico PPG bruto exige detecção de onda de pulso (inter-beat interval) a `500 Hz` via timer de hardware, provida de forma confiável pela `PulseSensorPlayground`.

---

## R2 — Evolução da Máquina de Estados de Detecção de Queda (6 Estágios com Filtro Pós-Impacto)

### Contexto
Em um dispositivo físico real usado no corpo, movimentos bruscos cotidianos (sentar-se rapidamente, descer um degrau ou bater a mão na mesa) podem gerar picos momentâneos de aceleração. Além disso, o protótipo físico definitivo **não utiliza LEDs nem buzzer na placa**, concentrando o alerta sonoro/vibratório no smartphone do idoso.

### Decisão
Adotar uma máquina de estados de **6 estágios** no ESP32 combinada com a janela de verificação de **45 segundos** no aplicativo:

```text
[1. INERTE] <──(histerese: liga >= 3.0 / desliga <= 1.5)──> [2. EM_MOVIMENTO]
     │                                                             │
     └────────────── (aceleracaoG < 0.55g) ────────────────────────┘
                               │
                               ▼
                      [3. QUEDA_LIVRE] (mínimo 80 ms; salva bpmAntesDaQueda)
                               │
           ┌───────────────────┴───────────────────┐
           │ (pico >= 2.5g imediato)               │ (saiu de queda livre < 2.5g)
           │                                       ▼
           │                           [4. AGUARDANDO_IMPACTO] (janela de até 1000 ms)
           │                                       │ (aceleracaoG >= 2.5g)
           └───────────────────┬───────────────────┘
                               ▼
                      [5. POS_IMPACTO] (avalia imobilidade por 3000 ms)
                               │
        ┌──────────────────────┴──────────────────────┐
        │ (movimentoMedio < 10.0/100)                 │ (movimentoMedio >= 10.0/100)
        ▼                                             ▼
[6. QUEDA_DETECTADA]                         Descarta falso positivo
(Publica /alerta e aguarda CESSAR_ALARME)    (Retorna para EM_MOVIMENTO)
```

1. **Índice Experimental de Movimento (`0 a 100`)**: Combina 40% da variação de magnitude linear (`deltaAceleracao / 0.15g`) com 60% da velocidade angular (`velocidadeRotacao / 30 graus/s`), suavizado por filtro exponencial (`0.75 * anterior + 0.25 * bruto`).
2. **Validação de Imobilidade Pós-Impacto (`3000 ms`)**: Após detectar queda livre (`>= 80 ms` abaixo de `0.55 g`) seguida de impacto (`>= 2.5 g`), o firmware observa os 3 segundos seguintes. Somente se o movimento médio pós-impacto for inferior a `10.0` a queda é confirmada (`QUEDA_DETECTADA`).
3. **Destravamento Remoto (`CESSAR_ALARME`)**: Quando o idoso responde *"Estou bem"* no app Memora, o comando `{"comando":"CESSAR_ALARME"}` publicado em `memora/iot/demonstracao-01/comando` faz o ESP32 sair do estado `QUEDA_DETECTADA` e retornar imediatamente ao estado `INERTE`.

---

## R3 — Arquitetura de Comunicação MQTT e Resiliência de Rede

### Contexto
O ESP32 físico conecta-se a uma rede Wi-Fi 2,4 GHz local e publica no broker `broker.hivemq.com:1883`, enquanto o aplicativo Flutter assina os tópicos de telemetria e alerta.

### Decisão
1. **Reconexão Não-Bloqueante no ESP32**:
   - Se o Wi-Fi ou o broker MQTT caírem, o loop principal do ESP32 continua amostrando o MPU a `100 Hz` e o Pulse Sensor a `500 Hz`.
   - Caso uma queda ocorra durante uma breve oscilação de rede, a flag `alertaPendente = true` retém o evento e publica `publicarAlertaQueda()` assim que a reconexão MQTT (tentada a cada `5 s`) se completa.
2. **ClientID Baseado em MAC Address**:
   - O ESP32 gera `Memora-ESP32-<MAC_HEX>` usando `ESP.getEfuseMac()`, evitando colisões de sessão no broker público.
3. **Resolução DNS IPv4 e MQTT 3.1.1 no App Flutter**:
   - O `ProvedorDeTelemetriaMqtt` resolve o host via `InternetAddressType.IPv4` e negocia MQTT 3.1.1 (`setProtocolV311()`), mantendo compatibilidade com aparelhos físicos e emuladores Android.

---

## R4 — Enriquecimento dos Contratos JSON e Fallback de BPM Pré-Queda

### Contexto
Durante uma queda real, o dedo da pessoa idosa pode escapar da face óptica do Pulse Sensor no momento do impacto, fazendo o `bpm` instantâneo cair para `0` (`bpm_valido: false`) exatamente quando o alerta de queda é enviado.

### Decisão
- O firmware salva `bpmAntesDaQueda = bpmValido ? bpm : -1` no instante em que entra em `QUEDA_LIVRE` e envia esse valor no JSON de alerta (`"bpm_antes_da_queda"`).
- No aplicativo Flutter, `EventoQueda.fromJson` lê `bpm`, `bpm_valido`, `bpm_antes_da_queda` e `movimento_pos_impacto`. Caso `bpm` no momento do alerta seja `<= 0` e `bpm_antes_da_queda > 0`, o app utiliza `bpm_antes_da_queda` como `bpmNoImpacto`, preservando o último batimento válido aferido imediatamente antes do acidente.
- Como o campo `timestamp` emitido pelo ESP32 utiliza `millis()` (tempo desde o boot do microcontrolador), os parsers `TelemetriaIot.fromJson` e `EventoQueda.fromJson` diferenciam timestamps epoch Unix (`>= 1000000000000`) de valores de `millis()` do microcontrolador, usando `DateTime.now()` na chegada da mensagem quando o valor recebido representar `millis()`.

---

## R5 — Terminologia de Interface e Acessibilidade (WCAG 2.2 AA/AAA)

### Contexto
A interface da `TelaDispositivoCuidado` possuía rótulos explícitos referenciando o simulador `"Wokwi"`. Com a adoção do ESP32 físico, a interface deve refletir o hardware real sem perder a clareza para a pessoa idosa e para o avaliador técnico.

### Decisão
- Substituir os rótulos visuais na `TelaDispositivoCuidado`:
  - `'Wokwi / MQTT'` ➔ `'Dispositivo ESP32 (MQTT)'`
  - `'Integração Wokwi & Testes'` ➔ `'Conexão ESP32 & Testes'`
  - `'Wokwi Ativo'` / `'Usar Wokwi'` ➔ `'ESP32 Ativo'` / `'Usar ESP32'`
  - `'Reconectar ao Wokwi'` ➔ `'Reconectar ao ESP32'`
- Manter intactos os requisitos do Design System Memora (piso de 16 sp, botões de decisão de 56 dp, zero literais visuais e suporte a 200% de escala de texto).
