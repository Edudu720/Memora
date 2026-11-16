import 'dart:math' as math;
import 'dart:ui' show Offset, lerpDouble;

import 'package:flutter/foundation.dart' show immutable;

/// As poses da Memora (feature 010, FR-002 e data-model.md).
///
/// É um enum **próprio** do desenho, e não o `ExpressaoDaMemora` da
/// `MemoraPersonagem`: esse enum só tem quatro valores e é reescrito pela
/// feature do redesenho das telas (que acrescenta `dica` e `mini`). Quando as
/// duas se encontrarem, a `MemoraPersonagem` mapeia cada expressão para uma
/// destas poses (Fase B).
enum PoseDaMemora {
  /// Repouso: braços baixos, olhos abertos, "respirando".
  neutra,

  /// Falando: boca aberta e um braço que gesticula.
  falando,

  /// Pensando: cabeça inclinada e a mão no queixo.
  pensando,

  /// Comemorando: braços para cima e olhos fechados de felicidade.
  comemorando,

  /// Preocupada: sobrancelha franzida e o escudo à frente.
  preocupada,

  /// Acenando: o braço direito levantado.
  acenando,

  /// Dica: um livro na mão e o dedo levantado.
  dica,

  /// Só a cabeça, para lugares pequenos.
  mini,
}

/// Onde ficam o cotovelo e a mão de um braço, em coordenadas do desenho
/// (0 a 1, com a origem no canto de cima à esquerda).
@immutable
class PosicaoDoBraco {
  /// O ponto por onde o braço se curva.
  final Offset cotovelo;

  /// Onde termina o braço, no centro da mão.
  final Offset mao;

  /// Cria a posição de um braço.
  const PosicaoDoBraco(this.cotovelo, this.mao);

  /// Interpola entre duas posições.
  static PosicaoDoBraco lerp(PosicaoDoBraco a, PosicaoDoBraco b, double t) =>
      PosicaoDoBraco(
        Offset.lerp(a.cotovelo, b.cotovelo, t)!,
        Offset.lerp(a.mao, b.mao, t)!,
      );
}

/// Os valores-alvo de uma pose: tudo o que o desenho precisa para pintar uma
/// expressão parada. Trocar de expressão é interpolar entre dois destes.
///
/// Todos os números são **proporções do desenho** (0 a 1 do lado do
/// quadrado), nunca pixels: a Memora vale o mesmo em 32 ou em 240 dp.
@immutable
class ValoresDaPose {
  /// Inclinação da cabeça, em radianos (positivo gira para a direita).
  final double inclinacaoDaCabeca;

  /// Quanto os olhos estão abertos (0 fechados, 1 abertos).
  final double olhoAbertura;

  /// Quanto os olhos são o "arco feliz" (0 ovais, 1 arcos).
  final double olhoFeliz;

  /// Para onde ela olha, de -1 (esquerda) a 1 (direita).
  final double olharX;

  /// Para onde ela olha, de -1 (cima) a 1 (baixo).
  final double olharY;

  /// A curva da boca, de -1 (triste) a 1 (sorriso aberto).
  final double sorriso;

  /// Quanto a boca está aberta (0 fechada, 1 bem aberta).
  final double bocaAbertura;

  /// Se a boca aparece (a versão mini não tem boca).
  final double bocaVisivel;

  /// Quanto a sobrancelha está franzida.
  final double sobrancelha;

  /// Quanto as bochechas aparecem.
  final double bochecha;

  /// O braço esquerdo (do lado esquerdo da imagem).
  final PosicaoDoBraco bracoEsquerdo;

  /// O braço direito.
  final PosicaoDoBraco bracoDireito;

  /// Quanto o dedo indicador está levantado na mão direita.
  final double dedo;

  /// O escudo (0 ausente, 1 inteiro).
  final double escudo;

  /// O livro (0 ausente, 1 inteiro).
  final double livro;

  /// Quanto o corpo aparece (0 só a cabeça).
  final double corpo;

  /// Altura do salto, de 0 a 1.
  final double salto;

