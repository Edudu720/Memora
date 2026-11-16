# Como usar o Design System do Memora

> Este guia é a T048 da feature 002. Ele responde **como se constrói uma tela
> aqui** — não descreve os componentes um a um, porque para isso existe a
> galeria, que está sempre certa por construção. O que está escrito aqui é o
> que a galeria não mostra: as razões.

**A galeria fica na aba "Componentes"** da casca de demonstração, em build de
desenvolvimento. Ela monta todo componente em todo estado, nos três temas e em
toda a faixa de ampliação. Antes de criar um componente novo, abra a galeria:
metade dos "preciso de um componente" morre ali.

---

## 1. A regra de importação

```dart
import 'package:memora/design_system/design_system.dart';
```

**Este é o único import.** Puxar de `design_system/tokens/` ou
`design_system/temas/` diretamente atravessa a fronteira do sistema — funciona,
e é assim que a erosão começa.

---

## 2. Cor, espaçamento e tamanho vêm de token. Sempre

```dart
// ❌ não compila a verificação
padding: const EdgeInsets.all(16),
Icon(Icons.check, size: 24),
color: const Color(0xFF1040F8),

// ✅
padding: const EdgeInsets.all(MemoraEspacamento.lg),
Icon(Icons.check, size: MemoraDimensoes.iconePadrao),
color: cores.primaria,
```

O portão é `specs/002-design-system/ferramentas/validar_tokens.py`, e ele roda
no CI como job próprio. **Valor que não existe em token nenhum não é motivo
para escrever literal** — é motivo para criar o token, com a razão escrita ao
lado dele.

Isso não é zelo estético. Quando esse portão foi escrito, ele encontrou **sete**
tamanhos de ícone diferentes no aplicativo (18, 20, 22, 24, 28, 56 e 72),
nenhum declarado em lugar nenhum, e quatro deles para a mesma situação — "ícone
ao lado de texto", escritos por pessoas diferentes em dias diferentes. Ninguém
decidiu que seriam quatro. É assim que a consistência se perde: sem decisão.

### Onde mora cada coisa

| Token | O que guarda |
|---|---|
| `MemoraCores` | as cores semânticas, por tema — via `context.memora.cores` |
| `MemoraEspacamento` | `xs` a `xxl` |
| `MemoraDimensoes` | alvo de toque, ícone, borda, indicador, escala de texto |
| `MemoraRaio` | cantos, incluindo a pílula |
| `MemoraElevacao` | sombra e sua cor |
| `MemoraTipografia` | os cinco estilos de texto |
| `MemoraMovimento` | durações e curvas |

### A cor vem do tema, não do token direto

```dart
final MemoraCores cores = context.memora.cores;
```

`MemoraCores.claro` só é referenciado dentro de `temas/`. Escrevê-lo numa tela
prende aquela tela ao tema claro, e o tema de alto contraste — que é requisito
de acessibilidade, não preferência — deixa de valer ali.

---

## 3. Ação usa pílula e preenchimento. Informação nunca usa nenhum dos dois

É a FR-012, e é o que permite reconhecer o que responde ao toque **sem tocar**.

Os componentes de `componentes/informacao/` **não aceitam callback de toque**.
Não é esquecimento: é ausência de API deliberada. Se você precisa que um dado
responda ao toque, o certo não é acrescentar esse callback — é perguntar se
aquilo é dado ou é ação.

---

## 4. Todo `Text` passa por `escalaTextoLimitada(context)`

Ou, melhor, use `TextoMemora`, que já faz isso. Sem o limitador, o componente
diverge dos demais em ampliação extrema e o layout quebra de um jeito
imprevisível.

O teto é `MemoraDimensoes.escalaTextoMax` (200%). Ele existe porque, sem teto,
o layout quebra em casos extremos e a pessoa fica sem saída (R7).

---

## 5. Texto dentro de `Row` quer `Flexible`

```dart
// ❌ estoura a largura quando o texto cresce
Row(children: <Widget>[Icon(...), SizedBox(...), Text('Mostrar senha')])

// ✅
Row(children: <Widget>[Icon(...), SizedBox(...), Flexible(child: Text(...))])
```

