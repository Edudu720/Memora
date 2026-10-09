//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api/src/model/mensagem.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assistente_conversa_post_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssistenteConversaPostRequest {
  /// Returns a new [AssistenteConversaPostRequest] instance.
  AssistenteConversaPostRequest({

    required  this.mensagem,

     this.historico,
  });

      /// O que a pessoa escreveu agora.
  @JsonKey(
    
    name: r'mensagem',
    required: true,
    includeIfNull: false,
  )


  final String mensagem;



      /// A conversa até aqui, guardada no aparelho (FR-047). O servidor não a persiste. 
  @JsonKey(
    
    name: r'historico',
    required: false,
    includeIfNull: false,
  )


  final List<Mensagem>? historico;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AssistenteConversaPostRequest &&
      other.mensagem == mensagem &&
      other.historico == historico;

    @override
    int get hashCode =>
        mensagem.hashCode +
        historico.hashCode;

  factory AssistenteConversaPostRequest.fromJson(Map<String, dynamic> json) => _$AssistenteConversaPostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AssistenteConversaPostRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

