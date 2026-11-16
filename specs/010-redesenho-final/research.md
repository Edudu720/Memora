# Pesquisa — feature 010 (redesenho final)

Cada decisão segue o formato Decisão / Por quê / Alternativas. As regras de UI
vêm da skill `memora-ux`; aqui está só o **como**.

---

## R1 — A Memora em 2.5D: desenho vetorial em camadas, pintado pelo aplicativo

**Decisão**: A Memora é desenhada **em código**, com um pintor por camada
(sombra no chão, corpo, cabeça, visor, olhos, antena, braço esquerdo, braço
direito, escudo), montadas numa pilha e animadas por transformações (rotação,
translação, escala) dirigidas por um controlador de animação. O volume do
"2.5D" vem de três recursos combinados:
1. **gradientes** em cada peça, com a luz vindo de cima à esquerda;
2. **sombra elíptica no chão**, que encolhe quando ela "sobe";
3. **leve perspectiva** (inclinação de poucos graus no eixo vertical, com
   ponto de fuga) e **paralaxe** entre camadas durante os gestos.

As cores saem de **tokens novos** em `MemoraCores` (`memoraCorpo`,
`memoraCorpoSombra`, `memoraVisor`, `memoraOlho`, `memoraDetalhe`,
`memoraEscudo`), definidos nos três temas e conferidos pelo `validar_paleta.py`
(contorno ≥ 3:1 com o fundo, FR-007).

As expressões (repouso, falando, pensando, comemorando, preocupada, acenando)
são **poses**: valores-alvo para olhos, braços, cabeça e escudo. Trocar de
expressão é interpolar entre poses; com "reduzir movimento", a pose-alvo é
aplicada direto.

**Por quê**:
- Atende ao clarify: vetor com volume, animado pelo aplicativo, sem artista
  externo e sem imagem solta.
- As cores ficam nos tokens: o alto contraste e o tema escuro saem de graça, e
  o `validar_tokens.py` continua enxergando tudo.
- Nenhuma dependência nova: só o que o Flutter já tem.
- Desligar a animação é trivial (pose fixa), o que cumpre o FR-004 e o V9.

**Alternativas**:
- **SVG em camadas** (`flutter_svg`, já no projeto): as cores ficam dentro do
  arquivo, e recolorir para três temas é frágil; o `validar_tokens.py` não varre
  SVG. Rejeitada.
- **Ferramenta de animação de personagem** (arquivo de animação exportado):
  exige editor visual e alguém que anime; o clarify escolheu "vetor em camadas".
  Rejeitada.
- **Animar os PNGs atuais**: continua imagem solta. Rejeitada no clarify.

**Risco**: o acabamento depende de quem desenha os caminhos. Mitigação: a folha
de expressões de `Memora-Desing-Ideias/` é a referência; a Memora entra no
álbum de telas e na galeria, e o Henrique aprova no celular antes de ela
substituir as imagens (portão da T116 da 004).

---

## R2 — Transições de tela: uma rota própria, com direção

**Decisão**: Uma rota do Design System, `RotaMemora`, que:
- desliza a tela nova da direita e empurra a anterior para a esquerda
  (paralaxe: a de trás anda cerca de 30% e escurece levemente);
