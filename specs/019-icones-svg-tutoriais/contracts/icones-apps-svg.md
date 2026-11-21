# Contrato de Ativo Vetorial: `app/assets/icones_apps/<chave>.svg`

## Convenção de Caminho e Formato

- **Diretório**: `app/assets/icones_apps/` (declarado como `- assets/icones_apps/` em `app/pubspec.yaml`).
- **Nomenclatura**: `<chave>.svg`, idêntica à coluna `chave` do catálogo (`e-titulo.svg`, `fgts.svg`, `instagram.svg`).
- **Dimensão lógica**: `viewBox="0 0 48 48"` (sem unidades fixas exóticas; proporção 1:1).

## Restrições de Segurança e Compatibilidade

1. Proibido conter `<script`, `onload`, `onerror`, `<foreignObject`, `<image`, `<text`, `javascript:`, `http://` ou `https://`.
2. Cores sólidas ou gradientes definidos inline em `<defs>` (compatíveis com `flutter_svg ^2.0.17`).
3. Renderizado em `IconeDoAplicativo` dentro de `MediaQuery.withNoTextScaling` e `ClipRRect`, com `SvgPicture.asset(..., width: tamanho, height: tamanho, fit: BoxFit.cover, excludeFromSemantics: true)`.
