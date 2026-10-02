/// O portão da FR-006 da feature 004: nenhuma tela fica em branco enquanto
/// espera, nem quando não há nada, nem quando dá errado (T033a).
///
/// ## O que "desenho próprio e frase" quer dizer aqui
///
/// Cada um dos três estados precisa mostrar, ao mesmo tempo:
///
/// - **uma frase** — algum texto não vazio na tela; e
/// - **um desenho** — o indicador de carregando, o estado vazio, a mensagem
///   de erro, ou uma ilustração do Memora.
///
/// Só o giro, sem dizer o que se espera, deixa quem enxerga pouco sem saber se
/// travou. Só a frase, sem desenho, some no meio da tela. É por isso que os
/// dois são exigidos juntos.
///
/// ## Como usar
///
/// O teste de cada tela monta a tela em cada estado — com o dublê do
/// repositório devolvendo nada, falhando ou demorando — e passa as três
/// montagens para [exigirOsEstadosDaFr006]. Uma tela que não tenha um dos
/// estados (a apresentação, por exemplo, não carrega nada) passa `null`
/// naquele.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Um estado da FR-006.
enum EstadoDaTela {
  /// Esperando a resposta.
  carregando,

  /// Não há nada para mostrar ainda.
  vazio,

  /// Não deu para carregar.
  erro,
}

/// O que conta como "desenho" num estado.
final List<Finder> _desenhos = <Finder>[
  find.byType(Carregando),
  find.byType(EstadoVazio),
  find.byType(MensagemErro),
  find.byType(IlustracaoMemora),
  find.byType(MemoraPersonagem),
  find.byType(MedalhaoDeIlustracao),
];

/// Reprova se a tela, montada em algum dos estados, não tiver frase **e**
/// desenho.
///
/// [montar] recebe o estado e devolve a tela montada nele, ou `null` quando a
/// tela não tem aquele estado.
Future<void> exigirOsEstadosDaFr006(
  WidgetTester t, {
  required String tela,
  required Widget? Function(EstadoDaTela estado) montar,
}) async {
  for (final EstadoDaTela estado in EstadoDaTela.values) {
    final Widget? montada = montar(estado);
    if (montada == null) continue;

    await t.pumpWidget(montada);
    // Bombeia sem esperar quietude: o `Carregando` anima sem parar, e
    // `pumpAndSettle` travaria.
    await t.pump(const Duration(milliseconds: 50));

    final bool temFrase = t
        .widgetList<Text>(find.byType(Text))
        .any(
          (Text texto) => (texto.data ?? texto.textSpan?.toPlainText() ?? '')
              .trim()
              .isNotEmpty,
        );
    expect(
      temFrase,
      isTrue,
      reason: '$tela, estado ${estado.name}: nenhuma frase na tela (FR-006)',
    );

    final bool temDesenho = _desenhos.any((Finder f) => t.any(f));
    expect(
      temDesenho,
      isTrue,
      reason:
          '$tela, estado ${estado.name}: nenhum desenho na tela — nem '
          'giro, nem estado vazio, nem erro, nem ilustração (FR-006)',
    );
  }
}
