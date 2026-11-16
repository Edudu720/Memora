import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';

/// Agrupa conteúdo relacionado numa superfície elevada.
///
/// **Não é clicável.** Cartão que responde ao toque volta a confundir dado com
/// ação (FR-012) — se algo precisa ser acionado, use um componente de ação
/// dentro do cartão.
class Cartao extends StatelessWidget {
  /// Conteúdo do cartão.
  final Widget child;

  /// Espaçamento interno.
  final EdgeInsetsGeometry padding;

  /// Força contorno visível também fora do Alto Contraste.
  final bool comBorda;

  /// Cria um cartão.
  const Cartao({
    required this.child,
    this.padding = const EdgeInsets.all(MemoraEspacamento.lg),
    this.comBorda = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool ehEscuro = tema.id == MemoraTemaId.escuro;

    final Border? borda = (ehAltoContraste || comBorda)
        ? Border.all(
            color: cores.borda,
            width: MemoraDimensoes.bordaEnfase,
          )
        : (ehEscuro
              ? Border.all(
                  color: cores.bordaSutil,
                )
              : null);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cores.superficie,
        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        border: borda,
        boxShadow: MemoraElevacao.listaSombrasCartao(cores),
      ),
      child: child,
    );
  }
}
