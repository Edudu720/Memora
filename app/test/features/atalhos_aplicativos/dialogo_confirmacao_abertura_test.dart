import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/abridor_de_aplicativo.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/atalhos_aplicativos/data/repositorio_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/controllers/atalhos_aplicativos_controller.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/cartao_atalho_aplicativo.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/dialogo_confirmacao_abertura.dart';
import 'package:memora/l10n/textos_atalhos_aplicativos.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

void main() {
  group('Fluxo de confirmação e abertura de app instalado — US2', () {
    late ConsultaDeAplicativosSimulada consulta;
    late AbridorDeAplicativoSimulado abridor;
    late AtalhosAplicativosController controlador;

    setUp(() {
      consulta = ConsultaDeAplicativosSimulada(
        instalados: <String>{'com.whatsapp'},
      );
      abridor = AbridorDeAplicativoSimulado();
      controlador = AtalhosAplicativosController(
        repositorio: RepositorioAtalhosAplicativos(
          assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
          consulta: consulta,
        ),
        abridor: abridor,
      );
    });

    tearDown(() => controlador.dispose());

    Widget montar() {
      return MaterialApp(
        theme: TemasMemora.claro,
        home: TelaAtalhosAplicativos(controlador: controlador),
      );
    }

    testWidgets('tocar em app instalado pede confirmação antes de abrir', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CartaoAtalhoAplicativo.chaveDoAplicativo('whatsapp')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(DialogoConfirmacaoAbertura.chaveDialogo),
        findsOneWidget,
      );
      expect(
        find.text(TextosAtalhosAplicativos.tituloConfirmarAbertura('WhatsApp')),
        findsOneWidget,
      );
      expect(
        abridor.abertos,
        isEmpty,
        reason: 'Nunca abrir aplicativo externo sem confirmação (Princípio II).',
      );

      // Cancelar mantém na tela sem disparar abertura
      await tester.tap(
        find.text(TextosAtalhosAplicativos.botaoCancelarAbertura),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(DialogoConfirmacaoAbertura.chaveDialogo), findsNothing);
      expect(abridor.abertos, isEmpty);
    });

    testWidgets('confirmar abertura invoca AbridorDeAplicativo com pacote correto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CartaoAtalhoAplicativo.chaveDoAplicativo('whatsapp')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(TextosAtalhosAplicativos.botaoConfirmarAbertura),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(DialogoConfirmacaoAbertura.chaveDialogo), findsNothing);
      expect(abridor.abertos, equals(<String>['com.whatsapp']));
    });

    testWidgets('exibe aviso amigável quando o sistema falha ao abrir o app', (
      WidgetTester tester,
    ) async {
      abridor.falharNaProxima = true;

      await tester.pumpWidget(montar());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(CartaoAtalhoAplicativo.chaveDoAplicativo('whatsapp')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(TextosAtalhosAplicativos.botaoConfirmarAbertura),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(TextosAtalhosAplicativos.erroAoAbrirAplicativo('WhatsApp')),
        findsOneWidget,
      );
    });
  });
}
