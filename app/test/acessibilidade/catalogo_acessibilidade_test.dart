import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';

import '../suporte/aparelhos.dart';

/// Acessibilidade do catálogo — T070, FR-026 a FR-030.
///
/// Cobre as duas categorias (sensível e cotidiana): são a mesma tela
/// parametrizada, mas a explicação extra que aparece só para os sensíveis
/// (FR-042) também precisa caber na ampliação de 200%.
void main() {
  /// Espera o `FutureBuilder` manual da tela carregar, sem `pumpAndSettle` —
  /// o `Carregando` inicial anima sem parar e travaria a espera.
  Future<void> carregar(WidgetTester t) async {
    await t.pump();
    await t.pump();
  }

  Future<void> montar(
    WidgetTester t,
    CategoriaDoServico categoria, {
    double escala = 1.0,
    Size aparelho = referencia,
  }) async {
    // `MediaQuery(data: MediaQueryData(size: ...))` sozinho NAO muda as
    // restricoes reais de layout, so o valor que widgets leem via
    // `MediaQuery.of`. Isto muda a janela de fato — ver a nota equivalente em
    // `conversa_acessibilidade_test.dart`, onde a diferenca escondeu um
    // overflow real.
    t.view.physicalSize = aparelho;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(escala)),
          child: TelaCatalogo(
            repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
            categoria: categoria,
          ),
        ),
      ),
    );
    await carregar(t);
  }

  group('Alvo de toque — FR-026', () {
    for (final CategoriaDoServico categoria in CategoriaDoServico.values) {
      testWidgets('categoria ${categoria.name} atende a diretriz de 48 dp',
          (WidgetTester t) async {
        final SemanticsHandle h = t.ensureSemantics();
        await montar(t, categoria);

        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        h.dispose();
      });
    }
  });

  group('Texto ampliado — FR-027', () {
    // A matriz de aparelhos entrou na revisao da PR #27: ate entao tudo rodava
    // num 390x844, e foi assim que o overflow da tela de conversa passou.
    for (final Size aparelho in aparelhos) {
      for (final double escala in <double>[1.0, 1.5, 2.0]) {
        testWidgets(
            'servicos sensiveis, com a explicacao extra da FR-042, nao '
            'quebram em ${nomeDo(aparelho)}, escala $escala',
            (WidgetTester t) async {
          await montar(t, CategoriaDoServico.sensivel,
              escala: escala, aparelho: aparelho);

          expect(t.takeException(), isNull);
          expect(find.byKey(TelaCatalogo.chaveLista), findsOneWidget);
        });

        testWidgets(
            'servicos cotidianos nao quebram em ${nomeDo(aparelho)}, '
            'escala $escala', (WidgetTester t) async {
          await montar(t, CategoriaDoServico.cotidiano,
              escala: escala, aparelho: aparelho);

          expect(t.takeException(), isNull);
          expect(find.byKey(TelaCatalogo.chaveLista), findsOneWidget);
        });
      }
    }
  });

  group('Nenhum gesto complexo — FR-030', () {
    testWidgets('a lista nao usa arrastar nem pressionar e segurar',
        (WidgetTester t) async {
      await montar(t, CategoriaDoServico.cotidiano);

      final Iterable<GestureDetector> gestos =
          t.widgetList<GestureDetector>(find.byType(GestureDetector));

      for (final GestureDetector g in gestos) {
        expect(g.onLongPress, isNull);
        expect(g.onHorizontalDragStart, isNull);
        expect(g.onVerticalDragStart, isNull);
      }
    });
  });
}
