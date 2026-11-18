import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Diálogo pedagógico prévio que explica o motivo do pedido de localização (FR-004, AC-003).
class DialogoPermissaoLocalizacao extends StatelessWidget {
  /// Chave raiz do diálogo de permissão.
  static const Key chaveDialogo = Key('localizador.dialogo_permissao');

  /// Chave do botão que confirma o pedido de localização.
  static const Key chaveConfirmar = Key('localizador.dialogo_permissao.confirmar');

  /// Chave do botão que recusa e mantém a pesquisa manual.
  static const Key chaveCancelar = Key('localizador.dialogo_permissao.cancelar');

  /// Retorno executado ao aceitar o uso da localização.
  final VoidCallback aoConfirmar;

  /// Retorno executado ao recusar e optar pela pesquisa manual.
  final VoidCallback aoCancelar;

  /// Cria o widget auxiliar de referência do diálogo de permissão.
  const DialogoPermissaoLocalizacao({
    required this.aoConfirmar,
    required this.aoCancelar,
    super.key,
  });

  /// Exibe o diálogo explicativo dentro do navegador do destino atual.
  static Future<void> mostrar(
    BuildContext context, {
    required VoidCallback aoConfirmar,
    required VoidCallback aoCancelar,
  }) {
    return DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: chaveDialogo,
        titulo: 'Autorizar localização?',
        mensagem:
            'Para achar saúde, farmácias e serviços perto de você, eu consulto '
            'sua localização só agora, no mapa público OpenStreetMap.\n\n'
            'Não envio dados da sua conta nem guardo por onde você passou — se '
            'preferir, escreva o nome do seu bairro ou cidade.',
        rotuloConfirmar: 'Sim, permitir localização',
        rotuloFechar: 'Não agora (pesquisar manual)',
        aoConfirmar: aoConfirmar,
        aoFechar: aoCancelar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
