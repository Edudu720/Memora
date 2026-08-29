# Implementation Plan: Hub e a assistente que ensina

**Branch**: `003-hub-e-assistente` | **Date**: 2026-08-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-hub-e-assistente/spec.md`

## Summary

O Hub substitui a tela provisória `_TelaDentro` e é o destino do caminho de volta
de todas as telas. A assistente conversa por um endpoint **autenticado** do
backend, que fala com a Claude API — a chave nunca chega ao aparelho.

A decisão que organiza toda a arquitetura é a **FR-022**: *a saída do modelo não
é autorização*. O modelo pode **sugerir** abrir um aplicativo; quem decide se
aquilo pode ser aberto é uma consulta determinística ao catálogo, no backend,
depois da resposta do modelo. Se a sugestão não passar, ela é descartada e a
pessoa nunca vê o oferecimento.

Isso significa que **um modelo comprometido por injeção não consegue abrir nada
que o catálogo não permita** — que é a diferença entre um assistente e um vetor.

## Technical Context

**Language/Version**: Java 21 (backend) · Dart 3.11 / Flutter 3.41 (aplicativo)

**Primary Dependencies**: Spring Boot 4.1, Spring Security, Spring Data JPA ·
`com.anthropic:anthropic-java` 2.34.0 · Flutter, `dio` (já presente pelo cliente
gerado)

**Storage**: PostgreSQL 16 — **catálogo de serviços** e **trilha de auditoria**.
O conteúdo das conversas **não** é persistido no servidor (FR-047); ele vive no
aparelho.

**Testing**: JUnit 5 + Testcontainers (backend, sobre `TesteComBanco`) ·
`flutter_test` (aplicativo)

**Target Platform**: Android; backend em JVM

**Project Type**: Mobile + API

**Performance Goals**: primeiro fragmento de resposta perceptível em até ~3 s;
resposta completa sem que a pessoa conclua que travou (SC-007). O estado de
espera é sempre visível, o que torna a percepção mais importante que o número.

**Constraints**: sem conteúdo de conversa no servidor (FR-047); sem segredo na
trilha (FR-036); a chave da API nunca no aparelho (Constituição — Segurança
Flutter); toda ação executada auditada (FR-020)

**Scale/Scope**: 4 portas no Hub, 1 tela de conversa, 2 catálogos, 1 tela de
registro. Backend: 3 endpoints novos.

## Constitution Check

*GATE: avaliado antes da Phase 0 e reavaliado após a Phase 1.*

| Princípio | Situação | Como este plano cumpre |
|---|---|---|
| **I — Segurança acima de tudo** | ✅ | Threat model na spec. O endpoint da assistente é autenticado e **herda a guarda do `FiltroDeTokenDeAcesso`** — ver a nota da sessão-chamariz abaixo, que é obrigatória em endpoint autenticado novo |
| **II — Engenharia social** | ✅ | FR-033 (aviso permanente), FR-041 (serviço sensível nunca abre), FR-021 (aviso antes de sair do app). O golpe é analisado por linha na spec |
| **III — Acessibilidade** | ✅ | Componentes vêm da feature 002, que já carrega contraste, alvo de 48 dp e escala a 200%. FR-026 a FR-030 são verificados por teste |
| **IV — Spec antes de código** | ✅ | Spec aprovada, com D1, D2 e D3 registradas. Este plano não inventa requisito |
| **V — Arquitetura limpa, feature-first** | ✅ | `features/hub/` e `features/assistente/` no app; pacote `assistente/` no backend, com a mesma separação de `autenticacao/` |
| **VI — A IA nunca age sozinha** | ✅ | É o eixo do desenho: confirmação explícita (FR-015), trilha imutável (FR-020) e **autorização determinística fora do modelo** (FR-022) |
| **VII — Ensinar, não substituir** | ✅ | O passo a passo vem antes da oferta de executar (FR-014); a SC-003 mede se a pessoa consegue repetir sozinha |

### ⚠️ A sessão-chamariz vale para os endpoints desta feature

`POST /v1/auth/cadastro` devolve, de propósito, um **JWT assinado para um UUID
que não existe** quando o canal já pertence a alguém (FR-010 da feature 001).
Existe token com assinatura válida cujo sujeito não corresponde a conta nenhuma.

Os três endpoints desta feature são autenticados e **precisam passar pela cadeia
do Spring Security**, onde `seguranca/FiltroDeTokenDeAcesso` resolve o sujeito no
banco e recusa quando não encontra. Ler o `subject` do JWT por conta própria
transformaria o chamariz em acesso — e aqui o acesso é a uma conversa com IA que
custa dinheiro por chamada.

### Complexity Tracking

Nenhuma violação a justificar. Duas decisões acrescentam peso e estão
justificadas no [research.md](research.md):

| Decisão | Por que o simples não serve |
|---|---|
| Conversa enviada inteira a cada turno | A FR-047 proíbe guardar conteúdo no servidor. Sessão no servidor seria mais barata em tokens e criaria o acervo que a D3 recusou |
| Catálogo no banco, e não em arquivo de configuração | A FR-022 exige autorização consultável e auditável; mudança de catálogo não pode exigir novo build para tirar um aplicativo do ar |

## Project Structure

### Documentation (this feature)

```text
specs/003-hub-e-assistente/
├── spec.md
├── plan.md              # este arquivo
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   └── openapi.yaml     # Phase 1 — acrescenta ao contrato existente
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
backend/src/main/java/br/fatec/memora/assistente/
├── api/
│   ├── ControladorConversa.java        # POST /v1/assistente/conversa (SSE)
│   ├── ControladorCatalogo.java        # GET  /v1/assistente/catalogo
│   └── ControladorRegistro.java        # GET  /v1/assistente/registro
│                                        # POST /v1/assistente/acao
├── aplicacao/
│   ├── ServicoDeConversa.java          # monta o pedido e transmite a resposta
│   ├── AutorizadorDeAcao.java          # a FR-022 mora aqui
│   └── ServicoDeRegistro.java
├── dominio/
│   ├── ServicoConhecido.java           # entidade do catálogo
│   ├── CategoriaDoServico.java         # SENSIVEL | COTIDIANO
│   └── EventoDaAssistente.java         # trilha, somente inserção
├── infra/
│   ├── ClienteDaAssistente.java        # porta
│   ├── ClienteClaude.java              # adaptador sobre anthropic-java
│   ├── PersonaDaMemora.java            # o system prompt, versionado
│   └── repositorios Spring Data
└── seguranca/
    └── LimitePorConta.java             # teto de conversas, por conta e por dia

