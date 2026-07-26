import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/movimento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';

/// Uma opção dentro de um grupo de escolha única.
///
/// ## Seleção nunca é comunicada apenas por cor
///
/// A FR-014 é explícita: quem não distingue matizes precisa perceber a escolha
/// por outro canal. Aqui a opção selecionada ganha **três** sinais simultâneos:
/// ícone de confirmação, borda mais grossa e fundo destacado.
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

  /// Cria uma opção selecionável.
  const OpcaoSelecionavel({
    required this.rotulo,
    required this.selecionada,
    required this.aoSelecionar,
    this.descricao,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selecionada,
      label: rotulo,
      hint: descricao,
      onTap: aoSelecionar,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: MemoraMovimento.efetiva(
            MemoraMovimento.rapido,
            reduzirMovimento: MediaQuery.disableAnimationsOf(context),
          ),
          constraints: const BoxConstraints(
            minHeight: MemoraDimensoes.alvoDecisao,
          ),
          decoration: BoxDecoration(
            color: selecionada ? cores.superficieAlt : cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            border: Border.all(
              color: selecionada ? cores.primaria : cores.borda,
              width: selecionada ? 3 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            child: InkWell(
              onTap: aoSelecionar,
              borderRadius: BorderRadius.circular(MemoraRaio.padrao),
              child: Padding(
                padding: const EdgeInsets.all(MemoraEspacamento.lg),
                child: Row(
                  children: <Widget>[
                    Icon(
                      selecionada
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: selecionada ? cores.primaria : cores.borda,
                      size: 28,
                    ),
                    const SizedBox(width: MemoraEspacamento.lg),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
