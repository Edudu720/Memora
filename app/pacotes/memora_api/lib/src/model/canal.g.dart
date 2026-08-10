// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Canal _$CanalFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Canal', json, ($checkedConvert) {
      final val = Canal(
        id: $checkedConvert('id', (v) => v as String?),
        tipo: $checkedConvert(
          'tipo',
          (v) => $enumDecodeNullable(_$CanalTipoEnumEnumMap, v),
        ),
        valorMascarado: $checkedConvert('valor_mascarado', (v) => v as String?),
        verificado: $checkedConvert('verificado', (v) => v as bool?),
        principal: $checkedConvert('principal', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'valorMascarado': 'valor_mascarado'});

Map<String, dynamic> _$CanalToJson(Canal instance) => <String, dynamic>{
  'id': ?instance.id,
  'tipo': ?_$CanalTipoEnumEnumMap[instance.tipo],
  'valor_mascarado': ?instance.valorMascarado,
  'verificado': ?instance.verificado,
  'principal': ?instance.principal,
};

const _$CanalTipoEnumEnumMap = {
  CanalTipoEnum.email: 'email',
  CanalTipoEnum.telefone: 'telefone',
};