- faz o inverso ao voltar, inclusive pelo gesto do sistema (FR-015);
- dura `MemoraMovimento.efetiva(lento)` (320 ms; zero com "reduzir
  movimento", quando a troca vira instantânea com um esmaecer curto);
- não deixa a tela que está saindo receber toque (FR-014).

O tema também registra a mesma transição como padrão de página, para que toda
rota de página que ainda não use a `RotaMemora` (inclusive as que a #71 trouxer)
herde o deslizamento sem mexer em cada chamada.

**Por quê**: Hoje as quatro rotas do aplicativo usam o padrão do Android
(zoom), e nenhum tema define transição. Uma rota própria dá controle sobre a
duração (o padrão é fixo em 300 ms e ignora "reduzir movimento"), e o tema
cobre o que escapar.

**Alternativas**: só o tema (não controla a duração nem respeita a preferência
do aplicativo); pacote de transições pronto (dependência a mais para o que são
duas animações).

---

## R3 — Troca de destino na barra inferior com direção

**Decisão**: A `CascaInterna` mantém um `Navigator` por destino (vivos, para
preservar a pilha de cada um), mas troca o `IndexedStack` por um componente
`TrocaDeDestino`:
- o destino que entra desliza do lado em que está na barra;
- o que sai desliza para o outro lado e depois fica fora da tela, sem animar e
  sem receber foco;
- com "reduzir movimento", a troca é instantânea.

**Por quê**: o `IndexedStack` não anima, e trocá-lo por um `AnimatedSwitcher`
destruiria a pilha de cada destino a cada troca (a pessoa perderia onde
estava).

**Alternativas**: `PageView` (permite arrastar entre destinos com o dedo, o que
cria troca acidental — o contrário do que se quer); manter sem animação
(contra a FR-011).

---

## R4 — Diálogos e folhas surgem por cima

**Decisão**: `Dialogo` e `FolhaInferior` ganham transições próprias: o diálogo
surge no centro (esmaecer + leve aumento de 96% a 100%); a folha sobe de baixo.
Ambas usam `MemoraMovimento.efetiva`.

**Por quê**: a FR-010 pede que a tela de trás não deslize; a sobreposição deixa
claro que a pessoa não saiu do lugar.

---

## R5 — Uma família de ícones: Material arredondado

**Decisão**: Todos os ícones passam a ser da variante **arredondada** dos ícones
Material que vêm com o Flutter (`*_rounded`). Os três ícones SVG próprios da
barra inferior (`assets/icones/navegacao/`, T112 da 004) são substituídos pelos
equivalentes arredondados. A resposta ao toque (FR-028) é a mesma da
`SuperficieTocavel`: leve afundar (`escalaPressionado`) e realce; sem
movimento, só o realce.

**Por quê**: a #71 já padronizou 44 ícones nessa variante; adotá-la evita
retrabalho e dependência nova. Vetorial, nítida em qualquer tamanho e
recolorida pelos tokens.

**Alternativas**: pacote de Material Symbols (mais ícones, mas dependência a
mais e fonte grande); desenhar uma família própria (sem prazo).

---

## R6 — Portão do texto curto: varredura lexical

**Decisão**: Um teste, `texto_da_interface_test.dart`, varre os arquivos de
texto (`app/lib/l10n/*.dart` e os guias em
`app/lib/features/aprendizado/data/guias/*.dart`), junta os literais
concatenados de cada constante e reprova quando:
- um bloco tem **mais de duas frases** (terminador `.`, `!`, `?` ou `…` seguido
  de espaço ou fim; ignora números como `1.000` e abreviações listadas);
- aparece **palavra proibida** ("idoso", "terceira idade", "melhor idade",
  "sênior", e a lista de frases de incapacidade da memora-ux), sem distinção de
  maiúsculas;
- aparece **emoji** (faixas Unicode de pictogramas e símbolos), exceto nos
  textos marcados como fala da IA.

No backend, um teste equivalente varre os textos que chegam à tela
(`CodigoDeErro` e as mensagens dos controladores) atrás de emoji. Hoje três
deles terminam com "😊" (`ControladorCanais`, `ControladorRecuperacao`,
`ControladorRegistro`) — contra a FR-020.

**Por quê**: o `sem_planos_test.dart` já faz varredura lexical de `l10n/` e
funciona. A regra das duas frases é objetiva o bastante para ser medida.

**Prova**: como todo portão do projeto, ele precisa ser quebrado de propósito
(um bloco de três frases, um "idoso", um emoji) antes de ser dado como pronto.

---

## R7 — No máximo um emoji por resposta da IA

**Decisão**: Duas camadas.
1. **Servidor**: a `PersonaDaMemora` ganha a regra "no máximo um emoji por
   mensagem, nunca no lugar de uma palavra".
2. **Aplicativo**: uma função pura, `limitarEmoji`, aplicada ao texto exibido
   da resposta: mantém o primeiro emoji e remove os seguintes (FR-024).

**Por quê**: o modelo pode desobedecer; a defesa no aplicativo não depende dele
(mesma lógica de "a saída do modelo não é autorização" da 003).

---

## R8 — Voz só no aparelho

**Decisão**: O leitor de voz da #71 passa a pedir reconhecimento **no
aparelho** (`onDevice: true`). Se o aparelho não oferecer, o botão de ditar
fica indisponível com o motivo em uma frase, e digitar continua funcionando.

**Dependência**: o código de voz só existe na #71. Esta decisão vira tarefa da
fase que espera a #71.

---

## R9 — A abertura com a Memora acenando

**Decisão**:
1. **Instante nativo** (antes do Flutter): o fundo de abertura do Android passa
   a ser a cor de fundo do tema com a Memora parada no centro (desenho vetorial
   do Android gerado a partir da mesma pose), nos temas claro e escuro. No
   Android 12+, a tela de abertura do sistema usa o ícone (que já é a Memora,
   FR-008) sobre o mesmo fundo.
2. **Abertura do aplicativo**: o `main.dart` chama o `runApp` **antes** de
   carregar as preferências. A primeira tela é a `AberturaMemora`: a Memora
   acenando, centralizada, na mesma posição do instante nativo. O carregamento
   (preferências, composição, cofre) roda por baixo.
3. **Saída**: quando o carregamento termina **e** o aceno em curso completa (no
   máximo ~1,5 s além do carregamento, FR-038/SC-009), a abertura sai com um
   esmaecer para o fluxo de autenticação.
4. **Reduzir movimento**: antes de carregar as preferências do aplicativo, só se
   conhece a preferência do sistema; a abertura usa ela (pose de aceno parada).
5. **Demora**: passados 4 s, aparece uma frase curta ("Estou quase pronta.").
   **Falha**: a abertura sai para a tela de erro com a Memora.

**Por quê**: a abertura nativa não pode rodar animação do aplicativo (ele ainda
não existe nesse instante); a única forma de ter o aceno é o aplicativo subir
primeiro e carregar depois. Manter a mesma posição e fundo nos dois instantes
evita o "pulo".

**Alternativas**: GIF ou vídeo na abertura nativa (imagem solta, não respeita
"reduzir movimento", e o Android 12+ ignora); pacote de splash nativo
(dependência para o que são dois arquivos de recurso).

---

## R10 — A Memora reage ao toque

**Decisão**: A `MemoraAnimada` aceita toque e responde com aceno ou piscada,
alternados. O toque:
- não tem semântica (fica fora da árvore do leitor de tela, FR-005b);
- é ignorado enquanto um gesto está em curso (sem acumular);
- não acontece com "reduzir movimento" (no máximo troca de expressão parada,
  FR-005d).

A distância mínima de 8 dp para qualquer alvo de verdade (FR-005c) é verificada
por teste nas telas em que ela aparece.

---

## R11 — Desempenho em aparelho de entrada

**Decisão**: Medir em modo de perfil, no aparelho de teste (S20 FE) e, se a
equipe tiver, num Galaxy A/M. Critério operacional do SC-005: menos de 5% de
quadros acima do orçamento de 16 ms durante a abertura, as trocas de tela e os
gestos da Memora. Medidas de projeto:
- a Memora fica isolada em camada de repintura própria;
- só anima enquanto está visível (fora da tela, o relógio dela para);
- os caminhos do desenho são montados uma vez e reaproveitados.

**Risco**: o S20 FE é mais rápido que a média do público. Se ninguém tiver
aparelho de entrada, a medição é feita no emulador com a CPU limitada, e o
risco fica registrado.

---

## R12 — Ordem em relação à #71

**Decisão**: Duas fases de implementação.
- **Fase A — independe da #71**: tudo o que nasce em arquivo novo ou em
  arquivo que a #71 não altera (conferido em 2026-11-15 com `git diff` contra a
  #71): `MemoraAnimada` e tokens dela, `RotaMemora`, `TrocaDeDestino` e a
  `CascaInterna` (não alterada), transições de `Dialogo` e `FolhaInferior` (não
  alteradas), `AberturaMemora` e o `main.dart` (não alterado), o portão de
  texto, `limitarEmoji` e o `TextoDaFala` (não alterado), a persona e o emoji
  do backend (não alterados).
- **Fase B — depois que a #71 entrar na `develop`**: o que toca arquivos que a
  #71 reescreve: ligar a `MemoraPersonagem` (`memora_personagem.dart`) ao
  desenho novo (mantendo o enum, incluindo `dica` e `mini`), registrar a
  transição no tema (`temas_memora.dart`), trocar a rota do
  `fluxo_autenticacao.dart`, a FR-035 na apresentação
  (`fluxo_apresentacao.dart`), o topo do Início, a conversa limpa
  (`balao_de_fala.dart`, `textos_assistente.dart`), a barra inferior, os tokens
  de cor que a #71 reescreve (`cores.dart`), a voz no aparelho, a reescrita dos
  textos dos guias, o Localizador e seus diálogos, e o álbum final.

**Por quê**: implementar a Fase B antes do merge da #71 geraria conflito nos
mesmos arquivos. A Fase A pode ir para a `develop` sem esperar.

**Atenção à Fase A**: os tokens novos da Memora entram num arquivo separado
(`tokens/cores_da_memora.dart`) até a #71 entrar, porque `cores.dart` é
reescrito por ela (+261 linhas). Na Fase B eles são integrados ao esquema de
cores.
