import 'package:flutter/painting.dart';

import '../../../../tokens/cores_da_memora.dart';
import '../poses.dart';

/// Tudo o que uma camada precisa para se pintar neste quadro (feature 013).
///
/// As camadas desenham em **coordenadas do desenho**: 0 a 1 do lado do
/// quadrado, com a origem no canto de cima à esquerda. [p] e [l] convertem
/// para pixels, e é por isso que a Memora é a mesma em 32 ou em 240 dp.
class ContextoDePintura {
  /// O lado do quadrado, em pixels.
  final double lado;

  /// As cores do tema e da paleta ativos.
  final CoresDaMemora cores;

  /// A pose deste quadro, já interpolada.
  final ValoresDaPose pose;

  /// A respiração, de -1 a 1.
  final double respira;

  /// A fala: quanto a boca abre por causa da voz, de 0 a 1.
  final double fala;

  /// O quanto os olhos estão fechados por uma piscada, de 0 a 1.
  final double piscar;

  /// A oscilação da mão que acena, de -1 a 1.
  final double aceno;

  /// A altura do salto, de 0 a 1.
  final double pulo;

  /// O balanço do corpo, de -1 a 1, que alimenta a paralaxe.
  final double balanco;

  /// A chegada, de 0 (acabou de aparecer) a 1 (já está inteira).
  final double entrada;

  /// O balanço da antena, de -1 a 1 (feature 013, T083): a bolinha balança de
  /// um lado para o outro, atrasada em relação à cabeça.
  final double antena;

  /// O "ajeitar" do corpo, de 0 a 1 (T083): um encolher de ombros curto, em
  /// que tronco e cabeça sobem um fio e voltam.
  final double ajeita;

  /// O giro da cabeça em torno do pescoço, de -1 (esquerda) a 1 (direita)
  /// (T083, T087): a cabeça se estreita um pouco e o rosto **desliza dentro
  /// do visor**, o que dá a sensação de volume.
  final double giro;

  /// A flutuação da anfitriã, de 0 a 1 (T088): sobe um pouco do chão e a
  /// sombra clareia e encolhe.
  final double flutua;

  /// O estica-e-encolhe do corpo no pulo, de -1 (encolhido) a 1 (esticado)
  /// (T087).
  final double esticar;

  /// Se este quadro é o da anfitriã, com o acabamento de maior detalhe:
  /// brilho especular, luz de contorno e sombra de contato (T087, FR-048).
  final bool detalhada;

  /// Onde está o trecho que corre dentro da barra de carregamento, de 0 (entra
  /// pela esquerda) a 1 (saiu pela direita): uma volta inteira é uma
  /// passada (T092). **Nulo é a barra parada**, com o trecho no meio, como
  /// fica com "reduzir movimento".
  final double? cicloDaBarra;

  /// Cria o contexto de um quadro.
  const ContextoDePintura({
    required this.lado,
    required this.cores,
    required this.pose,
    this.respira = 0,
    this.fala = 0,
    this.piscar = 0,
    this.aceno = 0,
    this.pulo = 0,
    this.balanco = 0,
    this.entrada = 1,
    this.antena = 0,
    this.ajeita = 0,
    this.giro = 0,
    this.flutua = 0,
    this.esticar = 0,
    this.detalhada = false,
    this.cicloDaBarra,
  });

  /// Um ponto do desenho, em pixels.
  Offset p(double x, double y) => Offset(x * lado, y * lado);

  /// Um ponto do desenho dado por um [Offset] de proporções.
  Offset pp(Offset o) => Offset(o.dx * lado, o.dy * lado);

  /// Um retângulo do desenho, em pixels.
  Rect rect(Rect o) =>
      Rect.fromLTRB(o.left * lado, o.top * lado, o.right * lado, o.bottom * lado);

  /// Um retângulo arredondado do desenho, em pixels.
  RRect rrect(Rect o, double raio) =>
      RRect.fromRectAndRadius(rect(o), Radius.circular(raio * lado));

  /// Uma medida do desenho, em pixels.
  double l(double v) => v * lado;

  /// A espessura do contorno (metade fica escondida sob o preenchimento).
  double get contorno => lado * 0.05;

  /// A espessura do aro de fora, quando ele existe.
  double get aro => lado * 0.022;

  /// Se o aro é uma linha à parte. No tema claro ele é o próprio contorno.
  bool get temAro => cores.aro != cores.contorno;

  /// O quanto uma camada em [profundidade] (0 a 1,5) anda com o balanço.
  double deslocamento(double profundidade) =>
      balanco * profundidade * lado * 0.012;

  /// Um traço arredondado com a cor e a espessura dadas.
  Paint traco(Color cor, double espessura) => Paint()
    ..color = cor
    ..style = PaintingStyle.stroke
    ..strokeWidth = espessura
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Um preenchimento liso.
  Paint cheio(Color cor) => Paint()
    ..color = cor
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  /// Um degradê linear de [a] para [b] dentro de [caixa].
  Paint degrade(Rect caixa, Color a, Color b,
      {Alignment de = Alignment.topLeft, Alignment ate = Alignment.bottomRight}) {
    return Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..shader = LinearGradient(begin: de, end: ate, colors: <Color>[a, b])
          .createShader(caixa);
  }

  /// Um fio de luz na borda de [forma] do lado de baixo e da direita, **para
  /// dentro** do contorno: é a "luz de contorno" da anfitriã (T087). [caixa] é
  /// a caixa do degradê, que vai de transparente (em cima, à esquerda) à cor
  /// da luz (embaixo, à direita).
  void luzNaBorda(Canvas canvas, Path forma, Rect caixa,
      {double espessura = 0.03, double forca = 1}) {
    canvas.save();
    canvas.clipPath(forma);
    final Color luz = cores.luzDeContorno;
    canvas.drawPath(
      forma,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = l(espessura)
        ..isAntiAlias = true
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            luz.withValues(alpha: 0),
            luz.withValues(alpha: 0),
            luz.withValues(alpha: 0.85 * forca),
          ],
          stops: const <double>[0, 0.5, 1],
        ).createShader(caixa),
    );
    canvas.restore();
  }

  /// Pinta [forma] com contorno (e aro, se houver) por baixo e o
  /// [preenchimento] por cima: o traço fica todo para fora da forma.
  void contornar(Canvas canvas, Path forma, Paint preenchimento,
      {double fator = 1}) {
    final double espessura = contorno * fator;
    if (temAro) {
      canvas.drawPath(
          forma, traco(cores.aro, espessura + 2 * aro * fator));
    }
    canvas.drawPath(forma, traco(cores.contorno, espessura));
    canvas.drawPath(forma, preenchimento);
  }
}

/// Uma camada do desenho da Memora (sombra, corpo, cabeça, visor...). Cada
/// camada vive no próprio arquivo e só sabe se pintar.
abstract class CamadaDaMemora {
  /// Cria a camada.
  const CamadaDaMemora();

  /// Pinta a camada no [canvas].
  void pintar(Canvas canvas, ContextoDePintura ctx);
}
