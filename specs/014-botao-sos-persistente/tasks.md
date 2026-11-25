# Tasks: Feature 014 — Botão SOS Persistente

**Input**: `specs/014-botao-sos-persistente/spec.md`, `plan.md`
**Regras de UI**: `.claude/skills/memora-ux/SKILL.md` e Design System 2.0

## Phase 1: Setup e Especificação
- [X] T001 Criar branch `feature/014-botao-sos-persistente` a partir do estado atualizado (`redesign/T029-textos` / `origin/redesign-final`) e apontar `.specify/feature.json` para `specs/014-botao-sos-persistente`
- [X] T002 Registrar `specs/014-botao-sos-persistente/spec.md`, `plan.md` e `tasks.md`

## Phase 2: Backend — Emergência e Idempotência
- [X] T003 Criar migration Flyway `backend/src/main/resources/db/migration/V12__evento_emergencia_sos.sql` com tabela `evento_emergencia`, índices e retenção de localização
- [X] T004 Criar entidades de domínio `TipoEventoEmergencia`, `StatusEventoEmergencia` e `EventoEmergencia` em `br.fatec.memora.emergencia.dominio`
- [X] T005 Criar `RepositorioEventoEmergencia`, interface `NotificadorDeEmergencia`, `NotificadorDeEmergenciaEmLog` (`!producao`) e `NotificadorDeEmergenciaPorEmail` (`producao`)
- [X] T006 Criar `ServicoEmergenciaSos` com idempotência por `eventoId`, distinção `SOS_MANUAL`/`QUEDA_AUTOMATICA`, retenção de localização de 24h e registro técnico sem expor detalhes internos
- [X] T007 Criar DTOs `SolicitarSosRequest`/`SolicitarSosResponse` e `EmergenciaSosController` (`POST /v1/emergencias/sos` e `/api/v1/emergencias/sos`) autenticado
- [X] T008 Criar testes unitários e de controlador `ServicoEmergenciaSosTest` e `EmergenciaSosControllerTest` cobrindo sucesso, idempotência, erro 400/401, localização opcional e falha de entrega

## Phase 3: Frontend — Domínio, Dados, Textos e Controlador
- [X] T009 Criar `app/lib/l10n/textos_sos.dart` dentro dos limites da `memora-ux` e adicioná-lo a `texto_da_interface_test.dart`
- [X] T010 Criar entidades em `app/lib/features/cuidado/domain/entidades/evento_emergencia_sos.dart` e interface `RepositorioEmergenciaSos`
- [X] T011 Criar `RepositorioEmergenciaSosApi` (HTTP autenticado) e `RepositorioEmergenciaSosSimulado` (em memória com idempotência e simulação de falhas)
- [X] T012 Criar `ControladorSosEmergencia` reutilizando `RepositorioContatoEmergencia`, tratando localização autorizada opcional, idempotência e contingência local (`DispararSocorroEmergencia` / `tel:192`)

## Phase 4: Frontend — UI Acessível e Integração na Casca
- [X] T013 Criar widget compartilhado `BotaoSosPersistente` em `app/lib/features/cuidado/presentation/widgets/botao_sos_persistente.dart` (alvo $\ge 48 \times 48\text{ dp}$, texto explícito `"SOS Ajuda"`, contraste elevado e tokens do Design System)
- [X] T014 Criar diálogo acessível `DialogoSosEmergencia` em `app/lib/features/cuidado/presentation/telas/dialogo_sos_emergencia.dart` (confirmação simples, feedback honesto de envio/falha e alternativas sem contato ou sem internet)
- [X] T015 Integrar `BotaoSosPersistente` à `CascaInterna` (`app/lib/features/casca/casca_interna.dart`) e ao `FluxoAutenticacao` (`app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`) mantendo compatibilidade integral com as telas e testes existentes
- [X] T016 Criar `app/test/features/cuidado/presentation/botao_sos_persistente_test.dart` cobrindo persistência na navegação, alvo de toque/semântica, cancelamento, envio com/sem localização, duplicidade, falha de rede e contato ausente

## Phase 5: Validação e PR
- [X] T017 Rodar todos os portões (`validar_paleta.py`, `validar_tokens.py`, `flutter analyze`, `flutter test` completo e testes unitários Maven)
- [X] T018 Fazer commit, push de `feature/014-botao-sos-persistente` e abrir Pull Request no GitHub

## Phase 6: Redesenho da bolinha (sessão de clarificação de 2026-11-18)
- [X] T019 Trocar a pílula "SOS Ajuda" e a faixa do topo pela bolinha vermelha com "SOS" no canto superior direito do cabeçalho (`VagaDoSos`/`TituloComSos` no Design System, usados pelo `CabecalhoDeTela`, pela `BarraSuperior`, pelo Início e por Meu perfil); a paleta de Ajustes para antes do título; bolinha flutuante só em tela sem cabeçalho; portões em `app/test/features/cuidado/presentation/bolinha_sos_test.dart`, provados quebrando. Feita em 2026-11-18.
