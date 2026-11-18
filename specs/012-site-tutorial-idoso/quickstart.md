# Quickstart de Validação: Site Tutorial do Memora (`012`) — Rodada 2

**Branch**: `redesign/S01-S10-S11-site-base` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)

Este guia descreve como regenerar os ativos da Memora para o site (`S02`), executar localmente e validar todos os portões automatizados e manuais do site estático.

---

## 1. Pré-requisitos

- **Navegador moderno** (Chrome, Edge ou Firefox no Windows/macOS/Android) — funciona abrindo `site/index.html` diretamente ou via servidor HTTP estático.
- **Python 3.12+** (`site/tests/validar_site.py` e validadores do Design System).
- **Node.js 20+** (`node --test site/tests/tutorial.test.mjs`).
- **Dart 3.13+ / Flutter 3.47.7** (somente quando for preciso rodar o exportador `S02` após alterações nos pintores ou na lista de dicas do app).
- **Playwright + axe-core (apenas dev/CI, `S12`)** para auditoria automática de acessibilidade, contraste dinâmico, layout a `200%` e orçamento em celular lento simulado.

---

## 2. Exportar a Memora e as Dicas do Aplicativo (`S02`, após `T083`/`T086`)

Sempre que os pintores em `app/lib/design_system/componentes/ilustracao/memora_animada/` ou a lista fixa de dicas da anfitriã mudarem no aplicativo:

```powershell
cd app
dart run tool/exportar_memora_site.dart
```

Resultado esperado: atualização determinística de `site/assets/memora/*.svg` (grupos nomeados por parte) e `site/assets/memora/memora.json` (poses, paletas e lista de dicas).

---

## 3. Como Executar Localmente (PC e Celular)

```powershell
python -m http.server 8080 --directory site
```

Acesse `http://localhost:8080` e teste em `320×568`, `390×844`, `768×1024` e `1280×800`.

---

## 4. Portões Automatizados (`S11`, `S12`, `S13`)

1. **Validador estático, WCAG 2.2, `memora-ux` e orçamento JS**:
   ```powershell
   python site/tests/validar_site.py
   ```
   - Confere semântica HTML, título/textos pela `memora-ux` (`<= 2` frases curtas, zero emoji, zero termos proibidos), ausência de formulários/links externos/CDNs, remoção das 7 imagens antigas da Memora, contraste WCAG 2.2 AA/AAA e teto de JavaScript `<= 100 KB`.
2. **Testes unitários em Node.js (`node --test`)**:
   ```powershell
   node --test site/tests/tutorial.test.mjs
   ```
   - Valida escala, tema, controle **"Reduzir movimento"** (preferência do sistema vs alternância manual), rotação e pausa da anfitriã (`20 s`, `"Outra dica da Memora"`), ciclo de `<memora-personagem>` e sincronismo `onboundary` + fallback.
3. **Auditoria dev/CI com Playwright + axe-core (`S12`)**:
   - Roda automaticamente no job `site` de `.github/workflows/verificacao.yml` (ou localmente na pasta de testes e2e), validando ausência de violações `axe-core`, zero rolagem lateral em `320×568` com fonte `200%`, e orçamento de animação/desempenho com CPU reduzida simulada.
4. **Portões existentes do repositório**:
   ```powershell
   python specs/002-design-system/ferramentas/validar_paleta.py
   python specs/002-design-system/ferramentas/validar_tokens.py
   ```

---

## 5. Checklist Rápido de Conferência Manual

- [x] **`<title>` e textos (`S11`)**: aba sem `"Pessoas Idosas"` e todos os blocos visíveis curtos (`<= 2` frases) e sem emojis.
- [x] **Anfitriã acompanhante e `<memora-personagem>` (`S03`–`S05`, `Session 2026-11-17`)**: personagem acompanhando o scroll no canto inferior esquerdo (oposto a `↑ Topo`), expandida em desktop com botão recolher e cápsula compacta visível em `320×568` / `200%`; dica alternando em `20 s` quando expandida e parando imediatamente ao tocar em **"Outra dica da Memora"**.
- [x] **Leitura em voz alta e expressão por capítulo (`S06`)**: **"Ouvir este trecho"** anima a boca da acompanhante em qualquer um dos 9 capítulos (inclusive quando recolhida em cápsula compacta) e a expressão acompanha o capítulo visível/lido.
- [x] **Conforto `"Reduzir movimento"` (`S10`)**: inicia marcado se o sistema pedir `prefers-reduced-motion: reduce`, permite alternar manualmente e congela personagem, dicas automáticas e transições CSS.
- [x] **Modos visuais (`S09`)**: `Fundo claro`, `Fundo escuro` e `Alto contraste` mantêm contraste integral inclusive em navegadores sem suporte a `light-dark()`.
- [x] **Celular estreito (`320×568`) a `200%`**: `scrollWidth <= clientWidth`, botões `>= 48×48 px` e foco visível ao navegar com `Tab`.
