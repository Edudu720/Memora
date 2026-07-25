# Specification Quality Checklist: Design System

**Purpose**: Validar completude e qualidade da especificação antes do planejamento
**Created**: 2026-07-24
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [ ] **No [NEEDS CLARIFICATION] markers remain** — ⚠️ 3 questões abertas (Q1, Q2, Q3)
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Conformidade com a Constituição

- [x] **Princípio I** — Threat model presente. Superfície reduzida, porém tratada:
      um tema ilegível é uma negação de acesso ao produto
- [x] **Princípio II** — 4 vetores analisados, incluindo o mais relevante aqui:
      inconsistência visual ensina a pessoa a não estranhar telas falsas
- [x] **Princípio III** — É a razão de ser da feature. Verificação automatizada
      exigida em FR-030 a FR-032
- [x] **Princípio IV** — Nenhuma linha de código escrita antes desta spec
- [x] **Princípio V** — FR-002 e FR-032 impedem erosão do sistema por tela avulsa
- [x] **Princípio VII** — US3 preserva autonomia de personalizar sem permitir que a
      pessoa se prejudique sem entender por quê

## Notes

### Defeitos do protótipo que esta spec corrige

| Defeito | Requisito |
|---|---|
| Campos do Perfil idênticos aos botões do Hub | FR-012 |
| Botões SIM/NÃO pequenos, pastel e adjacentes | FR-013, FR-014 |
| Fonte serifada no Chatbot | FR-006 |
| Navegação inferior só com ícones | FR-016 |
| Duas linguagens visuais concorrentes | FR-001, US4 |

### A tensão central da feature

O protótipo promete *"Mexa como quiser"* com escolha livre de Cores, Temas e Fontes.
A intenção — dar autonomia — está alinhada ao Princípio VII. Mas liberdade total de
cor **quebra a garantia de contraste**, e a pessoa que se prejudica normalmente não
percebe a causa nem sabe reverter.

FR-017 e FR-018 resolvem oferecendo escolha entre opções curadas e pré-validadas. A
autonomia é preservada; a garantia de leitura também. É uma divergência **deliberada**
em relação ao protótipo, e está registrada como tal.

### Portão de saída

Esta spec não avança para `/speckit-plan` enquanto Q1, Q2 e Q3 não forem
respondidas. **Q1 é a mais urgente**: os tokens são a base de tudo, e hoje os
valores que temos são aproximações amostradas de imagem comprimida.
