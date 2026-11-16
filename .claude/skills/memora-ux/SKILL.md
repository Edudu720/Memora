---
name: memora-ux
description: Regras de UI/UX do Memora para quem desenha, especifica, implementa ou revisa qualquer tela do aplicativo — princípios visuais, números que se medem, padrões de movimento e da Memora, voz do texto e o que nunca aparece na tela. Use antes de escrever spec, plano, tarefa ou código que mude o que a pessoa vê, toca ou ouve, e ao revisar PR de tela.
---

# memora-ux — como uma tela do Memora deve ser

A pergunta que decide tudo continua sendo a da constituição: **"Um idoso
conseguiria usar isso sozinho?"** Esta skill traduz essa pergunta em regras de
tela. Ela não substitui a constituição (`.specify/memory/constitution.md`) nem
os portões que já existem; ela junta o que vale para o visual num lugar só.

**Hierarquia, quando duas regras brigarem:** constituição → esta skill → spec da
feature → referência externa (Dribbble, mockups, skills públicas). Padrão de
mercado só entra quando não contradiz nada acima dele.

Origem: ideias do Henrique em 2026-11-15, a revisão de design da T044
(`specs/004-redesenho-das-telas/revisao-de-design.md`, que reprovou o
acabamento por "junto demais" e "simples demais"), e a spec 007 do Eduardo
(Design System 2.0), que esta skill continua.

---

## 1. Princípios

1. **Blocos simples, acabamento sofisticado.** Cada tela é feita de poucos
   blocos claros, e o refinamento vem do acabamento: superfície, respiro,
   tipografia, sombra sutil, movimento. Simples não é pobre — a T044 reprovou
   o "simples demais".
2. **Estética de aplicativo atual.** Nada que lembre software dos anos 2000
   (ver as proibições). A referência é um aplicativo bem-feito de hoje, com as
   regras de acessibilidade por cima.
3. **Um sistema só.** Toda tela usa os mesmos componentes e tokens do Design
   System. Exceção visual por tela é defeito, não personalidade.
4. **A Memora ajuda; nunca constata incapacidade.** Nenhum texto sugere que a
   pessoa não consegue, não entende ou é velha demais. O texto diz o que a
   Memora vai fazer **junto**.
5. **O movimento conta onde a pessoa está.** A tela nova chega deslizando,
   como se fosse arrastada, e a direção significa algo: avançar vem da
   direita, voltar vem da esquerda, algo que sobe por cima (diálogo, folha)
   vem de baixo. Nada é "jogado" na tela.
6. **Ensinar, não substituir.** A tela mostra o caminho para que da próxima vez
   a pessoa vá sozinha (Princípio VII).

## 2. Números (todos medíveis)

| O quê | Valor | De onde vem / como se prova |
|---|---|---|
| Alvo de toque | **≥ 48×48 dp**, 8 dp entre alvos; ação de decisão **≥ 56 dp** | `MemoraDimensoes.alvoMinimo` / `alvoDecisao` |
| Texto | ampliável até **200%** sem cortar nem estourar | matriz `app/test/suporte/aparelhos.dart` (4 aparelhos × 3 escalas) |
| Contraste | **4,5:1** texto, **3:1** ícone e contorno de controle; **7:1** no alto contraste | `validar_paleta.py`, `contraste_test.dart` |
| Texto por bloco | **no máximo duas frases curtas** | revisão de spec e de PR; o que passar vira etapa ou "Saber mais" |
| Tamanho | segue a escolha da pessoa em Aparência | nunca fixe tamanho de texto contra a escolha dela |
| Emoji na fala da IA | **no máximo um por mensagem** | instruções da persona no backend |
| Movimento | toda duração passa por `MemoraMovimento.efetiva` | portão V9 (lexical, na mesma linha do `duration:`) |
| Valores visuais | só tokens (`app/lib/design_system/tokens/`) | `validar_tokens.py` |

**O limite é de texto, não de caixa.** Com a letra a 200% a caixa cresce, e a
WCAG não deixa cortar. O que mantém o bloco curto é a frase curta.

## 3. Padrões

### A Memora
- A Memora é um **robô**, e aparece **em 2.5D, animada**, sempre que fala com a
  pessoa: balões de fala, apresentação, conversa, ajuda, passo a passo,
  conclusões e avisos de segurança.
- Cada momento tem uma expressão (repouso, falando, pensando, comemorando,
  preocupada com escudo). A expressão combina com o que o texto diz.
- Ela reage: acena ao chegar, "fala" enquanto o balão aparece, comemora ao fim
  de um passo a passo, fica atenta ao lado de um aviso.
