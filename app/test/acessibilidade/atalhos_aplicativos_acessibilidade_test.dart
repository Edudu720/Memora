import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/atalhos_aplicativos/data/repositorio_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/controllers/atalhos_aplicativos_controller.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/cartao_atalho_aplicativo.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

import '../suporte/aparelhos.dart';

/// Acessibilidade da tela de atalhos diretos — Princípio III e NFR-002.
void main() {
  Future<void> montar(
    WidgetTester t, {
    double escala = 1.0,
    Size aparelho = referencia,
    MemoraTemaId tema = MemoraTemaId.claro,
  }) async {
    vestir(t, aparelho);
    final AtalhosAplicativosController controlador =
        AtalhosAplicativosController(
          repositorio: RepositorioAtalhosAplicativos(
            assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
            consulta: ConsultaDeAplicativosSimulada(
              instalados: <String>{
                'com.whatsapp',
                'com.google.android.youtube',
              },
            ),
          ),
        );
    addTearDown(controlador.dispose);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.porId(tema),
        // Herda o MediaQuery do aparelho e troca só a escala. Um
        // `MediaQueryData` criado do zero tem tamanho 0 e desliga o "reduzir
        // movimento" com que os testes começam; com a Memora da 013, que
        // anima para sempre, o `pumpAndSettle` nunca assentava.
        home: Builder(
          builder: (BuildContext ctx) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: TextScaler.linear(escala)),
            child: TelaAtalhosAplicativos(
              controlador: controlador,
              aoVoltar: () {},
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  group('Alvo de toque e semântica — WCAG / Android', () {
    testWidgets(
      'cartões atendem a diretriz de 48 dp e possuem semântica de botão',
      (WidgetTester t) async {
        final SemanticsHandle h = t.ensureSemantics();
        await montar(t);

        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        expect(
          t.getSemantics(
            find.byKey(CartaoAtalhoAplicativo.chaveDoAplicativo('whatsapp')),
          ),
          isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
        );
        h.dispose();
      },
    );
  });

  group('Matriz de telas, temas e ampliações até 200%', () {
    for (final Size aparelho in aparelhos) {
      for (final double escala in <double>[1.0, 1.5, 2.0]) {
        testWidgets('não quebra em ${nomeDo(aparelho)}, escala $escala', (
          WidgetTester t,
        ) async {
          await montar(t, aparelho: aparelho, escala: escala);
          expect(t.takeException(), isNull);
          expect(find.byKey(TelaAtalhosAplicativos.chaveLista), findsOneWidget);
        });
      }
    }

    for (final MemoraTemaId tema in MemoraTemaId.values) {
      testWidgets('renderiza sem erros no tema ${tema.name} a 200%', (
        WidgetTester t,
      ) async {
        await montar(t, tema: tema, escala: 2.0);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('Nenhum gesto complexo — FR-030', () {
    testWidgets('a lista não usa arrastar nem pressionar e segurar', (
      WidgetTester t,
    ) async {
      await montar(t);
      final Iterable<GestureDetector> gestos = t.widgetList<GestureDetector>(
        find.byType(GestureDetector),
      );

      for (final GestureDetector g in gestos) {
        expect(g.onLongPress, isNull);
        expect(g.onHorizontalDragStart, isNull);
        expect(g.onVerticalDragStart, isNull);
      }
    });
  });
}
