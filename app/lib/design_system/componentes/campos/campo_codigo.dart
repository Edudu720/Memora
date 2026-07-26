import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'campo_texto.dart';

/// Campo para o código numérico de 6 dígitos enviado por e-mail ou SMS.
///
/// Usa teclado numérico e aceita **apenas dígitos**. O código é digitado, e
/// nunca clicado a partir de um link: a FR-046 da feature 001 desaconselha
/// links de autenticação em canais imitáveis, porque clicar em link recebido
/// por mensagem é exatamente o comportamento que golpistas exploram.
///
/// A regra que ensinamos à pessoa é simples: **nunca clique, sempre digite**.
class CampoCodigo extends StatelessWidget {
  /// Quantidade de dígitos esperada.
  static const int digitos = 6;

  /// Nome do campo.
  final String rotulo;

  /// Para que serve este dado, em linguagem comum.
  final String textoAjuda;

  /// Controlador do conteúdo digitado.
  final TextEditingController? controlador;

  /// Mensagem de erro.
  final String? erro;

  /// Chamada a cada alteração.
  final ValueChanged<String>? aoMudar;

  /// Cria um campo de código.
  const CampoCodigo({
    required this.rotulo,
    this.textoAjuda = 'Digite os 6 números que enviamos para você',
    this.controlador,
    this.erro,
    this.aoMudar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CampoTexto(
      rotulo: rotulo,
      textoAjuda: textoAjuda,
      controlador: controlador,
      erro: erro,
      aoMudar: aoMudar,
      tipoTeclado: TextInputType.number,
      formatadores: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(digitos),
      ],
    );
  }
}