backend/src/main/resources/db/migration/
└── V4__assistente.sql                  # catálogo + trilha da assistente

app/lib/features/hub/
├── domain/hub.dart                     # as portas, e o que cada uma abre
└── presentation/telas/tela_hub.dart

app/lib/features/assistente/
├── domain/assistente.dart              # contrato, mensagem, passo, ação
├── data/
│   ├── repositorio_assistente_api.dart
│   ├── repositorio_assistente_simulado.dart
│   └── conversa_local.dart             # a conversa no aparelho (FR-047)
└── presentation/
    ├── controladores/controlador_conversa.dart
    └── telas/
        ├── tela_conversa.dart
        ├── tela_catalogo.dart          # serve às duas portas
        └── tela_registro.dart
```

**Structure Decision**: Mobile + API, espelhando `autenticacao/` nos dois lados.
O catálogo é **uma tela só**, parametrizada pela categoria: duas telas quase
iguais divergiriam na primeira melhoria feita em uma delas — a mesma razão que
levou a US3 da feature 001 a ter uma tela com três etapas.

## Como a conversa acontece

```
 app                        backend                       Claude API
  │                            │                              │
  │ POST /assistente/conversa  │                              │
  │  (histórico + mensagem) ──▶│                              │
  │                            │ system = persona + catálogo  │
  │                            │ ──────────────────────────▶  │
  │                            │      texto + tool_use?       │
  │                            │ ◀──────────────────────────  │
  │                            │                              │
  │                            │ AutorizadorDeAcao:           │
  │                            │  o app está no catálogo,     │
  │                            │  na categoria COTIDIANO?     │
  │                            │  não → a sugestão morre aqui │
  │                            │                              │
  │ ◀── SSE: texto, e a ação   │                              │
  │      só se autorizada      │                              │
  │                            │                              │
  │ ConfirmacaoMemora          │                              │
  │ pessoa confirma            │                              │
  │ app abre o aplicativo      │                              │
  │                            │                              │
  │ POST /assistente/acao ────▶│ grava EventoDaAssistente     │
```

**A sugestão do modelo passa por uma porta que ele não controla.** Quem decide
não é a resposta do modelo, e sim uma consulta ao catálogo depois dela.

## Phase 0 — Research

Ver [research.md](research.md). Resolve: escolha do modelo e custo, streaming,
como a conversa trafega sem ser persistida, onde mora a trilha, limite de gasto
por conta, e o que fazer sem provedor configurado.

## Phase 1 — Design & Contracts

- [data-model.md](data-model.md) — catálogo, trilha e as entidades do aplicativo
- [contracts/openapi.yaml](contracts/openapi.yaml) — os três endpoints novos
- [quickstart.md](quickstart.md) — os cenários de validação, incluindo os que
  quebram portão de propósito

## Constitution Check — reavaliação após a Phase 1

| Princípio | Situação após o desenho |
|---|---|
| I | ✅ O `AutorizadorDeAcao` é o portão, e o `LimitePorConta` impede que o custo da API vire negação de serviço |
| II | ✅ `PersonaDaMemora` é versionada e testada; a recusa de serviço sensível não depende do texto do modelo |
| III | ✅ Sem componente visual novo fora do Design System |
| IV | ✅ Nenhum requisito inventado; o limite de gasto é decisão de arquitetura, registrada no research |
| V | ✅ `dominio` não conhece `infra`; `ClienteDaAssistente` é porta, e o adaptador Claude é substituível |
| VI | ✅ Confirmação no app, autorização no backend, trilha imutável no banco |
| VII | ✅ O ensino é a instrução central da persona, e a SC-003 é o portão de saída |
