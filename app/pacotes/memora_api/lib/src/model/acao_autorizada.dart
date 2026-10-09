//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'acao_autorizada.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AcaoAutorizada {
  /// Returns a new [AcaoAutorizada] instance.
  AcaoAutorizada({

    required  this.servicoId,

    required  this.nomeExibido,

    required  this.identificadorAndroid,
  });

  @JsonKey(
    
    name: r'servico_id',
    required: true,
    includeIfNull: false,
  )


  final String servicoId;



  @JsonKey(
    
    name: r'nome_exibido',
    required: true,
    includeIfNull: false,
  )


  final String nomeExibido;



      /// Presente sempre — serviço sensível nunca chega aqui.
  @JsonKey(
    
    name: r'identificador_android',
    required: true,
    includeIfNull: false,
  )


  final String identificadorAndroid;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AcaoAutorizada &&
      other.servicoId == servicoId &&
      other.nomeExibido == nomeExibido &&
      other.identificadorAndroid == identificadorAndroid;

    @override
    int get hashCode =>
        servicoId.hashCode +
        nomeExibido.hashCode +
        identificadorAndroid.hashCode;

  factory AcaoAutorizada.fromJson(Map<String, dynamic> json) => _$AcaoAutorizadaFromJson(json);

  Map<String, dynamic> toJson() => _$AcaoAutorizadaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

