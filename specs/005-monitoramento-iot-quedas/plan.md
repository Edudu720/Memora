# Implementation Plan: 005 — Monitoramento IoT e Alerta de Quedas

**Branch**: `005-monitoramento-iot-quedas` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-monitoramento-iot-quedas/spec.md`

---

## Summary

Esta feature implementa a integração do aplicativo Memora com o **Dispositivo de Cuidado** (ESP32 com MPU6050 e medidor de BPM simulado no Wokwi) para monitorar em tempo real se a pessoa idosa está em movimento, aferir frequência cardíaca e detectar eventos de queda acidental.

O plano organiza a entrega em três camadas:
1. **Infraestrutura e Contratos IoT**:
   - Integração do cliente MQTT no Flutter (`mqtt_client`) desacoplada por interface (`ProvedorDeTelemetria`).
   - Provedor simulado embutido para testes de desenvolvimento rápidos e offline.
   - Código do firmware do ESP32 para Wokwi (`firmware_wokwi.ino`) com Wi-Fi e MQTT (`PubSubClient`) publicando telemetria a cada 500 ms e alerta de queda imediato.
2. **Núcleo de Detecção e Emergência**:
   - Máquina de estados no aplicativo para contagem regressiva de **45 segundos**.
   - Fluxo de cancelamento imediato ("Estou bem") com comando MQTT de volta ao ESP32 para silenciar o buzzer.
   - Fluxo de escalamento ("Preciso de ajuda" ou expiração de 45s) com abertura do discador nativo (`ACTION_DIAL`) e disparo de mensagem padronizada segura contra golpes.
3. **Interface e Acessibilidade (WCAG 2.2 AA)**:
   - `TelaDispositivoCuidado`: Visão de batimentos cardíacos, movimentação e estado de conexão, acessível pelo Hub e Início.
   - `TelaVerificacaoQueda`: Tela de alto contraste e foco total, com pergunta clara *"Você está bem?"*, cronômetro regressivo e botões de grande alvo (> 56 dp).
   - Validação rigorosa na matriz de 4 aparelhos × 3 escalas (zero overflow em até 200%).

---

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (aplicativo) · C++ / Arduino Framework (ESP32 no Wokwi)

**Primary Dependencies**:
- `mqtt_client: ^10.3.3`: Comunicação leve e padronizada sobre TCP / WebSockets para IoT.
- `android_intent_plus: ^5.3.0` (já existente no projeto): Acionamento do discador telefônico nativo do Android (`ACTION_DIAL`) e SMS.
- `shared_preferences: ^2.5.5` e `flutter_secure_storage: ^9.2.4` (já existentes): Armazenamento de configurações do dispositivo e contato de emergência.
- Design System do Memora (`tokens`, `componentes`, tipografia `Atkinson Hyperlegible Next`).

**Storage**:
- Armazenamento local seguro no aparelho para persistir o `ContatoEmergencia`, configurações do broker e histórico local de alertas.
- Sem exigência de novas migrations no backend na fase inicial de telemetria direta por MQTT.

**Testing**:
- `flutter_test` cobrindo regras de negócio, transições de estado do cronômetro de 45 segundos, e testes de tela na matriz de acessibilidade (`test/suporte/aparelhos.dart`).

**Target Platform**: Android (Galaxy S20 FE, Pixel 6, telas de 320×568 a 390×844)

**Project Type**: Mobile App + Firmware IoT (Wokwi)

**Performance Goals**:
- Latência de telemetria ESP32 → Memora: < 500 ms.
- Resposta de cessação de som após clique em "Estou bem": < 300 ms.
- Zero estouro de layout em 200% de ampliação.

**Constraints**:
- Conformidade total com a Constituição (Threat Model e mitigação de golpes de falso acidente).
- Nenhum link externo ou pedido de dinheiro no fluxo de alerta.
- Contraste visual mínimo WCAG 2.2 AA (4.5:1 texto, 3:1 botões).

---

## Constitution Check

*GATE: avaliado antes da Phase 0 e reavaliado depois da Phase 1.*

| Princípio | Situação | Como este plano cumpre |
|---|---|---|
| **I — Segurança acima de tudo** | ✅ | Threat model documentado no `spec.md`. Telemetria trafega em tópicos MQTT autenticados/isolados. Contato de emergência guardado com segurança local. |
| **II — Engenharia social** | ✅ | Todo alerta emitido possui cláusula explícita de segurança: *"O Memora nunca pede senhas ou dinheiro"*. Nenhuma permissão de sobreposição ou dados financeiros. |
| **III — Acessibilidade** | ✅ | Botões "Estou bem" e "Preciso de ajuda" com altura ≥ 56 dp, cores distintas com texto explícito (nunca só cor), contraste alto e suporte a texto a 200%. |
| **IV — Spec antes de código** | ✅ | Spec aprovada com 16/16 itens no checklist de requisitos; decisões das 3 clarificações registradas. |
| **V — Arquitetura limpa, feature-first** | ✅ | Módulo isolado em `app/lib/features/cuidado/` com separação `domain`, `data`, `presentation`. |
| **VI — A IA nunca age sozinha** | ✅ | A IA atua na persona acolhedora e orientadora; o fluxo de emergência é estritamente determinístico no código. |
| **VII — Ensinar, não substituir** | ✅ | O idoso e a família aprendem passo a passo a testar o alarme e configurar o socorro de forma transparente. |

---

## Project Structure

### Documentation (this feature)

```text
specs/005-monitoramento-iot-quedas/
├── spec.md              # Especificação aprovada
├── checklists/
│   └── requirements.md  # Checklist de qualidade (16/16)
├── plan.md              # Este plano de implementação
├── research.md          # Decisões de arquitetura (MQTT, máquina de estados, discador)
├── data-model.md        # Entidades de domínio e ciclo de vida
├── quickstart.md        # Roteiro de validação dos cenários
├── contracts/
│   ├── telemetria-mqtt.md  # Tópicos e schemas JSON
│   └── acao-emergencia.md # Regras de discagem e mensagem segura
├── codigo.md            # Código base do ESP32 fornecido pelo usuário
└── firmware_wokwi.ino   # Código completo do ESP32 com Wi-Fi e MQTT pronto para Wokwi
```

### Source Code Layout

```text
app/lib/features/cuidado/
├── domain/
│   ├── entidades/
│   │   ├── dispositivo_cuidado.dart
│   │   ├── telemetria_iot.dart
│   │   ├── evento_queda.dart
│   │   └── contato_emergencia.dart
│   ├── repositorios/
│   │   ├── repositorio_contato_emergencia.dart
│   │   └── provedor_telemetria.dart
│   └── casos_de_uso/
│       ├── monitorar_dispositivo.dart
│       ├── processar_evento_queda.dart
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
