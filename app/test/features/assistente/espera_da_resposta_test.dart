import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';
import '../../suporte/aceite_em_memoria.dart';

/// A espera pela resposta tem fim (FR-052, SC-007 — T078).
///
/// ## Por que `testWidgets`, se não há tela
///
/// O relógio. Dentro de `testWidgets` ele é falso, e `t.pump(duração)` anda
/// meio minuto em um instante — que é o que um cronômetro de 30 s precisa para
/// ser testado sem o teste levar 30 s.
///
/// ## O repositório é um dublê que o teste controla
///
/// O simulado responde sozinho depois de uma demora fixa. Aqui cada resposta é
/// um `Completer` que o teste decide quando — e se — completar: é o único jeito
/// de exercer "a resposta chegou depois do corte".
class _RepositorioControlado implements RepositorioAssistente {
  final List<String> mensagens = <String>[];
  final List<Completer<RespostaDaAssistente>> pendentes =
      <Completer<RespostaDaAssistente>>[];
  void Function(String trecho)? aoReceberTrecho;

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) {
    mensagens.add(mensagem);
    this.aoReceberTrecho = aoReceberTrecho;
    final Completer<RespostaDaAssistente> resposta =
        Completer<RespostaDaAssistente>();
    pendentes.add(resposta);
    return resposta.future;
  }

  /// Completa o que ainda estiver pendente, para nada sobrar ao fim do teste.
  void encerrar() {
    for (final Completer<RespostaDaAssistente> c in pendentes) {
      if (!c.isCompleted) c.complete(const AssistenteRespondeu('tarde demais'));
    }
  }

  @override
  Future<List<ServicoDoCatalogo>> catalogo() => throw UnimplementedError();

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<AcaoRegistrada>> registro() => throw UnimplementedError();
}

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

class _ConversaQueConta extends _ConversaEmMemoria {
  int gravacoes = 0;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    gravacoes++;
    await super.guardar(mensagens);
  }
}

const String _pergunta = 'como vejo a foto do meu neto?';

