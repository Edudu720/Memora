//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api/src/model/canal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pessoa_resposta.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PessoaResposta {
  /// Returns a new [PessoaResposta] instance.
  PessoaResposta({

     this.id,

     this.nomeTratamento,

     this.canais,

     this.possuiSenha,
  });

  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false,
  )


  final String? id;



  @JsonKey(
    
    name: r'nome_tratamento',
    required: false,
    includeIfNull: false,
  )


  final String? nomeTratamento;



  @JsonKey(
    
    name: r'canais',
    required: false,
    includeIfNull: false,
  )


  final List<Canal>? canais;



      /// Falso quando a conta usa apenas login social
  @JsonKey(
    
    name: r'possui_senha',
    required: false,
    includeIfNull: false,
  )


  final bool? possuiSenha;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PessoaResposta &&
      other.id == id &&
      other.nomeTratamento == nomeTratamento &&
      other.canais == canais &&
      other.possuiSenha == possuiSenha;

    @override
    int get hashCode =>
        id.hashCode +
        nomeTratamento.hashCode +
        canais.hashCode +
        possuiSenha.hashCode;

  factory PessoaResposta.fromJson(Map<String, dynamic> json) => _$PessoaRespostaFromJson(json);

  Map<String, dynamic> toJson() => _$PessoaRespostaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

