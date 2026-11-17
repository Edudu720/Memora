import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/design_system/componentes/toque/superficie_tocavel.dart';

import '../suporte/aparelhos.dart';
import '../suporte/movimento.dart';

/// A barra inferior refeita — T055, FR-044 a FR-047 e V15 da feature 013.
///
/// O que se prova aqui: cada destino tem ícone **e** rótulo escrito juntos, o
/// alvo de toque tem pelo menos 48 dp em todos os aparelhos e escalas, o
/// indicador **desliza** até o destino tocado e, com "reduzir movimento", ele
/// muda de lugar sem deslizar.
void main() {
  // Quem prova movimento liga o movimento de volta; cada teste decide, pelo
  // `MediaQuery`, se a pessoa pediu para reduzi-lo.
  movimentoLiberado();

  const List<ItemNavegacao> itens = <ItemNavegacao>[
    ItemNavegacao(icone: IconeDeNavegacao.ajustes, rotulo: 'Ajustes'),
    ItemNavegacao(icone: IconeDeNavegacao.inicio, rotulo: 'Início'),
    ItemNavegacao(icone: IconeDeNavegacao.perfil, rotulo: 'Meu perfil'),
  ];

  /// A barra com estado de verdade: tocar muda o destino ativo, como na casca.
  Widget barra({
    required bool reduzir,
    double escala = 1.0,
    MemoraTemaId tema = MemoraTemaId.claro,
    ValueChanged<int>? aoSelecionar,
  }) {
    int ativo = 1;
    return MaterialApp(
      theme: TemasMemora.porId(tema),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduzir,
          textScaler: TextScaler.linear(escala),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return NavegacaoInferior(
              itens: itens,
              indiceAtivo: ativo,
              aoSelecionar: (int i) {
                aoSelecionar?.call(i);
                setState(() => ativo = i);
              },
            );
          },
        ),
      ),
    );
  }

  Finder item(int i) => find.ancestor(
    of: find.text(itens[i].rotulo),
    matching: find.byType(SuperficieTocavel),
  );

  group('Ícone e rótulo juntos — FR-044', () {
    testWidgets('cada destino tem o desenho e o nome escrito no mesmo toque', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(barra(reduzir: true));
      for (int i = 0; i < itens.length; i++) {
        // O rótulo é texto visível, e não só o que o leitor de tela anuncia.
        expect(
          find.text(itens[i].rotulo),
          findsOneWidget,
          reason: itens[i].rotulo,
        );
        expect(item(i), findsOneWidget);
        // O desenho está dentro do mesmo item que o rótulo: um toque só.
        expect(
          find.descendant(
            of: item(i),
            matching: find.byKey(NavegacaoInferior.chaveDoIcone(i + 1)),
          ),
          findsOneWidget,
          reason: 'ícone de ${itens[i].rotulo}',
        );
        expect(
          find.descendant(of: item(i), matching: find.byType(Icon)),
          findsOneWidget,
        );
      }
    });

    testWidgets('o leitor de tela anuncia o nome e o destino atual', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(barra(reduzir: true));
      expect(
        t.getSemantics(item(1)),
        isSemantics(label: 'Início', hint: '2 de 3', isSelected: true),
      );
      expect(
        t.getSemantics(item(0)),
        isSemantics(label: 'Ajustes', hint: '1 de 3', isSelected: false),
      );
      h.dispose();
    });
  });

  group('Alvo de toque de 48 dp, sem estourar — FR-044', () {
    for (final Combinacao c in matriz()) {
      testWidgets('${nomeDa(c)}: cada item tem 48 dp ou mais', (
        WidgetTester t,
      ) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          barra(reduzir: true, escala: c.escala, tema: c.tema),
        );
        expect(t.takeException(), isNull);

        for (int i = 0; i < itens.length; i++) {
          final Size tamanho = t.getSize(item(i));
          expect(
            tamanho.width,
            greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
            reason: '${itens[i].rotulo}: largura',
          );
          expect(
            tamanho.height,
            greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
            reason: '${itens[i].rotulo}: altura',
          );
          // E o rótulo cabe na barra: não vaza para fora da tela.
          final Rect rotulo = t.getRect(find.text(itens[i].rotulo));
          expect(rotulo.left, greaterThanOrEqualTo(0));
          expect(rotulo.right, lessThanOrEqualTo(c.aparelho.width));
        }
      });
    }
  });

  group('O indicador desliza — FR-046 e V15', () {
    Rect pilula(WidgetTester t) =>
        t.getRect(find.byKey(NavegacaoInferior.chaveDaPilula));
    Rect traco(WidgetTester t, int posicao) =>
        t.getRect(find.byKey(NavegacaoInferior.chaveDoTraco(posicao)));
    Rect icone(WidgetTester t, int posicao) =>
        t.getRect(find.byKey(NavegacaoInferior.chaveDoIcone(posicao)));

    testWidgets('com movimento, anda pelo caminho até o destino tocado', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(barra(reduzir: false));
      final double saida = pilula(t).center.dx;
      expect(saida, icone(t, 2).center.dx, reason: 'parte do Início');

      await t.tap(item(2));
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));

      // No meio do caminho: já saiu do Início e ainda não chegou ao perfil.
      final double meio = pilula(t).center.dx;
      expect(meio, greaterThan(saida), reason: 'já saiu do Início');
      expect(
        meio,
        lessThan(icone(t, 3).center.dx),
        reason: 'ainda não chegou ao Meu perfil',
      );
      // O traço anda junto com a pílula: é um par só.
      expect(
        traco(t, 3).center.dx,
        closeTo(meio, 0.01),
        reason: 'traço e pílula andam juntos',
      );

      await t.pumpAndSettle();
      expect(pilula(t).center.dx, closeTo(icone(t, 3).center.dx, 0.01));
      expect(pilula(t).center.dy, closeTo(icone(t, 3).center.dy, 0.01));
      expect(traco(t, 3).center.dx, closeTo(icone(t, 3).center.dx, 0.01));
    });

    testWidgets('anda também para trás, até o destino da esquerda', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(barra(reduzir: false));
      await t.tap(item(0));
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      final double meio = pilula(t).center.dx;
      expect(meio, lessThan(icone(t, 2).center.dx));
      expect(meio, greaterThan(icone(t, 1).center.dx));

      await t.pumpAndSettle();
      expect(pilula(t).center.dx, closeTo(icone(t, 1).center.dx, 0.01));
    });

    testWidgets('com "reduzir movimento", muda de lugar sem deslizar', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(barra(reduzir: true));
      await t.tap(item(2));
      // Um quadro só: sem o deslize, o indicador já está no destino.
      await t.pump();
      await t.pump(const Duration(milliseconds: 1));
      expect(pilula(t).center.dx, closeTo(icone(t, 3).center.dx, 0.01));
      expect(traco(t, 3).center.dx, closeTo(icone(t, 3).center.dx, 0.01));
    });

    testWidgets('o destino tocado é o que a barra avisa', (
      WidgetTester t,
    ) async {
      final List<int> avisos = <int>[];
      await t.pumpWidget(barra(reduzir: true, aoSelecionar: avisos.add));
      await t.tap(item(0));
      await t.pump();
      expect(avisos, <int>[0]);
    });
  });
}
