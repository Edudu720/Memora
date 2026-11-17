import 'package:flutter/material.dart';

import '../preferencias/reducao_de_movimento.dart';
import '../tokens/elevacao.dart';
import '../tokens/movimento.dart';
import 'direcao_da_transicao.dart';

/// A rota de página do Memora (feature 013, US2, R2).
///
/// Toda troca de tela desliza com direção — e a direção conta à pessoa onde
/// ela está: **avançar** vem da direita, **voltar** vem da esquerda (FR-009).
/// A tela de trás anda um pouco menos que a nova e escurece de leve
/// (paralaxe), para o olho ver que há um fundo, e não duas telas coladas.
///
/// ## O que ela garante
///
/// - **Duração** de `MemoraMovimento.transicaoDeTela` (no máximo 500 ms,
///   SC-004), e **zero** com "reduzir movimento", no aplicativo ou no sistema
///   (FR-013): a troca vira instantânea e nada desliza.
/// - **A tela que sai não recebe toque** durante a transição (FR-014). A que
///   entra recebe: um toque feito no meio do deslize vale para a tela que
///   ficará à vista, e não se perde.
/// - **O gesto de voltar do aparelho faz a mesma animação** do botão
///   "Voltar" (FR-015): as duas desempilham a mesma rota, e quem anima é o
///   controlador dela — e não quem pediu.
///
/// ## O voltar é o inverso, sem se pedir
///
/// `direcao` diz de onde a tela **entra**. Ao desempilhar, a animação roda ao
/// contrário: a tela sai por onde entrou, e a de trás volta por onde saiu.
///
/// ## Quem veste as rotas que não são esta
///
/// O tema registra [TransicaoMemora] como transição de página do Android
/// (T049), e qualquer `MaterialPageRoute` que sobrar — inclusive as que
/// chegarem de fora — desliza do mesmo jeito.
class RotaMemora<T> extends PageRoute<T> {
  /// A tela.
  final WidgetBuilder builder;

  /// De onde a tela entra. Padrão: [DirecaoDaTransicao.avancar] (pela direita).
  ///
  /// [DirecaoDaTransicao.destino] é da barra inferior e não vale numa rota.
  final DirecaoDaTransicao direcao;

  /// Cria uma rota do Memora.
  ///
  /// [fullscreenDialog] marca a tela como uma pergunta que cobre tudo (a do
  /// Material), e não como mais um passo do caminho; combina com
  /// [DirecaoDaTransicao.sobrepor].
  RotaMemora({
    required this.builder,
    this.direcao = DirecaoDaTransicao.avancar,
    super.settings,
    super.fullscreenDialog,
  }) : assert(
         direcao != DirecaoDaTransicao.destino,
         'DirecaoDaTransicao.destino é da TrocaDeDestino, não de uma rota',
       );

  /// Para onde a rota de baixo vai quando esta a cobre. Guardada porque a rota
  /// de baixo monta a própria saída sem saber quem está por cima.
  DirecaoDaTransicao _direcaoDaDeCima = DirecaoDaTransicao.avancar;

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    _direcaoDaDeCima = nextRoute is RotaMemora<dynamic>
        ? nextRoute.direcao
        : DirecaoDaTransicao.avancar;
    super.didChangeNext(nextRoute);
  }

  bool get _reduzirMovimento {
    // Como o próprio Flutter lê o tema nas rotas dele: pelo contexto do
    // `Navigator`. Quando a duração é pedida, a rota já foi instalada.
    final BuildContext? contexto = navigator?.context;
    return contexto != null &&
        (MediaQuery.maybeDisableAnimationsOf(contexto) ?? false);
  }

  @override
  Duration get transitionDuration => MemoraMovimento.efetiva(
    MemoraMovimento.transicaoDeTela,
    reduzirMovimento: _reduzirMovimento,
  );

  @override
  Duration get reverseTransitionDuration => MemoraMovimento.efetiva(
    MemoraMovimento.transicaoDeTela,
    reduzirMovimento: _reduzirMovimento,
  );

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  /// Para que uma rota do Material (a primeira do aplicativo, por exemplo)
  /// também ceda lugar a esta com o mesmo desenho: sem isso, o Flutter não
  /// anima a rota de baixo quando ela não é da mesma família.
  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      TransicaoMemora.delegada;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return TransicaoMemora.construir(
      context: context,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
      entraPor: direcao,
      baixoSaiPor: _direcaoDaDeCima,
    );
  }
}

/// A transição de página do Memora, como construtor de transição do tema
/// (feature 013, T022 e T049).
///
/// É a mesma que a [RotaMemora] usa. Registrada em `pageTransitionsTheme`, faz
/// toda rota de página que **não** seja uma [RotaMemora] — as de pacotes e as
/// que chegarem de fora — deslizar do mesmo jeito, sem mexer em cada chamada.
///
/// Num `PageTransitionsBuilder` não há contexto para ler a duração, então a
/// duração dessas rotas é a padrão do Flutter; o que muda com "reduzir
/// movimento" é o desenho: nada desliza, e a tela troca de uma vez.
class TransicaoMemora extends PageTransitionsBuilder {
  /// Cria o construtor de transição.
  const TransicaoMemora();

