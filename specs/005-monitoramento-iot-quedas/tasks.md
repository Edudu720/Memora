---
description: "Task list — 005 Monitoramento IoT e Alerta de Quedas (Hardware ESP32 Físico, Socorro via WhatsApp e Fechamento da Issue #43)"
---

# Tasks: 005 — Monitoramento IoT e Alerta de Quedas (ESP32 Físico, WhatsApp & Issue #43)

**Input**: Documentos de design em `specs/005-monitoramento-iot-quedas/`  
**Prerequisites**: [plan.md](plan.md) (obrigatório), [spec.md](spec.md) (obrigatório para user stories), [research.md](research.md), [data-model.md](data-model.md), [contracts/acao-emergencia.md](contracts/acao-emergencia.md), [contracts/telemetria-mqtt.md](contracts/telemetria-mqtt.md), [quickstart.md](quickstart.md)  
**Tests**: **Obrigatórios**. Toda tela deve ser validada na matriz de 4 aparelhos × 3 escalas × 3 temas (`app/test/suporte/aparelhos.dart`), com zero overflow em 200%, além da suíte Python `specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py` (8/8 portões) e `flutter analyze` zerado.

**Organization**: As tarefas estão agrupadas por fase e história de usuário (US1 a US4) para permitir implementação e validação independentes. As tarefas já entregues nas fases anteriores (`T001` a `T025`) estão marcadas com `[x]`, e as novas tarefas de fechamento definitivo (`T026` a `T038` — WhatsApp pré-pronto + Issue #43) estão abertas com `[ ]`.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Pode ser executado em paralelo (arquivos distintos, sem dependências bloqueantes)
- **[Story]**: Rótulo da User Story (`[US1]`, `[US2]`, `[US3]`, `[US4]`) — usado apenas nas fases de User Story
- Caminhos exatos de arquivos incluídos em todas as descrições

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Inicialização de dependências, segurança de manifesto Android (`queries` do WhatsApp e remoção de `usesCleartextTraffic`) e atualização do firmware embarcado do ESP32 físico.

- [x] T001 Adicionar dependência `mqtt_client: ^10.3.3` em `app/pubspec.yaml`
- [x] T002 Configurar permissões `INTERNET`, `VIBRATE`, `usesCleartextTraffic="true"` e `<queries>` (`DIAL` / `SENDTO`) em `app/android/app/src/main/AndroidManifest.xml`
- [x] T003 Criar estrutura de diretórios `domain/`, `data/` e `presentation/` em `app/lib/features/cuidado/`
- [x] T004 Atualizar o código-fonte do firmware embarcado com o sketch do ESP32 físico (`MPU6050/MPU9250/MPU9255` autocalibrado com 300 amostras, `PulseSensorPlayground` no `GPIO 34` em 10 bits a 500 Hz, 6 estados com janela pós-impacto de 3000 ms, sem LEDs/buzzer e ClientID por MAC) em `specs/005-monitoramento-iot-quedas/firmware_wokwi.ino` e `specs/005-monitoramento-iot-quedas/codigo.md`
- [x] T026 Remover o atributo global `android:usesCleartextTraffic="true"` da tag `<application>` e adicionar a `<intent>` de consulta ao esquema `whatsapp` dentro de `<queries>` em `app/android/app/src/main/AndroidManifest.xml`
- [x] T027 [P] Adicionar constantes opcionais `MQTT_USER` e `MQTT_PASS` com suporte a `mqttClient.connect(clientId.c_str(), MQTT_USER, MQTT_PASS)` no firmware embarcado em `specs/005-monitoramento-iot-quedas/firmware_wokwi.ino` e `specs/005-monitoramento-iot-quedas/codigo.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Entidades de domínio, contratos de repositório, limpeza de sessão (`DadoLocalDaPessoa`) e suporte a TLS/autenticação no provedor MQTT.

**⚠️ CRITICAL**: As atualizações de `ContatoEmergencia`, `RepositorioContatoEmergenciaLocal` e `ProvedorDeTelemetriaMqtt` sustentam a segurança e o acionamento via WhatsApp das User Stories.

- [x] T005 [P] Criar enums `StatusConexaoIot` (`desconectado`, `conectando`, `conectado`), `StatusConfirmacaoQueda` (`aguardandoConfirmacao`, `canceladoPeloUsuario`, `socorroAcionado`, `tempoExpirado`) e `ModoOperacaoIot` (`simulado`, `mqtt`) em `app/lib/features/cuidado/domain/entidades/enums_cuidado.dart`
- [x] T006 [P] Criar entidade `DispositivoCuidado` e `ContatoEmergencia` (com validação de 10 ou 11 dígitos nacionais com DDD e remoção de prefixo `+55` em `telefoneNumeros`) em `app/lib/features/cuidado/domain/entidades/dispositivo_cuidado.dart` e `app/lib/features/cuidado/domain/entidades/contato_emergencia.dart`
- [x] T007 [P] Criar interfaces `ProvedorDeTelemetria` e `RepositorioContatoEmergencia` em `app/lib/features/cuidado/domain/repositorios/provedor_telemetria.dart` e `app/lib/features/cuidado/domain/repositorios/repositorio_contato_emergencia.dart`
- [x] T008 [P] Implementar `ProvedorDeTelemetriaSimulado`, `ProvedorDeTelemetriaMqtt` (MQTT 3.1.1 + resolução DNS IPv4) e `RepositorioContatoEmergenciaLocal` em `app/lib/features/cuidado/data/`
- [x] T009 [P] Atualizar a entidade `TelemetriaIot` em `app/lib/features/cuidado/domain/entidades/telemetria_iot.dart` para incluir o campo `bpmValido` (`bool`, lido da chave JSON `bpm_valido` com fallback `bpmLido > 0`), suportar os 6 valores de `estadoSensor` (`"INERTE"`, `"EM_MOVIMENTO"`, `"QUEDA_LIVRE"`, `"AGUARDANDO_IMPACTO"`, `"POS_IMPACTO"`, `"QUEDA_DETECTADA"`) e normalizar `timestamp` para `DateTime.now()` quando o inteiro recebido vier de `millis()` do microcontrolador (`< 1000000000000`)
- [x] T010 [P] Atualizar a entidade `EventoQueda` em `app/lib/features/cuidado/domain/entidades/evento_queda.dart` para incluir os campos `bpmValido` (`bool`, chave JSON `bpm_valido`), `bpmAntesDaQueda` (`int`, chave JSON `bpm_antes_da_queda`, padrão `-1`) e `movimentoPosImpacto` (`double`, chave JSON `movimento_pos_impacto`, padrão `0.0`), usando `bpmAntesDaQueda` como fallback para `bpmNoImpacto` quando `bpm <= 0` e `bpm_antes_da_queda > 0`, além de normalizar `timestamp` oriundo de `millis()` (`< 1000000000000`)
- [x] T011 Atualizar testes unitários de domínio em `app/test/features/cuidado/domain/entidades_test.dart` cobrindo o parsing exato dos novos payloads JSON do ESP32 físico (`bpm_valido`, `bpm_antes_da_queda`, `movimento_pos_impacto`, estado `"EM_MOVIMENTO"` e `"QUEDA_DETECTADA"`, fallback de BPM pré-queda e normalização de `millis()`)
- [x] T028 [P] Adicionar getter `telefoneWhatsapp` (retornando `telefoneNumeros` com prefixo DDI `'55'` adicionado automaticamente quando tiver 10 ou 11 dígitos nacionais) na entidade `ContatoEmergencia` em `app/lib/features/cuidado/domain/entidades/contato_emergencia.dart`
- [x] T029 [P] Implementar a interface `DadoLocalDaPessoa` (delegando `apagar()` para `removerContato()`) em `RepositorioContatoEmergenciaLocal` no arquivo `app/lib/features/cuidado/data/repositorios/repositorio_contato_emergencia_local.dart` e registrá-lo na lista `dadosLocais` de `LimpezaDeSessao` em `app/lib/services/ambiente/composicao.dart`
- [x] T030 [P] Evoluir `ProvedorDeTelemetriaMqtt` para suportar conexão TLS (`usarTls: bool`, ativado automaticamente quando `usarTls == true` ou `porta == 8883` com `cliente.secure = true` e `SecurityContext.defaultContext`), credenciais opcionais (`usuario` e `senha` via `connect(usuario, senha)`) e leitura padrão via `--dart-define` (`MEMORA_MQTT_BROKER`, `MEMORA_MQTT_PORTA`, `MEMORA_MQTT_TLS`, `MEMORA_MQTT_TOPICO_BASE`, `MEMORA_MQTT_USUARIO`, `MEMORA_MQTT_SENHA`) em `app/lib/features/cuidado/data/provedores/provedor_telemetria_mqtt.dart`

**Checkpoint**: Fundação de domínio, privacidade de sessão (`FR-021`) e segurança MQTT (`FR-022`) pronta.

---

## Phase 3: User Story 1 - Acompanhar o Dispositivo de Cuidado no Aplicativo (Priority: P1) 🎯 MVP

**Goal**: Permitir que a pessoa idosa visualize o estado de conexão com o Dispositivo ESP32, sua frequência cardíaca real medida pelo Pulse Sensor óptico (com orientação quando o dedo não estiver posicionado) e seu estado de movimentação em tempo real.

**Independent Test**: Abrir a `TelaDispositivoCuidado` e verificar a exibição do status de conexão, do cartão `MedidorBpm` (com BPM válido ou aviso de posicionamento do dedo quando `bpm <= 0`) e do `IndicadorMovimento` sem rolagem nos 3 temas e até 200% de escala.

### Implementation for User Story 1

- [x] T012 [P] [US1] Implementar `IndicadorMovimento` em `app/lib/features/cuidado/presentation/widgets/indicador_movimento.dart` e `ControladorDispositivoCuidado` em `app/lib/features/cuidado/presentation/controladores/controlador_dispositivo_cuidado.dart`
- [x] T013 [US1] Integrar a porta `'Dispositivo de Cuidado'` no Hub principal em `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`
- [x] T014 [P] [US1] Atualizar `MedidorBpm` em `app/lib/features/cuidado/presentation/widgets/medidor_bpm.dart` para aceitar `bpmValido` (`bool`, opcional com padrão `true`) e exibir `--` com orientação acessível quando o Pulse Sensor óptico estiver sem leitura válida (`!bpmValido || bpm <= 0`)
- [x] T015 [US1] Repassar `bpmValido: telemetria?.bpmValido ?? false` ao `MedidorBpm` na `TelaDispositivoCuidado` em `app/lib/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart`

**Checkpoint**: User Story 1 completa e validada.

---

## Phase 4: User Story 2 - Verificação Imediata de Queda ("Você está bem?") (Priority: P1)

**Goal**: Exibir imediatamente a tela de verificação de bem-estar com contagem regressiva de 45 segundos ao receber o alerta de queda confirmada pós-impacto do ESP32 físico, permitindo encerrar o evento com *"Estou bem"* (enviando `CESSAR_ALARME` para destravar o estado `QUEDA_DETECTADA` no ESP32) ou acionar socorro imediato com *"Preciso de ajuda"*.

**Independent Test**: Emitir um payload de alerta do ESP32 físico no tópico `/alerta`, verificar a abertura imediata da `TelaVerificacaoQueda`, e confirmar que o toque em *"Estou bem"* publica `{"comando":"CESSAR_ALARME"}` no tópico `/comando` e fecha a tela.

### Implementation for User Story 2

- [x] T016 [P] [US2] Implementar `CronometroRegressivoQueda` em `app/lib/features/cuidado/presentation/widgets/cronometro_regressivo_queda.dart` e `ControladorVerificacaoQueda` em `app/lib/features/cuidado/presentation/controladores/controlador_verificacao_queda.dart`
- [x] T017 [US2] Implementar `TelaVerificacaoQueda` em `app/lib/features/cuidado/presentation/telas/tela_verificacao_queda.dart` e testes na matriz de aparelhos em `app/test/features/cuidado/presentation/tela_verificacao_queda_test.dart`
- [x] T018 [US2] Validar em `app/test/features/cuidado/data/provedores_test.dart` o fluxo de recebimento do payload de alerta do ESP32 físico (`evento: "QUEDA_DETECTADA"`, `bpm_antes_da_queda`, `movimento_pos_impacto`) e envio do comando `{"comando":"CESSAR_ALARME"}`

**Checkpoint**: User Story 2 completa e validada.

---

## Phase 5: User Story 3 - Cadastro e Disparo para Contato de Emergência via WhatsApp (Priority: P2)

**Goal**: Permitir o cadastro de um contato de confiança com DDD e abrir prioritariamente a conversa do contato no **WhatsApp** (`whatsapp://send?phone=55<numero>&text=<mensagem>`) com a mensagem de socorro e a cláusula antigolpe já preenchidas caso o cronômetro de 45 segundos expire ou a pessoa toque em *"Preciso de ajuda"*, mantendo fallback para `https://wa.me/`, SMS (`smsto:`) e discador (`tel:`).

**Independent Test**: Cadastrar um contato no `DialogoContatoEmergencia`, simular o disparo de emergência e verificar a geração da URI `whatsapp://send?phone=55...&text=...` com o texto padronizado e cláusula antigolpe.

### Implementation for User Story 3

- [x] T019 [P] [US3] Implementar `DispararSocorroEmergencia` em `app/lib/features/cuidado/domain/casos_de_uso/disparar_socorro_emergencia.dart` e `DialogoContatoEmergencia` em `app/lib/features/cuidado/presentation/telas/dialogo_contato_emergencia.dart`
- [x] T031 [US3] Atualizar `DispararSocorroEmergencia` em `app/lib/features/cuidado/domain/casos_de_uso/disparar_socorro_emergencia.dart` para construir a URI `whatsapp://send?phone=<telefoneWhatsapp>&text=<mensagem_codificada>` (expondo os métodos estáticos `formatarMensagemSocorro` e `formatarUriWhatsapp`), acionar prioritariamente o pacote `com.whatsapp` via `android.intent.action.VIEW` e executar fallback em cascata para `https://wa.me/` e SMS/Discador nativo (`smsto:` / `tel:`) caso o WhatsApp não esteja instalado
- [x] T032 [P] [US3] Atualizar os textos informativos do `DialogoContatoEmergencia` e da `TelaDispositivoCuidado` para explicitar o envio de mensagem pré-pronta pelo WhatsApp em `app/lib/features/cuidado/presentation/telas/dialogo_contato_emergencia.dart` e `app/lib/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart`
- [x] T033 [US3] Adicionar testes unitários em `app/test/features/cuidado/domain/entidades_test.dart` validando `ContatoEmergencia.telefoneWhatsapp`, `DispararSocorroEmergencia.formatarMensagemSocorro` (incluindo cláusula antigolpe) e `DispararSocorroEmergencia.formatarUriWhatsapp` (`whatsapp://send?phone=55...&text=...`)
- [x] T034 [P] [US3] Adicionar testes unitários em `app/test/features/cuidado/data/provedores_test.dart` validando `RepositorioContatoEmergenciaLocal.apagar()` (`DadoLocalDaPessoa`) e a configuração de TLS (`porta: 8883`, `usarTls: true`) e autenticação (`usuario`/`senha`) no `ProvedorDeTelemetriaMqtt`

**Checkpoint**: User Story 3 atualizada com acionamento via WhatsApp pré-pronto e testes de segurança/privacidade.

---

## Phase 6: User Story 4 - Modo de Conexão ESP32 Físico e Simulador de Testes (Priority: P2)

**Goal**: Permitir alternar na `TelaDispositivoCuidado` entre a conexão real com o **Dispositivo ESP32 (MQTT)** e o **Simulador** local para testes em sala de aula ou sem a placa física ligada, removendo a nomenclatura antiga do Wokwi.

**Independent Test**: Abrir a seção expansível de conexão e testes na `TelaDispositivoCuidado`, verificar os novos rótulos (`Dispositivo ESP32 (MQTT)`, `Conexão ESP32 & Testes`, `ESP32 Ativo` / `Usar ESP32`, `Reconectar ao ESP32`) e validar na matriz de 4 aparelhos × 3 escalas × 3 temas sem overflow.

### Implementation for User Story 4

- [x] T020 [P] [US4] Implementar painel expansível de configuração de broker/tópico MQTT e botão de simulação de queda em `app/lib/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart`
- [x] T021 [US4] Atualizar a nomenclatura visual na `TelaDispositivoCuidado` em `app/lib/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart`, substituindo `'Wokwi / MQTT'` por `'Dispositivo ESP32 (MQTT)'`, `'Integração Wokwi & Testes'` por `'Conexão ESP32 & Testes'`, `'Wokwi Ativo'`/`'Usar Wokwi'` por `'ESP32 Ativo'`/`'Usar ESP32'` e `'Reconectar ao Wokwi'` por `'Reconectar ao ESP32'`
- [x] T022 [US4] Atualizar os testes de widget em `app/test/features/cuidado/presentation/tela_dispositivo_cuidado_test.dart` para refletir os novos rótulos do ESP32 físico e validar a matriz de aparelhos e escalas até 200%

**Checkpoint**: Todas as User Stories (US1 a US4) concluídas.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Atualização da suíte automatizada de verificação (8 portões), documentação de fechamento e execução de todos os portões de qualidade da Constituição Memora.

- [x] T023 Atualizar o script `specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py` para validar o novo firmware do ESP32 físico (`PULSE_PIN 34`, `PulseSensorPlayground`, `MPU_ADDR_1 0x68`, `calibrarMPU`, 6 estados incluindo `EM_MOVIMENTO` e `QUEDA_DETECTADA`, e campos JSON `bpm_valido`, `bpm_antes_da_queda` e `movimento_pos_impacto`)
- [x] T024 [P] Executar `python specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py` garantindo 7/7 verificações aprovadas (incluindo `validar_paleta.py` e `validar_tokens.py`)
- [x] T025 [P] Executar `flutter analyze` e `flutter test test/features/cuidado/` em `app/` garantindo 0 avisos/erros de lint e 100% dos testes passando
- [x] T035 Atualizar `specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py` adicionando o 8º portão de verificação (`verificar_seguranca_e_whatsapp`: ausência de `usesCleartextTraffic="true"` no `AndroidManifest.xml`, implementação de `DadoLocalDaPessoa` em `RepositorioContatoEmergenciaLocal`, suporte a TLS/autenticação em `ProvedorDeTelemetriaMqtt` e URI `whatsapp://send` em `DispararSocorroEmergencia`)
- [x] T036 [P] Atualizar `docs/relatorios/o-que-falta.md` registrando a conclusão de 100% da Feature 005 e o fechamento da Issue #43
- [x] T037 [P] Executar `python specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py` garantindo 8/8 verificações aprovadas
- [x] T038 [P] Executar `flutter analyze` e `flutter test test/features/cuidado/` em `app/` garantindo 0 avisos/erros de lint e 100% dos testes aprovados

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: `T026` (`AndroidManifest.xml`) e `T027` (`firmware_wokwi.ino` / `codigo.md`) não possuem dependências bloqueantes e podem iniciar imediatamente.
- **Foundational (Phase 2)**: `T028` (`contato_emergencia.dart`), `T029` (`repositorio_contato_emergencia_local.dart` + `composicao.dart`) e `T030` (`provedor_telemetria_mqtt.dart`) tocam arquivos distintos e podem ser executados em paralelo (`[P]`).
- **User Story 3 (Phase 5)**:
  - `T031` (`disparar_socorro_emergencia.dart`) depende de `T028` (`ContatoEmergencia.telefoneWhatsapp`).
  - `T032` (`dialogo_contato_emergencia.dart` e `tela_dispositivo_cuidado.dart`) pode rodar em paralelo (`[P]`) com `T031`.
  - `T033` (`entidades_test.dart`) depende de `T028` e `T031`.
  - `T034` (`provedores_test.dart`) depende de `T029` e `T030`.
- **Polish (Phase 7)**: `T035`, `T036`, `T037` e `T038` certificam todo o conjunto após a conclusão das fases anteriores.

### Parallel Opportunities

- `T026`, `T027`, `T028`, `T029` e `T030` operam em arquivos independentes e podem rodar simultaneamente (`[P]`).
- `T031` e `T032` podem rodar em paralelo (`[P]`).
- `T033` e `T034` podem rodar em paralelo (`[P]`) após suas respectivas implementações.

---

## Parallel Example: Foundational & US3

```bash
# Executar em paralelo as evoluções de infraestrutura e fundação:
Task T026: "Remover usesCleartextTraffic e adicionar query whatsapp em app/android/app/src/main/AndroidManifest.xml"
Task T028: "Adicionar telefoneWhatsapp em app/lib/features/cuidado/domain/entidades/contato_emergencia.dart"
Task T029: "Implementar DadoLocalDaPessoa em RepositorioContatoEmergenciaLocal e registrar em composicao.dart"
Task T030: "Adicionar suporte a TLS (8883) e autenticacao em ProvedorDeTelemetriaMqtt"
```

---

## Implementation Strategy

### Incremental Delivery

1. Concluir **Phase 1 (`T026–T027`)** e **Phase 2 (`T028–T030`)** para fechar todos os itens de segurança e privacidade da Issue #43 (`usesCleartextTraffic`, `DadoLocalDaPessoa`, TLS/auth MQTT e normalização do telefone WhatsApp).
2. Concluir **Phase 5 (`T031–T034`)** para substituir o envio de SMS pelo acionamento prioritário do **WhatsApp com mensagem pré-pronta** e validar em testes unitários.
3. Concluir **Phase 7 (`T035–T038`)** para atualizar o validador (`8/8` portões), atualizar o relatório `o-que-falta.md` e certificar `flutter analyze` e `flutter test`.
