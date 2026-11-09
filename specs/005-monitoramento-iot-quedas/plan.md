# Implementation Plan: 005 — Monitoramento IoT e Alerta de Quedas (Hardware ESP32 Físico)

**Branch**: `feature/005-fase1-2-fundacao-iot` (`005-monitoramento-iot-quedas`) | **Date**: 2026-11-09 | **Spec**: [spec.md](spec.md)

**Input**: Migração do Módulo IoT de Monitoramento e Detecção de Quedas (Feature 005) do simulador Wokwi para o hardware ESP32 físico definitivo (`ESP32 DevKit` + `MPU6050/MPU9250/MPU9255` + `PulseSensorPlayground` óptico PPG).

---

## Summary

Esta atualização do plano técnico consolida a transição do **Dispositivo de Cuidado** do ambiente simulado Wokwi para o **hardware ESP32 físico definitivo**, mantendo o modo Simulador integrado no aplicativo para testes offline e automatizados.

O plano estrutura a entrega em quatro frentes:

1. **Firmware Embarcado Físico (`ESP32 DevKit` + `MPU` + `Pulse Sensor`)**:
   - Substituição do sketch Wokwi (potenciômetro + buzzer) pelo firmware físico em C++ (Arduino Framework).
   - Leitura inercial via barramento I2C (`SDA=21`, `SCL=22`, clock `100 kHz`) com autodetecção de **MPU6050 (`0x68`), MPU9250 (`0x71`) e MPU9255 (`0x73`)** nos endereços `0x68`/`0x69`, fundo de escala de acelerômetro em `±8g` (`4096 LSB/g`) e giroscópio em `±250 graus/s` (`131 LSB/(grau/s)`), além de rotina de calibração inicial de **300 amostras em repouso** (`fatorCorrecaoAceleracao` e offsets de giroscópio).
   - Leitura cardíaca óptica real via **Pulse Sensor analógico (PPG)** no `GPIO 34` (`ADC1`, resolução de 10 bits) utilizando a biblioteca `PulseSensorPlayground` (amostragem a `500 Hz` por timer de hardware, limiar `550`, faixa fisiológica válida `35..200 BPM` e timeout de perda de batida de `8000 ms`).
   - Hardware sem LEDs e sem buzzer físico: o comando MQTT `{"comando":"CESSAR_ALARME"}` enviado pelo aplicativo atua no destravamento e reinicialização da máquina de estados embarcada (`estadoAtual = INERTE`, `alertaPendente = false`).
   - Conectividade Wi-Fi 2,4 GHz com reconexão não-bloqueante a cada `10 s` e cliente MQTT 3.1.1 (`broker.hivemq.com:1883`) com `ClientID` derivado do MAC físico (`Memora-ESP32-<MAC_HEX>`) e publicação de telemetria a cada `500 ms` (`2 Hz`).

2. **Evolução da Máquina de Estados de Detecção de Queda (6 Estados)**:
   - `INERTE`: Repouso estável (~1,00 g após calibração).
   - `EM_MOVIMENTO`: Atividade cotidiana com histerese (`liga >= 3.0`, `desliga <= 1.5`).
   - `QUEDA_LIVRE`: Perda brusca de sustentação (`aceleracaoG < 0.55g` por no mínimo `80 ms`), capturando `bpmAntesDaQueda`.
   - `AGUARDANDO_IMPACTO`: Janela de até `1000 ms` aguardando pico de desaceleração (`aceleracaoG >= 2.5g`).
   - `POS_IMPACTO`: Janela de `3000 ms` avaliando imobilidade pós-impacto (`movimentoMedioPosImpacto < 10.0/100`) para descartar falsos positivos nos quais a pessoa continua se movimentando normalmente.
   - `QUEDA_DETECTADA`: Estado confirmado e retido até o recebimento de `CESSAR_ALARME` via MQTT.

