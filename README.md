# Memora

> Um companheiro digital que ensina pessoas idosas a usar o smartphone — com paciência, segurança e sem pressa.

O Memora não é um assistente que faz as coisas pelo usuário. Ele **ensina o caminho**, acompanha o passo a passo e devolve autonomia a quem hoje depende de filhos e netos para enviar uma mensagem, usar redes sociais, encontrar um posto de saúde ou acessar o Gov.br.

**Equipe NewXz** — Projeto Integrador, FATEC Americana (CST em Análise e Desenvolvimento de Sistemas)  
Eduardo Juncker Toras · Eduardo Moraes Trevisan · Henrique Moreira Sandrini  
Orientação: Prof. Dr. Ivan Menerval da Silva

🔗 **Portal oficial de tutoriais (Web)**: [memora-site-thf2.onrender.com](https://memora-site-thf2.onrender.com/) · 📜 **Lei do projeto**: [Constituição v1.1.0](.specify/memory/constitution.md) · 📋 **Histórico de entregas**: [CHANGELOG.md](CHANGELOG.md)

---

## Sumário

- [Por que este projeto existe](#por-que-este-projeto-existe)
- [Funcionalidades entregues](#funcionalidades-entregues)
- [Como trabalhamos: Spec Driven Development](#como-trabalhamos-spec-driven-development)
- [O fluxo SDD na prática](#o-fluxo-sdd-na-prática)
- [Começando (setup e execução)](#começando-setup-e-execução)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Regras de contribuição](#regras-de-contribuição)
- [Stack técnica](#stack-técnica)
- [Princípios inegociáveis](#princípios-inegociáveis)
- [Estado atual do projeto](#estado-atual-do-projeto)

---

## Por que este projeto existe

Uma parcela significativa da população idosa brasileira enfrenta dificuldade real com smartphones: falta de familiaridade, medo de errar, interfaces pouco acessíveis e ausência de suporte contínuo. O resultado é exclusão digital — e dependência de terceiros para tarefas básicas.

Aplicativos existentes (Google Assistente, Alexa, Voice Access) **executam** tarefas, mas não **ensinam**. O Memora se diferencia exatamente aí: ele combina assistência acolhedora com um modo educativo visual que mostra o caminho, para que da próxima vez a pessoa consiga sozinha.

Além disso, esse público é o alvo preferencial de golpes digitais no Brasil. Por isso, segurança, privacidade e proteção contra engenharia social não são funcionalidades avulsas neste projeto — são a fundação.

---

## Funcionalidades entregues

- **Assistente Educadora Memora (`003`, `007`, `018`, `022`)**: conversa didática em linguagem simples, respostas em *streaming* via Google Gemini (`gemini-3.6-flash` com retentativa curta e *fallback* automático para `gemini-3.5-flash-lite`), ditado por voz em `pt-BR` restrito ao rascunho (nunca envia sem confirmação), consentimento transparente (Emenda 1) e avatares laterais sincronizados com o retrato do perfil.
- **16 Guias Visuais Passo a Passo e Progresso Local (`004`, `006`, `016`, `019`, `020`)**: cobertura completa de *WhatsApp, Instagram, YouTube, Facebook, Google Fotos, Telegram, TikTok, Gov.br, Meu INSS, e-Título, Serasa, FGTS, Poupatempo, Carteira Digital de Trânsito, Correios* e *Carteira de Trabalho Digital* — com **172 capturas reais higienizadas** sem dados pessoais, marcações azuis numeradas (`#1040F8`), textos explicativos numerados, zoom acessível, divisão em seções curtas (`3` a `7` passos), selo `"Concluído"` no catálogo e `"Último aprendizado"` em Meu Perfil.
- **Análise Antigolpes Híbrida (`021`)**: verificação em 1 toque de mensagens e links suspeitos a partir do Início ou da Ajuda, combinando motor heurístico determinístico (homógrafos Unicode, personificação de marca, links encurtados, pedido de acesso remoto/APK) com análise por IA sanitizada por piso monotônico de risco e *fallback* determinístico offline no aparelho.
- **Localizador de Serviços Essenciais (`009`, `010`, `#81`, `#115`, `#117`)**: busca acessível por categorias (*Saúde*, *Serviços públicos*, *Emergência* e *Serviços cotidianos*) ou em linguagem natural, via GPS com explicação prévia ou busca manual por cidade/bairro de primeira classe. Conta com visualização em lista e mapa de alto contraste, confirmação em duas etapas para rotas e chamadas telefônicas, e arquitetura resiliente no backend (Geoapify + cache regional de 24h + rodízio Overpass + contingência regional Nominatim `viewbox`).
- **Saúde, Dispositivo de Cuidado IoT e Botão SOS (`005`, `014`, `016`)**: monitoramento em tempo real via MQTT integrado a hardware físico **ESP32** (acelerômetro/giroscópio MPU6050 autocalibrado + sensor de batimentos), alerta de queda com cronômetro regressivo de cancelamento, pedido de ajuda pré-pronto via WhatsApp mediante confirmação e botão **SOS** persistente no cabeçalho.
- **Atalhos Seguros e Portal Web de Tutoriais (`012`, `015`, `016`, `017`)**: atalhos rápidos que abrem apenas pacotes oficiais verificados (ou orientam com segurança até a Play Store) e portal estático público ([memora-site-thf2.onrender.com](https://memora-site-thf2.onrender.com/)) com contraste WCAG 2.2 AAA, zero rastreadores e cabeçalhos estritos de segurança (`CSP`, `X-Frame-Options`, `nosniff`).
- **Autenticação Acessível, Perfil Privado e Design System 2.0 (`001`, `002`, `007`, `011`, `013`)**: login, recuperação de conta e cadastro comum ou assistido (ocultando revelação de senha quando há acompanhante), sessão com JWT curto + Refresh Token rotativo (Argon2id) em `flutter_secure_storage`, foto de perfil 100% local com remoção determinística de metadados EXIF/GPS em Dart puro, **3 temas** (*Claro*, *Escuro*, *Alto Contraste*) × **6 paletas** validados em WCAG 2.2 e suporte integral a texto escalado até **200%**.

---

## Como trabalhamos: Spec Driven Development

**A especificação é a fonte da verdade. O código apenas a implementa.**

No SDD invertemos a ordem tradicional. Em vez de escrever código e documentar depois, especificamos o comportamento desejado com precisão suficiente para que a implementação seja consequência — não interpretação.

### Por que SDD neste projeto

| Problema | Como o SDD resolve |
|---|---|
| Time distribuído, várias pessoas no mesmo código | A spec alinha todo mundo antes do primeiro commit |
| Público vulnerável a golpes | Threat modeling acontece na spec, antes de existir superfície de ataque |
| Acessibilidade costuma virar "ajuste depois" | Critérios de acessibilidade viram critérios de aceite automatizados |
| Retrabalho por requisito mal entendido | Ambiguidade é resolvida com pergunta, não com suposição |
| Uso de IA na geração de código | O agente implementa contra uma spec auditada, não contra um palpite |

### As três leis do nosso SDD

1. **Nada é implementado sem especificação aprovada.**
2. **Ambiguidade vira pergunta, nunca suposição.** Se a spec não diz, ninguém inventa.
3. **Spec e código andam juntos.** Spec ou documentação viva desatualizada bloqueia o merge.

---

## O fluxo SDD na prática

Usamos o [GitHub Spec Kit](https://github.com/github/spec-kit) integrado aos agentes de desenvolvimento (`.specify/`, `.claude/skills/` e `.agents/skills/`).

```
constitution → specify → clarify → plan → checklist → tasks → analyze → implement → converge
```

| Etapa | Comando | O que produz | Obrigatório |
|---|---|---|---|
| 0. Princípios | `/speckit-constitution` | Lei do projeto (`.specify/memory/constitution.md`) | ✅ |
| 1. Especificar | `/speckit-specify` | `spec.md` — o **quê** e o **porquê** | ✅ |
| 2. Clarificar | `/speckit-clarify` | Perguntas estruturadas que eliminam ambiguidade | ⚠️ Recomendado |
| 3. Planejar | `/speckit-plan` | `plan.md` — arquitetura, contratos e o **como** | ✅ |
| 4. Checklist | `/speckit-checklist` | Validação de completude dos requisitos | ⚠️ Recomendado |
| 5. Tarefas | `/speckit-tasks` | `tasks.md` — passos acionáveis e ordenados | ✅ |
| 6. Analisar | `/speckit-analyze` | Relatório de consistência entre `spec`, `plan` e `tasks` | ⚠️ Recomendado |
| 7. Implementar | `/speckit-implement` | Código e testes que satisfazem a spec | ✅ |
| 8. Convergir | `/speckit-converge` | Auditoria do código contra a spec para fechar lacunas restantes | ⚠️ Recomendado |

### O que toda spec do Memora precisa conter

- [ ] **User story** na voz da pessoa idosa
- [ ] **Critérios de aceite** verificáveis
- [ ] **Estados**: vazio, carregando, sucesso, erro, offline
- [ ] **Edge cases** e caminhos de recuperação de erro
- [ ] **Threat model**: dados sensíveis, quem acessa, ataques possíveis, impacto, mitigação, logs
- [ ] **Análise de engenharia social**: *"Como um golpista exploraria esta tela?"*
- [ ] **Critérios de acessibilidade**: contraste WCAG 2.2, área de toque `>= 48×48 dp`, TalkBack, escala de texto até `200%`
- [ ] **Comportamento da IA**: o que ela fala, o que ela confirma, o que ela nunca faz sozinha

---

## Começando (setup e execução)

### Pré-requisitos

| Ferramenta | Versão | Uso |
|---|---|---|
| Git | `2.40+` | Controle de versão |
| Flutter SDK / Dart | `3.x` estável / `^3.11.4` | Aplicativo Android (`app/`) |
| Java (JDK) | `21` (Temurin recomendado) | Backend Spring Boot (`backend/`) |
| Docker Desktop | Recente | PostgreSQL local (`docker-compose.yml`) e Testcontainers |
| Python | `3.11+` | Validadores do Design System, do site e scripts de guias |
| Node.js | `24+` | Testes unitários e auditoria E2E Playwright/axe-core (`site/`) |

### 1. Clonar o repositório

```bash
git clone https://github.com/Edudu720/Memora.git
cd Memora
```

### 2. Executar o aplicativo Flutter (`app/`)

Por padrão, `flutter run` sobe em **modo simulado** (funciona imediatamente sem exigir backend nem chaves externas):

```bash
cd app
flutter pub get
flutter run
```

Para apontar para um backend local (no emulador Android `10.0.2.2` aponta para a máquina hospedeira) ou de produção:

```bash
flutter run \
  --dart-define=MEMORA_URL_BASE=http://10.0.2.2:8080/v1 \
  --dart-define=MEMORA_SERVIDOR_REAL=true
```

> **Dica no Windows:** caso o caminho do seu usuário no Windows contenha espaços, defina `$env:TEMP="C:\memora-tmp"; $env:TMP="C:\memora-tmp"` antes de compilar um APK com `flutter build apk --release` (ver [`docs/deploy/render.md`](docs/deploy/render.md)).

### 3. Executar o backend (`backend/`)

Suba o banco PostgreSQL local via Docker e inicie a API Spring Boot:

```bash
docker compose up -d
cd backend
./mvnw spring-boot:run
```

*(No Windows PowerShell, use `.\mvnw.cmd spring-boot:run`.)*

### 4. Executar os portões de verificação localmente

```bash
# Portões de acessibilidade e tokens visuais (Design System)
python specs/002-design-system/ferramentas/validar_paleta.py
python specs/002-design-system/ferramentas/validar_tokens.py

# Análise estática e suíte de testes do aplicativo
cd app && flutter analyze && flutter test

# Testes de unidade e integração do backend (requer Docker ativo para Testcontainers)
cd ../backend && ./mvnw test

# Validação estática WCAG AAA e testes unitários do site tutorial
cd .. && python site/tests/validar_site.py && node --test site/tests/tutorial.test.mjs
```

### 5. Leia antes de codar

1. [`.specify/memory/constitution.md`](.specify/memory/constitution.md) — **leitura obrigatória** (fonte suprema de regras do projeto)
2. [`CLAUDE.md`](CLAUDE.md) — contexto histórico detalhado, decisões arquiteturais e armadilhas conhecidas do ambiente
3. [`docs/deploy/render.md`](docs/deploy/render.md) — guia de publicação do backend (Render + Neon) e do site estático

---

## Estrutura do repositório

```text
Memora/
├── .specify/
│   ├── memory/constitution.md   ← LEI DO PROJETO (v1.1.0). Leia primeiro.
│   ├── templates/               ← Templates de spec, plan, tasks e checklist
│   └── scripts/                 ← Automação do fluxo SDD
├── .github/workflows/
│   └── verificacao.yml          ← 6 portões automatizados de CI (App, Backend, Site, WCAG, Tokens, OpenAPI)
├── app/                         ← Aplicativo Android em Flutter + Dart
│   ├── lib/
│   │   ├── core/                ← Constantes, erros e utilitários transversais
│   │   ├── design_system/       ← Tokens 2.0, temas (Claro/Escuro/Alto Contraste) e componentes
│   │   ├── features/            ← Módulos Feature-First (data / domain / presentation)
│   │   ├── l10n/                ← Textos centralizados em português claro e acolhedor
│   │   ├── services/            ← Ambiente, armazenamento seguro e integrações de plataforma
│   │   └── shared/              ← Widgets e helpers compartilhados
│   ├── pacotes/memora_api/      ← Cliente HTTP Dart gerado a partir dos contratos OpenAPI
│   ├── assets/                  ← 172 capturas dos 16 guias, ícones SVG e ilustrações da Memora
│   └── test/                    ← 3.590+ testes de unidade, widget, ouro/acessibilidade e fluxos
├── backend/                     ← API REST em Java 21 + Spring Boot 4.1
│   ├── src/main/java/           ← Módulos (autenticacao, assistente, antigolpe, cuidado, localizador...)
│   ├── src/main/resources/      ← Configurações e migrations Flyway (PostgreSQL)
│   └── src/test/java/           ← 573 testes JUnit 5 + Testcontainers
├── site/                        ← Portal web estático acessível de tutoriais + testes Playwright/axe-core
├── specs/                       ← Especificações completas das features 001 a 022 (spec, plan, tasks, contracts)
├── scripts/                     ← Ferramentas de processamento e anotação visual das capturas dos guias
├── docs/
│   ├── architecture/            ← Decisões arquiteturais (ADRs)
│   ├── deploy/                  ← Guia de operação no Render e Neon
│   ├── design/                  ← Protótipos e guia de uso do Design System
│   ├── referencia/              ← Documentação acadêmica de origem
│   ├── relatorios/              ← Acompanhamento consolidado de entregas
│   └── seguranca/               ← Auditorias e modelagem de ameaças
├── docker-compose.yml           ← PostgreSQL local para desenvolvimento
├── render.yaml                  ← Blueprint de infraestrutura (memora-backend Docker + memora-site estático)
├── CHANGELOG.md                 ← Registro vivo das entregas por feature
└── README.md
```

---

## Regras de contribuição

### Branches

Nunca commite direto na `master`. O desenvolvimento integra em `develop` via Pull Request e é promovido para `master` após homologação:

```text
feature/<numero>-<slug>     ex.: feature/021-analise-golpes
fix/<slug>                  ex.: fix/009-localizador-regiao-teclado
docs/<slug>                 ex.: docs/atualizar-readme
```

### Commits — Conventional Commits

```text
feat:     nova funcionalidade
fix:      correção de bug
docs:     documentação e specs
refactor: mudança de código sem alterar comportamento
test:     testes automatizados
chore:    build, dependências, configuração
```

### Pull Requests — checklist obrigatório

Nenhuma PR é aprovada sem todos os itens atendidos:

- [ ] Existe spec aprovada para a mudança (e foi atualizada junto com o código)
- [ ] Revisão de **segurança** e **engenharia social** realizada
- [ ] Revisão de **acessibilidade** realizada (contraste WCAG 2.2, toque `>= 48 dp`, TalkBack, texto a `200%`)
- [ ] Nenhum segredo, token ou chave de API no código
- [ ] Validações críticas refeitas de forma determinística no backend
- [ ] Textos seguem a persona paciente, literal e acolhedora da Memora
- [ ] Todos os 6 portões do workflow `Verificação` passando no CI

---

## Stack técnica

| Camada | Tecnologia | Papel no projeto |
|---|---|---|
| Aplicativo móvel | Flutter + Dart (`^3.11.4`) | Interface acessível sênior com controle fino de escala, semântica e contraste |
| Arquitetura App | Clean Architecture + Feature-First + SOLID | Isolamento estrito entre `domain`, `data` e `presentation` |
| Backend REST | Java `21` + Spring Boot `4.1` | API própria com validação, resiliência e auditoria ([ADR 001](docs/architecture/adr-001-linguagem-do-backend.md)) |
| Segurança API | Spring Security + Argon2id + JWT/Refresh rotativo | Proteção de sessão com janela mínima de exposição e *rate limiting* |
| Banco de dados | PostgreSQL + Flyway (Neon em produção) | Persistência relacional versionada com classificação de sensibilidade |
| Contrato App↔API | OpenAPI → `memora_api` (Dart gerado) | Fonte única da verdade entre frontend e backend |
| Armazenamento local | `flutter_secure_storage` + diretório privado | Credenciais apenas no Keystore; fotos sem EXIF e progresso isolados por conta |
| Inteligência Artificial | Google Gemini (`gemini-3.6-flash` + reserva `3.5-flash-lite`) | Assistente educadora e apoio contextual na análise antigolpes |
| Geolocalização e Mapas | Geoapify + OpenStreetMap (Overpass / Nominatim) + `flutter_map` | Busca real de serviços essenciais com cache regional de 24h e *fallback* em camadas |
| IoT / Cuidado | ESP32 (MPU6050 + PulseSensor) + MQTT (`mqtt_client`) | Telemetria de batimentos e detecção de quedas em tempo real |
| Portal Web e Deploy | HTML/CSS/JS puro + Render (Docker & Static Site) | Site tutorial leve WCAG AAA com CSP estrita e deploy contínuo |

---

## Princípios inegociáveis

Estes princípios regem toda decisão técnica e de produto. Texto integral e condições da **Emenda 1** (uso transparente do nível gratuito de IA com consentimento prévio e sem envio de dados identificáveis) na [Constituição v1.1.0](.specify/memory/constitution.md):

1. **Segurança acima de tudo** — vence prazo, performance e conveniência.
2. **Segurança contra engenharia social** — toda tela responde *"como um golpista tentaria explorar esta tela?"*
3. **Acessibilidade como requisito** — contraste WCAG 2.2 AA/AAA, alvo mínimo `48×48 dp`, texto escalável até `200%` sem quebra e rótulos completos para TalkBack.
4. **Especificação antes de código** — nenhuma implementação começa sem spec aprovada.
5. **Arquitetura limpa e Feature-First** — `domain` independente, zero lógica de negócio em widgets e tokens visuais centralizados.
6. **A IA nunca age sozinha** — toda ação externa ou sensível exige confirmação explícita da pessoa usuária e validação determinística no servidor.
7. **Ensinar, não substituir** — o objetivo do Memora é gerar autonomia, nunca dependência.

E a pergunta que valida qualquer entrega:

> **"Um idoso conseguiria usar isso sozinho?"**

---

## Estado atual do projeto

**Atualizado em 2026-11-24** — branches `master` e `develop` sincronizadas.

| Especificação / Entrega | Status |
|---|---|
| **Constituição v1.1.0** e fluxo SDD (`.specify/` + CI automatizado) | ✅ Ratificada e ativa |
| **001 — Autenticação Acessível** (comum, assistida, recuperação, sessão segura) | ✅ Concluída |
| **002 / 004 / 007 / 013 — Design System 2.0 e Redesenho Final** (3 temas × 6 paletas, animações, `200%`) | ✅ Concluída |
| **003 / 018 / 022 — Hub, Assistente Educadora, Ditado por Voz, Fallback Gemini e Avatares** | ✅ Concluída |
| **005 / 014 — Monitoramento IoT de Quedas (ESP32 + MQTT) e Botão SOS no Cabeçalho** | ✅ Concluída |
| **006 / 016 / 019 / 020 — 16 Guias Visuais Numerados (172 capturas), SVGs e Progresso Local** | ✅ Concluída |
| **009 / 010 — Localizador de Serviços Essenciais** (Geoapify, cache 24h, Overpass e Nominatim) | ✅ Concluída |
| **011 — Foto de Perfil Acessível e Privada** (recorte 1:1 e remoção de EXIF/GPS local) | ✅ Concluída |
| **012 / 017 — Site Tutorial para Idosos publicado no Render** (`memora-site-thf2.onrender.com`) | ✅ Concluída |
| **015 — Atalhos Seguros para Aplicativos Externos** (validação de pacote e loja oficial) | ✅ Concluída |
| **021 — Análise Antigolpes de Links e Mensagens Estranhas** (híbrida + fallback offline) | ✅ Concluída |

### Portões automatizados de verificação (`.github/workflows/verificacao.yml`)

| Portão no CI | Escopo | Resultado |
|---|---|---|
| **Contraste da paleta (WCAG 2.2)** | `validar_paleta.py` nos 3 temas × 6 paletas cromáticas | ✅ Aprovado |
| **Valor literal fora dos tokens (`FR-032`)** | `validar_tokens.py` varrendo `app/lib/` contra cores/espaços/tamanhos soltos | ✅ 0 literais |
| **Análise e testes do aplicativo** | `flutter analyze` + `flutter test` em `app/` | ✅ 0 avisos · **3.590+ testes passando** |
| **Cliente da API gerado do contrato** | `dart analyze` + `dart test` em `app/pacotes/memora_api` | ✅ Aprovado |
| **Build e testes do backend** | `./mvnw test` (Java 21 + Spring Boot 4.1 + Testcontainers PostgreSQL) | ✅ **573 testes passando** |
| **Qualidade e acessibilidade do site** | `validar_site.py` (WCAG AAA / orçamento JS) + `node:test` + Playwright/axe-core | ✅ **18 testes passando** |

---

## Licença

Projeto acadêmico desenvolvido na **FATEC Americana** — Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas (2025/2026).
