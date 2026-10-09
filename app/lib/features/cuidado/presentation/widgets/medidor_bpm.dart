import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';

/// Exibe a frequência cardíaca medida em BPM de forma clara e acessível.
class MedidorBpm extends StatelessWidget {
  const MedidorBpm({
    required this.bpm,
    super.key,
  });

  final int bpm;

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    final String textoBpm = bpm > 0 ? '$bpm' : '--';

    return Container(
      padding: const EdgeInsets.all(MemoraEspacamento.md),
      decoration: BoxDecoration(
        color: cores.superficie,
        borderRadius: BorderRadius.circular(MemoraRaio.padrao),
        border: Border.all(color: cores.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.favorite_rounded,
                color: cores.perigo,
                size: MemoraDimensoes.iconeDestaque,
              ),
              const SizedBox(width: MemoraEspacamento.sm),
              Flexible(
                child: Text(
                  'Frequência Cardíaca',
                  style: MemoraTipografia.apoio.copyWith(
                    color: cores.textoSuave,
                  ),
                  textScaler: escalaTextoLimitada(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoraEspacamento.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                textoBpm,
                style: MemoraTipografia.destaque.copyWith(
                  color: cores.texto,
                  fontWeight: FontWeight.bold,
                ),
                textScaler: escalaTextoLimitada(context),
              ),
              const SizedBox(width: MemoraEspacamento.xs),
              Text(
                'BPM',
                style: MemoraTipografia.corpo.copyWith(
                  color: cores.textoSuave,
                  fontWeight: FontWeight.bold,
                ),
                textScaler: escalaTextoLimitada(context),
              ),
            ],
          ),
          const SizedBox(height: MemoraEspacamento.xs),
          Text(
            _classificacaoBpm(bpm),
            style: MemoraTipografia.apoio.copyWith(
              color: cores.textoSuave,
            ),
            textScaler: escalaTextoLimitada(context),
          ),
        ],
      ),
    );
  }

  static String _classificacaoBpm(int valor) {
    if (valor <= 0) return 'Aguardando leitura do sensor';
    if (valor < 60) return 'Ritmo calmo em repouso';
    if (valor <= 100) return 'Ritmo normal e estável';
    return 'Ritmo elevado';
  }
}
