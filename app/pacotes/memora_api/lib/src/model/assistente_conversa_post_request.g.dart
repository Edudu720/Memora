// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistente_conversa_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssistenteConversaPostRequest _$AssistenteConversaPostRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AssistenteConversaPostRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mensagem']);
  final val = AssistenteConversaPostRequest(
    mensagem: $checkedConvert('mensagem', (v) => v as String),
    historico: $checkedConvert(
      'historico',
      (v) => (v as List<dynamic>?)
          ?.map((e) => Mensagem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AssistenteConversaPostRequestToJson(
  AssistenteConversaPostRequest instance,
) => <String, dynamic>{
  'mensagem': instance.mensagem,
  'historico': ?instance.historico?.map((e) => e.toJson()).toList(),
};
