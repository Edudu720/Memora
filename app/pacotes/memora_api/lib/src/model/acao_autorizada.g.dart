// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acao_autorizada.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcaoAutorizada _$AcaoAutorizadaFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AcaoAutorizada',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'servico_id',
            'nome_exibido',
            'identificador_android',
          ],
        );
        final val = AcaoAutorizada(
          servicoId: $checkedConvert('servico_id', (v) => v as String),
          nomeExibido: $checkedConvert('nome_exibido', (v) => v as String),
          identificadorAndroid: $checkedConvert(
            'identificador_android',
            (v) => v as String,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'servicoId': 'servico_id',
        'nomeExibido': 'nome_exibido',
        'identificadorAndroid': 'identificador_android',
      },
    );

Map<String, dynamic> _$AcaoAutorizadaToJson(AcaoAutorizada instance) =>
    <String, dynamic>{
      'servico_id': instance.servicoId,
      'nome_exibido': instance.nomeExibido,
      'identificador_android': instance.identificadorAndroid,
    };
