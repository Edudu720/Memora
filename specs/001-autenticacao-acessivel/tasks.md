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

- [ ] T001 Criar o projeto Spring Boot em `backend/`, pacote `br.fatec.memora`, com Java 21
- [ ] T002 [P] Configurar `backend/pom.xml` com Spring Web, Spring Security, Spring Data JPA, PostgreSQL, BouncyCastle, Bucket4j, springdoc-openapi e Testcontainers
- [ ] T003 [P] Criar `docker-compose.yml` na raiz com PostgreSQL 16 para desenvolvimento
- [ ] T004 [P] Adicionar `.gitignore` do Java em `backend/`
- [ ] T005 Configurar geração do cliente Dart a partir de `specs/001-autenticacao-acessivel/contracts/openapi.yaml` para `app/lib/services/api/`, com script reproduzível
- [ ] T006 Criar a estrutura `app/lib/features/autenticacao/{data,domain,presentation}/`
- [ ] T007 Estender `.github/workflows/verificacao.yml` com job de build e teste do backend

---

## Phase 2: Foundational

> **BLOQUEIA TODAS AS HISTÓRIAS.** Nenhuma tela ou endpoint antes disto.

### Banco e entidades

- [ ] T008 Criar migration inicial em `backend/src/main/resources/db/migration/` com as 5 tabelas de [data-model.md](data-model.md), usando UUID como chave
- [ ] T009 [P] Criar entidade `PessoaUsuaria` em `backend/src/main/java/br/fatec/memora/autenticacao/dominio/`
- [ ] T010 [P] Criar entidade `CanalContato` com unicidade de `(tipo, valor)`
- [ ] T011 [P] Criar entidade `Sessao` com `familiaId` e `substituidaPor`
- [ ] T012 [P] Criar entidade `CodigoVerificacao`
- [ ] T013 [P] Criar entidade `EventoAutenticacao`, somente inserção
- [ ] T014 Criar os repositórios Spring Data com os índices de [data-model.md](data-model.md)

### Segurança — o núcleo da feature

- [ ] T015 Configurar `Argon2PasswordEncoder` em `backend/src/main/java/br/fatec/memora/autenticacao/seguranca/` com **19456 KiB de memória, 2 iterações, paralelismo 1** — os padrões do Spring usam 16 MiB, abaixo do mínimo OWASP (R1)
- [ ] T016 Escrever teste que **falha** se os parâmetros do Argon2 ficarem abaixo do mínimo OWASP
- [ ] T017 Medir o tempo de hash no ambiente alvo e registrar em `research.md`; se ficar abaixo de ~250 ms, aumentar a memória
- [ ] T018 Implementar emissão de token de acesso (15 min) e refresh opaco em `seguranca/`
- [ ] T019 Implementar **rotação com detecção de reuso**: refresh já usado revoga toda a `familiaId` e registra `reuso_token_detectado` (R2)
- [ ] T020 Escrever teste do cenário V3 do [quickstart.md](quickstart.md) — reusar token antigo derruba a família inteira
- [ ] T021 Implementar rate limiting em duas camadas com Bucket4j, com estado fora da memória local (R4)
- [ ] T022 Implementar comparação em **tempo constante** executando hash fictício quando a conta não existe (R3)
- [ ] T023 Escrever teste que mede a latência de conta existente contra inexistente e falha se a diferença for observável

### Contrato e erros

- [ ] T024 Implementar o esquema `Erro` de [contracts/openapi.yaml](contracts/openapi.yaml) com tratamento global, sem stack trace nem detalhe interno (FR-041)
- [ ] T025 [P] Implementar registro de `EventoAutenticacao` para todos os tipos, sem dado sensível (FR-039, FR-040)
- [ ] T026 [P] Adicionar Trace ID e Request ID em toda resposta
- [ ] T027 Gerar o cliente Dart e verificar que ele compila contra o contrato

### Aplicativo — base da feature

- [ ] T028 [P] Criar entidades de domínio em `app/lib/features/autenticacao/domain/`
- [ ] T029 [P] Criar `RepositorioAutenticacao` (interface) em `domain/`
- [ ] T030 Implementar `RepositorioAutenticacaoApi` em `data/`, sobre o cliente gerado
- [ ] T031 Implementar armazenamento de credenciais com `flutter_secure_storage` em `app/lib/services/seguranca/` — **nunca** `SharedPreferences`
- [ ] T032 Escrever teste do cenário V8 — nenhuma credencial localizável em armazenamento comum

