import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Diálogo de confirmação em duas etapas antes de discar ligação telefônica (FR-012, NFR-008).
class DialogoConfirmacaoLigacao {
  /// Chave raiz do diálogo de confirmação de chamada.
  static const Key chaveDialogo = Key('localizador.confirmacao_ligacao');

  /// Chave do botão que confirma a abertura do discador.
  static const Key chaveConfirmar = Key('localizador.confirmacao_ligacao.confirmar');

  /// Chave do botão que cancela e volta à tela anterior.
  static const Key chaveCancelar = Key('localizador.confirmacao_ligacao.cancelar');

  /// Exibe o diálogo confirmando nome e telefone antes de discar.
  static Future<void> mostrar(
    BuildContext context, {
    required String nomeDestino,
    required String telefone,
    required VoidCallback aoConfirmar,
  }) {
    return DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: chaveDialogo,
        titulo: 'Fazer ligação telefônica?',
        mensagem:
            'Você deseja ligar para:\n\n'
            '• $nomeDestino\n'
            '• Telefone: $telefone\n\n'
            'Ao confirmar, o discador do seu celular será aberto para você iniciar a chamada com segurança.',
        rotuloConfirmar: 'Ligar para $telefone',
        rotuloFechar: 'Voltar',
        aoConfirmar: () {
          Navigator.of(context).pop();
          aoConfirmar();
        },
        aoFechar: () => Navigator.of(context).pop(),
      ),
    );
  }
}
