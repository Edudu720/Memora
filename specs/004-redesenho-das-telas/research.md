# Research: Redesenho das telas

**Feature**: [spec.md](spec.md) · **Plano**: [plan.md](plan.md) · **Data**: 2026-10-01

Cada decisão segue o formato **Decisão / Por quê / Alternativas descartadas**, e
termina com **o que faria mudar de ideia** quando isso não for óbvio.

---

## R1 — A casca de demonstração sai, e entra a casca do aplicativo

**Decisão**: `AplicativoMemora.home` deixa de ser a `CasaDemonstracao`. A raiz
passa a ser o `FluxoAutenticacao`, e quando a pessoa está dentro ele monta uma
**casca interna** (`features/casca/`) com a barra inferior de três destinos
(Configurações · Início · Perfil). Cada destino tem a própria pilha de
navegação, e o Hub, a conversa, os catálogos, a Ajuda e o passo a passo são
rotas empilhadas sobre o Início.

A galeria do Design System continua existindo só em `kDebugMode`, e passa a ser
alcançada por uma linha em Configurações que **só existe** quando
`GaleriaMemora.paraDesenvolvimento()` não devolve `null`. O contrato da R9 da
002 (sem botão em release) continua intacto.

**Por quê**: o diagnóstico 2 da spec — a pessoa vê o andaime. E o
`FluxoAutenticacao` já é quem sabe se há sessão, quem envolve as rotas no
`Listener` de atividade (`_rota(...)`) e quem fecha tudo quando a inatividade
expira (`_fecharRotasAbertas`). Pôr a casca **dentro** dele mantém os três
portões da revisão de 2026-10-01 valendo sem reescrevê-los.

**Alternativas descartadas**:
- *Casca acima do fluxo de autenticação*: a casca existiria antes do login, e a
  barra inferior apareceria na tela de cadastro.
- *Um `Navigator` só, com a barra redesenhada em cada tela*: a barra viraria
  cópia em cada tela — como componentes duplicados começam a divergir, que é o
  aviso que a galeria da 002 já registrou.

⚠️ **O aviso de inatividade usa o `Navigator` raiz** (pendência da #35). Com
pilhas por destino, `_fecharRotasAbertas` precisa fechar **as três** pilhas.
O portão `fluxo_dentro_da_conta.dart` precisa ganhar um caso com rota aberta
em cada destino.

---

## R2 — O que "prático, intuitivo, profissional e moderno" quer dizer aqui

**Decisão**: a direção visual é escrita como **sete regras verificáveis**, e não
como adjetivo:

1. **Uma ação principal por tela**, preenchida; as outras, contornadas ou em
   texto (FR-002).
2. **Cabeçalho único**: "Voltar" à esquerda, título em duas linhas no máximo,
   ilustração ou rosto da Memora à direita quando houver.
3. **Portas com ilustração** no lugar de listas de botões iguais: cada porta do
   Hub, cada assunto da Ajuda, cada grupo de Configurações é uma **pílula
   grande e preenchida**, com desenho, nome e uma linha de explicação.
   ⚠️ *Corrigido ao implementar*: a primeira versão dizia "cartão", e o
   `Cartao` do Design System **não é clicável** de propósito — "ação usa
   pílula e preenchimento; informação nunca usa nenhum dos dois" (FR-012 da
   002). Um cartão tocável seria a terceira linguagem que essa regra proíbe. A
   pílula grande é a própria linguagem do wireframe (as pílulas azuis do Hub),
   com desenho e explicação.
4. **Fundo com profundidade**: superfície clara com sombra suave, em vez de
   pílula azul sobre cinza liso. A porta (ação) é pílula com `MemoraRaio.porta`
   (ver o contrato de `CartaoDePorta`); a informação continua no `Cartao`.
5. **A Memora é personagem**: o robô do wireframe, redesenhado, em todo lugar
   onde ela fala (FR-003).
6. **Espaço respira**: o espaçamento entre blocos sobe um degrau (`xl` → `xxl`)
   nas telas de leitura.
