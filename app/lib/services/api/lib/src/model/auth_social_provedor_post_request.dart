//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'auth_social_provedor_post_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthSocialProvedorPostRequest {
  /// Returns a new [AuthSocialProvedorPostRequest] instance.
  AuthSocialProvedorPostRequest({

    required  this.tokenIdentidade,

     this.aparelhoDescricao,
  });

      /// Token de identidade devolvido pelo provedor
  @JsonKey(
    
    name: r'token_identidade',
    required: true,
    includeIfNull: false,
  )


  final String tokenIdentidade;



  @JsonKey(
    
    name: r'aparelho_descricao',
    required: false,
    includeIfNull: false,
  )


  final String? aparelhoDescricao;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AuthSocialProvedorPostRequest &&
      other.tokenIdentidade == tokenIdentidade &&
      other.aparelhoDescricao == aparelhoDescricao;

    @override
    int get hashCode =>
        tokenIdentidade.hashCode +
        aparelhoDescricao.hashCode;

  factory AuthSocialProvedorPostRequest.fromJson(Map<String, dynamic> json) => _$AuthSocialProvedorPostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AuthSocialProvedorPostRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

