# Memora — Relatório de Progresso

**Data**: 2026-08-24
**Equipe NewXz** — Eduardo Juncker Toras, Eduardo Moraes Trevisan e
Henrique Moreira Sandrini (Scrum Master)
**Projeto Integrador — FATEC Americana**
**Repositório**: `Edudu720/Memora` (privado)

> Este relatório é uma passagem completa pelo estado do projeto: o que existe,
> o que foi medido, o que foi decidido, o que ficou em aberto e o que vem a
> seguir. Os números da seção 8 foram **medidos nesta data**, não estimados.

---

## 1. Sumário executivo

O Memora é um aplicativo Android que **ensina pessoas idosas a usar o
smartphone** — não faz por elas. A primeira feature entregável é a
**Autenticação Acessível**, sustentada por um **Design System** próprio.

| Indicador | Valor |
|---|---|
| Features especificadas | 2 (001 Autenticação Acessível, 002 Design System) |
| Requisitos funcionais escritos | 64 (feature 001) + 38 (feature 002) |
| Tarefas concluídas | **65 de 91** na feature 001 · **44 de 53** na feature 002 |
| Histórias de usuário entregues | **US1** (criar conta), **US2** (voltar ao app) e **US5** (modo assistido) |
| Endpoints implementados | 5 — sendo os 2 primeiros **autenticados** |
| Testes automatizados | **219** no aplicativo + **271** no backend |
| Linhas de código (sem o gerado) | ~12,1 mil de produção · ~8,8 mil de teste |

**Em uma frase**: as três jornadas de entrada — criar conta, voltar depois e ser
ajudada por um familiar sem entregar a senha — estão completas de ponta a ponta,
com backend, telas, acessibilidade e uma bateria de portões de segurança que
foram validados quebrando-os de propósito.

> **Duas tarefas novas apareceram** entre este relatório e o anterior (89 → 91):
> a T065a e a T065b, criadas ao implementar a US5. Ver a seção 10.

---

## 2. O que é o Memora

Aplicativo Android voltado à **autonomia digital de pessoas idosas**. A
diferença em relação a um assistente comum é deliberada: o Memora **mostra o
caminho** para que da próxima vez a pessoa consiga sozinha.

A pergunta que valida qualquer decisão do projeto é *"um idoso conseguiria usar
isso sozinho?"*.

### As sete regras inegociáveis

Estão na constituição do projeto (`.specify/memory/constitution.md`) e valem
sobre qualquer prazo:

1. **Segurança acima de tudo** — vence prazo, performance e conveniência
2. **Proteção contra engenharia social** — toda tela responde *"como um
   golpista exploraria isto?"*
3. **Acessibilidade é requisito** — WCAG 2.2 AA, toque de 48 dp, texto a 200%
4. **Especificação antes de código**
5. **Arquitetura limpa, Feature-First**
6. **A IA nunca age sozinha** — ação crítica exige confirmação e gera log
7. **Ensinar, não substituir**

---

## 3. Como o trabalho é conduzido

O projeto usa **Spec Driven Development** (Spec Kit), com o ciclo:

```
constitution → specify → clarify → plan → checklist → tasks → analyze → implement
```

Cada fase tem portão próprio e vira **uma PR separada**. As regras que a equipe
segue: na spec não se fala de tecnologia; no plano não se escreve código; na
implementação não se inventa requisito; ambiguidade vira pergunta, nunca
suposição.

**O método já evitou retrabalho concreto** — por exemplo, a divergência da
T047 (canal "verificado" contra "cadastrado") foi detectada, discutida e
corrigida na spec, no `data-model.md` e no `openapi.yaml` **junto** com o
código, em vez de virar defeito silencioso.

### Artefatos de especificação produzidos

Para cada feature existem seis documentos: `spec.md`, `plan.md`, `research.md`,
`data-model.md`, `quickstart.md` e `tasks.md`, mais um checklist de requisitos.
São **12 documentos de especificação** e **2 checklists** no repositório.

---

## 4. Estado por feature

### Feature 001 — Autenticação Acessível

| Fase | Escopo | Estado |
|---|---|---|
| 1 — Setup | Projeto Spring Boot, Docker, CI, geração do cliente Dart | ✅ Completa |
| 2 — Fundação | Banco, entidades, núcleo de segurança, contrato de erro, auditoria | ✅ Completa (menos a T027a, dívida de spec) |
| 3 — US1 | Criar conta e começar a usar | ✅ Completa (backend + telas) |
| 4 — US2 | Voltar ao aplicativo depois | ✅ Completa (backend + telas) |
| 5 — US5 | Modo assistido (familiar ajuda sem ver a senha) | ✅ Completa (backend + telas) |
| 6 — US3 | Recuperar o acesso | ⬜ Pendente — T066-T073 |
| 7 — US4 | Sair da conta com segurança | ⬜ Pendente — T074-T078 |
| 8 — Login social | Google e Facebook | ⬜ Pendente — T079-T083 |
| 9 — Validação final | V1-V10 do quickstart, revisões obrigatórias | ⬜ Pendente — T084-T088 |

