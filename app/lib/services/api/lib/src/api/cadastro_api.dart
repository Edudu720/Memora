//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:memora_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:memora_api/src/model/cadastro_requisicao.dart';
import 'package:memora_api/src/model/erro.dart';
import 'package:memora_api/src/model/sessao_resposta.dart';

class CadastroApi {

  final Dio _dio;

  const CadastroApi(this._dio);

  /// Criar conta
  /// Cria a conta e **já devolve sessão iniciada** (FR-009). A pessoa não precisa fazer login em seguida.  Exige **apenas um** canal de contato (FR-049). O segundo é oferecido depois do primeiro acesso (FR-050).  Se o canal já pertencer a uma conta, responde **201 da mesma forma**, sem criar nada e sem revelar a existência (FR-010). O aplicativo conduz a pessoa ao login conforme o cenário 5 da User Story 1. 
  ///
  /// Parameters:
  /// * [cadastroRequisicao] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [SessaoResposta] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<SessaoResposta>> authCadastroPost({ 
    required CadastroRequisicao cadastroRequisicao,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/auth/cadastro';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
_bodyData=jsonEncode(cadastroRequisicao);
    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    SessaoResposta? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<SessaoResposta, SessaoResposta>(rawData, 'SessaoResposta', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<SessaoResposta>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
