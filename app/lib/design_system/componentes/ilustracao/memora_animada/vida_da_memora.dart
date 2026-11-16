import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

import 'poses.dart';

/// Quanto cada expressão se mexe **além de respirar** (feature 013, T083,
/// FR-003a).
///
/// Uma Memora que só respira parece uma foto. Cada pose ganha movimentos
/// próprios, pequenos e lentos, que não competem com o texto da tela: olhar em
/// volta, balançar a antena, inclinar a cabeça de leve, ajeitar o corpo. Os
/// números são **amplitudes** (0 a 1, quanto de cada movimento aquela pose
/// faz), e não pixels.
///
/// A Memora preocupada olha de um lado para o outro, atenta; a que comemora
/// balança a antena sem parar; a que pensa deixa os olhos passearem para
/// cima. É isso que torna cada expressão **própria**, e não a mesma
/// animação em todas.
@immutable
class VidaDaPose {
  /// Quanto os olhos e a cabeça passeiam (0 a 1).
  final double olhar;

  /// Quanto a cabeça se inclina de um lado e de outro (radianos de pico).
  final double cabeca;

  /// Quanto a antena balança (0 a 1).
  final double antena;

  /// Quanto o corpo se ajeita (0 a 1).
  final double ajeita;

  /// A rapidez dos movimentos: múltiplo inteiro da volta de 12 s, para o ciclo
  /// emendar sem salto (1 é o mais calmo).
  final int ritmo;

  /// Cria a vida de uma pose.
  const VidaDaPose({
    required this.olhar,
    required this.cabeca,
    required this.antena,
    required this.ajeita,
    required this.ritmo,
  });

  /// A vida de [pose].
  static VidaDaPose de(PoseDaMemora pose) {
    switch (pose) {
      case PoseDaMemora.neutra:
        return const VidaDaPose(
          olhar: 0.9,
          cabeca: 0.02,
          antena: 0.6,
          ajeita: 0.5,
          ritmo: 1,
        );
      case PoseDaMemora.falando:
        return const VidaDaPose(
          olhar: 0.3,
          cabeca: 0.035,
          antena: 0.5,
          ajeita: 0.3,
          ritmo: 2,
        );
      case PoseDaMemora.pensando:
        return const VidaDaPose(
          olhar: 0.55,
          cabeca: 0.025,
          antena: 0.4,
          ajeita: 0.2,
          ritmo: 1,
        );
      case PoseDaMemora.comemorando:
        return const VidaDaPose(
          olhar: 0.3,
          cabeca: 0.04,
          antena: 1,
          ajeita: 0.8,
          ritmo: 3,
        );
      case PoseDaMemora.preocupada:
        return const VidaDaPose(
          olhar: 0.8,
          cabeca: 0.015,
          antena: 0.3,
          ajeita: 0.3,
          ritmo: 2,
        );
      case PoseDaMemora.acenando:
        return const VidaDaPose(
          olhar: 0.4,
          cabeca: 0.035,
          antena: 0.7,
          ajeita: 0.4,
          ritmo: 1,
        );
      case PoseDaMemora.dica:
        return const VidaDaPose(
          olhar: 0.35,
          cabeca: 0.03,
          antena: 0.5,
          ajeita: 0.3,
          ritmo: 1,
        );
      case PoseDaMemora.mini:
        return const VidaDaPose(
          olhar: 0.9,
          cabeca: 0.035,
          antena: 0.8,
          ajeita: 0,
          ritmo: 1,
        );
    }
  }
}

/// Os movimentos de vida de uma pose num instante: somam-se à pose parada.
@immutable
class VidaNoInstante {
  /// Quanto somar a `olharX` da pose.
  final double olharX;

  /// Quanto somar a `olharY` da pose.
  final double olharY;

  /// Quanto somar à inclinação da cabeça (radianos).
  final double cabeca;

  /// O balanço da antena, de -1 a 1.
  final double antena;

  /// O ajeitar do corpo, de 0 a 1.
  final double ajeita;

  /// O giro da cabeça, de -1 a 1.
  final double giro;

  /// Cria os movimentos de um instante.
  const VidaNoInstante({
    required this.olharX,
    required this.olharY,
    required this.cabeca,
    required this.antena,
    required this.ajeita,
    required this.giro,
  });

  /// Sem nenhum movimento.
  static const VidaNoInstante parada = VidaNoInstante(
    olharX: 0,
    olharY: 0,
    cabeca: 0,
    antena: 0,
    ajeita: 0,
    giro: 0,
  );

