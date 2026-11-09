# Divergências entre o protótipo e o Design System

> **FR-038**: toda divergência entre o valor visual do protótipo e o token final
> precisa estar registrada **com a medição que a justificou**. Este arquivo é
> essa lista. É a T052 da feature 002.
>
> A regra que ele obedece: **nada aqui é opinião.** Cada linha tem um número
> medido ao lado, e a ferramenta que o produziu. Onde não há medição, está
> escrito que não há.

**Método**: duas das medições vieram de ferramentas versionadas em
`specs/002-design-system/ferramentas/` — `amostrar_cores.py` (2.962.440 pixels
em 36 telas; só reexecutável por quem tiver as imagens do protótipo) e
`validar_paleta.py` (51 pares de contraste nos três temas; reexecutável por
qualquer um). **A medição dos botões SIM/NÃO (seção 1) foi feita com um script
avulso que nunca entrou no repositório** — `medir_botoes.py` não existe em
nenhum commit. Os números daquela seção são o registro, e **não podem ser
reproduzidos a partir do repositório**.

---

## O resumo em uma linha

**O protótipo acertou a paleta e errou o tamanho.** A expectativa inicial da
equipe era a oposta — que as cores precisassem ser trocadas —, e a medição
desmentiu. Corrigir o que não estava quebrado teria descaracterizado o projeto
sem ganho nenhum.

---

## 1. Altura dos botões de confirmação — **a divergência mais grave**

| | Protótipo | Design System |
|---|---|---|
| Altura | **24 px** | **48 dp** (`alvoMinimo`), **56 dp** em decisão (`alvoDecisao`) |

**Medição** (tela de Chatbot; script avulso que não foi commitado, ver o aviso do Método):

| Botão | Cor | Tamanho | Contraste com texto preto |
|---|---|---|---|
| SIM | `#9EEE7E` | **77×24 px** | 14,98:1 |
| NÃO | `#E87B7B` | **77×24 px** | 7,55:1 |
| Separação entre eles | — | 62 px | adequada |

**Por que diverge**: 24 px é **exatamente metade** do mínimo de 48 dp da WCAG
2.2 e das diretrizes Android. Para o público desta aplicação — menor precisão
motora, tremor, dedo maior que o alvo — um botão de metade do tamanho não é
estética: é toque que erra.

**Premissa declarada**: a tela do protótipo tem 390 px de largura, compatível
com um quadro de 390 dp em densidade 1x, então px ≈ dp. Se o protótipo tiver
sido exportado em outra densidade, a proporção se mantém — a altura continua
sendo metade da largura mínima de alvo.

### ⚠️ Uma avaliação anterior estava errada, e fica registrado

A primeira análise afirmou que esses botões **reprovavam em contraste**. Não
reprovam: 14,98:1 e 7,55:1 passam inclusive no nível AAA. Era impressão visual,
não medição.

Vale mais do que a correção em si: dos dois problemas apontados de olho, **um
não existia e o outro era pior do que parecia**. É a razão de este arquivo
exigir número ao lado de cada linha.

---

## 2. A paleta — três cores preservadas, o resto derivado

### Preservadas exatamente como no protótipo

| Token | Valor | Ocorrência no protótipo | Contraste medido |
|---|---|---|---|
| `fundo` | `#F8F8F8` | 33,37% | — |
| `superficieAlt` | `#D8D8D8` | 12,37% | 14,73:1 com texto preto |
| `primaria` | `#1040F8` | 3,76% | **6,75:1** com texto branco |

**Não há divergência aqui, e isso é o achado.** A identidade visual do Memora já
atendia à WCAG. `#1040F8` é a cor do projeto e continua sendo.

### Descartada

| Cor | Ocorrência | Contraste | Por quê |
|---|---|---|---|
| `#7090E8` | 0,10% | **3,07:1** com branco, **2,89:1** com o fundo `#F8F8F8`; 6,15:1 com texto `#111111` | Como cor de texto ou de rótulo sobre fundo claro, fica abaixo de 4,5:1; só serve de preenchimento com texto escuro, e a primária já ocupa o papel de preenchimento com texto branco |

Ela não entrou na paleta em papel nenhum. Aparecia em 0,10% dos pixels, o que
sugere uso decorativo; mas um token existe para ser usado, e um token
com papel ambíguo (texto escuro? preenchimento? foreground?) é uma armadilha esperando alguém.

### Derivadas — sem contraparte no protótipo

