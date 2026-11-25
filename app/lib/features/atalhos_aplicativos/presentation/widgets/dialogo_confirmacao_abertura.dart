import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_atalhos_aplicativos.dart';

/// Diálogo de confirmação segura antes de sair do Memora e abrir um aplicativo
/// instalado no dispositivo (Princípio II da Constituição).
class DialogoConfirmacaoAbertura {
  /// Chave raiz do diálogo de confirmação de abertura.
  static const Key chaveDialogo = Key('atalhos.confirmacao_abertura');

  /// Exibe o diálogo pedindo confirmação para abrir [nomeAplicativo].
  static Future<void> mostrar(
    BuildContext context, {
    required String nomeAplicativo,
    required VoidCallback aoConfirmar,
  }) {
    return DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: chaveDialogo,
        titulo: TextosAtalhosAplicativos.tituloConfirmarAbertura(
          nomeAplicativo,
        ),
        mensagem: TextosAtalhosAplicativos.mensagemConfirmarAbertura(
          nomeAplicativo,
        ),
        rotuloConfirmar: TextosAtalhosAplicativos.botaoConfirmarAbertura,
        rotuloFechar: TextosAtalhosAplicativos.botaoCancelarAbertura,
        aoConfirmar: () {
          Navigator.of(context).pop();
          aoConfirmar();
        },
        aoFechar: () => Navigator.of(context).pop(),
      ),
    );
  }
}
