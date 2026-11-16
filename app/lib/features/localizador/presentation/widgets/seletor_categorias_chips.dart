import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entidades/categoria_servico.dart';

/// Barra horizontal rolável de categorias em pílulas (chips) acessíveis (FR-002).
class SeletorCategoriasChips extends StatelessWidget {
  /// Categoria atualmente destacada como selecionada.
  final CategoriaServico categoriaSelecionada;

  /// Callback disparado ao tocar em uma nova categoria.
  final ValueChanged<CategoriaServico> aoSelecionar;

  /// Cria o seletor horizontal de categorias essenciais.
  const SeletorCategoriasChips({
    required this.categoriaSelecionada,
    required this.aoSelecionar,
    super.key,
  });

  /// Chave estável de cada chip identificada pela categoria.
  static Key chaveChip(CategoriaServico cat) => Key('localizador.categoria.${cat.name}');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraEspacamento.md,
        vertical: MemoraEspacamento.xs,
      ),
      child: Row(
        children: <Widget>[
          for (final CategoriaServico cat in CategoriaServico.values) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(right: MemoraEspacamento.sm),
              child: ChipFiltro(
                key: chaveChip(cat),
                rotulo: cat.rotulo,
                icone: cat.icone,
                selecionado: cat == categoriaSelecionada,
                aoTocar: () => aoSelecionar(cat),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
