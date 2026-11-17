import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, LinearGradient;

import '../poses.dart';
import 'contexto_de_pintura.dart';
import 'geometria.dart';

/// Um braço que afina do ombro ao punho, com cotovelo dobrado e uma mão de
/// luva arredondada. Há uma instância por lado.
class CamadaBraco extends CamadaDaMemora {
  /// Se é o braço do lado esquerdo da imagem.
  final bool esquerdo;

  /// Cria a camada de um braço.
  const CamadaBraco({required this.esquerdo});

  /// Onde fica o centro da mão neste quadro, em pixels, com o aceno somado.
  /// É o mesmo ponto em que a luva é pintada: quem segura algo nela (a barra
  /// da abertura, T092) pergunta aqui.
  static Offset maoNoQuadro(ContextoDePintura ctx, {required bool esquerdo}) {
    final PosicaoDoBraco braco = esquerdo
        ? ctx.pose.bracoEsquerdo
        : ctx.pose.bracoDireito;
    final double onda = esquerdo ? 0 : ctx.aceno;
    return ctx
        .pp(braco.mao)
        .translate(ctx.l(0.06) * onda, ctx.l(0.008) * onda.abs());
  }

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final double presenca = ctx.pose.corpo;
    if (presenca <= 0) return;
    final PosicaoDoBraco braco = esquerdo
        ? ctx.pose.bracoEsquerdo
        : ctx.pose.bracoDireito;
    final Offset ombro = ctx.pp(
      esquerdo
          ? GeometriaDaMemora.ombroEsquerdo
          : GeometriaDaMemora.ombroDireito,
    );

    // O aceno só mexe a mão direita, em torno de onde ela já está.
    final double onda = esquerdo ? 0 : ctx.aceno;
    final Offset cotovelo = ctx
        .pp(braco.cotovelo)
        .translate(ctx.l(0.02) * onda, 0);
    final Offset mao = maoNoQuadro(ctx, esquerdo: esquerdo);

    _tubo(canvas, ctx, ombro, cotovelo, mao);

    // O dedo indicador levantado nasce do punho fechado.
    final double dedo = ctx.pose.dedo;
    if (!esquerdo && dedo > 0.01) _dedo(canvas, ctx, mao, dedo);

