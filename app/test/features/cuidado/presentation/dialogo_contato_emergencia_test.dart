import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/cuidado/presentation/telas/dialogo_contato_emergencia.dart';

import '../../../suporte/movimento.dart';

/// O diálogo do contato de emergência abre pela sobreposição do `Dialogo` —
/// T091 da feature 013 (FR-010 e FR-013).
///
/// Antes ele abria por um `showDialog` cru: sem o aumento de 96% a 100% e
/// com 150 ms fixos mesmo com "reduzir movimento".
void main() {
  movimentoLiberado();
  const Key abrir = Key('abrir');

  Widget app({required bool reduzir}) => MaterialApp(
    theme: TemasMemora.claro,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduzir),
      child: child!,
    ),
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: TextButton(
          key: abrir,
          onPressed: () => DialogoContatoEmergencia.exibir(
            context: context,
            aoSalvar: (_) {},
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );

  /// O menor esmaecer entre os que envolvem o diálogo.
  double opacidade(WidgetTester t) => t
      .widgetList<FadeTransition>(
        find.ancestor(
          of: find.byType(DialogoContatoEmergencia),
          matching: find.byType(FadeTransition),
        ),
      )
      .map((FadeTransition f) => f.opacity.value)
      .reduce((double a, double b) => a < b ? a : b);

  /// A escala aplicada pela sobreposição do `Dialogo` (1 quando não há).
  double escala(WidgetTester t) {
    final Iterable<ScaleTransition> escalas = t.widgetList<ScaleTransition>(
      find.ancestor(
        of: find.byType(DialogoContatoEmergencia),
        matching: find.byType(ScaleTransition),
      ),
    );
    return escalas.isEmpty ? 1 : escalas.first.scale.value;
  }

  testWidgets('com movimento, surge crescendo de 96% a 100% (FR-010)', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app(reduzir: false));
    await t.tap(find.byKey(abrir));
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));

    expect(opacidade(t), lessThan(1), reason: 'esmaece ao surgir');
    expect(escala(t), lessThan(1), reason: 'cresce, como o DialogoMemora');
    expect(escala(t), greaterThan(0.9));

    await t.pumpAndSettle();
    expect(opacidade(t), 1);
    expect(escala(t), 1);
  });

  testWidgets('com "reduzir movimento", já chega inteiro (FR-013)', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app(reduzir: true));
    await t.tap(find.byKey(abrir));
    await t.pump();
    await t.pump();

    expect(find.byType(DialogoContatoEmergencia), findsOneWidget);
    expect(opacidade(t), 1, reason: 'sem os 150 ms fixos do showDialog cru');
    expect(escala(t), 1);

    await t.ensureVisible(find.text('Cancelar'));
    await t.tap(find.text('Cancelar'));
    await t.pump();
    await t.pump();
    expect(find.byType(DialogoContatoEmergencia), findsNothing);
  });
}
