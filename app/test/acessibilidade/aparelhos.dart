/// Os aparelhos contra os quais a ampliação de texto é verificada.
///
/// ## Por que existe mais de um
///
/// O T070 mediu num aparelho só — o 390×844 — e calibrou tetos de altura em
/// pixels a partir dele. A revisão da PR #27 mediu os outros: com aqueles
/// tetos, um **360×800** (Galaxy A/M, o mais comum no Brasil) ainda estourava
/// 40 px em 200%, e um **360×640** estourava 133 px **já em 100%**, sem zoom
/// nenhum.
///
/// Nenhum teste pegava isso, porque todos rodavam no aparelho folgado. Um
/// teto em pixels não sabe quanto de tela existe; e um teste num aparelho só
/// não sabe que existem outros.
///
/// ## Por que o 320×568 está aqui
///
/// Ele não é comum, e é exatamente por isso: é o piso que o Android ainda
/// permite e o caso que ninguém tem na mesa para testar na mão.
library;

import 'dart:ui';

/// O aparelho em que o T070 foi medido, e o padrão de quem não pede outro.
const Size referencia = Size(390, 844);

/// A matriz completa, do mais folgado ao mais apertado.
const List<Size> aparelhos = <Size>[
  referencia,
  Size(360, 800),
  Size(360, 640),
  Size(320, 568),
];

/// Nome curto do aparelho, para o título do teste.
String nomeDo(Size aparelho) =>
    '${aparelho.width.toInt()}x${aparelho.height.toInt()}';
