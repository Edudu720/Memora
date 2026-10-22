# memora_api.api.CatalogoApi

## Load the API package
```dart
import 'package:memora_api/api.dart';
```

All URIs are relative to *https://api.memora.app/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assistenteCatalogoGet**](CatalogoApi.md#assistentecatalogoget) | **GET** /assistente/catalogo | Listar os serviços que a Memora conhece


# **assistenteCatalogoGet**
> AssistenteCatalogoGet200Response assistenteCatalogoGet(categoria)

Listar os serviços que a Memora conhece

Alimenta as portas *Serviços do dia a dia* e *Meus aplicativos*. Cada item diz, antes do toque, se a Memora **ensina** ou **ensina e abre** (FR-045). 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getCatalogoApi();
final String categoria = categoria_example; // String | Omitido, devolve as duas listas.

try {
    final response = api.assistenteCatalogoGet(categoria);
    print(response);
} catch on DioException (e) {
    print('Exception when calling CatalogoApi->assistenteCatalogoGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **categoria** | **String**| Omitido, devolve as duas listas. | [optional] 

### Return type

[**AssistenteCatalogoGet200Response**](AssistenteCatalogoGet200Response.md)

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