7. **A ilustração cede espaço primeiro**: em pouca altura ela encolhe e, abaixo
   de um piso, some — o texto e a ação nunca. É a mesma lição do teto da
   conversa: a conta é refeita por aparelho, nunca em pixel fixo.

**Por quê**: SC-004 e SC-005 medem "bonito" com gente. Sem regra escrita, a
revisão de design viraria gosto, e o próximo a mexer numa tela não teria como
saber se está dentro ou fora da linguagem.

**Alternativas descartadas**: adotar um kit pronto de terceiros. Traria a cara
de outro produto e não conhece a matriz de 200%, os três temas nem a separação
dado × ação (FR-012 da 002).

**O que faria mudar de ideia**: a revisão de design da equipe (SC-005) reprovar
a primeira tela feita com essas regras. A US2 é a primeira a ser implementada
justamente para isso aparecer cedo.

⚠️ **Revista depois da T044 (2026-10-01).** A revisão do Henrique não reprovou
a direção — fonte, paleta, personagem e barra inferior ficam —, mas achou o
resultado **junto demais e simples demais** para quem usa. As sete regras
continuam, e três mudam ou entram
([revisao-de-design.md](revisao-de-design.md)):

3. **Portas com ilustração** — continua pílula preenchida, mas com
   **acabamento de botão**: profundidade (sombra que encolhe ao pressionar),
   contorno, e a ilustração num medalhão que se destaca da pílula. "Simples"
   continua sendo a meta; "chapado" não.
8. **Uma caixa por etapa** (nova, FR-002a): cada grupo de campos, cada
   explicação e cada escolha mora numa caixa própria, com uma frase de
   instrução no topo dela ("Escreva aqui o seu e-mail"). Juntar tudo num
   cartão só economiza espaço e cobra atenção, que é o que falta.
9. **Tutorial no lugar de rótulo** (nova): a primeira vez que a pessoa chega a
   uma tela, a Memora diz em uma frase o que se faz ali. Rótulo curto não
   basta para quem não sabe o que esperar.

---

## R3 — Tipografia: Atkinson Hyperlegible Next, embarcada

**Decisão**: o aplicativo passa a embarcar a família **Atkinson Hyperlegible
Next** (licença SIL OFL 1.1), em vez da fonte do sistema. Os estilos de
`MemoraTipografia` ganham `fontFamily` e um degrau novo, `destaque` (o título
grande do Início e das boas-vindas, ~36).

**Por quê**: foi desenhada pelo Braille Institute para baixa visão —
diferencia `I`, `l` e `1`, e `0` de `O`, que são as confusões que mais derrubam
quem digita e-mail e código. É também o que mais muda a percepção de
"profissional" com menos risco: hoje cada fabricante mostra uma fonte
diferente, e o aplicativo parece outro em cada aparelho.

**Alternativas descartadas**:
- *Inter*: moderna e neutra, mas sem o cuidado de distinguir caracteres
  parecidos, que aqui é requisito e não estética.
- *Continuar com a fonte do sistema*: o visual muda de aparelho para aparelho,
  e a medição de estouro feita num emulador não vale para o aparelho da pessoa.

⚠️ **Conferir a licença no arquivo baixado, e não neste texto.** O `OFL.txt`
vem junto com a família; ele entra no repositório ao lado dos `.ttf`, e é ele
que autoriza embarcar a fonte. Se não for OFL, a decisão volta para cá.

⚠️ **Binário novo precisa entrar no `.gitattributes` antes do commit** — é a
regra que a PR #29 deixou, para `core.autocrlf` não corromper o `.ttf`.

~~⚠️ **A Atkinson é mais larga que a Roboto.** A matriz de estouro inteira precisa
rodar de novo com ela, nas telas que já existem, antes de qualquer tela nova.~~

✅ **Corrigido ao implementar (2026-10-01): a matriz nunca mediu com a Roboto.**
O `flutter test` desenha todo texto com uma fonte **quadrada**, de 1 em por
caractere, seja qual for a família pedida. Medido: "Esqueci minha senha" a
18 sp ocupa **342 px** na matriz e **168 px** com a Atkinson carregada. Com a
altura de linha fixada, como em todo estilo de `MemoraTipografia`, as duas têm
a mesma altura por linha (27 px a 1,5), e a quadrada quebra mais linhas: o
mesmo parágrafo em 200 px ocupa 162 px de altura contra 81.

