// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acao_registrada.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcaoRegistrada _$AcaoRegistradaFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AcaoRegistrada',
      json,
      ($checkedConvert) {
        final val = AcaoRegistrada(
          nomeExibido: $checkedConvert('nome_exibido', (v) => v as String?),
          pedidoResumido: $checkedConvert(
            'pedido_resumido',
            (v) => v as String?,
          ),
          ocorridoEm: $checkedConvert(
            'ocorrido_em',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'nomeExibido': 'nome_exibido',
        'pedidoResumido': 'pedido_resumido',
        'ocorridoEm': 'ocorrido_em',
      },
    );

Map<String, dynamic> _$AcaoRegistradaToJson(AcaoRegistrada instance) =>
    <String, dynamic>{
      'nome_exibido': ?instance.nomeExibido,
      'pedido_resumido': ?instance.pedidoResumido,
      'ocorrido_em': ?instance.ocorridoEm?.toIso8601String(),
    };