O protótipo não tinha valores declarados para texto, borda, sucesso e perigo:
essas cores foram **derivadas e ajustadas até atingirem conformidade**.

| Token | Valor (tema claro) | Origem |
|---|---|---|
| `superficie` | `#FFFFFF` | derivada |
| `texto` | `#111111` | derivada |
| `textoSuave` | `#4A4A4A` | derivada |
| `borda` | `#6B6B6B` | derivada |
| `sucesso` | `#186A2E` | derivada |
| `perigo` | `#B3231F` | derivada |
| `sobrePrimaria` / `sobrePerigo` | `#FFFFFF` | derivadas |

**Margens mais apertadas** — as que exigem atenção em qualquer alteração futura:

| Par | Tema | Resultado | Exigido |
|---|---|---|---|
| primária sobre superfície_alt | claro | 4,74:1 | 3:1 |
| borda sobre fundo | claro | 5,02:1 | 3:1 |
| perigo sobre fundo | claro | 6,22:1 | 4,5:1 |

⚠️ **Alterar qualquer valor de `tokens/cores.dart` exige rodar
`validar_paleta.py` antes do commit.** O portão está no CI, mas descobrir na
verificação contínua custa uma ida e volta que a ferramenta local evita.

### O balão de chat, que não virou token

`#78B8D8` aparece em 0,68% dos pixels, como fundo do balão do chat, e mede
9,64:1 com texto preto — passa com folga. **Não virou token** porque a feature
003 resolveu a conversa com `superficie` e `superficieAlt`, que já distinguem
quem falou. Um token a mais para uma cor usada em um lugar só é escala que
ninguém pediu.

---

## 3. Tipografia — o protótipo usava serifa

| | Protótipo | Design System |
|---|---|---|
| Família | Serifada (tela de Chatbot) | **Sem serifa** |
| Corpo | não declarado | **18 sp** |
| Mínimo absoluto | não havia | **16 sp** |

**Por que diverge** (FR-006): serifa reduz legibilidade em baixa visão e em
telas de baixa densidade — que é a combinação mais provável no aparelho do
público-alvo.

Os 18 sp de corpo estão **acima** do padrão de 14–16 sp de aplicativos comuns, e
o piso de 16 sp vale inclusive para aviso legal e mensagem auxiliar — que é
justamente onde interface costuma encolher a fonte.

⚠️ **Não há medição do tamanho de fonte do protótipo.** Os valores foram
derivados da literatura de acessibilidade, não amostrados. Está escrito aqui
porque o resto deste arquivo tem número, e a ausência precisa ser visível.

---

## 4. Forma — o que foi preservado de propósito

| Token | Valor | Origem |
|---|---|---|
| `MemoraRaio.pilula` | 999 | **a forma dos botões do protótipo** |
| `MemoraRaio.padrao` | 12 | derivado |
| `MemoraRaio.cartao` | 24 | derivado |

A pílula não é escolha estética arbitrária: ela virou **a linguagem que separa
ação de informação** (FR-012). Ação usa pílula e preenchimento; informação nunca
usa nenhum dos dois. Era a forma que o protótipo já dava aos botões, e mantê-la
fez a regra nascer reconhecível.

---

## 5. Divergências que apareceram depois, na implementação

Estas não vieram da comparação com o protótipo — apareceram construindo, e estão
aqui porque também são valores visuais que divergiram de uma intenção anterior.

| O quê | Antes | Depois | Medição |
|---|---|---|---|
| Tamanhos de ícone | **sete** valores soltos (18, 20, 22, 24, 28, 56, 72), nenhum declarado | escala de 4 degraus em `MemoraDimensoes` | quatro deles eram "ícone ao lado de texto"; quatro pontos mudaram, todos +2 dp |
| Estado desabilitado | `Opacity` | `superficieAlt` + `textoSuave` | `Opacity` derrubava o contraste do rótulo para **2,79:1**; a substituição mede **6,22:1** |
| Teto de altura da conversa | 420 px fixos | fração da tela disponível | 420 px cabiam num 390×844 e estouravam **133 px** num 360×640, já em 100% |
| Rótulo "Mostrar senha" | `Text` solto numa `Row` | `Flexible` | estourava **31 px** pela direita num 320×568 em 100%, e **265 px** em 200% |

---

## 6. Divergências do wireframe na Feature 004 (`004-redesenho-das-telas`, T107)

