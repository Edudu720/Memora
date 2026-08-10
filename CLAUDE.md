# Contexto do Projeto Memora

> Leia este arquivo inteiro antes de qualquer ação. Ele existe para que uma nova
> sessão consiga continuar o trabalho sem repetir decisões já tomadas nem refazer
> análises já feitas.

**Última sessão**: 2026-07-29
**Estado**: fase 1 completa (T001-T007); da fase 2, **banco** (T008-T014) e
**núcleo de segurança** (T015-T023) prontos, com 99 testes no backend. Telas de
cadastro da US1 contra repositório simulado; backend ainda **sem endpoints**.
**Próximo: T024-T027** (esquema de erro, auditoria, rastreio e cliente Dart).

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
| **001 — Autenticação Acessível** | ✅ | ✅ | ✅ | 🟡 telas da US1 prontas; backend pendente |
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

`backend/src/test/` — 99 testes. `TesteComBanco` é a base que compartilha **um**
PostgreSQL entre todas as classes (padrão singleton container); herdar dela
custa zero, subir um container por classe custaria ~15 s cada.

### Três portões de segurança, cada um validado quebrando de propósito

| Portão | Onde | Como foi provado |
|---|---|---|
| Entidade bate com a migration | `contextLoads` | Renomeei uma coluna: reprovou com `missing column` |
| Tempo não revela conta existente | `TempoConstanteTest` | Pus o atalho `return false`: reprovou com **0 ms** contra os ~240 ms esperados |
| Reuso de token derruba a família | `ReusoDeTokenTest` (V3) | Revoguei só o token reusado: reprovou com "B continuou funcionando" |

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

### Próxima tarefa: **T024 a T027** (contrato, erros e cliente Dart)

`specs/001-autenticacao-acessivel/tasks.md`, fase 2. Depois vêm os endpoints da
US1 (T033-T037), que substituem o `RepositorioAutenticacaoSimulado`.

Quando os endpoints chegarem, o que já está pronto para eles:
- `ServicoDeSessao.iniciar` devolve o `SessaoResposta` do contrato inteiro
  (token de acesso, refresh, 900 s)
- `ServicoDeSessao.renovar` devolve `Recusada(motivo)`. **O motivo é da
  auditoria, não do cliente** — a resposta é `401` em todos os casos, senão
  informa que aquele token um dia foi válido
- `LimitadorTentativas.avaliar` devolve `Bloqueado(segundos)`, que é o
  `tentar_novamente_em_segundos` do `429`
- **Bucket4j e springdoc continuam fora do pom** (lacuna do T002); springdoc
  entra na T024

**A troca do simulado pelo real é de uma linha**, em
`lib/demonstracao/casa_demonstracao.dart`, porque as telas dependem apenas da
interface `RepositorioAutenticacao`.

⚠️ Avisos para o **T027** (geração do cliente no app):
- Tags acentuadas do contrato geram nomes mutilados (`SessoApi`,
  `RecuperaoDeAcessoApi`). Normalizar as tags para ASCII antes de gerar.
- O `dart-dio` gera um **pacote completo** (pubspec próprio). Não cabe
  literalmente em `app/lib/services/api/`; montar como pacote local
  (ex.: `app/pacotes/memora_api/`) e ajustar a tarefa.
- Bucket4j e springdoc ainda **não** estão no pom (lacuna do T002);
  entram em T021 e T024 respectivamente.

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
| **Cadastro** | Fluxo real da US1: boas-vindas, cadastro e confirmação |
| **Componentes** | Vitrine do Design System |
| **Aparência** | Tela real de preferências, com pré-visualização |

A casca sai quando o Hub existir.

### Backend

Precisa de `JAVA_HOME` explícito, porque o `java` do PATH é um atalho que confunde
o Maven:

```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"; cd C:\Users\Edu\Documents\Memora\backend; .\mvnw test
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
- ❌ Guardar token em `SharedPreferences` — apenas `flutter_secure_storage`
- ❌ Implementar sem spec aprovada
- ❌ Afirmar que algo passa sem ter rodado a verificação
- ❌ Supor requisito quando a spec é ambígua — pergunte

---

## 10. Pendências que dependem de pessoas

| Pendência | Com quem | Bloqueia? |
|---|---|---|
| Aceitar convite do repositório | Henrique-Sandrini e Du3101 | Não |
| GitHub Student Pack aprovado | Eduardo (enviado) | Não — libera proteção de branch |
| Corrigir contradições do Arquivo X (voz, offline) | Equipe | Não — ver [requisitos-atualizados.md](docs/referencia/requisitos-atualizados.md) |
| Teste com 5 pessoas de 65+ anos | Equipe | **Sim** — portão de saída das features 001 e 002 |

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
