# memora_api.api.CanaisDeContatoApi

## Load the API package
```dart
import 'package:memora_api/api.dart';
```

All URIs are relative to *https://api.memora.app/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**canaisCanalIdCodigoPost**](CanaisDeContatoApi.md#canaiscanalidcodigopost) | **POST** /canais/{canalId}/codigo | Enviar código de verificação
[**canaisCanalIdVerificarPost**](CanaisDeContatoApi.md#canaiscanalidverificarpost) | **POST** /canais/{canalId}/verificar | Confirmar posse do canal
[**canaisPost**](CanaisDeContatoApi.md#canaispost) | **POST** /canais | Adicionar segundo canal de contato


# **canaisCanalIdCodigoPost**
> canaisCanalIdCodigoPost(canalId)

Enviar código de verificação

Envia código numérico de 6 dígitos, válido por 10 minutos, de uso único (R5).  **Código, não link.** A FR-046 desaconselha links de autenticação em canais imitáveis — a regra que ensinamos à pessoa é *\"nunca clique, sempre digite\"*.  Solicitar novo código invalida o anterior. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getCanaisDeContatoApi();
final String canalId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.canaisCanalIdCodigoPost(canalId);
} catch on DioException (e) {
    print('Exception when calling CanaisDeContatoApi->canaisCanalIdCodigoPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **canalId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **canaisCanalIdVerificarPost**
> Canal canaisCanalIdVerificarPost(canalId, canaisCanalIdVerificarPostRequest)

Confirmar posse do canal

Confirma que a pessoa controla o canal. **Somente canal verificado serve para recuperar acesso** (FR-052).  Este é o ponto que impede o cenário do acompanhante que cadastra o próprio contato e mantém controle da conta alheia (FR-062). 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getCanaisDeContatoApi();
final String canalId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final CanaisCanalIdVerificarPostRequest canaisCanalIdVerificarPostRequest = ; // CanaisCanalIdVerificarPostRequest | 

try {
    final response = api.canaisCanalIdVerificarPost(canalId, canaisCanalIdVerificarPostRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling CanaisDeContatoApi->canaisCanalIdVerificarPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **canalId** | **String**|  | 
 **canaisCanalIdVerificarPostRequest** | [**CanaisCanalIdVerificarPostRequest**](CanaisCanalIdVerificarPostRequest.md)|  | 

### Return type

[**Canal**](Canal.md)

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **canaisPost**
> Canal canaisPost(canalRequisicao)

Adicionar segundo canal de contato

Oferecido **após** o primeiro acesso, de forma não bloqueante, como reforço de segurança da conta (FR-050). Cria o canal como **não verificado**. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getCanaisDeContatoApi();
final CanalRequisicao canalRequisicao = ; // CanalRequisicao | 

try {
    final response = api.canaisPost(canalRequisicao);
    print(response);
} catch on DioException (e) {
    print('Exception when calling CanaisDeContatoApi->canaisPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **canalRequisicao** | [**CanalRequisicao**](CanalRequisicao.md)|  | 

### Return type

[**Canal**](Canal.md)

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

