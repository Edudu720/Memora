// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entrar_requisicao.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EntrarRequisicao _$EntrarRequisicaoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EntrarRequisicao', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['identificador', 'senha']);
      final val = EntrarRequisicao(
        identificador: $checkedConvert('identificador', (v) => v as String),
        senha: $checkedConvert('senha', (v) => v as String),
        aparelhoDescricao: $checkedConvert(
          'aparelho_descricao',
          (v) => v as String?,
        ),
      );
      return val;
    }, fieldKeyMap: const {'aparelhoDescricao': 'aparelho_descricao'});

Map<String, dynamic> _$EntrarRequisicaoToJson(EntrarRequisicao instance) =>
    <String, dynamic>{
      'identificador': instance.identificador,
      'senha': instance.senha,
      'aparelho_descricao': ?instance.aparelhoDescricao,
    };
