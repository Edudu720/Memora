import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/atalhos_aplicativos/data/repositorio_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/domain/entidades/atalho_aplicativo.dart';
import 'package:memora/features/atalhos_aplicativos/domain/entidades/categoria_aplicativo.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/controllers/atalhos_aplicativos_controller.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/cartao_atalho_aplicativo.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/dialogo_instalacao_play_store.dart';
import 'package:memora/l10n/textos_atalhos_aplicativos.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

void main() {
  group('Fluxo de orientação à Play Store para app não instalado — US3', () {
    late List<Uri> urlsAbertas;
    late bool urlDeveAbrir;
    late AtalhosAplicativosController controlador;

    setUp(() {
      urlsAbertas = <Uri>[];
      urlDeveAbrir = true;
      controlador = AtalhosAplicativosController(
        repositorio: RepositorioAtalhosAplicativos(
          assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
          consulta: ConsultaDeAplicativosSimulada(),
        ),
        abridorDeUrl: (Uri uri) async {
          urlsAbertas.add(uri);
          return urlDeveAbrir;
        },
      );
    });

    tearDown(() => controlador.dispose());

    Widget montar() {
      return MaterialApp(
        theme: TemasMemora.claro,
        home: TelaAtalhosAplicativos(controlador: controlador),
      );
    }

    testWidgets('tocar em app não instalado pede confirmação antes de abrir loja', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar());
      await tester.pumpAndSettle();

      final Finder instagram = find.byKey(
        CartaoAtalhoAplicativo.chaveDoAplicativo('instagram'),
      );
      await tester.ensureVisible(instagram);
      await tester.tap(instagram);
      await tester.pumpAndSettle();

      expect(
        find.byKey(DialogoInstalacaoPlayStore.chaveDialogo),
        findsOneWidget,
      );
      expect(
        find.text(
          TextosAtalhosAplicativos.tituloConfirmarInstalacao('Instagram'),
        ),
        findsOneWidget,
      );
      expect(urlsAbertas, isEmpty);

      await tester.tap(
        find.text(TextosAtalhosAplicativos.botaoCancelarInstalacao),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(DialogoInstalacaoPlayStore.chaveDialogo), findsNothing);
      expect(urlsAbertas, isEmpty);
    });

    testWidgets('confirmar ida à Play Store dispara URI oficial do pacote', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(montar());
      await tester.pumpAndSettle();

      final Finder instagram = find.byKey(
        CartaoAtalhoAplicativo.chaveDoAplicativo('instagram'),
      );
      await tester.ensureVisible(instagram);
      await tester.tap(instagram);
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(TextosAtalhosAplicativos.botaoConfirmarInstalacao),
      );
      await tester.pumpAndSettle();

      expect(
        urlsAbertas,
        equals(<Uri>[
          Uri.parse('market://details?id=com.instagram.android'),
        ]),
      );
    });

    testWidgets('exibe aviso amigável se a loja oficial não puder ser aberta', (
      WidgetTester tester,
    ) async {
      urlDeveAbrir = false;

      await tester.pumpWidget(montar());
      await tester.pumpAndSettle();

      final Finder instagram = find.byKey(
        CartaoAtalhoAplicativo.chaveDoAplicativo('instagram'),
      );
      await tester.ensureVisible(instagram);
      await tester.tap(instagram);
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(TextosAtalhosAplicativos.botaoConfirmarInstalacao),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(TextosAtalhosAplicativos.erroAoAbrirLoja('Instagram')),
        findsOneWidget,
      );
    });

    test('recusa abrir pacote desconhecido fora do catálogo homologado', () async {
      await controlador.carregar();

      const AtalhoAplicativo suspeito = AtalhoAplicativo(
        chave: 'suspeito',
        nomeExibido: 'Suspeito',
        pacoteAndroid: 'com.malware.fake',
        descricaoCurta: 'Falso',
        categoria: CategoriaAplicativo.comunicacao,
      );

      final bool abriuApp = await controlador.abrirAplicativo(suspeito);
      final bool abriuLoja = await controlador.abrirNaPlayStore(suspeito);

      expect(abriuApp, isFalse);
      expect(abriuLoja, isFalse);
      expect(urlsAbertas, isEmpty);
    });
  });
}
