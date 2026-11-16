import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Diálogo de confirmação em duas etapas antes de abrir aplicativo de mapas externo (FR-010, NFR-008).
class DialogoConfirmacaoRota {
  /// Chave raiz do diálogo de confirmação de rota externa.
  static const Key chaveDialogo = Key('localizador.confirmacao_rota');

  /// Chave do botão que confirma abrir o mapa externo.
  static const Key chaveConfirmar = Key('localizador.confirmacao_rota.confirmar');

  /// Chave do botão que mantém a pessoa no Memora.
  static const Key chaveCancelar = Key('localizador.confirmacao_rota.cancelar');

  /// Exibe o diálogo confirmando o destino antes de abrir o mapa externo.
  static Future<void> mostrar(
    BuildContext context, {
    required String nomeDestino,
    required String enderecoFormatado,
    required VoidCallback aoConfirmar,
  }) {
    return DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: chaveDialogo,
        titulo: 'Ver como chegar?',
        mensagem:
            'Você está prestes a sair do Memora para ver o caminho até:\n\n'
            '• $nomeDestino\n'
            '• $enderecoFormatado\n\n'
            'Deseja abrir o aplicativo de mapas do seu celular agora?',
        rotuloConfirmar: 'Abrir mapa e rotas',
        rotuloFechar: 'Ficar no Memora',
        aoConfirmar: () {
          Navigator.of(context).pop();
          aoConfirmar();
        },
        aoFechar: () => Navigator.of(context).pop(),
      ),
    );
  }
}
