# Implementation Plan: Publicação do Site Tutorial no Render (Item 14b)

**Branch**: `feature/017-site-no-render` | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/017-site-no-render/spec.md`

## Summary

Adicionar o serviço estático `memora-site` ao Blueprint raiz ([render.yaml](../../render.yaml)) apontando para `site/` com `runtime: static`, filtro de build isolado (`site/**` e `render.yaml`) e cabeçalhos HTTP restritivos (`Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`), preservando integralmente o `memora-backend` existente e atualizando [docs/deploy/render.md](../../docs/deploy/render.md) e [CHANGELOG.md](../../CHANGELOG.md) para publicação e repasse da URL `https://` ao Item 11.

## Technical Context

**Language/Version**: YAML (Render Blueprint Spec), Markdown, Python 3.14 (validador existente), HTML/CSS/JS estáticos em `site/`
**Primary Dependencies**: Render Static Site runtime (`type: web`, `runtime: static`)
**Storage**: N/A (site estático sem persistência no servidor)
**Testing**: `py site/tests/validar_site.py`, `node --test site/tests/tutorial.test.mjs` e verificação estrutural Python do `render.yaml`
**Target Platform**: Render Static Hosting (`https://*.onrender.com`)
**Project Type**: Infraestrutura declarativa (Blueprint) + documentação operacional
**Performance Goals**: Entrega imediata via CDN estática sem cold start / hibernação
**Constraints**: Zero secrets no repositório, zero alteração nos arquivos do `site/`, preservação total de `memora-backend`, CSP compatível com `<style>` em Shadow DOM do `<memora-personagem>`
**Scale/Scope**: 1 serviço estático adicional em `render.yaml` + documentação em `docs/deploy/render.md` + `CHANGELOG.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Princípio I (Segurança Acima de Tudo)**: PASS — Threat model documentado na spec; headers `CSP`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer` e `Permissions-Policy` aplicados a `/*`; zero segredos ou rede externa.
- **Princípio II (Segurança Contra Engenharia Social)**: PASS — Impede embutimento do guia em iframe malicioso (`frame-ancestors 'none'` + `X-Frame-Options: DENY`) e define conferência explícita da URL `https://` antes do repasse ao Item 11.
- **Princípio III (Acessibilidade)**: PASS — `site/` validado pelo `validar_site.py` (WCAG 2.2 AA/AAA, 200%, leitura em voz local) sem regressões.
- **Princípio IV (Especificação Antes de Código)**: PASS — Ciclo completo `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-analyze` → `/speckit-implement` → `/speckit-converge`.
- **Documentação Viva**: PASS — `docs/deploy/render.md` e `CHANGELOG.md` atualizados no mesmo PR/commit.

## Project Structure

### Documentation (this feature)

```text
specs/017-site-no-render/
├── spec.md
├── plan.md
├── research.md
├── quickstart.md
├── checklists/
│   └── requirements.md
├── contracts/
│   └── render-site-blueprint.md
└── tasks.md
```

### Source Code (repository root)

```text
render.yaml                  # Adiciona serviço memora-site (static) ao lado de memora-backend
docs/deploy/render.md        # Documenta publicação, conferência HTTPS/headers e repasse ao Item 11
CHANGELOG.md                 # Registra a preparação do site tutorial no Blueprint do Render
site/                        # Preservado intacto (validado por validar_site.py e tutorial.test.mjs)
```

**Structure Decision**: Nenhuma pasta nova de código de aplicativo é criada; apenas a configuração declarativa de Blueprint (`render.yaml`) e os documentos operacionais (`docs/deploy/render.md`, `CHANGELOG.md`).

## Complexity Tracking

Nenhuma violação da constituição ou complexidade extra justificada.
