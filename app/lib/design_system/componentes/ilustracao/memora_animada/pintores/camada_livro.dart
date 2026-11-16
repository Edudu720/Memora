import 'dart:math' as math;
import 'dart:ui';

import 'contexto_de_pintura.dart';

/// O livro aberto da expressão "dica": duas páginas e a capa por baixo.
class CamadaLivro extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaLivro();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final double presenca = ctx.pose.livro.clamp(0.0, 1.0);
    if (presenca <= 0.01) return;
    final Offset centro = ctx.p(0.215, 0.795);
    final double meiaLargura = ctx.l(0.165);
    final double meiaAltura = ctx.l(0.12);

    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.rotate(-0.16);
    canvas.scale(0.6 + 0.4 * presenca);

    // Capa: um pouco maior que as páginas, e escura.
    final Path capa = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(-meiaLargura - ctx.l(0.01), -meiaAltura - ctx.l(0.01),
            meiaLargura + ctx.l(0.01), meiaAltura + ctx.l(0.015)),
        Radius.circular(ctx.l(0.02)),
      ));
    ctx.contornar(canvas, capa, ctx.cheio(ctx.cores.livro), fator: 0.8);

    // As duas páginas, levemente inclinadas, para dar a ideia de livro aberto.
    final Path esquerda = Path()
      ..moveTo(-meiaLargura, -meiaAltura * 0.9)
      ..lineTo(-ctx.l(0.008), -meiaAltura)
      ..lineTo(-ctx.l(0.008), meiaAltura)
      ..lineTo(-meiaLargura, meiaAltura * 0.9)
      ..close();
    final Path direita = Path()
      ..moveTo(ctx.l(0.008), -meiaAltura)
      ..lineTo(meiaLargura, -meiaAltura * 0.9)
      ..lineTo(meiaLargura, meiaAltura * 0.9)
      ..lineTo(ctx.l(0.008), meiaAltura)
      ..close();
    canvas.drawPath(esquerda, ctx.cheio(ctx.cores.livroPagina));
    canvas.drawPath(direita, ctx.cheio(ctx.cores.escudoLuz));

    // Linhas de texto desenhadas, em cada página.
    final Paint linha =
        ctx.traco(ctx.cores.livro.withValues(alpha: 0.6), ctx.l(0.01));
    for (int i = 0; i < 3; i++) {
      final double y = -meiaAltura * 0.5 + i * meiaAltura * 0.45;
      canvas.drawLine(
          Offset(-meiaLargura * 0.82, y),
          Offset(-meiaLargura * 0.2, y - ctx.l(0.004) * math.max(1, i)),
          linha);
      canvas.drawLine(Offset(meiaLargura * 0.2, y - ctx.l(0.004)),
          Offset(meiaLargura * 0.82, y), linha);
    }
    canvas.restore();
  }
}
