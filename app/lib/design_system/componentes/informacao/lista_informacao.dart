import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';
import 'campo_informacao.dart';

/// Agrupa vários [CampoInformacao] com espaçamento consistente em superfície limpa.
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
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool ehEscuro = tema.id == MemoraTemaId.escuro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (titulo != null) ...<Widget>[
          TextoMemora.tituloSecao(titulo!),
          const SizedBox(height: MemoraEspacamento.md),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          decoration: BoxDecoration(
            color: cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.cartaoMedio),
            border: ehAltoContraste
                ? Border.all(
                    color: cores.borda,
                    width: MemoraDimensoes.bordaEnfase,
                  )
                : (ehEscuro
                      ? Border.all(
                          color: cores.bordaSutil,
                        )
                      : null),
            boxShadow: MemoraElevacao.listaSombrasCartao(cores),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < campos.length; i++) ...<Widget>[
                campos[i],
                if (i < campos.length - 1)
                  const SizedBox(height: MemoraEspacamento.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
