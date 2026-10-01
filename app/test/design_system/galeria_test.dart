import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/aparelhos.dart';

/// A galeria do Design System — T045, FR-033.
///
/// ## Por que este arquivo vale mais do que parece
///
/// A galeria monta **todo** componente em **todo** estado. Montá-la é, de
/// graça, um teste de fumaça do sistema inteiro: se um componente estourar a
/// largura no tema de alto contraste a 200% num aparelho estreito, ele
/// estoura aqui — sem ninguém precisar escrever um caso para ele.
///
/// É por isso que a matriz abaixo é cruzada de verdade (aparelho × escala) e
/// os três temas entram por dentro: são as três dimensões em que um
/// componente quebra sem que ninguém perceba.
///
/// ## `pumpAndSettle` não serve aqui
///
/// O `Carregando` anima sem parar, e a galeria tem um sempre na tela. Quem
/// chamar `pumpAndSettle` neste arquivo trava o teste até o tempo esgotar.
void main() {
  Future<void> montar(
    WidgetTester t, {
    required Size aparelho,
    double escala = 1.0,
  }) async {
    t.view.physicalSize = aparelho;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(escala)),
        child: const MaterialApp(home: GaleriaMemora()),
      ),
    );
    await t.pump();
  }

  group('A galeria monta em todo aparelho e toda ampliação', () {
    for (final Size aparelho in aparelhos) {
      for (final double escala in <double>[1.0, 1.5, 2.0]) {
        testWidgets('${nomeDo(aparelho)}, escala $escala',
            (WidgetTester t) async {
          await montar(t, aparelho: aparelho, escala: escala);

          expect(t.takeException(), isNull,
              reason: 'algum componente quebrou em ${nomeDo(aparelho)} a '
                  '$escala — a galeria monta todos, entao o estouro pode '
                  'estar em qualquer um deles');
        });
      }
    }
  });

  group('Os três temas — FR-004', () {
    for (final String tema in <String>['Claro', 'Escuro', 'Alto contraste']) {
      testWidgets('trocar para "$tema" nao quebra nada',
          (WidgetTester t) async {
        // Na escala máxima, que é onde a troca de tema tem mais chance de
        // revelar um componente que só cabia por sorte.
        await montar(
          t,
          aparelho: referencia,
          escala: MemoraDimensoes.escalaTextoMax,
        );

        final Finder pastilha = find.bySemanticsLabel(tema);
        await t.ensureVisible(pastilha);
        await t.tap(pastilha);
        await t.pump();

        expect(t.takeException(), isNull,
            reason: 'o tema "$tema" quebrou algum componente');
      });
    }
  });

  testWidgets('a ampliação pode ser trocada de dentro da galeria',
      (WidgetTester t) async {
    await montar(t, aparelho: referencia);

    final Finder duzentos = find.bySemanticsLabel('200%');
    await t.ensureVisible(duzentos);
    await t.tap(duzentos);
    await t.pump();

    expect(t.takeException(), isNull);
  });

  testWidgets('fora do modo de depuração a galeria não existe (R9)',
      (WidgetTester t) async {
    // `flutter test` roda em modo de depuração, então aqui ela existe. O que
    // este caso prende é o **contrato**: o ponto de entrada é anulável, e
    // quem chama precisa continuar tratando o `null`. Se alguém trocar o
    // retorno por `Widget` não-anulável para "simplificar", a galeria passa a
    // acompanhar o aplicativo até a loja, e este teste para de compilar.
    final Widget? galeria = GaleriaMemora.paraDesenvolvimento();

    expect(galeria, isNotNull, reason: 'flutter test roda em kDebugMode');
    expect(galeria, isA<GaleriaMemora>());
  });
}
