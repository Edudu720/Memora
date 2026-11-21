# Implementation Plan: Ícones SVG para e-Título, FGTS e Instagram (Item 13)

**Branch**: `feature/019-icones-svg-tutoriais` | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/019-icones-svg-tutoriais/spec.md`

## Summary

Criar três arquivos SVG próprios em `app/assets/icones_apps/` (`e-titulo.svg`, `fgts.svg`, `instagram.svg`) com `viewBox="0 0 48 48"` em vetor puro seguro, registrar `- assets/icones_apps/` em `app/pubspec.yaml`, ligar os três casos no `IconeDoAplicativo` via `SvgPicture.asset` (removendo `_CameraInstagramPainter` e `dart:math` não utilizado), registrar origem em `LICENCAS.md` e validar com suíte dedicada + `flutter analyze`, `flutter test` e `validar_tokens.py`.

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7, SVG 1.1 compatível com `flutter_svg: ^2.0.17`
**Primary Dependencies**: `flutter_svg: ^2.0.17` (já declarada no `pubspec.yaml`)
**Storage**: N/A (ativos estáticos embarcados no bundle)
**Testing**: `flutter analyze`, `flutter test` (incluindo `icone_do_aplicativo_svg_test.dart`) e `py specs/002-design-system/ferramentas/validar_tokens.py`
**Target Platform**: Android (e testes headless em Windows/Linux)
**Project Type**: Flutter Design System + assets (`app/`)
**Performance Goals**: Vetores leves (< 2 KB cada) sem filtros pesados ou máscaras complexas
**Constraints**: `viewBox="0 0 48 48"`; zero `<script>`, `<image>`, `<text>` ou URLs externas; não editar ícones dos demais aplicativos (Item 6 / spec `016`)
**Scale/Scope**: 3 novos SVGs, `pubspec.yaml`, `icone_do_aplicativo.dart`, `LICENCAS.md`, 1 novo arquivo de teste e `CHANGELOG.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Princípio I & II (Segurança)**: PASS — SVGs estáticos locais auditados contra scripts, handlers, `foreignObject` e URLs externas.
- **Princípio III (Acessibilidade & `memora-ux`)**: PASS — Vetores nítidos em qualquer tamanho, decorativos (`excludeFromSemantics: true`), sempre acompanhados de texto nas telas.
- **Princípio IV (Spec Antes de Código)**: PASS — Ciclo SpecKit completo.
- **Documentação Viva**: PASS — `LICENCAS.md` e `CHANGELOG.md` atualizados juntos.

## Project Structure

### Documentation (this feature)

```text
specs/019-icones-svg-tutoriais/
├── spec.md
├── plan.md
├── research.md
├── quickstart.md
├── checklists/
│   └── requirements.md
├── contracts/
│   └── icones-apps-svg.md
└── tasks.md
```

### Source Code (repository root)

```text
app/
├── assets/
│   ├── icones_apps/
│   │   ├── e-titulo.svg
│   │   ├── fgts.svg
│   │   └── instagram.svg
│   └── ilustracoes/
│       └── LICENCAS.md
├── lib/design_system/componentes/ilustracao/
│   └── icone_do_aplicativo.dart
├── pubspec.yaml
└── test/design_system/
    └── icone_do_aplicativo_svg_test.dart
CHANGELOG.md
```

**Structure Decision**: Adota exatamente o caminho combinado na Issue #106 (`app/assets/icones_apps/<chave>.svg`) para integrar naturalmente com o Item 6 (`@Du3101`) sem conflito de merge.

## Complexity Tracking

Nenhuma violação constitucional ou complexidade extra.
