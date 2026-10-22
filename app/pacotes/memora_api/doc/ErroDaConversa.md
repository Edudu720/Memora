# memora_api.model.ErroDaConversa

## Load the model package
```dart
import 'package:memora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**codigo** | **String** | `LIMITE_DE_CONVERSAS` — teto diário da conta (FR-053); volta no dia seguinte, não se oferece tentar de novo. `ASSISTENTE_INDISPONIVEL` — o provedor está fora do ar, sem cota ou não respondeu no prazo (FR-057); oferece tentar de novo mais tarde. `ERRO_INESPERADO` — defeito nosso; o detalhe fica no log.  | 
**mensagem** | **String** | Texto já pronto para a pessoa, na voz da Memora. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


