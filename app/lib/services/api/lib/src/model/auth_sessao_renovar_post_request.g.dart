// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_sessao_renovar_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSessaoRenovarPostRequest _$AuthSessaoRenovarPostRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AuthSessaoRenovarPostRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['refresh_token']);
  final val = AuthSessaoRenovarPostRequest(
    refreshToken: $checkedConvert('refresh_token', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'refreshToken': 'refresh_token'});

Map<String, dynamic> _$AuthSessaoRenovarPostRequestToJson(
  AuthSessaoRenovarPostRequest instance,
) => <String, dynamic>{'refresh_token': instance.refreshToken};
