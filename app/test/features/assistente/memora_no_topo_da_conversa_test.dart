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
import '../../suporte/aparelhos.dart';
import '../../suporte/movimento.dart';

/// A Memora pequena no topo da conversa — T059, US4, FR-025 e FR-042.
///
/// - **uma só**, na barra do topo (que já existe: não toma altura da lista) e
///   nenhuma ao lado dos balões;
/// - **falando** enquanto a resposta aparece letra a letra, e **de volta ao
///   repouso** quando termina;
/// - parada em repouso com "reduzir movimento" e **decorativa** para o leitor
///   de tela.
class _Repositorio implements RepositorioAssistente {
  void Function(String trecho)? aoReceberTrecho;
  Completer<RespostaDaAssistente>? resposta;

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
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

const String _resposta =
    'Para ver a foto do seu neto, abra o **WhatsApp** e toque na conversa '
    'dele. As fotos estão lá, uma abaixo da outra, e você pode tocar em '
    'cada uma para ver maior.';
const String _antiga =
    'Esta é uma resposta antiga da Memora, que estava guardada no aparelho.';

void main() {
  movimentoLiberado();

  late _Repositorio repositorio;
  late ControladorConversa controlador;

  Future<void> montar(
    WidgetTester t, {
    List<MensagemDaConversa>? guardadas,
    bool reduzirMovimento = false,
    Size tela = referencia,
    double escala = 1.0,
  }) async {
    t.view.physicalSize = tela;
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
            data: MediaQuery.of(contexto).copyWith(
              disableAnimations: reduzirMovimento,
              textScaler: TextScaler.linear(escala),
            ),
            child: TelaConversa(controlador: controlador),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));
  }

  Future<void> perguntar(WidgetTester t) async {
    await t.enterText(
      find.byKey(TelaConversa.chaveCampo),
      'como vejo a foto do meu neto',
    );
    await t.pump();
    await t.tap(find.byKey(TelaConversa.chaveEnviar));
    await t.pump();
  }

  Future<void> responder(WidgetTester t, String texto) async {
    repositorio.resposta!.complete(AssistenteRespondeu(texto));
    await t.pump();
    await t.pump();
  }

  /// Deixa a escrita acabar. O aviso de "parou" chega depois do quadro em que
  /// a última letra entrou, e a Memora o mostra no quadro seguinte.
  Future<void> terminarAEscrita(WidgetTester t) async {
    await t.pump(const Duration(seconds: 10));
    await t.pump();
  }

  /// A Memora do topo. Antes da primeira mensagem há também o rosto do
  /// convite (FR-042, rev. 2026-11-18), que é a voz dela e não conta.
  Finder doTopo() => find.descendant(
    of: find.byType(BarraSuperior),
    matching: find.byType(MemoraAnimada),
  );

  MemoraAnimada memora(WidgetTester t) => t.widget<MemoraAnimada>(doTopo());

  group('Uma Memora só, pequena e no topo — FR-025, FR-042', () {
    testWidgets('na barra do topo, acima da lista, e só uma fora do convite', (
      WidgetTester t,
    ) async {
      await montar(t);

      expect(doTopo(), findsOneWidget);
      // Fora o rosto do convite, não há outra.
      final Finder doConvite = find.descendant(
        of: find.byKey(TelaConversa.chaveConvite),
        matching: find.byType(MemoraAnimada),
      );
      expect(doConvite, findsOneWidget);
      expect(find.byType(MemoraAnimada), findsNWidgets(2));
      // Acima das mensagens: não ocupa o espaço delas.
      expect(
        t.getRect(doTopo()).bottom,
        lessThanOrEqualTo(t.getTopLeft(find.byType(ListView).first).dy),
      );
      // Pequena: no máximo o alvo mínimo de toque.
      expect(
        t.getSize(doTopo()).height,
        lessThanOrEqualTo(MemoraDimensoes.alvoMinimo),
      );
    });

    testWidgets('o convite, antes da primeira mensagem, leva o rosto dela '
        '(FR-042, rev. 2026-11-18)', (WidgetTester t) async {
      await montar(t);

      final BalaoDeFala convite = t.widget<BalaoDeFala>(
        find.byKey(TelaConversa.chaveConvite),
      );
      expect(convite.autor, AutorDoBalao.memora);
      expect(convite.comRosto, isTrue);
      expect(
        find.descendant(
          of: find.byKey(TelaConversa.chaveConvite),
          matching: find.byType(MemoraAnimada),
        ),
        findsOneWidget,
      );
    });

    testWidgets('continua uma só depois de várias falas, e nenhum balão traz '
        'rosto', (WidgetTester t) async {
      await montar(
        t,
        guardadas: <MensagemDaConversa>[
          MensagemDaConversa(
            autor: AutorDaMensagem.pessoa,
            texto: 'oi',
            momento: DateTime(2026),
          ),
          MensagemDaConversa(
            autor: AutorDaMensagem.memora,
            texto: _antiga,
            momento: DateTime(2026),
          ),
        ],
      );
      await perguntar(t);
      await responder(t, 'Ok.');
      await t.pump(const Duration(seconds: 5));

      expect(find.byType(MemoraAnimada), findsOneWidget);
      expect(find.byType(BalaoDeFala), findsWidgets);
      for (final Element balao in find.byType(BalaoDeFala).evaluate()) {
        final Finder dele = find.byWidget(balao.widget);
        expect(
          find.descendant(of: dele, matching: find.byType(MemoraPersonagem)),
          findsNothing,
        );
        expect(
          find.descendant(of: dele, matching: find.byType(MemoraAnimada)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: dele,
            matching: find.byIcon(Icons.person_rounded),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('a explicação do aceite não traz uma segunda Memora', (
      WidgetTester t,
    ) async {
      t.view.physicalSize = referencia;
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final ControladorConversa c = ControladorConversa(
        _Repositorio(),
        _ConversaEmMemoria(),
        aceite: AceiteEmMemoria(aceito: false),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaConversa(controlador: c),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));

      expect(find.byKey(TelaConversa.chaveAceite), findsOneWidget);
      expect(find.byType(MemoraAnimada), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TelaConversa.chaveAceite),
          matching: find.byType(MemoraAnimada),
        ),
        findsNothing,
      );
    });

    testWidgets('é decorativa para o leitor de tela', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t);

      expect(
        find.ancestor(
          of: find.byType(MemoraAnimada),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      h.dispose();
    });

    testWidgets('a barra não ficou mais alta por causa dela', (
      WidgetTester t,
    ) async {
      await montar(t);
      expect(
        t.getSize(find.byType(BarraSuperior)).height,
        MemoraDimensoes.alvoDecisao,
      );
    });
  });

  group('Fala enquanto a resposta aparece — FR-025', () {
    testWidgets('em repouso antes da pergunta, falando durante a escrita e de '
        'volta ao repouso no fim', (WidgetTester t) async {
      await montar(t);
      expect(memora(t).expressao, PoseDaMemora.neutra);
      expect(memora(t).falando, isFalse);

      await perguntar(t);
      await responder(t, _resposta);
      await t.pump(const Duration(milliseconds: 300));

      // No meio da escrita: pose e boca falando.
      expect(memora(t).expressao, PoseDaMemora.falando);
      expect(memora(t).falando, isTrue);

      await terminarAEscrita(t);
      expect(memora(t).expressao, PoseDaMemora.neutra);
      expect(memora(t).falando, isFalse);
    });

    testWidgets('fala também enquanto os trechos chegam', (
      WidgetTester t,
    ) async {
      await montar(t);
      await perguntar(t);

      // Esperando o primeiro trecho: ainda nada escrito, ainda em repouso.
      expect(memora(t).falando, isFalse);

      repositorio.aoReceberTrecho!('Para ver a foto do seu neto, ');
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(memora(t).expressao, PoseDaMemora.falando);
      expect(memora(t).falando, isTrue);

      await responder(t, _resposta);
      await terminarAEscrita(t);
      expect(memora(t).falando, isFalse);
      expect(memora(t).expressao, PoseDaMemora.neutra);
    });

    testWidgets('fala antiga, lida do disco, não faz a Memora falar', (
      WidgetTester t,
    ) async {
      await montar(
        t,
        guardadas: <MensagemDaConversa>[
          MensagemDaConversa(
            autor: AutorDaMensagem.memora,
            texto: _antiga,
            momento: DateTime(2026),
          ),
        ],
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(memora(t).falando, isFalse);
      expect(memora(t).expressao, PoseDaMemora.neutra);
    });

    testWidgets('mandar a próxima pergunta no meio da escrita não deixa a '
        'Memora falando para sempre', (WidgetTester t) async {
      await montar(t);
      await perguntar(t);
      await responder(t, _resposta);
      await t.pump(const Duration(milliseconds: 300));
      expect(memora(t).falando, isTrue);

      // O campo está livre: a pessoa pergunta de novo antes de a escrita acabar.
      await perguntar(t);
      await t.pump(const Duration(milliseconds: 100));
      // Respondendo, sem trecho ainda: nada sendo escrito.
      expect(controlador.respondendo, isTrue);
      expect(memora(t).falando, isFalse);

      await responder(t, 'Ok.');
      await terminarAEscrita(t);
      expect(memora(t).falando, isFalse);
    });

    testWidgets('com "reduzir movimento", fica em repouso o tempo todo', (
      WidgetTester t,
    ) async {
      await montar(t, reduzirMovimento: true);
      await perguntar(t);
      repositorio.aoReceberTrecho!('Para ver a foto do seu neto, ');
      await t.pump();
      expect(memora(t).falando, isFalse);
      expect(memora(t).expressao, PoseDaMemora.neutra);
      await responder(t, _resposta);
      await t.pump(const Duration(milliseconds: 100));
      expect(memora(t).falando, isFalse);
      expect(memora(t).expressao, PoseDaMemora.neutra);
    });
  });

  group('Cabe em todo aparelho — FR-042, FR-027', () {
    for (final Size aparelho in aparelhos) {
      for (final double escala in escalas) {
        testWidgets(
          'a Memora não rouba a lista em ${nomeDo(aparelho)}, escala $escala',
          (WidgetTester t) async {
            await montar(t, tela: aparelho, escala: escala);

            // Com a letra muito ampliada a figura sai da barra (como no
            // cabeçalho das telas); senão, é uma só e cabe na barra. O rosto
            // do convite (FR-042, rev. 2026-11-18) não é a figura do topo.
            final Finder figura = doTopo();
            if (escala < CabecalhoDeTela.ampliacaoQueTiraAFigura) {
              expect(figura, findsOneWidget);
              final Rect barra = t.getRect(find.byType(BarraSuperior));
              expect(t.getRect(figura).bottom, lessThanOrEqualTo(barra.bottom));
            } else {
              expect(figura, findsNothing);
            }
            expect(t.takeException(), isNull);

            // A altura da lista, e o botão de enviar, são o portão da FR-027 em
            // conversa_acessibilidade_test.dart; aqui basta o botão à mão.
            expect(find.byKey(TelaConversa.chaveEnviar), findsOneWidget);
          },
        );
      }
    }
  });
}
