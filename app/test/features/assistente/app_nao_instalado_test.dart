import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';
import '../../suporte/aceite_em_memoria.dart';

class _ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _mensagens = <MensagemDaConversa>[];

  @override
  Future<List<MensagemDaConversa>> ler() async => _mensagens;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _mensagens = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async => _mensagens = <MensagemDaConversa>[];
}

class _RepositorioComAcaoWhatsApp implements RepositorioAssistente {
  @override
  Future<List<ServicoDoCatalogo>> catalogo() async =>
      const <ServicoDoCatalogo>[];

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) async => const AssistenteRespondeu(
    'Posso abrir o WhatsApp para você.',
    acao: AcaoAutorizada(
      servicoId: 'whatsapp-1',
      nomeExibido: 'WhatsApp',
      identificadorAndroid: 'com.whatsapp',
    ),
  );

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {}

  @override
  Future<List<AcaoRegistrada>> registro() async => const <AcaoRegistrada>[];
}

void main() {
  group('Checagem prévia de app instalado — T089 (FR-046)', () {
    testWidgets(
      'no Catálogo, app cotidiano ausente mostra que só ensina e esconde "Pedir para a Memora abrir"',
      (WidgetTester t) async {
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaCatalogo(
              repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
              categoria: CategoriaDoServico.cotidiano,
              consultaAplicativos: ConsultaDeAplicativosSimulada(),
              aoEscolher: (_) {},
              aoAbrirGuia: (_, _) {},
            ),
          ),
        );
        await t.pumpAndSettle();

        final Finder cardWhatsApp = find.ancestor(
          of: find.text('WhatsApp'),
          matching: find.byType(Cartao),
        );
        expect(cardWhatsApp, findsOneWidget);
        expect(
          find.descendant(
            of: cardWhatsApp,
            matching: find.text(TextosAssistente.soEnsinaNaoInstalado),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cardWhatsApp,
            matching: find.text('Pedir para a Memora abrir'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: cardWhatsApp,
            matching: find.text('Ensinar passo a passo'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'no Catálogo, app cotidiano instalado mantém "Eu te ensino e posso abrir" e o botão de abrir',
      (WidgetTester t) async {
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaCatalogo(
              repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
              categoria: CategoriaDoServico.cotidiano,
              consultaAplicativos: ConsultaDeAplicativosSimulada(
                instalados: const <String>{'com.whatsapp'},
              ),
              aoEscolher: (_) {},
              aoAbrirGuia: (_, _) {},
            ),
          ),
        );
        await t.pumpAndSettle();

        final Finder cardWhatsApp = find.ancestor(
          of: find.text('WhatsApp'),
          matching: find.byType(Cartao),
        );
        expect(
          find.descendant(
            of: cardWhatsApp,
            matching: find.text(TextosAssistente.descricaoAplicativos),
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
      },
    );

    test(
      'na conversa, ação autorizada para app não instalado vira orientação sem oferta de abrir',
      () async {
        final ControladorConversa controlador = ControladorConversa(
          _RepositorioComAcaoWhatsApp(),
          _ConversaEmMemoria(),
          aceite: AceiteEmMemoria(),
          consultaAplicativos: ConsultaDeAplicativosSimulada(),
          rascunhoInicial: 'abre o whatsapp',
        );
        await controlador.iniciar();

        await controlador.enviar();

        expect(controlador.acaoOferecida, isNull);
        expect(
          controlador.mensagens.last.texto,
          TextosAssistente.naoInstaladoAntesDeAbrir('WhatsApp'),
        );
        controlador.dispose();
      },
    );

    test(
      'na conversa, ação autorizada para app instalado oferece abrir normalmente',
      () async {
        final ControladorConversa controlador = ControladorConversa(
          _RepositorioComAcaoWhatsApp(),
          _ConversaEmMemoria(),
          aceite: AceiteEmMemoria(),
          consultaAplicativos: ConsultaDeAplicativosSimulada(
            instalados: const <String>{'com.whatsapp'},
          ),
          rascunhoInicial: 'abre o whatsapp',
        );
        await controlador.iniciar();

        await controlador.enviar();

        expect(controlador.acaoOferecida, isNotNull);
        expect(controlador.acaoOferecida!.nomeExibido, 'WhatsApp');
        controlador.dispose();
      },
    );
  });
}