    _luva(canvas, ctx, cotovelo, mao);
  }

  /// O braço: dois segmentos que afinam do ombro ao punho (largura de
  /// [GeometriaDaMemora.bracoOmbro] a [GeometriaDaMemora.bracoPunho]), unidos
  /// por juntas redondas no ombro e no cotovelo. Uma junta redonda, e não uma
  /// curva no eixo, é o que deixa o cotovelo dobrar até ficar fechado (o braço
  /// do "pensando") sem o contorno se cruzar.
  void _tubo(
    Canvas canvas,
    ContextoDePintura ctx,
    Offset ombro,
    Offset cotovelo,
    Offset mao,
  ) {
    final double w0 = ctx.l(GeometriaDaMemora.bracoOmbro);
    final double w1 = ctx.l(GeometriaDaMemora.bracoPunho);
    final double wm = (w0 + w1) / 2;

    Path segmento(Offset a, Offset b, double larguraA, double larguraB) {
      final Offset v = b - a;
      final double d = v.distance;
      if (d == 0) return Path();
      final Offset normal = Offset(-v.dy / d, v.dx / d);
      return Path()
        ..moveTo(
          a.dx + normal.dx * larguraA / 2,
          a.dy + normal.dy * larguraA / 2,
        )
        ..lineTo(
          b.dx + normal.dx * larguraB / 2,
          b.dy + normal.dy * larguraB / 2,
        )
        ..lineTo(
          b.dx - normal.dx * larguraB / 2,
          b.dy - normal.dy * larguraB / 2,
        )
        ..lineTo(
          a.dx - normal.dx * larguraA / 2,
          a.dy - normal.dy * larguraA / 2,
        )
        ..close();
    }

    Path junta(Offset c, double larg) =>
        Path()..addOval(Rect.fromCircle(center: c, radius: larg / 2));

    Path braco = segmento(ombro, cotovelo, w0, wm);
    for (final Path parte in <Path>[
      junta(ombro, w0),
      segmento(cotovelo, mao, wm, w1),
      junta(cotovelo, wm),
    ]) {
      braco = Path.combine(PathOperation.union, braco, parte);
    }

    final Rect caixa = braco.getBounds();
    ctx.contornar(
      canvas,
      braco,
      Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..shader = LinearGradient(
          begin: esquerdo ? Alignment.centerRight : Alignment.centerLeft,
          end: esquerdo ? Alignment.centerLeft : Alignment.centerRight,
          colors: <Color>[ctx.cores.corpoLuz, ctx.cores.corpoSombra],
        ).createShader(caixa),
      fator: 0.9,
    );
    if (ctx.detalhada) {
      ctx.luzNaBorda(canvas, braco, caixa, espessura: 0.028, forca: 0.8);
    }
  }

  /// O dedo: uma cápsula arredondada que sai do alto da mão fechada.
  void _dedo(Canvas canvas, ContextoDePintura ctx, Offset mao, double dedo) {
    final double largura = ctx.l(0.052);
    final double comprimento = ctx.l(0.16) * dedo;
    final Rect cap = Rect.fromLTWH(
      mao.dx - largura / 2 + ctx.l(0.004),
      mao.dy - ctx.l(0.025) - comprimento,
      largura,
      comprimento + ctx.l(0.02),
    );
    final Path forma = Path()
      ..addRRect(RRect.fromRectAndRadius(cap, Radius.circular(largura / 2)));
    ctx.contornar(
      canvas,
      forma,
      ctx.degrade(
        cap,
        ctx.cores.corpoLuz,
        ctx.cores.corpo,
        de: Alignment.centerLeft,
        ate: Alignment.centerRight,
      ),
      fator: 0.85,
    );
  }

  /// A mão: uma luva oval no sentido do antebraço, com o polegar por fora.
  void _luva(
    Canvas canvas,
    ContextoDePintura ctx,
    Offset cotovelo,
    Offset mao,
  ) {
    final Offset direcao = mao - cotovelo;
    final double angulo = math.atan2(direcao.dy, direcao.dx);
    final double largura = ctx.l(0.108);
    final double altura = ctx.l(0.128);

    // O polegar, do lado de dentro, um pouco para cima.
    final double para = esquerdo ? 1 : -1;
    final Offset polegar = mao.translate(para * ctx.l(0.046), -ctx.l(0.012));
    final Rect cxPolegar = Rect.fromCircle(
      center: polegar,
      radius: ctx.l(0.03),
    );
    ctx.contornar(
      canvas,
      Path()..addOval(cxPolegar),
      ctx.degrade(cxPolegar, ctx.cores.corpoLuz, ctx.cores.corpo),
      fator: 0.75,
    );

    canvas.save();
    canvas.translate(mao.dx, mao.dy);
    canvas.rotate(angulo - math.pi / 2);
    final Rect oval = Rect.fromCenter(
      center: Offset(0, ctx.l(0.008)),
      width: largura,
      height: altura,
    );
    ctx.contornar(
      canvas,
      Path()..addOval(oval),
      ctx.degrade(oval, ctx.cores.corpoLuz, ctx.cores.corpoSombra),
      fator: 0.9,
    );
    canvas.restore();

    canvas.drawCircle(
      mao.translate(-ctx.l(0.018), -ctx.l(0.022)),
      ctx.l(0.011),
      ctx.cheio(
        ctx.detalhada
            ? ctx.cores.brilho.withValues(alpha: 0.9)
            : ctx.cores.visor.withValues(alpha: 0.55),
      ),
    );
  }
}
