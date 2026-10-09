//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:memora_api/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:memora_api/src/model/assistente_catalogo_get200_response.dart';

class CatalogoApi {

  final Dio _dio;

  const CatalogoApi(this._dio);

  /// Listar os serviços que a Memora conhece
  /// Alimenta as portas *Serviços do dia a dia* e *Meus aplicativos*. Cada item diz, antes do toque, se a Memora **ensina** ou **ensina e abre** (FR-045). 
  ///
  /// Parameters:
  /// * [categoria] - Omitido, devolve as duas listas.
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AssistenteCatalogoGet200Response] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AssistenteCatalogoGet200Response>> assistenteCatalogoGet({ 
    String? categoria,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/assistente/catalogo';
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

    final _queryParameters = <String, dynamic>{
      if (categoria != null) r'categoria': categoria,
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    AssistenteCatalogoGet200Response? _responseData;

    try {
final rawData = _response.data;
_responseData = rawData == null ? null : deserialize<AssistenteCatalogoGet200Response, AssistenteCatalogoGet200Response>(rawData, 'AssistenteCatalogoGet200Response', growable: true);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AssistenteCatalogoGet200Response>(
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
