import 'package:flutter/material.dart';

import '../../preferencias/reducao_de_movimento.dart';
import '../../tokens/abertura.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/movimento.dart';
import '../ilustracao/memora_animada/memora_animada.dart';
import '../ilustracao/memora_animada/poses.dart';
import '../texto/texto_memora.dart';

/// Indicador de que algo está acontecendo: a Memora segurando a barra de
/// carregamento, e a frase que diz o que está sendo feito (feature 013, T095,
/// FR-059).
///
/// ## O que mostra
///
/// A Memora comum (a anfitriã é do Início e da abertura, FR-048) na pose
/// [PoseDaMemora.carregando], com a barra indeterminada correndo entre as
/// mãos — a mesma passada da abertura ([MemoraAbertura.passadaDaBarra]), em
/// ciclo, enquanto a tela espera. A barra **não diz quanto falta**: não há
/// número, e ela não acelera nem pisca para disfarçar a espera.
///
/// ## O que garante
///
/// - **Sempre acompanhado de texto.** Um desenho sozinho não informa o que
///   está sendo feito, e silêncio durante uma espera é interpretado como
///   travamento por quem tem pouca familiaridade digital.
/// - **Reduzir movimento**: nenhum relógio roda; a Memora e a barra ficam
///   paradas (FR-039, FR-059).
/// - **Decorativa para o leitor de tela**: a Memora e a barra não são
///   anunciadas. Quem usa o leitor ouve só a frase, como aviso (`liveRegion`).
///
/// ## Uma Memora por tela (FR-006)
///
/// Se a tela já mostra outra Memora enquanto espera, **a outra** esconde-se
/// durante a espera: quem usa este componente cuida disso na própria tela.
class Carregando extends StatefulWidget {
  /// O que está acontecendo, em linguagem comum.
  final String mensagem;

  /// Cria um indicador de carregamento.
  const Carregando({this.mensagem = 'Só um instante...', super.key});

  @override
  State<Carregando> createState() => _CarregandoState();
}

class _CarregandoState extends State<Carregando>
    with SingleTickerProviderStateMixin {
  /// O relógio da barra: de 0 a 1 é uma passada. Só existe quando há movimento
  /// permitido.
  AnimationController? _passada;

  bool _reduzir = true;
  bool _leuOMovimento = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduzir = context.reduzirMovimento;
    if (_leuOMovimento && reduzir == _reduzir) return;
    _leuOMovimento = true;
    _reduzir = reduzir;
    if (_reduzir) {
      // Sem movimento: nenhum relógio, e a barra fica onde está.
      _passada?.stop();
    } else {
      final AnimationController passada = _passada ??= AnimationController(
        vsync: this,
        duration: MemoraMovimento.efetiva(
          MemoraAbertura.passadaDaBarra,
          reduzirMovimento: _reduzir,
        ),
      );
      passada.repeat();
    }
  }

  @override
  void dispose() {
    _passada?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: widget.mensagem,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MemoraAnimada(
              expressao: PoseDaMemora.carregando,
              tamanho: MemoraDimensoes.ilustracaoCabecalho,
              reageAoToque: false,
              cicloDaBarra: _reduzir ? null : _passada,
            ),
            const SizedBox(height: MemoraEspacamento.lg),
            TextoMemora(widget.mensagem, alinhamento: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
