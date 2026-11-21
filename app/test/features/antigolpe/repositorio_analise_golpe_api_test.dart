import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/antigolpe/data/repositorios/repositorio_analise_golpe_api.dart';
import 'package:memora/features/antigolpe/data/repositorios/repositorio_analise_golpe_simulado.dart';
import 'package:memora/features/antigolpe/domain/entidades/analise_golpe.dart';
import 'package:memora/features/antigolpe/domain/repositorios/repositorio_analise_golpe.dart';
import 'package:memora/features/assistente/data/chamada_com_renovacao.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/services/seguranca/sessao_perdida.dart';
import 'package:memora_api/memora_api.dart' as api;

import '../assistente/suporte_da_api_falsa.dart';

void main() {
  Map<String, Object?> payloadApi({
    String risco = 'ALTO',
    String titulo = 'Cuidado: link suspeito',
    String explicacao = 'O endereço imita um banco conhecido.',
    List<String> orientacoes = const <String>['Não toque no link.'],
    List<String> sinaisDetectados = const <String>['Domínio falso.'],
    bool analisadoPorIa = true,
  }) => <String, Object?>{
    'risco': risco,
    'titulo': titulo,
    'explicacao': explicacao,
    'orientacoes': orientacoes,
    'sinaisDetectados': sinaisDetectados,
    'analisadoPorIa': analisadoPorIa,
  };

  group('RepositorioAnaliseGolpeApi — chamadas online e mapeamento', () {
    test('normaliza /golpes/analisar com baseUrl /v1 e mapeia BAIXO/MEDIO/ALTO', () async {
      final CofreEmMemoria cofre = CofreEmMemoria(acesso: 'token-ok');
      final RenovadorFalso renovador = RenovadorFalso(cofre);
      final AdaptadorFalso adaptador = AdaptadorFalso((
        RequestOptions op,
        int numero,
      ) async {
        final String risco = switch (numero) {
          1 => 'BAIXO',
          2 => 'MEDIO',
          _ => 'ALTO',
        };
        return respostaJson(200, payloadApi(risco: risco));
      });

      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: cliente.dio,
        chamadas: ChamadaComRenovacao(
          cliente: cliente,
          cofre: cofre,
          renovar: renovador.renovar,
        ),
      );

      final AnaliseGolpe baixo = await repo.analisar('Oi mãe, tudo bem?');
      final AnaliseGolpe medio = await repo.analisar('Ganhou um brinde hoje');
      final AnaliseGolpe alto = await repo.analisar('https://bit.ly/golpe');

      expect(adaptador.pedidos.length, 3);
      expect(adaptador.pedidos[0].path, '/golpes/analisar');
      expect(adaptador.pedidos[0].method, 'POST');
      expect(
        adaptador.pedidos[0].headers['Authorization'],
        'Bearer token-ok',
      );
      expect(adaptador.pedidos[0].data, <String, dynamic>{
        'conteudo': 'Oi mãe, tudo bem?',
      });

      expect(baixo.risco, NivelRisco.seguro);
      expect(baixo.origem, OrigemAnalise.servidorIa);
      expect(baixo.analisadoPorIa, isTrue);

      expect(medio.risco, NivelRisco.atencao);
      expect(alto.risco, NivelRisco.altoRisco);
    });

    test('mapeia origem para servidorRegras quando analisadoPorIa é false na resposta do servidor', () async {
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async => respostaJson(
          200,
          payloadApi(analisadoPorIa: false),
        ),
      );
      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: cliente.dio,
      );

      final AnaliseGolpe resultado = await repo.analisar(
        'Acesse http://192.168.0.1/banco',
      );

      expect(resultado.analisadoPorIa, isFalse);
      expect(resultado.origem, OrigemAnalise.servidorRegras);
      expect(resultado.ehOffline, isFalse);
    });

    test('usa /v1/golpes/analisar quando baseUrl não termina em /v1', () async {
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async =>
            respostaJson(200, payloadApi(risco: 'BAIXO')),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://servidor.teste'))
        ..httpClientAdapter = adaptador;

      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: dio,
      );
      await repo.analisar('Mensagem comum de bom dia');

      expect(adaptador.pedidos.single.path, '/v1/golpes/analisar');
    });
  });

  group('RepositorioAnaliseGolpeApi — 401 e sessão expirada', () {
    test('renova o token em silêncio no 401 e repete a análise', () async {
      final CofreEmMemoria cofre = CofreEmMemoria(acesso: 'token-vencido');
      final RenovadorFalso renovador = RenovadorFalso(cofre);
      final AdaptadorFalso adaptador = AdaptadorFalso((
        RequestOptions op,
        int numero,
      ) async {
        if (numero == 1) {
          return respostaJson(401, <String, Object>{'erro': 'EXPIRADO'});
        }
        return respostaJson(200, payloadApi(risco: 'BAIXO'));
      });

      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: cliente.dio,
        chamadas: ChamadaComRenovacao(
          cliente: cliente,
          cofre: cofre,
          renovar: renovador.renovar,
        ),
      );

      final AnaliseGolpe resultado = await repo.analisar('Oi, tudo certo?');

      expect(renovador.chamadas, 1);
      expect(adaptador.pedidos.length, 2);
      expect(
        adaptador.pedidos[1].headers['Authorization'],
        'Bearer acesso-2',
      );
      expect(resultado.origem, OrigemAnalise.servidorIa);
    });

    test('NÃO faz fallback offline quando a renovação falha: propaga sessaoExpirada e avisa SessaoPerdida', () async {
      final CofreEmMemoria cofre = CofreEmMemoria(acesso: 'token-vencido');
      final RenovadorFalso renovador = RenovadorFalso(cofre, recusar: true);
      final SessaoPerdida sessaoPerdida = SessaoPerdida();
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async =>
            respostaJson(401, <String, Object>{'erro': 'INVALIDO'}),
      );

      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: cliente.dio,
        chamadas: ChamadaComRenovacao(
          cliente: cliente,
          cofre: cofre,
          renovar: renovador.renovar,
          sessaoPerdida: sessaoPerdida,
        ),
      );

      await expectLater(
        repo.analisar('Clique aqui https://bit.ly/teste'),
        throwsA(
          isA<FalhaDeChamadaDaAssistente>().having(
            (FalhaDeChamadaDaAssistente e) => e.falha,
            'falha',
            FalhaDaAssistente.sessaoExpirada,
          ),
        ),
      );
      expect(sessaoPerdida.avisos, 1);
    });
  });

  group('RepositorioAnaliseGolpeApi — fallback local offline e HTTP 429', () {
    test('cai para fallback local em erro de conexão para mensagem segura e suspeita', () async {
      final AdaptadorFalso adaptador = AdaptadorFalso((
        RequestOptions op,
        int n,
      ) async {
        throw DioException.connectionError(
          requestOptions: op,
          reason: 'Sem internet',
        );
      });
      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: cliente.dio,
      );

      final AnaliseGolpe seguro = await repo.analisar(
        'Bom dia, mãe! Chego para o almoço.',
      );
      final AnaliseGolpe suspeito = await repo.analisar(
        'Urgente: sua conta foi bloqueada. Envie a senha em http://192.168.0.2/banco',
      );

      expect(seguro.origem, OrigemAnalise.localOffline);
      expect(seguro.analisadoPorIa, isFalse);
      expect(seguro.risco, NivelRisco.seguro);

      expect(suspeito.origem, OrigemAnalise.localOffline);
      expect(suspeito.analisadoPorIa, isFalse);
      expect(suspeito.risco, NivelRisco.altoRisco);
    });

    test('cai para fallback local em timeout, 500 e 503', () async {
      for (final Future<ResponseBody> Function(RequestOptions op) falha
          in <Future<ResponseBody> Function(RequestOptions op)>[
            (RequestOptions op) => Future<ResponseBody>.error(
              DioException.receiveTimeout(
                timeout: const Duration(seconds: 15),
                requestOptions: op,
              ),
            ),
            (_) async => respostaJson(500, <String, Object>{'erro': 'interno'}),
            (_) async =>
                respostaJson(503, <String, Object>{'erro': 'indisponivel'}),
          ]) {
        final AdaptadorFalso adaptador = AdaptadorFalso(
          (RequestOptions op, int n) => falha(op),
        );
        final api.MemoraApi cliente = clienteFalso(adaptador);
        final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
          dio: cliente.dio,
        );

        final AnaliseGolpe res = await repo.analisar(
          'Último aviso: clique em https://bit.ly/abc para desbloquear',
        );
        expect(res.origem, OrigemAnalise.localOffline);
        expect(res.analisadoPorIa, isFalse);
        expect(res.risco, NivelRisco.altoRisco);
      }
    });

    test('NÃO mascara HTTP 429 como offline: lança FalhaAnaliseGolpe(limiteExcedido) com esperaEmSegundos', () async {
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async => ResponseBody.fromString(
          '{"erro":"LIMITE_EXCEDIDO","tentarNovamenteEmSegundos":42}',
          429,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            'retry-after': <String>['42'],
          },
        ),
      );
      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: cliente.dio,
      );

      await expectLater(
        repo.analisar('Mensagem qualquer'),
        throwsA(
          isA<FalhaAnaliseGolpe>()
              .having(
                (FalhaAnaliseGolpe e) => e.tipo,
                'tipo',
                FalhaAnaliseGolpeTipo.limiteExcedido,
              )
              .having(
                (FalhaAnaliseGolpe e) => e.esperaEmSegundos,
                'esperaEmSegundos',
                42,
              )
              .having(
                (FalhaAnaliseGolpe e) => e.statusCode,
                'statusCode',
                429,
              ),
        ),
      );
    });

    test('cai para fallback local quando renovação falha por semRede', () async {
      final CofreEmMemoria cofre = CofreEmMemoria(acesso: 'token-vencido');
      final RenovadorFalso renovador = RenovadorFalso(cofre, semRede: true);
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async =>
            respostaJson(401, <String, Object>{'erro': 'EXPIRADO'}),
      );
      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: cliente.dio,
        chamadas: ChamadaComRenovacao(
          cliente: cliente,
          cofre: cofre,
          renovar: renovador.renovar,
        ),
      );

      final AnaliseGolpe res = await repo.analisar(
        'Bom dia, tudo bem por aí?',
      );
      expect(res.origem, OrigemAnalise.localOffline);
      expect(res.risco, NivelRisco.seguro);
    });

    test('propaga ErroRequisicaoAnaliseException no 400 Bad Request sem mascarar como offline', () async {
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async =>
            respostaJson(400, <String, Object>{'mensagem': 'invalido'}),
      );
      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioAnaliseGolpeApi repo = RepositorioAnaliseGolpeApi(
        dio: cliente.dio,
      );

      await expectLater(
        repo.analisar('texto valido'),
        throwsA(isA<ErroRequisicaoAnaliseException>()),
      );
    });
  });

  group('RepositorioAnaliseGolpeSimulado', () {
    test('diferencia modo online simulado (servidorRegras) de modo offline simulado (localOffline)', () async {
      const RepositorioAnaliseGolpeSimulado online =
          RepositorioAnaliseGolpeSimulado();
      const RepositorioAnaliseGolpeSimulado offline =
          RepositorioAnaliseGolpeSimulado(modoOffline: true);

      final AnaliseGolpe rOnline = await online.analisar(
        'Urgente: envie seu código de 6 dígitos no link https://bit.ly/abc',
      );
      final AnaliseGolpe rOffline = await offline.analisar(
        'Urgente: envie seu código de 6 dígitos no link https://bit.ly/abc',
      );

      expect(rOnline.origem, OrigemAnalise.servidorRegras);
      expect(rOnline.analisadoPorIa, isFalse);
      expect(rOnline.risco, NivelRisco.altoRisco);

      expect(rOffline.origem, OrigemAnalise.localOffline);
      expect(rOffline.analisadoPorIa, isFalse);
      expect(rOffline.risco, NivelRisco.altoRisco);
    });
  });
}
