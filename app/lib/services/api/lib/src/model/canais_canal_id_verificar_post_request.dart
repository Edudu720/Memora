//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'canais_canal_id_verificar_post_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanaisCanalIdVerificarPostRequest {
  /// Returns a new [CanaisCanalIdVerificarPostRequest] instance.
  CanaisCanalIdVerificarPostRequest({

    required  this.codigo,
  });

  @JsonKey(
    
    name: r'codigo',
    required: true,
    includeIfNull: false,
  )


  final String codigo;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanaisCanalIdVerificarPostRequest &&
      other.codigo == codigo;

    @override
    int get hashCode =>
        codigo.hashCode;

  factory CanaisCanalIdVerificarPostRequest.fromJson(Map<String, dynamic> json) => _$CanaisCanalIdVerificarPostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CanaisCanalIdVerificarPostRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