**56 tarefas concluídas de 89.**

### Feature 002 — Design System

| Escopo | Estado |
|---|---|
| Tokens, temas e portão de contraste | ✅ |
| Componentes de informação, ação e texto | ✅ |
| Campos, confirmação, cartões, diálogos, navegação, feedback | ✅ |
| Preferências de aparência com pré-visualização | ✅ |
| Fase 7 — galeria de componentes e análise estática contra literais | ⬜ T045-T048 |
| Validação final — V1-V10, teste com 5 pessoas de 65+ | ⬜ T049-T053 |

**44 tarefas concluídas de 53.**

---

## 5. O que existe em código — backend

`backend/src/main/java/br/fatec/memora/` — **45 arquivos, ~4,5 mil linhas**.

### Domínio

Cinco entidades (`PessoaUsuaria`, `CanalContato`, `Sessao`, `CodigoVerificacao`,
`EventoAutenticacao`) e cinco enums. Canais, sessões e códigos referenciam a
pessoa **por UUID, sem associação JPA** — nada navega de sessão para pessoa,
porque associação preguiçosa com `open-in-view=false` estoura fora de transação.

O Flyway é o dono do esquema; o Hibernate **nunca** cria nem altera tabela.
`spring.jpa.hibernate.ddl-auto=validate` é portão, não configuração: divergência
entre entidade e migration derruba a subida da aplicação.

### Segurança — o núcleo da feature

| Componente | O que garante |
|---|---|
| `ConfiguracaoDeSenha` | Argon2id a 64 MiB, t=4 (~240 ms medidos) |
| `GeradorDeSegredoOpaco` | Refresh token de 256 bits, com SHA-256 |
| `EmissorDeTokenDeAcesso` | JWT HS256 de 15 min; sem segredo configurado, chave sorteada na subida com WARN |
| `ServicoDeSessao` | Abre e rotaciona sessão, com **detecção de reuso** |
| `VerificadorCredenciais` | Roda o hash **mesmo sem conta**, contra hash fictício |
| `LimitadorTentativas` + `BloqueioProgressivo` | As duas camadas de contenção: por conta e por origem |

O refresh usa SHA-256 e não Argon2 de propósito: hash lento existe para proteger
segredo de baixa entropia; um valor aleatório de 256 bits não ganha nada com
isso, e pagaria 240 ms a cada abertura do aplicativo.

### Contrato, erros e auditoria

`comum/` reúne o que atravessa a aplicação: `CodigoDeErro`, `Erro`,
`FalhaDoMemora`, `TratadorGlobalDeErros`, `FiltroRastreio`,
`ContextoDaRequisicao` e `RegistroDeAuditoria`.

A regra que sustenta a FR-041: **texto de exceção que não seja nossa nunca vai
para a resposta**. Uma `DataIntegrityViolationException` traz o nome da
constraint na mensagem; repassá-la revelaria que aquele canal já pertence a
alguém, derrubando a FR-010 por caminho lateral.

**A trilha de auditoria não se reescreve**: `EventoAutenticacao` é `@Immutable`
e um gatilho no banco (`tg_evento_somente_insercao`) recusa `UPDATE` **inclusive
por SQL avulso**. `DELETE` continua permitido de propósito, porque a retenção de
12 meses exige expurgo.

**A origem de rede é HMAC, não resumo simples.** O espaço IPv4 inteiro são 4
bilhões de valores, revertidos por força bruta a partir de uma cópia do banco;
SHA-256 puro não protegeria nada. A chave vem de `MEMORA_CHAVE_ORIGEM` e não
tem padrão no repositório — um padrão commitado seria conhecido, e a proteção
*é* a chave.

**A auditoria tem dois modos de gravação, e trocá-los quebra coisa.** Evento de
**recusa** vai em transação própria, senão o rollback da operação apaga o
registro da tentativa. Evento de **sucesso** não pode fazer isso: o evento de
cadastro aponta para conta criada na transação em curso e ainda não confirmada,
e a chave estrangeira quebraria. Há teste para os dois lados.

### Os cinco endpoints que existem hoje

| Endpoint | Autenticado | Devolve | Recusa com |
|---|---|---|---|
| `POST /v1/auth/cadastro` | não | `201` + sessão | `400`, `429` |
| `POST /v1/auth/entrar` | não | `200` + sessão | `401` genérico, `429` com espera |
| `POST /v1/auth/sessao/renovar` | não | `200` + sessão | `401` genérico |
| `POST /v1/canais/{id}/codigo` | **sim** | `202` sempre | `401` |
| `POST /v1/canais/{id}/verificar` | **sim** | `200` + canal | `400` genérico, `401` |

