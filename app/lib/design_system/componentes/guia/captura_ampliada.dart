import 'package:flutter/material.dart';

import '../../../features/aprendizado/domain/guia.dart';
import '../../../l10n/textos_guias.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/movimento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_secundario.dart';
import '../texto/texto_memora.dart';
import 'captura_com_destaque.dart';
import 'selo_exemplo.dart';

/// A captura de um passo em tela cheia, para quem enxerga pouco (T134,
/// FR-028b).
///
/// ## Por que não basta a pinça
///
/// O gesto de dois dedos é difícil para muitas pessoas idosas e não pode ser o
/// único caminho (WCAG 2.2, critérios 2.5.1 e 2.5.7). Por isso há botões
/// **"Aproximar"** e **"Afastar"**, em degraus de 1x a [escalaMaxima]; e
/// aproximar leva direto ao destaque, para ninguém ter de arrastar a imagem
/// até achar o ponto. Com a imagem ampliada, um toque simples nela a
/// centraliza naquele ponto — a alternativa de um dedo ao arrastar.
///
/// ## O que fica fixo e o que acompanha
///
/// O selo "Exemplo" e o "Fechar" **não** acompanham a escala: ficam na janela.
/// O anel do destaque, sim — é a [CapturaComDestaque] inteira que escala, e o
/// anel cai sobre a região da imagem em qualquer ampliação (FR-028c).
///
/// ## Abre na pilha da casca
///
/// [abrir] usa o `Navigator` mais próximo, o da pilha da casca: a inatividade
/// e a saída a fecham como a qualquer outra rota. Com "reduzir movimento" a
/// rota aparece sem transição e a aproximação por botão é instantânea.
class CapturaAmpliada extends StatefulWidget {
  /// Chave do botão "Fechar".
  static const Key chaveFechar = Key('ampliada.fechar');

  /// Chave do botão "Aproximar".
  static const Key chaveAproximar = Key('ampliada.aproximar');

  /// Chave do botão "Afastar".
  static const Key chaveAfastar = Key('ampliada.afastar');

  /// Chave do selo "Exemplo" da ampliação.
  static const Key chaveSelo = Key('ampliada.selo_exemplo');

  /// Chave do texto que diz quanto a imagem está ampliada.
  static const Key chaveAmpliacaoAtual = Key('ampliada.ampliacao_atual');

  /// Chave do `InteractiveViewer`.
  static const Key chaveVisor = Key('ampliada.visor');

  /// A imagem inteira.
  static const double escalaMinima = 1;

  /// O máximo que a imagem amplia, por botão ou por pinça.
  static const double escalaMaxima = 4;

  /// O passo cuja captura se amplia.
  final Passo passo;

  /// De onde vem a imagem; ver [CapturaComDestaque.imagem].
  final ImageProvider? imagem;

  /// A proporção, quando já se sabe; ver [CapturaComDestaque.proporcao].
  final double? proporcao;

  /// Cria a tela de ampliação. Quem a abre usa [abrir].
  const CapturaAmpliada({
    required this.passo,
    this.imagem,
    this.proporcao,
    super.key,
  });

  /// Abre a ampliação no `Navigator` mais próximo de [context].
  static Future<void> abrir(
    BuildContext context, {
    required Passo passo,
    ImageProvider? imagem,
    double? proporcao,
  }) {
    final Duration transicao = MemoraMovimento.efetiva(
      MemoraMovimento.padrao,
      reduzirMovimento: MediaQuery.disableAnimationsOf(context),
    );
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: transicao,
        reverseTransitionDuration: transicao,
        pageBuilder: (BuildContext _, Animation<double> _, Animation<double> _) =>
            CapturaAmpliada(
              passo: passo,
              imagem: imagem,
              proporcao: proporcao,
            ),
        transitionsBuilder:
            (
              BuildContext _,
              Animation<double> entrada,
              Animation<double> _,
              Widget filho,
            ) => FadeTransition(opacity: entrada, child: filho),
      ),
    );
  }

  @override
  State<CapturaAmpliada> createState() => _EstadoDaCapturaAmpliada();
}

