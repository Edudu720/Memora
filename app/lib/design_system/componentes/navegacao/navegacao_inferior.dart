import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/movimento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';
import 'icone_de_navegacao.dart';

/// Um destino da navegação inferior.
@immutable
class ItemNavegacao {
  /// Desenho do destino, da família única de ícones (FR-045).
  final IconeDeNavegacao icone;

  /// Rótulo escrito. **Obrigatório** (FR-016).
  final String rotulo;

  /// Cria um item de navegação.
  const ItemNavegacao({required this.icone, required this.rotulo});
}

/// Navegação inferior do Memora (feature 013, FR-044 a FR-047).
///
/// **Todo item tem ícone e rótulo escrito.** No protótipo, a barra inferior
/// tinha apenas três ícones — engrenagem, casa e pessoa — sem nenhum texto.
/// Ícone isolado depende de convenção que este público não necessariamente
/// conhece, e a FR-016 da 004 proíbe.
///
/// ## O indicador desliza
///
/// O traço no topo e a pílula atrás do ícone são **um só par**, que anda até o
/// destino tocado (FR-046) — em vez de apagar num item e acender no outro. Com
/// "reduzir movimento" ele muda de lugar sem deslizar. O destino atual
/// continua marcado por mais de um sinal além da cor: o traço, a pílula e o
/// rótulo em negrito, e o leitor de tela o anuncia como selecionado.
///
/// ## O acabamento
///
/// Superfície com sombra e os cantos de cima arredondados, como os demais
/// blocos (FR-047). Cada item responde ao toque pela `SuperficieTocavel`:
/// afunda e ganha o realce `destaque`; sem movimento, só o realce.
class NavegacaoInferior extends StatelessWidget {
  /// Destinos exibidos.
  final List<ItemNavegacao> itens;

  /// Índice do destino ativo.
  final int indiceAtivo;

  /// Acionada ao escolher um destino.
  final ValueChanged<int> aoSelecionar;

  /// Chave do traço do destino ativo (posição de 1 a N), para os testes. O
  /// traço é um só: o número da chave acompanha o destino atual.
  static Key chaveDoTraco(int posicao) => Key('navegacao.traco.$posicao');

  /// Chave da pílula que anda atrás do ícone do destino ativo.
  static const Key chaveDaPilula = Key('navegacao.pilula');

  /// Chave da caixa que reserva o ícone de cada destino, para os testes.
  static Key chaveDoIcone(int posicao) => Key('navegacao.icone.$posicao');

