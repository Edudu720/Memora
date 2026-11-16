/// As medidas e os tempos da abertura do aplicativo (feature 013, T036; FR-036
/// a FR-039).
///
/// ## Por que existe um arquivo só para isto
///
/// A Memora da abertura precisa estar **no mesmo lugar e do mesmo tamanho**
/// em dois mundos que não se falam: o desenho do Android (recursos XML, antes
/// de o Flutter existir) e o `MemoraAnimada` (depois). Os números nascem aqui
/// e os recursos em `android/app/src/main/res/` os repetem — mudar um sem o
/// outro faz a Memora "pular" na passagem de um para o outro.
abstract final class MemoraAbertura {
  /// O lado do quadrado da Memora, em dp. O mesmo de
  /// `res/drawable-v21/memora_abertura.xml`, que desenha a Memora num quadro
  /// de 160 dp, centralizado na janela.
  static const double tamanhoDaMemora = 160;

  /// O lado da Memora na tela de erro. Menor: ali ela acompanha o texto, e não
  /// é a única coisa na tela.
  static const double tamanhoNoErro = 120;

  /// A folga entre a Memora e a frase de "quase pronta".
  static const double folgaDaFrase = 16;

  /// Quanto o carregamento pode levar antes de aparecer a frase "Estou quase
  /// pronta." (FR-038).
  static const Duration limiteDaDemora = Duration(seconds: 4);

  /// O descanso entre um aceno e o seguinte, quando o carregamento demora.
  ///
  /// Calmo de propósito: a Memora não acelera nem pisca para disfarçar a
  /// espera. O aceno seguinte começa depois deste intervalo.
  static const Duration pausaEntreAcenos = Duration(milliseconds: 800);
}
