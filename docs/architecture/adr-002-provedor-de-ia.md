# ADR 002 — Provedor de IA da assistente

- **Status:** Aceito — **risco aceito** pela FR-051 revista em 2026-10-03 e pela Emenda 1 ao Princípio I (constituição v1.1.0, aprovação unânime). Ver "A violação, com todas as letras" e "Revisão de 2026-10-03"
- **Data da decisão:** 2026-10-02
- **Decisor:** Henrique Moreira Sandrini (Scrum Master)
- **Contexto normativo:** [Constituição do Projeto](../../.specify/memory/constitution.md) — Princípio I (Segurança Acima de Tudo) e Princípio VI (A IA nunca age sozinha); [spec da 003](../../specs/003-hub-e-assistente/spec.md) — FR-022, FR-034, FR-047 e **FR-051**; [R2 do research](../../specs/003-hub-e-assistente/research.md)
- **Tarefas:** T061 (escolha), T062 (este documento), T063-T065 (adaptador, chave, teto de turnos), T086 (encerrada pela T105), T101-T105 (aviso, consentimento, revisão)

---

## Contexto

A feature 003 foi desenhada para **não depender** do provedor: tudo conversa com a
porta `ClienteDaAssistente`, e o `ClienteDaAssistenteSimulado` responde com
roteiros fixos. O adaptador do provedor é uma classe só (R2). Escolher o provedor
era a única decisão que travava a última fatia (a fase 8).

A R2 fixou seis coisas que precisam ser verdade, seja qual for o provedor, e um
método: rodar as mesmas conversas reais nos candidatos e comparar o passo a
passo. **O método não foi aplicado.** A equipe não tem verba, e a decisão abaixo
foi tomada pelo único critério que sobrou — o preço — que a própria R2 desaconselha
como critério único. Isto está dito aqui para que ninguém leia a ADR como se a
comparação tivesse acontecido.

## Decisão

**Google Gemini API, nível gratuito, modelo `gemini-3.6-flash` com reserva automática `gemini-3.5-flash-lite` (atualizado em 2026-11-20; decisão inicial de 2026-10-02 usava `gemini-3.8-flash`).**

| Item | Escolha |
|---|---|
| Provedor | Google Gemini API |
| Nível | **Gratuito** (sem faturamento no Google Cloud) |
| Modelo principal | `gemini-3.6-flash` — alinhado ao Render após ocorrências de `503` no `3.8-flash`. Configurável em `memora.assistente.gemini.modelo` |
| Modelo reserva | `gemini-3.5-flash-lite` — cota isolada e menor disputa no nível gratuito; acionado apenas antes do 1º trecho em `429` ou após falha nas retentativas (`5xx`, rede, prazo). Configurável em `memora.assistente.gemini.modelo-reserva` |
| Integração | REST direto, com o `HttpClient` do JDK; **não** o SDK oficial (ver abaixo) |
| Chave | Variável de ambiente `GEMINI_API_KEY`, sem padrão no repositório; o perfil `producao` não sobe sem ela |
| Seleção | `memora.assistente.provedor` (`MEMORA_ASSISTENTE_PROVEDOR`): vazio = simulado; `gemini` = real; `producao` = sempre real |

Fatos levantados nas páginas oficiais em 2026-10-02 (conferir de novo antes de
qualquer decisão que dependa deles — termos mudam):

- **Preços e níveis** — <https://ai.google.dev/gemini-api/docs/pricing>: no nível
  gratuito, "Used to improve our products: **Yes**"; no pago, "**No**". O pago exige
  faturamento no Google Cloud e um pré-pagamento mínimo de US$ 5.
- **Termos** — <https://ai.google.dev/gemini-api/terms>: nos *Unpaid Services* o
  Google usa o conteúdo para melhorar produtos; **revisores humanos podem ler
  entrada e saída** (desvinculadas da conta); e o texto diz literalmente "Do not
  submit sensitive, confidential, or personal information to the Unpaid Services".
  Exige 18+ de quem usa a API. O Brasil é região atendida.
