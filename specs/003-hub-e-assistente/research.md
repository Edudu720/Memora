# Research — Hub e a assistente que ensina

Decisões técnicas da feature 003, com o que foi descartado e por quê.

---

## R1 — Onde a inteligência mora: no backend

**Decisão**: o aplicativo fala com o nosso backend, e só o backend fala com o
provedor de IA.

**Motivo**: três coisas exigem isso, e nenhuma delas admite contorno.

1. A **FR-022** manda validar de forma determinística o que pode ser executado,
   **fora do modelo**. Se o aplicativo falasse direto com o provedor, a
   autorização estaria no aparelho — onde quem controla o aparelho controla a
   autorização.
2. A Constituição proíbe chave de API no aplicativo: *"Nenhum secret, API key ou
   URL sensível hardcoded — chaves vêm do backend"*. Chave embutida em APK é
   extraível, e a conta é nossa.
3. A **FR-020** exige trilha auditável. Trilha escrita pelo próprio aparelho que
   executou a ação não é auditoria; é declaração.

**Descartado**: chamada direta do aplicativo ao provedor. Mais simples e mais
barato de construir, e insustentável nos três pontos acima.

---

## R2 — Modelo: `claude-opus-5`

**Decisão**: `claude-opus-5`, com **thinking adaptativo** e **streaming**.

**Motivo**: é o padrão da plataforma, e a tarefa não é trivial — a assistente
precisa entender pedido escrito com erro de digitação (FR-007), decidir se
ensina ou oferece executar (FR-014), e nunca inventar caminho (FR-012). Um passo
a passo inventado leva uma pessoa idosa a tocar em coisas que ela não pretendia.

| Modelo | Entrada / Saída por 1M | Observação |
|---|---|---|
| `claude-opus-5` | **US$ 5 / US$ 25** | Escolhido |
| `claude-sonnet-5` | US$ 2 / US$ 10 | Troca de uma linha, se a equipe quiser |
| `claude-haiku-4-5` | US$ 1 / US$ 5 | Mais barato; menos confiável no julgamento de ensinar × executar |

**A troca de modelo é uma linha** em `ClienteClaude`. Baixar o modelo é decisão
da equipe, não do plano — e vale medir com conversas reais antes, porque o
prejuízo de um passo a passo errado recai sobre quem tem menos condição de
perceber o erro.

**Streaming** porque o público é o que menos tolera tela parada: ver a resposta
aparecendo é o que diferencia *"está pensando"* de *"travou"* (SC-007).

---

## R3 — A conversa não é persistida no servidor

**Decisão**: o aplicativo guarda a conversa e **envia o histórico a cada turno**.
O backend é sem estado quanto ao conteúdo.

**Motivo**: a **D3** da spec decidiu que a conversa fica só no aparelho, e a
razão é o que ela evitaria — um acervo Confidencial sobre a intimidade de
pessoas idosas, que são o alvo preferencial de golpe no Brasil.

**O preço, declarado**: o histórico viaja e é cobrado como entrada a cada turno,
então o custo de uma conversa cresce com o quadrado do número de turnos. Duas
mitigações:

- **Prompt caching** no bloco estável — persona e catálogo vão primeiro, e o
  histórico depois do último ponto de cache. É o que a ordem `system` → `messages`
  permite.
- **Teto de turnos por conversa**, com a assistente encerrando com elegância e
  convidando a começar outra. Também protege o contexto.

**Descartado**: sessão no servidor. Mais barata em tokens e mais simples de
implementar — e é exatamente o acervo que a D3 recusou.

---

## R4 — A trilha de auditoria fica no servidor

**Decisão**: `EventoDaAssistente` no PostgreSQL, **somente inserção**, no mesmo
molde de `EventoAutenticacao`.

**Motivo**: parece contradizer a R3, e não contradiz — são coisas diferentes. A
trilha registra **que uma ação foi executada**, e nunca o conteúdo da conversa
(FR-036). É auditoria, e auditoria que o auditado pode apagar não serve.

A FR-023 exige que a **pessoa** veja o registro. Guardado só no aparelho, ele
sumiria ao sair da conta — e sair da conta é justamente o que alguém faria depois
de usar a conta de outra pessoa.

Reusa o padrão que já existe: entidade `@Immutable`, gatilho
`tg_evento_somente_insercao` recusando UPDATE **no banco**, e `DELETE` permitido
para o expurgo por retenção.

---

## R5 — A autorização é uma consulta, não uma resposta

