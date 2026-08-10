// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_recuperacao_solicitar_post202_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthRecuperacaoSolicitarPost202Response
_$AuthRecuperacaoSolicitarPost202ResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AuthRecuperacaoSolicitarPost202Response', json, (
      $checkedConvert,
    ) {
      final val = AuthRecuperacaoSolicitarPost202Response(
        mensagem: $checkedConvert('mensagem', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AuthRecuperacaoSolicitarPost202ResponseToJson(
  AuthRecuperacaoSolicitarPost202Response instance,
) => <String, dynamic>{'mensagem': ?instance.mensagem};