Os três primeiros são públicos porque **produzem** credencial: exigir uma seria
exigir o que a operação existe para devolver. Os dois últimos são os **primeiros
caminhos autenticados do projeto**, e trouxeram consigo uma peça que até então
não existia — ver "O filtro que desarma o chamariz", adiante.

**`/canais/{id}/codigo` responde `202` sempre**, exista o canal ou não e
pertença ele a quem for. O contrato diz "código enviado, *se o canal for
elegível*" justamente para permitir isso: responder `404` para canal alheio
transformaria o endpoint num mapa de quais identificadores existem.

### O filtro que desarma o chamariz

`seguranca/FiltroDeTokenDeAcesso` traduz o token do cabeçalho em identidade — e
**consulta o banco** em vez de parar na assinatura do JWT.

Isso não é zelo excessivo. O cadastro responde `201` idêntica quando o canal já
pertence a alguém (FR-010), e para isso devolve uma **sessão-chamariz**: um JWT
que nós mesmos assinamos, para um sujeito que não existe. Um filtro que
confiasse na assinatura transformaria o chamariz em acesso — bastaria tentar
cadastrar com o e-mail de outra pessoa para receber um token que abriria estes
endpoints. Foi testado quebrando: com o filtro confiando só na assinatura, o
chamariz abriu o endpoint com `202` no lugar de `401`.

### O estado que resolveu uma circularidade da spec

A FR-062 exige canal com posse confirmada **antes de concluir** o cadastro
assistido, e o cenário V4 é literal: *"o cadastro assistido não conclui sem
posse confirmada"*.

Só que o canal **passa a existir dentro do cadastro**, e confirmá-lo exige um
token que só é emitido no fim dele. Como está escrito, o requisito é
impossível de cumprir.

A saída foi um estado intermediário — `PENDENTE_VERIFICACAO`, na migration V3.
A conta nasce em espera, recebe sessão que serve para confirmar o canal e nada
mais, e só vira `ATIVA` quando a posse é confirmada. Entrar é recusado enquanto
isso, com a **mesma** recusa genérica de senha errada.

⚠️ **`estado` agora guarda duas naturezas diferentes.**
`PENDENTE_VERIFICACAO` e `DESATIVADA` são **ciclo de vida**; `ATIVA` e
`BLOQUEADA_TEMPORARIAMENTE` são a **tranca temporária**, cuja verdade real mora
em `bloqueada_ate`. Tranca nunca sobrescreve ciclo de vida — sem essa regra,
cinco senhas erradas tirariam a conta assistida da espera e, passado um minuto,
ela entraria sem ninguém ter confirmado canal nenhum.

**Os serviços devolvem resultado; quem lança exceção é o controlador.** Não é
estilo: a recusa da entrada precisa **persistir** o contador de falhas, e lançar
exceção de dentro do serviço desfaria a transação e levaria o contador junto —
o limitador contaria até um para sempre e a FR-014 viraria enfeite.

**O login aceita qualquer canal cadastrado, verificado ou não.** Quem autentica
é a senha; o canal só localiza a conta. Exigir verificação deixaria toda conta
nova sem conseguir entrar, já que a confirmação de posse só chega na US5.

---

## 6. O que existe em código — aplicativo

`app/lib/` — **54 arquivos, ~5,7 mil linhas**, mais 55 arquivos no cliente
gerado do contrato, em `app/pacotes/memora_api/`.

### Design System

- **7 arquivos de tokens** — cores (3 temas), tipografia, espaçamento, raio,
  elevação, movimento, dimensões
- **`ThemeExtension` tipada** — um token inexistente **não compila**
- **20 componentes** em 10 famílias: botões (4 sobre um `BotaoBase`), campos
  (3), informação (3), feedback (3), navegação (2), diálogos (2), cartões,
  confirmação, seleção e texto
- **Preferências de aparência** com pré-visualização ao vivo

Duas regras de linguagem visual valem em todo o aplicativo:

- **Todo `Text` usa `escalaTextoLimitada(context)`** — sem isso o componente
  diverge dos demais em ampliação extrema e o layout quebra de forma
  imprevisível
- **Ação usa pílula e preenchimento; informação nunca usa nenhum dos dois** —
  é o que separa dado de ação para quem não tem repertório de interface

### Autenticação

`app/lib/features/autenticacao/` — domínio, dados e apresentação separados:

