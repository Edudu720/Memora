# Data Model: Site Tutorial Acolhedor do Memora (`012`) — Rodada 2

**Branch**: `redesign/S01-S10-S11-site-base` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)

Não há banco de dados, servidor nem persistência de dados pessoais. Este modelo documenta as preferências locais de conforto, os metadados exportados da Memora (`S02`) e os estados efêmeros da anfitriã, do personagem e da síntese de voz.

---

## 1. Preferência de Leitura Local (`PreferenciaDeLeitura`)

Armazenada opcionalmente em `localStorage` sob chaves isoladas não sensíveis (com fallback transparente em memória se o navegador bloquear `localStorage`):

| Campo | Chave Local | Valores Permitidos | Padrão Inicial | Regra de Validação |
| :--- | :--- | :--- | :--- | :--- |
| `tamanhoFonte` | `memora.tutorial.escala_fonte` | `'padrao'` \| `'grande'` \| `'muito-grande'` | `'padrao'` | Valor fora da enumeração volta silenciosamente para `'padrao'`. Refletido em `data-escala` no `<html>`. Equivalências: `1.125rem` (`18px`), `1.45rem` (`~23px`) e `2.0rem` (`32px`, `200%` sobre `16px`). |
| `modoVisual` | `memora.tutorial.modo_visual` | `'claro'` \| `'escuro'` \| `'alto-contraste'` | `'claro'` | Valor fora da enumeração volta para `'claro'`. Refletido em `data-tema` no `<html>`. |
| `reduzirMovimento` | `memora.tutorial.reduzir_movimento` | `'normal'` \| `'reduzido'` | Sistema (`prefers-reduced-motion: reduce` → `'reduzido'`, senão `'normal'`) | Sem valor salvo em `localStorage`, segue o sistema operacional. Após alternância manual no painel, o valor salvo prevalece. Refletido em `data-movimento` no `<html>`. |

**Nota de privacidade**: Nenhum dado de identificação, nome, CPF, telefone, senha ou histórico de navegação pessoal é gravado ou transmitido.

---

## 2. Pacote Exportado da Memora (`DadosExportadosDaMemora`, `S02`)

Gerado em build pelo exportador Dart em `site/assets/memora/` (`memora.json`, SVGs `<expressao>.svg` e módulo local `memora-dados.js` para uso direto via `file://` sem depender de `fetch`):

| Campo / Artefato | Tipo / Estrutura | Origem Única | Regras |
| :--- | :--- | :--- | :--- |
| `<expressao>.svg` e `memora-dados.js` | SVG estático com grupos `<g id="...">` nomeados (`sombra`, `corpo`, `painel-peito`, `antena`, `cabeca`, `visor`, `rosto`, `olhos`, `boca`, `braco-esquerdo`, `braco-direito`, `escudo`, `livro`, `barra`) + módulo JS local com o mesmo pacote inline | `PintorDaMemora` + `poses.dart` | 9 expressões de `PoseDaMemora`: `neutra`, `falando`, `pensando`, `comemorando`, `preocupada`, `acenando`, `dica`, `mini`, `carregando`; funcionamento idêntico sob `file://` e `http(s)://`, com fallback limpo para texto puro se o carregamento falhar. |
| `paletas` | Mapa `{ claro, escuro, alto-contraste }` -> tokens hexadecimais da Memora | Tokens oficiais da Memora (`app/lib/design_system/tokens/cores_da_memora.dart`) | Mantém contraste mínimo `>= 3:1` em todos os 3 modos visuais. |
| `poses` | Mapa por expressão com transformações/visibilidade das partes | `poses.dart` | Usado pelo `<memora-personagem>` para respiração, piscar, aceno, fala e comemoração. |
| `dicasDaAnfitria` | Lista ordenada de strings (blocos curtos `<= 2` frases) | `TextosAnfitria.dicas` (`app/lib/l10n/textos_anfitria.dart`, `T086`) | Fonte única imutável em runtime; revisada por PR; zero geração dinâmica pela IA. |

---

## 3. Estado da Anfitriã Acompanhante Global (`EstadoDaAnfitria`, `S05`, `FR-015`, `Session 2026-11-17`)

Gerenciado em memória na sessão da página fora das `<section>` (canto inferior esquerdo):

