//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:memora_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:memora_api/src/model/auth_recuperacao_confirmar_post_request.dart';
import 'package:memora_api/src/model/auth_recuperacao_solicitar_post202_response.dart';
import 'package:memora_api/src/model/auth_recuperacao_solicitar_post_request.dart';
import 'package:memora_api/src/model/erro.dart';
import 'package:memora_api/src/model/sessao_resposta.dart';

class RecuperaoDeAcessoApi {

  final Dio _dio;

  const RecuperaoDeAcessoApi(this._dio);

  /// Definir nova senha
  /// Troca a senha e **revoga todas as sessões ativas** (FR-021). A pessoa é notificada pelo canal cadastrado (FR-022). 
  ///
  /// Parameters:
  /// * [authRecuperacaoConfirmarPostRequest] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [SessaoResposta] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<SessaoResposta>> authRecuperacaoConfirmarPost({ 
    required AuthRecuperacaoConfirmarPostRequest authRecuperacaoConfirmarPostRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/auth/recuperacao/confirmar';
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
_bodyData=jsonEncode(authRecuperacaoConfirmarPostRequest);
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

  /// Solicitar recuperação de acesso
  /// Responde **202 sempre**, exista a conta ou não (FR-019). O texto devolvido é idêntico nos dois casos.  Só envia para canal **verificado**. 
  ///
  /// Parameters:
  /// * [authRecuperacaoSolicitarPostRequest] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AuthRecuperacaoSolicitarPost202Response] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AuthRecuperacaoSolicitarPost202Response>> authRecuperacaoSolicitarPost({ 
    required AuthRecuperacaoSolicitarPostRequest authRecuperacaoSolicitarPostRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/auth/recuperacao/solicitar';
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
_bodyData=jsonEncode(authRecuperacaoSolicitarPostRequest);
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

    AuthRecuperacaoSolicitarPost202Response? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<AuthRecuperacaoSolicitarPost202Response, AuthRecuperacaoSolicitarPost202Response>(rawData, 'AuthRecuperacaoSolicitarPost202Response', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AuthRecuperacaoSolicitarPost202Response>(
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
