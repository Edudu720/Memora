# Implementation Plan: Site Tutorial Acolhedor do Memora para Pessoas Idosas

**Branch**: `feature/012-site-tutorial-idoso` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)  
**Input**: Feature specification from `/specs/012-site-tutorial-idoso/spec.md`

---

## Summary

Entregar um site tutorial e informativo **100% estático, responsivo e acolhedor para pessoas idosas (60+)** em `site/` na raiz do repositório, totalmente desacoplado do aplicativo Android (`app/`) e do servidor (`backend/`).

A arquitetura adota **HTML5 semântico em página única contínua** com sumário acessível e retorno fácil ao topo, **CSS3 modular** baseado diretamente nos tokens validados do Design System do Memora (`Claro`, `Escuro`, `Alto Contraste`, escala até `200%` e responsividade fluida de `320 px` até telas largas de desktop), **ilustrações próprias do acervo do Memora** somadas a mini-telas estilizadas adaptáveis, e **JavaScript progressivo mínimo** sem dependências externas para controles integrados de letra/contraste e leitura local opcional em voz alta (`pt-BR`).

---

## Technical Context

**Language/Version**: HTML5, CSS3, JavaScript ES6+ (padrão de navegador sem transpilador)  
**Primary Dependencies**: Zero dependências de runtime ou *bundlers*; apenas recursos padrão da plataforma Web (`localStorage` opcional com fallback, `window.speechSynthesis` opcional com detecção segura, `IntersectionObserver` opcional para destacar capítulo ativo). Ativos visuais copiados do acervo próprio em `app/assets/ilustracoes/`.  
**Storage**: Apenas preferências locais não sensíveis no navegador (`tamanhoFonte` e `modoVisual`), com degradação silenciosa em memória quando bloqueado. Nenhum servidor ou banco de dados.  
**Testing**: Python 3.13 (`site/tests/validar_site.py` para integridade HTML/offline/anti-phishing/WCAG 2.2) + Node.js 24 (`node --test site/tests/tutorial.test.mjs` para lógica cliente) + inspeção visual em navegador real (PC e mobile `320px`–`1280px`).  
**Target Platform**: Navegadores web modernos em Desktop (PC) e Mobile (Android/iOS), inclusive em acesso offline local (`file://`) ou servidor HTTP estático.  
**Project Type**: Static Web Educational Site (portal tutorial independente do aplicativo móvel).  
**Performance Goals**: Abertura imediata sem tela de espera, renderização sem bloqueio por requisições externas e ZERO requisições de rede de terceiros.  
**Constraints**: Zero jargões técnicos/inglesismos no texto visível; design polido e sereno (nunca HTML cru); zero formulários ou coleta de dados (`FR-011`); zero links externos (`FR-012`); WCAG 2.2 AA/AAA com zoom/escala `200%` sem rolagem horizontal a partir de `320 px`; zero impacto nos fluxos do CI existentes para `app/` e `backend/`.  
**Scale/Scope**: 1 página única contínua com 9 capítulos estruturados (Boas-vindas, Primeiros Passos, 3 Botões Principais, Conversa e Histórico, Aplicativos do Dia a Dia, Ajustes e Foto de Perfil, Pulseira de Cuidado, Proteção contra Golpes, Dúvidas Frequentes + dica rápida para familiares), 1 arquivo principal de tokens CSS espelhado do Design System, 1 folha de estilos responsiva, 1 módulo JS testável e acervo reduzido de ilustrações SVG/PNG próprias em `site/assets/ilustracoes/`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio da Constituição | Avaliação Pré-Design e Pós-Design | Status |
| :--- | :--- | :--- |
| **I. Segurança Acima de Tudo** | *Threat Model* documentado na spec. Zero formulários, zero coleta de dados pessoais, zero cookies de rastreamento, zero scripts ou CDNs externos. | ✅ APROVADO |
| **II. Engenharia Social** | Linguagem literal e calma; quadro destacado **"O que o Memora NUNCA faz"**; zero links externos (`FR-012`); mini-telas marcadas explicitamente como exemplos ilustrativos. | ✅ APROVADO |
| **III. Acessibilidade** | Tokens idênticos a [`cores.dart`](file:///c:/Users/Eduardo/Memora/app/lib/design_system/tokens/cores.dart) (WCAG 2.2 AA e `>= 7.0:1` em Alto Contraste); alvos `>= 48×48 px` com `>= 8 px` de folga; escala até `200%`; `prefers-reduced-motion`; zero ícones sem legenda em português; link de salto e marcos semânticos. | ✅ APROVADO |
| **IV. Spec Antes de Código** | `spec.md` criado, clarificado em 4 decisões com o usuário e validado em `requirements.md` (`16/16`). | ✅ APROVADO |
| **V. Arquitetura Limpa / Modularidade** | Separação clara em `site/` entre semântica (`index.html`), tokens visuais (`styles/tokens.css`), layout responsivo (`styles/main.css`), comportamento desacoplado e testável (`scripts/tutorial.js`), ativos (`assets/ilustracoes/`) e testes (`tests/`), sem misturar código com `app/` nem `backend/`. | ✅ APROVADO |
| **VI. IA Nunca Age Sozinha** | Site puramente educativo (sem IA ativa); ensina de forma explícita os limites da assistente do app. | ✅ APROVADO |
| **VII. Ensinar, Não Substituir** | Todo o site materializa o princípio de ensinar passo a passo com paciência para dar autonomia real à pessoa idosa. | ✅ APROVADO |

---

## Project Structure

### Documentation (this feature)

```text
specs/012-site-tutorial-idoso/
├── spec.md                                      # Especificação clarificada
├── plan.md                                      # Este plano de implementação
├── research.md                                  # Decisões técnicas e alternativas (Phase 0)
├── data-model.md                                # Estrutura editorial e preferências locais (Phase 1)
├── quickstart.md                                # Guia de execução e validação (Phase 1)
├── contracts/
│   └── estrutura-e-acessibilidade.md            # Contratos HTML/CSS/ARIA/Privacidade (Phase 1)
├── checklists/
│   └── requirements.md                          # Validação de qualidade da spec
└── tasks.md                                     # Lista ordenada de tarefas (/speckit-tasks)
```

### Source Code (repository root)

```text
site/
├── index.html                                   # Documento único semântico e acessível (9 capítulos + barra de conforto + FAQ)
├── styles/
│   ├── tokens.css                               # Tokens visuais oficiais espelhados de MemoraCores + escalas + espaçamentos
│   └── main.css                                 # Layout responsivo (PC e mobile 320px+), cartões, mini-telas, foco e alto contraste
├── scripts/
│   └── tutorial.js                              # Lógica pura testável (escala, tema, fallback localStorage, voz pt-BR e capítulo ativo)
├── assets/
│   └── ilustracoes/                             # Subconjunto das ilustrações próprias do projeto (ver app/assets/ilustracoes/LICENCAS.md)
│       ├── ajuste_aparencia.svg
│       ├── casal_idoso.svg
│       ├── memora_ajuda_robo.png
│       ├── memora_alerta_robo.png
│       ├── memora_comemorando.svg
│       ├── memora_dica_robo.png
│       ├── memora_falando.svg
│       ├── memora_neutra.svg
│       ├── memora_perfil_robo.png
│       ├── pessoa_com_celular.svg
│       ├── porta_ajuda.svg
│       ├── porta_aplicativos.svg
│       ├── porta_conversa.svg
│       ├── porta_registro.svg
│       └── porta_servicos.svg
└── tests/
    ├── validar_site.py                          # Validação automatizada HTML, offline, zero links externos, zero formulários e WCAG 2.2
    └── tutorial.test.mjs                        # Testes unitários Node (node --test) da lógica de tema, escala e síntese de voz
```

**Structure Decision**: Optou-se pelo diretório isolado `site/` na raiz do repositório em vez de reutilizar `docs/` (que contém documentos técnicos de arquitetura/deploy para a equipe) ou alterar `app/`. Dessa forma, o site estático é portátil, não interfere nos validadores de Dart/Flutter/Maven e mantém exatamente o mesmo padrão visual e licenciamento documentado em `app/assets/ilustracoes/LICENCAS.md`.

---

## Complexity Tracking

Nenhuma violação da Constituição foi identificada. A solução usa zero frameworks, zero servidores e zero dependências externas, mantendo simplicidade máxima com cobertura completa de testes estáticos e de comportamento.
