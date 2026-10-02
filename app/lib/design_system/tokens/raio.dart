/// Raios de canto do Memora.
abstract final class MemoraRaio {
  /// 12 — padrão para campos e superfícies pequenas.
  static const double padrao = 12;

  /// 24 — cartões e folhas.
  static const double cartao = 24;

  /// 999 — pílula. Preserva a forma dos botões do protótipo.
  static const double pilula = 999;

  /// 40 — a porta (feature 004): pílula quando ela tem uma linha só, e
  /// cantos redondos quando cresce.
  ///
  /// Não é [pilula] porque o Flutter reduz o raio de um retângulo à metade do
  /// menor lado: uma porta que fica alta com o texto a 150% ou 200% virava
  /// quase um círculo, e os cantos do nome e da explicação saíam do
  /// preenchimento — na porta principal, texto branco sobre o fundo claro,
  /// invisível (achado da revisão da #38). Com 40, a 100% a porta, de ~90 dp,
  /// continua parecendo a pílula do wireframe, e o texto nunca encosta na curva.
  static const double porta = 40;
}