- **Modelos** — <https://ai.google.dev/gemini-api/docs/models>: `gemini-3.1-pro` é
  *preview* e não é gratuito; `gemini-2.5-pro` só para quem já o usava.
- **API** — REST em
  `https://generativelanguage.googleapis.com/v1beta/models/{modelo}:streamGenerateContent?alt=sse`
  (SSE) e `:generateContent`; autenticação pelo cabeçalho `x-goog-api-key`.

## Revisão de 2026-10-03 — o risco passou a ser aceito

O `/speckit-clarify` de 2026-10-03 reescreveu a FR-051, e a equipe aprovou **por
unanimidade** a Emenda 1 ao Princípio I da constituição (v1.1.0). O que esta ADR
chama de "violação" abaixo continua sendo verdade sobre o serviço — o Google
treina com o conteúdo e revisores podem lê-lo —, mas **deixou de ser violação da
spec**: virou risco aceito, com quatro condições, todas na FR-051 e na emenda:

1. aviso permanente na conversa para não escrever senha, documento, endereço,
   saúde nem dinheiro (T101);
2. consentimento antes da primeira mensagem, e quem recusa fica com o resto do
   Memora (T102);
3. nenhum dado que identifique a pessoa no pedido (já provado por
   `PedidoAoProvedorTest.semDadoPessoal`);
4. **saída obrigatória**: trocar por um serviço que não treine e retenha no
   máximo 30 dias, por escrito, assim que houver verba. Não há data.

Consequências práticas, que **substituem** os itens de "Até que a revisão
aconteça" logo abaixo:

- **A T086 está encerrada** (pela T105): a evidência de termos que ela exigia
  deixou de ser requisito enquanto o serviço for do tipo gratuito. Ela volta a
  valer na troca de serviço da condição 4.
- **A T071 pode usar a chave gratuita**, desde que as condições 1 e 2 estejam no
  aplicativo que as pessoas usarem. Sem o aviso e o consentimento no app, a
  emenda não vale.
- O WARN de subida foi reescrito: diz que, com chave gratuita, o risco é o
  aceito pela FR-051 e pela emenda, e lembra a condição de saída.
- O teto de turnos (T065) passou a ser **janela deslizante de 20 turnos = 40
  mensagens** (FR-056; turno é uma troca). A divergência anotada em "O que foi
  feito para o cache" está resolvida.

## A violação, com todas as letras

A **FR-051** diz que o serviço externo que gera as respostas **não pode treinar
com o conteúdo das conversas**, que só pode retê-lo para monitoramento de abuso
por **no máximo 30 dias**, e que as duas garantias precisam estar documentadas no
contrato ou nos termos publicados **antes** de ele receber a primeira conversa
real.

**O nível gratuito do Gemini não cumpre isso.** Ele diz o contrário: usa o conteúdo
para melhorar os produtos do Google, e pessoas podem lê-lo. Não há contrato de
retenção a citar, e não há como a equipe obtê-lo sem migrar para o nível pago.

O efeito é exatamente o que a D3 e a R2 quiseram evitar: a conversa fica só no
aparelho (FR-047) e **viaja inteira ao Google a cada turno** (R3) — um acervo
sobre a intimidade de pessoas idosas, alvo preferencial de golpe no Brasil,
formado fora do nosso controle e sem aparecer no nosso código.

**O Henrique sabe disso e vai rodar `/speckit-clarify` para rever a FR-051.** Este
documento não altera a spec. Até que a revisão aconteça:

- **A T086 continua aberta.** Ela exige a evidência da FR-051 (link para o contrato
  ou termos que proíbem treino e limitam a retenção a 30 dias) e faz da ausência
  dela um bloqueio para a primeira conversa real. Com a chave gratuita **essa
  evidência não existe**, então a primeira conversa real continua bloqueada.
