import 'dart:ui';

import 'contexto_de_pintura.dart';
import 'geometria.dart';

/// A antena fina com a bolinha amarela. Balança um pouco com a paralaxe.
class CamadaAntena extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaAntena();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final Offset base = ctx.p(0.5, GeometriaDaMemora.cabeca.top + 0.02);
    // A bolinha atrasa em relação à cabeça: é o que faz parecer mola.
    final Offset ponta = ctx.p(0.5, GeometriaDaMemora.bolinha.dy).translate(
          ctx.balanco * ctx.l(0.014) -
              ctx.respira * ctx.l(0.002) +
              ctx.antena * ctx.l(0.03),
          0,
        );
    final Path haste = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx,
        (base.dy + ponta.dy) / 2,
        ponta.dx,
        ponta.dy,
      );
    if (ctx.temAro) {
      canvas.drawPath(
        haste,
        ctx.traco(ctx.cores.aro, ctx.l(0.03) + 2 * ctx.aro * 0.6),
      );
    }
    canvas.drawPath(haste, ctx.traco(ctx.cores.contorno, ctx.l(0.03)));

    final double raio = ctx.l(GeometriaDaMemora.raioDaBolinha);
    if (ctx.detalhada) {
      // Um halo macio, que pulsa com a respiração: a antena "acesa" (T087).
      canvas.drawCircle(
        ponta,
        raio * 2.3,
        ctx.cheio(
          ctx.cores.detalhe.withValues(alpha: 0.3 + 0.1 * ctx.respira),
        )..maskFilter = MaskFilter.blur(BlurStyle.normal, raio * 1.1),
      );
    }
    if (ctx.temAro) {
      canvas.drawCircle(ponta, raio + ctx.contorno * 0.5 + ctx.aro * 0.8,
          ctx.cheio(ctx.cores.aro));
    }
    canvas.drawCircle(ponta, raio + ctx.contorno * 0.5,
        ctx.cheio(ctx.cores.contorno));
    canvas.drawCircle(ponta, raio, ctx.cheio(ctx.cores.detalhe));
    canvas.drawCircle(
      ponta.translate(-raio * 0.3, -raio * 0.3),
      raio * 0.3,
      ctx.cheio(ctx.cores.livroPagina.withValues(alpha: 0.75)),
    );
  }
}
