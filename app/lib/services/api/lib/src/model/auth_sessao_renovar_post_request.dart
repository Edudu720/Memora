//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'auth_sessao_renovar_post_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthSessaoRenovarPostRequest {
  /// Returns a new [AuthSessaoRenovarPostRequest] instance.
  AuthSessaoRenovarPostRequest({

    required  this.refreshToken,
  });

  @JsonKey(
    
    name: r'refresh_token',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AuthSessaoRenovarPostRequest &&
      other.refreshToken == refreshToken;

    @override
    int get hashCode =>
        refreshToken.hashCode;

  factory AuthSessaoRenovarPostRequest.fromJson(Map<String, dynamic> json) => _$AuthSessaoRenovarPostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AuthSessaoRenovarPostRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

