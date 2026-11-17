import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/abridor_de_aplicativo.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/dialogo_confirmacao_abertura.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/dialogo_instalacao_play_store.dart';
import 'package:memora/l10n/textos_atalhos_aplicativos.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

class _RepositorioEspiaoRegistro implements RepositorioAssistente {
  final RepositorioAssistente _base = RepositorioAssistenteSimulado(
    demora: Duration.zero,
  );
  int chamadasRegistrarAcao = 0;

  @override
  Future<List<ServicoDoCatalogo>> catalogo() => _base.catalogo();

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) => _base.conversar(
    mensagem: mensagem,
    historico: historico,
    aoReceberTrecho: aoReceberTrecho,
    aoCriarCancelamento: aoCriarCancelamento,
  );

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {
    chamadasRegistrarAcao++;
  }

  @override
  Future<List<AcaoRegistrada>> registro() => _base.registro();
}

void main() {
  group('Convivência da Feature 015 com o TelaCatalogo do servidor', () {
    testWidgets(
      'app instalado oferece Abrir agora, confirma saída, abre nativo e não gera Registro',
      (WidgetTester tester) async {
        final _RepositorioEspiaoRegistro repo = _RepositorioEspiaoRegistro();
        final AbridorDeAplicativoSimulado abridor =
            AbridorDeAplicativoSimulado();

        await tester.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaCatalogo(
              repositorio: repo,
              categoria: CategoriaDoServico.cotidiano,
              consultaAplicativos: ConsultaDeAplicativosSimulada(
                instalados: const <String>{'com.whatsapp'},
              ),
              abridor: abridor,
              aoEscolher: (_) {},
              aoPedirParaAbrir: (_) {},
              aoAbrirGuia: (_, _) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Finder cardWhatsApp = find.ancestor(
          of: find.text('WhatsApp'),
          matching: find.byType(Cartao),
        );
        expect(
          find.descendant(
            of: cardWhatsApp,
            matching: find.text('Ensinar passo a passo'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cardWhatsApp,
            matching: find.text('Pedir para a Memora abrir'),
          ),
          findsOneWidget,
        );

        final Finder botaoAbrir = find.byKey(
          TelaCatalogo.chaveAbrirDireto('WhatsApp'),
        );
        expect(botaoAbrir, findsOneWidget);

        await tester.ensureVisible(botaoAbrir);
        await tester.tap(botaoAbrir);
        await tester.pumpAndSettle();

        expect(
          find.byKey(DialogoConfirmacaoAbertura.chaveDialogo),
          findsOneWidget,
        );
        expect(abridor.abertos, isEmpty);

        await tester.tap(
          find.text(TextosAtalhosAplicativos.botaoConfirmarAbertura),
        );
        await tester.pumpAndSettle();

        expect(abridor.abertos, equals(<String>['com.whatsapp']));
        expect(
          repo.chamadasRegistrarAcao,
          0,
          reason:
              'Abertura manual direta não passa pela IA e não gera Registro (003/D1).',
        );
      },
    );

    testWidgets(
      'app cotidiano ausente oferece Baixar na Play Store com confirmação oficial',
      (WidgetTester tester) async {
        final List<Uri> urls = <Uri>[];

        await tester.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaCatalogo(
              repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
              categoria: CategoriaDoServico.cotidiano,
              consultaAplicativos: ConsultaDeAplicativosSimulada(),
              abridor: AbridorDeAplicativoSimulado(),
              abridorDeUrl: (Uri uri) async {
                urls.add(uri);
                return true;
              },
              aoEscolher: (_) {},
              aoAbrirGuia: (_, _) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Finder botaoLoja = find.byKey(
          TelaCatalogo.chaveBaixarNaLoja('WhatsApp'),
        );
        expect(botaoLoja, findsOneWidget);

        await tester.ensureVisible(botaoLoja);
        await tester.tap(botaoLoja);
        await tester.pumpAndSettle();

        expect(
          find.byKey(DialogoInstalacaoPlayStore.chaveDialogo),
          findsOneWidget,
        );
        await tester.tap(
          find.text(TextosAtalhosAplicativos.botaoConfirmarInstalacao),
        );
        await tester.pumpAndSettle();

        expect(
          urls,
          equals(<Uri>[Uri.parse('market://details?id=com.whatsapp')]),
        );
      },
    );

    testWidgets(
      'serviços sociais não exibem atalhos diretos nem botões Abrir agora ou Play Store',
      (WidgetTester tester) async {
        int abriuAtalhos = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaCatalogo(
              repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
              categoria: CategoriaDoServico.sensivel,
              consultaAplicativos: ConsultaDeAplicativosSimulada(
                instalados: const <String>{'com.whatsapp'},
              ),
              abridor: AbridorDeAplicativoSimulado(),
              aoAbrirAtalhosDiretos: () => abriuAtalhos++,
              aoEscolher: (_) {},
              aoAbrirGuia: (_, _) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(TelaCatalogo.chaveAtalhosDiretos), findsNothing);
        expect(
          find.text(TextosAtalhosAplicativos.botaoAbrirAgora),
          findsNothing,
        );
        expect(
          find.text(TextosAtalhosAplicativos.botaoBaixarPlayStore),
          findsNothing,
        );

        await tester.tap(find.text('Apps do celular'));
        await tester.pumpAndSettle();

        expect(find.byKey(TelaCatalogo.chaveAtalhosDiretos), findsOneWidget);
        await tester.tap(find.byKey(TelaCatalogo.chaveAtalhosDiretos));
        expect(abriuAtalhos, 1);
      },
    );
  });
}
