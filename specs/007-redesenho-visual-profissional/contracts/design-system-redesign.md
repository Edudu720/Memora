# Contrato de Componentes do Design System — Feature 007

Todos os widgets devem ser exportados por `app/lib/design_system/design_system.dart` e importar tokens exclusivamente de `tokens/` (zero literais visuais em `componentes/` ou `features/`).

---

## 1. Componentes Evoluídos (Compatibilidade Retroativa Obrigatória)

### 1.1 `Cartao` (`componentes/cartoes/cartao.dart`)
- **Regra 002/FR-012 (INEGOCIÁVEL)**: **Permanece estritamente não clicável** (`**Não é clicável.**` — NUNCA adicionar callback `aoTocar` ao `Cartao`).
- **Assinatura**: `const Cartao({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(MemoraEspacamento.lg), bool comBorda = false, super.key})`
- **Estilo**: Fundo `cores.superficie`, `BorderRadius.circular(MemoraRaio.cartao)`, sombras de `MemoraElevacao.listaSombrasCartao(cores)` (no Claro), `bordaSutil` (`1 px`) para definição no Escuro e automaticamente `Border.all(color: cores.borda, width: MemoraDimensoes.bordaEnfase)` no `altoContraste` ou quando `comBorda == true`.

### 1.2 `CaixaDeEtapa` (`componentes/cartoes/caixa_de_etapa.dart`)
- **Assinatura preservada**: `const CaixaDeEtapa({required String instrucao, required Widget child, super.key})`
- **Invariante de Acessibilidade**: Mantém `Semantics(container: true, explicitChildNodes: true)` lendo `instrucao` antes de `child`; também sem API de toque.
- **Evolução visual**: Substitui a faixa `#D8D8D8` + `Border.all(color: cores.borda)` por cartão branco limpo (`cores.superficie`), sombras suaves, cabeçalho tonal `cores.superficieSutil` e separador `1 px` `cores.bordaSutil` (revertendo para `cores.borda` no Alto Contraste).

### 1.3 `NavegacaoInferior` (`componentes/navegacao/navegacao_inferior.dart`)
- **Destinos da Casca**: mantém exatamente os **3 destinos fixos** (`Ajustes`, `Início`, `Meu perfil`).
- **Contrato visual**:
  - Fundo `cores.superficieBarra` com separador superior `cores.bordaSutil` (`1 px`) + `MemoraElevacao.listaSombrasBarra(cores)`.
  - Item ativo recebe pílula tonal envolvente no ícone (`cores.destaque`) e indicador superior (`MemoraDimensoes.indicadorAtivoBarra` em `cores.primaria`), com rótulo escrito em `cores.primaria` (negrito).
  - Ícone **e** rótulo escrito visíveis em todos os itens (`>= 48x48 dp`, altura mínima `>= 56 dp`, seguro a `200%` em `320 px`).

### 1.4 `CabecalhoDeTela` & `BarraSuperior` (`componentes/navegacao/`)
- Fundo transparente sobre `cores.fundo`, botão `"Voltar"` em pílula tonal sutil (`Icon + Texto`, `>= 48 dp`), título editorial (`MemoraTipografia.tituloSecao` / `tituloTela`) e slot opcional para `ExpressaoDaMemora.mini`.

### 1.5 `BalaoDeFala` (`componentes/conversa/balao_de_fala.dart`)
- Preserva `autor`, `texto`, `opcoes`, `escreverAosPoucos`, `emAndamento`, `aoEscrever`, `escrito` e TalkBack (`"Memora disse: ..."` / `"Você disse: ..."`).
- **Memora (esquerda)**: avatar `ExpressaoDaMemora.mini` em medalhão limpo, balão em `cores.superficie` + sombra difusa sem borda `#6B6B6B` no Claro.
- **Pessoa (direita)**: balão em `cores.superficieSutil` alinhado à direita, texto em `cores.texto` (`>= 4.5:1`).

