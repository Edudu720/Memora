import 'dart:ui' show Offset, Rect, Radius, RRect;

/// As medidas do desenho da Memora, em proporções do lado do quadrado.
///
/// São a **forma do personagem**, não valores de interface: ficam num lugar só
/// para que a cabeça, o visor e o rosto concordem entre si.
abstract final class GeometriaDaMemora {
  /// O centro da cabeça.
  static const Offset centroDaCabeca = Offset(0.5, 0.40);

  /// A cabeça: cantos bem arredondados.
  static const Rect cabeca = Rect.fromLTRB(0.20, 0.17, 0.80, 0.63);

  /// O raio dos cantos da cabeça.
  static const double raioDaCabeca = 0.17;

  /// A "tela" do rosto.
  static const Rect visor = Rect.fromLTRB(0.26, 0.22, 0.74, 0.57);

  /// O raio dos cantos do visor.
  static const double raioDoVisor = 0.11;

  /// O ponto em que a cabeça gira (o pescoço).
  static const Offset pescoco = Offset(0.5, 0.62);

  /// A bolinha da antena.
  static const Offset bolinha = Offset(0.5, 0.077);

  /// O raio da bolinha da antena.
  static const double raioDaBolinha = 0.037;

  /// O tronco.
  static const Rect tronco = Rect.fromLTRB(0.31, 0.60, 0.69, 0.965);

  /// Os ombros.
  static const Offset ombroEsquerdo = Offset(0.33, 0.715);

  /// O ombro direito.
  static const Offset ombroDireito = Offset(0.67, 0.715);

  /// A espessura do braço no ombro.
  static const double bracoOmbro = 0.09;

  /// A espessura do braço no punho: ele afina até a mão.
  static const double bracoPunho = 0.058;

  /// O raio da mão.
  static const double raioDaMao = 0.054;

  /// O painel do peito.
  static const Rect painel = Rect.fromLTRB(0.40, 0.745, 0.60, 0.855);

  /// A cabeça como retângulo arredondado.
  static RRect get cabecaArredondada =>
      RRect.fromRectAndRadius(cabeca, const Radius.circular(raioDaCabeca));

  /// O visor como retângulo arredondado.
  static RRect get visorArredondado =>
      RRect.fromRectAndRadius(visor, const Radius.circular(raioDoVisor));
}
