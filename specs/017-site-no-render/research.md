# Research: Publicação do Site Tutorial no Render (Item 14b)

## Decisão 1 — Sintaxe do serviço estático no Render Blueprint (`render.yaml`)

- **Decisão**: Declarar o segundo item em `services:` como `type: web`, `name: memora-site`, `runtime: static`, `buildCommand: ""`, `staticPublishPath: site`, `buildFilter` com `paths: [site/**, render.yaml]` e seção `headers` em `path: /*`.
- **Justificativa**: Na especificação atual de Blueprints do Render, Static Sites usam `type: web` + `runtime: static` + `staticPublishPath` (substituindo o antigo `env: static` depreciado) e podem declarar headers HTTP diretamente no `render.yaml`. O serviço estático no Render gratuito não hiberna e é servido via CDN em `https://`.
- **Alternativas consideradas**: Subir um contêiner Nginx em `runtime: docker` — rejeitado porque contêineres Free dormem após 15 min, aumentam superfície de ataque e desperdiçam build/CPU para arquivos puramente estáticos.

## Decisão 2 — Política de Content-Security-Policy (CSP) compatível com `site/`

- **Decisão**: Usar `"default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; object-src 'none'"`.
- **Justificativa**: Auditoria em `site/index.html`, `site/styles/*.css` e `site/scripts/*.js` confirmou zero URLs `http://`/`https://`, zero `data:` URIs, zero `<script>` inline no HTML e uso de `<style>` injetado no Shadow DOM em `site/scripts/memora-personagem.js` (linha 311). Portanto `'unsafe-inline'` é necessário apenas em `style-src` para não quebrar o Web Component `<memora-personagem>`, enquanto `script-src` permanece estrito em `'self'` e `connect-src`, `form-action` e `frame-ancestors` ficam bloqueados.
- **Alternativas consideradas**: `style-src 'self'` puro — quebraria a estilização interna do Shadow DOM em `memora-personagem.js` (e alterar `site/` violaria FR-006 / escopo do Item 14b).

## Decisão 3 — Ausência de rewrite SPA global

- **Decisão**: Não configurar `routes` com rewrite `/* -> /index.html`.
- **Justificativa**: O site tutorial (`site/index.html`) é uma página única baseada em âncoras (`#boas-vindas`, etc.) sem roteamento client-side por path. Sem rewrite global, links ou ativos ausentes retornam HTTP 404 real em vez de mascarar erros com HTML.
