import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/movimento.dart';

/// A superfície que responde ao toque, com cada estado visível por mais de um
/// sinal (FR-043 da feature 004).
///
/// ## Por que existe
///
/// Os componentes da 002 mostram foco e toque pela camada de cor do
/// `InkWell` — e só por ela. A constituição pede feedback visual para **todo**
/// estado, e cor sozinha não basta para quem enxerga pouco. Em vez de cada
/// componente novo resolver isso de um jeito, os quatro da feature 004 passam
/// por aqui:
///
/// | Estado | Sinal além da cor |
/// |---|---|
/// | foco | anel de [MemoraDimensoes.bordaSelecao] em primária, por fora |
/// | pressionado | a superfície encolhe para [MemoraMovimento.escalaPressionado] e perde a sombra |
/// | desabilitado | anunciado como tal ao leitor de tela; quem chama troca o conteúdo |
///
/// O anel vai em `foregroundDecoration`: por cima, sem mudar o tamanho, para a
/// tela não "pular" quando o foco chega.
///
/// ## Por que não é exportada
///
/// É uma peça de montar componentes, não um componente: uma tela que a usasse
/// direto estaria inventando ação sem passar pelo Design System.
class SuperficieTocavel extends StatefulWidget {
  /// O que o leitor de tela anuncia.
  final String rotulo;

  /// Complemento ao [rotulo], anunciado depois dele.
  final String? dica;

  /// Ação. Nula, a superfície fica desabilitada.
  final VoidCallback? aoTocar;

  /// Cor de fundo.
  final Color fundo;

  /// Arredondamento.
  final BorderRadius raio;

  /// Com sombra de cartão quando em repouso.
  final bool sombra;

  /// Conteúdo.
  final Widget child;

  /// Cria a superfície.
  const SuperficieTocavel({
    required this.rotulo,
    required this.fundo,
    required this.raio,
    required this.child,
    this.aoTocar,
    this.dica,
    this.sombra = false,
    super.key,
  });

  @override
  State<SuperficieTocavel> createState() => _SuperficieTocavelState();
}

class _SuperficieTocavelState extends State<SuperficieTocavel> {
  bool _focada = false;
  bool _pressionada = false;

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool habilitada = widget.aoTocar != null;
    final Duration transicao = MemoraMovimento.efetiva(
      MemoraMovimento.rapido,
      reduzirMovimento: MediaQuery.disableAnimationsOf(context),
    );

    return Semantics(
      button: true,
      enabled: habilitada,
      label: widget.rotulo,
      hint: widget.dica,
      // Sem onTap na própria Semantics, o TalkBack anuncia o botão e o
      // duplo-toque não faz nada (achado da 002).
      onTap: widget.aoTocar,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: _pressionada ? MemoraMovimento.escalaPressionado : 1,
          duration: transicao,
          child: AnimatedContainer(
            duration: transicao,
            decoration: BoxDecoration(
              color: widget.fundo,
              borderRadius: widget.raio,
              boxShadow: widget.sombra && !_pressionada
                  ? <BoxShadow>[
                      BoxShadow(
                        color: MemoraElevacao.sombra,
                        blurRadius: MemoraElevacao.cartao * 4,
                        offset: const Offset(0, MemoraElevacao.cartao),
                      ),
                    ]
                  : null,
            ),
            foregroundDecoration: _focada
                ? BoxDecoration(
                    borderRadius: widget.raio,
                    border: Border.all(
                      color: cores.primaria,
                      width: MemoraDimensoes.bordaSelecao,
                    ),
                  )
                : null,
            child: Material(
              color: Colors.transparent,
              borderRadius: widget.raio,
              child: InkWell(
                onTap: widget.aoTocar,
                borderRadius: widget.raio,
                onHighlightChanged: (bool pressionada) =>
                    setState(() => _pressionada = pressionada),
                onFocusChange: (bool focada) =>
                    setState(() => _focada = focada),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