3. **Alinhamento de Contratos JSON MQTT e Camada de Domínio (`app/lib/features/cuidado/`)**:
   - Atualização de `TelemetriaIot` para suportar `bpm_valido` (`bool`), estados `"EM_MOVIMENTO"` e `"QUEDA_DETECTADA"`, e normalização de `timestamp` quando oriundo de `millis()` do microcontrolador.
   - Atualização de `EventoQueda` para suportar `bpm_valido` (`bool`), `bpm_antes_da_queda` (`int`) e `movimento_pos_impacto` (`double`), utilizando `bpm_antes_da_queda` como fallback quando o sensor óptico perder contato com o dedo durante o impacto (`bpm == 0`).

4. **Atualização da Interface (WCAG 2.2 AA/AAA) e Portões de Qualidade**:
   - Atualização da nomenclatura na `TelaDispositivoCuidado`, substituindo referências ao simulador Wokwi por **ESP32 Físico / Dispositivo ESP32 (MQTT)**.
   - Orientação clara no `MedidorBpm` quando o sensor óptico PPG estiver sem leitura válida (`bpmValido == false` ou `bpm <= 0`).
   - Atualização de `validar_suite_cuidado.py` e dos testes automatizados do Flutter para refletir o firmware físico e os novos campos do contrato MQTT.

---

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (aplicativo Android) · C++ / Arduino Framework (ESP32 DevKit físico)

**Primary Dependencies**:
- **App Flutter**:
  - `mqtt_client: ^10.3.3`: Cliente MQTT 3.1.1 sobre TCP (`porta 1883`) com resolução DNS IPv4 priorizada.
  - `android_intent_plus: ^5.3.0`: Acionamento do discador telefônico nativo (`ACTION_DIAL`) e envio assistido de SMS (`ACTION_SENDTO`).
  - `shared_preferences: ^2.5.5`: Persistência local do `ContatoEmergencia`.
  - Design System do Memora (`tokens`, `componentes`, tipografia `Atkinson Hyperlegible Next`).
- **Firmware ESP32**:
  - `Arduino.h`, `Wire.h` (I2C a 100 kHz), `WiFi.h` (Wi-Fi STA 2,4 GHz).
  - `PubSubClient.h` (cliente MQTT com buffer de 512 bytes, keep-alive 30 s, socket timeout 3 s).
  - `PulseSensorPlayground.h` (leitura óptica PPG no `GPIO 34` / `ADC1` em 10 bits a 500 Hz).

**Storage**:
- Armazenamento local no aparelho para persistir o `ContatoEmergencia` e estado da sessão de monitoramento.
- Sem exigência de novas migrations no backend para a comunicação direta MQTT entre ESP32 e aplicativo.

**Testing**:
- `flutter_test` cobrindo parsing dos novos payloads JSON do ESP32 físico, transições do cronômetro de 45 segundos e matriz de acessibilidade (`test/suporte/aparelhos.dart`: 4 aparelhos × 3 escalas × 3 temas).
- `python specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py` (7 portões de validação).

**Target Platform**: Android (aparelhos físicos e emuladores de 320×568 até 390×844) + Hardware ESP32 DevKit v1 (30/38 pinos).

**Project Type**: Mobile App (Flutter) + Firmware Embarcado IoT (ESP32 Físico).

**Performance Goals**:
- Taxa de publicação de telemetria MQTT: `500 ms` (`2 Hz`), latência de rede < `500 ms`.
- Amostragem inercial do MPU: ~`100 Hz` (DLPF ativo, `SMPLRT_DIV = 9`); amostragem PPG: `500 Hz`.
- Resposta ao toque em "Estou bem" (cessação da vibração local + publicação de `CESSAR_ALARME`): < `300 ms`.
- Zero estouro de layout (overflow) em até `200%` de escala de fonte.

**Constraints**:
- Conformidade estrita com a Constituição do Memora (WCAG 2.2 AA/AAA, piso de `16 sp`, alvos ≥ `48x48 dp` / `56 dp` para decisões, zero valores visuais literais fora dos tokens).
- Cláusula antigolpe obrigatória em toda mensagem de emergência.
- Código, entidades, testes e documentação 100% em Português Brasileiro.

