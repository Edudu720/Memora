import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, LinearGradient;

import '../poses.dart';
import 'contexto_de_pintura.dart';
import 'geometria.dart';

/// Um braço com a mão arredondada (luva). Há uma instância por lado.
class CamadaBraco extends CamadaDaMemora {
  /// Se é o braço do lado esquerdo da imagem.
  final bool esquerdo;

  /// Cria a camada de um braço.
  const CamadaBraco({required this.esquerdo});

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final double presenca = ctx.pose.corpo;
    if (presenca <= 0) return;
    final PosicaoDoBraco braco =
        esquerdo ? ctx.pose.bracoEsquerdo : ctx.pose.bracoDireito;
    final Offset ombro = ctx.pp(
      esquerdo ? GeometriaDaMemora.ombroEsquerdo : GeometriaDaMemora.ombroDireito,
    );

    // O aceno só mexe a mão direita, em torno de onde ela já está.
    final double onda = esquerdo ? 0 : ctx.aceno;
    final Offset cotovelo =
        ctx.pp(braco.cotovelo).translate(ctx.l(0.02) * onda, 0);
    final Offset mao = ctx
        .pp(braco.mao)
        .translate(ctx.l(0.06) * onda, ctx.l(0.008) * onda.abs());

    final Path tubo = Path()
      ..moveTo(ombro.dx, ombro.dy)
      ..quadraticBezierTo(cotovelo.dx, cotovelo.dy, mao.dx, mao.dy);

    final double espessura = ctx.l(GeometriaDaMemora.braco);
    if (ctx.temAro) {
      canvas.drawPath(
        tubo,
        ctx.traco(ctx.cores.aro, espessura + ctx.contorno + 2 * ctx.aro),
      );
    }
    canvas.drawPath(
        tubo, ctx.traco(ctx.cores.contorno, espessura + ctx.contorno));
    final Rect caixa = tubo.getBounds().inflate(espessura);
    canvas.drawPath(
      tubo,
      ctx.traco(ctx.cores.corpo, espessura)
        ..shader = LinearGradient(
          begin: esquerdo ? Alignment.centerRight : Alignment.centerLeft,
          end: esquerdo ? Alignment.centerLeft : Alignment.centerRight,
          colors: <Color>[ctx.cores.corpoLuz, ctx.cores.corpoSombra],
        ).createShader(caixa),
    );

    // O dedo indicador levantado, atrás da mão.
    final double dedo = ctx.pose.dedo;
    if (!esquerdo && dedo > 0.01) {
      final Offset base = mao.translate(ctx.l(0.004), -ctx.l(0.03));
      final Offset ponta = base.translate(ctx.l(0.01), -ctx.l(0.12) * dedo);
      final Path haste = Path()
        ..moveTo(base.dx, base.dy)
        ..lineTo(ponta.dx, ponta.dy);
      final double larg = ctx.l(0.056);
      if (ctx.temAro) {
        canvas.drawPath(
            haste, ctx.traco(ctx.cores.aro, larg + ctx.contorno + 2 * ctx.aro));
      }
      canvas.drawPath(
          haste, ctx.traco(ctx.cores.contorno, larg + ctx.contorno));
      canvas.drawPath(haste, ctx.traco(ctx.cores.corpoLuz, larg));
    }

    // A mão: um círculo com o mesmo volume do corpo.
    final double raio = ctx.l(GeometriaDaMemora.raioDaMao);
    final Path luva = Path()
      ..addOval(Rect.fromCircle(center: mao, radius: raio));
    ctx.contornar(
      canvas,
      luva,
      ctx.degrade(
        Rect.fromCircle(center: mao, radius: raio),
        ctx.cores.corpoLuz,
        ctx.cores.corpoSombra,
      ),
      fator: 0.85,
    );
    canvas.drawCircle(
      mao.translate(-raio * 0.3, -raio * 0.34),
      raio * 0.2,
      ctx.cheio(ctx.cores.visor.withValues(alpha: 0.55)),
    );
  }
}
