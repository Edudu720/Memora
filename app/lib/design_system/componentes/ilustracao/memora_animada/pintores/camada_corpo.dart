import 'dart:ui';


import 'contexto_de_pintura.dart';
import 'geometria.dart';

/// O tronco: um bloco arredondado com a luz vindo de cima à esquerda.
class CamadaCorpo extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaCorpo();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final Rect caixa = ctx.rect(GeometriaDaMemora.tronco);
    // Respirar estica o tronco um fio para cima, a partir da base.
    canvas.save();
    canvas.translate(0, caixa.bottom);
    canvas.scale(1, 1 + ctx.respira * 0.012);
    canvas.translate(0, -caixa.bottom);

    final Path forma = Path()
      ..addRRect(RRect.fromRectAndCorners(
        caixa,
        topLeft: Radius.circular(ctx.l(0.11)),
        topRight: Radius.circular(ctx.l(0.11)),
        bottomLeft: Radius.circular(ctx.l(0.13)),
        bottomRight: Radius.circular(ctx.l(0.13)),
      ));
    final Paint tinta = ctx.degrade(
      caixa,
      ctx.cores.corpoLuz,
      ctx.cores.corpoSombra,
    );
    ctx.contornar(canvas, forma, tinta);

    // Um reflexo de luz na quina de cima à esquerda.
    final Path reflexo = Path()
      ..moveTo(caixa.left + caixa.width * 0.14, caixa.top + caixa.height * 0.42)
      ..quadraticBezierTo(
        caixa.left + caixa.width * 0.1,
        caixa.top + caixa.height * 0.22,
        caixa.left + caixa.width * 0.3,
        caixa.top + caixa.height * 0.1,
      );
    canvas.drawPath(
      reflexo,
      ctx.traco(ctx.cores.corpoLuz.withValues(alpha: 0.8), ctx.l(0.018)),
    );
    canvas.restore();
  }
}
