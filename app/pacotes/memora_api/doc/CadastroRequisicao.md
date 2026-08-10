# memora_api.model.CadastroRequisicao

## Load the model package
```dart
import 'package:memora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**nomeTratamento** | **String** | Como a pessoa quer ser chamada. **Nunca é credencial** (FR-003) | 
**canal** | [**CanalRequisicao**](CanalRequisicao.md) |  | 
**senha** | **String** | A política prioriza **comprimento** sobre complexidade simbólica (FR-042). Não exigimos maiúscula, número ou símbolo — exigências assim levam pessoas idosas a anotar a senha em papel, o que piora a segurança real.  Senhas notoriamente comprometidas são recusadas.  | 
**modoAssistido** | **bool** | Indica que houve acompanhante no cadastro (D3). Quando `true`, o servidor **exige canal com posse já confirmada** antes de concluir (FR-062).  Não cria vínculo, permissão ou acesso do acompanhante (FR-064) — é apenas um sinal de fluxo.  | [optional] [default to false]
**aparelhoDescricao** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