A matriz é, portanto, **pessimista nas duas direções**, e isso é o que se quer:
o que passa nela passa com a fonte real. Decisões:

- **A matriz continua com a fonte quadrada**, de propósito. Carregar a Atkinson
  nela tiraria metade da margem.
- **Só o álbum de telas (R13) carrega a Atkinson**, porque ele existe para
  olhar, não para reprovar.
- **A troca de família não pode mudar nenhum resultado da matriz.** Se mudar, é
  sinal de que algum teste passou a carregar fonte, e é isso que se investiga.

⚠️ Vale lembrar o outro lado: os estouros que a matriz já achou (o "Mostrar
senha" de 31 px no 320×568, por exemplo) foram medidos com texto duas vezes
mais largo que o real. Continuam sendo defeito — a margem existe para cobrir
fonte de sistema, escala do fabricante e texto que ainda vai mudar —, mas o
número em px não é o que a pessoa vê.

---

## R4 — Ilustrações: a Memora redesenhada e um conjunto de licença aberta

**Decisão**:
- **A Memora** (o robô do wireframe) é redesenhada pela equipe em SVG, com
  quatro expressões: neutra, falando, comemorando e preocupada (para os
  avisos). É o `MemoraPersonagem`. O `AvatarMemora` **não** é substituído: é o
  retrato do casal no cartão do cadastro e do login, e o nome é anterior ao
  personagem (T013; `CLAUDE.md`, seção 8).
- **As demais ilustrações** (pessoas, portas do Hub, estados vazio e erro e,
  se houver, os assuntos da Ajuda) eram previstas de um conjunto de **licença
  aberta que permita alteração**. Na implementação entraram como **desenho
  original da equipe** (nota da T011), o que simplifica a licença; cada arquivo
  continua registrado em `app/assets/ilustracoes/LICENCAS.md`.
- **Nos temas escuro e de alto contraste**, ilustração com cores próprias fica
  sobre um **medalhão** claro, como os círculos do wireframe. Ilustração de
  traço único continua recebendo `cor`.
- Tudo continua passando pelo enum `Ilustracao`: arquivo que não existe **não
  compila**. (Vale para as ilustrações. Para as capturas dos guias, a regra é
  outra: ver a FR-028a e a R6.)

**Por quê**: o wireframe usava ilustrações de banco de imagens, sem licença
registrada; não dá para levá-las para uma entrega que vai ser apresentada. E
ilustração colorida sobre fundo escuro é onde o contraste quebra em silêncio:
o medalhão resolve sem precisar de três versões de cada desenho.

**Alternativas descartadas**: gerar ilustrações por IA (licença incerta e estilo
instável entre desenhos); usar só ícones (é o que existe hoje, e é o que a
equipe não quer).

---

## R5 — Aviso de segurança proporcional

**Decisão**: novo componente `AvisoCompacto`, que mostra **o título do aviso e
uma linha**, com "Ler o aviso inteiro" para expandir. O estado inicial depende
da conversa (FR-022 revista na T044): aberto até a primeira mensagem, depois
uma linha. Expandido, ele empurra o
conteúdo, mas nunca passa de 50% da altura disponível; acima disso o texto
rola dentro dele. **Só a conversa (FR-022) passa a usá-lo.**

⚠️ *Corrigido na revisão da #36*: a primeira versão levava o aviso compacto
também à recuperação de acesso. Lá o título fixo é "Eu nunca peço sua senha", e
o "número de 6 dígitos" — o dado que o golpe daquela tela pede — ficaria só no
texto expandido. A recuperação nem tinha o problema de espaço da conversa.
Ela mantém o aviso inteiro (FR-049).

O portão da FR-022 é uma extensão do da FR-027 da 003: na matriz de aparelhos,
em 100% e 150%, **lista de mensagens + campo de escrever ≥ 50% da altura
disponível**.

**Por quê**: o diagnóstico 3 da spec. O aviso continua permanente, que é o que a
FR-023 da 001 e a FR-033 da 003 exigem: compacto não é escondido.

⚠️ **Revista na T044 (2026-10-01): o aviso encolhe depois da primeira
mensagem.** O Henrique pediu um aviso menor, que pudesse ser removido e sumisse
ao mandar mensagem. Ficou o meio-termo, decidido por ele: **aberto até a
primeira mensagem; depois, uma linha** com escudo e o núcleo ("senha" e
"código"), que se toca para ler inteiro. Sumir — sozinho ou por gesto — foi
recusado: o golpista pressiona a pessoa **durante** a conversa, e "feche esse
aviso" é exatamente o que ele pediria. O portão continua conferindo o núcleo
com o aviso fechado.

**Alternativas descartadas**: mostrar o aviso só na primeira vez. Contraria a
permanência exigida pelas duas features: a pessoa sendo enganada ao telefone
pode estar na décima conversa.

⚠️ **Os portões da FR-023 da 001 não mudam**: a recuperação mantém o aviso
inteiro. Na conversa, o resumo sempre visível precisa conter o núcleo do aviso
("senha" e "código"), e o teste confere isso **com o aviso fechado** — que é o
que a maioria vê.

---

## R6 — O passo a passo: conteúdo tipado, capturas da equipe, destaque desenhado pelo app

**Decisão**:
- **Conteúdo em Dart, tipado** (`features/aprendizado/data/guias/`), um arquivo
  por guia. A captura de um passo que ainda não existe **não derruba a
  construção nem o teste**: o passo mostra um aviso visível de **captura
  pendente**, com a chave do guia e o número do passo, e o texto continua
  funcionando (FR-028a). Um teste lista as pendentes, e a lista precisa zerar
  antes da revisão de design final. Os textos ficam em `l10n/textos_guias.dart`,
  pela estrutura preparada da D3 da 002.
- **As imagens são capturas de tela feitas pela equipe**, numa conta de teste
  sem dado real, guardadas em `app/assets/guias/<chave>/passo_N.png`, em 3x.
- **O destaque, o selo "Exemplo" e a moldura de celular são desenhados pelo
  aplicativo**, por cima da captura, a partir de uma região em coordenadas
  relativas (0 a 1). Assim o destaque acompanha o tema, tem contraste medido e
  escala com a tela, e a captura pode ser trocada sem refazer o desenho.
- **Cada guia é ligado ao item do catálogo pela `chave`** (ver R8).

**Por quê**: o passo a passo precisa ser revisável (é ensino a um público que
erra o que aprendeu errado) e não pode depender do provedor de IA, que não foi
escolhido. Captura real é o que permite à pessoa **reconhecer** a tela depois,
no aplicativo de verdade — o objetivo do SC-003.

**Alternativas descartadas**:
- *Esquemas vetoriais redesenhados*: mais leves e sem questão de direito, mas
  a pessoa não reconhece a tela real, e reconhecer é o objetivo. **Fica como
  plano B** se a revisão acadêmica levantar objeção ao uso das capturas: o
  formato do `Passo` aceita qualquer imagem, então trocar é conteúdo, não
  código.
- *JSON em `assets/`*: editável sem compilar, mas erro de digitação vira tela
  vazia no aparelho, e não erro de build.
- *Gerado pela assistente na hora*: depende do provedor, não é revisável, e a
  assistente pode descrever um botão que não existe.

⚠️ **Capturas envelhecem.** O aplicativo do outro lado muda. A saída "A minha
tela está diferente" (FR-026) existe para isso, e cada guia registra a **data e
a versão** do aplicativo capturado, para a revisão saber quando refazer.

---

## R7 — Ícone de aplicativo vem do aparelho; serviço sensível não usa logotipo

**Decisão**:
- **Aplicativo cotidiano instalado**: o ícone vem do próprio aparelho, por um
  canal de plataforma novo (`memora/aplicativos`) com dois métodos —
  `estaInstalado(pacote)` e `iconeDe(pacote)`. Só funciona para os pacotes já
  declarados em `<queries>`, o que é o comportamento certo.
- **Aplicativo cotidiano não instalado**: ilustração genérica e o nome, e o
  passo a passo começa ensinando a baixá-lo da loja oficial (caso de borda da
  spec). Fecha também a T089 da 003.
- **Serviço sensível**: **pictograma do Memora** (prédio, documento, carteira,
  envelope), com o nome escrito — **nunca o logotipo oficial**.

**Por quê**: o ícone do aparelho é o que a pessoa vai procurar na tela inicial
dela, e não é cópia de marca: é o que o sistema já mostra. Já pôr o logotipo do
gov.br numa tela do Memora ensina que **logotipo é prova de oficialidade** —
exatamente o que o aplicativo falso usa. O serviço sensível também não tem
pacote, por construção (`ck_servico_sensivel_nao_abre`), então não há ícone de
aparelho a buscar.

**Alternativas descartadas**: embarcar os logotipos (direito de marca e o golpe
acima); só ícones Material (é o hoje, e não é reconhecível).

**Interpretação registrada**: a US5 pede "nome e símbolo reconhecível". O
pictograma com o nome é o símbolo; se a equipe entender que "reconhecível"
exige o logotipo, isso é uma reabertura da spec, por causa do golpe acima.

---

## R8 — Catálogo: as migrations V8 a V10 e o que entra nelas

**Decisão**: duas coisas, em três migrations — a **V8** cria a `chave`, e a
**V9** e a **V10** trazem as linhas novas, cada uma junto com os guias delas.

1. **Acrescenta `chave`** a `servico_conhecido`: texto curto, ASCII, único e
   obrigatório (`gov-br`, `whatsapp`), preenchido para as linhas existentes. O
   `id` continua sendo o que a trilha referencia; a `chave` é o que liga um
   item ao guia no aparelho, e é a mesma em qualquer banco. O `Servico` do
   contrato da 003 ganha o campo `chave` — mudança **aditiva**, que não quebra
   cliente nenhum.
2. **Acrescenta os serviços sociais do wireframe**, todos `SENSIVEL`, sem pacote:
   e-Título, Serasa, FGTS, Poupatempo, Carteira Digital (o documento do gov.br, e não a de Trânsito; T080, resolvida), Correios e
   Carteira de Trabalho Digital. Gov.br e Meu INSS já existem.

**Aplicativos cotidianos do wireframe**: entram **TikTok, Kwai, Messenger,
Gmail, Netflix e Google**, cada um com o pacote em `<queries>`. Ficam de fora,
com motivo:

| Fora | Por quê |
|---|---|
| Shopee | Compra e pagamento: abrir pela pessoa contraria a D2 da 003 |
| Play Store | Instalar aplicativo é o pedido mais comum do golpista; vira assunto da Ajuda ("Como baixar um aplicativo"), onde é ensino puro |
| Configurações do Android | Permissões e acessibilidade do aparelho: é por ali que o golpe instala o controle remoto |
| Candy Crush | Compras dentro do jogo, e nenhum caminho de aprendizado que o Memora precise ensinar |
| X | Pacote estável, mas uso baixo neste público; entra quando houver motivo |

**Um item só entra no catálogo com o guia pronto.** Um teste do aplicativo lê
as migrations do backend — o mesmo truque do `PoliticaDeSenhaTest`, ao
contrário — e reprova se existir `chave` sem guia correspondente. Isso fecha,
para o catálogo, o aviso de que **simulado e banco são mundos separados e
nenhum teste liga os dois**: o simulado passa a ser conferido contra as
migrations pelo mesmo teste.

**Por quê "Correios" e "Serasa" são sensíveis**: pedem CPF e tratam de crédito;
a D2 da 003 vale para eles (Assumption da spec).

---

## R9 — Busca em "Meus aplicativos"

**Decisão**: filtro local, por trecho do nome, comparando as duas pontas sem
acento e em minúsculas. Sem servidor, sem tolerância a erro de digitação nesta
entrega.

**Por quê**: o catálogo tem dezenas de itens, e não milhares. Tolerância a erro
(distância de edição) traria falso positivo justamente com nomes curtos ("X",
"Kwai"), e a pessoa tocaria no aplicativo errado.

**O que faria mudar de ideia**: o teste com as 5 pessoas mostrar busca falhando
por erro de digitação.

---

## R10 — Perfil e Conta sem endpoint novo

**Decisão**: o nome vem da sessão (`PessoaAutenticada.nomeTratamento`); o canal
vem do **identificador do último acesso**, que o aparelho já guarda (FR-012 da
001) — foi com ele que a pessoa entrou ou se cadastrou.

⚠️ **Não é, sempre, um canal da conta** (correção da revisão da #36). Na
sessão-chamariz, quem tentou cadastrar um canal que já pertence a alguém
recebe uma sessão para um sujeito que não existe, e o fluxo grava o canal
**digitado** (`fluxo_autenticacao.dart`, `_cadastrou`). Não vaza nada além do
que a própria pessoa digitou — mas o Perfil mostraria um canal que não é de
conta nenhuma. É o mesmo comportamento que o login já tem desde a FR-012.

**Por quê**: um endpoint autenticado novo traria a obrigação da sessão-chamariz
e mais superfície, para mostrar um dado que o aparelho já tem. Não há dado
novo no servidor (Clarifications, Q2).

**Limite conhecido**: mostra o canal **como foi digitado** no último acesso. Se
a US4 da 001 um dia permitir trocar o canal, isso precisa ser revisto.

---

## R11 — O que fica no aparelho, e quando sai

| Dado | Onde | Sai ao sair da conta? |
|---|---|---|
| Apresentação vista | `shared_preferences`, por conta | **Não** na saída comum — sair e voltar não deve repetir a apresentação. **Sim** com `esquecerTudo`: aparelho que vai ser vendido não deve guardar os identificadores das contas que passaram por ele (revisão da #36) |
| Progresso de aprendizado | arquivo local, por conta | **Sim** — entra como `DadoLocalDaPessoa` na `LimpezaDeSessao` (FR-042b) |
| Catálogo guardado | arquivo local, único | **Não** — é o mesmo para todo mundo e não diz nada sobre a pessoa (FR-024a, decisão da análise de 2026-10-01) |

**Por quê o progresso sai e a apresentação fica**: o progresso revela o que a
pessoa **não sabe** fazer — o mesmo argumento que tira a conversa do aparelho.
Que ela já viu a apresentação não revela nada.

⚠️ A `LimpezaDeSessao` não pode parar no primeiro item que falhar (achado 3 da
revisão de 2026-10-01). O progresso entra na lista dela, e o teste que a
própria #35 corrigiu precisa ganhar o caso.

---

## R12 — Compartilhar, site de ajuda e login social: escondidos até existirem

**Decisão**:
- **Compartilhar** só aparece quando houver um endereço oficial de download,
  informado no build (`--dart-define=MEMORA_URL_DOWNLOAD`). **Hoje não há** — o
  aplicativo não está publicado —, então o assunto fica oculto. Quando houver,
  o envio usa a folha de compartilhamento do sistema pelo `android_intent_plus`
  (`ACTION_SEND`), sem dependência nova.
- **O site de ajuda do wireframe** (`ajudamemora.com.br`) não é da equipe e não
  entra. Link para domínio que não controlamos é o link que um golpista compra.
- **Google e Facebook no login** continuam ocultos até a fase 8 da 001 (FR-011).

**Por quê**: FR-018. Porta que não abre nada é pior do que porta que não existe.

---

## R13 — Como se verifica o que é visual

**Decisão**: três camadas.

1. **Matriz automatizada** (já existe para as telas da 001 e da 003): 4
   aparelhos × 3 escalas × 3 temas, para **toda** tela nova. Reprova estouro e
   ação principal fora de alcance (FR-044).
2. **Álbum de telas**: um teste que renderiza cada tela em cada tema e salva a
   imagem em `build/album/`, sem comparar com nada. Ele existe para a revisão de
   design (SC-005) olhar as 35 telas lado a lado com o wireframe, sem montar
   emulador.
3. **Gente**: a revisão da equipe (SC-005) e o teste com 5 pessoas de 65+
   (SC-002 a SC-004).

**Alternativas descartadas**: testes de *golden* que reprovam por diferença de
pixel. Com fonte embarcada eles ficam mais estáveis, mas a renderização ainda
difere entre Windows (as duas máquinas) e Linux (o CI), e um portão que reprova
por motivo que não é defeito ensina a equipe a ignorá-lo.

---

## R14 — Ordem de entrega

**Decisão**: fundação primeiro, depois as histórias em ordem de prioridade, uma
PR por fase, como nas features anteriores:

1. **Fundação**: fonte, tokens novos, componentes novos, ilustrações, casca
   interna — e a matriz rodando de novo nas telas que já existem.
2. **US2** (Início, Hub, barra inferior) — primeira, para a revisão de design
   julgar a linguagem cedo (R2).
3. **US1** (primeiro contato), **US3** (conversa), **US4** (aplicativos e passo a
   passo).
4. **US5** (serviços sociais e a V10), **US6** (Ajuda), **US7** (Configurações).
5. **US8** (Perfil) e o redesenho das telas da 001 que não estão no wireframe.
6. **Validação**: álbum, revisão de design, teste com as 5 pessoas.

**Por quê a US2 antes da US1**: a US1 é a primeira impressão, mas a US2 é a tela
mais vista, e ela fixa a linguagem que as outras copiam. Errar a linguagem na
US1 e descobrir na US2 custaria refazer as duas.

---

## R15 — Paletas prontas de cor de destaque

Acrescentada na revisão da T044 (FR-039).

**Decisão**: Aparência oferece **cinco ou seis paletas prontas** — azul (a do
protótipo, padrão), verde, roxo, laranja-terra, rosa e grafite, a fechar na
medição — combináveis com os três temas da 002. Uma paleta troca só a cor
**primária** e os tons derivados dela (`destaque`, `medalhao`, o anel de foco);
fundo, superfície, texto, erro e sucesso continuam sendo os do tema. No tema de
alto contraste a paleta **não se aplica**: ele existe para o máximo contraste,
e qualquer cor de destaque seria concessão.

**Por quê**: o pedido foi personalização; a constituição exige WCAG 2.2 AA em
toda combinação. Paleta pronta resolve os dois: cada combinação entra no
`validar_paleta.py` **antes** de existir, e uma que não passa simplesmente não
é oferecida.

**Alternativas descartadas**: seletor de cor livre. Não há como validar
contraste de uma cor que só existe no aparelho da pessoa, e o prejuízo de uma
escolha ruim cai em quem enxerga pior. Mudar também fundo e texto por paleta
multiplicaria as combinações a validar sem pedido nenhum por isso.

**O que faria mudar de ideia**: alguma paleta reprovar no validador em mais de
um tema — aí ela sai da lista, em vez de ganhar exceção.

---

## R16 — Fechamento Técnico da Feature 004 (`CaixaDeEtapa`, Álbum Completo e Inventário)

Acrescentada em 2026-11-09 para consolidar as tarefas técnicas remanescentes da Feature 004 (`T035`, `T125a–d`, `T101`, `T102`, `T103`, `T107`) sobre a branch `develop`.

**Decisão**:
1. **Aplicação de `CaixaDeEtapa` (`FR-002a` — `T125a`, `T125b`, `T125c`, `T125d`)**:
   - **`T125a` (`US7` — Ajustes, Conta e Privacidade)**:
     - Em `TelaConfiguracoes`: envolver o grupo das 4 portas de ajustes em uma `CaixaDeEtapa` com instrução acolhedora orientando a escolha do que ajustar.
     - Em `TelaConta`: envolver a seção de `"Sair"` e a seção separada de `"Sair e esquecer este aparelho"` em suas respectivas `CaixaDeEtapa` (mantendo o espaçamento `MemoraEspacamento.xxxl` entre as duas ações para cumprir o Princípio II e a `FR-041`).
     - Em `TelaPrivacidade`: envolver a seção de ação `"Apagar a conversa deste aparelho"` em uma `CaixaDeEtapa` com a frase orientadora, mantendo a `ListaInformacao` acima como informação pura.
   - **`T125b` (`US8` — Data de nascimento no Perfil)**:
     - Em `TelaDataDeNascimento`: envolver cada etapa de preenchimento (ou o grupo de campos de dia, mês e ano e a ação de guardar) com `CaixaDeEtapa`, garantindo que os rótulos, textos de ajuda e erros por campo continuem intactos e sem estouro em `320×568` a `200%`.
   - **`T125c` (`US4` — Passo a Passo dos guias)**:
     - Em `PassoIlustrado` / `TelaPassoAPasso`: envolver o bloco de ações do passo (`Continuar` / `Voltar ao início`, `A minha tela está diferente`, `Peça à Memora para abrir`, `Ficou com alguma dúvida?`) em uma `CaixaDeEtapa` orientando o próximo passo da pessoa.
   - **`T125d` (`US6` — Ajuda)**:
     - Em `TelaAjuda`, `TelaAssunto` e `AjudaGuiadaDaConversa`: envolver a escolha de assunto (`TelaAjuda`) e os controles de navegação/ação (`TelaAssunto` e `AjudaGuiadaDaConversa`) em `CaixaDeEtapa`.
2. **Consolidação dos Testes do Hub (`T035`)**:
   - Confirmar que `app/test/features/hub/tela_hub_test.dart`, `app/test/acessibilidade/hub_acessibilidade_test.dart` e `app/test/acessibilidade/hub_cabe_sem_rolar_test.dart` cobrem integralmente a regra vigente da `FR-017` (porta principal sempre à vista + faixa `"há mais"`; Hub inteiro sem rolar em `360×800` a `100%`; exceção de `320×568` a `200%`), a `FR-018` (porta sem destino não aparece) e os estados da `FR-006`, marcando `T035` como concluída.
3. **Extensão do Álbum de Telas (`T101`)**:
   - Estender `app/test/album/album_de_telas_test.dart` para renderizar e gravar em `app/build/album/<tema>/` as telas da Feature 004 (Apresentação, Início, Hub, Conversa, Catálogos Cotidiano e Sensível, Passo a Passo, Ajuda, Assunto, Ajuda Guiada, Ajustes, Aparência, Acessibilidade, Privacidade, Conta, Perfil e Data de Nascimento) e as telas fora do wireframe redesenhadas na `T099` (Login, Cadastro, Confirmar Canal, Entrega do Aparelho, Primeira Entrada, Recuperação e Registro).
4. **Fechamento Documental (`T102`, `T103`, `T107`)**:
   - Preencher a tabela `"Onde cada cenário roda"` em `specs/004-redesenho-das-telas/quickstart.md` mapeando `V1` a `V14` para seus respectivos arquivos de teste (`T102`).
   - Registrar as divergências conscientes em relação ao protótipo em `docs/design/divergencias-do-prototipo.md`, atualizar `docs/referencia/requisitos-atualizados.md` e alinhar `specs/003-hub-e-assistente/spec.md` quanto ao nome `"Serviços sociais"` (`T107`).
   - Executar a bateria completa de verificação (`flutter analyze`, `flutter test`, `validar_paleta.py`, `validar_tokens.py` e `--autoteste`) e atualizar `docs/relatorios/o-que-falta.md` (`T103`).

**Por quê**: fecha 100% das tarefas de engenharia de software da Feature 004 sobre a branch `develop`, deixando pendentes exclusivamente as atividades presenciais/humanas (`T104` revisão visual humana do álbum gerado, `T105` teste presencial com 5 idosos 65+ e `T074` capturas adicionais).

**Alternativas descartadas**: adiar `T125a–d` ou `T101` para depois da revisão humana — sem o álbum completo (`T101`) e sem as `CaixaDeEtapa` (`T125a–d`), o álbum fotografaria telas ainda sem o acabamento aprovado na `T044`.
