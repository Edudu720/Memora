import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/movimento.dart';

/// A troca de passo dentro da mesma tela — T072 da feature 013 (US6), FR-009,
/// FR-013 e FR-014.
///
/// Como em `rota_memora_test.dart`, o deslize se mede pela posição **na tela**
/// de uma chave que cobre o passo inteiro, sem depender de qual widget desliza.
void main() {
  movimentoLiberado();

  Key chaveDoPasso(int n) => Key('passo.$n');

  late Map<int, int> toques;
  setUp(() => toques = <int, int>{});

  Widget passo(int n) => SizedBox(
    key: chaveDoPasso(n),
    height: 80,
    // O botão ocupa o passo todo: o que sai ainda tem uma faixa à vista.
    child: TextButton(
      style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 80)),
      onPressed: () => toques[n] = (toques[n] ?? 0) + 1,
      child: Text('passo $n'),
    ),
  );

  Widget app(int posicao, {bool reduzir = false}) => MaterialApp(
    theme: TemasMemora.claro,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduzir),
      child: child!,
    ),
    home: Scaffold(
      body: TrocaDePasso(posicao: posicao, child: passo(posicao)),
    ),
  );

  double largura(WidgetTester t) =>
      t.view.physicalSize.width / t.view.devicePixelRatio;

  double esquerdaDe(WidgetTester t, int n) =>
      t.getTopLeft(find.byKey(chaveDoPasso(n), skipOffstage: false)).dx;

  group('Avançar — FR-009', () {
    testWidgets(
      'o passo novo entra pela direita e o antigo sai pela esquerda',
      (WidgetTester t) async {
        await t.pumpWidget(app(1));
        final double w = largura(t);

        await t.pumpWidget(app(2));
        await t.pump(const Duration(milliseconds: 100));

        expect(esquerdaDe(t, 2), greaterThan(0), reason: 'entra da direita');
        expect(esquerdaDe(t, 2), lessThan(w), reason: 'já está entrando');
        expect(
          esquerdaDe(t, 1),
          lessThan(0),
          reason: 'o antigo sai pela esquerda',
        );

        await t.pumpAndSettle();
        expect(esquerdaDe(t, 2), 0);
        expect(find.byKey(chaveDoPasso(1)), findsNothing);
      },
    );

    testWidgets('termina em no máximo 500 ms (SC-004)', (WidgetTester t) async {
      await t.pumpWidget(app(1));
      await t.pumpWidget(app(2));
      await t.pump(const Duration(milliseconds: 500));

      expect(esquerdaDe(t, 2), 0);
      expect(find.byKey(chaveDoPasso(1)), findsNothing);
      expect(t.binding.transientCallbackCount, 0);
    });
  });

  group('Voltar — FR-009', () {
    testWidgets('o passo anterior volta pela esquerda e o de agora sai pela '
        'direita', (WidgetTester t) async {
      await t.pumpWidget(app(2));
      final double w = largura(t);

      await t.pumpWidget(app(1));
      await t.pump(const Duration(milliseconds: 100));

      expect(esquerdaDe(t, 1), lessThan(0), reason: 'volta da esquerda');
      expect(esquerdaDe(t, 1), greaterThan(-w), reason: 'já está voltando');
      expect(
        esquerdaDe(t, 2),
        greaterThan(0),
        reason: 'o de agora sai à direita',
      );

      await t.pumpAndSettle();
      expect(esquerdaDe(t, 1), 0);
      expect(find.byKey(chaveDoPasso(2)), findsNothing);
    });
  });

  group('Toque e leitura durante o deslize — FR-014', () {
    testWidgets('o passo que sai não recebe toque nem é lido', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app(1));
      await t.pumpWidget(app(2));
      // 250 ms: os dois passos ainda estão em parte à vista.
      await t.pump(const Duration(milliseconds: 250));

      final double y = t.getCenter(find.byKey(chaveDoPasso(2))).dy;
      final double w = largura(t);

      // A faixa à esquerda ainda é do passo 1, que está saindo: o toque nela
      // não chega ao botão dele.
      expect(esquerdaDe(t, 1) + w, greaterThan(50));
      await t.tapAt(Offset(20, y));
      expect(toques[1], isNull, reason: "o passo que sai não aceita toque");

      // A do passo 2, que chega, aceita (FR-014: o toque não se perde).
      await t.tapAt(Offset(w - 20, y));
      expect(toques[2], 1, reason: "o passo que chega aceita toque");

      // E só o passo que chega aparece para o leitor de tela.
      expect(find.semantics.byLabel(RegExp('passo 1')), findsNothing);
      expect(find.semantics.byLabel(RegExp('passo 2')), findsOneWidget);

      await t.pumpAndSettle();
      h.dispose();
    });
  });

  group('Reduzir movimento — FR-013', () {
    testWidgets('a troca é instantânea e nada desliza, nos dois sentidos', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(1, reduzir: true));

      await t.pumpWidget(app(2, reduzir: true));
      // Um quadro só: sem nenhum instante de deslize.
      await t.pump();
      expect(esquerdaDe(t, 2), 0, reason: 'chegou no lugar de uma vez');
      expect(find.byKey(chaveDoPasso(1)), findsNothing);

      await t.pumpWidget(app(1, reduzir: true));
      await t.pump();
      expect(esquerdaDe(t, 1), 0);
      expect(find.byKey(chaveDoPasso(2)), findsNothing);
      expect(t.binding.transientCallbackCount, 0);
    });
  });
}
