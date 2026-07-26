import 'package:flutter/material.dart';

import '../../tokens/dimensoes.dart';
import 'botao_base.dart';

/// Ação principal de uma tela.
///
/// Preenchido com a cor primária e com altura de
/// [MemoraDimensoes.alvoDecisao] — acima do mínimo de 48 dp, porque este é o
/// botão que a pessoa idosa mais precisa acertar de primeira.
///
/// **Use no máximo um por tela.** Duas ações com o mesmo peso visual obrigam a
/// pessoa a decidir qual é a principal, e essa decisão é nossa, não dela.
class BotaoPrimario extends StatelessWidget {
  /// Texto do botão. Prefira frases completas a palavras isoladas.
  final String rotulo;

  /// Ação disparada ao toque. `null` deixa o botão desabilitado.
  final VoidCallback? aoTocar;

  /// Ícone opcional, exibido antes do rótulo.
  final IconData? icone;

  /// Exibe indicador de progresso e bloqueia o toque.
  final bool carregando;

  /// Ocupa toda a largura disponível.
  final bool larguraTotal;

  /// Cria um botão de ação principal.
  const BotaoPrimario({
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
      estilo: EstiloBotao.primario,
      alturaMinima: MemoraDimensoes.alvoDecisao,
      aoTocar: aoTocar,
      icone: icone,
      carregando: carregando,
      larguraTotal: larguraTotal,
    );
  }
}
