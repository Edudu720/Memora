//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'auth_recuperacao_solicitar_post202_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthRecuperacaoSolicitarPost202Response {
  /// Returns a new [AuthRecuperacaoSolicitarPost202Response] instance.
  AuthRecuperacaoSolicitarPost202Response({

     this.mensagem,
  });

  @JsonKey(
    
    name: r'mensagem',
    required: false,
    includeIfNull: false,
  )


  final String? mensagem;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AuthRecuperacaoSolicitarPost202Response &&
      other.mensagem == mensagem;

    @override
    int get hashCode =>
        mensagem.hashCode;

  factory AuthRecuperacaoSolicitarPost202Response.fromJson(Map<String, dynamic> json) => _$AuthRecuperacaoSolicitarPost202ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthRecuperacaoSolicitarPost202ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

