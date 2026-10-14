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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

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

// -----------------------------------------------------------------------------
// A matriz completa da feature 004: aparelho × escala × tema (FR-044).
// -----------------------------------------------------------------------------

/// As escalas de texto verificadas: 100%, 150% e o teto de 200%.
const List<double> escalas = <double>[1.0, 1.5, 2.0];

/// Uma combinação da matriz.
typedef Combinacao = ({Size aparelho, double escala, MemoraTemaId tema});

/// Toda combinação de [de] × [em] × [temas], na ordem do mais folgado ao mais
/// apertado.
///
/// São 36 combinações com os padrões. Um teste de tela que rode todas custa
/// segundos, e foi um aparelho só que escondeu o estouro do 360×640 em 100%.
Iterable<Combinacao> matriz({
  List<Size> de = aparelhos,
  List<double> em = escalas,
  List<MemoraTemaId> temas = MemoraTemaId.values,
}) sync* {
  for (final Size aparelho in de) {
    for (final double escala in em) {
      for (final MemoraTemaId tema in temas) {
        yield (aparelho: aparelho, escala: escala, tema: tema);
      }
    }
  }
}

/// Nome da combinação, para o título do teste e a mensagem de falha.
String nomeDa(Combinacao c) =>
    '${nomeDo(c.aparelho)} a ${(c.escala * 100).round()}% no tema ${c.tema.name}';

/// Põe a janela do teste no tamanho do aparelho, e a devolve no fim.
///
/// `MediaQuery(size:)` sozinho **não** muda o layout — só o que
/// `MediaQuery.of` lê. As restrições de verdade vêm da janela, que é 800×600
/// por padrão: mais larga que qualquer telefone. Foi assim que os testes de
/// acessibilidade antigos rodaram anos num tamanho que nenhum idoso tem.
void vestir(WidgetTester t, Size aparelho) {
  t.view.physicalSize = aparelho;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

/// Um aplicativo mínimo na combinação [c], com [filho] como tela.
Widget naCombinacao(Combinacao c, Widget filho) => MaterialApp(
  theme: TemasMemora.porId(c.tema),
  home: MediaQuery(
    data: MediaQueryData(
      size: c.aparelho,
      textScaler: TextScaler.linear(c.escala),
    ),
    child: filho,
  ),
);

/// Reprova se [alvo] não ficar **alcançável** no aparelho [aparelho]: depois de
/// rolar até ele, ele precisa estar inteiro dentro da janela.
///
/// "Não estourou" não é "continua utilizável" — a lição do portão da FR-027 da
/// 003, que passava com a conversa reduzida a 4 px. A ação principal de uma
/// tela precisa poder ser **tocada**, e tocar exige vê-la.
///
/// Quem chama toca em seguida e confere o efeito: isto prova que o alvo está à
/// vista, não que ele responde.
Future<void> exigirAlcancavel(
  WidgetTester t,
  Finder alvo, {
  required Size aparelho,
  required String contexto,
}) async {
  expect(alvo, findsOneWidget, reason: '$contexto: o alvo nem existe');
  await t.ensureVisible(alvo);
  await t.pump();
  final Rect r = t.getRect(alvo);
  // Folga de ruído de ponto flutuante: `ensureVisible` alinha o alvo à borda,
  // e ela sai como -3e-14 (visto em Ajustes, 360x800 a 150%, depois da 3b). É
  // a mesma folga do `matriz_dentro_da_conta_test.dart`; um centésimo de px
  // não esconde estouro nenhum.
  const double folga = 0.01;
  expect(
    r.top,
    greaterThanOrEqualTo(-folga),
    reason: '$contexto: o alvo ficou acima da janela ($r)',
  );
  expect(
    r.bottom,
    lessThanOrEqualTo(aparelho.height + folga),
    reason: '$contexto: o alvo ficou abaixo da janela ($r)',
  );
  expect(
    r.left >= 0 && r.right <= aparelho.width,
    isTrue,
    reason: '$contexto: o alvo passou da largura da janela ($r)',
  );
}
