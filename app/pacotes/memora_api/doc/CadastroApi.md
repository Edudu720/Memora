# memora_api.api.CadastroApi

## Load the API package
```dart
import 'package:memora_api/api.dart';
```

All URIs are relative to *https://api.memora.app/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authCadastroPost**](CadastroApi.md#authcadastropost) | **POST** /auth/cadastro | Criar conta


# **authCadastroPost**
> SessaoResposta authCadastroPost(cadastroRequisicao)

Criar conta

Cria a conta e **já devolve sessão iniciada** (FR-009). A pessoa não precisa fazer login em seguida.  Exige **apenas um** canal de contato (FR-049). O segundo é oferecido depois do primeiro acesso (FR-050).  Se o canal já pertencer a uma conta, responde **201 da mesma forma**, sem criar nada e sem revelar a existência (FR-010). O aplicativo conduz a pessoa ao login conforme o cenário 5 da User Story 1. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getCadastroApi();
final CadastroRequisicao cadastroRequisicao = ; // CadastroRequisicao | 

try {
    final response = api.authCadastroPost(cadastroRequisicao);
    print(response);
} catch on DioException (e) {
    print('Exception when calling CadastroApi->authCadastroPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cadastroRequisicao** | [**CadastroRequisicao**](CadastroRequisicao.md)|  | 

### Return type

[**SessaoResposta**](SessaoResposta.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

