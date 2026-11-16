---

description: "Task list — Autenticação Acessível do Memora"
---

# Tasks: Autenticação Acessível

**Input**: Documentos de design em `specs/001-autenticacao-acessivel/`

**Prerequisites**: [spec.md](spec.md) · [plan.md](plan.md) · [research.md](research.md) · [data-model.md](data-model.md) · [contracts/openapi.yaml](contracts/openapi.yaml) · [quickstart.md](quickstart.md)

**Tests**: **obrigatórios**. A Constituição exige revisão de segurança e acessibilidade, e o [quickstart.md](quickstart.md) define 10 cenários de validação que são portão de saída da feature.

## Format: `[ID] [P?] [Story] Descrição`

- **[P]**: pode ser feito em paralelo (arquivos distintos, sem dependência)
- **[Story]**: a qual história de usuário a tarefa pertence

## Regras que valem para todas as tarefas

1. **O Design System já existe e está no `master`.** Use `BotaoPrimario`,
   `CampoTexto`, `CampoSenha`, `CampoCodigo`, `ConfirmacaoMemora`,
   `MensagemErro`, `Carregando`, `BarraSuperior` e os componentes de informação.
   **Nunca recrie um componente** — se faltar algo, ele entra na feature 002.
2. **O cliente Dart da API é gerado** a partir de `contracts/openapi.yaml`
   (decisão R8). **Nunca editar à mão.**
3. **Nenhum valor visual literal** fora dos tokens.
4. Toda validação de interface é **repetida no servidor** (FR-038).

---

## Phase 1: Setup

- [x] T001 Criar o projeto Spring Boot em `backend/`, pacote `br.fatec.memora`, com Java 21
- [x] T002 [P] Configurar `backend/pom.xml` com Spring Web, Spring Security, Spring Data JPA, PostgreSQL, BouncyCastle, Bucket4j, springdoc-openapi e Testcontainers
- [x] T003 [P] Criar `docker-compose.yml` na raiz com PostgreSQL 16 para desenvolvimento
- [x] T004 [P] Adicionar `.gitignore` do Java em `backend/`
- [x] T005 Configurar geração do cliente Dart a partir de `specs/001-autenticacao-acessivel/contracts/openapi.yaml` para `app/lib/services/api/`, com script reproduzível
- [x] T006 Criar a estrutura `app/lib/features/autenticacao/{data,domain,presentation}/`
- [x] T007 Estender `.github/workflows/verificacao.yml` com job de build e teste do backend

---

## Phase 2: Foundational

> **BLOQUEIA TODAS AS HISTÓRIAS.** Nenhuma tela ou endpoint antes disto.

### Banco e entidades

- [x] T008 Criar migration inicial em `backend/src/main/resources/db/migration/` com as 5 tabelas de [data-model.md](data-model.md), usando UUID como chave
- [x] T009 [P] Criar entidade `PessoaUsuaria` em `backend/src/main/java/br/fatec/memora/autenticacao/dominio/`
- [x] T010 [P] Criar entidade `CanalContato` com unicidade de `(tipo, valor)`
- [x] T011 [P] Criar entidade `Sessao` com `familiaId` e `substituidaPor`
- [x] T012 [P] Criar entidade `CodigoVerificacao`
- [x] T013 [P] Criar entidade `EventoAutenticacao`, somente inserção
- [x] T014 Criar os repositórios Spring Data com os índices de [data-model.md](data-model.md)

### Segurança — o núcleo da feature