**Decisão**: o modelo declara uma ferramenta `abrir_aplicativo`. Quando ele a
chama, o `AutorizadorDeAcao` consulta o catálogo no banco e só deixa passar se o
serviço existir **e** for da categoria `COTIDIANO`. Sugestão que não passa é
descartada em silêncio, e a pessoa nunca vê o oferecimento.

**Motivo**: é a **FR-022** literal, e é o que torna a injeção de prompt
inofensiva para o que importa. Alguém pode conseguir fazer o modelo pedir para
abrir o aplicativo do banco; ninguém consegue fazer o catálogo dizer que o banco
é `COTIDIANO`.

O catálogo também vai no system prompt, para o modelo não oferecer o que será
recusado — mas **isso é conveniência, não segurança**. A verificação depois da
resposta é a que vale.

**Descartado**: confiar na instrução do system prompt. É a diferença entre pedir
e garantir.

---

## R6 — Catálogo no banco, não em arquivo

**Decisão**: `servico_conhecido` como tabela, semeada por migration.

**Motivo**: tirar um aplicativo do ar — porque virou vetor de golpe, porque mudou
de dono — não pode depender de novo build e nova publicação na loja. A FR-022
também pede autorização **consultável**: uma tabela responde *"por que isto foi
autorizado em 12 de março"*; uma constante compilada não.

---

## R7 — Limite de gasto por conta

**Decisão**: `LimitePorConta` — teto de conversas por conta e por dia, com estado
no banco, no mesmo molde do `LimitadorTentativas` da feature 001.

**Motivo**: **não estava na spec**, e é consequência direta de existir um
endpoint autenticado que gasta dinheiro por chamada. Sem teto, uma conta
comprometida esgota a cota da API e derruba a assistente para todo mundo — uma
negação de serviço que se paga em reais.

Fica registrado aqui como decisão de arquitetura. Se a equipe entender que o
limite muda o comportamento visível para a pessoa — e ele muda, quando alguém
esbarra nele —, o lugar de resolver é a spec.

---

## R8 — Sem provedor configurado, a aplicação não sobe

**Decisão**: sem a chave da API, o bean do `ClienteClaude` não existe e o perfil
`producao` **não sobe**. Em desenvolvimento, um `ClienteDaAssistenteSimulado`
responde com roteiros fixos.

**Motivo**: é a mesma escolha do `EnviadorDeCodigo` na US5 da feature 001, e pelo
mesmo motivo. Subir sem provedor faria a assistente responder erro a cada
pergunta — pior do que não subir, porque a falha apareceria para a pessoa idosa
em vez de para quem implanta.

Diverge de propósito de `ConfiguracaoDeToken` e `ConfiguracaoDeRastreio`, que
sorteiam valor e seguem com WARN: lá o prejuízo é interno e reversível.

---

## R9 — Conteúdo externo é dado, nunca instrução

**Decisão**: tudo que vem do aparelho entra como conteúdo de mensagem da pessoa.
Nada vindo do aplicativo altera o system prompt, e a `PersonaDaMemora` é
constante versionada no servidor.

**Motivo**: a **FR-034**. Uma pessoa pode colar no chat o texto de uma mensagem
de golpe — e esse texto vai conter instruções. Elas precisam chegar ao modelo
como o que são: o relato de alguém pedindo ajuda.

A defesa real não é o modelo resistir à instrução, e sim a R5: mesmo obedecendo,
o modelo não consegue autorizar nada.

---

## R10 — O aplicativo abre, o backend nunca

**Decisão**: quem abre o outro aplicativo é o Flutter, depois da confirmação. O
backend só diz *"esta ação está autorizada"*.

**Motivo**: o backend não tem como abrir aplicativo no aparelho de ninguém, e
não deve ter. A confirmação da FR-015 acontece onde a pessoa está, com
`ConfirmacaoMemora`, que já existe no Design System.

O aviso de saída do Memora (FR-021) também é do aplicativo, e reusa o idioma que
a feature 001 já estabeleceu.

---

## Pendências que este research abre

| # | O quê | Para quem |
|---|---|---|
| 1 | **Conta e chave da Claude API**, e quem paga | Equipe — bloqueia a integração real |
| 2 | **Semear o catálogo**: quais aplicativos entram como cotidianos e quais serviços entram como sensíveis | Equipe — decide o alcance da assistente |
| 3 | **Teto de conversas por dia**: qual número | Equipe — número arbitrário sem uso real para medir |
