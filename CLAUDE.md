# Contexto do Projeto Memora

> Leia este arquivo inteiro antes de qualquer ação. Ele existe para que uma nova
> sessão consiga continuar o trabalho sem repetir decisões já tomadas nem refazer
> análises já feitas.

**Última sessão**: 2026-09-15 — **revisão da PR #27** (T070), a auditoria que
ela pediu, e a **fase 7 da feature 002**, pelo Henrique. Entraram na `master`:
a #27, a #28 (teto da conversa vira fração da tela), a #29 (plano de pentest) e
a #30 (o `Flexible` do "Mostrar senha"); a #31 (galeria e portão dos tokens)
está aberta. Duas PRs de conserto saíram de uma revisão, e os dois defeitos
eram **layout que só quebrava em aparelho que ninguém testava**.
**Estado**: **346 testes** no backend (eram 334) e **460** no aplicativo
(eram 346). A
feature 001 está completa, só a fase 8 (login social) fora, com bloqueio
externo. A feature 003 tem **Hub, conversa que ensina, catálogos, execução com
confirmação e registro** — tudo contra simulado, **sem provedor de IA
escolhido** — e a T070 da fase 9 feita.
**Próximo: a fase 8 da 003** (T061-T068), que espera a escolha do provedor, ou
o resto da **fase 9** (T069, T071-T074 — T071 exige as 5 pessoas de 65+). Ver
seção 4-B.

