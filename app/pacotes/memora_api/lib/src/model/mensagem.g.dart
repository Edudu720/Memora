// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mensagem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mensagem _$MensagemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Mensagem', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['autor', 'texto']);
      final val = Mensagem(
        autor: $checkedConvert(
          'autor',
          (v) => $enumDecode(_$MensagemAutorEnumEnumMap, v),
        ),
        texto: $checkedConvert('texto', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$MensagemToJson(Mensagem instance) => <String, dynamic>{
  'autor': _$MensagemAutorEnumEnumMap[instance.autor]!,
  'texto': instance.texto,
};

const _$MensagemAutorEnumEnumMap = {
  MensagemAutorEnum.pessoa: 'pessoa',
  MensagemAutorEnum.memora: 'memora',
};
