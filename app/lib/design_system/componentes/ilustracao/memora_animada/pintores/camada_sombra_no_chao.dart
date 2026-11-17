import 'dart:ui';

import 'contexto_de_pintura.dart';

/// A sombra elíptica no chão: dá o "2.5D" e encolhe quando ela salta.
///
/// Na anfitriã ela ganha uma **sombra de contato** (T087): uma elipse pequena e
/// escura logo debaixo dos pés, que some quando ela flutua ou salta, por cima
/// da sombra larga e macia. É o que mostra se ela está apoiada ou no ar.
class CamadaSombraNoChao extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaSombraNoChao();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    // Só a cabeça: nada para apoiar no chão.
    final double presenca = ctx.pose.corpo;
    if (presenca <= 0) return;
    final double suspensa = (ctx.pulo + ctx.flutua * 0.5).clamp(0.0, 1.0);
    final double encolhe = 1 - ctx.pulo * 0.35 - ctx.flutua * 0.12;
    final double largura = ctx.l(0.6) * encolhe;
    final double altura = ctx.l(0.068) * encolhe;
    final double clareia = 1 - 0.3 * ctx.flutua;
    final Paint tinta = ctx.cheio(
      ctx.cores.sombraChao.withValues(
        alpha: ctx.cores.sombraChao.a * clareia,
      ),
    )..maskFilter = MaskFilter.blur(BlurStyle.normal, ctx.l(0.018));
    canvas.drawOval(
      Rect.fromCenter(
        center: ctx.p(0.5, 0.978),
        width: largura * presenca,
        height: altura * presenca,
      ),
      tinta,
    );

    if (ctx.detalhada) {
      // O contato: pequeno, escuro e firme; quanto mais no ar, mais fraco.
      final Paint contato = ctx.cheio(
        ctx.cores.contorno.withValues(
          alpha: ctx.cores.sombraChao.a * 0.9 * (1 - suspensa),
        ),
      )..maskFilter = MaskFilter.blur(BlurStyle.normal, ctx.l(0.008));
      canvas.drawOval(
        Rect.fromCenter(
          center: ctx.p(0.5, 0.972),
          width: ctx.l(0.32) * presenca * (1 - 0.4 * suspensa),
          height: ctx.l(0.026) * presenca,
        ),
        contato,
      );
    }
  }
}
