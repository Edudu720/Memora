---

description: "Task list — Hub e a assistente que ensina"
---

# Tasks: Hub e a assistente que ensina

**Input**: Documentos de design em `specs/003-hub-e-assistente/`

**Prerequisites**: [spec.md](spec.md) · [plan.md](plan.md) · [research.md](research.md) · [data-model.md](data-model.md) · [contracts/openapi.yaml](contracts/openapi.yaml) · [quickstart.md](quickstart.md)

**Tests**: **obrigatórios**. A Constituição exige revisão de segurança e acessibilidade, e o [quickstart.md](quickstart.md) define 12 cenários que são portão de saída da feature.

## Format: `[ID] [P?] [Story] Descrição`

- **[P]**: pode ser feito em paralelo (arquivos distintos, sem dependência)
- **[Story]**: a qual história de usuário a tarefa pertence

---

## ⚠️ A ordem desta lista tem um propósito

**O provedor de IA ainda não foi escolhido** (R2 do research), e as fases estão
ordenadas para que isso **não bloqueie nada**.

Tudo até a T053 — Hub, catálogos, o autorizador, a trilha, todas as telas, o
armazenamento local da conversa e os 12 cenários do quickstart — é construído e
testado contra `ClienteDaAssistenteSimulado`, com roteiros fixos. **A escolha do
provedor só aparece na fase 8**, e ela tem uma classe.

Isso vale inclusive para os portões de segurança: o H3, que é o portão central da
feature, testa que a sugestão do modelo não é autorização — e isso se prova
melhor com um cliente falso que sugere abrir o banco de propósito do que com um
modelo real que provavelmente não sugeriria.

---

## Regras que valem para todas as tarefas

1. **O Design System já existe.** Use `BotaoPrimario`, `Cartao`, `CartaoComAvatar`,
   `IlustracaoMemora`, `TextoComDestaque`, `ConfirmacaoMemora`, `CampoTexto`,
   `MensagemErro`, `Carregando`, `BarraSuperior`. **Nunca recrie um componente** —
   se faltar algo, ele entra na feature 002.
2. **Nenhum valor visual literal** fora dos tokens.
3. **Todo endpoint novo é autenticado e passa pela cadeia do Spring Security.**
   Ler o `subject` do JWT por conta própria transforma a sessão-chamariz em
   acesso (ver o aviso no [plan.md](plan.md)).
4. **A saída do modelo nunca autoriza nada.** Quem autoriza é o catálogo.
5. Toda validação de interface é **repetida no servidor**.

---

## Phase 1: Setup

- [X] T001 Criar a estrutura `backend/src/main/java/br/fatec/memora/assistente/{api,aplicacao,dominio,infra,seguranca}/`
- [X] T002 [P] Criar a estrutura `app/lib/features/hub/{domain,presentation}/` e `app/lib/features/assistente/{domain,data,presentation}/`
- [X] T003 [P] Acrescentar os textos da feature em `app/lib/l10n/textos_assistente.dart`, na voz da Memora

---

## Phase 2: Foundational

> **BLOQUEIA TODAS AS HISTÓRIAS.** Nenhuma tela ou endpoint antes disto.

### Banco e domínio

- [X] T004 Criar `backend/src/main/resources/db/migration/V4__assistente.sql` com `servico_conhecido` e `evento_da_assistente`, conforme [data-model.md](data-model.md)
- [X] T005 Na mesma migration, adicionar a restrição `CHECK` que exige `identificador_android IS NULL` quando `categoria = 'SENSIVEL'` — é a FR-041 escrita no banco, e não no código
- [X] T006 Na mesma migration, adicionar o gatilho de somente-inserção em `evento_da_assistente`, no molde de `tg_evento_somente_insercao`
- [X] T007 [P] Criar `dominio/CategoriaDoServico.java` com `SENSIVEL` e `COTIDIANO`, gravados em MAIÚSCULAS como os demais enums do projeto
- [X] T008 [P] Criar a entidade `dominio/ServicoConhecido.java`
- [X] T009 [P] Criar a entidade `dominio/EventoDaAssistente.java`, `@Immutable` e sem método que altere estado
- [X] T010 Criar os repositórios Spring Data em `infra/`, com os índices declarados em [data-model.md](data-model.md)
- [X] T011 Escrever `backend/src/test/java/br/fatec/memora/assistente/dominio/PortoesDoEsquemaDaAssistenteTest.java` provando, por SQL avulso, que o banco recusa `UPDATE` na trilha **e** recusa serviço `SENSIVEL` com pacote preenchido

### O portão central