  @override
  DelegatedTransitionBuilder? get delegatedTransition => delegada;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return construir(
      context: context,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }

  /// A transição inteira, para quem monta uma rota própria: a entrada da tela
  /// e, quando outra a cobre, a saída dela.
  ///
  /// [entraPor] diz de onde a tela nova vem; [baixoSaiPor], para onde ela vai
  /// quando outra a cobre (a direção da rota de cima, vista de baixo).
  static Widget construir({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    DirecaoDaTransicao entraPor = DirecaoDaTransicao.avancar,
    DirecaoDaTransicao baixoSaiPor = DirecaoDaTransicao.avancar,
  }) {
    // FR-013: nada desliza. A rota própria já dura zero; o que se desfaz aqui
    // é a transição das rotas que o tema veste, cuja duração não é nossa.
    //
    // A árvore tem **sempre** a mesma forma: se ela mudasse com a preferência,
    // quem a ligasse de dentro de uma tela (Aparência) faria o Flutter
    // recriar a página e a pessoa perderia onde estava.
    final bool reduzir = context.reduzirMovimento;
    return _saida(
      secondaryAnimation: reduzir ? _parada(0) : secondaryAnimation,
      saiPor: baixoSaiPor,
      child: _entrada(
        animation: reduzir ? _parada(1) : animation,
        entraPor: entraPor,
        child: child,
      ),
    );
  }

  /// A saída da tela de baixo, vista pela rota de cima. É o que o Flutter
  /// chama quando uma rota do Material está sob uma [RotaMemora] (ou o
  /// contrário): as duas devolvem **esta mesma função**, e por isso o Flutter
  /// só a usa quando as famílias são diferentes.
  static Widget? delegada(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    if (child == null) return child;
    return _saida(
      secondaryAnimation: context.reduzirMovimento
          ? _parada(0)
          : secondaryAnimation,
      saiPor: DirecaoDaTransicao.avancar,
      child: child,
    );
  }

  /// A tela nova já no lugar (1) ou a de baixo ainda no dela (0), sem andar.
  ///
  /// As constantes do Flutter, e não uma `AlwaysStoppedAnimation`: esta diz
  /// que está **indo** (`forward`), e a tela de baixo ficaria sem receber
  /// toque para sempre.
  static Animation<double> _parada(int valor) =>
      valor == 1 ? kAlwaysCompleteAnimation : kAlwaysDismissedAnimation;

  /// A tela nova chegando, de onde [entraPor] manda.
  static Widget _entrada({
    required Animation<double> animation,
    required DirecaoDaTransicao entraPor,
    required Widget child,
  }) {
    final Offset deOnde = switch (entraPor) {
      DirecaoDaTransicao.avancar => const Offset(1, 0),
      DirecaoDaTransicao.voltar => const Offset(-1, 0),
      DirecaoDaTransicao.sobrepor => const Offset(0, 1),
      DirecaoDaTransicao.destino => Offset.zero,
    };
    return SlideTransition(
      position: animation
          .drive(CurveTween(curve: MemoraMovimento.curvaDeTela))
          .drive(Tween<Offset>(begin: deOnde, end: Offset.zero)),
      child: child,
    );
  }

  /// A tela de baixo enquanto outra a cobre: anda menos que a nova (paralaxe),
  /// escurece de leve e **não recebe toque** (FR-014). Quando a de cima está
  /// saindo, a de baixo já recebe: o toque vale para a que ficará à vista.
  static Widget _saida({
    required Animation<double> secondaryAnimation,
    required DirecaoDaTransicao saiPor,
    required Widget child,
  }) {
    Widget tela = child;
    if (saiPor != DirecaoDaTransicao.sobrepor) {
      final double sentido = saiPor == DirecaoDaTransicao.voltar ? -1 : 1;
      tela = SlideTransition(
        position: secondaryAnimation
            .drive(CurveTween(curve: MemoraMovimento.curvaDeTela))
            .drive(
              Tween<Offset>(
                begin: Offset.zero,
                end: Offset(-sentido * MemoraMovimento.paralaxeDaTelaDeTras, 0),
              ),
            ),
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: secondaryAnimation,
                  child: const ColoredBox(
                    color: MemoraElevacao.veuDaTelaDeTras,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: secondaryAnimation,
      builder: (BuildContext _, Widget? filho) => IgnorePointer(
        ignoring: secondaryAnimation.status == AnimationStatus.forward,
        child: filho,
      ),
      child: tela,
    );
  }
}
