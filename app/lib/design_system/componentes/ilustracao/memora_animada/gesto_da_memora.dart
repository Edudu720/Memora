/// Uma animação curta e única da Memora, disparada por um evento
/// (feature 013, data-model.md).
///
/// Com "reduzir movimento" nenhum gesto acontece: a Memora fica na pose
/// parada da expressão.
enum GestoDaMemora {
  /// Acena com a mão direita. Dispara ao toque (alternado com a piscada).
  aceno,

  /// Fecha e abre os olhos. Dispara ao toque (alternado com o aceno).
  piscada,

  /// Salta com os braços para cima, uma vez. Fim de um passo a passo.
  comemoracao,

  /// Um pulinho leve, sem mudar de expressão: encolhe, salta esticada e pousa
  /// (feature 013, T087). É o gesto da anfitriã; a comemoração é o grande.
  pulinho,
}
