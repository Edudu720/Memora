//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api/src/model/acao_registrada.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assistente_registro_get200_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssistenteRegistroGet200Response {
  /// Returns a new [AssistenteRegistroGet200Response] instance.
  AssistenteRegistroGet200Response({

     this.acoes,
  });

  @JsonKey(
    
    name: r'acoes',
    required: false,
    includeIfNull: false,
  )


  final List<AcaoRegistrada>? acoes;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AssistenteRegistroGet200Response &&
      other.acoes == acoes;

    @override
    int get hashCode =>
        acoes.hashCode;

  factory AssistenteRegistroGet200Response.fromJson(Map<String, dynamic> json) => _$AssistenteRegistroGet200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AssistenteRegistroGet200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

