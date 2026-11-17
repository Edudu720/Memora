# Implementation Plan: Feature 015 — Atalhos Rápidos para Aplicativos

**Branch**: `feature/015-atalhos-aplicativos` | **Date**: 2026-11-16 | **Spec**: [specs/015-atalhos-aplicativos/spec.md](spec.md)

**Input**: Feature specification from `/specs/015-atalhos-aplicativos/spec.md`

## Summary

Implementar uma tela dedicada no Memora intitulada *"Meus Aplicativos"*, fornecendo atalhos diretos para que pessoas idosas possam abrir aplicativos comuns do cotidiano (WhatsApp, YouTube, Instagram, Facebook, Google Fotos, Telegram e TikTok) sem passos guiados ou tutoriais. 

A tela filtra dinamicamente os aplicativos para exibir por padrão **somente aqueles instalados no aparelho do usuário**, utilizando as tags `<queries>` pré-declaradas no manifesto Android e a camada nativa de `MethodChannel` (`ConsultaDeAplicativos` e `AbridorDeAplicativo`). Serviços sociais/governamentais foram estritamente excluídos do escopo desta funcionalidade para manter a simplicidade e segurança. Para proteção contra toques involuntários (Princípio II da Constituição), toda abertura exige diálogo de confirmação claro antes da transição.

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
- 100% funcional offline (sem chamadas ao backend Spring Boot);
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
│   │   └── atalhos_aplicativos/
│   │       ├── data/
│   │       │   ├── catalogo_aplicativos_comuns.dart
│   │       │   └── repositorio_atalhos_aplicativos.dart
│   │       ├── domain/
│   │       │   ├── entidades/
│   │       │   │   ├── atalho_aplicativo.dart
│   │       │   │   └── categoria_aplicativo.dart
│   │       │   └── repositorios/
│   │       │       └── i_repositorio_atalhos.dart
│   │       └── presentation/
│   │           ├── controllers/
│   │           │   └── atalhos_aplicativos_controller.dart
│   │           └── widgets/
│   │               ├── tela_atalhos_aplicativos.dart
│   │               ├── cartao_atalho_aplicativo.dart
│   │               └── dialogo_confirmacao_abertura.dart
└── test/
    └── features/
        └── atalhos_aplicativos/
            ├── catalogo_aplicativos_test.dart
            ├── atalhos_aplicativos_controller_test.dart
            └── tela_atalhos_aplicativos_test.dart
```

**Structure Decision**: Padrão Feature-First e Clean Architecture aderente às demais features do Memora (`lib/features/...`), reutilizando os serviços compartilhados `ConsultaDeAplicativos` e `AbridorDeAplicativo`.

---

## Complexity Tracking

> Nenhuma violação constitucional identificada. A complexidade é estritamente proporcional à necessidade, dispensando backend e banco de dados.

| Decisão | Por que Necessário | Alternativa Mais Simples Rejeitada Por Que |
| :--- | :--- | :--- |
| **Lista fixa de 7 apps em `<queries>`** | Permite checar instalação sem violar regras da Google Play Store (Android 11+). | Tentar varrer todos os apps com `QUERY_ALL_PACKAGES` causaria rejeição imediata do aplicativo na loja e violaria a privacidade do idoso. |
| **Diálogo de confirmação antes de abrir** | Previne que o idoso saia do app acidentalmente por tremor ou toque involuntário. | Abrir no clique direto desorienta pessoas idosas (Princípio II). |