- **O Gemini gratuito serve para desenvolvimento e para conversa fictícia** —
  roteiros escritos pela equipe, sem nome, sem dado de ninguém. O teste opcional
  `ClienteDaAssistenteGeminiRealTest` faz uma pergunta inventada
  ("Como aumento a letra do celular?") e nada além disso.
- **A T071 (as cinco pessoas de 65+) não pode usar a chave gratuita.** É o ponto em
  que a violação deixaria de ser teórica: conversas reais de pessoas idosas
  entrariam num serviço que, pelos termos, pode usá-las para treino e mostrá-las a
  revisores. Ou a FR-051 é revista antes, ou o teste roda com chave do nível pago,
  ou roda com roteiro fictício.
- **A aplicação avisa a cada subida.** Com `provedor=gemini`, o log traz um WARN
  dizendo que, se a chave for do nível gratuito, a FR-051 não está cumprida. O
  aviso é condicional porque nada no código diferencia chave gratuita de paga.

### O que o nosso lado faz para reduzir o dano (e o que não consegue)

O `Pedido` que o adaptador envia contém: a persona (constante do código), o
catálogo de aplicativos (lido do banco: nome, descrição curta, pacote — dado do
produto, não de pessoa), o histórico que o aparelho mandou e a mensagem atual.
**Nenhum nome, e-mail, telefone ou identificador da pessoa viaja** — há teste
(`PedidoAoProvedorTest.semDadoPessoal`) que cria uma pessoa chamada "Ana", monta o
pedido e procura nome, UUID e `@` em tudo que seria enviado. O Google também não
recebe o IP da pessoa: vê o do nosso servidor, e a chave identifica o projeto, não
quem pergunta.

O que **não** há como filtrar é o **texto que a própria pessoa escreve**. A persona
a instrui a nunca pedir senha, código ou dado bancário, mas ninguém impede quem
conversa de digitar o nome de um neto ou um endereço, e isso viaja. É o conteúdo da
conversa — o centro do risco, e a razão de a FR-051 existir.

## Por que REST direto, e não o SDK oficial

O SDK Java do Google (`com.google.genai:google-genai`) usa **Jackson 2**
(`com.fasterxml.jackson.databind`). O Spring Boot 4 trouxe o **Jackson 3**
(`tools.jackson.*`), e os dois pacotes coexistem sem se falar: seria uma
dependência grande, com a árvore de transitivas dela, para fazer uma chamada HTTP
com corpo JSON e ler um fluxo de linhas. O `HttpClient` do JDK faz isso, e o corpo
do pedido fica visível em **um** arquivo — numa feature em que "o que viaja ao
modelo" é questão de privacidade, ler o pedido inteiro num lugar só vale mais que
a conveniência do SDK.

O custo: o formato do corpo e o do fluxo são nossos para manter. Se o Google
mudar o formato, quebra aqui. Mitigação: o teste opcional contra o serviço real
(com `GEMINI_API_KEY` definida) existe para ser rodado de vez em quando.

> **O adaptador nunca falou com o Gemini de verdade nesta entrega**: não havia chave.
> Os testes provam o que o adaptador *envia* e como ele *lê* o que o formato
> documentado diz que volta, contra um servidor falso. Que o serviço real aceita o
> pedido e responde como esperado só se prova rodando
> `ClienteDaAssistenteGeminiRealTest`, e o nome `gemini-3.8-flash` vem da decisão
> do Henrique, não de uma chamada nossa.

## Os seis critérios da R2, um a um

