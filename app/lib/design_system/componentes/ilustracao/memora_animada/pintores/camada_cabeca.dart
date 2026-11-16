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
  }
}
