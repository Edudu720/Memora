// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistente_acao_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssistenteAcaoPostRequest _$AssistenteAcaoPostRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AssistenteAcaoPostRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['servico_id', 'pedido_resumido']);
    final val = AssistenteAcaoPostRequest(
      servicoId: $checkedConvert('servico_id', (v) => v as String),
      pedidoResumido: $checkedConvert('pedido_resumido', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'servicoId': 'servico_id',
    'pedidoResumido': 'pedido_resumido',
  },
);

Map<String, dynamic> _$AssistenteAcaoPostRequestToJson(
  AssistenteAcaoPostRequest instance,
) => <String, dynamic>{
  'servico_id': instance.servicoId,
  'pedido_resumido': instance.pedidoResumido,
};
