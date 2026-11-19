import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import '../suporte/movimento.dart';

/// A transição do diálogo — T020 da feature 013 (V7 e V9), FR-010 e FR-013.
///
/// O diálogo surge no centro, por cima: esmaece e cresce de 96% a 100%, e a
/// tela de trás não se mexe. Com "reduzir movimento" ele já chega inteiro.
void main() {
  movimentoLiberado();
  const Key fundo = Key('fundo');
  const Key abrir = Key('abrir');
  const Key chaveDoDialogo = Key('dialogo');

  Widget app({bool reduzir = false}) => MaterialApp(
    theme: TemasMemora.claro,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduzir),
      child: child!,
    ),
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: Column(
          children: <Widget>[
            const SizedBox(key: fundo, height: 40, width: 40),
            TextButton(
              key: abrir,
              onPressed: () => DialogoMemora.mostrar(
                context,
                dialogo: DialogoMemora(
                  key: chaveDoDialogo,
                  titulo: 'Tudo certo!',
                  mensagem: 'Sua senha nova já está valendo.',
                  rotuloConfirmar: 'Entendi',
                  aoConfirmar: () => Navigator.of(context).pop(),
                ),
              ),
              child: const Text('abrir'),
            ),
          ],
        ),
      ),
    ),
  );

  /// A largura do diálogo **na tela** (conta a escala, que o layout não vê).
  double larguraNaTela(WidgetTester t) =>
      t.getBottomRight(find.byKey(chaveDoDialogo)).dx -
      t.getTopLeft(find.byKey(chaveDoDialogo)).dx;

  /// Em que pé está a animação da rota do diálogo.
  AnimationStatus estadoDaRota(WidgetTester t) =>
      ModalRoute.of(t.element(find.byKey(chaveDoDialogo)))!.animation!.status;

  /// O menor esmaecer entre os que envolvem o diálogo.
  double opacidade(WidgetTester t) => t
      .widgetList<FadeTransition>(
        find.ancestor(
          of: find.byKey(chaveDoDialogo),
          matching: find.byType(FadeTransition),
        ),
      )
      .map((FadeTransition f) => f.opacity.value)
      .reduce((double a, double b) => a < b ? a : b);

  testWidgets('surge no centro, esmaecendo e crescendo, sem mexer no fundo', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app());
    final Offset fundoAntes = t.getTopLeft(find.byKey(fundo));

    await t.tap(find.byKey(abrir));
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));

    expect(opacidade(t), lessThan(1), reason: 'esmaece ao surgir');
    final double meio = larguraNaTela(t);
    expect(
      t.getTopLeft(find.byKey(fundo)),
      fundoAntes,
      reason: 'a tela de trás não desliza (FR-010)',
    );

    await t.pumpAndSettle();
    final double inteiro = larguraNaTela(t);
    expect(opacidade(t), 1);
    expect(meio, lessThan(inteiro), reason: 'cresce até o tamanho final');
    expect(meio, greaterThan(inteiro * 0.9), reason: 'um aumento leve, de 96%');
    expect(t.getTopLeft(find.byKey(fundo)), fundoAntes);
    // No centro da tela (a janela do teste é de 800 por 600).
    final Offset centro = t.getCenter(find.byKey(chaveDoDialogo));
    expect(centro.dx, closeTo(400, 1));
  });

  testWidgets('termina em no máximo 500 ms (SC-004)', (WidgetTester t) async {
    await t.pumpWidget(app());
    await t.tap(find.byKey(abrir));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(estadoDaRota(t), AnimationStatus.completed);
    expect(opacidade(t), 1);
  });

  testWidgets('"Entendi" fecha por cima, sem mexer no fundo', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app());
    final Offset fundoAntes = t.getTopLeft(find.byKey(fundo));
    await t.tap(find.byKey(abrir));
    await t.pumpAndSettle();

    await t.tap(find.text('Entendi'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    expect(t.getTopLeft(find.byKey(fundo)), fundoAntes);
    await t.pumpAndSettle();
    expect(find.byKey(chaveDoDialogo), findsNothing);
  });

  testWidgets('com "reduzir movimento", já chega inteiro e parado', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app(reduzir: true));
    await t.tap(find.byKey(abrir));
    await t.pump();
    await t.pump();

    expect(opacidade(t), 1);
    expect(find.byKey(chaveDoDialogo), findsOneWidget);
    expect(estadoDaRota(t), AnimationStatus.completed);
    final double inteiro = larguraNaTela(t);
    final Size layout = t.getSize(find.byKey(chaveDoDialogo));
    expect(inteiro, layout.width, reason: 'sem aumento escondido');

    await t.tap(find.text('Entendi'));
    await t.pump();
    await t.pump();
    expect(find.byKey(chaveDoDialogo), findsNothing);
  });
}
