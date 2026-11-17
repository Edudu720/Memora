# Implementation Plan: Feature 015 — Atalhos Rápidos para Aplicativos

**Branch**: `feature/015-atalhos-aplicativos` | **Date**: 2026-11-16 | **Spec**: [specs/015-atalhos-aplicativos/spec.md](spec.md)

**Input**: Feature specification from `/specs/015-atalhos-aplicativos/spec.md`

## Summary

Implementar atalhos diretos para abrir aplicativos comuns do cotidiano (WhatsApp, YouTube, Instagram, Facebook, Google Fotos, Telegram e TikTok) sem exigir tutoriais, **convivendo** com o `TelaCatalogo` e mantendo o catálogo oficial do servidor (`RepositorioAssistente.catalogo()`) como fonte única da verdade (preservando **R6** e **Princípio VII**).

A porta *"Meus aplicativos"* no Início e no Hub continua levando ao `TelaCatalogo`, onde cada cartão cotidiano passa a oferecer abertura direta segura (*"Abrir agora"* ou *"Baixar na Play Store"*) ao lado das ações educativas (*"Ensinar passo a passo"* e *"Pedir para a Memora abrir"*), além de um botão no catálogo (*"Abrir só por atalhos"*) para a tela dedicada `TelaAtalhosAplicativos`. O estado de instalação é detectado em tempo real via `ConsultaDeAplicativos`, serviços sensíveis/governamentais permanecem estritamente excluídos, aberturas manuais diretas não geram `Registro` da assistente (`003/D1`) e todo disparo externo exige confirmação clara (`DialogoConfirmacaoAbertura` ou `DialogoInstalacaoPlayStore`).

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.47.7+ e Kotlin (Android nativo).

**Primary Dependencies**: Flutter Material 3, Design System Memora (`design_system`), MethodChannels existentes (`memora/aplicativos` e `memora/abridor`), `url_launcher` (para abertura oficial da Google Play Store quando o idoso desejar instalar um app ausente).

**Storage**: N/A (100% em memória local; o estado de instalação é consultado dinamicamente via `PackageManager` em tempo real para refletir instalações/desinstalações imediatas sem cache estragado).

**Testing**: `flutter test` com `ConsultaDeAplicativosSimulada` e `AbridorDeAplicativoSimulado` em testes unitários e de widget com cobertura de 100% dos fluxos de confirmação e estados vazios.

**Target Platform**: Android (API 26 a 35 / Android 8.0 a 15+).

**Project Type**: Mobile Application (módulo de apresentação e domínio em Flutter).

**Performance Goals**: Carregamento da lista de aplicativos e checagem de instalação dos 7 itens em menos de 100 ms na inicialização; renderização a 60 fps constantes.

**Constraints**:
- Conformidade obrigatória com as regras de visibilidade do Android 11+ (API 30+): proibido `QUERY_ALL_PACKAGES`;
- Fonte única da verdade no catálogo do servidor (`RepositorioAssistente.catalogo()`), preservando **R6** (desativação remota) e **Princípio VII** (sem substituir o catálogo educativo nem conflitar com `TelaInicio`);
- Acessibilidade sênior (WCAG 2.2 AA/AAA, Atkinson Hyperlegible Next, escala de texto 200%, alvos de toque >= 56 dp).

