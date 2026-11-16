import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';

/// Linha padronizada de lista com ícone ou ilustração opcional à esquerda.
///
/// Respeita estritamente `002/FR-012`:
/// - Quando [aoTocar] é nulo, é **puramente informativa** (sem chevron e sem
///   semântica nem superfície de toque).
/// - Quando [aoTocar] é informado, exibe pista de ação explícita (chevron) e
///   área de toque mínima de `48 dp` com anel de foco e resposta tátil.
class LinhaDeLista extends StatelessWidget {
  /// Elemento opcional à esquerda (ex.: badge com ícone ou avatar).
  final Widget? esquerda;

  /// Título principal da linha.
  final String titulo;

  /// Subtítulo ou descrição auxiliar opcional.
  final String? subtitulo;

  /// Elemento opcional exibido antes da seta de navegação.
  final Widget? direita;

  /// Complemento opcional abaixo do subtítulo (ex.: a contagem de passos e a
  /// marca "Já aprendeu" de uma seção). Fica visível mesmo quando a ampliação
  /// esconde o subtítulo.
  final Widget? rodape;

  /// O que o leitor de tela anuncia, quando precisa dizer mais que o título e
  /// o subtítulo (ex.: o rodapé). Nulo, vale `titulo, subtitulo`.
  final String? rotuloDoLeitor;

  /// Callback opcional. Se nulo, o item é estritamente informativo.
  final VoidCallback? aoTocar;

  /// Exibe divisor inferior sutil quando agrupada dentro de um cartão passivo.
  final bool mostrarDivisorInferior;

  /// Cria uma linha de lista.
  const LinhaDeLista({
    required this.titulo,
    this.esquerda,
    this.subtitulo,
    this.direita,
    this.rodape,
    this.rotuloDoLeitor,
    this.aoTocar,
    this.mostrarDivisorInferior = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool compacto = escala >= MemoraDimensoes.escalaColapsoGrade;
    final bool ocultarOrnamento = escala >= MemoraDimensoes.escalaTextoAlta;
    final double larguraBorda = ehAltoContraste
        ? MemoraDimensoes.bordaEnfase
        : MemoraDimensoes.espessuraBordaSutil;
    final Color corBorda = ehAltoContraste ? cores.borda : cores.bordaSutil;

    final Widget conteudo = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: MemoraDimensoes.alvoMinimo),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compacto ? MemoraEspacamento.md : MemoraEspacamento.lg,
          vertical: compacto ? MemoraEspacamento.sm : MemoraEspacamento.md,
        ),
        child: Row(
          children: <Widget>[
            if (esquerda != null && !ocultarOrnamento) ...<Widget>[
              esquerda!,
              const SizedBox(width: MemoraEspacamento.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextoMemora(
                    titulo,
                    estilo: ocultarOrnamento && aoTocar != null
                        ? EstiloTexto.apoio
                        : EstiloTexto.corpoForte,
                  ),
                  if (subtitulo != null &&
                      !(ocultarOrnamento && aoTocar != null)) ...<Widget>[
                    const SizedBox(height: MemoraEspacamento.xs),
                    TextoMemora.apoio(subtitulo!),
                  ],
                  if (rodape != null) ...<Widget>[
                    const SizedBox(height: MemoraEspacamento.xs),
                    rodape!,
                  ],
                ],
              ),
            ),
            if (direita != null) ...<Widget>[
              const SizedBox(width: MemoraEspacamento.sm),
              direita!,
            ],
            if (aoTocar != null) ...<Widget>[
              const SizedBox(width: MemoraEspacamento.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: MemoraDimensoes.iconePadrao,
                color: ehAltoContraste ? cores.texto : cores.primaria,
              ),
            ],
          ],
        ),
      ),
    );

    if (aoTocar == null) {
      return Semantics(
        button: false,
        readOnly: true,
        container: true,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cores.superficie,
            borderRadius: mostrarDivisorInferior
                ? null
                : BorderRadius.circular(MemoraRaio.cartaoMedio),
            border: mostrarDivisorInferior
                ? Border(
                    bottom: BorderSide(color: corBorda, width: larguraBorda),
                  )
                : Border.all(color: corBorda, width: larguraBorda),
          ),
          child: conteudo,
        ),
      );
    }

    final String rotulo =
        rotuloDoLeitor ?? (subtitulo == null ? titulo : '$titulo, $subtitulo');
    return SuperficieTocavel(
      rotulo: rotulo,
      aoTocar: aoTocar,
      fundo: cores.superficie,
      borda: corBorda,
      larguraBorda: larguraBorda,
      sombras: MemoraElevacao.listaSombrasCartao(cores),
      raio: BorderRadius.circular(MemoraRaio.cartaoMedio),
      child: conteudo,
    );
  }
}