  /// Cria a navegação inferior.
  const NavegacaoInferior({
    required this.itens,
    required this.indiceAtivo,
    required this.aoSelecionar,
    super.key,
  }) : assert(itens.length >= 2, 'Navegação exige ao menos dois destinos.');

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    const BorderRadius cantos = BorderRadius.vertical(
      top: Radius.circular(MemoraRaio.cartao),
    );
    final bool reduzir = MediaQuery.disableAnimationsOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieBarra,
        borderRadius: cantos,
        boxShadow: MemoraElevacao.listaSombrasBarra(cores),
        // A sombra separa a barra do conteúdo; só no alto contraste, que não
        // tem sombra, o contorno faz esse papel.
        border: ehAltoContraste
            ? Border.all(color: cores.borda, width: MemoraDimensoes.bordaEnfase)
            : null,
      ),
      child: Material(
        color: cores.superficieBarra,
        borderRadius: cantos,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints restricoes) {
              final double larguraDoItem = restricoes.maxWidth / itens.length;
              // O centro do destino ativo, menos a metade do indicador.
              final double esquerda =
                  indiceAtivo * larguraDoItem +
                  (larguraDoItem - MemoraDimensoes.larguraDaPilulaDeNavegacao) /
                      2;
              return Stack(
                children: <Widget>[
                  AnimatedPositioned(
                    duration: MemoraMovimento.efetiva(
                      MemoraMovimento.padrao,
                      reduzirMovimento: reduzir,
                    ),
                    curve: MemoraMovimento.curvaDeTela,
                    left: esquerda,
                    top: 0,
                    child: Container(
                      key: NavegacaoInferior.chaveDoTraco(indiceAtivo + 1),
                      height: MemoraDimensoes.indicadorAtivoBarra,
                      width: MemoraDimensoes.larguraDaPilulaDeNavegacao,
                      decoration: BoxDecoration(
                        color: cores.primaria,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(MemoraRaio.pilula),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: MemoraMovimento.efetiva(
                      MemoraMovimento.padrao,
                      reduzirMovimento: reduzir,
                    ),
                    curve: MemoraMovimento.curvaDeTela,
                    left: esquerda,
                    // O respiro do item, o lugar do traço e mais um respiro:
                    // é onde a caixa do ícone está dentro de cada item.
                    top:
                        MemoraEspacamento.xs +
                        MemoraDimensoes.indicadorAtivoBarra +
                        MemoraEspacamento.xs,
                    child: Container(
                      key: NavegacaoInferior.chaveDaPilula,
                      width: MemoraDimensoes.larguraDaPilulaDeNavegacao,
                      height: MemoraDimensoes.alturaDaPilulaDeNavegacao,
                      decoration: BoxDecoration(
                        color: cores.destaque,
                        borderRadius: BorderRadius.circular(MemoraRaio.pilula),
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      for (int i = 0; i < itens.length; i++)
                        Expanded(
                          child: _Item(
                            item: itens[i],
                            ativo: i == indiceAtivo,
                            posicao: i + 1,
                            total: itens.length,
                            aoTocar: () => aoSelecionar(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final ItemNavegacao item;
  final bool ativo;
  final int posicao;
  final int total;
  final VoidCallback aoTocar;

  const _Item({
    required this.item,
    required this.ativo,
    required this.posicao,
    required this.total,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final Color cor = ativo ? cores.primaria : cores.texto;

    // O traço e a pílula do destino ativo andam por cima desta coluna (ver
    // `NavegacaoInferior`): aqui só se reserva o lugar deles, na mesma altura
    // em todos os itens. A pílula sozinha não bastaria — o `destaque` mede só
    // 1,1 a 1,6:1 contra a barra —, e por isso o traço, que é par validado
    // como gráfico (primária sobre superficieAlt), vem junto, com o rótulo em
    // negrito.
    return Padding(
      padding: const EdgeInsets.all(MemoraEspacamento.xs),
      child: SuperficieTocavel(
        rotulo: item.rotulo,
        dica: '$posicao de $total',
        selecionada: ativo,
        aoTocar: aoTocar,
        fundo: Colors.transparent,
        raio: BorderRadius.circular(MemoraRaio.cartaoMedio),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MemoraDimensoes.alvoDecisao,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: MemoraDimensoes.indicadorAtivoBarra),
              const SizedBox(height: MemoraEspacamento.xs),
              SizedBox(
                width: MemoraDimensoes.larguraDaPilulaDeNavegacao,
                height: MemoraDimensoes.alturaDaPilulaDeNavegacao,
                // Os três desenhos ocupam a mesma caixa, atual ou não.
                child: Center(
                  child: SizedBox(
                    key: NavegacaoInferior.chaveDoIcone(posicao),
                    width: MemoraDimensoes.iconeDestaque,
                    height: MemoraDimensoes.iconeDestaque,
                    // Decoração: o destino é anunciado pelo rótulo escrito.
                    child: ExcludeSemantics(
                      child: Icon(
                        item.icone.dados,
                        size: MemoraDimensoes.iconeDestaque,
                        color: cor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              // Rótulo escrito, sempre.
              TextoMemora(
                item.rotulo,
                estilo: ativo ? EstiloTexto.corpoForte : EstiloTexto.apoio,
                cor: cor,
                alinhamento: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
