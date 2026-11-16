import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_secundario.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';

/// Comunica que algo não deu certo.
///
/// ## Duas regras
///
/// 1. **Ícone e texto**, nunca apenas a cor vermelha (FR-032).
/// 2. **Tom acolhedor, jamais culpando a pessoa.** *"Não consegui"* em vez de
///    *"Você digitou errado"*. Culpar quem já está inseguro é o caminho mais
///    curto para a desistência.
///
/// Sempre que possível, ofereça um caminho de saída em [aoTentarNovamente].
class MensagemErro extends StatelessWidget {
  /// O que aconteceu, em linguagem comum e sem detalhe técnico.
  final String mensagem;

  /// Ação de recuperação. Quando nula, o botão não aparece.
  final VoidCallback? aoTentarNovamente;

  /// Rótulo do botão de recuperação.
  final String rotuloTentarNovamente;

  /// Cria uma mensagem de erro.
  const MensagemErro({
    required this.mensagem,
    this.aoTentarNovamente,
    this.rotuloTentarNovamente = 'Tentar de novo',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool mostrarMascote =
        MediaQuery.textScalerOf(context).scale(1) <
        MemoraDimensoes.escalaTextoAlta;

    return Semantics(
      liveRegion: true,
      label: mensagem,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          decoration: BoxDecoration(
            color: cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.cartaoMedio),
            border: Border.all(
              color: cores.perigo,
              width: MemoraDimensoes.bordaEnfase,
            ),
            boxShadow: MemoraElevacao.listaSombrasCartao(cores),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (mostrarMascote) ...<Widget>[
                const Center(
                  child: MemoraPersonagem(
                    expressao: ExpressaoDaMemora.preocupada,
                    tamanho: MemoraDimensoes.pisoDeIlustracao,
                  ),
                ),
                const SizedBox(height: MemoraEspacamento.sm),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Ícone E texto: cor sozinha não comunica.
                  Icon(
                    Icons.error_outline,
                    color: cores.perigo,
                    size: MemoraDimensoes.iconeDestaque,
                  ),
                  const SizedBox(width: MemoraEspacamento.md),
                  Expanded(child: TextoMemora(mensagem)),
                ],
              ),
              if (aoTentarNovamente != null) ...<Widget>[
                const SizedBox(height: MemoraEspacamento.md),
                BotaoSecundario(
                  rotulo: rotuloTentarNovamente,
                  icone: Icons.refresh,
                  aoTocar: aoTentarNovamente,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
