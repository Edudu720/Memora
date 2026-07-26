import 'package:flutter/material.dart';

import '../../tokens/dimensoes.dart';
import 'botao_base.dart';

/// Ação alternativa, com menos peso que a principal.
///
/// Contornado em vez de preenchido. Continua com altura de
/// [MemoraDimensoes.alvoDecisao]: ter menos ênfase visual não significa ser
/// mais difícil de acertar.
class BotaoSecundario extends StatelessWidget {
  /// Texto do botão.
  final String rotulo;

  /// Ação disparada ao toque. `null` deixa o botão desabilitado.
  final VoidCallback? aoTocar;

  /// Ícone opcional, exibido antes do rótulo.
  final IconData? icone;

  /// Exibe indicador de progresso e bloqueia o toque.
  final bool carregando;

  /// Ocupa toda a largura disponível.
  final bool larguraTotal;

  /// Cria um botão de ação secundária.
  const BotaoSecundario({
    required this.rotulo,
    this.aoTocar,
    this.icone,
    this.carregando = false,
    this.larguraTotal = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BotaoBase(
      rotulo: rotulo,
      estilo: EstiloBotao.secundario,
      alturaMinima: MemoraDimensoes.alvoDecisao,
      aoTocar: aoTocar,
      icone: icone,
      carregando: carregando,
      larguraTotal: larguraTotal,
    );
  }
}
