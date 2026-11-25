import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
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
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

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
            // Superfície limpa elevada (nunca a cor primária de botão).
            color: cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.cartaoMedio),
            border: Border.all(
              color: ehAltoContraste ? cores.borda : cores.bordaSutil,
              width: ehAltoContraste
                  ? MemoraDimensoes.bordaEnfase
                  : MemoraDimensoes.espessuraBordaSutil,
            ),
            boxShadow: MemoraElevacao.listaSombrasCartao(cores),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (icone != null) ...<Widget>[
                    Icon(
                      icone,
                      size: MemoraDimensoes.iconePequeno,
                      color: cores.textoSuave,
                    ),
                    const SizedBox(width: MemoraEspacamento.sm),
                  ],
                  Flexible(
                    child: Text(
                      rotulo,
                      textScaler: escalaTextoLimitada(context),
                      style: MemoraTipografia.apoio.copyWith(
                        color: cores.textoSuave,
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
