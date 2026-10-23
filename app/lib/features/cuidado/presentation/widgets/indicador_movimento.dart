import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';

/// Exibe o status de movimentação da pessoa de forma amigável e acolhedora.
class IndicadorMovimento extends StatelessWidget {
  /// Cria o indicador visual de estado de movimento.
  const IndicadorMovimento({
    required this.emMovimento,
    required this.nivelMovimento,
    super.key,
  });

  /// Indica se a pessoa está em movimento ativo.
  final bool emMovimento;

  /// Valor numérico do nível de movimento.
  final double nivelMovimento;

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    final Color corStatus = emMovimento ? cores.sucesso : cores.primaria;
    final IconData iconeStatus =
        emMovimento ? Icons.directions_walk_rounded : Icons.self_improvement_rounded;
    final String rotuloStatus =
        emMovimento ? 'Em movimento ativo' : 'Em repouso tranquilo';

    return Container(
      padding: const EdgeInsets.all(MemoraEspacamento.md),
      decoration: BoxDecoration(
        color: cores.superficie,
        borderRadius: BorderRadius.circular(MemoraRaio.padrao),
        border: Border.all(color: cores.borda),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(MemoraEspacamento.sm),
            decoration: BoxDecoration(
              color: corStatus.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconeStatus,
              color: corStatus,
              size: MemoraDimensoes.iconeDestaque,
            ),
          ),
          const SizedBox(width: MemoraEspacamento.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Estado de Movimento',
                  style: MemoraTipografia.apoio.copyWith(
                    color: cores.textoSuave,
                  ),
                  textScaler: escalaTextoLimitada(context),
                ),
                const SizedBox(height: MemoraEspacamento.xs),
                Text(
                  rotuloStatus,
                  style: MemoraTipografia.corpo.copyWith(
                    color: cores.texto,
                    fontWeight: FontWeight.bold,
                  ),
                  textScaler: escalaTextoLimitada(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
