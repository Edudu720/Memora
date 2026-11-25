import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/abridor_de_aplicativo.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';

import '../../suporte/aceite_em_memoria.dart';

/// O registro da ação que falha depois de o aplicativo abrir (T112, Edge Cases
/// de 2026-10-09).
///
/// A rede pode cair entre a confirmação e o registro. O gesto da pessoa não
/// depende dela — o aplicativo abre —, mas a trilha da FR-020 ficaria com um
/// buraco e, antes da T112, a exceção subia sem tratamento a partir do toque.
///
/// `test` puro: o repositório e o abridor são dublês em memória, e nada aqui
/// precisa de relógio falso.
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

/// Oferece abrir o WhatsApp e falha no registro como o teste mandar.
class _RepositorioQueFalhaNoRegistro implements RepositorioAssistente {
  /// O que cada tentativa de registro faz: lançar o que está na lista, na
  /// ordem; passada a lista, dá certo.
  final List<Exception> falhas;

  /// Se não nulo, cada registro espera por ele antes de agir.
  final Completer<void>? portao;

  int tentativas = 0;

  _RepositorioQueFalhaNoRegistro(this.falhas, {this.portao});

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) async => const AssistenteRespondeu(
    'Quer que eu abra o WhatsApp?',
    acao: AcaoAutorizada(
      servicoId: 'id-whatsapp',
      nomeExibido: 'WhatsApp',
      identificadorAndroid: 'com.whatsapp',
    ),
  );

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {
    tentativas++;
    await portao?.future;
    if (tentativas <= falhas.length) throw falhas[tentativas - 1];
  }

  @override
  Future<List<ServicoDoCatalogo>> catalogo() async =>
      const <ServicoDoCatalogo>[];

  @override
  Future<List<AcaoRegistrada>> registro() async => const <AcaoRegistrada>[];
}

void main() {
  late AbridorDeAplicativoSimulado abridor;

  setUp(() => abridor = AbridorDeAplicativoSimulado());

  /// Conversa até a oferta de abrir, e a deixa pronta para confirmar.
  Future<ControladorConversa> comOferta(
    _RepositorioQueFalhaNoRegistro repositorio, {
    bool descartarNoFim = true,
  }) async {
    final ControladorConversa c = ControladorConversa(
      repositorio,
      _ConversaEmMemoria(),
      aceite: AceiteEmMemoria(),
      abridor: abridor,
    );
    if (descartarNoFim) addTearDown(c.dispose);
    await c.iniciar();
    c.escrever('não consegui achar o zap');
    await c.enviar();
    expect(c.acaoOferecida, isNotNull, reason: 'o cenário pressupõe a oferta');
    return c;
  }

  Iterable<String> falasDaMemora(ControladorConversa c) => c.mensagens
      .where((MensagemDaConversa m) => m.autor == AutorDaMensagem.memora)
      .map((MensagemDaConversa m) => m.texto);

  test('registro que dá certo: uma chamada, e nada a explicar', () async {
    final _RepositorioQueFalhaNoRegistro repo = _RepositorioQueFalhaNoRegistro(
      <Exception>[],
    );
    final ControladorConversa c = await comOferta(repo);

    await c.confirmarAcao();

    expect(repo.tentativas, 1);
    expect(abridor.abertos, <String>['com.whatsapp']);
    expect(
      falasDaMemora(c),
      isNot(contains(TextosAssistente.naoAnoteiNoRegistro('WhatsApp'))),
    );
  });

  test(
    'falha uma vez e dá certo na repetição: a pessoa não fica sabendo',
    () async {
      final _RepositorioQueFalhaNoRegistro repo =
          _RepositorioQueFalhaNoRegistro(<Exception>[Exception('rede caiu')]);
      final ControladorConversa c = await comOferta(repo);

      await c.confirmarAcao();

      expect(repo.tentativas, 2, reason: 'o registro é tentado mais uma vez');
      expect(
        falasDaMemora(c),
        isNot(contains(TextosAssistente.naoAnoteiNoRegistro('WhatsApp'))),
      );
    },
  );

  test(
    'falha duas vezes: o aplicativo continua aberto e a Memora conta',
    () async {
      final _RepositorioQueFalhaNoRegistro repo =
          _RepositorioQueFalhaNoRegistro(<Exception>[
            Exception('rede caiu'),
            Exception('ainda sem rede'),
          ]);
      final ControladorConversa c = await comOferta(repo);

      // Sem exceção sem tratamento: o `await` volta normalmente.
      await c.confirmarAcao();

      expect(repo.tentativas, 2, reason: 'uma repetição, e só uma');
      expect(abridor.abertos, <String>[
        'com.whatsapp',
      ], reason: 'o gesto da pessoa não depende da rede');
      expect(
        falasDaMemora(c),
        contains(TextosAssistente.naoAnoteiNoRegistro('WhatsApp')),
        reason:
            'nunca falha em silêncio: a FR-023 mostra à pessoa o que a '
            'Memora fez',
      );
    },
  );

  test('a fala não culpa a pessoa nem usa palavra técnica', () {
    final String fala = TextosAssistente.naoAnoteiNoRegistro('WhatsApp');

    expect(fala, contains('Abri o WhatsApp'));
    expect(fala, contains('Registro'));
    for (final String proibida in <String>[
      'erro',
      'falha',
      'exceção',
      'servidor',
      'conexão',
      'você errou',
    ]) {
      expect(fala.toLowerCase(), isNot(contains(proibida)));
    }
  });

  test(
    'sessão perdida: não repete, e não fala por cima da volta à entrada',
    () async {
      final _RepositorioQueFalhaNoRegistro repo =
          _RepositorioQueFalhaNoRegistro(<Exception>[
            const FalhaDeChamadaDaAssistente(FalhaDaAssistente.sessaoExpirada),
          ]);
      final ControladorConversa c = await comOferta(repo);

      await c.confirmarAcao();

      expect(repo.tentativas, 1, reason: 'a renovação já foi recusada');
      expect(
        falasDaMemora(c),
        isNot(contains(TextosAssistente.naoAnoteiNoRegistro('WhatsApp'))),
        reason: 'quem trata a sessão perdida é o fluxo (T111)',
      );
    },
  );

  test(
    'controlador descartado não fala, mas o registro ainda é tentado',
    () async {
      final Completer<void> portao = Completer<void>();
      final _RepositorioQueFalhaNoRegistro repo =
          _RepositorioQueFalhaNoRegistro(<Exception>[
            Exception('rede caiu'),
            Exception('ainda sem rede'),
          ], portao: portao);
      final ControladorConversa c = await comOferta(
        repo,
        descartarNoFim: false,
      );

      final Future<void> confirmando = c.confirmarAcao();
      await pumpEventQueue();
      final int falasAntes = c.mensagens.length;
      c.dispose();

      portao.complete();
      await confirmando;

      expect(repo.tentativas, 2, reason: 'é trilha de auditoria');
      expect(
        c.mensagens,
        hasLength(falasAntes),
        reason: 'controlador descartado não fala',
      );
    },
  );
}
