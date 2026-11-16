/// Para onde a tela nova vem (feature 013, FR-009 e data-model.md).
///
/// A direção conta à pessoa onde ela está: avançar vem da direita, voltar vem
/// da esquerda, e o que sobe por cima (folha, diálogo) não move o que está
/// atrás.
enum DirecaoDaTransicao {
  /// Entra pela direita; a tela que sai vai à esquerda, mais devagar.
  avancar,

  /// Entra pela esquerda; a tela que sai vai à direita.
  voltar,

  /// Sobe de baixo (folha) ou aparece no centro (diálogo). A de trás não se
  /// move.
  sobrepor,

  /// Troca de destino da barra inferior: entra do lado da posição relativa.
  destino,
}
