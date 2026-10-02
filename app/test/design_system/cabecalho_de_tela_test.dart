import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/aparelhos.dart';

/// `CabecalhoDeTela` — T014, FR-001 da feature 004.
void main() {
  const String tituloLongo =
      'Um título comprido o bastante para precisar de mais de duas linhas '
      'em qualquer telefone que exista hoje';

  Widget app(Widget filho, {double escala = 1.0, Size? tamanho}) => MaterialApp(
    theme: TemasMemora.claro,
    home: MediaQuery(
      data: MediaQueryData(
        size: tamanho ?? referencia,
        textScaler: TextScaler.linear(escala),
      ),
      child: Scaffold(body: filho),
    ),
  );

  group('"Voltar"', () {
    testWidgets('tem seta e palavra, e volta', (WidgetTester t) async {
      int voltou = 0;
      await t.pumpWidget(
        app(CabecalhoDeTela(titulo: 'Ajuda', aoVoltar: () => voltou++)),
      );
      final Finder voltar = find.byKey(CabecalhoDeTela.chaveVoltar);
      expect(
        find.descendant(of: voltar, matching: find.byIcon(Icons.arrow_back)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: voltar, matching: find.text('Voltar')),
        findsOneWidget,
      );
      await t.tap(voltar);
      expect(voltou, 1);
    });

    testWidgets('fica sempre no mesmo canto, com ou sem figura', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(CabecalhoDeTela(titulo: 'Ajuda', aoVoltar: () {})),
      );
      final Offset semFigura = t.getTopLeft(
        find.byKey(CabecalhoDeTela.chaveVoltar),
      );

      await t.pumpWidget(
        app(
          CabecalhoDeTela(
            titulo: 'Ajuda',
            aoVoltar: () {},
            memora: ExpressaoDaMemora.neutra,
          ),
        ),
      );
      expect(t.getTopLeft(find.byKey(CabecalhoDeTela.chaveVoltar)), semFigura);
    });

    testWidgets('sem aoVoltar, não existe — é a raiz de um destino', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(const CabecalhoDeTela(titulo: 'Início')));
      expect(find.byKey(CabecalhoDeTela.chaveVoltar), findsNothing);
    });

    testWidgets('mostra o foco com o anel, e não só com a cor (FR-043)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(CabecalhoDeTela(titulo: 'Ajuda', aoVoltar: () {})),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      final AnimatedContainer c = t.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(CabecalhoDeTela.chaveVoltar),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(c.foregroundDecoration, isNotNull);
    });
  });

  group('Título', () {
    testWidgets('cabe em duas linhas, e o leitor recebe o título inteiro', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app(const CabecalhoDeTela(titulo: tituloLongo)));

      final Text texto = t.widget<Text>(find.text(tituloLongo));
      expect(texto.maxLines, 2);
      expect(find.bySemanticsLabel(tituloLongo), findsOneWidget);
      expect(
        t.getSemantics(find.bySemanticsLabel(tituloLongo)),
        isSemantics(isHeader: true),
      );
      h.dispose();
    });
  });

  group('A figura cede primeiro — regra 7 da R2', () {
    testWidgets('aparece com folga', (WidgetTester t) async {
      await t.pumpWidget(
        app(
          const CabecalhoDeTela(
            titulo: 'Ajuda',
            memora: ExpressaoDaMemora.neutra,
          ),
        ),
      );
      expect(find.byKey(CabecalhoDeTela.chaveFigura), findsOneWidget);
    });

    testWidgets('some a partir de 175% de texto', (WidgetTester t) async {
      await t.pumpWidget(
        app(
          const CabecalhoDeTela(
            titulo: 'Ajuda',
            memora: ExpressaoDaMemora.neutra,
          ),
          escala: 2.0,
        ),
      );
      expect(find.byKey(CabecalhoDeTela.chaveFigura), findsNothing);
      expect(find.text('Ajuda'), findsOneWidget);
    });

    testWidgets('some quando a tela é baixa demais para o piso', (
      WidgetTester t,
    ) async {
      // 300 × 0,11 = 33 dp, abaixo do piso de 40: desenho desse tamanho vira
      // borrão e ocupa uma linha de texto.
      await t.pumpWidget(
        app(
          const CabecalhoDeTela(
            titulo: 'Ajuda',
            ilustracao: Ilustracao.portaAjuda,
          ),
          tamanho: const Size(320, 300),
        ),
      );
      expect(find.byKey(CabecalhoDeTela.chaveFigura), findsNothing);
    });
  });

  group('Matriz — FR-044', () {
    for (final Combinacao c in matriz()) {
      testWidgets('não estoura em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            Scaffold(
              body: CabecalhoDeTela(
                titulo: tituloLongo,
                aoVoltar: () {},
                memora: ExpressaoDaMemora.neutra,
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull, reason: nomeDa(c));
      });
    }
  });
}
