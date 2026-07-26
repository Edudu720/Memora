import 'package:flutter/material.dart';

import '../../tokens/espacamento.dart';
import 'campo_informacao.dart';

/// Agrupa vários [CampoInformacao] com espaçamento consistente.
///
/// Aceita **apenas** [CampoInformacao] — a tipagem impede que um botão seja
/// misturado a dados e volte a confundir informação com ação (FR-012).
///
/// Se uma tela precisa exibir dados **e** oferecer uma ação, a ação fica fora
/// desta lista, visualmente separada.
class ListaInformacao extends StatelessWidget {
  /// Os campos exibidos, na ordem em que aparecem.
  final List<CampoInformacao> campos;

  /// Título opcional do agrupamento.
  final String? titulo;

  /// Cria uma lista de informações.
  const ListaInformacao({required this.campos, this.titulo, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (titulo != null) ...<Widget>[
          Semantics(
            header: true,
            child: Text(
              titulo!,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: MemoraEspacamento.md),
        ],
        for (int i = 0; i < campos.length; i++) ...<Widget>[
          campos[i],
          if (i < campos.length - 1)
            const SizedBox(height: MemoraEspacamento.md),
        ],
      ],
    );
  }
}
