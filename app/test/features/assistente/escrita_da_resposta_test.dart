import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';

import '../../suporte/aceite_em_memoria.dart';

/// A espera e a escrita da resposta, na tela de conversa — T132, FR-020b.
///
/// - a espera é **só** o balão da Memora se formando: nada de frase embaixo do
///   campo, e o campo e o botão ficam no lugar, desabilitados;
/// - a resposta vai aparecendo **aos poucos**, e a mensagem final continua de
///   onde o texto que chegava estava;
/// - só a fala que **acabou de chegar** é escrita: a conversa guardada e as
///   falas antigas aparecem inteiras;
/// - com "reduzir movimento", tudo de uma vez.
///
/// O repositório é um dublê que o teste controla: cada trecho e o fim da
/// resposta chegam quando o teste manda.
class _Repositorio implements RepositorioAssistente {
  void Function(String trecho)? aoReceberTrecho;
  Completer<RespostaDaAssistente>? resposta;

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) {
    this.aoReceberTrecho = aoReceberTrecho;
    resposta = Completer<RespostaDaAssistente>();
    return resposta!.future;
  }

  @override
  Future<List<ServicoDoCatalogo>> catalogo() => throw UnimplementedError();

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) => throw UnimplementedError();

  @override
  Future<List<AcaoRegistrada>> registro() => throw UnimplementedError();
}

class _ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _guardadas;

  _ConversaEmMemoria([List<MensagemDaConversa>? iniciais])
    : _guardadas = iniciais ?? <MensagemDaConversa>[];

  @override
  Future<List<MensagemDaConversa>> ler() async => _guardadas;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _guardadas = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async => _guardadas = <MensagemDaConversa>[];
}

MensagemDaConversa _fala(AutorDaMensagem autor, String texto) =>
    MensagemDaConversa(autor: autor, texto: texto, momento: DateTime(2026));

const String _pergunta = 'como vejo a foto do meu neto';
const String _resposta =
    'Para ver a foto do seu neto, abra o **WhatsApp** e toque na conversa '
    'dele. As fotos estão lá, uma abaixo da outra, e você pode tocar em '
    'cada uma para ver maior.';
const String _respostaLimpa =
    'Para ver a foto do seu neto, abra o WhatsApp e toque na conversa '
    'dele. As fotos estão lá, uma abaixo da outra, e você pode tocar em '
    'cada uma para ver maior.';
const String _antiga =
    'Esta é uma resposta antiga da Memora, que estava guardada no aparelho '
    'e precisa aparecer inteira, sem ninguém escrevê-la de novo.';

