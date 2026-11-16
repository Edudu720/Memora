import 'package:flutter/material.dart';

import '../../../l10n/textos_guias.dart';
import '../informacao/badge_de_status.dart';

/// O selo "Exemplo" que acompanha toda captura de passo a passo (FR-028).
///
/// Uso interno da pasta `guia/`: a moldura do [PassoIlustrado] e a ampliação
/// desenham o mesmo selo, para ele não divergir entre as duas. Quem posiciona
/// é quem usa. Desenhado como [BadgeDeStatus] neutro (redesenho 007): é
/// informação, nunca ação.
class SeloExemplo extends StatelessWidget {
  /// Cria o selo.
  const SeloExemplo({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: TextosGuias.seloExemploDescrito,
      child: const BadgeDeStatus(
        rotulo: TextosGuias.exemplo,
        icone: Icons.photo_library_outlined,
        tom: TomBadgeStatus.neutro,
      ),
    );
  }
}