Sem `Flexible`, o texto exige a largura natural dele — e a largura natural
cresce com a ampliação. Esse defeito existiu de verdade no `CampoSenha`:
estourava 31 px pela direita num aparelho de 320 dp **já em 100%**, e 265 px em
200%, nas três telas que pedem senha.

**A mesma família de erro em altura**: teto de layout se mede em fração da tela
disponível, nunca em número de pixels. Um teto de 420 px cabe num 390×844 e não
cabe num 360×640.

---

## 6. Alvo de toque

`MemoraDimensoes.alvoMinimo` são 48 dp — o mínimo da WCAG 2.2. Em ponto de
**decisão**, onde um toque acidental tem consequência, use
`MemoraDimensoes.alvoDecisao` (56 dp).

`Semantics(button: true)` **não basta**: sem `onTap` na própria `Semantics`, o
TalkBack anuncia o botão e o duplo-toque não ativa nada. Isso já custou um
defeito real.

---

## 7. Cor nunca carrega significado sozinha

Princípio III. Erro tem ícone **e** texto; estado selecionado tem contorno mais
grosso **e** cor; quem falou numa conversa é dito por posição, cor **e** rótulo.

Pela mesma razão, sombra não é sinal de que algo é clicável: ela é praticamente
invisível para quem tem baixa visão. Forma e cor carregam; a elevação reforça.

E não use `Opacity` para estado desabilitado — ela derruba o contraste do
rótulo para 2,79:1. Use `superficieAlt` com `textoSuave`, que mede 6,22:1.

---

## 8. Antes de criar um componente novo

Três perguntas, nesta ordem:

1. **A galeria já tem?** Abra e procure. É mais rápido que escrever.
2. **Serve a mais de uma tela?** Se sim, o lugar é `design_system/componentes/`,
   nunca dentro de `features/`.
3. **Um idoso conseguiria usar isso sozinho?** É a pergunta que valida qualquer
   decisão neste projeto.

Componente novo entra na galeria **na mesma PR**. Um componente que não está na
galeria é um componente que ninguém vai achar — e, meses depois, alguém escreve
o segundo.

---

## 9. O que rodar antes de dizer que terminou

```powershell
cd app; flutter analyze; flutter test
```

```powershell
py specs/002-design-system/ferramentas/validar_paleta.py
```

```powershell
py specs/002-design-system/ferramentas/validar_tokens.py
```

Os três são portões do CI. E há um quarto, que não é comando: **quebre o portão
de propósito antes de confiar nele.** Teste que passa não prova que o portão
funciona — neste projeto, um portão de acessibilidade já passou com o defeito
presente, porque procurava o ícone errado. Só apareceu ao ser quebrado.

---

## 10. Se você mexer na paleta

`tokens/cores.dart` é a contraparte em código de `validar_paleta.py`. **Alterar
um valor lá sem rodar o validador é como um par de contraste reprova em
silêncio.** São 51 pares nos três temas, e o de alto contraste exige 7:1 onde os
outros exigem 4,5:1.

O azul `#1040F8` veio do protótipo e mede 6,75:1 com texto branco. A identidade
visual foi preservada de propósito — não a altere sem medir.

---

## 11. Padrão Visual 2.0 e Tokens Evoluídos (Feature 007)

A partir da Feature `007-redesenho-visual-profissional`, o Design System passa a
separar blocos por **fundo, respiro e elevação sutil**, em vez de contornar
tudo com bordas escuras de wireframe:

- **Superfícies em `MemoraCores`**: `fundo` funciona como canvas suave
  (`#F4F6FA` no tema Claro), contrastando com `superficie` (`#FFFFFF`),
  `superficieSutil` (faixas, badges neutros e balão da pessoa),
  `superficieBarra` (navegação inferior e barra do chat) e `bordaSutil` para
  divisores leves de `1 dp`. No tema **Alto Contraste**, os contornos reforçados
  (`borda`, `>= 3:1`) continuam automáticos e obrigatórios.
- **Gradientes e Saúde**: `gradienteHeroiInicio` / `gradienteHeroiFim` com texto
  em `sobreGradienteHeroi`, e `gradienteSaudeInicio` / `gradienteSaudeFim` com
  `sobreGradienteSaude`, `saudeSuave` e `sucessoTexto` garantem leitura segura em
  todos os 3 temas × 6 paletas.