- [X] T012 Criar `infra/ClienteDaAssistente.java` — a porta, com um método e nenhuma dependência de provedor
- [X] T013 Criar `infra/ClienteDaAssistenteSimulado.java`, com roteiros fixos e a capacidade de **sugerir uma ação arbitrária sob comando do teste** — sem isso o cenário H3 não tem como ser exercido
- [X] T014 Criar `aplicacao/AutorizadorDeAcao.java`: consulta o catálogo e só autoriza serviço existente, ativo e `COTIDIANO`. **A FR-022 mora aqui**
- [X] T015 Escrever `backend/src/test/java/br/fatec/memora/assistente/aplicacao/AutorizadorDeAcaoTest.java` cobrindo serviço sensível, inexistente, inativo e cotidiano
- [X] T016 Escrever o cenário **H3** em `backend/src/test/java/br/fatec/memora/assistente/api/SugestaoNaoEhAutorizacaoTest.java`: o simulado sugere abrir o banco, e a ação **não** chega ao aplicativo
- [X] T017 Quebrar o T014 de propósito — fazer o autorizador confiar na sugestão — e **confirmar que o T016 reprova**. Desfazer depois. Commitar antes de quebrar

### Contrato, persona e limite

- [X] T018 [P] Criar `infra/PersonaDaMemora.java` com o system prompt versionado: ensinar antes de executar (FR-014), um passo por vez (FR-008), nunca inventar caminho (FR-012), nunca pedir senha (FR-032)
- [X] T019 [P] Criar `seguranca/LimitePorConta.java` — teto diário de conversas, com estado no banco, no molde do `LimitadorTentativas`
- [X] T020 [P] Acrescentar os códigos de erro novos a `comum/CodigoDeErro.java`, com texto na voz da Memora
- [X] T021 Gerar o cliente Dart a partir de [contracts/openapi.yaml](contracts/openapi.yaml) para `app/pacotes/memora_api/`, com o script existente
  > **Adiada de propósito.** Gerar agora produziria um cliente para endpoints que ainda não existem, e o script aponta para o contrato da feature 001 — fundir os dois contratos é decisão de spec, não de implementação. Fica para quando os controladores da fase 4 existirem.
- [X] T022 [P] Criar `app/lib/features/assistente/domain/assistente.dart` — contrato, mensagem, orientação, passo e ação
- [X] T023 [P] Criar `app/lib/features/assistente/data/repositorio_assistente_simulado.dart`, para as telas serem construídas sem backend

---

## Phase 3: US1 — Chegar ao Hub e saber o que fazer (P1) 🎯 MVP

**Meta**: a pessoa entra na conta e chega a um lugar que ela reconhece como *o
lugar para onde eu sempre volto*.

**Teste independente**: entregar o aparelho a uma pessoa de 65+ recém-cadastrada,
sem instrução, e pedir que ela diga em voz alta o que cada porta faz.

- [X] T024 [P] [US1] Criar `app/lib/features/hub/domain/hub.dart` com as portas e o que cada uma abre
- [X] T025 [US1] Criar `app/lib/features/hub/presentation/telas/tela_hub.dart`, com nome escrito **e** ilustração em cada porta (FR-002)
- [X] T026 [US1] Fazer o Hub exibir **apenas** portas construídas (FR-003) — porta que não abre nada não aparece
- [X] T027 [US1] Substituir a `_TelaDentro` provisória de `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart` pelo Hub
- [X] T028 [US1] Garantir o caminho de volta ao Hub, sempre na mesma posição, em todas as telas da feature (FR-005)
- [X] T029 [P] [US1] Desenhar as ilustrações das portas em `app/assets/ilustracoes/`, no estilo já estabelecido
  > **Resolvida com ícone, não com ilustração.** O Hub reusa o casal no cabeçalho, e cada porta leva **ícone grande + rótulo + descrição** — que é o que a FR-002 pede (nome escrito **e** elemento visual). Cinco ilustrações distintas competiriam entre si numa tela cujo trabalho é ser lida rápido, e ícone com texto é mais legível a 200% de ampliação.
- [X] T030 [US1] Escrever o cenário **H1** em `app/test/features/hub/tela_hub_test.dart`: percorrer as portas e navegar para cada uma
- [X] T031 [US1] Quebrar o T026 — acrescentar uma porta *Planos* apontando para tela inexistente — e **confirmar que o T030 reprova**

---

## Phase 4: US2 — Pedir ajuda e aprender o caminho (P1)

**Meta**: a razão de o Memora existir. A pessoa pergunta com as próprias palavras
e aprende o caminho, um passo por vez.

**Teste independente**: realizar a tarefa guiada pela Memora e depois repeti-la
**sem** ela. A segunda tentativa é o teste.

