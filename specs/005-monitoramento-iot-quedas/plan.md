# Implementation Plan: 005 — Monitoramento IoT e Alerta de Quedas (Hardware ESP32 Físico, Socorro via WhatsApp e Fechamento da Issue #43)

**Branch**: `feature/005-fase1-2-fundacao-iot` (`005-monitoramento-iot-quedas`) | **Date**: 2026-11-09 | **Spec**: [spec.md](spec.md)

**Input**: Finalizar todas as pendências remanescentes do Módulo IoT de Monitoramento e Detecção de Quedas (Feature 005 / Issue #43) e substituir o acionamento de emergência por SMS pelo envio via WhatsApp com mensagem pré-pronta.

---

## Summary

Esta atualização final do plano técnico consolida o fechamento de 100% da **Feature 005** e da **Issue #43**, unindo a arquitetura do **hardware ESP32 físico** (`ESP32 DevKit` + `MPU6050/9250/9255` + `PulseSensorPlayground`) com:

1. **Acionamento de Socorro via WhatsApp com Mensagem Pré-Pronta (`DispararSocorroEmergencia`)**:
   - Substituição do redirecionamento padrão para o app de SMS (`smsto:`) pelo acionamento direto do **WhatsApp** via `AndroidIntent` (`action_view`, `data: whatsapp://send?phone=55<numero>&text=<mensagem_codificada>`, `package: com.whatsapp`).
   - Normalização automática do telefone do `ContatoEmergencia` com adição do DDI `55` quando o número possuir 10 ou 11 dígitos locais (DDD + telefone), abrindo diretamente a conversa do contato com o alerta de queda e a cláusula antigolpe já preenchidos no campo de mensagem.
   - Fallback resiliente em cascata: caso o pacote `com.whatsapp` não esteja instalado no aparelho, tenta abrir `https://wa.me/55<numero>?text=<mensagem>` ou aciona o SMS (`smsto:`) e o discador nativo (`tel:`).
   - Declaração do esquema `whatsapp` na seção `<queries>` do `AndroidManifest.xml`.

2. **Privacidade e Limpeza de Sessão do Contato de Emergência (`FR-021`, `FR-026`, `FR-048` e Issue #43)**:
   - Implementação da interface `DadoLocalDaPessoa` (`app/lib/services/seguranca/limpeza_de_sessao.dart`) em `RepositorioContatoEmergenciaLocal`, delegando `apagar()` para `removerContato()`.
   - Registro de `RepositorioContatoEmergenciaLocal(preferencias)` na lista `dadosLocais` de `LimpezaDeSessao` dentro de `Composicao.resolver` (`app/lib/services/ambiente/composicao.dart`), garantindo que os dados pessoais do contato de emergência sejam removidos do aparelho sempre que a pessoa sair da conta.

3. **Remoção de Tráfego HTTP em Texto Claro no Manifesto Android (`FR-022`, Issue #43 e Princípio V)**:
   - Remoção do atributo global `android:usesCleartextTraffic="true"` da tag `<application>` em `app/android/app/src/main/AndroidManifest.xml`. Como o `mqtt_client` utiliza sockets TCP/TLS nativos via `dart:io` (`Socket` / `SecureSocket`) e não a pilha HTTP do Android, a bancada de testes continua funcional sem enfraquecer a exigência de HTTPS do restante do aplicativo.

4. **Suporte a TLS (`8883`), Autenticação MQTT e Parametrização por Ambiente (`FR-022` e Issue #43)**:
   - Evolução de `ProvedorDeTelemetriaMqtt` para suportar TLS (`usarTls: bool`, ativado automaticamente quando `usarTls == true` ou `porta == 8883` com `cliente.secure = true` e `SecurityContext.defaultContext`) e credenciais opcionais (`usuario` e `senha` no `connect`).
   - Suporte a variáveis de compilação `--dart-define` (`MEMORA_MQTT_BROKER`, `MEMORA_MQTT_PORTA`, `MEMORA_MQTT_TLS`, `MEMORA_MQTT_TOPICO_BASE`, `MEMORA_MQTT_USUARIO`, `MEMORA_MQTT_SENHA`), mantendo os padrões de bancada (`broker.hivemq.com`, `1883`, `memora/iot/demonstracao-01`) como fallback para testes locais com o ESP32 físico.
   - Suporte a constantes opcionais `MQTT_USER` e `MQTT_PASS` no firmware embarcado (`firmware_wokwi.ino` e `codigo.md`).

5. **Portões de Qualidade (`8/8` em `validar_suite_cuidado.py`), Testes e Documentação**:
   - Cobertura de testes unitários para a URI do WhatsApp com DDI `55` e mensagem pré-pronta, limpeza de sessão via `DadoLocalDaPessoa.apagar()` e parâmetros de TLS/autenticação MQTT.
   - Atualização de `validar_suite_cuidado.py` (8 portões) e de `docs/relatorios/o-que-falta.md`.

---

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (aplicativo Android) · C++ / Arduino Framework (ESP32 DevKit físico)

**Primary Dependencies**:
- **App Flutter**:
  - `mqtt_client: ^10.3.3`: Cliente MQTT 3.1.1 sobre TCP (`1883`) ou TLS (`8883`) com suporte a autenticação (`usuario`/`senha`) e resolução DNS IPv4 priorizada.
  - `android_intent_plus: ^5.3.0`: Acionamento direto do WhatsApp (`whatsapp://send?phone=55...&text=...`) com mensagem pré-pronta e fallback para `wa.me` / SMS / discador nativo.
  - `shared_preferences: ^2.5.5`: Persistência local do `ContatoEmergencia` integrada ao ciclo de `LimpezaDeSessao` (`DadoLocalDaPessoa`).
  - Design System do Memora (`tokens`, `componentes`, tipografia `Atkinson Hyperlegible Next`).
- **Firmware ESP32**:
  - `Arduino.h`, `Wire.h` (I2C a 100 kHz), `WiFi.h` (Wi-Fi STA 2,4 GHz).
  - `PubSubClient.h` (cliente MQTT com buffer de 512 bytes, keep-alive 30 s, socket timeout 3 s e suporte a `MQTT_USER`/`MQTT_PASS`).
  - `PulseSensorPlayground.h` (leitura óptica PPG no `GPIO 34` / `ADC1` em 10 bits a 500 Hz).

**Storage**:
- Armazenamento local (`SharedPreferences`) para o `ContatoEmergencia`, limpo automaticamente no logout via `LimpezaDeSessao` (`DadoLocalDaPessoa`).

**Testing**:
- `flutter_test` cobrindo parsing dos payloads JSON do ESP32 físico, formatação da URI do WhatsApp (`whatsapp://send`), limpeza de sessão do contato de emergência, configuração TLS/auth do provedor MQTT e matriz de acessibilidade.
- `python specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py` (8 portões de validação).

**Target Platform**: Android (aparelhos físicos e emuladores de 320×568 até 390×844) + Hardware ESP32 DevKit v1 (30/38 pinos).

**Project Type**: Mobile App (Flutter) + Firmware Embarcado IoT (ESP32 Físico).

**Performance Goals**:
- Taxa de publicação de telemetria MQTT: `500 ms` (`2 Hz`), latência de rede < `500 ms`.
- Amostragem inercial do MPU: ~`100 Hz`; amostragem PPG: `500 Hz`.
- Resposta ao toque em "Estou bem" (cessação da vibração local + publicação de `CESSAR_ALARME`): < `300 ms`.
- Zero estouro de layout (overflow) em até `200%` de escala de fonte.

**Constraints**:
- Conformidade estrita com a Constituição do Memora (WCAG 2.2 AA/AAA, piso de `16 sp`, alvos ≥ `48x48 dp` / `56 dp` para decisões, zero valores visuais literais fora dos tokens).
- Cláusula antigolpe obrigatória na mensagem pré-pronta do WhatsApp e no fallback SMS.
- Proibição de `android:usesCleartextTraffic="true"` no `AndroidManifest.xml`.
- Código, entidades, testes e documentação 100% em Português Brasileiro.

---

## Constitution Check

*GATE: avaliado antes da Phase 0 e reavaliado após a Phase 1.*

| Princípio | Situação | Como este plano cumpre |
|---|---|---|
| **I — Segurança acima de tudo** | ✅ | Remove `usesCleartextTraffic="true"` do manifesto Android, adiciona suporte a TLS (`8883`) e autenticação no MQTT, e apaga o contato de emergência na saída da sessão (`DadoLocalDaPessoa`). |
| **II — Engenharia social** | ✅ | A mensagem pré-pronta aberta no WhatsApp contém a cláusula inegociável: *"O Memora NUNCA solicita dinheiro, transferências ou senhas"*. |
| **III — Acessibilidade** | ✅ | Piso tipográfico de 16 sp, botões de decisão de 56 dp, abertura direta da conversa do contato no WhatsApp com o texto já digitado, zero overflow em 200%. |
| **IV — Spec antes de código** | ✅ | Especificação, pesquisa técnica, modelo de dados, contratos e guia de validação atualizados antes da implementação. |
| **V — Arquitetura limpa, feature-first** | ✅ | Evoluções isoladas em `app/lib/features/cuidado/` e integração limpa com `LimpezaDeSessao` em `composicao.dart`. |
| **VI — A IA nunca age sozinha** | ✅ | O protocolo de verificação de 45 segundos dá controle prioritário ao idoso antes de abrir o WhatsApp com a mensagem pré-pronta. |
| **VII — Ensinar, não substituir** | ✅ | A interface informa claramente que o alerta abrirá o WhatsApp com a mensagem pronta para o contato de confiança. |

---

## Project Structure

### Documentation (this feature)

```text
specs/005-monitoramento-iot-quedas/
├── spec.md                     # Especificação da feature (FR-001 a FR-022)
├── checklists/
│   └── requirements.md         # Checklist de qualidade (16/16)
├── plan.md                     # Este plano de implementação
├── research.md                 # Decisões técnicas (R1 a R7: ESP32, WhatsApp, TLS e LimpezaDeSessao)
├── data-model.md               # Entidades de domínio e ciclo de limpeza local
├── quickstart.md               # Roteiro de validação (8 portões + cenários V1 a V6)
├── contracts/
│   ├── telemetria-mqtt.md      # Tópicos, parâmetros TLS/auth e schemas JSON do ESP32
│   └── acao-emergencia.md      # Contrato de acionamento via WhatsApp pré-pronto + fallback
├── firmware_wokwi.ino          # Firmware C++ do ESP32 físico (MPU + PulseSensor + MQTT auth)
├── codigo.md                   # Espelho documentado do firmware físico do ESP32
└── validar_suite_cuidado.py    # Suíte automatizada de verificação (8 portões)
```

### Source Code Layout

```text
app/lib/
├── features/cuidado/
│   ├── domain/
│   │   ├── entidades/
│   │   │   ├── enums_cuidado.dart
│   │   │   ├── dispositivo_cuidado.dart
│   │   │   ├── telemetria_iot.dart
│   │   │   ├── evento_queda.dart
│   │   │   └── contato_emergencia.dart
│   │   ├── repositorios/
│   │   │   ├── repositorio_contato_emergencia.dart
│   │   │   └── provedor_telemetria.dart
│   │   └── casos_de_uso/
│   │       └── disparar_socorro_emergencia.dart
│   ├── data/
│   │   ├── provedores/
│   │   │   ├── provedor_telemetria_mqtt.dart
│   │   │   └── provedor_telemetria_simulado.dart
│   │   └── repositorios/
│   │       └── repositorio_contato_emergencia_local.dart
│   └── presentation/
│       ├── controladores/
│       │   ├── controlador_dispositivo_cuidado.dart
│       │   └── controlador_verificacao_queda.dart
│       ├── telas/
│       │   ├── tela_dispositivo_cuidado.dart
│       │   ├── tela_verificacao_queda.dart
│       │   └── dialogo_contato_emergencia.dart
│       └── widgets/
│           ├── medidor_bpm.dart
│           ├── indicador_movimento.dart
│           └── cronometro_regressivo_queda.dart
└── services/ambiente/
    └── composicao.dart         # Registra RepositorioContatoEmergenciaLocal em LimpezaDeSessao
```

---

## Complexity Tracking

*Nenhuma violação constitucional a justificar.*
