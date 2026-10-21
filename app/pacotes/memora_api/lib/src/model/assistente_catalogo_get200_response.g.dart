// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistente_catalogo_get200_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssistenteCatalogoGet200Response _$AssistenteCatalogoGet200ResponseFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('AssistenteCatalogoGet200Response', json, ($checkedConvert) {
      final val = AssistenteCatalogoGet200Response(
        servicos: $checkedConvert(
          'servicos',
          (v) => (v as List<dynamic>?)
              ?.map((e) => Servico.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AssistenteCatalogoGet200ResponseToJson(
  AssistenteCatalogoGet200Response instance,
) => <String, dynamic>{
  'servicos': ?instance.servicos?.map((e) => e.toJson()).toList(),
};