- [x] T015 Configurar `Argon2PasswordEncoder` em `backend/src/main/java/br/fatec/memora/autenticacao/seguranca/` com **19456 KiB de memória, 2 iterações, paralelismo 1** — os padrões do Spring usam 16 MiB, abaixo do mínimo OWASP (R1)
- [x] T016 Escrever teste em `backend/src/test/java/br/fatec/memora/autenticacao/seguranca/Argon2ParametrosTest.java` que **falha** se os parâmetros ficarem abaixo do mínimo OWASP
- [x] T017 Medir o tempo de hash no ambiente alvo e registrar em `specs/001-autenticacao-acessivel/research.md`; se ficar abaixo de ~250 ms, aumentar a memória
- [x] T018 Implementar emissão de token de acesso (15 min) e refresh opaco em `seguranca/`
- [x] T019 Implementar **rotação com detecção de reuso**: refresh já usado revoga toda a `familiaId` e registra `reuso_token_detectado` (R2)
- [x] T020 Escrever teste do cenário V3 do [quickstart.md](quickstart.md) — reusar token antigo derruba a família inteira
- [x] T021 Implementar rate limiting em duas camadas em `backend/src/main/java/br/fatec/memora/autenticacao/seguranca/LimitadorTentativas.java`, com estado fora da memória local (R4)
- [x] T022 Implementar comparação em **tempo constante** em `backend/src/main/java/br/fatec/memora/autenticacao/seguranca/VerificadorCredenciais.java`, executando hash fictício quando a conta não existe (R3)
- [x] T023 Escrever teste em `backend/src/test/java/br/fatec/memora/autenticacao/seguranca/TempoConstanteTest.java` medindo a latência de conta existente contra inexistente

### Contrato e erros

- [x] T024 Implementar o esquema `Erro` de [contracts/openapi.yaml](contracts/openapi.yaml) com tratamento global, sem stack trace nem detalhe interno (FR-041)
- [x] T025 [P] Implementar registro de `EventoAutenticacao` para todos os tipos, sem dado sensível (FR-039, FR-040)
- [x] T026 [P] Adicionar Trace ID e Request ID em `backend/src/main/java/br/fatec/memora/comum/FiltroRastreio.java`
- [x] T027 Gerar o cliente Dart em `app/pacotes/memora_api/` e verificar que compila contra o contrato
- [ ] T027a Documentar em [contracts/openapi.yaml](contracts/openapi.yaml) as respostas de erro que o servidor já devolve e o contrato não prevê: `500` (`ERRO_INESPERADO`), `404` e `405`. **Dívida de spec, não de código** — hoje as três existem em `CodigoDeErro`/`TratadorGlobalDeErros` porque a alternativa era vazar o formato padrão do Spring, que carrega caminho e classe da exceção (FR-041). Fechar isto também elimina os `unused_import` que o gerador produz por não haver resposta de erro declarada
  > **Acrescentado em 2026-08-15, ao fazer a T048**: vale revisar junto qual
  > código o `POST /v1/auth/sessao/renovar` devolve no `401`. O contrato aponta
  > para `CredenciaisInvalidas`, e é o que está implementado — mas o texto desse
  > código é *"Esses dados não conferem"*, e quem falha ao renovar **não digitou
  > nada**. O `SESSAO_EXPIRADA` existe, está sem uso, e o texto dele — *"Faz um
  > tempinho que você não usa o Memora. Vamos entrar de novo?"* — descreve
  > exatamente esta situação. Não há diferença de segurança entre os dois,
  > desde que a resposta continue **uniforme** nos quatro motivos de recusa.
  > Troca de uma linha em `ControladorSessao`, mas muda o contrato.

### Aplicativo — base da feature

- [x] T028 [P] Criar entidades de domínio em `app/lib/features/autenticacao/domain/`
- [x] T029 [P] Criar `RepositorioAutenticacao` (interface) em `domain/`
- [x] T030 Implementar `RepositorioAutenticacaoApi` em `data/`, sobre o cliente gerado
- [x] T031 Implementar armazenamento de credenciais com `flutter_secure_storage` em `app/lib/services/seguranca/` — **nunca** `SharedPreferences`
- [x] T032 Escrever teste do cenário V8 em `app/test/features/autenticacao/armazenamento_seguro_test.dart` — nenhuma credencial em armazenamento comum

---

## Phase 3: US1 — Criar minha conta e começar a usar (P1)

**Meta**: a pessoa cria a conta e **já entra no aplicativo**, sem passar pelo login.

**Teste independente**: entregar o app a alguém de 65+ anos, sem instrução, e observar se conclui o cadastro sozinha.

> 🟡 **Aplicativo concluído em 2026-07-26. Backend pendente.**
>
> As telas funcionam de ponta a ponta contra `RepositorioAutenticacaoSimulado`,
> que substitui o servidor até os endpoints existirem. A troca para a
> implementação real é de uma linha, porque as telas dependem apenas da
> interface `RepositorioAutenticacao`.
>
> 36 testes. Achados durante a implementação:
> - `pumpAndSettle` **nunca resolve** enquanto o indicador de carregamento
>   estiver na tela — ele anima indefinidamente. Um teste travou 10 minutos até
>   eu mover a verificação de concorrência para teste de unidade.
> - Localizar campo por texto é frágil: o rótulo aparece em mais de um ponto da
>   árvore. As telas expõem chaves (`TelaCadastro.chaveNome` etc.) para isso.

