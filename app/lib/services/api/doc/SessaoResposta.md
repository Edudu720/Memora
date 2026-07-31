# memora_api.model.SessaoResposta

## Load the model package
```dart
import 'package:memora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**tokenAcesso** | **String** | Válido por 15 minutos (R2) | 
**refreshToken** | **String** | Opaco e rotativo. O aplicativo MUST guardá-lo apenas em armazenamento seguro do sistema, nunca em preferências comuns (FR-036, R7).  | 
**expiraEmSegundos** | **int** |  | 
**pessoa** | [**PessoaResposta**](PessoaResposta.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


