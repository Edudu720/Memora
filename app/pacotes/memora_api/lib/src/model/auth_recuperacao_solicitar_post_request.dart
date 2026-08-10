//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'auth_recuperacao_solicitar_post_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthRecuperacaoSolicitarPostRequest {
  /// Returns a new [AuthRecuperacaoSolicitarPostRequest] instance.
  AuthRecuperacaoSolicitarPostRequest({

    required  this.identificador,
  });

  @JsonKey(
    
    name: r'identificador',
    required: true,
    includeIfNull: false,
  )


  final String identificador;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AuthRecuperacaoSolicitarPostRequest &&
      other.identificador == identificador;

    @override
    int get hashCode =>
        identificador.hashCode;

  factory AuthRecuperacaoSolicitarPostRequest.fromJson(Map<String, dynamic> json) => _$AuthRecuperacaoSolicitarPostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AuthRecuperacaoSolicitarPostRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

