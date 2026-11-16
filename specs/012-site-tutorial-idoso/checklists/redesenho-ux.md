# Checklist de Qualidade de Requisitos (UX & Redesenho — Rodada 2): Site Tutorial do Memora (`012`)

**Purpose**: Validar completude, clareza, consistência, mensurabilidade e cobertura de riscos nos requisitos da Rodada 2 (`memora-ux`, `<memora-personagem>`, anfitriã, voz sincronizada, movimento reduzido, CSS progressivo e fronteira com `app/`/CI) antes do `/speckit-converge` e da revisão pré-PR na `redesign-final`.  
**Created**: 2026-11-16  
**Feature**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)  
**Scope / Depth / Timing**: Completo (`S01`–`S13`) · Padrão (`20` itens) · Autor pré-tarefas e Revisor em PR  

**Note**: Este checklist funciona como "teste de unidade dos requisitos escritos" — **não** avalia código nem marca tarefas como implementadas. Os itens marcados com `[x]` foram avaliados contra `spec.md`, `plan.md`, `research.md`, `data-model.md` e `contracts/estrutura-e-acessibilidade.md`; os deixados em `[ ]` apontam lacunas ou riscos reais para ajustar nos documentos ou durante as tarefas.

---

## Completude dos Requisitos (`memora-ux`, Personagem e Movimento)

- [x] CHK001 As exigências da `memora-ux` para texto visível e título da aba (limite de duas frases curtas por bloco, ausência de emojis, termos proibidos e frases de incapacidade) estão definidas com escopo completo para todos os elementos textuais do site (incluindo balões da anfitriã, FAQ, legendas de exemplo e mensagens de fallback)? [Completeness, Spec §FR-002, Contract §4]
- [x] CHK002 Os requisitos para o Web Component `<memora-personagem>` e para a exportação oficial (`S02`) documentam integralmente as 8 expressões previstas, os grupos anatômicos nomeados e o esquema de cores por modo visual (`claro`, `escuro`, `alto-contraste`)? [Completeness, Spec §FR-003, Spec §FR-015, Data Model §2]
- [x] CHK003 Todas as condições que iniciam, mantêm ou interrompem a troca automática de dicas da anfitriã (`20 s`, interação manual no botão **"Outra dica da Memora"**, foco de teclado/leitor de tela e modo `"Reduzir movimento"`) estão especificadas sem lacunas? [Completeness, Spec §FR-015, Contract §3]
- [x] CHK004 Os requisitos de sincronização entre `"Ouvir este trecho"` e a boca da Memora especificam o comportamento primário (`onboundary`) e o fallback temporal (`onstart`..`onend`), além do comportamento sob movimento reduzido? [Completeness, Spec §FR-013, Data Model §4]
- [x] CHK005 O critério de fonte visual única para os novos ícones vetoriais arredondados das portas e das pessoas (`S07`) está especificado com referência explícita de família/origem e substituição de ativos antigos em `site/assets/ilustracoes/`? [Completeness, Spec §Assumptions, Contract §4] — *Resolvido*: família `Material Rounded` (equivalente a `Icons.*_rounded` da 013) e lista explícita dos arquivos substituídos (`porta_*.svg`, `casal_idoso.svg`, `pessoa_com_celular.svg`, `ajuste_aparencia.svg`).

## Clareza e Quantificação de Critérios

- [x] CHK006 A fronteira do limite de `"aproximadamente 100 KB"` de JavaScript (`Spec §FR-014`) está quantificada de forma única com o valor exato em bytes do contrato (`102.400 bytes` em `Contract §4`) e com indicação clara de quais diretórios entram na soma? [Clarity, Spec §FR-014, Contract §4] — *Atendido no contrato*: `site/scripts/` + `site/vendor/` + `site/assets/memora/memora-dados.js` <= `102.400 bytes`.
- [x] CHK007 O que conta como `"bloco de texto"` no portão automatizado de no máximo duas frases curtas (`FR-002`, `SC-001`) — e como abreviações, listas enumeradas ou selos curtos são tratados — está definido de forma não ambígua entre `spec.md` e `Contract §4`? [Clarity, Spec §FR-002, Contract §4] — *Resolvido*: `Contract §4` detalha os elementos HTML verificados e a regra de segmentação alinhada a `texto_da_interface_test.dart`.
- [x] CHK008 A precedência entre preferência do sistema (`prefers-reduced-motion: reduce`), ausência de dado salvo, alternância manual no botão **"Reduzir movimento"** e modo restrito sem `localStorage` está descrita sem ambiguidade em todos os estados? [Clarity, Spec §FR-010, Contract §2]
- [x] CHK009 A regra que restringe `light-dark()` exclusivamente ao par `claro`/`escuro` — preservando regras explícitas independentes para `alto-contraste` (`>= 7,0:1`) e fallbacks via `@supports` — está formulada com critérios claros de compatibilidade? [Clarity, Spec §FR-016, Contract §2]

## Consistência Entre Artefatos e Documentos

