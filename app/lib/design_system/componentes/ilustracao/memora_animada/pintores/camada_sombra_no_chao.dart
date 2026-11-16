import 'dart:ui';

import 'contexto_de_pintura.dart';

/// A sombra elíptica no chão: dá o "2.5D" e encolhe quando ela salta.
class CamadaSombraNoChao extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaSombraNoChao();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    // Só a cabeça: nada para apoiar no chão.
    final double presenca = ctx.pose.corpo;
    if (presenca <= 0) return;
    final double encolhe = 1 - ctx.pulo * 0.35;
    final double largura = ctx.l(0.52) * encolhe;
    final double altura = ctx.l(0.055) * encolhe;
    final Paint tinta = ctx.cheio(ctx.cores.sombraChao)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, ctx.l(0.018));
    canvas.drawOval(
      Rect.fromCenter(
        center: ctx.p(0.5, 0.978),
        width: largura * presenca,
        height: altura * presenca,
      ),
      tinta,
    );
  }
}
