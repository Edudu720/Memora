// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessao_resposta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessaoResposta _$SessaoRespostaFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SessaoResposta',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'token_acesso',
            'refresh_token',
            'expira_em_segundos',
            'pessoa',
          ],
        );
        final val = SessaoResposta(
          tokenAcesso: $checkedConvert('token_acesso', (v) => v as String),
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          expiraEmSegundos: $checkedConvert(
            'expira_em_segundos',
            (v) => (v as num).toInt(),
          ),
          pessoa: $checkedConvert(
            'pessoa',
            (v) => PessoaResposta.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'tokenAcesso': 'token_acesso',
        'refreshToken': 'refresh_token',
        'expiraEmSegundos': 'expira_em_segundos',
      },
    );

Map<String, dynamic> _$SessaoRespostaToJson(SessaoResposta instance) =>
    <String, dynamic>{
      'token_acesso': instance.tokenAcesso,
      'refresh_token': instance.refreshToken,
      'expira_em_segundos': instance.expiraEmSegundos,
      'pessoa': instance.pessoa.toJson(),
    };