| # | Critério da R2 | Contra o Gemini gratuito |
|---|---|---|
| 1 | **Chamada de ferramenta** | **Atende**, segundo a documentação do modelo. A sugestão de abrir aplicativo é a função `sugerir_abrir_aplicativo(identificador_android)`, e **só** uma parte `functionCall` com esse nome vira `Sugestao`; prosa nunca é interpretada (teste que reprova se virar). Sugestão continua sendo só sugestão: o `AutorizadorDeAcao` decide (FR-022) |
| 2 | **Streaming** | **Atende.** `streamGenerateContent?alt=sse`; cada trecho vai ao `aoReceberTrecho` assim que chega (SC-007) |
| 3 | **Instrução de sistema** que a mensagem não sobrescreve | **Atende.** Persona e catálogo vão em `systemInstruction`; a mensagem da pessoa só em `contents`, com papel `user`. Teste: "ignore as instruções" nunca aparece em `systemInstruction` (FR-034). *Limite honesto:* o campo separa **onde** o texto entra, não impede um modelo de ser convencido — por isso a defesa real é o autorizador, depois da resposta |
| 4 | **Português do Brasil** com qualidade | **Não medido.** A R2 manda comparar conversas reais; isso não foi feito. Fica para a T068 e para a T093 (recusa idêntica sob insistência). É o ponto em que a decisão por preço mais pode custar |
| 5 | **Custo previsível por token**, com preço público | **Atende de forma peculiar:** no nível gratuito o custo é zero, e o que existe é **cota** (limite de uso por minuto/dia, que devolve HTTP 429). O preço do nível pago é público. A R7 (teto diário por conta) continua valendo — agora protege a cota compartilhada, não o dinheiro. A cota esgotada vira `ASSISTENTE_INDISPONIVEL` na voz da Memora |
| 6 | **Retenção de dados conhecida** | **Conhecida, e reprova.** Ver "A violação" acima. É o único critério que a R2 marcou como merecedor de peso extra — e é o que falha |

## Alternativas consideradas

### A. Gemini API, nível pago — *a saída natural da violação*

Mesmo modelo, mesmo adaptador (nada muda no código), mas com "Used to improve our
products: **No**". Exige faturamento no Google Cloud e pré-pagamento mínimo de
US$ 5. **Não foi escolhida por falta de verba**, não por mérito técnico — e é a
primeira coisa a fazer quando houver. Ainda assim, **o nível pago por si só não
cumpre a FR-051 por escrito**: a evidência exigida é um link para o contrato ou
termos que garantam a retenção de no máximo 30 dias para abuso, e isso precisa ser
lido nos termos do nível pago antes de a T086 poder ser fechada. Não se assume.

### B. Outros provedores, com chave paga

Não foram avaliados contra os critérios. A equipe não tem verba, e nenhum
candidato foi medido com as conversas da R2. Esta alternativa continua aberta —
a porta `ClienteDaAssistente` existe justamente para que trocar seja escrever
outro adaptador.

### C. Modelo rodando na infraestrutura da própria equipe

Resolveria a FR-051 de raiz (nada sai do nosso controle). Não foi considerado
viável: exige hardware e operação que o projeto não tem, e a qualidade em
português de modelos pequenos não foi medida.

### D. Ficar com o simulado até haver verba

É o que acontece **por padrão** (sem `MEMORA_ASSISTENTE_PROVEDOR`, o simulado
responde). Mas o produto sem assistente real não pode ser avaliado pelas cinco
pessoas de 65+ (T071), que é portão de saída. A decisão do Gemini gratuito existe
para destravar o **desenvolvimento** e as medições da T068 — não para atender
pessoas reais.

## Consequências

### Positivas

- A fase 8 destrava: o adaptador existe, é testado sem rede e liga com uma variável.
- Nenhuma mudança no resto do sistema: Hub, autorizador, trilha e telas não notam.
- Trocar para o nível pago, ou outro provedor, é trocar a chave ou escrever uma
  classe.

### Negativas

- **A FR-051 está violada** enquanto a chave for do nível gratuito e houver
  qualquer conversa que não seja fictícia.
