# Contrato de Telemetria e Alertas MQTT (ESP32 Físico)

Define os tópicos, formatos exatos de mensagens JSON geradas pelo firmware do **ESP32 físico** (`ESP32 DevKit` + `MPU6050/9250/9255` + `PulseSensorPlayground`) e o fluxo bidirecional de comunicação com o aplicativo Memora.

---

## 1. Parâmetros de Conexão, TLS e Autenticação MQTT (`FR-013`, `FR-022`)

- **Broker padrão (`MEMORA_MQTT_BROKER`)**: `broker.hivemq.com`
- **Porta TCP/TLS (`MEMORA_MQTT_PORTA`)**: `1883` (TCP padrão de bancada) ou `8883` (TLS cifrado em produção)
- **TLS (`MEMORA_MQTT_TLS`)**: Ativado automaticamente quando `usarTls == true` ou `porta == 8883` (`SecurityContext.defaultContext`)
- **Credenciais opcionais (`MEMORA_MQTT_USUARIO` / `MEMORA_MQTT_SENHA`)**: Suporte a autenticação `username`/`password` no handshake MQTT (`connect(usuario, senha)` no app e `MQTT_USER`/`MQTT_PASS` no ESP32)
- **ClientID do ESP32**: `Memora-ESP32-<MAC_HEX>` (derivado de `ESP.getEfuseMac()`)
- **ClientID do App**: `MemoraApp_<timestamp_ms>`
- **Prefixo base configurável (`MEMORA_MQTT_TOPICO_BASE`)**: `memora/iot/{dispositivoId}` (padrão: `memora/iot/demonstracao-01`)

---

## 2. Telemetria Contínua

- **Tópico**: `memora/iot/demonstracao-01/telemetria`
- **Frequência de envio**: A cada **500 ms** (`2 Hz`, `INTERVALO_TELEMETRIA = 500`)
- **QoS**: `0` (at most once)
- **Direção**: ESP32 Físico → Aplicativo Memora

### Formato Exato no Firmware (`snprintf`):
```c
snprintf(payload, sizeof(payload),
         "{\"bpm\":%d,\"bpm_valido\":%s,\"movimento\":%.1f,\"aceleracao\":%.2f,\"em_movimento\":%s,\"estado\":\"%s\",\"timestamp\":%lu}",
         bpm,
         bpmValido ? "true" : "false",
         nivelMovimento,
         aceleracaoG,
         emMovimento ? "true" : "false",
         nomeEstado(),
         (unsigned long)millis());
```

### Exemplo de Payload JSON:
```json
{
  "bpm": 74,
  "bpm_valido": true,
  "movimento": 4.2,
  "aceleracao": 1.00,
  "em_movimento": true,
  "estado": "EM_MOVIMENTO",
  "timestamp": 145500
}
```

### Especificação de Campos:
- `bpm` (`int`): Frequência cardíaca aferida pelo Pulse Sensor óptico no `GPIO 34` (`35..200 BPM` quando válido; `0` quando inválido ou sem dedo posicionado).
- `bpm_valido` (`bool`): `true` se houve batida detectada nos últimos `8000 ms` dentro da faixa `35..200 BPM`; caso contrário, `false`.
- `movimento` (`double`): Índice experimental filtrado de movimentação (`0.0` a `100.0`), combinando 40% de variação de aceleração linear e 60% de velocidade angular do giroscópio.
- `aceleracao` (`double`): Magnitude resultante calibrada da aceleração (`sqrt(ax² + ay² + az²)`) em múltiplos de `g`.
- `em_movimento` (`bool`): `true` quando `estado == "EM_MOVIMENTO"`, `false` nos demais estados.
- `estado` (`String`): Um dos 6 estados da máquina de estados embarcada:
  - `"INERTE"`
  - `"EM_MOVIMENTO"`
  - `"QUEDA_LIVRE"`
  - `"AGUARDANDO_IMPACTO"`
  - `"POS_IMPACTO"`
  - `"QUEDA_DETECTADA"`
- `timestamp` (`int`): Tempo em milissegundos (`millis()` no ESP32 ou epoch ms no simulador).

---

## 3. Alerta de Queda Confirmada

- **Tópico**: `memora/iot/demonstracao-01/alerta`
- **Gatilho de envio**: Imediato ao entrar no estado `QUEDA_DETECTADA` (após queda livre `>= 80 ms`, impacto `>= 2.5 g` e 3 segundos de pós-impacto com movimento médio `< 10.0`). Se o MQTT estiver desconectado no instante da queda, `alertaPendente = true` garante o envio assim que reconectar.
- **Direção**: ESP32 Físico → Aplicativo Memora

### Formato Exato no Firmware (`snprintf`):
```c
snprintf(payload, sizeof(payload),
         "{\"evento\":\"QUEDA_DETECTADA\",\"bpm\":%d,\"bpm_valido\":%s,\"bpm_antes_da_queda\":%d,\"aceleracao\":%.2f,\"movimento_pos_impacto\":%.1f,\"timestamp\":%lu}",
         bpm,
         bpmValido ? "true" : "false",
         bpmAntesDaQueda,
         aceleracaoG,
         movimentoMedioPosImpacto,
         (unsigned long)millis());
```

### Exemplo de Payload JSON:
```json
{
  "evento": "QUEDA_DETECTADA",
  "bpm": 0,
  "bpm_valido": false,
  "bpm_antes_da_queda": 78,
  "aceleracao": 2.85,
  "movimento_pos_impacto": 3.4,
  "timestamp": 148900
}
```

### Especificação de Campos e Comportamento no App:
- `evento` (`String`): Identificador fixo `"QUEDA_DETECTADA"`.
- `bpm` (`int`): BPM instantâneo no momento da confirmação.
- `bpm_valido` (`bool`): Validade do BPM no momento da confirmação.
- `bpm_antes_da_queda` (`int`): BPM registrado no instante em que a queda livre começou (`-1` se não havia leitura válida). O aplicativo usa este valor como fallback de `bpmNoImpacto` caso `bpm` atual seja `0`.
- `aceleracao` (`double`): Aceleração resultante em `g`.
- `movimento_pos_impacto` (`double`): Movimento médio (`0..100`) medido nos 3 segundos após o impacto.
- **Ação no App**:
  1. Dispara vibração tátil imediata no celular.
  2. Abre a `TelaVerificacaoQueda` (*"Você está bem?"*) em primeiro plano.
  3. Inicia a contagem regressiva de **45 segundos**.

---

## 4. Comando de Reconhecimento / Cessação de Alarme

- **Tópico**: `memora/iot/demonstracao-01/comando`
- **Gatilho de envio**: Quando a pessoa idosa toca em **"Estou bem"** na `TelaVerificacaoQueda`
- **QoS**: `1` (at least once)
- **Direção**: Aplicativo Memora → ESP32 Físico

### Payload JSON:
```json
{
  "comando": "CESSAR_ALARME"
}
```

### Comportamento no ESP32 Físico:
1. Verifica `mensagem.indexOf("CESSAR_ALARME") >= 0`.
2. Restaura `estadoAtual = INERTE` e `alertaPendente = false`.
3. Zera os acumuladores `somaMovimentoPosImpacto = 0.0f` e `quantidadeAmostrasPosImpacto = 0`.
4. Registra no Serial Monitor: `>>> Evento de queda reconhecido/encerrado pelo Memora. <<<`.
