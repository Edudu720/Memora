# Tarefas do redesenho do site (spec 012) — rodada 2

**Responsável**: Eduardo Trevisan (todas as tarefas do site, decisão do
Henrique em 2026-11-16).
**Branch**: saia da `redesign-final` e abra PR para ela; outra pessoa revisa.
**Origem**: proposta de 2026-11-16, depois do merge da #74 e da aprovação da
Memora vetorial 2.5D da feature 013 (`specs/013-redesenho-final/`).

As 27 tarefas da primeira rodada estão feitas. Esta rodada traz a Memora nova
para o site, a deixa viva, e moderniza a interface sem perder o que o site faz
bem.

---

## O que não muda

- **Nenhum recurso de fora**: nada de CDN, fonte externa ou rastreador. Toda
  biblioteca entra **copiada para dentro de `site/`**, com versão fixa.
- **Sem formulário e sem link de download.**
- **A skill `memora-ux` vale para o site** (`.claude/skills/memora-ux/`): no
  máximo duas frases por bloco, nunca "idoso" nem "terceira idade", nenhum
  emoji, ícone sempre com texto.
- **"Reduzir movimento" desliga tudo**: a preferência do sistema
  (`prefers-reduced-motion`) e o botão novo do painel de conforto (S10).

## Escolhas técnicas

- **JavaScript sem framework, com Web Components.** Um site estático de uma
  página não ganha com React ou com gerador de sites, e o celular de entrada
  do público paga o peso.
- **Animação pela API nativa do navegador (Web Animations).** Se precisar de
  sequências mais complexas: **Motion** na versão mínima (~2,5 KB, usa a mesma
  API nativa), copiado para dentro. Alternativa, se a boca precisar trocar de
  forma: **GSAP**, gratuito com todos os plugins desde 2025 (inclusive o
  MorphSVG), porém mais pesado.
- **CSS novo só como melhoria progressiva**, sempre com `@supports`:
  transição entre capítulos (View Transitions dentro do mesmo documento),
  capítulo surgindo com a rolagem, consultas de contêiner, `text-wrap: pretty`,
  `light-dark()`. Num navegador antigo, o site continua como hoje.

---

## Tarefas

- [ ] **S01** — `/speckit-clarify` da spec 012: registrar a Memora animada, o
  botão "reduzir movimento", a regra de biblioteca copiada para dentro e as
  escolhas técnicas acima.
- [ ] **S02** — **Exportador da Memora** (ferramenta em Dart): roda os
  pintores da `MemoraAnimada` (`app/lib/design_system/componentes/ilustracao/memora_animada/`)
  e gera um **SVG por expressão**, com **cada parte num grupo nomeado**
  (cabeça, visor, olhos, boca, braços, antena, escudo…), mais um JSON com as
  poses, as cores de cada paleta e a lista de dicas da anfitriã. A Memora do
  site tem que ser **a mesma** do aplicativo, nunca redesenhada à parte.
  *Combinar com o Henrique* (dono dos pintores); depende da T083 e da T086 da
  013.
- [ ] **S03** — Web Component `<memora-personagem>`: monta o SVG e anima
  respiração, piscar, aceno, fala e comemoração; atributos `expressao` e
  `falando`; `aria-hidden` (decorativa); parada com "reduzir movimento" e
  quando sai da tela (`IntersectionObserver`). Depende da S02.
- [ ] **S04** — Trocar as **7 imagens antigas da Memora** (3 PNG e 4 SVG de
  `site/assets/ilustracoes/`) pelo componente; apagar os arquivos antigos e
  atualizar o `LICENCAS.md`. Depende da S03.
- [ ] **S05** — **A anfitriã do site** no topo: balão de dicas com a **mesma
  lista fixa do aplicativo** (vinda do JSON da S02, nunca uma segunda lista);
  troca a cada 20 s; **para** com leitor de tela, com "reduzir movimento" ou
  depois de um toque (WCAG 2.2.2); o toque é um botão "Outra dica da Memora".
  Mesmas regras da US8 da spec 013 (FR-048 a FR-058). Depende da S03.
- [ ] **S06** — **A Memora fala junto com o "Ouvir"**: o site já lê os
  capítulos em voz alta; a boca dela acompanha a leitura pelos eventos de
  fronteira de palavra da síntese de voz. Depende da S03.
- [ ] **S07** — Ícones das "portas" e das pessoas: trocar pela mesma família
  arredondada do aplicativo (SVG copiado para dentro), com resposta ao toque e
  ao foco.
- [ ] **S08** — Movimento da página: transição suave ao pular de capítulo
  pelo sumário e capítulo surgindo com a rolagem, com `@supports` e desligado
  com "reduzir movimento". Depende da S10.
- [ ] **S09** — CSS moderno: tokens com `light-dark()`, consultas de
  contêiner nos cartões, `text-wrap: pretty`; o contraste continua validado
  pelo `validar_site.py`.
- [ ] **S10** — Botão **"Reduzir movimento"** no painel de conforto, guardado
  como já são o tamanho da letra e o tema.
- [ ] **S11** — Texto pela memora-ux: o título da aba sem "Pessoas Idosas"
  (sugestão: "Guia do Memora — passo a passo, no seu ritmo") e duas frases por
  bloco, com o mesmo portão de texto do aplicativo dentro do
  `validar_site.py`.
- [ ] **S12** — Qualidade no CI: um job para o site (hoje o `validar_site.py`
  e o `tutorial.test.mjs` não rodam no CI), mais Playwright com axe-core para
  acessibilidade e uma meta de desempenho simulando celular lento. Tudo só em
  desenvolvimento; nada disso vai para o site publicado.
- [ ] **S13** — Orçamento de desempenho: no máximo ~100 KB de JavaScript,
  animar só posição, escala e transparência, e parar a Memora fora da tela.
- [ ] **T082** (vinda da 013) — quando a Memora vetorial estiver no site, as
  imagens antigas saem de vez (é a S04) e o título é revisto (é a S11).

**Ordem sugerida**: S01 → S10 e S11 (rápidas, sem dependência) → S02 → S03 →
S04, S05 e S06 → S07, S08, S09, S13. A S12 pode correr em paralelo desde o
começo.

## Fontes consultadas (2026-11-16)

- [Webflow makes GSAP 100% free](https://webflow.com/blog/gsap-becomes-free)
- [GSAP 3.15.0 README](https://cdn.jsdelivr.net/npm/gsap@3.15.0/README.md)
- [Motion: feature comparison](https://motion.dev/docs/feature-comparison)
- [Motion 13.1.0 README](https://cdn.jsdelivr.net/npm/motion@13.1.0/README.md)
- [Chrome: View Transitions](https://developer.chrome.com/docs/web-platform/view-transitions/cross-document?hl=pt)
- [Can I use: cross-document view transitions](https://caniuse.com/cross-document-view-transitions)
