import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../texto/texto_memora.dart';

/// Barra superior do Memora.
///
/// O botão de voltar **sempre traz a palavra "Voltar"** ao lado da seta. Seta
/// isolada é ambígua para quem tem pouca familiaridade digital, e a FR-016
/// proíbe ícone sem rótulo.
class BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  /// Título da tela.
  final String titulo;

  /// Acionada ao voltar. Quando nula, o botão não aparece.
  final VoidCallback? aoVoltar;

  /// Ação opcional à direita da barra.
  final Widget? acao;

  /// Cria a barra superior.
  const BarraSuperior({
    required this.titulo,
    this.aoVoltar,
    this.acao,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(MemoraDimensoes.alvoDecisao);

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Material(
      color: cores.fundo,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MemoraDimensoes.alvoDecisao,
          ),
          child: Row(
            children: <Widget>[
              if (aoVoltar != null)
                Semantics(
                  button: true,
                  label: 'Voltar',
                  onTap: aoVoltar,
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: aoVoltar,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: MemoraDimensoes.alvoMinimo,
                          minHeight: MemoraDimensoes.alvoMinimo,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MemoraEspacamento.md,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.arrow_back, color: cores.primaria),
                              const SizedBox(width: MemoraEspacamento.xs),
                              // Palavra escrita: seta sozinha é ambígua.
                              TextoMemora('Voltar', cor: cores.primaria),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraEspacamento.md,
                  ),
                  child: TextoMemora.tituloSecao(titulo, maxLinhas: 2),
                ),
              ),
              ?acao,
            ],
          ),
        ),
      ),
    );
  }
}
