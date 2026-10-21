// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'erro_da_conversa.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErroDaConversa _$ErroDaConversaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ErroDaConversa', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['codigo', 'mensagem']);
      final val = ErroDaConversa(
        codigo: $checkedConvert(
          'codigo',
          (v) => $enumDecode(_$ErroDaConversaCodigoEnumEnumMap, v),
        ),
        mensagem: $checkedConvert('mensagem', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ErroDaConversaToJson(ErroDaConversa instance) =>
    <String, dynamic>{
      'codigo': _$ErroDaConversaCodigoEnumEnumMap[instance.codigo]!,
      'mensagem': instance.mensagem,
    };

const _$ErroDaConversaCodigoEnumEnumMap = {
  ErroDaConversaCodigoEnum.LIMITE_DE_CONVERSAS: 'LIMITE_DE_CONVERSAS',
  ErroDaConversaCodigoEnum.ASSISTENTE_INDISPONIVEL: 'ASSISTENTE_INDISPONIVEL',
  ErroDaConversaCodigoEnum.ERRO_INESPERADO: 'ERRO_INESPERADO',
};
