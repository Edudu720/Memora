import 'package:flutter/material.dart';

import '../../preferencias/reducao_de_movimento.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/movimento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_secundario.dart';
import '../texto/texto_memora.dart';

/// Folha que sobe pela parte de baixo da tela, para escolher entre opções.
///
/// Sobe **por cima**, sem mover a tela de trás (feature 013, FR-010).
///
/// Sempre traz um botão de fechar escrito. Fechar arrastando para baixo é
/// gesto complexo, e a FR-015 proíbe que ele seja o caminho único.
class FolhaInferior extends StatelessWidget {
  /// Título da folha.
  final String titulo;

  /// Conteúdo, normalmente uma lista de opções.
  final Widget child;

  /// Acionada ao fechar.
  final VoidCallback? aoFechar;

  /// Cria uma folha inferior.
  const FolhaInferior({
    required this.titulo,
    required this.child,
    this.aoFechar,
    super.key,
  });

  /// Exibe a folha.
  static Future<void> mostrar(
    BuildContext context, {
    required FolhaInferior folha,
  }) {
    final bool reduzir = context.reduzirMovimento;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Sobe devagar e desce depressa; com "reduzir movimento", de uma vez
      // (FR-013). A tela de trás fica onde está (FR-010).
      sheetAnimationStyle: AnimationStyle(
        duration: MemoraMovimento.efetiva(
          MemoraMovimento.lento,
          reduzirMovimento: reduzir,
        ),
        reverseDuration: MemoraMovimento.efetiva(
          MemoraMovimento.padrao,
          reduzirMovimento: reduzir,
        ),
        curve: MemoraMovimento.curvaDeSobreposicao,
      ),
      builder: (BuildContext _) => folha,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: cores.superficie,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MemoraRaio.cartao),
        ),
      ),
      padding: const EdgeInsets.all(MemoraEspacamento.xl),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextoMemora.tituloSecao(titulo),
              const SizedBox(height: MemoraEspacamento.lg),
              child,
              const SizedBox(height: MemoraEspacamento.xl),
              // Saída escrita: arrastar para baixo não pode ser o único caminho.
              BotaoSecundario(
                rotulo: 'Fechar',
                icone: Icons.close_rounded,
                aoTocar: aoFechar ?? () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
