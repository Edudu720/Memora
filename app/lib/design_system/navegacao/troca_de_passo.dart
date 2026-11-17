import 'package:flutter/widgets.dart';

import '../preferencias/reducao_de_movimento.dart';
import '../tokens/movimento.dart';

/// A troca de um passo para outro dentro da mesma tela (feature 013, US6,
/// T072, FR-009 e FR-013).
///
/// O passo a passo não abre uma rota nova a cada passo: a tela é a mesma e o
/// conteúdo troca. Mesmo assim a pessoa precisa saber **para onde foi**, e a
/// direção diz isso sem precisar de leitura: **avançar** traz o passo novo
/// pela direita, **voltar** traz pela esquerda — o mesmo que a `RotaMemora`
/// faz entre telas, com a mesma duração e a mesma curva
/// (`MemoraMovimento.transicaoDeTela`, `curvaDeTela`).
///
/// ## O que ela garante
///
/// - **O sentido vem da posição**: se [posicao] cresceu, avançou; se diminuiu,
///   voltou. Quem usa não diz a direção.
/// - **O passo que sai não recebe toque, foco nem leitura** (FR-014): durante
///   o deslize só o passo que chega existe para o toque e para o TalkBack.
/// - **O passo que chega mantém o estado** quando o deslize termina: a árvore
///   tem sempre a mesma forma, e a captura carregada não é buscada de novo.
/// - Com "reduzir movimento" (do aplicativo ou do sistema) a troca é
///   instantânea e nada desliza (FR-013).
///
/// O filho de cada passo é dado em [child]; quem troca de passo muda [posicao]
/// **e** o [child] juntos.
class TrocaDePasso extends StatefulWidget {
  /// A posição do passo à vista (1, 2, 3, ...). Só a ordem importa.
  final int posicao;

  /// O conteúdo do passo à vista.
  final Widget child;

  /// Cria a troca de passo.
  const TrocaDePasso({required this.posicao, required this.child, super.key});

  @override
  State<TrocaDePasso> createState() => _TrocaDePassoState();
}

class _TrocaDePassoState extends State<TrocaDePasso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _curva;

  /// O passo que está saindo, enquanto o deslize dura. Nulo em repouso.
  Widget? _saindo;
  int _posicaoSaindo = 0;

  /// De que lado o passo novo entra: +1 pela direita, −1 pela esquerda.
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
  void didUpdateWidget(TrocaDePasso anterior) {
    super.didUpdateWidget(anterior);
    if (widget.posicao == anterior.posicao) return;

    final Duration duracao = MemoraMovimento.efetiva(
      MemoraMovimento.transicaoDeTela,
      reduzirMovimento: context.reduzirMovimento,
    );
    if (duracao == Duration.zero) {
      _saindo = null;
      _controlador.value = 1;
      return;
    }

    _sentido = widget.posicao > anterior.posicao ? 1 : -1;
    _saindo = anterior.child;
    _posicaoSaindo = anterior.posicao;
    _controlador.duration = duracao;
    _controlador.forward(from: 0);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? saindo = _saindo;
    return ClipRect(
      child: Stack(
        // Os dois passos têm a largura da tela; a altura é a do maior.
        children: <Widget>[
          if (saindo != null)
            _Folha(
              key: ValueKey<int>(_posicaoSaindo),
              aVista: false,
              position: _curva.drive(
                Tween<Offset>(begin: Offset.zero, end: Offset(-_sentido, 0)),
              ),
              child: saindo,
            ),
          // Quem chega, ou já está. A chave por posição mantém o estado
          // quando o deslize termina e o passo que saiu some da lista.
          _Folha(
            key: ValueKey<int>(widget.posicao),
            aVista: true,
            position: _curva.drive(
              Tween<Offset>(begin: Offset(_sentido, 0), end: Offset.zero),
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Um passo: o que chega (ou já está) e o que sai têm **a mesma forma**, para
/// que o passo que estava à vista e passa a sair não seja recriado.
class _Folha extends StatelessWidget {
  const _Folha({
    required this.aVista,
    required this.position,
    required this.child,
    super.key,
  });

  /// Falso para o passo que sai: sem toque, sem foco e sem leitura (FR-014).
  final bool aVista;
  final Animation<Offset> position;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: !aVista,
      child: ExcludeFocus(
        excluding: !aVista,
        child: IgnorePointer(
          ignoring: !aVista,
          child: SlideTransition(position: position, child: child),
        ),
      ),
    );
  }
}
