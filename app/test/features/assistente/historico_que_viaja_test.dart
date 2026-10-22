import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';

import '../../suporte/aceite_em_memoria.dart';

/// O que viaja ao serviço a cada turno — FR-056, T104 (lado do aparelho).
///
/// ## A regra
///
/// A conversa **nunca** é encerrada por ficar longa. O aparelho guarda e mostra
/// tudo; ao serviço de fora vão só os **20 turnos** mais recentes, que são **40
/// mensagens** — o `maxItems` do contrato. O servidor recusa mais que isso com
/// `400`, e antes desta tarefa o aparelho mandava a conversa inteira: a partir
/// da 41ª mensagem, a pessoa recebia um erro sem ter feito nada.
class _RepositorioQueAnota implements RepositorioAssistente {
  final List<List<MensagemDaConversa>> historicos =
      <List<MensagemDaConversa>>[];

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) async {
    historicos.add(List<MensagemDaConversa>.of(historico));
    return const AssistenteRespondeu('Vamos juntos.');
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

class _ConversaCom implements ConversaLocal {
  List<MensagemDaConversa> guardadas;

  _ConversaCom(this.guardadas);

  @override
  Future<List<MensagemDaConversa>> ler() async => guardadas;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    guardadas = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async => guardadas = <MensagemDaConversa>[];
}

/// [quantas] mensagens alternando pessoa e Memora, numeradas na ordem.
List<MensagemDaConversa> _conversaDe(int quantas) => <MensagemDaConversa>[
  for (int i = 0; i < quantas; i++)
    MensagemDaConversa(
      autor: i.isEven ? AutorDaMensagem.pessoa : AutorDaMensagem.memora,
      texto: 'mensagem $i',
      momento: DateTime(2026, 10, 3, 9, 0, i),
    ),
];

void main() {
  late _RepositorioQueAnota repositorio;

  setUp(() => repositorio = _RepositorioQueAnota());

  Future<ControladorConversa> abrirCom(List<MensagemDaConversa> antigas) async {
    final ControladorConversa c = ControladorConversa(
      repositorio,
      _ConversaCom(antigas),
      aceite: AceiteEmMemoria(),
    );
    addTearDown(c.dispose);
    await c.iniciar();
    return c;
  }

  test('o limite é de 40 mensagens, o maxItems do contrato', () {
    expect(ControladorConversa.mensagensQueViajam, 40);
  });

  test('com 50 mensagens na conversa, o serviço recebe exatamente as 40 '
      'últimas, na ordem', () async {
    final List<MensagemDaConversa> antigas = _conversaDe(50);
    final ControladorConversa c = await abrirCom(antigas);

    c.escrever('mais uma pergunta');
    await c.enviar();

    expect(repositorio.historicos, hasLength(1));
    final List<MensagemDaConversa> enviado = repositorio.historicos.single;
    expect(enviado, hasLength(40));

    // As 40 mais recentes são as 39 últimas das 50 e a pergunta de agora.
    expect(enviado.map((MensagemDaConversa m) => m.texto).toList(), <String>[
      ...antigas.sublist(11).map((MensagemDaConversa m) => m.texto),
      'mais uma pergunta',
    ]);
  });

  test(
    'o aparelho continua guardando e mostrando TODAS as mensagens',
    () async {
      final List<MensagemDaConversa> antigas = _conversaDe(50);
      final ControladorConversa c = await abrirCom(antigas);

      c.escrever('mais uma pergunta');
      await c.enviar();

      // 50 de antes + a pergunta + a resposta: nada foi cortado no aparelho.
      expect(c.mensagens, hasLength(52));
      expect(c.mensagens.first.texto, 'mensagem 0');
    },
  );

  test('conversa curta viaja inteira', () async {
    final ControladorConversa c = await abrirCom(_conversaDe(4));

    c.escrever('oi de novo');
    await c.enviar();

    expect(repositorio.historicos.single, hasLength(5));
  });

  test('exatamente no limite, nada é cortado', () async {
    // 39 antigas + a pergunta de agora = 40.
    final ControladorConversa c = await abrirCom(_conversaDe(39));

    c.escrever('a quadragésima');
    await c.enviar();

    expect(repositorio.historicos.single, hasLength(40));
    expect(repositorio.historicos.single.first.texto, 'mensagem 0');
  });

  test('um turno depois do outro, o tamanho nunca passa de 40', () async {
    final ControladorConversa c = await abrirCom(_conversaDe(0));

    for (int turno = 0; turno < 30; turno++) {
      c.escrever('pergunta $turno');
      await c.enviar();
    }

    expect(
      repositorio.historicos.map((List<MensagemDaConversa> h) => h.length),
      everyElement(lessThanOrEqualTo(40)),
      reason: 'a 41ª mensagem fazia o servidor recusar com 400',
    );
    expect(
      c.mensagens,
      hasLength(60),
      reason: 'a conversa nunca é encerrada por ficar longa (FR-056)',
    );
  });
}
