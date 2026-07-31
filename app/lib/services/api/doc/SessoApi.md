# memora_api.api.SessoApi

## Load the API package
```dart
import 'package:memora_api/api.dart';
```

All URIs are relative to *https://api.memora.app/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authEntrarPost**](SessoApi.md#authentrarpost) | **POST** /auth/entrar | Entrar com identificador e senha
[**authSairPost**](SessoApi.md#authsairpost) | **POST** /auth/sair | Encerrar sessão
[**authSessaoRenovarPost**](SessoApi.md#authsessaorenovarpost) | **POST** /auth/sessao/renovar | Renovar sessão
[**authSocialProvedorPost**](SessoApi.md#authsocialprovedorpost) | **POST** /auth/social/{provedor} | Entrar com provedor externo
[**euGet**](SessoApi.md#euget) | **GET** /eu | Dados da pessoa autenticada


# **authEntrarPost**
> SessaoResposta authEntrarPost(entrarRequisicao)

Entrar com identificador e senha

Aceita **qualquer canal verificado** da pessoa — e-mail ou telefone (FR-051).  O erro é sempre genérico: não distingue identificador inexistente de senha incorreta (FR-013). O servidor executa o hash mesmo quando a conta não existe, para que o tempo de resposta não denuncie a existência (R3). 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getSessoApi();
final EntrarRequisicao entrarRequisicao = ; // EntrarRequisicao | 

try {
    final response = api.authEntrarPost(entrarRequisicao);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SessoApi->authEntrarPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **entrarRequisicao** | [**EntrarRequisicao**](EntrarRequisicao.md)|  | 

### Return type

[**SessaoResposta**](SessaoResposta.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authSairPost**
> authSairPost()

Encerrar sessão

Revoga a sessão atual (FR-026). O aplicativo é responsável por limpar todo dado pessoal e credencial do armazenamento seguro do aparelho. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getSessoApi();

try {
    api.authSairPost();
} catch on DioException (e) {
    print('Exception when calling SessoApi->authSairPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authSessaoRenovarPost**
> SessaoResposta authSessaoRenovarPost(authSessaoRenovarPostRequest)

Renovar sessão

Rotação de refresh token (R2). O token apresentado é invalidado e um novo é emitido.  **Detecção de reuso**: se o token já tiver sido usado, isso indica roubo. Toda a família de sessões é revogada e a pessoa é notificada. A resposta é `401`. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getSessoApi();
final AuthSessaoRenovarPostRequest authSessaoRenovarPostRequest = ; // AuthSessaoRenovarPostRequest | 

try {
    final response = api.authSessaoRenovarPost(authSessaoRenovarPostRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SessoApi->authSessaoRenovarPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **authSessaoRenovarPostRequest** | [**AuthSessaoRenovarPostRequest**](AuthSessaoRenovarPostRequest.md)|  | 

### Return type

[**SessaoResposta**](SessaoResposta.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authSocialProvedorPost**
> SessaoResposta authSocialProvedorPost(provedor, authSocialProvedorPostRequest)

Entrar com provedor externo

Recebe o token de identidade obtido pelo aplicativo via Authorization Code com PKCE (R6). O backend **valida assinatura, emissor, audiência e expiração** antes de aceitar.  Se o identificador já existir como conta com senha, os acessos são vinculados à mesma pessoa, sem criar duplicata e **sem revelar** que a conta já existia (FR-057).  O token do provedor é validado e **descartado** — nunca armazenado. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getSessoApi();
final String provedor = provedor_example; // String | 
final AuthSocialProvedorPostRequest authSocialProvedorPostRequest = ; // AuthSocialProvedorPostRequest | 

try {
    final response = api.authSocialProvedorPost(provedor, authSocialProvedorPostRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SessoApi->authSocialProvedorPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **provedor** | **String**|  | 
 **authSocialProvedorPostRequest** | [**AuthSocialProvedorPostRequest**](AuthSocialProvedorPostRequest.md)|  | 

### Return type

[**SessaoResposta**](SessaoResposta.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **euGet**
> PessoaResposta euGet()

Dados da pessoa autenticada

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getSessoApi();

try {
    final response = api.euGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SessoApi->euGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PessoaResposta**](PessoaResposta.md)

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

