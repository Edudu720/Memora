//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:memora_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:memora_api/src/model/assistente_acao_post_request.dart';
import 'package:memora_api/src/model/assistente_conversa_post_request.dart';
import 'package:memora_api/src/model/assistente_registro_get200_response.dart';
import 'package:memora_api/src/model/erro.dart';

class AssistenteApi {

  final Dio _dio;

  const AssistenteApi(this._dio);

  /// Registrar que a pessoa confirmou e o aplicativo executou
  /// Escreve a trilha da FR-020. Quem abre o outro aplicativo é o Flutter, depois da confirmação; este endpoint só registra que aconteceu.  O servidor **reconfere** a autorização antes de gravar: um pedido de registro para serviço sensível é recusado e vira &#x60;ACAO_RECUSADA&#x60; na trilha — se ele chegou aqui, algo está errado, e o registro disso vale mais do que a recusa silenciosa. 
  ///
  /// Parameters:
  /// * [assistenteAcaoPostRequest] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> assistenteAcaoPost({ 
    required AssistenteAcaoPostRequest assistenteAcaoPostRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/assistente/acao';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'tokenDeAcesso',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
_bodyData=jsonEncode(assistenteAcaoPostRequest);
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

    return _response;
  }

  /// Conversar com a assistente
  /// Recebe o histórico e a mensagem nova, e transmite a resposta por **Server-Sent Events**. O público do Memora é o que menos tolera tela parada: ver o texto aparecendo é o que diferencia \&quot;está pensando\&quot; de \&quot;travou\&quot; (SC-007).  O campo &#x60;acao&#x60; de um evento &#x60;acao&#x60; **já passou** pelo catálogo. Sugestão do modelo que não passa nunca chega aqui.  **Falha da conversa nunca vira status HTTP.** Limite diário de conversas e provedor indisponível chegam como evento &#x60;erro&#x60; dentro do stream, com a resposta HTTP já &#x60;200&#x60; (clarificação de 2026-10-03, FR-053 e FR-057). Por isso esta operação **não** declara &#x60;429&#x60; nem &#x60;503&#x60;. 
  ///
  /// Parameters:
  /// * [assistenteConversaPostRequest] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [String] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<String>> assistenteConversaPost({ 
    required AssistenteConversaPostRequest assistenteConversaPostRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/assistente/conversa';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'tokenDeAcesso',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
_bodyData=jsonEncode(assistenteConversaPostRequest);
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

    String? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<String, String>(rawData, 'String', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<String>(
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

  /// O que a Memora fez em meu nome
  /// A FR-023. Devolve as ações executadas, em linguagem comum. Orientação apenas ensinada **não** aparece aqui (FR-025) — ela não foi executada por ninguém além da própria pessoa. 
  ///
  /// Parameters:
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AssistenteRegistroGet200Response] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AssistenteRegistroGet200Response>> assistenteRegistroGet({ 
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/assistente/registro';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'tokenDeAcesso',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    AssistenteRegistroGet200Response? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<AssistenteRegistroGet200Response, AssistenteRegistroGet200Response>(rawData, 'AssistenteRegistroGet200Response', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AssistenteRegistroGet200Response>(
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
