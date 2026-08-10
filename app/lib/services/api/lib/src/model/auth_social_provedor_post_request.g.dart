// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_social_provedor_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSocialProvedorPostRequest _$AuthSocialProvedorPostRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AuthSocialProvedorPostRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['token_identidade']);
    final val = AuthSocialProvedorPostRequest(
      tokenIdentidade: $checkedConvert('token_identidade', (v) => v as String),
      aparelhoDescricao: $checkedConvert(
        'aparelho_descricao',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'tokenIdentidade': 'token_identidade',
    'aparelhoDescricao': 'aparelho_descricao',
  },
);

Map<String, dynamic> _$AuthSocialProvedorPostRequestToJson(
  AuthSocialProvedorPostRequest instance,
) => <String, dynamic>{
  'token_identidade': instance.tokenIdentidade,
  'aparelho_descricao': ?instance.aparelhoDescricao,
};