class _EstadoDaCapturaAmpliada extends State<CapturaAmpliada>
    with SingleTickerProviderStateMixin {
  /// Abaixo disto a imagem conta como inteira; absorve ruído de ponto flutuante.
  static const double _tolerancia = 1e-3;

  final TransformationController _controle = TransformationController();
  late final AnimationController _animacao = AnimationController(vsync: this);
  final GlobalKey _chaveDaCena = GlobalKey(debugLabel: 'cena da ampliação');
  final GlobalKey _chaveDoAnel = GlobalKey(debugLabel: 'anel da ampliação');

  Matrix4Tween? _trajeto;
  Size _janela = Size.zero;

  @override
  void initState() {
    super.initState();
    _animacao.addListener(() {
      final Matrix4Tween? trajeto = _trajeto;
      if (trajeto != null) _controle.value = trajeto.evaluate(_animacao);
    });
  }

  @override
  void dispose() {
    _animacao.dispose();
    _controle.dispose();
    super.dispose();
  }

  double get _escala => _controle.value.getMaxScaleOnAxis();

  /// A matriz que mostra a escala [escala] com o ponto [cena] da imagem no
  /// meio da janela, sem deixar aparecer o que fica fora da imagem.
  Matrix4 _matrizCentradaEm(double escala, Offset cena) {
    final double x = (_janela.width / 2 - escala * cena.dx).clamp(
      _janela.width * (1 - escala),
      0.0,
    );
    final double y = (_janela.height / 2 - escala * cena.dy).clamp(
      _janela.height * (1 - escala),
      0.0,
    );
    return Matrix4(escala, 0, 0, 0, 0, escala, 0, 0, 0, 0, 1, 0, x, y, 0, 1);
  }

  /// Vai para [alvo]: de uma vez com "reduzir movimento", suave sem ele.
  void _irPara(Matrix4 alvo) {
    final Duration duracao = MemoraMovimento.efetiva(
      MemoraMovimento.padrao,
      reduzirMovimento: MediaQuery.disableAnimationsOf(context),
    );
    _animacao.stop();
    if (duracao == Duration.zero) {
      _trajeto = null;
      _controle.value = alvo;
      return;
    }
    _trajeto = Matrix4Tween(begin: _controle.value.clone(), end: alvo);
    _animacao
      ..duration = duracao
      ..forward(from: 0);
  }

  /// O centro do anel de destaque, nas coordenadas da imagem (da cena).
  Offset _centroDoDestaque() {
    final RenderObject? anel = _chaveDoAnel.currentContext?.findRenderObject();
    final RenderObject? cena = _chaveDaCena.currentContext?.findRenderObject();
    if (anel is RenderBox && cena is RenderBox && anel.hasSize) {
      return anel.localToGlobal(
        anel.size.center(Offset.zero),
        ancestor: cena,
      );
    }
    return _janela.center(Offset.zero);
  }

  void _aproximar() {
    final double proxima = ((_escala + _tolerancia).floor() + 1).toDouble();
    final double nova = proxima.clamp(
      CapturaAmpliada.escalaMinima,
      CapturaAmpliada.escalaMaxima,
    );
    _irPara(_matrizCentradaEm(nova, _centroDoDestaque()));
  }

  void _afastar() {
    final double proxima = ((_escala - _tolerancia).ceil() - 1).toDouble();
    final double nova = proxima.clamp(
      CapturaAmpliada.escalaMinima,
      CapturaAmpliada.escalaMaxima,
    );
    // Em 1x é a imagem inteira, sem translação.
    final Offset meio = _controle.toScene(_janela.center(Offset.zero));
    _irPara(_matrizCentradaEm(nova, meio));
  }

  /// Um toque simples na imagem ampliada a centraliza naquele ponto.
  void _centralizarEm(Offset cena) {
    if (_escala <= CapturaAmpliada.escalaMinima + _tolerancia) return;
    _irPara(_matrizCentradaEm(_escala, cena));
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TopoDaAmpliacao(
                controle: _controle,
                aoFechar: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: MemoraEspacamento.md),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cores.superficieAlt,
                    borderRadius: BorderRadius.circular(MemoraRaio.cartao),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (BuildContext _, BoxConstraints restricoes) {
                            _janela = restricoes.biggest;
                            return InteractiveViewer(
                              key: CapturaAmpliada.chaveVisor,
                              transformationController: _controle,
                              minScale: CapturaAmpliada.escalaMinima,
                              maxScale: CapturaAmpliada.escalaMaxima,
                              child: GestureDetector(
                                key: _chaveDaCena,
                                onTapUp: (TapUpDetails d) =>
                                    _centralizarEm(d.localPosition),
                                child: CapturaComDestaque(
                                  passo: widget.passo,
                                  imagem: widget.imagem,
                                  proporcao: widget.proporcao,
                                  chaveDoAnel: _chaveDoAnel,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Fixo na janela: não some nem encolhe com o zoom.
                      const Positioned(
                        top: MemoraEspacamento.sm,
                        right: MemoraEspacamento.sm,
                        child: SeloExemplo(key: CapturaAmpliada.chaveSelo),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MemoraEspacamento.md),
              ListenableBuilder(
                listenable: _controle,
                builder: (BuildContext _, Widget? _) {
                  final double escala = _escala;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: BotaoSecundario(
                          key: CapturaAmpliada.chaveAfastar,
                          rotulo: TextosGuias.afastar,
                          icone: Icons.remove,
                          aoTocar:
                              escala > CapturaAmpliada.escalaMinima + _tolerancia
                              ? _afastar
                              : null,
                        ),
                      ),
                      const SizedBox(width: MemoraEspacamento.md),
                      Expanded(
                        child: BotaoSecundario(
                          key: CapturaAmpliada.chaveAproximar,
                          rotulo: TextosGuias.aproximar,
                          icone: Icons.add,
                          aoTocar:
                              escala < CapturaAmpliada.escalaMaxima - _tolerancia
                              ? _aproximar
                              : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O topo: o "Fechar", sempre à vista, e quanto a imagem está ampliada.
class _TopoDaAmpliacao extends StatelessWidget {
  final TransformationController controle;
  final VoidCallback aoFechar;

  const _TopoDaAmpliacao({required this.controle, required this.aoFechar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        BotaoSecundario(
          key: CapturaAmpliada.chaveFechar,
          rotulo: TextosGuias.fecharImagem,
          icone: Icons.close,
          larguraTotal: false,
          aoTocar: aoFechar,
        ),
        const SizedBox(width: MemoraEspacamento.md),
        Flexible(
          child: ListenableBuilder(
            listenable: controle,
            builder: (BuildContext _, Widget? _) {
              // `liveRegion`: o TalkBack lê a mudança sem a pessoa procurar.
              return Semantics(
                liveRegion: true,
                container: true,
                child: TextoMemora(
                  TextosGuias.ampliadaVezes(
                    controle.value.getMaxScaleOnAxis(),
                  ),
                  estilo: EstiloTexto.corpoForte,
                  key: CapturaAmpliada.chaveAmpliacaoAtual,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
