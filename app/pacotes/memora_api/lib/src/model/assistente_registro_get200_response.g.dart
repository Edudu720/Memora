// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistente_registro_get200_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssistenteRegistroGet200Response _$AssistenteRegistroGet200ResponseFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('AssistenteRegistroGet200Response', json, ($checkedConvert) {
      final val = AssistenteRegistroGet200Response(
        acoes: $checkedConvert(
          'acoes',
          (v) => (v as List<dynamic>?)
              ?.map((e) => AcaoRegistrada.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AssistenteRegistroGet200ResponseToJson(
  AssistenteRegistroGet200Response instance,
) => <String, dynamic>{
  'acoes': ?instance.acoes?.map((e) => e.toJson()).toList(),
};
