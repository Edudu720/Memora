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
- [ ] T021 Gerar o cliente Dart a partir de [contracts/openapi.yaml](contracts/openapi.yaml) para `app/pacotes/memora_api/`, com o script existente
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

- [ ] T043 [US5] Criar `api/ControladorCatalogo.java` com `GET /v1/assistente/catalogo`
- [ ] T044 [US5] Semear o catálogo na migration, separando serviços sensíveis de aplicativos cotidianos — **depende da pendência 2 do research**
- [ ] T045 [US5] Criar `app/lib/features/assistente/presentation/telas/tela_catalogo.dart`, **uma tela parametrizada** pela categoria, servindo às duas portas
- [ ] T046 [US5] Deixar claro em cada item, antes do toque, se a Memora **ensina** ou **ensina e abre** (FR-045)
- [ ] T047 [US5] Tratar aplicativo não instalado como ensinável, avisando a pessoa (FR-046)
- [ ] T048 [US5] Escrever o cenário **H4** em `app/test/features/assistente/servico_sensivel_test.dart`: recusa idêntica sob insistência repetida

---

## Phase 6: US3 — Quando eu não consigo, a Memora faz por mim (P2)

**Meta**: dar saída digna a quem não conseguiu hoje, sem desfazer o Princípio VII.

**Teste independente**: declarar dificuldade e verificar que ela oferece,
confirma antes, executa, e depois mostra o caminho percorrido.

- [ ] T049 [US3] Fazer o `ServicoDeConversa` declarar a ferramenta `abrir_aplicativo` e passar a sugestão pelo `AutorizadorDeAcao` antes de emitir o evento `acao`
- [ ] T050 [US3] Criar `api/ControladorRegistro.java` com `POST /v1/assistente/acao`, **truncando `pedido_resumido` no servidor** — confiar o corte ao aparelho transformaria um campo de tabela imutável em texto livre
- [ ] T051 [US3] Exibir a oferta com `ConfirmacaoMemora`, declarando o que será feito antes de qualquer coisa (FR-015)
- [ ] T052 [US3] Fazer a recusa encerrar o assunto, sem repetir a oferta na mesma conversa (FR-016)
- [ ] T053 [US3] Exibir o aviso de saída do Memora antes de abrir o outro aplicativo (FR-021), reusando o idioma da feature 001
- [ ] T054 [US3] Abrir o aplicativo pelo Flutter após a confirmação, e registrar a execução
- [ ] T055 [US3] Mostrar o caminho percorrido depois da execução (FR-019)
- [ ] T056 [US3] Escrever os cenários **H7** e **H8** em `app/test/features/assistente/acao_confirmada_test.dart`
- [ ] T057 [US3] Quebrar o T051 — abrir direto ao receber a ação autorizada — e **confirmar que o T056 reprova**

---

## Phase 7: US4 — Ver o que a Memora fez por mim (P3)

**Meta**: o log do Princípio VI serve à pessoa, e não só à equipe.

- [ ] T058 [P] [US4] Criar `aplicacao/ServicoDeRegistro.java` e `GET /v1/assistente/registro`
- [ ] T059 [US4] Criar `app/lib/features/assistente/presentation/telas/tela_registro.dart`, em linguagem comum
- [ ] T060 [US4] Escrever o cenário **H9** em `app/test/features/assistente/tela_registro_test.dart`: ação executada aparece, tarefa só ensinada não

---

## Phase 8: A fatia do provedor de IA

> **A única fase que depende da escolha da equipe** (R2). Tudo acima já funciona
> e é testável sem ela.

- [ ] T061 Escolher o provedor e o modelo contra os critérios da **R2** do [research.md](research.md), rodando as mesmas conversas reais nos candidatos. **Decisão da equipe**
- [ ] T062 Registrar a escolha em `docs/architecture/adr-002-provedor-de-ia.md`, com as alternativas avaliadas e o que faria mudar de ideia
- [ ] T063 Criar o adaptador em `infra/`, implementando `ClienteDaAssistente` — a **única** classe que importa o SDK do provedor
- [ ] T064 Configurar a chave por variável de ambiente, **sem padrão no repositório**, e fazer o perfil `producao` não subir sem ela (R8)
- [ ] T065 Aplicar cache do bloco estável — persona e catálogo antes do histórico — e o teto de turnos por conversa (R3)
- [ ] T066 Escrever o cenário **H5** em `backend/src/test/java/br/fatec/memora/assistente/InjecaoNaoViraAcaoTest.java`, com texto de golpe colado no chat
- [ ] T067 Escrever o cenário **H10**, do limite diário, em `backend/src/test/java/br/fatec/memora/assistente/LimiteDeConversasTest.java`
- [ ] T068 Medir custo e latência reais de uma conversa típica e registrar no [research.md](research.md)

---

## Phase 9: Validação final

- [ ] T069 Executar os cenários **H1 a H11** de [quickstart.md](quickstart.md) de forma automatizada
- [ ] T070 [P] Escrever os testes de acessibilidade em `app/test/acessibilidade/` para as telas do Hub, da conversa, do catálogo e do registro (FR-026 a FR-030)
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
