/// Escala de espaçamento do Memora, com base 4.
///
/// Nenhum valor fora desta escala deve aparecer no aplicativo (FR-007).
/// Espaçamento avulso é o começo da inconsistência visual.
abstract final class MemoraEspacamento {
  /// 4 — separação mínima entre elementos muito relacionados.
  static const double xs = 4;

  /// 8 — separação mínima entre alvos de toque.
  static const double sm = 8;

  /// 12
  static const double md = 12;

  /// 16 — respiro padrão interno de componente.
  static const double lg = 16;

  /// 24 — margem lateral padrão de tela.
  static const double xl = 24;

  /// 32 — separação entre seções.
  static const double xxl = 32;

  /// 48 — separação forte, usada para isolar ação destrutiva.
  static const double xxxl = 48;

  /// 64
  static const double xxxxl = 64;

  /// Todos os valores, usados pelos testes de conformidade.
  static const List<double> todos = <double>[xs, sm, md, lg, xl, xxl, xxxl, xxxxl];
}
