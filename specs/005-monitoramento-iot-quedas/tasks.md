---
description: "Task list — 005 Monitoramento IoT e Alerta de Quedas"
---

# Tasks: 005 — Monitoramento IoT e Alerta de Quedas

**Input**: Documentos de design em `specs/005-monitoramento-iot-quedas/`  
**Prerequisites**: [spec.md](spec.md) · [plan.md](plan.md) · [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md)  
**Tests**: **Obrigatórios**. Toda tela deve ser validada na matriz de 4 aparelhos × 3 escalas × 3 temas (`test/suporte/aparelhos.dart`), com zero overflow em 200%.

## Formato: `[ID] [P?] [Story] Descrição`
- **[P]**: Pode ser executado em paralelo (arquivos distintos, sem dependência mútua)
- **[Story]**: História de usuário correspondente (US1, US2, US3, US4, Fundacao)

---

## Phase 1: Setup e Infraestrutura

- [ ] T001 [Setup] Adicionar dependência `mqtt_client: ^10.3.3` em `app/pubspec.yaml` e executar `flutter pub get`.
- [ ] T002 [Setup] Configurar permissões de rede e intenções de discador em `app/android/app/src/main/AndroidManifest.xml` (`<queries>` para `android.intent.action.DIAL`).
- [ ] T003 [Setup] Criar diretório base do módulo em `app/lib/features/cuidado/` com as camadas `domain`, `data`, `presentation`.

---

## Phase 2: Fundação de Domínio e Dados

- [ ] T004 [P] [Fundacao] Criar entidades de domínio em `app/lib/features/cuidado/domain/entidades/`:
  - `dispositivo_cuidado.dart`
  - `telemetria_iot.dart`
  - `evento_queda.dart`
  - `contato_emergencia.dart`
- [ ] T005 [P] [Fundacao] Criar enums de domínio em `app/lib/features/cuidado/domain/entidades/enums_cuidado.dart`:
  - `StatusConexaoIot` (`desconectado`, `conectando`, `conectado`)
  - `StatusConfirmacaoQueda` (`aguardandoConfirmacao`, `canceladoPeloUsuario`, `socorroAcionado`, `tempoExpirado`)
  - `ModoOperacaoIot` (`simulado`, `mqtt`)
- [ ] T006 [Fundacao] Criar contratos de repositório e provedor em `app/lib/features/cuidado/domain/repositorios/`:
  - `provedor_telemetria.dart` (Streams de `TelemetriaIot` e `EventoQueda`, método `enviarComandoCessarAlarme`)
  - `repositorio_contato_emergencia.dart` (salvar, obter, validar contato)
- [ ] T007 [Fundacao] Testes unitários das entidades e regras de validação em `app/test/features/cuidado/domain/entidades_test.dart`.

---

## Phase 3: Provedores de Telemetria (Simulado e MQTT)

- [ ] T008 [P] [Fundacao] Implementar `ProvedorDeTelemetriaSimulado` em `app/lib/features/cuidado/data/provedores/provedor_telemetria_simulado.dart` com métodos para gerar batimentos normais, variar movimento e injetar evento de queda artificialmente.
- [ ] T009 [P] [Fundacao] Implementar `ProvedorDeTelemetriaMqtt` em `app/lib/features/cuidado/data/provedores/provedor_telemetria_mqtt.dart` conectando ao broker (ex.: `broker.hivemq.com`), assinando telemetria e alertas, e publicando comandos de cessação de alarme.
- [ ] T010 [Fundacao] Implementar `RepositorioContatoEmergenciaLocal` em `app/lib/features/cuidado/data/repositorios/repositorio_contato_emergencia_local.dart` persistindo nome e telefone via `shared_preferences`.
- [ ] T011 [Fundacao] Testes unitários dos provedores de telemetria e repositório local em `app/test/features/cuidado/data/provedores_test.dart`.

---

## Phase 4: US1 — Acompanhar o Dispositivo de Cuidado no Aplicativo (P1)

