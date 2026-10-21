# memora_api.model.Servico

## Load the model package
```dart
import 'package:memora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**chave** | **String** | Identificador estável do item, igual em qualquer banco. É o que liga o item ao guia de passo a passo embarcado no aplicativo. O `id` continua sendo o que a trilha de auditoria referencia.  | 
**nomeExibido** | **String** |  | 
**descricaoCurta** | **String** |  | [optional] 
**categoria** | **String** |  | 
**memoraPodeAbrir** | **bool** | Redundante com `categoria`, e de propósito: é o que a tela exibe (FR-045), e derivar isso na tela espalharia a regra da FR-041 por dois lugares.  | 
**identificadorAndroid** | **String** | Ausente quando `sensivel`. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


