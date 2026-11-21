# Research: Ícones SVG para e-Título, FGTS e Instagram (Item 13)

## Decisão 1 — Padrão compartilhado de pasta, nome e `viewBox`

- **Decisão**: Salvar em `app/assets/icones_apps/<chave>.svg` usando a chave exata do catálogo (`e-titulo.svg`, `fgts.svg`, `instagram.svg`) com `viewBox="0 0 48 48"`.
- **Justificativa**: Alinhado diretamente com `@Du3101` nos comentários da Issue #106 para que todos os novos ícones sigam a mesma convenção e declaração única `- assets/icones_apps/` em `app/pubspec.yaml`.

## Decisão 2 — Primitivos SVG suportados com segurança pelo `flutter_svg`

- **Decisão**: Utilizar apenas `<svg>`, `<defs>`, `<linearGradient>`, `<radialGradient>`, `<stop>`, `<rect>`, `<circle>` e `<path>` com coordenadas inteiras/decimais simples no sistema `0..48`.
- **Justificativa**: O parser do `flutter_svg` não executa `<script>` nem CSS complexo e não garante consistência tipográfica para `<text>`. Geometria pura com `path` garante renderização idêntica no Android e nos testes headless (`flutter test`), sem risco de XSS/SSRF.

## Decisão 3 — Isolamento contra conflitos com o Item 6 (`016`)

- **Decisão**: Alterar apenas os ramos `instagram`, `e-titulo` (`normalizada.contains('titulo')`) e `fgts` em `IconeDoAplicativo` e remover somente `_CameraInstagramPainter` e `dart:math` (não usado fora dele).
- **Justificativa**: Os demais apps (`meu-inss`, `tiktok`, `youtube`, `google-fotos`, etc.) pertencem ao Item 6 (`specs/016-ajustes-pos-redesenho`); preservar esses ramos evita conflitos no merge com a PR do colega.
