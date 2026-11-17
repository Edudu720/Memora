import 'package:dio/dio.dart';

import '../../../assistente/data/chamada_com_renovacao.dart';
import '../../../assistente/domain/assistente.dart';
import '../../domain/entidades/contato_emergencia.dart';
import '../../domain/entidades/evento_emergencia_sos.dart';
import '../../domain/repositorios/repositorio_emergencia_sos.dart';

/// Cliente HTTP autenticado para encaminhar solicitações SOS ao backend Memora.
class RepositorioEmergenciaSosApi implements RepositorioEmergenciaSos {
  /// Cliente HTTP configurado pelo aplicativo.
  final Dio dio;

  /// Envolvedor opcional para renovar a sessão em silêncio diante de 401.
  final ChamadaComRenovacao? chamadaAutenticada;

  /// Cria o repositório remoto do botão SOS.
  const RepositorioEmergenciaSosApi({
    required this.dio,
    this.chamadaAutenticada,
  });

  String get _rotaSos {
    final String base = dio.options.baseUrl.trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    return base.endsWith('/v1')
        ? '/emergencias/sos'
        : '/api/v1/emergencias/sos';
  }

  @override
  Future<EventoEmergenciaSos> solicitarSos({
    required String eventoId,
    required TipoEventoEmergencia tipo,
    LocalizacaoSos? localizacao,
    ContatoEmergencia? contato,
  }) async {
    final String destinoRemoto = contato?.destinoNotificacaoRemota ?? '';
    final Map<String, dynamic> corpo = <String, dynamic>{
      'eventoId': eventoId,
      'tipo': tipo.codigoApi,
      if (localizacao != null) 'localizacao': localizacao.toJson(),
      if (contato != null && contato.nome.trim().isNotEmpty)
        'contatoNome': contato.nome.trim(),
      if (destinoRemoto.isNotEmpty) 'contatoDestino': destinoRemoto,
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
        dio.post<dynamic>(_rotaSos, data: corpo, options: opcoes);

    try {
      final Response<dynamic> response = chamadaAutenticada != null
          ? await chamadaAutenticada!.executar<Response<dynamic>>(executarPost)
          : await executarPost();

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        return EventoEmergenciaSos.fromJson(
          response.data as Map<String, dynamic>,
          localizacaoEnviada: localizacao,
          contatoNotificado: contato?.nome,
        );
      }

      throw Exception('Resposta inesperada ao encaminhar pedido SOS');
    } on FalhaDeChamadaDaAssistente catch (e) {
      if (e.falha == FalhaDaAssistente.semConexao) {
        throw const FalhaDeConexaoSosException();
      }
      rethrow;
    } on DioException catch (e) {
      if (_ehFalhaDeConexao(e)) {
        throw FalhaDeConexaoSosException(e.message ?? 'Falha de conexão');
      }
      rethrow;
    }
  }

  bool _ehFalhaDeConexao(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }
}
