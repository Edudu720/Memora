// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servico.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Servico _$ServicoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Servico',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'chave',
        'nome_exibido',
        'categoria',
        'memora_pode_abrir',
      ],
    );
    final val = Servico(
      id: $checkedConvert('id', (v) => v as String),
      chave: $checkedConvert('chave', (v) => v as String),
      nomeExibido: $checkedConvert('nome_exibido', (v) => v as String),
      descricaoCurta: $checkedConvert('descricao_curta', (v) => v as String?),
      categoria: $checkedConvert(
        'categoria',
        (v) => $enumDecode(_$ServicoCategoriaEnumEnumMap, v),
      ),
      memoraPodeAbrir: $checkedConvert('memora_pode_abrir', (v) => v as bool),
      identificadorAndroid: $checkedConvert(
        'identificador_android',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'nomeExibido': 'nome_exibido',
    'descricaoCurta': 'descricao_curta',
    'memoraPodeAbrir': 'memora_pode_abrir',
    'identificadorAndroid': 'identificador_android',
  },
);

Map<String, dynamic> _$ServicoToJson(Servico instance) => <String, dynamic>{
  'id': instance.id,
  'chave': instance.chave,
  'nome_exibido': instance.nomeExibido,
  'descricao_curta': ?instance.descricaoCurta,
  'categoria': _$ServicoCategoriaEnumEnumMap[instance.categoria]!,
  'memora_pode_abrir': instance.memoraPodeAbrir,
  'identificador_android': ?instance.identificadorAndroid,
};

const _$ServicoCategoriaEnumEnumMap = {
  ServicoCategoriaEnum.sensivel: 'sensivel',
  ServicoCategoriaEnum.cotidiano: 'cotidiano',
};
