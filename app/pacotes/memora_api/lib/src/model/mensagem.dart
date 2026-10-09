//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'mensagem.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Mensagem {
  /// Returns a new [Mensagem] instance.
  Mensagem({

    required  this.autor,

    required  this.texto,
  });

  @JsonKey(
    
    name: r'autor',
    required: true,
    includeIfNull: false,
  )


  final MensagemAutorEnum autor;



  @JsonKey(
    
    name: r'texto',
    required: true,
    includeIfNull: false,
  )


  final String texto;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Mensagem &&
      other.autor == autor &&
      other.texto == texto;

    @override
    int get hashCode =>
        autor.hashCode +
        texto.hashCode;

  factory Mensagem.fromJson(Map<String, dynamic> json) => _$MensagemFromJson(json);

  Map<String, dynamic> toJson() => _$MensagemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MensagemAutorEnum {
@JsonValue(r'pessoa')
pessoa(r'pessoa'),
@JsonValue(r'memora')
memora(r'memora');

const MensagemAutorEnum(this.value);

final String value;

@override
String toString() => value;
}


