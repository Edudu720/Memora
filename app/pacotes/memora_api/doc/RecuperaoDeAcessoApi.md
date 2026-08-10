# memora_api.api.RecuperaoDeAcessoApi

## Load the API package
```dart
import 'package:memora_api/api.dart';
```

All URIs are relative to *https://api.memora.app/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authRecuperacaoConfirmarPost**](RecuperaoDeAcessoApi.md#authrecuperacaoconfirmarpost) | **POST** /auth/recuperacao/confirmar | Definir nova senha
[**authRecuperacaoSolicitarPost**](RecuperaoDeAcessoApi.md#authrecuperacaosolicitarpost) | **POST** /auth/recuperacao/solicitar | Solicitar recuperação de acesso


# **authRecuperacaoConfirmarPost**
> SessaoResposta authRecuperacaoConfirmarPost(authRecuperacaoConfirmarPostRequest)

Definir nova senha

Troca a senha e **revoga todas as sessões ativas** (FR-021). A pessoa é notificada pelo canal cadastrado (FR-022). 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getRecuperaoDeAcessoApi();
final AuthRecuperacaoConfirmarPostRequest authRecuperacaoConfirmarPostRequest = ; // AuthRecuperacaoConfirmarPostRequest | 

try {
    final response = api.authRecuperacaoConfirmarPost(authRecuperacaoConfirmarPostRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecuperaoDeAcessoApi->authRecuperacaoConfirmarPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **authRecuperacaoConfirmarPostRequest** | [**AuthRecuperacaoConfirmarPostRequest**](AuthRecuperacaoConfirmarPostRequest.md)|  | 

### Return type

[**SessaoResposta**](SessaoResposta.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authRecuperacaoSolicitarPost**
> AuthRecuperacaoSolicitarPost202Response authRecuperacaoSolicitarPost(authRecuperacaoSolicitarPostRequest)

Solicitar recuperação de acesso

Responde **202 sempre**, exista a conta ou não (FR-019). O texto devolvido é idêntico nos dois casos.  Só envia para canal **verificado**. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getRecuperaoDeAcessoApi();
final AuthRecuperacaoSolicitarPostRequest authRecuperacaoSolicitarPostRequest = ; // AuthRecuperacaoSolicitarPostRequest | 

try {
    final response = api.authRecuperacaoSolicitarPost(authRecuperacaoSolicitarPostRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecuperaoDeAcessoApi->authRecuperacaoSolicitarPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **authRecuperacaoSolicitarPostRequest** | [**AuthRecuperacaoSolicitarPostRequest**](AuthRecuperacaoSolicitarPostRequest.md)|  | 

### Return type

[**AuthRecuperacaoSolicitarPost202Response**](AuthRecuperacaoSolicitarPost202Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

