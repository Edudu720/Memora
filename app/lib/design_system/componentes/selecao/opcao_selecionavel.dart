import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';

/// Uma opção dentro de um grupo de escolha única.
///
/// ## Seleção nunca é comunicada apenas por cor
///
/// A FR-014 é explícita: quem não distingue matizes precisa perceber a escolha
/// por outro canal. Aqui a opção selecionada ganha **três** sinais simultâneos:
/// ícone de confirmação, borda mais grossa e fundo destacado.
///
/// Delega toque e foco a [SuperficieTocavel], exibindo anel externo no foco
/// e escala de pressão além da variação de cor (Princípio III).
///
/// Expõe semântica de escolha em grupo exclusivo, para que o leitor de tela
/// anuncie "selecionado" e "1 de 4".
class OpcaoSelecionavel extends StatelessWidget {
  /// Texto principal da opção.
  final String rotulo;

  /// Explicação curta, em linguagem comum.
  final String? descricao;

  /// Se esta é a opção ativa.
  final bool selecionada;

  /// Acionada ao tocar.
  final VoidCallback aoSelecionar;

  /// Elemento visual opcional exibido antes do texto (ex.: miniatura de avatar).
  final Widget? lider;

  /// Cria uma opção selecionável.
  const OpcaoSelecionavel({
    required this.rotulo,
    required this.selecionada,
    required this.aoSelecionar,
    this.descricao,
    this.lider,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final Icon indicadorEstado = Icon(
      selecionada ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
      color: selecionada ? cores.primaria : cores.borda,
      size: MemoraDimensoes.iconeDestaque,
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selecionada,
      label: rotulo,
      hint: descricao,
      onTap: aoSelecionar,
      child: ExcludeSemantics(
        child: SuperficieTocavel(
          rotulo: rotulo,
          dica: descricao,
          selecionada: selecionada,
          aoTocar: aoSelecionar,
          fundo: selecionada ? cores.superficieAlt : cores.superficie,
          borda: selecionada ? cores.primaria : cores.borda,
          raio: BorderRadius.circular(MemoraRaio.padrao),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MemoraDimensoes.alvoDecisao,
            ),
            child: Padding(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: Row(
                children: <Widget>[
                  if (lider != null) ...<Widget>[
                    lider!,
                    const SizedBox(width: MemoraEspacamento.md),
                  ] else ...<Widget>[
                    indicadorEstado,
                    const SizedBox(width: MemoraEspacamento.lg),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextoMemora(
                          rotulo,
                          estilo: selecionada
                              ? EstiloTexto.corpoForte
                              : EstiloTexto.corpo,
                        ),
                        if (descricao != null) ...<Widget>[
                          const SizedBox(height: MemoraEspacamento.xs),
                          TextoMemora.apoio(descricao!),
                        ],
                      ],
                    ),
                  ),
                  if (lider != null) ...<Widget>[
                    const SizedBox(width: MemoraEspacamento.sm),
                    indicadorEstado,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