- [x] CHK010 O título e a prosa contextual da `spec.md` (ex.: menções internas a *"Pessoas Idosas"* em `User Stories 1–5` e no cabeçalho do arquivo) estão claramente demarcados como narrativa interna ou em potencial conflito com a proibição editorial de `"idoso"` na interface visível (`FR-002`)? [Consistency, Spec §User Story 1, Spec §FR-002] — *Resolvido*: `Nota terminológica` adicionada no topo da `spec.md`.
- [x] CHK011 As restrições de `"zero dependências externas"` no *Threat Model* de `spec.md` estão totalmente consistentes com a regra revisada da `FR-014` que admite bibliotecas enxutas copiadas localmente em `site/vendor/` com versão fixa? [Consistency, Spec §FR-014, Spec §Threat Model]
- [x] CHK012 A nota de independência em `Spec §Assumptions` (`"sem alterar contratos ou pipelines existentes do aplicativo principal"`) está consistente com a inclusão do exportador em `app/tool/` e do novo job `site` no workflow do CI em `plan.md`? [Consistency, Spec §Assumptions, Plan §Structure Decision] — *Resolvido*: `Spec §Assumptions` alinhada com `app/tool/` e o job paralelo `site` no CI.

## Mensurabilidade e Critérios de Aceite

- [x] CHK013 Cada novo critério em `FR-014`–`FR-016` e `SC-001` possui métricas objetivas e verificáveis sem depender de avaliação subjetiva (orçamento JS em bytes, intervalo `20.000 ms`, limite de `2` frases, razão de contraste `>= 7,0:1` em Alto Contraste, alvos `>= 48×48 px`)? [Measurability, Spec §SC-001, Contract §2–§4]
- [x] CHK014 Os critérios de orçamento de animação e desempenho para aparelhos simples (`IntersectionObserver` fora da tela, restrição a `transform`/`opacity` e simulação de celular lento no CI) estão traduzidos em metas passíveis de medição objetiva? [Measurability, Spec §FR-014, Plan §Technical Context, Contract §4] — *Resolvido*: meta objetiva com throttling `CPU 4x` no Playwright, `0` violações `axe-core`, `0` overflow em `320 px` a `200%` e JS total `<= 102.400 bytes`.

## Cobertura de Cenários, Casos de Borda e Segurança

- [x] CHK015 Todos os cenários de degradação e erro de plataforma relacionados aos novos recursos (navegador sem `onboundary` na síntese de voz, sem suporte a `light-dark()`/View Transitions/`animation-timeline`, bloqueio de `localStorage` para `reduzirMovimento`, falha ou ausência de `memora.json`) estão cobertos pelos requisitos e casos de borda? [Coverage, Spec §Edge Cases & Estados, Data Model §2, Contract §3] — *Resolvido*: pacote `memora-dados.js` gerado para compatibilidade integral em `file://` sem `fetch()`, mantendo fallback legível em caso de ausência.
- [x] CHK016 Os requisitos definem de forma explícita a pausa automática e irrevogável na sessão da troca de dicas após interação humana em **"Outra dica da Memora"** (`WCAG 2.2.2`), inclusive após alternar `"Reduzir movimento"`? [Coverage, Data Model §3, Contract §3]
- [x] CHK017 Os riscos de engenharia social introduzidos pela presença da anfitriã interativa no topo da página estão mitigados nos requisitos (dicas exclusivamente de lista estática exportada do código do app, proibição de dicas vindas de IA/servidor e inexistência de redirecionamento ou ação externa no toque)? [Completeness, Spec §FR-015, Plan §Constitution Check]

## Dependências, Fronteiras (`app/` × `site/` × CI) e Limites

- [x] CHK018 O contrato de interface do pacote gerado pelo exportador (`site/assets/memora/memora.json` + SVGs nomeados) define claramente as chaves, expressões, paletas e lista de dicas esperadas antes da entrega de `T083` e `T086` pela frente `013`? [Dependency, Data Model §2, Plan §Project Structure]
- [x] CHK019 A separação entre ferramentas dev-only de qualidade no CI (Playwright e `@axe-core/playwright` em `site/tests/e2e/`) e os artefatos publicados do site (`site/` runtime <= `100 KB` JS, zero `node_modules` em produção) está especificada sem margem para contaminação do bundle estático? [Completeness, Plan §Structure Decision, Contract §4]
- [x] CHK020 Existe critério explícito determinando a remoção das 7 imagens legadas da Memora (`3 PNG + 4 SVG`) e atualização de `site/assets/ilustracoes/LICENCAS.md` vinculada à entrada do componente `<memora-personagem>`, evitando ativos órfãos em `site/assets/`? [Completeness, Research §2, Contract §4]

---

## Notes

- Revisão concluída em 2026-11-16 comparando os requisitos da Rodada 2 (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/estrutura-e-acessibilidade.md`) com `memora-ux` e a spec `013`.
- **Resultado**: **20/20** critérios aprovados (`[x]`) após ajustes pontuais aplicados nos documentos da feature `012`; fase pronta para `/speckit-converge` e `/speckit-implement`.
