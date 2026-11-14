import 'package:flutter/painting.dart';

import 'cores.dart';

/// Elevações e sombras do Memora.
///
/// Sombra **nunca** é o sinal principal de que algo é clicável: ela é
/// praticamente invisível para quem tem baixa visão. Forma, contorno e texto
/// carregam o sinal; a elevação apenas reforça a hierarquia (research.md, R5).
abstract final class MemoraElevacao {
  /// Sem elevação.
  static const double plana = 0;

  /// Cartões e agrupamentos.
  static const double cartao = 1;

  /// Elementos flutuantes sobre o conteúdo.
  static const double flutuante = 3;

  /// Diálogos e folhas modais.
  static const double modal = 6;

  /// Cor da sombra legada — preto a 6%.
  static const Color sombra = Color(0x0F000000);

  /// Sombra difusa principal dos cartões elevados — preto a 6%.
  static const Color sombraCartaoDifusa = Color(0x0F000000);

  /// Sombra de contato rente ao cartão — preto a 4%.
  static const Color sombraContato = Color(0x0A000000);

  /// Sombra sutil voltada para cima nas barras inferiores elevadas — preto a 5%.
  static const Color sombraBarra = Color(0x0D000000);

  /// A porta em repouso (feature 004, FR-016).
  static const double porta = 4;

  /// A porta com o dedo em cima.
  static const double portaPressionada = 1;

  /// Cor da sombra da porta — preto a 20%.
  static const Color sombraDaPorta = Color(0x33000000);

  /// Indica se [cores] pertence ao tema de Alto Contraste (onde sombras somem).
  static bool _ehAltoContraste(MemoraCores cores) =>
      cores.fundo == MemoraCores.altoContraste.fundo &&
      cores.borda == MemoraCores.altoContraste.borda;

  /// Duas camadas suaves de sombra para cartões no Claro/Escuro; vazia no
  /// Alto Contraste (substituída por contorno reforçado).
  static List<BoxShadow> listaSombrasCartao(MemoraCores cores) {
    if (_ehAltoContraste(cores)) return const <BoxShadow>[];
    return const <BoxShadow>[
      BoxShadow(
        color: sombraCartaoDifusa,
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: sombraContato,
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
    ];
  }

  /// Sombra limpa voltada para cima para a barra inferior e faixa do chat;
  /// vazia no Alto Contraste.
  static List<BoxShadow> listaSombrasBarra(MemoraCores cores) {
    if (_ehAltoContraste(cores)) return const <BoxShadow>[];
    return const <BoxShadow>[
      BoxShadow(
        color: sombraBarra,
        blurRadius: 20,
        offset: Offset(0, -4),
      ),
    ];
  }
}
