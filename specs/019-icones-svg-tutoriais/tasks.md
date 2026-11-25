# Tasks: Ícones SVG para e-Título, FGTS e Instagram (Item 13)

**Input**: Design documents from `/specs/019-icones-svg-tutoriais/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, contracts/icones-apps-svg.md, quickstart.md

**Tests**: Portão estrutural/segurança dos SVGs e testes de widget em `app/test/design_system/icone_do_aplicativo_svg_test.dart`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User Story (`US1`, `US2`)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Preparar diretório e registro de ativos para ícones de aplicativos.

- [X] T001 Registrar `- assets/icones_apps/` em `app/pubspec.yaml`

---

## Phase 2: User Story 1 — Criar e ligar ícones SVG de e-Título, FGTS e Instagram (Priority: P1) 🎯 MVP

**Goal**: Substituir desenhos manuais/ícones genéricos de `e-titulo`, `fgts` e `instagram` por SVGs próprios nítidos em `app/assets/icones_apps/`.

**Independent Test**: Renderizar `IconeDoAplicativo` para `'e-titulo'`, `'fgts'` e `'instagram'` nos tamanhos `48`, `64` e `96` confirmando presença de `SvgPicture`.

- [X] T002 [P] [US1] Criar `app/assets/icones_apps/e-titulo.svg` com `viewBox="0 0 48 48"` em vetor puro reconhecível
- [X] T003 [P] [US1] Criar `app/assets/icones_apps/fgts.svg` com `viewBox="0 0 48 48"` em vetor puro reconhecível
- [X] T004 [P] [US1] Criar `app/assets/icones_apps/instagram.svg` com `viewBox="0 0 48 48"` em vetor puro reconhecível
- [X] T005 [US1] Atualizar `app/lib/design_system/componentes/ilustracao/icone_do_aplicativo.dart` para renderizar `e-titulo`, `fgts` e `instagram` via `SvgPicture.asset` (`fit: BoxFit.cover`, `excludeFromSemantics: true`) e remover `_CameraInstagramPainter` e `dart:math` não utilizado

---

## Phase 3: User Story 2 — Portões de segurança, semântica e documentação dos SVGs (Priority: P1)

**Goal**: Garantir ausência de scripts/URLs externas/textos dependentes de fonte, semântica decorativa, registro de origem em `LICENCAS.md` e cobertura nos 3 temas visuais.

**Independent Test**: Executar `flutter test test/design_system/icone_do_aplicativo_svg_test.dart`.

- [X] T006 [P] [US2] Criar `app/test/design_system/icone_do_aplicativo_svg_test.dart` validando `viewBox="0 0 48 48"`, ausência de `<script`/`http(s)://`/`<image`/`<text`/`on*=`, semântica decorativa e renderização nos 3 temas e múltiplos tamanhos
- [X] T007 [P] [US2] Registrar os 3 novos SVGs em `app/assets/ilustracoes/LICENCAS.md` e documentar a entrega em `CHANGELOG.md`

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Executar validações completas de código, tokens e testes do aplicativo.

- [X] T008 Executar `flutter pub get`, `flutter analyze`, `flutter test` e `py specs/002-design-system/ferramentas/validar_tokens.py`, confirmando conformidade com `quickstart.md`

---

## Dependencies & Execution Order

- **Phase 1 (T001)** + **Phase 2 (T002, T003, T004 em paralelo)** → **T005** → **Phase 3 (T006, T007)** → **Phase 4 (T008)**.

---

## Phase 5: Rebase e Unificação pós-016

- [X] T009 [US1/US2] Rebasar `019` sobre `develop` (`0014c0f`), unificar os 10 SVGs no mapa `_iconesSvgPorChave` / `_buscarSvgPorChave` em `icone_do_aplicativo.dart` preservando `_normalizarChave`, registrar todos os SVGs em `LICENCAS.md` e validar sem duplicação em `app/pubspec.yaml`
