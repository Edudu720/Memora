import 'package:dio/dio.dart';

import '../../../../l10n/textos_antigolpe.dart';
import '../../../assistente/data/chamada_com_renovacao.dart';
import '../../../assistente/domain/assistente.dart';
import '../../domain/entidades/analise_golpe.dart';
import '../../domain/repositorios/repositorio_analise_golpe.dart';
import '../../domain/servicos/analisador_local_de_golpes.dart';

/// Repositório remoto para análise de risco de golpes via `POST /v1/golpes/analisar`,
/// com fallback automático para [AnalisadorLocalDeGolpes] quando não há conexão,
/// ocorre timeout ou o servidor está indisponível.
///
/// Nunca aciona fallback local quando a sessão expirou
/// ([FalhaDaAssistente.sessaoExpirada]), permitindo que `SessaoPerdida`
/// conduza a pessoa de volta à entrada.
class RepositorioAnaliseGolpeApi implements RepositorioAnaliseGolpe {
  final Dio _dio;
  final ChamadaComRenovacao? _chamadas;
  final AnalisadorLocalDeGolpes _analisadorLocal;

  /// Cria o repositório remoto com fallback offline determinístico.
  const RepositorioAnaliseGolpeApi({
    required Dio dio,
    ChamadaComRenovacao? chamadas,
    AnalisadorLocalDeGolpes analisadorLocal = const AnalisadorLocalDeGolpes(),
  }) : _dio = dio,
       _chamadas = chamadas,
       _analisadorLocal = analisadorLocal;

  String get _caminhoAnalisar {
    final String base = _dio.options.baseUrl.trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    return base.endsWith('/v1') ? '/golpes/analisar' : '/v1/golpes/analisar';
  }

  @override
  Future<AnaliseGolpe> analisar(String conteudo) async {
    final String textoLimpo = conteudo.trim();
    if (textoLimpo.isEmpty) {
      throw const ConteudoAnaliseInvalidoException(TextosAntigolpe.erroVazio);
    }
    if (textoLimpo.length > AnalisadorLocalDeGolpes.limiteCaracteres) {
      throw const ConteudoAnaliseInvalidoException(
        TextosAntigolpe.erroMuitoLongo,
      );
    }

    final Options opcoes = Options(
      contentType: 'application/json',
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          <String, String>{
            'type': 'http',
            'scheme': 'bearer',
            'name': 'tokenDeAcesso',
          },
        ],
      },
    );

    Future<Response<dynamic>> executarPost() => _dio.post<dynamic>(
      _caminhoAnalisar,
      data: <String, dynamic>{'conteudo': textoLimpo},
      options: opcoes,
    );

    try {
      final Response<dynamic> resposta = _chamadas != null
          ? await _chamadas.executar<Response<dynamic>>(executarPost)
          : await executarPost();
      return _interpretarResposta(resposta.data);
    } on FalhaDeChamadaDaAssistente catch (e) {
      if (e.falha == FalhaDaAssistente.sessaoExpirada) {
        rethrow;
      }
      return _analisadorLocal.analisar(textoLimpo);
    } on DioException catch (e) {
      soltarCorpoDaResposta(e);
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      if (_deveUsarFallbackOffline(e)) {
        return _analisadorLocal.analisar(textoLimpo);
      }
      throw ErroRequisicaoAnaliseException(
        TextosAntigolpe.erroInesperado,
        statusCode: e.response?.statusCode,
      );
    } on FormatException {
      return _analisadorLocal.analisar(textoLimpo);
    } on TypeError {
      return _analisadorLocal.analisar(textoLimpo);
    }
  }

  AnaliseGolpe _interpretarResposta(Object? bruto) {
    if (bruto is! Map) {
      throw const FormatException('Resposta de analise nao e um objeto JSON.');
    }
    final Map<String, dynamic> dados = Map<String, dynamic>.from(bruto);
    final NivelRisco risco = NivelRisco.deCodigoApi(dados['risco'] as String?);
    final String titulo = (dados['titulo'] as String? ?? '').trim();
    final String explicacao = (dados['explicacao'] as String? ?? '').trim();
    if (titulo.isEmpty || explicacao.isEmpty) {
      throw const FormatException('Titulo ou explicacao ausente na resposta.');
    }

    final List<String> orientacoes = _lerListaDeTextos(dados['orientacoes']);
    final List<String> sinaisDetectados = _lerListaDeTextos(
      dados['sinaisDetectados'],
    );
    final bool analisadoPorIa = dados['analisadoPorIa'] as bool? ?? true;

    return AnaliseGolpe(
      risco: risco,
      origem: OrigemAnalise.servidorIa,
      titulo: titulo,
      explicacao: explicacao,
      orientacoes: orientacoes,
      sinaisDetectados: sinaisDetectados,
      analisadoPorIa: analisadoPorIa,
    );
  }

  List<String> _lerListaDeTextos(Object? valor) {
    if (valor == null) return const <String>[];
    if (valor is! List) {
      throw const FormatException('Campo de lista invalido na resposta.');
    }
    return List<String>.unmodifiable(
      valor
          .map((Object? item) => (item as String).trim())
          .where((String texto) => texto.isNotEmpty),
    );
  }

  bool _deveUsarFallbackOffline(DioException e) {
    if (e.response == null) {
      return true;
    }
    final int status = e.response!.statusCode ?? 0;
    return status >= 500 || status == 429;
  }
}
