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
   passa pela confirmação e pelo registro da 003. Este canal não ganha `abrir`;
   abrir tem canal próprio (`memora/abridor`, abaixo).
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

⚠️ **O ícone é cacheado em memória, por pacote, durante a execução.** A lista de
"Meus aplicativos" pede vários de uma vez, e cada pedido atravessa o canal.

---

# Contrato: canal de plataforma `memora/abridor` (T136)

Abrir outro aplicativo. Fica **separado** do `memora/aplicativos` de propósito:
aquele é só leitura, e essa garantia não se mistura com um método que muda o que
a pessoa vê.

| Método | Argumento | Devolve | Quando falha |
|---|---|---|---|
| `abrir` | `pacote` (texto) | `true` se a atividade de entrada foi iniciada, `false` se não | Devolve `false`. Nunca lança para o Dart |

## Regras

1. **Não decide autorização.** Quem decide se aquele aplicativo pode ser aberto
   é o servidor (`AutorizadorDeAcao`, consultando o catálogo), e a pessoa
   confirma antes (FR-015 da 003). O canal só executa o que já foi autorizado.
2. **Só abre o que está em `<queries>`** (Android 11+). Pacote fora da lista ou
   não instalado devolve `false`. Nenhuma permissão nova, nada de
   `QUERY_ALL_PACKAGES`.
3. **Recusa o que não parece pacote**, com a mesma expressão do
   `memora/aplicativos`, sem consultar o sistema. O lado Dart confere antes de
   chamar o canal.
4. **Abre pelo `getLaunchIntentForPackage`**, e não pelo `android_intent_plus`:
   o plugin não traduz `action_main` e a conferência dele
   (`MATCH_DEFAULT_ONLY`) recusa a atividade de entrada dos aplicativos.

Do lado do Dart: `AbridorDeAplicativoPorCanal`, em
`app/lib/features/assistente/data/abridor_de_aplicativo.dart`.