---

## Phase 3: US1 — Criar minha conta e começar a usar (P1)

**Meta**: a pessoa cria a conta e **já entra no aplicativo**, sem passar pelo login.

**Teste independente**: entregar o app a alguém de 65+ anos, sem instrução, e observar se conclui o cadastro sozinha.

### Backend

- [ ] T033 [US1] Implementar `POST /v1/auth/cadastro` em `autenticacao/api/`, devolvendo sessão iniciada (FR-009)
- [ ] T034 [US1] Implementar política de senha priorizando **comprimento** e recusando senhas comprometidas (FR-042)
- [ ] T035 [US1] Garantir resposta `201` idêntica quando o canal já existe, sem revelar (FR-010)
- [ ] T036 [US1] Escrever teste do cenário V2 — nenhuma resposta revela existência de conta
- [ ] T037 [US1] Implementar normalização do identificador: minúsculas, sem espaços

### Aplicativo

- [ ] T038 [P] [US1] Criar `TelaBoasVindas` em `presentation/telas/` — **uma única** ação principal, nenhuma decisão
- [ ] T039 [US1] Criar `ControladorCadastro` em `presentation/controladores/`, com estados vazio, carregando, erro e sucesso
- [ ] T040 [US1] Criar `TelaCadastro` usando `CampoTexto`, `CampoSenha` e `BotaoPrimario` do Design System
- [ ] T041 [US1] Implementar `textoAjuda` em cada campo explicando **para que o dado serve** (FR-004)
- [ ] T042 [US1] Implementar validação ao sair de cada campo, preservando o que já foi digitado em caso de erro (FR-005, FR-006)
- [ ] T043 [US1] Exibir as regras de senha **antes** de a pessoa digitar, com atendimento em tempo real (FR-008)
- [ ] T044 [US1] Tratar toque duplo no envio para não criar conta duplicada
- [ ] T045 [US1] Escrever teste de widget do fluxo completo de cadastro
- [ ] T046 [US1] Escrever teste de acessibilidade da tela de cadastro: contraste, alvo de toque, escala 2.0 e leitor de tela

---

## Phase 4: US2 — Voltar ao aplicativo depois (P2)

**Meta**: reabrir o app e continuar conectada, sem digitar nada.

**Teste independente**: fechar e reabrir após um cadastro e contar quantas ações são necessárias.

### Backend

- [ ] T047 [US2] Implementar `POST /v1/auth/entrar`, aceitando **qualquer canal verificado** (FR-051)
- [ ] T048 [US2] Implementar `POST /v1/auth/sessao/renovar` com a rotação de T019
- [ ] T049 [US2] Implementar bloqueio progressivo — 1, 5, 15, 60 min — após 5 falhas (FR-014)
- [ ] T050 [US2] Escrever teste do cenário V6 — bloqueio progressivo devolve `tentar_novamente_em_segundos`

### Aplicativo

- [ ] T051 [US2] Criar `ControladorLogin` com renovação automática de sessão
- [ ] T052 [US2] Criar `TelaLogin` usando os componentes do Design System
- [ ] T053 [US2] Pré-preencher o identificador do último acesso neste aparelho (FR-012)
- [ ] T054 [US2] Escrever os textos de bloqueio na persona da Memora: acolhedores, explicando o motivo e oferecendo a recuperação (FR-015)
- [ ] T055 [US2] Implementar expiração por inatividade com aviso prévio (FR-017)
- [ ] T056 [US2] Escrever teste de widget do login, incluindo o estado bloqueado

---

## Phase 5: US5 — Ser ajudada por um familiar sem entregar a senha (P2)

**Meta**: o acompanhante ajuda no preenchimento, mas **nunca** vê a senha nem controla a recuperação.

**Teste independente**: simular o cadastro com duas pessoas e verificar que o acompanhante não vê nem digita a senha.

### Backend