---

## Constitution Check

*GATE: avaliado antes da Phase 0 e reavaliado após a Phase 1.*

| Princípio | Situação | Como este plano cumpre |
|---|---|---|
| **I — Segurança acima de tudo** | ✅ | Threat model preservado no `spec.md`. ClientID MQTT único por MAC evita desconexões cruzadas; dados de contato permanecem locais no aparelho. |
| **II — Engenharia social** | ✅ | A mensagem de socorro mantém a cláusula inegociável: *"O Memora NUNCA solicita dinheiro, transferências ou senhas"*. |
| **III — Acessibilidade** | ✅ | Piso tipográfico de 16 sp, botões de decisão de 56 dp, indicação textual clara quando o dedo não está posicionado no Pulse Sensor, zero overflow em 200%. |
| **IV — Spec antes de código** | ✅ | Especificação, pesquisa técnica, modelo de dados, contratos MQTT e guia de validação atualizados antes da alteração do código. |
| **V — Arquitetura limpa, feature-first** | ✅ | Mudanças isoladas em `app/lib/features/cuidado/` respeitando a separação `domain`, `data` e `presentation`. |
| **VI — A IA nunca age sozinha** | ✅ | O protocolo de verificação de 45 segundos dá controle prioritário ao idoso antes de qualquer acionamento externo, que usa intents nativas transparentes. |
| **VII — Ensinar, não substituir** | ✅ | A interface orienta claramente como posicionar o dedo no sensor óptico e como testar a conexão com o dispositivo físico ou simulador. |

---

## Project Structure

### Documentation (this feature)

```text
specs/005-monitoramento-iot-quedas/
├── spec.md                     # Especificação da feature
├── checklists/
│   └── requirements.md         # Checklist de qualidade (16/16)
├── plan.md                     # Este plano de implementação (ESP32 Físico)
├── research.md                 # Decisões técnicas (MPU autocalibrado, PulseSensor, 6 estados, MQTT)
├── data-model.md               # Entidades de domínio atualizadas (bpmValido, bpmAntesDaQueda)
├── quickstart.md               # Roteiro de validação com o ESP32 físico e simulador
├── contracts/
│   ├── telemetria-mqtt.md      # Tópicos e schemas JSON exatos do ESP32 físico
│   └── acao-emergencia.md      # Regras de discagem e mensagem segura antigolpe
├── firmware_wokwi.ino          # Firmware C++ do ESP32 físico (MPU + PulseSensor + MQTT)
└── validar_suite_cuidado.py    # Suíte automatizada de verificação (7 portões)
```

### Source Code Layout

```text
app/lib/features/cuidado/
├── domain/
│   ├── entidades/
│   │   ├── enums_cuidado.dart
│   │   ├── dispositivo_cuidado.dart
│   │   ├── telemetria_iot.dart
│   │   ├── evento_queda.dart
│   │   └── contato_emergencia.dart
│   ├── repositorios/
│   │   ├── repositorio_contato_emergencia.dart
│   │   └── provedor_telemetria.dart
│   └── casos_de_uso/
│       └── disparar_socorro_emergencia.dart
├── data/
│   ├── provedores/
│   │   ├── provedor_telemetria_mqtt.dart
│   │   └── provedor_telemetria_simulado.dart
│   └── repositorios/
│       └── repositorio_contato_emergencia_local.dart
└── presentation/
    ├── controladores/
    │   ├── controlador_dispositivo_cuidado.dart
    │   └── controlador_verificacao_queda.dart
    ├── telas/
    │   ├── tela_dispositivo_cuidado.dart
    │   ├── tela_verificacao_queda.dart
    │   └── dialogo_contato_emergencia.dart
    └── widgets/
        ├── medidor_bpm.dart
        ├── indicador_movimento.dart
        └── cronometro_regressivo_queda.dart
```

---

## Complexity Tracking

*Nenhuma violação constitucional a justificar.*
