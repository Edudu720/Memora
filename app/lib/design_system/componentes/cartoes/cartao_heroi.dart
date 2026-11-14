import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';

/// Cartão herói **estritamente interativo** para a ação principal de uma tela.
///
/// Diferencia-se do [PainelHeroi] pela exigência estrutural de [aoTocar],
/// semântica de botão (`Semantics(button: true)`) e pista explícita de ação
/// em alto contraste (`rotuloAcao` com ícone de seta).
class CartaoHeroi extends StatelessWidget {
  /// Título principal da ação (ex.: "Conversar com a Memora").
  final String titulo;

  /// Descrição curta e clara do benefício da ação.
  final String? subtitulo;

  /// Texto explícito do botão interno que convida ao toque (ex.: "Começar").
  final String rotuloAcao;

  /// Ícone opcional exibido ao lado de [rotuloAcao].
  final IconData? icone;

  /// Elemento visual à esquerda (ex.: robô Memora), ocultado em ampliações altas.
  final Widget? visualEsquerda;

  /// Ação executada ao tocar em qualquer ponto do cartão.
  final VoidCallback aoTocar;

  /// Cria um cartão herói acionável.
  const CartaoHeroi({
    required this.titulo,
    required this.rotuloAcao,
    required this.aoTocar,
    this.subtitulo,
    this.icone,
    this.visualEsquerda,
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
    final bool compacto = escala >= MemoraDimensoes.escalaColapsoGrade;

    final String rotuloSemantico = subtitulo == null
        ? '$titulo. $rotuloAcao'
        : '$titulo. $subtitulo. $rotuloAcao';

    final Color fundoPista = ehAltoContraste ? cores.fundo : cores.superficie;
    final Color corPista = ehAltoContraste ? cores.texto : cores.primaria;

    return SuperficieTocavel(
      rotulo: rotuloSemantico,
      aoTocar: aoTocar,
      fundo: cores.gradienteHeroiInicio,
      gradiente: ehAltoContraste
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                cores.gradienteHeroiInicio,
                cores.gradienteHeroiFim,
              ],
            ),
      borda: ehAltoContraste ? cores.borda : null,
      larguraBorda: MemoraDimensoes.bordaEnfase,
      sombras: MemoraElevacao.listaSombrasCartao(cores),
      raio: BorderRadius.circular(MemoraRaio.cartaoDestaque),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: MemoraDimensoes.alvoDecisao,
        ),
        child: Padding(
          padding: EdgeInsets.all(
            compacto ? MemoraEspacamento.sm : MemoraEspacamento.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (visualEsquerda != null &&
                      !ocultarVisualLateral) ...<Widget>[
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
                          estilo: ocultarVisualLateral
                              ? EstiloTexto.apoio
                              : (compacto
                                    ? EstiloTexto.corpoForte
                                    : EstiloTexto.tituloSecao),
                          cor: cores.sobreGradienteHeroi,
                        ),
                        if (subtitulo != null && !ocultarVisualLateral) ...<Widget>[
                          const SizedBox(height: MemoraEspacamento.xs),
                          TextoMemora(
                            subtitulo!,
                            estilo: EstiloTexto.apoio,
                            cor: cores.sobreGradienteHeroi,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: compacto ? MemoraEspacamento.xs : MemoraEspacamento.lg,
              ),
              Container(
                constraints: compacto
                    ? const BoxConstraints()
                    : const BoxConstraints(
                        minHeight: MemoraDimensoes.alvoMinimo,
                      ),
                padding: EdgeInsets.symmetric(
                  horizontal: compacto
                      ? MemoraEspacamento.sm
                      : MemoraEspacamento.lg,
                  vertical: compacto
                      ? MemoraEspacamento.xs
                      : MemoraEspacamento.sm,
                ),
                decoration: BoxDecoration(
                  color: fundoPista,
                  borderRadius: BorderRadius.circular(MemoraRaio.pilula),
                  border: ehAltoContraste
                      ? Border.all(
                          color: cores.borda,
                          width: MemoraDimensoes.bordaEnfase,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icone != null && !ocultarVisualLateral) ...<Widget>[
                      Icon(
                        icone,
                        size: MemoraDimensoes.iconePadrao,
                        color: corPista,
                      ),
                      const SizedBox(width: MemoraEspacamento.sm),
                    ],
                    Flexible(
                      child: TextoMemora(
                        rotuloAcao,
                        estilo: ocultarVisualLateral
                            ? EstiloTexto.apoio
                            : EstiloTexto.corpoForte,
                        cor: corPista,
                      ),
                    ),
                    const SizedBox(width: MemoraEspacamento.sm),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: MemoraDimensoes.iconePequeno,
                      color: corPista,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
