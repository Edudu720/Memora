import 'package:flutter/animation.dart';

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

  /// A Memora acena (FR-005a, feature 013): um gesto curto, uma vez só.
  static const Duration aceno = Duration(milliseconds: 1200);

  /// A Memora pisca ao toque (FR-005a).
  static const Duration piscada = Duration(milliseconds: 300);

  /// A Memora comemora o fim de um passo a passo (FR-003).
  static const Duration comemoracao = Duration(milliseconds: 1000);

  /// Quanto leva para a Memora ir de uma expressão a outra.
  static const Duration trocaDeExpressao = Duration(milliseconds: 360);

  /// Um ciclo completo de "respiração" em repouso. Lento de propósito.
  static const Duration respiracao = Duration(seconds: 4);

  /// Uma abertura e fechamento de boca enquanto a Memora fala.
  static const Duration silaba = Duration(milliseconds: 600);

  /// Transição entre telas (SC-004: no máximo 500 ms).
  static const Duration transicaoDeTela = Duration(milliseconds: 400);

  /// A curva de toda troca de tela e de destino (feature 013, R2).
  ///
  /// Suave nas duas pontas: a tela começa e termina devagar, sem batida.
  static const Curve curvaDeTela = Curves.easeInOutCubic;

  /// Quanto a tela de trás anda enquanto a nova a cobre, em fração da largura
  /// (paralaxe, R2). Menos que a tela nova, para o olho ver que há um fundo.
  static const double paralaxeDaTelaDeTras = 0.3;

  /// A curva de quem surge por cima (diálogo e folha): chega depressa e
  /// assenta devagar (feature 013, R4).
  static const Curve curvaDeSobreposicao = Curves.easeOut;

  /// De que tamanho o diálogo parte ao surgir, em fração do final: 96%
  /// (feature 013, R4). Um aumento leve, que dá a ideia de chegar sem mover a
  /// tela de trás.
  static const double escalaDoDialogoAoSurgir = 0.96;

  /// O diálogo parado, no tamanho dele.
  static const double escalaDoDialogoEmRepouso = 1.0;

  /// Quanto uma superfície tocável encolhe enquanto o dedo está nela.
  ///
  /// É o segundo sinal do estado "pressionado", além da camada de cor do
  /// toque (FR-043 da feature 004). Pequeno de propósito: o bastante para ser
  /// visto, pouco para parecer que a tela pulou. Com "reduzir movimento" a
  /// mudança acontece sem transição, e o sinal continua lá.
  static const double escalaPressionado = 0.97;

  /// Quanto leva para a Memora "escrever" cada letra da resposta (FR-020b).
  ///
  /// Perto do ritmo de quem escreve devagar, mas ainda confortável de ler
  /// acompanhando. Com "reduzir movimento" o texto aparece inteiro de uma vez.
  static const Duration escritaPorLetra = Duration(milliseconds: 18);

  /// O mais que a escrita pode ficar atrás do que já chegou (FR-020b).
  ///
  /// Quando a resposta chega depressa e é longa, a escrita acelera para não
  /// passar disso: animação que faz a pessoa esperar para ler o que já está
  /// pronto deixa de ser acompanhamento e vira atraso.
  static const Duration escritaAtrasoMaximo = Duration(seconds: 2);

  /// Duração efetiva, considerando a preferência de redução de movimento.
  static Duration efetiva(Duration desejada, {required bool reduzirMovimento}) {
    return reduzirMovimento ? Duration.zero : desejada;
  }
}
