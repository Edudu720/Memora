import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/espacamento.dart';
import '../texto/texto_memora.dart';

/// Indicador de que algo está acontecendo.
///
/// **Sempre acompanhado de texto.** Um círculo girando sozinho não informa o
/// que está sendo feito, e silêncio durante uma espera é interpretado como
/// travamento por quem tem pouca familiaridade digital.
class Carregando extends StatelessWidget {
  /// O que está acontecendo, em linguagem comum.
  final String mensagem;

  /// Cria um indicador de carregamento.
  const Carregando({this.mensagem = 'Só um instante...', super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      liveRegion: true,
      label: mensagem,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(cores.primaria),
              ),
            ),
            const SizedBox(height: MemoraEspacamento.lg),
            TextoMemora(mensagem, alinhamento: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
