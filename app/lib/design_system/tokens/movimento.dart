/// Durações de animação do Memora.
///
/// Toda animação é suprimida quando a pessoa ativa "reduzir movimento" no
/// sistema (FR-027), e nenhuma informação depende de animação para ser
/// compreendida (FR-028).
abstract final class MemoraMovimento {
  /// Transições pequenas, como mudança de estado de botão.
  static const Duration rapido = Duration(milliseconds: 120);

  /// Padrão para a maioria das transições.
  static const Duration padrao = Duration(milliseconds: 200);

  /// Transições amplas, como abertura de folha inferior.
  static const Duration lento = Duration(milliseconds: 320);

  /// Quanto uma superfície tocável encolhe enquanto o dedo está nela.
  ///
  /// É o segundo sinal do estado "pressionado", além da camada de cor do
  /// toque (FR-043 da feature 004). Pequeno de propósito: o bastante para ser
  /// visto, pouco para parecer que a tela pulou. Com "reduzir movimento" a
  /// mudança acontece sem transição, e o sinal continua lá.
  static const double escalaPressionado = 0.97;

  /// Duração efetiva, considerando a preferência de redução de movimento.
  static Duration efetiva(Duration desejada, {required bool reduzirMovimento}) {
    return reduzirMovimento ? Duration.zero : desejada;
  }
}
