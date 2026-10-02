import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_primario.dart';
import '../botoes/botao_secundario.dart';
import '../texto/texto_memora.dart';

/// Diálogo modal do Memora.
///
/// Sempre oferece uma saída clara. Um modal sem saída visível deixa a pessoa
/// presa numa tela que ela não sabe fechar — e o gesto de voltar do sistema
/// não é conhecido por todo o público.
class DialogoMemora extends StatelessWidget {
  /// Título curto e direto.
  final String titulo;

  /// Explicação em linguagem comum.
  final String mensagem;

  /// Rótulo da ação principal.
  final String rotuloConfirmar;

  /// Acionada ao confirmar.
  final VoidCallback aoConfirmar;

  /// Rótulo da saída. Quando nulo, exibe apenas a ação principal.
  final String? rotuloFechar;

  /// Acionada ao fechar.
  final VoidCallback? aoFechar;

  /// Cria um diálogo.
  const DialogoMemora({
    required this.titulo,
    required this.mensagem,
    required this.rotuloConfirmar,
    required this.aoConfirmar,
    this.rotuloFechar,
    this.aoFechar,
    super.key,
  });

  /// Exibe o diálogo no `Navigator` que [context] encontra.
  ///
  /// **Não no de fora**, que é o padrão do `showDialog`. Desde a casca da
  /// feature 004 há um `Navigator` por destino, e quem fecha o diálogo com
  /// `Navigator.of(context).pop()` acha o do destino: com o diálogo no de
  /// fora, "Entendi" fechava a tela de trás e deixava o diálogo aberto
  /// (revisão da #38). No mesmo `Navigator`, o `pop()` fecha o diálogo — e um
  /// diálogo aberto dentro de um destino sai da árvore junto com a casca
  /// quando a sessão expira.
  static Future<void> mostrar(
    BuildContext context, {
    required DialogoMemora dialogo,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext _) => dialogo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Dialog(
      backgroundColor: cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MemoraEspacamento.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextoMemora.tituloSecao(titulo),
            const SizedBox(height: MemoraEspacamento.md),
            TextoMemora(mensagem),
            const SizedBox(height: MemoraEspacamento.xl),
            BotaoPrimario(rotulo: rotuloConfirmar, aoTocar: aoConfirmar),
            if (rotuloFechar != null) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.md),
              BotaoSecundario(rotulo: rotuloFechar!, aoTocar: aoFechar),
            ],
          ],
        ),
      ),
    );
  }
}
