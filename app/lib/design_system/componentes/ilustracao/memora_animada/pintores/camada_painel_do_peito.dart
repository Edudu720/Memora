import 'dart:ui';

import 'contexto_de_pintura.dart';
import 'geometria.dart';

/// O painel do peito: retângulo escuro, um círculo amarelo e barrinhas claras.
class CamadaPainelDoPeito extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaPainelDoPeito();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final RRect painel = ctx.rrect(GeometriaDaMemora.painel, 0.025);
    canvas.drawRRect(painel, ctx.cheio(ctx.cores.contorno));

    final Rect caixa = painel.outerRect;
    final double passo = caixa.height / 4;

    // O círculo amarelo, à esquerda, com um brilho.
    final Offset centro = Offset(caixa.left + caixa.width * 0.29, caixa.center.dy);
    final double raio = caixa.height * 0.30;
    canvas.drawCircle(centro, raio, ctx.cheio(ctx.cores.detalhe));
    canvas.drawCircle(
      centro.translate(-raio * 0.3, -raio * 0.3),
      raio * 0.28,
      ctx.cheio(ctx.cores.livroPagina.withValues(alpha: 0.7)),
    );

    // Três barrinhas, à direita.
    final double inicio = caixa.left + caixa.width * 0.55;
    final double fim = caixa.right - caixa.width * 0.1;
    for (int i = 1; i <= 3; i++) {
      final double y = caixa.top + passo * i;
      final double comprimento = i == 2 ? 0.55 : 1.0;
      canvas.drawLine(
        Offset(inicio, y),
        Offset(inicio + (fim - inicio) * comprimento, y),
        ctx.traco(ctx.cores.painelBarra, caixa.height * 0.13),
      );
    }
  }
}
