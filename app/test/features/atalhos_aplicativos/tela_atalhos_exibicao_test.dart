import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/atalhos_aplicativos/data/catalogo_aplicativos_comuns.dart';
import 'package:memora/features/atalhos_aplicativos/data/repositorio_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/domain/entidades/atalho_aplicativo.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/controllers/atalhos_aplicativos_controller.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/cartao_atalho_aplicativo.dart';
import 'package:memora/l10n/textos_atalhos_aplicativos.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

void main() {
  Widget montarTela(
    AtalhosAplicativosController controlador, {
    VoidCallback? aoVoltar,
  }) {
    return MaterialApp(
      theme: TemasMemora.claro,
      home: TelaAtalhosAplicativos(
        controlador: controlador,
        aoVoltar: aoVoltar,
      ),
    );
  }

  group('TelaAtalhosAplicativos — US1 exibição completa', () {
    testWidgets('exibe indicador de carregamento enquanto consulta e depois mostra os 7 aplicativos', (
      WidgetTester tester,
    ) async {
      final ConsultaDeAplicativosSimulada consulta =
          ConsultaDeAplicativosSimulada(
            instalados: <String>{
              'com.whatsapp',
              'com.google.android.youtube',
            },
          );
      final AtalhosAplicativosController controlador =
          AtalhosAplicativosController(
            repositorio: RepositorioAtalhosAplicativos(consulta: consulta),
          );
      addTearDown(controlador.dispose);

      await tester.pumpWidget(montarTela(controlador));
      await tester.pumpAndSettle();

      expect(find.text(TextosAtalhosAplicativos.tituloTela), findsOneWidget);
      expect(find.byKey(TelaAtalhosAplicativos.chaveLista), findsOneWidget);
      expect(find.byType(CartaoAtalhoAplicativo), findsNWidgets(7));

      for (final AtalhoAplicativo app in CatalogoAplicativosComuns.todos) {
        expect(
          find.byKey(CartaoAtalhoAplicativo.chaveDoAplicativo(app.chave)),
          findsOneWidget,
        );
        expect(find.text(app.nomeExibido), findsOneWidget);
      }

      // Status dos instalados vs não instalados (2 instalados, 5 não instalados)
      expect(
        find.text(TextosAtalhosAplicativos.statusInstalado),
        findsNWidgets(2),
      );
      expect(
        find.text(TextosAtalhosAplicativos.statusNaoInstalado),
        findsNWidgets(5),
      );
    });

    testWidgets('não exibe nenhum serviço social ou governamental na tela', (
      WidgetTester tester,
    ) async {
      final AtalhosAplicativosController controlador =
          AtalhosAplicativosController(
            repositorio: const RepositorioAtalhosAplicativos(),
          );
      addTearDown(controlador.dispose);

      await tester.pumpWidget(montarTela(controlador));
      await tester.pumpAndSettle();

      for (final String termo in <String>[
        'Gov.br',
        'Meu INSS',
        'FGTS',
        'Poupatempo',
        'Serasa',
        'Correios',
        'e-Título',
      ]) {
        expect(find.textContaining(termo), findsNothing);
      }
    });

    testWidgets('botão Voltar da barra superior aciona callback aoVoltar', (
      WidgetTester tester,
    ) async {
      int voltou = 0;
      final AtalhosAplicativosController controlador =
          AtalhosAplicativosController(
            repositorio: const RepositorioAtalhosAplicativos(),
          );
      addTearDown(controlador.dispose);

      await tester.pumpWidget(
        montarTela(controlador, aoVoltar: () => voltou++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CabecalhoDeTela.chaveVoltar));
      await tester.pump();
      expect(voltou, 1);
    });
  });
}