### 1.6 `AvisoCompacto` (`componentes/avisos/aviso_compacto.dart`)
- Preserva assinatura (`titulo`, `resumo`, `textoCompleto`, `comMemora`, `abertoNoComeco`, `fechadoEmUmaLinha`, `fechadoSoEscudo`), sem botão de dispensar nem `Dismissible`.
- Quando `fechadoEmUmaLinha == true`, renderiza como pílula limpa de segurança no topo (`"Eu nunca peço sua senha nem código"` + escudo em `cores.perigo`, fundo limpo `cores.superficie`, `>= 48 dp` tocável para expandir).

---

## 2. Novos Componentes do Design System (`design_system.dart`)

### 2.1 Separação Herói: `PainelHeroi` (Informação) vs `CartaoHeroi` (Ação)
- **`PainelHeroi` (`componentes/informacao/painel_heroi.dart`)** — **estritamente não clicável** (sem `aoTocar`, como `Cartao` e `DestaqueInformacao` pela `002/FR-012`):
  - Uso: painel de leitura de saúde / status em `TelaDispositivoCuidado` (`gradienteSaudeInicio/Fim`, `sobreGradienteSaude`).
  - Props: `String titulo`, `String? valorDestaque` (`MemoraTipografia.destaque` tabular), `Widget? badgeStatus` (`BadgeDeStatus`), `Widget? visualEsquerda`, `Widget? rodape`.
- **`CartaoHeroi` (`componentes/cartoes/cartao_heroi.dart`)** — **estritamente ação** (`required VoidCallback aoTocar`, `Semantics(button: true)`):
  - Uso: destaque principal `"Conversar com a Memora"` no `Início`/`Hub` (`gradienteHeroiInicio/Fim`, `sobreGradienteHeroi`).
  - Pista visual obrigatória (Q2): exibe botão/pílula explícita de chamada ou indicador `rotuloAcao` + ícone de seta com contraste garantido (`>= 4.5:1`), texto em `MemoraTipografia.tituloSecao` + `apoio`.

### 2.2 `TileAcaoRapida` (`componentes/cartoes/tile_acao_rapida.dart`)
- **Uso**: grade `2x2` de atalhos no `Início`, `Hub`, sugestões na `Conversa` e ações em `Cuidado`.
- **Props**: `required IconData icone`, `required String titulo`, `String? subtitulo`, `required VoidCallback? aoTocar`, `VarianteBadge variacao` (`primario | saude | alerta | neutro`), `String? pistaAcao`, `super.key`.
- **Pista visual & Tipografia (Q2 & U3)**: cartão branco (`cores.superficie`, `MemoraRaio.cartaoMedio`), badge quadrado `MemoraDimensoes.badgeAtalhoRapido` (`MemoraRaio.badge`), título em `MemoraTipografia.corpoForte`, subtítulo em `MemoraTipografia.apoio`, **indicador explícito de ação (`Icons.arrow_forward_rounded` / pílula discreta)** + contorno tonal (`bordaSutil` ou `borda` no Alto Contraste) para distinguir nitidamente de `Cartao` passivo.

### 2.3 `ChipFiltro` & `BadgeDeStatus` (`componentes/selecao/chip_filtro.dart`, `componentes/informacao/badge_de_status.dart`)
- `ChipFiltro`: pílula segmentada selecionável (`selecionado`, `rotulo`, `icone`, `aoTocar`), `minHeight >= 48 dp`, texto em `MemoraTipografia.apoio` negrito.
- `BadgeDeStatus`: selo **estritamente informativo** (sem callback de toque — testado em `informacao_nao_e_acao_test.dart`), tipografia `MemoraTipografia.apoio`, cores `saudeSuave` + `sucessoTexto` ou tokens semânticos de alerta/perigo.

### 2.4 `LinhaDeLista` (`componentes/informacao/linha_de_lista.dart`)
- Item horizontal limpo (`design-2`, `fkhvix`): `Widget? esquerda`, `required String titulo` (`MemoraTipografia.corpoForte`), `String? subtitulo` (`MemoraTipografia.apoio`), `VoidCallback? aoTocar`. Quando `aoTocar != null`, exibe obrigatoriamente seta direcional (`Icons.chevron_right_rounded`) + `SuperficieTocavel` (`>= 48 dp`); quando `aoTocar == null`, é meramente informativa (sem chevron nem handler).