- [ ] T012 [P] [US1] Criar componente `MedidorBpm` em `app/lib/features/cuidado/presentation/widgets/medidor_bpm.dart` exibindo o valor em fonte Atkinson destacada, ícone de pulsação e rótulo acessível.
- [ ] T013 [P] [US1] Criar componente `IndicadorMovimento` em `app/lib/features/cuidado/presentation/widgets/indicador_movimento.dart` exibindo se a pessoa está em movimento ou em repouso de forma calma e acolhedora.
- [ ] T014 [US1] Criar `ControladorDispositivoCuidado` em `app/lib/features/cuidado/presentation/controladores/controlador_dispositivo_cuidado.dart` escutando a telemetria e expondo o estado para a tela.
- [ ] T015 [US1] Implementar `TelaDispositivoCuidado` em `app/lib/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart` com status de conexão, medidores e botão para abrir configurações/testes.
- [ ] T016 [US1] Integrar o atalho para a tela do Dispositivo de Cuidado no Hub (`TelaHub`) e no Início (`TelaInicio`).
- [ ] T017 [US1] Testes de widget da `TelaDispositivoCuidado` na matriz de 4 aparelhos × 3 escalas em `app/test/features/cuidado/presentation/tela_dispositivo_cuidado_test.dart`.

---

## Phase 5: US2 — Verificação Imediata de Queda ("Você está bem?") (P1)

- [ ] T018 [P] [US2] Criar componente `CronometroRegressivoQueda` em `app/lib/features/cuidado/presentation/widgets/cronometro_regressivo_queda.dart` com contagem regressiva de 45 segundos em algarismos grandes e claros.
- [ ] T019 [US2] Criar `ControladorVerificacaoQueda` em `app/lib/features/cuidado/presentation/controladores/controlador_verificacao_queda.dart` gerenciando o temporizador de 45 s, vibração contínua e disparo de callbacks ("Estou bem" vs "Preciso de ajuda" / timeout).
- [ ] T020 [US2] Implementar `TelaVerificacaoQueda` em `app/lib/features/cuidado/presentation/telas/tela_verificacao_queda.dart`:
  - Pergunta central destacada *"Você está bem?"*
  - Botão grande *"Estou bem"* (cessa alarme imediatamente e fecha tela)
  - Botão grande de perigo *"Preciso de ajuda"* (escala para emergência)
  - Cronômetro visível com aviso explicativo
- [ ] T021 [US2] Integrar o disparo da `TelaVerificacaoQueda` no aplicativo quando o `Stream<EventoQueda>` emitir um novo evento.
- [ ] T022 [US2] Testes unitários do temporizador e fluxo de cancelamento em `app/test/features/cuidado/presentation/controlador_verificacao_queda_test.dart`.
- [ ] T023 [US2] Testes de layout da `TelaVerificacaoQueda` na matriz de aparelhos (320x568 até 390x844 em 100%, 150%, 200%) em `app/test/features/cuidado/presentation/tela_verificacao_queda_test.dart`.

---

## Phase 6: US3 — Cadastro e Disparo para Contato de Emergência (P2)

- [ ] T024 [P] [US3] Implementar caso de uso `DispararSocorroEmergencia` em `app/lib/features/cuidado/domain/casos_de_uso/disparar_socorro_emergencia.dart` acionando discador (`ACTION_DIAL`) e preparando SMS nativo com texto padrão antigolpe.
- [ ] T025 [P] [US3] Implementar `DialogoContatoEmergencia` em `app/lib/features/cuidado/presentation/telas/dialogo_contato_emergencia.dart` permitindo cadastrar nome e telefone com validação de formato e confirmação explícita.
- [ ] T026 [US3] Conectar o caso de uso `DispararSocorroEmergencia` ao término do cronômetro de 45 s ou ao clique em *"Preciso de ajuda"*.
- [ ] T027 [US3] Testes de widget do diálogo e simulação de disparo em `app/test/features/cuidado/presentation/dialogo_contato_emergencia_test.dart`.

---

## Phase 7: US4 — Modo de Teste e Integração com Wokwi (P2)

- [ ] T028 [P] [US4] Implementar painel de testes/simulador na `TelaDispositivoCuidado` com alternância entre provedor simulado e provedor MQTT.
- [ ] T029 [P] [US4] Fornecer controles para testador: botão "Simular Queda", slider de variação de BPM e alternador de movimento.
- [ ] T030 [US4] Testar e validar a integração ao vivo com o simulador Wokwi utilizando o código [firmware_wokwi.ino](firmware_wokwi.ino).

---

## Phase 8: Validação e Portões de Qualidade

- [ ] T031 [Qualidade] Rodar `flutter analyze` e garantir zero warnings ou lints.
- [ ] T032 [Qualidade] Rodar todos os testes automatizados da feature com `flutter test test/features/cuidado/`.
- [ ] T033 [Qualidade] Executar os validadores de design system (`validar_tokens.py` e `validar_paleta.py`).
- [ ] T034 [Qualidade] Validar os cenários V1 a V6 de [quickstart.md](quickstart.md) com APK no celular ou emulador.
