# Contexto do Projeto Memora

> Leia este arquivo inteiro antes de qualquer ação. Ele existe para que uma nova
> sessão consiga continuar o trabalho sem repetir decisões já tomadas nem refazer
> análises já feitas.

**Última sessão**: 2026-08-20 — telas da US2 (T051-T056)
**Estado**: fases 2 e 3 completas, **backend da US2** completo (**244 testes**)
e as **telas da US2** completas (**204 testes** no aplicativo). Existem
`POST /v1/auth/cadastro`, `POST /v1/auth/entrar` e
`POST /v1/auth/sessao/renovar`. O aplicativo tem cadastro **e login**, com
renovação automática de sessão, bloqueio progressivo com contagem regressiva e
expiração por inatividade.
**Próximo: T057-T065** — a US5, o modo assistido. Ver seção 4.

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
| **001 — Autenticação Acessível** | ✅ | ✅ | ✅ | 🟡 US1 e US2 completas; US5, US3 e US4 pendentes |
| **002 — Design System** | ✅ | ✅ | ✅ | 🟡 T001-T044 feitas |

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

### Dez portões de segurança, cada um validado quebrando de propósito

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

**Faça o mesmo com qualquer portão novo.** Foi assim que descobrimos que os
três realmente pegam.

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

### Próxima tarefa: **T057-T065** — a US5, o modo assistido

`specs/001-autenticacao-acessivel/tasks.md`, fase 5. Protege a autonomia de quem
está sendo ajudada por um familiar: o acompanhante preenche, mas **nunca** vê a
senha nem controla a recuperação. A T058 traz a confirmação de posse do canal,
que é o que a T047 precisou adiar.

Continua em aberto a **fase 7 da feature 002** (T045-T048): galeria de componentes
e análise estática contra valores literais. Protege o sistema a longo prazo, mas
não entrega produto.

**A feature 001 é desbloqueada ao final da fase 6** (T044).

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

---

## 6. Verificação — rode antes de dizer que terminou

```powershell
cd app; flutter analyze; flutter test
```

```powershell
python specs/002-design-system/ferramentas/validar_paleta.py
```

Os três precisam passar. O CI (`.github/workflows/verificacao.yml`) roda os mesmos.

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

---

## 9. Coisas que NÃO se faz neste projeto

- ❌ Escrever cor, espaçamento ou tamanho literal fora dos tokens
- ❌ Criar componente dentro de `features/` quando ele serve a mais de uma tela
- ❌ Editar cliente de API gerado à mão
- ❌ Guardar token em `SharedPreferences` — apenas `flutter_secure_storage`.
  (O identificador do último acesso **fica** em `SharedPreferences`, e isso não
  é exceção à regra: ele não é credencial, e o V8 reprova se sobrar qualquer
  coisa no cofre depois de sair)
- ❌ Implementar sem spec aprovada
- ❌ Afirmar que algo passa sem ter rodado a verificação
- ❌ Supor requisito quando a spec é ambígua — pergunte

---

## 10. Pendências que dependem de pessoas

| Pendência | Com quem | Bloqueia? |
|---|---|---|
| **De onde vem a URL base do servidor** | Eduardo — não está na spec | **Sim, para o app falar com o backend.** Ver o aviso no topo deste arquivo |
| **Contrato passar a documentar o `500`** (T027a) | Eduardo — decisão de spec | Não, mas o servidor já responde algo que o contrato não prevê |
| **Normalizar as tags acentuadas do `openapi.yaml`** | Eduardo — decisão de spec | Não — nomes mutilados no cliente |
| **Definir `MEMORA_CHAVE_ORIGEM` em produção** (≥ 32 bytes) | Quem for implantar | **Sim, na implantação.** Sem ela a chave é sorteada a cada subida e o limite por origem da R4 zera junto; um WARN avisa |
| Aceitar convite do repositório | Du3101 | Não — Henrique já aceitou, com acesso de escrita |
| GitHub Student Pack aprovado | Eduardo (enviado) | Não — libera proteção de branch |
| Corrigir contradições do Arquivo X (voz, offline) | Equipe | Não — ver [requisitos-atualizados.md](docs/referencia/requisitos-atualizados.md) |
| Teste com 5 pessoas de 65+ anos | Equipe | **Sim** — portão de saída das features 001 e 002 |

### Onde a fila parou em 2026-08-20

**Nenhuma PR aberta.** As PRs #8 a #14 entraram todas na `master`: fase 1, banco,
núcleo de segurança, contrato/erros/auditoria/cliente gerado, correções da
revisão, backend da US1 e o lado do aplicativo da fase 2.

Duas coisas ainda **não estão na `master`**, e a fila empilhada voltou:

1. `feature/001-fase4-us2-backend` — o **backend da US2** (T047-T050), commits
   `657ef5c` e `e9651d7`. Entra primeiro.
2. Em cima dela, as **telas da US2** (T051-T056). Quando a de baixo for
   mergeada, esta precisa ser reapontada com `gh pr edit N --base master` —
   senão o merge não chega à `master`.

> A proteção da branch `master` **não está ativa** — o GitHub exige plano Pro em
> repositório privado. A regra de não commitar direto vale por acordo da equipe.

---

## 11. Como falar com o usuário

- **Em português.**
- Explique o que está fazendo e por quê — ele pediu isso explicitamente.
- **Meça antes de afirmar.** Este projeto tem ferramentas para isso; use-as.
- **Corrija-se em voz alta** quando errar. Já aconteceu nesta sessão e foi útil.
- Ao recomendar algo, diga também **o que o faria mudar de ideia**.
- Não trate o SDD como burocracia: cada etapa evitou retrabalho concreto aqui.
