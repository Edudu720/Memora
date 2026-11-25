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
  /// O lado do quadrado da Memora, em dp. O mesmo dos desenhos do Android
  /// (`res/drawable*/memora_abertura*.xml`, T094), que têm a Memora de 160 dp
  /// no centro do quadro. Eles são gerados do primeiro quadro da abertura por
  /// `test/features/abertura/abertura_nativa_test.dart`: mudou este número,
  /// gere de novo.
  static const double tamanhoDaMemora = 160;

  /// O lado da Memora na tela de erro. Menor: ali ela acompanha o texto, e não
  /// é a única coisa na tela.
  static const double tamanhoNoErro = 120;

  /// A folga entre a Memora e a frase de "quase pronta".
  static const double folgaDaFrase = 16;

  /// Quanto o carregamento pode levar antes de aparecer a frase "Estou quase
  /// pronta." (FR-038).
  static const Duration limiteDaDemora = Duration(seconds: 4);

  /// Uma passada da barra de carregamento que a Memora segura (T092): o
  /// trecho entra pela esquerda e sai pela direita, e a passada seguinte
  /// emenda nesta.
  ///
  /// É o "gesto" da abertura: ela sai quando carregou **e** a passada em curso
  /// terminou, nunca mais que uma passada depois (FR-038). Calma de
  /// propósito, no ritmo de uma barra indeterminada comum: não acelera nem
  /// pisca para disfarçar a espera.
  static const Duration passadaDaBarra = Duration(milliseconds: 1500);

  /// De onde a **primeira** passada parte (T094): do meio da passada, com o
  /// trecho no centro da barra, que é onde o desenho do Android
  /// (`memora_abertura*.xml`) o deixou parado. Assim a barra continua de onde
  /// a abertura do sistema parou, em vez de o trecho sumir e reentrar pela
  /// esquerda. A passada é suavizada nas pontas (`ValoresDaPose.suavizar`,
  /// simétrica): na metade do tempo o trecho está na metade do caminho.
  ///
  /// A primeira passada dura, por isso, metade de [passadaDaBarra]; as
  /// seguintes são inteiras.
  static const double inicioDaPrimeiraPassada = 0.5;
}
