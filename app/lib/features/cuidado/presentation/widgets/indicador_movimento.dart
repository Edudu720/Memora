import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_cuidado.dart';

/// Cartão informativo com o estado de movimentação captado pelo acelerômetro.
class IndicadorMovimento extends StatelessWidget {
  /// Cria o indicador de movimento estritamente informativo (`002/FR-012`).
  const IndicadorMovimento({
    required this.emMovimento,
    required this.nivelMovimento,
    super.key,
  });

  /// Indica se há movimentação ativa registrada no momento.
  final bool emMovimento;

  /// Intensidade atual do movimento calculada pelo sensor.
  final double nivelMovimento;

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final String resumoMovimento = emMovimento
        ? TextosCuidado.movimentoEmAtividade
        : TextosCuidado.movimentoEmRepouso;
    final String nivelFormatado = nivelMovimento.toStringAsFixed(1);

    return Semantics(
      container: true,
      readOnly: true,
      label:
          '${TextosCuidado.tituloEstadoMovimento}: $resumoMovimento. ${TextosCuidado.rotuloNivelMovimento}: $nivelFormatado.',
      child: ExcludeSemantics(
        child: Cartao(
          comBorda: ehAltoContraste,
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: MemoraDimensoes.badgeAtalhoRapido,
                    height: MemoraDimensoes.badgeAtalhoRapido,
                    decoration: BoxDecoration(
                      color: ehAltoContraste
                          ? cores.superficieSutil
                          : (emMovimento
                              ? cores.destaque
                              : cores.superficieSutil),
                      borderRadius: BorderRadius.circular(MemoraRaio.badge),
                      border: ehAltoContraste
                          ? Border.all(
                              color: cores.borda,
                              width: MemoraDimensoes.espessuraBordaSutil,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      emMovimento
                          ? Icons.directions_walk_rounded
                          : Icons.accessibility_new_rounded,
                      color: emMovimento ? cores.primaria : cores.textoSuave,
                      size: MemoraDimensoes.iconePadrao,
                    ),
                  ),
                  const SizedBox(width: MemoraEspacamento.sm),
                  Expanded(
                    child: TextoMemora(
                      TextosCuidado.tituloEstadoMovimento,
                      estilo: EstiloTexto.corpoForte,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.md),
              BadgeDeStatus(
                rotulo: emMovimento
                    ? TextosCuidado.badgeEmMovimento
                    : TextosCuidado.badgeEmRepouso,
                icone: emMovimento
                    ? Icons.directions_run_rounded
                    : Icons.pause_circle_outline_rounded,
                tom: emMovimento
                    ? TomBadgeStatus.informativo
                    : TomBadgeStatus.neutro,
              ),
              const SizedBox(height: MemoraEspacamento.md),
              Text(
                nivelFormatado,
                textScaler: escalaTextoLimitada(context),
                style: MemoraTipografia.destaque.copyWith(
                  color: cores.texto,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              TextoMemora.apoio(
                resumoMovimento,
                cor: cores.textoSuave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
