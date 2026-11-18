import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/abridor_de_aplicativo.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/features/atalhos_aplicativos/data/repositorio_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/controllers/atalhos_aplicativos_controller.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/telas/tela_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/presentation/widgets/cartao_atalho_aplicativo.dart';
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
  group('Separação clara entre Catálogo educativo e Tela de abertura direta', () {
    testWidgets(
      'cartão do catálogo mantém apenas ensino e pedido à Memora (sem dois botões de abrir)',
      (WidgetTester tester) async {
        int navegacoes = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaCatalogo(
              repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
              categoria: CategoriaDoServico.cotidiano,
              consultaAplicativos: ConsultaDeAplicativosSimulada(
                instalados: const <String>{'com.whatsapp'},
              ),
              aoAbrirAtalhosDiretos: () => navegacoes++,
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
        expect(
          find.descendant(
            of: cardWhatsApp,
            matching: find.text('Abrir agora'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: cardWhatsApp,
            matching: find.text('Baixar na Play Store'),
          ),
          findsNothing,
        );

        final Finder botaoEntradaDireta = find.byKey(
          TelaCatalogo.chaveAtalhosDiretos,
        );
        expect(botaoEntradaDireta, findsOneWidget);
        expect(
          find.text(TextosAtalhosAplicativos.botaoVerAtalhosDiretos),
          findsOneWidget,
        );
        await tester.tap(botaoEntradaDireta);
        expect(navegacoes, 1);
      },
    );

    testWidgets(
      'tela dedicada abre app confirmado diretamente sem gerar Registro (003/D1)',
      (WidgetTester tester) async {
        final _RepositorioEspiaoRegistro repo = _RepositorioEspiaoRegistro();
        final AbridorDeAplicativoSimulado abridor =
            AbridorDeAplicativoSimulado();
        final AtalhosAplicativosController controlador =
            AtalhosAplicativosController(
              repositorio: RepositorioAtalhosAplicativos(
                assistente: repo,
                consulta: ConsultaDeAplicativosSimulada(
                  instalados: const <String>{'com.whatsapp'},
                ),
              ),
              abridor: abridor,
            );
        addTearDown(controlador.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaAtalhosAplicativos(controlador: controlador),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(TextosAtalhosAplicativos.orientacaoTopo),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(CartaoAtalhoAplicativo.chaveDoAplicativo('whatsapp')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(DialogoConfirmacaoAbertura.chaveDialogo),
          findsOneWidget,
        );
        await tester.tap(
          find.text(TextosAtalhosAplicativos.botaoConfirmarAbertura),
        );
        await tester.pumpAndSettle();

        expect(abridor.abertos, equals(<String>['com.whatsapp']));
        expect(repo.chamadasRegistrarAcao, 0);
      },
    );

    testWidgets(
      'tela dedicada oferece Play Store para app não instalado do catálogo do servidor',
      (WidgetTester tester) async {
        final List<Uri> urls = <Uri>[];
        final AtalhosAplicativosController controlador =
            AtalhosAplicativosController(
              repositorio: RepositorioAtalhosAplicativos(
                assistente: RepositorioAssistenteSimulado(
                  demora: Duration.zero,
                ),
                consulta: ConsultaDeAplicativosSimulada(),
              ),
              abridor: AbridorDeAplicativoSimulado(),
              abridorDeUrl: (Uri uri) async {
                urls.add(uri);
                return true;
              },
            );
        addTearDown(controlador.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaAtalhosAplicativos(controlador: controlador),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(CartaoAtalhoAplicativo.chaveDoAplicativo('whatsapp')),
        );
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
      'botão Abrir um aplicativo direto fica oculto em Serviços sociais',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaCatalogo(
              repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
              categoria: CategoriaDoServico.sensivel,
              consultaAplicativos: ConsultaDeAplicativosSimulada(
                instalados: const <String>{'com.whatsapp'},
              ),
              aoAbrirAtalhosDiretos: () {},
              aoEscolher: (_) {},
              aoAbrirGuia: (_, _) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(TelaCatalogo.chaveAtalhosDiretos), findsNothing);

        await tester.tap(find.text('Apps do celular'));
        await tester.pumpAndSettle();

        expect(find.byKey(TelaCatalogo.chaveAtalhosDiretos), findsOneWidget);
      },
    );
  });
}