**Scale/Scope**: 1 tela nova principal, 3 componentes especializados (`CartaoAtalhoAplicativo`, `DialogoConfirmacaoAbertura`, `DialogoInstalacaoPlayStore`), 1 repositório de domínio e 1 controller de estado.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio Constitucional | Avaliação | Status |
| :--- | :--- | :--- |
| **I. Segurança Acima de Tudo** | A feature não acessa nem armazena dados sensíveis ou credenciais. Não faz varredura genérica do aparelho (`QUERY_ALL_PACKAGES`), mantendo a superfície de exposição estritamente restrita aos 7 pacotes conhecidos. Zero secrets no app. | **PASS** |
| **II. Segurança Contra Engenharia Social** | Nenhuma ação externa é disparada sem aviso prévio. Ao tocar em um aplicativo, um diálogo claro e inequívoco explica que o usuário sairá do Memora e como retornar, evitando desorientação por toque acidental. Exclusão estrita de serviços governamentais e financeiros para evitar manipulação ou phishing. | **PASS** |
| **III. Acessibilidade como Requisito** | Cartões com alvos de toque amplos (mínimo 72 dp de altura), contraste de cores >= 4.5:1, fonte `AtkinsonHyperlegibleNext` legível para idosos, suporte completo a escala de 200% e TalkBack. | **PASS** |
| **IV. Especificação Antes de Código** | `spec.md`, `research.md`, `data-model.md`, `contracts/` e `quickstart.md` gerados e revisados antes de qualquer linha de implementação. | **PASS** |
| **V. Arquitetura Limpa e Feature-First** | Funcionalidade isolada em `lib/features/atalhos_aplicativos/` com separação rigorosa entre domínio, dados e apresentação. | **PASS** |
| **VI. A IA Nunca Age Sozinha** | A funcionalidade é determinística e acionada exclusivamente por ação deliberada do usuário na interface gráfica; nenhuma IA executa ações ou redireciona sem consentimento. | **PASS** |
| **VII. Ensinar, Não Substituir** | O objetivo desta tela é ser um lançador limpo e acessível para o dia a dia, complementando as telas de aprendizado e guias (Feature 004 e 006) sem forçar o idoso que já sabe usar o WhatsApp a passar por um tutorial repetitivo. | **PASS** |

---

## Project Structure

### Documentation (this feature)

```text
specs/015-atalhos-aplicativos/
├── spec.md              # Especificação de requisitos e regras de negócio
├── plan.md              # Este plano de implementação
├── research.md          # Análise de viabilidade técnica e restrições Android
├── data-model.md        # Entidades, enums e modelos de estado
├── quickstart.md        # Guia de validação e testes automatizados
└── contracts/
    └── atalhos-aplicativos.md # Contratos de MethodChannel e componentes de UI
```

### Source Code Layout

```text
app/
├── lib/
│   ├── features/
│   │   ├── assistente/presentation/telas/
│   │   │   └── tela_catalogo.dart              # Coexistência: Abrir agora / Play Store / Abrir só por atalhos
│   │   └── atalhos_aplicativos/
│   │       ├── data/
│   │       │   └── repositorio_atalhos_aplicativos.dart
│   │       ├── domain/
│   │       │   ├── entidades/
│   │       │   │   ├── atalho_aplicativo.dart
│   │       │   │   └── categoria_aplicativo.dart
│   │       │   └── repositorios/
│   │       │       └── i_repositorio_atalhos.dart
│   │       └── presentation/
│   │           ├── controllers/
│   │           │   ├── estado_tela_atalhos.dart
│   │           │   └── atalhos_aplicativos_controller.dart
│   │           ├── telas/
│   │           │   └── tela_atalhos_aplicativos.dart
│   │           └── widgets/
│   │               ├── cartao_atalho_aplicativo.dart
│   │               ├── dialogo_confirmacao_abertura.dart
│   │               └── dialogo_instalacao_play_store.dart
└── test/
    ├── acessibilidade/
    │   └── atalhos_aplicativos_acessibilidade_test.dart
    └── features/
        └── atalhos_aplicativos/
            ├── catalogo_abertura_direta_test.dart
            ├── dialogo_confirmacao_abertura_test.dart
            ├── dialogo_instalacao_test.dart
            ├── repositorio_atalhos_test.dart
            └── tela_atalhos_exibicao_test.dart
```

**Structure Decision**: Padrão Feature-First e Clean Architecture aderente às demais features do Memora (`lib/features/...`), reutilizando os serviços compartilhados `ConsultaDeAplicativos` e `AbridorDeAplicativo`.

---

## Complexity Tracking

> Nenhuma violação constitucional identificada. A complexidade é estritamente proporcional à necessidade, dispensando backend e banco de dados.

| Decisão | Por que Necessário | Alternativa Mais Simples Rejeitada Por Que |
| :--- | :--- | :--- |
| **Lista fixa de 7 apps em `<queries>`** | Permite checar instalação sem violar regras da Google Play Store (Android 11+). | Tentar varrer todos os apps com `QUERY_ALL_PACKAGES` causaria rejeição imediata do aplicativo na loja e violaria a privacidade do idoso. |
| **Diálogo de confirmação antes de abrir** | Previne que o idoso saia do app acidentalmente por tremor ou toque involuntário. | Abrir no clique direto desorienta pessoas idosas (Princípio II). |
