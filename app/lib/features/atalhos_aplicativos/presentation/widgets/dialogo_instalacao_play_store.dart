import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_atalhos_aplicativos.dart';

/// Diálogo de orientação segura quando a pessoa toca em um aplicativo que
/// ainda não está instalado no celular, oferecendo abertura da loja oficial.
class DialogoInstalacaoPlayStore {
  /// Chave raiz do diálogo de instalação na Play Store.
  static const Key chaveDialogo = Key('atalhos.confirmacao_instalacao');

  /// Exibe o diálogo perguntando se deseja abrir a Google Play Store.
  static Future<void> mostrar(
    BuildContext context, {
    required String nomeAplicativo,
    required VoidCallback aoConfirmar,
  }) {
    return DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: chaveDialogo,
        titulo: TextosAtalhosAplicativos.tituloConfirmarInstalacao(
          nomeAplicativo,
        ),
        mensagem: TextosAtalhosAplicativos.mensagemConfirmarInstalacao(
          nomeAplicativo,
        ),
        rotuloConfirmar: TextosAtalhosAplicativos.botaoConfirmarInstalacao,
        rotuloFechar: TextosAtalhosAplicativos.botaoCancelarInstalacao,
        aoConfirmar: () {
          Navigator.of(context).pop();
          aoConfirmar();
        },
        aoFechar: () => Navigator.of(context).pop(),
      ),
    );
  }
}
