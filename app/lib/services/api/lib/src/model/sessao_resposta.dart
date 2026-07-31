//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api/src/model/pessoa_resposta.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sessao_resposta.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SessaoResposta {
  /// Returns a new [SessaoResposta] instance.
  SessaoResposta({

    required  this.tokenAcesso,

    required  this.refreshToken,

    required  this.expiraEmSegundos,

    required  this.pessoa,
  });

      /// Válido por 15 minutos (R2)
  @JsonKey(
    
    name: r'token_acesso',
    required: true,
    includeIfNull: false,
  )


  final String tokenAcesso;



      /// Opaco e rotativo. O aplicativo MUST guardá-lo apenas em armazenamento seguro do sistema, nunca em preferências comuns (FR-036, R7). 
  @JsonKey(
    
    name: r'refresh_token',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;



  @JsonKey(
    
    name: r'expira_em_segundos',
    required: true,
    includeIfNull: false,
  )


  final int expiraEmSegundos;



  @JsonKey(
    
    name: r'pessoa',
    required: true,
    includeIfNull: false,
  )


  final PessoaResposta pessoa;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SessaoResposta &&
      other.tokenAcesso == tokenAcesso &&
      other.refreshToken == refreshToken &&
      other.expiraEmSegundos == expiraEmSegundos &&
      other.pessoa == pessoa;

    @override
    int get hashCode =>
        tokenAcesso.hashCode +
        refreshToken.hashCode +
        expiraEmSegundos.hashCode +
        pessoa.hashCode;

  factory SessaoResposta.fromJson(Map<String, dynamic> json) => _$SessaoRespostaFromJson(json);

  Map<String, dynamic> toJson() => _$SessaoRespostaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

