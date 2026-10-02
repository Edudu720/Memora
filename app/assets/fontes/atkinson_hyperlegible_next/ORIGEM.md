# Atkinson Hyperlegible Next — de onde veio

**Licença**: SIL Open Font License 1.1 — ver [`OFL.txt`](OFL.txt), que veio junto
com a fonte e é o que autoriza embarcá-la. O cabeçalho não declara nenhum
*Reserved Font Name*, então as instâncias derivadas podem manter o nome.

**Fonte original**: `ofl/atkinsonhyperlegiblenext/AtkinsonHyperlegibleNext[wght].ttf`,
do repositório [google/fonts](https://github.com/google/fonts), baixada em
2026-10-01. Projeto de origem: <https://github.com/googlefonts/atkinson-hyperlegible-next>.

## Por que três arquivos estáticos, e não o variável

O original é uma fonte **variável** (eixo `wght` de 200 a 800). No Flutter, o
`fontWeight` de um `TextStyle` não escolhe sozinho o ponto do eixo: cada texto
teria de passar `FontVariation('wght', …)`, e essa regra se espalharia por todos
os estilos. Com instâncias estáticas, `FontWeight.w400`, `w600` e `w700` — os
três pesos que `MemoraTipografia` usa — funcionam como em qualquer família.

Geradas com `fontTools` 4.60.1:

```powershell
py -m fontTools.varLib.instancer variavel.ttf wght=400 --update-name-table -o AtkinsonHyperlegibleNext-Regular.ttf
py -m fontTools.varLib.instancer variavel.ttf wght=600 --update-name-table -o AtkinsonHyperlegibleNext-SemiBold.ttf
py -m fontTools.varLib.instancer variavel.ttf wght=700 --update-name-table -o AtkinsonHyperlegibleNext-Bold.ttf
```

Cobertura conferida para o português: todos os acentos, `ç`, travessão,
reticências, aspas curvas, `º`, `ª` e `R$`.

**Precisa de outro peso?** Gere a partir do variável com o mesmo comando, e
declare o arquivo novo no `pubspec.yaml`.
