import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment;

import '../poses.dart';
import 'camada_braco.dart';
import 'contexto_de_pintura.dart';

/// A barra de carregamento que a Memora segura na abertura (feature 013,
/// T092).
///
/// ## Entre as mãos, e não num lugar fixo
///
/// A barra vai **de uma mão à outra**, um pouco além de cada punho: é
/// desenhada a partir de onde as mãos estão neste quadro
/// ([CamadaBraco.maoNoQuadro]). Respirar, flutuar, ajeitar o corpo ou trocar
/// de pose leva a barra junto, e ela nunca descola das mãos. As luvas são
/// pintadas **por cima** dela (ver `PintorDaMemora`): é o que faz a mão
/// fechar em volta da ponta.
///
/// ## Sem número
///
/// Uma pílula de vidro (o mesmo do visor) com um trecho da cor do corpo que a
/// atravessa da esquerda para a direita, sem fim: é indeterminada, e não diz
/// "quanto falta" (US7, cenário 1). Parada ([ContextoDePintura.cicloDaBarra]
/// nulo), o trecho fica no meio — nem vazio, que parece quebrado, nem cheio,
/// que parece pronto.
class CamadaBarra extends CamadaDaMemora {
  /// Cria a camada.
  const CamadaBarra();

  /// A espessura da barra.
  static const double espessura = 0.1;

  /// Quanto a barra passa de cada punho, para a ponta aparecer fora da mão.
  static const double sobra = 0.03;

  /// A folga entre a borda da barra e o trilho por dentro.
  static const double folgaDoTrilho = 0.02;

  /// Quanto do trilho o trecho que corre ocupa.
  static const double fracaoDoTrecho = 0.4;

  @override
  void pintar(Canvas canvas, ContextoDePintura ctx) {
    final double presenca = ctx.pose.barra.clamp(0.0, 1.0);
    if (presenca <= 0.01 || ctx.pose.corpo <= 0) return;

    final Offset a = CamadaBraco.maoNoQuadro(ctx, esquerdo: true);
    final Offset b = CamadaBraco.maoNoQuadro(ctx, esquerdo: false);
    final Offset meio = Offset.lerp(a, b, 0.5)!;
    final double comprimento = (b - a).distance + 2 * ctx.l(sobra);
    final double altura = ctx.l(espessura);

    canvas.save();
    canvas.translate(meio.dx, meio.dy);
    canvas.rotate(math.atan2(b.dy - a.dy, b.dx - a.dx));
    canvas.scale(0.6 + 0.4 * presenca);

    // A pílula de fora: vidro claro, um pouco mais escuro embaixo.
    final Rect caixa = Rect.fromCenter(
      center: Offset.zero,
      width: comprimento,
      height: altura,
    );
    final Path pilula = Path()
      ..addRRect(RRect.fromRectAndRadius(caixa, Radius.circular(altura / 2)));
    ctx.contornar(
      canvas,
      pilula,
      ctx.degrade(
        caixa,
        ctx.cores.visor,
        Color.lerp(ctx.cores.visor, ctx.cores.corpo, 0.22)!,
        de: Alignment.topCenter,
        ate: Alignment.bottomCenter,
      ),
      fator: 0.75,
    );

    // O trilho, por dentro, e o trecho que corre nele.
    final double folga = ctx.l(folgaDoTrilho);
    final Rect trilho = caixa.deflate(folga);
    final RRect trilhoArredondado = RRect.fromRectAndRadius(
      trilho,
      Radius.circular(trilho.height / 2),
    );
    final double largura = trilho.width * fracaoDoTrecho;
    final double? ciclo = ctx.cicloDaBarra;
    final double inicio = ciclo == null
        ? trilho.left + (trilho.width - largura) / 2
        : trilho.left -
              largura +
              ValoresDaPose.suavizar(ciclo.clamp(0.0, 1.0)) *
                  (trilho.width + largura);
    final Rect trecho = Rect.fromLTWH(
      inicio,
      trilho.top,
      largura,
      trilho.height,
    );
    canvas.save();
    canvas.clipRRect(trilhoArredondado);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trecho, Radius.circular(trilho.height / 2)),
      ctx.degrade(
        trecho,
        ctx.cores.corpoLuz,
        ctx.cores.corpo,
        de: Alignment.topCenter,
        ate: Alignment.bottomCenter,
      ),
    );
    canvas.restore();

    if (ctx.detalhada) {
      // O reflexo de vidro na borda de cima, e a luz de contorno embaixo.
      canvas.drawLine(
        Offset(caixa.left + altura * 0.7, caixa.top + altura * 0.22),
        Offset(caixa.left + caixa.width * 0.32, caixa.top + altura * 0.22),
        ctx.traco(ctx.cores.brilho.withValues(alpha: 0.8), ctx.l(0.01)),
      );
      ctx.luzNaBorda(canvas, pilula, caixa, espessura: 0.022, forca: 0.7);
    }
    canvas.restore();
  }
}
