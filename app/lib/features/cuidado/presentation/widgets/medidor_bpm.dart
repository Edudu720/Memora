import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_cuidado.dart';

/// Cartão informativo com a frequência cardíaca medida pelo dispositivo IoT.
class MedidorBpm extends StatelessWidget {
  /// Cria o medidor de BPM estritamente informativo (`002/FR-012`).
  const MedidorBpm({
    required this.bpm,
    this.bpmValido = false,
    super.key,
  });

  /// Último batimento cardíaco recebido em batimentos por minuto.
  final int bpm;

  /// Indica se há leitura óptica válida no momento (dedo no sensor).
  final bool bpmValido;

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final String valorExibido = bpmValido ? '$bpm' : '--';
    final String estadoTexto = bpmValido
        ? TextosCuidado.bpmMedicaoAtiva
        : TextosCuidado.bpmAguardandoDedo;

    return Semantics(
      container: true,
      readOnly: true,
      label:
          '${TextosCuidado.tituloFrequenciaCardiaca}: $valorExibido ${TextosCuidado.unidadeBpm}. $estadoTexto',
      child: ExcludeSemantics(
        child: Cartao(
          comBorda: ehAltoContraste,
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: MemoraDimensoes.badgeAtalhoRapido,
                    height: MemoraDimensoes.badgeAtalhoRapido,
                    decoration: BoxDecoration(
                      color: ehAltoContraste
                          ? cores.superficieSutil
                          : cores.saudeSuave,
                      borderRadius: BorderRadius.circular(MemoraRaio.badge),
                      border: ehAltoContraste
                          ? Border.all(
                              color: cores.borda,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: bpmValido ? cores.perigo : cores.sucessoTexto,
                      size: MemoraDimensoes.iconePadrao,
                    ),
                  ),
                  const SizedBox(width: MemoraEspacamento.sm),
                  Expanded(
                    child: TextoMemora(
                      TextosCuidado.tituloFrequenciaCardiaca,
                      estilo: EstiloTexto.corpoForte,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.md),
              BadgeDeStatus(
                rotulo: bpmValido
                    ? TextosCuidado.statusLeituraAtiva
                    : TextosCuidado.statusAguardandoSensor,
                icone: bpmValido
                    ? Icons.check_circle_outline_rounded
                    : Icons.sensors_rounded,
                tom: bpmValido
                    ? TomBadgeStatus.positivo
                    : TomBadgeStatus.neutro,
              ),
              const SizedBox(height: MemoraEspacamento.md),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: MemoraEspacamento.xs,
                children: <Widget>[
                  Text(
                    valorExibido,
                    textScaler: escalaTextoLimitada(context),
                    style: MemoraTipografia.destaque.copyWith(
                      color: bpmValido ? cores.texto : cores.textoSuave,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  TextoMemora.apoio(
                    TextosCuidado.unidadeBpm,
                    cor: cores.textoSuave,
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              TextoMemora.apoio(
                estadoTexto,
                cor: bpmValido ? cores.texto : cores.textoSuave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
