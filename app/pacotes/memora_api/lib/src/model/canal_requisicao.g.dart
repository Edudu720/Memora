// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canal_requisicao.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanalRequisicao _$CanalRequisicaoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanalRequisicao', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['tipo', 'valor']);
      final val = CanalRequisicao(
        tipo: $checkedConvert(
          'tipo',
          (v) => $enumDecode(_$CanalRequisicaoTipoEnumEnumMap, v),
        ),
        valor: $checkedConvert('valor', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CanalRequisicaoToJson(CanalRequisicao instance) =>
    <String, dynamic>{
      'tipo': _$CanalRequisicaoTipoEnumEnumMap[instance.tipo]!,
      'valor': instance.valor,
    };

const _$CanalRequisicaoTipoEnumEnumMap = {
  CanalRequisicaoTipoEnum.email: 'email',
  CanalRequisicaoTipoEnum.telefone: 'telefone',
};
