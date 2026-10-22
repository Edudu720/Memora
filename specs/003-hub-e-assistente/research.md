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

## R2 — O provedor de IA fica em aberto

**Decisão**: a escolha do provedor e do modelo é **da equipe**, e não deste
plano. O que o plano fixa é a **porta** que a protege.

**Motivo**: a escolha envolve custo recorrente, conta a ser criada e paga, e
critérios que ninguém mediu ainda. Fixá-la aqui seria decidir por preferência —
e o Princípio IV existe para impedir exatamente isso.

**Como isso não trava a feature**: o resto do sistema conhece apenas
`ClienteDaAssistente`, uma porta com um método. O adaptador do provedor é a
única classe que importa o SDK dele.

Consequência prática, e é grande: **quase toda a feature é construída sem
provedor nenhum.** Hub, catálogos, `AutorizadorDeAcao`, trilha, telas, o
armazenamento local da conversa e todos os testes rodam contra
`ClienteDaAssistenteSimulado`, com roteiros fixos. Só a última fatia depende da
escolha — e ela é uma classe.

### O que precisa ser verdade, seja qual for o provedor

| Requisito | Por quê |
|---|---|
| **Chamada de ferramenta** (o modelo consegue pedir uma ação estruturada) | Sem isso, a sugestão viria como texto solto e o `AutorizadorDeAcao` teria que interpretar prosa — que é exatamente o tipo de análise frágil que a FR-022 evita |
| **Streaming** | O público do Memora é o que menos tolera tela parada: ver a resposta aparecendo é o que diferencia *"está pensando"* de *"travou"* (SC-007) |
| **Instrução de sistema** que a mensagem da pessoa não sobrescreve | A FR-034: conteúdo externo é dado, nunca instrução |
| **Português do Brasil** com qualidade | A persona da Memora é acolhedora e sem jargão. Tradução malfeita quebra a voz antes de quebrar o conteúdo |
| **Custo previsível por token**, com preço público | A R3 faz o custo crescer com os turnos; sem preço claro não dá para dimensionar o teto da R7 |
| **Retenção de dados conhecida** | O que trafega é conversa de pessoa idosa. Provedor que treina com o que recebe é incompatível com a classificação Confidencial da spec |

O último item merece peso: **a D3 recusou guardar a conversa no nosso servidor
para não criar um acervo sobre pessoas idosas.** Escolher um provedor que guarde
e treine com esse conteúdo desfaria a decisão por fora, e ninguém perceberia lendo
o nosso código.

### Como decidir

Rode o mesmo punhado de conversas reais nos candidatos, com a persona já escrita,
e compare: acerta o passo a passo do aplicativo de verdade? Inventa caminho
quando não sabe (FR-012)? Respeita *um passo por vez* (FR-008)? Oferece executar
antes de ensinar (FR-014)?

**Não escolha por preço na tabela.** Um passo a passo inventado leva a pessoa a
tocar no que não pretendia, e o prejuízo recai sobre quem tem menos condição de
perceber o erro — o custo por token é a parte barata da conta.

### Atualização de 2026-10-02 — a escolha foi feita, e ela viola a FR-051

O Henrique escolheu o **Gemini API, nível gratuito, modelo `gemini-3.8-flash`**,
por falta de verba; a comparação com conversas reais deste "Como decidir" **não
foi feita**. O nível gratuito deixa o Google usar o conteúdo para melhorar os
produtos dele e permite revisão humana, o que **desfaz a FR-051** (e o último item
da tabela acima). Registro completo, com os seis critérios, as alternativas e o que
faria mudar de ideia, em [ADR-002](../../docs/architecture/adr-002-provedor-de-ia.md).
**Pendência**: a FR-051 será revista em `/speckit-clarify`; até lá a T086 continua
aberta e nenhuma conversa real (nem a T071, com as cinco pessoas de 65+) pode passar
por esta chave.

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
- **Janela deslizante de turnos**: o pedido leva só os 20 turnos mais recentes,
  e a conversa nunca é encerrada por tamanho (FR-056, clarificação de
  2026-10-03). Também protege o contexto e reduz o que viaja ao provedor.
  *Versão anterior*: "teto de turnos, com a assistente encerrando com elegância
  e convidando a começar outra" — descartada por contrariar a FR-053, que
  proíbe interromper a pessoa no meio de um passo.

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

**Decisão**: sem a chave da API, o bean do adaptador não existe e o perfil
`producao` **não sobe**. Em desenvolvimento, `ClienteDaAssistenteSimulado`
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
| 1 | **Escolher o provedor de IA e o modelo**, contra os critérios da R2 | Equipe — **não bloqueia a construção**, só a última fatia |
| 1b | **Conta e chave do provedor escolhido**, e quem paga | Equipe — bloqueia a integração real |
| 2 | **Semear o catálogo**: quais aplicativos entram como cotidianos e quais serviços entram como sensíveis | Equipe — decide o alcance da assistente |
| 3 | **Teto de conversas por dia**: qual número | Equipe — número arbitrário sem uso real para medir |