- [X] T032 [US2] Criar `aplicacao/ServicoDeConversa.java`, montando persona + catálogo + histórico e transmitindo a resposta
- [X] T033 [US2] Criar `api/ControladorConversa.java` com `POST /v1/assistente/conversa`, respondendo por **SSE**
- [X] T034 [US2] Aplicar o `LimitePorConta` no controlador, respondendo `429` com espera e texto acolhedor
- [X] T035 [P] [US2] Criar `app/lib/features/assistente/data/conversa_local.dart` — a conversa no aparelho (FR-047)
  > **Decisão tomada: arquivo no diretório privado do aplicativo**, via `path_provider`. O cofre está descartado porque o V8 reprova se sobrar qualquer coisa lá; `SharedPreferences` é armazenamento comum, e a conversa é Confidencial. Apagada ao sair da conta (FR-048).
- [ ] T036 [P] [US2] Criar `app/lib/features/assistente/data/repositorio_assistente_api.dart`, consumindo o SSE
  > **Adiada junto com a T021.** Depende do cliente gerado, e gerá-lo agora produziria um cliente para endpoints que o servidor tem mas o contrato ainda não fundiu. As telas rodam contra o simulado até lá.
- [X] T037 [US2] Criar `app/lib/features/assistente/presentation/controladores/controlador_conversa.dart`, com o passo a passo e o estado de espera
- [X] T038 [US2] Criar `app/lib/features/assistente/presentation/telas/tela_conversa.dart`, com o aviso antigolpe permanente (FR-033) reusando o idioma da `TelaRecuperacao`
- [X] T039 [US2] Implementar a retomada de passo a passo interrompido (FR-049) e o apagar conversa (FR-050)
- [X] T040 [US2] Escrever o cenário **H2** em `app/test/features/assistente/tela_conversa_test.dart`: um passo por vez, e nenhuma oferta de executar no primeiro turno
- [X] T041 [US2] Quebrar o T037 — oferecer executar já na primeira resposta — e **confirmar que o T040 reprova**
- [X] T042 [US2] Escrever o cenário **H6** em `backend/src/test/java/br/fatec/memora/assistente/ConversaNaoPersisteTest.java`: varrer as tabelas procurando o texto das mensagens

---

## Phase 5: US5 — A Memora ensina o banco, mas não entra nele (P2)

**Meta**: a recusa **é** a funcionalidade. Quanto mais sensível o serviço, menos
a Memora toca nele.

**Teste independente**: pedir que ela abra o banco, de várias formas e
insistindo, e verificar que ela ensina e nunca abre.

- [X] T043 [US5] Criar `api/ControladorCatalogo.java` com `GET /v1/assistente/catalogo`
- [X] T044 [US5] Semear o catálogo na migration, separando serviços sensíveis de aplicativos cotidianos
  > **Lista definida em 2026-08-29, com dados de uso real.** Entre pessoas de 60+ no Brasil o WhatsApp tem 58,7% de penetração e o Instagram 26,3% (74,5% dos idosos já usam internet — IBGE 2025). Entram como **cotidianos**: WhatsApp, Facebook, Instagram, YouTube, Google Fotos e Telegram. Câmera, galeria e telefone ficaram de fora apesar do uso altíssimo — o pacote muda por fabricante, e abrir o aplicativo errado é pior que não abrir. Em **sensíveis**, só o **Gov.br** por decisão do Eduardo; banco, INSS e saúde entram em migrations próprias.
- [X] T045 [US5] Criar `app/lib/features/assistente/presentation/telas/tela_catalogo.dart`, **uma tela parametrizada** pela categoria, servindo às duas portas
- [X] T046 [US5] Deixar claro em cada item, antes do toque, se a Memora **ensina** ou **ensina e abre** (FR-045)
- [X] T047 [US5] Tratar aplicativo não instalado como ensinável, avisando a pessoa (FR-046)
- [X] T048 [US5] Escrever o cenário **H4** em `app/test/features/assistente/servico_sensivel_test.dart`: recusa idêntica sob insistência repetida

---

## Phase 6: US3 — Quando eu não consigo, a Memora faz por mim (P2)

**Meta**: dar saída digna a quem não conseguiu hoje, sem desfazer o Princípio VII.

**Teste independente**: declarar dificuldade e verificar que ela oferece,
confirma antes, executa, e depois mostra o caminho percorrido.

