// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pessoa_resposta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PessoaResposta _$PessoaRespostaFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PessoaResposta',
      json,
      ($checkedConvert) {
        final val = PessoaResposta(
          id: $checkedConvert('id', (v) => v as String?),
          nomeTratamento: $checkedConvert(
            'nome_tratamento',
            (v) => v as String?,
          ),
          canais: $checkedConvert(
            'canais',
            (v) => (v as List<dynamic>?)
                ?.map((e) => Canal.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          possuiSenha: $checkedConvert('possui_senha', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'nomeTratamento': 'nome_tratamento',
        'possuiSenha': 'possui_senha',
      },
    );

Map<String, dynamic> _$PessoaRespostaToJson(PessoaResposta instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'nome_tratamento': ?instance.nomeTratamento,
      'canais': ?instance.canais?.map((e) => e.toJson()).toList(),
      'possui_senha': ?instance.possuiSenha,
    };
