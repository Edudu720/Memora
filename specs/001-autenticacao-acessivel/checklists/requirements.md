# Specification Quality Checklist: Autenticação Acessível

**Purpose**: Validar completude e qualidade da especificação antes do planejamento
**Created**: 2026-07-24
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [ ] **No [NEEDS CLARIFICATION] markers remain** — ⚠️ **FALHA ESPERADA**: 3 questões
      abertas (Q1, Q2, Q3). Ver notas.
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

- [x] **Princípio I** — Threat Model documentado com dados, atores, ameaças, impacto,
      mitigação e monitoramento
- [x] **Princípio II** — Análise de engenharia social respondendo *"como um golpista
      exploraria estas telas?"*, com 6 vetores mapeados
- [x] **Princípio III** — Critérios de acessibilidade como requisitos verificáveis
      (FR-027 a FR-034) e como métricas de sucesso (SC-005 a SC-007)
- [x] **Princípio IV** — Nenhuma linha de código escrita antes desta spec
- [x] **Princípio VI** — FR-047 impede a assistente de tocar em credenciais
- [x] **Princípio VII** — Autonomia preservada: FR-024 e Q3 tratam a dependência
      familiar em vez de ignorá-la

## Notes

### Item que falha, e por quê

**"No [NEEDS CLARIFICATION] markers remain"** é o único item reprovado, e isso é
**intencional**. As três questões abertas atendem aos critérios de bloqueio:
impactam escopo, segurança e experiência, e não possuem padrão razoável que
pudesse ser assumido sem risco.

- **Q1 (identificador de acesso)** condiciona cadastro, login e todo o fluxo de
  recuperação. Assumir "e-mail" por padrão é a escolha comum da indústria — e
  provavelmente errada para um público que frequentemente não tem ou não acessa
  e-mail. Não é uma decisão que eu deva tomar sozinho.
- **Q2 (login social)** é decisão de segurança com trade-off real entre reduzir
  senhas e adicionar tela de terceiro não verificável.
- **Q3 (cadastro assistido)** define escopo e afeta diretamente o Princípio VII.

### Observação sobre unidade de medida

FR-027 usa `dp`, unidade da plataforma Android. É tecnicamente um detalhe de
implementação, mas foi mantida por ser a forma como o critério de acessibilidade é
expresso e verificado na prática, e por já constar assim na Constituição.

### Portão de saída

Esta spec **não avança para `/speckit-plan`** enquanto Q1, Q2 e Q3 não forem
respondidas. Próximo passo: `/speckit-clarify`.
