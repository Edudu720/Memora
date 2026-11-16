import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// A transição da folha inferior — T020 da feature 013 (V7 e V9), FR-010 e
/// FR-013.
///
/// A folha sobe de baixo, por cima, e a tela de trás não se mexe. Com
/// "reduzir movimento" ela já chega no lugar.
void main() {
  const Key fundo = Key('fundo');
  const Key abrir = Key('abrir');
  const Key chaveDaFolha = Key('folha');

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
              onPressed: () => FolhaInferior.mostrar(
                context,
                folha: const FolhaInferior(
                  key: chaveDaFolha,
                  titulo: 'Como eu te ajudo',
                  child: Text('Eu mostro o caminho.'),
                ),
              ),
              child: const Text('abrir'),
            ),
          ],
        ),
      ),
    ),
  );

  /// Em que pé está a animação da rota da folha.
  AnimationStatus estadoDaRota(WidgetTester t) =>
      ModalRoute.of(t.element(find.byKey(chaveDaFolha)))!.animation!.status;

  double topoDaFolha(WidgetTester t) =>
      t.getTopLeft(find.byKey(chaveDaFolha)).dy;

  testWidgets('sobe de baixo, sem mexer no fundo', (WidgetTester t) async {
    await t.pumpWidget(app());
    final Offset fundoAntes = t.getTopLeft(find.byKey(fundo));

    await t.tap(find.byKey(abrir));
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));

    final double meio = topoDaFolha(t);
    expect(
      t.getTopLeft(find.byKey(fundo)),
      fundoAntes,
      reason: 'a tela de trás não desliza (FR-010)',
    );
    await t.pumpAndSettle();
    final double parada = topoDaFolha(t);

    expect(meio, greaterThan(parada), reason: 'ainda estava subindo');
    expect(
      parada + t.getSize(find.byKey(chaveDaFolha)).height,
      600,
      reason: 'termina encostada na borda de baixo',
    );
    expect(t.getTopLeft(find.byKey(fundo)), fundoAntes);
  });

  testWidgets('termina em no máximo 500 ms (SC-004)', (WidgetTester t) async {
    await t.pumpWidget(app());
    await t.tap(find.byKey(abrir));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(estadoDaRota(t), AnimationStatus.completed);
  });

  testWidgets('"Fechar" desce, sem mexer no fundo', (WidgetTester t) async {
    await t.pumpWidget(app());
    final Offset fundoAntes = t.getTopLeft(find.byKey(fundo));
    await t.tap(find.byKey(abrir));
    await t.pumpAndSettle();
    final double parada = topoDaFolha(t);

    await t.tap(find.text('Fechar'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    expect(topoDaFolha(t), greaterThan(parada), reason: 'está descendo');
    expect(t.getTopLeft(find.byKey(fundo)), fundoAntes);
    await t.pumpAndSettle();
    expect(find.byKey(chaveDaFolha), findsNothing);
  });

  testWidgets('com "reduzir movimento", já chega no lugar e parada', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app());
    await t.tap(find.byKey(abrir));
    await t.pumpAndSettle();
    final double lugar = topoDaFolha(t);
    await t.tap(find.text('Fechar'));
    await t.pumpAndSettle();

    await t.pumpWidget(app(reduzir: true));
    await t.tap(find.byKey(abrir));
    await t.pump();
    await t.pump();

    expect(topoDaFolha(t), lugar);
    expect(estadoDaRota(t), AnimationStatus.completed);

    await t.tap(find.text('Fechar'));
    await t.pump();
    await t.pump();
    expect(find.byKey(chaveDaFolha), findsNothing);
  });
}