- **domain/** — contrato do repositório, entidades e `monitor_de_sessao.dart`
- **data/** — repositório sobre o cliente gerado, repositório simulado para
  demonstração e `ultimo_acesso_local.dart`
- **presentation/** — `fluxo_autenticacao.dart` liga boas-vindas → cadastro →
  login → dentro, com o monitor de sessão ativo **só enquanto a pessoa está
  dentro**
- **telas/** — `TelaBoasVindas`, `TelaCadastro`, `TelaLogin`,
  `TelaEntregaDoAparelho`, `TelaConfirmarCanal` e `TelaPrimeiraEntrada`
- **controladores/** — `ControladorCadastro`, `ControladorLogin`

O fluxo assistido acrescenta três etapas entre o cadastro e o login:
**entrega do aparelho** → senha (sem olhinho) → **confirmação do canal** →
**primeira entrada sozinha**.

⚠️ **No modo assistido o campo de senha não existe na árvore de widgets** até o
aparelho voltar para a pessoa dona da conta. Um aviso no lugar disso seria lido
depois de a senha já ter sido digitada — tarde demais, com o acompanhante já
tendo visto o que a FR-060 protege.

Os textos vivem em `app/lib/l10n/textos_autenticacao.dart`, na voz da Memora.
Não é `flutter_localizations` — é a "estrutura preparada" que a decisão D3 da
feature 002 pediu: quando houver um segundo idioma, estas constantes viram
`.arb` sem ninguém caçar frase dentro de widget.

### O que dá para ver rodando hoje

A tela inicial é uma **casca de demonstração** provisória, com três abas:
**Entrar** (fluxo real das US1, US2 e US5: boas-vindas → cadastro → dentro →
sair → login, e o caminho assistido inteiro), **Componentes** (vitrine do Design
System) e **Aparência** (tela real de preferências). A casca sai quando o Hub
existir.

**Para ver o modo assistido no aparelho**: no cadastro, toque em *"Tem alguém te
ajudando agora?"*. O código de confirmação no simulado é **fixo, `123456`** — não
há como ler um SMS numa demonstração. O servidor real sorteia.

⚠️ O fluxo roda hoje sobre o **repositório simulado**, não sobre o backend — a
troca é de uma linha, mas depende de decidir de onde vem a URL base do servidor
(ver seção 10).

---

## 7. Segurança — os portões e como foram provados

O princípio de verificação adotado aqui: **teste que passa não prova que o
portão funciona**. Cada portão foi validado **quebrando-o de propósito** e
confirmando que reprova.

| Portão | Como foi provado |
|---|---|
| Entidade bate com a migration | Renomeei uma coluna: reprovou com `missing column` |
| Tempo não revela conta existente | Pus o atalho `return false`: reprovou com **0 ms** contra os ~240 ms esperados |
| Reuso de token derruba a família | Revoguei só o token reusado: reprovou com "B continuou funcionando" |
| Falha do framework não vira 500 | Desliguei a checagem: reprovou com `expected:<404> but was:<500>` |
| Chave de origem fraca não sobe | Removi a checagem de tamanho: reprovou nas três chaves curtas |
| Latência não revela conta existente | Movi o hash para depois da consulta: reprovou com **11 ms contra 261 ms** |
| Piso da senha bate com o da tela | Subi o piso do servidor para 12: o teste que lê o controlador reprovou |
| Credencial não vai para armazenamento comum | Gravei o token em `SharedPreferences`: reprovou com `Expected: empty` |
| Latência do login não revela conta | Pus a saída antecipada antes do hash: reprovou com **18 ms contra 282 ms** |
| Bloqueio correto com texto ríspido reprova | Troquei a mensagem por uma ríspida: a escada continuou passando e **só os 3 testes de texto reprovaram** |
| O mesmo, agora na tela | Idem no `tela_login_test.dart`: contagem regressiva e liberação continuaram passando; só o texto reprovou |
| Identificador só é gravado após sucesso | Movi `lembrar()` para antes da resposta: reprovou com `Expected: null` |
| Bloqueio não ressuscita conta desativada | Tirei a guarda: a sexta tentativa devolveu **200** |
| Renovação recusa conta desativada | Desliguei a checagem: `expected:<401> but was:<200>` |
| Chamariz não vira acesso | Fiz o filtro confiar só na assinatura do JWT: `Status expected:<401> but was:<202>` |
| Cadastro assistido não conclui sozinho | Fiz a conta assistida nascer `ATIVA`: **5 testes** reprovaram, um com `expected:<401> but was:<200>` |
| Canal alheio não se verifica | Tirei o filtro por dono: `Status expected:<400> but was:<200>` |
| Bloqueio não conclui cadastro assistido | Devolvi a tranca ao comportamento antigo: `expected: PENDENTE_VERIFICACAO` |
| A senha para o acompanhante (FR-059) | Liberei o campo sem a entrega: **4 testes**, um com `Expected: null / Actual: Instance of 'DadosDeCadastro'` |
| A primeira entrada é sozinha (FR-063) | Fiz a confirmação levar direto para dentro: `Found 0 widgets with type "TelaPrimeiraEntrada"` |

São **vinte portões**, cada um provado por quebra.

### Um portão que reprovou a si mesmo

Vale registrar em separado, porque é a melhor justificativa do método.

O portão da FR-060 — *no modo assistido a senha não pode ser revelada* —
**passava mesmo com o portão quebrado**. Ao ligar `permitirRevelar: true` de
propósito, o teste continuou verde. A causa: ele procurava
`Icons.visibility_outlined`, e o `CampoSenha` usa `Icons.visibility`. O teste
nunca encontrava nada, e "não encontrou nada" era exatamente o que ele esperava.

Corrigido o ícone, o teste passou a reprovar com `Expected: no matching
candidates / Actual: Found 1 widget with icon` — com a quebra ainda aplicada, o
que prova que agora ele pega.

**Um teste que passa não prova nada. Um teste que reprova quando deveria, sim.**

### A sessão-chamariz — a decisão de segurança mais delicada do projeto

`POST /v1/auth/cadastro` responde `201` **idêntica** quando o canal já pertence
a alguém, porque a FR-010 proíbe revelar a existência da conta e o cenário V2
reprova "qualquer diferença observável em corpo, código de status ou tempo".
Como a resposta carrega uma sessão, não há como cumprir isso sem devolver uma.

O que volta nesse caso é um **JWT assinado de verdade para um UUID que não
existe**, com refresh não gravado e nada criado no banco. Devolver a sessão da
conta real entregaria a conta a quem soubesse o e-mail; devolver texto aleatório
seria detectável, porque o token real é um JWT de três segmentos.

> ⚠️ **A consequência atravessa a aplicação inteira**: existe token com
> assinatura válida cujo sujeito não corresponde a conta nenhuma. **Todo caminho
> autenticado precisa resolver o sujeito e recusar quando não encontrar.
> Assinatura válida não é autorização.** Quem esquecer disso transforma o
> chamariz em acesso.

A senha é hasheada **nos dois caminhos, antes da consulta ao canal**. Sem isso o
cadastro contra canal existente responderia em ~11 ms contra ~261 ms, e a
latência entregaria o que o corpo escondeu — medido, não suposto.

---

## 8. Verificação — números medidos em 2026-08-24

Todos os comandos abaixo foram executados nesta data, na branch
`feature/001-fase5-us5`, e reproduzidos pelo CI na PR #19.

| Verificação | Comando | Resultado |
|---|---|---|
| Análise estática do aplicativo | `flutter analyze` | ✅ **No issues found** |
| Testes do aplicativo | `flutter test` | ✅ **219 testes — All tests passed!** |
| Contraste da paleta | `python validar_paleta.py` | ✅ **Todos os pares aprovados**, WCAG 2.2 |
| Testes do backend | `./mvnw clean test` | ✅ **271 testes, 0 falhas, 0 erros** |

O backend sobe um PostgreSQL real por Testcontainers — o Docker Desktop precisa
estar rodando, senão a falha aparece longe da causa.

O CI (`.github/workflows/verificacao.yml`) roda quatro jobs em toda push e PR:
contraste da paleta, build e testes do backend, análise e testes do aplicativo,
e o cliente gerado do contrato.

### Distribuição dos testes

| Suíte | Quantidade |
|---|---|
| Design System | 139 |
| Autenticação (aplicativo) | 80 |
| **Total aplicativo** | **219** |
| **Backend** | **271** |
| **Total do projeto** | **490** |

> **Correção de registro — e a correção da correção.** A primeira versão deste
> relatório dizia 245, corrigindo os 244 do `CLAUDE.md`. Ambos estavam errados,
> e pelo mesmo motivo: a contagem vinha de somar os XMLs de
> `target/surefire-reports/` **sem `clean`**, e havia ali um
> `TEST-...SondaCaminhoDesconhecidoTest.xml` de 10/08/2026 — uma classe de sonda
> que nunca foi commitada e não existe em `backend/src` nem em commit algum.
> Valendo 1 teste, ela inflava toda contagem seguinte, porque `target/` está no
> `.gitignore` e ninguém limpava. Numa execução com `clean`, o `Tests run:` do
> Maven e a soma dos 26 XMLs concordam — eram **250** naquele momento, e são
> **271** com a US5. A lição que fica não é o número: é que **contagem de teste
> se faz com `clean`**, e que um relatório órfão em `target/` sobrevive a
> qualquer quantidade de convicção.

---

## 9. Decisões tomadas — não reabrir sem motivo novo

| Decisão | Escolha | Onde está justificada |
|---|---|---|
| Backend | Java + Spring Boot | ADR 001 |
| Identificador de login | E-mail **ou** telefone; só um no cadastro | spec 001, D1 |
| Login social | Google **e** Facebook | spec 001, D2 |
| Cadastro assistido | Modo assistido explícito | spec 001, D3 |
| Origem dos tokens visuais | Amostragem das imagens do protótipo | spec 002, D1 |
| Temas | Claro, escuro e alto contraste | spec 002, D2 |
| Idiomas | Fora de escopo; estrutura preparada | spec 002, D3 |
| Onde mora o identificador do último acesso | `shared_preferences` | Não é credencial, e o propósito da FR-012 é exibi-lo na tela |
| Prazo de inatividade | 30 min, com aviso 2 min antes | A ameaça que a FR-017 mitiga é **celular esquecido na mesa** |

### Duas divergências conscientes da pesquisa

**A pesquisa sugeria Bucket4j; não usamos.** As duas camadas de contenção
guardam estado no banco — a camada por conta em `pessoa_usuaria`, a camada por
origem contando `evento_autenticacao`, que a FR-039 obriga a escrever de
qualquer forma. Bucket4j traria dependência e tabela própria para reimplementar
contagem que já existe. A troca fica isolada em `LimitadorTentativas`.

**Brecha conhecida e aceita por ora**: só conta que existe pode ser bloqueada,
então um `429` depois de 5 tentativas revela que aquele identificador tem conta
— o oposto do que a proteção contra enumeração busca. A camada por origem
atenua. Fechar de vez exigiria contar falhas por identificador, inclusive
inexistente, e a trilha deliberadamente não guarda identificador (FR-040).
**Decisão da equipe.**

---

## 10. Dívidas e pendências abertas

### Aberto hoje, ao implementar a US5 (2026-08-24)

Três coisas que **não estavam previstas em tarefa nenhuma** e apareceram ao
cumprir a FR-062. Nenhuma é requisito novo — todas são consequências de fazer o
que a spec já pedia.

| # | O que é | Por que importa | Estado |
|---|---|---|---|
| 1 | **Não existe envio de e-mail nem SMS** | A US5 depende de a pessoa **receber** um código. Nenhuma tarefa da feature 001 implementa envio; o `plan.md` cita "envio de código, provedores" ao desenhar a pasta `infra/`, e nada mais | **T065a** |
| 2 | **Conta assistida abandonada trava o e-mail** | Quem desiste no meio fica `PENDENTE_VERIFICACAO` para sempre, com o canal ocupado. Recadastrar com o mesmo e-mail cai no chamariz da FR-010, e a pessoa fica **sem saída** | **T065b** |
| 3 | **`TelaConfirmarCanal` não estava nas tarefas** | Já **resolvido** nesta entrega. Sem ela, a conta assistida nasceria em espera e não haveria por onde sair dela | Feito |

**Sobre o envio (1), a escolha foi falhar alto.** Existe a porta
`EnviadorDeCodigo` e um único adaptador, `EnviadorDeCodigoEmLog`, que escreve o
código **em claro no log** e é `@Profile("!producao")`. Com o perfil `producao`
ativo o bean não existe, nenhum outro foi escrito, e **a aplicação não sobe**.

Isso diverge do padrão usado em `ConfiguracaoDeToken` e `ConfiguracaoDeRastreio`,
onde a falta de configuração sorteia um valor e segue com um WARN. Lá o prejuízo
é interno e reversível — sessões caem, uma contagem zera. Aqui, seguir adiante
significaria responder `202` *"código enviado"* a uma pessoa que nunca receberá
código nenhum, e deixá-la presa numa tela esperando uma mensagem que não vem.

**Uma ressalva de segurança que precisa estar escrita**, e que não é dívida e
sim limite do desenho: **confirmar posse não prova de quem é o canal.** Prova
que quem digitou o código *alcança* aquele contato — e no cadastro assistido o
acompanhante está ao lado, com o próprio telefone na mão. Quem de fato mitiga a
FR-062 é a **entrega do aparelho** (FR-059) e a **primeira entrada sozinha**
(FR-063). Está registrado no javadoc do `ServicoDeVerificacaoDeCanal`, para
ninguém confiar no portão errado.

### Corrigido hoje: um erro de registro que se propagava

O `CLAUDE.md` já afirmou **244**, **245** e **251** testes de backend em
momentos diferentes, e o próprio relatório anterior "corrigiu" 244 para 245 —
errado também.

A causa era um `TEST-...SondaCaminhoDesconhecidoTest.xml` de **10/08/2026**
parado em `target/surefire-reports/`, de uma classe de sonda que nunca foi
commitada e não existe em `backend/src` nem em commit algum de branch alguma.
Valia 1 teste e era somado em toda contagem feita sem `clean`, porque `target/`
está no `.gitignore` e ninguém limpava.

**A correção não é o número, é o método**: contagem se faz com `clean test`, e o
que vale é o `Tests run:` do Maven.

### Dívida técnica

| Item | Impacto | Onde está rastreado |
|---|---|---|
| **URL base do servidor sem origem definida** | O aplicativo fala com o repositório simulado, não com o backend | Não está na spec — decisão pendente |
| Tags acentuadas do `openapi.yaml` não normalizadas | Nomes mutilados no cliente gerado (`sesso_api.dart`) | Precisa passar por `/speckit-clarify` |
| `500`, `404` e `405` fora do contrato | O servidor já os devolve | **T027a** do `tasks.md` |
| springdoc fora do `pom.xml` | Sem documentação viva da API | Lacuna aberta desde a T002 |
| `POST /v1/auth/sair` não existe | `encerrarSessao()` só apaga a credencial local; o refresh **continua válido no servidor até vencer** | **T074/T077**, US4 |
| Versões diferentes do Flutter entre as máquinas | `pubspec.lock` oscila entre commits | CI usa `channel: stable` sem pino |
| **Sem provedor de envio de código** | A US5 não fecha o ciclo de ponta a ponta; em `producao` a aplicação não sobe | **T065a** |
| **Conta assistida abandonada** | Fica pendente para sempre e mantém o canal ocupado | **T065b** |

### Pendências que dependem de pessoas

| Pendência | Com quem | Bloqueia? |
|---|---|---|
| De onde vem a URL base do servidor | Eduardo | **Sim**, para o aplicativo falar com o backend |
| Definir `MEMORA_CHAVE_ORIGEM` em produção (≥ 32 bytes) | Quem implantar | **Sim**, na implantação |
| **Escolher provedor de e-mail/SMS** (T065a) | Equipe — nunca esteve na spec | **Sim**, na implantação: sem ele a aplicação não sobe em `producao` |
| **Decidir o destino da conta assistida abandonada** (T065b) | Equipe | Não hoje — mas quem desiste no meio perde o e-mail |
| **Confirmar a `TelaConfirmarCanal`** como parte da US5 | Eduardo | Não — já implementada; falta o aval de que era consequência, e não escopo novo |
| Contrato documentar o `500` (T027a) | Eduardo | Não |
| Normalizar as tags acentuadas | Eduardo | Não |
| Aceitar convite do repositório | Du3101 | Não |
| GitHub Student Pack | Eduardo (enviado) | Não — libera proteção de branch |
| Corrigir contradições do Arquivo X | Equipe | Não |
| **Teste com 5 pessoas de 65+ anos** | Equipe | **Sim** — portão de saída das duas features |

> A proteção da branch `master` **não está ativa** — o GitHub exige plano Pro em
> repositório privado. A regra de não commitar direto na `master` vale por
> acordo da equipe.

---

## 11. Estado do repositório

O fluxo é de **PRs empilhadas**: cada seção do `tasks.md` vira uma branch, e
cada branch sai da anterior, não da `master`. Elas entram **na ordem**, e quando
a de baixo é mergeada a de cima precisa ser reapontada
(`gh pr edit N --base master`) — senão o merge não chega à `master`.

### PRs mergeadas — 18

Da #1 à #18: especificações das duas features, tokens e temas, componentes,
fundação do backend, banco, núcleo de segurança, contrato/auditoria/cliente
gerado, correções de revisão, backend da US1, o lado do aplicativo da fase 2,
o backend da US2, as correções da revisão dele, este relatório e as telas da US2.

**A fila foi fechada em 2026-08-24**, na ordem que o empilhamento exigia: #15 →
reapontar a #16 para `master` → #16 → #17 → #18.

### Fila atual — uma PR aberta

| # | Título | Base | Estado |
|---|---|---|---|
| **#19** | Modo assistido — US5 completa (T057-T065) | `master` | 🟢 Aberta, CI verde nos quatro jobs |

A branch `feature/001-fase5-us5` saiu **da `master`**, e não da anterior — a
primeira em várias fases que não nasce empilhada, porque a fila estava vazia
quando ela começou.

### Uma lição de fluxo que custou quase um erro

Quando a fila foi fechada, o merge da `master` de volta na branch das telas
gerou **cinco blocos conflitantes no `CLAUDE.md`** — as duas linhas de trabalho
tinham editado a mesma passagem de contexto.

Resolver mantendo só um dos lados teria apagado, em silêncio, os avisos que a
revisão da PR #15 havia acrescentado: a distinção entre `estado` e
`bloqueada_ate`, duas regras novas de processo e dois portões de segurança.
**Conflito em documentação de contexto não se resolve escolhendo um lado** — os
dois lados costumam ser verdade.

---

## 12. Próximos passos

### Imediato

1. **Revisar e mergear a #19** (US5). O CI está verde, mas ela não tem revisão —
   e foi justamente a revisão da #15 que encontrou duas falhas latentes de
   segurança que ninguém tinha visto
2. **Decidir de onde vem a URL base do servidor** — é o que separa o aplicativo
   de conversar com o backend real em vez do simulado
3. **Escolher um provedor de e-mail/SMS** (T065a). Sem ele a US5 não fecha o
   ciclo de ponta a ponta, e o servidor **não sobe** com o perfil `producao`

### Próxima fase de implementação — **T066-T078, as US3 e US4**

A **US3** é recuperar o acesso sozinha, sem contato humano. É onde mora o golpe
que a FR-062 descreve, e ela só é segura porque a US5 acabou de tornar possível
exigir canal **verificado**: a recuperação nunca envia código para canal cuja
posse não foi confirmada.

A **US4** fecha a saída deliberada — `POST /v1/auth/sair`, a T074 — e com ela a
dívida de `encerrarSessao()`, que hoje apaga a credencial só no aparelho e deixa
o refresh válido no servidor até vencer.

**A feature 001 é desbloqueada ao final da fase 6** (T044 do plano de validação).

### Depois

| Fase | Escopo |
|---|---|
| 6 — US3 | Recuperar o acesso, com aviso antigolpe permanente |
| 7 — US4 | Sair da conta — **desbloqueia a feature 001** ao final |
| 8 | Login social por Authorization Code com PKCE, sem WebView |
| 9 | Validação final: V1-V10 e as seis revisões obrigatórias |

Continua em aberto a **fase 7 da feature 002** (galeria de componentes e análise
estática contra valores literais). Protege o sistema a longo prazo, mas não
entrega produto.

---

## 13. Achados que valem registro

Coisas descobertas medindo, não supondo:

- **A paleta do protótipo passa na WCAG.** O azul `#1040F8` mede 6,75:1 com
  texto branco. A identidade visual foi preservada — não a altere sem medir.
- **O padrão do Spring Security é fraco demais.** `Argon2PasswordEncoder` usa
  16 MiB; a OWASP exige no mínimo 19 MiB. E **o mínimo da OWASP é fraco neste
  hardware**: 19 MiB rende 42 ms. Calibramos para 64 MiB com t=4, ~240 ms.
- **Os botões SIM/NÃO do protótipo não reprovavam em contraste** (14,98:1 e
  7,55:1) — a primeira avaliação estava errada, era impressão visual. O defeito
  real era a **altura de 24 px contra os 48 dp exigidos**.
- **`Semantics(button: true)` não basta**: sem `onTap` na própria `Semantics`, o
  TalkBack anuncia o botão mas o duplo-toque não ativa nada. Custou um defeito.
- **Não use `Opacity` para estado desabilitado** — derruba o contraste do rótulo
  para 2,79:1.
- **No Spring Boot 4 cada autoconfiguração vive em módulo próprio.** Pôr
  `flyway-core` no pom **não** ativa o Flyway: as migrations são ignoradas em
  silêncio e o sintoma aparece longe da causa.
- **Docker 29 rejeita Testcontainers 1.x.** Usamos 2.0.5, gerenciado pelo Spring
  Boot 4.1.
- **Dentro de `testWidgets` o relógio é falso** — um repositório que faz
  `Future.delayed` nunca completa se ninguém bombear quadros, e o arquivo
  inteiro trava sem apontar a causa.
- **O `REQUIRES_NEW` da auditoria custa duas conexões por requisição** — por
  isso `maximum-pool-size` está explícito em 20, e o teto de requisições
  simultâneas em operação auditada é metade disso.
- **O Argon2 não pode rodar dentro da transação.** Achado na revisão da #15:
  vinte requisições simultâneas ao endpoint público seguravam as vinte conexões
  do pool por 240 ms cada, sem tocar no banco.
- **Jackson mudou de pacote no Spring Boot 4.** `ObjectMapper` agora é
  `tools.jackson.databind.ObjectMapper`; `com.fasterxml.jackson.databind` não
  existe mais no classpath. As **anotações** (`@JsonProperty`) continuam no
  pacote antigo, o que torna o erro confuso: metade dos imports antigos compila.
- **Bean de `Filter` é registrado duas vezes.** Declarar um
  `OncePerRequestFilter` como `@Bean` faz o Boot instalá-lo também como filtro
  de servlet, fora da cadeia do Spring Security — ele passa a rodar duas vezes
  por requisição. O antídoto é um `FilterRegistrationBean` com
  `setEnabled(false)`.
- **Hash lento não é sempre a resposta, e hash rápido também não.** O refresh
  token usa SHA-256 porque tem 256 bits de entropia, onde Argon2 não compraria
  nada. O código de verificação usa **Argon2**, porque tem 10⁶ possibilidades e
  um resumo simples se inverte em tempo desprezível. A pergunta certa não é
  "qual hash é mais forte", é **quanta entropia o segredo tem**.
- **Contagem de teste se faz com `clean`.** Um relatório órfão do Surefire, de
  uma classe que já não existe, sobrevive em `target/` e infla toda soma —
  fez este projeto acreditar em três números errados seguidos.
- **Um teste que passa pode estar procurando a coisa errada.** O portão da
  FR-060 passava com o portão quebrado, porque o finder buscava um ícone que o
  componente não usa. Só apareceu ao quebrar de propósito. **É por isso que se
  quebra.**

---

*Relatório atualizado a partir do estado do repositório em 2026-08-24, após a
entrega da US5. Os números de teste, análise estática e contraste foram obtidos
executando as verificações, não estimados.*