- [X] T049 [US3] Fazer o `ServicoDeConversa` declarar a ferramenta `abrir_aplicativo` e passar a sugestão pelo `AutorizadorDeAcao` antes de emitir o evento `acao`
- [X] T050 [US3] Criar `api/ControladorRegistro.java` com `POST /v1/assistente/acao`, **truncando `pedido_resumido` no servidor** — confiar o corte ao aparelho transformaria um campo de tabela imutável em texto livre
- [X] T051 [US3] Exibir a oferta com `ConfirmacaoMemora`, declarando o que será feito antes de qualquer coisa (FR-015)
- [X] T052 [US3] Fazer a recusa encerrar o assunto, sem repetir a oferta na mesma conversa (FR-016)
- [X] T053 [US3] Exibir o aviso de saída do Memora antes de abrir o outro aplicativo (FR-021), reusando o idioma da feature 001
- [X] T054 [US3] Abrir o aplicativo pelo Flutter após a confirmação, e registrar a execução
- [X] T055 [US3] Mostrar o caminho percorrido depois da execução (FR-019)
- [X] T056 [US3] Escrever os cenários **H7** e **H8** em `app/test/features/assistente/acao_confirmada_test.dart`
- [X] T057 [US3] Quebrar o T051 — abrir direto ao receber a ação autorizada — e **confirmar que o T056 reprova**

---

## Phase 7: US4 — Ver o que a Memora fez por mim (P3)

**Meta**: o log do Princípio VI serve à pessoa, e não só à equipe.

- [X] T058 [P] [US4] Criar `aplicacao/ServicoDeRegistro.java` e `GET /v1/assistente/registro`
- [X] T059 [US4] Criar `app/lib/features/assistente/presentation/telas/tela_registro.dart`, em linguagem comum
- [X] T060 [US4] Escrever o cenário **H9** em `app/test/features/assistente/tela_registro_test.dart`: ação executada aparece, tarefa só ensinada não

---

## Phase 8: A fatia do provedor de IA

> **A única fase que depende da escolha da equipe** (R2). Tudo acima já funciona
> e é testável sem ela.

- [X] T061 Escolher o provedor e o modelo contra os critérios da **R2** do [research.md](research.md), rodando as mesmas conversas reais nos candidatos. **Decisão da equipe** — **Gemini gratuito (`gemini-3.8-flash`), decisão do Henrique em 2026-10-02, ver ADR-002**; a comparação com conversas reais não foi feita, e a escolha viola a FR-051 (a T086 segue aberta)
- [X] T062 Registrar a escolha em `docs/architecture/adr-002-provedor-de-ia.md`, com as alternativas avaliadas e o que faria mudar de ideia
- [X] T063 Criar o adaptador em `infra/`, implementando `ClienteDaAssistente` — a **única** classe que importa o SDK do provedor — feito por REST direto, sem SDK (Jackson 2 do SDK x Jackson 3 do Spring Boot 4; ver ADR-002)
- [X] T064 Configurar a chave por variável de ambiente, **sem padrão no repositório**, e fazer o perfil `producao` não subir sem ela (R8)
- [X] T065 Aplicar cache do bloco estável — persona e catálogo antes do histórico — e o teto de turnos por conversa (R3)
- [X] T066 Escrever o cenário **H5** em `backend/src/test/java/br/fatec/memora/assistente/InjecaoNaoViraAcaoTest.java`, com texto de golpe colado no chat
- [X] T067 Escrever o cenário **H10**, do limite diário, em `backend/src/test/java/br/fatec/memora/assistente/LimiteDeConversasTest.java`
- [ ] T068 Medir custo e latência reais de uma conversa típica e registrar no [research.md](research.md)

---

## Phase 9: Validação final

- [X] T069 Executar os cenários **H1 a H11** de [quickstart.md](quickstart.md) de forma automatizada
- [X] T070 [P] Escrever os testes de acessibilidade em `app/test/acessibilidade/` para as telas do Hub, da conversa, do catálogo e do registro (FR-026 a FR-030)
- [ ] T071 Executar **H12** — 5 pessoas de 65+ anos, sem instrução e sem ajuda, **incluindo o passo em que repetem a tarefa sozinhas**
- [ ] T072 Verificar SC-001 a SC-010 de [spec.md](spec.md) contra os resultados observados
- [ ] T073 Revisões obrigatórias conforme `.specify/memory/constitution.md`: código, UX, acessibilidade, performance, segurança e arquitetura
- [ ] T074 Atualizar `CLAUDE.md` com a passagem de contexto da feature

---

## Dependências

```
Phase 1 (setup)
   └─▶ Phase 2 (foundational) ── BLOQUEIA TUDO
          ├─▶ Phase 3 (US1 — Hub) 🎯 MVP
          ├─▶ Phase 4 (US2 — ensinar)      ┐
          ├─▶ Phase 5 (US5 — recusar)      ├─ podem ir em paralelo
          ├─▶ Phase 6 (US3 — executar)     │  depois da Phase 4
          └─▶ Phase 7 (US4 — registro)     ┘
                 └─▶ Phase 8 (provedor) ── depende da escolha da equipe
                        └─▶ Phase 9 (validação)
```

**A Phase 6 depende da Phase 5**: executar só faz sentido depois de o catálogo
existir, porque é o catálogo que autoriza.

---

## Escopo do MVP

