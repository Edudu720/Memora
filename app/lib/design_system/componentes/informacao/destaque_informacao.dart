import 'package:flutter/material.dart';

import '../../tokens/cores.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../../temas/memora_theme_extension.dart';
import '../texto/texto_memora.dart';

/// Informação de maior ênfase — ainda inequivocamente **não clicável**.
///
/// Use quando um dado precisa de destaque, como o plano ativo da pessoa ou uma
/// contagem relevante. A ênfase vem de **tamanho e peso do texto**, nunca de
/// preenchimento com a cor primária, que é reservada a ações.
///
/// Assim como [CampoInformacao], **não aceita callback de toque** (FR-012).
class DestaqueInformacao extends StatelessWidget {
  /// O que o dado representa.
  final String rotulo;

  /// O conteúdo em destaque.
  final String valor;

  /// Ícone opcional, exibido antes do rótulo.
  final IconData? icone;

  /// Cria um destaque de informação.
  const DestaqueInformacao({
    required this.rotulo,
    required this.valor,
    this.icone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      button: false,
      readOnly: true,
      label: rotulo,
      value: valor,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          decoration: BoxDecoration(
            // Superfície secundária, nunca a cor primária: preenchimento com
            // primária é linguagem de botão.
            color: cores.superficieAlt,
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (icone != null) ...<Widget>[
                    Icon(icone, size: 20, color: cores.texto),
                    const SizedBox(width: MemoraEspacamento.sm),
                  ],
                  Flexible(
                    child: Text(
                      rotulo,
                      textScaler: escalaTextoLimitada(context),
                      style: MemoraTipografia.apoio.copyWith(
                        color: cores.texto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              Text(
                valor,
                textScaler: escalaTextoLimitada(context),
                style: MemoraTipografia.tituloSecao.copyWith(
                  color: cores.texto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
