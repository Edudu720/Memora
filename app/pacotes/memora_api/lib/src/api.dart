//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:memora_api/src/auth/api_key_auth.dart';
import 'package:memora_api/src/auth/basic_auth.dart';
import 'package:memora_api/src/auth/bearer_auth.dart';
import 'package:memora_api/src/auth/oauth.dart';
import 'package:memora_api/src/api/assistente_api.dart';
import 'package:memora_api/src/api/cadastro_api.dart';
import 'package:memora_api/src/api/canais_de_contato_api.dart';
import 'package:memora_api/src/api/catalogo_api.dart';
import 'package:memora_api/src/api/recuperao_de_acesso_api.dart';
import 'package:memora_api/src/api/sesso_api.dart';

class MemoraApi {
  static const String basePath = r'https://api.memora.app/v1';

  final Dio dio;
  MemoraApi({
    Dio? dio,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  })  : 
        this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Get AssistenteApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AssistenteApi getAssistenteApi() {
    return AssistenteApi(dio);
  }

  /// Get CadastroApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CadastroApi getCadastroApi() {
    return CadastroApi(dio);
  }

  /// Get CanaisDeContatoApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CanaisDeContatoApi getCanaisDeContatoApi() {
    return CanaisDeContatoApi(dio);
  }

  /// Get CatalogoApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CatalogoApi getCatalogoApi() {
    return CatalogoApi(dio);
  }

  /// Get RecuperaoDeAcessoApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  RecuperaoDeAcessoApi getRecuperaoDeAcessoApi() {
    return RecuperaoDeAcessoApi(dio);
  }

  /// Get SessoApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SessoApi getSessoApi() {
    return SessoApi(dio);
  }
}
