import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment;

import 'contexto_de_pintura.dart';
import 'geometria.dart';

/// A cabeça quadrada de cantos bem arredondados, com os fones nas laterais.
class CamadaCabeca extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaCabeca();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final Rect cabeca = ctx.rect(GeometriaDaMemora.cabeca);

    // Fones: duas cápsulas escuras, uma de cada lado, atrás da cabeça.
    final double altura = ctx.l(0.25);
    final double largura = ctx.l(0.105);
    for (final bool esquerdo in <bool>[true, false]) {
      final double x = esquerdo
          ? cabeca.left - ctx.l(0.012)
          : cabeca.right + ctx.l(0.012);
      final RRect fone = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, cabeca.center.dy + ctx.l(0.01)),
          width: largura,
          height: altura,
        ),
        Radius.circular(largura * 0.5),
      );
      final Path forma = Path()..addRRect(fone);
      ctx.contornar(
        canvas,
        forma,
        ctx.degrade(
          fone.outerRect,
          ctx.cores.corpoSombra,
          ctx.cores.contorno,
          de: Alignment.topCenter,
          ate: Alignment.bottomCenter,
        ),
        fator: 0.7,
      );
      if (ctx.detalhada) {
        // Um fio de luz no alto de cada fone, de onde a luz vem (T087).
        canvas.drawLine(
          Offset(fone.left + fone.width * 0.3, fone.top + fone.height * 0.2),
          Offset(fone.left + fone.width * 0.3, fone.top + fone.height * 0.5),
          ctx.traco(ctx.cores.luzDeContorno.withValues(alpha: 0.7), ctx.l(0.012)),
        );
      }
    }

    final Path forma = Path()
      ..addRRect(
        ctx.rrect(GeometriaDaMemora.cabeca, GeometriaDaMemora.raioDaCabeca),
      );
    ctx.contornar(
      canvas,
      forma,
      ctx.degrade(cabeca, ctx.cores.corpoLuz, ctx.cores.corpo),
    );

    // Sombra de baixo, para o volume: o queixo escurece.
    canvas.save();
    canvas.clipPath(forma);
    canvas.drawRect(
      Rect.fromLTRB(
        cabeca.left,
        cabeca.bottom - cabeca.height * 0.16,
        cabeca.right,
        cabeca.bottom,
      ),
      ctx.cheio(ctx.cores.corpoSombra.withValues(alpha: 0.6)),
    );
    canvas.restore();

    // Reflexo de luz no canto de cima à esquerda.
    final Path reflexo = Path()
      ..moveTo(
        cabeca.left + cabeca.width * 0.07,
        cabeca.top + cabeca.height * 0.36,
      )
      ..quadraticBezierTo(
        cabeca.left + cabeca.width * 0.06,
        cabeca.top + cabeca.height * 0.12,
        cabeca.left + cabeca.width * 0.27,
        cabeca.top + cabeca.height * 0.07,
      );
    canvas.drawPath(
      reflexo,
      ctx.traco(ctx.cores.visor.withValues(alpha: 0.55), ctx.l(0.016)),
    );

    if (ctx.detalhada) _acabamento(canvas, ctx, forma, cabeca);
  }

  /// O acabamento da anfitriã (T087): luz de contorno na borda de baixo e da
  /// direita, e um brilho especular — um ponto de luz forte na quina de cima à
  /// esquerda, de onde vem a luz, e um segundo, menor, logo ao lado.
  void _acabamento(Canvas canvas, ContextoDePintura ctx, Path forma, Rect cabeca) {
    ctx.luzNaBorda(canvas, forma, cabeca);

    canvas.save();
    canvas.clipPath(forma);
    canvas.save();
    canvas.translate(
      cabeca.left + cabeca.width * 0.2,
      cabeca.top + cabeca.height * 0.15,
    );
    canvas.rotate(-0.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: cabeca.width * 0.24,
        height: cabeca.height * 0.085,
      ),
      ctx.cheio(ctx.cores.brilho.withValues(alpha: 0.75))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ctx.l(0.006)),
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(
        cabeca.left + cabeca.width * 0.33,
        cabeca.top + cabeca.height * 0.085,
      ),
      ctx.l(0.0085),
      ctx.cheio(ctx.cores.brilho.withValues(alpha: 0.85)),
    );
    canvas.restore();
  }
}