### Backend

- [x] T033 [US1] Implementar `POST /v1/auth/cadastro` em `autenticacao/api/`, devolvendo sessão iniciada (FR-009)
- [x] T034 [US1] Implementar política de senha em `backend/src/main/java/br/fatec/memora/autenticacao/dominio/PoliticaDeSenha.java`, priorizando **comprimento** e recusando senhas comprometidas (FR-042)
- [x] T035 [US1] Garantir resposta `201` idêntica quando o canal já existe, sem revelar (FR-010)
- [x] T036 [US1] Escrever teste do cenário V2 em `backend/src/test/java/br/fatec/memora/autenticacao/api/NaoRevelaExistenciaTest.java`
- [x] T037 [US1] Implementar normalização do identificador em `backend/src/main/java/br/fatec/memora/autenticacao/dominio/NormalizadorIdentificador.java`

### Aplicativo

- [x] T038 [P] [US1] Criar `TelaBoasVindas` em `presentation/telas/` — **uma única** ação principal, nenhuma decisão
- [x] T039 [US1] Criar `ControladorCadastro` em `presentation/controladores/`, com estados vazio, carregando, erro e sucesso
- [x] T040 [US1] Criar `TelaCadastro` usando `CampoTexto`, `CampoSenha` e `BotaoPrimario` do Design System
- [x] T041 [US1] Implementar `textoAjuda` em cada campo explicando **para que o dado serve** (FR-004)
- [x] T042 [US1] Implementar validação por campo em `app/lib/features/autenticacao/presentation/controladores/controlador_cadastro.dart`, preservando o que já foi digitado (FR-005, FR-006)
- [x] T043 [US1] Exibir as regras de senha em `app/lib/features/autenticacao/presentation/widgets/regras_de_senha.dart`, com atendimento em tempo real (FR-008)
- [x] T044 [US1] Tratar toque duplo no envio em `app/lib/features/autenticacao/presentation/controladores/controlador_cadastro.dart`
- [x] T045 [US1] Escrever teste de widget do cadastro em `app/test/features/autenticacao/tela_cadastro_test.dart`
- [x] T046 [US1] Escrever teste de acessibilidade em `app/test/features/autenticacao/cadastro_acessibilidade_test.dart`: contraste, alvo de toque, escala 2.0 e leitor de tela

---

## Phase 4: US2 — Voltar ao aplicativo depois (P2)

**Meta**: reabrir o app e continuar conectada, sem digitar nada.

**Teste independente**: fechar e reabrir após um cadastro e contar quantas ações são necessárias.

### Backend

- [x] T047 [US2] Implementar `POST /v1/auth/entrar`, aceitando **qualquer canal cadastrado** (FR-051)
  > ⚠️ **A tarefa dizia "qualquer canal verificado", e isso estava errado.** O
  > cadastro cria o canal com `verificado = false` e o fluxo de confirmação de
  > posse só chega na T058 (US5): exigir verificação aqui deixaria **toda conta
  > sem conseguir entrar** até a fase 5 existir, contra a FR-011. A própria
  > FR-051 fala em canais *cadastrados*; quem restringe canal não verificado é a
  > FR-052, e ela restringe a **recuperação de acesso**, que é onde mora o golpe
  > da FR-062. No login quem autentica é a senha; o canal só localiza a conta.
  > **Decisão da equipe em 2026-08-15**: `data-model.md` (linha 71) e a descrição
  > da operação no `openapi.yaml` foram corrigidos junto.
- [x] T048 [US2] Implementar `POST /v1/auth/sessao/renovar` com a rotação de T019
- [x] T049 [US2] Implementar bloqueio progressivo em `backend/src/main/java/br/fatec/memora/autenticacao/seguranca/BloqueioProgressivo.java` — 1, 5, 15, 60 min após 5 falhas (FR-014)
  > A escada já existia desde a T021. Esta tarefa ligou o `LimitadorTentativas`
  > ao `POST /v1/auth/entrar` e fez o `429` sair com
  > `tentar_novamente_em_segundos`. **A tentativa que estoura o limite já
  > responde `429`**, e não `401`: é o que o passo 2 do V6 descreve.
