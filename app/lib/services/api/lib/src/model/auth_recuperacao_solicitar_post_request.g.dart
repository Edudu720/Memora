// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_recuperacao_solicitar_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthRecuperacaoSolicitarPostRequest
_$AuthRecuperacaoSolicitarPostRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AuthRecuperacaoSolicitarPostRequest', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['identificador']);
      final val = AuthRecuperacaoSolicitarPostRequest(
        identificador: $checkedConvert('identificador', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AuthRecuperacaoSolicitarPostRequestToJson(
  AuthRecuperacaoSolicitarPostRequest instance,
) => <String, dynamic>{'identificador': instance.identificador};