| Campo | Tipo | Valores / Estado | Regras de Transição |
| :--- | :--- | :--- | :--- |
| `indiceAtual` | `number` | `0 .. dicasDaAnfitria.length - 1` | Inicializado em `0`. Avança circularmente (`(indice + 1) % total`) ao vencer o temporizador ou ao clicar em **"Outra dica da Memora"**. |
| `rotacaoAutomaticaAtiva` | `boolean` | `true` \| `false` | Inicia `true` apenas se o painel estiver `expandido`, `reduzirMovimento === 'normal'` e sem leitor de tela/foco contínuo bloqueando. Pausa automaticamente quando recolhido para cápsula compacta (`expandida === false`), quando `reduzirMovimento` mudar para `'reduzido'`, ou permanentemente após qualquer acionamento manual de **"Outra dica da Memora"** (`WCAG 2.2.2`). |
| `expandida` | `boolean` | `true` \| `false` | Inicia `true` em desktop largo (`>= 64rem` e `tamanhoFonte !== 'muito-grande'`); inicia `false` (cápsula compacta com `<memora-personagem>` visível) em telas compactas (`< 64rem`) ou escala `200%` (`'muito-grande'`), exibida no fluxo normal da página abaixo de `64rem` ou em `200%` sem `position: fixed`. Alternável manualmente pelo botão acessível (`aria-expanded`). |
| `expressaoAtual` | `ExpressaoMemora` | `acenando` \| `neutra` \| `pensando` \| `dica` \| `preocupada` \| `comemorando` | Sincronizada automaticamente com o capítulo ativo na rolagem ou com `secaoAtivaId` enquanto `"Ouvir este trecho"` está ativo. |
| `intervaloMs` | `number` | `20000` | Intervalo fixo de `20 s` entre trocas automáticas quando ativo. |

---

## 4. Estado de Leitura em Voz Alta e Sincronismo (`EstadoLeituraEmVoz`, `S06`, `FR-013`)

Gerenciado exclusivamente em memória durante a sessão aberta na página:

| Campo | Tipo | Valores / Estado | Regras de Transição |
| :--- | :--- | :--- | :--- |
| `suportado` | `boolean` | `'speechSynthesis' in window` | Se `false`, todos os botões `"Ouvir este trecho"` permanecem com atributo `hidden`. |
| `secaoAtivaId` | `string \| null` | ID da seção em leitura ou `null` | Apenas uma seção pode estar ativa por vez. Iniciar nova seção chama `speechSynthesis.cancel()` antes de iniciar a nova fala. |
| `estado` | `'ocioso' \| 'lendo'` | `'ocioso'` inicialmente | Alterna `aria-pressed="true"` e rótulo `"Parar leitura"`. Propaga `falando="true"` (e expressão correspondente ao capítulo lido) para o `<memora-personagem data-memora-anfitria>` global entre `onstart` e `onend`/`onerror`, inclusive quando em cápsula recolhida. |
| `modoSincroniaBoca` | `'boundary' \| 'pulso' \| 'parada'` | `'parada'` quando ocioso ou movimento reduzido | Usa pulsos diretos de `onboundary` quando o navegador emite eventos; se passarem alguns instantes de `onstart` sem `onboundary`, alterna para `'pulso'` rítmico calmo até `onend`. Sob `reduzirMovimento === 'reduzido'`, permanece `'parada'`. |

---

## 5. Catálogo Estrutural de Capítulos do Tutorial (`CapituloDoTutorial`)

Mantém os 9 capítulos semânticos (`#boas-vindas` até `#duvidas-frequentes`), atualizando seus ativos, layout e textos para a Rodada 2:
- **Acompanhante global + Cartões**: a anfitriã falante e o botão `"Outra dica da Memora"` operam em `<aside class="anfitria-flutuante">` fora das seções (`Session 2026-11-17`); `#boas-vindas` adota abertura limpa sem painel lateral duplicado; `.marca-selo` (`mini`) e os cartões dos capítulos 6, 8 e 9 mantêm `<memora-personagem>` decorativos (`aria-hidden="true"`).
- **Ícones de portas e pessoas**: substituídos por ícones arredondados vetoriais consistentes com o aplicativo (`S07`).
- **Blocos textuais**: todos os títulos, parágrafos, passos e FAQ limitados a no máximo **2 frases curtas** pela `memora-ux`, sem termos proibidos nem emojis (`S11`).
