import 'package:flutter/widgets.dart';

import '../tokens/movimento.dart';

/// A troca de destino da barra inferior, com direção (feature 013, US2, R3,
/// FR-011).
///
/// O destino que entra desliza do lado em que está na barra: de Início para
/// Meu perfil (à direita), o Perfil vem pela direita; de Início para Ajustes
/// (à esquerda), o Ajustes vem pela esquerda. O que sai vai para o outro lado
/// e depois fica fora da tela.
///
/// ## Por que não um `AnimatedSwitcher`, nem um `PageView`
///
/// - O `AnimatedSwitcher` **recria** o filho que entra. Cada destino é um
///   `Navigator` com a pilha da pessoa dentro (conversa, catálogo, passo a
///   passo); recriá-lo a cada troca faria quem vai ao Perfil perder onde
///   estava no Início.
/// - O `PageView` deixa **arrastar** de um destino a outro com o dedo, e quem
///   rola a tela de lado troca de destino sem querer — o contrário do que a
///   barra existe para dar.
///
/// ## O que ela garante
///
/// - **Todos os filhos continuam vivos**, na mesma posição da árvore: a pilha
///   de cada destino é preservada, com o estado dela.
/// - **Fora da tela não se anima, nem se foca, nem se lê, nem se toca.** O
///   destino que saiu fica fora do desenho, com os relógios parados.
/// - **Durante o deslize**, o destino que sai não recebe toque; o que entra
///   recebe (FR-014).
/// - Com "reduzir movimento" a troca é instantânea (FR-013).
class TrocaDeDestino extends StatefulWidget {
  /// O destino à vista: o índice de um dos [filhos].
  final int indice;

  /// Um por destino, na ordem da barra. Cada um deve ter a própria chave se
  /// guardar estado (os `Navigator`s da casca têm).
  final List<Widget> filhos;

  /// Cria a troca de destino.
  const TrocaDeDestino({required this.indice, required this.filhos, super.key});

  @override
  State<TrocaDeDestino> createState() => _TrocaDeDestinoState();
}

class _TrocaDeDestinoState extends State<TrocaDeDestino>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _curva;

  /// O destino que está saindo, enquanto o deslize dura. Nulo em repouso.
  int? _saindo;

  /// De que lado o novo destino entra: +1 pela direita, −1 pela esquerda.
  double _sentido = 1;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(vsync: this, value: 1)
      ..addStatusListener((AnimationStatus estado) {
        if (estado == AnimationStatus.completed && _saindo != null) {
          setState(() => _saindo = null);
        }
      });
    _curva = CurvedAnimation(
      parent: _controlador,
      curve: MemoraMovimento.curvaDeTela,
    );
  }

  @override
  void didUpdateWidget(TrocaDeDestino anterior) {
    super.didUpdateWidget(anterior);
    if (widget.indice == anterior.indice) return;

    final bool reduzir = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Duration duracao = MemoraMovimento.efetiva(
      MemoraMovimento.transicaoDeTela,
      reduzirMovimento: reduzir,
    );
    if (duracao == Duration.zero) {
      _saindo = null;
      _controlador.value = 1;
      return;
    }

    _sentido = widget.indice > anterior.indice ? 1 : -1;
    _saindo = anterior.indice;
    _controlador.duration = duracao;
    _controlador.forward(from: 0);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  /// Onde o filho [i] está agora, em fração da largura.
  Animation<Offset> _posicao(int i) {
    if (i == widget.indice) {
      return _curva.drive(
        Tween<Offset>(begin: Offset(_sentido, 0), end: Offset.zero),
      );
    }
    if (i == _saindo) {
      return _curva.drive(
        Tween<Offset>(begin: Offset.zero, end: Offset(-_sentido, 0)),
      );
    }
    return const AlwaysStoppedAnimation<Offset>(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          for (int i = 0; i < widget.filhos.length; i++)
            _Destino(
              // A chave por posição mantém o estado de cada filho mesmo que a
              // lista mude de tamanho em volta dele.
              key: ValueKey<int>(i),
              aVista: i == widget.indice || i == _saindo,
              recebeToque: i == widget.indice,
              posicao: _posicao(i),
              child: widget.filhos[i],
            ),
        ],
      ),
    );
  }
}

/// Um destino: à vista ou fora da tela, mas sempre na árvore.
class _Destino extends StatelessWidget {
  const _Destino({
    required this.aVista,
    required this.recebeToque,
    required this.posicao,
    required this.child,
    super.key,
  });

  final bool aVista;
  final bool recebeToque;
  final Animation<Offset> posicao;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A forma da árvore é sempre a mesma, à vista ou não: se ela mudasse, o
    // Flutter recriaria o filho — e a pilha do destino iria embora.
    return Offstage(
      offstage: !aVista,
      child: TickerMode(
        enabled: aVista,
        child: ExcludeFocus(
          excluding: !aVista,
          child: ExcludeSemantics(
            excluding: !aVista,
            child: IgnorePointer(
              ignoring: !recebeToque,
              child: SlideTransition(position: posicao, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
