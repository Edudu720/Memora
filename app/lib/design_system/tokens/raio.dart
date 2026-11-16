/// Raios de canto do Memora.
abstract final class MemoraRaio {
  /// 12 — padrão para campos e superfícies pequenas.
  static const double padrao = 12;

  /// 24 — cartões e folhas.
  static const double cartao = 24;

  /// 24 — cartões e painéis herói em destaque.
  static const double cartaoDestaque = 24;

  /// 20 — atalhos médios em grade 2x2 e sub-blocos compactos.
  static const double cartaoMedio = 20;

  /// 14 — badges quadrados arredondados em atalhos e listas.
  static const double badge = 14;

  /// 999 — pílula. Preserva a forma dos botões do protótipo.
  static const double pilula = 999;

  /// 40 — a porta (feature 004): pílula quando ela tem uma linha só, e
  /// cantos redondos quando cresce.
  static const double porta = 40;

  /// 18 — balão de fala curvo.
  static const double balao = 18;

  /// 6 — ponta de ancoragem do balão de fala.
  static const double balaoPonta = 6;
}
