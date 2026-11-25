import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';

/// Variante visual do badge quadrado do [TileAcaoRapida].
enum VarianteBadge {
  /// Destaque principal do aplicativo.
  primario,

  /// Identidade tonal da área de saúde e cuidado.
  saude,

  /// Destaque de alerta ou atenção imediata.
  alerta,

  /// Destaque neutro para informações e configurações auxiliares.
  neutro,
}

/// Bloco de ação rápida em grade com ícone em badge quadrado (`48 dp`) e pista
/// explícita de toque (`002/FR-012` + `007/FR-008`).
class TileAcaoRapida extends StatelessWidget {
  /// Ícone exibido dentro do badge quadrado arredondado.
  final IconData icone;

  /// Título curto e claro da ação.
  final String titulo;

  /// Descrição opcional de apoio abaixo do título.
  final String? subtitulo;

  /// Callback de toque. Se nulo, exibe estado desabilitado sem pista ativa.
  final VoidCallback? aoTocar;

  /// Paleta tonal do badge do ícone.
  final VarianteBadge variacao;

  /// Texto curto da pista de ação (padrão: "Abrir").
  final String? pistaAcao;

  /// Cria um tile de ação rápida.
  const TileAcaoRapida({
    required this.icone,
    required this.titulo,
    required this.aoTocar,
    this.subtitulo,
    this.variacao = VarianteBadge.primario,
    this.pistaAcao,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool interativo = aoTocar != null;

    final (Color fundoBadge, Color corIconeBadge) = switch (variacao) {
      VarianteBadge.primario => (cores.destaque, cores.primaria),
      VarianteBadge.saude => (cores.saudeSuave, cores.sucessoTexto),
      VarianteBadge.alerta => (cores.perigo, cores.sobrePerigo),
      VarianteBadge.neutro => (cores.superficieSutil, cores.texto),
    };

    final Color corAcao = ehAltoContraste ? cores.texto : cores.primaria;
    final String textoAcao = pistaAcao ?? 'Abrir';
    final String rotuloSemantico = subtitulo == null
        ? titulo
        : '$titulo, $subtitulo';

    return SuperficieTocavel(
      rotulo: rotuloSemantico,
      dica: interativo ? textoAcao : null,
      aoTocar: aoTocar,
      fundo: cores.superficie,
      borda: ehAltoContraste ? cores.borda : cores.bordaSutil,
      larguraBorda: ehAltoContraste
          ? MemoraDimensoes.bordaEnfase
          : MemoraDimensoes.espessuraBordaSutil,
      sombras: MemoraElevacao.listaSombrasCartao(cores),
      raio: BorderRadius.circular(MemoraRaio.cartaoMedio),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: MemoraDimensoes.alvoDecisao,
          minWidth: MemoraDimensoes.alvoMinimo,
        ),
        child: Padding(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: MemoraDimensoes.badgeAtalhoRapido,
                height: MemoraDimensoes.badgeAtalhoRapido,
                decoration: BoxDecoration(
                  color: fundoBadge,
                  borderRadius: BorderRadius.circular(MemoraRaio.badge),
                  border: ehAltoContraste
                      ? Border.all(
                          color: cores.borda,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icone,
                  size: MemoraDimensoes.iconePadrao,
                  color: corIconeBadge,
                ),
              ),
              const SizedBox(height: MemoraEspacamento.md),
              TextoMemora(
                titulo,
                estilo: EstiloTexto.corpoForte,
              ),
              if (subtitulo != null) ...<Widget>[
                const SizedBox(height: MemoraEspacamento.xs),
                TextoMemora.apoio(subtitulo!),
              ],
              if (interativo) ...<Widget>[
                const SizedBox(height: MemoraEspacamento.md),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        textoAcao,
                        textScaler: escalaTextoLimitada(context),
                        style: MemoraTipografia.apoio.copyWith(
                          color: corAcao,
                          fontWeight: MemoraTipografia.pesoDoNegrito,
                        ),
                      ),
                    ),
                    const SizedBox(width: MemoraEspacamento.xs),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: MemoraDimensoes.iconePequeno,
                      color: corAcao,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
