import 'package:flutter/material.dart';

import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../botoes/botao_primario.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';

/// Exibido quando não há nada para mostrar.
///
/// Explica **o que houve** e **o que fazer em seguida**. Uma tela vazia sem
/// explicação é lida como erro do aplicativo — ou, pior, como erro da própria
/// pessoa.
class EstadoVazio extends StatelessWidget {
  /// Título curto do que está vazio.
  final String titulo;

  /// O que houve e o que fazer agora.
  final String explicacao;

  /// Ícone opcional (mantido para compatibilidade; a composição padrão destaca
  /// a Memora falando).
  final IconData icone;

  /// Rótulo da ação sugerida. Quando nulo, o botão não aparece.
  final String? rotuloAcao;

  /// Acionada ao tocar na ação sugerida.
  final VoidCallback? aoAgir;

  /// Se a Memora (falando) aparece acima do texto (FR-001, T073).
  ///
  /// Uma Memora só por tela (FR-006, T096): quando a tela já mostra a dela —
  /// no cartão de apresentação, na barra, na anfitriã —, passe `false`. O
  /// texto do estado nunca sai.
  final bool comMemora;

  /// Cria um estado vazio.
  const EstadoVazio({
    required this.titulo,
    required this.explicacao,
    this.icone = Icons.inbox_rounded,
    this.rotuloAcao,
    this.aoAgir,
    this.comMemora = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool mostrarMascote =
        comMemora &&
        MediaQuery.textScalerOf(context).scale(1) <
            MemoraDimensoes.escalaTextoAlta;

    return Padding(
      padding: const EdgeInsets.all(MemoraEspacamento.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (mostrarMascote) ...<Widget>[
            const Center(
              child: MemoraPersonagem(expressao: ExpressaoDaMemora.falando),
            ),
            const SizedBox(height: MemoraEspacamento.lg),
          ],
          TextoMemora.tituloSecao(titulo, alinhamento: TextAlign.center),
          const SizedBox(height: MemoraEspacamento.sm),
          TextoMemora(explicacao, alinhamento: TextAlign.center),
          if (rotuloAcao != null) ...<Widget>[
            const SizedBox(height: MemoraEspacamento.xl),
            BotaoPrimario(rotulo: rotuloAcao!, aoTocar: aoAgir),
          ],
        ],
      ),
    );
  }
}
