# Security, WhatsApp Emergency & Physical ESP32 Requirements Checklist: 005 — Monitoramento IoT e Alerta de Quedas

**Purpose**: Validar a qualidade, completude, clareza, consistência e mensurabilidade dos requisitos de fechamento da Feature 005 (Acionamento via WhatsApp pré-pronto, Segurança/Privacidade da Issue #43, Hardware ESP32 Físico e Acessibilidade WCAG 2.2).
**Created**: 2026-11-09
**Feature**: [spec.md](../spec.md) · [plan.md](../plan.md)

**Ownership Note**: Este checklist avalia a qualidade da escrita dos requisitos ("Unit Tests for Requirements"). Marcar `[x]` significa que o revisor validou que o requisito está claramente especificado, completo e sem ambiguidades — e não que o código foi implementado. `/speckit-implement` lê este arquivo sem alterar o estado das caixas.

---

## Requirement Completeness (Completude dos Requisitos)

- [x] CHK001 Os requisitos de normalização do número de telefone para o WhatsApp (adição automática do DDI `55` para números nacionais de 10 ou 11 dígitos) estão explicitamente especificados? [Completeness, Spec §FR-020, Contract `acao-emergencia.md` §1]
- [x] CHK002 A ordem de prioridade e a cascata de fallback do acionamento de emergência (`whatsapp://send` com pacote `com.whatsapp` ➔ `https://wa.me/` ➔ SMS `smsto:` e discador `tel:`) estão integralmente documentadas? [Completeness, Spec §FR-020, Research §R6]
- [x] CHK003 O requisito de limpeza dos dados do contato de emergência ao encerrar a sessão (`DadoLocalDaPessoa` registrado em `LimpezaDeSessao`) está formalizado na especificação e no modelo de dados? [Completeness, Spec §FR-021, Data Model §3]
- [x] CHK004 Os parâmetros de configuração segura do broker MQTT (TLS na porta `8883`, flag `usarTls`, credenciais `usuario`/`senha` e variáveis `--dart-define`) estão completamente definidos nos contratos? [Completeness, Spec §FR-022, Contract `telemetria-mqtt.md` §1]
- [x] CHK005 Todos os campos dos contratos JSON de telemetria (`bpm_valido`, `estado` com 6 estágios) e de alerta de queda (`bpm_antes_da_queda`, `movimento_pos_impacto`) do ESP32 físico estão especificados com tipos e semântica de domínio? [Completeness, Data Model §1, Contract `telemetria-mqtt.md` §2-§3]

---

## Requirement Clarity (Clareza e Ausência de Ambiguidade)

- [x] CHK006 O texto padronizado da mensagem pré-pronta de socorro e a cláusula obrigatória antigolpe (Princípio II) estão redigidos de forma exata e sem termos vagos? [Clarity, Spec §FR-012, §FR-018, Contract `acao-emergencia.md` §3]
- [x] CHK007 A regra de fallback para `bpm_antes_da_queda` quando a leitura óptica no momento do impacto é inválida (`bpm <= 0` ou `bpm_valido == false`) está definida de maneira determinística? [Clarity, Research §R4, Data Model §1]
- [x] CHK008 Os limiares físicos e temporais da máquina de 6 estados do ESP32 (`< 0.55 g` por `>= 80 ms`, impacto `>= 2.5 g` em até `1000 ms`, pós-impacto de `3000 ms` com movimento médio `< 10.0`) estão quantificados com precisão? [Clarity, Plan §Summary, Research §R2]
- [x] CHK009 A distinção entre timestamps baseados em `millis()` do microcontrolador ESP32 e timestamps epoch Unix está claramente especificada para a camada de parsing? [Clarity, Research §R4, Data Model §1]

---

## Requirement Consistency (Consistência entre Artefatos)

- [x] CHK010 Os requisitos do canal de emergência em `spec.md` (`FR-020`), `plan.md`, `data-model.md`, `contracts/acao-emergencia.md` e `quickstart.md` (`V5`) estão alinhados ao priorizar o WhatsApp com mensagem pré-pronta em vez de apenas SMS? [Consistency, Spec §FR-020, Contract `acao-emergencia.md`]
- [x] CHK011 A proibição de `android:usesCleartextTraffic="true"` em `spec.md` (`FR-022`) é consistente com a operação de bancada em TCP puro (`porta 1883`) e operação segura em TLS (`porta 8883`) descrita em `research.md` (`R7`)? [Consistency, Spec §FR-022, Research §R7]
- [x] CHK012 A nomenclatura visual da interface (`ESP32 Físico` / `Dispositivo ESP32 (MQTT)`) está uniforme entre `plan.md`, `research.md` (`R5`) e `quickstart.md`? [Consistency, Plan §Summary, Research §R5]

---

## Scenario & Edge Case Coverage (Cobertura de Cenários e Casos Limite)

- [x] CHK013 Os requisitos cobrem o cenário em que o aparelho Android da pessoa idosa não possui o aplicativo WhatsApp instalado no momento da emergência? [Coverage, Edge Case, Spec §FR-020, Contract `acao-emergencia.md` §2]
- [x] CHK014 Os requisitos especificam o comportamento do sistema quando o sensor óptico PPG está conectado, mas o dedo da pessoa não está apoiado no sensor (`bpm_valido == false`)? [Coverage, Edge Case, Research §R1, Data Model §1]
- [x] CHK015 Os requisitos contemplam a retenção e o reenvio do alerta de queda (`alertaPendente`) caso a conexão Wi-Fi/MQTT oscile no exato instante da queda física? [Coverage, Recovery Flow, Research §R3, Contract `telemetria-mqtt.md` §3]
- [x] CHK016 O descarte automático de falsos positivos quando a pessoa continua se movimentando nos 3 segundos pós-impacto (`movimentoMedioPosImpacto >= 10.0`) está documentado como requisito comportamental? [Coverage, Alternate Flow, Research §R2, Quickstart §V4]

---

## Non-Functional Requirements & Measurability (Requisitos Não-Funcionais e Mensurabilidade)

- [x] CHK017 Os critérios de acessibilidade (alvos mínimos de `48x48 dp`, decisões de `56 dp`, piso tipográfico de `16 sp`, contraste WCAG 2.2 AA e escala de texto até `200%` sem overflow) são objetivamente verificáveis? [Measurability, Spec §FR-014 a §FR-017, §SC-003]
- [x] CHK018 As metas de tempo de resposta (< `1,5 s` para abrir a tela de verificação após o alerta, `45 s` de contagem regressiva e < `300 ms` para cessar o alarme ao tocar em *"Estou bem"*) estão quantificadas de forma testável? [Measurability, Spec §FR-009, §SC-001, §SC-002]
- [x] CHK019 Os requisitos de visibilidade de pacotes no Android 11+ (`<queries>` no `AndroidManifest.xml` para `com.whatsapp`, `whatsapp://`, `tel:` e `smsto:`) estão especificados para garantir que as Intents funcionem em produção? [Completeness, Non-Functional, Plan §Summary, Research §R6]
- [x] CHK020 Os 8 portões automatizados de verificação do módulo (`validar_suite_cuidado.py`) cobrem todas as restrições constitucionais e de segurança da Feature 005? [Measurability, Plan §Testing, Quickstart §2]

---

## Notes

- Todos os itens começam desmarcados (`[ ]`) para revisão da qualidade dos requisitos.
- Rastreabilidade: 20/20 itens (100%) possuem referências explícitas para seções de `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/` ou `quickstart.md`.
