# Fase 1 — Contrato dos Componentes

**Feature**: 002-design-system

> Este é o **contrato** do Design System: o que cada componente garante a quem o
> usa. Uma tela que use apenas estes componentes é acessível **por construção** —
> quem constrói não precisa lembrar de contraste, área de toque ou semântica.

---

## Garantias universais

Todo componente interativo da biblioteca garante, sem configuração:

1. Área de toque ≥ **48 dp**, com ≥ 8 dp de separação (FR-009)
2. Contraste validado em todos os temas (FR-003)
3. Rótulo e estado expostos a leitores de tela (FR-010)
4. Estados visuais distintos: normal, foco, pressionado, carregando, desabilitado,
   erro (FR-011)
5. Funciona com texto até escala 2,0, sem corte (FR-025)
6. Acionável por **toque simples** — nenhum gesto complexo (FR-015)
7. Respeita "reduzir movimento" (FR-027)

**Quem usa não pode desligar nenhuma dessas garantias.** Não há parâmetro para
reduzir a área de toque nem para passar cor arbitrária.

---

## Ação — `botoes/`

| Componente | Uso | Altura | Observação |
|---|---|---|---|
| `BotaoPrimario` | Ação principal da tela | 56 dp | Um por tela. Preenchido com `primaria` |
| `BotaoSecundario` | Ação alternativa | 56 dp | Contornado |
| `BotaoTerciario` | Ação de baixo peso | 48 dp | Só texto, com sublinhado |
| `BotaoPerigo` | Ação destrutiva | 56 dp | `perigo` + ícone. **Nunca adjacente a outro botão** (FR-013) |

**Regra**: todo botão exige `rotulo` textual. **Não existe** botão apenas com ícone
(FR-016).

---

## Confirmação — `confirmacao/`

### `ConfirmacaoMemora`

Substitui os botões SIM/NÃO do protótipo. Ver R2 e R3 para a medição que motivou.

| Garantia | Valor |
|---|---|
| Disposição | **Vertical, largura total** — elimina o toque acidental por proximidade |
| Altura de cada opção | **56 dp** |
| Rótulos | Frase completa: *"Sim, pode abrir"* / *"Agora não"* — nunca palavra isolada |
| Hierarquia | Confirmar é preenchido; recusar é contornado, mas **nunca escondido** |
| Sinalização | Ícone **e** texto — cor nunca sozinha |

**Variante `irreversivel`**: a ação destrutiva aparece separada por espaçamento
maior, em `perigo`, e exige **segunda confirmação**. Atende ao Princípio VI — a
assistente nunca age sem confirmação deliberada.

---

## Informação — `informacao/`

> Existe para tornar **estruturalmente difícil** repetir o erro do Perfil, em que
> dados apareciam como pílulas azuis idênticas aos botões do Hub (FR-012).

| Componente | Uso |
|---|---|
| `CampoInformacao` | Rótulo + valor. **Sem** fundo preenchido, **sem** forma de pílula, **sem** retorno ao toque |
| `ListaInformacao` | Vários campos agrupados |
| `DestaqueInformacao` | Informação de ênfase, ainda claramente não clicável |

**Contrato negativo**: estes componentes **não aceitam** callback de toque. Se
alguém precisar de ação, precisa usar um botão — e a diferença fica visível.

---

## Entrada — `campos/`

| Componente | Observação |
|---|---|
| `CampoTexto` | Rótulo **acima e sempre visível** — placeholder não é rótulo (FR-030 da spec 001) |
| `CampoSenha` | Com controle de revelar, **rotulado em texto**. Desativável para o modo assistido (FR-060 da 001) |
| `CampoCodigo` | 6 dígitos, teclado numérico, avanço automático |

Todo campo exige `textoAjuda` explicando **para que serve o dado** (FR-004 da 001).

---

## Estrutura — `cartoes/`, `dialogos/`, `navegacao/`

| Componente | Observação |
|---|---|
| `Cartao` | Agrupa conteúdo. Não é clicável por padrão |
| `Dialogo` | Interrupção modal. Sempre com saída clara |
| `FolhaInferior` | Escolha entre opções |
| `BarraSuperior` | Título e retorno. Voltar sempre com rótulo textual |
| `NavegacaoInferior` | **Ícone + rótulo** em todos os itens (FR-016) |

---

## Retorno — `feedback/`

| Componente | Observação |
|---|---|
| `Carregando` | Aparece em qualquer espera perceptível (FR-033 da 001) |
| `MensagemErro` | Ícone + texto. **Nunca só cor** (FR-032 da 001). Tom acolhedor, jamais culpando a pessoa |
| `EstadoVazio` | Explica o que houve e o que fazer em seguida |

---

## Regras para quem usa

1. **Nenhum valor literal.** Cor, espaçamento e tamanho vêm sempre do tema (FR-002).
   Verificado por análise estática (FR-032).
2. **Nenhum widget de UI cru** em tela de feature quando existir componente
   equivalente aqui.
3. **Componente novo entra na biblioteca**, com teste e entrada na galeria — nunca
   nasce dentro de uma feature.
4. **Alterar token exige rodar o validador.** `validar_paleta.py` falha o build se
   qualquer par reprovar.
