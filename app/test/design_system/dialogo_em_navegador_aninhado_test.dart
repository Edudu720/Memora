import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// `DialogoMemora` dentro de um `Navigator` aninhado — achado da revisão da
/// #38.
///
/// A casca da feature 004 tem um `Navigator` por destino. O diálogo abria no
/// `Navigator` de fora (o padrão do `showDialog`), e quem o fechava com o
/// próprio contexto achava o `Navigator` do destino: "Entendi" fechava **a
/// tela de trás** e deixava o diálogo aberto. Agora o diálogo abre no mesmo
/// `Navigator` que o contexto de quem chama encontra — e `pop()` fecha ele.
void main() {
  testWidgets('"Entendi" fecha o diálogo, e não a tela de trás',
      (WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('raiz do destino')),
          ),
        ),
      ),
    );

    final NavigatorState destino = t.state<NavigatorState>(
      find.byType(Navigator).last,
    );
    destino.push(
      MaterialPageRoute<void>(
        builder: (BuildContext pagina) => Scaffold(
          body: Center(
            child: BotaoPrimario(
              rotulo: 'Abrir diálogo',
              aoTocar: () => DialogoMemora.mostrar(
                pagina,
                dialogo: DialogoMemora(
                  titulo: 'Tudo certo!',
                  mensagem: 'Sua senha nova já está valendo.',
                  rotuloConfirmar: 'Entendi',
                  aoConfirmar: () => Navigator.of(pagina).pop(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();

    await t.tap(find.text('Abrir diálogo'));
    await t.pumpAndSettle();
    expect(find.text('Tudo certo!'), findsOneWidget);

    await t.tap(find.text('Entendi'));
    await t.pumpAndSettle();
    expect(find.text('Tudo certo!'), findsNothing, reason: 'o diálogo ficou');
    expect(find.text('Abrir diálogo'), findsOneWidget,
        reason: 'a tela de trás é que fechou');
  });
}
