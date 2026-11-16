import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_cuidado.dart';

/// Destaque regressivo que mostra quanto tempo resta antes de chamar ajuda.
class CronometroRegressivoQueda extends StatelessWidget {
  /// Cria o cronômetro regressivo de verificação de queda.
  const CronometroRegressivoQueda({
    required this.segundosRestantes,
    super.key,
  });

  /// Quantidade de segundos restantes até o disparo automático.
  final int segundosRestantes;

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final String textoSegundos = '$segundosRestantes segundos';

    return Semantics(
      liveRegion: true,
      readOnly: true,
      label: '${TextosCuidado.prefixoCronometroQueda}: $textoSegundos',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          decoration: BoxDecoration(
            color: cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.cartaoDestaque),
            border: Border.all(
              color: ehAltoContraste ? cores.borda : cores.perigo,
              width: MemoraDimensoes.bordaEnfase,
            ),
            boxShadow: MemoraElevacao.listaSombrasCartao(cores),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const BadgeDeStatus(
                rotulo: TextosCuidado.badgeContagemQueda,
                icone: Icons.timer_outlined,
                tom: TomBadgeStatus.atencao,
              ),
              const SizedBox(height: MemoraEspacamento.md),
              Text(
                textoSegundos,
                textAlign: TextAlign.center,
                textScaler: escalaTextoLimitada(context),
                style: MemoraTipografia.destaque.copyWith(
                  color: ehAltoContraste ? cores.texto : cores.perigo,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              TextoMemora.apoio(
                TextosCuidado.apoioCronometroQueda,
                cor: cores.textoSuave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
