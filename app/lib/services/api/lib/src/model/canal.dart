//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'canal.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Canal {
  /// Returns a new [Canal] instance.
  Canal({

     this.id,

     this.tipo,

     this.valorMascarado,

     this.verificado,

     this.principal,
  });

  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false,
  )


  final String? id;



  @JsonKey(
    
    name: r'tipo',
    required: false,
    includeIfNull: false,
  )


  final CanalTipoEnum? tipo;



      /// Nunca devolvemos o valor completo
  @JsonKey(
    
    name: r'valor_mascarado',
    required: false,
    includeIfNull: false,
  )


  final String? valorMascarado;



  @JsonKey(
    
    name: r'verificado',
    required: false,
    includeIfNull: false,
  )


  final bool? verificado;



  @JsonKey(
    
    name: r'principal',
    required: false,
    includeIfNull: false,
  )


  final bool? principal;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Canal &&
      other.id == id &&
      other.tipo == tipo &&
      other.valorMascarado == valorMascarado &&
      other.verificado == verificado &&
      other.principal == principal;

    @override
    int get hashCode =>
        id.hashCode +
        tipo.hashCode +
        valorMascarado.hashCode +
        verificado.hashCode +
        principal.hashCode;

  factory Canal.fromJson(Map<String, dynamic> json) => _$CanalFromJson(json);

  Map<String, dynamic> toJson() => _$CanalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanalTipoEnum {
@JsonValue(r'email')
email(r'email'),
@JsonValue(r'telefone')
telefone(r'telefone');

const CanalTipoEnum(this.value);

final String value;

@override
String toString() => value;
}


