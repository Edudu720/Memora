import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/chamada_com_renovacao.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/services/seguranca/sessao_perdida.dart';
import 'package:memora_api/memora_api.dart' as api;

import 'suporte_da_api_falsa.dart';

typedef _Resposta = Response<api.AssistenteCatalogoGet200Response>;

/// A renovação em silêncio (T108, Edge Cases de 2026-10-09).
///
/// O token de acesso vale 15 minutos: vencer no meio do uso não pode virar
/// "entre de novo". E duas renovações com o mesmo refresh são o sinal de roubo
/// que o servidor pune derrubando a família inteira (V3) — por isso o teste
/// central é o das duas chamadas simultâneas.
///
/// `test` puro, de propósito: relógio falso e I/O não combinam.
void main() {
  late CofreEmMemoria cofre;
  late RenovadorFalso renovador;
  late AdaptadorFalso servidor;
  late ChamadaComRenovacao chamadas;
  late SessaoPerdida sessaoPerdida;
  late Future<_Resposta> Function() chamada;

  /// Monta tudo. [aceita] diz qual token o servidor aceita.
  void montar({
    required String aceita,
    RenovadorFalso Function(CofreEmMemoria)? renovadorDoTeste,
    Future<ResponseBody> Function(RequestOptions, int)? resposta,
  }) {
    cofre = CofreEmMemoria();
    sessaoPerdida = SessaoPerdida();
    renovador = (renovadorDoTeste ?? RenovadorFalso.new)(cofre);
    servidor = AdaptadorFalso(
      resposta ??
          (RequestOptions opcoes, int numero) async {
            final bool autorizado =
                opcoes.headers['Authorization'] == 'Bearer $aceita';
            return autorizado
                ? respostaJson(200, <String, Object>{'servicos': <Object>[]})
                : respostaJson(401, <String, Object>{
                    'codigo': 'SESSAO_EXPIRADA',
                    'mensagem': 'x',
                  });
          },
    );
    final api.MemoraApi cliente = clienteFalso(servidor);
    chamadas = ChamadaComRenovacao(
      cliente: cliente,
      cofre: cofre,
      renovar: renovador.renovar,
      sessaoPerdida: sessaoPerdida,
    );
    chamada = () => cliente.getCatalogoApi().assistenteCatalogoGet();
  }

  FalhaDaAssistente? falhaDe(Object? excecao) =>
      excecao is FalhaDeChamadaDaAssistente ? excecao.falha : null;

  Future<Object?> falhaDaChamada() async {
    try {
      await chamadas.executar(chamada);
    } on Object catch (e) {
      return e;
    }
    return null;
  }

  test('401 → renova → reenvia com o token novo → sucesso', () async {
    montar(aceita: 'acesso-2');

    final _Resposta resposta = await chamadas.executar(chamada);

    expect(resposta.statusCode, 200);
    expect(renovador.chamadas, 1);
    expect(servidor.pedidos, hasLength(2));
    expect(servidor.pedidos[0].headers['Authorization'], 'Bearer acesso-1');
    expect(
      servidor.pedidos[1].headers['Authorization'],
      'Bearer acesso-2',
      reason:
          'o reenvio precisa levar o token que a renovação acabou de gravar',
    );
  });

  test('token válido: nenhuma renovação, um pedido só', () async {
    montar(aceita: 'acesso-1');

    await chamadas.executar(chamada);

    expect(renovador.chamadas, 0);
    expect(servidor.pedidos, hasLength(1));
  });

  test('renovação recusada → sessaoExpirada, sem reenviar', () async {
    montar(
      aceita: 'acesso-2',
      renovadorDoTeste: (CofreEmMemoria c) => RenovadorFalso(c, recusar: true),
    );

    expect(falhaDe(await falhaDaChamada()), FalhaDaAssistente.sessaoExpirada);
    expect(renovador.chamadas, 1);
    expect(
      servidor.pedidos,
      hasLength(1),
      reason: 'sem sessão nova não há o que reenviar',
    );
  });

  test('falta de rede NA renovação não manda a pessoa ao login', () async {
    montar(
      aceita: 'acesso-2',
      renovadorDoTeste: (CofreEmMemoria c) => RenovadorFalso(c, semRede: true),
    );

    expect(
      falhaDe(await falhaDaChamada()),
      FalhaDaAssistente.semConexao,
      reason:
          'a rede caiu, a sessão não: sessaoExpirada faria a pessoa digitar '
          'a senha por um problema que não é dela',
    );
  });

  test('nunca mais de um reenvio, nem de uma renovação', () async {
    // O servidor recusa até o token novo (conta desativada, ou token de
    // sessão que nunca existiu).
    montar(aceita: 'nenhum');

    expect(falhaDe(await falhaDaChamada()), FalhaDaAssistente.sessaoExpirada);
    expect(servidor.pedidos, hasLength(2), reason: 'original + UM reenvio');
    expect(renovador.chamadas, 1, reason: 'o segundo 401 não renova de novo');
  });

  test('falha que não é 401 passa direto, sem renovar', () async {
    montar(
      aceita: 'acesso-1',
      resposta: (RequestOptions o, int n) async =>
          respostaJson(500, <String, Object>{'codigo': 'ERRO_INESPERADO'}),
    );

    await expectLater(
      chamadas.executar(chamada),
      throwsA(
        isA<DioException>().having(
          (DioException e) => e.response?.statusCode,
          'status',
          500,
        ),
      ),
    );
    expect(renovador.chamadas, 0);
    expect(servidor.pedidos, hasLength(1));
  });

  test('sem token de acesso, mas com refresh, renova em silêncio', () async {
    montar(aceita: 'acesso-2');
    cofre.acesso = null;

    final _Resposta resposta = await chamadas.executar(chamada);

    expect(resposta.statusCode, 200);
    expect(renovador.chamadas, 1);
  });

  test('duas chamadas simultâneas com 401 → UMA renovação', () async {
    // O portão segura a renovação até as duas chamadas terem levado o 401:
    // sem isto uma poderia terminar antes de a outra chegar, e o teste não
    // provaria nada.
    final Completer<void> portao = Completer<void>();
    montar(
      aceita: 'acesso-2',
      renovadorDoTeste: (CofreEmMemoria c) => RenovadorFalso(c, portao: portao),
    );

    final Future<_Resposta> a = chamadas.executar(chamada);
    final Future<_Resposta> b = chamadas.executar(chamada);

    await pumpEventQueue();
    expect(servidor.pedidos, hasLength(2), reason: 'as duas já levaram o 401');
    expect(renovador.chamadas, 1, reason: 'e só uma está renovando');

    portao.complete();
    final List<_Resposta> respostas = await Future.wait(<Future<_Resposta>>[
      a,
      b,
    ]);

    expect(respostas.map((_Resposta r) => r.statusCode), <int?>[200, 200]);
    expect(
      renovador.chamadas,
      1,
      reason:
          'duas renovações com o mesmo refresh são o sinal de roubo (V3): o '
          'servidor derruba a família inteira',
    );
    expect(servidor.pedidos, hasLength(4), reason: '2 originais + 2 reenvios');
  });

  test(
    '401 que chega DEPOIS de a renovação terminar não renova de novo',
    () async {
      // A chamada B sai com o token antigo e o servidor demora a responder. A
      // renovação da A termina antes. Quando o 401 da B chega, já não há
      // renovação em curso — mas o cofre tem token novo, e gastar mais um
      // refresh seria desperdício.
      final Completer<void> liberarB = Completer<void>();
      montar(
        aceita: 'acesso-2',
        resposta: (RequestOptions opcoes, int numero) async {
          final bool novo =
              opcoes.headers['Authorization'] == 'Bearer acesso-2';
          if (novo) {
            return respostaJson(200, <String, Object>{'servicos': <Object>[]});
          }
          if (numero == 2) await liberarB.future; // a B, segurada
          return respostaJson(401, <String, Object>{
            'codigo': 'SESSAO_EXPIRADA',
            'mensagem': 'x',
          });
        },
      );

      final Future<_Resposta> a = chamadas.executar(chamada);
      final Future<_Resposta> b = chamadas.executar(chamada);

      await a; // A inteira: 401 → renova → reenvia → 200
      expect(renovador.chamadas, 1);

      liberarB.complete();
      await b;

      expect(
        renovador.chamadas,
        1,
        reason: 'a B só precisava reenviar com o token que o cofre já tinha',
      );
      expect(servidor.pedidos.last.headers['Authorization'], 'Bearer acesso-2');
    },
  );
  group('o aviso de sessão perdida (T111)', () {
    test('renovação recusada aciona o aviso, uma vez', () async {
      montar(
        aceita: 'acesso-2',
        renovadorDoTeste: (CofreEmMemoria c) =>
            RenovadorFalso(c, recusar: true),
      );

      await falhaDaChamada();

      expect(sessaoPerdida.avisos, 1);
    });

    test('o segundo 401, depois de renovar, também aciona o aviso', () async {
      montar(aceita: 'nenhum');

      await falhaDaChamada();

      expect(sessaoPerdida.avisos, 1);
    });

    test(
      'duas chamadas em voo com a renovação recusada avisam UMA vez',
      () async {
        // A renovação é uma só (a segunda chamada espera a mesma), e é nela que o
        // aviso nasce: duas saídas automáticas seriam duas limpezas.
        final Completer<void> portao = Completer<void>();
        montar(
          aceita: 'acesso-2',
          renovadorDoTeste: (CofreEmMemoria c) =>
              RenovadorFalso(c, portao: portao, recusar: true),
        );

        final Future<Object?> a = falhaDaChamada();
        final Future<Object?> b = falhaDaChamada();
        await pumpEventQueue();
        portao.complete();
        await Future.wait(<Future<Object?>>[a, b]);

        expect(renovador.chamadas, 1);
        expect(sessaoPerdida.avisos, 1);
      },
    );

    test('falta de rede na renovação NÃO aciona o aviso', () async {
      montar(
        aceita: 'acesso-2',
        renovadorDoTeste: (CofreEmMemoria c) =>
            RenovadorFalso(c, semRede: true),
      );

      await falhaDaChamada();

      expect(sessaoPerdida.avisos, 0);
    });

    test('falha que não é 401 e sucesso não acionam o aviso', () async {
      montar(
        aceita: 'acesso-1',
        resposta: (RequestOptions o, int n) async =>
            respostaJson(500, <String, Object>{'codigo': 'ERRO_INESPERADO'}),
      );
      await falhaDaChamada();

      montar(aceita: 'acesso-2');
      await chamadas.executar(chamada);

      expect(sessaoPerdida.avisos, 0);
    });
  });
}
