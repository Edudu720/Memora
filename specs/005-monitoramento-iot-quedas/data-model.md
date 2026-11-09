# Data Model: 005 — Monitoramento IoT e Alerta de Quedas (ESP32 Físico)

Entidades de domínio, ciclo de vida e representação de dados para o Dispositivo de Cuidado (ESP32 DevKit + MPU6050/9250/9255 + Pulse Sensor PPG), telemetria MQTT e fluxos de emergência.

---

## 1. Entidades de Domínio

### `DispositivoCuidado`
Representa o módulo vestível inteligente (ESP32 físico ou simulador local) associado à pessoa usuária.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `String` | Identificador único do dispositivo (ex.: `pulseira-01`) |
| `nome` | `String` | Nome amigável de exibição (`"Dispositivo de Cuidado"`) |
| `statusConexao` | `StatusConexaoIot` | `desconectado`, `conectando`, `conectado` |
| `modoOperacao` | `ModoOperacaoIot` | `mqtt` (ESP32 físico via broker) ou `simulado` (gerador offline) |
| `brokerHost` | `String` | Endereço do broker MQTT (padrão: `broker.hivemq.com`) |
| `topicoBase` | `String` | Prefixo do tópico MQTT (padrão: `memora/iot/demonstracao-01`) |
| `ultimaTelemetria` | `TelemetriaIot?` | Amostra mais recente de dados recebida |

---

### `TelemetriaIot`
Registro instantâneo transmitido periodicamente a cada `500 ms` (`2 Hz`) pelo ESP32 físico ou a cada `1000 ms` pelo simulador local.

| Campo | Tipo | Chave JSON MQTT | Descrição |
|---|---|---|---|
| `timestamp` | `DateTime` | `timestamp` | Instante da leitura (normalizado para horário do aparelho caso o payload traga `millis()` de uptime do ESP32) |
| `bpm` | `int` | `bpm` | Frequência cardíaca atual em batimentos por minuto (`0` quando indisponível) |
| `bpmValido` | `bool` | `bpm_valido` | Indica se o Pulse Sensor óptico detectou batimento válido recente (`35..200 BPM` nos últimos `8000 ms`) |
| `aceleracaoG` | `double` | `aceleracao` | Aceleração resultante calibrada em múltiplos da gravidade (`g`) |
| `nivelMovimento` | `double` | `movimento` | Índice experimental filtrado de atividade física (`0.0` a `100.0`) |
| `emMovimento` | `bool` | `em_movimento` | Indicador se a pessoa está em movimento ativo (`estado == EM_MOVIMENTO`) |
| `estadoSensor` | `String` | `estado` | Estado atual da máquina de estados do ESP32 (`INERTE`, `EM_MOVIMENTO`, `QUEDA_LIVRE`, `AGUARDANDO_IMPACTO`, `POS_IMPACTO`, `QUEDA_DETECTADA`) |

---

### `EventoQueda`
Registro de uma ocorrência crítica de queda confirmada após queda livre (`>= 80 ms`), impacto (`>= 2.5 g`) e imobilidade pós-impacto (`3000 ms` com movimento médio `< 10.0`).

| Campo | Tipo | Chave JSON MQTT | Descrição |
|---|---|---|---|
| `id` | `String` | `id` | Identificador único do evento de queda |
| `timestamp` | `DateTime` | `timestamp` | Data e hora em que o alerta foi registrado |
| `bpmNoImpacto` | `int` | `bpm` / `bpm_antes_da_queda` | Batimentos cardíacos registrados no impacto (com fallback automático para `bpm_antes_da_queda` caso o dedo tenha saído do sensor óptico na queda) |
| `bpmValido` | `bool` | `bpm_valido` | Indica se o sensor óptico tinha leitura válida no exato instante da publicação do alerta |
| `bpmAntesDaQueda` | `int` | `bpm_antes_da_queda` | BPM capturado no início da queda livre (`-1` se indisponível) |
| `aceleracaoNoImpacto` | `double` | `aceleracao` | Magnitude de aceleração (`g`) registrada no evento |
| `movimentoPosImpacto` | `double` | `movimento_pos_impacto` | Média do índice de movimento (`0..100`) durante os 3 segundos pós-impacto |
| `status` | `StatusConfirmacaoQueda` | — | `aguardandoConfirmacao`, `canceladoPeloUsuario`, `socorroAcionado`, `tempoExpirado` |
| `tempoRestanteSegundos` | `int` | `tempo_restante` | Segundos restantes no cronômetro de confirmação (padrão: `45`) |
| `encerradoEm` | `DateTime?` | — | Momento em que o alarme foi cancelado ou escalado |

---

### `ContatoEmergencia`
Pessoa de confiança cadastrada para receber socorro imediato (chamada telefônica e mensagem SMS).

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `String` | Identificador do contato |
| `nome` | `String` | Nome de tratamento da pessoa de confiança (ex.: `"Filha Mariana"`) |
| `telefone` | `String` | Número de telefone com DDD (10 ou 11 dígitos nacionais; suporta remoção automática de `+55` em `telefoneNumeros`) |
| `parentesco` | `String` | Grau de parentesco ou relação (ex.: `"Filha"`, `"Vizinho"`, `"Cuidador"`) |
| `ativo` | `bool` | Indica se o contato está ativo para acionamento |

---

## 2. Enums e Máquinas de Estado

### `StatusConexaoIot` (App)
- `desconectado`: Sem conexão ativa com o broker MQTT ou simulador.
- `conectando`: Handshake TCP/MQTT em andamento.
- `conectado`: Inscrito nos tópicos `/telemetria` e `/alerta`.

### `StatusConfirmacaoQueda` (App)
- `aguardandoConfirmacao`: Tela *"Você está bem?"* aberta com cronômetro regressivo de 45 segundos.
- `canceladoPeloUsuario`: A pessoa idosa tocou em *"Estou bem"*; alarme encerrado e comando `CESSAR_ALARME` enviado ao ESP32.
- `socorroAcionado`: A pessoa idosa tocou em *"Preciso de ajuda"*; discador e SMS disparados imediatamente.
- `tempoExpirado`: O cronômetro de 45 segundos atingiu zero sem resposta; discador e SMS disparados automaticamente.

### `ModoOperacaoIot` (App)
- `simulado`: Geração interna de dados para testes offline e automatizados.
- `mqtt`: Conexão em tempo real com o hardware **ESP32 Físico** via broker MQTT.

### `Estado` (Firmware ESP32 Físico — 6 Estados)
1. `INERTE`: Repouso (`nivelMovimento < 3.0`).
2. `EM_MOVIMENTO`: Movimento cotidiano ativo (liga em `>= 3.0`, volta para `INERTE` em `<= 1.5`).
3. `QUEDA_LIVRE`: `aceleracaoG < 0.55 g` (mínimo de `80 ms` para validar).
4. `AGUARDANDO_IMPACTO`: Janela de até `1000 ms` aguardando `aceleracaoG >= 2.5 g`.
5. `POS_IMPACTO`: Janela de `3000 ms` calculando `movimentoMedioPosImpacto`.
6. `QUEDA_DETECTADA`: Confirmado quando `movimentoMedioPosImpacto < 10.0`; permanece retido até receber `CESSAR_ALARME` via MQTT.

---

## 3. Persistência Local

- `ContatoEmergencia` é persistido em JSON via `SharedPreferences` (`RepositorioContatoEmergenciaLocal`).
