import 'dart:math' as math;
import 'dart:ui';

import 'contexto_de_pintura.dart';

/// Olhos, sobrancelhas, boca e bochechas: o que dá expressão à Memora.
class CamadaRosto extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaRosto();

  static const double _olhoY = 0.375;
  static const double _olhoX = 0.105;

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    _bochechas(canvas, ctx);
    _olhos(canvas, ctx);
    _sobrancelhas(canvas, ctx);
    _boca(canvas, ctx);
  }

  void _bochechas(Canvas canvas, ContextoDePintura ctx) {
    final double alfa = ctx.pose.bochecha.clamp(0.0, 1.0);
    if (alfa <= 0) return;
    final Paint tinta = ctx.cheio(
      ctx.cores.bochecha.withValues(alpha: 0.9 * alfa),
    );
    for (final double sinal in <double>[-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: ctx.p(0.5 + sinal * 0.183, 0.472),
          width: ctx.l(0.082),
          height: ctx.l(0.048),
        ),
        tinta,
      );
    }
  }

  void _olhos(Canvas canvas, ContextoDePintura ctx) {
    final double feliz = ctx.pose.olhoFeliz.clamp(0.0, 1.0);
    final double aberto = (ctx.pose.olhoAbertura * (1 - ctx.piscar)).clamp(
      0.0,
      1.0,
    );
    for (final double sinal in <double>[-1, 1]) {
      final Offset centro = ctx.p(
        0.5 + sinal * _olhoX + ctx.pose.olharX * 0.012,
        _olhoY + ctx.pose.olharY * 0.012,
      );
      if (feliz < 1) {
        final double ry = math.max(ctx.l(0.008), ctx.l(0.054) * aberto);
        final Rect olho = Rect.fromCenter(
          center: centro,
          width: ctx.l(0.064),
          height: ry * 2,
        );
        canvas.drawOval(
          olho,
          ctx.cheio(ctx.cores.olho.withValues(alpha: 1 - feliz)),
        );
        // O brilho do olho, que some quando ele fecha.
        if (aberto > 0.45) {
          canvas.drawCircle(
            centro.translate(-ctx.l(0.011), -ry * 0.38),
            ctx.l(0.0095),
            ctx.cheio(ctx.cores.visor.withValues(alpha: 1 - feliz)),
          );
        }
      }
      if (feliz > 0) {
        // O arco feliz: um "^" arredondado.
        final Path arco = Path()
          ..moveTo(centro.dx - ctx.l(0.036), centro.dy + ctx.l(0.014))
          ..quadraticBezierTo(
            centro.dx,
            centro.dy - ctx.l(0.034),
            centro.dx + ctx.l(0.036),
            centro.dy + ctx.l(0.014),
          );
        canvas.drawPath(
          arco,
          ctx.traco(ctx.cores.olho.withValues(alpha: feliz), ctx.l(0.022)),
        );
      }
    }
  }

  void _sobrancelhas(Canvas canvas, ContextoDePintura ctx) {
    final double franzir = ctx.pose.sobrancelha.clamp(0.0, 1.0);
    if (franzir <= 0) return;
    final Paint tinta = ctx.traco(
      ctx.cores.olho.withValues(alpha: franzir),
      ctx.l(0.02),
    );
    for (final double sinal in <double>[-1, 1]) {
      // Preocupação, não bronca: a ponta de dentro SOBE (o contrário do
      // "franzido" bravo), com uma leve curva. Ela nunca repreende.
      final Offset fora = ctx.p(0.5 + sinal * 0.155, 0.318);
      final Offset dentro = ctx.p(0.5 + sinal * 0.055, 0.292 - 0.01 * franzir);
      final Offset meio = ctx.p(0.5 + sinal * 0.105, 0.296);
      final Path linha = Path()
        ..moveTo(fora.dx, fora.dy)
        ..quadraticBezierTo(meio.dx, meio.dy, dentro.dx, dentro.dy);
      canvas.drawPath(linha, tinta);
    }
  }

  void _boca(Canvas canvas, ContextoDePintura ctx) {
    final double visivel = ctx.pose.bocaVisivel.clamp(0.0, 1.0);
    if (visivel <= 0) return;
    final double abertura = (ctx.pose.bocaAbertura + ctx.fala * 0.55).clamp(
      0.0,
      1.0,
    );
    final double sorriso = ctx.pose.sorriso.clamp(-1.0, 1.0);
    final double meia = ctx.l(0.058 + 0.014 * abertura);
    final Offset centro = ctx.p(0.5 + ctx.pose.olharX * 0.01, 0.46);

    if (abertura < 0.12) {
      // Boca fechada: um arco, para cima (sorriso) ou para baixo (preocupada).
      final Path arco = Path()
        ..moveTo(centro.dx - meia, centro.dy)
        ..quadraticBezierTo(
          centro.dx,
          centro.dy + ctx.l(0.06) * sorriso,
          centro.dx + meia,
          centro.dy,
        );
      canvas.drawPath(
        arco,
        ctx.traco(ctx.cores.olho.withValues(alpha: visivel), ctx.l(0.019)),
      );
      return;
    }

    // Boca aberta: a de cima quase reta, a de baixo funda, com a língua.
    final double fundo =
        ctx.l(0.025 + 0.07 * abertura) * (0.55 + 0.45 * sorriso.abs());
    final Path boca = Path()
      ..moveTo(centro.dx - meia, centro.dy)
      ..quadraticBezierTo(
        centro.dx,
        centro.dy + ctx.l(0.012),
        centro.dx + meia,
        centro.dy,
      )
      ..quadraticBezierTo(
        centro.dx,
        centro.dy + fundo * 2,
        centro.dx - meia,
        centro.dy,
      )
      ..close();
    canvas.drawPath(boca, ctx.cheio(ctx.cores.olho.withValues(alpha: visivel)));
    canvas.save();
    canvas.clipPath(boca);
    canvas.drawOval(
      Rect.fromCenter(
        center: centro.translate(0, fundo * 1.25),
        width: meia * 1.3,
        height: fundo * 0.9,
      ),
      ctx.cheio(ctx.cores.bochecha.withValues(alpha: visivel)),
    );
    canvas.restore();
  }
}