Na implementação das 35 telas do wireframe do Arquivo X, as divergências abaixo foram introduzidas por requisitos de segurança (Princípios I e II) ou medições de acessibilidade (Princípio III):

| Item do wireframe | Implementação na Feature 004 | Medição / Justificativa |
|---|---|---|
| **Passo a passo por cima do aplicativo real** (Figuras 21–24 e 29–36) | Passo a passo **inteiro dentro do Memora** (`TelaPassoAPasso` / `PassoIlustrado`), com captura marcada com o selo `"Exemplo"` (`FR-028`, `FR-029`) | Desenhar por cima de outro aplicativo exige `SYSTEM_ALERT_WINDOW`, a permissão mais explorada por trojans bancários no Brasil (Princípio II) |
| **Aviso de segurança fixo ocupando o topo da conversa** | `AvisoCompacto` aberto até a 1ª pergunta e encolhido para escudo de `48 dp` depois dela (`FR-022`, `R5`) | **Medido**: o aviso fixo chegava a ocupar **~90%** da altura útil em `320×568` a `200%`; com o `AvisoCompacto`, a área útil da conversa + campo de texto mantém **≥ 50%** da altura disponível em `100%` e `150%` (`conversa_espaco_util_test.dart`) |
| **Hub sem rolagem em qualquer escala** (Figura 9) | Hub inteiro sem rolar em `360×800` a `100%`; em escalas maiores ou aparelhos menores, a porta principal fica à vista sem rolar junto com a faixa `"Role para baixo para ver mais opções"` (`FR-017`, `T113`) | **Medido na T113**: em `360×800` a `150%`, o cabeçalho toma `200 px` e a 5ª porta termina `~170 px` abaixo da barra (`138 px` com respiro no piso); em `320×568` a `200%`, o cabeçalho toma `326 px` de `421 px` disponíveis (`hub_cabe_sem_rolar_test.dart`) |
| **"Apps atuais" em grade** (Figura 20) | `"Meus aplicativos"` em **lista vertical**, com ícone à esquerda, nome ao lado e busca no topo (`FR-023`, revisão da `T044`) | Ícone à esquerda com o nome na mesma linha evita truncamento em `150%`/`200%` e permite leitura linear de relance |
| **Logotipos oficiais em "Serviços sociais"** (Figura 28) | Pictogramas próprios do Design System para serviços sensíveis; logotipos de marca restritos a aplicativos cotidianos (`R7`, `FR-030`) | Evita que a pessoa se acostume a ver marcas de banco/governo dentro de outro aplicativo, reduzindo a superfície para páginas de phishing (Princípio II) |
| **Link para `ajudamemora.com.br` na Ajuda** (Figura 14) | Removido; substituído pela saída direta para a conversa com a Memora (`R12`, `FR-037`) | O domínio citado no wireframe não pertence ao projeto; apontar para domínio não registrado exporia o usuário a registro malicioso por terceiros |
| **Tela de Planos e campo de plano no Perfil** (Figuras 10 e 27) | Fora do aplicativo; validado por scanner estático (`sem_planos_test.dart`, `US9`, `FR-008`) | Monetização fora de escopo; exibir cobrança ou assinatura cria vetor para o golpe *"seu plano do Memora venceu"* |
| **"Tela" e "Acessibilidade" juntas em Aparência** (Figuras 25 e 26) | Separadas em duas portas distintas em Ajustes (`Aparência` e `Acessibilidade`) + `Privacidade` e `Conta` (`FR-038`, `FR-039a`) | Acessibilidade é requisito central do produto, não preferência estética; em `Aparência`, a cor livre foi substituída por **6 paletas curadas** aprovadas em contraste (`validar_paleta.py`, `FR-039`) |

---

## O que este arquivo não cobre

- **Ilustrações e ícones do protótipo** não foram medidos individualmente. O que
  entrou em `app/assets/ilustracoes/` veio do protótipo e não passou por
  avaliação de contraste própria — ilustração não carrega informação que o texto
  ao lado já não carregue, mas isso é uma afirmação de desenho, não uma medição.
- **Layout de tela** não é comparado aqui. O protótipo tem 38 telas e o Design
  System não é uma delas; a fidelidade de cada tela é assunto da feature que a
  implementa.
- **V7 e V8 do quickstart** — as duas validações com 5 pessoas de 65+ anos —
  continuam **não executadas**. Elas são o portão de saída da feature 002, e
  nenhuma linha deste arquivo substitui as duas.
