//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'assistente_acao_post_request.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AssistenteAcaoPostRequest {
  /// Returns a new [AssistenteAcaoPostRequest] instance.
  AssistenteAcaoPostRequest({

    required  this.servicoId,

    required  this.pedidoResumido,
  });

  @JsonKey(
    
    name: r'servico_id',
    required: true,
    includeIfNull: false,
  )


  final String servicoId;



      /// O que a pessoa pediu. **Truncado no servidor** a 120 caracteres — confiar o corte ao aparelho transformaria um campo de tabela imutável em texto livre. 
  @JsonKey(
    
    name: r'pedido_resumido',
    required: true,
    includeIfNull: false,
  )


  final String pedidoResumido;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AssistenteAcaoPostRequest &&
      other.servicoId == servicoId &&
      other.pedidoResumido == pedidoResumido;

    @override
    int get hashCode =>
        servicoId.hashCode +
        pedidoResumido.hashCode;

  factory AssistenteAcaoPostRequest.fromJson(Map<String, dynamic> json) => _$AssistenteAcaoPostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AssistenteAcaoPostRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

