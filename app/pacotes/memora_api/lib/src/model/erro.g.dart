// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'erro.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Erro _$ErroFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Erro',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['codigo', 'mensagem']);
    final val = Erro(
      codigo: $checkedConvert('codigo', (v) => v as String),
      mensagem: $checkedConvert('mensagem', (v) => v as String),
      tentarNovamenteEmSegundos: $checkedConvert(
        'tentar_novamente_em_segundos',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'tentarNovamenteEmSegundos': 'tentar_novamente_em_segundos',
  },
);

Map<String, dynamic> _$ErroToJson(Erro instance) => <String, dynamic>{
  'codigo': instance.codigo,
  'mensagem': instance.mensagem,
  'tentar_novamente_em_segundos': ?instance.tentarNovamenteEmSegundos,
};
