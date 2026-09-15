import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/presentation/telas/tela_registro.dart';

/// Acessibilidade do registro — T070, FR-026 a FR-030.
///
/// Cobre os dois estados que a tela pode mostrar: vazio (ninguém precisou da
/// Memora ainda) e com ações registradas — cada um com seu próprio texto e
/// layout, e os dois precisam caber na ampliação de 200%.
void main() {
  Future<void> carregar(WidgetTester t) async {
    await t.pump();
    await t.pump();
  }

  Future<RepositorioAssistenteSimulado> repositorioComUmaAcao() async {
    final RepositorioAssistenteSimulado repo =
        RepositorioAssistenteSimulado(demora: Duration.zero);
    await repo.registrarAcao(
      servicoId: 'whatsapp',
      pedidoResumido: 'como mando mensagem',
    );
    return repo;
  }

  Future<void> montar(
    WidgetTester t,
    RepositorioAssistenteSimulado repo, {
    double escala = 1.0,
  }) async {
    // `MediaQuery(data: MediaQueryData(size: ...))` sozinho NAO muda as
    // restricoes reais de layout, so o valor que widgets leem via
    // `MediaQuery.of`. Isto muda a janela de fato — ver a nota equivalente em
    // `conversa_acessibilidade_test.dart`, onde a diferenca escondeu um
    // overflow real.
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(escala)),
          child: TelaRegistro(repositorio: repo),
        ),
      ),
    );
    await carregar(t);
  }

  group('Alvo de toque — FR-026', () {
    testWidgets('a tela com uma acao registrada atende a diretriz de 48 dp',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, await repositorioComUmaAcao());

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });

    testWidgets('a tela vazia tambem atende a diretriz de 48 dp',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, RepositorioAssistenteSimulado(demora: Duration.zero));

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });
  });

  group('Texto ampliado — FR-027', () {
    for (final double escala in <double>[1.0, 1.5, 2.0]) {
      testWidgets('a tela com registro nao quebra em escala $escala',
          (WidgetTester t) async {
        await montar(t, await repositorioComUmaAcao(), escala: escala);

        expect(t.takeException(), isNull);
        expect(find.byKey(TelaRegistro.chaveLista), findsOneWidget);
      });

      testWidgets('a tela vazia nao quebra em escala $escala',
          (WidgetTester t) async {
        await montar(
          t,
          RepositorioAssistenteSimulado(demora: Duration.zero),
          escala: escala,
        );

        expect(t.takeException(), isNull);
        expect(find.byKey(TelaRegistro.chaveLista), findsOneWidget);
      });
    }
  });

  group('Nenhum gesto complexo — FR-030', () {
    testWidgets('a lista nao usa arrastar nem pressionar e segurar',
        (WidgetTester t) async {
      await montar(t, await repositorioComUmaAcao());

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
