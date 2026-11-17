import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/movimento.dart';

/// O `Carregando` é a Memora segurando a barra (feature 013, T095, FR-059).
///
/// O arquivo começa com o movimento do sistema **liberado**: quem prova a
/// barra correndo precisa de relógio. Cada caso monta o próprio `MediaQuery`
/// quando quer "reduzir movimento".
void main() {
  movimentoLiberado();

  Future<void> montar(
    WidgetTester t, {
    required bool reduzirMovimento,
    String mensagem = 'Estou criando sua conta...',
  }) {
    return t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduzirMovimento),
            child: Scaffold(
              body: Center(child: Carregando(mensagem: mensagem)),
            ),
          ),
        ),
      ),
    );
  }

  MemoraAnimada memora(WidgetTester t) =>
      t.widget<MemoraAnimada>(find.byType(MemoraAnimada));

  group('A Memora segurando a barra', () {
    testWidgets('é a pose `carregando`, comum (não a anfitriã), sem toque', (
      WidgetTester t,
    ) async {
      await montar(t, reduzirMovimento: false);

      expect(find.byType(MemoraAnimada), findsOneWidget);
      expect(memora(t).expressao, PoseDaMemora.carregando);
      expect(
        memora(t).anfitria,
        isFalse,
        reason: 'A anfitriã é do Início e da abertura (FR-048).',
      );
      expect(memora(t).reageAoToque, isFalse);
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason:
            'O círculo girando saiu: a espera é a Memora com a barra '
            '(FR-059).',
      );
      // Sem número: a barra é indeterminada, e a frase é a única informação.
      expect(find.text('Estou criando sua conta...'), findsOneWidget);
    });

    testWidgets('a barra corre sem parar enquanto a tela espera', (
      WidgetTester t,
    ) async {
      await montar(t, reduzirMovimento: false);

      final Animation<double>? ciclo = memora(t).cicloDaBarra;
      expect(ciclo, isNotNull, reason: 'Sem o ciclo, a barra não corre.');

      await t.pump(const Duration(milliseconds: 300));
      final double a = ciclo!.value;
      await t.pump(const Duration(milliseconds: 500));
      final double b = ciclo.value;
      expect(b, greaterThan(a), reason: 'A barra precisa avançar.');

      // Passa de uma passada inteira (1,5 s) e a seguinte emenda: o ciclo
      // volta ao começo em vez de parar no fim.
      await t.pump(const Duration(milliseconds: 1000));
      expect(ciclo.value, lessThan(b));
      expect(t.hasRunningAnimations, isTrue);
    });
  });

  group('Reduzir movimento — FR-039, FR-059', () {
    testWidgets('a barra fica parada e nenhum relógio roda', (
      WidgetTester t,
    ) async {
      await montar(t, reduzirMovimento: true);

      expect(memora(t).cicloDaBarra, isNull);
      expect(
        t.hasRunningAnimations,
        isFalse,
        reason: 'Com "reduzir movimento" nenhum relógio roda.',
      );
      await t.pump(const Duration(seconds: 3));
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('ligar a preferência com a espera na tela para a barra', (
      WidgetTester t,
    ) async {
      await montar(t, reduzirMovimento: false);
      expect(t.hasRunningAnimations, isTrue);

      await montar(t, reduzirMovimento: true);
      await t.pump();

      expect(memora(t).cicloDaBarra, isNull);
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('desligar a preferência volta a correr a barra', (
      WidgetTester t,
    ) async {
      await montar(t, reduzirMovimento: true);
      expect(t.hasRunningAnimations, isFalse);

      await montar(t, reduzirMovimento: false);
      await t.pump(const Duration(milliseconds: 200));

      expect(memora(t).cicloDaBarra, isNotNull);
      expect(t.hasRunningAnimations, isTrue);
    });
  });

  group('O leitor de tela — FR-059', () {
    for (final bool reduzir in <bool>[false, true]) {
      testWidgets('ouve só a frase, como aviso; a Memora é decorativa '
          '(reduzir movimento: $reduzir)', (WidgetTester t) async {
        final SemanticsHandle handle = t.ensureSemantics();
        await montar(t, reduzirMovimento: reduzir);

        // Todo nó da árvore que fala alguma coisa.
        final List<SemanticsNode> falantes = <SemanticsNode>[];
        void percorrer(SemanticsNode no) {
          if (no.label.isNotEmpty ||
              no.value.isNotEmpty ||
              no.hint.isNotEmpty) {
            falantes.add(no);
          }
          no.visitChildren((SemanticsNode filho) {
            percorrer(filho);
            return true;
          });
        }

        percorrer(
          t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
        );

        expect(falantes.map((SemanticsNode n) => n.label).toList(), <String>[
          'Estou criando sua conta...',
        ], reason: 'A Memora e a barra não podem ser anunciadas: só a frase.');
        expect(
          t.getSemantics(find.byType(Carregando)),
          isSemantics(label: 'Estou criando sua conta...', isLiveRegion: true),
          reason: 'A frase é um aviso: o leitor a lê sem a pessoa tocar.',
        );
        handle.dispose();
      });
    }
  });
}