- **A cota do nível gratuito é limitada e compartilhada por todas as contas.** Uma
  rajada de uso (ou um abuso) a esgota, e a assistente fica indisponível para
  todos — a negação de serviço que a R7 previa, agora sem custo em reais, mas
  igualmente real. A falha é tratada: a pessoa lê "estou com um pouquinho de
  dificuldade", e o motivo (`COTA_ESGOTADA`) vai para o log.
- **A conversa de uma pessoa é contada antes de falar com o provedor** (a ordem
  que o `ServicoDeConversa` já tinha, de propósito): uma chamada que falha por
  cota **gasta** o teto diário dela. É o preço de não deixar um atacante gastar a
  cota com chamadas que falham no fim.
- O formato do pedido é nosso para manter (REST direto).

### Neutras

- O texto de erro do Google nunca é lido nem repassado: o corpo de uma resposta de
  erro é descartado, e a exceção carrega só um motivo e, quando há, o status HTTP.
- A chave vai no cabeçalho `x-goog-api-key`, nunca na URL, e não aparece em
  mensagem de exceção nem em log.

## O que foi feito para o cache (T065)

O pedido segue a ordem **persona → catálogo → ferramenta → histórico → mensagem**:
do mais estável ao mais volátil. O Gemini tem **cache implícito** — reaproveita o
prefixo idêntico entre pedidos sem custo de configuração — e persona e catálogo são
idênticos a cada turno de todas as pessoas. Dado que varie por pessoa, posto antes
do histórico, destruiria o prefixo; por isso há teste que compara o prefixo de dois
pedidos de pessoas diferentes. **Não se usa a API de cache explícito**: ela cobra
armazenamento. O cache implícito tem um piso mínimo de tokens para entrar em ação,
e não foi medido se a persona mais o catálogo o alcançam — isso é parte da T068.

O **teto de turnos** (R3) já existia (`ServicoDeConversa.TURNOS_NO_PEDIDO = 20`,
corte pelo **fim**) e não tinha teste; agora tem. *Divergência a notar:* a R3 diz
"com a assistente encerrando com elegância e convidando a começar outra"; o código
faz **janela deslizante** — conversa mais longa segue funcionando e perde os turnos
mais antigos. Não foi alterado: é decisão de produto, não deste ADR.

## O que faria mudar de ideia

- **A revisão da FR-051 (`/speckit-clarify`)**: se a equipe aceitar a violação com
  limites escritos (por exemplo, só para desenvolvimento), este ADR passa a
  "Aceito" sem ressalva; se mantiver a FR-051, o provedor muda **ou** o nível passa
  a ser o pago, e a T086 só fecha com a evidência dos termos pagos.
- **Verba**: US$ 5 de pré-pagamento já tiram o "Yes" de "Used to improve our
  products" — é a mudança mais barata que existe, e deve ser feita **antes** da
  T071.
- **A T068 ou a T093 mostrarem português fraco, passo a passo inventado ou recusa
  que cede sob insistência** — a R2 avisa que o prejuízo recai sobre quem tem menos
  condição de perceber o erro. Qualidade ruim derruba a escolha, seja qual for o
  preço.
- **A cota gratuita se mostrar apertada** mesmo em desenvolvimento — 429 frequente
  no log.
- **Mudança nos termos ou nos preços do Google** — os fatos acima são de
  2026-10-02.
- **Chamada de ferramenta do modelo instável**: se `sugerir_abrir_aplicativo` não
  vier de forma confiável, a sugestão some (sem prejuízo de segurança, mas com
  prejuízo de produto).

## Validação pendente

- [ ] Rodar `ClienteDaAssistenteGeminiRealTest` com uma chave real (a T068 mede
      custo e latência de uma conversa típica)
- [ ] Comparar o Gemini com ao menos mais um candidato nas conversas da R2 (R2, "Como decidir")
- [x] **T086** — revisão da FR-051 feita em 2026-10-03 (risco aceito, Emenda 1); a evidência de termos volta a valer na troca de serviço
- [ ] T093 — recusa a serviço sensível idêntica sob insistência, com o modelo real