  /// Cria os valores de uma pose.
  const ValoresDaPose({
    required this.inclinacaoDaCabeca,
    required this.olhoAbertura,
    required this.olhoFeliz,
    required this.olharX,
    required this.olharY,
    required this.sorriso,
    required this.bocaAbertura,
    required this.bocaVisivel,
    required this.sobrancelha,
    required this.bochecha,
    required this.bracoEsquerdo,
    required this.bracoDireito,
    required this.dedo,
    required this.escudo,
    required this.livro,
    required this.corpo,
    required this.salto,
  });

  // ---- os braços que as poses compartilham ----
  static const PosicaoDoBraco _esquerdoBaixo = PosicaoDoBraco(
    Offset(0.245, 0.80),
    Offset(0.255, 0.915),
  );
  static const PosicaoDoBraco _direitoBaixo = PosicaoDoBraco(
    Offset(0.755, 0.80),
    Offset(0.745, 0.915),
  );
  static const PosicaoDoBraco _esquerdoAlto = PosicaoDoBraco(
    Offset(0.15, 0.66),
    Offset(0.105, 0.40),
  );
  static const PosicaoDoBraco _direitoAlto = PosicaoDoBraco(
    Offset(0.85, 0.66),
    Offset(0.895, 0.40),
  );
  static const PosicaoDoBraco _direitoAcenando = PosicaoDoBraco(
    Offset(0.855, 0.72),
    Offset(0.885, 0.49),
  );

  /// Repouso.
  static const ValoresDaPose _neutra = ValoresDaPose(
    inclinacaoDaCabeca: 0,
    olhoAbertura: 1,
    olhoFeliz: 0,
    olharX: 0,
    olharY: 0,
    sorriso: 0.6,
    bocaAbertura: 0,
    bocaVisivel: 1,
    sobrancelha: 0,
    bochecha: 1,
    bracoEsquerdo: _esquerdoBaixo,
    bracoDireito: _direitoBaixo,
    dedo: 0,
    escudo: 0,
    livro: 0,
    corpo: 1,
    salto: 0,
  );

  /// Os valores de [pose].
  static ValoresDaPose de(PoseDaMemora pose) {
    switch (pose) {
      case PoseDaMemora.neutra:
        return _neutra;
      case PoseDaMemora.falando:
        return _neutra.copiar(
          inclinacaoDaCabeca: 0.03,
          sorriso: 0.5,
          bocaAbertura: 0.45,
          bracoDireito: const PosicaoDoBraco(
            Offset(0.86, 0.78),
            Offset(0.875, 0.665),
          ),
        );
      case PoseDaMemora.pensando:
        return _neutra.copiar(
          inclinacaoDaCabeca: -0.07,
          olharX: 0.7,
          olharY: -0.6,
          sorriso: 0.1,
          bochecha: 0.6,
          bracoDireito: const PosicaoDoBraco(
            Offset(0.755, 0.885),
            Offset(0.60, 0.625),
          ),
        );
      case PoseDaMemora.comemorando:
        return _neutra.copiar(
          olhoFeliz: 1,
          sorriso: 1,
          bocaAbertura: 0.8,
          bracoEsquerdo: _esquerdoAlto,
          bracoDireito: _direitoAlto,
        );
      case PoseDaMemora.preocupada:
        return _neutra.copiar(
          sorriso: -0.2,
          sobrancelha: 1,
          bochecha: 0.2,
          bracoDireito: const PosicaoDoBraco(
            Offset(0.80, 0.84),
            Offset(0.78, 0.86),
          ),
          escudo: 1,
        );
      case PoseDaMemora.acenando:
        return _neutra.copiar(
          inclinacaoDaCabeca: 0.04,
          sorriso: 0.85,
          bracoDireito: _direitoAcenando,
        );
      case PoseDaMemora.dica:
        return _neutra.copiar(
          inclinacaoDaCabeca: 0.03,
          sorriso: 0.9,
          bocaAbertura: 0.5,
          bracoEsquerdo: const PosicaoDoBraco(
            Offset(0.29, 0.885),
            Offset(0.355, 0.905),
          ),
          bracoDireito: const PosicaoDoBraco(
            Offset(0.845, 0.745),
            Offset(0.845, 0.56),
          ),
          dedo: 1,
          livro: 1,
        );
      case PoseDaMemora.mini:
        return _neutra.copiar(bocaVisivel: 0, bochecha: 0, corpo: 0);
    }
  }

