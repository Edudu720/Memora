// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canais_canal_id_verificar_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanaisCanalIdVerificarPostRequest _$CanaisCanalIdVerificarPostRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CanaisCanalIdVerificarPostRequest', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['codigo']);
  final val = CanaisCanalIdVerificarPostRequest(
    codigo: $checkedConvert('codigo', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$CanaisCanalIdVerificarPostRequestToJson(
  CanaisCanalIdVerificarPostRequest instance,
) => <String, dynamic>{'codigo': instance.codigo};
