import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../texto/texto_memora.dart';

/// Painel herói puramente **informativo** (estritamente não clicável).
///
/// Apresenta dados principais de monitoramento ou estado geral com destaque
/// visual limpo, respeitando `002/FR-012`: **não possui `aoTocar`** nem
/// semântica de botão. Quando o bloco inteiro precisa navegar ou iniciar uma
/// ação, utilize [CartaoHeroi].
class PainelHeroi extends StatelessWidget {
  /// Título principal do painel.
  final String titulo;

  /// Valor numérico ou curto em destaque com algarismos tabulares.
  final String? valorDestaque;

  /// Subtítulo ou explicação complementar opcional.
  final String? subtitulo;

  /// Badge de status exibido no painel (ex.: [BadgeDeStatus]).
  final Widget? badgeStatus;

  /// Elemento visual à esquerda (ex.: ícone ou ilustração da Memora).
  final Widget? visualEsquerda;

  /// Conteúdo complementar no rodapé (ex.: último registro ou contexto).
  final Widget? rodape;

  /// Cria um painel herói informativo.
  const PainelHeroi({
    required this.titulo,
    this.valorDestaque,
    this.subtitulo,
    this.badgeStatus,
    this.visualEsquerda,
    this.rodape,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool ocultarVisualLateral =
        escala >= MemoraDimensoes.escalaTextoAlta;

    return Semantics(
      button: false,
      readOnly: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        decoration: BoxDecoration(
          color: ehAltoContraste ? cores.gradienteSaudeInicio : null,
          gradient: ehAltoContraste
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    cores.gradienteSaudeInicio,
                    cores.gradienteSaudeFim,
                  ],
                ),
          borderRadius: BorderRadius.circular(MemoraRaio.cartaoDestaque),
          border: ehAltoContraste
              ? Border.all(
                  color: cores.borda,
                  width: MemoraDimensoes.bordaEnfase,
                )
              : null,
          boxShadow: MemoraElevacao.listaSombrasCartao(cores),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (visualEsquerda != null && !ocultarVisualLateral) ...<Widget>[
                  visualEsquerda!,
                  const SizedBox(width: MemoraEspacamento.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextoMemora(
                        titulo,
                        estilo: EstiloTexto.tituloSecao,
                        cor: cores.sobreGradienteSaude,
                        cabecalho: true,
                      ),
                      if (valorDestaque != null) ...<Widget>[
                        const SizedBox(height: MemoraEspacamento.xs),
                        Text(
                          valorDestaque!,
                          textScaler: escalaTextoLimitada(context),
                          style: MemoraTipografia.destaque.copyWith(
                            color: cores.sobreGradienteSaude,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                      if (subtitulo != null) ...<Widget>[
                        const SizedBox(height: MemoraEspacamento.xs),
                        TextoMemora(
                          subtitulo!,
                          estilo: EstiloTexto.apoio,
                          cor: cores.sobreGradienteSaude,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (badgeStatus != null) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.md),
              badgeStatus!,
            ],
            if (rodape != null) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.md),
              rodape!,
            ],
          ],
        ),
      ),
    );
  }
}