void main() {
  late _Repositorio repositorio;
  late ControladorConversa controlador;

  Future<void> montar(
    WidgetTester t, {
    List<MensagemDaConversa>? guardadas,
    bool reduzirMovimento = false,
  }) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    repositorio = _Repositorio();
    controlador = ControladorConversa(
      repositorio,
      _ConversaEmMemoria(guardadas),
      aceite: AceiteEmMemoria(),
    );
    addTearDown(controlador.dispose);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: Builder(
          builder: (BuildContext contexto) => MediaQuery(
            data: MediaQuery.of(
              contexto,
            ).copyWith(disableAnimations: reduzirMovimento),
            child: TelaConversa(controlador: controlador),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));
  }

  /// Escreve a pergunta e toca em "Perguntar".
  Future<void> perguntar(WidgetTester t, [String texto = _pergunta]) async {
    await t.enterText(find.byKey(TelaConversa.chaveCampo), texto);
    await t.pump();
    await t.tap(find.byKey(TelaConversa.chaveEnviar));
    await t.pump();
  }

  /// A Memora termina a resposta, com o texto dado.
  Future<void> responder(WidgetTester t, String texto) async {
    repositorio.resposta!.complete(AssistenteRespondeu(texto));
    await t.pump();
    await t.pump();
  }

  /// O balão de uma das falas da Memora, o último.
  Finder ultimoBalaoDaMemora() => find
      .byWidgetPredicate(
        (Widget w) => w is BalaoDeFala && w.autor == AutorDoBalao.memora,
      )
      .last;

  /// O texto que a pessoa VÊ no último balão da Memora.
  String visivel(WidgetTester t) {
    final RichText rico = t.widget<RichText>(
      find
          .descendant(
            of: ultimoBalaoDaMemora(),
            matching: find.byType(RichText),
          )
          .last,
    );
    return rico.text.toPlainText();
  }

  group('A espera é só o balão — FR-020b', () {
    testWidgets('enquanto a Memora responde, nenhuma frase de espera '
        'embaixo do campo, e o campo e o botão ficam no lugar', (
      WidgetTester t,
    ) async {
      await montar(t);
      final Rect botaoAntes = t.getRect(find.byKey(TelaConversa.chaveEnviar));
      final Rect campoAntes = t.getRect(find.byKey(TelaConversa.chaveCampo));

      await perguntar(t);
      expect(controlador.respondendo, isTrue);

      // A espera é o balão da Memora se formando — e só ele.
      expect(find.byType(Carregando), findsNothing);
      expect(find.textContaining('pensando'), findsNothing);
      expect(
        find.text('• • •  ${BalaoDeFala.textoEscrevendo}'),
        findsOneWidget,
      );

      // O campo e o botão não somem nem mudam de lugar: a faixa não pula.
      expect(find.byKey(TelaConversa.chaveEnviar), findsOneWidget);
      expect(
        t.widget<BotaoPrimario>(find.byKey(TelaConversa.chaveEnviar)).aoTocar,
        isNull,
        reason: 'o botão fica desabilitado enquanto ela responde',
      );
      expect(
        t.widget<TextField>(
          find.descendant(
            of: find.byKey(TelaConversa.chaveCampo),
            matching: find.byType(TextField),
          ),
        ).enabled,
        isFalse,
      );
      expect(t.getRect(find.byKey(TelaConversa.chaveEnviar)), botaoAntes);
      expect(t.getRect(find.byKey(TelaConversa.chaveCampo)), campoAntes);

      await responder(t, 'Ok.');
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('o leitor de tela é avisado de que a Memora está escrevendo', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t);
      await perguntar(t);

      expect(
        find.bySemanticsLabel('Memora está ${BalaoDeFala.textoEscrevendo}'),
        findsOneWidget,
      );

      await responder(t, 'Ok.');
      await t.pump(const Duration(seconds: 5));
      h.dispose();
    });
  });

  group('A resposta aparece aos poucos — FR-020b', () {
    testWidgets('a mensagem final vai aparecendo letra a letra, até o fim', (
      WidgetTester t,
    ) async {
      await montar(t);
      await perguntar(t);
      await responder(t, _resposta);

      await t.pump(const Duration(milliseconds: 300));
      final String noMeio = visivel(t);
      expect(noMeio, isNotEmpty);
      expect(
        noMeio.length,
        lessThan(_respostaLimpa.length),
        reason: 'no meio da escrita só há parte do texto',
      );
      expect(_respostaLimpa, startsWith(noMeio));

      await t.pump(const Duration(seconds: 10));
      expect(visivel(t), _respostaLimpa);
      expect(
        t.binding.transientCallbackCount,
        0,
        reason: 'terminada a escrita, nenhum relógio fica ligado',
      );
    });

    testWidgets('o texto que chega aos pedaços continua, na mensagem final, '
        'de onde estava — sem recomeçar nem piscar', (WidgetTester t) async {
      await montar(t);
      await perguntar(t);

      repositorio.aoReceberTrecho!('Para ver a foto do seu neto, ');
      await t.pump();
      repositorio.aoReceberTrecho!('abra o **WhatsApp** e toque na conversa ');
      await t.pump(const Duration(milliseconds: 400));
      final String jaEscrito = visivel(t);
      expect(jaEscrito, isNotEmpty);

      // A resposta termina: a mensagem final entra na lista no lugar do texto
      // que chegava.
      await responder(t, _resposta);
      expect(
        visivel(t).length,
        greaterThanOrEqualTo(jaEscrito.length),
        reason: 'a escrita continua, não volta ao zero',
      );
      expect(_respostaLimpa, startsWith(visivel(t)));
      expect(
        find.byType(BalaoDeFala).evaluate().where(
          (Element e) => (e.widget as BalaoDeFala).autor == AutorDoBalao.memora,
        ),
        hasLength(1),
        reason: 'um balão só: o texto que chegava virou a mensagem',
      );

      await t.pump(const Duration(seconds: 10));
      expect(visivel(t), _respostaLimpa);
    });

    testWidgets('o leitor de tela recebe a fala inteira desde o primeiro '
        'quadro', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t);
      await perguntar(t);
      await responder(t, _resposta);
      await t.pump(const Duration(milliseconds: 100));

      expect(
        visivel(t).length,
        lessThan(_respostaLimpa.length),
        reason: 'sanidade: ainda está escrevendo',
      );
      expect(
        find.bySemanticsLabel('Memora disse: $_respostaLimpa'),
        findsOneWidget,
      );
      await t.pump(const Duration(seconds: 10));
      h.dispose();
    });

    testWidgets('a lista acompanha o texto que cresce: o fim fica à vista', (
      WidgetTester t,
    ) async {
      // Resposta comprida de verdade, para a lista precisar rolar.
      final String longa = List<String>.filled(
        14,
        'Toque em **Fotos**, depois na foto que você quer ver.',
      ).join(' ');
      await montar(t);
      await perguntar(t);
      await responder(t, longa);

      final ScrollableState rolagem = t.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        ).first,
      );
      for (int i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 200));
        await t.pump();
        expect(
          rolagem.position.pixels,
          closeTo(rolagem.position.maxScrollExtent, 2.0),
          reason: 'quadro $i: a lista fica no fim enquanto o texto cresce',
        );
      }
      await t.pump(const Duration(seconds: 20));
      await t.pump();
      expect(
        rolagem.position.pixels,
        closeTo(rolagem.position.maxScrollExtent, 2.0),
      );
    });

    testWidgets('a próxima pergunta não faz a resposta anterior ser escrita '
        'de novo', (WidgetTester t) async {
      await montar(t);
      await perguntar(t);
      await responder(t, _resposta);
      await t.pump(const Duration(seconds: 10));

      await perguntar(t, 'e como volto');
      // A Memora está respondendo à segunda: a primeira resposta segue inteira.
      final Finder primeira = find
          .byWidgetPredicate(
            (Widget w) =>
                w is BalaoDeFala &&
                w.autor == AutorDoBalao.memora &&
                w.texto == _resposta,
          );
      expect(primeira, findsOneWidget);
      expect(
        t
            .widget<RichText>(
              find
                  .descendant(of: primeira, matching: find.byType(RichText))
                  .last,
            )
            .text
            .toPlainText(),
        _respostaLimpa,
      );
      expect(t.widget<BalaoDeFala>(primeira).escreverAosPoucos, isFalse);

      await responder(t, 'Toque no botão de voltar.');
      await t.pump(const Duration(seconds: 10));
    });
  });

  group('Só a fala que acabou de chegar é escrita', () {
    testWidgets('a conversa guardada aparece inteira, de uma vez, sem '
        'relógio', (WidgetTester t) async {
      await montar(
        t,
        guardadas: <MensagemDaConversa>[
          _fala(AutorDaMensagem.pessoa, 'oi'),
          _fala(AutorDaMensagem.memora, _antiga),
        ],
      );

      expect(visivel(t), _antiga, reason: 'inteira, já no primeiro quadro');
      expect(t.binding.transientCallbackCount, 0);
    });

    testWidgets('a falha que devolve a pergunta ao campo não faz uma fala '
        'antiga recomeçar a ser escrita', (WidgetTester t) async {
      await montar(
        t,
        guardadas: <MensagemDaConversa>[
          _fala(AutorDaMensagem.pessoa, 'oi'),
          _fala(AutorDaMensagem.memora, _antiga),
        ],
      );
      await perguntar(t);
      repositorio.resposta!.complete(
        const AssistenteFalhou(FalhaDaAssistente.semConexao),
      );
      await t.pump();
      await t.pump();

      // A pergunta voltou ao campo, e a última fala da conversa é a antiga.
      expect(controlador.mensagens.last.texto, _antiga);
      expect(visivel(t), _antiga, reason: 'inteira, e não a partir do zero');
    });
  });

  group('Reduzir movimento — FR-020b e FR-027', () {
    testWidgets('a resposta aparece inteira, de uma vez', (
      WidgetTester t,
    ) async {
      await montar(t, reduzirMovimento: true);
      await perguntar(t);
      await responder(t, _resposta);

      expect(visivel(t), _respostaLimpa, reason: 'no primeiro quadro');
    });

    testWidgets('o texto que chega aos pedaços também aparece de uma vez', (
      WidgetTester t,
    ) async {
      await montar(t, reduzirMovimento: true);
      await perguntar(t);
      repositorio.aoReceberTrecho!('Para ver a foto, abra o **WhatsApp**.');
      await t.pump();
      expect(visivel(t), 'Para ver a foto, abra o WhatsApp.');

      await responder(t, 'Para ver a foto, abra o **WhatsApp**.');
      expect(visivel(t), 'Para ver a foto, abra o WhatsApp.');
    });
  });
}
