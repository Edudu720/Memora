# Tasks: Publicação do Site Tutorial no Render (Item 14b)

**Input**: Design documents from `/specs/017-site-no-render/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, contracts/render-site-blueprint.md, quickstart.md

**Tests**: Verificação automatizada de sintaxe/estrutura do Blueprint + execução da suíte existente do site (`validar_site.py` e `tutorial.test.mjs`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User Story (`US1`, `US2`, `US3`)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirmar estado limpo do Blueprint e integridade prévia da pasta `site/`.

- [X] T001 Verificar integridade atual de `render.yaml` e confirmar passagem prévia de `site/tests/validar_site.py` e `site/tests/tutorial.test.mjs`

---

## Phase 2: User Story 1 — Publicar o site tutorial pelo Blueprint único do repositório (Priority: P1) 🎯 MVP

**Goal**: Declarar o serviço estático `memora-site` em `render.yaml` publicando `site/` sem afetar `memora-backend` nem disparar rebuilds cruzados.

**Independent Test**: Validar sintaticamente `render.yaml` confirmando 2 serviços (`memora-backend` intacto e `memora-site` com `type: web`, `runtime: static`, `staticPublishPath: site`, `buildCommand: ""`, `buildFilter` em `site/**` e `render.yaml`).

- [X] T002 [US1] Adicionar o serviço estático `memora-site` ao `render.yaml` preservando integralmente todos os campos e variáveis de `memora-backend`

---

## Phase 3: User Story 2 — Proteger visitantes com cabeçalhos de segurança (Priority: P1)

**Goal**: Proteger todas as rotas do site estático (`/*`) contra clickjacking, MIME sniffing, vazamento de referrer, acesso a sensores e carregamento/envio externo mantendo `<memora-personagem>` funcional.

**Independent Test**: Inspecionar `render.yaml` validando os 5 cabeçalhos em `memora-site.headers` para `path: /*` e executar a suíte de testes de `site/`.

- [X] T003 [US2] Configurar os cabeçalhos de segurança (`Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`) no serviço `memora-site` em `render.yaml` conforme `contracts/render-site-blueprint.md`
- [X] T004 [US2] Executar `py site/tests/validar_site.py` e `node --test site/tests/tutorial.test.mjs` garantindo zero regressões na pasta `site/`

---

## Phase 4: User Story 3 — Guiar a publicação e passagem da URL para o Item 11 (Priority: P2)

**Goal**: Documentar o deploy do serviço `memora-site`, conferência pós-deploy e repasse da URL `https://` oficial na Issue #106.

**Independent Test**: Conferir se `docs/deploy/render.md` e `CHANGELOG.md` documentam `memora-site`, ausência de hibernação e comando `curl.exe -I`.

- [X] T005 [P] [US3] Atualizar `docs/deploy/render.md` documentando o serviço `memora-site` (Static Site sem hibernação), sincronização do Blueprint, conferência HTTPS/headers e entrega da URL ao Item 11
- [X] T006 [P] [US3] Registrar a entrega do Item 14b no `CHANGELOG.md`

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Auditoria final do YAML, revisão de conformidade constitucional e validação do `quickstart.md`.

- [X] T007 Validar estrutura do `render.yaml` contra `contracts/render-site-blueprint.md` (incluindo preservação integral do `memora-backend`) e verificar `quickstart.md`

---

## Dependencies & Execution Order

- **Phase 1 (T001)** → **Phase 2 (T002)** → **Phase 3 (T003, T004)** → **Phase 4 (T005, T006 em paralelo)** → **Phase 5 (T007)**.

---

## Phase 6: Review Follow-up

- [X] T008 Registrar em `docs/deploy/render.md` (seção `2b`) que `https://memora-site.onrender.com` já pertence a outro projeto externo no Render e a URL oficial gerada no Blueprint terá sufixo único
