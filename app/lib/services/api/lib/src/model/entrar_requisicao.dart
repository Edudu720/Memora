//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'entrar_requisicao.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EntrarRequisicao {
  /// Returns a new [EntrarRequisicao] instance.
  EntrarRequisicao({

    required  this.identificador,

    required  this.senha,

     this.aparelhoDescricao,
  });

      /// E-mail **ou** telefone. Qualquer canal verificado (FR-051)
  @JsonKey(
    
    name: r'identificador',
    required: true,
    includeIfNull: false,
  )


  final String identificador;



  @JsonKey(
    
    name: r'senha',
    required: true,
    includeIfNull: false,
  )


  final String senha;



  @JsonKey(
    
    name: r'aparelho_descricao',
    required: false,
    includeIfNull: false,
  )


  final String? aparelhoDescricao;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EntrarRequisicao &&
      other.identificador == identificador &&
      other.senha == senha &&
      other.aparelhoDescricao == aparelhoDescricao;

    @override
    int get hashCode =>
        identificador.hashCode +
        senha.hashCode +
        aparelhoDescricao.hashCode;

  factory EntrarRequisicao.fromJson(Map<String, dynamic> json) => _$EntrarRequisicaoFromJson(json);

  Map<String, dynamic> toJson() => _$EntrarRequisicaoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

