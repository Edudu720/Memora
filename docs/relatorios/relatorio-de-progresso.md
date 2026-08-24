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
| Tarefas concluídas | **56 de 89** na feature 001 · **44 de 53** na feature 002 |
| Histórias de usuário entregues | **US1** (criar conta) e **US2** (voltar ao app) |
| Endpoints implementados | 3 |
| Testes automatizados | **204** no aplicativo + **250** no backend |
| Linhas de código (sem o gerado) | ~10,2 mil de produção · ~7,8 mil de teste |

**Em uma frase**: as duas jornadas de entrada — criar conta e voltar depois —
estão completas de ponta a ponta, com backend, telas, acessibilidade e uma
bateria de portões de segurança que foram validados quebrando-os de propósito.

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
| 5 — US5 | Modo assistido (familiar ajuda sem ver a senha) | ⬜ Próxima — T057-T065 |
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

### Os três endpoints que existem hoje

| Endpoint | Devolve | Recusa com |
|---|---|---|
| `POST /v1/auth/cadastro` | `201` + sessão | `400`, `429` |
| `POST /v1/auth/entrar` | `200` + sessão | `401` genérico, `429` com espera |
| `POST /v1/auth/sessao/renovar` | `200` + sessão | `401` genérico |

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
- **telas/** — `TelaBoasVindas`, `TelaCadastro`, `TelaLogin`
- **controladores/** — `ControladorCadastro`, `ControladorLogin`

Os textos vivem em `app/lib/l10n/textos_autenticacao.dart`, na voz da Memora.
Não é `flutter_localizations` — é a "estrutura preparada" que a decisão D3 da
feature 002 pediu: quando houver um segundo idioma, estas constantes viram
`.arb` sem ninguém caçar frase dentro de widget.

### O que dá para ver rodando hoje

A tela inicial é uma **casca de demonstração** provisória, com três abas:
**Entrar** (fluxo real das US1 e US2: boas-vindas → cadastro → dentro → sair →
login), **Componentes** (vitrine do Design System) e **Aparência** (tela real de
preferências). A casca sai quando o Hub existir.

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

Dois portões novos vieram da revisão da PR #15 e estão na PR #16: *bloqueio não
ressuscita conta desativada* (a sexta tentativa devolvia **200**) e *renovação
recusa conta desativada* (`expected:<401> but was:<200>`).

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
`feature/001-fase4-us2-app`.

| Verificação | Comando | Resultado |
|---|---|---|
| Análise estática do aplicativo | `flutter analyze` | ✅ **No issues found** (54 s) |
| Testes do aplicativo | `flutter test` | ✅ **204 testes — All tests passed!** |
| Contraste da paleta | `python validar_paleta.py` | ✅ **Todos os pares aprovados**, WCAG 2.2 |
| Testes do backend | `./mvnw clean test` | ✅ **250 testes, 0 falhas, 0 erros** |

O backend sobe um PostgreSQL real por Testcontainers — o Docker Desktop precisa
estar rodando, senão a falha aparece longe da causa. Os 250 já incluem as
correções da revisão (PR #16), mergeada em 2026-08-24.

O CI (`.github/workflows/verificacao.yml`) roda quatro jobs em toda push e PR:
contraste da paleta, build e testes do backend, análise e testes do aplicativo,
e o cliente gerado do contrato.

### Distribuição dos testes

| Suíte | Quantidade |
|---|---|
| Design System | 139 |
| Autenticação (aplicativo) | 65 |
| **Total aplicativo** | **204** |
| **Backend** | **250** |
| **Total do projeto** | **454** |

> **Correção de registro — e a correção da correção.** A primeira versão deste
> relatório dizia 245, corrigindo os 244 do `CLAUDE.md`. Ambos estavam errados,
> e pelo mesmo motivo: a contagem vinha de somar os XMLs de
> `target/surefire-reports/` **sem `clean`**, e havia ali um
> `TEST-...SondaCaminhoDesconhecidoTest.xml` de 10/08/2026 — uma classe de sonda
> que nunca foi commitada e não existe em `backend/src` nem em commit algum.
> Valendo 1 teste, ela inflava toda contagem seguinte, porque `target/` está no
> `.gitignore` e ninguém limpava. Numa execução com `clean`, o `Tests run:` do
> Maven e a soma dos 26 XMLs concordam: **250**.

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

### Dívida técnica

| Item | Impacto | Onde está rastreado |
|---|---|---|
| **URL base do servidor sem origem definida** | O aplicativo fala com o repositório simulado, não com o backend | Não está na spec — decisão pendente |
| Tags acentuadas do `openapi.yaml` não normalizadas | Nomes mutilados no cliente gerado (`sesso_api.dart`) | Precisa passar por `/speckit-clarify` |
| `500`, `404` e `405` fora do contrato | O servidor já os devolve | **T027a** do `tasks.md` |
| springdoc fora do `pom.xml` | Sem documentação viva da API | Lacuna aberta desde a T002 |
| `POST /v1/auth/sair` não existe | `encerrarSessao()` só apaga a credencial local; o refresh **continua válido no servidor até vencer** | **T074/T077**, US4 |
| Versões diferentes do Flutter entre as máquinas | `pubspec.lock` oscila entre commits | CI usa `channel: stable` sem pino |

### Pendências que dependem de pessoas

| Pendência | Com quem | Bloqueia? |
|---|---|---|
| De onde vem a URL base do servidor | Eduardo | **Sim**, para o aplicativo falar com o backend |
| Definir `MEMORA_CHAVE_ORIGEM` em produção (≥ 32 bytes) | Quem implantar | **Sim**, na implantação |
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

### PRs mergeadas — 14

Da #1 à #14: especificações das duas features, tokens e temas, componentes,
fundação do backend, banco, núcleo de segurança, contrato/auditoria/cliente
gerado, correções de revisão, backend da US1 e o lado do aplicativo da fase 2.

### Fila atual — duas PRs abertas e uma branch sem PR

| # | Título | Base | Estado |
|---|---|---|---|
| **#15** | Backend da US2: entrada e renovação de sessão (T047-T050) | `master` | 🟡 Aberta — entra primeiro |
| **#16** | Correções da revisão da PR #15 | `feature/001-fase4-us2-backend` | 🟡 Aberta — empilhada sobre a #15 |
| — | Telas da US2 (T051-T056), em `feature/001-fase4-us2-app` | — | ⚠️ **Sem PR aberta** |

**Três commits estão fora da `master`** na linha das telas — `657ef5c` (backend
da US2), `e9651d7` (passagem de contexto) e `44a2630` (telas da US2) — mais os
dois commits da PR #16.

⚠️ **Ponto de atenção**: a branch das telas da US2 está empilhada sobre
`feature/001-fase4-us2-backend`, **não** sobre a branch de correções
(`fix/001-revisao-fase4-us2`). Ao integrar, confirme a ordem — as correções da
#16 fecham duas falhas latentes de segurança: conta desativada ressuscitada pelo
próprio bloqueio, e renovação de sessão que não olhava o estado da conta.

---

## 12. Próximos passos

### Imediato

1. **Fechar a fila de PRs**: mergear a #15, reapontar a #16 para a `master`,
   mergear, e então abrir a PR das telas da US2 já reapontada
2. **Decidir de onde vem a URL base do servidor** — é o que separa o aplicativo
   de conversar com o backend real em vez do simulado

### Próxima fase de implementação — **T057-T065, a US5 (modo assistido)**

Protege a autonomia de quem está sendo ajudada por um familiar: o acompanhante
preenche, mas **nunca** vê a senha nem controla a recuperação. Traz junto a
confirmação de posse do canal — código de 6 dígitos, validade de 10 min, uso
único, guardado **hasheado** — que é o que a T047 precisou adiar.

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

---

*Relatório gerado a partir do estado do repositório em 2026-08-24. Os números de
teste, análise estática e contraste foram obtidos executando as verificações,
não estimados.*
