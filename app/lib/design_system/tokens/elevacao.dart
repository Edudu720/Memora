/// Elevações do Memora.
///
/// Sombra **nunca** é o sinal principal de que algo é clicável: ela é
/// praticamente invisível para quem tem baixa visão. Forma e cor carregam o
/// sinal; a elevação apenas reforça (research.md, R5).
abstract final class MemoraElevacao {
  /// Sem elevação.
  static const double plana = 0;

  /// Cartões e agrupamentos.
  static const double cartao = 1;

  /// Elementos flutuantes sobre o conteúdo.
  static const double flutuante = 3;

  /// Diálogos e folhas modais.
  static const double modal = 6;
}
