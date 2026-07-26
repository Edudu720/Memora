# Memora

> Um companheiro digital que ensina pessoas idosas a usar o smartphone — com paciência, segurança e sem pressa.

O Memora não é um assistente que faz as coisas pelo usuário. Ele **ensina o caminho**,
acompanha o passo a passo e devolve autonomia a quem hoje depende de filhos e netos
para enviar uma mensagem ou acessar o Gov.br.

**Equipe NewXz** — Projeto Integrador, FATEC Americana
Eduardo Juncker Toras · Eduardo Moraes Trevisan · Henrique Moreira Sandrini
Orientação: Prof. Dr. Ivan Menerval da Silva

---

## Sumário

- [Por que este projeto existe](#por-que-este-projeto-existe)
- [Como trabalhamos: Spec Driven Development](#como-trabalhamos-spec-driven-development)
- [O fluxo SDD na prática](#o-fluxo-sdd-na-prática)
- [Começando (setup)](#começando-setup)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Regras de contribuição](#regras-de-contribuição)
- [Stack técnica](#stack-técnica)
- [Princípios inegociáveis](#princípios-inegociáveis)
- [Estado atual do projeto](#estado-atual-do-projeto)

---

## Por que este projeto existe

Uma parcela significativa da população idosa brasileira enfrenta dificuldade real com
smartphones: falta de familiaridade, medo de errar, interfaces pouco acessíveis e
ausência de suporte contínuo. O resultado é exclusão digital — e dependência de
terceiros para tarefas básicas.

Aplicativos existentes (Google Assistente, Alexa, Voice Access) **executam** tarefas,
mas não **ensinam**. O Memora se diferencia exatamente aí: ele combina assistência com
um modo educativo que mostra o caminho, para que da próxima vez o usuário consiga sozinho.

Além disso, esse público é o alvo preferencial de golpes digitais. Por isso, segurança
e proteção contra engenharia social não são features neste projeto — são a fundação.

---

## Como trabalhamos: Spec Driven Development

**A especificação é a fonte da verdade. O código apenas a implementa.**

No SDD invertemos a ordem tradicional. Em vez de escrever código e documentar depois,
nós especificamos o comportamento desejado com precisão suficiente para que a
implementação seja consequência — não interpretação.

### Por que SDD neste projeto

| Problema | Como o SDD resolve |
|---|---|
| Time distribuído, várias pessoas no mesmo código | A spec alinha todo mundo antes do primeiro commit |
| Público vulnerável a golpes | Threat modeling acontece na spec, antes de existir superfície de ataque |
| Acessibilidade costuma virar "ajuste depois" | Critérios de acessibilidade viram critérios de aceite |
| Retrabalho por requisito mal entendido | Ambiguidade é resolvida com pergunta, não com suposição |
| Uso de IA na geração de código | O agente implementa contra uma spec, não contra um palpite |

### As três leis do nosso SDD

1. **Nada é implementado sem especificação aprovada.**
2. **Ambiguidade vira pergunta, nunca suposição.** Se a spec não diz, ninguém inventa.
3. **Spec e código andam juntos.** Spec desatualizada bloqueia o merge.

---

## O fluxo SDD na prática

Usamos o [GitHub Spec Kit](https://github.com/github/spec-kit) integrado ao Claude Code.
Cada comando abaixo é executado **dentro do agente**, no diretório do projeto.

```
constitution → specify → clarify → plan → checklist → tasks → analyze → implement
```

| Etapa | Comando | O que produz | Obrigatório |
|---|---|---|---|
| 0. Princípios | `/speckit-constitution` | Lei do projeto (feito uma vez) | ✅ |
| 1. Especificar | `/speckit-specify` | `spec.md` — o **quê** e o **porquê** | ✅ |
| 2. Clarificar | `/speckit-clarify` | Perguntas estruturadas que eliminam ambiguidade | ⚠️ Recomendado |
| 3. Planejar | `/speckit-plan` | `plan.md` — arquitetura e o **como** | ✅ |
| 4. Checklist | `/speckit-checklist` | Validação de completude dos requisitos | ⚠️ Recomendado |
| 5. Tarefas | `/speckit-tasks` | `tasks.md` — passos acionáveis e ordenados | ✅ |
| 6. Analisar | `/speckit-analyze` | Relatório de consistência entre spec/plan/tasks | ⚠️ Recomendado |
| 7. Implementar | `/speckit-implement` | Código que satisfaz a spec | ✅ |

### Regra de ouro por etapa

- **Na etapa 1 não se fala de tecnologia.** A spec descreve comportamento e valor para
  o usuário, não widgets nem tabelas.
- **Na etapa 3 não se escreve código.** O plano descreve estrutura, contratos e decisões.
- **Na etapa 7 não se inventa requisito.** Se faltou algo, volta-se para a etapa 1.

### O que toda spec do Memora precisa conter

Além do template padrão, este projeto exige em **toda** spec:

- [ ] **User story** na voz do usuário idoso
- [ ] **Critérios de aceite** verificáveis
- [ ] **Estados**: vazio, carregando, sucesso, erro, offline
- [ ] **Edge cases** e caminhos de recuperação de erro
- [ ] **Threat model**: dados sensíveis, quem acessa, ataques possíveis, impacto, mitigação, logs
- [ ] **Análise de engenharia social**: *"Como um golpista exploraria esta tela?"*
- [ ] **Critérios de acessibilidade**: contraste, área de toque, TalkBack, escala de texto
- [ ] **Comportamento da IA**: o que ela fala, o que ela confirma, o que ela nunca faz sozinha

Uma spec sem essas seções **não é aprovada**.

---

## Começando (setup)

### Pré-requisitos

| Ferramenta | Versão | Verificar com |
|---|---|---|
| Git | 2.40+ | `git --version` |
| Flutter SDK | 3.x estável | `flutter --version` |
| Dart | acompanha o Flutter | `dart --version` |
| Python | 3.11+ | `python --version` |
| uv | recente | `uv --version` |
| Claude Code | atual | dentro do VS Code |

### 1. Clonar o repositório

```bash
git clone <URL-DO-REPOSITORIO> && cd Memora
```

### 2. Instalar o uv (gerenciador usado pelo Spec Kit)

```bash
python -m pip install --user uv
```

No Windows, adicione ao PATH: `%APPDATA%\Python\Python3XX\Scripts`

### 3. Verificar a instalação do Spec Kit

```bash
uv tool run --from git+https://github.com/github/spec-kit.git specify check
```

> O Spec Kit **já está configurado** neste repositório (`.specify/` e `.claude/skills/`).
> Você não precisa rodar `specify init` novamente — isso sobrescreveria nossa constitution.

### 4. Abrir no VS Code com Claude Code

Abra a pasta do projeto e inicie o Claude Code. Os comandos `/speckit-*` estarão disponíveis.

### 5. Leia antes de codar

1. [`.specify/memory/constitution.md`](.specify/memory/constitution.md) — **leitura obrigatória**
2. [`docs/design/prototipo/`](docs/design/prototipo/) — telas do protótipo
3. [`docs/referencia/`](docs/referencia/) — documentação acadêmica de origem

---

## Estrutura do repositório

```
Memora/
├── .specify/
│   ├── memory/
│   │   └── constitution.md      ← LEI DO PROJETO. Leia primeiro.
│   ├── templates/               ← Templates de spec, plan, tasks, checklist
│   └── scripts/                 ← Automação do fluxo SDD
├── .claude/
│   └── skills/                  ← Comandos /speckit-* do agente
├── specs/                       ← Uma pasta por feature (spec.md, plan.md, tasks.md)
├── docs/
│   ├── design/prototipo/        ← Telas do protótipo (fonte de design)
│   ├── architecture/            ← Decisões arquiteturais (ADRs)
│   └── referencia/              ← Documentação acadêmica
├── lib/                         ← Código Flutter (ver constitution)
└── README.md
```

---

## Regras de contribuição

### Branches

Nunca commite direto na branch principal.

```
feature/<numero>-<slug>     ex.: feature/003-login-acessivel
fix/<slug>                  ex.: fix/contraste-botao-hub
docs/<slug>                 ex.: docs/adr-escolha-backend
```

### Commits — Conventional Commits

```
feat:     nova funcionalidade
fix:      correção de bug
docs:     documentação e specs
refactor: mudança de código sem alterar comportamento
test:     testes
chore:    build, dependências, configuração
```

Exemplo:

```bash
git commit -m "feat(auth): adiciona login com validação acessível"
```

### Pull Requests — checklist obrigatório

Nenhuma PR é aprovada sem todos os itens marcados:

- [ ] Existe spec aprovada para esta mudança
- [ ] A spec foi atualizada junto com o código
- [ ] Revisão de **segurança** realizada
- [ ] Revisão de **acessibilidade** realizada (contraste, toque, TalkBack, escala de texto)
- [ ] Nenhum secret, token ou API key no código
- [ ] Validações críticas existem também no backend
- [ ] Textos da IA seguem a persona definida na constitution
- [ ] Testes passando

### Ordem de trabalho para uma nova feature

```bash
# 1. Especifique (dentro do Claude Code)
/speckit-specify <descrição da funcionalidade>

# 2. Elimine ambiguidades
/speckit-clarify

# 3. Planeje a arquitetura
/speckit-plan

# 4. Gere as tarefas
/speckit-tasks

# 5. Só então implemente
/speckit-implement
```

---

## Stack técnica

| Camada | Tecnologia | Motivo |
|---|---|---|
| App | Flutter + Dart | Multiplataforma, controle fino de acessibilidade |
| Arquitetura | Clean Architecture, Feature-First, Repository Pattern, SOLID | Isolamento e testabilidade |
| Backend | Java + Spring Boot | Ecossistema de segurança maduro e conhecimento prévio da equipe — ver [ADR 001](docs/architecture/adr-001-linguagem-do-backend.md) |
| Segurança backend | Spring Security | Argon2id, JWT, rate limiting e hardening como configuração de framework auditado |
| Banco | PostgreSQL | Relacional, com classificação de sensibilidade por campo |
| Auth | JWT curto + Refresh Token rotativo | Janela de exposição mínima |
| Contrato app↔API | OpenAPI → cliente Dart gerado | Evita divergência entre DTO do app e a API |
| Storage seguro | `flutter_secure_storage` | Tokens nunca em SharedPreferences |
| Storage de arquivos | Cloud Storage | — |

---

## Princípios inegociáveis

Estes princípios não admitem exceção. Detalhamento completo na
[constitution](.specify/memory/constitution.md).

1. **Segurança acima de tudo** — vence prazo, performance e conveniência.
2. **Proteção contra engenharia social** — toda tela responde *"como um golpista exploraria isto?"*
3. **Acessibilidade é requisito** — WCAG 2.2 AA, toque de 48dp, texto a 200%, TalkBack.
4. **Especificação antes de código** — sem spec aprovada, não se implementa.
5. **A IA nunca age sozinha** — toda ação crítica exige confirmação explícita e gera log.
6. **Ensinar, não substituir** — o objetivo é autonomia, não dependência.

E a pergunta que valida qualquer decisão:

> **"Um idoso conseguiria usar isso sozinho?"**

---

## Estado atual do projeto

**Atualizado em 2026-07-26.**

| Item | Status |
|---|---|
| Ambiente SDD (Spec Kit + Claude Code) | ✅ Configurado |
| Constitution v1.0.0 | ✅ Ratificada |
| Protótipo de telas | ✅ 38 telas em `docs/design/prototipo/` |
| Requisitos atualizados vs. Arquivo X | ✅ [documentado](docs/referencia/requisitos-atualizados.md) |
| **001 — Autenticação** — spec e plano | ✅ 64 requisitos, contrato OpenAPI |
| **001 — Autenticação** — tarefas | ✅ 88 tarefas |
| **001 — Autenticação** — telas da US1 | 🟡 Funcionando contra repositório simulado |
| **001 — Autenticação** — backend | 🟡 Núcleo de segurança pronto; endpoints pendentes |
| **002 — Design System** — spec, plano e tarefas | ✅ 38 requisitos, 53 tarefas |
| **002 — Design System** — tokens e temas | ✅ T001-T015, 52 testes passando |
| **002 — Design System** — componentes | 🟡 Em andamento a partir de T016 |
| Backend (Java + Spring Boot) | 🟡 Projeto criado, Argon2 calibrado e testado |

> ⚠️ **Docker é pré-requisito para continuar.** Sem ele não há PostgreSQL local
> nem Testcontainers, e as tarefas T008-T014 ficam bloqueadas.

### Verificação atual

| Portão | Resultado |
|---|---|
| `flutter analyze` | ✅ Sem problemas |
| `flutter test` | ✅ 175 passando |
| `mvnw test` (backend) | ✅ 6 passando |
| `validar_paleta.py` | ✅ 51 pares, 3 temas |

Como rodar o aplicativo: ver [CLAUDE.md, seção 5.1](CLAUDE.md).

> **Continuando o trabalho?** Leia [CLAUDE.md](CLAUDE.md) — contém o estado
> detalhado, as decisões já tomadas e as armadilhas do ambiente.

---

## Licença

Projeto acadêmico — FATEC Americana, 2025/2026.
