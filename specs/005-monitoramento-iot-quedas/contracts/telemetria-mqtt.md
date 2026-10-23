# Contrato de Telemetria e Alertas MQTT

Define os tópicos, formatos de mensagens JSON e fluxo bidirecional de comunicação entre o ESP32 (Wokwi / Físico) e o aplicativo Memora.

---

## 1. Tópicos MQTT

Todos os tópicos utilizam o prefixo base configurável: `memora/iot/{dispositivoId}/...`  
Onde `{dispositivoId}` é uma identificação de sessão única (ex.: `demonstracao-01` ou UUID).

---

## 2. Telemetria Contínua

- **Tópico**: `memora/iot/{dispositivoId}/telemetria`
- **Frequência de envio**: A cada 500 ms (durante monitoramento normal)
- **QoS**: 0 (melhor esforço)
- **Direção**: ESP32 → Aplicativo Memora

### Payload JSON:
```json
{
  "bpm": 74,
  "movimento": 18.5,
  "aceleracao": 0.98,
  "em_movimento": true,
  "estado": "MOVIMENTO",
  "timestamp": 1728512345000
}
```

### Especificação de Campos:
- `bpm` (`int`): Frequência cardíaca atual (lida no pino do potenciômetro/sensor).
- `movimento` (`float`): Nível de agitação ou deslocamento ponderado (0 a 100).
- `aceleracao` (`float`): Magnitude resultante da aceleração do MPU6050 em `g`.
- `em_movimento` (`bool`): Verdadeiro se `movimento >= 5.0` ou estado for `MOVIMENTO`.
- `estado` (`string`): Enum do código ESP32: `"INERTE"`, `"MOVIMENTO"`, `"QUEDA_LIVRE"`, `"AGUARDANDO_IMPACTO"`, `"POS_IMPACTO"`.
- `timestamp` (`long`): Milissegundos UTC ou `millis()` do microcontrolador.

---

## 3. Alerta de Queda

- **Tópico**: `memora/iot/{dispositivoId}/alerta`
- **Gatilho de envio**: Imediato após confirmação do impacto e imobilidade no algoritmo do MPU6050
- **QoS**: 1 (garantia de entrega)
- **Direção**: ESP32 → Aplicativo Memora

### Payload JSON:
```json
{
  "evento": "QUEDA_DETECTADA",
  "bpm": 86,
  "movimento_pos_impacto": 2.1,
  "timestamp": 1728512348500
}
```

### Comportamento no App:
1. Dispara som de alerta e vibração intensa no celular.
2. Abre a tela "Você está bem?" em primeiro plano.
3. Inicia a contagem regressiva de 45 segundos.

---

## 4. Comando de Cessação de Alarme

- **Tópico**: `memora/iot/{dispositivoId}/comando`
- **Gatilho de envio**: Quando o idoso toca em "Estou bem" no aplicativo
- **QoS**: 1
- **Direção**: Aplicativo Memora → ESP32

### Payload JSON:
```json
{
  "comando": "CESSAR_ALARME"
}
```

### Comportamento no ESP32:
1. Desliga o alarme sonoro no buzzer (`noTone(BUZZER_PIN)`).
2. Apaga o LED vermelho e retorna ao LED verde (modo normal).
3. Reseta o estado interno para `INERTE`.

