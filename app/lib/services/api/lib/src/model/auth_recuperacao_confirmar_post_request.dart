//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'auth_recuperacao_confirmar_post_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthRecuperacaoConfirmarPostRequest {
  /// Returns a new [AuthRecuperacaoConfirmarPostRequest] instance.
  AuthRecuperacaoConfirmarPostRequest({

    required  this.identificador,

    required  this.codigo,

    required  this.novaSenha,
  });

  @JsonKey(
    
    name: r'identificador',
    required: true,
    includeIfNull: false,
  )


  final String identificador;



  @JsonKey(
    
    name: r'codigo',
    required: true,
    includeIfNull: false,
  )


  final String codigo;



      /// A política prioriza **comprimento** sobre complexidade simbólica (FR-042). Não exigimos maiúscula, número ou símbolo — exigências assim levam pessoas idosas a anotar a senha em papel, o que piora a segurança real.  Senhas notoriamente comprometidas são recusadas. 
  @JsonKey(
    
    name: r'nova_senha',
    required: true,
    includeIfNull: false,
  )


  final String novaSenha;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AuthRecuperacaoConfirmarPostRequest &&
      other.identificador == identificador &&
      other.codigo == codigo &&
      other.novaSenha == novaSenha;

    @override
    int get hashCode =>
        identificador.hashCode +
        codigo.hashCode +
        novaSenha.hashCode;

  factory AuthRecuperacaoConfirmarPostRequest.fromJson(Map<String, dynamic> json) => _$AuthRecuperacaoConfirmarPostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AuthRecuperacaoConfirmarPostRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