- **Decorativa para o leitor de tela** quando o balão já diz tudo; nunca é a
  única portadora de uma informação.
- **A anfitriã do Início é a exceção** (spec 013, 2026-11-16): mais
  detalhada e mais animada que as outras, se mexe sozinha, conta dicas num
  balão (lista fixa do aplicativo, nunca da IA nem do servidor) com a boca
  mexendo, troca a dica a cada 20 s **só** sem leitor de tela, sem "reduzir
  movimento" e enquanto ninguém tocou nela, e o toque nela é uma **ação
  acessível** ("Outra dica da Memora", 48 dp) que nunca leva a lugar nenhum.
- **Reage ao toque com um gesto** (aceno ou piscada) e mais nada: não abre,
  não fala, não navega. O gesto não existe para o leitor de tela, não acontece
  com "reduzir movimento", e a área dela fica a pelo menos 8 dp de qualquer
  botão (clarify da 013, 2026-11-15).
- É **vetor com volume** (luz e sombra em camadas), animada pelo aplicativo —
  nunca imagem recortada.
- Não aparece duas vezes na mesma tela (ponto levantado na T116).

### Transições
- Entre telas: deslizamento contínuo, com a direção do item 5 dos princípios.
- Dentro da tela: elementos entram com movimento curto e coordenado, não
  espalhado — um momento orquestrado vale mais que dez efeitos soltos.
- **Com "reduzir movimento" ligado no aparelho**: a transição vira troca suave
  ou instantânea, e a Memora fica parada na expressão certa. Isso não é opcional.
- **Aparelho de entrada** (Galaxy A/M, o mais comum no público): animação não
  pode travar a tela nem atrasar o toque.

### Ícones e ilustrações
- Vetoriais, nítidos em qualquer tamanho, com resposta visível ao toque.
- **Nunca imagem solta** (PNG recortado, ícone de outra família).
- Todo ícone interativo vem **com texto** (constituição, Princípio III).
- **Exceção:** as capturas dos guias são fotos reais da tela e continuam
  imagem (WebP; ver `CAPTURAS.md` e o contrato da 004).

### Blocos e superfícies (herdado da 007)
- Fundo suave, cartões claros, sombra sutil, borda pesada só onde a
  acessibilidade exige (campos, foco, alto contraste).
- **Informação nunca parece ação.** Cartão de leitura não tem pílula, seta nem
  preenchimento de botão; o que se toca tem pista explícita (FR-012 da 002).

### Voz do texto
- Português comum, literal, sem jargão ("aplicativo", não "app").
- A Memora fala em primeira pessoa e convida: "Vamos ver juntos", "Eu te mostro".
- Erro nunca culpa a pessoa: diz o que aconteceu e o que fazer agora.

## 4. Proibições

- ❌ **Visual de software dos anos 2000**: caixa de texto longa, borda grossa em
  todo bloco, botão com gradiente brilhante, cinza de sistema chapado, tela
  densa sem respiro, tabela onde caberia uma lista.
- ❌ **Emoji na interface** (títulos, botões, rótulos, avisos). Emoji fica só na
  fala da IA, no máximo um por mensagem, e **nunca carregando informação**
  ("✅ feito" no lugar de "feito"). O TalkBack lê cada emoji em voz alta.
- ❌ **A palavra "idoso"** (e "terceira idade", "melhor idade", "sênior") em
  qualquer texto que a pessoa veja.
- ❌ **Frase de incapacidade**: "é difícil para você", "não se preocupe se não
  entender", "até você consegue", "modo simplificado".
- ❌ Ícone sem texto; cor como único sinal; movimento como único sinal.
- ❌ Informação que só aparece animando (se a animação for desligada, sumiu).
- ❌ Valor visual literal fora dos tokens.

## 5. Como checar uma tela (antes de dar como pronta)

1. Passa na matriz de aparelhos (4 × 3) sem estouro e **continua usável**
   (não basta não estourar: o portão da FR-027 já foi decorativo uma vez).
2. Com "reduzir movimento" ligado, nada some e nada depende de animação.
3. Algum bloco tem mais de duas frases? Corte ou divida.
4. Algum texto contém as palavras proibidas ou soa como incapacidade?
5. A Memora aparece com a expressão certa, uma vez só, e o leitor de tela não
   repete o que o balão já disse?
6. Algum ícone sem texto, ou imagem solta onde deveria haver vetor?
7. **"Como um golpista exploraria esta tela?"** (Princípio II) — animação e
   beleza nunca podem esconder aviso, origem de link ou confirmação.
