//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api/src/model/servico.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assistente_catalogo_get200_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssistenteCatalogoGet200Response {
  /// Returns a new [AssistenteCatalogoGet200Response] instance.
  AssistenteCatalogoGet200Response({

     this.servicos,
  });

  @JsonKey(
    
    name: r'servicos',
    required: false,
    includeIfNull: false,
  )


  final List<Servico>? servicos;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AssistenteCatalogoGet200Response &&
      other.servicos == servicos;

    @override
    int get hashCode =>
        servicos.hashCode;

  factory AssistenteCatalogoGet200Response.fromJson(Map<String, dynamic> json) => _$AssistenteCatalogoGet200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AssistenteCatalogoGet200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

