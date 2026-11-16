import 'package:dio/dio.dart';

import '../../../assistente/data/chamada_com_renovacao.dart';
import '../../domain/entidades/categoria_servico.dart';
import '../../domain/repositorios/repositorio_localizador.dart';
import '../modelos/estabelecimento_servico_dto.dart';

/// Cliente HTTP autenticado para a busca de serviços essenciais (`/v1/servicos/buscar`).
class FonteLocalizadorApi {
  /// Cliente HTTP configurado pelo aplicativo.
  final Dio dio;

  /// Envolvedor para renovar o token ao receber 401/403.
  final ChamadaComRenovacao? chamadas;

  /// Cria uma instância de [FonteLocalizadorApi].
  const FonteLocalizadorApi(this.dio, {this.chamadas});

  String get _caminhoBuscar {
    final String base = dio.options.baseUrl.trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    return base.endsWith('/v1')
        ? '/servicos/buscar'
        : '/api/v1/servicos/buscar';
  }

  /// Executa a busca autenticada no endpoint `/servicos/buscar`.
  Future<ResultadoBuscaServicos> buscarServicos({
    String? consulta,
    CategoriaServico? categoria,
    double? latitude,
    double? longitude,
    String? regiaoManual,
    int? raioMetros,
  }) async {
    final Map<String, dynamic> corpo = <String, dynamic>{
      if (consulta != null && consulta.trim().isNotEmpty)
        'consulta': consulta.trim(),
      if (categoria != null) 'categoria': categoria.name.toUpperCase(),
      if (latitude != null && longitude != null)
        'localizacao': <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
        },
      if (regiaoManual != null && regiaoManual.trim().isNotEmpty)
        'regiaoManual': regiaoManual.trim(),
      'raioMetros': ?raioMetros,
    };

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

    Future<Response<dynamic>> executarPost() =>
        dio.post<dynamic>(_caminhoBuscar, data: corpo, options: opcoes);

    final Response<dynamic> response = chamadas != null
        ? await chamadas!.executar<Response<dynamic>>(executarPost)
        : await executarPost();

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return EstabelecimentoServicoDto.deJson(
        response.data as Map<String, dynamic>,
      );
    }

    throw Exception('Falha ao obter serviços da rede pública');
  }
}
