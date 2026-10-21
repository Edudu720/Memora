import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/chamada_com_renovacao.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_api.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora_api/memora_api.dart' as api;

import 'suporte_da_api_falsa.dart';

/// O repositório real da assistente (T036), contra um servidor de mentira no
/// nível do transporte.
///
/// `test` puro: nada aqui usa relógio falso, e o que passa pelo adaptador é o
/// `Dio` de verdade, com os interceptores do cliente gerado.
void main() {
  late CofreEmMemoria cofre;
  late RenovadorFalso renovador;
  late AdaptadorFalso servidor;
  late RepositorioAssistenteApi repositorio;

  void montar(
    Future<ResponseBody> Function(RequestOptions, int) resposta, {
    bool renovacaoRecusada = false,
  }) {
    cofre = CofreEmMemoria();
    renovador = RenovadorFalso(cofre, recusar: renovacaoRecusada);
    servidor = AdaptadorFalso(resposta);
    final api.MemoraApi cliente = clienteFalso(servidor);
    repositorio = RepositorioAssistenteApi(
      cliente: cliente,
      chamadas: ChamadaComRenovacao(
        cliente: cliente,
        cofre: cofre,
        renovar: renovador.renovar,
      ),
    );
  }

  ResponseBody sessaoRecusada() => respostaJson(401, <String, Object>{
    'codigo': 'SESSAO_EXPIRADA',
    'mensagem': 'x',
  });

  group('conversar', () {
    test('o texto aparece à medida que chega, não só no fim', () async {
      // O ponto da FR-052: com o fluxo ainda aberto, os trechos já foram
      // entregues à tela.
      final StreamController<Uint8List> fluxo = StreamController<Uint8List>();
      montar(
        (RequestOptions o, int n) async => ResponseBody(
          fluxo.stream,
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/event-stream'],
          },
        ),
      );
      final List<String> trechos = <String>[];

      final Future<RespostaDaAssistente> resposta = repositorio.conversar(
        mensagem: 'Como mando uma foto?',
        historico: const <MensagemDaConversa>[],
        aoReceberTrecho: trechos.add,
      );
      await pumpEventQueue();

      fluxo.add(Uint8List.fromList(utf8.encode(evento('texto', 'Vamos '))));
      await pumpEventQueue();
      expect(trechos, <String>['Vamos '], reason: 'antes de o fluxo acabar');

      fluxo.add(Uint8List.fromList(utf8.encode(evento('texto', 'juntos.'))));
      fluxo.add(Uint8List.fromList(utf8.encode(evento('fim'))));
      await fluxo.close();

      final RespostaDaAssistente r = await resposta;
      expect(trechos, <String>['Vamos ', 'juntos.']);
      expect((r as AssistenteRespondeu).texto, 'Vamos juntos.');
    });

    test(
      'envia o pedido no formato do contrato, com o token da sessão',
      () async {
        montar(
          (RequestOptions o, int n) async =>
              respostaSse(<String>[evento('fim')]),
        );

        await repositorio.conversar(
          mensagem: 'E agora?',
          historico: <MensagemDaConversa>[
            MensagemDaConversa(
              autor: AutorDaMensagem.pessoa,
              texto: 'Oi',
              momento: DateTime(2026),
            ),
            MensagemDaConversa(
              autor: AutorDaMensagem.memora,
              texto: 'Olá!',
              momento: DateTime(2026),
            ),
          ],
        );

        final RequestOptions pedido = servidor.pedidos.single;
        expect(pedido.method, 'POST');
        expect(pedido.uri.path, '/v1/assistente/conversa');
        expect(pedido.headers['Authorization'], 'Bearer acesso-1');
        expect(pedido.headers['Accept'], 'text/event-stream');
        expect(jsonDecode(pedido.data as String), <String, Object>{
          'mensagem': 'E agora?',
          'historico': <Map<String, String>>[
            <String, String>{'autor': 'pessoa', 'texto': 'Oi'},
            <String, String>{'autor': 'memora', 'texto': 'Olá!'},
          ],
        });
      },
    );

    test('a ação autorizada chega à resposta', () async {
      montar(
        (RequestOptions o, int n) async => respostaSse(<String>[
          evento('texto', 'Quer que eu abra?'),
          evento(
            'acao',
            jsonEncode(<String, String>{
              'servico_id': 'abc',
              'nome_exibido': 'WhatsApp',
              'identificador_android': 'com.whatsapp',
            }),
          ),
          evento('fim'),
        ]),
      );

      final RespostaDaAssistente r = await repositorio.conversar(
        mensagem: 'não consegui',
        historico: const <MensagemDaConversa>[],
      );

      expect(
        (r as AssistenteRespondeu).acao?.identificadorAndroid,
        'com.whatsapp',
      );
    });

    test('401 na conversa: renova em silêncio e reenvia o pedido', () async {
      montar((RequestOptions o, int n) async {
        return o.headers['Authorization'] == 'Bearer acesso-2'
            ? respostaSse(<String>[evento('texto', 'oi'), evento('fim')])
            : sessaoRecusada();
      });

      final RespostaDaAssistente r = await repositorio.conversar(
        mensagem: 'oi',
        historico: const <MensagemDaConversa>[],
      );

      expect((r as AssistenteRespondeu).texto, 'oi');
      expect(renovador.chamadas, 1);
      expect(servidor.pedidos, hasLength(2));
    });

    test('renovação recusada: a conversa falha com sessaoExpirada', () async {
      montar(
        (RequestOptions o, int n) async => sessaoRecusada(),
        renovacaoRecusada: true,
      );

      final RespostaDaAssistente r = await repositorio.conversar(
        mensagem: 'oi',
        historico: const <MensagemDaConversa>[],
      );

      expect((r as AssistenteFalhou).falha, FalhaDaAssistente.sessaoExpirada);
    });

    test('sem rede é semConexao', () async {
      montar((RequestOptions o, int n) async {
        throw DioException.connectionError(
          requestOptions: o,
          reason: 'sem rede',
        );
      });

      final RespostaDaAssistente r = await repositorio.conversar(
        mensagem: 'oi',
        historico: const <MensagemDaConversa>[],
      );

      expect((r as AssistenteFalhou).falha, FalhaDaAssistente.semConexao);
    });

    test('400 e 500 são inesperada (e passageiras)', () async {
      for (final int status in <int>[400, 500]) {
        montar(
          (RequestOptions o, int n) async =>
              respostaSse(<String>['{"codigo":"X"}'], status: status),
        );

        final RespostaDaAssistente r = await repositorio.conversar(
          mensagem: 'oi',
          historico: const <MensagemDaConversa>[],
        );

        expect(
          (r as AssistenteFalhou).falha,
          FalhaDaAssistente.inesperada,
          reason: 'status $status',
        );
        expect(renovador.chamadas, 0);
      }
    });

    test('a conexão cai com o fluxo aberto: semConexao, sem exceção', () async {
      final StreamController<Uint8List> fluxo = StreamController<Uint8List>();
      montar((RequestOptions o, int n) async {
        return ResponseBody(fluxo.stream, 200);
      });

      final Future<RespostaDaAssistente> resposta = repositorio.conversar(
        mensagem: 'oi',
        historico: const <MensagemDaConversa>[],
      );
      await pumpEventQueue();
      fluxo.add(Uint8List.fromList(utf8.encode(evento('texto', 'Vamos '))));
      fluxo.addError(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/assistente/conversa'),
          reason: 'caiu',
        ),
      );
      await fluxo.close();

      expect(
        ((await resposta) as AssistenteFalhou).falha,
        FalhaDaAssistente.semConexao,
      );
    });
  });

  group('catálogo, registro e ação', () {
    test('catálogo: traduz serviços, categorias e a chave', () async {
      montar(
        (RequestOptions o, int n) async => respostaJson(200, <String, Object>{
          'servicos': <Map<String, Object>>[
            <String, Object>{
              'id': 'id-1',
              'chave': 'whatsapp',
              'nome_exibido': 'WhatsApp',
              'descricao_curta': 'Mandar mensagem',
              'categoria': 'cotidiano',
              'memora_pode_abrir': true,
              'identificador_android': 'com.whatsapp',
            },
            <String, Object>{
              'id': 'id-2',
              'chave': 'gov-br',
              'nome_exibido': 'Gov.br',
              'categoria': 'sensivel',
              'memora_pode_abrir': false,
            },
          ],
        }),
      );

      final List<ServicoDoCatalogo> servicos = await repositorio.catalogo();

      expect(servicos, hasLength(2));
      expect(servicos[0].id, 'id-1');
      expect(servicos[0].chave, 'whatsapp');
      expect(servicos[0].categoria, CategoriaDoServico.cotidiano);
      expect(servicos[0].memoraPodeAbrir, isTrue);
      expect(servicos[0].descricaoCurta, 'Mandar mensagem');
      expect(servicos[1].chave, 'gov-br');
      expect(servicos[1].categoria, CategoriaDoServico.sensivel);
      expect(
        servicos[1].memoraPodeAbrir,
        isFalse,
        reason: 'o aplicativo repassa o que o servidor disse, sem derivar',
      );
      expect(servicos[1].descricaoCurta, isEmpty);
      expect(
        servidor.pedidos.single.headers['Authorization'],
        'Bearer acesso-1',
      );
    });

    test('catálogo com 401: renova e reenvia', () async {
      montar((RequestOptions o, int n) async {
        return o.headers['Authorization'] == 'Bearer acesso-2'
            ? respostaJson(200, <String, Object>{'servicos': <Object>[]})
            : sessaoRecusada();
      });

      expect(await repositorio.catalogo(), isEmpty);
      expect(renovador.chamadas, 1);
    });

    test('registro: traduz as ações', () async {
      montar(
        (RequestOptions o, int n) async => respostaJson(200, <String, Object>{
          'acoes': <Map<String, String>>[
            <String, String>{
              'nome_exibido': 'WhatsApp',
              'pedido_resumido': 'abrir o zap',
              'ocorrido_em': '2026-10-09T12:00:00Z',
            },
          ],
        }),
      );

      final List<AcaoRegistrada> acoes = await repositorio.registro();

      expect(acoes.single.nomeExibido, 'WhatsApp');
      expect(acoes.single.pedidoResumido, 'abrir o zap');
      expect(acoes.single.ocorridoEm.toUtc(), DateTime.utc(2026, 10, 9, 12));
    });

    test(
      'registro com linha incompleta falha, em vez de inventar a data',
      () async {
        montar(
          (RequestOptions o, int n) async => respostaJson(200, <String, Object>{
            'acoes': <Map<String, String>>[
              <String, String>{'nome_exibido': 'WhatsApp'},
            ],
          }),
        );

        await expectLater(
          repositorio.registro(),
          throwsA(isA<FalhaDeChamadaDaAssistente>()),
        );
      },
    );

    test('registro com sessão perdida lança sessaoExpirada', () async {
      montar(
        (RequestOptions o, int n) async => sessaoRecusada(),
        renovacaoRecusada: true,
      );

      await expectLater(
        repositorio.registro(),
        throwsA(
          isA<FalhaDeChamadaDaAssistente>().having(
            (FalhaDeChamadaDaAssistente e) => e.falha,
            'falha',
            FalhaDaAssistente.sessaoExpirada,
          ),
        ),
      );
    });

    test('registrarAcao envia servico_id e pedido_resumido', () async {
      montar(
        (RequestOptions o, int n) async => ResponseBody.fromString('', 204),
      );

      await repositorio.registrarAcao(
        servicoId: 'id-1',
        pedidoResumido: 'abrir o zap',
      );

      final RequestOptions pedido = servidor.pedidos.single;
      expect(pedido.uri.path, '/v1/assistente/acao');
      expect(pedido.headers['Authorization'], 'Bearer acesso-1');
      expect(jsonDecode(pedido.data as String), <String, String>{
        'servico_id': 'id-1',
        'pedido_resumido': 'abrir o zap',
      });
    });

    test('registrarAcao com 401: renova e reenvia uma vez', () async {
      montar((RequestOptions o, int n) async {
        return o.headers['Authorization'] == 'Bearer acesso-2'
            ? ResponseBody.fromString('', 204)
            : sessaoRecusada();
      });

      await repositorio.registrarAcao(servicoId: 'id-1', pedidoResumido: 'x');

      expect(renovador.chamadas, 1);
      expect(servidor.pedidos, hasLength(2));
    });
  });
}
