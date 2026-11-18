import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/componentes/toque/superficie_tocavel.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_sos.dart';

/// O botão SOS persistente: uma bolinha vermelha com "SOS" (feature 014).
///
/// ## Por que uma bolinha (decisão do Henrique, 2026-11-18)
///
/// A versão anterior mostrava três textos — o ícone "sos", "SOS" e "Ajuda" —
/// numa pílula que ganhava uma faixa inteira no topo de toda tela. Agora é um
/// círculo na cor de perigo do tema, com "SOS" em negrito, no canto superior
/// direito do cabeçalho de cada tela (`VagaDoSos`).
///
/// ## O que não muda
///
/// - **O leitor de tela** anuncia o mesmo de antes: o nome
///   [TextosSos.rotuloBotaoSos] e a dica [TextosSos.semanticaBotaoSos], como
///   botão. O nome falado começa pela palavra escrita ("SOS"), como pede a
///   WCAG 2.5.3.
/// - **O alvo de toque** nunca é menor que [MemoraDimensoes.alvoMinimo].
///
/// ## A bolinha cresce com a letra
///
/// O diâmetro é o maior entre 48 dp e a diagonal do texto "SOS" na escala da
/// pessoa ([diametro]): a diagonal é o que garante que o retângulo do texto
/// cabe inteiro dentro do círculo. A letra nunca é encolhida para caber.
class BotaoSosPersistente extends StatelessWidget {
  /// Chave padrão quando usado isoladamente em widgets/testes.
  static const Key chaveBotao = Key('botao_sos_persistente');

  /// O estilo do "SOS": o do rótulo de botão, em negrito.
  static final TextStyle estiloDoTexto = MemoraTipografia.rotuloBotao.copyWith(
    fontWeight: MemoraTipografia.pesoDoNegrito,
  );

  /// Ação chamada ao tocar no botão (sempre abre a confirmação antes do envio).
  final VoidCallback aoTocar;

  /// Cria o botão SOS persistente.
  const BotaoSosPersistente({
    required this.aoTocar,
    super.key,
  });

  /// O diâmetro da bolinha na escala de texto de [context].
  static double diametro(BuildContext context) {
    final TextPainter medida = TextPainter(
      text: TextSpan(text: TextosSos.textoDaBolinha, style: estiloDoTexto),
      textDirection: TextDirection.ltr,
      textScaler: escalaTextoLimitada(context),
      maxLines: 1,
    )..layout();
    final double diagonal = math.sqrt(
      medida.width * medida.width + medida.height * medida.height,
    );
    medida.dispose();
    return math.max(MemoraDimensoes.alvoMinimo, diagonal);
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double lado = diametro(context);

    return SuperficieTocavel(
      rotulo: TextosSos.rotuloBotaoSos,
      dica: TextosSos.semanticaBotaoSos,
      fundo: cores.perigo,
      borda: ehAltoContraste ? cores.borda : cores.sobrePerigo,
      raio: BorderRadius.circular(MemoraRaio.pilula),
      sombra: !ehAltoContraste,
      conteinerSemantico: true,
      aoTocar: aoTocar,
      child: SizedBox.square(
        dimension: lado,
        child: Center(
          child: Text(
            TextosSos.textoDaBolinha,
            style: estiloDoTexto.copyWith(color: cores.sobrePerigo),
            textScaler: escalaTextoLimitada(context),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}