void main() {
  late _RepositorioControlado repositorio;
  late ControladorConversa controlador;

  Future<void> preparar() async {
    repositorio = _RepositorioControlado();
    controlador = ControladorConversa(
      repositorio,
      _ConversaEmMemoria(),
      aceite: AceiteEmMemoria(),
      rascunhoInicial: _pergunta,
    );
    await controlador.iniciar();
  }

  Iterable<MensagemDaConversa> falasDaPessoa() => controlador.mensagens
      .where((MensagemDaConversa m) => m.autor == AutorDaMensagem.pessoa);

  testWidgets('sem nenhuma palavra em 30 s, a espera acaba e diz que é a conexão',
      (WidgetTester t) async {
    await preparar();
    unawaited(controlador.enviar());

    await t.pump(const Duration(seconds: 29));
    expect(controlador.respondendo, isTrue,
        reason: 'Antes dos 30 s, ainda é espera.');

    await t.pump(const Duration(seconds: 1));
    expect(controlador.estado, EstadoConversa.comErro);
    expect(controlador.mensagemDeErro, TextosAssistente.semRespostaDaConversa);

    repositorio.encerrar();
    await t.pump();
    controlador.dispose();
  });

  testWidgets('a pergunta volta ao campo, e não fica uma fala sem resposta',
      (WidgetTester t) async {
    await preparar();
    unawaited(controlador.enviar());
    await t.pump(ControladorConversa.esperaMaxima);

    expect(controlador.rascunho, _pergunta,
        reason: 'O texto de erro diz "o que você escreveu continua aqui". Era '
            'mentira: o rascunho já tinha sido apagado no envio.');
    expect(falasDaPessoa(), isEmpty);

    repositorio.encerrar();
    await t.pump();
    controlador.dispose();
  });

  testWidgets('tentar de novo reenvia sem a pessoa reescrever',
      (WidgetTester t) async {
    await preparar();
    unawaited(controlador.enviar());
    await t.pump(ControladorConversa.esperaMaxima);

    controlador.tentarNovamente();
    await t.pump();

    expect(repositorio.mensagens, <String>[_pergunta, _pergunta]);
    repositorio.pendentes.last
        .complete(const AssistenteRespondeu('Vou te mostrar o caminho.'));
    await t.pump();

    expect(controlador.estado, EstadoConversa.aguardando);
    expect(falasDaPessoa(), hasLength(1),
        reason: 'A pergunta aparece uma vez, e não uma por tentativa.');

    repositorio.encerrar();
    await t.pump();
    controlador.dispose();
  });

  testWidgets('a resposta que chega depois do corte é descartada',
      (WidgetTester t) async {
    await preparar();
    unawaited(controlador.enviar());
    await t.pump(ControladorConversa.esperaMaxima);

    repositorio.pendentes.first
        .complete(const AssistenteRespondeu('resposta atrasada'));
    await t.pump();

    expect(
      controlador.mensagens.map((MensagemDaConversa m) => m.texto),
      isNot(contains('resposta atrasada')),
      reason: 'Senão a pessoa, que já tocou em tentar de novo, recebe duas '
          'respostas para uma pergunta.',
    );
    expect(controlador.estado, EstadoConversa.comErro);
    controlador.dispose();
  });

  testWidgets('resposta que já começou a chegar não é cortada',
      (WidgetTester t) async {
    await preparar();
    unawaited(controlador.enviar());

    await t.pump(const Duration(seconds: 5));
    repositorio.aoReceberTrecho!('Vou te ');
    await t.pump(const Duration(seconds: 60));

    expect(controlador.respondendo, isTrue,
        reason: 'A FR-052 fala da resposta que não COMEÇA. Uma resposta longa, '
            'que está aparecendo, não pode ser interrompida no meio.');

    repositorio.pendentes.first
        .complete(const AssistenteRespondeu('Vou te mostrar.'));
    await t.pump();
    expect(controlador.estado, EstadoConversa.aguardando);
    controlador.dispose();
  });

  testWidgets('sem internet, a pergunta também volta ao campo',
      (WidgetTester t) async {
    await preparar();
    unawaited(controlador.enviar());
    repositorio.pendentes.first
        .complete(const AssistenteFalhou(FalhaDaAssistente.semConexao));
    await t.pump();

    expect(controlador.rascunho, _pergunta);
    expect(falasDaPessoa(), isEmpty);
    controlador.dispose();
  });

  testWidgets('resposta que chega depois do descarte não regrava a conversa',
      (WidgetTester t) async {
    // FR-048: depois de sair da tela (ou da conta, com a conversa já apagada
    // pela LimpezaDeSessao), uma resposta tardia não pode chamar `guardar`.
    final _RepositorioControlado repo = _RepositorioControlado();
    final _ConversaQueConta local = _ConversaQueConta();
    final ControladorConversa c =
        ControladorConversa(
      repo,
      local,
      aceite: AceiteEmMemoria(),
      rascunhoInicial: _pergunta,
    );
    await c.iniciar();

    unawaited(c.enviar());
    await t.pump();

    c.dispose();
    final int gravacoesAntes = local.gravacoes;

    repo.pendentes.first
        .complete(const AssistenteRespondeu('resposta tardia'));
    await t.pump();
    // O cronômetro de 30 s também não pode disparar depois do descarte.
    await t.pump(ControladorConversa.esperaMaxima);

    expect(local.gravacoes, gravacoesAntes,
        reason: 'resposta tardia regravaria a conversa que a saida apagou');
    expect(t.takeException(), isNull);
  });

  test('o texto diz que o problema é a conexão, e não a pessoa (FR-052)', () {
    final String texto = TextosAssistente.semRespostaDaConversa.toLowerCase();
    expect(texto, contains('internet'));
    expect(texto, contains('não foi nada que você fez'));
  });

  test('o aviso sem conexão das outras telas não promete o que não existe', () {
    // Catálogo e registro usam o aviso genérico, e nelas a pessoa não
    // escreveu nada: "o que você escreveu continua aqui" não cabe ali.
    expect(TextosAssistente.semConexao.toLowerCase(),
        isNot(contains('você escreveu')));
  });

  testWidgets('apagar a conversa com uma resposta em voo: o que chega depois '
      'não volta nem regrava (FR-040)', (WidgetTester t) async {
    repositorio = _RepositorioControlado();
    final _ConversaQueConta local = _ConversaQueConta();
    controlador = ControladorConversa(
      aceite: AceiteEmMemoria(),
      repositorio,
      local,
      rascunhoInicial: _pergunta,
    );
    await controlador.iniciar();

    unawaited(controlador.enviar());
    await t.pump();
    repositorio.aoReceberTrecho!('Primeiro, abra ');
    expect(controlador.respondendo, isTrue);

    await controlador.apagarConversa();
    final int gravacoesAoApagar = local.gravacoes;

    // A resposta e um trecho soltos DEPOIS de apagar.
    repositorio.aoReceberTrecho!('o aplicativo da galeria');
    repositorio.pendentes.first.complete(
      const AssistenteRespondeu('Abra a galeria.'),
    );
    await t.pump();
    await t.pump(ControladorConversa.esperaMaxima);

    expect(controlador.mensagens, isEmpty);
    expect(await local.ler(), isEmpty, reason: 'regravou no aparelho');
    expect(local.gravacoes, gravacoesAoApagar);
    expect(controlador.trechoEmCurso, isEmpty);
    expect(controlador.respondendo, isFalse);
    expect(controlador.estado, EstadoConversa.aguardando);
  });
}