- [x] T050 [US2] Escrever teste do cenário V6 — bloqueio progressivo devolve `tentar_novamente_em_segundos`
  > `BloqueioProgressivoNoLoginTest`, 12 testes. Percorre os quatro degraus pelo
  > endpoint com um **relógio ajustável** no lugar do `Clock` da aplicação —
  > com o relógio do sistema o percurso levaria 81 minutos.
  > **A revisão de UX foi automatizada na parte automatizável**: o texto precisa
  > explicar o motivo, oferecer a recuperação e não usar tom de punição nem
  > jargão. Validado quebrando: com a mensagem trocada por *"Conta bloqueada:
  > você excedeu o número de tentativas permitidas"*, a escada continuou
  > passando e os três testes de texto reprovaram — que é exatamente o caso que
  > o V6 descreve.

### Aplicativo

- [x] T051 [US2] Criar `ControladorLogin` com renovação automática de sessão
  > **A renovação vem antes do formulário.** `iniciar()` tenta `renovarSessao()`
  > em silêncio e só mostra campo quando isso falha — é o cenário 1 da US2
  > ("reabro e continuo conectada") e o 2 ("já vem preenchido, só falta a
  > senha") no mesmo caminho. Mostrar o formulário primeiro faria a tela piscar
  > entre "digite sua senha" e "bem-vinda de volta", o que para quem lê devagar
  > é indistinguível de defeito.
- [x] T052 [US2] Criar `TelaLogin` usando os componentes do Design System
- [x] T053 [US2] Pré-preencher o identificador do último acesso em `app/lib/features/autenticacao/data/ultimo_acesso_local.dart` (FR-012)
  > **Fica em `shared_preferences`, não no cofre.** Decisão de 2026-08-20.
  > Identificador não é credencial, e cifrá-lo não protegeria nada: o propósito
  > da FR-012 é **exibi-lo na tela**, já preenchido. Além disso, o cenário V8
  > reprova se sobrar **qualquer coisa** no cofre depois de sair — guardar ali
  > um dado que precisa sobreviver à saída obrigaria a afrouxar esse teste.
- [x] T054 [US2] Escrever os textos de bloqueio em `app/lib/l10n/` na persona da Memora: acolhedores, com motivo e caminho de recuperação (FR-015)
  > **É um arquivo Dart de constantes, não `flutter_localizations`.** A decisão
  > D3 da feature 002 deixou idiomas fora de escopo com a "estrutura preparada";
  > isto é a estrutura preparada. Montar `.arb` e geração de código mexeria em
  > pubspec, build e CI para entregar zero comportamento novo.
- [x] T055 [US2] Implementar expiração por inatividade em `app/lib/features/autenticacao/domain/monitor_de_sessao.dart`, com aviso prévio (FR-017)
  > **30 minutos parado, com aviso 2 minutos antes.** A spec dizia "período
  > prolongado" e não dava número. O prazo saiu da ameaça que a FR-017 mitiga na
  > tabela da spec — **roubo de referência de sessão**, isto é, o celular
  > esquecido na mesa — e não de "faz semanas que não abro", que já é coberto
  > pela validade de 60 dias do refresh. Os 2 minutos de aviso são o tempo de
  > alguém com dificuldade motora perceber, achar os óculos e acertar o botão;
  > 1 minuto, o padrão bancário, expulsa exatamente quem este produto atende.
- [x] T056 [US2] Escrever teste de widget do login em `app/test/features/autenticacao/tela_login_test.dart`, incluindo o estado bloqueado

> **Duas decisões que apareceram ao implementar, e que valem revisar:**
>
> 1. **`RepositorioAutenticacao` ganhou `encerrarSessao()`**, porque sem apagar
>    a credencial local a FR-017 não encerra nada: o monitor levaria a pessoa ao
>    login e a renovação automática a colocaria de volta no mesmo instante. É
>    **só o lado do aparelho** — `POST /v1/auth/sair` é a T074 e ainda não
>    existe, então o refresh apagado aqui continua válido no servidor até
>    vencer. A US4 fecha isso junto com a T077.
> 2. **O botão "Esqueci minha senha" não aparece.** `TelaLogin.aoRecuperar` é
>    opcional e hoje ninguém o preenche, porque a recuperação é a US3. Oferecer
>    uma saída que não leva a lugar nenhum é pior do que não oferecer; o texto
>    do bloqueio já menciona o caminho, que é o que a FR-015 exige.
>
> **O portão de texto foi validado quebrando de propósito.** Trocando a
> mensagem de bloqueio por *"Conta bloqueada: você excedeu o número de
> tentativas permitidas"*, a mecânica inteira **continuou passando** — escada,
> botão sumindo, contagem regressiva, liberação automática — e só os três
> testes de texto reprovaram. Mesmo achado do `BloqueioProgressivoNoLoginTest`
> no backend. O portão da FR-012 também foi validado: movendo a gravação do
> identificador para antes da resposta do servidor, reprovou com
> `Expected: null / Actual: 'ana@email.com'`.

---

## Phase 5: US5 — Ser ajudada por um familiar sem entregar a senha (P2)

**Meta**: o acompanhante ajuda no preenchimento, mas **nunca** vê a senha nem controla a recuperação.

**Teste independente**: simular o cadastro com duas pessoas e verificar que o acompanhante não vê nem digita a senha.

### Backend

- [X] T057 [US5] Aceitar `modo_assistido` no cadastro e **exigir canal com posse confirmada** antes de concluir (FR-062)
- [X] T058 [US5] Implementar `POST /v1/canais/{id}/codigo` e `POST /v1/canais/{id}/verificar` com código de 6 dígitos, validade de 10 min e uso único (R5)
- [X] T059 [US5] Guardar o código **hasheado** em `backend/src/main/java/br/fatec/memora/autenticacao/dominio/CodigoVerificacao.java`, nunca em texto puro
- [X] T060 [US5] Escrever teste do cenário V4 em `backend/src/test/java/br/fatec/memora/autenticacao/api/CanalNaoVerificadoTest.java`

### Aplicativo

- [X] T061 [US5] Adicionar a pergunta *"Tem alguém te ajudando agora?"* no início do cadastro (FR-058)
- [X] T062 [US5] Criar `TelaEntregaDoAparelho`, que interrompe o fluxo e pede que o aparelho volte à pessoa dona da conta (FR-059)
- [X] T063 [US5] Usar `CampoSenha` com `permitirRevelar: false` no modo assistido (FR-060)
- [X] T064 [US5] Criar `TelaPrimeiraEntrada`, conduzindo a pessoa a entrar sozinha ao final (FR-063)
- [X] T065 [US5] Escrever teste em `backend/src/test/java/br/fatec/memora/autenticacao/api/ModoAssistidoSemVinculoTest.java` garantindo que não há vínculo nem permissão para o acompanhante (FR-064)

> **Três coisas que a fase 5 exigiu e não estavam escritas aqui.** Nenhuma é
> requisito novo: são consequências de cumprir a FR-062.
>
> 1. **Estado `PENDENTE_VERIFICACAO`** (migration V3). A T057 manda exigir posse
>    confirmada *antes de concluir* o cadastro, e o canal só passa a existir
>    **dentro** do cadastro — a confirmação exige um token que só é emitido no
>    fim dele. A conta assistida nasce em espera e só vira `ATIVA` quando a
>    posse é confirmada.
> 2. **Filtro de autenticação por token.** A T058 criou os dois primeiros
>    endpoints autenticados do projeto, e não existia nada que resolvesse o
>    token em identidade. O filtro **consulta o banco**: a sessão-chamariz da
>    FR-010 é um JWT válido cujo sujeito não existe, e parar na assinatura a
>    transformaria em acesso.
> 3. **`TelaConfirmarCanal`**, no aplicativo. Sem ela a conta assistida nasce em
>    espera e não há por onde sair: a pessoa fica com uma conta que existe e não
>    entra.

- [X] T065a [US5] Implementar o **envio real** do código (`EnviadorDeCodigo`) — fechado na Feature 006 com `EnviadorDeCodigoPorEmail` (`@Profile("producao")`, via `spring-boot-starter-mail` / `JavaMailSender`, validação *fail-fast* em `@PostConstruct`, texto sem links na voz da Memora e zero registro de código em log), mantendo `EnviadorDeCodigoEmLog` em `@Profile("!producao")`
- [X] T065b [US5] Decidir o que fazer com **conta assistida abandonada** — fechado na Feature 006 com `ServicoDeExpurgoDeContaPendente`: contas em `PENDENTE_VERIFICACAO` há mais de 24 horas são expurgadas tanto sob demanda (após o hash Argon2id em tempo constante no novo cadastro) quanto por rotina agendada (`@Scheduled`), preservando o chamariz da FR-010 para contas `ATIVA` ou pendentes recentes (`<= 24h`)

---

## Phase 6: US3 — Recuperar o acesso (P3)

**Meta**: recuperar a senha sozinha, sem contato humano.

**Teste independente**: a partir de uma conta existente, concluir a troca de senha sem usar nenhum outro fluxo.

### Backend

- [X] T066 [US3] Implementar `POST /v1/auth/recuperacao/solicitar`, respondendo `202` **sempre** (FR-019)
- [X] T067 [US3] Implementar `POST /v1/auth/recuperacao/confirmar`, revogando **todas** as sessões (FR-021)
- [X] T068 [US3] Notificar pelo canal cadastrado quando a senha mudar (FR-022) — a porta ficou em `aplicacao/NotificadorDeConta.java`, o adaptador de desenvolvimento em `infra/NotificadorDeContaEmLog.java` (`@Profile("!producao")`) e o adaptador real de produção em `infra/NotificadorDeContaPorEmail.java` (`@Profile("producao")`, fechado na Feature 006 junto com a T065a)
- [X] T069 [US3] Escrever teste do cenário V5 em `backend/src/test/java/br/fatec/memora/autenticacao/api/TrocaDeSenhaRevogaSessoesTest.java`
- [X] T069a [US3] Acrescentar o portão de latência da recuperação ao `NaoRevelaExistenciaTest` (V2, FR-019) — o terceiro endpoint público, e o terceiro a hashear antes da consulta ao canal

### Aplicativo

- [X] T070 [US3] Criar `TelaRecuperacao` usando `CampoCodigo`
- [X] T071 [US3] Exibir aviso permanente em `app/lib/features/autenticacao/presentation/widgets/aviso_antigolpe.dart` — o Memora **nunca** pede senha por telefone, mensagem ou e-mail (FR-023)
- [X] T072 [US3] Tratar código expirado em `app/lib/features/autenticacao/presentation/controladores/controlador_recuperacao.dart`, com caminho para solicitar outro
- [X] T073 [US3] Escrever teste de widget em `app/test/features/autenticacao/tela_recuperacao_test.dart`

---

## Phase 7: US4 — Sair da conta com segurança (P4)

**Meta**: sair sem procurar, com confirmação consciente e sem deixar rastro.

**Teste independente**: sair e verificar que nenhum dado pessoal permanece acessível.

- [X] T074 [US4] Implementar `POST /v1/auth/sair` revogando a sessão atual. **Exigiu acrescentar o campo `fam` ao JWT**: o `sub` identifica a pessoa, e uma pessoa tem várias sessões — sem ele não havia o que encerrar
- [X] T075 [US4] Adicionar a saída em `app/lib/features/autenticacao/presentation/telas/tela_perfil.dart`, a no máximo dois toques (FR-024)
- [X] T076 [US4] Usar `ConfirmacaoMemora` em `app/lib/features/autenticacao/presentation/telas/tela_perfil.dart` antes de encerrar (FR-025)
- [X] T077 [US4] Limpar dado pessoal e credencial em `app/lib/services/seguranca/limpeza_de_sessao.dart` (FR-026). **A contradição FR-012 × FR-026 foi decidida em 2026-09-08**: o identificador do último acesso **fica**, toda credencial vai embora. Ver o cabeçalho da classe
- [X] T078 [US4] Escrever teste em `app/test/features/autenticacao/saida_limpa_armazenamento_test.dart`

---

## Phase 8: Login social (D2)

> Depende da US1 e da US2 existirem.

> ⚠️ **A tabela `IDENTIDADE_EXTERNA` ainda não existe.** O
> [data-model.md](data-model.md) descreve **6** entidades, mas a T008 pede as
> "5 tabelas" e as T009-T013 criam 5 entidades — `IdentidadeExterna` ficou de
> fora, e ela só é usada aqui. Foi deliberado não criá-la na migration V1:
> tabela que nada usa é superfície sem valor, e migration do Flyway é
> acrescentável. **Esta fase precisa de uma migration `V2`** com
> `identidade_externa`, índice único em `(provedor, subject)`, e da entidade
> correspondente. Vale confirmar com a equipe se preferem antecipar isso.
>
> Junto vem a regra que hoje não tem como ser garantida: "senha nula exige ao
> menos uma identidade externa" (FR-053). Não pode virar `CHECK` porque depende
> de outra tabela — precisa ser verificada no domínio ao criar conta social.

- [ ] T079 Implementar `POST /v1/auth/social/{provedor}` validando assinatura, emissor, audiência e expiração do token (R6)
- [ ] T080 Implementar vinculação de contas em `backend/src/main/java/br/fatec/memora/autenticacao/dominio/VinculadorDeIdentidades.java`, sem duplicata e sem revelar existência prévia (FR-057)
- [ ] T081 Integrar Google e Facebook em `app/lib/services/identidade/`, por Authorization Code com PKCE em aba segura do sistema
- [ ] T082 Exibir aviso de saída em `app/lib/features/autenticacao/presentation/widgets/aviso_saida_do_app.dart`, antes do redirecionamento (FR-054)
- [ ] T083 Escrever teste do cenário V9 em `app/test/features/autenticacao/login_social_sem_webview_test.dart`

---

## Phase 9: Validação final

- [ ] T084 Executar V1 a V9 de `specs/001-autenticacao-acessivel/quickstart.md` de forma automatizada
- [ ] T085 Executar **V10** de `specs/001-autenticacao-acessivel/quickstart.md` — 5 pessoas de 65+ anos, sem instrução e sem ajuda
- [ ] T086 Verificar SC-001 a SC-010 de `specs/001-autenticacao-acessivel/spec.md` contra os resultados observados
- [ ] T087 Revisões obrigatórias conforme `.specify/memory/constitution.md`: código, UX, acessibilidade, performance, segurança e arquitetura
- [ ] T088 Atualizar [requisitos-atualizados.md](../../docs/referencia/requisitos-atualizados.md) com o que a implementação revelou

---

## Dependências

```
Setup (T001-T007)
   ↓
Foundational (T008-T032)   ← BLOQUEIA TUDO
   ↓
   ├── US1 (T033-T046)  ← MVP. Sozinha já entrega valor
   │      ↓
   │   US2 (T047-T056)  ← depende da US1 para existir conta
   │      ↓
   │   ├── US5 (T057-T065)  [P] com US3
   │   ├── US3 (T066-T073)  [P] com US5
   │   └── US4 (T074-T078)
   │          ↓
   │      Login social (T079-T083)
   ↓
Validação final (T084-T088)
```

---

## Escopo do MVP

**US1 sozinha já é um incremento entregável**: a pessoa cria a conta e entra no
aplicativo. Não é um produto completo, mas é demonstrável e testável com usuários
reais.

Ordem sugerida de entrega:

1. **T001-T032** — infraestrutura e segurança. Nenhuma tela ainda
2. **T033-T046** — US1, o MVP
3. **T047-T056** — US2, o caminho mais percorrido do produto
4. **T057-T065** — US5, que protege a autonomia
5. **T066-T078** — US3 e US4
6. **T079-T083** — login social
7. **T084-T088** — validação

---

## Oportunidades de paralelismo

| Bloco | Tarefas |
|---|---|
| Entidades do backend | T009 a T013 |
| Setup de projeto | T002, T003, T004 |
| Domínio do aplicativo | T028, T029 |
| US5 e US3 | podem ser desenvolvidas ao mesmo tempo |

**Backend e aplicativo podem avançar em paralelo dentro de cada história**, porque
o contrato OpenAPI é a fonte da verdade e o cliente é gerado a partir dele.

---

## Observações

- **T015 a T023 são o núcleo de segurança da feature.** São as tarefas em que um
  erro não gera bug, gera vítima. Nenhuma delas pode ser marcada como pronta sem
  o teste correspondente passando.
- **T085 não é opcional.** É o único item que nenhum teste automatizado substitui,
  e é portão de saída da feature.
- **T017 exige medição no ambiente real.** Parâmetro de Argon2 que parece forte no
  papel pode estar fraco na máquina onde roda.
