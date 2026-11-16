import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/leitor_de_voz_nativo.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/domain/leitor_de_voz.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';

import '../../suporte/aceite_em_memoria.dart';

class _ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _guardadas = <MensagemDaConversa>[];

  @override
  Future<List<MensagemDaConversa>> ler() async => _guardadas;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _guardadas = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async => _guardadas = <MensagemDaConversa>[];
}

class _RepositorioEspiao extends RepositorioAssistenteSimulado {
  int chamadasEnviar = 0;

  _RepositorioEspiao() : super(demora: Duration.zero);

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) {
    chamadasEnviar++;
    return super.conversar(
      mensagem: mensagem,
      historico: historico,
      aoReceberTrecho: aoReceberTrecho,
    );
  }
}

class _FakeLeitorDeVoz implements LeitorDeVoz {
  ResultadoDitado respostaAoIniciar;
  int chamadasIniciar = 0;
  int chamadasParar = 0;
  int chamadasDispose = 0;
  void Function(String textoParcial)? _callbackParcial;

  _FakeLeitorDeVoz({
    this.respostaAoIniciar = const ResultadoDitado(estado: EstadoDitado.ouvindo),
  });

  @override
  Future<ResultadoDitado> verificarDisponibilidade() async =>
      respostaAoIniciar.disponivel
      ? const ResultadoDitado(estado: EstadoDitado.ocioso)
      : respostaAoIniciar;

  @override
  Future<ResultadoDitado> iniciarEscuta({
    required void Function(String textoParcial) aoReconhecer,
  }) async {
    chamadasIniciar++;
    _callbackParcial = aoReconhecer;
    return respostaAoIniciar;
  }

  void emitirFala(String texto) {
    _callbackParcial?.call(texto);
  }

  @override
  Future<void> pararEscuta() async {
    chamadasParar++;
  }

  @override
  void dispose() {
    chamadasDispose++;
  }
}

