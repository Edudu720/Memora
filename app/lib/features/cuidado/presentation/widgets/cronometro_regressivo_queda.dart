import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';

/// Exibe o cronômetro regressivo da verificação de queda (iniciando em 45 s).
class CronometroRegressivoQueda extends StatelessWidget {
  /// Cria o cronômetro regressivo de verificação de queda.
  const CronometroRegressivoQueda({
    required this.segundosRestantes,
    this.totalSegundos = 45,
    super.key,
  });

  /// Quantidade de segundos restantes até o acionamento automático.
  final int segundosRestantes;

  /// Duração total da janela de verificação em segundos.
  final int totalSegundos;

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    final double progresso = (segundosRestantes / totalSegundos).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraEspacamento.md,
        vertical: MemoraEspacamento.sm,
      ),
      decoration: BoxDecoration(
        color: cores.perigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MemoraRaio.padrao),
        border: Border.all(color: cores.perigo.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MemoraEspacamento.sm,
            children: <Widget>[
              Icon(
                Icons.timer_outlined,
                color: cores.perigo,
                size: MemoraDimensoes.iconeDestaque,
              ),
              Text(
                '$segundosRestantes segundos',
                style: MemoraTipografia.tituloSecao.copyWith(
                  color: cores.perigo,
                  fontWeight: FontWeight.bold,
                ),
                textScaler: escalaTextoLimitada(context),
              ),
            ],
          ),
          const SizedBox(height: MemoraEspacamento.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            child: LinearProgressIndicator(
              value: progresso,
              backgroundColor: cores.borda,
              valueColor: AlwaysStoppedAnimation<Color>(cores.perigo),
              minHeight: MemoraDimensoes.separacaoAlvo,
            ),
          ),
          const SizedBox(height: MemoraEspacamento.xs),
          Text(
            'Se você não responder, avisaremos seu contato de emergência.',
            textAlign: TextAlign.center,
            style: MemoraTipografia.apoio.copyWith(
              color: cores.texto,
            ),
            textScaler: escalaTextoLimitada(context),
          ),
        ],
      ),
    );
  }
}
