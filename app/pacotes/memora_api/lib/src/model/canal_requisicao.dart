//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'canal_requisicao.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanalRequisicao {
  /// Returns a new [CanalRequisicao] instance.
  CanalRequisicao({

    required  this.tipo,

    required  this.valor,
  });

  @JsonKey(
    
    name: r'tipo',
    required: true,
    includeIfNull: false,
  )


  final CanalRequisicaoTipoEnum tipo;



      /// Normalizado pelo servidor — minúsculas, sem espaços
  @JsonKey(
    
    name: r'valor',
    required: true,
    includeIfNull: false,
  )


  final String valor;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanalRequisicao &&
      other.tipo == tipo &&
      other.valor == valor;

    @override
    int get hashCode =>
        tipo.hashCode +
        valor.hashCode;

  factory CanalRequisicao.fromJson(Map<String, dynamic> json) => _$CanalRequisicaoFromJson(json);

  Map<String, dynamic> toJson() => _$CanalRequisicaoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanalRequisicaoTipoEnum {
@JsonValue(r'email')
email(r'email'),
@JsonValue(r'telefone')
telefone(r'telefone');

const CanalRequisicaoTipoEnum(this.value);

final String value;

@override
String toString() => value;
}


