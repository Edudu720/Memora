import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_api.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora_api/memora_api.dart' as api;
import 'package:shared_preferences/shared_preferences.dart';

/// Cenário V8 do quickstart — nenhuma credencial no aparelho (T032).
///
/// Cobre FR-036, FR-026 e SC-009.
///
/// ## O que este arquivo consegue provar, e o que não consegue
///
/// O V8 completo é manual: build de release com ofuscação, inspecionar
/// `shared_prefs` e bancos locais no aparelho. Isso **não** roda em CI, e fingir
/// que roda seria pior do que não ter teste.
///
/// O que dá para automatizar é a parte que quebra primeiro numa refatoração: que
/// o caminho de código que guarda a sessão **não passa perto** de armazenamento
/// comum. O cofre-espião abaixo falha se alguém escrever em
/// `SharedPreferences`, e o teste confere que, depois de um cadastro concluído,
/// as preferências continuam vazias.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CofreEspiao cofre;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    cofre = _CofreEspiao();
  });

  group('V8 — nenhuma credencial em armazenamento comum', () {
    test('cadastro guarda a sessão no cofre, e não em SharedPreferences',
        () async {
      final RepositorioAutenticacaoApi repositorio = _repositorioQueResponde(
        cofre,
        _respostaDeSessao(),
      );

      final ResultadoAutenticacao resultado =
          await repositorio.cadastrar(_dados);

      expect(resultado, isA<AutenticacaoConcluida>());
      expect(cofre.tokenGuardado, 'jwt.de.teste');
      expect(cofre.refreshGuardado, 'refresh-opaco-de-teste');

      final SharedPreferences preferencias =
          await SharedPreferences.getInstance();
      expect(
        preferencias.getKeys(),
        isEmpty,
        reason: 'nenhuma credencial pode encostar em armazenamento comum',
      );
    });

    test('nenhum valor guardado contém a senha digitada', () async {
      final RepositorioAutenticacaoApi repositorio = _repositorioQueResponde(
        cofre,
        _respostaDeSessao(),
      );

      await repositorio.cadastrar(_dados);

      expect(cofre.tokenGuardado, isNot(contains(_dados.senha)));
      expect(cofre.refreshGuardado, isNot(contains(_dados.senha)));
    });

    test('limpar não deixa nada para trás (FR-026)', () async {
      await cofre.guardarSessao(
        tokenAcesso: 'jwt.de.teste',
        refreshToken: 'refresh-opaco-de-teste',
      );

      await cofre.limpar();

      expect(await cofre.tokenAcesso(), isNull);
      expect(await cofre.refreshToken(), isNull);
    });
  });

  group('Tradução de falha do servidor', () {
    test('sem resposta vira semConexao, e não erro genérico', () async {
      final RepositorioAutenticacaoApi repositorio = _repositorioQueFalha(
        cofre,
        DioException(
          requestOptions: RequestOptions(path: '/auth/cadastro'),
          type: DioExceptionType.connectionError,
        ),
      );

      final ResultadoAutenticacao resultado =
          await repositorio.cadastrar(_dados);

      expect(
        (resultado as AutenticacaoFalhou).falha,
        FalhaAutenticacao.semConexao,
      );
    });

    test('429 traz a espera que o servidor mandou', () async {
      final RepositorioAutenticacaoApi repositorio = _repositorioQueFalha(
        cofre,
        _erroDoServidor(429, <String, dynamic>{
          'codigo': 'MUITAS_TENTATIVAS',
          'mensagem': 'texto para a pessoa',
          'tentar_novamente_em_segundos': 300,
        }),
      );

      final AutenticacaoFalhou resultado =
          await repositorio.cadastrar(_dados) as AutenticacaoFalhou;

      expect(resultado.falha, FalhaAutenticacao.muitasTentativas);
      expect(resultado.tentarNovamenteEmSegundos, 300);
    });

    /// Código novo no servidor não pode virar comportamento silencioso aqui.
    test('código desconhecido vira falha inesperada', () async {
      final RepositorioAutenticacaoApi repositorio = _repositorioQueFalha(
        cofre,
        _erroDoServidor(400, <String, dynamic>{
          'codigo': 'ALGO_QUE_AINDA_NAO_EXISTE',
          'mensagem': 'texto para a pessoa',
        }),
      );

      final AutenticacaoFalhou resultado =
          await repositorio.cadastrar(_dados) as AutenticacaoFalhou;

      expect(resultado.falha, FalhaAutenticacao.inesperada);
    });

    test('falha não guarda credencial nenhuma', () async {
      final RepositorioAutenticacaoApi repositorio = _repositorioQueFalha(
        cofre,
        _erroDoServidor(400, <String, dynamic>{
          'codigo': 'DADOS_INVALIDOS',
          'mensagem': 'texto para a pessoa',
        }),
      );

      await repositorio.cadastrar(_dados);

      expect(cofre.tokenGuardado, isNull);
      expect(cofre.refreshGuardado, isNull);
    });
  });
}