void main() {
  late _ConversaEmMemoria local;
  late _RepositorioEspiao repositorio;

  setUp(() {
    local = _ConversaEmMemoria();
    repositorio = _RepositorioEspiao();
  });

  Future<void> montarTela(WidgetTester t, ControladorConversa c) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: TelaConversa(controlador: c),
      ),
    );
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));
  }

  group('FR-013 — Ditado por voz seguro na conversa', () {
    testWidgets(
      'explica a permissão em português simples antes de acionar o microfone',
      (WidgetTester t) async {
        final _FakeLeitorDeVoz leitor = _FakeLeitorDeVoz();
        final ControladorConversa c = ControladorConversa(
          repositorio,
          local,
          aceite: AceiteEmMemoria(),
          leitorDeVoz: leitor,
        );
        addTearDown(c.dispose);
        await montarTela(t, c);

        final Finder mic = find.byKey(TelaConversa.chaveMicrofone);
        expect(find.text(TextosAssistente.botaoFalar), findsOneWidget);
        await t.ensureVisible(mic);
        await t.tap(mic);
        await t.pump();

        expect(
          find.byKey(TelaConversa.chaveDialogoPermissaoVoz),
          findsOneWidget,
        );
        expect(
          find.text(TextosAssistente.explicacaoPermissaoVoz),
          findsOneWidget,
        );
        expect(
          leitor.chamadasIniciar,
          0,
          reason: 'Não deve pedir ao sistema antes de explicar à pessoa',
        );

        await t.tap(find.text(TextosAssistente.botaoRecusarPermissaoVoz));
        await t.pump();
        expect(
          find.byKey(TelaConversa.chaveDialogoPermissaoVoz),
          findsNothing,
        );
        expect(leitor.chamadasIniciar, 0);
      },
    );

    testWidgets(
      'alterna Falar/Parar, preenche só o rascunho sem envio automático e só envia com Perguntar',
      (WidgetTester t) async {
        final _FakeLeitorDeVoz leitor = _FakeLeitorDeVoz();
        final ControladorConversa c = ControladorConversa(
          repositorio,
          local,
          aceite: AceiteEmMemoria(),
          leitorDeVoz: leitor,
        );
        addTearDown(c.dispose);
        await montarTela(t, c);

        await t.ensureVisible(find.byKey(TelaConversa.chaveMicrofone));
        await t.tap(find.byKey(TelaConversa.chaveMicrofone));
        await t.pump();
        await t.tap(find.text(TextosAssistente.botaoConfirmarPermissaoVoz));
        await t.pump();

        expect(leitor.chamadasIniciar, 1);
        expect(find.text(TextosAssistente.botaoPararDitado), findsOneWidget);
        expect(find.byKey(TelaConversa.chaveStatusVoz), findsOneWidget);

        leitor.emitirFala('como vejo as fotos do meu neto');
        await t.pump();

        expect(c.rascunho, 'como vejo as fotos do meu neto');
        final TextField campo = t.widget<TextField>(
          find.descendant(
            of: find.byKey(TelaConversa.chaveCampo),
            matching: find.byType(TextField),
          ),
        );
        expect(campo.controller?.text, 'como vejo as fotos do meu neto');
        expect(
          repositorio.chamadasEnviar,
          0,
          reason: 'Voz nunca envia mensagem automaticamente',
        );
        expect(c.mensagens, isEmpty);

        await t.ensureVisible(find.byKey(TelaConversa.chaveMicrofone));
        await t.tap(find.byKey(TelaConversa.chaveMicrofone));
        await t.pump();

        expect(leitor.chamadasParar, 1);
        expect(find.text(TextosAssistente.botaoFalar), findsOneWidget);
        expect(repositorio.chamadasEnviar, 0);

        await t.ensureVisible(find.byKey(TelaConversa.chaveEnviar));
        await t.tap(find.byKey(TelaConversa.chaveEnviar));
        await t.pump(const Duration(milliseconds: 50));

        expect(repositorio.chamadasEnviar, 1);
      },
    );

    testWidgets(
      'mostra fallback amigável quando microfone está indisponível mantendo digitação ativa',
      (WidgetTester t) async {
        final _FakeLeitorDeVoz leitor = _FakeLeitorDeVoz(
          respostaAoIniciar: const ResultadoDitado(
            estado: EstadoDitado.indisponivel,
          ),
        );
        final ControladorConversa c = ControladorConversa(
          repositorio,
          local,
          aceite: AceiteEmMemoria(),
          leitorDeVoz: leitor,
        );
        addTearDown(c.dispose);
        await montarTela(t, c);

        await t.ensureVisible(find.byKey(TelaConversa.chaveMicrofone));
        await t.tap(find.byKey(TelaConversa.chaveMicrofone));
        await t.pump();
        await t.tap(find.text(TextosAssistente.botaoConfirmarPermissaoVoz));
        await t.pump();

        expect(find.byKey(TelaConversa.chaveStatusVoz), findsOneWidget);
        expect(find.text(TextosAssistente.vozIndisponivel), findsOneWidget);

        await t.enterText(
          find.byKey(TelaConversa.chaveCampo),
          'como aumento a letra',
        );
        await t.pump();
        await t.ensureVisible(find.byKey(TelaConversa.chaveEnviar));
        await t.tap(find.byKey(TelaConversa.chaveEnviar));
        await t.pump(const Duration(milliseconds: 50));

        expect(repositorio.chamadasEnviar, 1);
      },
    );

    testWidgets(
      'botão de microfone atende à área mínima tocável (>= 48x48 dp)',
      (WidgetTester t) async {
        final SemanticsHandle h = t.ensureSemantics();
        final ControladorConversa c = ControladorConversa(
          repositorio,
          local,
          aceite: AceiteEmMemoria(),
          leitorDeVoz: _FakeLeitorDeVoz(),
        );
        addTearDown(c.dispose);
        await montarTela(t, c);

        final Size tamanho = t.getSize(find.byKey(TelaConversa.chaveMicrofone));
        expect(tamanho.width, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
        expect(tamanho.height, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
        h.dispose();
      },
    );
  });

  group('FR-004/FR-005 — Processamento estritamente offline (onDevice: true)', () {
    test(
      'solicita onDevice: true e não tenta fallback em nuvem quando listen falha',
      () async {
        final _EspiaoSpeechToText espiao = _EspiaoSpeechToText(
          erroAoOuvir: ListenFailedException('Pacote offline pt_BR ausente'),
        );
        final LeitorDeVozSpeechToText leitor = LeitorDeVozSpeechToText(
          speech: espiao,
        );

        final ResultadoDitado resultado = await leitor.iniciarEscuta(
          aoReconhecer: (_) {},
        );

        expect(espiao.chamadasListen, 1);
        expect(espiao.opcoesRegistradas.single?.onDevice, isTrue);
        expect(resultado.estado, EstadoDitado.indisponivel);
        expect(resultado.mensagem, TextosAssistente.vozOfflineIndisponivel);
      },
    );

    test(
      'retorna vozOfflineIndisponivel quando initialize recusa ou falha',
      () async {
        final _EspiaoSpeechToText espiao = _EspiaoSpeechToText(
          inicializa: false,
        );
        final LeitorDeVozSpeechToText leitor = LeitorDeVozSpeechToText(
          speech: espiao,
        );

        final ResultadoDitado resultado = await leitor.iniciarEscuta(
          aoReconhecer: (_) {},
        );

        expect(espiao.chamadasListen, 0);
        expect(resultado.estado, EstadoDitado.indisponivel);
        expect(resultado.mensagem, TextosAssistente.vozOfflineIndisponivel);
      },
    );

    testWidgets(
      'preserva rascunho parcial, mantém botão Falar e orienta teclado/pacote offline após erro permanente',
      (WidgetTester t) async {
        final _EspiaoSpeechToText espiao = _EspiaoSpeechToText();
        late final ControladorConversa c;
        final LeitorDeVozSpeechToText leitor = LeitorDeVozSpeechToText(
          speech: espiao,
          aoMudarEstado: (ResultadoDitado r) =>
              c.aplicarEstadoDitadoExterno(r),
        );
        c = ControladorConversa(
          repositorio,
          local,
          aceite: AceiteEmMemoria(),
          leitorDeVoz: leitor,
        );
        addTearDown(c.dispose);
        await montarTela(t, c);

        await t.ensureVisible(find.byKey(TelaConversa.chaveMicrofone));
        await t.tap(find.byKey(TelaConversa.chaveMicrofone));
        await t.pump();
        await t.tap(find.text(TextosAssistente.botaoConfirmarPermissaoVoz));
        await t.pump();

        expect(espiao.chamadasListen, 1);
        expect(espiao.opcoesRegistradas.single?.onDevice, isTrue);

        espiao.emitirResultadoParcial('tomar remédio');
        await t.pump();
        expect(c.rascunho, 'tomar remédio');

        espiao.emitirErro('error_language_unavailable', permanent: true);
        espiao.emitirStatus(SpeechToText.notListeningStatus);
        await t.pump();

        expect(c.estadoDitado, EstadoDitado.indisponivel);
        expect(
          find.text(TextosAssistente.vozOfflineIndisponivel),
          findsOneWidget,
        );
        expect(find.text(TextosAssistente.botaoFalar), findsOneWidget);
        expect(c.rascunho, 'tomar remédio');
        expect(repositorio.chamadasEnviar, 0);
      },
    );
  });
}

class _EspiaoSpeechToText extends SpeechToText {
  final bool inicializa;
  final Exception? erroAoOuvir;
  int chamadasListen = 0;
  final List<SpeechListenOptions?> opcoesRegistradas =
      <SpeechListenOptions?>[];

  SpeechErrorListener? _onError;
  SpeechStatusListener? _onStatus;
  SpeechResultListener? _onResult;

  _EspiaoSpeechToText({this.inicializa = true, this.erroAoOuvir})
    : super.withMethodChannel();

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    _onError = onError;
    _onStatus = onStatus;
    return inicializa;
  }

  @override
  Future<List<LocaleName>> locales() async => <LocaleName>[
    LocaleName('pt_BR', 'Português (Brasil)'),
  ];

  @override
  Future<dynamic> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    chamadasListen++;
    opcoesRegistradas.add(listenOptions);
    _onResult = onResult;
    if (erroAoOuvir != null) {
      throw erroAoOuvir!;
    }
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  void emitirResultadoParcial(String texto) {
    _onResult?.call(
      SpeechRecognitionResult.init(<SpeechRecognitionWords>[
        SpeechRecognitionWords(texto, null, 0.9),
      ], ResultType.partial),
    );
  }

  void emitirErro(String msg, {bool permanent = false}) {
    _onError?.call(SpeechRecognitionError(msg, permanent));
  }

  void emitirStatus(String status) {
    _onStatus?.call(status);
  }
}
