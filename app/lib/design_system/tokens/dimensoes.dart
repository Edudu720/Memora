/// Dimensões de acessibilidade do Memora.
///
/// Estes valores não são preferência estética — são requisitos verificáveis,
/// medidos em testes automatizados.
abstract final class MemoraDimensoes {
  /// 48 dp — mínimo da WCAG 2.2 e das diretrizes Android (FR-009).
  ///
  /// Os botões SIM/NÃO do protótipo mediam 24 px de altura, exatamente
  /// metade deste valor (research.md, R2).
  static const double alvoMinimo = 48;

  /// 56 dp — usado em pontos de decisão, onde um toque acidental tem
  /// consequência. Acima do mínimo por causa da menor precisão motora do
  /// público-alvo (research.md, R3).
  static const double alvoDecisao = 56;

  /// 8 dp — separação mínima entre dois alvos de toque.
  static const double separacaoAlvo = 8;

  /// Teto da escala de texto combinada entre sistema e aplicativo.
  ///
  /// Sem teto, o layout quebra em casos extremos e a pessoa fica sem saída
  /// (research.md, R7).
  static const double escalaTextoMax = 2.0;

  /// Piso da escala de texto.
  static const double escalaTextoMin = 1.0;
}