**US1 sozinha já é um incremento entregável**: a pessoa entra e chega a um lugar
com sentido, em vez da tela provisória que diz *"Você está dentro"*.

Ordem sugerida de entrega:

1. **T001-T023** — fundação, com o portão da FR-022 já testado
2. **T024-T031** — US1, o MVP
3. **T032-T042** — US2, a razão de o produto existir
4. **T043-T048** — US5, a recusa que protege
5. **T049-T060** — US3 e US4
6. **T061-T068** — a fatia do provedor
7. **T069-T074** — validação

---

## Oportunidades de paralelismo

| Bloco | Tarefas |
|---|---|
| Entidades do backend | T007, T008, T009 |
| Domínio e dados do aplicativo | T022, T023 |
| Persona, limite e códigos de erro | T018, T019, T020 |
| Ilustrações do Hub | T029, junto com o resto da US1 |
| US5 e US4 | podem ser desenvolvidas ao mesmo tempo |

**Backend e aplicativo avançam em paralelo dentro de cada história**, porque o
contrato OpenAPI é a fonte da verdade e o cliente é gerado a partir dele.

---

## Observações

- **T014 a T017 são o núcleo de segurança da feature.** O `AutorizadorDeAcao` é
  o que separa um assistente de um vetor. A T017 não é opcional: foi a **ausência**
  desse hábito que deixou a guarda de conta desativada entrar furada na PR #15.
- **T005 escreve a FR-041 no banco.** Serviço sensível não tem como ser aberto
  porque falta o dado necessário para abri-lo. Quem mudar a categoria no futuro
  esbarra na restrição antes de esbarrar num teste.
- **T044 depende de decisão da equipe** (pendência 2 do research): quais
  aplicativos entram como cotidianos e quais serviços como sensíveis.
- **T061 é decisão da equipe, e não escolha por preço de tabela.** Um passo a
  passo inventado leva a pessoa a tocar no que não pretendia.
- **T071 não é opcional.** É o único item que nenhum teste automatizado
  substitui, e o passo em que a pessoa repete a tarefa **sozinha** é a feature
  inteira medida em número.

---

## Phase 10: Convergence

> Gerada por `/speckit-converge` em 2026-09-30, depois da clarificação que
> acrescentou as FR-051 a FR-055. Cada tarefa aponta a origem e o tipo de lacuna.
> **As tarefas não saem da ordem de gravidade**: as HIGH vêm primeiro.

