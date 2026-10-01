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

  // ---------------------------------------------------------------------------
  // Ícones
  //
  // ⚠️ Estes tokens nasceram do que a T046 encontrou: **sete** tamanhos de
  // ícone espalhados pelo código (18, 20, 22, 24, 28, 56 e 72), nenhum
  // declarado em lugar nenhum. É a erosão que a FR-032 existe para impedir,
  // acontecendo em silêncio — quatro deles eram "ícone ao lado de texto",
  // escritos por pessoas diferentes em dias diferentes.
  //
  // A escala abaixo tem quatro degraus, e cada um responde a uma pergunta
  // diferente: "acompanha um texto?", "é o assunto do bloco?", "é a tela
  // inteira?". Dois degraus que respondem à mesma pergunta são dois degraus
  // a mais.
  // ---------------------------------------------------------------------------

  /// 20 dp — ícone que acompanha um texto **de apoio**, sem competir com ele.
  static const double iconePequeno = 20;

  /// 24 dp — ícone que acompanha um texto **de corpo**. É o padrão do
  /// Material e o degrau mais usado; na dúvida, é este.
  static const double iconePadrao = 24;

  /// 28 dp — ícone que **é** o sinal, e não o acompanhamento: erro, seleção,
  /// aviso, navegação. Ele precisa ser visto antes do texto ao lado.
  static const double iconeDestaque = 28;

  /// 56 dp — ícone de estado vazio, onde ele é o único conteúdo da área.
  static const double iconeEstadoVazio = 56;

  /// 72 dp — ícone de celebração, no meio de uma tela de conclusão. É o maior
  /// que existe, e ele marca o momento em que a pessoa conseguiu.
  static const double iconeCelebracao = 72;

  // ---------------------------------------------------------------------------
  // Leitura
  // ---------------------------------------------------------------------------

  /// 320 dp — largura máxima de um bloco de texto corrido.
  ///
  /// Não é um limite de tela, é um limite de **linha**: linha longa demais
  /// faz o olho perder o começo da seguinte, e quem tem baixa visão perde
  /// primeiro. Num telefone o cap quase nunca chega a valer; ele existe para
  /// a tela larga, onde o balão de conversa se esticaria de ponta a ponta.
  static const double larguraMaximaDeLeitura = 320;

  // ---------------------------------------------------------------------------
  // Contornos
  // ---------------------------------------------------------------------------

  /// 2 dp — contorno que **carrega significado**: botão secundário, aviso de
  /// perigo. Grosso o bastante para ser visto sem depender da cor, que é o
  /// que o Princípio III exige.
  static const double bordaEnfase = 2;

  /// 3 dp — contorno de foco e de seleção. Mais grosso que o de ênfase de
  /// propósito: ele precisa vencer o contorno que já estava lá.
  static const double bordaSelecao = 3;

  /// 5 dp — o anel que separa o avatar da Memora do fundo atrás dele.
  static const double bordaAvatar = 5;

  // ---------------------------------------------------------------------------
  // Indicador de progresso
  // ---------------------------------------------------------------------------

  /// 20 dp — o giro que cabe **dentro** de um botão, ao lado do rótulo.
  static const double indicadorEmBotao = 20;

  /// 2.5 dp — espessura do giro pequeno.
  static const double espessuraIndicadorEmBotao = 2.5;

  /// 40 dp — o giro que ocupa a tela enquanto a pessoa espera.
  static const double indicadorDeTela = 40;

  /// 4 dp — espessura do giro grande.
  static const double espessuraIndicadorDeTela = 4;
}
