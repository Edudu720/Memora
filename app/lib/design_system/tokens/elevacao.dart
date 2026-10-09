import 'package:flutter/painting.dart';

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

  /// Cor da sombra — preto a 6%.
  ///
  /// Era `Colors.black.withValues(alpha: 0.06)` escrito dentro do `Cartao`, e
  /// foi a única cor literal que sobrou no aplicativo inteiro. Mora aqui, e
  /// não em `MemoraCores`, porque não é cor **semântica**: ela não muda entre
  /// os três temas, e a sombra nunca carrega significado sozinha (R5).
  static const Color sombra = Color(0x0F000000);

  /// A porta em repouso (feature 004, FR-016): a sombra que a faz parecer um
  /// botão que se pode apertar, e não uma faixa chapada.
  ///
  /// Maior que [cartao] de propósito: a 1 dp a sombra do cartão não se via no
  /// celular do Henrique, e foi isso — "simples demais" — que a revisão da
  /// T044 reprovou. Continua sendo **reforço**: o sinal de que é ação é a
  /// pílula preenchida e o contorno, nunca a sombra (R5).
  static const double porta = 4;

  /// A porta com o dedo em cima: a sombra encolhe e a porta "desce" até a
  /// superfície. Não zera — sumir de uma vez parece defeito; encolher parece
  /// aperto.
  static const double portaPressionada = 1;

  /// Cor da sombra da porta — preto a 20%.
  ///
  /// Mais escura que [sombra] pelo mesmo motivo de [porta] ser maior que
  /// [cartao]. Nos temas escuros uma sombra preta sobre fundo quase preto
  /// pouco aparece, e tudo bem: lá o contorno em primária faz o trabalho.
  static const Color sombraDaPorta = Color(0x33000000);
}
