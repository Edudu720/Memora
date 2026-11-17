import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment;

import 'contexto_de_pintura.dart';
import 'geometria.dart';

/// O visor: a "tela" clara que ocupa quase todo o rosto.
class CamadaVisor extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaVisor();

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final Rect caixa = ctx.rect(GeometriaDaMemora.visor);
    final Path forma = Path()..addRRect(ctx.rrect(
        GeometriaDaMemora.visor, GeometriaDaMemora.raioDoVisor));

    // Moldura fina e escura, só para separar o visor do corpo da cabeça.
    canvas.drawPath(forma, ctx.traco(ctx.cores.contorno, ctx.contorno * 0.8));
    canvas.drawPath(
      forma,
      ctx.degrade(
        caixa,
        ctx.cores.visor,
        Color.lerp(ctx.cores.visor, ctx.cores.corpo, 0.22)!,
        de: Alignment.topCenter,
        ate: Alignment.bottomCenter,
      ),
    );

    // Um brilho curto, de vidro, no canto de cima à esquerda.
    final Path brilho = Path()
      ..moveTo(caixa.left + caixa.width * 0.09, caixa.top + caixa.height * 0.30)
      ..quadraticBezierTo(
        caixa.left + caixa.width * 0.09,
        caixa.top + caixa.height * 0.12,
        caixa.left + caixa.width * 0.22,
        caixa.top + caixa.height * 0.1,
      );
    canvas.drawPath(
      brilho,
      ctx.traco(ctx.cores.livroPagina.withValues(alpha: 0.85), ctx.l(0.014)),
    );

    if (ctx.detalhada) {
      // Um segundo reflexo, em faixa diagonal, como o de um vidro de verdade:
      // ele fica parado enquanto o rosto desliza por baixo (T087).
      canvas.save();
      canvas.clipPath(forma);
      final Path faixa = Path()
        ..moveTo(caixa.left + caixa.width * 0.55, caixa.top)
        ..lineTo(caixa.left + caixa.width * 0.72, caixa.top)
        ..lineTo(caixa.left + caixa.width * 0.44, caixa.bottom)
        ..lineTo(caixa.left + caixa.width * 0.27, caixa.bottom)
        ..close();
      canvas.drawPath(
        faixa,
        ctx.cheio(ctx.cores.brilho.withValues(alpha: 0.22)),
      );
      canvas.restore();
    }
  }
}