> 🔒 **O plano de pentest está em [`docs/seguranca/plano-de-pentest.md`](docs/seguranca/plano-de-pentest.md)**
> (PR #29), escrito em 2026-09-11 e versionado em 2026-09-15. Ele é o **plano**:
> escopo, ferramentas e, para cada um dos 12 pontos de ataque, hipótese de
> falha, evidência a coletar, impacto e correção esperada. **Nunca foi
> executado** — o relatório de resultados é trabalho separado, e o caso 4.7
> (fazer o modelo abrir serviço sensível) é o que mais vale rodar, porque é o
> cenário H3 atacado por fora, em vez de por teste nosso.
>
> ⚠️ **Um `.gitattributes` entrou junto, e ele evita corrupção silenciosa.** Com
> `core.autocrlf=true` — o padrão do Git for Windows, ativo nas duas máquinas —
> o git converteria LF em CRLF **dentro do PDF**, e isso só apareceria quando
> alguém tentasse abrir o arquivo depois de um clone. Qualquer binário novo
> (PDF, PNG, fonte, `.jar`) precisa estar lá **antes** de ser commitado. O PDF
> do plano é **derivado do `.md`** e vai divergir dele: quem editar o texto
> regenera o PDF, ou tira o PDF do repositório.

> 🔴 **Teto de layout se mede em fração de tela, nunca em pixel — e isso custou
> duas rodadas.** O T070 achou que a tela de conversa estourava em 200%: o
> aviso antigolpe ia de 364 px (100%) para **1324 px** (200%) num 390×844,
> derrubando campo e botão de enviar para fora da tela. Corrigiu com tetos
> fixos de 420 px e 300 px, medidos naquele aparelho — e a revisão mediu os
> outros: com esses tetos, um **360×800** (Galaxy A/M, o mais comum no Brasil)
> ainda estourava 40 px em 200%, e um **360×640** estourava 133 px **já em
> 100%**, sem zoom nenhum. Hoje um `LayoutBuilder` dá a altura disponível e as
> duas faixas ficam em **45% e 42%** dela; os 13% restantes são o piso da lista
> de mensagens. Zero estouro nas 12 combinações de aparelho × escala.
>
> ⚠️ **E o portão da FR-027 estava decorativo.** Ele verificava
> `takeException() == null` e "o campo existe" — as duas coisas são verdade com
> a **conversa reduzida a 4 px de altura**. Não estourar não é continuar
> utilizável. Hoje ele exige altura mínima para a lista e o botão de enviar
> alcançável, e foi provado quebrando: com os tetos fixos de volta, **10 das 12
> combinações reprovam**, inclusive o 390×844 a 150%, que a versão antiga
> deixava passar.
>
> **A causa de isto ter passado despercebido até então**: testes de
> acessibilidade que fazem `MediaQuery(data: MediaQueryData(size: ...))` **não
> mudam o tamanho real usado no layout**, só o valor que `MediaQuery.of` lê.
> As restrições de verdade vêm da janela do teste, que é **800×600** — mais
> larga que qualquer telefone. O jeito certo é `tester.view.physicalSize`.
>
> **E não basta um aparelho.** A matriz está em
> `app/test/suporte/aparelhos.dart`: 390×844, 360×800, 360×640 e 320×568,
> cruzada com 1.0 / 1.5 / 2.0. Rodar num aparelho só foi exatamente o que
> escondeu o estouro do 360×640 em 100%.

> ✅ **A suspeita sobre os testes antigos foi auditada em 2026-09-15, e havia
> defeito de verdade.** O `cadastro_acessibilidade_test.dart` declarava
> `size: Size(390, 844)` e rodava em 800×600. Apontado para telefone, reprovou:
> o controle **"Mostrar senha"** do `CampoSenha` estava numa `Row` sem
> `Flexible`, então exigia a largura natural do rótulo — que cresce com a
> ampliação. Estouro **horizontal** de 31 px num 320×568 **já em 100%**, 78 px
> num 390×844 a 150% e 265 px a 200%, nas **três** telas que pedem senha
> (cadastro, login, recuperação). Conserto de uma linha, o mesmo que o
> `BotaoBase` já fazia.
>
> **As oito telas da autenticação foram varridas** na matriz de 4 aparelhos ×
> 3 escalas: com o `Flexible`, zero estouro em 96 combinações. O portão é
> duplo, e de propósito — `campo_senha_ampliacao_test.dart` (componente) e o
> `cadastro_acessibilidade_test.dart` (tela). Quebrando o `Flexible`, **17
> casos reprovam**, e o do 320×568 a 100% **só a tela pega**: um componente
> isolado tem mais largura que o mesmo componente dentro do cartão.
>
> ⚠️ **Texto dentro de `Row` quase sempre quer `Flexible`.** É a mesma família
> do teto fixo da conversa: largura natural não sabe quanto de tela existe.

> 🔴 **O que falta para haver produto não é código, e isso precisa entrar na
> fila agora.** Levantamento de 2026-09-08: três das quatro coisas que separam
> o repositório de um Memora entregue dependem de decisão ou contratação, não
> de esforço nosso — **provedor de IA** (sem ele a assistente não pensa),
> **provedor de envio** (sem ele nenhum código chega a ninguém) e o **teste com
> 5 pessoas de 65+**, que é portão de saída obrigatório das features 001 e 002.
> A quarta era a integração aplicativo↔servidor, e essa foi feita hoje.
>
> O risco, com prazo de entrega em novembro: chegar lá com centenas de testes
> verdes e um aplicativo que não faz o que promete.

> ⚠️ **O provedor de IA NÃO foi escolhido, e isso é uma decisão em aberto da
> equipe** (R2 do research da 003). A arquitetura foi desenhada para que isso
> não bloqueasse nada: tudo conversa com a porta `ClienteDaAssistente`, e o
> `ClienteDaAssistenteSimulado` responde. **Não escolha por conta própria** —
> os seis critérios estão em `specs/003-hub-e-assistente/research.md`, e o que
> mais pesa é retenção de dados: um provedor que treine com o que recebe
> desfaria a decisão D3 por fora, sem aparecer no nosso código.

> ✅ **A US3 fechou em 2026-09-08.** Os dois endpoints existem
> (`/auth/recuperacao/solicitar` e `/auth/recuperacao/confirmar`) e o
> `RepositorioAutenticacaoApi` já não recebe `404`. Ver "O backend da US3", na
> seção 4. **Continua sem provedor de envio** (T065a): o código e o aviso de
> troca de senha vão para o log, e o perfil `producao` não sobe sem substituto.

> ⚠️ **Confira o GitHub antes de decidir o que fazer.** Este arquivo já ficou
> para trás uma vez: em 2026-08-16 ele apontava T030-T032 como próximo passo, e
> as duas fases seguintes já estavam mergeadas havia dias. Uma sessão inteira
> quase começou pelo lugar errado. `gh pr list --state all` custa segundos.

> ⚠️ **`estado` da conta não é o mesmo que `bloqueada_ate`.** Ver "Duas coisas
> que a revisão da #15 mudou", na seção 4, antes de escrever em `estado`.

> 📄 **Há um panorama completo em
> [docs/relatorios/relatorio-de-progresso.md](docs/relatorios/relatorio-de-progresso.md)**
> (PR #17): estado por fase, o que existe em código nos dois lados, os portões
> de segurança, dívidas e fila de PRs. Este arquivo continua sendo a passagem de
> contexto operacional; o relatório é o retrato para a equipe e a faculdade.
>
> **São 301 testes no backend e 294 no aplicativo (2026-08-29), e a soma do
> Surefire mente sem `clean`.** Este
> arquivo já disse 244, 245 e 251. Em 2026-08-24 a causa apareceu: havia um
> `TEST-...SondaCaminhoDesconhecidoTest.xml` de **10/08** parado em
> `target/surefire-reports/`, de uma classe de sonda que nunca foi commitada e
> não existe mais em `backend/src` nem em commit nenhum — `git log --all` não a
> encontra. Ela valia 1 teste, e `Select-String` sobre os XMLs continuava
> somando esse 1 em toda execução seguinte, porque `target/` está no
> `.gitignore` e ninguém limpava. Daí o 245 contra 244, e o 251 contra 250.
>
> **O número em que confiar é o `Tests run:` de uma execução limpa.** Com
> `clean`, o Maven e a soma dos XMLs concordam em 250, em 26 arquivos:
> ```powershell
> $env:JAVA_HOME = "C:\Program Files\Java\jdk-21"; cd backend; .\mvnw clean test
> ```

> ⚠️ **A casca de demonstração continua no `RepositorioAutenticacaoSimulado`** —
> agora para cadastro **e login**. A troca é de uma linha em
> `lib/demonstracao/casa_demonstracao.dart`, mas exige decidir de onde vem a URL
> base do servidor — não há configuração de ambiente no aplicativo, e `MemoraApi`
> hoje aponta para produção por padrão. **Isso não está na spec**; decidir antes
> de trocar.
>
> O simulado **reproduz a escada de bloqueio real** (5 falhas, depois 1 min) e
> guarda as contas criadas na própria execução, para que cadastrar e depois
> entrar funcione no aparelho. `registrarConta(...)` semeia conta sem passar pelo
> cadastro — necessário em `testWidgets`, onde o relógio é falso e
> `await cadastrar(...)` esperaria para sempre por um temporizador que só anda
> quando alguém bombeia quadros.

> ⚠️ **Antes de criar qualquer endpoint autenticado, leia "A sessão-chamariz"**,
> na seção 4. Existe token assinado por nós cujo sujeito não existe, de
> propósito. **Assinatura válida não é autorização.**
>
> O filtro que desarma isso **já existe**, desde a US5:
> `seguranca/FiltroDeTokenDeAcesso`. Ele resolve o sujeito no banco e só
> autentica se encontrar conta. Endpoint autenticado novo herda essa proteção
> de graça — desde que passe pela cadeia do Spring Security, e não leia o
> `subject` do JWT por conta própria.

> ⚠️ **`estado` da conta agora tem quatro valores, e dois deles não cedem.**
> `PENDENTE_VERIFICACAO` e `DESATIVADA` são **ciclo de vida**; `ATIVA` e
> `BLOQUEADA_TEMPORARIAMENTE` são a **tranca temporária**. Nenhuma tranca
> sobrescreve ciclo de vida — quem carrega essa regra é
> `EstadoDaConta.ehDeCicloDeVida()`. Sem ela, cinco senhas erradas tirariam a
> conta assistida da espera e, passado um minuto, ela entraria sem ninguém ter
> confirmado canal nenhum. Testado quebrando de propósito.

> ⚠️ **Antes de tocar no cliente da API, leia "Dívida deixada pelo T027"**, na
> seção 4. O cliente agora é um pacote local em `app/pacotes/memora_api/`, com
> job próprio no CI; o que continua em aberto são as tags acentuadas do contrato.

---

## 1. O que é o Memora

Aplicativo Android que **ensina pessoas idosas a usar o smartphone**. Não é um
assistente que faz as coisas pelo usuário — ele mostra o caminho, para que da
próxima vez a pessoa consiga sozinha.

Projeto Integrador da FATEC Americana. Equipe NewXz: Eduardo Juncker Toras,
Eduardo Moraes Trevisan e Henrique Moreira Sandrini (Scrum Master).

A pergunta que valida qualquer decisão: **"Um idoso conseguiria usar isso sozinho?"**

---

## 2. Regras que não se negociam

Estão em [`.specify/memory/constitution.md`](.specify/memory/constitution.md).
**Leia antes de propor qualquer coisa.** Resumo:

1. **Segurança acima de tudo** — vence prazo, performance e conveniência
2. **Proteção contra engenharia social** — toda tela responde *"como um golpista
   exploraria isto?"*
3. **Acessibilidade é requisito** — WCAG 2.2 AA, toque de 48 dp, texto a 200%
4. **Especificação antes de código** — sem spec aprovada, não se implementa
5. **Arquitetura limpa, Feature-First**
6. **A IA nunca age sozinha** — toda ação crítica exige confirmação e gera log
7. **Ensinar, não substituir** — o objetivo é autonomia

---

## 3. Como se trabalha aqui: Spec Driven Development

```
constitution → specify → clarify → plan → checklist → tasks → analyze → implement
```

### ⚠️ Armadilha conhecida

As skills do Spec Kit estão em `.claude/skills/speckit-*` e **normalmente estão
registradas** na ferramenta `Skill` em sessões novas.

**Se `Skill(speckit-plan)` falhar com "Unknown skill"** — acontece quando são
instaladas no meio da sessão: leia `.claude/skills/speckit-<nome>/SKILL.md` e
execute as instruções manualmente. O resultado é idêntico.

**Ao usar `/speckit-implement`, limite o escopo a uma fase por vez.** Cada fase do
`tasks.md` tem portão próprio e vira uma PR separada.

### Regras de fase

- **Na spec não se fala de tecnologia.** Comportamento e valor, não widgets.
- **No plano não se escreve código.** Estrutura, contratos e decisões.
- **Na implementação não se inventa requisito.** Faltou algo? Volta para a spec.
- **Ambiguidade vira pergunta, nunca suposição.**

---

## 4. Estado atual

| Feature | Spec | Plano | Tarefas | Código |
|---|---|---|---|---|
| **001 — Autenticação Acessível** | ✅ | ✅ | ✅ | 🟡 US1, US2 e US5 completas; **US3 só no aplicativo**; US4 pendente |
| **002 — Design System** | ✅ | ✅ | ✅ | 🟡 **T001-T049 e T052 feitas** — faltam T050/T051 (5 pessoas) e T053 (revisões) |
| **003 — Hub e a assistente** | ✅ | ✅ | ✅ | 🟡 **58 de 74 tarefas**; falta só a fatia do provedor de IA e a validação |

### O que já existe em código

`app/lib/design_system/`:
- **tokens/** — cores (3 temas), tipografia, espaçamento, raio, elevação,
  movimento, dimensões
- **temas/** — `ThemeExtension` tipada; um token inexistente **não compila**
- **design_system.dart** — ponto único de exportação

- **componentes/informacao/** — `CampoInformacao`, `DestaqueInformacao`,
  `ListaInformacao`. **Nenhum aceita callback de toque** — é ausência de API
- **componentes/botoes/** — `BotaoPrimario`, `BotaoSecundario`, `BotaoTerciario`,
  `BotaoPerigo`, sobre um `BotaoBase` que concentra as garantias
- **componentes/texto/** — `TextoMemora` e `escalaTextoLimitada(context)`
- **componentes/selecao/** — `OpcaoSelecionavel`
- **preferencias/** — entidade, controlador com pré-visualização, escopo e
  `TelaAparencia`. A implementação de persistência vive em
  `services/preferencias/`, para o Design System não depender de armazenamento

- **componentes/confirmacao/** — `ConfirmacaoMemora`, com variante irreversível
- **componentes/campos/** — `CampoTexto`, `CampoSenha`, `CampoCodigo`
- **componentes/cartoes/**, **dialogos/**, **navegacao/**, **feedback/**

`app/test/design_system/` — 139 testes.

`app/lib/features/autenticacao/` — as telas das US1 e US2:
- **domain/** — `autenticacao.dart` (contrato e entidades) e `monitor_de_sessao.dart`
- **data/** — repositório sobre o cliente gerado, repositório simulado e
  `ultimo_acesso_local.dart`
- **presentation/** — `fluxo_autenticacao.dart` liga boas-vindas → cadastro →
  login → dentro, com o monitor de sessão ativo só enquanto a pessoa está dentro
- **presentation/telas/** — `TelaBoasVindas`, `TelaCadastro`, `TelaLogin`
- **presentation/controladores/** — `ControladorCadastro`, `ControladorLogin`

`app/lib/l10n/textos_autenticacao.dart` — os textos na voz da Memora. **Não é
`flutter_localizations`**: é a "estrutura preparada" que a decisão D3 da feature
002 pediu. Quando houver um segundo idioma, estas constantes viram `.arb` sem
ninguém caçar frase dentro de widget.

### Regra de texto

**Todo `Text` usa `escalaTextoLimitada(context)`.** Sem isso o componente diverge
dos demais em ampliação extrema e o layout quebra de forma imprevisível.

### Regra visual que separa dado de ação

**Ação usa pílula e preenchimento. Informação nunca usa nenhum dos dois.**
Não invente uma terceira linguagem sem revisar a FR-012.

### O que já existe no backend

`backend/src/main/java/br/fatec/memora/autenticacao/`:
- **dominio/** — as 5 entidades (`PessoaUsuaria`, `CanalContato`, `Sessao`,
  `CodigoVerificacao`, `EventoAutenticacao`) e os 5 enums. Canais, sessões e
  códigos referenciam a pessoa **por UUID**, sem associação JPA: nada no domínio
  navega de sessão para pessoa, e associação preguiçosa com
  `open-in-view=false` estoura fora de transação.
- **seguranca/** — o núcleo da feature:
  - `ConfiguracaoDeSenha` — Argon2id a 64 MiB, t=4
  - `GeradorDeSegredoOpaco` — refresh token de 256 bits. **Usa SHA-256, não
    Argon2**: hash lento existe para proteger segredo de baixa entropia; valor
    aleatório de 256 bits não ganha nada com isso, e pagaria 240 ms a cada
    abertura do app
  - `EmissorDeTokenDeAcesso` / `ConfiguracaoDeToken` — JWT HS256 de 15 min. Sem
    `memora.token.segredo` configurado, a chave é **sorteada na subida** e um
    WARN avisa. Nenhum segredo no repositório; segredo curto derruba a subida
  - `ServicoDeSessao` — abre e rotaciona sessão, com detecção de reuso
  - `VerificadorCredenciais` — roda o hash **mesmo sem conta**, contra hash
    fictício gerado pelo mesmo codificador
  - `LimitadorTentativas` + `BloqueioProgressivo` — as duas camadas da R4
- **infra/** — os 5 repositórios Spring Data. Cada consulta corresponde a um
  índice declarado na migration

`backend/src/main/resources/db/migration/V1__esquema_inicial.sql` — o Flyway é o
dono do esquema; o Hibernate nunca cria nem altera tabela.

**Os valores de enum são gravados em MAIÚSCULAS** (`ATIVA`, `EMAIL`), embora o
`data-model.md` os escreva em minúsculas. Assim banco e constante Java são
idênticos, sem conversor no meio. A camada de API converte para o formato do
contrato (`email`, `telefone`) ao responder.

**A trilha de auditoria não se reescreve**: `EventoAutenticacao` é
`@Immutable`, não tem método que altere estado, e o gatilho
`tg_evento_somente_insercao` recusa UPDATE **no banco** — inclusive por SQL
avulso. `DELETE` continua permitido de propósito, porque a retenção de 12 meses
exige expurgo. Testado em `PortoesDoEsquemaTest`.

`backend/src/main/java/br/fatec/memora/comum/` — o que atravessa a aplicação
inteira (T024-T026):
- `CodigoDeErro` — os 4 códigos do contrato mais `ERRO_INESPERADO`, cada um com
  status HTTP e o texto na persona da Memora no **mesmo lugar**
- `Erro` — o record do contrato. `tentar_novamente_em_segundos` some do JSON
  quando não há espera. Usa `@JsonProperty` em vez de estratégia global de
  snake_case, para que o nome que viaja esteja escrito ao lado do campo
- `FalhaDoMemora` — falha **prevista**, a única cuja mensagem chega à pessoa
- `TratadorGlobalDeErros` — a regra que sustenta a FR-041: **texto de exceção que
  não seja nossa nunca vai para a resposta**. Uma
  `DataIntegrityViolationException` traz o nome da constraint na mensagem;
  repassá-la revelaria que aquele canal já pertence a alguém, derrubando a FR-010
  por caminho lateral
- `FiltroRastreio` — Trace ID e Request ID no MDC e nos cabeçalhos. Request ID
  vindo do cliente é **validado antes de aceito**: quebra de linha no valor forja
  entrada de log e parte a resposta HTTP em duas
- `ContextoDaRequisicao` — `ThreadLocal` limpo no `finally`. Sem a limpeza, a
  origem de uma pessoa reaparece na requisição da seguinte
- `RegistroDeAuditoria` — ponto único de escrita na trilha

**A origem de rede é HMAC, não resumo simples.** SHA-256 puro não cumpre o que o
`data-model.md` pede: o espaço IPv4 inteiro são 4 bilhões de valores, revertidos
por força bruta a partir de uma cópia do banco. A chave vem de
`MEMORA_CHAVE_ORIGEM` e **precisa ser estável entre reinícios** — se mudar, a
contagem por origem da R4 zera junto com o processo.

**A chave dessa HMAC não tem padrão no repositório**, e isso é de propósito
(`ConfiguracaoDeRastreio`). Toda a proteção do parágrafo acima *é* a chave: com
chave conhecida, o HMAC vale o mesmo que o resumo sem chave que ele substituiu —
e um padrão commitado seria conhecido. Sem a variável, a chave é **sorteada na
subida** com WARN, exatamente como o `memora.token.segredo` já fazia; chave
informada com menos de 32 bytes **derruba a subida**. O preço do sorteio é a
contagem da R4 recomeçar a cada reinício, e ele é menor que entregar de bandeja
a origem de todo mundo.

**Falha que o Spring já classificou preserva o status dela.** O handler de
`Exception` verifica `instanceof ErrorResponse` antes de tratar como defeito:
sem isso, caminho inexistente e método errado saíam como `500` com stack trace em
nível ERROR, e um robô varrendo caminhos virava tempestade no log. Repare que
`NoResourceFoundException` **implementa** `ErrorResponse` sem estender
`ErrorResponseException` — por isso a verificação é por interface, e um
`@ExceptionHandler(ErrorResponseException.class)` não pegaria o caso.

**O `REQUIRES_NEW` da auditoria custa duas conexões por requisição.** Durante a
gravação do evento de recusa, a requisição segura a conexão da transação de fora
e a da de dentro. Com o padrão do Hikari (10), bastariam 10 requisições
simultâneas para o pool esperar por si mesmo; por isso
`spring.datasource.hikari.maximum-pool-size` está **explícito** em 20. O teto de
requisições simultâneas em operação auditada é metade desse número.

**A auditoria tem dois modos de gravação, e trocá-los quebra coisa.** Evento de
**recusa** vai em transação própria, senão o rollback da operação apaga o
registro da tentativa. Evento de **sucesso** não pode fazer isso: o evento de
cadastro aponta para conta criada na transação em curso e ainda não confirmada, e
`fk_evento_pessoa` quebraria. Há teste para os dois lados.

`backend/src/test/` — 151 testes. `TesteComBanco` é a base que compartilha **um**
PostgreSQL entre todas as classes (padrão singleton container); herdar dela
custa zero, subir um container por classe custaria ~15 s cada.

### Os três endpoints que existem hoje

`autenticacao/api/` — `ControladorCadastro` (T033) e `ControladorSessao`
(T047, T048). `autenticacao/aplicacao/` — `ServicoDeCadastro`,
`ServicoDeEntrada`, `ServicoDeRenovacao` e o record `SessaoDaPessoa`, que é a
forma comum das três respostas.

| Endpoint | Devolve | Recusa com |
|---|---|---|
| `POST /v1/auth/cadastro` | `201` + sessão | `400`, `429` |
| `POST /v1/auth/entrar` | `200` + sessão | `401` genérico, `429` com espera |
| `POST /v1/auth/sessao/renovar` | `200` + sessão | `401` genérico |

**Os serviços devolvem resultado; quem lança exceção é o controlador.** Não é
estilo: a recusa da entrada precisa **persistir** o contador de falhas, e lançar
`FalhaDoMemora` de dentro do serviço desfaria a transação e levaria o contador
junto — o limitador contaria até um para sempre e a FR-014 viraria enfeite.

**O login aceita qualquer canal cadastrado, verificado ou não.** A T047 dizia
"verificado", e estava errada: o cadastro cria canal não verificado e a
confirmação de posse só chega na T058, então exigir verificação deixaria toda
conta nova sem entrar. Quem autentica é a senha; o canal só localiza a conta. A
FR-052 exige verificação na **recuperação**, que é onde mora o golpe da FR-062.
Decisão de 2026-08-15; `data-model.md` e `openapi.yaml` corrigidos junto.

**O tipo do canal não é pedido no login** (`TipoDoIdentificador`): a presença de
`@` decide. Pedir o tipo devolveria à pessoa a pergunta "com qual dos dois você
se cadastrou?", que é o que a FR-051 existe para evitar. Procurar como e-mail *e*
como telefone foi recusado — o cadastro não valida formato, então nada impede um
canal `EMAIL` gravado como `"11999998888"`, e duas contas disputariam o login.

**A tentativa que estoura o limite já responde `429`**, não `401`. É o passo 2 do
V6. E insistir durante o bloqueio **não conta nova falha**, senão quem tentasse
três vezes durante a espera pularia dois degraus sem ter tido chance de acertar.

**A auditoria de recusa é escrita antes de gravar a conta.**
`registrarMesmoComRollback` abre transação própria; fazer isso com a linha da
pessoa já travada pela transação de fora colocaria duas conexões do mesmo pool
esperando uma pela outra a cada senha errada.

### Duas coisas que a revisão da #15 mudou — não desfaça sem ler

**1. `estado` da conta e `bloqueada_ate` são coisas separadas.**

`EstadoDaConta` guarda o **ciclo de vida** (`ATIVA`, `DESATIVADA`). A tranca
temporária do bloqueio tem sua verdade em `bloqueada_ate`, e
`BLOQUEADA_TEMPORARIAMENTE` é só o reflexo dela. Misturar os dois já custou um
defeito real: `bloquearAte` escrevia por cima de `DESATIVADA`, e cinco recusas
apagavam o marcador — passada a tranca, a conta desativada entrava e
`registrarEntradaBemSucedida` ainda a devolvia a `ATIVA`.

Hoje **`DESATIVADA` é terminal**: nem `bloquearAte` nem
`registrarEntradaBemSucedida` saem dele, e existe `PessoaUsuaria.desativar()`
para entrar nele. Reativar é ato explícito, e ainda não existe — quando a US4
criar, será um método novo, nunca um efeito colateral de login.

**Toda porta que a desativação fecha precisa ser fechada nos dois lados.**
`entrar` recusava conta desativada e `sessao/renovar` não: como a renovação
rotaciona o refresh e reinicia os 60 dias, quem já tivesse o token seguiria
dentro para sempre. Ao criar endpoint autenticado novo, pergunte o mesmo.

**2. O Argon2 não roda dentro de transação.**

`ServicoDeEntrada.entrar` **não** é `@Transactional`. São duas transações curtas
por `TransactionTemplate` — uma resolve a conta e a decisão do limitador, outra
grava o desfecho —, com o hash entre elas, fora de transação.

O motivo é disponibilidade: o Hibernate toma a conexão na primeira consulta e só
a devolve no commit, então o hash de ~240 ms segurava uma conexão do pool sem
tocar no banco. Com `maximum-pool-size=20`, vinte requisições simultâneas ao
endpoint **público** esgotavam o pool e faziam cadastro e renovação esperarem.

**A R3 continua de pé**, porque o que ela exige é o hash rodar *sempre*,
inclusive sem conta — e ele roda. `TempoConstanteTest` e o
`mesmaOrdemDeGrandeza` do `EntrarTest` seguem passando.

> ⚠️ `ServicoDeCadastro` **ainda tem o mesmo padrão** e não foi tocado nesta
> revisão. O cadastro é menos atraente para força bruta, mas a conta é a mesma.
> Vale medir antes de decidir se muda.

**3. O caminho bloqueado não escreve na trilha por tentativa.**

Escrevia um evento `BLOQUEIO` por requisição — no único caminho que não paga o
Argon2. Era escrita ilimitada, de graça, para quem não está autenticado, numa
tabela com retenção de 12 meses.

**O que se perde está registrado**: a contagem da insistência depois de fechada
a porta. O `BLOQUEIO` continua escrito uma vez, quando aplicado, e as
`FALHA_ENTRADA` que o produziram seguem na trilha. Se a equipe quiser a
insistência de volta, o caminho é contá-la de forma limitada — **não** voltar ao
INSERT por requisição.

### A sessão-chamariz — leia antes de criar endpoint autenticado

`POST /v1/auth/cadastro` responde `201` **idêntica** quando o canal já pertence a
alguém, porque a FR-010 proíbe revelar a existência e o V2 reprova "qualquer
diferença observável em corpo, código de status ou tempo". Como a resposta
carrega uma sessão, não há como cumprir isso sem devolver uma sessão.

O que volta nesse caso é um **JWT assinado de verdade para um UUID que não
existe**, com refresh não gravado e nada criado no banco. Devolver a sessão da
conta real entregaria a conta a quem soubesse o e-mail; devolver texto aleatório
seria detectável, porque o token real é um JWT de três segmentos.

**A consequência que atravessa a aplicação inteira**: existe token com assinatura
válida cujo sujeito não corresponde a conta nenhuma. Todo caminho autenticado
**precisa resolver o sujeito e recusar quando não encontrar**. Assinatura válida
não é autorização. Quem esquecer disso transforma o chamariz em acesso.

A senha é hasheada **nos dois caminhos, antes da consulta ao canal**. Sem isso o
cadastro contra canal existente responde em ~11 ms contra ~261 ms, e a latência
entrega o que o corpo escondeu — medido, não suposto.

### Trinta e quatro portões de segurança, cada um validado quebrando de propósito

| Portão | Onde | Como foi provado |
|---|---|---|
| Entidade bate com a migration | `contextLoads` | Renomeei uma coluna: reprovou com `missing column` |
| Tempo não revela conta existente | `TempoConstanteTest` | Pus o atalho `return false`: reprovou com **0 ms** contra os ~240 ms esperados |
| Reuso de token derruba a família | `ReusoDeTokenTest` (V3) | Revoguei só o token reusado: reprovou com "B continuou funcionando" |
| Falha do framework não vira 500 | `TratadorGlobalDeErrosTest` | Desliguei o `instanceof ErrorResponse`: reprovou com `expected:<404> but was:<500>` |
| Chave de origem fraca não sobe | `ConfiguracaoDeRastreioTest` | Removi a checagem de tamanho: reprovou com "Expecting code to raise a throwable" nas três chaves curtas |
| Latência não revela conta existente | `NaoRevelaExistenciaTest` (V2) | Movi o hash da senha para depois da consulta ao canal: reprovou com **11 ms contra 261 ms** |
| Piso da senha bate com o da tela | `PoliticaDeSenhaTest` | Subi o piso do servidor para 12: o teste que lê `controlador_cadastro.dart` reprovou |
| Credencial não vai para armazenamento comum | `armazenamento_seguro_test.dart` (V8) | Gravei o token em `SharedPreferences` de propósito: reprovou com `Expected: empty / Actual: Set:['token']` |
| Latência do login não revela conta | `EntrarTest` | Pus `if (pessoa == null) return recusar(...)` antes do hash: reprovou com **18 ms contra 282 ms** |
| Bloqueio correto com texto ríspido reprova | `BloqueioProgressivoNoLoginTest` (V6) | Troquei a mensagem por "Conta bloqueada: você excedeu o número de tentativas": a **escada continuou passando** e os 3 testes de texto reprovaram |
| O mesmo, agora na tela | `tela_login_test.dart` (FR-015) | Troquei `TextosAutenticacao.bloqueio` pela versão ríspida: escada, botão sumindo, contagem regressiva e liberação automática **continuaram passando**; só os 3 testes de texto reprovaram |
| Identificador só é gravado depois do sucesso | `tela_login_test.dart` (FR-012) | Movi `lembrar()` para antes da resposta do servidor: reprovou com `Expected: null / Actual: 'ana@email.com'` |
| Bloqueio não ressuscita conta desativada | `BloqueioProgressivoNoLoginTest` | Tirei a guarda de `bloquearAte`: a sexta tentativa devolveu **200**, com `expected:<CLIENT_ERROR> but was:<SUCCESSFUL>` |
| Renovação recusa conta desativada | `RenovarSessaoTest` | Pus `if (false && ...)` na checagem: reprovou com `expected:<401> but was:<200>` nos dois testes |
| Chamariz não vira acesso | `CanalNaoVerificadoTest` | Fiz o filtro confiar só na assinatura do JWT: reprovou com `Status expected:<401> but was:<202>` — o token de sujeito inexistente abriu o endpoint |
| Cadastro assistido não conclui sozinho | `CanalNaoVerificadoTest` (V4) | Fiz a conta assistida nascer `ATIVA`: **5 testes** reprovaram, um deles com `expected:<401> but was:<200>` — a pessoa entrou sem confirmar canal |
| Canal alheio não se verifica | `CanalNaoVerificadoTest` | Tirei o filtro por dono: reprovou com `Status expected:<400> but was:<200>` — autenticada, verifiquei o canal de outra conta |
| Bloqueio não conclui cadastro assistido | `CanalNaoVerificadoTest` | Devolvi `bloquearAte` a `!= DESATIVADA`: reprovou com `expected: PENDENTE_VERIFICACAO` — 5 senhas erradas tiravam a conta da espera |
| A senha para o acompanhante (FR-059) | `controlador_cadastro_test.dart` e `fluxo_assistido_test.dart` | Fiz `podeDigitarSenha => true`: **4 testes** reprovaram, um com `Expected: null / Actual: Instance of 'DadosDeCadastro'` — o acompanhante criou a senha |
| A primeira entrada é sozinha (FR-063) | `fluxo_assistido_test.dart` | Fiz a confirmação levar direto para dentro: **4 testes** reprovaram com `Found 0 widgets with type "TelaPrimeiraEntrada"` |
| A recuperação não revela conta (FR-019) | `tela_recuperacao_test.dart` | Fiz `solicitarRecuperacao` falhar sem conta: **3 testes** reprovaram, o primeiro com `Expected: true / Actual: <false>` — a tela parou na primeira etapa e contou |
| O aviso antigolpe é permanente (FR-023) | `tela_recuperacao_test.dart` | Deixei o aviso só na primeira etapa: reprovou com `Found 0 widgets with type "AvisoAntigolpe"` |
| O número recusado sai do campo | `tela_recuperacao_test.dart` | Tirei a limpeza do código: reprovou com `Expected: empty / Actual: '000000'` |
| A troca conta que as sessões caíram (FR-021) | `tela_recuperacao_test.dart` | Troquei o aviso por "Pronto!": reprovou com `Found 0 widgets with text "Sua senha nova já está valendo..."` |
| O código de recuperação é de uso único (FR-020) | `tela_recuperacao_test.dart` | Não removi o código do mapa: reprovou com `expected AutenticacaoFalhou but was AutenticacaoConcluida` |
| Trocar a senha derruba **todas** as sessões (FR-021) | `TrocaDeSenhaRevogaSessoesTest` (V5) | Comentei `revogarSessoesDaPessoa`: **2 testes** reprovaram, o primeiro com `expected:<401> but was:<200>` — o refresh antigo continuou renovando |
| Só canal verificado recebe código (FR-052) | `TrocaDeSenhaRevogaSessoesTest` | Tirei o `!isVerificado()`: reprovou com `Expecting empty but was: ["562181"]` — o golpe da FR-062 acontecendo em uma linha |
| Latência da recuperação não revela conta (FR-019) | `NaoRevelaExistenciaTest` (V2) | Movi o hash do código para depois da consulta ao canal: reprovou com **9 ms contra 274 ms** |
| A sessão da recuperação sobrevive à revogação | `TrocaDeSenhaRevogaSessoesTest` | Inverti a ordem — emitir antes de revogar: reprovou com `expected:<200> but was:<401>`, a sessão nova morreu junto com as velhas |
| Trocar a senha destranca a conta bloqueada | `TrocaDeSenhaRevogaSessoesTest` | Tirei o `registrarEntradaBemSucedida`: reprovou com `expected: null` — a pessoa trocava a senha e continuava trancada do lado de fora |
| Sair encerra **de verdade** (FR-026) | `SairEncerraSessaoTest` | Pus `if (false)` na revogação: **3 testes** reprovaram, o principal com `expected:<401> but was:<200>` — o refresh de 60 dias continuou renovando depois do `204` |
| Sair encerra **só este aparelho** (FR-024) | `SairEncerraSessaoTest` | Troquei por `revogarSessoesDaPessoa`: **2 testes** reprovaram com `expected:<200> but was:<401>` — o tablet caiu junto com o celular |
| Sair exige confirmação (FR-025) | `saida_limpa_armazenamento_test.dart` | Liguei o botão direto no `_sair`: **4 testes** reprovaram com `Found 0 widgets with key [<'perfil.confirmacao'>]` |
| A credencial sai do aparelho (FR-026) | `saida_limpa_armazenamento_test.dart` | Comentei o `_cofre.limpar()`: reprovou com `Expected: null / Actual: 'refresh-de-60-dias'` |

**Faça o mesmo com qualquer portão novo.** Foi assim que descobrimos que os
trinta e quatro realmente pegam — e foi a **ausência** desse hábito que deixou a guarda de
conta desativada entrar sem teste nenhum e furada, na revisão da #15.

⚠️ **Os cinco portões da recuperação passaram todos na primeira execução**, e
isso não significou nada até cada um ser quebrado. Os cinco pegaram exatamente o
que deveriam, e nenhum pegou o do vizinho — que é o segundo passo que o achado
do `ControladorLogin` ensinou a fazer.

### Duas decisões que divergem da pesquisa — reabra se discordar

**A R4 sugeria Bucket4j; não usamos.** As duas camadas guardam estado no banco:
a camada por conta em `pessoa_usuaria.falhas_consecutivas`/`bloqueada_ate`, e a
camada por origem contando `evento_autenticacao`, que a FR-039 obriga a escrever
de qualquer forma. Bucket4j traria dependência e tabela própria para
reimplementar contagem que já existe. A troca fica isolada em
`LimitadorTentativas`.

**Brecha conhecida e aceita por ora**: só conta que existe pode ser bloqueada,
então um `429` depois de 5 tentativas revela que aquele identificador tem conta —
o oposto do que a R3 busca. A camada por origem atenua. Fechar de vez exigiria
contar falhas por identificador, inclusive inexistente, e a trilha
deliberadamente não guarda identificador (FR-040). **Decisão da equipe.**

### Dívida deixada pelo T027 — leia antes de mexer no cliente da API

1. ~~**O cliente foi gerado dentro de `app/lib/services/api/`**~~ — **resolvido
   na revisão da PR #11.** O pacote vive em **`app/pacotes/memora_api/`**, é
   dependência `path:` declarada em `app/pubspec.yaml`, e o `-Saida` padrão do
   script aponta para lá.

   Vale saber por que isso importava mais do que parecia. Dentro de `lib/`, o
   pacote **não era dependência de ninguém**: nada o importava, a análise
   estática o excluía, e os 46 testes que o gerador escreve **não rodavam**, pois
   `flutter test` só varre `app/test/`. Ou seja, o entregável do T027 não era
   verificado por nada — uma regeração quebrada passaria até o dia em que uma
   tela precisasse dele. Agora há um job próprio no CI (`cliente-gerado`) que
   roda `dart analyze` e `dart test` no pacote.

   Os quatro avisos `unused_import` que motivaram a exclusão da análise são
   silenciados **um a um**, pelo próprio script, no `analysis_options.yaml`
   gerado. Excluir o pacote inteiro esconderia erro de verdade, que é justamente
   o que precisa ser pego quando o contrato mudar.

2. **As tags acentuadas do contrato não foram normalizadas**, e os nomes saíram
   mutilados como o aviso previa: `sesso_api.dart`,
   `recuperao_de_acesso_api.dart`. Normalizar as tags do `openapi.yaml` para
   ASCII resolve, mas mexe no contrato — pelo Princípio IV isso é decisão de
   spec, não de implementação. **Precisa passar por `/speckit-clarify`.**

3. **O springdoc continua fora do pom.** Este arquivo dizia que ele entraria no
   T024; não entrou. Não fez falta ainda porque não existe endpoint para
   documentar, mas a lacuna do T002 segue aberta — junto com o Bucket4j, que
   permanece dispensado por decisão consciente (ver "Duas decisões que divergem
   da pesquisa", acima).

### Divergências do contrato — agora rastreadas na **T027a**

**`ERRO_INESPERADO` não existe no `openapi.yaml`.** Nenhuma operação documenta
resposta `500`, e ela vai acontecer. Sem código nosso, a falha inesperada sairia
no formato padrão do Spring, que carrega caminho da requisição e classe da
exceção — exatamente o que a FR-041 proíbe. Foi implementado porque a
alternativa era vazar.

**`404` e `405` também não estão no contrato**, e o servidor os devolve desde a
correção do handler de `ErrorResponse`. Saem com `DADOS_INVALIDOS`, que é o
código mais próximo — nenhuma tela depende disso, porque o aplicativo só chama
caminhos que o cliente gerado conhece.

Dívida de spec, não de código. Está na **T027a** do `tasks.md`, para não
depender de alguém reler este arquivo. Fechá-la também elimina os
`unused_import` do cliente gerado, que existem justamente porque nenhuma
operação declara resposta de erro.

### As telas da US2 — o que ficou decidido (T051-T056, 2026-08-20)

O login existe e funciona sobre o simulado. Três decisões saíram daqui e valem
saber antes de mexer:

| Decisão | Escolha | Por quê |
|---|---|---|
| Onde mora o identificador do último acesso | `shared_preferences` | Não é credencial, e cifrá-lo não protege nada: o propósito da FR-012 é **exibi-lo na tela**. Guardá-lo no cofre obrigaria a afrouxar o V8, que reprova se sobrar **qualquer coisa** lá depois de sair |
| Onde moram os textos | Arquivo Dart em `app/lib/l10n/` | É a "estrutura preparada" da decisão D3. `.arb` mexeria em pubspec, build e CI para entregar zero comportamento |
| Prazo de inatividade | 30 min, aviso 2 min antes | A spec só dizia "período prolongado". O número veio da ameaça que a FR-017 mitiga na tabela da spec: **celular esquecido na mesa**, não "faz semanas que não abro" |

⚠️ **`RepositorioAutenticacao` ganhou `encerrarSessao()`, e ela é só local.**
Sem apagar a credencial do aparelho a FR-017 não encerraria nada — o monitor
levaria a pessoa ao login e a renovação automática a colocaria de volta no mesmo
instante. Mas `POST /v1/auth/sair` é a **T074** e ainda não existe: o refresh
apagado aqui **continua válido no servidor até vencer**. Chamá-lo hoje daria
`404`, que o tratador converteria em `DADOS_INVALIDOS` e prenderia a pessoa numa
tela de erro ao tentar sair. A US4 fecha isso com a T077.

⚠️ **Cadastrar também grava o identificador do último acesso.** Achado ao
implementar: só o login gravava, e cadastro **é** acesso bem-sucedido (FR-009) —
quem criasse a conta teria que digitar o e-mail inteiro no primeiro login, que é
a barreira que a FR-012 existe para remover. Quem grava é o `FluxoAutenticacao`
(`_cadastrou`), não o `ControladorCadastro`, para o controlador do cadastro não
passar a depender de armazenamento.

⚠️ **O botão "Esqueci minha senha" não aparece.** `TelaLogin.aoRecuperar` é
opcional e ninguém o preenche, porque a recuperação é a US3. Oferecer saída que
não leva a lugar nenhum é pior que não oferecer — mesmo idioma do `aoJaTerConta`
na `TelaBoasVindas`, que ficou nulo até esta sessão. O texto do bloqueio já
menciona o caminho, que é o que a FR-015 exige.

### A US5 — o modo assistido (T057-T065, 2026-08-24)

Protege a autonomia de quem está sendo ajudada. O acompanhante preenche nome e
canal, e **para na senha**: o aplicativo pede o aparelho de volta antes de
qualquer campo de senha existir na árvore.

| Decisão | Escolha | Por quê |
|---|---|---|
| Como o cadastro assistido "não conclui" (FR-062) | Conta nasce `PENDENTE_VERIFICACAO`, migration **V3** | O canal só existe **dentro** do cadastro, e confirmar posse exige token que só é emitido no fim dele. Sem um estado intermediário, a FR-062 é literalmente impossível |
| Hash do código de 6 dígitos | **Argon2**, não SHA-256 | São 10⁶ possibilidades: resumo simples se inverte em tempo desprezível. Os ~240 ms também freiam a força bruta **online**, que é a ameaça concreta num espaço desse tamanho |
| Renovação com conta pendente | **Permitida** | O token vale 15 min. Recusar prenderia quem demorasse mais que isso para digitar o código — e sem saída, porque o canal já está ocupado pela própria conta pendente e um novo cadastro cairia no chamariz |

⚠️ **Confirmar posse não prova de quem é o canal.** Prova que quem digitou o
código *alcança* aquele contato — e o acompanhante está ao lado, com o próprio
telefone. Quem de fato mitiga a FR-062 é a **entrega do aparelho** (FR-059) e a
**primeira entrada sozinha** (FR-063). Não confie no portão errado.

⚠️ **Não existe envio de e-mail nem de SMS**, e nunca houve tarefa para isso na
feature 001. Há a porta `EnviadorDeCodigo` e um adaptador que **escreve o código
no log**, restrito a `@Profile("!producao")` — com o perfil `producao` a
aplicação **não sobe**, por falta do bean. É deliberado: seguir adiante
responderia `202` "código enviado" a quem nunca receberá nada. Está na **T065a**.

⚠️ **Conta assistida abandonada fica pendente para sempre** e mantém o canal
ocupado. Quem desistir no meio não consegue recadastrar com o mesmo e-mail — cai
no chamariz da FR-010. Está na **T065b**.

### As telas da US3 — recuperar o acesso (T070-T073, 2026-08-27)

Uma tela, `TelaRecuperacao`, com **três etapas** no `ControladorRecuperacao`:
pedir o número, digitar código e senha nova, e a confirmação.

| Decisão | Escolha | Por quê |
|---|---|---|
| Uma tela ou três | **Uma** | O aviso antigolpe da FR-023 é **permanente**. Duplicá-lo em três arquivos é como ele começa a divergir — basta alguém melhorar a frase de um |
| Onde fica o aviso | **No topo, antes do convite** | Quem está sendo enganado ao telefone é conduzido direto ao campo. Aviso embaixo do formulário só é lido por quem já não precisava dele |
| Depois de trocar a senha | **Uma terceira etapa**, com botão | Entrar em silêncio desperdiçaria a FR-021. Quem recupera a conta pode estar fazendo isso **porque** alguém entrou nela: saber que os outros aparelhos saíram é a notícia que importa |
| "Não recebi" | **Volta à primeira etapa** | Diferente da `TelaConfirmarCanal`, onde o canal foi digitado três telas antes e está certo. Aqui o endereço acabou de ser escrito por alguém com dificuldade, e **o motivo mais comum de "não recebi" é a digitação errada** |
| Regras da senha nova | **As mesmas do cadastro**, reusando `RegraDeSenha` | Senha criada aqui vale o mesmo que a criada lá. `RegraDeSenha` **fica em `controlador_cadastro.dart`**: `PoliticaDeSenhaTest`, no backend, lê esse arquivo para conferir que o piso bate com o do servidor — movê-la quebra o portão |

⚠️ **O aviso da FR-023 fala do número, não só da senha.** O texto da spec
menciona senha; o golpe **desta tela** pede o código de 6 dígitos — o golpista
dispara a recuperação com o e-mail da vítima, liga dizendo ser o suporte e pede
"o código que acabou de chegar". Avisar só sobre a senha deixaria de fora
exatamente o dado que está na tela. Há teste que reprova se o texto perder
qualquer um dos dois.

⚠️ **O `RepositorioAutenticacao` ganhou dois métodos, e o primeiro nunca falha
por conta inexistente.** `solicitarRecuperacao` devolve `CanalConcluido`
**sempre** que a chamada chegar. `CanalFalhou` ali significa *não consegui
perguntar* — nunca *essa conta não existe*. O controlador segue de etapa sem
ramo para o segundo caso, de propósito: quem for acrescentar um vai ter que
inventar de onde essa informação veio, e é aí que percebe que inventá-la é o
vazamento.

⚠️ **O botão "Esqueci minha senha" agora aparece.** `TelaLogin.aoRecuperar`
estava nulo desde a US2 justamente porque não havia para onde ir. O
`FluxoAutenticacao` o preenche, e leva o identificador junto (FR-012).

### O backend da US3 — recuperar o acesso (T066-T069, 2026-09-08)

`autenticacao/aplicacao/ServicoDeRecuperacao.java` e
`autenticacao/api/ControladorRecuperacao.java`. Fecha o buraco que existia desde
a PR #20: as telas chamavam dois endpoints que respondiam `404`.

| Endpoint | Devolve | Recusa com |
|---|---|---|
| `POST /v1/auth/recuperacao/solicitar` | `202` **sempre** | `429` só por origem |
| `POST /v1/auth/recuperacao/confirmar` | `200` + sessão | `400` genérico, `429` |

**Conta bloqueada recupera, sim — e a troca destranca.** A tela de bloqueio
oferece "Criar uma senha nova" como saída; recusar a recuperação por causa do
bloqueio faria dela porta pintada na parede. Por isso `solicitar` **não** olha
`bloqueada_ate` (só a camada por origem), e a confirmação chama
`registrarEntradaBemSucedida`, que limpa falhas e a tranca. Sem essa limpeza, a
pessoa faria tudo certo e continuaria trancada do lado de fora — resolvendo
metade do problema.

**A ordem de três linhas é o cenário V5.** Revogar **todas** as sessões vem
antes de emitir a nova. Invertida, a sessão recém-criada morre junto com as
velhas e a pessoa sai da recuperação com um token morto. E precisa ser todas as
sessões da pessoa, não só a família da atual: quem troca a senha por suspeitar
de invasão está justamente tentando expulsar uma sessão que não é dela.

**Nenhum Argon2 dentro de transação, de novo.** `confirmar` paga **dois** hashes
(~480 ms): conferir o código e codificar a senha nova. É o mesmo
`TransactionTemplate` que a revisão da #15 aplicou em `ServicoDeEntrada`, pelo
mesmo motivo — conexão presa sem tocar no banco, em endpoint público. Duas
transações curtas, os hashes entre elas.

**O hash roda antes da consulta ao canal, nos dois caminhos.** Terceiro endpoint
público a precisar disso, e o portão mediu **9 ms contra 274 ms** quando
quebrado. `ServicoDeCadastro` e `ServicoDeEntrada` já faziam; suspeite disso em
qualquer endpoint público novo.

**A porta `NotificadorDeConta` ficou em `aplicacao/`, não em `infra/`** como a
T068 escreve — mesma divisão que `EnviadorDeCodigo` já usa, e o que o Princípio
V pede. O adaptador é `infra/NotificadorDeContaEmLog.java`, `@Profile("!producao")`.

⚠️ **Continua sem provedor de envio** (T065a). Sem ele, o código de recuperação
e o aviso de senha alterada vão para o log, e o perfil `producao` não sobe. A
FR-022 está implementada e não chega a ninguém em produção — é a mesma lacuna do
modo assistido, agora em dois lugares.

⚠️ **A confirmação não exige canal verificado por argumento separado**: ela
localiza o canal e recusa se não for verificado, igual ao `solicitar`. Se alguém
acrescentar um caminho de troca de senha autenticado (a US4 vai), lembre que a
regra precisa valer lá também — a mesma lição que a #15 deixou sobre conta
desativada em `entrar` e `renovar`.

## 4-B. A feature 003 — Hub e a assistente que ensina

Feita em 2026-08-29, do zero até a fase 7. É a primeira feature **do produto**:
as 001 e 002 são fundação, e nenhuma delas responde para que o Memora serve.

### A decisão que organiza tudo

**A saída do modelo não é autorização.** O modelo pode *sugerir* abrir um
aplicativo; quem decide é uma consulta determinística ao catálogo, no banco,
**depois** da resposta. Sugestão que não passa morre no servidor, e a pessoa
nunca vê o oferecimento.

Alguém pode convencer um modelo. Ninguém convence uma linha de tabela.

### As três decisões de spec (D1, D2, D3)

| # | Decisão | Por quê |
|---|---|---|
| **D1** | A lista fechada tem **uma** ação: abrir aplicativo cotidiano | Abrir é reversível. Enviar mensagem e ligar ficaram de fora por serem irreversíveis, e por serem o que um golpista pediria |
| **D2** | **Quanto mais sensível o serviço, menos a Memora toca nele** | Gov.br e Meu INSS ela **só ensina**, nem com pedido e confirmação. Abrir o banco pela pessoa treinaria nela o gesto que o golpista precisa que ela tenha |
| **D3** | A conversa fica **só no aparelho** | No servidor viraria acervo Confidencial sobre a intimidade de quem é alvo preferencial de golpe no Brasil |

A tela de **Planos** do Arquivo X ficou como **Futuro**, fora de escopo:
monetização nunca foi discutida pela equipe.

### O que existe em código

`backend/.../assistente/`:
- **dominio/** — `ServicoConhecido`, `CategoriaDoServico` (SENSIVEL/COTIDIANO),
  `EventoDaAssistente` (`@Immutable`), `UsoDaAssistente`
- **aplicacao/** — `AutorizadorDeAcao` (**a FR-022 mora aqui**),
  `ServicoDeConversa`, `ServicoDeRegistro`
- **infra/** — a porta `ClienteDaAssistente`, o simulado, `PersonaDaMemora`
- **seguranca/** — `LimitePorConta`, teto diário de conversas
- **api/** — `ControladorConversa` (SSE), `ControladorCatalogo`,
  `ControladorRegistro`

Migrations **V4** (estrutura), **V5** (catálogo inicial) e **V6** (Meu INSS).

`app/lib/features/hub/` e `app/lib/features/assistente/` — Hub com 5 portas,
conversa, catálogo (uma tela parametrizada), registro, `ConversaLocal` e
`AbridorDeAplicativo`.

### ⚠️ A FR-041 é restrição de banco, não regra de código

```sql
CONSTRAINT ck_servico_sensivel_nao_abre CHECK (
    (categoria = 'SENSIVEL'  AND identificador_android IS NULL)
    OR
    (categoria = 'COTIDIANO' AND identificador_android IS NOT NULL)
)
```

**Serviço sensível não tem como ser aberto porque falta o dado necessário para
abri-lo.** Não existe caminho de código que contorne a ausência de um pacote.
Quem mudar a categoria de um banco para `COTIDIANO` vai ter que preencher o
pacote junto — gesto visível na revisão. Uma verificação em Java alguém remove
sem querer.

### ⚠️ O Android 11 limita ACRESCENTAR aplicativo, não tirar

Desde o Android 11, o aplicativo só enxerga pacotes declarados em `<queries>`
no `AndroidManifest.xml`. O catálogo no banco continua permitindo **tirar** um
aplicativo do ar sem novo build (era o objetivo da R6) — mas **acrescentar** um
abrível exige mexer no manifesto e publicar versão nova na loja.

Não usamos `QUERY_ALL_PACKAGES`: a Play Store restringe severamente, e ela daria
ao Memora visibilidade de tudo que a pessoa tem instalado.

### ⚠️ O simulado do aplicativo precisa espelhar o catálogo do banco

Eles são mundos separados, e **nenhum teste pega a divergência** — ela só
aparece rodando no emulador. Aconteceu nesta sessão: a demonstração mostrava
serviços que a migration não tinha. A cada mudança de catálogo, mexa nos dois.

### ⚠️ Por que o simulado é ferramenta de segurança, e não andaime

O cenário **H3** precisa que a assistente sugira abrir o banco. Um modelo real,
bem instruído, provavelmente **não** sugeriria — e um teste que depende de o
modelo se comportar mal para provar que a defesa funciona não prova nada.

No `ClienteDaAssistenteSimulado` a sugestão maliciosa é produzida sob comando,
em toda execução. **É a diferença entre torcer para o portão ser testado e
testá-lo.**

### A T069 e o que ela encontrou (2026-09-15)

A tabela **"Onde cada cenário roda"**, no fim do
[quickstart.md](specs/003-hub-e-assistente/quickstart.md), aponta qual teste é
qual cenário. `H1` a `H11` estão automatizados; o `H12` são cinco pessoas.

🔴 **A FR-048 não estava implementada, e a `LimpezaDeSessao` era código morto.**
Sair da conta **não apagava a conversa do aparelho**, e a classe que deveria
fazer isso não era usada por ninguém em `lib/` — só por um teste. A saída real
chamava `_cofre.limpar()` direto, de dentro do `RepositorioAutenticacaoApi`.
Consequência colateral: `esquecerTudo: true`, que este arquivo descrevia como
"uma linha só, num lugar só", **não existia em lugar nenhum do aplicativo**.

Hoje a `LimpezaDeSessao` recebe `List<DadoLocalDaPessoa>`, vem da `Composicao`
e roda em **toda** saída — inclusive a automática por inatividade, que é
justamente o caso do celular esquecido na mesa. O cofre continua sendo limpo
também pelo repositório, e precisa: a ordem exige que o token que autentica a
chamada de saída só vá embora depois que ela volta.

⚠️ **T066 e T067 não pertenciam à fase 8.** A `tasks.md` os coloca junto com a
escolha do provedor, e nenhum dos dois depende dela: o H5 é provado com o
simulado **obedecendo** à injeção (depender de um modelo real resistir provaria
menos), e o teto diário é inteiramente nosso. Os dois foram escritos na T069.

⚠️ **O H10 diverge do que acontece no fio.** O cenário espera `429` com espera;
a conversa é **SSE**, então quando a cota acaba o stream já respondeu `200` e o
limite viaja como evento `erro` com `LIMITE_DE_CONVERSAS`. Não há campo de
espera no corpo. Não é defeito — é o cenário descrevendo outra coisa. Decidir
se corrige o texto ou o transporte.

### O que falta na 003

| Fase | Tarefas | Situação |
|---|---|---|
| **8 — o provedor** | T061-T068 | **Espera a equipe escolher.** Só esta fase depende |
| 9 — validação | T069, T071-T074 | ✅ T070 feita (2026-09-10). O resto não depende da fase 8 — T071 é o **V10 com 5 pessoas de 65+** |

Também ficaram adiadas a **T021** e a **T036** (gerar o cliente Dart da 003):
gerariam cliente para endpoints cujo contrato ainda não foi fundido com o da
001 — decisão de spec.

---

### O que ainda falta na feature 001

**Nada, exceto a fase 8** — login social (T079-T083), que tem bloqueio externo
não levantado: registrar o aplicativo no Google e no Facebook, obter client IDs,
e aprovação no Facebook não é rápida. Confirmar **antes** de a fase chegar.

A US3 fechou em 2026-09-08, e a **US4 também** — ver as duas seções acima.

### A US4 — sair da conta (T074-T078, 2026-09-08)

`ServicoDeSaida`, `POST /v1/auth/sair` no `ControladorSessao`, e no aplicativo
`TelaPerfil` + `services/seguranca/limpeza_de_sessao.dart`.

⚠️ **O JWT ganhou o campo `fam`, e isso atravessa o sistema inteiro.** O `sub`
identifica a pessoa, e uma pessoa tem várias sessões — sem o campo não havia
**o que** encerrar. `EmissorDeTokenDeAcesso.emitir` agora exige o `familiaId`,
`sujeitoDoToken` devolve os dois, e `PessoaAutenticada` carrega a família.

**É a família, não a linha de sessão.** A renovação cria uma linha nova a cada
rotação; a família é o que atravessa as rotações e significa "este aparelho,
desde que entrou". Revogar a linha deixaria o refresh vivo depois da primeira
renovação — há teste para isso.

**Token sem o campo revoga todas as sessões.** É o token emitido antes da T074 e
ainda dentro dos 15 minutos: na dúvida sobre qual aparelho encerrar, encerrar
demais protege; encerrar de menos deixa alguém conectado achando que saiu.

**`revogarFamiliaDaPessoa` amarra a família à pessoa.** O claim é assinado por
nós e não é manipulável de fora — a cláusula é defesa em profundidade, custa
nada (mesmo índice) e transforma um eventual defeito nosso na emissão, que hoje
seria negação de serviço contra sessão alheia, em comando que não afeta linha
nenhuma.

**Sair nunca falha para a pessoa.** `RepositorioAutenticacaoApi.encerrarSessao`
avisa o servidor e **engole a falha de rede**. O preço é uma sessão que
sobrevive até vencer; o preço de propagar seria uma pessoa idosa vendo "erro ao
sair" e concluindo que continua conectada — sem saber que não está. E a limpeza
local, que é o que de fato tira o acesso deste aparelho, acontece de qualquer
jeito.

**A `ConfirmacaoMemora` comum passou a aceitar `aviso`.** Antes era só da
variante irreversível. Sair não destrói nada e não merece o tom grave —
reservá-lo ao que é de fato irreversível é o que faz esse tom continuar
significando alguma coisa —, mas "você vai precisar da senha para voltar" é a
informação que transforma a pergunta numa decisão.

### ✅ A contradição FR-012 × FR-026 foi resolvida

**O identificador do último acesso permanece; toda credencial vai embora.**
Decisão do Henrique em 2026-09-08, registrada na `spec.md` ao lado da FR-026.

Apagá-lo tornaria a FR-012 inútil justamente no caso mais comum — a pessoa sai
e volta depois —, e para o público que tem mais dificuldade em digitar um e-mail
inteiro. O que a FR-026 protege de verdade continua protegido: quem pega o
aparelho encontra um e-mail preenchido e **nenhuma forma de entrar com ele**.

`LimpezaDeSessao.executar(esquecerTudo: true)` faz a leitura literal, para
aparelho compartilhado ou que será vendido. **Não é o padrão**, e mudar isso é
uma linha só, num lugar só.

A **fase 7 da feature 002 fechou em 2026-09-15** (T045-T048). Ver "A galeria
e o portão dos tokens", logo abaixo.

### A fase 8 da 002 — o que a T049 encontrou (2026-09-15)

A tabela **"Onde cada cenário roda"**, no fim do
[quickstart.md da 002](specs/002-design-system/quickstart.md), aponta qual teste
é qual cenário — V1 a V10.

🔴 **O V5 estava sendo dado como automatizado sem nada o automatizando.** O
cenário mandava rodar `flutter analyze` para detectar valor literal fora dos
tokens, e **não existe lint do Dart para isso**. Só passou a ser verdade com o
`validar_tokens.py` da T046. Corrigido no texto do cenário.

⚠️ **V9 e V10 não tinham teste nenhum.** Agora têm, e os dois foram escritos
contra o problema de amanhã:

- o do **V9** é portão de **código-fonte**: toda animação em `app/lib/` precisa
  passar por `MemoraMovimento.efetiva`. A primeira versão varria a galeria
  montada e **não servia** — a `ListView` é preguiçosa, e os componentes
  animados nem chegavam à árvore;
- o do **V10** compara o barril `design_system.dart` com a galeria, e reprova
  nomeando o componente ausente. Provado tirando o `CampoCodigo` de propósito.

⚠️ **Animação do Material não obedece a "reduzir movimento", e não é nossa.**
Montar um botão traz seis `ImplicitlyAnimatedWidget` do Flutter, todos em
200 ms, nenhum consultando `disableAnimations`. Um portão que exigisse zero de
todos reprovaria contra código que não temos como consertar. O V9 vale para o
que é nosso, e o que importa — que nenhuma informação dependa **só** do
movimento — tem caso próprio.

**As divergências do protótipo estão em
[docs/design/divergencias-do-prototipo.md](docs/design/divergencias-do-prototipo.md)**
(T052, FR-038), cada uma com a medição que a justificou. O resumo:
**o protótipo acertou a paleta e errou o tamanho** — a expectativa da equipe era
a oposta, e a medição desmentiu.

### A galeria e o portão dos tokens (T045-T048, 2026-09-15)

`app/lib/design_system/galeria/galeria_memora.dart` monta **todo** componente
em **todo** estado, com troca de tema e de ampliação por dentro. Ela vive na
aba "Componentes" da casca de demonstração e **substituiu** a vitrine antiga
(`demonstracao/tela_componentes.dart`, apagada): duas listas dos mesmos
componentes é como elas começam a divergir.

⚠️ **`GaleriaMemora.paraDesenvolvimento()` devolve `null` fora do
`kDebugMode`**, e isso é a R9. Quem chama trata o `null` — o resultado é que,
num build de release, **não existe botão** que leve à galeria, em vez de
existir um botão que leva a uma recusa. Há teste prendendo esse contrato: se
alguém trocar o retorno por `Widget` não-anulável, ele para de compilar.

⚠️ **Percorrer a galeria é teste de fumaça do sistema inteiro — mas só se
rolar.** A lista é uma `ListView`, que só constrói e mede o que está na janela:
a primeira versão de `test/design_system/galeria_test.dart` montava a galeria e
olhava `takeException()`, e o campo de senha, o de código, a confirmação e a
navegação **nunca eram construídos**. Hoje o teste rola a lista inteira, em
passos de meia janela, checando exceção a cada passo, e no fim afirma que 14
tipos de componente — um de cada região, até a `NavegacaoInferior`, o último —
chegaram a ser construídos. Isso roda na matriz de 4 aparelhos × 3 escalas, e
nos **três temas** só no aparelho mais estreito (320×568) a 200%. Provado: com
um estouro horizontal no fim da lista, o teste antigo passava e o novo reprova
nos 15 casos. A própria galeria apareceu estourando 18 px em 200%, antes de
existir por cinco minutos.

**O portão da FR-032 é `specs/002-design-system/ferramentas/validar_tokens.py`**,
com job próprio no CI. Ele varre `app/lib/` atrás de cor, espaçamento, raio e
tamanho literais. A pasta `tokens/` é a única isenta — é ali que valor literal
deixa de ser literal e vira nome. `Colors.transparent` é o único permitido, e a
razão está escrita ao lado dele: é a **ausência** de cor, e não pode divergir
do sistema porque não tem valor que possa divergir.

⚠️ **Ele achou a erosão já instalada**: sete tamanhos de ícone (18, 20, 22, 24,
28, 56, 72), nenhum declarado, quatro deles para a mesma situação. Espaçamento
estava limpo; de cor, só a sombra do `Cartao`. Os tokens novos estão em
`MemoraDimensoes` (ícone em 4 degraus, borda em 3, indicador, largura de
leitura) e `MemoraElevacao.sombra`.

⚠️ **Quatro pontos mudaram de tamanho**, todos para maior, todos por 2 dp: três
`22→24` (botão, erro de campo, regras de senha) e um `18→20` (catálogo). Era
isso ou inventar um degrau de 22 e um de 18 só para preservar o que ninguém
tinha decidido.

---

## 5. Ambiente — atalhos que economizam tempo

Ferramentas **não estão no PATH** do shell. Exporte antes de usar:

```bash
export PATH="/c/flutter_windows_3.41.6-stable/flutter/bin:/c/Program Files/GitHub CLI:$PATH"
```

Para o Spec Kit (`uv`):
```bash
export PATH="/c/Users/Edu/AppData/Roaming/Python/Python314/Scripts:$PATH"
```

| Item | Valor |
|---|---|
| Flutter | 3.41.6 · Dart 3.11.4 |
| Java | 21 LTS |
| Docker | Desktop 29.6.2 · Compose v5.3.1 — `docker compose up -d` na raiz sobe o PostgreSQL 16 |
| Scripts do Spec Kit | **PowerShell** (`.ps1`) — use a ferramenta PowerShell |
| Identidade git | `Eduardo Juncker <eduardojunckertorasl@gmail.com>` |
| **Shell do usuário** | **Windows PowerShell 5.1** |
| Repositório | `Edudu720/Memora` (privado) |

### A máquina do Henrique é diferente — não presuma a do Eduardo

Desde 2026-07-30 há duas máquinas no projeto, e os caminhos **não coincidem**.
Confira em qual você está antes de copiar comando daqui.

| Item | Eduardo | Henrique |
|---|---|---|
| Raiz do repo | `C:\Users\Edu\Documents\Memora` | `C:\Users\Henriqueee sigma\Documents\ProgramingProjects\Memora` |
| Flutter | 3.41.6 · Dart 3.11.4 | **3.44.8 · Dart 3.12.2**, em `C:\flutter` |
| JDK | 21 | **22** (`JAVA_HOME` já definido) |
| `gh` | no PATH | `C:\Program Files\GitHub CLI\gh.exe` |
| git | `Eduardo Juncker` | `Henrique Sandrini <sandrinihenrique@gmail.com>` |

⚠️ **O caminho do Henrique tem espaço** (`Henriqueee sigma`), e isso quebra
ferramenta de verdade. Já derrubou o `openapi-generator` duas vezes: ele valida a
entrada como URI, onde espaço é ilegal, e depois abre como caminho de arquivo,
onde `file:///...%20...` não existe. **Não há caminho absoluto que agrade os
dois** — a saída foi gerar de dentro da pasta do contrato passando só o nome do
arquivo, e é por isso que o Flutter dele está em `C:\flutter`, fora da home.
Espere o mesmo tipo de falha em outras ferramentas Java e Dart.

⚠️ **Os dois estão em versões diferentes do Flutter.** Rodar `flutter pub get` na
máquina do Henrique reescreve `app/pubspec.lock` com `meta 1.18.0` e
`test_api 0.7.11`, contra `1.17.0` e `0.7.10` do repositório. **Reverter o lock**
em vez de commitar — o contrário força o outro a atualizar o SDK sem ter pedido.
O CI usa `channel: stable` sem pino, então a divergência volta. Vale a equipe
decidir se pina a versão no workflow.

### Fluxo de PRs — empilhadas

Cada seção do `tasks.md` vira uma branch e uma PR, e **cada branch sai da
anterior**, não da `master`. Consequências práticas:

- entram **na ordem**; a de baixo primeiro;
- quando a de baixo é mergeada, a de cima **continua apontando para a branch
  antiga** e precisa ser reapontada (`gh pr edit N --base master`) — senão o
  merge não chega à `master`;
- merge com **commit de merge**, que é o padrão do histórico.

---

## 5.1 Como rodar o aplicativo

O projeto é **apenas Android**. Não há suporte a Windows nem web — `flutter run`
falha com "No supported devices connected" se nenhum emulador estiver de pé.

Emulador configurado: **Pixel_6**.

```powershell
cd C:\Users\Edu\Documents\Memora\app; flutter emulators --launch Pixel_6; Start-Sleep -Seconds 60; flutter run
```

Com o emulador já aberto:

```powershell
cd C:\Users\Edu\Documents\Memora\app; flutter run
```

Com o app rodando: `r` recarrega na hora, `R` reinicia, `q` encerra.

⚠️ **Emulador parado em `offline` com ~950 MB é falta de RAM, não defeito
gráfico.** Na máquina do Henrique isso aconteceu em 2026-09-08: o `adb devices`
mostrava `emulator-5554 offline` indefinidamente e o `qemu-system-x86_64`
estacionava perto de 1 GB sem nunca crescer. **Havia 0,6 GB livres de 16 GB** —
Rocket League com 1,6 GB, mais Docker (`vmmemWSL`), Discord e o backend Java. O
emulador precisa de vários GB e simplesmente não avança sem eles.

O sintoma engana porque é idêntico ao de um problema de renderização, e o
caminho errado custa tempo. **Cheque a memória primeiro** — é uma linha:

```powershell
$os = Get-CimInstance Win32_OperatingSystem; "Livre: {0:N1} GB" -f ($os.FreePhysicalMemory/1MB)
```

Rodar backend, Docker e emulador ao mesmo tempo nesta máquina exige fechar jogo
e o que mais estiver aberto. Não há folga para os três mais um jogo.

### O que existe para ver

A tela inicial é uma **casca de demonstração** (`lib/demonstracao/`), provisória,
com três abas:

| Aba | Conteúdo |
|---|---|
| **Entrar** | Fluxo real das US1 e US2: boas-vindas → cadastro → dentro → sair → login |
| **Componentes** | Vitrine do Design System |
| **Aparência** | Tela real de preferências, com pré-visualização |

A casca sai quando o Hub existir.

**Como ver o estado bloqueado no aparelho**: crie a conta pelo cadastro, saia,
e erre a senha **5 vezes**. A quinta já responde bloqueio, com contagem
regressiva de 1 minuto que libera o botão sozinha.

**Como ver o aviso de inatividade sem esperar meia hora**: em
`casa_demonstracao.dart`, passe prazos curtos ao `FluxoAutenticacao` —
`inatividade: Duration(seconds: 30), avisoDeInatividade: Duration(seconds: 10)`.
São os valores reais por padrão; o parâmetro existe justamente para não precisar
mentir sobre eles no código.

### Backend

Precisa de `JAVA_HOME` explícito, porque o `java` do PATH é um atalho que confunde
o Maven:

```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"; cd C:\Users\Edu\Documents\Memora\backend; .\mvnw test
```

⚠️ **O Docker Desktop precisa estar rodando** — não basta estar instalado. Todo
teste que herda de `TesteComBanco` sobe um PostgreSQL pelo Testcontainers, e com
o daemon parado a falha aparece longe da causa: `NoClassDefFoundError: Could not
initialize class TesteComBanco`, com a razão real (`Could not find a valid Docker
environment`) enterrada no meio do rastro. Subir leva ~40 s:

```powershell
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

### O aplicativo falando com o servidor (2026-09-08)

Até esta data o aplicativo **nunca** havia trocado um byte com o backend: tudo
rodava contra simulado, e a escolha estava dentro de um widget. Hoje ela vem de
`--dart-define`, resolvida uma vez em `services/ambiente/composicao.dart`.

**Os três passos, na ordem:**

```powershell
docker compose up -d
```

```powershell
$env:MEMORA_CHAVE_ORIGEM = "chave-de-desenvolvimento-com-mais-de-32-bytes-para-o-hmac"; cd backend; .\mvnw spring-boot:run
```

```powershell
$env:TEMP="C:\memora-tmp"; $env:TMP="C:\memora-tmp"; cd app; flutter run --dart-define=MEMORA_URL_BASE=http://10.0.2.2:8080/v1 --dart-define=MEMORA_SERVIDOR_REAL=true
```

⚠️ **`10.0.2.2`, nunca `localhost`.** Dentro do emulador, `localhost` é o
**próprio emulador** — o Spring Boot da sua máquina é invisível dali. O erro é
`Connection refused`, que parece servidor fora do ar e manda para o lado errado.
Em aparelho físico nem um nem outro serve: use o IP da máquina na rede.

⚠️ **Sem os dois `--dart-define` o app usa simulado**, e isso é o padrão de
propósito: quem clona e roda `flutter run` vê o aplicativo funcionando em vez de
uma tela de erro de rede.

⚠️ **`spring-boot:run` com `Out-String` no PowerShell não mostra nada.**
`Out-String` acumula até o processo terminar, e um servidor não termina — o log
fica vazio e parece que a subida travou. Redirecione para arquivo:
`Start-Process .\mvnw.cmd -ArgumentList "spring-boot:run" -RedirectStandardOutput C:\memora-tmp\backend.log -NoNewWindow`.

**O código de verificação sai no log do backend**, pelo `EnviadorDeCodigoEmLog`.
É assim que se exercita a recuperação sem provedor de envio:

```powershell
Select-String -Path C:\memora-tmp\backend.log -Pattern "Codigo de verificacao" | Select-Object -Last 1
```

**O que já foi exercitado ponta a ponta contra o servidor real** (não só em
teste): cadastro `201`, login `200`, recuperação `202` idêntica para conta
existente e inexistente — **926 ms contra 887 ms**, indistinguível —, canal não
verificado sem receber nada, código emitido e confirmado, **as duas sessões
antigas mortas com `401` e a nova viva com `200`**, senha antiga recusada e
notificação disparada.

---

## 6. Verificação — rode antes de dizer que terminou

```powershell
cd app; flutter analyze; flutter test
```

```powershell
py specs/002-design-system/ferramentas/validar_paleta.py
```

```powershell
py specs/002-design-system/ferramentas/validar_tokens.py
```

Os quatro precisam passar. O CI (`.github/workflows/verificacao.yml`) roda os mesmos.

⚠️ **Na máquina do Henrique é `py`, não `python`.** Existe Python 3.14 em
`AppData\Local\Programs\Python\Python314`, mas quem está no PATH é o **alias da
Microsoft Store** — ele não executa nada e ainda devolve um texto sugerindo
instalar da loja, com código de saída 49. Parece Python ausente e não é. O
launcher `py` acha a instalação real.

### ⚠️ Sintaxe de comando

O usuário roda **Windows PowerShell 5.1**, que **não aceita `&&`** — é erro de
parser, não apenas incompatibilidade. Ao entregar comandos a ele:

- Use `;` como separador: `cd app; flutter test`
- Para encadear só em caso de sucesso: `cd app; if ($?) { flutter test }`
- `&&`, `||`, ternário e `??` não existem nessa versão

Você (agente) pode usar bash pela ferramenta Bash, mas **o que for colado para o
usuário precisa ser PowerShell**.

### Princípio de verificação adotado aqui

**Teste que passa não prova que o portão funciona.** Nesta sessão, o portão de
contraste foi validado *injetando um valor ruim de propósito* e confirmando que ele
falha. Faça o mesmo ao criar qualquer novo portão.

---

## 7. Decisões já tomadas — não reabra sem motivo novo

| Decisão | Escolha | Onde está justificada |
|---|---|---|
| Backend | **Java + Spring Boot** | [ADR 001](docs/architecture/adr-001-linguagem-do-backend.md) |
| Identificador de login | E-mail **ou** telefone; só um no cadastro | spec 001, D1 |
| Login social | Google **e** Facebook | spec 001, D2 |
| Cadastro assistido | Modo assistido explícito | spec 001, D3 |
| Origem dos tokens | Amostragem das imagens do protótipo | spec 002, D1 |
| Temas | Claro, escuro e alto contraste | spec 002, D2 |
| Idiomas | Fora de escopo; estrutura preparada | spec 002, D3 |

---

## 8. Achados que valem lembrar

- **A paleta do protótipo passa na WCAG.** O azul `#1040F8` mede 6,75:1 com texto
  branco. A identidade visual foi preservada — não a altere sem medir.
- **O padrão do Spring Security é fraco demais.** `Argon2PasswordEncoder` usa 16 MiB
  de memória; a OWASP exige no mínimo 19 MiB. Os parâmetros precisam ser explícitos.
- **Os botões SIM/NÃO não reprovavam em contraste** (14,98:1 e 7,55:1). A primeira
  avaliação estava errada — era impressão visual. O defeito real é a **altura de
  24 px contra 48 dp**. Meça antes de afirmar.
- **`@immutable` vem de `foundation`**, não de `painting`. Custou um erro de
  compilação.
- **`containsSemantics` está obsoleto** no Flutter 3.41. Use `isSemantics`.
- **Não acesse o tema por reflexão.** Use `context.memora` — a extensão já existe
  em `temas/memora_theme_extension.dart`.
- **`Semantics(button: true)` não basta**: sem `onTap` na própria `Semantics`, o
  TalkBack anuncia o botão mas o duplo-toque não ativa nada. Custou um defeito real.
- **Não use `Opacity` para estado desabilitado.** Derruba o contraste do rótulo
  para 2,79:1. Use `superficieAlt` com `textoSuave`, que mede 6,22:1.
- **`pumpAndSettle` trava com o `Carregando` na tela** — ele anima sem parar.
  Verificações de concorrência vão para teste de unidade, não de widget.
- **Localize campo por chave, não por texto.** O rótulo aparece em mais de um
  ponto da árvore. As telas expõem `TelaCadastro.chaveNome` e afins.
- **Argon2: o mínimo da OWASP é fraco neste hardware.** 19 MiB rende 42 ms;
  calibramos para 64 MiB com t=4, que rende ~240 ms. Meça antes de confiar.
- **Não há Maven na máquina.** O backend usa o wrapper (`./mvnw`) e
  precisa de `JAVA_HOME="/c/Program Files/Java/jdk-21"`.
- **Docker 29 rejeita Testcontainers 1.x** (exige API ≥ 1.44; o docker-java
  antigo pede 1.32 e leva 400 com um "info" vazio). Usamos **Testcontainers
  2.0.5, gerenciado pelo Spring Boot 4.1** — sem BOM próprio no pom, e os
  artefatos 2.x têm prefixo novo: `testcontainers-postgresql`,
  `testcontainers-junit-jupiter`.
- **No Spring Boot 4 cada autoconfiguração vive em módulo próprio.** Pôr
  `flyway-core` no pom **não** ativa o Flyway: as migrations são ignoradas em
  silêncio e o sintoma aparece longe da causa, como
  `Schema validation: missing table` vindo do Hibernate. Use
  `spring-boot-starter-flyway`. Mesma família de armadilha do
  `spring-boot-starter-webmvc`. Suspeite disso em qualquer integração nova.
- **`spring.jpa.hibernate.ddl-auto=validate` é portão, não configuração.**
  Com ele, subir o contexto compara cada entidade com o esquema do Flyway;
  divergência derruba a aplicação em vez de gerar coluna fantasma. Verificado
  injetando `nome_de_tratamento` de propósito: reprova com
  `missing column [nome_de_tratamento]`. É o que o `contextLoads` protege.
- **O driver do PostgreSQL não infere tipo SQL para `Instant`** em JDBC cru
  (`JdbcTemplate`) — falha com "Não pode inferir um tipo SQL". Pelo Hibernate
  funciona, porque ele declara o tipo. Em consulta crua use `OffsetDateTime`.
- **Compare instante truncado a microssegundos em teste.** `TIMESTAMPTZ` guarda
  microssegundos e o `Instant` do Java carrega nanossegundos: comparar o valor
  gravado com o original falha de forma intermitente. Use
  `truncatedTo(ChronoUnit.MICROS)`.
- **Para testar regra de tempo pelo endpoint, troque o `Clock` inteiro.** Um
  `@TestConfiguration` com um `Clock` `@Primary` que o teste move na mão
  (`BloqueioProgressivoNoLoginTest.RelogioAjustavel`) faz a escada de bloqueio
  inteira caber em milissegundos, em vez dos 81 minutos que ela leva no relógio
  do sistema. Adiantar o banco na marra não serve: quem compara `bloqueada_ate`
  com o agora é o `LimitadorTentativas`, e é o agora **dele** que precisa andar.
  O `@Import` do `@TestConfiguration` cria um contexto Spring próprio para a
  classe — custo de uma subida a mais, e o container do Postgres continua sendo
  o mesmo.
- **Encoding no Windows tem duas armadilhas opostas**: `.ps1` com acento
  precisa de UTF-8 **com** BOM (senão o PowerShell 5.1 lê como ANSI e quebra o
  parser); `.java` precisa de UTF-8 **sem** BOM (senão o `javac` engasga).
  O `Set-Content -Encoding UTF8` do PS 5.1 grava BOM sempre.
- **O parser do OpenAPI Generator trata `-i` como URI**: caminho Windows com
  `\` falha com "Illegal character in opaque part". Converta para `/` antes.
- **O separador de `-Dtest=` no Surefire é vírgula, não `+`.** Com `+` o build
  falha antes de rodar teste nenhum, sem dizer por quê.
- **`Select-Object -First N` em cima do `mvnw` mata o processo** e devolve código
  de saída não-zero mesmo com BUILD SUCCESS. Para ler saída de build, capture
  com `Out-String` antes de filtrar — senão você persegue um erro que não existe.
- **`@Modifying` em consulta de atualização precisa de
  `clearAutomatically = true`**, senão entidade já carregada na transação fica
  desatualizada depois da atualização em massa e o teste engana.
- **Dentro de `testWidgets` o relógio é falso.** `await repo.cadastrar(...)` num
  repositório que faz `Future.delayed` **nunca completa** se ninguém bombear
  quadros — o arquivo inteiro trava e o relatório diz "did not complete" em
  todos os casos, sem apontar a causa. Semeie estado pela via síncrona
  (`RepositorioAutenticacaoSimulado.registrarConta`) ou use `tester.runAsync`.
- **A checagem de temporizador pendente roda ANTES do `tearDown`.** Descartar o
  controlador em `addTearDown` não salva de "A Timer is still pending": a
  contagem precisa acabar **dentro do corpo do teste**. Custou uma rodada.
- **Montar duas vezes o mesmo tipo de tela reaproveita o `State`.** Sem `key`
  distinta, `initState` não roda na segunda montagem, o controlador novo fica
  preso no estado inicial e o teste falha com "No element" ao procurar um campo
  que nunca chegou a aparecer.
- **Em teste de widget, role antes de tocar.** As telas do Memora são altas por
  causa da tipografia grande; `tester.tap` em elemento fora da dobra não registra.
  Use `ensureVisible` antes.
- **`.specify/feature.json`** aponta a feature ativa e **conflita** quando duas
  branches o alteram. Resolva mantendo a feature em que você está.
- **Jackson 3 mudou de pacote no Spring Boot 4.** `ObjectMapper` agora é
  `tools.jackson.databind.ObjectMapper`; `com.fasterxml.jackson.databind` **não
  existe** no classpath. As *anotações* (`@JsonProperty`) continuam em
  `com.fasterxml.jackson.annotation`, o que torna o erro confuso: metade dos
  imports antigos compila.
- **Bean de `Filter` é registrado duas vezes.** Declarar um `OncePerRequestFilter`
  como `@Bean` faz o Boot instalá-lo também como filtro de servlet, fora da
  cadeia do Spring Security — ele roda em toda requisição, duas vezes. O antídoto
  é um `FilterRegistrationBean` com `setEnabled(false)`, como em
  `ConfiguracaoDeSegurancaWeb`.
- **Contagem de teste: use `clean`.** Somar os XMLs de `target/surefire-reports/`
  sem limpar inclui relatório órfão de classe que não existe mais — foi o que
  fez este arquivo dizer 244, 245 e 251 em vez de 250. Ver o aviso no topo.
- **Teste que passa pode estar procurando a coisa errada.** O teste do "olhinho"
  da FR-060 passava mesmo com `permitirRevelar: true`, porque procurava
  `Icons.visibility_outlined` e o `CampoSenha` usa `Icons.visibility`. Só
  apareceu ao quebrar o portão de propósito. **É por isso que se quebra.**
- **O Hibernate segura a conexão do commit até o fim da transação.** Ela é
  tomada na primeira consulta JDBC e só volta no commit — então qualquer coisa
  cara **entre** as duas prende uma conexão do pool sem tocar no banco. Foi como
  o Argon2 de 240 ms virou limite de disponibilidade em `entrar`. Para tirar
  trabalho pesado de dentro da transação sem depender de proxy do Spring, use
  `TransactionTemplate`: `@Transactional` em método privado **não funciona**,
  porque a chamada não passa pelo proxy.
- **Enum de domínio que mistura dois eixos vira defeito.** `EstadoDaConta`
  guardava ciclo de vida e tranca temporária na mesma coluna, e o bloqueio
  apagava a desativação. Se dois valores de um enum podem valer ao mesmo tempo,
  eles não pertencem ao mesmo enum.
- **`Docker Desktop.exe` precisa estar de pé antes dos testes do backend.**
  Testcontainers falha com "failed to connect to the docker API at npipe". Subir
  o Docker leva ~1 min; `.\mvnw test-compile` roda sem ele e já pega erro de
  compilação, o que economiza a espera quando o problema é sintático.
- **Commite antes de quebrar um portão de propósito.** O jeito natural de
  desfazer a quebra é `git checkout -- <arquivo>`, e ele reverte para o **HEAD**
  — levando junto todo o trabalho não commitado daquele arquivo. Aconteceu nesta
  sessão: a quebra da FR-019 foi desfeita e os dois métodos novos do
  `RepositorioAutenticacaoSimulado` sumiram com ela. Pior, `git checkout --`
  **não funciona em arquivo novo**, então as quebras seguintes não reverteram e
  contaminaram umas às outras. Commite primeiro; aí o revert é confiável para
  todos os arquivos.
- **`Future.delayed(Duration.zero)` ainda agenda um timer.** Dentro de
  `testWidgets` o relógio é falso: um `await` no corpo do teste **nunca
  completa**, e o caso morre em "did not complete" depois de MINUTOS, sem
  apontar a causa. Custou duas rodadas na feature 003. A saída foi o próprio
  simulado não criar timer quando a demora é zero — um arquivo de teste passou
  de 5 minutos travado para 1 segundo. Alternativa pontual: `tester.runAsync`.
- **I/O de arquivo real também não completa dentro de `testWidgets`**, pelo
  mesmo motivo. Disco vai para `test` puro; teste de widget usa dublê em
  memória.
- **Teste que chama `deleteAll()` num banco compartilhado apaga o dado do
  produto.** Três testes da 003 faziam isso e, quando o catálogo real foi
  semeado por migration, eles colidiram na unicidade **e** deixaram o teste
  seguinte com um banco vazio. O container do Postgres é um só para a suíte
  (`TesteComBanco`): cada teste apaga apenas o que criou, e usa dados fictícios
  (`com.teste.*`) que não disputem com o catálogo real.
- **Simulado e banco são mundos separados, e nenhum teste liga os dois.** A
  divergência entre o catálogo do `RepositorioAssistenteSimulado` e o das
  migrations só apareceu ao rodar no emulador. A cada mudança de catálogo, mexa
  nos dois lados.
- **`NoClassDefFoundError: TesteComBanco` significa Docker parado**, e não
  defeito de código. Aconteceu de novo nesta sessão, com 18 erros de uma vez.
- **`FATAL: sorry, too many clients already` significa contexto Spring demais,
  e o sintoma aparece na classe errada.** Toda classe com `@TestConfiguration`
  ou `@TestPropertySource` ganha contexto próprio, e cada um abre um Hikari de
  20 conexões. Cinco contextos são 100 — exatamente o `max_connections` padrão
  do PostgreSQL. Acrescentar o `LimiteDeConversasTest` derrubou **18 testes de
  recuperação de acesso** que ninguém tinha tocado, porque o contexto *deles*
  foi o que não subiu. Hoje o container sobe com `max_connections=200`. Se
  voltar a aparecer, a pergunta é "quantos contextos existem agora?", não "o
  que essa classe quebrou?".
- **Teto de altura em pixel só cabe no aparelho em que foi medido.** Os 420 px
  do aviso antigolpe foram calibrados num 390×844 e estouravam num 360×640 já
  em 100%. `LayoutBuilder` + fração da altura disponível não tem esse problema,
  porque a conta é refeita em cada aparelho. Vale para qualquer
  `BoxConstraints(maxHeight:)` que não seja de um ícone.
- **Testar num aparelho só esconde layout quebrado.** Os quatro arquivos de
  acessibilidade rodavam em 390×844 — o mais folgado. A matriz de
  `aparelhos.dart` custa segundos e pegou dois estouros que ninguém via.
- **Texto solto dentro de `Row` estoura a largura.** Sem `Flexible`, um `Text`
  exige a largura natural dele, e ela cresce com a ampliação — foi assim que o
  rótulo "Mostrar senha" passou 265 px da tela em 200%. O `BotaoBase` já fazia
  certo desde sempre; o `CampoSenha` não. Ao escrever `Row` com texto dentro,
  a pergunta é "e se este texto dobrar de tamanho?".
- **Teste que passa não prova portão nenhum — e isso já falhou aqui.** A guarda
  de conta desativada entrou na #15 anunciada na descrição da PR, sem um único
  teste, e furada. `git grep <a constante que a guarda usa>` em
  `backend/src/test/` custa segundos e teria mostrado.

---

## 9. Coisas que NÃO se faz neste projeto

- ❌ Escrever cor, espaçamento ou tamanho literal fora dos tokens
- ❌ Criar componente dentro de `features/` quando ele serve a mais de uma tela
- ❌ Editar cliente de API gerado à mão
- ❌ Guardar token em `SharedPreferences` — apenas `flutter_secure_storage`.
  (O identificador do último acesso **fica** em `SharedPreferences`, e isso não
  é exceção à regra: ele não é credencial, e o V8 reprova se sobrar qualquer
  coisa no cofre depois de sair)
- ❌ Empurrar correção de revisão para a branch de outra pessoa — vai em PR
  própria, empilhada
- ❌ Entregar guarda de segurança sem um teste que a exercite
- ❌ Implementar sem spec aprovada
- ❌ Afirmar que algo passa sem ter rodado a verificação
- ❌ Supor requisito quando a spec é ambígua — pergunte

---

## 10. Pendências que dependem de pessoas

### Aberto em 2026-08-24, ao implementar a US5

Três coisas apareceram ao cumprir a FR-062. **Nenhuma é requisito novo** — todas
são consequências de fazer o que a spec já pedia, e por isso não passaram por
`/speckit-clarify`. Se a equipe discordar dessa leitura, o lugar de resolver é a
spec, não o código.

| # | O quê | Estado |
|---|---|---|
| 1 | **Não existe envio de e-mail nem SMS.** Nenhuma tarefa da feature 001 implementa envio; o `plan.md` só cita "envio de código, provedores" ao desenhar a pasta `infra/` | **T065a**, aberta |
| 2 | **Conta assistida abandonada trava o e-mail.** Fica `PENDENTE_VERIFICACAO` para sempre com o canal ocupado; recadastrar cai no chamariz da FR-010 e a pessoa fica sem saída | **T065b**, aberta |
| 3 | **`TelaConfirmarCanal` não estava nas tarefas.** Sem ela a conta assistida nasce em espera e não há por onde sair | ✅ feita nesta entrega |

**Sobre o envio, a escolha foi falhar alto.** Existe a porta `EnviadorDeCodigo`
e um único adaptador, `EnviadorDeCodigoEmLog`, que escreve o código **em claro
no log** e é `@Profile("!producao")`. Com o perfil `producao` o bean não existe,
nenhum outro foi escrito, e **a aplicação não sobe**.

Isso **diverge de propósito** do padrão de `ConfiguracaoDeToken` e
`ConfiguracaoDeRastreio`, onde a falta de configuração sorteia um valor e segue
com WARN. Lá o prejuízo é interno e reversível — sessões caem, uma contagem
zera. Aqui, seguir adiante responderia `202` "código enviado" a quem nunca
receberá nada, e a deixaria presa esperando uma mensagem que não vem.

### O que foi corrigido hoje e não deve voltar

- **A contagem de testes do backend.** Este arquivo já disse 244, 245 e 251.
  São **271** agora (250 antes da US5), e o método é `mvnw clean test`. Ver o
  aviso no topo.
- **A tabela de portões tinha um portão decorativo.** O da FR-060 passava com o
  portão quebrado. Corrigido e reprovado com a quebra aplicada, que é a única
  prova que vale.



| Pendência | Com quem | Bloqueia? |
|---|---|---|
| ~~**De onde vem a URL base do servidor**~~ | — | ✅ **Resolvida em 2026-09-08** sem precisar decidir: vem de `--dart-define`, num lugar só (`services/ambiente/composicao.dart`). A spec não precisava escolher *uma* URL, precisava que existisse *um lugar* onde ela é escolhida |
| **Contrato passar a documentar o `500`** (T027a) | Eduardo — decisão de spec | Não, mas o servidor já responde algo que o contrato não prevê |
| **Normalizar as tags acentuadas do `openapi.yaml`** | Eduardo — decisão de spec | Não — nomes mutilados no cliente |
| **Definir `MEMORA_CHAVE_ORIGEM` em produção** (≥ 32 bytes) | Quem for implantar | **Sim, na implantação.** Sem ela a chave é sorteada a cada subida e o limite por origem da R4 zera junto; um WARN avisa |
| **Provedor de envio de e-mail/SMS** (T065a) | Equipe — nunca esteve na spec | **Sim, na implantação.** Com o perfil `producao` a aplicação não sobe sem um `EnviadorDeCodigo`, de propósito |
| **O que fazer com conta assistida abandonada** (T065b) | Equipe | Não hoje — mas quem desiste no meio fica sem conseguir recadastrar com o mesmo e-mail |
| **Escolher o provedor de IA** (R2 da 003) | Equipe | **Sim, para a assistente pensar.** Não bloqueia a construção — só a fase 8. Seis critérios em `specs/003-hub-e-assistente/research.md`; o que mais pesa é retenção de dados |
| **Conta e chave do provedor**, e quem paga | Equipe | **Sim, na implantação** |
| **Teto diário de conversas** — hoje `TETO_PADRAO = 20`, provisório | Equipe | Não, mas o número foi escolhido sem uso real para medir |
| **Bancos e serviços de saúde no catálogo** | Equipe | Não — hoje há Gov.br e Meu INSS entre os sensíveis. Cada acréscimo é uma migration |
| Aceitar convite do repositório | Du3101 | Não — Henrique já aceitou, com acesso de escrita |
| GitHub Student Pack aprovado | Eduardo (enviado) | Não — libera proteção de branch |
| Corrigir contradições do Arquivo X (voz, offline) | Equipe | Não — ver [requisitos-atualizados.md](docs/referencia/requisitos-atualizados.md) |
| **Revisar as PRs de 2026-09-08** — [#24](https://github.com/Edudu720/Memora/pull/24) (backend da US3) e a da integração + US4 | Eduardo | Não, mas a #16 existe porque a revisão da #15 achou duas falhas latentes que ninguém tinha visto |
| **Registrar app no Google e no Facebook** (client IDs, PKCE) | Equipe — ninguém levantou ainda | **Sim, para a fase 8 da 001.** Aprovação no Facebook não é rápida, e é o único pedaço da feature 001 que continua aberto |
| **Confirmar a `TelaConfirmarCanal`** como consequência, não escopo novo | Eduardo | Não — já implementada; sem ela a conta assistida não teria saída |
| Teste com 5 pessoas de 65+ anos | Equipe | **Sim** — portão de saída das features 001 e 002 |

### Onde a fila parou em 2026-09-15

**A fila está vazia de novo** — e ficou, por dias, com uma PR verde parada.

| # | O quê | Situação |
|---|---|---|
| #24, #26 | Backend da US3 e a integração + US4 | ✅ na `master` (2026-09-09) |
| **#27** | **T070 — testes de acessibilidade do Hub e da assistente** | ✅ na `master` (2026-09-15), revisada e aprovada |
| **#28** | Correção da revisão da #27 — teto proporcional e o portão da FR-027 | ✅ na `master` |
| **#29** | Plano de pentest e o `.gitattributes` | ✅ na `master` |
| **#30** | Auditoria da ampliação — o `Flexible` do "Mostrar senha" | ✅ na `master` |
| **#31** | Fase 7 da 002 — galeria, portão dos tokens e guia de uso | 🟢 **Aberta**, base `master` |

⚠️ **A #27 ficou 5 dias aberta com CI verde e sem revisão nenhuma.** Não é
detalhe de processo: a revisão dela achou que o conserto do T070 só valia no
aparelho em que foi medido, e achou um portão decorativo. **O que a fila custa
quando para é isso.** Confira `gh pr list --state open` no começo de cada
sessão — foi assim que esta começou.

### Onde a fila parou em 2026-08-29

**Cinco PRs abertas**, e a ordem importa: cada uma sai da anterior.

| # | O quê | Base | Situação |
|---|---|---|---|
| **#19** | Modo assistido — US5 (T057-T065) | `master` | Aberta, **sem revisão** |
| **#20** | Telas da US3 (T070-T073) | #19 | Aberta |
| **#21** | Visual das telas, vindo do protótipo | #20 | Aberta |
| **#23** | **Feature 003 — fases 1 a 7** | #21 | Aberta |
| **#22** | **Spec, plano e tarefas da 003** | `master` | Aberta, **independente da fila** |

A #22 sai da `master` de propósito: é documentação, e não deve esperar código.

⚠️ **Quando a de baixo entrar, a de cima precisa de `gh pr edit N --base master`**,
senão o merge não chega à `master`. Já quase aconteceu com a #10 e a #16.

### Onde a fila parou em 2026-08-24

**As PRs #1 a #18 estão todas na `master`.** A fila foi fechada nesta data, na
ordem que o empilhamento exigia: #15 → reapontar a #16 → #16 → #17 → #18.

| # | O quê | Situação |
|---|---|---|
| #15 | Backend da US2 (T047-T050) | ✅ na `master` |
| #16 | Correções da revisão da #15 | ✅ na `master`, reapontada antes do merge |
| #17 | Relatório de progresso | ✅ na `master` |
| #18 | Telas da US2 (T051-T056) | ✅ na `master` |
| **#19** | **Modo assistido — US5 (T057-T065)** | 🟢 **Aberta**, CI verde, **sem revisão** |
| **#20** | **Telas da US3 (T070-T073)** | 🟢 **Aberta**, empilhada sobre a #19 |

A branch da US5, `feature/001-fase5-us5`, saiu **da `master`** — a primeira em
várias fases que não nasce empilhada, porque a fila estava vazia quando ela
começou. A da US3, `feature/001-fase6-us3-app`, saiu **dela**, então a fila
voltou a existir: quando a #19 entrar, a #20 precisa de
`gh pr edit 20 --base master` antes do merge.

⚠️ **A regra do empilhamento continua valendo** para quando houver fila de novo:
quando a PR de baixo entra, a de cima precisa ser reapontada com
`gh pr edit N --base master`, senão o merge não chega à `master`. Aconteceu com
a #10 e quase aconteceu com a #16.

⚠️ **Conflito de `CLAUDE.md` ao fechar fila é esperado, e não se resolve
escolhendo um lado.** Ao trazer a `master` de volta para a branch das telas
foram **cinco blocos conflitantes** — as duas linhas de trabalho editaram a
mesma passagem de contexto. Ficar só com um lado teria apagado em silêncio os
avisos que a revisão da #15 acrescentou. Os dois lados costumam ser verdade.

> A proteção da branch `master` **não está ativa** — o GitHub exige plano Pro em
> repositório privado. A regra de não commitar direto vale por acordo da equipe.

### Como se revisa aqui — o padrão que a #12 criou e a #16 repetiu

**Correção de revisão vai em branch e PR próprias, empilhadas sobre a PR
revisada.** Não se empurra para a branch de quem escreveu. O diff da revisão
fica separado do trabalho original, e quem escreveu vê o que mudou em vez de
descobrir depois.

O comentário na PR revisada traz o veredito, a tabela dos achados e o ponteiro
para a PR de correção. Elogio específico entra junto — a #12 e a #16 fizeram
isso, e não é gentileza: dizer **qual** decisão estava certa evita que ela seja
desfeita na próxima passagem.

---

## 11. Como falar com o usuário

- **Em português.**
- Explique o que está fazendo e por quê — ele pediu isso explicitamente.
- **Meça antes de afirmar.** Este projeto tem ferramentas para isso; use-as.
- **Corrija-se em voz alta** quando errar. Já aconteceu nesta sessão e foi útil.
- Ao recomendar algo, diga também **o que o faria mudar de ideia**.
- Não trate o SDD como burocracia: cada etapa evitou retrabalho concreto aqui.
