// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_recuperacao_confirmar_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthRecuperacaoConfirmarPostRequest
_$AuthRecuperacaoConfirmarPostRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AuthRecuperacaoConfirmarPostRequest', json, (
      $checkedConvert,
    ) {
      $checkKeys(
        json,
        requiredKeys: const ['identificador', 'codigo', 'nova_senha'],
      );
      final val = AuthRecuperacaoConfirmarPostRequest(
        identificador: $checkedConvert('identificador', (v) => v as String),
        codigo: $checkedConvert('codigo', (v) => v as String),
        novaSenha: $checkedConvert('nova_senha', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'novaSenha': 'nova_senha'});

Map<String, dynamic> _$AuthRecuperacaoConfirmarPostRequestToJson(
  AuthRecuperacaoConfirmarPostRequest instance,
) => <String, dynamic>{
  'identificador': instance.identificador,
  'codigo': instance.codigo,
  'nova_senha': instance.novaSenha,
};
