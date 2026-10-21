import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora_api/memora_api.dart' as api;

/// Servidor de mentira no nível do transporte do Dio.
///
/// Nada de rede e nada de timer: o teste de repositório roda como `test`
/// puro, sem `testWidgets`, porque I/O e relógio falso não combinam (ver
/// CLAUDE.md, seção 8). O que passa pelo adaptador é o `Dio` **de verdade**,
/// com os interceptores de autenticação do cliente gerado — então o cabeçalho
/// `Authorization` que o teste confere é o que iria para a rede.
class AdaptadorFalso implements HttpClientAdapter {
  /// Responde a cada pedido. [numero] conta de 1, em todos os pedidos.
  final Future<ResponseBody> Function(RequestOptions opcoes, int numero)
  responder;

  /// Os pedidos que chegaram, na ordem.
  final List<RequestOptions> pedidos = <RequestOptions>[];

  /// Cria o adaptador.
  AdaptadorFalso(this.responder);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    pedidos.add(options);
    return responder(options, pedidos.length);
  }

  @override
  void close({bool force = false}) {}
}

/// O cliente gerado, montado sobre um [AdaptadorFalso].
api.MemoraApi clienteFalso(AdaptadorFalso adaptador) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://servidor.teste/v1'))
    ..httpClientAdapter = adaptador;
  return api.MemoraApi(dio: dio);
}

/// Resposta JSON, como o servidor responde catálogo, registro e erros.
ResponseBody respostaJson(int status, Object corpo) => ResponseBody.fromString(
  jsonEncode(corpo),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>['application/json'],
  },
);

/// Resposta `text/event-stream` entregue em [pedacos], um por vez.
ResponseBody respostaSse(List<String> pedacos, {int status = 200}) =>
    respostaSseDeBytes(<List<int>>[
      for (final String p in pedacos) utf8.encode(p),
    ], status: status);

/// Como [respostaSse], mas com os bytes já cortados onde o teste quiser.
ResponseBody respostaSseDeBytes(List<List<int>> pedacos, {int status = 200}) =>
    ResponseBody(
      Stream<Uint8List>.fromIterable(
        pedacos.map((List<int> b) => Uint8List.fromList(b)),
      ),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/event-stream'],
      },
    );

/// Um evento SSE no formato que o servidor emite.
String evento(String nome, [String dados = '']) =>
    'event:$nome\ndata:$dados\n\n';

/// Cofre em memória, com os dois tokens à vista do teste.
class CofreEmMemoria implements CofreDeCredenciais {
  /// Token de acesso guardado.
  String? acesso;

  /// Refresh token guardado.
  String? refresh;

  /// Cria o cofre, já com uma sessão.
  CofreEmMemoria({this.acesso = 'acesso-1', this.refresh = 'refresh-1'});

  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {
    acesso = tokenAcesso;
    refresh = refreshToken;
  }

  @override
  Future<String?> tokenAcesso() async => acesso;

  @override
  Future<String?> refreshToken() async => refresh;

  @override
  Future<void> limpar() async {
    acesso = null;
    refresh = null;
  }
}

/// Uma renovação de mentira: conta as chamadas e grava o par novo no cofre,
/// como a `RepositorioAutenticacaoApi.renovarSessao` de verdade faz.
class RenovadorFalso {
  /// O cofre onde o par novo é gravado.
  final CofreEmMemoria cofre;

  /// Quantas renovações foram pedidas.
  int chamadas = 0;

  /// Quanto a renovação demora. Dá a duas chamadas tempo de se encontrarem.
  final Completer<void>? portao;

  /// Se verdadeiro, a renovação é recusada.
  final bool recusar;

  /// Se verdadeiro, a renovação falha por falta de rede.
  final bool semRede;

  /// Cria o renovador.
  RenovadorFalso(
    this.cofre, {
    this.portao,
    this.recusar = false,
    this.semRede = false,
  });

  /// O que o `ChamadaComRenovacao` chama.
  Future<ResultadoAutenticacao> renovar() async {
    chamadas++;
    await portao?.future;
    if (semRede) {
      return const AutenticacaoFalhou(FalhaAutenticacao.semConexao);
    }
    if (recusar) {
      return const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas);
    }
    await cofre.guardarSessao(
      tokenAcesso: 'acesso-${chamadas + 1}',
      refreshToken: 'refresh-${chamadas + 1}',
    );
    return const AutenticacaoConcluida(
      PessoaAutenticada(id: 'p', nomeTratamento: 'Ana'),
    );
  }
}
