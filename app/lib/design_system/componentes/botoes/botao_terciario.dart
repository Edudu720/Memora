import 'package:flutter/material.dart';

import '../../tokens/dimensoes.dart';
import 'botao_base.dart';

/// Ação de baixo peso, como "Esqueci minha senha".
///
/// Apenas texto sublinhado. O sublinhado não é decoração: é o que sinaliza
/// "isto é clicável" sem depender de cor, atendendo a quem não distingue
/// matizes.
///
/// Usa [MemoraDimensoes.alvoMinimo] — menor que os demais, mas **nunca** abaixo
/// dos 48 dp exigidos.
class BotaoTerciario extends StatelessWidget {
  /// Texto do botão.
  final String rotulo;

  /// Ação disparada ao toque. `null` deixa o botão desabilitado.
  final VoidCallback? aoTocar;

  /// Ocupa toda a largura disponível.
  final bool larguraTotal;

  /// Ícone opcional, antes do rótulo. O rótulo continua obrigatório.
  final IconData? icone;

  /// Cria um botão de ação terciária.
  const BotaoTerciario({
    required this.rotulo,
    this.aoTocar,
    this.larguraTotal = false,
    this.icone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BotaoBase(
      rotulo: rotulo,
      estilo: EstiloBotao.terciario,
      alturaMinima: MemoraDimensoes.alvoMinimo,
      aoTocar: aoTocar,
      icone: icone,
      larguraTotal: larguraTotal,
    );
  }
}
