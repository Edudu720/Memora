# Data Model: 005 — Monitoramento IoT e Alerta de Quedas

Entidades de domínio, ciclo de vida e representação de dados para o dispositivo de cuidado, telemetria e fluxos de emergência.

---

## 1. Entidades de Domínio

### `DispositivoCuidado`
Representa o módulo vestível inteligente (ESP32) associado à pessoa usuária.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `String` | Identificador único do dispositivo ou tópico base |
| `nome` | `String` | Nome amigável de exibição (ex.: "Minha Pulseira") |
| `statusConexao` | `StatusConexaoIot` | `desconectado`, `conectando`, `conectado` |
| `ultimaTelemetria` | `TelemetriaIot?` | Amostra mais recente de dados recebida |
| `bateriaPercentual` | `int?` | Nível estimado de bateria (quando disponível) |

---

### `TelemetriaIot`
Registro instantâneo transmitido periodicamente (ex.: a cada 500 ms) pelo dispositivo físico ou simulador.

| Campo | Tipo | Descrição |
|---|---|---|
| `timestamp` | `DateTime` | Momento em que a leitura foi capturada |
| `bpm` | `int` | Frequência cardíaca atual em batimentos por minuto |
| `aceleracaoG` | `double` | Aceleração resultante em múltiplos da gravidade |
| `nivelMovimento` | `double` | Índice de atividade física ponderado (0 a 100) |
| `emMovimento` | `bool` | Indicador se o idoso está ativo ou em repouso |
| `estadoSensor` | `String` | Estado interno do algoritmo ESP32 (`INERTE`, `MOVIMENTO`, `POS_IMPACTO`) |

---

### `EventoQueda`
Registro de uma ocorrência crítica de queda detectada pelo acelerômetro/giroscópio.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `String` | UUID único do evento de queda |
| `timestamp` | `DateTime` | Data e hora exata do impacto detectado |
| `bpmNoImpacto` | `int` | Batimentos cardíacos registrados no momento do impacto |
| `status` | `StatusConfirmacaoQueda` | `aguardandoConfirmacao`, `canceladoPeloUsuario`, `socorroAcionado`, `tempoExpirado` |
| `tempoRestanteSegundos` | `int` | Segundos restantes no cronômetro (inicial: 45) |
| `encerradoEm` | `DateTime?` | Momento em que o alarme foi cancelado ou escalado |

---

### `ContatoEmergencia`
Pessoa de confiança cadastrada para receber socorro imediato.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `String` | Identificador do contato |
| `nome` | `String` | Nome de tratamento da pessoa de confiança (ex.: "Filha Mariana") |
| `telefone` | `String` | Número de telefone com DDD (apenas dígitos) |
| `parentesco` | `String` | Grau de parentesco ou relação (ex.: "Filho", "Vizinho", "Cuidador") |
| `ativo` | `bool` | Se o contato está habilitado para chamadas automáticas |

---

### `ConfiguracaoIot`
Parâmetros de conexão e comportamento do dispositivo no aplicativo.

| Campo | Tipo | Descrição |
|---|---|---|
| `modoOperacao` | `ModoOperacaoIot` | `simulado` (gerador local) ou `mqtt` (broker em rede) |
| `brokerHost` | `String` | Endereço do broker MQTT (padrão: `broker.hivemq.com`) |
| `brokerPorta` | `int` | Porta TCP do broker (padrão: `1883`) ou WebSocket |
| `topicoBase` | `String` | Prefixo do tópico MQTT (padrão: `memora/iot/{uuid}`) |
| `timeoutRespostaSegundos`| `int` | Tempo de espera da pergunta "Você está bem?" (fixo em 45 s) |

---

## 2. Enums

### `StatusConexaoIot`
- `desconectado`: Nenhum sinal recebido nos últimos 15 segundos.
- `conectando`: Tentando handshake com o broker ou simulador.
- `conectado`: Telemetria fluindo regularmente.

### `StatusConfirmacaoQueda`
- `aguardandoConfirmacao`: Tela "Você está bem?" aberta com cronômetro em contagem regressiva.
- `canceladoPeloUsuario`: O idoso tocou em "Estou bem". Alarme cessado.
- `socorroAcionado`: O idoso tocou em "Preciso de ajuda". Discador e mensagens disparados.
- `tempoExpirado`: O cronômetro de 45 segundos zerou sem resposta. Discador e mensagens disparados automaticamente.

### `ModoOperacaoIot`
- `simulado`: Geração interna de dados para testes em sala ou desenvolvimento offline.
- `mqtt`: Conexão em tempo real com Wokwi ou hardware ESP32 real.

---

## 3. Persistência Local

- `ContatoEmergencia` é persistido no armazenamento local seguro do aplicativo (`shared_preferences` / `flutter_secure_storage`).
- Histórico de `EventoQueda` é armazenado localmente em arquivo de log de segurança/auditoria para conferência da família.