- [X] T075 Fazer o `LimitePorConta` contar **conversas**, não turnos: hoje `ServicoDeConversa.conversar` registra um uso a cada mensagem, e o teto de 20 vira 20 mensagens por dia. Definir o que inicia uma conversa (primeiro turno sem histórico, ou depois de um intervalo) e ajustar o H10 em `LimiteDeConversasTest.java` per FR-053 (contradicts)
- [X] T076 Reescrever a regra de serviço sensível em `infra/PersonaDaMemora.java`: hoje ela diz "nunca abre **nem ensina a acessar**" e "você só ENSINA" na mesma frase. Deve dizer sem ambiguidade que ensina o caminho e nunca abre, e ensinar é exatamente o que a US5 pede per US5/AC1, FR-042 (contradicts)
- [X] T077 Fazer cada item do catálogo levar à conversa já com o pedido de ensinar aquele serviço, preenchendo `aoEscolher` em `fluxo_autenticacao.dart`; trocar o estado vazio "Em breve…" de `tela_catalogo.dart`, que o H1 proíbe. Hoje todo item é um botão desabilitado — a porta que não abre da FR-003 per FR-003, FR-042, FR-043, FR-044 (contradicts)
- [X] T078 Encerrar a espera em 30 s no `ControladorConversa` do aplicativo, com texto que diz que o problema é a conexão; fazer `tentarNovamente()` **reenviar** `_ultimoPedido` em vez de só limpar o estado; corrigir `TextosAssistente.semConexao`, que promete "o que você escreveu continua aqui" com o rascunho já apagado; alinhar o `TIMEOUT_MS` de 120 s do servidor. Com teste de widget per FR-052, SC-007 (missing)
- [ ] T079 Filtrar senha, código e sequência longa de dígitos do `pedido_resumido` **no servidor**, antes de gravar em `evento_da_assistente`, e estender o H9 para reprovar se "meu código é 123456" chegar ao registro per FR-036 (partial)
- [ ] T080 Implementar a retenção da trilha: expurgo aos 12 meses e resumo do pedido apagado aos 90 dias. **Exige decisão de plano antes**, porque `tg_evento_assistente_somente_insercao` recusa todo `UPDATE`: mover o resumo para tabela própria, que aceite `DELETE` (recomendado — o gatilho continua sem exceção), ou abrir exceção para anular só aquela coluna. Registrar a escolha no `data-model.md` e testar em `PortoesDoEsquemaDaAssistenteTest` per FR-055 (missing)
- [ ] T081 Fazer `TelaRegistro` dizer, em linguagem comum, que o pedido de uma ação com mais de 90 dias já foi apagado, em vez de exibir só "Abri o X para você" per FR-055, FR-024 (missing)
- [ ] T082 Apagar do aparelho as mensagens com mais de 30 dias em `data/conversa_local.dart`, usando o `momento` que a mensagem já guarda, com teste de unidade per FR-054 (missing)
- [ ] T083 Impedir de forma determinística que a oferta de executar volte depois de recusada na mesma conversa — marca no `ControladorConversa` e a recusa entrando no histórico enviado ao servidor —, e testar que um segundo "não consegui" não produz oferta per FR-016, US3/AC2 (partial)
- [ ] T084 Fazer a Memora dizer que é um programa, uma vez por conversa e sem repetir: instrução na `PersonaDaMemora` e texto no convite inicial da `TelaConversa` per FR-013 (missing)
- [ ] T085 Acrescentar à `TelaConversa` um controle visível para apagar a conversa e recomeçar, ligado a `apagarConversa()`, com confirmação — hoje o método só é chamado por teste per FR-050, FR-049 (missing)
- [X] T086 Exigir na ADR-002 (T062) a evidência da FR-051 — link para o contrato ou os termos do provedor que proíbem treino e limitam a retenção a 30 dias — e fazer da ausência dela um bloqueio para a primeira conversa real per FR-051 (missing) — **segue aberta**: a ADR-002 existe e registra que o nível gratuito do Gemini não tem essa evidência; a primeira conversa real continua bloqueada — **encerrada pela T105** em 2026-10-03: a FR-051 revista dispensa a evidência enquanto o serviço for do tipo gratuito (Emenda 1); ela volta a valer na troca de serviço
- [ ] T087 Acrescentar à `PersonaDaMemora` a recusa explicada de pedido financeiro ou irreversível ("transfere R$ 500 para o Carlos"), sem contorno; criar o roteiro no simulado e um teste per FR-018, FR-031, FR-037, US3/AC4 (partial)
- [ ] T088 Decidir se `ACAO_RECUSADA` pode guardar o texto cru do chat em `pedido_resumido`: hoje guarda (`ServicoDeConversa.java:125`), o que põe no servidor conteúdo de conversa — inclusive texto de golpe colado — fora do caso que a FR-023 justifica. Justificar na spec ou deixar de gravar, e ajustar `ConversaNaoPersisteTest` per FR-047 (contradicts)
- [ ] T089 Verificar se o aplicativo está instalado **antes** de marcá-lo como "ensina e abre" no catálogo e antes de oferecer abri-lo; hoje isso só é descoberto depois da confirmação per FR-046 (partial)
- [ ] T090 Dar saída, na persona e no simulado, para "não achei o botão" quando a tela do outro aplicativo mudou, sem culpar a pessoa e sem cair direto na oferta de abrir per spec Edge Cases (missing)
- [ ] T091 Testar o Hub **real** — as portas de `_portasConstruidas()` — cabendo sem rolagem no texto padrão, e fazer o H1 reprovar com a quebra "Planos" que o quickstart descreve; hoje ele usa portas sintéticas e não pegaria a quebra per FR-004, FR-003 (partial)
- [ ] T092 Calcular o dia do `LimitePorConta` no fuso de São Paulo: com `Clock.systemUTC()` o dia vira às 21h, e quem ouve "vamos continuar amanhã" às 20h é liberado uma hora depois per FR-053 (partial)
- [ ] T093 Verificar com o modelo real, na T069, que a recusa a serviço sensível é **idêntica** sob insistência — o H4 de hoje só prova o simulado, que devolve texto fixo per FR-038 (partial)
- [ ] T094 [P] Testar que o "Voltar" está na mesma posição nas telas de conversa, catálogo, registro e aparência, e acrescentar verificação de contraste por tela em `app/test/acessibilidade/` per FR-005, SC-008 (partial)
- [ ] T095 [P] Registrar duas decisões que o código tomou sem a spec: a porta "Ajuda" da US1/AC1 não existe (e `portaAjuda`, `descricaoAjuda` e `vocePodeFazerSozinha` estão sem uso), e o H10 responde por evento SSE com `200` em vez de `429` com espera — corrigir quickstart ou código per US1/AC1, quickstart H10 (unrequested)

### Achados da revisão das PRs #31-#34 que não bloquearam o merge (2026-10-01)

> Os que bloqueavam foram corrigidos na PR de revisão. Estes ficaram porque
> pedem decisão, ou porque o custo hoje é baixo.

