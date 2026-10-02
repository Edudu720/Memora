# Contrato: componentes novos do Design System

Cada componente abaixo entra em `app/lib/design_system/`, é exportado pelo barril
`design_system.dart` e **aparece na galeria** — o portão do V10 da 002 reprova
componente exportado que a galeria não mostre.

Todos herdam as garantias que o `BotaoBase` e os demais já carregam: toque de
48 dp, texto por `escalaTextoLimitada`, rótulo semântico, cor só por token,
movimento por `MemoraMovimento.efetiva`.

---

## `CabecalhoDeTela`

O topo de toda tela interna.

| Entrada | Obrigatória | Comportamento |
|---|---|---|
| `titulo` | sim | No máximo duas linhas; acima disso, reticências e o título inteiro no rótulo semântico |
| `aoVoltar` | não | Sem ela, não há "Voltar" (raiz de destino) |
| `ilustracao` ou `memora` | não | À direita. Some quando a altura disponível é pouca (regra 7 da R2) |

"Voltar" é sempre **ícone e texto**, sempre no mesmo canto (FR-001, US2 cenário 5).

## `CartaoDePorta`

Uma porta: do Hub, da Ajuda, de Configurações.

| Entrada | Obrigatória | Comportamento |
|---|---|---|
| `nome` | sim | Texto principal |
| `explicacao` | sim | Uma linha; quebra em duas se precisar, nunca estoura |
| `ilustracao` | sim | Encolhe antes do texto; abaixo do piso, some |
| `aoAbrir` | sim | O cartão inteiro é o alvo de toque |
| `principal` | não | Destaque de ação principal (FR-002). No máximo um por tela |

**É ação**, então usa preenchimento (FR-012 da 002). Informação nunca usa este
componente.

## `AvisoCompacto`

O aviso permanente que não ocupa a tela (R5).

| Entrada | Obrigatória | Comportamento |
|---|---|---|
| `titulo` | sim | Sempre visível, sempre na árvore — é o que os portões procuram |
| `resumo` | sim | Uma linha, visível fechado |
| `textoCompleto` | sim | Visível só aberto. Aberto, o aviso não passa de 50% da altura disponível; o resto rola dentro dele |
| `expressao` | não | Rosto da Memora "preocupada" ao lado |

Fechado por padrão. A escolha de abrir **não** é lembrada entre telas: quem
abriu uma vez vê fechado na próxima, para o aviso não virar paisagem aberta.

## `BalaoDeFala`

Uma fala na conversa, na apresentação e na ajuda guiada.

| Entrada | Obrigatória | Comportamento |
|---|---|---|
| `autor` | sim | `memora` ou `pessoa`. Muda **posição, rosto e nome**, além da cor (FR-020) |
| `texto` | sim | — |
| `opcoes` | não | Frases completas, empilhadas, com `alvoDecisao` (56 dp) e separação mínima de 16 dp (FR-021) |

O leitor de tela anuncia "Memora disse: …" e "Você disse: …".

## `PassoIlustrado`

Uma tela de passo a passo.

| Entrada | Obrigatória | Comportamento |
|---|---|---|
| `passo` | sim | Um `Passo` do [contrato de guias](guias.md) |
| `posicao`, `total` | sim | Alimentam o `IndicadorDePasso` |
| `aoContinuar`, `aoVoltar`, `aoTelaDiferente` | sim | As três saídas da FR-026 |

Desenha, nesta ordem: a moldura de celular, a captura, o **selo "Exemplo"** no
canto superior (FR-028, sempre presente, contraste medido nos três temas), o
**destaque** (anel na região relativa, com contraste de 3:1 contra a captura
nos dois lados do anel) e, embaixo, o texto. Se o passo `temCampoDeSenha`, o
aviso da FR-032 vem acima do texto, como `AvisoCompacto`.

## `IndicadorDePasso`

"Passo 2 de 4", **sempre em texto**, com a barra de progresso como reforço — a
barra sozinha seria informação só visual.

## `MemoraPersonagem`

Componente **novo** — não confundir com o `AvatarMemora`, que é o retrato do casal no cartão do cadastro e do login e continua existindo. Expressões: `neutra`, `falando`, `comemorando`,
`preocupada`. Decorativa por padrão; com `descricao`, anunciada. Nos temas escuro
e de alto contraste, sobre medalhão claro (R4).

## Tokens novos

| Token | Onde | Por quê |
|---|---|---|
| `MemoraTipografia.destaque` | título grande do Início e das boas-vindas | O wireframe abre com título de ~36; `tituloTela` (32) não dá a hierarquia |
| `MemoraTipografia.familia` | todos os estilos | Atkinson Hyperlegible Next (R3) |
| `MemoraDimensoes.ilustracaoCartao`, `ilustracaoCabecalho`, `ilustracaoHeroi`, `pisoDeIlustracao` | cartões, cabeçalho, telas de entrada | Hoje não existe tamanho de ilustração declarado; o `validar_tokens.py` passaria a acusar os literais |
| `MemoraDimensoes.tetoDoAvisoAberto` | `AvisoCompacto` | **Fração** (0,5), não pixel — a lição do teto da conversa |
| `MemoraDimensoes.alturaMinimaDaTarefa` | conversa | Fração (0,5) da FR-022 |

Toda cor nova passa pelo `validar_paleta.py`; toda dimensão nova, pelo
`validar_tokens.py`.
