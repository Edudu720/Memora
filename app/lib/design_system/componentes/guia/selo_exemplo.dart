import 'package:flutter/material.dart';

import '../../../l10n/textos_guias.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';

/// O selo "Exemplo" que acompanha toda captura de passo a passo (FR-028).
///
/// Uso interno da pasta `guia/`: a moldura do [PassoIlustrado] e a ampliação
/// desenham o mesmo selo, para ele não divergir entre as duas. Quem posiciona
/// é quem usa.
class SeloExemplo extends StatelessWidget {
  /// Cria o selo.
  const SeloExemplo({super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      container: true,
      label: TextosGuias.seloExemploDescrito,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MemoraEspacamento.sm,
          vertical: MemoraEspacamento.xs,
        ),
        decoration: BoxDecoration(
          color: cores.superficie,
          borderRadius: BorderRadius.circular(MemoraRaio.padrao),
          border: Border.all(color: cores.borda),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: MemoraElevacao.sombra,
              blurRadius: MemoraElevacao.cartao * 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: TextoMemora.apoio(TextosGuias.exemplo, cor: cores.texto),
      ),
    );
  }
}