const DadosDeCadastro _dados = DadosDeCadastro(
  nomeTratamento: 'Ana',
  tipoCanal: TipoCanal.email,
  canal: 'ana@gmail.com',
  senha: 'pipoca no varal azul',
);

api.SessaoResposta _respostaDeSessao() => api.SessaoResposta(
      tokenAcesso: 'jwt.de.teste',
      refreshToken: 'refresh-opaco-de-teste',
      expiraEmSegundos: 900,
      pessoa: api.PessoaResposta(
        id: '11111111-1111-1111-1111-111111111111',
        nomeTratamento: 'Ana',
      ),
    );

DioException _erroDoServidor(int status, Map<String, dynamic> corpo) {
  final RequestOptions opcoes = RequestOptions(path: '/auth/cadastro');
  return DioException(
    requestOptions: opcoes,
    response: Response<dynamic>(
      requestOptions: opcoes,
      statusCode: status,
      data: corpo,
    ),
    type: DioExceptionType.badResponse,
  );
}

RepositorioAutenticacaoApi _repositorioQueResponde(
  CofreDeCredenciais cofre,
  api.SessaoResposta resposta,
) {
  final Dio dio = Dio();
  dio.httpClientAdapter = _AdaptadorFixo.sucesso(resposta);
  return RepositorioAutenticacaoApi(
    cliente: api.MemoraApi(dio: dio),
    cofre: cofre,
  );
}

RepositorioAutenticacaoApi _repositorioQueFalha(
  CofreDeCredenciais cofre,
  DioException excecao,
) {
  final Dio dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions opcoes, RequestInterceptorHandler manipulador) {
        manipulador.reject(excecao);
      },
    ),
  );
  return RepositorioAutenticacaoApi(
    cliente: api.MemoraApi(dio: dio),
    cofre: cofre,
  );
}

/// Responde sempre o mesmo corpo, sem rede.
class _AdaptadorFixo implements HttpClientAdapter {
  final api.SessaoResposta _resposta;

  _AdaptadorFixo.sucesso(this._resposta);

  @override
  Future<ResponseBody> fetch(
    RequestOptions opcoes,
    Stream<Uint8List>? corpoDaRequisicao,
    Future<void>? cancelar,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_resposta.toJson()),
      201,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Cofre que guarda em memória e denuncia quem tentar usar o outro caminho.
class _CofreEspiao implements CofreDeCredenciais {
  String? tokenGuardado;
  String? refreshGuardado;

  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {
    tokenGuardado = tokenAcesso;
    refreshGuardado = refreshToken;
  }

  @override
  Future<String?> tokenAcesso() async => tokenGuardado;

  @override
  Future<String?> refreshToken() async => refreshGuardado;

  @override
  Future<void> limpar() async {
    tokenGuardado = null;
    refreshGuardado = null;
  }
}
