# Contrato: canal de plataforma `memora/aplicativos`

Código nativo novo, em Kotlin, para duas perguntas que o Flutter não responde
sozinho: **este aplicativo está instalado?** e **qual é o ícone dele?** (R7).

## Métodos

| Método | Argumento | Devolve | Quando falha |
|---|---|---|---|
| `estaInstalado` | `pacote` (texto) | `true` / `false` | Devolve `false`. Nunca lança para o Dart |
| `iconeDe` | `pacote` (texto) | PNG em bytes, 192×192 | Devolve `null`; a tela usa a ilustração genérica |

## Regras

1. **Só lê.** Abrir continua sendo do `AbridorDeAplicativo`, que já existe e já
   passa pela confirmação e pelo registro da 003. O canal não ganha `abrir`.
2. **Só enxerga o que está em `<queries>`.** É a regra do Android 11+, e é a
   certa: o Memora não pede `QUERY_ALL_PACKAGES` (decisão da 003). Um pacote
   fora da lista aparece como "não instalado".
3. **Recusa o que não parece pacote.** Argumento que não case com
   `^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$` devolve `false`/`null`
   sem consultar o sistema.
4. **Nenhuma permissão nova** no `AndroidManifest.xml`.

## Do lado do Dart

`app/lib/services/aplicativos/` — uma porta (`ConsultaDeAplicativos`) com o
adaptador do canal e um simulado. O simulado é o que roda em todo teste de
widget: canal de plataforma não existe em `flutter test`, e o simulado deixa o
teste escolher o que está instalado.

⚠️ **O ícone é cacheado em memória, por pacote, durante a execução.** A grade de
"Meus aplicativos" pede vários de uma vez, e cada pedido atravessa o canal.
