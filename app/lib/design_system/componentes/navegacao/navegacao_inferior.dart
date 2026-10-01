import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../texto/texto_memora.dart';

/// Um destino da navegação inferior.
@immutable
class ItemNavegacao {
  /// Ícone do destino.
  final IconData icone;

  /// Rótulo escrito. **Obrigatório** (FR-016).
  final String rotulo;

  /// Cria um item de navegação.
  const ItemNavegacao({required this.icone, required this.rotulo});
}

/// Navegação inferior do Memora.
///
/// **Todo item tem ícone e rótulo escrito.** No protótipo, a barra inferior
/// tinha apenas três ícones — engrenagem, casa e pessoa — sem nenhum texto.
/// Ícone isolado depende de convenção que este público não necessariamente
/// conhece, e a FR-016 proíbe.
class NavegacaoInferior extends StatelessWidget {
  /// Destinos exibidos.
  final List<ItemNavegacao> itens;

  /// Índice do destino ativo.
  final int indiceAtivo;

  /// Acionada ao escolher um destino.
  final ValueChanged<int> aoSelecionar;

  /// Cria a navegação inferior.
  const NavegacaoInferior({
    required this.itens,
    required this.indiceAtivo,
    required this.aoSelecionar,
    super.key,
  }) : assert(itens.length >= 2, 'Navegação exige ao menos dois destinos.');

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Material(
      color: cores.superficieAlt,
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < itens.length; i++)
              Expanded(
                child: _Item(
                  item: itens[i],
                  ativo: i == indiceAtivo,
                  posicao: i + 1,
                  total: itens.length,
                  aoTocar: () => aoSelecionar(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final ItemNavegacao item;
  final bool ativo;
  final int posicao;
  final int total;
  final VoidCallback aoTocar;

  const _Item({
    required this.item,
    required this.ativo,
    required this.posicao,
    required this.total,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final Color cor = ativo ? cores.primaria : cores.texto;

    return Semantics(
      button: true,
      selected: ativo,
      label: item.rotulo,
      hint: '$posicao de $total',
      onTap: aoTocar,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: aoTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MemoraDimensoes.alvoDecisao,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MemoraEspacamento.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(item.icone, color: cor, size: MemoraDimensoes.iconeDestaque),
                  const SizedBox(height: MemoraEspacamento.xs),
                  // Rótulo escrito, sempre.
                  TextoMemora(
                    item.rotulo,
                    estilo: ativo ? EstiloTexto.corpoForte : EstiloTexto.apoio,
                    cor: cor,
                    alinhamento: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