- **Elevação padronizada (`MemoraElevacao`)**: use
  `MemoraElevacao.listaSombrasCartao(cores)` e
  `MemoraElevacao.listaSombrasBarra(cores)` — ambos devolvem lista vazia no tema
  Alto Contraste, onde o sinal visual passa para a borda reforçada.
- **Dimensões e raios 2.0**: `MemoraDimensoes.badgeAtalhoRapido` (`48.0`),
  `espessuraBordaSutil` (`1.0`), `indicadorAtivoBarra` (`3.0`),
  `escalaColapsoGrade` (`1.5`), `larguraMinimaGrade` (`300`), além de
  `MemoraRaio.badge` (`14`), `cartaoMedio` (`20`) e `cartaoDestaque` (`24`).

---

## 12. Novos componentes da versão 2.0 (Informação vs. Ação)

A fronteira da `002/FR-012` permanece estrita nos novos blocos:

| Componente | Papel | Pode tocar (`aoTocar`)? | Observações |
|---|---|---|---|
| `PainelHeroi` | Resumo principal de saúde/dados | **Não** | `Semantics(button: false, readOnly: true)`, algarismos tabulares |
| `BadgeDeStatus` | Selo curto (`TomBadgeStatus`: `positivo`, `atencao`, `informativo`, `neutro`) | **Não** | Piso de `16 sp`, nunca formato de pílula clicável |
| `LinhaDeLista` (sem `aoTocar`) | Linha informativa em lista | **Não** | Sem seta nem superfície de toque |
| `CartaoHeroi` | Ação principal da tela (ex.: conversar) | **Sim (obrigatório)** | Pista explícita (`rotuloAcao` + seta) e semântica de botão |
| `TileAcaoRapida` | Atalho de grade com badge (`VarianteBadge`) | **Sim (opcional)** | Badge `48 dp` ocultado em ampliações extremas, pista `"Abrir"` |
| `ChipFiltro` | Filtro interativo em formato pílula | **Sim (obrigatório)** | Alvo mínimo `48 dp`; seleção por preenchimento, negrito e ícone |
| `LinhaDeLista` (com `aoTocar`) | Navegação ou item acionável em grupo | **Sim** | Exibe seta de navegação e respeita alvo mínimo `48 dp` |

---

## 13. Mascote unificado (`MemoraPersonagem`)

`ExpressaoDaMemora` centraliza as **6 expressões oficiais em PNG** de alta
resolução em `app/assets/ilustracoes/`:

- `neutra` (`memora_perfil_robo.png`) — repouso, boas-vindas, perfil, saúde;
- `falando` (`memora_ajuda_robo.png`) — conversa, ajuda e orientações;
- `comemorando` (`memora_conclusao_robo.png`) — conclusão de etapa ou conta criada;
- `preocupada` (`memora_alerta_robo.png`) — avisos antigolpe e atenção imediata;
- `dica` (`memora_dica_robo.png`) — cartões de sugestão, exemplo guiado e dicas;
- `mini` (`memora_mini_robo.png`) — emblema compacto para balões e cabeçalhos estreitos.

---

## 14. Ditado por voz na Conversa (`FR-013`)

O microfone da conversa segue os **Princípios I e II da Constituição**:

1. **Domínio isolado**: o contrato `LeitorDeVoz` (`EstadoDitado`,
   `ResultadoDitado`) e a implementação nativa `LeitorDeVozSpeechToText`
   (`pt_BR`) operam exclusivamente em memória. Nenhum áudio é gravado em disco
   nem registrado em logs.
2. **Explicação antes da permissão**: no primeiro acionamento de
   `TelaConversa.chaveMicrofone`, um diálogo prévio
   (`TelaConversa.chaveDialogoPermissaoVoz`) explica o motivo do uso do microfone
   antes da abertura do canal nativo.
3. **Somente rascunho, sem envio automático**: o texto ditado preenche o campo de
   mensagem (`rascunho`) no `ControladorConversa` para a pessoa conferir e tocar
   em enviar manualmente, acompanhado por uma faixa acessível com
   `liveRegion: true` (`TelaConversa.chaveStatusVoz`) em caso de escuta,
   indisponibilidade ou erro.