  /// A mesma pose com alguns valores trocados.
  ValoresDaPose copiar({
    double? inclinacaoDaCabeca,
    double? olhoAbertura,
    double? olhoFeliz,
    double? olharX,
    double? olharY,
    double? sorriso,
    double? bocaAbertura,
    double? bocaVisivel,
    double? sobrancelha,
    double? bochecha,
    PosicaoDoBraco? bracoEsquerdo,
    PosicaoDoBraco? bracoDireito,
    double? dedo,
    double? escudo,
    double? livro,
    double? corpo,
    double? salto,
  }) {
    return ValoresDaPose(
      inclinacaoDaCabeca: inclinacaoDaCabeca ?? this.inclinacaoDaCabeca,
      olhoAbertura: olhoAbertura ?? this.olhoAbertura,
      olhoFeliz: olhoFeliz ?? this.olhoFeliz,
      olharX: olharX ?? this.olharX,
      olharY: olharY ?? this.olharY,
      sorriso: sorriso ?? this.sorriso,
      bocaAbertura: bocaAbertura ?? this.bocaAbertura,
      bocaVisivel: bocaVisivel ?? this.bocaVisivel,
      sobrancelha: sobrancelha ?? this.sobrancelha,
      bochecha: bochecha ?? this.bochecha,
      bracoEsquerdo: bracoEsquerdo ?? this.bracoEsquerdo,
      bracoDireito: bracoDireito ?? this.bracoDireito,
      dedo: dedo ?? this.dedo,
      escudo: escudo ?? this.escudo,
      livro: livro ?? this.livro,
      corpo: corpo ?? this.corpo,
      salto: salto ?? this.salto,
    );
  }

  /// Interpola entre duas poses; [t] de 0 (em [a]) a 1 (em [b]).
  static ValoresDaPose lerp(ValoresDaPose a, ValoresDaPose b, double t) {
    double n(double x, double y) => lerpDouble(x, y, t)!;
    return ValoresDaPose(
      inclinacaoDaCabeca: n(a.inclinacaoDaCabeca, b.inclinacaoDaCabeca),
      olhoAbertura: n(a.olhoAbertura, b.olhoAbertura),
      olhoFeliz: n(a.olhoFeliz, b.olhoFeliz),
      olharX: n(a.olharX, b.olharX),
      olharY: n(a.olharY, b.olharY),
      sorriso: n(a.sorriso, b.sorriso),
      bocaAbertura: n(a.bocaAbertura, b.bocaAbertura),
      bocaVisivel: n(a.bocaVisivel, b.bocaVisivel),
      sobrancelha: n(a.sobrancelha, b.sobrancelha),
      bochecha: n(a.bochecha, b.bochecha),
      bracoEsquerdo: PosicaoDoBraco.lerp(a.bracoEsquerdo, b.bracoEsquerdo, t),
      bracoDireito: PosicaoDoBraco.lerp(a.bracoDireito, b.bracoDireito, t),
      dedo: n(a.dedo, b.dedo),
      escudo: n(a.escudo, b.escudo),
      livro: n(a.livro, b.livro),
      corpo: n(a.corpo, b.corpo),
      salto: n(a.salto, b.salto),
    );
  }

  /// Uma curva suave para as trocas de pose (sai devagar, chega devagar).
  static double suavizar(double t) => t * t * (3 - 2 * t);

  /// O envelope de um gesto: sobe, fica e desce, de 0 a 1 e de volta a 0.
  static double envelope(double t) => math.sin(math.pi * t.clamp(0.0, 1.0));
}
