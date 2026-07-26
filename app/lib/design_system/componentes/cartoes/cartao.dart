import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';

/// Agrupa conteúdo relacionado numa superfície.
///
/// **Não é clicável.** Cartão que responde ao toque volta a confundir dado com
/// ação (FR-012) — se algo precisa ser acionado, use um botão dentro do cartão.
class Cartao extends StatelessWidget {
  /// Conteúdo do cartão.
  final Widget child;

  /// Espaçamento interno.
  final EdgeInsetsGeometry padding;

  /// Cria um cartão.
  const Cartao({
    required this.child,
    this.padding = const EdgeInsets.all(MemoraEspacamento.lg),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cores.superficie,
        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        border: Border.all(color: cores.borda),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: MemoraElevacao.cartao * 4,
            offset: const Offset(0, MemoraElevacao.cartao),
          ),
        ],
      ),
      child: child,
    );
  }
}