  /// Segundos que o ciclo de vida leva para emendar.
  static const double cicloEmSegundos = 12;

  /// Os movimentos de [pose] em [segundos] (módulo o ciclo de 12 s).
  ///
  /// [intensidade] 1 é a Memora comum; a anfitriã usa mais.
  static VidaNoInstante calcular(
    PoseDaMemora pose,
    double segundos, {
    double intensidade = 1,
  }) {
    final VidaDaPose v = VidaDaPose.de(pose);
    final double t = segundos % cicloEmSegundos;
    const double w = 2 * math.pi / cicloEmSegundos;
    final int k = v.ritmo;

    // Olhar em volta: duas ondas lentas que não se alinham, para o olhar não
    // andar sempre pelo mesmo caminho.
    final double ox =
        0.6 * math.sin(w * t * k + 0.6) + 0.4 * math.sin(w * t * (k + 2) + 2.1);
    final double oy = math.sin(w * t * (k + 1) + 4.0);

    // A cabeça acompanha o olhar, e ainda balança um pouco por conta própria.
    final double cab =
        0.7 * math.sin(w * t * (k + 1) + 1.0) + 0.3 * math.sin(w * t * 3 + 2.5);

    // A antena balança em rajadas: um tremor rápido que vai e passa.
    final double rajada = math
        .pow(math.max(0.0, math.sin(w * t * 2 + 0.3)), 2)
        .toDouble();
    final double antena = math.sin(w * t * 12) * rajada;

    // O ajeitar acontece uma vez por ciclo, num momento que depende da pose.
    final double centro = (7.6 + k * 0.9) % cicloEmSegundos;
    final double ajeita = _janela(t, centro, 0.9);

    return VidaNoInstante(
      olharX: v.olhar * 1.6 * ox * intensidade,
      olharY: v.olhar * 0.9 * oy * intensidade,
      cabeca: v.cabeca * cab * intensidade,
      antena: (v.antena * antena * intensidade).clamp(-1.0, 1.0),
      ajeita: (v.ajeita * ajeita * intensidade).clamp(0.0, 1.0),
      giro: (v.olhar * 0.35 * ox * intensidade).clamp(-1.0, 1.0),
    );
  }

  /// Uma janela suave de 0 a 1 e de volta a 0, centrada em [centro], com
  /// [meia] segundos de cada lado, que emenda na volta do ciclo.
  static double _janela(double t, double centro, double meia) {
    double d = (t - centro).abs();
    if (d > cicloEmSegundos / 2) d = cicloEmSegundos - d;
    if (d >= meia) return 0;
    return 0.5 + 0.5 * math.cos(math.pi * d / meia);
  }

  /// O quanto a pose se mexe, de 0 a 1 — a soma dos módulos de tudo o que
  /// mexe. Para os testes: zero quer dizer "parada".
  double get tamanho =>
      olharX.abs() +
      olharY.abs() +
      cabeca.abs() +
      antena.abs() +
      ajeita.abs() +
      giro.abs();
}

/// O pulo da Memora e como o corpo estica e encolhe nele (T087): encolhe para
/// pegar impulso, estica no ar, encolhe de novo ao pousar e se acomoda.
abstract final class PuloDaMemora {
  /// A altura do pulo no ponto [p] (0 a 1) do gesto, de 0 a 1.
  static double altura(double p) {
    final double t = p.clamp(0.0, 1.0);
    if (t < 0.18 || t > 0.70) return 0;
    return math.sin(math.pi * (t - 0.18) / 0.52);
  }

  /// O estica-e-encolhe no ponto [p] do gesto: de -1 (encolhido) a 1
  /// (esticado).
  static double esticar(double p) {
    final double t = p.clamp(0.0, 1.0);
    if (t < 0.18) return -math.sin(math.pi * t / 0.18);
    if (t < 0.70) {
      // No ar: esticada na subida e na descida, relaxada no topo, e com as
      // pontas amaciadas para não dar salto na passagem do encolher.
      final double u = (t - 0.18) / 0.52;
      final double rampa = math.min(1.0, math.min(u / 0.15, (1 - u) / 0.15));
      return 0.8 * math.cos(math.pi * u).abs() * rampa;
    }
    if (t < 0.88) return -0.65 * math.sin(math.pi * (t - 0.70) / 0.18);
    // Acomoda: uma oscilação pequena que morre.
    return 0.15 * math.sin(math.pi * (t - 0.88) / 0.12);
  }
}
