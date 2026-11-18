# Implementation Plan: Site Tutorial Acolhedor do Memora (`012`) — Rodada 2 + Acompanhante Global

**Branch**: `redesign/S01-S10-S11-site-base` (base `redesign-final`) | **Date**: 2026-11-17 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)  
**Input**: Especificação clarificada em `specs/012-site-tutorial-idoso/spec.md` (`S01` + `Session 2026-11-17`) + roadmap `specs/012-site-tutorial-idoso/tarefas-do-redesenho.md` (`S01`–`S13`) + regras de [SKILL.md](file:///c:/Users/Eduardo/Memora/.claude/skills/memora-ux/SKILL.md)

---

## Summary

Modernizar o site tutorial estático em `site/` mantendo-o **100% autônomo do app Android (`app/`) e do backend (`backend/`)**, agora alinhado visual e editorialmente à feature `013-redesenho-final`:

- **Uma só Memora entre app e site (`S02`–`S06`, `Session 2026-11-17`)**: exportador em Dart reutiliza os pintores e poses oficiais de `PintorDaMemora` ([app/lib/design_system/componentes/ilustracao/memora_animada/](file:///c:/Users/Eduardo/Memora/app/lib/design_system/componentes/ilustracao/memora_animada/)) e a lista fixa de dicas da anfitriã (`T086`) para gerar SVGs com grupos nomeados + JSON/módulo local compartilhado, consumidos pelo Web Component `<memora-personagem>` em **acompanhante global flutuante fora dos capítulos** (canto inferior esquerdo, oposto ao `↑ Topo`) com abertura limpa no `#boas-vindas`, cápsula compacta recolhível em telas `< 64rem` ou `200%`, adaptação de expressão ao capítulo ativo na rolagem e sincronização da boca com `"Ouvir este trecho"` em todos os 9 capítulos (mantendo o selo `mini` no cabeçalho e as ilustrações decorativas dos capítulos 6, 8 e 9 nos cartões).
- **Acessibilidade, movimento e texto pela `memora-ux` (`S08`–`S11`, `S13`)**: botão `"Reduzir movimento"` integrado ao painel de conforto (respeitando `prefers-reduced-motion` no carregamento e prevalecendo a escolha manual salva localmente), ícones arredondados vetoriais consistentes com o app (`S07`), CSS moderno apenas como melhoria progressiva via `@supports` (`light-dark()` para Claro/Escuro mantendo `alto-contraste >= 7,0:1`, container queries, `text-wrap: pretty`, View Transitions e revelação na rolagem), revisão editorial (`<= 2` frases por bloco, zero emojis na UI, zero termos proibidos inclusive no `<title>`) e orçamento máximo de `~100 KB` de JavaScript.
- **Qualidade contínua no CI (`S12`)**: job dedicado no [verificacao.yml](file:///c:/Users/Eduardo/Memora/.github/workflows/verificacao.yml) rodando `validar_site.py` (HTML, offline, anti-golpe, contraste WCAG, regra `memora-ux`, orçamento JS), `node --test site/tests/tutorial.test.mjs`, e suíte dev-only com Playwright + `axe-core` simulando celular de entrada.

---

## Technical Context

**Language/Version**: HTML5 semântico, CSS3 moderno progressivo (`@supports`), JavaScript ES6+ nativo (Web Components + Web Animations API); ferramenta auxiliar de exportação em Dart (`3.13.5` / Flutter `3.47.7`).  
**Primary Dependencies**: Zero frameworks e zero CDNs/redes externas em produção. Qualquer biblioteca auxiliar de animação eventual (`Motion` ~2,5 KB ou equivalente dentro do teto de JS) só entra **copiada para dentro de `site/`** com versão fixa. Dependências de desenvolvimento para o CI (`playwright`, `@axe-core/playwright`) vivem isoladas como dev-only e nunca vão para os artefatos publicados do site.  
**Storage**: Apenas preferências locais não sensíveis em `localStorage` (`memora.tutorial.escala_fonte`, `memora.tutorial.modo_visual`, `memora.tutorial.reduzir_movimento`), com fallback silencioso em memória quando bloqueado.  
**Testing**:
- `python site/tests/validar_site.py` (HTML, offline, zero rede externa, zero formulários, contraste WCAG 2.2 AA/AAA, regra de texto `memora-ux`, remoção de imagens legadas da Memora, orçamento JS `<= 100 KB`).
- `node --test site/tests/tutorial.test.mjs` (preferências de leitura + `"Reduzir movimento"` + `prefers-reduced-motion`, `<memora-personagem>`, anfitriã `20 s`/pausa, voz `onboundary` + fallback).
- Playwright + `axe-core` (acessibilidade automatizada sem violações WCAG 2.2 AA/AAA, ausência de `scrollWidth > clientWidth` em `320 px` a `200%` e simulação de celular de entrada com desaceleração `CPU 4x` no Chromium mantendo animações sem travamento e carga JS runtime `<= 102.400 bytes`) no job `site` do CI.  
**Target Platform**: Navegadores modernos e intermediários em Desktop e Mobile Android/iOS (incluindo `file://` local sem erro de CORS ao carregar ativos da Memora e servidor estático), mantendo degradação limpa em navegadores sem `light-dark()`, View Transitions ou `animation-timeline`.  
**Project Type**: Static Educational Web Site (`site/`) + gerador de ativos acoplado apenas em build/exportação aos pintores de `app/`.  
**Performance Goals**: Orçamento total de JS em produção (`site/scripts/` + `site/vendor/` + dados locais gerados) <= `102.400 bytes` (`100 KiB`); apenas propriedades compositoras (`transform`, `opacity`) animadas; `<memora-personagem>` pausada fora da tela via `IntersectionObserver`; aprovação em perfil `CPU 4x` simulado sem violações `axe-core` nem bloqueio visível da interação.  
**Constraints**: Zero formulários/campos sensíveis (`FR-011`), zero links externos (`FR-012`), zero dependências em CDN (`FR-014`), conformidade integral com `memora-ux` (`FR-002`, `SC-001`), preservação rigorosa do modo Alto Contraste `>= 7,0:1` (`AC-001`, `FR-016`).  
**Scale/Scope**: 1 página única contínua (`index.html`), painel de conforto (`tamanho`, `tema`, `reduzir movimento`), módulo acompanhante global da anfitriã fora das `<section>` (expandido no canto inferior esquerdo em desktop com botão de recolher, e cápsula compacta recolhida por padrão em mobile/`200%`), `<memora-personagem>` decorativas nos capítulos 6/8/9 e selo `mini`, exportação de 9 poses/expressões oficiais da `MemoraAnimada` (incluindo `carregando`), e cobertura completa de validação no CI.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio da Constituição | Avaliação Pré-Design e Pós-Design | Status |
| :--- | :--- | :--- |
| **I. Segurança Acima de Tudo** | *Threat Model* atualizado para permitir bibliotecas JS somente copiadas localmente com versão fixa (zero CDN/terceiros em runtime); zero formulários, zero coleta de dados pessoais ou telemetria. | ✅ APROVADO |
| **II. Engenharia Social** | Lista fixa de dicas da anfitriã exportada diretamente do código revisado do app (nunca gerada por IA ou servidor em runtime); toque na anfitriã apenas troca dica e nunca abre URL nem dispara ação externa; textos curtos preservam avisos essenciais visíveis (`FR-002`, `FR-008`). | ✅ APROVADO |
| **III. Acessibilidade** | `<memora-personagem>` marcada `aria-hidden="true"` (decorativa); botões acessíveis **"Outra dica da Memora"** e de recolher/expandir a anfitriã (`>= 48×48 px` e folga `>= 8 px` com `↑ Topo`); pausa automática de rotação ao recolher, sob leitor de tela, movimento reduzido, foco contínuo ou após interação (`WCAG 2.2.2`); controle `"Reduzir movimento"` integrado; contraste WCAG 2.2 AA/AAA validado matematicamente e via `axe-core`; abertura inicial em cápsula compacta em `< 64rem` e `200%` sem sobrepor conteúdo. | ✅ APROVADO |
| **IV. Spec Antes de Código** | `spec.md` clarificada na `S01` (5/5 respostas registradas e `checklists/requirements.md` `16/16`), seguida deste `plan.md`, `research.md`, `data-model.md`, `contracts/` e `quickstart.md` antes da implementação. | ✅ APROVADO |
| **V. Arquitetura Limpa / Fonte Única** | Fonte única da Memora (`PintorDaMemora`) e das dicas (`T086`) via ferramenta exportadora em Dart; separação limpa em `site/` entre HTML semântico, tokens/estilos CSS, Web Component `<memora-personagem>`, controlador JS (`tutorial.js`), ativos e suíte de verificação. | ✅ APROVADO |
| **VI. IA Nunca Age Sozinha** | Site puramente educativo e offline, sem chamadas a provedor de IA; fala local em `window.speechSynthesis` nunca envia dados à rede (`FR-013`). | ✅ APROVADO |
| **VII. Ensinar, Não Substituir** | Textos encurtados pela `memora-ux` ensinam em blocos de no máximo 2 frases com autonomia e sem termos capacitistas ou jargões. | ✅ APROVADO |

---

## Project Structure

### Documentation (this feature)

```text
specs/012-site-tutorial-idoso/
├── spec.md                                      # Especificação clarificada (Rodada 1 + S01)
├── plan.md                                      # Este plano de implementação (Rodada 2)
├── research.md                                  # Decisões técnicas e alternativas (Phase 0)
├── data-model.md                                # Preferências locais, estado da anfitriã e payload exportado (Phase 1)
├── quickstart.md                                # Guia de execução, exportação e validação completa (Phase 1)
├── contracts/
│   └── estrutura-e-acessibilidade.md            # Contratos HTML/CSS/WCAG/CustomElement/Exportação (Phase 1)
├── checklists/
│   ├── requirements.md                          # Checklist de qualidade da spec
│   ├── revisao-requisitos.md                    # Revisão complementar da spec
│   └── redesenho-ux.md                          # Checklist UX/AC do redesenho (Rodada 2)
├── tasks.md                                     # Tarefas da Rodada 1 concluídas + convergência Rodada 2
└── tarefas-do-redesenho.md                      # Lista S01–S13 de trabalho da Rodada 2 no redesign-final
```

### Source Code & Tooling Layout

```text
app/
└── tool/
    └── exportar_memora_site.dart                # S02: exportador CLI usando PintorDaMemora/poses + dicas da T086 -> site/assets/memora/

site/
├── index.html                                   # S04, S05, S10, S11: página única contínua, hero limpo em #boas-vindas, <aside> acompanhante global fora das seções + capítulos 6/8/9 e selo mini
├── styles/
│   ├── tokens.css                               # S09: tokens oficiais Claro/Escuro/Alto Contraste + progressivo light-dark() em @supports
│   └── main.css                                 # S08, S09, S10: layout fluido, container queries, View Transitions, scroll reveal, anfitriã flutuante + cápsula mobile/200%, [data-movimento="reduzido"]
├── scripts/
│   ├── memora-personagem.js                     # S03, S06, S13: Web Component <memora-personagem> + Web Animations + IntersectionObserver
│   └── tutorial.js                              # S05, S06, S10: preferências, anfitriã acompanhante global (20s/recolher/expressão por capítulo), SpeechSynthesis + sync boca global
├── assets/
│   ├── memora/                                  # S02: SVGs exportados por expressão (grupos nomeados) + memora.json + memora-dados.js (compatível com file:// sem fetch)
│   └── ilustracoes/                             # S04, S07: ícones Material Rounded em SVG (substituindo porta_*, casal_idoso, pessoa_com_celular, ajuste_aparencia) + LICENCAS.md (sem as 7 imagens antigas da Memora)
├── vendor/                                      # Opcional (vazio por padrão): biblioteca enxuta copiada localmente se necessário (dentro de 100 KB total JS)
└── tests/
    ├── validar_site.py                          # S11, S13: HTML, offline, contraste WCAG, texto memora-ux, ausência de imagens legadas, teto <= 100 KB JS
    ├── tutorial.test.mjs                        # S03, S05, S06, S10: testes Node da lógica de preferências, anfitriã, fala e <memora-personagem>
    └── e2e/                                     # S12 (dev-only): Playwright + axe-core + orçamento em celular lento simulado

.github/workflows/
└── verificacao.yml                              # S12: novo job `site` executando validar_site.py, tutorial.test.mjs e Playwright/axe-core
```

**Structure Decision**:
- O exportador (`app/tool/exportar_memora_site.dart`) vive em `app/` porque importa diretamente os pintores e poses oficiais (`PintorDaMemora`, `poses.dart`) e a lista de dicas (`T086`) sem duplicar geometria nem texto fora de `app/`. A saída gerada é materializada estaticamente em `site/assets/memora/` para que `site/` continue autônomo em execução/hospedagem (funciona offline e sem Flutter).
- Ferramentas de navegador para o CI (`playwright`, `@axe-core/playwright`) ficam isoladas para desenvolvimento/CI em `site/tests/e2e/` (com `package.json` próprio em devDependencies ou dentro de `site/tests/e2e/`), garantindo que **nenhum** pacote de teste ou módulo externo entre na publicação do site nem exceda o orçamento de JS runtime em `site/scripts/` + `site/vendor/`.

---

## Complexity Tracking

Nenhuma violação da Constituição foi identificada. Todo script adicional segue arquitetura modular nativa (`Web Components` + `Web Animations`), depende zero de rede em runtime e só inclui dependência externa em código copiado caso estritamente necessário e dentro de `100 KB`.
