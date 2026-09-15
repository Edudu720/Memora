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
}