- [ ] T096 Cancelar de verdade a requisição SSE quando a espera de 30 s vence (T078): hoje o `ControladorConversa` só descarta a resposta, a conexão continua aberta e o servidor segue gerando — e, com o provedor real, cobrando. Um "tentar de novo" abre um segundo turno no servidor per FR-052, R7
- [ ] T097 Escrever o H3/H5 **de ponta a ponta pelo `ServicoDeConversa`**: hoje os dois chamam `AutorizadorDeAcao.autorizar` direto, e um `ServicoDeConversa` que deixasse de chamar o autorizador não reprovaria nenhum dos dois. Usar um serviço sensível **do catálogo** (hoje o H5 usa um pacote que não existe, e a camada `podeSerAberto()` nunca é exercida), e fazer as quatro variações de texto colado deixarem de ser o mesmo teste ou admitir no comentário que são
- [ ] T098 Decidir se a FR-027 ("reduzir movimento") vale para transição de rota, diálogo e folha inferior. O portão do V9 só vê `duration:` em `app/lib/`, e as transições de `MaterialPageRoute`, `showDialog` e `showModalBottomSheet` são configuráveis (`PageTransitionsTheme`, `transitionDuration`) — não são "do Material, fora do nosso alcance" como o texto do V9 diz. **Decisão de spec**
- [ ] T099 Reduzir o pool do Hikari nos testes (`spring.datasource.hikari.maximum-pool-size`/`minimum-idle`) em vez de depender de `max_connections=200`: com 20 conexões por contexto, o limite volta com uns cinco contextos novos

---

## Phase 11: Convergence

> Gerada por `/speckit-converge` em 2026-10-03, depois da clarificação que
> reescreveu a FR-051 e acrescentou as FR-056 e FR-057. Avaliou a fundo só o
> que a clarificação mudou; os demais requisitos seguem cobertos pelas tarefas
> abertas da fase 10. A T036 (repositório real da assistente) continua adiada e
> **não** foi duplicada — a T103 e a T104 dizem o que ela precisa trazer.

- [X] T100 **CRITICAL** — Resolver o conflito entre a FR-051 revista e o Princípio I, que é INEGOCIÁVEL e só admite **emenda formal com aprovação unânime da equipe** (Governança da constituição, hoje v1.0.0). Ou a equipe — Eduardo Juncker, Eduardo Trevisan e Henrique — aprova por escrito uma emenda que permita aceitar o risco do provedor gratuito, com justificativa e versão nova da constituição (`/speckit-constitution`); ou, até haver provedor com as garantias da FR-051 original, nenhuma conversa de pessoa de fora da equipe é enviada ao provedor, a T071 incluída. Sem uma das duas, a T101 e a T102 não autorizam a T071 per Constitution I, FR-051 (contradicts) — **feita**: Emenda 1 ao Princípio I, constituição v1.1.0, aprovação unânime registrada em 2026-10-03
- [X] T101 Acrescentar à `TelaConversa` o aviso de privacidade da FR-051 — o que for escrito é lido por um serviço de fora do Memora; não escreva senha, documento, endereço nem dado de saúde ou de dinheiro —, junto ao aviso antigolpe e com a mesma permanência (encolhe e não some, FR-002a da 004). Texto em `l10n/textos_assistente.dart`; teste que reprova se o aviso sumir ou perder qualquer um dos quatro tipos de dado; rodar na matriz de `aparelhos.dart` per FR-051 (missing)
- [X] T102 Pedir consentimento antes da primeira mensagem no aparelho: explicar em linguagem comum que a conversa é lida por um serviço de fora e só liberar o envio depois de a pessoa dizer que entendeu. Quem não aceitar continua com Hub, catálogos e registro, sem a conversa. Decidir no `plan.md` onde o aceite fica e se ele sobrevive à saída da conta (`LimpezaDeSessao`). Portão: teste que prova que o `RepositorioAssistente` **não é chamado** antes do aceite, quebrado de propósito; acrescentar o cenário ao `quickstart.md` per FR-051 (missing)
- [X] T103 Distinguir provedor indisponível de limite diário e de conexão: novo valor em `FalhaDaAssistente` (`assistenteIndisponivel`), texto próprio em `TextosAssistente` (dificuldade da Memora, não da pessoa), roteiro no simulado sob comando, e o `ControladorConversa` oferecendo "tentar de novo" **só** para falha passageira — nunca para `limiteDeConversas`, que diz "amanhã". Registrar na T036 o mapeamento do `codigo` do evento `erro`: `LIMITE_DE_CONVERSAS`→`limiteDeConversas`, `ASSISTENTE_INDISPONIVEL`→`assistenteIndisponivel`, `ERRO_INESPERADO`→`inesperada`. Teste de widget para cada um per FR-057, contracts/openapi.yaml `EventoDaConversa` (missing)
- [X] T104 Impedir que a conversa quebre por tamanho: hoje o aplicativo envia `_mensagens` inteiras (`controlador_conversa.dart:180`) e o servidor recusa mais de 40 itens com `400` (`ControladorConversa.java:86`, `@Size(max = 40)`) — ao ligar a T036, a conversa morre depois de 40 mensagens. O aparelho passa a enviar só o recorte recente, dentro do limite do contrato, e guarda tudo. Definir no `data-model.md` a unidade "turno" — o servidor conta **mensagem** (`TURNOS_NO_PEDIDO = 20` são 10 trocas) e a FR-053 conta turnos da pessoa — e alinhar FR-056, `TURNOS_NO_PEDIDO` e a contagem de conversas. Teste com 50 mensagens que continua respondendo per FR-056 (partial) — **feita**, com uma ressalva: a `ConversaLocal` ainda guarda em disco só as 40 últimas mensagens (`turnosGuardados = 40`), então ao reabrir o app as mais antigas não voltam, contra o "guardados e visíveis" da FR-056. Tirar o teto exige a limpeza de 30 dias da **T082** antes, senão a conversa cresce sem limite — resolver as duas juntas
- [X] T105 Atualizar a ADR-002 e o aviso de subida para a FR-051 revista: status de "violação conhecida" para "risco aceito pela FR-051 de 2026-10-03" (condicionado à T100), e o WARN de `ConfiguracaoDoProvedorDeIa.java:70`, que ainda diz "a FR-051 NÃO está cumprida". Fechar a T086 apontando para esta tarefa — a evidência que ela pede deixou de ser exigida enquanto o serviço for do tipo gratuito per FR-051, T086 (partial)
- [X] T106 Remover `AssistenteFalhou.tentarNovamenteEmSegundos`, ou justificá-lo: o contrato não tem campo de espera, e o limite diário diz "amanhã" em vez de um prazo per contracts/openapi.yaml, FR-053 (unrequested)

