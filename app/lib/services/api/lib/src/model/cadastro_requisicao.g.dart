// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cadastro_requisicao.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CadastroRequisicao _$CadastroRequisicaoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CadastroRequisicao',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['nome_tratamento', 'canal', 'senha']);
    final val = CadastroRequisicao(
      nomeTratamento: $checkedConvert('nome_tratamento', (v) => v as String),
      canal: $checkedConvert(
        'canal',
        (v) => CanalRequisicao.fromJson(v as Map<String, dynamic>),
      ),
      senha: $checkedConvert('senha', (v) => v as String),
      modoAssistido: $checkedConvert(
        'modo_assistido',
        (v) => v as bool? ?? false,
      ),
      aparelhoDescricao: $checkedConvert(
        'aparelho_descricao',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'nomeTratamento': 'nome_tratamento',
    'modoAssistido': 'modo_assistido',
    'aparelhoDescricao': 'aparelho_descricao',
  },
);

Map<String, dynamic> _$CadastroRequisicaoToJson(CadastroRequisicao instance) =>
    <String, dynamic>{
      'nome_tratamento': instance.nomeTratamento,
      'canal': instance.canal.toJson(),
      'senha': instance.senha,
      'modo_assistido': ?instance.modoAssistido,
      'aparelho_descricao': ?instance.aparelhoDescricao,
    };
