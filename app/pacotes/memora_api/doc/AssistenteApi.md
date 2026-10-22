# memora_api.api.AssistenteApi

## Load the API package
```dart
import 'package:memora_api/api.dart';
```

All URIs are relative to *https://api.memora.app/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assistenteAcaoPost**](AssistenteApi.md#assistenteacaopost) | **POST** /assistente/acao | Registrar que a pessoa confirmou e o aplicativo executou
[**assistenteConversaPost**](AssistenteApi.md#assistenteconversapost) | **POST** /assistente/conversa | Conversar com a assistente
[**assistenteRegistroGet**](AssistenteApi.md#assistenteregistroget) | **GET** /assistente/registro | O que a Memora fez em meu nome


# **assistenteAcaoPost**
> assistenteAcaoPost(assistenteAcaoPostRequest)

Registrar que a pessoa confirmou e o aplicativo executou

Escreve a trilha da FR-020. Quem abre o outro aplicativo é o Flutter, depois da confirmação; este endpoint só registra que aconteceu.  O servidor **reconfere** a autorização antes de gravar: um pedido de registro para serviço sensível é recusado e vira `ACAO_RECUSADA` na trilha — se ele chegou aqui, algo está errado, e o registro disso vale mais do que a recusa silenciosa. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getAssistenteApi();
final AssistenteAcaoPostRequest assistenteAcaoPostRequest = ; // AssistenteAcaoPostRequest | 

try {
    api.assistenteAcaoPost(assistenteAcaoPostRequest);
} catch on DioException (e) {
    print('Exception when calling AssistenteApi->assistenteAcaoPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **assistenteAcaoPostRequest** | [**AssistenteAcaoPostRequest**](AssistenteAcaoPostRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assistenteConversaPost**
> String assistenteConversaPost(assistenteConversaPostRequest)

Conversar com a assistente

Recebe o histórico e a mensagem nova, e transmite a resposta por **Server-Sent Events**. O público do Memora é o que menos tolera tela parada: ver o texto aparecendo é o que diferencia \"está pensando\" de \"travou\" (SC-007).  O campo `acao` de um evento `acao` **já passou** pelo catálogo. Sugestão do modelo que não passa nunca chega aqui.  **Falha da conversa nunca vira status HTTP.** Limite diário de conversas e provedor indisponível chegam como evento `erro` dentro do stream, com a resposta HTTP já `200` (clarificação de 2026-10-03, FR-053 e FR-057). Por isso esta operação **não** declara `429` nem `503`. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getAssistenteApi();
final AssistenteConversaPostRequest assistenteConversaPostRequest = ; // AssistenteConversaPostRequest | 

try {
    final response = api.assistenteConversaPost(assistenteConversaPostRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AssistenteApi->assistenteConversaPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **assistenteConversaPostRequest** | [**AssistenteConversaPostRequest**](AssistenteConversaPostRequest.md)|  | 

### Return type

**String**

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: text/event-stream, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assistenteRegistroGet**
> AssistenteRegistroGet200Response assistenteRegistroGet()

O que a Memora fez em meu nome

A FR-023. Devolve as ações executadas, em linguagem comum. Orientação apenas ensinada **não** aparece aqui (FR-025) — ela não foi executada por ninguém além da própria pessoa. 

### Example
```dart
import 'package:memora_api/api.dart';

final api = MemoraApi().getAssistenteApi();

try {
    final response = api.assistenteRegistroGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AssistenteApi->assistenteRegistroGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AssistenteRegistroGet200Response**](AssistenteRegistroGet200Response.md)

### Authorization

[tokenDeAcesso](../README.md#tokenDeAcesso)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