## Phase 12: Convergence

> Gerada por `/speckit-converge` em 2026-10-09, depois da clarificação que
> destravou a T036 (contrato fundido, conversa lida à mão, renovação em
> silêncio, uma escolha só de servidor). Avaliou a fundo só o que a
> clarificação mudou. **A T021 e a T036 deixam de estar adiadas** quando a T107
> fechar, e não foram duplicadas: as tarefas abaixo dizem o que elas precisam
> trazer.

- [X] T107 Fundir os caminhos e esquemas da assistente (`/assistente/conversa`, `/assistente/acao`, `/assistente/catalogo`, `/assistente/registro`, `EventoDaConversa`, `AcaoAutorizada` e o resto) no `specs/001-autenticacao-acessivel/contracts/openapi.yaml`, mantendo as tags ASCII `Assistente` e `Catalogo`; tirar a resposta `429` de `/assistente/conversa`, que contradiz o "nunca 429" do evento `erro`; reduzir o `contracts/openapi.yaml` desta pasta a ponteiro para o da 001. Depois, a T021 gera o pacote único por `gerar_cliente_api.ps1` per Dependências 2026-10-09, clarificação 2026-10-03 (missing)
- [ ] T108 Renovar a sessão em silêncio diante de `401` e reenviar o pedido **uma vez**, num ponto só da camada `data/` usado pela conversa, pelos catálogos, pelo registro e pela ação. As renovações MUST ser **em série**: duas em paralelo com o mesmo refresh disparam a detecção de reuso (V3) e derrubam a família inteira. Só a renovação recusada vira `FalhaDaAssistente.sessaoExpirada` → entrada. Testes: 401→renova→sucesso; renovação recusada→`sessaoExpirada`; nunca mais de um reenvio; duas chamadas simultâneas com 401 → **uma** renovação per Edge Cases 2026-10-09, FR-017 da 001 (missing)
- [ ] T109 Ligar a assistente ao servidor pela mesma escolha da conta: com `MEMORA_SERVIDOR_REAL=true`, a `Composicao` monta o `RepositorioAssistenteApi` da T036, e o cabeçalho "sempre simulada" de `services/ambiente/composicao.dart` sai. Teste que reprova se a composição real devolver o simulado per Dependências 2026-10-09 (contradicts)
- [ ] T110 [P] Prender o leitor de SSE escrito à mão (T036) ao contrato: teste que lê `EventoDaConversa` do `openapi.yaml` fundido e confere cada `tipo` (`texto`, `acao`, `fim`, `erro`) e campo (`trecho`, `acao`, `codigo`, `mensagem`) que o leitor interpreta, e que mapeia os três valores de `codigo` para `FalhaDaAssistente`; provar quebrando, renomeando um `tipo` no contrato per Dependências 2026-10-09, FR-052, FR-057 (partial)
