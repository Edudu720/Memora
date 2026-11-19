import 'dart:ui';

import 'contexto_de_pintura.dart';

/// O escudo da expressão preocupada: duas metades, uma clara e uma escura.
class CamadaEscudo extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaEscudo();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final double presenca = ctx.pose.escudo.clamp(0.0, 1.0);
    if (presenca <= 0.01) return;
    final Offset centro = ctx.p(0.745, 0.80);
    final double meiaLargura = ctx.l(0.135);
    final double meiaAltura = ctx.l(0.16);

    canvas.save();
    // Ele chega crescendo a partir do centro.
    canvas.translate(centro.dx, centro.dy);
    canvas.scale(0.6 + 0.4 * presenca);
    canvas.translate(-centro.dx, -centro.dy);

    final Path forma = Path()
      ..moveTo(centro.dx - meiaLargura, centro.dy - meiaAltura * 0.9)
      ..quadraticBezierTo(centro.dx, centro.dy - meiaAltura * 1.15,
          centro.dx + meiaLargura, centro.dy - meiaAltura * 0.9)
      ..lineTo(centro.dx + meiaLargura, centro.dy + meiaAltura * 0.05)
      ..quadraticBezierTo(centro.dx + meiaLargura * 0.9,
          centro.dy + meiaAltura * 0.7, centro.dx, centro.dy + meiaAltura)
      ..quadraticBezierTo(centro.dx - meiaLargura * 0.9,
          centro.dy + meiaAltura * 0.7, centro.dx - meiaLargura,
          centro.dy + meiaAltura * 0.05)
      ..close();
    final Rect caixa = forma.getBounds();

    ctx.contornar(
      canvas,
      forma,
      ctx.degrade(caixa, ctx.cores.escudoLuz, ctx.cores.escudo),
      fator: 0.85,
    );

    // A metade da direita fica mais escura: é o que lhe dá volume.
    canvas.save();
    canvas.clipPath(forma);
    canvas.drawRect(
      Rect.fromLTRB(centro.dx, caixa.top, caixa.right, caixa.bottom),
      ctx.cheio(ctx.cores.livro.withValues(alpha: 0.55)),
    );
    canvas.restore();
    canvas.restore();
  }
}
