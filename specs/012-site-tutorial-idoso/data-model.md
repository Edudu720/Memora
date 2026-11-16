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
| `<expressao>.svg` e `memora-dados.js` | SVG estático com grupos `<g id="...">` nomeados (`sombra`, `corpo`, `painel-peito`, `antena`, `cabeca`, `visor`, `rosto`, `olhos`, `boca`, `braco-esquerdo`, `braco-direito`, `escudo`, `livro`) + módulo JS local com o mesmo pacote inline | `PintorDaMemora` + `poses.dart` | 8 expressões: `neutra`, `falando`, `pensando`, `comemorando`, `preocupada`, `acenando`, `dica`, `mini`; funcionamento idêntico sob `file://` e `http(s)://`, com fallback limpo para texto puro se o carregamento falhar. |
| `paletas` | Mapa `{ claro, escuro, alto-contraste }` -> tokens hexadecimais da Memora | Tokens oficiais do Design System (`cores.dart`) | Mantém contraste mínimo `>= 3:1` em todos os 3 modos visuais. |
| `poses` | Mapa por expressão com transformações/visibilidade das partes | `poses.dart` | Usado pelo `<memora-personagem>` para respiração, piscar, aceno, fala e comemoração. |
| `dicasDaAnfitria` | Lista ordenada de strings (blocos curtos `<= 2` frases) | Lista fixa da `T086` (`textos_anfitria.dart`) | Fonte única imutável em runtime; revisada por PR; zero geração dinâmica pela IA. |

---

## 3. Estado da Anfitriã do Site (`EstadoDaAnfitria`, `S05`, `FR-015`)

Gerenciado em memória na sessão da página:

| Campo | Tipo | Valores / Estado | Regras de Transição |
| :--- | :--- | :--- | :--- |
| `indiceAtual` | `number` | `0 .. dicasDaAnfitria.length - 1` | Inicializado em `0`. Avança circularmente (`(indice + 1) % total`) ao vencer o temporizador ou ao clicar em **"Outra dica da Memora"**. |
| `rotacaoAutomaticaAtiva` | `boolean` | `true` \| `false` | Inicia `true` apenas se `reduzirMovimento === 'normal'` e sem leitor de tela/foco contínuo bloqueando. Muda para `false` permanentemente na sessão após qualquer acionamento manual de **"Outra dica da Memora"** (`WCAG 2.2.2`), ou sempre que `reduzirMovimento` mudar para `'reduzido'`. |
| `intervaloMs` | `number` | `20000` | Intervalo fixo de `20 s` entre trocas automáticas quando ativo. |

---

## 4. Estado de Leitura em Voz Alta e Sincronismo (`EstadoLeituraEmVoz`, `S06`, `FR-013`)

Gerenciado exclusivamente em memória durante a sessão aberta na página:

| Campo | Tipo | Valores / Estado | Regras de Transição |
| :--- | :--- | :--- | :--- |
| `suportado` | `boolean` | `'speechSynthesis' in window` | Se `false`, todos os botões `"Ouvir este trecho"` permanecem com atributo `hidden`. |
| `secaoAtivaId` | `string \| null` | ID da seção em leitura ou `null` | Apenas uma seção pode estar ativa por vez. Iniciar nova seção chama `speechSynthesis.cancel()` antes de iniciar a nova fala. |
| `estado` | `'ocioso' \| 'lendo'` | `'ocioso'` inicialmente | Alterna `aria-pressed="true"` e rótulo `"Parar leitura"`. Propaga `falando="true"` para o `<memora-personagem>` associado entre `onstart` e `onend`/`onerror`. |
| `modoSincroniaBoca` | `'boundary' \| 'pulso' \| 'parada'` | `'parada'` quando ocioso ou movimento reduzido | Usa pulsos diretos de `onboundary` quando o navegador emite eventos; se passarem alguns instantes de `onstart` sem `onboundary`, alterna para `'pulso'` rítmico calmo até `onend`. Sob `reduzirMovimento === 'reduzido'`, permanece `'parada'`. |

---

## 5. Catálogo Estrutural de Capítulos do Tutorial (`CapituloDoTutorial`)

Mantém os 9 capítulos semânticos (`#boas-vindas` até `#duvidas-frequentes`), atualizando seus ativos e textos para a Rodada 2:
- **Personagem**: substitui as 7 imagens antigas de PNG/SVG da Memora pelo componente `<memora-personagem>` (`S03`, `S04`, `S05`).
- **Ícones de portas e pessoas**: substituídos por ícones arredondados vetoriais consistentes com o aplicativo (`S07`).
- **Blocos textuais**: todos os títulos, parágrafos, passos e FAQ limitados a no máximo **2 frases curtas** pela `memora-ux`, sem termos proibidos nem emojis (`S11`).
