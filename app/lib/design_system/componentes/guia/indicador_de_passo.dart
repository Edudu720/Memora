import 'package:flutter/material.dart';

import '../../../l10n/textos_guias.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';

/// Indicador textual e visual da etapa atual num guia passo a passo (`T053`, `T065`).
///
/// "Passo 2 de 4", **sempre em texto**, acompanhado da barra de progresso
/// limpa com trilho em `superficieSutil` e contorno reservado ao Alto Contraste.
class IndicadorDePasso extends StatelessWidget {
  /// Posição atual da etapa (iniciando em 1).
  final int posicao;

  /// Total de etapas do guia.
  final int total;

  /// Cria o indicador de passo.
  const IndicadorDePasso({
    required this.posicao,
    required this.total,
    super.key,
  }) : assert(total > 0, 'O total de passos deve ser maior que zero'),
       assert(
         posicao >= 1 && posicao <= total,
         'A posição deve estar entre 1 e o total',
       );

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double fracao = (posicao / total).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      label: TextosGuias.passoDescrito(posicao, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(
            child: TextoMemora(
              TextosGuias.passo(posicao, total),
              estilo: EstiloTexto.corpoForte,
              cor: cores.primaria,
            ),
          ),
          const SizedBox(height: MemoraEspacamento.xs),
          ExcludeSemantics(
            child: Container(
              height: MemoraDimensoes.alturaIndicadorDePasso,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: ehAltoContraste ? cores.superficie : cores.superficieSutil,
                borderRadius: BorderRadius.circular(MemoraRaio.pilula),
                border: ehAltoContraste
                    ? Border.all(
                        color: cores.borda,
                      )
                    : null,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fracao,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cores.primaria,
                    borderRadius: BorderRadius.circular(MemoraRaio.pilula),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
