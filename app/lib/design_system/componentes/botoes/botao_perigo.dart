import 'package:flutter/material.dart';

import '../../tokens/dimensoes.dart';
import 'botao_base.dart';

/// Ação destrutiva ou irreversível — apagar conta, excluir dados, sair.
///
/// ## Ícone obrigatório, e não por estética
///
/// O ícone é exigido pela FR-014: a gravidade da ação **nunca** pode ser
/// comunicada apenas por cor. Quem não distingue vermelho de azul precisa
/// perceber o perigo por outro canal.
///
/// ## Regra de posicionamento
///
/// Este botão **não pode ficar adjacente a um botão comum** (FR-013). Separe-o
/// com [MemoraEspacamento.xxxl] ou coloque-o em outra seção da tela. Foi
/// exatamente a adjacência dos botões SIM/NÃO do protótipo que criou risco de
/// confirmação acidental.
class BotaoPerigo extends StatelessWidget {
  /// Texto do botão. Descreva a consequência, não a operação: prefira
  /// "Apagar minhas fotos" a "Excluir".
  final String rotulo;

  /// Ícone que reforça a gravidade. **Obrigatório** (FR-014).
  final IconData icone;

  /// Ação disparada ao toque. `null` deixa o botão desabilitado.
  final VoidCallback? aoTocar;

  /// Exibe indicador de progresso e bloqueia o toque.
  final bool carregando;

  /// Ocupa toda a largura disponível.
  final bool larguraTotal;

  /// Cria um botão de ação destrutiva.
  const BotaoPerigo({
    required this.rotulo,
    required this.icone,
    this.aoTocar,
    this.carregando = false,
    this.larguraTotal = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BotaoBase(
      rotulo: rotulo,
      estilo: EstiloBotao.perigo,
      alturaMinima: MemoraDimensoes.alvoDecisao,
      aoTocar: aoTocar,
      icone: icone,
      carregando: carregando,
      larguraTotal: larguraTotal,
    );
  }
}