- [ ] T057 [US5] Aceitar `modo_assistido` no cadastro e **exigir canal com posse confirmada** antes de concluir (FR-062)
- [ ] T058 [US5] Implementar `POST /v1/canais/{id}/codigo` e `POST /v1/canais/{id}/verificar` com código de 6 dígitos, validade de 10 min e uso único (R5)
- [ ] T059 [US5] Guardar o código **hasheado**, nunca em texto puro
- [ ] T060 [US5] Escrever teste do cenário V4 — canal não verificado **não** recebe código de recuperação

### Aplicativo

- [ ] T061 [US5] Adicionar a pergunta *"Tem alguém te ajudando agora?"* no início do cadastro (FR-058)
- [ ] T062 [US5] Criar `TelaEntregaDoAparelho`, que interrompe o fluxo e pede que o aparelho volte à pessoa dona da conta (FR-059)
- [ ] T063 [US5] Usar `CampoSenha` com `permitirRevelar: false` no modo assistido (FR-060)
- [ ] T064 [US5] Criar `TelaPrimeiraEntrada`, conduzindo a pessoa a entrar sozinha ao final (FR-063)
- [ ] T065 [US5] Escrever teste garantindo que o modo assistido **não** cria vínculo nem permissão para o acompanhante (FR-064)

---

## Phase 6: US3 — Recuperar o acesso (P3)

**Meta**: recuperar a senha sozinha, sem contato humano.

**Teste independente**: a partir de uma conta existente, concluir a troca de senha sem usar nenhum outro fluxo.

### Backend

- [ ] T066 [US3] Implementar `POST /v1/auth/recuperacao/solicitar`, respondendo `202` **sempre** (FR-019)
- [ ] T067 [US3] Implementar `POST /v1/auth/recuperacao/confirmar`, revogando **todas** as sessões (FR-021)
- [ ] T068 [US3] Notificar a pessoa pelo canal cadastrado quando a senha mudar (FR-022)
- [ ] T069 [US3] Escrever teste do cenário V5 — trocar a senha derruba as sessões de todos os aparelhos

### Aplicativo

- [ ] T070 [US3] Criar `TelaRecuperacao` usando `CampoCodigo`
- [ ] T071 [US3] Exibir aviso permanente de que o Memora **nunca** pede senha por telefone, mensagem ou e-mail (FR-023)
- [ ] T072 [US3] Tratar código expirado com caminho claro para solicitar outro
- [ ] T073 [US3] Escrever teste de widget do fluxo de recuperação

---

## Phase 7: US4 — Sair da conta com segurança (P4)

**Meta**: sair sem procurar, com confirmação consciente e sem deixar rastro.

**Teste independente**: sair e verificar que nenhum dado pessoal permanece acessível.

- [ ] T074 [US4] Implementar `POST /v1/auth/sair` revogando a sessão atual
- [ ] T075 [US4] Adicionar a saída em local previsível, a no máximo dois toques do perfil (FR-024)
- [ ] T076 [US4] Usar `ConfirmacaoMemora` antes de encerrar, explicando o que vai acontecer (FR-025)
- [ ] T077 [US4] Limpar todo dado pessoal e credencial do aparelho ao sair (FR-026)
- [ ] T078 [US4] Escrever teste verificando que nada resta no armazenamento após a saída

---

## Phase 8: Login social (D2)

> Depende da US1 e da US2 existirem.

- [ ] T079 Implementar `POST /v1/auth/social/{provedor}` validando assinatura, emissor, audiência e expiração do token (R6)
- [ ] T080 Implementar vinculação de contas sem criar duplicata e sem revelar existência prévia (FR-057)
- [ ] T081 Integrar Google e Facebook no aplicativo por Authorization Code com PKCE, em aba segura do sistema
- [ ] T082 Exibir aviso explícito **antes** do redirecionamento, informando que a pessoa sai do Memora (FR-054)
- [ ] T083 Escrever teste do cenário V9 — **nenhuma WebView**, nenhum campo de senha de terceiro dentro do app

---

## Phase 9: Validação final

- [ ] T084 Executar V1 a V9 do [quickstart.md](quickstart.md) de forma automatizada
- [ ] T085 Executar **V10** — teste com 5 pessoas de 65+ anos, sem instrução e sem ajuda
- [ ] T086 Verificar SC-001 a SC-010 contra os resultados observados
- [ ] T087 Revisões obrigatórias: código, UX, acessibilidade, performance, segurança e arquitetura
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
