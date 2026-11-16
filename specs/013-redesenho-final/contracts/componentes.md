# Contrato dos componentes — feature 013

Contrato de interface de cada componente novo do Design System. Os nomes são o
que as telas vão chamar; os detalhes de desenho ficam para a implementação.

---

## MemoraAnimada

`app/lib/design_system/componentes/ilustracao/memora_animada/`

| Entrada | Tipo | Obrigatória | Significado |
|---|---|---|---|
| `expressao` | `ExpressaoDaMemora` | sim | pose atual; trocar interpola até a nova |
| `tamanho` | `double` | sim | lado do quadrado que ela ocupa |
| `falando` | `bool` | não (falso) | liga o ciclo de fala (sincroniza com o texto que aparece) |
| `reageAoToque` | `bool` | não (verdadeiro) | aceno/piscada ao toque (FR-005a) |
| `gesto` | `GestoDaMemora?` | não | dispara um gesto único (ex.: comemoração) |

**Garantias**:
- fora da árvore de semântica (`ExcludeSemantics`), sempre (FR-005, FR-005b);
- com "reduzir movimento" (do aplicativo ou do sistema): pose parada, sem gesto
  ao toque (FR-004, FR-005d);
- toda duração passa por `MemoraMovimento.efetiva` (V9);
- isolada em camada de repintura própria e parada quando fora da tela (R11);
- cores só de tokens (`validar_tokens.py`);
- reconhecível nos três temas, contorno ≥ 3:1 com o fundo (FR-007).

**Substitui**, na Fase B, o desenho interno da `MemoraPersonagem`; a
`MemoraPersonagem` mantém a mesma assinatura e passa a montar uma `MemoraAnimada`.

## RotaMemora\<T\>

`app/lib/design_system/navegacao/rota_memora.dart`

| Entrada | Tipo | Significado |
|---|---|---|
| `builder` | `WidgetBuilder` | a tela |
| `direcao` | `DirecaoDaTransicao` | padrão `avancar`; o voltar é o inverso automático |

**Garantias**: duração `MemoraMovimento.efetiva(lento)` (≤ 500 ms, SC-004);
instantânea com "reduzir movimento"; a tela que sai não recebe toque durante a
transição; o gesto de voltar do sistema faz a mesma animação (FR-015).

Também exposta como `TransicaoMemora`, um construtor de transição de página
para o tema (Fase B).

## TrocaDeDestino

`app/lib/design_system/navegacao/troca_de_destino.dart`

| Entrada | Tipo | Significado |
|---|---|---|
| `indice` | `int` | destino visível |
| `filhos` | `List<Widget>` | um por destino (os `Navigator`s da casca) |

**Garantias**: todos os filhos continuam vivos (a pilha de cada destino é
preservada); o que entra desliza do lado da posição relativa; os que estão
fora da tela não animam nem recebem foco; instantânea com "reduzir movimento".

## AberturaMemora

`app/lib/features/abertura/presentation/abertura_memora.dart`

| Entrada | Tipo | Significado |
|---|---|---|
| `carregar` | `Future<Composicao> Function()` | o trabalho que hoje roda antes do `runApp` |
| `aoConcluir` | `void Function(Composicao)` | entrega o resultado e sai |
| `aoFalhar` | `void Function(Object)` | vai à tela de erro |

**Garantias**: a Memora acena centralizada, na mesma posição da abertura
nativa; sai quando o carregamento terminou **e** o aceno em curso completou;
frase de "quase pronta" depois de 4 s; com "reduzir movimento" do sistema, pose
de aceno parada (FR-036 a FR-039).

## limitarEmoji

`app/lib/features/assistente/domain/limitar_emoji.dart`

`String limitarEmoji(String texto)` — função pura: devolve o texto com no máximo
o primeiro emoji; os seguintes são removidos sem deixar espaço duplo (FR-024).

## Portão do texto da interface

`app/test/design_system/texto_da_interface_test.dart` (aplicativo) e
`TextoDaInterfaceTest` (backend).

**Reprova** com: bloco de mais de duas frases; palavra ou frase proibida; emoji
fora da fala da IA. **Prova**: quebrado de propósito com um caso de cada antes
de ser dado como pronto.
